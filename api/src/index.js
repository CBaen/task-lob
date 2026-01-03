import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import 'dotenv/config';

import { lobCatcher } from './routes/lob-catcher.js';
import { health } from './routes/health.js';

const app = new Hono();

// Middleware
app.use('/*', cors());

// Routes
app.route('/api/health', health);
app.route('/api/lob', lobCatcher);

// Start server
const port = process.env.PORT || 3000;

console.log(`Task Lob API starting on port ${port}`);

serve({
  fetch: app.fetch,
  port,
});

console.log(`Task Lob API running at http://localhost:${port}`);
