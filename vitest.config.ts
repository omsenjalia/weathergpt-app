import path from "node:path";
import { defineConfig } from "vitest/config";

// React Native / Expo ship Flow syntax and native globals that node-side
// vitest cannot parse or define. The unit tests exercise pure TypeScript
// modules only, so the RN runtime, AsyncStorage and expo-modules-core are
// aliased to lightweight stubs. `__DEV__` is defined globally below.
const rnStub = path.resolve(__dirname, "test/stubs/reactNative.ts");
const asyncStorageStub = path.resolve(__dirname, "test/stubs/asyncStorage.ts");

export default defineConfig({
  resolve: {
    alias: {
      "react-native": rnStub,
      "@react-native-async-storage/async-storage": asyncStorageStub,
      "expo-modules-core": rnStub,
      "expo-constants": rnStub,
      "expo-speech": rnStub,
    },
  },
  define: {
    __DEV__: "false",
  },
  test: {
    include: ["test/**/*.test.ts"],
    environment: "node",
  },
});
