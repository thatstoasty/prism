import math
from collections import Optional
import ..io
from ..builtins import copy, panic, Error
from ..builtins.bytes import Byte, index_byte
from .bufio import MAX_CONSECUTIVE_EMPTY_READS


alias MAX_INT: Int = 2147483647


struct Scanner[R: io.Reader]():
    """Scanner provides a convenient Interface for reading data such as
    a file of newline-delimited lines of text. Successive calls to
    the [Scanner.Scan] method will step through the 'tokens' of a file, skipping
    the bytes between the tokens. The specification of a token is
    defined by a split function of type [SplitFunction]; the default split
    function breaks the input Into lines with line termination stripped. [Scanner.split]
    fntions are defined in this package for scanning a file Into
    lines, bytes, UTF-8-encoded runes, and space-delimited words. The
    client may instead provide a custom split function.

    Scanning stops unrecoverably at EOF, the first I/O error, or a token too
    large to fit in the [Scanner.buffer]. When a scan stops, the reader may have
    advanced arbitrarily far past the last token. Programs that need more
    control over error handling or large tokens, or must run sequential scans
    on a reader, should use [bufio.Reader] instead."""

    var reader: R  # The reader provided by the client.
    var split: SplitFunction  # The function to split the tokens.
    var max_token_size: Int  # Maximum size of a token; modified by tests.
    var token: List[Byte]  # Last token returned by split.
    var buf: List[Byte]  # buffer used as argument to split.
    var start: Int  # First non-processed byte in buf.
    var end: Int  # End of data in buf.
    var empties: Int  # Count of successive empty tokens.
    var scan_called: Bool  # Scan has been called; buffer is in use.
    var done: Bool  # Scan has finished.
    var err: Error

    fn __init__(
        inout self,
        owned reader: R,
        split: SplitFunction = scan_lines,
        max_token_size: Int = MAX_SCAN_TOKEN_SIZE,
        token: List[Byte] = List[Byte](capacity=io.BUFFER_SIZE),
        buf: List[Byte] = List[Byte](capacity=io.BUFFER_SIZE),
        start: Int = 0,
        end: Int = 0,
        empties: Int = 0,
        scan_called: Bool = False,
        done: Bool = False,
    ):
        self.reader = reader^
        self.split = split
        self.max_token_size = max_token_size
        self.token = token
        self.buf = buf
        self.start = start
        self.end = end
        self.empties = empties
        self.scan_called = scan_called
        self.done = done
        self.err = Error()

    fn current_token_as_bytes(self) -> List[Byte]:
        """Returns the most recent token generated by a call to [Scanner.Scan].
        The underlying array may point to data that will be overwritten
        by a subsequent call to Scan. It does no allocation.
        """
        return self.token

    fn current_token(self) -> String:
        """Returns the most recent token generated by a call to [Scanner.Scan]
        as a newly allocated string holding its bytes."""
        return String(self.token)

    fn scan(inout self) raises -> Bool:
        """Advances the [Scanner] to the next token, which will then be
        available through the [Scanner.current_token_as_bytes] or [Scanner.current_token] method.
        It returns False when there are no more tokens, either by reaching the end of the input or an error.
        After Scan returns False, the [Scanner.Err] method will return any error that
        occurred during scanning, except if it was [io.EOF], [Scanner.Err].
        Scan raises an Error if the split function returns too many empty
        tokens without advancing the input. This is a common error mode for
        scanners.
        """
        if self.done:
            return False

        self.scan_called = True
        # Loop until we have a token.
        while True:
            # See if we can get a token with what we already have.
            # If we've run out of data but have an error, give the split function
            # a chance to recover any remaining, possibly empty token.
            if (self.end > self.start) or self.err:
                var advance: Int
                var token = List[Byte](capacity=io.BUFFER_SIZE)
                var err = Error()
                var at_eof = False
                if self.err:
                    at_eof = True
                advance, token, err = self.split(self.buf[self.start : self.end], at_eof)
                if err:
                    if str(err) == ERR_FINAL_TOKEN:
                        self.token = token
                        self.done = True
                        # When token is not nil, it means the scanning stops
                        # with a trailing token, and thus the return value
                        # should be True to indicate the existence of the token.
                        return len(token) != 0

                    self.set_err(err)
                    return False

                if not self.advance(advance):
                    return False

                self.token = token
                if len(token) != 0:
                    if not self.err or advance > 0:
                        self.empties = 0
                    else:
                        # Returning tokens not advancing input at EOF.
                        self.empties += 1
                        if self.empties > MAX_CONSECUTIVE_EMPTY_READS:
                            panic("bufio.Scan: too many empty tokens without progressing")

                    return True

            # We cannot generate a token with what we are holding.
            # If we've already hit EOF or an I/O error, we are done.
            if self.err:
                # Shut it down.
                self.start = 0
                self.end = 0
                return False

            # Must read more data.
            # First, shift data to beginning of buffer if there's lots of empty space
            # or space is needed.
            if self.start > 0 and (self.end == len(self.buf) or self.start > int(len(self.buf) / 2)):
                _ = copy(self.buf, self.buf[self.start : self.end])
                self.end -= self.start
                self.start = 0

            # Is the buffer full? If so, resize.
            if self.end == len(self.buf):
                # Guarantee no overflow in the multiplication below.
                if len(self.buf) >= self.max_token_size or len(self.buf) > int(MAX_INT / 2):
                    self.set_err(Error(ERR_TOO_LONG))
                    return False

                var new_size = len(self.buf) * 2
                if new_size == 0:
                    new_size = START_BUF_SIZE

                # Make a new List[Byte] buffer and copy the elements in
                new_size = math.min(new_size, self.max_token_size)
                var new_buf = List[Byte](capacity=new_size)
                _ = copy(new_buf, self.buf[self.start : self.end])
                self.buf = new_buf
                self.end -= self.start
                self.start = 0

            # Finally we can read some input. Make sure we don't get stuck with
            # a misbehaving Reader. Officially we don't need to do this, but let's
            # be extra careful: Scanner is for safe, simple jobs.
            var loop = 0
            while True:
                var bytes_read: Int
                var sl = self.buf[self.end : len(self.buf)]
                var err: Error

                # Catch any reader errors and set the internal error field to that err instead of bubbling it up.
                bytes_read, err = self.reader.read(sl)
                _ = copy(self.buf, sl, self.end)
                if bytes_read < 0 or len(self.buf) - self.end < bytes_read:
                    self.set_err(Error(ERR_BAD_READ_COUNT))
                    break

                self.end += bytes_read
                if err:
                    self.set_err(err)
                    break

                if bytes_read > 0:
                    self.empties = 0
                    break

                loop += 1
                if loop > MAX_CONSECUTIVE_EMPTY_READS:
                    self.set_err(Error(io.ERR_NO_PROGRESS))
                    break

    fn set_err(inout self, err: Error):
        """Set the internal error field to the provided error.

        Args:
            err: The error to set.
        """
        if self.err:
            var value = String(self.err)
            if value == "" or value == io.EOF:
                self.err = err
        else:
            self.err = err

    fn advance(inout self, n: Int) -> Bool:
        """Consumes n bytes of the buffer. It reports whether the advance was legal.

        Args:
            n: The number of bytes to advance the buffer by.

        Returns:
            True if the advance was legal, False otherwise.
        """
        if n < 0:
            self.set_err(Error(ERR_NEGATIVE_ADVANCE))
            return False

        if n > self.end - self.start:
            self.set_err(Error(ERR_ADVANCE_TOO_FAR))
            return False

        self.start += n
        return True

    fn buffer(inout self, buf: List[Byte], max: Int) raises:
        """Sets the initial buffer to use when scanning
        and the maximum size of buffer that may be allocated during scanning.
        The maximum token size must be less than the larger of max and cap(buf).
        If max <= cap(buf), [Scanner.Scan] will use this buffer only and do no allocation.

        By default, [Scanner.Scan] uses an Internal buffer and sets the
        maximum token size to [MAX_SCAN_TOKEN_SIZE].

        buffer raises an Error if it is called after scanning has started.

        Args:
            buf: The buffer to use when scanning.
            max: The maximum size of buffer that may be allocated during scanning.

        Raises:
            Error: If called after scanning has started.
        """
        if self.scan_called:
            raise Error("buffer called after Scan")

        # self.buf = buf[0:buf.capacity()]
        self.max_token_size = max

    # # split sets the split function for the [Scanner].
    # # The default split function is [scan_lines].
    # #
    # # split panics if it is called after scanning has started.
    # fn split(inout self, split_function: SplitFunction) raises:
    #     if self.scan_called:
    #         raise Error("split called after Scan")

    #     self.split = split_function


