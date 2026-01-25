import { Hono } from 'hono';
import { jsonCompletion, getProviderInfo, listProviders } from '../lib/ai-provider.js';
import { transcribeAudio, getTranscriptionInfo } from '../lib/transcription.js';
import { LOB_PARSER_PROMPT, CONTEXT_SYNTHESIS_PROMPT } from '../lib/prompts.js';
import { getEntityResolver } from '../lib/entity-resolver.js';
import { getMemoryService } from '../lib/memory-service.js';

export const lobCatcher = new Hono();

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

    // Stage 1-4: Lob Detection, Task Separation, Classification, Entity Extraction
    const { tasks, entities } = await parseLob(input, companyContext);

    // Generate a lob session ID
    const lobId = generateLobId();

    return c.json({
      lobId,
      rawInput: input,
      sender: sender || 'unknown',
      parsedTasks: tasks,
      entities,
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
 * Returns both tasks and extracted entities
 */
async function parseLob(input, companyContext = null) {
  // Build the system prompt with company context if available
  let systemPrompt = LOB_PARSER_PROMPT;

  if (companyContext) {
    systemPrompt += `\n\n## Company Context\n${JSON.stringify(companyContext, null, 2)}`;
  }

  // Use the provider-agnostic completion
  const parsed = await jsonCompletion(
    [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: input }
    ],
    {
      temperature: 0.3, // Lower temperature for more consistent parsing
      maxTokens: 3000, // Increased for entity extraction
      taskType: 'logic', // Parsing is a logic task - ideal for DeepSeek/Groq
    }
  );

  return {
    tasks: parsed.tasks || [],
    entities: parsed.entities || [],
  };
}

/**
 * POST /api/lob/parse-enriched
 *
 * Full pipeline: parse → resolve entities → get context → enrich
 * This is the "integration layer" endpoint.
 *
 * Request body:
 * {
 *   "input": "Tell Sarah to fix WordPress by Monday...",
 *   "sender": "jeff",
 *   "workspace": "workspace_id"
 * }
 *
 * Response:
 * {
 *   "lobId": "lob_abc123",
 *   "rawInput": "...",
 *   "parsedTasks": [...],
 *   "entities": {
 *     "resolved": [...],
 *     "ambiguous": [...]
 *   },
 *   "context": {
 *     "resolutions": [...],
 *     "routing": [...]
 *   }
 * }
 */
lobCatcher.post('/parse-enriched', async (c) => {
  try {
    const body = await c.req.json();
    const { input, sender, workspace } = body;

    if (!input || typeof input !== 'string') {
      return c.json({ error: 'Input is required' }, 400);
    }

    const workspaceId = workspace || 'default';

    // Stage 1-4: Parse lob and extract entities
    const { tasks, entities } = await parseLob(input);

    // Stage 5: Resolve entities against company brain
    const entityResolver = getEntityResolver(workspaceId);
    const { resolved, ambiguous } = await entityResolver.resolveAll(entities);

    // Stage 6: Get context (resolutions, routing patterns)
    const memoryService = getMemoryService(workspaceId);
    const context = await memoryService.getFullContext({ tasks, entities });

    // Generate lob ID
    const lobId = generateLobId();

    // Store the lob for future reference
    await memoryService.storeLob({
      rawInput: input,
      sender,
      parsed: { tasks, entities },
    }).catch(err => console.error('Failed to store lob:', err));

    return c.json({
      lobId,
      rawInput: input,
      sender: sender || 'unknown',
      parsedTasks: tasks,
      entities: {
        extracted: entities,
        resolved,
        ambiguous,
      },
      context,
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    console.error('Enriched parsing error:', error);
    return c.json({
      error: 'Failed to parse and enrich lob',
      details: error.message
    }, 500);
  }
});

/**
 * Generate a unique lob session ID
 */
function generateLobId() {
  return 'lob_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
}

/**
 * POST /api/lob/transcribe
 *
 * Transcribes audio using Groq Whisper (or OpenAI).
 * This is the "lob" endpoint - user speaks, releases, gets clean transcript.
 *
 * Request: multipart/form-data with 'audio' file
 * Optional query params:
 *   - language: ISO language code (e.g., 'en')
 *   - parse: if 'true', also parses transcript into tasks
 *
 * Response (transcribe only):
 * {
 *   "text": "The transcribed text...",
 *   "duration": 5.2,
 *   "language": "en",
 *   "provider": "groq",
 *   "model": "whisper-large-v3"
 * }
 *
 * Response (with parse=true):
 * {
 *   "transcript": { text, duration, language, provider, model },
 *   "lobId": "lob_abc123",
 *   "parsedTasks": [ ... ]
 * }
 */
lobCatcher.post('/transcribe', async (c) => {
  try {
    const formData = await c.req.formData();
    const audioFile = formData.get('audio');

    if (!audioFile || !(audioFile instanceof File)) {
      return c.json({ error: 'Audio file is required. Send as multipart/form-data with field "audio".' }, 400);
    }

    // Get options from query params
    const language = c.req.query('language');
    const shouldParse = c.req.query('parse') === 'true';

    // Get audio data as buffer
    const audioBuffer = await audioFile.arrayBuffer();
    const audioData = Buffer.from(audioBuffer);

    // Transcribe using Groq Whisper
    const transcript = await transcribeAudio(audioData, audioFile.name, {
      language,
    });

    // If parse=true, also parse the transcript into tasks
    if (shouldParse && transcript.text) {
      const { tasks, entities } = await parseLob(transcript.text);
      const lobId = generateLobId();

      return c.json({
        transcript,
        lobId,
        rawInput: transcript.text,
        parsedTasks: tasks,
        entities,
        timestamp: new Date().toISOString(),
      });
    }

    // Just return the transcript
    return c.json(transcript);

  } catch (error) {
    console.error('Transcription error:', error);
    return c.json({
      error: 'Failed to transcribe audio',
      details: error.message
    }, 500);
  }
});

/**
 * GET /api/lob/transcription-info
 *
 * Returns current transcription provider configuration
 */
lobCatcher.get('/transcription-info', (c) => {
  return c.json(getTranscriptionInfo());
});

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
    const { tasks, entities } = await parseLob(testInput);
    const provider = getProviderInfo();

    return c.json({
      testInput,
      parsedTasks: tasks,
      entities,
      provider,
      note: 'This is a test endpoint. In production, use POST /api/lob/parse or /api/lob/parse-enriched'
    });
  } catch (error) {
    const provider = getProviderInfo();
    return c.json({
      error: 'Test failed',
      details: error.message,
      provider,
      note: 'Check your AI provider configuration in .env'
    }, 500);
  }
});

