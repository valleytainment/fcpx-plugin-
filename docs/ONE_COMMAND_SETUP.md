# One-Command Setup

Your only requirement after install: **open Final Cut Pro and use the extension**.

## Install everything

```bash
cd valleytainment-fcp-ai-starter
chmod +x scripts/*.sh
./scripts/install_plugin.sh
```

This single script:

1. Starts Ollama if needed
2. Pulls the locked Qwen model (falls back to `qwen2.5:14b` on older Ollama)
3. Writes shared runtime config for host + extension
4. Builds the host app and Final Cut Workflow Extension
5. Installs to `/Applications/Valleytainment FCP AI.app`
6. Registers the extension with `pluginkit`
7. Opens Final Cut Pro

## Inside Final Cut Pro

1. **Window → Extensions** (or Extensions toolbar)
2. Select **FCP AI Operator**
3. Open a timeline → **Refresh** → **Run local Qwen**

## If the extension does not appear

1. Quit Final Cut Pro completely (Cmd+Q)
2. Reopen Final Cut Pro
3. Confirm only one copy exists: `/Applications/Valleytainment FCP AI.app`
4. Re-register manually:
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
     -f "/Applications/Valleytainment FCP AI.app"
   pluginkit -a "/Applications/Valleytainment FCP AI.app/Contents/PlugIns/FCPWorkflowExtension.appex"
   ```
5. Confirm it is registered and matches Final Cut's extension point:
   ```bash
   pluginkit -mv -p com.apple.FinalCut.WorkflowExtension | grep valleytainment
   ```

## Verified on this build

- dyld resolves `ProExtensionHost`/`ProExtension` from Final Cut Pro and `libFCPAIKit.dylib` from the app bundle with no missing symbols.
- `pluginkit` registers `com.valleytainment.fcpai.workflow` and matches `com.apple.FinalCut.WorkflowExtension`.

Note: this Mac has no Apple code-signing identity, so the bundle is ad-hoc signed. If Final Cut Pro refuses to load an ad-hoc extension on your macOS version, use the Xcode path below with your Apple Development team.

## Xcode path (recommended for production signing)

If you have Xcode 16+ installed:

```bash
brew install xcodegen   # once
xcodegen generate
open ValleytainmentFCPAI.xcodeproj
```

Sign with your Apple Development team, build **FCPAIHost**, copy to `/Applications`, reopen Final Cut Pro.

## Custom Final Cut Pro location

```bash
FCP_APP="/Applications/Final Cut Pro.app" ./scripts/install_plugin.sh
```

## What Phase 0 can do in Final Cut

- Read active sequence name, duration, frame rate, playhead
- Ask local Qwen to reason over timeline state
- Move playhead to an exact frame (Execute Safe mode)

Blade, trim, duplicate, and export require Phase 1 CommandPost bridge.