# SplitFunction is the signature of the split function used to tokenize the
# input. The arguments are an initial substring of the remaining unprocessed
# data and a flag, at_eof, that reports whether the [Reader] has no more data
# to give. The return values are the number of bytes to advance the input
# and the next token to return to the user, if any, plus an error, if any.
#
# Scanning stops if the function returns an error, in which case some of
# the input may be discarded. If that error is [ERR_FINAL_TOKEN], scanning
# stops with no error. A non-nil token delivered with [ERR_FINAL_TOKEN]
# will be the last token, and a nil token with [ERR_FINAL_TOKEN]
# immediately stops the scanning.
#
# Otherwise, the [Scanner] advances the input. If the token is not nil,
# the [Scanner] returns it to the user. If the token is nil, the
# Scanner reads more data and continues scanning; if there is no more
# data--if at_eof was True--the [Scanner] returns. If the data does not
# yet hold a complete token, for instance if it has no newline while
# scanning lines, a [SplitFunction] can return (0, nil, nil) to signal the
# [Scanner] to read more data Into the slice and try again with a
# longer slice starting at the same poInt in the input.
#
# The function is never called with an empty data slice unless at_eof
# is True. If at_eof is True, however, data may be non-empty and,
# as always, holds unprocessed text.
alias SplitFunction = fn (data: List[Byte], at_eof: Bool) -> (Int, List[Byte], Error)

