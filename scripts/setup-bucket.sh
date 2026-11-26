#!/usr/bin/env bash
# One-time setup of a public GCS bucket that serves a static site.
# All customer sites live in one shared project, one bucket each: smb-site-<customer>.
# Usage: scripts/setup-bucket.sh <bucket-name> [region]
# Env:   GCP_PROJECT (set by the Makefile)
#        CLOUDSDK_ACTIVE_CONFIG_NAME (default smb; set by the Makefile) — gcloud config to use
set -euo pipefail
BUCKET="${1:?usage: setup-bucket.sh <bucket-name> [region]}"
REGION="${2:-us-west1}"
PROJECT="${GCP_PROJECT:?set GCP_PROJECT}"
export CLOUDSDK_ACTIVE_CONFIG_NAME="${CLOUDSDK_ACTIVE_CONFIG_NAME:-smb}"

echo "Project: $PROJECT  Bucket: gs://$BUCKET  Region: $REGION  gcloud config: $CLOUDSDK_ACTIVE_CONFIG_NAME"
read -r -p "Continue? [y/N] " ok; [[ "$ok" == "y" ]] || exit 1

if gcloud storage buckets describe "gs://$BUCKET" --format="value(name)" >/dev/null 2>&1; then
  echo "Bucket gs://$BUCKET already exists; updating its settings."
else
  gcloud storage buckets create "gs://$BUCKET" --project="$PROJECT" --location="$REGION" \
    --uniform-bucket-level-access --default-storage-class=STANDARD
fi
gcloud storage buckets update "gs://$BUCKET" --web-main-page-suffix=index.html --web-error-page=404.html
gcloud storage buckets update "gs://$BUCKET" --update-labels=managed-by=${BUCKET_MANAGED_BY:-manual},purpose=website,lifecycle=${BUCKET_LIFECYCLE:-temporary}
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member=allUsers --role=roles/storage.objectViewer

echo
echo "Done. Next: 'make deploy'."
