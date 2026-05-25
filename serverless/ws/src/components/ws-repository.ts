import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DeleteCommand, DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const CONNECTIONS_TABLE_NAME = process.env.WS_CONNECTIONS_TABLE_NAME;

if (!CONNECTIONS_TABLE_NAME) {
  throw new Error("WS_CONNECTIONS_TABLE_NAME is required");
}

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

export async function saveConnection(input: {
  connectionId: string;
  username: string;
  connectedAt: string;
  ttl: number;
}) {
  await ddb.send(
    new PutCommand({
      TableName: CONNECTIONS_TABLE_NAME,
      Item: {
        connectionId: input.connectionId,
        username: input.username,
        connectedAt: input.connectedAt,
        ttl: input.ttl
      }
    })
  );
}

export async function deleteConnection(connectionId: string) {
  await ddb.send(
    new DeleteCommand({
      TableName: CONNECTIONS_TABLE_NAME,
      Key: {
        connectionId
      }
    })
  );
}
