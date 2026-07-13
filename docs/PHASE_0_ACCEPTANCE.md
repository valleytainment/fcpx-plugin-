# Phase 0 Acceptance Matrix

## Core package

- [x] Swift package builds.
- [x] Ollama `/api/chat` client supports native tool calls.
- [x] Default model is Qwen3-4B-Instruct-2507 Q4_K_M.
- [x] Tool names and argument schemas are typed.
- [x] Observe mode blocks mutations.
- [x] Suggest mode blocks mutations.
- [x] Execute Safe permits reversible operations.
- [x] Export is locked without explicit external-side-effect approval.
- [x] Unknown tools are denied.
- [x] Agent loop is bounded.
- [x] Tool executions can be journaled.
- [x] All included tests pass.

## Final Cut integration — requires destination Mac

- [ ] Apple's Workflow Extension template installed.
- [ ] Host app and extension signed by the same team.
- [ ] Extension appears in Final Cut Pro 10.6.5.
- [ ] Active sequence observation succeeds.
- [ ] Playhead observation succeeds.
- [ ] Playhead movement succeeds in Execute Safe mode.
- [ ] Ollama remains reachable from the sandboxed extension.
- [ ] Extension reconnects after closing and reopening its window.
- [ ] Unsupported edit tools fail closed.

## Required proof artifact

Record one run containing:

1. Final Cut Pro version display showing 10.6.5.
2. Extension opened from Final Cut Pro.
3. Timeline state before the request.
4. User request to move the playhead.
5. Qwen tool call.
6. Tool result with `ok=true`.
7. Timeline state after execution.
8. Screen recording showing the playhead moved to the expected frame.
