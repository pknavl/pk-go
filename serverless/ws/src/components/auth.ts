import type { APIGatewayProxyWebsocketEventV2 } from "aws-lambda";
import { CognitoJwtVerifier } from "aws-jwt-verify";

interface ConnectEvent extends APIGatewayProxyWebsocketEventV2 {
  queryStringParameters?: Record<string, string | undefined>;
}

const COGNITO_USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const COGNITO_APP_CLIENT_ID = process.env.COGNITO_APP_CLIENT_ID;

if (!COGNITO_USER_POOL_ID || !COGNITO_APP_CLIENT_ID) {
  throw new Error("COGNITO_USER_POOL_ID and COGNITO_APP_CLIENT_ID are required");
}

const verifier = CognitoJwtVerifier.create({
  userPoolId: COGNITO_USER_POOL_ID,
  tokenUse: "id",
  clientId: COGNITO_APP_CLIENT_ID
});

interface VerifiedJwt {
  email?: string;
  username?: string;
  sub?: string;
}

export async function verifyWebSocketIdentity(event: ConnectEvent) {
  const token = event.queryStringParameters?.token;

  if (!token) {
    throw new Error("Missing token query parameter");
  }

  const jwt = (await verifier.verify(token)) as VerifiedJwt;

  const usernameClaim = jwt.email ?? jwt.username ?? jwt.sub;
  if (!usernameClaim) {
    throw new Error("Token missing identity claim");
  }

  return {
    username: String(usernameClaim)
  };
}
