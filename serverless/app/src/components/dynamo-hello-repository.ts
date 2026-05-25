import { randomUUID } from "node:crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import type { HelloMessage, HelloRepository } from "./contracts";

const TABLE_NAME = process.env.APP_TABLE_NAME;

if (!TABLE_NAME) {
  throw new Error("APP_TABLE_NAME is required");
}

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

export const dynamoHelloRepository: HelloRepository = {
  async putHello(input) {
    const now = new Date().toISOString();
    const id = randomUUID();

    const item = {
      PK: "HELLO",
      SK: `MSG#${now}#${id}`,
      id,
      createdAt: now,
      message: input.message,
      username: input.username
    };

    await ddb.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: item
      })
    );

    return {
      id: item.id,
      createdAt: item.createdAt,
      message: item.message
    } satisfies HelloMessage;
  },

  async getLatestHello() {
    const result = await ddb.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk",
        ExpressionAttributeValues: {
          ":pk": "HELLO"
        },
        ScanIndexForward: false,
        Limit: 1
      })
    );

    const item = result.Items?.[0];
    if (!item) {
      return undefined;
    }

    return {
      id: String(item.id),
      createdAt: String(item.createdAt),
      message: String(item.message)
    } satisfies HelloMessage;
  }
};
