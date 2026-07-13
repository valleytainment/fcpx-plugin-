#!/usr/bin/env bash
# One-command installer: Ollama model + plugin build + install + register + open Final Cut Pro.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_APP="/Applications/Valleytainment FCP AI.app"
FCP_APP="${FCP_APP:-/Applications/Final Cut Pro 2.app}"
MODEL_PRIMARY="qwen3:4b-instruct-2507-q4_K_M"
MODEL_FALLBACK="qwen2.5:14b"
RUNTIME_DIR="$HOME/Library/Application Support/ValleytainmentFCPAI"

echo "=============================================="
echo " Valleytainment FCP AI — One-Command Installer"
echo "=============================================="
echo

if [[ ! -d "$FCP_APP" ]]; then
  echo "Final Cut Pro not found at: $FCP_APP" >&2
  echo "Install Final Cut Pro, or set FCP_APP to your .app path." >&2
  exit 1
fi

echo "==> [1/5] Ensuring Ollama is running"
if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama is not installed." >&2
  echo "Install from https://ollama.com/download and rerun:" >&2
  echo "  $ROOT/scripts/install_plugin.sh" >&2
  exit 1
fi

if ! curl -sf --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "Starting Ollama server..."
  nohup ollama serve >/tmp/valleytainment-ollama.log 2>&1 &
  sleep 4
fi

SELECTED_MODEL="$MODEL_PRIMARY"
echo "==> [2/5] Pulling local model (this may take a while)"
if ! ollama pull "$MODEL_PRIMARY" 2>/tmp/valleytainment-pull.log; then
  echo "Primary model unavailable on this Ollama build; falling back to $MODEL_FALLBACK"
  ollama pull "$MODEL_FALLBACK"
  SELECTED_MODEL="$MODEL_FALLBACK"
fi

mkdir -p "$RUNTIME_DIR"
cat > "$RUNTIME_DIR/runtime-config.json" <<JSON
{
  "ollamaBaseURL": "http://127.0.0.1:11434",
  "model": "$SELECTED_MODEL"
}
JSON
echo "Wrote runtime config: $RUNTIME_DIR/runtime-config.json"

echo "==> [3/5] Building plugin"
FCP_APP="$FCP_APP" bash "$ROOT/scripts/build_plugin.sh"

echo "==> [4/5] Installing to $INSTALL_APP"
sudo rm -rf "$INSTALL_APP" 2>/dev/null || rm -rf "$INSTALL_APP"
cp -R "$ROOT/dist/FCPAIHost.app" "$INSTALL_APP"

APPEX="$INSTALL_APP/Contents/PlugIns/FCPWorkflowExtension.appex"
if command -v pluginkit >/dev/null 2>&1; then
  pluginkit -a "$APPEX" 2>/dev/null || true
fi

echo "==> [5/5] Launching Final Cut Pro"
open -a "$FCP_APP" || open "$FCP_APP"

cat <<MSG

==============================================
 INSTALL COMPLETE
==============================================

Your only steps inside Final Cut Pro:

  1. Open  Window → Extensions  (or the Extensions toolbar button)
  2. Choose  FCP AI Operator
  3. Open a project timeline, click  Refresh , then  Run local Qwen

Model: $SELECTED_MODEL
Ollama: http://127.0.0.1:11434
Host app: $INSTALL_APP

If the extension does not appear, quit Final Cut Pro completely and reopen it.
For deep blade/trim edits, Phase 1 CommandPost bridge is still required.

MSG
