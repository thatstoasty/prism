from external.libc import c_ssize_t, c_size_t, c_int, char_pointer
from external.gojo.builtins import Byte
import external.gojo.io


@value
struct STDWriter(Copyable, io.Writer, io.StringWriter):
    """A writer for POSIX file descriptors."""

    var fd: Int

    fn __init__(inout self, fd: Int):
        self.fd = fd

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd

    fn dup(self) -> Self:
        """Duplicates the file descriptor.

        Returns:
            A new STDWriter with a duplicated file descriptor.
        """
        var new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """Writes the given bytes to the file descriptor.

        Args:
            src: The bytes to write to the file descriptor.

        Returns:
            The number of bytes written to the file descriptor.
        """
        var write_count: c_ssize_t = external_call["write", c_ssize_t, c_int, char_pointer, c_size_t](
            self.fd, src.data.bitcast[UInt8](), len(src)
        )

        if write_count == -1:
            return 0, Error("Failed to write to file descriptor " + String(self.fd))

        return write_count, Error()

    fn write_string(inout self, src: String) -> (Int, Error):
        """Writes the given string to the file descriptor.

        Args:
            src: The string to write to the file descriptor.

        Returns:
            The number of bytes written to the file descriptor.
        """
        return self.write(src.as_bytes())

    fn read_from[R: io.Reader](inout self, inout reader: R) -> (Int, Error):
        """Reads from the given reader to a temporary buffer and writes to the file descriptor.

        Args:
            reader: The reader to read from.

        Returns:
            The number of bytes written to the file descriptor.
        """
        var buffer = List[Byte](capacity=io.BUFFER_SIZE)
        _ = reader.read(buffer)
        return self.write(buffer)
