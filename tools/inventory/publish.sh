#!/usr/bin/env bash
# Publishes the inventory of one OpenTofu root to Taelron Docs, then rebuilds
# /platform/inventory/ from every root. Run from the root's directory, after
# an apply, with AWS credentials (the pipeline's apply role, or an Identity
# Center session from the RHEL box for tofu/bootstrap).
# Usage: publish.sh <root>
set -euo pipefail
root=$1
here=$(cd "$(dirname "$0")" && pwd)
bucket=docs-site-181841605684
distribution=E1F1ZNPSMAKS77
prefix=platform/inventory

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/all"

# The state goes straight from tofu into the filter: never written to disk.
tofu show -json \
  | jq --arg root "$root" \
       --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       --arg commit "${GITHUB_SHA:-$(git rev-parse HEAD)}" \
       -f "$here/filter.jq" > "$work/$root.json"

aws s3 cp --only-show-errors "$work/$root.json" "s3://$bucket/$prefix/$root.json" \
  --content-type application/json
aws s3 cp --only-show-errors --recursive "s3://$bucket/$prefix/" "$work/all/" \
  --exclude "*" --include "*.json"
aws s3 cp --only-show-errors "s3://$bucket/platform/architecture/index.html" \
  "$work/sidebar.html" || true

"$here/render.sh" "$work/all" "$work/sidebar.html" > "$work/index.html"
aws s3 cp --only-show-errors "$work/index.html" "s3://$bucket/$prefix/index.html" \
  --content-type "text/html; charset=utf-8"

id=$(aws cloudfront create-invalidation --distribution-id "$distribution" \
  --paths "/$prefix/*" --query Invalidation.Id --output text)
echo "Inventory of tofu/$root published; invalidation $id"
