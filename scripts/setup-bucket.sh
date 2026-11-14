#!/usr/bin/env bash
# One-time setup of a public GCS bucket that serves a static site.
# Usage: scripts/setup-bucket.sh <bucket-name> [region]
set -euo pipefail
BUCKET="${1:?usage: setup-bucket.sh <bucket-name> [region]}"
REGION="${2:-us-west1}"
PROJECT="$(gcloud config get-value project 2>/dev/null)"
echo "Project: $PROJECT  Bucket: gs://$BUCKET  Region: $REGION"
read -r -p "Continue? [y/N] " ok; [[ "$ok" == "y" ]] || exit 1

gcloud storage buckets create "gs://$BUCKET" --location="$REGION" --uniform-bucket-level-access
gcloud storage buckets update "gs://$BUCKET" --web-main-page-suffix=index.html --web-error-page=404.html
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member=allUsers --role=roles/storage.objectViewer

echo
echo "Done. Next: 'make deploy'. For HTTPS on a custom domain, put a global external"
echo "Application Load Balancer with a backend bucket + Google-managed cert in front (see README)."
