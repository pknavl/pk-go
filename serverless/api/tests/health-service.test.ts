import { describe, expect, it } from "vitest";
import { getApiHealth } from "../src/components/health-service";

describe("api health service", () => {
  it("returns health payload", () => {
    const result = getApiHealth();
    expect(result.ok).toBe(true);
    expect(result.service).toBe("api");
  });
});
