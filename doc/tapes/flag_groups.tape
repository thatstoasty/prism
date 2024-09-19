Output doc/tapes/flag_groups.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 600
Set WindowBar Colorful
Set Theme "Catppuccin Frappe"
Set BorderRadius 10

Type "mojo build examples/fg_parent.mojo -o group" Sleep 500ms  Enter
Sleep 3s
Type "./group --required --host=www.example.com --port 8080" Sleep 500ms  Enter
Sleep 2s
Type "./group --required --host www.example.com" Sleep 500ms  Enter
Sleep 2s
Type "./group --required --host www.example.com --uri abcdef --port 8080" Sleep 500ms  Enter
Sleep 2s
Type "./group" Sleep 500ms  Enter
Sleep 1s
Sleep 5s
