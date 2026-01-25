/**
 * AI Provider Abstraction Layer
 *
 * Implements a provider-agnostic interface for LLM calls.
 *
 * RECOMMENDED PROVIDERS (based on Jan 2026 research):
 * - mistral: FREE 1B tokens/month - best for development
 * - deepinfra: $0.50/1M tokens - US-based, nearly DeepSeek pricing
 * - together: $1.25/1M tokens - US-based, SOC2 compliant
 * - openrouter: Aggregator with auto-fallbacks, access to 300+ models
 *
 * WARNING: DeepSeek direct API sends data to China with government access.
 * Use deepinfra or together to access DeepSeek models safely from US servers.
 *
 * Supported providers:
 * - mistral: Mistral AI (FREE 1B tokens/month, no credit card)
 * - deepinfra: DeepInfra (US-based, cheap DeepSeek/Llama hosting)
 * - openrouter: OpenRouter (aggregator with 300+ models, auto-fallbacks)
 * - together: Together AI (US-based, SOC2, hosts DeepSeek/Llama)
 * - groq: Groq API (fast inference, free tier 14k req/day)
 * - openai: OpenAI API (GPT-4, GPT-4o)
 * - anthropic: Anthropic API (Claude - best for creative/narrative)
 * - gemini: Google Gemini API (2M context window - best for archives)
 * - fireworks: Fireworks AI (has reliability concerns per research)
 * - deepseek: DeepSeek direct (NOT RECOMMENDED - data goes to China)
 */

// Provider configurations
const PROVIDER_CONFIGS = {
  // === RECOMMENDED FOR DEVELOPMENT ===
  mistral: {
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModel: 'mistral-small-latest', // Good balance of cost/quality
    envKey: 'MISTRAL_API_KEY',
    type: 'openai-compatible',
    notes: 'FREE 1B tokens/month, no credit card required',
  },

  // === RECOMMENDED FOR PRODUCTION (US-BASED, CHEAP) ===
  deepinfra: {
    baseUrl: 'https://api.deepinfra.com/v1/openai',
    defaultModel: 'deepseek-ai/DeepSeek-R1', // Or 'meta-llama/Llama-3.3-70B-Instruct'
    envKey: 'DEEPINFRA_API_KEY',
    type: 'openai-compatible',
    notes: 'US-based, $0.50/$2.15 per 1M tokens for DeepSeek R1',
  },

  // === AGGREGATOR WITH FALLBACKS ===
  openrouter: {
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'deepseek/deepseek-r1', // Can use any of 300+ models
    envKey: 'OPENROUTER_API_KEY',
    type: 'openai-compatible',
    notes: 'Aggregator with auto-fallbacks, 300+ models, some free',
  },

  // === OTHER GOOD OPTIONS ===
  together: {
    baseUrl: 'https://api.together.xyz/v1',
    defaultModel: 'deepseek-ai/DeepSeek-R1',
    envKey: 'TOGETHER_API_KEY',
    type: 'openai-compatible',
    notes: 'US-based, SOC2 compliant, good enterprise support',
  },

  groq: {
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
    envKey: 'GROQ_API_KEY',
    type: 'openai-compatible',
    notes: 'Fastest inference, free tier 14k req/day',
  },

  openai: {
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o',
    envKey: 'OPENAI_API_KEY',
    type: 'openai-compatible',
  },

  anthropic: {
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-sonnet-4-20250514',
    envKey: 'ANTHROPIC_API_KEY',
    type: 'anthropic',
    notes: 'Best for creative/narrative prose',
  },

  gemini: {
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    defaultModel: 'gemini-1.5-pro',
    envKey: 'GEMINI_API_KEY',
    type: 'gemini',
    notes: '2M token context - best for archives/long documents',
  },

  // === USE WITH CAUTION ===
  fireworks: {
    baseUrl: 'https://api.fireworks.ai/inference/v1',
    defaultModel: 'accounts/fireworks/models/deepseek-r1',
    envKey: 'FIREWORKS_API_KEY',
    type: 'openai-compatible',
    notes: 'Has reliability/support issues per research',
  },

  // === NOT RECOMMENDED (data goes to China) ===
  deepseek: {
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
    reasonerModel: 'deepseek-reasoner',
    envKey: 'DEEPSEEK_API_KEY',
    type: 'openai-compatible',
    notes: 'WARNING: Data stored in China with government access. Use deepinfra instead.',
  },
};

/**
 * Get the configured provider from environment
 */
function getProviderConfig() {
  // Default to Mistral (free tier) if not specified
  const providerName = (process.env.AI_PROVIDER || 'mistral').toLowerCase();
  const config = PROVIDER_CONFIGS[providerName];

  if (!config) {
    throw new Error(
      `Unknown AI provider: ${providerName}. ` +
      `Supported: ${Object.keys(PROVIDER_CONFIGS).join(', ')}`
    );
  }

  // Check for API key
  const apiKey = config.envKey ? process.env[config.envKey] : null;
  if (config.envKey && !apiKey) {
    throw new Error(
      `Missing API key for ${providerName}. ` +
      `Set ${config.envKey} in your .env file. ` +
      (config.notes || '')
    );
  }

  // Warn if using DeepSeek direct
  if (providerName === 'deepseek') {
    console.warn(
      '⚠️  WARNING: Using DeepSeek direct API. Data is sent to China with government access. ' +
      'Consider using AI_PROVIDER=deepinfra or AI_PROVIDER=together instead.'
    );
  }

  return {
    name: providerName,
    ...config,
    apiKey,
    model: process.env.AI_MODEL || config.defaultModel,
  };
}

