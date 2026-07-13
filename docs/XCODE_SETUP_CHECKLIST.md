# Xcode Setup Checklist

- [ ] Use Apple's Final Cut Pro Workflow Extension target template.
- [ ] Preserve the template-generated `ProExtensionUUID` behavior.
- [ ] Preserve template build phases and special linker flags.
- [ ] For newer Xcode versions, inspect whether `-e` and `_ProExtensionMain` must be separate linker arguments.
- [ ] Link the local `FCPAIKit` package product to host and extension.
- [ ] Use the template's `ProExtensionHost` headers/framework setup.
- [ ] Merge, do not blindly replace, the template Info.plist.
- [ ] Confirm `com.apple.FinalCut.WorkflowExtension` is the extension point.
- [ ] Confirm `ProExtensionPrincipalViewControllerClass` points to `ExtensionViewController`.
- [ ] Enable App Sandbox and outgoing network access.
- [ ] Add Apple Events/Automation permissions only when the deep-control adapter is introduced.
- [ ] Sign host and extension with the same team and compatible bundle identifiers.
- [ ] Ensure only one installed copy exists in `/Applications` during testing.
- [ ] Set Final Cut Pro as the extension scheme's executable when debugging.
