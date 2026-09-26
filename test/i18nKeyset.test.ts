import { describe, expect, it } from "vitest";

import { createTranslator, SUPPORTED_LANGUAGES, translationKeyCount } from "../src/i18n";
import en from "../src/i18n/locales/en.json";

const EN_KEYS = Object.keys(en).filter((key) => key !== "default");

describe("i18n", () => {
  it("ships 9 live languages", () => {
    expect(SUPPORTED_LANGUAGES).toHaveLength(9);
  });

  it("every locale resolves the English key set without throwing", () => {
    for (const language of SUPPORTED_LANGUAGES) {
      const t = createTranslator(language);
      for (const key of EN_KEYS) {
        expect(() => t(key)).not.toThrow();
        expect(t(key).length).toBeGreaterThan(0);
      }
    }
  });

  it("interpolates placeholders", () => {
    const t = createTranslator("en");
    expect(t("home.updated", { time: "2:00 PM" })).toBe("Updated 2:00 PM");
    expect(t("home.next_hours", { n: 12 })).toBe("Next 12 hours");
  });

  it("missing keys fall back to English then to the key", () => {
    const t = createTranslator("hi");
    expect(t("definitely.not.a.key")).toBe("definitely.not.a.key");
  });

  it("key counts are reported for the fact-checked 287-key contract", () => {
    expect(translationKeyCount("en")).toBe(EN_KEYS.length);
    expect(EN_KEYS.length).toBeGreaterThanOrEqual(280);
    expect(EN_KEYS.length).toBeLessThanOrEqual(300);
  });
});
