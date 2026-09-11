# Chiket — landing page

The marketing page for **Chiket**, a parking-compliance app for Chicago drivers.

It is a single self-contained `index.html`: every asset — the scroll-scrubbed hero
video, the photography, the icon sprite — is inlined as a `data:` URI. There is no
build step, no bundler and no runtime dependency. The only thing it fetches from the
network is Inter from Google Fonts.

---

## Run it on a VPS

Needs Docker Engine with the Compose plugin.

```bash
git clone https://github.com/vladymoney/ChiketLanding.git
cd ChiketLanding
docker compose up -d --build
```

That serves the page on **port 8080**. Check it:

```bash
curl -I http://localhost:8080
```

To serve it on port 80 instead:

```bash
PORT=80 docker compose up -d --build
```

Then it is live at `http://<your-vps-ip>/`.

### Updating after a change

```bash
git pull && docker compose up -d --build
```

`--build` matters — without it Compose reuses the existing image and you will keep
serving the old page.

### Stopping

```bash
docker compose down
```

---

## Adding a domain and HTTPS

The container speaks plain HTTP on purpose, so it can sit behind whatever you already
run. If you have nothing yet, Caddy is the shortest path to automatic TLS — point your
domain's A record at the VPS, leave this container on 8080, and give Caddy a one-line
`Caddyfile`:

```
landing.yourdomain.com {
    reverse_proxy localhost:8080
}
```

---

## What's in here

| File | Purpose |
| --- | --- |
| `index.html` | The entire page, ~3.3 MB with all assets inlined |
| `og.jpg` | Social preview image for link unfurls |
| `Dockerfile` | Precompresses the page, then serves it from `nginx:1.27-alpine` |
| `nginx.conf` | `gzip_static`, `no-cache` on the page, `/healthz` endpoint |
| `docker-compose.yml` | One service, restart-on-failure, healthcheck, capped logs |
| `build-standalone.py` | Regenerates `index.html` from the source build (see below) |

### Why the page is precompressed

`index.html` is mostly base64, which inflates binary assets by about a third. Gzip wins
most of that back — roughly 3.3 MB down to ~2.6 MB — but compressing several megabytes
on every request is wasteful. The Dockerfile gzips it once at build time and nginx
serves the `.gz` via `gzip_static`.

### Why `no-cache` on the page

There is one HTML file and its name never changes, so there is no content hash to bust
a cache with. `no-cache` tells browsers to revalidate rather than to skip caching — a
304 costs nothing and a redeploy is visible immediately.

### `build-standalone.py`

The page is authored inside Claude's artifact host, which injects the doctype, the
charset and viewport meta tags, and a small CSS reset. Served from nginx it gets none
of that — without a wrapper the page would render in quirks mode and lay out at 980px
on phones. This script wraps the artifact build into a real document:

```bash
python build-standalone.py path/to/artifact-build.html index.html
```

---

## Status

Chiket is in **private beta, Chicago only**. Nothing on the page claims otherwise:
there are no testimonials, no user counts, no ratings and no app-store badges, because
none of those exist yet. The waitlist form is not wired to a mailing list and says so
in plain text when you submit it — connect it before showing this to real prospects.

The figures in the "cost of doing nothing" section ($60 street cleaning, $200 city
sticker, 3 unpaid tickets to a boot) come from the City of Chicago fine schedule and
municipal code, and the page says so. Verify current amounts before relying on them.
