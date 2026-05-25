import { Amplify } from "aws-amplify";
import { getConfig } from "./config";

let configured = false;

export function configureAmplify() {
  if (configured) {
    return;
  }

  const config = getConfig();

  if (!config.userPoolId || !config.appClientId) {
    return;
  }

  Amplify.configure({
    Auth: {
      Cognito: {
        userPoolId: config.userPoolId,
        userPoolClientId: config.appClientId
      }
    }
  });

  configured = true;
}
