# SimplifyMyBiz static site — same workflow for every customer site.
# Always run as the SMB gcloud profile (see README "Google Cloud access"),
# regardless of what the current terminal is switched to.
GCP_PROFILE ?= smb
# TEMPORARY project until the Terraform-managed website project exists.
export GCP_PROJECT ?= aqueous-abbey-515821-c3
export CLOUDSDK_ACTIVE_CONFIG_NAME := $(GCP_PROFILE)
export GOOGLE_APPLICATION_CREDENTIALS := $(HOME)/.config/gcp-profiles/adc/$(GCP_PROFILE).json

BUCKET ?= $(shell sed -n 's/^ *URL = "gs:\/\/\(.*\)"/\1/p' hugo.toml | head -1)
# Public address the site is built for. Until the domain points at a load balancer,
# that's the bucket's storage.googleapis.com URL; then set SITE_URL = https://simplifymy.biz/
SITE_URL ?= https://storage.googleapis.com/$(BUCKET)/

.PHONY: serve build deploy bucket clean

serve:            ## Live preview at http://localhost:1313
	hugo server --disableFastRender

build:            ## Production build into ./public
	hugo --gc --minify --cleanDestinationDir --baseURL "$(SITE_URL)"

deploy: build     ## Sync ./public to the GCS bucket (only changed files)
	@test -f "$$GOOGLE_APPLICATION_CREDENTIALS" || { echo "No credentials for profile $(GCP_PROFILE). Run: gcp login $(GCP_PROFILE)"; exit 1; }
	hugo deploy --target production

bucket:           ## One-time: create + configure the GCS bucket
	./scripts/setup-bucket.sh $(BUCKET)

clean:
	rm -rf public resources/_gen
