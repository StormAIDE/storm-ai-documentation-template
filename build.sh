#!/usr/bin/env bash
set -euo pipefail

# ponytail: hardcoded macOS LibreOffice path; upgrade: $(which soffice) with fallback
SOFFICE=/Applications/LibreOffice.app/Contents/MacOS/soffice

input="${1:-sample.md}"
# ponytail: strips path, swaps extension, collapses non-alphanumeric runs to dashes
output="$(basename "${input%.*}" | tr -cs '[:alnum:]' '-' | sed 's/-$//')".pdf

# clean up any temp files we create on exit
_tmpfiles=()
trap 'rm -f "${_tmpfiles[@]+"${_tmpfiles[@]}"}"' EXIT

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
    _mime_html="${input%.doc}_mime.html"
    _tmpfiles+=("$_mime_html")
    python3 -c "
import email, sys
with open(sys.argv[1], 'rb') as f:
    msg = email.message_from_bytes(f.read())
for part in msg.walk():
    if part.get_content_type() == 'text/html':
        sys.stdout.buffer.write(part.get_payload(decode=True))
        break
" "$input" > "$_mime_html"

# rewrite Confluence <pre class="syntaxhighlighter-pre"> into <pre><code>
# so Pandoc reads it as a real code block with indentation intact
_pre_html="${_mime_html%.html}_pre.html"
_tmpfiles+=("$_pre_html")
python3 - "$_mime_html" > "$_pre_html" <<'PY'
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

input="$(realpath "$_pre_html")"
fmt=html
  else
    _docx="${input%.doc}.docx"
    _tmpfiles+=("$_docx")
    "$SOFFICE" --headless --convert-to docx \
      --outdir "$(dirname "$(realpath "$input")")" "$input"
    input="$(realpath "$_docx")"
  fi
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