/**
 * OpenAI-compatible chat completion
 * Works with: Mistral, DeepInfra, OpenRouter, Together, Groq, OpenAI, Fireworks
 */
async function openaiCompatibleCompletion(config, messages, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(config.apiKey && { 'Authorization': `Bearer ${config.apiKey}` }),
  };

  // OpenRouter requires additional headers
  if (config.name === 'openrouter') {
    headers['HTTP-Referer'] = process.env.APP_URL || 'http://localhost:3001';
    headers['X-Title'] = 'Task Lob';
  }

  const response = await fetch(`${config.baseUrl}/chat/completions`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      model: options.model || config.model,
      messages,
      temperature: options.temperature ?? 0.3,
      max_tokens: options.maxTokens ?? 2000,
      ...(options.jsonMode && { response_format: { type: 'json_object' } }),
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`${config.name} API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return data.choices[0]?.message?.content;
}

/**
 * Anthropic Claude chat completion
 */
async function anthropicCompletion(config, messages, options = {}) {
  const systemMessage = messages.find(m => m.role === 'system');
  const userMessages = messages.filter(m => m.role !== 'system');

  const response = await fetch(`${config.baseUrl}/messages`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: options.model || config.model,
      max_tokens: options.maxTokens ?? 2000,
      ...(systemMessage && { system: systemMessage.content }),
      messages: userMessages.map(m => ({
        role: m.role === 'assistant' ? 'assistant' : 'user',
        content: m.content,
      })),
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Anthropic API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return data.content[0]?.text;
}

/**
 * Google Gemini chat completion
 */
async function geminiCompletion(config, messages, options = {}) {
  const systemMessage = messages.find(m => m.role === 'system');
  const userMessages = messages.filter(m => m.role !== 'system');

  const contents = userMessages.map(m => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const url = `${config.baseUrl}/models/${options.model || config.model}:generateContent?key=${config.apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents,
      ...(systemMessage && {
        systemInstruction: { parts: [{ text: systemMessage.content }] },
      }),
      generationConfig: {
        temperature: options.temperature ?? 0.3,
        maxOutputTokens: options.maxTokens ?? 2000,
        ...(options.jsonMode && { responseMimeType: 'application/json' }),
      },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Gemini API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return data.candidates[0]?.content?.parts[0]?.text;
}

/**
 * Main completion function - routes to appropriate provider
 *
 * @param {Array} messages - Array of {role, content} messages
 * @param {Object} options - Optional settings
 * @param {string} options.model - Override model
 * @param {number} options.temperature - Temperature (0-1)
 * @param {number} options.maxTokens - Max tokens to generate
 * @param {boolean} options.jsonMode - Request JSON output
 * @param {string} options.taskType - Task type for potential routing ('logic', 'creative', 'archival')
 * @returns {Promise<string>} - The completion text
 */
export async function completion(messages, options = {}) {
  const config = getProviderConfig();

  switch (config.type) {
    case 'openai-compatible':
      return openaiCompatibleCompletion(config, messages, options);
    case 'anthropic':
      return anthropicCompletion(config, messages, options);
    case 'gemini':
      return geminiCompletion(config, messages, options);
    default:
      throw new Error(`Unknown provider type: ${config.type}`);
  }
}

/**
 * JSON completion - parses response as JSON
 *
 * @param {Array} messages - Array of {role, content} messages
 * @param {Object} options - Optional settings
 * @returns {Promise<Object>} - Parsed JSON response
 */
export async function jsonCompletion(messages, options = {}) {
  // Ensure system prompt mentions JSON for providers that require it
  const systemIdx = messages.findIndex(m => m.role === 'system');
  if (systemIdx >= 0 && !messages[systemIdx].content.toLowerCase().includes('json')) {
    messages[systemIdx].content += '\n\nRespond with valid JSON.';
  }

  const response = await completion(messages, { ...options, jsonMode: true });

  try {
    return JSON.parse(response);
  } catch (e) {
    // Some providers might wrap JSON in markdown code blocks
    const jsonMatch = response.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[1].trim());
    }
    throw new Error(`Failed to parse JSON response: ${e.message}`);
  }
}

/**
 * Get current provider info (for debugging/display)
 */
export function getProviderInfo() {
  try {
    const config = getProviderConfig();
    return {
      provider: config.name,
      model: config.model,
      type: config.type,
      hasKey: !!config.apiKey,
      notes: config.notes || null,
    };
  } catch (e) {
    return { error: e.message };
  }
}

/**
 * List available providers with recommendations
 */
export function listProviders() {
  return Object.entries(PROVIDER_CONFIGS).map(([name, config]) => ({
    name,
    type: config.type,
    defaultModel: config.defaultModel,
    envKey: config.envKey,
    configured: config.envKey ? !!process.env[config.envKey] : true,
    notes: config.notes || null,
    recommended: ['mistral', 'deepinfra', 'together', 'openrouter'].includes(name),
  }));
}
