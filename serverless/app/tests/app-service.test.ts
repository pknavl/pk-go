import { describe, expect, it, vi } from "vitest";
import { createAppService } from "../src/components/app-service";

describe("app service", () => {
  it("stores and broadcasts hello message", async () => {
    const putHello = vi.fn(async () => ({
      id: "1",
      createdAt: "2026-01-01T00:00:00.000Z",
      message: "hello"
    }));

    const getLatestHello = vi.fn(async () => undefined);
    const broadcast = vi.fn(async () => undefined);

    const service = createAppService({
      helloRepository: { putHello, getLatestHello },
      helloBroadcaster: { broadcast }
    });

    const result = await service.postHello({
      identity: {
        username: "user@example.org",
        roles: ["user"]
      },
      message: "hello"
    });

    expect(result.ok).toBe(true);
    expect(putHello).toHaveBeenCalledOnce();
    expect(broadcast).toHaveBeenCalledOnce();
  });

  it("rejects admin endpoint for non-admin", async () => {
    const service = createAppService({
      helloRepository: {
        putHello: vi.fn(async () => ({ id: "1", createdAt: "", message: "" })),
        getLatestHello: vi.fn(async () => undefined)
      },
      helloBroadcaster: {
        broadcast: vi.fn(async () => undefined)
      }
    });

    await expect(
      service.getAdmin({
        identity: {
          username: "user@example.org",
          roles: ["user"]
        }
      })
    ).rejects.toThrow("Admin role required");
  });
});
