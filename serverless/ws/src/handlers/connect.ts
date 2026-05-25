import type { APIGatewayProxyWebsocketEventV2 } from "aws-lambda";
import { verifyWebSocketIdentity } from "../components/auth";
import { saveConnection } from "../components/ws-repository";

const ONE_DAY_SECONDS = 24 * 60 * 60;

export async function connectHandler(event: APIGatewayProxyWebsocketEventV2) {
  try {
    const identity = await verifyWebSocketIdentity(event);
    const connectionId = event.requestContext.connectionId;

    if (!connectionId) {
      return {
        statusCode: 400,
        body: "Missing connection id"
      };
    }

    const now = new Date();
    const ttl = Math.floor(now.getTime() / 1000) + ONE_DAY_SECONDS;

    await saveConnection({
      connectionId,
      username: identity.username,
      connectedAt: now.toISOString(),
      ttl
    });

    return {
      statusCode: 200,
      body: "connected"
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      statusCode: 401,
      body: message
    };
  }
}
