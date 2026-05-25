export interface HelloWsEvent {
  type: "app.hello";
  payload: {
    message: string;
    createdAt: string;
    username: string;
  };
}

export interface WsClient {
  close(): void;
}

export function createHelloWsClient(input: {
  baseUrl: string;
  token: string;
  onEvent: (event: HelloWsEvent) => void;
  onError: (message: string) => void;
}): WsClient {
  const separator = input.baseUrl.includes("?") ? "&" : "?";
  const wsUrl = `${input.baseUrl}${separator}token=${encodeURIComponent(input.token)}`;
  const socket = new WebSocket(wsUrl);

  socket.onmessage = (event) => {
    try {
      const parsed = JSON.parse(String(event.data)) as HelloWsEvent;
      if (parsed.type === "app.hello") {
        input.onEvent(parsed);
      }
    } catch (error) {
      input.onError(error instanceof Error ? error.message : String(error));
    }
  };

  socket.onerror = () => {
    input.onError("WebSocket error");
  };

  return {
    close() {
      socket.close();
    }
  };
}
