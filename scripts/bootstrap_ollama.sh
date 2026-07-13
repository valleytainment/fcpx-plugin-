#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen3:4b-instruct-2507-q4_K_M"
CUSTOM_MODEL="valleytainment-fcp-qwen3-4b"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama is not installed. Install the macOS application first, then rerun this script." >&2
  exit 1
fi

ollama pull "$MODEL"
ollama create "$CUSTOM_MODEL" -f "$ROOT/config/Modelfile"

echo
printf 'Ready. Test with:\n  ollama run %s\n' "$CUSTOM_MODEL"
