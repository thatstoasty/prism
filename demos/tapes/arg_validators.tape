Output demos/tapes/arg_validators.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 600


Type "mojo build examples/arg_validators/root.mojo -o validators" Sleep 500ms  Enter
Sleep 2s
Type "./validators Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators no_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators valid_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators minimum_n_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators maximum_n_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators exact_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 2s
Type "./validators range_args Hello from Mojo!" Sleep 500ms  Enter
Sleep 1s
Sleep 5s
