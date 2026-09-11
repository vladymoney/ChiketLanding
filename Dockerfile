# The first stage exists only to precompress the page. index.html is ~3.3 MB of
# inlined base64; gzipping it once at build time is far cheaper than doing it per
# request, and nginx serves the .gz directly via gzip_static.
FROM alpine:3.20 AS compress
WORKDIR /src
COPY index.html og.jpg ./
RUN gzip -9 -k index.html

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=compress /src/index.html /src/index.html.gz /src/og.jpg /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
