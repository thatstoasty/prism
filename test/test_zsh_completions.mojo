from prism.zsh_completions import GenZshCompletion
from prism import Command, Context
import gojo.bytes


fn dummy(ctx: Context) -> None:
        return None


fn main() raises:
    var buf = bytes.Buffer()
    var cmd = Command(name="root", usage="Base command.", run=dummy)
    GenZshCompletion(cmd, buf)
    print(str(buf))