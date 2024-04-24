from external.gojo.builtins import Byte, copy
import external.gojo.io


struct FileWrapper(io.ReadWriteSeeker, io.ByteReader):
    var handle: FileHandle

    fn __init__(inout self, path: String, mode: String) raises:
        self.handle = open(path, mode)

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle^

    fn __del__(owned self):
        var err = self.close()
        if err:
            # TODO: __del__ can't raise, but there should be some fallback.
            print(str(err))

    fn close(inout self) -> Error:
        try:
            self.handle.close()
        except e:
            return e

        return Error()

    fn read(inout self, inout dest: List[Byte]) -> (Int, Error):
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result: String = ""
        var bytes_to_read = dest.capacity - len(dest)
        try:
            result = self.handle.read(bytes_to_read)
        except e:
            return 0, e

        var bytes_read = len(result)
        if bytes_read == 0:
            return 0, Error(io.EOF)

        var bytes_result = result.as_bytes()
        var elements_copied = copy(dest, bytes_result[:bytes_read])
        # dest = dest[:elements_copied]

        var err = Error()
        if elements_copied < bytes_to_read:
            err = Error(io.EOF)

        return elements_copied, err

    fn read(inout self, inout dest: List[Byte], size: Int64) -> (Int, Error):
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result: String = ""
        try:
            result = self.handle.read(size)
        except e:
            return 0, Error(e)

        var bytes_read = len(result)
        if bytes_read == 0:
            return 0, Error(io.EOF)

        var bytes_result = result.as_bytes()
        var elements_copied = copy(dest, bytes_result[:bytes_read])
        dest = dest[:elements_copied]

        var err = Error()
        if elements_copied < int(size):
            err = Error(io.EOF)

        return elements_copied, err

    fn read_all(inout self) -> (List[Byte], Error):
        var bytes = List[Byte](capacity=io.BUFFER_SIZE)
        while True:
            var temp = List[Byte](capacity=io.BUFFER_SIZE)
            _ = self.read(temp, io.BUFFER_SIZE)

            # If new bytes will overflow the result, resize it.
            if len(bytes) + len(temp) > bytes.capacity:
                bytes.reserve(bytes.capacity * 2)
            bytes.extend(temp)

            if len(temp) < io.BUFFER_SIZE:
                return bytes, Error(io.EOF)

    fn read_byte(inout self) -> (Byte, Error):
        try:
            var byte = self.read_bytes(1)[0]
            return byte, Error()
        except e:
            return Int8(0), Error(e)

    fn read_bytes(inout self, size: Int64) raises -> List[Int8]:
        return self.handle.read_bytes(size)

    fn read_bytes(inout self) raises -> List[Int8]:
        return self.handle.read_bytes()

    fn stream_until_delimiter(inout self, inout dest: List[Byte], delimiter: Int8, max_size: Int) raises:
        var byte: Int8
        var err: Error
        for i in range(max_size):
            byte, err = self.read_byte()
            if byte == delimiter:
                return
            dest.append(byte)
        raise Error("Stream too long")

    fn seek(inout self, offset: Int64, whence: Int = 0) -> (Int64, Error):
        try:
            var position = self.handle.seek(offset.cast[DType.uint64]())
            return position.cast[DType.int64](), Error()
        except e:
            return Int64(0), Error(e)

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        try:
            var copy = List[Byte](src)
            var bytes_length = len(copy)
            self.handle.write(StringRef(copy.steal_data(), bytes_length))
            return len(src), Error(io.EOF)
        except e:
            return 0, Error(e)
