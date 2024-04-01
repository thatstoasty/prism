from external.stump import (
    LEVEL_MAPPING,
    DEBUG,
    JSON_FORMAT,
    DEFAULT_FORMAT,
    Processor,
    Context,
    Styles,
    Sections,
    BoundLogger,
    PrintLogger,
    Logger,
    add_log_level,
    add_timestamp,
    add_timestamp_with_format,
)


fn add_my_name(context: Context) -> Context:
    var new_context = Context(context)
    new_context["name"] = "Name"
    return new_context


fn my_processors() -> List[Processor]:
    return List[Processor](
        add_log_level, add_timestamp_with_format["YYYY"](), add_my_name
    )


# The loggers are compiled at runtime, so we can reuse it.
alias LOG_LEVEL = DEBUG
alias inner_logger = PrintLogger(LOG_LEVEL)
alias logger = bound_logger(inner_logger)
alias default_logger = bound_default_logger(inner_logger)
alias json_logger = bound_json_logger(inner_logger)


# Build a basic print logger
# fn build_logger() -> PrintLogger:
#     return PrintLogger(LOG_LEVEL)


# Build a bound logger with custom processors and styling
fn bound_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(
        logger, formatter=DEFAULT_FORMAT, processors=my_processors,
    )
    return bound_log


# Build a bound logger with default processors and styling
fn bound_default_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(logger, formatter=DEFAULT_FORMAT)
    return bound_log


# Build a bound logger with json formatting
fn bound_json_logger(logger: PrintLogger) -> BoundLogger[PrintLogger]:
    var bound_log = BoundLogger(logger, formatter=JSON_FORMAT)
    return bound_log