export interface AppHelloResponse {
  ok: true;
  service: "app";
  message: string;
  identity: {
    username: string;
    roles: Array<"admin" | "user">;
  };
  item?: {
    id: string;
    createdAt: string;
    message: string;
  };
}

export interface AppHelloRequest {
  message: string;
}

export async function postHello(input: {
  baseUrl: string;
  token: string;
  body: AppHelloRequest;
}): Promise<AppHelloResponse> {
  const response = await fetch(`${input.baseUrl}/hello`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${input.token}`
    },
    body: JSON.stringify(input.body)
  });

  if (!response.ok) {
    throw new Error(`POST /hello failed (${response.status})`);
  }

  return (await response.json()) as AppHelloResponse;
}

export async function getLatestHello(input: {
  baseUrl: string;
  token: string;
}): Promise<AppHelloResponse> {
  const response = await fetch(`${input.baseUrl}/hello/latest`, {
    method: "GET",
    headers: {
      authorization: `Bearer ${input.token}`
    }
  });

  if (!response.ok) {
    throw new Error(`GET /hello/latest failed (${response.status})`);
  }

  return (await response.json()) as AppHelloResponse;
}

export async function getMe(input: {
  baseUrl: string;
  token: string;
}): Promise<{ ok: true; identity: { username: string; roles: Array<"admin" | "user"> } }> {
  const response = await fetch(`${input.baseUrl}/me`, {
    method: "GET",
    headers: {
      authorization: `Bearer ${input.token}`
    }
  });

  if (!response.ok) {
    throw new Error(`GET /me failed (${response.status})`);
  }

  return (await response.json()) as { ok: true; identity: { username: string; roles: Array<"admin" | "user"> } };
}

export async function getAdminPanel(input: {
  baseUrl: string;
  token: string;
}): Promise<{ ok: true; panel: string; identity: { username: string; roles: Array<"admin" | "user"> } }> {
  const response = await fetch(`${input.baseUrl}/admin`, {
    method: "GET",
    headers: {
      authorization: `Bearer ${input.token}`
    }
  });

  if (!response.ok) {
    throw new Error(`GET /admin failed (${response.status})`);
  }

  return (await response.json()) as {
    ok: true;
    panel: string;
    identity: { username: string; roles: Array<"admin" | "user"> };
  };
}
