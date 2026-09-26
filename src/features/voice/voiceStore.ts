/// Voice store — port of `lib/features/voice/providers/voice_provider.dart`.
///
/// Speech recognition requires native platform channels (speech_to_text).
/// In this React Native port the native module is behind a capability check:
/// when STT is unavailable (web preview, or the module is not installed in a
/// bare build) the store reports it and the UI falls back to typed input.
/// Text-to-speech works via `expo-speech` on all platforms.

import { create } from "zustand";
import * as Speech from "expo-speech";

import { ApiEndpoints } from "../../core/config/apiEndpoints";
import { apiErrorMessage, isAppApiError } from "../../core/errors/appErrors";
import { buildAgentRequestContext, agentContextPayload, FarmContext } from "../../core/models/requestContext";
import { MarkdownUtils } from "../../core/utils/markdownUtils";
import { ApiClient } from "../../core/services/apiClient";
import { AppLocation, DEFAULT_LOCATION } from "../location/locationStore";
import { DEFAULT_FARM_PROFILE, FarmProfile } from "../farm/models/farmProfile";
import { mapBackendAnswer, VoiceResponse } from "./mappers/voiceResponseMapper";

export enum VoiceStatus {
  Idle = "idle",
  Listening = "listening",
  Processing = "processing",
  Speaking = "speaking",
  Done = "done",
  Error = "error",
}

export interface VoiceState {
  status: VoiceStatus;
  transcript: string;
  response: VoiceResponse | null;
  errorMessage: string | null;
}

export interface VoiceContext {
  language: string;
  userPersona: string;
  ttsVoiceLocale: string;
  ttsSpeed: number;
  location: AppLocation;
  profile: FarmProfile;
}

export const DEFAULT_VOICE_CONTEXT: VoiceContext = {
  language: "en",
  userPersona: "everyone",
  ttsVoiceLocale: "en-US",
  ttsSpeed: 0.85,
  location: DEFAULT_LOCATION,
  profile: DEFAULT_FARM_PROFILE,
};

/// True when speech recognition can run on this platform. Expo web has no
/// `speech_to_text` equivalent, so voice input gracefully degrades.
export function speechRecognitionAvailable(): boolean {
  return typeof ExpoSpeechRecognitionModule !== "undefined";
}

// Optional native module: resolved at runtime so the web bundle stays clean.
declare const ExpoSpeechRecognitionModule: Record<string, unknown> | undefined;

const STT_LOCALES: Record<string, string> = {
  en: "en_US", hi: "hi_IN", gu: "gu_IN", mr: "mr_IN", ta: "ta_IN",
  te: "te_IN", kn: "kn_IN", ml: "ml_IN", bn: "bn_IN", pa: "pa_IN",
};

interface VoiceStore extends VoiceState {
  generation: number;
  context: VoiceContext;
  silenceTimer: ReturnType<typeof setTimeout> | null;
  setContext: (context: VoiceContext) => void;
  startListening: () => Promise<void>;
  stopListening: () => Promise<void>;
  submitQuery: (text: string) => Promise<void>;
  speak: (text: string) => Promise<void>;
  stopSpeaking: () => void;
  cancel: () => void;
}

function sttLocale(language: string): string {
  return STT_LOCALES[language.toLowerCase()] ?? "en_US";
}

