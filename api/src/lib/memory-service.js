/**
 * Memory Service - Pluggable Interface
 *
 * ARCHITECTURE: Task Lob is an integration layer. This interface defines
 * how memory (resolutions, context, patterns) is stored and retrieved.
 *
 * MVP uses PocketBase's text search.
 * Future implementations can use:
 * - Qdrant for semantic vector search
 * - Pinecone for cloud vector search
 * - Postgres with pgvector
 * - Any embedding-based search
 */

import { resolutions, companyBrain } from './pocketbase.js';

/**
 * MemoryService Interface
 *
 * All implementations must provide these methods.
 * Handles storage and retrieval of resolutions, patterns, and context.
 */
export class MemoryService {
  constructor(workspaceId) {
    this.workspaceId = workspaceId;
  }

  /**
   * Search for similar past issues
   * @param {string} text - The problem description to match
   * @param {object} options - Search options
   * @returns {Promise<Array<{id, problem, solution, relevance, successCount}>>}
   */
  async searchSimilar(text, options = {}) {
    throw new Error('Not implemented: searchSimilar');
  }

  /**
   * Store a new resolution (how a problem was fixed)
   * @param {object} resolution - The resolution to store
   * @returns {Promise<{id}>}
   */
  async storeResolution(resolution) {
    throw new Error('Not implemented: storeResolution');
  }

  /**
   * Mark a resolution as successful (it worked again)
   * @param {string} id - Resolution ID
   * @returns {Promise<void>}
   */
  async recordSuccess(id) {
    throw new Error('Not implemented: recordSuccess');
  }

  /**
   * Get context for entities (people, systems mentioned)
   * Returns relevant memories for those entities.
   * @param {Array<string>} entityIds - Entity IDs to get context for
   * @returns {Promise<{routing: Array, notes: Array, patterns: Array}>}
   */
  async getContextForEntities(entityIds) {
    throw new Error('Not implemented: getContextForEntities');
  }

  /**
   * Get routing patterns for a system/keyword
   * @param {string} key - System name or keyword
   * @returns {Promise<{suggestedAssignee, confidence, reason}>}
   */
  async getRoutingPattern(key) {
    throw new Error('Not implemented: getRoutingPattern');
  }

  /**
   * Learn a new routing pattern
   * @param {object} pattern - The pattern to learn
   * @returns {Promise<{id}>}
   */
  async learnRouting(pattern) {
    throw new Error('Not implemented: learnRouting');
  }

  /**
   * Store a lob for future reference
   * Used by vector implementations to build semantic search index.
   * @param {object} lob - The lob to store
   * @returns {Promise<{id}>}
   */
  async storeLob(lob) {
    throw new Error('Not implemented: storeLob');
  }

  /**
   * Get comprehensive context for a parsed lob
   * Aggregates resolutions, routing, and entity context.
   * @param {object} parsedLob - The parsed lob with entities
   * @returns {Promise<object>} Full context object
   */
  async getFullContext(parsedLob) {
    const { entities, tasks } = parsedLob;

    // Extract unique systems and keywords
    const systems = new Set();
    const keywords = new Set();

    for (const entity of entities || []) {
      if (entity.type === 'system') {
        systems.add(entity.mention);
      }
      keywords.add(entity.mention.toLowerCase());
    }

    for (const task of tasks || []) {
      if (task.system) {
        systems.add(task.system);
      }
    }

    // Gather context in parallel
    const [similarResolutions, routingPatterns] = await Promise.all([
      this.searchSimilarForMultiple([...keywords]),
      this.getRoutingForMultiple([...systems]),
    ]);

    return {
      resolutions: similarResolutions,
      routing: routingPatterns,
      systems: [...systems],
      keywords: [...keywords],
    };
  }

  /**
   * Search similar for multiple keywords
   */
  async searchSimilarForMultiple(keywords) {
    const results = [];
    const seen = new Set();

    for (const keyword of keywords) {
      const matches = await this.searchSimilar(keyword, { limit: 3 });
      for (const match of matches) {
        if (!seen.has(match.id)) {
          seen.add(match.id);
          results.push(match);
        }
      }
    }

    // Sort by relevance
    results.sort((a, b) => (b.relevance || 0) - (a.relevance || 0));
    return results.slice(0, 5);
  }

  /**
   * Get routing for multiple systems
   */
  async getRoutingForMultiple(systems) {
    const results = [];

    for (const system of systems) {
      const pattern = await this.getRoutingPattern(system);
      if (pattern) {
        results.push({
          system,
          ...pattern,
        });
      }
    }

    return results;
  }
}

/**
 * PocketBase Implementation
 *
 * Uses text matching (not semantic) for MVP.
 * Queries resolutions and company_brain collections.
 */
