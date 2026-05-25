#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Upsert API custom domain Route53 alias records in org account.

Usage:
  scripts/sync-api-dns.sh \
    --stage dev \
    --project serverless-app-template \
    --domain example.org \
    --zone-id Z1234567890 \
    --org-role-arn arn:aws:iam::123456789012:role/serverless-app-template-route53-manager \
    --region us-east-2

Required:
  --stage         dev or prod
  --project       project slug (stack/service prefix)
  --domain        root domain
  --zone-id       Route53 hosted zone id in org account
  --org-role-arn  role ARN in org account for DNS updates
  --region        AWS region used by API Gateway stacks

Notes:
  - Expects app-<stage>, ws-<stage>, and api-<stage> as optional stacks
  - Reads domain target outputs from CloudFormation and writes alias records in Route53
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
DOMAIN=""
ZONE_ID=""
ORG_ROLE_ARN=""
REGION=""

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
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --zone-id)
      ZONE_ID="$2"
      shift 2
      ;;
    --org-role-arn)
      ORG_ROLE_ARN="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
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
require_cmd jq

if [[ -z "$STAGE" || -z "$PROJECT" || -z "$DOMAIN" || -z "$ZONE_ID" || -z "$ORG_ROLE_ARN" || -z "$REGION" ]]; then
  echo "error: missing required arguments" >&2
  usage
  exit 1
fi

if [[ "$STAGE" != "dev" && "$STAGE" != "prod" ]]; then
  echo "error: --stage must be dev or prod" >&2
  exit 1
fi

resolve_output() {
  local stack_name="$1"
  local output_key="$2"

  aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='${output_key}'].OutputValue | [0]" \
    --output text
}

stack_exists() {
  local stack_name="$1"

  aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$REGION" \
    >/dev/null 2>&1
}

assume_org_role() {
  local role_arn="$1"
  local session_name="$2"

  aws sts assume-role \
    --role-arn "$role_arn" \
    --role-session-name "$session_name" \
    --query 'Credentials' \
    --output json
}

upsert_alias() {
  local record_name="$1"
  local target_name="$2"
  local target_zone_id="$3"

  local change_batch
  change_batch="$(jq -n \
    --arg name "$record_name" \
    --arg target_name "$target_name" \
    --arg target_zone_id "$target_zone_id" \
    '{
      Changes: [
        {
          Action: "UPSERT",
          ResourceRecordSet: {
            Name: $name,
            Type: "A",
            AliasTarget: {
              DNSName: $target_name,
              HostedZoneId: $target_zone_id,
              EvaluateTargetHealth: false
            }
          }
        }
      ]
    }')"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "$change_batch" \
    >/dev/null
}

suffix=""
if [[ "$STAGE" != "prod" ]]; then
  suffix="-dev"
fi

APP_STACK="app-${STAGE}"
WS_STACK="ws-${STAGE}"
API_STACK="api-${STAGE}"

echo "Resolving CloudFormation outputs..."
APP_TARGET_NAME=""
APP_TARGET_ZONE_ID=""

WS_TARGET_NAME=""
WS_TARGET_ZONE_ID=""
API_TARGET_NAME=""
API_TARGET_ZONE_ID=""

if stack_exists "$APP_STACK"; then
  APP_TARGET_NAME="$(resolve_output "$APP_STACK" "AppApiDomainTargetName")"
  APP_TARGET_ZONE_ID="$(resolve_output "$APP_STACK" "AppApiDomainTargetZoneId")"
else
  echo "  - app stack not found, skipping app-api dns"
fi

if stack_exists "$WS_STACK"; then
  WS_TARGET_NAME="$(resolve_output "$WS_STACK" "AppWsDomainTargetName")"
  WS_TARGET_ZONE_ID="$(resolve_output "$WS_STACK" "AppWsDomainTargetZoneId")"
else
  echo "  - ws stack not found, skipping ws dns"
fi

if stack_exists "$API_STACK"; then
  API_TARGET_NAME="$(resolve_output "$API_STACK" "ApiDomainTargetName")"
  API_TARGET_ZONE_ID="$(resolve_output "$API_STACK" "ApiDomainTargetZoneId")"
else
  echo "  - api stack not found, skipping api dns"
fi

echo "Assuming org Route53 role..."
ORG_CREDS="$(assume_org_role "$ORG_ROLE_ARN" "sync-api-dns-${STAGE}")"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

AWS_ACCESS_KEY_ID="$(jq -r '.AccessKeyId' <<<"$ORG_CREDS")"
AWS_SECRET_ACCESS_KEY="$(jq -r '.SecretAccessKey' <<<"$ORG_CREDS")"
AWS_SESSION_TOKEN="$(jq -r '.SessionToken' <<<"$ORG_CREDS")"

echo "Upserting Route53 aliases in zone $ZONE_ID..."
if [[ -n "$APP_TARGET_NAME" && -n "$APP_TARGET_ZONE_ID" ]]; then
  upsert_alias "app-api${suffix}.${DOMAIN}" "$APP_TARGET_NAME" "$APP_TARGET_ZONE_ID"
fi

if [[ -n "$WS_TARGET_NAME" && -n "$WS_TARGET_ZONE_ID" ]]; then
  upsert_alias "app-ws${suffix}.${DOMAIN}" "$WS_TARGET_NAME" "$WS_TARGET_ZONE_ID"
fi

if [[ -n "$API_TARGET_NAME" && -n "$API_TARGET_ZONE_ID" ]]; then
  upsert_alias "api${suffix}.${DOMAIN}" "$API_TARGET_NAME" "$API_TARGET_ZONE_ID"
fi

if [[ -z "$APP_TARGET_NAME" && -z "$WS_TARGET_NAME" && -z "$API_TARGET_NAME" ]]; then
  echo "No app/ws/api stacks found for stage '$STAGE'; nothing to sync."
  exit 0
fi

echo "DNS sync complete for stage '$STAGE'."
