export interface ApiHealthResponse {
  ok: true;
  service: "api";
  message: string;
}

export function getApiHealth(): ApiHealthResponse {
  return {
    ok: true,
    service: "api",
    message: "Third-party REST API is healthy"
  };
}