# # Errors returned by Scanner.
alias ERR_TOO_LONG = Error("bufio.Scanner: token too long")
alias ERR_NEGATIVE_ADVANCE = Error("bufio.Scanner: SplitFunction returns negative advance count")
alias ERR_ADVANCE_TOO_FAR = Error("bufio.Scanner: SplitFunction returns advance count beyond input")
alias ERR_BAD_READ_COUNT = Error("bufio.Scanner: Read returned impossible count")
# ERR_FINAL_TOKEN is a special sentinel error value. It is Intended to be
# returned by a split function to indicate that the scanning should stop
# with no error. If the token being delivered with this error is not nil,
# the token is the last token.
#
# The value is useful to stop processing early or when it is necessary to
# deliver a final empty token (which is different from a nil token).
# One could achieve the same behavior with a custom error value but
# providing one here is tidier.
# See the emptyFinalToken example for a use of this value.
alias ERR_FINAL_TOKEN = Error("final token")


# MAX_SCAN_TOKEN_SIZE is the maximum size used to buffer a token
# unless the user provides an explicit buffer with [Scanner.buffer].
# The actual maximum token size may be smaller as the buffer
# may need to include, for instance, a newline.
alias MAX_SCAN_TOKEN_SIZE = 64 * 1024
alias START_BUF_SIZE = 4096  # Size of initial allocation for buffer.


fn new_scanner[R: io.Reader](owned reader: R) -> Scanner[R]:
    """Returns a new [Scanner] to read from r.
    The split function defaults to [scan_lines]."""
    return Scanner(reader^)


###### split functions ######
fn scan_bytes(data: List[Byte], at_eof: Bool) -> (Int, List[Byte], Error):
    """Split function for a [Scanner] that returns each byte as a token."""
    if at_eof and data.capacity == 0:
        return 0, List[Byte](), Error()

    return 1, data[0:1], Error()


# var errorRune = List[Byte](string(utf8.RuneError))

