# Frontend

Vite + React + TypeScript application deployed to S3 + CloudFront.

## What It Demonstrates

- Cognito sign-in
- Role-aware UI (`admin` vs `user`)
- HTTP call to `app-api`
- WebSocket subscription to `app-ws`
- DynamoDB-backed hello message flow via backend

## Environment Variables

Required for build/runtime:

- `VITE_APP_API_URL`
- `VITE_APP_WS_URL`
- `VITE_COGNITO_USER_POOL_ID`
- `VITE_COGNITO_APP_CLIENT_ID`
- `VITE_AWS_REGION`

## Commands

```bash
npm run dev --workspace @serverless-app-template/frontend
npm run lint --workspace @serverless-app-template/frontend
npm run typecheck --workspace @serverless-app-template/frontend
npm run test --workspace @serverless-app-template/frontend
npm run build --workspace @serverless-app-template/frontend
```
