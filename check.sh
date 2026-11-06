#!/bin/bash
# AI testing training: system check for macOS (also runs on Linux).
# Read-only. Installs nothing, changes no settings, sends no personal data.
# Run:   bash check.sh
# Optional: export OPENROUTER_API_KEY=... first to also test one real model call.

OUT="$(pwd)/system-check-result.txt"
: > "$OUT"
say() { printf '%s\n' "$1" | tee -a "$OUT"; }
PUBLIC_CA="Let's Encrypt|DigiCert|Google Trust|Sectigo|GlobalSign|Amazon|Cloudflare|Baltimore|Microsoft|Entrust|GoDaddy|USERTrust|Comodo|ISRG|Fastly|Certainly"

# curl ignores the macOS system proxy, so pass it explicitly when one is set.
PROXY_ARGS=()
SYS_PROXY=""
if command -v scutil >/dev/null 2>&1; then
  P=$(scutil --proxy)
  if echo "$P" | grep -q 'HTTPSEnable : 1'; then
    SYS_PROXY="$(echo "$P" | awk '/HTTPSProxy :/{h=$3} /HTTPSPort :/{p=$3} END{print h":"p}')"
  fi
  PAC=$(echo "$P" | awk '/ProxyAutoConfigURLString :/{print $3}')
fi
if [ -n "$SYS_PROXY" ] && [ -z "${HTTPS_PROXY}${https_proxy}" ]; then PROXY_ARGS=(-x "http://$SYS_PROXY"); fi

