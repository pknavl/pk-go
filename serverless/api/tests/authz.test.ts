import { describe, expect, it } from "vitest";
import { testingUsagePlanPreset } from "../src/components/authz";

describe("api authz preset", () => {
  it("returns constrained testing plan", () => {
    const preset = testingUsagePlanPreset();
    expect(preset.name).toBe("testing");
    expect(preset.monthlyQuota).toBe(1000);
    expect(preset.rateLimit).toBe(5);
  });
});
