# pk-go

A reusable TypeScript template for bootstrapping AWS serverless applications with Terraform, Serverless Framework, Vite/React, and GitHub Actions.

This template is designed so you can:

- create org/dev/prod AWS accounts,
- run minimal one-time backend bootstrap prerequisites,
- run bootstrap prerequisites and bootstrap Terraform locally, then use regular GitHub workflows for ongoing Terraform/deploy,
- configure GitHub Actions OIDC role ARNs as repository variables,
- merge to `main` and get a working end-to-end platform quickly.

## What This Template Includes

- Multi-account AWS setup model (`org`, `dev`, `prod`)
- Route53 hosted zone in `org` account (manual hosted zone creation)
- Cross-account Route53 management role created in `org` Terraform
- Prerequisites script (`scripts/bootstrap-account.sh`) for Terraform state bucket + lock table
- Terraform layout:
  - `infra/terraform/bootstrap` (per-account bootstrap baseline)
  - `infra/terraform/org` (org-level DNS role and metadata)
  - `infra/terraform/dev`, `infra/terraform/prod` (env baseline + frontend + Cognito)
  - `infra/terraform/main` (shared module)
- Serverless Compose with four services:
  - `serverless/infra` (shared app resources)
  - `serverless/app` (HTTP API for browser app)
  - `serverless/ws` (WebSocket API)
  - `serverless/api` (REST API for third parties)
- Frontend app (`frontend`) using Vite + React + TypeScript
- Cognito user pool, app client, and `admin` / `user` groups
- Single-table DynamoDB starter table
- API key + usage plan for third-party REST API
- GitHub Actions workflows for PR checks, automated deploys, and manual deploy
- Root `AGENTS.md` for LLM coding agents

## URL Layout

Expected DNS pattern:

- `domain.tld` -> marketing site placeholder (apex)
- `app.domain.tld` -> prod app frontend
- `app-dev.domain.tld` -> dev app frontend
- `app-api.domain.tld` -> prod app HTTP API
- `app-api-dev.domain.tld` -> dev app HTTP API
- `api.domain.tld` -> prod third-party REST API
- `api-dev.domain.tld` -> dev third-party REST API
- `app-ws.domain.tld` -> prod WebSocket API
- `app-ws-dev.domain.tld` -> dev WebSocket API

## Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── frontend/
├── infra/
│   └── terraform/
│       ├── bootstrap/
│       ├── dev/
│       ├── main/
│       ├── org/
│       └── prod/
├── scripts/
├── serverless/
│   ├── api/
│   ├── app/
│   ├── infra/
│   ├── ws/
│   └── serverless-compose.yml
└── shared/
```

## Testing Convention

This template uses `src/` and `tests/` as sibling directories across packages.

- `src/` contains implementation.
- `tests/` contains unit/component tests.
- `tests/integration/` is reserved for integration-level tests when needed.

Lambda handlers are intentionally thin wrappers; most tests should focus on reusable components.

## Prerequisites

- Node.js 20+
- npm 10+
- Terraform 1.6+
- AWS CLI v2
- `jq`

## Manual Setup (One Time)

### 1) Create AWS Accounts

Create and secure:

- `org`
- `dev`
- `prod`

### 2) Create Route53 Hosted Zone in Org Account

- Create hosted zone for your domain in org account.
- Point registrar nameservers to the hosted zone.

### 3) Run Prerequisites Script per Account

Run this once in each account context/profile:

```bash
scripts/bootstrap-account.sh --account org --project serverless-app-template --region us-east-2
scripts/bootstrap-account.sh --account dev --project serverless-app-template --region us-east-2
scripts/bootstrap-account.sh --account prod --project serverless-app-template --region us-east-2
```

This creates only:

- Terraform state bucket
- Terraform lock table

### 4) Bootstrap Terraform in Each Account

Run `infra/terraform/bootstrap` once per account (switch AWS credentials/profile each time).

This is a local setup stage. Do not run bootstrap Terraform in GitHub Actions.
After local bootstrap + initial org/env applies complete, regular updates should go through GitHub Actions workflows.

Example for dev:

```bash
terraform -chdir=infra/terraform/bootstrap init \
  -backend-config="bucket=serverless-app-template-dev-tf-state" \
  -backend-config="key=terraform/bootstrap-dev.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="dynamodb_table=serverless-app-template-dev-tf-locks" \
  -backend-config="encrypt=true"

terraform -chdir=infra/terraform/bootstrap apply \
  -var "project_name=serverless-app-template" \
  -var "account_name=dev" \
  -var "region=us-east-2" \
  -var "github_owner=<your-github-owner>" \
  -var "github_repo=<your-repo-name>"

Repeat for org/prod with the correct `account_name` and backend config key.

For dev/prod bootstrap apply, include org role ARN once org Terraform has been applied:

```bash
terraform -chdir=infra/terraform/bootstrap apply \
  -var "project_name=serverless-app-template" \
  -var "account_name=dev" \
  -var "region=us-east-2" \
  -var "github_owner=<your-github-owner>" \
  -var "github_repo=<your-repo-name>" \
  -var "org_route53_role_arn=arn:aws:iam::<ORG_ACCOUNT_ID>:role/serverless-app-template-route53-manager"
```

Run similarly for `org` and `prod` (`account_name=org` / `prod`).

### 5) Apply Org Terraform

After org bootstrap role is available:

