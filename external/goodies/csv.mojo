from external.gojo.builtins import Byte
import external.gojo.io
import external.gojo.bufio
from external.gojo.strings import StringBuilder
from external.csv import CsvBuilder, CsvTable
from .file import FileWrapper


struct CSVReader[R: io.Reader]():
    var reader: bufio.Reader[R]

    fn __init__(inout self, owned reader: R) raises:
        self.reader = bufio.Reader(reader^)

    fn __moveinit__(inout self, owned existing: Self):
        self.reader = existing.reader^

    # TODO: Probably a good place to optimize. bufio reader fills it's buffer, then we read line by line from it.
    fn read_lines(inout self, lines_to_read: Int, delimiter: String = "\r\n", column_count: Int = 1) raises -> CsvTable:
        var lines_remaining = lines_to_read
        var builder = CsvBuilder(column_count)
        while lines_remaining != 0:
            var text: String
            var err: Error
            text, err = self.reader.read_string(ord(delimiter))
            if err:
                if str(err) != io.EOF:
                    raise err

            # read_string includes the delimiter in the result, so we slice off whatever the length of the delimiter is from the end
            # CRLF is optional on the last line, so we check for the delimiter.
            var suffix_to_remove = len(delimiter)
            if lines_remaining == 1 and not text.endswith(delimiter):
                suffix_to_remove = 0

            var fields = text[: len(text) - suffix_to_remove].split(",")
            for field in fields:
                builder.push(field[])
            lines_remaining -= 1

        return CsvTable(builder^.finish())


struct CSVWriter[W: io.Writer]():
    var writer: bufio.Writer[W]

    fn __init__(inout self, owned writer: W) raises:
        self.writer = bufio.Writer(writer^)

    fn __moveinit__(inout self, owned existing: Self):
        self.writer = existing.writer^

    fn write(inout self, src: CsvTable) raises -> Int:
        var bytes_written: Int
        var err: Error
        bytes_written, err = self.writer.write_string(src._inner_string)
        if err:
            if str(err) != io.EOF:
                raise err

        # Flush remaining contents of buffer
        err = self.writer.flush()
        if err:
            if str(err) != io.EOF:
                raise err

        return bytes_written

    fn write(inout self, src: List[String]) raises -> Int:
        var total_bytes_written: Int = 0
        for row in src:
            var bytes_written: Int
            var err: Error
            bytes_written, err = self.writer.write_string(row[] + "\r\n")
            if err:
                if str(err) != io.EOF:
                    raise err

            total_bytes_written += bytes_written

        # Flush remaining contents of buffer
        var error = self.writer.flush()
        if error:
            if str(error) != io.EOF:
                raise error

        return total_bytes_written
