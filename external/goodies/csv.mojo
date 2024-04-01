from external.gojo.builtins import Bytes
import external.gojo.io
import external.gojo.bufio
from external.gojo.strings import StringBuilder
from external.csv import CsvBuilder, CsvTable
from .file import FileWrapper


struct CSVReader[R: io.Reader]():
    var reader: bufio.Reader[R]

    fn __init__(inout self, owned reader: R) raises:
        self.reader = bufio.Reader(reader ^)

    fn __moveinit__(inout self, owned existing: Self):
        self.reader = existing.reader ^
    
    # TODO: Probably a good place to optimize. bufio reader fills it's buffer, then we read line by line from it.
    fn read_lines(inout self, lines_to_read: Int, delimiter: String = "\r\n", column_count: Int = 1) raises -> CsvTable:
        var lines_remaining = lines_to_read
        var builder = CsvBuilder(column_count)
        while lines_remaining != 0:
            var result = self.reader.read_string(ord(delimiter))
            if result.has_error():
                var err = result.unwrap_error()
                if str(err) != io.EOF:
                    raise err.error
            
            # read_string includes the delimiter in the result, so we slice off whatever the length of the delimiter is from the end
            # CRLF is optional on the last line, so we check for the delimiter.
            var suffix_to_remove = len(delimiter)
            if lines_remaining == 1 and not result.value.endswith(delimiter):
                suffix_to_remove = 0

            var fields = result.value[:len(result.value) - suffix_to_remove].split(",")
            for field in fields:
                builder.push(field[])
            lines_remaining -= 1

        return CsvTable(builder^.finish())


struct CSVWriter[W: io.Writer]():
    var writer: bufio.Writer[W]

    fn __init__(inout self, owned writer: W) raises:
        self.writer = bufio.Writer(writer ^)

    fn __moveinit__(inout self, owned existing: Self):
        self.writer = existing.writer ^
    
    fn write(inout self, src: CsvTable) raises -> Int:
        var result = self.writer.write_string(src._inner_string)
        if result.has_error():
            var error = result.unwrap_error()
            if str(error) != io.EOF:
                raise error.error
        
        # Flush remaining contents of buffer
        var error = self.writer.flush()
        if error:
            var err = error.value().error
            if str(err) != io.EOF:
                raise err
                
        return result.value
    
    fn write(inout self, src: List[String]) raises -> Int:
        var bytes_written: Int = 0
        for row in src:
            var result = self.writer.write_string(row[] + "\r\n")
            if result.has_error():
                var error = result.unwrap_error()
                if str(error) != io.EOF:
                    raise error.error
            
            bytes_written += result.value
        
        # Flush remaining contents of buffer
        var error = self.writer.flush()
        if error:
            var err = error.value().error
            if str(err) != io.EOF:
                raise err
        
        return bytes_written
    