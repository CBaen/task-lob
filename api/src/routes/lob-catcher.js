import { Hono } from 'hono';
import Groq from 'groq-sdk';
import { LOB_PARSER_PROMPT, CLASSIFICATION_PROMPT } from '../lib/prompts.js';

export const lobCatcher = new Hono();

// Initialize Groq client
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

/**
 * POST /api/lob/parse
 *
 * Takes raw voice/text input and parses it into discrete tasks.
 * This is the core "lob catching" functionality.
 *
 * Request body:
 * {
 *   "input": "First we need to fix the notification problem...",
 *   "sender": "jeff",
 *   "companyContext": { ... } // Optional company brain context
 * }
 *
 * Response:
 * {
 *   "lobId": "abc123",
 *   "rawInput": "First we need to fix...",
 *   "parsedTasks": [
 *     {
 *       "position": 1,
 *       "summary": "Fix notification problem",
 *       "classification": "task",
 *       "system": "WordPress",
 *       "urgency": "normal",
 *       "missingInfo": ["What exactly is broken?"],
 *       "suggestedRoute": null,
 *       "selfServiceSteps": null
 *     },
 *     ...
 *   ]
 * }
 */
lobCatcher.post('/parse', async (c) => {
  try {
    const body = await c.req.json();
    const { input, sender, companyContext } = body;

    if (!input || typeof input !== 'string') {
      return c.json({ error: 'Input is required' }, 400);
    }

    // Stage 1-3: Lob Detection, Task Separation, Classification
    const parsedTasks = await parseLob(input, companyContext);

    // Generate a lob session ID
    const lobId = generateLobId();

    return c.json({
      lobId,
      rawInput: input,
      sender: sender || 'unknown',
      parsedTasks,
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    console.error('Lob parsing error:', error);
    return c.json({
      error: 'Failed to parse lob',
      details: error.message
    }, 500);
  }
});

/**
 * Parse a raw input into discrete tasks using the AI pipeline
 */
async function parseLob(input, companyContext = null) {
  // Build the system prompt with company context if available
  let systemPrompt = LOB_PARSER_PROMPT;

  if (companyContext) {
    systemPrompt += `\n\n## Company Context\n${JSON.stringify(companyContext, null, 2)}`;
  }

  const completion = await groq.chat.completions.create({
    model: 'llama-3.1-70b-versatile',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: input }
    ],
    temperature: 0.3, // Lower temperature for more consistent parsing
    max_tokens: 2000,
    response_format: { type: 'json_object' },
  });

  const response = completion.choices[0]?.message?.content;

  if (!response) {
    throw new Error('No response from AI');
  }

  const parsed = JSON.parse(response);
  return parsed.tasks || [];
}

/**
 * Generate a unique lob session ID
 */
function generateLobId() {
  return 'lob_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
}

/**
 * GET /api/lob/test
 *
 * Test endpoint with a sample Jeff-style lob
 */
lobCatcher.get('/test', async (c) => {
  const testInput = `First thing we need to fix the notification problem. It has an error
that needs to be fixed. 2nd we need to fix the birthday deliveries by
monday because i forgot i have a TV spot with KUTV to promote them.
I might need access to the google account too. WordPress sent a 3rd
party authentication to the gmail account and its probably time sensitive.`;

  try {
    const parsedTasks = await parseLob(testInput);

    return c.json({
      testInput,
      parsedTasks,
      note: 'This is a test endpoint. In production, use POST /api/lob/parse'
    });
  } catch (error) {
    return c.json({
      error: 'Test failed',
      details: error.message,
      note: 'Make sure GROQ_API_KEY is set in .env'
    }, 500);
  }
});
