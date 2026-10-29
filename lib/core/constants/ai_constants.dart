/// Gemini model used for both chat and grammar checks.
///
/// Model names change often: confirm this one is still listed on the
/// Firebase AI Logic "supported models" page before release.
const kGeminiModel = 'gemini-2.5-flash';

/// Shown when Gemini returns an empty or blocked reply.
const kFallbackReply = 'Could you say that another way?';
