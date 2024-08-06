import sys


fn string_to_int(s: String) raises -> ArgType:
    return int(s)


alias ArgType = Variant[Int, String]
alias Transformer = fn (String) raises -> ArgType


@value
struct PositionalArg:
    var transformer: Transformer


fn main() raises:
    var args = List[String]()
    for arg in sys.argv():
        args.append(arg)

    args = args[1:]
    var positional_args = List[PositionalArg]()
    for arg in args:
        positional_args.append(PositionalArg(transformer=string_to_int))

    for positional_arg in positional_args:
        var a = positional_arg[].transformer(args[0])
        if a.isa[Int]():
            print(a[Int])
        elif a.isa[String]():
            print(a[String])
        else:
            print("Unknown type")
