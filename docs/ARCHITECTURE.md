# Architecture

```text
┌────────────────────────────────────────────────────────────┐
│ Final Cut Pro 10.6.5                                       │
│                                                            │
│  FCP AI Operator Workflow Extension                        │
│  ├─ Chat / status / safety mode                             │
│  ├─ Public FCP timeline observer                            │
│  ├─ WorkflowExtensionFCPAdapter                             │
│  └─ Local Ollama client                                    │
└──────────────────────────────┬─────────────────────────────┘
                               │ HTTP on loopback
┌──────────────────────────────▼─────────────────────────────┐
│ Ollama                                                     │
│ qwen3:4b-instruct-2507-q4_K_M                              │
└────────────────────────────────────────────────────────────┘

Shared Swift package:

FCPAIKit
├─ OllamaClient
├─ FCPToolCatalog
├─ FCPAgent
├─ AgentSafetyPolicy
├─ ArtifactJournal
├─ FCPAdapter protocol
└─ MockFCPAdapter
```

## Why the Phase 0 agent runs inside the extension

This reduces the first integration surface:

- No XPC protocol is required yet.
- No background service installation is required.
- Qwen can immediately observe the public Final Cut timeline proxy.
- Tool contracts and safety behavior remain identical to the future companion service.

Before long-running media analysis is added, move `FCPAgent` into the companion app and connect the extension through XPC or an App Group message bus. The tool schemas and adapters do not need to change.

## Adapter strategy

```text
FCPAdapter
├─ WorkflowExtensionFCPAdapter   public Apple API, stable, limited
├─ CommandPostFCPAdapter         deep commands, preferred Phase 1
├─ AccessibilityFCPAdapter       fallback for missing commands
├─ FCPXMLAdapter                 deterministic project construction
└─ MockFCPAdapter                tests and model evaluation
```

The model never receives raw mouse access. It invokes typed tools. Each adapter is responsible for preconditions, execution, and verification.
