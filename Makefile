# SimplifyMyBiz static site — same workflow for every customer site.
# Hosting: Cloudflare Workers static assets (see wrangler.jsonc).

# Public address the site is built for.
SITE_URL ?= https://simplifymy.biz/
# Cloudflare's CLI, pinned so every site deploys the same way.
WRANGLER ?= npx --yes wrangler@4.169.0

.PHONY: serve build deploy check login whoami clean

serve:            ## Live preview at http://localhost:1313
	hugo server --disableFastRender --renderToMemory

build:            ## Production build into ./public
	hugo --gc --minify --cleanDestinationDir --baseURL "$(SITE_URL)"

check: build      ## Validate the Cloudflare deploy without uploading anything
	$(WRANGLER) deploy --dry-run

deploy: build     ## Build and publish to Cloudflare
	$(WRANGLER) deploy

login:            ## One-time: sign in to Cloudflare (opens the browser)
	$(WRANGLER) login

whoami:           ## Show which Cloudflare login and accounts are active
	$(WRANGLER) whoami

clean:
	rm -rf public resources/_gen .wrangler
