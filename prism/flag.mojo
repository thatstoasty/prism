from sys import argv
from collections.dict import Dict, KeyElement
from memory._arc import Arc
from collections.optional import Optional
from .vector import to_string


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s

    fn __ne__(self, other: Self) -> Bool:
        return self.s != other.s

    fn __str__(self) -> String:
        return self.s


fn string_to_bool(value: String) -> Bool:
    if value == "True":
        return True
    return False


fn str_to_float(s: String) raises -> Float64:
    try:
      # locate decimal point
      var dot_pos = s.find(".")
      # grab the integer part of the number 
      var int_str = s[0:dot_pos]
      # grab the decimal part of the number
      var num_str = s[dot_pos+1:len(s)]
      # set the numerator to be the integer equivalent
      var numerator = atol(num_str)
      # construct denom_str to be "1" + "0"s for the length of the fraction
      var denom_str = String()
      for _ in range(len(num_str)):
        denom_str += "0"
      var denominator = atol("1" + denom_str)
      # school-level maths here :)
      var frac = numerator / denominator
      
      # return the number as a Float64
      var result: Float64 = atol(int_str) + frac
      return result
    except:
      raise Error("Failed to convert " + s + " to a float.")


@value
struct FlagSet(Stringable, Sized):
    var flags: List[Flag]

    fn __str__(self) -> String:
        var result = String("Flags: [")
        for i in range(self.flags.size):
            result += self.flags[i]
            if i != self.flags.size - 1:
                result += String(", ")
        result += String("]")
        return result
    
    fn __len__(self) -> Int:
        return self.flags.size
    
    fn __contains__(self, value: Flag) -> Bool:
        for flag in self.flags:
            if flag[] == value:
                return True
        return False
    
    fn __eq__(self, other: Self) -> Bool:
        if len(self.flags) != len(other.flags):
            return False
        
        for i in range(len(self.flags)):
            if self.flags[i] != other.flags[i]:
                return False
        return True
    
    fn __ne__(self, other: Self) -> Bool:
        return not self == other
    
    fn get_flag(self, name: String) raises -> Arc[Flag]:
        for flag in self.flags:
            if flag[].name == name:
                return Arc(flag[])
        
        raise Error("FlagNotFound: Could not find flag with name: " + name)
    
    fn get_as_string(self, name: String) -> Optional[String]:
        try:
            var flag = self.get_flag(name)[]
            if flag.value == "" and flag.default != "":
                return flag.default
            
            return flag.value
        except e:
            print(e)
            return None
    
    fn get_as_bool(self, name: String) -> Optional[Bool]:
        try:
            var flag = self.get_flag(name)[]
            if flag.value == "" and flag.default != "":
                return string_to_bool(flag.default)
            
            return string_to_bool(flag.value)
        except e:
            print(e)
            return None
    
    fn get_as_int(self, name: String) raises -> Optional[Int]:
        try:
            var flag = self.get_flag(name)[]
            if flag.value == "" and flag.default != "":
                return atol(flag.default)
            
            return atol(flag.value)
        except e:
            print(e)
            return None
    
    fn get_as_float(self, name: String) raises -> Optional[Float64]:
        try:
            var flag = self.get_flag(name)[]
            if flag.value == "" and flag.default != "":
                return str_to_float(flag.default)
            
            return str_to_float(flag.value)
        except e:
            print(e)
            return None
    
    fn get_flags(self) -> List[Arc[Flag]]:
        var result = List[Arc[Flag]]()
        for flag in self.flags:
            result.append(Arc(flag[]))
        return result
    
    fn get_flags_with_values(self) -> List[Arc[Flag]]:
        var result = List[Arc[Flag]]()
        for flag in self.flags:
            if flag[].value != "":
                result.append(Arc(flag[]))
        return result
    
    fn get_names(self) -> List[String]:
        var result = List[String]()
        for flag in self.flags:
            result.append(flag[].name)
        return result
    
    fn add_flag(inout self, flag: Flag) -> None:
        self.flags.append(flag)
    
    # TODO: This is temporary until I figure out how to return a mutable reference to a flag inside the list.
    # Calling get_flag, dereferencing, and then setting the value does not persist.
    fn set_flag_value(inout self, name: String, value: String) raises -> None:
        for i in range(len(self.flags)):
            if self.flags[i].name == name:
                self.flags[i].value = value
                return
        
        raise Error("FlagNotFound: Could not find flag with name: " + name)


# TODO: Add functions to get flag as a <TYPE>. Like get flag as int, get flag as bool, etc.
@value
struct Flag(CollectionElement, Stringable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via --name or -shorthand and can have a value associated with them.
    """
    var name: String
    var shorthand: String
    var usage: String
    var value: String
    var default: String

    fn __init__(
        inout self,
        name: String, 
        shorthand: String, 
        usage: String,
        value: String = "",
        default: String = "",
    ) -> None:
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = value
        self.default = default

    fn __str__(self) -> String:
        return (
            String("(Name: ")
            + self.name
            + String(", Shorthand: ")
            + self.shorthand
            + String(", Usage: ")
            + self.usage
            + String(")")
        )

    fn __repr__(self) -> String:
        return str(self)

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name and \
        self.shorthand == other.shorthand and \
        self.usage == other.usage and \
        self.value == other.value and \
        self.default == other.default
    
    fn __ne__(self, other: Self) -> Bool:
        return not self == other


alias Flags = List[Flag]
alias InputFlags = Dict[StringKey, String]
alias PositionalArgs = List[String]


fn get_args_and_flags(
    inout args: PositionalArgs, inout flags: FlagSet
) raises -> None:
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        args: The positional args passed via the command line.
        flags: The flags passed via the command line.

    Raises:
        Error: TODO
    """
    var arguments = argv()
    for i in range(len(arguments)):
        if i != 0:
            var argument = String(arguments[i])
            if argument.find("--") != -1:
                if argument.find("=") != -1:
                    var flag = argument.split("=")
                    var name = flag[0][2:]
                    var value = flag[1]

                    try:
                        flags.set_flag_value(name, value)
                    except e:
                        raise Error("Command does not accept the flag supplied: " + name + "; " + e)
            else:
                args.append(argument)
