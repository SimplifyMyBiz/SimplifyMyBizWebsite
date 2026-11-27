# SimplifyMyBiz Website

The marketing site for [SimplifyMyBiz](https://simplifymy.biz) — and the template we use for every customer website.

**Stack:** [Hugo](https://gohugo.io) (static site generator) → plain HTML/CSS → [Cloudflare](https://developers.cloudflare.com/workers/static-assets/) (Workers static assets).
No database, no admin login, no plugins, no JavaScript. Nothing to patch, nothing to break.
Anything that needs server-side processing (contact forms, logged-in apps) runs on Google Cloud Run — see [Hosting](#hosting).

## Quick start

```bash
brew install hugo node     # Hugo, plus Node for Cloudflare's wrangler CLI (run via npx, pinned in the Makefile)
make serve                 # live preview at http://localhost:1313
make build                 # production build into ./public (base URL = baseURL in hugo.toml)
make check                 # dry-run the Cloudflare deploy, uploads nothing
make login                 # one-time: sign in to Cloudflare in the browser
make deploy                # build and publish to Cloudflare
```

## How the site is built

| Path | What it is |
| --- | --- |
| `hugo.toml` | Site name, domain (`baseURL`), contact info, brand colors, menu |
| `wrangler.jsonc` | Cloudflare hosting: Worker name and the site's domains |
| `content/_index.md` | The homepage, written as a list of **blocks** in front matter |
| `themes/smb/` | The reusable SMB theme — shared by all sites |
| `static/` | Files copied as-is: favicon, `_headers` (security headers), optional `images/og.png` and `apple-touch-icon.png` |

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

Icons available for `features`: `workspace`, `admin`, `docs`, `ai`, `shield`, `vault`, `person`, `check`
(add more in `themes/smb/layouts/_partials/icon.html`).

Extra pages: add `content/<name>.md` with a `title` and Markdown body (rendered with `page.html`).

### Brand colors

Set `brandColor` and `accentColor` in `hugo.toml`. Check that text in `accentColor` reaches 4.5:1 contrast
on `brandColor` and white (WCAG AA). The theme font is Nunito Sans, self-hosted from `themes/smb/static/fonts/`.

### Contact

The `cta` block uses, in order: a form posting to `formEndpoint` (a Cloud Run URL) if set,
otherwise a button to `bookingURL` if set, otherwise a `mailto:` link to `email`.
If you set `formEndpoint`, add its origin to `form-action` in `static/_headers`, or the browser will block the form.

## New customer site (the repeatable process)

```bash
scripts/new-site.sh ../customer-acme "Acme Plumbing" acmeplumbing.com
cd ../customer-acme
# 1. hugo.toml: description, tagline, email, colors, menu
# 2. content/_index.md: rewrite the blocks with their pitch
# 3. static/: their favicon.svg; optionally images/og.png (1200x630) and apple-touch-icon.png (180x180)
make serve        # review with the customer
make deploy       # publishes to the customer's Cloudflare account
```

The script fills in `baseURL`, the email address and `wrangler.jsonc` (Worker `acmeplumbing-com`, domains
`acmeplumbing.com` and `www.acmeplumbing.com`).

## Hosting

The same pattern for every site, ours included:

| What | Where |
| --- | --- |
| Static website | **Cloudflare** Workers static assets: DNS, HTTPS, caching, analytics, security headers |
| Logged-in apps | **Google Cloud Run** behind IAP on a subdomain (e.g. `portal.example.com`), DNS-only record in Cloudflare |
| Email, documents | **Google Workspace** |
| Backups | **Google Cloud Storage** vaults with Bucket Lock |

### The customer owns everything

Each customer signs up for, pays for and owns their own **Google Workspace** and **Cloudflare** accounts, and
the domain is registered in their Cloudflare account. SMB is invited as an administrator (Super Administrator in
Cloudflare). One SMB Cloudflare login is a member of every customer account, so `make login` once covers them all.
If a customer leaves, they remove SMB's access and keep everything.

### Onboarding a customer to Cloudflare

1. The customer creates a free Cloudflare account and invites the SMB admin as **Super Administrator**.
2. Add their domain. Before switching nameservers, check that the Workspace email records (MX, SPF, DKIM,
   DMARC) were imported exactly.
3. Switch the nameservers at their registrar; later, transfer the registration to Cloudflare Registrar in their account.
4. `make deploy` creates the Worker and attaches the domains (Cloudflare adds the DNS records and certificates).
5. In the Cloudflare dashboard: **SSL/TLS → Edge Certificates → Always Use HTTPS** on, and a
   **Redirect Rule** from `https://www.<domain>/*` to `https://<domain>/${1}` (301, keep query string).

### Caching and headers

`static/_headers` sets the security headers (Content-Security-Policy, HSTS, no framing) and caching for fonts
and images. CSS is inlined into each page, and HTML is revalidated on every visit, so a deploy shows up immediately.
