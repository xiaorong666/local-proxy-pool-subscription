#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${SUBS_CHECK_VERSION:-v1.13.3}"
ARCHIVE="subs-check_Linux_x86_64.tar.gz"
URL="https://github.com/sinspired/subs-check/releases/download/${VERSION}/${ARCHIVE}"

mkdir -p tmp public
touch tmp/run-start.stamp

if [[ ! -x tmp/subs-check ]]; then
  curl -L --retry 3 --retry-delay 5 -o "tmp/${ARCHIVE}" "$URL"
  tar -xzf "tmp/${ARCHIVE}" -C tmp
  chmod +x tmp/subs-check
fi

set +e
timeout "${SUBS_CHECK_TIMEOUT:-55m}" tmp/subs-check -f config/config.yaml
code=$?
set -e

if [[ "$code" != "0" && "$code" != "124" ]]; then
  exit "$code"
fi

test -s public/all.yaml
test -s public/mihomo.yaml
test -s public/base64.txt
test public/all.yaml -nt tmp/run-start.stamp
test public/mihomo.yaml -nt tmp/run-start.stamp
test public/base64.txt -nt tmp/run-start.stamp

cat > public/index.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>Proxy Subscription</title>
<h1>Proxy Subscription</h1>
<ul>
  <li><a href="./mihomo.yaml">mihomo.yaml</a></li>
  <li><a href="./all.yaml">all.yaml</a></li>
  <li><a href="./base64.txt">base64.txt</a></li>
  <li><a href="./history.yaml">history.yaml</a></li>
</ul>
HTML
