/**
 * Audio Transcription Service
 *
 * Uses Groq Whisper for high-accuracy batch transcription.
 * Perfect for "lobbing" - user speaks, releases, gets clean transcript.
 *
 * Groq Whisper:
 * - Same Whisper large-v3 model as OpenAI
 * - FREE tier: 14,400 requests/day
 * - ~10% word error rate - excellent for chaotic speech
 * - Batch processing = better accuracy than real-time
 */

const TRANSCRIPTION_PROVIDERS = {
  groq: {
    url: 'https://api.groq.com/openai/v1/audio/transcriptions',
    model: 'whisper-large-v3',
    envKey: 'GROQ_API_KEY',
  },
  openai: {
    url: 'https://api.openai.com/v1/audio/transcriptions',
    model: 'whisper-1', // or 'gpt-4o-transcribe' for best accuracy
    envKey: 'OPENAI_API_KEY',
  },
};

/**
 * Get transcription provider config
 */
function getTranscriptionConfig() {
  const providerName = (process.env.TRANSCRIPTION_PROVIDER || 'groq').toLowerCase();
  const config = TRANSCRIPTION_PROVIDERS[providerName];

  if (!config) {
    throw new Error(
      `Unknown transcription provider: ${providerName}. ` +
      `Supported: ${Object.keys(TRANSCRIPTION_PROVIDERS).join(', ')}`
    );
  }

  const apiKey = process.env[config.envKey];
  if (!apiKey) {
    throw new Error(
      `Missing API key for ${providerName} transcription. ` +
      `Set ${config.envKey} in your .env file.`
    );
  }

  return {
    name: providerName,
    ...config,
    apiKey,
    model: process.env.TRANSCRIPTION_MODEL || config.model,
  };
}

/**
 * Transcribe audio using Groq Whisper (or OpenAI)
 *
 * @param {Buffer|Blob} audioData - The audio file data
 * @param {string} filename - Original filename (for format detection)
 * @param {Object} options - Optional settings
 * @param {string} options.language - Language code (e.g., 'en')
 * @param {string} options.prompt - Optional context to improve accuracy
 * @returns {Promise<Object>} - { text, duration, language }
 */
export async function transcribeAudio(audioData, filename = 'audio.webm', options = {}) {
  const config = getTranscriptionConfig();

  // Create form data for multipart upload
  const formData = new FormData();

  // Handle both Buffer and Blob
  const blob = audioData instanceof Blob
    ? audioData
    : new Blob([audioData], { type: getMimeType(filename) });

  formData.append('file', blob, filename);
  formData.append('model', config.model);

  // Optional parameters
  if (options.language) {
    formData.append('language', options.language);
  }
  if (options.prompt) {
    formData.append('prompt', options.prompt);
  }

  // Response format - we want detailed response
  formData.append('response_format', 'verbose_json');

  const response = await fetch(config.url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${config.apiKey}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Transcription error (${config.name}): ${response.status} - ${error}`);
  }

  const result = await response.json();

  return {
    text: result.text,
    duration: result.duration,
    language: result.language,
    provider: config.name,
    model: config.model,
  };
}

/**
 * Get MIME type from filename
 */
function getMimeType(filename) {
  const ext = filename.split('.').pop()?.toLowerCase();
  const mimeTypes = {
    'mp3': 'audio/mpeg',
    'mp4': 'audio/mp4',
    'm4a': 'audio/m4a',
    'wav': 'audio/wav',
    'webm': 'audio/webm',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
  };
  return mimeTypes[ext] || 'audio/webm';
}

/**
 * Get transcription provider info
 */
export function getTranscriptionInfo() {
  try {
    const config = getTranscriptionConfig();
    return {
      provider: config.name,
      model: config.model,
      hasKey: true,
    };
  } catch (e) {
    return { error: e.message };
  }
}
