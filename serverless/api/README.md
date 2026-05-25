# api service

REST API intended for third-party consumers.

## Responsibilities

- API key + usage plan protected REST endpoints
- Separate domain surface from app HTTP API (`api` / `api-dev`)
- Demonstrate constrained testing usage plan defaults

## Structure

- `src/components`: reusable business logic and authz presets
- `src/handlers`: handler logic
- `handlers`: thin export wrappers for Serverless
- `tests`: unit/component tests
