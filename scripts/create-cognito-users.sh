#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Create default Cognito users and assign admin/user groups.

Usage:
  scripts/create-cognito-users.sh \
    --stage dev \
    --project serverless-app-template \
    --region us-east-2 \
    --admin-email admin@example.org \
    --admin-password 'TempPassw0rd!' \
    --user-email user@example.org \
    --user-password 'TempPassw0rd!'

Required:
  --stage           dev or prod
  --project         project slug
  --region          AWS region
  --admin-email     admin username/email
  --admin-password  permanent admin password
  --user-email      user username/email
  --user-password   permanent user password

Notes:
  - User pool id is read from SSM: /<project>/<stage>/cognito/user-pool-id
  - Creates users if absent and force-sets permanent password
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' is not installed" >&2
    exit 1
  fi
}

STAGE=""
PROJECT=""
REGION=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
USER_EMAIL=""
USER_PASSWORD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --admin-email)
      ADMIN_EMAIL="$2"
      shift 2
      ;;
    --admin-password)
      ADMIN_PASSWORD="$2"
      shift 2
      ;;
    --user-email)
      USER_EMAIL="$2"
      shift 2
      ;;
    --user-password)
      USER_PASSWORD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd aws

if [[ -z "$STAGE" || -z "$PROJECT" || -z "$REGION" || -z "$ADMIN_EMAIL" || -z "$ADMIN_PASSWORD" || -z "$USER_EMAIL" || -z "$USER_PASSWORD" ]]; then
  echo "error: missing required arguments" >&2
  usage
  exit 1
fi

if [[ "$STAGE" != "dev" && "$STAGE" != "prod" ]]; then
  echo "error: --stage must be dev or prod" >&2
  exit 1
fi

POOL_PARAM="/${PROJECT}/${STAGE}/cognito/user-pool-id"

USER_POOL_ID="$(aws ssm get-parameter --name "$POOL_PARAM" --region "$REGION" --query 'Parameter.Value' --output text)"

if [[ -z "$USER_POOL_ID" || "$USER_POOL_ID" == "None" ]]; then
  echo "error: unable to resolve Cognito user pool id from $POOL_PARAM" >&2
  exit 1
fi

ensure_user() {
  local email="$1"
  local password="$2"

  if aws cognito-idp admin-get-user --user-pool-id "$USER_POOL_ID" --username "$email" --region "$REGION" >/dev/null 2>&1; then
    echo "User exists: $email"
  else
    aws cognito-idp admin-create-user \
      --user-pool-id "$USER_POOL_ID" \
      --username "$email" \
      --user-attributes Name=email,Value="$email" Name=email_verified,Value=true \
      --message-action SUPPRESS \
      --region "$REGION" >/dev/null
    echo "User created: $email"
  fi

  aws cognito-idp admin-set-user-password \
    --user-pool-id "$USER_POOL_ID" \
    --username "$email" \
    --password "$password" \
    --permanent \
    --region "$REGION" >/dev/null
}

ensure_group() {
  local group_name="$1"

  if aws cognito-idp get-group --user-pool-id "$USER_POOL_ID" --group-name "$group_name" --region "$REGION" >/dev/null 2>&1; then
    echo "Group exists: $group_name"
  else
    aws cognito-idp create-group \
      --user-pool-id "$USER_POOL_ID" \
      --group-name "$group_name" \
      --description "${group_name} group for ${PROJECT}/${STAGE}" \
      --region "$REGION" >/dev/null
    echo "Group created: $group_name"
  fi
}

ensure_group "admin"
ensure_group "user"

ensure_user "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
ensure_user "$USER_EMAIL" "$USER_PASSWORD"

aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username "$ADMIN_EMAIL" \
  --group-name "admin" \
  --region "$REGION" >/dev/null

aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USER_EMAIL" \
  --group-name "user" \
  --region "$REGION" >/dev/null

echo "Cognito demo users ready in pool $USER_POOL_ID"
