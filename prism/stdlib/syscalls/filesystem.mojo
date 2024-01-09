from ..syscalls import c


fn rmdir(pathname: String) raises:
    with c.Str(pathname) as pathname_as_c_str:
        let output = external_call["rmdir", c.int, c.char_pointer](
            pathname_as_c_str.vector.data
        )
        if output == c.SUCCESS:
            return
        elif output == c.EACCES:
            raise Error(
                "Write access to the directory containing "
                + pathname
                + " was notallowed, or one of the directories in the path prefix of "
                + pathname
                + " did notallow search permission."
            )
        elif output == c.EBUSY:
            raise Error(
                pathname
                + " is currently in use by the system or some process"
                "that prevents its removal.  On Linux, this means "
                + pathname
                + " is currently"
                "used as a mount point or is the root directory of the calling process."
            )
        elif output == c.EFAULT:
            raise Error(pathname + " points outside your accessible address space.")
        elif output == c.EINVAL:
            raise Error(pathname + " has .  as last component.")
        elif output == c.ENOENT:
            raise Error(
                "A directory component in "
                + pathname
                + " does not exist or is adangling symbolic link."
            )
        elif output == c.ENOMEM:
            raise Error("Insufficient kernel memory was available.")
        elif output == c.ENOTDIR:
            raise Error(
                pathname
                + ", or a component used as a directory in "
                + pathname
                + ", is not, in fact, a directory."
            )
        elif output == c.EPERM:
            raise Error(
                "The filesystem containing "
                + pathname
                + " does not support the removal of directories."
            )
        elif output == c.EROFS:
            raise Error(pathname + " refers to a directory on a read-only filesystem.")
        else:
            raise Error("rmdir failed with unknown error code: " + String(output))


fn unlink(pathname: String) raises:
    with c.Str(pathname) as pathname_as_c_str:
        let output = external_call["unlink", c.int, c.char_pointer](
            pathname_as_c_str.vector.data
        )
        if output == c.SUCCESS:
            return
        elif output == c.EACCES:
            raise Error(
                "Write permission is denied for the directory from which the file +"
                + pathname
                + " is to be removed, "
                "or the directory has the sticky bit set and you do not own the file."
            )
        elif output == c.EBUSY:
            raise Error(
                "the file "
                + pathname
                + " is being used by the system in such a way thatit can’t be unlinked."
                " For example, you might see this error if the filename specifies the"
                " root directory or a mount point for a file system."
            )
        elif output == c.ENOENT:
            raise Error("he file " + pathname + " doesn’t exist.")
        elif output == c.EPERM:
            raise Error(
                "On some systems unlink cannot be used to delete the name of a"
                " directory, or at least can only be used this way by a privileged"
                " user."
            )
        elif output == c.EROFS:
            raise Error(
                pathname
                + " refers to a file on a read-only filesystem and thus cannot be"
                " removed."
            )
        else:
            raise Error("rmdir failed with unknown error code: " + String(output))


fn read_string_from_fd(file_descriptor: c.int) raises -> String:
    alias buffer_size: Int = 2**13
    let buffer: c.Str
    with c.Str(size=buffer_size) as buffer:
        let read_count: c.ssize_t = external_call[
            "read", c.ssize_t, c.int, c.char_pointer, c.size_t
        ](file_descriptor, buffer.vector.data, buffer_size)
        if read_count == -1:
            raise Error("Failed to read file descriptor" + String(file_descriptor))

        # for stdin, stdout, stderr, we can do this approximation
        # normally we would decode to utf-8 as we go and check for \n, but we can't do that now because
        # we don't have easy to use utf-8 support.
        if read_count == buffer_size:
            raise Error(
                "You can only read up to "
                + String(buffer_size)
                + " bytes. "
                "Wait for UTF-8 support in Mojo for better handling of long inputs."
            )

        return buffer.to_string(read_count)


fn read_from_stdin() raises -> String:
    return read_string_from_fd(c.FD_STDIN)
