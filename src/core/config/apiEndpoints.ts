/// Every backend path the app calls — port of
/// `lib/core/constants/api_endpoints.dart`. Legacy paths stay version-less for
/// backward compatibility. Backend v3: IMD → WeatherNext → Open-Meteo, official alerts.

export const ApiEndpoints = {
  chat: "/chat",
  weather: "/weather",
  health: "/health",
  diagnostics: "/dev",
  sandbox: "/dev/sandbox",
  advisory: "/advisory",
  historical: "/historical",
  comparison: "/comparison",

  // WeatherNext v2 (backend v2.1.0+)
  v2Weather: "/v2/weather",
  v2WeatherHealth: "/v2/weather/health",
  v2WeatherCatalog: "/v2/weather/catalog",
  v2WeatherSeries: "/v2/weather/series",
  v2Alerts: "/v2/alerts",

  // Bhashini speech (backend proxies MeitY ULCA; keys stay server-side)
  speechHealth: "/v2/speech/health",
  speechTts: "/v2/speech/tts",
  speechAsr: "/v2/speech/asr",
} as const;
