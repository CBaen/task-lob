/**
 * Entity Resolver - Pluggable Interface
 *
 * ARCHITECTURE: Task Lob is an integration layer. This interface defines
 * how entities are resolved against ANY backend (PocketBase, Odoo,
 * Salesforce, HubSpot, etc.).
 *
 * Each backend gets its own implementation of this interface.
 * Switch implementations via environment variable or workspace config.
 */

import { companyBrain, resolutions } from './pocketbase.js';

/**
 * Fuzzy matching score (0-1) for string similarity
 * Uses Levenshtein-inspired approach
 */
function fuzzyScore(needle, haystack) {
  const n = needle.toLowerCase();
  const h = haystack.toLowerCase();

  // Exact match
  if (n === h) return 1.0;

  // Contains match
  if (h.includes(n)) return 0.9;

  // Starts with match
  if (h.startsWith(n)) return 0.85;

  // Word boundary match (e.g., "sarah" matches "Sarah Thompson")
  const words = h.split(/\s+/);
  for (const word of words) {
    if (word.startsWith(n)) return 0.8;
    if (word === n) return 0.85;
  }

  // Partial match - count matching characters
  let matches = 0;
  let lastIndex = -1;
  for (const char of n) {
    const index = h.indexOf(char, lastIndex + 1);
    if (index > lastIndex) {
      matches++;
      lastIndex = index;
    }
  }

  return matches / Math.max(n.length, h.length) * 0.7;
}

/**
 * EntityResolver Interface
 *
 * All implementations must provide these methods.
 * Returns arrays of matches with confidence scores.
 */
export class EntityResolver {
  constructor(workspaceId) {
    this.workspaceId = workspaceId;
  }

  /**
   * Find person entities matching a mention
   * @param {string} mention - The text mention (e.g., "Sarah", "my boss")
   * @param {object} context - Context clues from extraction
   * @returns {Promise<Array<{id, name, email?, role?, confidence}>>}
   */
  async findPerson(mention, context = {}) {
    throw new Error('Not implemented: findPerson');
  }

  /**
   * Find company/organization entities
   * @param {string} mention - The text mention (e.g., "KUTV", "the vendor")
   * @returns {Promise<Array<{id, name, type?, confidence}>>}
   */
  async findCompany(mention) {
    throw new Error('Not implemented: findCompany');
  }

  /**
   * Find system/platform entities
   * @param {string} mention - The text mention (e.g., "WordPress", "the website")
   * @returns {Promise<Array<{id, name, type?, confidence}>>}
   */
  async findSystem(mention) {
    throw new Error('Not implemented: findSystem');
  }

  /**
   * Find account entities
   * @param {string} mention - The text mention (e.g., "our Stripe", "the Gmail")
   * @returns {Promise<Array<{id, name, system?, confidence}>>}
   */
  async findAccount(mention) {
    throw new Error('Not implemented: findAccount');
  }

  /**
   * Add a new entity to the backend
   * @param {object} entity - Entity to create
   * @returns {Promise<{id, name}>}
   */
  async addEntity(entity) {
    throw new Error('Not implemented: addEntity');
  }

  /**
   * Resolve all entities from a parsed lob
   * @param {Array} entities - Extracted entities from parser
   * @returns {Promise<{resolved: Array, ambiguous: Array}>}
   */
  async resolveAll(entities) {
    const resolved = [];
    const ambiguous = [];

    for (const entity of entities) {
      let matches = [];

      switch (entity.type) {
        case 'person':
          matches = await this.findPerson(entity.mention, {
            contextClues: entity.contextClues,
            role: entity.role,
          });
          break;
        case 'company':
          matches = await this.findCompany(entity.mention);
          break;
        case 'system':
          matches = await this.findSystem(entity.mention);
          break;
        case 'account':
          matches = await this.findAccount(entity.mention);
          break;
        case 'date':
          // Dates don't need resolution, just normalization
          resolved.push({
            ...entity,
            resolved: true,
            resolvedTo: entity.mention,
            confidence: 1.0,
          });
          continue;
      }

      if (matches.length === 0) {
        // No matches - could be new entity
        ambiguous.push({
          ...entity,
          resolved: false,
          possibleMatches: [],
          clarificationQuestion: `Who/what is "${entity.mention}"?`,
        });
      } else if (matches.length === 1 && matches[0].confidence >= 0.9) {
        // Single high-confidence match
        resolved.push({
          ...entity,
          resolved: true,
          resolvedTo: matches[0].id,
          resolvedName: matches[0].name,
          confidence: matches[0].confidence,
        });
      } else if (matches[0].confidence >= 0.9 && matches[1]?.confidence < 0.7) {
        // Clear winner with low-confidence alternatives
        resolved.push({
          ...entity,
          resolved: true,
          resolvedTo: matches[0].id,
          resolvedName: matches[0].name,
          confidence: matches[0].confidence,
          alternates: matches.slice(1, 3),
        });
      } else {
        // Ambiguous - multiple viable matches
        ambiguous.push({
          ...entity,
          resolved: false,
          possibleMatches: matches.slice(0, 4),
          clarificationQuestion: this.buildClarificationQuestion(entity, matches),
        });
      }
    }

    return { resolved, ambiguous };
  }

