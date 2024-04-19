from external.gojo.strings import StringBuilder
from external.gojo.fmt.fmt import sprintf_str, sprintf
from .base import Context, ContextPair, LEVEL_MAPPING
from .style import Styles


# Formatter options
alias Formatter = UInt8
alias DEFAULT_FORMAT: Formatter = 0
alias JSON_FORMAT: Formatter = 1
alias LOGFMT_FORMAT: Formatter = 2


fn join(separator: String, iterable: List[String]) raises -> String:
    var result: String = ""
    for i in range(iterable.__len__()):
        result += iterable[i]
        if i != iterable.__len__() - 1:
            result += separator
    return result


fn default_formatter(context: Context) raises -> String:
    """Default formatter for log messages.

    Args:
        context: The context to format.

    Returns:
        The formatted log message.
    """
    # TODO: Probably need a better algorithm for this formatting process.
    var new_context = Context(context)
    var format = List[String]()
    var args = List[String]()

    # timestamp then level, then message, then other context keys
    if "timestamp" in new_context:
        args.append(new_context.pop("timestamp"))
        format.append("%s")

    if "level" in new_context:
        args.append(new_context.pop("level"))
        format.append("%s")

    args.append(new_context.pop("message"))
    format.append("%s")

    # Add the rest of the context delimited by a space.
    var delimiter: String = " "
    var builder = StringBuilder()
    _ = builder.write_string(delimiter)
    var pair_count = new_context.size
    var current_index = 0
    for pair in new_context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

        if current_index < pair_count - 1:
            _ = builder.write_string(delimiter)
        current_index += 1

    return sprintf_str(join(" ", format), args=args) + str(builder)


fn json_formatter(context: Context) raises -> String:
    return stringify_context(context)


fn stringify_kv_pair(pair: ContextPair) raises -> String:
    return sprintf("%s=%s", pair.key.s, pair.value)


fn stringify_context(data: Context) -> String:
    var key_count = data.size
    var builder = StringBuilder()
    _ = builder.write_string("{")

    var key_index = 0
    for pair in data.items():
        _ = builder.write_string('"')
        _ = builder.write_string(pair[].key.s)
        _ = builder.write_string('"')
        _ = builder.write_string(':"')

        if pair[].key.s == "level":
            var level_text: String = ""
            try:
                level_text = LEVEL_MAPPING[atol(pair[].value)]
                _ = builder.write_string(level_text)
            except:
                _ = builder.write_string(pair[].value)
        else:
            _ = builder.write_string(pair[].value)

        _ = builder.write_string('"')

        # Add comma for all elements except last
        if key_index != key_count - 1:
            _ = builder.write_string(", ")
            key_index += 1

    _ = builder.write_string("}")
    return str(builder)


fn logfmt_formatter(context: Context) raises -> String:
    var new_context = Context(context)

    # Add all the keys in the context in KV format.
    var delimiter = " "
    var builder = StringBuilder()
    var pair_count = new_context.size
    var current_index = 0
    for pair in new_context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

        if current_index < pair_count - 1:
            _ = builder.write_string(delimiter)
        current_index += 1

    # timestamp then level, then message, then other context keys
    return str(builder)


fn format(formatter: Formatter, context: Context) raises -> String:
    if formatter == JSON_FORMAT:
        return json_formatter(context)
    elif formatter == LOGFMT_FORMAT:
        return logfmt_formatter(context)

    return default_formatter(context)
