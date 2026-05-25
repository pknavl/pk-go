import { getApiHealth } from "../components/health-service";

export async function healthHandler() {
  return {
    statusCode: 200,
    headers: {
      "content-type": "application/json"
    },
    body: JSON.stringify(getApiHealth())
  };
}
