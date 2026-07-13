# Runtime Compatibility

## Default runtime

- Provider: Ollama native `/api/chat`
- Model: `qwen3:4b-instruct-2507-q4_K_M`
- Quantization: Q4_K_M
- Download size shown by Ollama: approximately 2.5 GB
- Configured context for this starter: 32,768 tokens

## macOS constraint

Current Ollama releases require macOS 14 Sonoma or newer. Apple Silicon uses CPU/GPU acceleration; Intel Macs are CPU-only in Ollama.

## Older macOS route

Do not couple the Final Cut extension to a forced operating-system upgrade. The core contracts are provider-neutral even though Phase 0 ships an `OllamaClient`. Add a `LocalModelClient` protocol and a llama.cpp/OpenAI-compatible implementation when the target workstation cannot run current Ollama.

## Production local-only setting

Disable cloud features in Ollama's server configuration and keep the endpoint bound to loopback. Do not expose port 11434 to the LAN unless authentication and transport security are added.