```bash
terraform -chdir=infra/terraform/org init \
  -backend-config="bucket=serverless-app-template-org-tf-state" \
  -backend-config="key=terraform/org.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="dynamodb_table=serverless-app-template-org-tf-locks" \
  -backend-config="encrypt=true"

terraform -chdir=infra/terraform/org apply \
  -var "project_name=serverless-app-template" \
  -var "domain=<domain.tld>" \
  -var "zone_id=<hosted-zone-id>" \
  -var 'trusted_role_arns=["arn:aws:iam::<DEV_ACCOUNT_ID>:role/serverless-app-template-dev-github-deploy","arn:aws:iam::<PROD_ACCOUNT_ID>:role/serverless-app-template-prod-github-deploy"]'
```

### 6) Apply Env Terraform (dev, then prod)

```bash
terraform -chdir=infra/terraform/dev init \
  -backend-config="bucket=serverless-app-template-dev-tf-state" \
  -backend-config="key=terraform/dev.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="dynamodb_table=serverless-app-template-dev-tf-locks" \
  -backend-config="encrypt=true"

terraform -chdir=infra/terraform/dev apply \
  -var "project_name=serverless-app-template" \
  -var "domain=<domain.tld>" \
  -var "zone_id=<hosted-zone-id>" \
  -var "org_route53_role_arn=arn:aws:iam::<ORG_ACCOUNT_ID>:role/serverless-app-template-route53-manager"
```

Repeat for prod (`infra/terraform/prod`).

### 7) Configure Role ARN Variables for GitHub Actions

After local bootstrap and org apply, set the role-ARN variables that regular workflows use:

- `ORG_DEPLOY_ROLE_ARN=arn:aws:iam::<ORG_ACCOUNT_ID>:role/serverless-app-template-org-github-deploy`
- `DEV_DEPLOY_ROLE_ARN=arn:aws:iam::<DEV_ACCOUNT_ID>:role/serverless-app-template-dev-github-deploy`
- `PROD_DEPLOY_ROLE_ARN=arn:aws:iam::<PROD_ACCOUNT_ID>:role/serverless-app-template-prod-github-deploy`
- `ORG_ROUTE53_ROLE_ARN=<output org_route53_role_arn from infra/terraform/org>`

## GitHub Variables

Set repository variables:

- `AWS_REGION` (example `us-east-2`)
- `PROJECT_SLUG` (required; no default)
- `DOMAIN` (example `example.org`)
- `ROUTE53_ZONE_ID` (hosted zone id in org account)
- `ORG_DEPLOY_ROLE_ARN` (example `arn:aws:iam::<ORG_ACCOUNT_ID>:role/serverless-app-template-org-github-deploy`)
- `DEV_DEPLOY_ROLE_ARN` (example `arn:aws:iam::<DEV_ACCOUNT_ID>:role/serverless-app-template-dev-github-deploy`)
- `PROD_DEPLOY_ROLE_ARN` (example `arn:aws:iam::<PROD_ACCOUNT_ID>:role/serverless-app-template-prod-github-deploy`)
- `ORG_ROUTE53_ROLE_ARN` (example `arn:aws:iam::<ORG_ACCOUNT_ID>:role/serverless-app-template-route53-manager`)
- `AWS_SIGNIN_START_URL` (optional; set only when using aws.<domain> redirect feature)

Optional but recommended:

- `GITHUB_OWNER_OVERRIDE` (if repository owner differs from deploy trust target)

Optional deployment branches:

- `main` for dev deploys (automatic)
- `live` for prod deploys (automatic)

No long-lived AWS secrets are required. Workflows use GitHub OIDC to assume roles provided through repository variables.

## GitHub Workflows

- `PR Checks`: lint, typecheck, tests, Terraform plans
- `Deploy`:
  - merge to `main` -> deploy dev
  - merge to `live` -> deploy prod + create release
- `Manual Deploy`:
  - choose branch
  - choose components: `org`, `backend`, `frontend`

Important naming convention:

- `bootstrap` means local-only setup (scripts + `infra/terraform/bootstrap`).
- GitHub Actions runs only regular/main workflows (`org`, `dev`, `prod` applies + service/frontend deploy).

`Manual Deploy` targets dev account/environment and supports deploying a selected branch to dev.

## Local Development

Install dependencies:

```bash
npm ci
```

Run checks:

```bash
npm run check
```

Run frontend:

```bash
npm run dev --workspace @serverless-app-template/frontend
```

Deploy backend locally (after AWS auth + terraform baseline):

```bash
npm run compose:deploy:dev
```

## Demo Cognito Users

Use helper script after Cognito is created:

```bash
scripts/create-cognito-users.sh \
  --stage dev \
  --project serverless-app-template \
  --region us-east-2 \
  --admin-email admin@example.org \
  --admin-password 'TempPassw0rd!' \
  --user-email user@example.org \
  --user-password 'TempPassw0rd!'
```

This creates one user in `admin` group and one in `user` group.

## Notes

- DNS records for API custom domains are synchronized by `scripts/sync-api-dns.sh` during deployment.
- `serverless/infra` must deploy first; `app`, `ws`, and `api` can deploy in parallel (managed by compose dependencies).
- The frontend demo includes Cognito login, app-api call, ws push display, DynamoDB-backed data retrieval, and an admin-only panel.
- Serverless `app` and `ws` services verify Cognito ID tokens for role-aware identity (`cognito:groups`).

## Generated Project Metadata

- Project slug: pk-go
- Domain: pechakuchaavl.org
- Region: us-east-2

This repository was generated by serverless-app-generator.
