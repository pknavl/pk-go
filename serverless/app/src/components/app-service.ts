import type {
  AppService,
  AppServiceDependencies,
  AppIdentity,
  AppHelloResponse
} from "./contracts";

function ensureMessage(input: string): string {
  const message = input.trim();
  if (message.length < 1) {
    throw new Error("Message is required");
  }

  if (message.length > 500) {
    throw new Error("Message is too long");
  }

  return message;
}

function isAdmin(identity: AppIdentity): boolean {
  return identity.roles.includes("admin");
}

export function createAppService(deps: AppServiceDependencies): AppService {
  return {
    async postHello(input): Promise<AppHelloResponse> {
      const message = ensureMessage(input.message);

      const item = await deps.helloRepository.putHello({
        username: input.identity.username,
        message
      });

      await deps.helloBroadcaster.broadcast({
        username: input.identity.username,
        message: item.message,
        createdAt: item.createdAt
      });

      return {
        ok: true,
        service: "app",
        message: `Stored message for ${input.identity.username}`,
        identity: input.identity,
        item
      };
    },

    async getLatest(input): Promise<AppHelloResponse> {
      const item = await deps.helloRepository.getLatestHello();
      return {
        ok: true,
        service: "app",
        message: item ? "Fetched latest message" : "No message found yet",
        identity: input.identity,
        item
      };
    },

    async getMe(input) {
      return {
        ok: true,
        identity: input.identity
      };
    },

    async getAdmin(input) {
      if (!isAdmin(input.identity)) {
        throw new Error("Admin role required");
      }

      return {
        ok: true,
        panel: "Admin panel response from app service",
        identity: input.identity
      };
    }
  };
}
