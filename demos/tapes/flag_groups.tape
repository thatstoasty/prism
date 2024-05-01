Output demos/tapes/flag_groups.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 600


Type "mojo build examples/flag_groups/root.mojo -o group" Sleep 500ms  Enter
Sleep 1500ms
Type "./group tool --color '#ffffff' --formatting 'underline' --required" Sleep 500ms  Enter
Sleep 2s
Type "./group tool --color '#ffffff' --required" Sleep 500ms  Enter
Sleep 2s
Type "./group tool --color '#ffffff' --hue red --formatting 'underline' --required" Sleep 500ms  Enter
Sleep 2s
Type "./group tool" Sleep 500ms  Enter
Sleep 1s
Sleep 5s
