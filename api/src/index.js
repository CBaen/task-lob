import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import 'dotenv/config';

import { lobCatcher } from './routes/lob-catcher.js';
import { health } from './routes/health.js';
import { tasksRouter } from './routes/tasks.js';
import { routingRouter } from './routes/routing.js';
import { brainRouter } from './routes/brain.js';

const app = new Hono();

// Middleware
app.use('/*', cors());

// Routes
app.route('/api/health', health);
app.route('/api/lob', lobCatcher);
app.route('/api/tasks', tasksRouter);
app.route('/api/routing', routingRouter);
app.route('/api/brain', brainRouter);

// Start server
const port = process.env.PORT || 3000;

console.log(`Task Lob API starting on port ${port}`);

serve({
  fetch: app.fetch,
  port,
});

console.log(`Task Lob API running at http://localhost:${port}`);
