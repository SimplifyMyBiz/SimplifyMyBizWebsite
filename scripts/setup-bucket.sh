#!/usr/bin/env bash
# One-time setup of a public GCS bucket that serves a static site.
# All customer sites live in one shared project, one bucket each: smb-site-<customer>.
# Usage: scripts/setup-bucket.sh <bucket-name> [region]
# Env:   GCP_PROJECT (default smb-customers-sites)
#        CLOUDSDK_ACTIVE_CONFIG_NAME (default smb; set by the Makefile) — gcloud config to use
set -euo pipefail
BUCKET="${1:?usage: setup-bucket.sh <bucket-name> [region]}"
REGION="${2:-us-west1}"
PROJECT="${GCP_PROJECT:-smb-customers-sites}"
export CLOUDSDK_ACTIVE_CONFIG_NAME="${CLOUDSDK_ACTIVE_CONFIG_NAME:-smb}"
[[ "$BUCKET" == smb-site-* ]] || echo "warning: bucket doesn't follow the smb-site-<customer> convention"

echo "Project: $PROJECT  Bucket: gs://$BUCKET  Region: $REGION  gcloud config: $CLOUDSDK_ACTIVE_CONFIG_NAME"
read -r -p "Continue? [y/N] " ok; [[ "$ok" == "y" ]] || exit 1

gcloud storage buckets create "gs://$BUCKET" --project="$PROJECT" --location="$REGION" \
  --uniform-bucket-level-access --default-storage-class=STANDARD
gcloud storage buckets update "gs://$BUCKET" --web-main-page-suffix=index.html --web-error-page=404.html
gcloud storage buckets update "gs://$BUCKET" --update-labels=managed-by=smb,purpose=website
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member=allUsers --role=roles/storage.objectViewer

echo
echo "Done. Next: 'make deploy'."
