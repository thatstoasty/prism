from prism import Command, Context


fn test(ctx: Context) -> None:
    for arg in ctx.args:
        print("Received:", arg[])


fn main() -> None:
    Command(name="hello", usage="This is a dummy command!", run=test, suggest=True).execute()
