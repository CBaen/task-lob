import { Hono } from 'hono';
import { companyBrain, resolutions } from '../lib/pocketbase.js';

export const brainRouter = new Hono();

/**
 * GET /api/brain/:workspace
 *
 * Get all Company Brain memories for a workspace.
 *
 * Query params:
 * - type: Filter by memory_type (routing, vocabulary, system, person, product, resolution)
 */
brainRouter.get('/:workspace', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const { type } = c.req.query();

    const result = await companyBrain.list(workspace, type || null);

    // Group by type for easier consumption
    const grouped = {};
    for (const memory of result.items) {
      const memType = memory.memory_type;
      if (!grouped[memType]) grouped[memType] = [];
      grouped[memType].push({
        id: memory.id,
        key: memory.key,
        value: memory.value,
        confidence: memory.confidence,
        timesConfirmed: memory.times_confirmed,
        timesUsed: memory.times_used,
        lastUsed: memory.last_used,
        created: memory.created,
      });
    }

    return c.json({
      memories: result.items,
      grouped,
      total: result.totalItems,
    });
  } catch (error) {
    console.error('Get brain error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/brain/:workspace
 *
 * Add a new memory to the Company Brain.
 *
 * Body:
 * {
 *   memory_type: "routing" | "vocabulary" | "system" | "person" | "product" | "website"
 *   key: string (the thing being remembered)
 *   value: object (details about this memory)
 *   learned_from: string[] (optional - task IDs that taught this)
 * }
 */
brainRouter.post('/:workspace', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.memory_type || !body.key) {
      return c.json({ error: 'memory_type and key are required' }, 400);
    }

    const memory = await companyBrain.create({
      workspace,
      memory_type: body.memory_type,
      key: body.key.toLowerCase(),
      value: body.value || {},
      learned_from: body.learned_from || [],
    });

    return c.json(memory, 201);
  } catch (error) {
    console.error('Create memory error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * PATCH /api/brain/memory/:id
 *
 * Update a memory.
 */
brainRouter.patch('/memory/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    const memory = await companyBrain.update(id, body);
    return c.json(memory);
  } catch (error) {
    console.error('Update memory error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * DELETE /api/brain/memory/:id
 *
 * Delete a memory.
 */
brainRouter.delete('/memory/:id', async (c) => {
  try {
    const id = c.req.param('id');
    await companyBrain.delete(id);
    return c.json({ success: true });
  } catch (error) {
    console.error('Delete memory error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/brain/memory/:id/confirm
 *
 * Confirm a memory (increases confidence).
 */
brainRouter.post('/memory/:id/confirm', async (c) => {
  try {
    const id = c.req.param('id');
    const memory = await companyBrain.confirmMemory(id);
    return c.json(memory);
  } catch (error) {
    console.error('Confirm memory error:', error);
    return c.json({ error: error.message }, 500);
  }
});

// ============================================
// VOCABULARY HELPERS
// ============================================

/**
 * POST /api/brain/:workspace/vocabulary
 *
 * Add a vocabulary term (jargon, acronyms, product names).
 *
 * Body:
 * {
 *   term: string (e.g., "KUTV", "birthday deliveries")
 *   meaning: string (e.g., "Local TV station in Utah")
 *   context: string (optional - when this term is used)
 * }
 */
brainRouter.post('/:workspace/vocabulary', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.term || !body.meaning) {
      return c.json({ error: 'term and meaning are required' }, 400);
    }

    const memory = await companyBrain.create({
      workspace,
      memory_type: 'vocabulary',
      key: body.term.toLowerCase(),
      value: {
        term: body.term,
        meaning: body.meaning,
        context: body.context || null,
      },
    });

    return c.json(memory, 201);
  } catch (error) {
    console.error('Add vocabulary error:', error);
    return c.json({ error: error.message }, 500);
  }
});

// ============================================
// SYSTEM HELPERS
// ============================================

/**
 * POST /api/brain/:workspace/systems
 *
 * Add a known system.
 *
 * Body:
 * {
 *   name: string (e.g., "WordPress", "WooCommerce")
 *   description: string (what it's used for)
 *   keywords: string[] (words that indicate this system)
 * }
 */
brainRouter.post('/:workspace/systems', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.name) {
      return c.json({ error: 'name is required' }, 400);
    }

    const memory = await companyBrain.create({
      workspace,
      memory_type: 'system',
      key: body.name.toLowerCase(),
      value: {
        name: body.name,
        description: body.description || null,
        keywords: body.keywords || [],
      },
    });

    return c.json(memory, 201);
  } catch (error) {
    console.error('Add system error:', error);
    return c.json({ error: error.message }, 500);
  }
});

// ============================================
// PERSON HELPERS
// ============================================

/**
 * POST /api/brain/:workspace/people
 *
 * Add a person (for routing and context).
 *
 * Body:
 * {
 *   userId: string (their user ID in the system)
 *   name: string
 *   role: string
 *   handles: string[] (what they typically handle)
 * }
 */
brainRouter.post('/:workspace/people', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.userId || !body.name) {
      return c.json({ error: 'userId and name are required' }, 400);
    }

    const memory = await companyBrain.create({
      workspace,
      memory_type: 'person',
      key: body.name.toLowerCase(),
      value: {
        userId: body.userId,
        name: body.name,
        role: body.role || null,
        handles: body.handles || [],
      },
    });

    return c.json(memory, 201);
  } catch (error) {
    console.error('Add person error:', error);
    return c.json({ error: error.message }, 500);
  }
});

