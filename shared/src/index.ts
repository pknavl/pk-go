export type Role = "admin" | "user";

export interface HelloMessage {
  id: string;
  createdAt: string;
  message: string;
}

export interface AppIdentity {
  username: string;
  roles: Role[];
}

export interface AppHelloResponse {
  ok: true;
  service: "app";
  message: string;
  identity: AppIdentity;
  item?: HelloMessage;
}

export interface AppHelloRequest {
  message: string;
}

export interface WsOutboundMessage {
  type: "app.hello";
  payload: {
    message: string;
    createdAt: string;
    username: string;
  };
}

export interface ApiHealthResponse {
  ok: true;
  service: "api";
  message: string;
}
