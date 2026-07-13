#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${FCP_AI_MODEL:-qwen3:4b-instruct-2507-q4_K_M}"

curl --fail --silent http://127.0.0.1:11434/api/tags >/dev/null
printf 'Ollama reachable.\n'

if ! ollama list | grep -Fq "$MODEL"; then
  printf 'Model not present: %s\n' "$MODEL" >&2
  exit 1
fi
printf 'Model present: %s\n' "$MODEL"

cd "$ROOT"
swift test
printf 'Swift tests passed.\n'
