import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";
import type { HelloBroadcaster } from "./contracts";

const CONNECTIONS_TABLE_NAME = process.env.WS_CONNECTIONS_TABLE_NAME;
const WS_MANAGEMENT_ENDPOINT = process.env.WS_MANAGEMENT_ENDPOINT;

const hasWsBroadcastConfig =
  typeof CONNECTIONS_TABLE_NAME === "string" &&
  CONNECTIONS_TABLE_NAME.length > 0 &&
  typeof WS_MANAGEMENT_ENDPOINT === "string" &&
  WS_MANAGEMENT_ENDPOINT.length > 0;

const ddb = hasWsBroadcastConfig ? DynamoDBDocumentClient.from(new DynamoDBClient({})) : undefined;
const wsClient = hasWsBroadcastConfig
  ? new ApiGatewayManagementApiClient({
      endpoint: WS_MANAGEMENT_ENDPOINT
    })
  : undefined;

export const wsBroadcaster: HelloBroadcaster = {
  async broadcast(input) {
    if (!hasWsBroadcastConfig || !ddb || !wsClient || !CONNECTIONS_TABLE_NAME) {
      return;
    }

    const scan = await ddb.send(
      new ScanCommand({
        TableName: CONNECTIONS_TABLE_NAME,
        ProjectionExpression: "connectionId"
      })
    );

    const connections = (scan.Items ?? [])
      .map((item) => item.connectionId)
      .filter((value): value is string => typeof value === "string" && value.length > 0);

    if (connections.length === 0) {
      return;
    }

    const data = JSON.stringify({
      type: "app.hello",
      payload: {
        message: input.message,
        createdAt: input.createdAt,
        username: input.username
      }
    });

    await Promise.allSettled(
      connections.map((connectionId) =>
        wsClient.send(
          new PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: Buffer.from(data)
          })
        )
      )
    );
  }
};