test_url() { # name url want_json
  local name="$1" url="$2" want_json="$3" tmp body status issuer verdict detail tls route
  tmp=$(mktemp)
  status=$(curl -sS -o "$tmp" -w '%{http_code}' -m 15 -A 'training-system-check/1.0' "${PROXY_ARGS[@]}" -v "$url" 2>"$tmp.err")
  issuer=$(grep -i '^\*  *issuer:' "$tmp.err" | head -1 | sed 's/^\*  *issuer: *//I')
  body=$(head -c 200 "$tmp" | tr -d '[:space:]')
  route="direct"; [ ${#PROXY_ARGS[@]} -gt 0 ] && route="proxy $SYS_PROXY"; [ -n "${HTTPS_PROXY}${https_proxy}" ] && route="proxy ${HTTPS_PROXY:-$https_proxy}"
  case "$body" in \{*|\[*) is_json=1 ;; *) is_json=0 ;; esac
  if [ "$status" = "000" ]; then verdict=FAIL; detail=$(grep -v '^[*<>{}]' "$tmp.err" | tail -1)
  elif [ "$status" = "407" ]; then verdict=BLOCKED; detail="HTTP 407 (proxy wants authentication)"
  elif [ "$status" = "403" ] && ! { [ "$want_json" = 1 ] && [ $is_json = 1 ]; }; then verdict=BLOCKED; detail="HTTP 403 (proxy or firewall)"
  elif [ "$want_json" = 1 ] && [ $is_json = 0 ]; then verdict="BLOCKED?"; detail="HTTP $status, not the expected API answer (block page?)"
  elif [ "$status" -ge 500 ]; then verdict=FAIL; detail="HTTP $status"
  else verdict=OK; detail="HTTP $status"; fi
  tls=""
  if [ -n "$issuer" ]; then
    if echo "$issuer" | grep -Eq "$PUBLIC_CA"; then tls=" | issuer: $issuer"; else tls=" | TLS INSPECTED? issuer: $issuer"; fi
  fi
  say "$(printf '%-9s %-28s %s | %s%s' "$verdict" "$name" "$detail" "$route" "$tls")"
  rm -f "$tmp" "$tmp.err"
}

tool() { # name cmd arg
  if command -v "$2" >/dev/null 2>&1; then
    say "$(printf '%-9s %-28s %s (%s)' FOUND "$1" "$("$2" "$3" 2>&1 | head -1)" "$(command -v "$2")")"
  else say "$(printf '%-9s %-28s not installed' - "$1")"; fi
}

say "=== AI testing training: system check ($(uname -s)) ==="
say "Date: $(date '+%Y-%m-%d %H:%M')  |  OS: $(sw_vers -productVersion 2>/dev/null || uname -r)  |  arch: $(uname -m)"
say ""
say "--- 1. Model providers (any HTTP answer from the API means reachable; 401 is fine) ---"
test_url 'OpenRouter API'    'https://openrouter.ai/api/v1/models' 1
test_url 'OpenAI API'        'https://api.openai.com/v1/models' 1
test_url 'Anthropic API'     'https://api.anthropic.com/v1/models' 1
test_url 'Google Gemini API' 'https://generativelanguage.googleapis.com/v1beta/models' 1
say ""
say "--- 2. Package sources (needed to install promptfoo and the harness) ---"
test_url 'npm registry'      'https://registry.npmjs.org/promptfoo' 1
test_url 'PyPI index'        'https://pypi.org/simple/streamlit/' 0
test_url 'PyPI files'        'https://files.pythonhosted.org/' 0
test_url 'nodejs.org'        'https://nodejs.org/dist/index.json' 1
test_url 'python.org'        'https://www.python.org/ftp/python/' 0
test_url 'astral.sh (uv)'    'https://astral.sh/uv/install.sh' 0
test_url 'GitHub'            'https://github.com/' 0
say ""
say "--- 3. Installed tools ---"
tool Node node --version
tool npm npm --version
tool Python python3 --version
tool uv uv --version
tool git git --version
tool Docker docker --version
say ""
say "--- 4. Proxy configuration ---"
[ "$(uname -s)" = "Darwin" ] && say "macOS HTTPS proxy: ${SYS_PROXY:-none}  |  PAC: ${PAC:-none}"
for v in HTTPS_PROXY https_proxy HTTP_PROXY NO_PROXY NODE_EXTRA_CA_CERTS SSL_CERT_FILE REQUESTS_CA_BUNDLE; do
  [ -n "${!v}" ] && say "env $v = ${!v}"
done
command -v npm >/dev/null 2>&1 && say "npm https-proxy: $(npm config get https-proxy 2>/dev/null) | npm cafile: $(npm config get cafile 2>/dev/null)"
say ""
say "--- 5. Same check from inside the tools (they do not always use the system proxy) ---"
if command -v npm >/dev/null 2>&1; then
  r=$(npm view promptfoo@0.124.1 version 2>&1 | tail -1)
  if [ "$(echo "$r" | tr -d '[:space:]')" = "0.124.1" ]; then say "OK        npm can reach its registry"; else say "FAIL      npm cannot reach its registry: $r"; fi
fi
if command -v python3 >/dev/null 2>&1; then
  r=$(python3 -c "import urllib.request as u;print(u.urlopen('https://openrouter.ai/api/v1/models',timeout=15).status)" 2>&1 | tail -1)
  if [ "$r" = "200" ]; then say "OK        Python can reach OpenRouter"; else say "FAIL      Python cannot reach OpenRouter: $r"; fi
fi
if ! command -v npm >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then say "skipped   (neither Node nor Python installed)"; fi
say ""
say "--- 6. One real model call (only if OPENROUTER_API_KEY is set) ---"
if [ -n "$OPENROUTER_API_KEY" ]; then
  r=$(curl -sS -m 30 "${PROXY_ARGS[@]}" https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" -H 'Content-Type: application/json' \
      -d '{"model":"anthropic/claude-haiku-5.5","max_tokens":30,"messages":[{"role":"user","content":"Reply with exactly: pong"}]}' 2>&1)
  if echo "$r" | grep -q '"content"'; then say "OK        model answered: $(echo "$r" | sed -n 's/.*"content": *"\([^"]*\)".*/\1/p' | head -1)"
  else say "FAIL      model call: $(echo "$r" | head -c 300)"; fi
else say "skipped   (no key set)"; fi
say ""
say "=== end ==="
echo "Saved to $OUT"
command -v pbcopy >/dev/null 2>&1 && pbcopy < "$OUT" && echo "Copied to clipboard: paste it into the Teams chat."
exit 0