/**
 * GET /api/lob/provider
 *
 * Returns current AI provider configuration (for debugging)
 */
lobCatcher.get('/provider', (c) => {
  return c.json(getProviderInfo());
});

/**
 * GET /api/lob/providers
 *
 * Returns all available AI providers with recommendations
 * Based on January 2026 research
 */
lobCatcher.get('/providers', (c) => {
  const providers = listProviders();
  const current = getProviderInfo();

  return c.json({
    current,
    recommendations: {
      development: {
        provider: 'mistral',
        reason: 'FREE 1 billion tokens/month, no credit card required',
        signupUrl: 'https://console.mistral.ai/',
        pricing: 'Free tier: 1B tokens/month',
      },
      production: {
        provider: 'deepinfra',
        reason: 'US-based, nearly DeepSeek pricing without China data concerns',
        signupUrl: 'https://deepinfra.com/dash/api_keys',
        pricing: '$0.50 input / $2.15 output per 1M tokens',
      },
      enterprise: {
        provider: 'together',
        reason: 'US-based, SOC2 compliant, good enterprise support',
        signupUrl: 'https://api.together.xyz/settings/api-keys',
        pricing: '$1.25 flat per 1M tokens',
      },
      fallbackAggregator: {
        provider: 'openrouter',
        reason: 'Access 300+ models, auto-fallbacks on provider errors',
        signupUrl: 'https://openrouter.ai/keys',
        pricing: 'Varies by model, some free',
      },
      creative: {
        provider: 'anthropic',
        reason: 'Best for narrative prose, dialogue, creative writing',
        signupUrl: 'https://console.anthropic.com/',
        pricing: '$3 input / $15 output per 1M tokens',
      },
      longContext: {
        provider: 'gemini',
        reason: '2M token context window - best for archives, story bibles',
        signupUrl: 'https://aistudio.google.com/',
        pricing: '$2.50 input / $10 output per 1M tokens',
      },
      speed: {
        provider: 'groq',
        reason: 'Fastest inference speeds, good free tier',
        signupUrl: 'https://console.groq.com/keys',
        pricing: 'Free tier: 14,400 requests/day',
      },
    },
    avoid: [
      {
        provider: 'deepseek',
        reason: 'Data sent to China with government access. Security vulnerabilities. Banned by multiple governments.',
        alternative: 'Use deepinfra or together to access DeepSeek models safely from US servers.',
      },
      {
        provider: 'fireworks',
        reason: 'Reliability and support issues reported in developer reviews.',
        alternative: 'Use together or deepinfra instead.',
      },
    ],
    allProviders: providers,
    researchDate: '2026-01-05',
    configInstructions: {
      step1: 'Choose a provider from recommendations above',
      step2: 'Get an API key from the signupUrl',
      step3: 'Set AI_PROVIDER and the appropriate API key in api/.env',
      example: 'AI_PROVIDER=mistral\nMISTRAL_API_KEY=your_key_here',
    },
  });
});
