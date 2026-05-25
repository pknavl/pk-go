import type { APIGatewayProxyEventV2 } from "aws-lambda";
import { verifyIdentity } from "../components/auth";
import { appService } from "../components/service-factory";
import { badRequest, internalError, ok, unauthorized } from "./http";

export async function postHelloHandler(event: APIGatewayProxyEventV2) {
  try {
    const identity = await verifyIdentity(event);
    const parsed = event.body ? (JSON.parse(event.body) as { message?: string }) : {};
    const message = parsed.message;

    if (!message || typeof message !== "string") {
      return badRequest("Field 'message' is required");
    }

    const result = await appService.postHello({
      identity,
      message
    });

    return ok(result);
  } catch (error) {
    const value = error instanceof Error ? error.message : String(error);

    if (value.includes("Bearer") || value.includes("Token") || value.includes("JWT")) {
      return unauthorized(value);
    }

    return internalError(value);
  }
}
