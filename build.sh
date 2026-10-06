#!/usr/bin/env bash
set -euo pipefail

# ponytail: hardcoded macOS LibreOffice path; upgrade: $(which soffice) with fallback
SOFFICE=/Applications/LibreOffice.app/Contents/MacOS/soffice

# resolve before the `cd` below so relative paths from any working dir work
input="$(realpath "${1:-sample.md}")"
# ponytail: strips path, swaps extension, collapses non-alphanumeric runs to dashes
output="$(basename "${input%.*}" | tr -cs '[:alnum:]' '-' | sed 's/-$//')".pdf

# intermediates live in a private temp dir, never next to the user's input
# (a real Foo.doc would otherwise overwrite and then delete an existing Foo.docx)
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# detect pandoc input format from file extension
ext="${input##*.}"
case "$ext" in
md|markdown) fmt=markdown ;;
rst)         fmt=rst ;;
html|htm)    fmt=html ;;
doc|docx)    fmt=docx ;;
tex)         fmt=latex ;;
*)           echo "Unknown input format: .$ext" >&2; exit 1 ;;
esac

# .doc handling: may be a real Word binary or a MIME/HTML export (e.g. from Confluence)
# ponytail: MIME detection covers Confluence .doc exports; true .doc falls back to LibreOffice
if [[ "$ext" == "doc" ]]; then
if head -1 "$input" | grep -qi "^mime-version\|^content-type\|^date:\|^message-id"; then
# MIME/HTML disguised as .doc — extract the HTML part directly
_mime_html="$tmpdir/mime.html"
python3 -c "
import email, sys
with open(sys.argv[1], 'rb') as f:
    msg = email.message_from_bytes(f.read())
for part in msg.walk():
    if part.get_content_type() == 'text/html':
        sys.stdout.buffer.write(part.get_payload(decode=True))
        break
" "$input" > "$_mime_html"
input="$_mime_html"
fmt=html
else
"$SOFFICE" --headless --convert-to docx --outdir "$tmpdir" "$input"
input="$tmpdir/$(basename "${input%.doc}").docx"
fi
fi

# Confluence code blocks: rewrite <pre class="syntaxhighlighter-pre"> to
# <pre><code> so Pandoc reads them as code blocks with indentation intact.
# Pandoc's HTML reader collapses whitespace in loose inline content, so without
# this the indentation is lost. Applies to any HTML input: .doc MIME payloads,
# REST export_view, or a saved .html file.
if [[ "$fmt" == "html" ]]; then
_pre_html="$tmpdir/pre.html"
python3 - "$input" > "$_pre_html" <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8', errors='replace').read()

def fix(m):
    inner = re.sub(r'<[^>]+>', '', m.group(1))   # strip tags inside pre
    return '<pre><code>' + inner + '</code></pre>'

src = re.sub(
    r'<pre[^>]*class="[^"]*syntaxhighlighter-pre[^"]*"[^>]*>(.*?)</pre>',
    fix, src, flags=re.S)
sys.stdout.write(src)
PY
input="$_pre_html"
fi

cd "$(dirname "$0")"
mkdir -p .texlive-cache
export TEXMFVAR="$PWD/.texlive-cache"
export PATH="/Applications/LibreOffice.app/Contents/MacOS:$PATH"

# --number-sections only for text formats; Word/HTML docs often already have numbered headings
case "$fmt" in
markdown|rst|latex) extra_args="--number-sections" ;;
*)                  extra_args="" ;;
esac

# Server mode (STORM_UNTRUSTED=1): drop-raw.lua strips all raw LaTeX from the
# input; additionally forbid shell escape and file access outside the build dir.
if [[ "${STORM_UNTRUSTED:-}" == "1" ]]; then
extra_args+=" --pdf-engine-opt=--no-shell-escape"
export openin_any=p openout_any=p
fi

pandoc "$input" \
--from "$fmt" \
--lua-filter drop-raw.lua \
--template storm-reply.latex \
--pdf-engine=lualatex \
--syntax-highlighting=none \
--toc \
--toc-depth=3 \
  ${extra_args:+$extra_args} \
--resource-path=. \
--output "$output"