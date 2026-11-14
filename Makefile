# SimplifyMyBiz static site — same workflow for every customer site.
BUCKET ?= $(shell sed -n 's/^ *URL = "gs:\/\/\(.*\)"/\1/p' hugo.toml | head -1)

.PHONY: serve build deploy bucket clean

serve:            ## Live preview at http://localhost:1313
	hugo server --disableFastRender

build:            ## Production build into ./public
	hugo --gc --minify

deploy: build     ## Sync ./public to the GCS bucket (only changed files)
	hugo deploy --target production

bucket:           ## One-time: create + configure the GCS bucket
	./scripts/setup-bucket.sh $(BUCKET)

clean:
	rm -rf public resources/_gen
