# Run nanobot in a single hit

If you want this repo to run **right now**, use one command from repo root:

```bash
OPENROUTER_API_KEY="sk-or-v1-xxx" ./run_now.sh
```

What it does automatically:
1. Uses Python 3.11.14 via `pyenv`
2. Installs this repo with `pip install -e .`
3. Runs onboarding if `~/.nanobot/config.json` is missing
4. Writes OpenRouter config + default model
5. Sends a first test message (`What is 2+2?...`)

## Optional flags

```bash
./run_now.sh --help
```

Examples:

```bash
OPENROUTER_API_KEY="sk-or-v1-xxx" ./run_now.sh --prompt "Say hello"
OPENROUTER_API_KEY="sk-or-v1-xxx" ./run_now.sh --model "openai/gpt-4o-mini"
OPENROUTER_API_KEY="sk-or-v1-xxx" ./run_now.sh --python 3.12.12
```