export class PocketBaseMemoryService extends MemoryService {
  async searchSimilar(text, options = {}) {
    const { limit = 5, systemName = null } = options;

    // Extract keywords for matching
    const keywords = text
      .toLowerCase()
      .split(/\s+/)
      .filter(w => w.length > 3)
      .slice(0, 5);

    if (keywords.length === 0) {
      return [];
    }

    // Build filter for text matching
    // PocketBase uses ~ for contains
    const keywordFilters = keywords.map(k => `problem_pattern ~ "${k}"`);
    let filter = `workspace = "${this.workspaceId}" && (${keywordFilters.join(' || ')})`;

    if (systemName) {
      filter += ` && system_name = "${systemName}"`;
    }

    try {
      const result = await resolutions.list(this.workspaceId);

      // Manual filtering and scoring since PocketBase has limited search
      const matches = [];
      for (const res of result.items || []) {
        let score = 0;
        const problem = (res.problem_pattern || '').toLowerCase();
        const solution = (res.solution || '').toLowerCase();

        for (const keyword of keywords) {
          if (problem.includes(keyword)) score += 2;
          if (solution.includes(keyword)) score += 1;
        }

        if (systemName && res.system_name === systemName) {
          score += 3;
        }

        if (score > 0) {
          matches.push({
            id: res.id,
            problem: res.problem_pattern,
            solution: res.solution,
            systemName: res.system_name,
            successCount: res.times_worked || 0,
            relevance: score / (keywords.length * 2),
          });
        }
      }

      // Sort by success rate weighted by relevance
      matches.sort((a, b) => {
        const scoreA = a.relevance * (1 + a.successCount * 0.1);
        const scoreB = b.relevance * (1 + b.successCount * 0.1);
        return scoreB - scoreA;
      });

      return matches.slice(0, limit);
    } catch (error) {
      console.error('Error searching resolutions:', error);
      return [];
    }
  }

  async storeResolution(resolution) {
    const record = await resolutions.create({
      workspace: this.workspaceId,
      problem_pattern: resolution.problem,
      solution: resolution.solution,
      system_name: resolution.systemName || null,
      resolved_by: resolution.resolvedBy || null,
      task_id: resolution.taskId || null,
    });

    return { id: record.id };
  }

  async recordSuccess(id) {
    await resolutions.recordSuccess(id);
  }

  async getContextForEntities(entityIds) {
    // Get all company brain entries for these entities
    const routing = [];
    const notes = [];
    const patterns = [];

    for (const entityId of entityIds) {
      try {
        const memory = await companyBrain.get(entityId);

        switch (memory.memory_type) {
          case 'routing':
            routing.push({
              id: memory.id,
              key: memory.key,
              assignee: memory.value?.assignee,
              confidence: memory.confidence,
            });
            break;
          case 'note':
            notes.push({
              id: memory.id,
              content: memory.value?.content || memory.key,
              addedAt: memory.created,
            });
            break;
          default:
            patterns.push({
              id: memory.id,
              type: memory.memory_type,
              key: memory.key,
              value: memory.value,
            });
        }
      } catch (error) {
        // Entity not found, skip
        continue;
      }
    }

    return { routing, notes, patterns };
  }

  async getRoutingPattern(key) {
    const pattern = await companyBrain.findRouting(this.workspaceId, key);

    if (!pattern) {
      return null;
    }

    return {
      id: pattern.id,
      suggestedAssignee: pattern.value?.assignee,
      assigneeId: pattern.value?.assignee_id,
      confidence: pattern.confidence || 0.5,
      reason: pattern.value?.reason || `Usually handles ${key} issues`,
      timesUsed: pattern.times_used || 0,
    };
  }

  async learnRouting(pattern) {
    const record = await companyBrain.create({
      workspace: this.workspaceId,
      memory_type: 'routing',
      key: pattern.key,
      value: {
        assignee: pattern.assignee,
        assignee_id: pattern.assigneeId,
        reason: pattern.reason,
        learned_from: pattern.learnedFrom || 'manual',
      },
      confidence: pattern.confidence || 0.5,
    });

    return { id: record.id };
  }

  async storeLob(lob) {
    // For PocketBase, we just store the lob session
    // Vector implementations would also create embeddings
    const { lobSessions } = await import('./pocketbase.js');

    const record = await lobSessions.create({
      workspace: this.workspaceId,
      raw_input: lob.rawInput,
      sender: lob.sender || null,
      parsed_data: JSON.stringify(lob.parsed || {}),
    });

    return { id: record.id };
  }
}

/**
 * Factory function to get the appropriate memory service
 * Switch implementations based on config
 */
export function getMemoryService(workspaceId, backend = 'pocketbase') {
  switch (backend) {
    case 'pocketbase':
      return new PocketBaseMemoryService(workspaceId);
    // Future: case 'qdrant': return new QdrantMemoryService(workspaceId);
    // Future: case 'pinecone': return new PineconeMemoryService(workspaceId);
    default:
      return new PocketBaseMemoryService(workspaceId);
  }
}

export default {
  MemoryService,
  PocketBaseMemoryService,
  getMemoryService,
};
