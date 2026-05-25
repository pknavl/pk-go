# Terraform Infrastructure

Terraform is organized by account scope:

- `bootstrap`: per-account bootstrap baseline (OIDC + deploy role)
- `org`: org-level resources (Route53 management role)
- `dev`: dev account resources
- `prod`: prod account resources
- `main`: shared module used by `dev` and `prod`

## Trust model

- `bootstrap` creates one GitHub OIDC deploy role per account.
- `org` Route53 manager trust is scoped to specific deploy role ARNs (dev/prod), not account root principals.
- GitHub workflows consume role ARNs from repository variables (OIDC-first, no long-lived AWS secrets).

## Execution model

1. Run `scripts/bootstrap-account.sh` per account.
2. Apply `bootstrap` Terraform in each account.
3. Apply `org` Terraform in org account with trusted dev/prod deploy role ARNs.
4. Apply `dev` and `prod` Terraform in env accounts.
5. Use GitHub Actions for ongoing apply/deploy.

Terminology: `bootstrap` is local-only setup. GitHub Actions executes only regular/main workflows.

All root modules use `backend "s3" {}` and expect backend values via `-backend-config`.
