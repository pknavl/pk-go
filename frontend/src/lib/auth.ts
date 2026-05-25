import { fetchAuthSession, signIn, signOut } from "aws-amplify/auth";

export interface SessionIdentity {
  username: string;
  roles: string[];
  token: string;
}

export async function loginWithPassword(input: { username: string; password: string }) {
  const result = await signIn({
    username: input.username,
    password: input.password
  });

  return result;
}

export async function logout() {
  await signOut();
}

export async function getSessionIdentity(): Promise<SessionIdentity> {
  const session = await fetchAuthSession();
  const idToken = session.tokens?.idToken?.toString();

  if (!idToken) {
    throw new Error("No active Cognito ID token found");
  }

  const payload = session.tokens?.idToken?.payload;
  const username = String(payload?.email ?? payload?.username ?? payload?.sub ?? "unknown");

  const groupsRaw = payload?.["cognito:groups"];
  const roles = Array.isArray(groupsRaw)
    ? groupsRaw.map((value) => String(value))
    : typeof groupsRaw === "string"
      ? [groupsRaw]
      : ["user"];

  return {
    username,
    roles,
    token: idToken
  };
}
