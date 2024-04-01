from external.morrow import Morrow
from .base import Context
from .style import get_default_styles

# TODO: Included `escaping` in the Processor alias for now. It enables the use of functions that generate processors (ie passing args to the processor function)
# Nede to understanding closures a bit more, but this works with existing processors.
alias Processor = fn (Context) escaping -> Context


# Built in processor functions to modify the context before logging a message.
fn add_timestamp(context: Context) -> Context:
    var new_context = Context(context)
    var timestamp: String = ""
    try:
        timestamp = Morrow.now().format("YYYY-MM-DD HH:mm:ss")
    except:
        print("add_timestamp: failed to get timestamp")

    new_context["timestamp"] = timestamp
    return new_context


fn add_log_level(context: Context) -> Context:
    var new_context = Context(context)
    try:
        new_context["level"] = LEVEL_MAPPING[atol(new_context.pop("level"))]
    except:
        print("add_log_level: failed to get log level")
        new_context["level"] = ""

    return new_context


# If you need to modify something within the processor function, create a function that returns a Processor
fn add_timestamp_with_format[format: String]() -> fn (Context) escaping -> Context:
    fn processor(context: Context) -> Context:
        var new_context = Context(context)
        var timestamp: String = ""
        try:
            timestamp = Morrow.now().format(format)
        except:
            print("add_timestamp_with_format: failed to get timestamp")

        new_context["timestamp"] = timestamp
        return new_context

    return processor


# TODO: Temporary solution to get a list of processors at runtime. Storing the processors as a field in the boundlogger struct does not work as of 24.2
fn get_processors() -> List[Processor]:
    return List[Processor](add_timestamp, add_log_level)
