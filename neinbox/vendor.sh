#!/usr/bin/env bash
# Re-fetch the vendored fonts and libraries.
#
# Everything this site needs is served from this site. Nothing is pulled from
# Google Fonts or a third-party CDN at page load, so no visitor IP is handed to
# anyone for typography or for reading a PDF. That is a GDPR position, not a
# performance one: embedding Google Fonts by URL transmits the visitor's IP to
# the USA, which is what produced the German Abmahnung wave after
# LG München I, 20.01.2022, Az. 3 O 17493/20.
#
# Run from the neinbox/ directory. Requires curl and tar.
# You should not normally need this — the files are committed. It exists so the
# provenance of every binary in the repo is reproducible.

set -euo pipefail
cd "$(dirname "$0")"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

PDFJS_VERSION="3.11.174"
JSZIP_VERSION="3.10.1"

# Exactly the weights the stylesheet uses. Archivo is variable-only on Google,
# so one file covers 500-700; Source Serif is requested without the optical-size
# axis, which is what kept it from being four times the size.
FONT_URL="https://fonts.googleapis.com/css2"
FONT_URL+="?family=Archivo:wght@500;600;700"
FONT_URL+="&family=IBM+Plex+Mono:wght@400;500"
FONT_URL+="&family=Source+Serif+4:ital,wght@0,400;1,400"
FONT_URL+="&display=swap"

echo "==> fonts"
mkdir -p fonts
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A browser user-agent is required, or Google serves ttf instead of woff2.
curl -fsS -A "$UA" "$FONT_URL" -o "$tmp/gf.css"

python3 - "$tmp/gf.css" <<'PY'
import os, re, subprocess, sys

css = open(sys.argv[1], encoding="utf-8").read()
blocks = re.findall(r'/\* ([a-z-]+) \*/\s*(@font-face \{.*?\})', css, re.S)
rules, seen = [], set()

for subset, block in blocks:
    # latin and latin-ext only. latin-ext matters here: this site's audience
    # includes people whose names carry Polish, Czech and Turkish diacritics.
    if subset not in ("latin", "latin-ext"):
        continue
    fam = re.search(r"font-family: '([^']+)'", block).group(1)
    weight = re.search(r'font-weight: ([^;]+);', block).group(1)
    style = re.search(r'font-style: ([^;]+);', block).group(1)
    rng = re.search(r'unicode-range: ([^;]+);', block).group(1)
    url = re.search(r'url\((https://[^)]+)\)', block).group(1)

    if fam == "Archivo":
        # Variable file: identical bytes for every requested weight.
        weight, key = "500 700", ("Archivo", subset)
        if key in seen:
            continue
        seen.add(key)

    slug = f"{fam.lower().replace(' ', '-')}-{weight.replace(' ', '-')}-{style}-{subset}.woff2"
    subprocess.run(["curl", "-fsS", "-o", os.path.join("fonts", slug), url], check=True)
    assert open(os.path.join("fonts", slug), "rb").read(4) == b"wOF2", slug
    print(f"    {slug}")
    rules.append(
        f"@font-face {{\n"
        f"  font-family: '{fam}';\n"
        f"  font-style: {style};\n"
        f"  font-weight: {weight};\n"
        f"  font-display: swap;\n"
        f"  src: url('fonts/{slug}') format('woff2');\n"
        f"  unicode-range: {rng};\n}}"
    )

open("fonts/fontface.css", "w", encoding="utf-8").write("\n".join(rules) + "\n")
print(f"    -> fonts/fontface.css ({len(rules)} rules)")
print("    paste these rules into the <style> block of index.html,")
print("    impressum.html and datenschutz.html if they have changed.")
PY

echo "==> libraries"
mkdir -p vendor

curl -fsS -o "$tmp/jszip.tgz" \
  "https://registry.npmjs.org/jszip/-/jszip-${JSZIP_VERSION}.tgz"
tar xzf "$tmp/jszip.tgz" -C "$tmp"
cp "$tmp/package/dist/jszip.min.js"  "vendor/jszip-${JSZIP_VERSION}.min.js"
cp "$tmp/package/LICENSE.markdown"   "vendor/jszip-LICENSE.txt"
rm -rf "$tmp/package"
echo "    jszip-${JSZIP_VERSION}.min.js"

curl -fsS -o "$tmp/pdfjs.tgz" \
  "https://registry.npmjs.org/pdfjs-dist/-/pdfjs-dist-${PDFJS_VERSION}.tgz"
tar xzf "$tmp/pdfjs.tgz" -C "$tmp"
cp "$tmp/package/build/pdf.min.js"        "vendor/pdf-${PDFJS_VERSION}.min.js"
cp "$tmp/package/build/pdf.worker.min.js" "vendor/pdf.worker-${PDFJS_VERSION}.min.js"
cp "$tmp/package/LICENSE"                 "vendor/pdfjs-LICENSE.txt"
echo "    pdf-${PDFJS_VERSION}.min.js"
echo "    pdf.worker-${PDFJS_VERSION}.min.js"

echo
echo "Done. If you changed a version, update the paths in index.html:"
echo "  - the two <script src=\"vendor/...\"> tags"
echo "  - pdfjsLib.GlobalWorkerOptions.workerSrc in the script block"
echo
echo "Licences: pdf.js is Apache-2.0, JSZip is MIT/GPLv3 dual-licensed."
echo "Both licence texts are kept in vendor/ as redistribution requires."
