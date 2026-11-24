# The first stage exists only to precompress the pages, so nginx can hand over the
# .gz via gzip_static instead of compressing on every request.
FROM alpine:3.20 AS compress
WORKDIR /src
COPY index.html delete-account.html delete-data.html privacy-policy.html beta-terms.html beta.html \
     robots.txt sitemap.xml og.jpg favicon.png favicon.svg apple-touch-icon.png logo.svg ./
RUN gzip -9 -k index.html delete-account.html delete-data.html privacy-policy.html beta-terms.html beta.html

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=compress /src/index.html /src/index.html.gz /usr/share/nginx/html/
COPY --from=compress /src/delete-account.html /src/delete-account.html.gz /usr/share/nginx/html/
COPY --from=compress /src/delete-data.html /src/delete-data.html.gz /usr/share/nginx/html/
COPY --from=compress /src/privacy-policy.html /src/privacy-policy.html.gz /usr/share/nginx/html/
COPY --from=compress /src/beta-terms.html /src/beta-terms.html.gz /usr/share/nginx/html/
COPY --from=compress /src/beta.html /src/beta.html.gz /usr/share/nginx/html/
COPY --from=compress /src/robots.txt /src/sitemap.xml /usr/share/nginx/html/
COPY --from=compress /src/og.jpg /src/favicon.png /src/favicon.svg /src/apple-touch-icon.png /src/logo.svg /usr/share/nginx/html/
# Hero video, its poster stills and the photographs. Already compressed formats, and
# every name carries a content hash, so nginx can let browsers keep them for a year.
COPY assets/ /usr/share/nginx/html/assets/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
