import type { APIGatewayProxyWebsocketEventV2 } from "aws-lambda";
import { deleteConnection } from "../components/ws-repository";

export async function disconnectHandler(event: APIGatewayProxyWebsocketEventV2) {
  const connectionId = event.requestContext.connectionId;

  if (!connectionId) {
    return {
      statusCode: 200,
      body: "ok"
    };
  }

  await deleteConnection(connectionId);

  return {
    statusCode: 200,
    body: "disconnected"
  };
}
