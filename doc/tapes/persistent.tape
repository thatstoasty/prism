Output doc/tapes/persistent.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 400
Set WindowBar Colorful
Set Theme "Catppuccin Frappe"
Set BorderRadius 10

# Type "mojo build examples/persistent/root.mojo -o pet_facts" Sleep 500ms  Enter
# Sleep 1500ms
# Type "./pet_facts get dog -l" Sleep 500ms  Enter
Type "mojo run examples/persistent_flags.mojo get dog -l" Sleep 500ms  Enter
Sleep 3s
Sleep 5s
