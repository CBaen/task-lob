import { Hono } from 'hono';
import { tasks, threads, lobSessions } from '../lib/pocketbase.js';

export const tasksRouter = new Hono();

/**
 * GET /api/tasks
 *
 * List tasks with optional filters.
 *
 * Query params:
 * - workspace: Required workspace ID
 * - court: Filter by court_user
 * - sender: Filter by sender
 * - status: Filter by status
 * - page: Page number (default 1)
 * - perPage: Items per page (default 50)
 */
tasksRouter.get('/', async (c) => {
  try {
    const { workspace, court, sender, status, page, perPage } = c.req.query();

    if (!workspace) {
      return c.json({ error: 'workspace query param is required' }, 400);
    }

    // Build filter
    let filter = `workspace = "${workspace}"`;
    if (court) filter += ` && court_user = "${court}"`;
    if (sender) filter += ` && sender = "${sender}"`;
    if (status) filter += ` && status = "${status}"`;

    const result = await tasks.list({
      filter,
      page: parseInt(page) || 1,
      perPage: parseInt(perPage) || 50,
    });

    return c.json(result);
  } catch (error) {
    console.error('List tasks error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * GET /api/tasks/my-court/:userId
 *
 * Get all tasks in a user's court (tasks they need to act on).
 */
tasksRouter.get('/my-court/:userId', async (c) => {
  try {
    const userId = c.req.param('userId');
    const { workspace } = c.req.query();

    if (!workspace) {
      return c.json({ error: 'workspace query param is required' }, 400);
    }

    const result = await tasks.getMyCourt(userId, workspace);
    return c.json(result);
  } catch (error) {
    console.error('My court error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * GET /api/tasks/waiting/:userId
 *
 * Get tasks the user sent that are waiting on others.
 */
tasksRouter.get('/waiting/:userId', async (c) => {
  try {
    const userId = c.req.param('userId');
    const { workspace } = c.req.query();

    if (!workspace) {
      return c.json({ error: 'workspace query param is required' }, 400);
    }

    const result = await tasks.getWaitingOnOthers(userId, workspace);
    return c.json(result);
  } catch (error) {
    console.error('Waiting on others error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * GET /api/tasks/:id
 *
 * Get a single task by ID.
 */
tasksRouter.get('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const task = await tasks.get(id);
    return c.json(task);
  } catch (error) {
    console.error('Get task error:', error);
    return c.json({ error: error.message }, 404);
  }
});

/**
 * POST /api/tasks
 *
 * Create a new task.
 *
 * Body:
 * {
 *   workspace: string (required)
 *   sender: string (required)
 *   raw_input: string (required)
 *   summary: string (required)
 *   classification: "task" | "self_service" | "reminder" | "venting"
 *   urgency: "normal" | "urgent" | "deadline"
 *   deadline: string (ISO date)
 *   system_name: string
 *   owner: string (user ID)
 *   court_user: string (user ID)
 *   lob_session: string (lob session ID)
 *   position_in_lob: number
 *   missing_info: string[]
 *   ai_research: object
 *   ai_suggested_plan: object
 * }
 */
tasksRouter.post('/', async (c) => {
  try {
    const body = await c.req.json();

    // Validate required fields
    const required = ['workspace', 'sender', 'raw_input', 'summary', 'classification'];
    for (const field of required) {
      if (!body[field]) {
        return c.json({ error: `${field} is required` }, 400);
      }
    }

    // Set defaults
    const taskData = {
      ...body,
      status: 'draft',
      urgency: body.urgency || 'normal',
      court_user: body.court_user || body.owner || null,
      court_reason: body.court_user ? 'Task assigned' : null,
    };

    const task = await tasks.create(taskData);

    // Add system thread entry
    await threads.addSystemEvent(
      task.id,
      'status_change',
      `Task created: ${task.summary}`
    );

    return c.json(task, 201);
  } catch (error) {
    console.error('Create task error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/tasks/from-lob
 *
 * Create multiple tasks from a parsed lob.
 *
 * Body:
 * {
 *   workspace: string
 *   sender: string
 *   rawInput: string (the original lob)
 *   parsedTasks: array (from lob parser)
 * }
 */
tasksRouter.post('/from-lob', async (c) => {
  try {
    const body = await c.req.json();
    const { workspace, sender, rawInput, parsedTasks } = body;

    if (!workspace || !sender || !rawInput || !parsedTasks) {
      return c.json({ error: 'workspace, sender, rawInput, and parsedTasks are required' }, 400);
    }

    // Create lob session first
    const lobSession = await lobSessions.create({
      workspace,
      sender,
      raw_input: rawInput,
    });

    // Create tasks from parsed lob
    const createdTasks = [];
    for (const parsed of parsedTasks) {
      // Skip venting - just acknowledge, don't create task
      if (parsed.classification === 'venting') {
        continue;
      }

      const taskData = {
        workspace,
        sender,
        raw_input: parsed.rawChunk,
        summary: parsed.summary,
        classification: parsed.classification,
        urgency: parsed.urgency,
        deadline: parsed.deadline ? new Date(parsed.deadline).toISOString() : null,
        system_name: parsed.system,
        missing_info: parsed.missingInfo || [],
        lob_session: lobSession.id,
        position_in_lob: parsed.position,
        status: 'draft',
      };

      // Self-service tasks stay with sender
      if (parsed.classification === 'self_service') {
        taskData.court_user = sender;
        taskData.court_reason = 'Self-service - you can handle this';
      }

      const task = await tasks.create(taskData);
      createdTasks.push(task);
    }

    return c.json({
      lobSession,
      tasks: createdTasks,
      ventingAcknowledged: parsedTasks.filter(t => t.classification === 'venting').length,
    }, 201);
  } catch (error) {
    console.error('Create from lob error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * PATCH /api/tasks/:id
 *
 * Update a task.
 */
tasksRouter.patch('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    const task = await tasks.update(id, body);
    return c.json(task);
  } catch (error) {
    console.error('Update task error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/tasks/:id/send
 *
 * Send a draft task (change status from draft to sent).
 *
 * Body:
 * {
 *   owner: string (user ID to assign to)
 * }
 */
tasksRouter.post('/:id/send', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    const task = await tasks.update(id, {
      status: 'sent',
      owner: body.owner,
      court_user: body.owner,
      court_reason: 'New task assigned',
    });

    await threads.addSystemEvent(
      task.id,
      'status_change',
      `Task sent to ${body.owner}`
    );

    return c.json(task);
  } catch (error) {
    console.error('Send task error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/tasks/:id/flip-court
 *
 * Flip court to another user.
 *
 * Body:
 * {
 *   court_user: string (new court user ID)
 *   reason: string
 *   message: string (optional message to include)
 * }
 */
tasksRouter.post('/:id/flip-court', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    if (!body.court_user || !body.reason) {
      return c.json({ error: 'court_user and reason are required' }, 400);
    }

    const task = await tasks.flipCourt(id, body.court_user, body.reason);

    await threads.addSystemEvent(
      task.id,
      'court_flip',
      `Court flipped to ${body.court_user}: ${body.reason}`
    );

    if (body.message) {
      await threads.addMessage(id, body.from_user, 'user', body.message);
    }

    return c.json(task);
  } catch (error) {
    console.error('Flip court error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/tasks/:id/complete
 *
 * Mark a task as complete.
 *
 * Body:
 * {
 *   resolution_notes: string (how it was resolved)
 * }
 */
tasksRouter.post('/:id/complete', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    const task = await tasks.complete(id, body.resolution_notes || '');

    await threads.addSystemEvent(
      task.id,
      'status_change',
      `Task completed: ${body.resolution_notes || 'No notes'}`
    );

    return c.json(task);
  } catch (error) {
    console.error('Complete task error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * DELETE /api/tasks/:id
 *
 * Delete a task.
 */
tasksRouter.delete('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    await tasks.delete(id);
    return c.json({ success: true });
  } catch (error) {
    console.error('Delete task error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * GET /api/tasks/:id/thread
 *
 * Get the conversation thread for a task.
 */
tasksRouter.get('/:id/thread', async (c) => {
  try {
    const id = c.req.param('id');
    const result = await threads.list(id);
    return c.json(result);
  } catch (error) {
    console.error('Get thread error:', error);
    return c.json({ error: error.message }, 500);
  }
});

/**
 * POST /api/tasks/:id/thread
 *
 * Add a message to a task's thread.
 *
 * Body:
 * {
 *   actor: string (user ID)
 *   content: string
 * }
 */
tasksRouter.post('/:id/thread', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    if (!body.actor || !body.content) {
      return c.json({ error: 'actor and content are required' }, 400);
    }

    const thread = await threads.addMessage(id, body.actor, 'user', body.content);
    return c.json(thread, 201);
  } catch (error) {
    console.error('Add message error:', error);
    return c.json({ error: error.message }, 500);
  }
});
