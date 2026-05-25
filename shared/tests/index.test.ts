import { describe, expect, it } from "vitest";
import type { AppHelloResponse } from "../src/index";

describe("shared contracts", () => {
  it("supports app hello response shape", () => {
    const sample: AppHelloResponse = {
      ok: true,
      service: "app",
      message: "hello",
      identity: {
        username: "user@example.org",
        roles: ["user"]
      }
    };

    expect(sample.ok).toBe(true);
    expect(sample.identity.roles).toContain("user");
  });
});
