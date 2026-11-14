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
scripts/new-site.sh ../customer-acme "Acme Plumbing" acme-plumbing-site
cd ../customer-acme
# 1. hugo.toml: baseURL, email, phone, colors, menu
# 2. content/_index.md: rewrite the blocks with their pitch
# 3. static/: their logo / favicon
make serve        # review with the customer
make bucket       # one-time GCS setup
make deploy
```

## Hosting on Google Cloud Storage

One-time per site (needs `gcloud` logged in to the right project):

```bash
make bucket       # creates the bucket, sets index.html/404.html, makes it publicly readable
make deploy
```

The bucket is then live at `https://storage.googleapis.com/<bucket>/index.html`.

**Custom domain with HTTPS:** GCS website hosting alone is HTTP-only on a custom domain. For HTTPS, put a
global external Application Load Balancer in front with a **backend bucket** (Cloud CDN on) and a
Google-managed certificate, then point the domain's A record at the load balancer IP.
Multiple customer sites can share one load balancer using host rules.

Caching is set in `hugo.toml` under `[deployment]`: fingerprinted CSS/images cache for a year,
HTML for 5 minutes, so updates show up quickly.
