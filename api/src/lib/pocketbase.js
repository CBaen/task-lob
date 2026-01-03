/**
 * PocketBase client for Task Lob API
 *
 * Handles all database operations through PocketBase.
 */

const POCKETBASE_URL = process.env.POCKETBASE_URL || 'http://127.0.0.1:8090';

/**
 * Make a request to PocketBase API
 */
async function pbRequest(path, options = {}) {
  const url = `${POCKETBASE_URL}/api${path}`;

  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: response.statusText }));
    throw new Error(error.message || `PocketBase error: ${response.status}`);
  }

  return response.json();
}

/**
 * Collection operations
 */
export const collections = {
  /**
   * List records from a collection
   */
  async list(collection, { page = 1, perPage = 50, filter = '', sort = '-created' } = {}) {
    const params = new URLSearchParams({
      page: String(page),
      perPage: String(perPage),
      sort,
    });
    if (filter) params.set('filter', filter);

    return pbRequest(`/collections/${collection}/records?${params}`);
  },

  /**
   * Get a single record
   */
  async get(collection, id) {
    return pbRequest(`/collections/${collection}/records/${id}`);
  },

  /**
   * Create a new record
   */
  async create(collection, data) {
    return pbRequest(`/collections/${collection}/records`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  /**
   * Update a record
   */
  async update(collection, id, data) {
    return pbRequest(`/collections/${collection}/records/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  /**
   * Delete a record
   */
  async delete(collection, id) {
    return pbRequest(`/collections/${collection}/records/${id}`, {
      method: 'DELETE',
    });
  },
};

/**
 * Task-specific operations
 */
export const tasks = {
  async list(options = {}) {
    return collections.list('tasks', options);
  },

  async get(id) {
    return collections.get('tasks', id);
  },

  async create(data) {
    return collections.create('tasks', {
      ...data,
      status: data.status || 'draft',
      urgency: data.urgency || 'normal',
    });
  },

  async update(id, data) {
    return collections.update('tasks', id, data);
  },

  async delete(id) {
    return collections.delete('tasks', id);
  },

  /**
   * Get tasks in a user's court
   */
  async getMyCourt(userId, workspaceId) {
    return collections.list('tasks', {
      filter: `court_user = "${userId}" && workspace = "${workspaceId}" && status != "done"`,
      sort: '-urgency,-created',
    });
  },

  /**
   * Get tasks waiting on others
   */
  async getWaitingOnOthers(userId, workspaceId) {
    return collections.list('tasks', {
      filter: `sender = "${userId}" && court_user != "${userId}" && workspace = "${workspaceId}" && status != "done"`,
      sort: '-created',
    });
  },

  /**
   * Flip court to another user
   */
  async flipCourt(taskId, newCourtUserId, reason) {
    return collections.update('tasks', taskId, {
      court_user: newCourtUserId,
      court_reason: reason,
    });
  },

  /**
   * Mark task as done with resolution notes
   */
  async complete(taskId, resolutionNotes) {
    return collections.update('tasks', taskId, {
      status: 'done',
      resolution_notes: resolutionNotes,
      court_user: null,
    });
  },
};

/**
 * Lob session operations
 */
export const lobSessions = {
  async create(data) {
    return collections.create('lob_sessions', data);
  },

  async get(id) {
    return collections.get('lob_sessions', id);
  },
};

/**
 * Thread operations (task conversation)
 */
export const threads = {
  async list(taskId) {
    return collections.list('threads', {
      filter: `task = "${taskId}"`,
      sort: 'created',
    });
  },

  async addMessage(taskId, actorId, actorType, content) {
    return collections.create('threads', {
      task: taskId,
      type: 'message',
      actor: actorType === 'user' ? actorId : null,
      actor_type: actorType,
      content,
    });
  },

  async addSystemEvent(taskId, type, content) {
    return collections.create('threads', {
      task: taskId,
      type,
      actor: null,
      actor_type: 'system',
      content,
    });
  },
};

/**
 * Company Brain operations
 */
export const companyBrain = {
  async list(workspaceId, memoryType = null) {
    let filter = `workspace = "${workspaceId}"`;
    if (memoryType) {
      filter += ` && memory_type = "${memoryType}"`;
    }
    return collections.list('company_brain', { filter, perPage: 200 });
  },

  async get(id) {
    return collections.get('company_brain', id);
  },

  async create(data) {
    return collections.create('company_brain', {
      ...data,
      confidence: data.confidence || 0.5,
      times_confirmed: 0,
      times_used: 0,
    });
  },

  async update(id, data) {
    return collections.update('company_brain', id, data);
  },

  async delete(id) {
    return collections.delete('company_brain', id);
  },

  /**
   * Find routing suggestion for a system/keyword
   */
  async findRouting(workspaceId, key) {
    const result = await collections.list('company_brain', {
      filter: `workspace = "${workspaceId}" && memory_type = "routing" && key ~ "${key}"`,
      sort: '-confidence',
      perPage: 1,
    });
    return result.items[0] || null;
  },

  /**
   * Increase confidence for a memory
   */
  async confirmMemory(id) {
    const memory = await collections.get('company_brain', id);
    const newConfidence = Math.min(1.0, memory.confidence + 0.1);
    return collections.update('company_brain', id, {
      confidence: newConfidence,
      times_confirmed: (memory.times_confirmed || 0) + 1,
      last_used: new Date().toISOString(),
    });
  },

  /**
   * Record that a memory was used
   */
  async recordUsage(id) {
    const memory = await collections.get('company_brain', id);
    return collections.update('company_brain', id, {
      times_used: (memory.times_used || 0) + 1,
      last_used: new Date().toISOString(),
    });
  },
};

/**
 * Resolution operations
 */
export const resolutions = {
  async list(workspaceId) {
    return collections.list('resolutions', {
      filter: `workspace = "${workspaceId}"`,
      sort: '-times_worked',
    });
  },

  async create(data) {
    return collections.create('resolutions', {
      ...data,
      times_suggested: 0,
      times_worked: 0,
    });
  },

  /**
   * Find similar past resolutions
   */
  async findSimilar(workspaceId, problemPattern, systemName = null) {
    let filter = `workspace = "${workspaceId}" && problem_pattern ~ "${problemPattern}"`;
    if (systemName) {
      filter += ` && system_name = "${systemName}"`;
    }
    return collections.list('resolutions', {
      filter,
      sort: '-times_worked',
      perPage: 5,
    });
  },

  /**
   * Record that a resolution worked
   */
  async recordSuccess(id) {
    const resolution = await collections.get('resolutions', id);
    return collections.update('resolutions', id, {
      times_worked: (resolution.times_worked || 0) + 1,
    });
  },
};

export default {
  collections,
  tasks,
  lobSessions,
  threads,
  companyBrain,
  resolutions,
};
