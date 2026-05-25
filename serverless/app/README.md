# app service

HTTP API for browser clients.

## Responsibilities

- Cognito-authorized routes for app clients
- Store and read sample hello data in DynamoDB
- Trigger ws broadcasts to connected clients
- Expose role-aware `/me` and admin-only `/admin` paths

## Structure

- `src/components`: reusable business logic and adapters
- `src/handlers`: handler logic
- `handlers`: thin export wrappers for Serverless
- `tests`: unit/component tests