// ============================================
// RESOLUTIONS (What worked before)
// ============================================

/**
 * GET /api/brain/:workspace/resolutions
 *
 * Get resolution memory - what worked before for similar issues.
 */
brainRouter.get('/:workspace/resolutions', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const result = await resolutions.list(workspace);
    return c.json(result);
  } catch (error) {
    console.error('Get resolutions error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/brain/:workspace/resolutions
 *
 * Record a new resolution.
 *
 * Body:
 * {
 *   problemPattern: string (what the problem looked like)
 *   solution: string (what fixed it)
 *   systemName: string (optional)
 *   resolvedBy: string (user ID)
 *   taskId: string (which task this came from)
 * }
 */
brainRouter.post('/:workspace/resolutions', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.problemPattern || !body.solution) {
      return c.json({ error: 'problemPattern and solution are required' }, 400);
    }

    const resolution = await resolutions.create({
      workspace,
      problem_pattern: body.problemPattern,
      solution: body.solution,
      system_name: body.systemName || null,
      resolved_by: body.resolvedBy || null,
      task_id: body.taskId || null,
    });

    return c.json(resolution, 201);
  } catch (error) {
    console.error('Create resolution error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/brain/:workspace/resolutions/search
 *
 * Find similar past resolutions.
 *
 * Body:
 * {
 *   problemPattern: string
 *   systemName: string (optional)
 * }
 */
brainRouter.post('/:workspace/resolutions/search', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    if (!body.problemPattern) {
      return c.json({ error: 'problemPattern is required' }, 400);
    }

    const result = await resolutions.findSimilar(
      workspace,
      body.problemPattern,
      body.systemName
    );

    return c.json({
      resolutions: result.items,
      total: result.totalItems,
    });
  } catch (error) {
    console.error('Search resolutions error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/brain/resolutions/:id/worked
 *
 * Record that a suggested resolution worked.
 */
brainRouter.post('/resolutions/:id/worked', async (c) => {
  try {
    const id = c.req.param('id');
    const resolution = await resolutions.recordSuccess(id);
    return c.json(resolution);
  } catch (error) {
    console.error('Record resolution success error:', error);
    return c.json({ error: error.message }, 500);
  }
});

// ============================================
// ONBOARDING SEED
// ============================================

/**
 * POST /api/brain/:workspace/seed
 *
 * Seed the Company Brain with initial data during onboarding.
 *
 * Body:
 * {
 *   companyName: string
 *   websiteUrl: string
 *   people: [{ userId, name, role, handles }]
 *   systems: [{ name, description }]
 * }
 */
brainRouter.post('/:workspace/seed', async (c) => {
  try {
    const workspace = c.req.param('workspace');
    const body = await c.req.json();

    const created = {
      people: [],
      systems: [],
      vocabulary: [],
    };

    // Seed people
    if (body.people && Array.isArray(body.people)) {
      for (const person of body.people) {
        const memory = await companyBrain.create({
          workspace,
          memory_type: 'person',
          key: person.name.toLowerCase(),
          value: person,
          confidence: 0.8, // High confidence for manual entry
        });
        created.people.push(memory);

        // Also create routing patterns from handles
        if (person.handles && Array.isArray(person.handles)) {
          for (const handle of person.handles) {
            await companyBrain.create({
              workspace,
              memory_type: 'routing',
              key: handle.toLowerCase(),
              value: { userId: person.userId },
              confidence: 0.7,
            });
          }
        }
      }
    }

    // Seed systems
    if (body.systems && Array.isArray(body.systems)) {
      for (const system of body.systems) {
        const memory = await companyBrain.create({
          workspace,
          memory_type: 'system',
          key: system.name.toLowerCase(),
          value: system,
          confidence: 0.9,
        });
        created.systems.push(memory);
      }
    }

    // Seed company vocabulary
    if (body.companyName) {
      const vocab = await companyBrain.create({
        workspace,
        memory_type: 'vocabulary',
        key: body.companyName.toLowerCase(),
        value: {
          term: body.companyName,
          meaning: 'Company name',
          context: 'The business',
        },
        confidence: 1.0,
      });
      created.vocabulary.push(vocab);
    }

    return c.json({
      message: 'Company Brain seeded',
      created,
    }, 201);
  } catch (error) {
    console.error('Seed brain error:', error);
    return c.json({ error: error.message }, 500);
  }
});
