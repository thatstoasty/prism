Output demos/tapes/logging.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 400

Type "mojo run examples/logging/root.mojo 'My message.'" Sleep 500ms  Enter
Sleep 2s
Type "mojo run examples/logging/root.mojo 'My message.' --type json" Sleep 500ms  Enter
Sleep 2s
Type "mojo run examples/logging/root.mojo 'My message.' -t custom" Sleep 500ms  Enter
Sleep 1s
Sleep 5s