export const useVoiceStore = create<VoiceStore>((set, get) => ({
  status: VoiceStatus.Idle,
  transcript: "",
  response: null,
  errorMessage: null,
  generation: 0,
  context: DEFAULT_VOICE_CONTEXT,
  silenceTimer: null,

  setContext: (context) => set({ context }),

  startListening: async () => {
    set({ status: VoiceStatus.Processing, errorMessage: null });
    try {
      if (!speechRecognitionAvailable()) {
        set({
          status: VoiceStatus.Error,
          errorMessage: "Speech recognition is not available here. You can still type a question.",
        });
        return;
      }
      const recognition = ExpoSpeechRecognitionModule as {
        start: (opts: Record<string, unknown>) => Promise<void>;
        stop: () => Promise<void>;
        onresult: ((event: { results: Array<Array<{ transcript: string }>>; isFinal: boolean }) => void) | undefined;
      };
      recognition.onresult = (event) => {
        const transcript = event.results?.[0]?.[0]?.transcript ?? "";
        set({ transcript });
        get().silenceTimer && clearTimeout(get().silenceTimer!);
        set({ silenceTimer: setTimeout(() => void get().stopListening(), 2500) });
      };
      set({ status: VoiceStatus.Listening });
      await recognition.start({
        lang: sttLocale(get().context.language),
        interimResults: true,
        continuous: false,
      });
      get().silenceTimer && clearTimeout(get().silenceTimer!);
      set({ silenceTimer: setTimeout(() => void get().stopListening(), 2500) });
    } catch {
      set({ status: VoiceStatus.Error, errorMessage: "Could not start listening. Please try again." });
    }
  },

  stopListening: async () => {
    if (get().status !== VoiceStatus.Listening) return;
    if (get().silenceTimer !== null) clearTimeout(get().silenceTimer!);
    try {
      if (speechRecognitionAvailable()) {
        await (ExpoSpeechRecognitionModule as { stop: () => Promise<void> }).stop();
      }
    } catch {
      // ignore
    }
    set({ status: VoiceStatus.Processing });
    await get().submitQuery(get().transcript);
  },

  submitQuery: async (text) => {
    if (get().silenceTimer !== null) clearTimeout(get().silenceTimer!);
    set({ status: VoiceStatus.Processing, transcript: text });
    const generation = get().generation + 1;
    set({ generation });
    try {
      const context = get().context;
      const transcript = get().transcript.trim();
      if (transcript === "") {
        set({ status: VoiceStatus.Error, errorMessage: "No speech detected. Try again or pick a suggestion." });
        return;
      }

      // Validated mode plus the user's real farm profile, built by the same
      // helper the chat surface uses so both send identical context.
      const requestContext = buildAgentRequestContext({
        profilePersona: context.userPersona,
        farm: {
          crop: context.profile.crop,
          growthStage: context.profile.growthStage,
          soilType: context.profile.soilType,
          irrigationType: context.profile.irrigationType,
        } satisfies FarmContext,
      });

      // Always use /chat — /voice multipart is optional and often unavailable.
      const postChat = (msg: string) =>
        ApiClient.post(ApiEndpoints.chat, {
          message: msg,
          location: context.location.name,
          lat: context.location.lat,
          lon: context.location.lon,
          language: context.language,
          ...agentContextPayload(requestContext),
        });

      let result = await postChat(transcript);
      let responseText = typeof result["response"] === "string" ? result["response"] : "";
      // Backend sometimes returns a generic empty-fail; retry with a simpler weather ask.
      if (responseText.toLowerCase().includes("couldn't fetch live weather")) {
        const city = context.location.name.split(",")[0]!.trim();
        const simplified = `What is the weather forecast for ${city} including rain chances tomorrow?`;
        try {
          const retryResult = await postChat(simplified);
          const retry = typeof retryResult["response"] === "string" ? retryResult["response"] : "";
          if (retry !== "" && !retry.toLowerCase().includes("couldn't fetch live weather")) {
            result = retryResult;
            responseText = retry;
          }
        } catch {
          // keep first response
        }
      }
      // A newer question superseded this one: never render the stale answer.
      if (generation !== get().generation) return;
      set({
        status: VoiceStatus.Done,
        response: mapBackendAnswer(transcript, responseText, result),
      });
    } catch (error) {
      if (generation !== get().generation) return;
      set({
        status: VoiceStatus.Error,
        errorMessage: isAppApiError(error) ? apiErrorMessage(error) : "WeatherGPT took too long to answer. Please try again.",
      });
    }
  },

  speak: async (text) => {
    set({ status: VoiceStatus.Speaking });
    try {
      const context = get().context;
      Speech.stop();
      const clean = MarkdownUtils.forSpeech(text);
      if (clean !== "") {
        await Speech.speak(clean, {
          language: context.ttsVoiceLocale,
          rate: Math.min(Math.max(context.ttsSpeed * 0.55, 0.25), 0.75),
        });
      }
    } catch {
      // TTS unavailable — stay silent, the text answer is still on screen.
    }
    set({ status: VoiceStatus.Done });
  },

  stopSpeaking: () => {
    Speech.stop();
  },

  cancel: () => {
    if (get().silenceTimer !== null) clearTimeout(get().silenceTimer!);
    try {
      if (speechRecognitionAvailable()) {
        void (ExpoSpeechRecognitionModule as { stop: () => Promise<void> }).stop();
      }
    } catch {
      // ignore
    }
    Speech.stop();
    set({ status: VoiceStatus.Idle, transcript: "", response: null, errorMessage: null });
  },
}));
