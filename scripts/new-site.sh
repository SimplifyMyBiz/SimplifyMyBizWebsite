#!/usr/bin/env bash
# Scaffold a new customer site using the SMB theme.
# Usage: scripts/new-site.sh <dir> "<Business Name>" <customer-slug>   (bucket = smb-site-<slug>)
set -euo pipefail
DIR="${1:?usage: new-site.sh <dir> \"<Business Name>\" <customer-slug>}"
NAME="${2:?business name required}"
BUCKET="smb-site-${3:?customer slug required}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
[[ -e "$DIR" ]] && { echo "$DIR already exists"; exit 1; }

mkdir -p "$DIR"/{content,static,scripts}
cp -R "$SRC/themes" "$DIR/"
cp "$SRC/Makefile" "$SRC/.gitignore" "$DIR/"
cp "$SRC/scripts/setup-bucket.sh" "$DIR/scripts/"
cp "$SRC/static/favicon.svg" "$DIR/static/"
sed -e "s/^title = .*/title = \"$NAME\"/" \
    -e "s|gs://[^\"]*|gs://$BUCKET|" \
    -e 's/^baseURL = .*/baseURL = "https:\/\/example.com\/"/' \
    "$SRC/hugo.toml" > "$DIR/hugo.toml"
cp "$SRC/content/_index.md" "$DIR/content/_index.md"
(cd "$DIR" && git init -q)
echo "Created $DIR. Next: edit hugo.toml (baseURL, params, colors) and content/_index.md, then 'make serve'."
