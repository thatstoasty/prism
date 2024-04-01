from external.gojo.strings import StringBuilder
from external.gojo.fmt import sprintf
from .base import Context, ContextPair, LEVEL_MAPPING
from .style import Styles



# Formatter options
alias Formatter = UInt8
alias DEFAULT_FORMAT: Formatter = 0
alias JSON_FORMAT: Formatter = 1


fn default_formatter(context: Context) raises -> String:
    var new_context = Context(context)
    var timestamp = new_context.pop("timestamp")
    var level = new_context.pop("level")
    var message = new_context.pop("message")

    # Add the rest of the context delimited by a space.
    var delimiter = " "
    var builder = StringBuilder()
    _ = builder.write_string(delimiter)
    var pair_count = new_context.size
    var current_index = 0
    for pair in new_context.items():
        _ = builder.write_string(stringify_kv_pair(pair[]))

        if current_index < pair_count - 1:
            _ = builder.write_string(delimiter)
        current_index += 1

    # timestamp then level, then message, then other context keys
    return sprintf("%s %s %s", timestamp, level, message) + str(builder)


fn json_formatter(context: Context) raises -> String:
    var new_context = Context(context)
    var timestamp = new_context.pop("timestamp")
    var level = new_context.pop("level")
    var message = new_context.pop("message")

    # timestamp then level, then message, then other context keys
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
            _ = builder.write_string(",")
            key_index += 1

    _ = builder.write_string("}")
    return str(builder)


fn format(formatter: Formatter, context: Context) raises -> String:
    if formatter == JSON_FORMAT:
        return json_formatter(context)
    return default_formatter(context)
