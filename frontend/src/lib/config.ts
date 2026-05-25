export interface FrontendConfig {
  appApiUrl: string;
  appWsUrl: string;
  userPoolId: string;
  appClientId: string;
  region: string;
}

export function getConfig(): FrontendConfig {
  return {
    appApiUrl: import.meta.env.VITE_APP_API_URL ?? "",
    appWsUrl: import.meta.env.VITE_APP_WS_URL ?? "",
    userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID ?? "",
    appClientId: import.meta.env.VITE_COGNITO_APP_CLIENT_ID ?? "",
    region: import.meta.env.VITE_AWS_REGION ?? "us-east-2"
  };
}
