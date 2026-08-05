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
    input="$(realpath "$_mime_html")"
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
  ${extra_args:+$extra_args} \
  --resource-path=. \
  --output "$output"
