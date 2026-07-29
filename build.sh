#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p .texlive-cache
export TEXMFVAR="$PWD/.texlive-cache"

pandoc sample.md \
  --from markdown \
  --template storm-reply.latex \
  --pdf-engine=lualatex \
  --syntax-highlighting=none \
  --number-sections \
  --resource-path=. \
  --output storm-reply-markdown-poc.pdf
