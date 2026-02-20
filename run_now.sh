#!/usr/bin/env bash
set -euo pipefail

PY_VERSION="${PY_VERSION:-3.11.14}"
MODEL="${MODEL:-anthropic/claude-opus-4-5}"
PROMPT="${PROMPT:-What is 2+2? Reply in one short sentence.}"
API_KEY="${OPENROUTER_API_KEY:-}"
FORCE_ONBOARD=0

usage() {
  cat <<USAGE
Usage: OPENROUTER_API_KEY=sk-or-v1-xxx ./run_now.sh [options]

Options:
  --api-key <key>      OpenRouter API key (or use OPENROUTER_API_KEY env)
  --model <model>      Model id (default: ${MODEL})
  --prompt <text>      Prompt to send (default: ${PROMPT})
  --python <version>   pyenv Python version (default: ${PY_VERSION})
  --force-onboard      Re-run onboarding even if config already exists
  -h, --help           Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key) API_KEY="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --python) PY_VERSION="$2"; shift 2 ;;
    --force-onboard) FORCE_ONBOARD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if ! command -v pyenv >/dev/null 2>&1; then
  echo "Error: pyenv is required for this script." >&2
  exit 1
fi

if [[ -z "$API_KEY" ]]; then
  echo "Error: missing OpenRouter API key. Pass --api-key or OPENROUTER_API_KEY." >&2
  exit 1
fi

export PYENV_VERSION="$PY_VERSION"

echo "[1/5] Verifying Python..."
python -c 'import sys; assert sys.version_info >= (3, 11), f"Need >=3.11, got {sys.version}"; print(sys.version.split()[0])'

echo "[2/5] Installing nanobot..."
pip install -e . >/dev/null

CONFIG_PATH="$HOME/.nanobot/config.json"

if [[ ! -f "$CONFIG_PATH" || "$FORCE_ONBOARD" -eq 1 ]]; then
  echo "[3/5] Running onboarding..."
  nanobot onboard >/dev/null
else
  echo "[3/5] Config exists. Skipping onboarding."
fi

echo "[4/5] Writing provider config to $CONFIG_PATH ..."
python - <<PY
import json
from pathlib import Path

config_path = Path.home() / '.nanobot' / 'config.json'
config_path.parent.mkdir(parents=True, exist_ok=True)
if config_path.exists():
    try:
        cfg = json.loads(config_path.read_text())
    except Exception:
        cfg = {}
else:
    cfg = {}

cfg.setdefault('providers', {})
cfg['providers']['openrouter'] = {'apiKey': '''$API_KEY'''}
cfg.setdefault('agents', {})
cfg['agents']['defaults'] = {'model': '''$MODEL'''}

config_path.write_text(json.dumps(cfg, indent=2) + '\n')
print(config_path)
PY

echo "[5/5] Sending first message..."
nanobot agent -m "$PROMPT"