  /**
   * Build a clarification question for ambiguous entities
   */
  buildClarificationQuestion(entity, matches) {
    if (matches.length === 0) {
      return `I don't recognize "${entity.mention}". Would you like to add them?`;
    }

    const names = matches.slice(0, 3).map(m => m.name).join(', ');
    return `Which ${entity.type} did you mean: ${names}?`;
  }
}

/**
 * PocketBase Implementation
 *
 * Uses the company_brain collection to store and resolve entities.
 * This is the default implementation for Task Lob MVP.
 */
export class PocketBaseEntityResolver extends EntityResolver {
  async findPerson(mention, context = {}) {
    // Search company_brain for person memories
    const result = await companyBrain.list(this.workspaceId, 'person');
    const matches = [];

    for (const memory of result.items || []) {
      const score = fuzzyScore(mention, memory.key);
      if (score >= 0.5) {
        matches.push({
          id: memory.id,
          name: memory.key,
          role: memory.value?.role,
          email: memory.value?.email,
          confidence: score * (memory.confidence || 0.5),
        });
      }
    }

    // Apply context clues to boost scores
    if (context.contextClues) {
      for (const match of matches) {
        for (const clue of context.contextClues) {
          // Check if clue matches role or other metadata
          if (match.role && clue.toLowerCase().includes(match.role.toLowerCase())) {
            match.confidence = Math.min(1.0, match.confidence + 0.15);
          }
        }
      }
    }

    // Sort by confidence, highest first
    matches.sort((a, b) => b.confidence - a.confidence);
    return matches;
  }

  async findCompany(mention) {
    const result = await companyBrain.list(this.workspaceId, 'company');
    const matches = [];

    for (const memory of result.items || []) {
      const score = fuzzyScore(mention, memory.key);
      if (score >= 0.5) {
        matches.push({
          id: memory.id,
          name: memory.key,
          type: memory.value?.type,
          confidence: score * (memory.confidence || 0.5),
        });
      }
    }

    matches.sort((a, b) => b.confidence - a.confidence);
    return matches;
  }

  async findSystem(mention) {
    const result = await companyBrain.list(this.workspaceId, 'system');
    const matches = [];

    for (const memory of result.items || []) {
      const score = fuzzyScore(mention, memory.key);
      if (score >= 0.5) {
        matches.push({
          id: memory.id,
          name: memory.key,
          type: memory.value?.type,
          url: memory.value?.url,
          confidence: score * (memory.confidence || 0.5),
        });
      }
    }

    matches.sort((a, b) => b.confidence - a.confidence);
    return matches;
  }

  async findAccount(mention) {
    // Accounts might be stored as systems with account type
    const result = await companyBrain.list(this.workspaceId, 'system');
    const matches = [];

    for (const memory of result.items || []) {
      if (memory.value?.type === 'account' || memory.key.toLowerCase().includes('account')) {
        const score = fuzzyScore(mention, memory.key);
        if (score >= 0.4) {
          matches.push({
            id: memory.id,
            name: memory.key,
            system: memory.value?.system,
            confidence: score * (memory.confidence || 0.5),
          });
        }
      }
    }

    matches.sort((a, b) => b.confidence - a.confidence);
    return matches;
  }

  async addEntity(entity) {
    const memoryType = entity.type === 'account' ? 'system' : entity.type;

    const record = await companyBrain.create({
      workspace: this.workspaceId,
      memory_type: memoryType,
      key: entity.name,
      value: {
        role: entity.role,
        email: entity.email,
        type: entity.type,
        source: 'user_added',
        addedAt: new Date().toISOString(),
      },
      confidence: 0.8, // User-added entities start with high confidence
    });

    return {
      id: record.id,
      name: entity.name,
    };
  }
}

/**
 * Factory function to get the appropriate resolver
 * Switch implementations based on config
 */
export function getEntityResolver(workspaceId, backend = 'pocketbase') {
  switch (backend) {
    case 'pocketbase':
      return new PocketBaseEntityResolver(workspaceId);
    // Future: case 'odoo': return new OdooEntityResolver(workspaceId);
    // Future: case 'salesforce': return new SalesforceEntityResolver(workspaceId);
    default:
      return new PocketBaseEntityResolver(workspaceId);
  }
}

export default {
  EntityResolver,
  PocketBaseEntityResolver,
  getEntityResolver,
};
