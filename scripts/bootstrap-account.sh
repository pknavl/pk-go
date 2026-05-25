#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Create Terraform backend prerequisites for one AWS account.

Usage:
  scripts/bootstrap-account.sh \
    --account org \
    --project serverless-app-template \
    --region us-east-2

Required:
  --account   Account label (org | dev | prod)
  --project   Project slug used in bucket/table names
  --region    AWS region

Optional:
  --bucket    Override tf state bucket name
  --table     Override tf lock table name

Creates only:
  1) S3 bucket for Terraform state
  2) DynamoDB table for Terraform locking
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' is not installed" >&2
    exit 1
  fi
}

ACCOUNT=""
PROJECT=""
REGION=""
BUCKET=""
TABLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      ACCOUNT="$2"
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
    --bucket)
      BUCKET="$2"
      shift 2
      ;;
    --table)
      TABLE="$2"
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

if [[ -z "$ACCOUNT" || -z "$PROJECT" || -z "$REGION" ]]; then
  echo "error: missing required arguments" >&2
  usage
  exit 1
fi

if [[ "$ACCOUNT" != "org" && "$ACCOUNT" != "dev" && "$ACCOUNT" != "prod" ]]; then
  echo "error: --account must be one of: org, dev, prod" >&2
  exit 1
fi

if [[ -z "$BUCKET" ]]; then
  BUCKET="${PROJECT}-${ACCOUNT}-tf-state"
fi

if [[ -z "$TABLE" ]]; then
  TABLE="${PROJECT}-${ACCOUNT}-tf-locks"
fi

echo "Bootstrapping Terraform backend prerequisites"
echo "  account: $ACCOUNT"
echo "  project: $PROJECT"
echo "  region:  $REGION"
echo "  bucket:  $BUCKET"
echo "  table:   $TABLE"

echo "[1/2] Ensure state bucket exists"
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "  - bucket exists"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration "LocationConstraint=${REGION}"
  fi
  echo "  - bucket created"
fi

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "  - versioning and encryption ensured"

echo "[2/2] Ensure lock table exists"
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "  - table exists"
else
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
  echo "  - table created"
fi

echo
echo "Bootstrap complete for account '$ACCOUNT'."
