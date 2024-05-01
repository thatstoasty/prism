Output demos/tapes/logging.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 400

Type "mojo build examples/logging/root.mojo -o logger" Sleep 500ms  Enter
Sleep 1500ms
Type "./logger 'My message.'" Sleep 500ms  Enter
Sleep 2s
Type "./logger 'My message.' --type json" Sleep 500ms  Enter
Sleep 2s
Type "./logger 'My message.' -t custom" Sleep 500ms  Enter
Sleep 1s
Sleep 5s
