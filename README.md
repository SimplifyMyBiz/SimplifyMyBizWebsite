# SimplifyMyBiz Website

The marketing site for [SimplifyMyBiz](https://simplifymy.biz) — and the template we use for every customer website.

**Stack:** [Hugo](https://gohugo.io) (static site generator) → plain HTML/CSS → Google Cloud Storage bucket.
No database, no admin login, no plugins, no JavaScript framework. Nothing to hack, nothing to patch.
Anything that needs server-side processing (contact forms, etc.) runs as a separate Cloud Run service.

## Quick start

```bash
brew install hugo          # needs the "extended+withdeploy" build (Homebrew's default)
make serve                 # live preview at http://localhost:1313
make build                 # production build into ./public
make deploy                # sync ./public to the GCS bucket (changed files only)
```

## How the site is built

| Path | What it is |
| --- | --- |
| `hugo.toml` | Site name, contact info, brand colors, menu, deploy bucket |
| `content/_index.md` | The homepage, written as a list of **blocks** in front matter |
| `themes/smb/` | The reusable SMB theme — shared by all sites |
| `static/` | Files copied as-is (favicon, images) |

### Homepage blocks

The homepage is a stack of blocks. Each block's `type` maps to `themes/smb/layouts/_partials/blocks/<type>.html`.
Reorder, remove or duplicate them freely in `content/_index.md`.

| Block | Use for | Fields |
| --- | --- | --- |
| `hero` | The top pitch | `eyebrow`, `heading`, `text`, `cta`, `secondary`, `points[]` |
| `features` | Grid of service cards | `id`, `eyebrow`, `heading`, `text`, `items[]{icon,title,text}` |
| `split` | Pitch + checklist side by side | `id`, `eyebrow`, `heading`, `text`, `note`, `items[]`, `reverse` |
| `steps` | Numbered process | `id`, `eyebrow`, `heading`, `items[]{title,text}` |
| `faq` | Expanding Q&A | `id`, `eyebrow`, `heading`, `items[]{q,a}` |
| `cta` | Closing call to action / contact | `id`, `heading`, `text` |

Icons available for `features`: `workspace`, `admin`, `ai`, `shield`, `vault`, `person`, `check`
(add more in `themes/smb/layouts/_partials/icon.html`).

Extra pages: add `content/<name>.md` with a `title` and Markdown body (rendered with `page.html`).

### Brand colors

Set `brandColor` and `accentColor` in `hugo.toml`. Light and dark mode are handled automatically.

### Contact

The `cta` block uses, in order: a form posting to `formEndpoint` (a Cloud Run URL) if set,
otherwise a button to `bookingURL` if set, otherwise a `mailto:` link to `email`.

## New customer site (the repeatable process)

```bash
scripts/new-site.sh ../customer-acme "Acme Plumbing" acme   # bucket: smb-site-acme
cd ../customer-acme
# 1. hugo.toml: baseURL, email, phone, colors, menu
# 2. content/_index.md: rewrite the blocks with their pitch
# 3. static/: their logo / favicon
make serve        # review with the customer
make bucket       # one-time GCS setup
make deploy
```

## Hosting on Google Cloud

All sites — ours and every customer's — live in the SMB org, in **one shared project: `smb-customers-sites`**.
Each site gets its own bucket named **`smb-site-<customer>`** (ours: `smb-site-simplifymybiz`).
One HTTPS load balancer in that project serves every bucket using host rules (domain → bucket).

### Google Cloud access

We use **gcp**, a small zsh helper (`~/.config/gcp-profiles/gcp.zsh`, sourced from `~/.zshrc`) that gives each
terminal its own Google Cloud profile: a gcloud configuration plus its own Application Default Credentials,
so `gcloud`, `hugo deploy` and Terraform all act as the same account. The current profile shows on the
right of the prompt.

```bash
gcp                 # list profiles, show this terminal's
gcp use smb         # switch this terminal to SMB
gcp login smb       # sign in (gcloud + ADC) - pick the SMB-org Google account
```

The Makefile pins this repo to the `smb` profile, so `make bucket` / `make deploy` always run as SMB,
whatever the terminal is switched to. Profiles: `smb` (SimplifyMyBiz org, project `smb-customers-sites`)
and `smc` (SimplifyMyCloud, unrelated to this repo).

### Per site

```bash
make bucket       # creates smb-site-<customer>, sets index.html/404.html, labels it, makes it public-read
make deploy
```

The bucket is then live at `https://storage.googleapis.com/<bucket>/index.html`. The build uses that
address as its base URL (`SITE_URL` in the Makefile) so CSS and links resolve inside the bucket. Once a domain
points at the load balancer, set `SITE_URL = https://<domain>/`.

**Current (temporary) hosting:** project `aqueous-abbey-515821-c3`, bucket `smb-smb-pubsite-temp`, live at
https://storage.googleapis.com/smb-smb-pubsite-temp/index.html. The project has a domain-restricted-sharing
exception (`infra/temp-allow-public-members.yaml`) so the bucket can be public. Both get replaced by the
Terraform-managed website project.

**Custom domain with HTTPS:** add a backend bucket (Cloud CDN on) + host rule for the domain to the shared
load balancer, add the domain to its Google-managed certificate, and point the domain's A record at the
load balancer IP.

Caching is set in `hugo.toml` under `[deployment]`: fingerprinted CSS/images cache for a year,
HTML for 5 minutes, so updates show up quickly.
