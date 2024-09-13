Output demos/tapes/printer.gif

Set Shell "zsh"
Set FontSize 23
Set Width 1200
Set Height 400


Type "mojo build examples/printer/printer.mojo -o printer" Sleep 500ms  Enter
Sleep 4s
Type "./printer 'Blue Drafter'" Sleep 500ms  Enter
Sleep 2s
Type "./printer 'Red Drafter' --color #e02214 --formatting underline" Sleep 500ms  Enter
Sleep 1s

Sleep 5s
