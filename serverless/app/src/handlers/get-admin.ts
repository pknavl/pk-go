import type { APIGatewayProxyEventV2 } from "aws-lambda";
import { verifyIdentity } from "../components/auth";
import { appService } from "../components/service-factory";
import { forbidden, internalError, ok, unauthorized } from "./http";

export async function getAdminHandler(event: APIGatewayProxyEventV2) {
  try {
    const identity = await verifyIdentity(event);
    const result = await appService.getAdmin({ identity });
    return ok(result);
  } catch (error) {
    const value = error instanceof Error ? error.message : String(error);

    if (value.includes("Admin role required")) {
      return forbidden(value);
    }

    if (value.includes("Bearer") || value.includes("Token") || value.includes("JWT")) {
      return unauthorized(value);
    }

    return internalError(value);
  }
}
