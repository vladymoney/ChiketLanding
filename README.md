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

That serves the page on **port 8417** — deliberately off the beaten track, so it
should not collide with anything else you already run. It is live at
`http://<your-vps-ip>:8417/`. Check it:

```bash
curl -I http://localhost:8417
```

### Changing the port

The host port lives in `.env`, which Compose loads automatically:

```
PORT=8417
```

Edit that line and re-run `docker compose up -d`. Nothing else needs to change —
the container always listens on 80 internally, so the healthcheck and nginx config
are unaffected.

For a one-off without editing the file:

```bash
PORT=9123 docker compose up -d --build
```

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

## Putting it on a domain, with HTTPS

The container speaks plain HTTP on purpose so it can sit behind the nginx you
already run on the host. These steps assume Ubuntu with nginx and certbot.

### 1. Point DNS at the server

Create an `A` record for the hostname you want, pointing at the VPS IP. Then
confirm it resolves before going further — certbot will fail if it does not:

```bash
dig +short landing.example.com
```

### 2. Add a server block

```bash
sudo tee /etc/nginx/sites-available/chiket-landing >/dev/null <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name landing.example.com;

    location / {
        proxy_pass http://127.0.0.1:8417;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # The page is ~2.5 MB gzipped. nginx buffers proxied responses with about
        # 32 KB by default, so without this every request spools through a temp
        # file on disk.
        proxy_buffer_size       64k;
        proxy_buffers        16 64k;
        proxy_busy_buffers_size 128k;
    }
}
EOF
```

Drop the `listen [::]:80;` line if `nginx -t` complains that IPv6 is unavailable.

### 3. Enable it

```bash
sudo ln -s /etc/nginx/sites-available/chiket-landing /etc/nginx/sites-enabled/
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 4. Get the certificate

```bash
sudo certbot --nginx -d landing.example.com
```

Certbot edits the block in place: it adds the `443` server, installs the
certificate, and sets up the HTTP-to-HTTPS redirect. Renewal is automatic via
its systemd timer.

### 5. Check it

```bash
curl -sI https://landing.example.com | head -n 1
```

### Optional: stop exposing the port directly

Once the domain works, the container no longer needs a public port — only nginx
on the same host talks to it. Bind it to loopback in `docker-compose.yml`:

```yaml
    ports:
      - "127.0.0.1:${PORT:-8417}:80"
```

Then `docker compose up -d`. After this `http://<ip>:8417` stops answering from
the outside, which is the point; the domain keeps working.

---

## The Google Play pages

Play requires two publicly reachable URLs:

```
https://<your-domain>/privacy-policy
https://<your-domain>/delete-account
https://<your-domain>/beta-terms
```

The page explains where the **Delete account** button is inside the app. It is static,
needs no backend, and works with JavaScript disabled.

Note that `location /` returns **404** for unknown paths rather than falling back to
`index.html`. That is deliberate: with a catch-all fallback, `/delete-account` and
`/privacy-policy` answered 200 with the marketing page, so a reviewer following the link would
have been shown the landing page instead of the policy.

---

## What's in here

| File | Purpose |
| --- | --- |
| `index.html` | The entire page, ~3.3 MB with all assets inlined |
| `privacy-policy.html` | Privacy policy, served at `/privacy-policy` for Google Play |
| `beta-terms.html` | Founder Beta Terms, served at `/beta-terms` |
| `beta.html` | Two-step tester onboarding for ad traffic, at `/beta.html` and `/beta` |
| `delete-account.html` | Account-deletion instructions, served at `/delete-account` for Google Play |
| `robots.txt` | Crawl rules, points at the sitemap |
| `sitemap.xml` | The four indexable URLs |
| `og.jpg` | Social preview image for link unfurls |
| `Dockerfile` | Precompresses the page, then serves it from `nginx:1.27-alpine` |
| `nginx.conf` | `gzip_static`, `no-cache`, `/healthz`, `/delete-account`, 404 on unknown paths |
| `docker-compose.yml` | One service, restart-on-failure, healthcheck, capped logs |
| `.env` | Host port, read automatically by Compose |
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
