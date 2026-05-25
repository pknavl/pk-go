import { useEffect, useMemo, useState } from "react";
import { configureAmplify } from "./lib/amplify";
import { getConfig } from "./lib/config";
import { getAdminPanel, getLatestHello, getMe, postHello } from "./lib/api";
import type { AppHelloResponse } from "./lib/api";
import { createHelloWsClient } from "./lib/ws";
import { getSessionIdentity, loginWithPassword, logout } from "./lib/auth";
import { rolloutFeatures } from "./lib/features";

function makeId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

interface UiSession {
  username: string;
  roles: string[];
  token: string;
}

interface WsFeedItem {
  id: string;
  line: string;
}

function isAdmin(roles: string[]): boolean {
  return roles.includes("admin");
}

export function App() {
  const config = useMemo(() => getConfig(), []);

  const [username, setUsername] = useState("admin@example.org");
  const [password, setPassword] = useState("TempPassw0rd!");
  const [session, setSession] = useState<UiSession | null>(null);
  const [status, setStatus] = useState("Signed out");
  const [error, setError] = useState("");

  const [messageInput, setMessageInput] = useState("Hello from frontend");
  const [latest, setLatest] = useState<AppHelloResponse | null>(null);
  const [mePayload, setMePayload] = useState<string>("");
  const [adminPayload, setAdminPayload] = useState<string>("");

  const [wsItems, setWsItems] = useState<WsFeedItem[]>([]);

  useEffect(() => {
    configureAmplify();
  }, []);

  useEffect(() => {
    if (!session || !rolloutFeatures.websocketService || !config.appWsUrl) {
      return undefined;
    }

    const client = createHelloWsClient({
      baseUrl: config.appWsUrl,
      token: session.token,
      onEvent: (event) => {
        const line = `${event.payload.createdAt} :: ${event.payload.username} :: ${event.payload.message}`;
        setWsItems((current) => [{ id: makeId(), line }, ...current].slice(0, 20));
      },
      onError: (message) => {
        setError(message);
      }
    });

    return () => {
      client.close();
    };
  }, [session, config.appWsUrl]);

  async function handleSignIn() {
    setError("");
    setStatus("Signing in...");

    try {
      if (!rolloutFeatures.cognitoAuth) {
        throw new Error("Cognito rollout feature is disabled");
      }

      await loginWithPassword({ username, password });
      const identity = await getSessionIdentity();
      setSession(identity);
      setStatus(`Signed in as ${identity.username}`);
    } catch (value) {
      const message = value instanceof Error ? value.message : String(value);
      setError(message);
      setStatus("Sign in failed");
    }
  }

  async function handleSignOut() {
    setError("");
    await logout();
    setSession(null);
    setMePayload("");
    setAdminPayload("");
    setLatest(null);
    setWsItems([]);
    setStatus("Signed out");
  }

  async function callPostHello() {
    if (!session) {
      return;
    }

    setError("");

    try {
      const response = await postHello({
        baseUrl: config.appApiUrl,
        token: session.token,
        body: {
          message: messageInput
        }
      });
      setLatest(response);
    } catch (value) {
      setError(value instanceof Error ? value.message : String(value));
    }
  }

  async function callGetLatest() {
    if (!session) {
      return;
    }

    setError("");

    try {
      const response = await getLatestHello({
        baseUrl: config.appApiUrl,
        token: session.token
      });
      setLatest(response);
    } catch (value) {
      setError(value instanceof Error ? value.message : String(value));
    }
  }

  async function callGetMe() {
    if (!session) {
      return;
    }

    setError("");

    try {
      const response = await getMe({
        baseUrl: config.appApiUrl,
        token: session.token
      });
      setMePayload(JSON.stringify(response, null, 2));
    } catch (value) {
      setError(value instanceof Error ? value.message : String(value));
    }
  }

  async function callGetAdmin() {
    if (!session) {
      return;
    }

    setError("");

    try {
      const response = await getAdminPanel({
        baseUrl: config.appApiUrl,
        token: session.token
      });
      setAdminPayload(JSON.stringify(response, null, 2));
    } catch (value) {
      setError(value instanceof Error ? value.message : String(value));
    }
  }

  return (
    <main className="page">
      <section className="hero">
        <h1>Serverless App Template - Hello World</h1>
        <p>
          Cognito sign-in, role-aware UI, app-api HTTP calls, ws push
          updates, and DynamoDB-backed hello data.
        </p>
      </section>

      <div className="grid">
        <section className="card">
          <h2>Auth</h2>
          <p className="meta">Status: {status}</p>
          <label>
            Username
            <input value={username} onChange={(event) => setUsername(event.target.value)} />
          </label>
          <label>
            Password
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>
          <div className="row">
            <button onClick={handleSignIn}>Sign In</button>
            <button className="secondary" onClick={handleSignOut}>
              Sign Out
            </button>
          </div>
          {session ? (
            <p className="meta">
              Signed in as <strong>{session.username}</strong>
            </p>
          ) : null}
        </section>

        <section className="card">
          <h2>Identity and Roles</h2>
          {session ? (
            <>
              <p>
                <strong>{session.username}</strong>
              </p>
              <div>
                {session.roles.map((role) => (
                  <span key={role} className="pill">
                    {role}
                  </span>
                ))}
              </div>
              <div className="row identity-actions">
                <button className="secondary" onClick={callGetMe}>
                  Call /me
                </button>
              </div>
              {mePayload ? <pre>{mePayload}</pre> : null}
            </>
          ) : (
            <p className="meta">Sign in to load identity</p>
          )}
        </section>

        <section className="card wide">
          <h2>App API + DynamoDB</h2>
          <p className="meta">POST /hello stores a message and pushes to WebSocket clients.</p>

          <label>
            Message
            <textarea
              value={messageInput}
              onChange={(event) => setMessageInput(event.target.value)}
              placeholder="Type a message"
            />
          </label>

          <div className="row">
            <button onClick={callPostHello} disabled={!session}>
              POST /hello
            </button>
            <button className="secondary" onClick={callGetLatest} disabled={!session}>
              GET /hello/latest
            </button>
          </div>

          {latest ? <pre>{JSON.stringify(latest, null, 2)}</pre> : null}
        </section>

        <section className="card">
          <h2>WebSocket Feed</h2>
          <p className="meta">Listening on {config.appWsUrl || "(not configured)"}</p>
          <ul className="ws-feed">
            {wsItems.map((item) => (
              <li key={item.id}>{item.line}</li>
            ))}
          </ul>
        </section>

        <section className="card">
          <h2>Admin Panel</h2>
          <p className="meta">Visible and callable for admin role users only.</p>

          {session && isAdmin(session.roles) ? (
            <>
              <div className="row">
                <button className="warn" onClick={callGetAdmin}>
                  Call /admin
                </button>
              </div>
              {adminPayload ? <pre>{adminPayload}</pre> : null}
            </>
          ) : (
            <p className="meta">Admin group required.</p>
          )}
        </section>
      </div>

      {error ? <p className="error">{error}</p> : null}
    </main>
  );
}
