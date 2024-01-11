fn exit(code: c.ssize_t) raises:
    _ = external_call["exit", c.ssize_t, c.ssize_t](code)
