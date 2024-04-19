from external.morrow import Morrow
from .base import Context
from .style import get_default_styles

# TODO: Included `escaping` in the Processor alias for now. It enables the use of functions that generate processors (ie passing args to the processor function)
# Need to understanding closures a bit more, but this works with existing processors.
alias Processor = fn (context: Context, level: String) escaping -> Context


# Built in processor functions to modify the context before logging a message.
fn add_timestamp(context: Context, level: String) -> Context:
    """Adds a timestamp to the log message with the specified format. 
    The default format for timestamps is `YYYY-MM-DD HH:mm:ss`.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = Context(context)
    # var timestamp: String = ""
    try:
        # timestamp = Morrow.now().format("YYYY-MM-DD HH:mm:ss")
        new_context["timestamp"] = Morrow.now().format("YYYY-MM-DD HH:mm:ss")
        return new_context
    except:
        print("add_timestamp: failed to get timestamp")

    # new_context["timestamp"] = timestamp
    return new_context


fn add_log_level(context: Context, level: String) -> Context:
    """Adds the log level to the log message.

    Args:
        context: The current context.
        level: The log level of the message.
    """
    var new_context = Context(context)
    new_context["level"] = level

    return new_context


# If you need to modify something within the processor function, create a function that returns a Processor
fn add_timestamp_with_format[format: String]() -> Processor:
    """Adds a timestamp to the log message with the specified format. 
    The format should be a valid format string for Morrow.now().format() or "iso".
    
    The default format for timestamps is `YYYY-MM-DD HH:mm:ss`.

    Params:
        format: The format string for the timestamp.
    """
    fn processor(context: Context, level: String) -> Context:
        var new_context = Context(context)
        try:
            var now = Morrow.now()
            var timestamp: String = ""
            if format == "iso":
                timestamp = now.isoformat()
            else:
                timestamp = Morrow.now().format(format)
            new_context["timestamp"] = timestamp
            return new_context
        except:
            print("add_timestamp_with_format: failed to get timestamp")

        return new_context

    return processor


# TODO: Temporary solution to get a list of processors at runtime. Storing the processors as a field in the boundlogger struct does not work as of 24.2
fn get_processors() -> List[Processor]:
    return List[Processor](add_timestamp, add_log_level)