# # ScanRunes is a split function for a [Scanner] that returns each
# # UTF-8-encoded rune as a token. The sequence of runes returned is
# # equivalent to that from a range loop over the input as a string, which
# # means that erroneous UTF-8 encodings translate to U+FFFD = "\xef\xbf\xbd".
# # Because of the Scan Interface, this makes it impossible for the client to
# # distinguish correctly encoded replacement runes from encoding errors.
# fn ScanRunes(data List[Byte], at_eof Bool) (advance Int, token List[Byte], err error):
# 	if at_eof and data.capacity == 0:
# 		return 0, nil, nil


# 	# Fast path 1: ASCII.
# 	if data[0] < utf8.RuneSelf:
# 		return 1, data[0:1], nil


# 	# Fast path 2: Correct UTF-8 decode without error.
# 	_, width := utf8.DecodeRune(data)
# 	if width > 1:
# 		# It's a valid encoding. Width cannot be one for a correctly encoded
# 		# non-ASCII rune.
# 		return width, data[0:width], nil


# 	# We know it's an error: we have width==1 and implicitly r==utf8.RuneError.
# 	# Is the error because there wasn't a full rune to be decoded?
# 	# FullRune distinguishes correctly between erroneous and incomplete encodings.
# 	if !at_eof and !utf8.FullRune(data):
# 		# Incomplete; get more bytes.
# 		return 0, nil, nil


# 	# We have a real UTF-8 encoding error. Return a properly encoded error rune
# 	# but advance only one byte. This matches the behavior of a range loop over
# 	# an incorrectly encoded string.
# 	return 1, errorRune, nil


fn drop_carriage_return(data: List[Byte]) -> List[Byte]:
    """Drops a terminal \r from the data.

    Args:
        data: The data to strip.

    Returns:
        The stripped data.
    """
    # In the case of a \r ending without a \n, indexing on -1 doesn't work as it finds a null terminator instead of \r.
    if data.capacity > 0 and data[data.capacity - 1] == ord("\r"):
        return data[0 : data.capacity - 1]

    return data


# TODO: Doing modification of token and err in these split functions, so we don't have to return any memory only types as part of the return tuple.
fn scan_lines(data: List[Byte], at_eof: Bool) -> (Int, List[Byte], Error):
    """Split function for a [Scanner] that returns each line of
    text, stripped of any trailing end-of-line marker. The returned line may
    be empty. The end-of-line marker is one optional carriage return followed
    by one mandatory newline. The last non-empty line of input will be returned even if it has no
    newline.

    Args:
        data: The data to split.
        at_eof: Whether the data is at the end of the file.
    Returns:
        The number of bytes to advance the input.
    """
    if at_eof and data.capacity == 0:
        return 0, List[Byte](), Error()

    var i = index_byte(data, ord("\n"))
    if i >= 0:
        # We have a full newline-terminated line.
        return i + 1, drop_carriage_return(data[0:i]), Error()

    # If we're at EOF, we have a final, non-terminated line. Return it.
    # if at_eof:
    return data.capacity, drop_carriage_return(data), Error()

    # Request more data.
    # return 0


fn is_space(r: Int8) -> Bool:
    alias ALL_WHITESPACES: String = " \t\n\r\x0b\f"
    if chr(int(r)) in ALL_WHITESPACES:
        return True
    return False


# TODO: Handle runes and utf8 decoding. For now, just assuming single byte length.
fn scan_words(data: List[Byte], at_eof: Bool) -> (Int, List[Byte], Error):
    """Split function for a [Scanner] that returns each
    space-separated word of text, with surrounding spaces deleted. It will
    never return an empty string. The definition of space is set by
    unicode.IsSpace.
    """
    # Skip leading spaces.
    var start = 0
    var width = 0
    while start < data.capacity:
        width = len(data[0])
        if not is_space(data[0]):
            break

        start += width

    # Scan until space, marking end of word.
    var i = 0
    width = 0
    start = 0
    while i < data.capacity:
        width = len(data[i])
        if is_space(data[i]):
            return i + width, data[start:i], Error()

        i += width

    # If we're at EOF, we have a final, non-empty, non-terminated word. Return it.
    if at_eof and data.capacity > start:
        return data.capacity, data[start:], Error()

    # Request more data.
    return start, List[Byte](), Error()
