# ws service

WebSocket API for browser push flow.

## Responsibilities

- Validate Cognito token on `$connect`
- Persist active connection ids in DynamoDB
- Remove connection ids on `$disconnect`
- Provide broadcast substrate for `app` service via management API

## Structure

- `src/components`: core logic
- `src/handlers`: handler implementations
- `handlers`: thin export wrappers for Serverless
- `tests`: unit/component tests
