# Valleytainment FCP AI Operator — Phase 0 Starter

A local-first AI operator foundation for **Final Cut Pro 10.6.5** using:

- **Qwen3-4B-Instruct-2507** through Ollama
- Swift 6 agent core
- Typed, auditable Final Cut tool contracts
- Observe / Suggest / Execute Safe / Auto Edit safety modes
- Apple Final Cut Pro Workflow Extension source templates
- Public timeline inspection and playhead control
- Mock editing adapter for safe agent-loop development
- Per-tool execution artifacts and replayable test fixtures

> Phase 0 deliberately does **not** pretend that Apple's public workflow-extension API can blade, trim, duplicate, or export arbitrary projects. The included extension uses the official timeline surface for timeline state and playhead movement. Deep editing is the next adapter layer.

## Quick install (one command)

```bash
chmod +x scripts/*.sh
./scripts/install_plugin.sh
```

Then in Final Cut Pro: **Window → Extensions → FCP AI Operator**.

See `docs/ONE_COMMAND_SETUP.md` for details and troubleshooting.

## Repository map

```text
.
├── Package.swift
├── Sources/
│   ├── FCPAIKit/              # Model client, tool schemas, safety, agent loop
│   └── FCPAIHostCLI/          # Runnable local Qwen + mock FCP harness
├── Tests/FCPAIKitTests/       # 5 deterministic safety/adapter tests
├── macOS/
│   ├── FCPAIHost/             # Companion macOS settings app source
│   └── FCPWorkflowExtension/  # Embedded Final Cut extension source
├── config/
│   ├── default.json
│   └── Modelfile
├── scripts/
│   ├── bootstrap_ollama.sh
│   └── verify_local_stack.sh
└── docs/
```

## Locked model

Default Ollama model:

```text
qwen3:4b-instruct-2507-q4_K_M
```

The supplied `Modelfile` creates an optional customized alias:

```text
valleytainment-fcp-qwen3-4b
```

The context is intentionally capped at 32K for the first local build. Timeline state should be compacted into structured artifacts instead of dumping an entire library into the prompt.

## 1. Install and prepare Ollama on the Mac

Current Ollama for macOS requires **macOS 14 Sonoma or newer**. On an older Final Cut workstation, retain the same Qwen GGUF model and add the planned llama.cpp-compatible provider instead of upgrading blindly.


```bash
cd valleytainment-fcp-ai-starter
./scripts/bootstrap_ollama.sh
```

Or pull only the base model:

```bash
ollama pull qwen3:4b-instruct-2507-q4_K_M
```

For a strictly local runtime, disable Ollama cloud features in its server configuration before production use.

Verify Ollama:

```bash
curl http://127.0.0.1:11434/api/tags
```

## 2. Run the safe mock harness first

```bash
swift test
```

Then run Qwen against the mock Final Cut adapter:

```bash
swift run fcp-ai-cli --mode suggest \
  "Inspect the active timeline and propose a safe edit plan."
```

Execute a reversible mock edit:

```bash
swift run fcp-ai-cli --mode execute_safe \
  "Inspect the timeline, duplicate the project as Demo Interview — AI Cut 001, blade at frame 240, add a Review marker at frame 240, and verify the final state."
```

Each tool result is saved under `Runs/<timestamp>/`.

## 3. Create the real Xcode host and workflow-extension targets

Apple distributes the Final Cut Pro Workflow Extension template as part of its Professional Video Applications developer tooling. Create the targets with Apple's template rather than hand-inventing all build settings.

### Host target

1. In Xcode, create a macOS App named `FCPAIHost`.
2. Add this repository as a **local Swift package**.
3. Link the `FCPAIKit` product to the host target.
4. Replace the generated host Swift files with `macOS/FCPAIHost/*.swift`.
5. Merge `macOS/FCPAIHost/Info.plist` and entitlements into the target.
6. Keep App Sandbox enabled and enable outgoing network connections for local Ollama access.

### Workflow extension target

1. Choose **File → New → Target**.
2. Select **Final Cut Pro Workflow Extension** from Apple's installed template.
3. Name it `FCPWorkflowExtension`.
4. Link `FCPAIKit` to the extension target.
5. Replace the generated controller/UI files with `macOS/FCPWorkflowExtension/*.swift`.
6. Preserve the template's generated extension UUID, build scripts, linker settings, embedding phase, and signing configuration.
7. Merge the provided plist values instead of blindly replacing template-only keys.
8. Add outgoing network permission so the extension can call Ollama on `127.0.0.1`.
9. Sign the host and extension with the same Apple development team.

## 4. Install and open in Final Cut Pro

1. Build the host application.
2. Copy the signed host app to `/Applications`.
3. Remove any older duplicate copies of the host app.
4. Quit and reopen Final Cut Pro 10.6.5.
5. Open **Window → Extensions** or use the Extensions toolbar button.
6. Select **FCP AI Operator**.
7. Open a project timeline and click **Refresh**.

The Phase 0 extension can:

- Read the active sequence name.
- Read duration, frame rate, and playhead position.
- Ask local Qwen to reason over that state.
- Move the playhead to an exact frame in Execute Safe mode.
- Refuse unsupported/deeper edit operations instead of fabricating success.

## Safety contract

| Mode | Reads | Reversible edits | Export/publish | Destructive operations |
|---|---:|---:|---:|---:|
| Observe | Yes | No | No | No |
| Suggest | Yes | No | No | No |
| Execute Safe | Yes | Yes | Explicit approval only | No |
| Auto Edit | Yes | Yes | Explicit approval only | No |

Additional locks:

- Unknown tools are denied by default.
- Multi-step edits should begin with project duplication.
- Blade operations are rejected until the working project is a duplicate.
- Tool errors are returned to Qwen as evidence.
- The agent stops after a bounded number of steps.
- Every tool call can be journaled as JSON.

## Current boundary and next build

Apple's public workflow-extension timeline API is intentionally limited. The next production phase adds a **CommandPost bridge** with an Accessibility fallback for commands such as:

- Duplicate active project
- Blade at playhead/timecode
- Add marker
- Select clips/ranges
- Trim start/end
- Insert, connect, overwrite, and delete ranges
- Apply roles, transitions, titles, and effects
- Undo and verify
- Export only after explicit approval

See `docs/PHASE_1_DEEP_CONTROL.md` for the next implementation contract.

## Validation status

The cross-platform Swift package was built with Swift 6.2.1 and all included tests passed. The macOS Workflow Extension source cannot be linked in a Linux build environment because `Cocoa`, `CoreMedia`, and Apple's `ProExtensionHost` SDK are macOS-only; compile that target on the destination Mac using Apple's template.
