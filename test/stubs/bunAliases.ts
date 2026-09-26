/// Bun `bun test` preload: redirect runtime-only modules to the same stubs
/// vitest uses (see vitest.config.ts). Implemented by registering mock modules
/// before any test file imports the store chain (farmStores → apiClient →
/// expo-constants → react-native Flow source).
// @ts-expect-error — `bun:test` types ship with the Bun runtime, not @types.
import { mock } from "bun:test";

import * as asyncStorageStub from "./asyncStorage";

mock.module("@react-native-async-storage/async-storage", () => asyncStorageStub);
mock.module("react-native", () => ({
  Platform: { OS: "web", select: (o: Record<string, unknown>) => o.web ?? o.default },
  StyleSheet: { create: <T,>(s: T): T => s, hairlineWidth: 1, absoluteFill: {}, absoluteFillObject: {} },
  View: class {},
  Text: class {},
  default: {},
}));
mock.module("expo-constants", () => ({
  default: { expoConfig: { extra: {} } },
}));
mock.module("expo-speech", () => ({
  stop: () => undefined,
  speak: async () => undefined,
}));
mock.module("expo-modules-core", () => ({ default: {} }));
