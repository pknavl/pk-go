# Serverless Services

This directory contains four Serverless Framework services composed together:

- `infra`: shared app resources (must deploy first)
- `app`: HTTP API for browser frontend
- `ws`: WebSocket API for browser push flow
- `api`: REST API for third-party clients

## Deployment Order

Deployment is coordinated by `serverless-compose.yml`:

1. `infra` first
2. `app`, `ws`, and `api` depend on `infra` and can deploy in parallel

## Local Commands

From repo root:

```bash
npm run compose:deploy:dev
npm run compose:deploy:prod
```

## Testing Conventions

Each service uses:

- `src/` for implementation
- `tests/` for unit/component tests
- `tests/integration/` for optional integration tests
- `handlers/` for thin Lambda wrappers
