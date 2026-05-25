import type { APIGatewayProxyEventV2 } from "aws-lambda";
import { CognitoJwtVerifier } from "aws-jwt-verify";
import type { AppIdentity } from "./contracts";

const COGNITO_USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const COGNITO_APP_CLIENT_ID = process.env.COGNITO_APP_CLIENT_ID;

let verifier: ReturnType<typeof CognitoJwtVerifier.create> | undefined;

interface VerifiedJwt {
  email?: string;
  username?: string;
  sub?: string;
  "cognito:groups"?: string | string[];
}

function getVerifier() {
  if (!COGNITO_USER_POOL_ID || !COGNITO_APP_CLIENT_ID) {
    throw new Error("COGNITO_USER_POOL_ID and COGNITO_APP_CLIENT_ID are required");
  }

  if (!verifier) {
    verifier = CognitoJwtVerifier.create({
      userPoolId: COGNITO_USER_POOL_ID,
      tokenUse: "id",
      clientId: COGNITO_APP_CLIENT_ID
    });
  }

  return verifier;
}

function parseBearerToken(event: APIGatewayProxyEventV2): string {
  const authHeader = event.headers.authorization ?? event.headers.Authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw new Error("Missing Bearer token");
  }

  return authHeader.slice("Bearer ".length);
}

function extractRoles(payload: VerifiedJwt): Array<"admin" | "user"> {
  const groupsClaim = payload["cognito:groups"];
  const groups = Array.isArray(groupsClaim)
    ? groupsClaim
    : typeof groupsClaim === "string"
      ? [groupsClaim]
      : [];

  const roles: Array<"admin" | "user"> = [];
  for (const group of groups) {
    if (group === "admin") {
      roles.push("admin");
    }
    if (group === "user") {
      roles.push("user");
    }
  }

  if (roles.length === 0) {
    roles.push("user");
  }

  return roles;
}

export async function verifyIdentity(event: APIGatewayProxyEventV2): Promise<AppIdentity> {
  const token = parseBearerToken(event);
  const jwt = (await getVerifier().verify(token)) as VerifiedJwt;

  const usernameClaim = jwt.email ?? jwt.username ?? jwt.sub;
  if (!usernameClaim) {
    throw new Error("Token does not include a usable identity claim");
  }

  const username = String(usernameClaim);

  return {
    username,
    roles: extractRoles(jwt)
  };
}
