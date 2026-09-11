"""Wrap the artifact build into a standalone HTML document.

The page is authored for Claude's artifact host, which injects the doctype, a charset
and viewport meta, and a small reset. Served from nginx it gets none of that, so
without this wrapper the page renders in quirks mode and mobile lays out at 980px.

Usage:  python build-standalone.py <artifact-build.html> [out.html]
"""
import io
import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else 'landing.html'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'index.html'

body = io.open(SRC, encoding='utf-8').read()

if body.lstrip().lower().startswith('<!doctype'):
    sys.exit('%s already looks like a full document - nothing to wrap.' % SRC)

split = '</style>'
if body.count(split) != 1:
    sys.exit('expected exactly one </style>, found %d' % body.count(split))
head, rest = body.split(split, 1)
head += split

HEAD = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark">
<meta property="og:type" content="website">
<meta property="og:title" content="Chiket - Parking compliance for Chicago drivers">
<meta property="og:description" content="Chiket monitors Chicago street sweeping, winter parking bans, and permit deadlines, and alerts you before a ticket becomes a boot.">
<meta property="og:image" content="og.jpg">
<meta name="twitter:card" content="summary_large_image">
<style>:root{color-scheme:dark}[hidden]{display:none!important}</style>
"""

TAIL = """
</body>
</html>
"""

doc = HEAD + head + '\n</head>\n<body>\n' + rest.strip() + TAIL
# newline='' keeps LF on Windows too - this file is served from a Linux container
io.open(OUT, 'w', encoding='utf-8', newline='').write(doc)
print('wrote %s  %.2f MB' % (OUT, len(doc.encode('utf-8')) / 1048576))
