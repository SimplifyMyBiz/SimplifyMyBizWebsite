#!/usr/bin/env bash
# Scaffold a new customer site using the SMB theme, hosted on Cloudflare.
# Usage: scripts/new-site.sh <dir> "<Business Name>" <domain>
#   e.g. scripts/new-site.sh ../customer-acme "Acme Plumbing" acmeplumbing.com
set -euo pipefail
DIR="${1:?usage: new-site.sh <dir> \"<Business Name>\" <domain>}"
NAME="${2:?business name required}"
DOMAIN="${3:?domain required, e.g. acmeplumbing.com}"
DOMAIN="${DOMAIN#https://}"; DOMAIN="${DOMAIN#http://}"; DOMAIN="${DOMAIN#www.}"; DOMAIN="${DOMAIN%/}"
[[ "$DOMAIN" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]] || { echo "Domain looks wrong: $DOMAIN"; exit 1; }
WORKER="${DOMAIN//./-}"   # Cloudflare Worker name, e.g. acmeplumbing-com
SRC="$(cd "$(dirname "$0")/.." && pwd)"
[[ -e "$DIR" ]] && { echo "$DIR already exists"; exit 1; }

mkdir -p "$DIR"/{content,static,.claude}
cp -R "$SRC/themes" "$DIR/"
cp "$SRC/Makefile" "$SRC/.gitignore" "$DIR/"
cp "$SRC/.claude/launch.json" "$DIR/.claude/"
cp "$SRC/static/_headers" "$SRC/static/favicon.svg" "$DIR/static/"
cp "$SRC/content/_index.md" "$DIR/content/_index.md"

sed -e "s|^title = .*|title = \"$NAME\"|" \
    -e "s|^baseURL = .*|baseURL = \"https://$DOMAIN/\"|" \
    -e "s|^\( *email = \).*|\1\"hello@$DOMAIN\"|" \
    "$SRC/hugo.toml" > "$DIR/hugo.toml"

sed -e "s|\"name\": \"[^\"]*\"|\"name\": \"$WORKER\"|" \
    -e "s|\"pattern\": \"www\.simplifymy\.biz\"|\"pattern\": \"www.$DOMAIN\"|" \
    -e "s|\"pattern\": \"simplifymy\.biz\"|\"pattern\": \"$DOMAIN\"|" \
    "$SRC/wrangler.jsonc" > "$DIR/wrangler.jsonc"

(cd "$DIR" && git init -q)
cat <<EOF
Created $DIR for $NAME ($DOMAIN, Cloudflare Worker "$WORKER").
Next:
  1. hugo.toml: description, tagline, email, colors, menu
  2. content/_index.md: rewrite the blocks with their pitch
  3. static/: their favicon.svg; optionally images/og.png (1200x630) and apple-touch-icon.png (180x180)
  4. make serve      # review with the customer
  5. make login      # Cloudflare, as the SMB admin (must be a member of their account)
  6. make deploy
EOF
