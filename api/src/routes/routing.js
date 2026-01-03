import { Hono } from 'hono';
import { companyBrain } from '../lib/pocketbase.js';

export const routingRouter = new Hono();

/**
 * POST /api/routing/suggest
 *
 * Get routing suggestions for a task based on Company Brain patterns.
 *
 * Body:
 * {
 *   workspace: string (required)
 *   systemName: string (detected system like "WordPress", "WooCommerce")
 *   keywords: string[] (extracted keywords from task)
 *   taskSummary: string (the task summary)
 * }
 *
 * Returns:
 * {
 *   suggestion: {
 *     userId: string,
 *     confidence: number,
 *     reason: string
 *   } | null,
 *   alternatives: array
 * }
 */
routingRouter.post('/suggest', async (c) => {
  try {
    const body = await c.req.json();
    const { workspace, systemName, keywords, taskSummary } = body;

    if (!workspace) {
      return c.json({ error: 'workspace is required' }, 400);
    }

    let suggestion = null;
    const alternatives = [];

    // First, try to find routing by system name
    if (systemName) {
      const systemRouting = await companyBrain.findRouting(workspace, systemName);
      if (systemRouting) {
        suggestion = {
          userId: systemRouting.value.userId,
          confidence: systemRouting.confidence,
          reason: `Handles ${systemName} issues`,
          memoryId: systemRouting.id,
        };
      }
    }

    // If no system match, try keywords
    if (!suggestion && keywords && keywords.length > 0) {
      for (const keyword of keywords) {
        const keywordRouting = await companyBrain.findRouting(workspace, keyword);
        if (keywordRouting && keywordRouting.confidence > 0.5) {
          if (!suggestion) {
            suggestion = {
              userId: keywordRouting.value.userId,
              confidence: keywordRouting.confidence,
              reason: `Handles "${keyword}" related tasks`,
              memoryId: keywordRouting.id,
            };
          } else {
            alternatives.push({
              userId: keywordRouting.value.userId,
              confidence: keywordRouting.confidence,
              reason: `Also handles "${keyword}"`,
              memoryId: keywordRouting.id,
            });
          }
        }
      }
    }

    // If we found a suggestion, record that we used this memory
    if (suggestion && suggestion.memoryId) {
      await companyBrain.recordUsage(suggestion.memoryId).catch(() => {});
    }

    return c.json({
      suggestion,
      alternatives,
      needsUserInput: !suggestion || suggestion.confidence < 0.7,
    });
  } catch (error) {
    console.error('Routing suggest error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/routing/learn
 *
 * Learn a new routing pattern or confirm an existing one.
 *
 * Body:
 * {
 *   workspace: string (required)
 *   key: string (system name or keyword)
 *   userId: string (who should handle this)
 *   taskId: string (optional - which task taught this)
 *   isConfirmation: boolean (confirming existing pattern vs new learning)
 *   memoryId: string (if confirming existing memory)
 * }
 */
routingRouter.post('/learn', async (c) => {
  try {
    const body = await c.req.json();
    const { workspace, key, userId, taskId, isConfirmation, memoryId } = body;

    if (!workspace || !key || !userId) {
      return c.json({ error: 'workspace, key, and userId are required' }, 400);
    }

    let memory;

    if (isConfirmation && memoryId) {
      // User confirmed existing pattern - increase confidence
      memory = await companyBrain.confirmMemory(memoryId);
    } else {
      // Check if pattern already exists
      const existing = await companyBrain.findRouting(workspace, key);

      if (existing) {
        // Update existing pattern
        if (existing.value.userId === userId) {
          // Same user - confirm
          memory = await companyBrain.confirmMemory(existing.id);
        } else {
          // Different user - this might mean pattern is changing
          // Lower confidence and update
          memory = await companyBrain.update(existing.id, {
            value: { userId },
            confidence: Math.max(0.3, existing.confidence - 0.2),
            learned_from: taskId ? [...(existing.learned_from || []), taskId] : existing.learned_from,
          });
        }
      } else {
        // Create new pattern
        memory = await companyBrain.create({
          workspace,
          memory_type: 'routing',
          key: key.toLowerCase(),
          value: { userId },
          confidence: 0.5, // Start at 50%
          learned_from: taskId ? [taskId] : [],
        });
      }
    }

    return c.json({
      memory,
      message: isConfirmation ? 'Pattern confirmed' : 'Pattern learned',
    });
  } catch (error) {
    console.error('Routing learn error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * GET /api/routing/patterns/:workspace
 *
 * Get all learned routing patterns for a workspace.
 */
routingRouter.get('/patterns/:workspace', async (c) => {
  try {
    const workspace = c.req.param('workspace');

    const result = await companyBrain.list(workspace, 'routing');

    // Transform into more readable format
    const patterns = result.items.map((memory) => ({
      id: memory.id,
      key: memory.key,
      routesTo: memory.value?.userId,
      confidence: memory.confidence,
      timesConfirmed: memory.times_confirmed || 0,
      timesUsed: memory.times_used || 0,
      lastUsed: memory.last_used,
    }));

    return c.json({
      patterns,
      total: result.totalItems,
    });
  } catch (error) {
    console.error('Get patterns error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * DELETE /api/routing/patterns/:id
 *
 * Delete a routing pattern.
 */
routingRouter.delete('/patterns/:id', async (c) => {
  try {
    const id = c.req.param('id');
    await companyBrain.delete(id);
    return c.json({ success: true });
  } catch (error) {
    console.error('Delete pattern error:', error);
    return c.json({ error: error.message }, 500);
  }
});
