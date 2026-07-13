# Phase 1 — Deep Final Cut Control

## Goal

Allow Qwen to perform bounded, reversible editing operations in Final Cut Pro 10.6.5 while retaining typed tools, deterministic verification, and duplicate-project protection.

## Preferred bridge order

1. CommandPost command/API integration.
2. FCPXML generation and import for batch timeline construction.
3. macOS Accessibility API for unsupported UI controls.
4. Coordinate-based mouse actions only as an explicitly disabled last resort.

## First production vertical slice

> Inspect an interview timeline, duplicate the project, identify supplied silence ranges, blade around those ranges, remove them with configured handles, add markers where confidence is low, and verify final duration and cut count.

Audio silence detection is performed outside Final Cut Pro. The model receives structured ranges rather than raw audio samples.

## Required tool contracts

```text
fcp.get_timeline_state
project.duplicate
timeline.select_range
timeline.blade
timeline.delete_range
timeline.add_marker
project.undo
project.verify
```

## Execution sequence

```text
Observe current state
  ↓
Duplicate active project
  ↓
Verify duplicate identity
  ↓
Apply no more than N edits per batch
  ↓
Re-observe timeline
  ↓
Compare expected and actual state
  ├─ match → continue
  └─ mismatch → stop and rollback
```

## Adapter result envelope

Every deep-control tool must return:

```json
{
  "ok": true,
  "tool": "timeline.blade",
  "before": {},
  "after": {},
  "verification": {
    "passed": true,
    "checks": []
  },
  "undo_available": true
}
```

## Hard gates

- Never edit the source project after duplication.
- Never delete original media.
- Never continue after focus or active-project identity changes.
- Never trust a keyboard shortcut without reading resulting state.
- Never batch more than the configured maximum before verification.
- Never export in the same authorization used for editing.
