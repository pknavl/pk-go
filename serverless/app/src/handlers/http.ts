import type { APIGatewayProxyStructuredResultV2 } from "aws-lambda";

export function ok(body: unknown): APIGatewayProxyStructuredResultV2 {
  return {
    statusCode: 200,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify(body)
  };
}

export function badRequest(message: string): APIGatewayProxyStructuredResultV2 {
  return {
    statusCode: 400,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify({ error: message })
  };
}

export function unauthorized(message: string): APIGatewayProxyStructuredResultV2 {
  return {
    statusCode: 401,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify({ error: message })
  };
}

export function forbidden(message: string): APIGatewayProxyStructuredResultV2 {
  return {
    statusCode: 403,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify({ error: message })
  };
}

export function internalError(message: string): APIGatewayProxyStructuredResultV2 {
  return {
    statusCode: 500,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify({ error: message })
  };
}
