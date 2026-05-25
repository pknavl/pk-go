# infra service

Shared serverless-managed infrastructure for application services.

## Responsibilities

- Create app DynamoDB single-table starter
- Create ws connections table used by websocket service and broadcaster
- Export table names for dependent services

This service must deploy before `app`, `ws`, and `api`.
