from external.gojo.fmt import sprintf
from .style import bel, csi, reset, osc
from .color import AnyColor, NoColor, ANSIColor, ANSI256Color, RGBColor


# Sequence definitions.
## Cursor positioning.
alias cursor_up_seq = "%dA"
alias cursor_down_seq = "%dB"
alias cursor_forward_seq = "%dC"
alias cursor_back_seq = "%dD"
alias cursor_next_line_seq = "%dE"
alias cursor_previous_line_seq = "%dF"
alias cursor_horizontal_seq = "%dG"
alias cursor_position_seq = "%d;%dH"
alias erase_display_seq = "%dJ"
alias erase_line_seq = "%dK"
alias scroll_up_seq = "%dS"
alias scroll_down_seq = "%dT"
alias save_cursor_position_seq = "s"
alias restore_cursor_position_seq = "u"
alias change_scrolling_region_seq = "%d;%dr"
alias insert_line_seq = "%dL"
alias delete_line_seq = "%dM"

## Explicit values for EraseLineSeq.
alias erase_line_right_seq = "0K"
alias erase_line_left_seq = "1K"
alias erase_entire_line_seq = "2K"

## Mouse
alias enable_mouse_press_seq = "?9h"  # press only (X10)
alias disable_mouse_press_seq = "?9l"
alias enable_mouse_seq = "?1000h"  # press, release, wheel
alias disable_mouse_seq = "?1000l"
alias enable_mouse_hilite_seq = "?1001h"  # highlight
alias disable_mouse_hilite_seq = "?1001l"
alias enable_mouse_cell_motion_seq = "?1002h"  # press, release, move on pressed, wheel
alias disable_mouse_cell_motion_seq = "?1002l"
alias enable_mouse_all_motion_seq = "?1003h"  # press, release, move, wheel
alias disable_mouse_all_motion_seq = "?1003l"
alias enable_mouse_extended_mode_seq = "?1006h"  # press, release, move, wheel, extended coordinates
alias disable_mouse_extended_mode_seq = "?1006l"
alias enable_mouse_pixels_mode_seq = "?1016h"  # press, release, move, wheel, extended pixel coordinates
alias disable_mouse_pixels_mode_seq = "?1016l"

## Screen
alias restore_screen_seq = "?47l"
alias save_screen_seq = "?47h"
alias alt_screen_seq = "?1049h"
alias exit_alt_screen_seq = "?1049l"

## Bracketed paste.
## https:#en.wikipedia.org/wiki/Bracketed-paste
alias enable_bracketed_paste_seq = "?2004h"
alias disable_bracketed_paste_seq = "?2004l"
alias start_bracketed_paste_seq = "200~"
alias end_bracketed_paste_seq = "201~"

## Session
alias set_window_title_seq = "2;%s" + bel
alias set_foreground_color_seq = "10;%s" + bel
alias set_background_color_seq = "11;%s" + bel
alias set_cursor_color_seq = "12;%s" + bel
alias show_cursor_seq = "?25h"
alias hide_cursor_seq = "?25l"


fn __string__mul__(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


fn reset_terminal():
    """Reset the terminal to its default style, removing any active styles."""
    print(csi + reset + "m", end="")


fn set_foreground_color(color: AnyColor):
    """Sets the default foreground color.

    Args:
        color: The color to set.
    """
    var c: String = ""

    if color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(False)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(False)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(False)

    print(osc + set_foreground_color_seq, c, end="")


fn set_background_color(color: AnyColor):
    """Sets the default background color.

    Args:
        color: The color to set.
    """
    var c: String = ""
    if color.isa[NoColor]():
        pass
    elif color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(True)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(True)

    print(osc + set_background_color_seq, c, end="")


fn set_cursor_color(color: AnyColor):
    """Sets the cursor color.

    Args:
        color: The color to set.
    """
    var c: String = ""
    if color.isa[NoColor]():
        pass
    elif color.isa[ANSIColor]():
        c = color[ANSIColor].sequence(True)
    elif color.isa[ANSI256Color]():
        c = color[ANSI256Color].sequence(True)
    elif color.isa[RGBColor]():
        c = color[RGBColor].sequence(True)

    print(osc + set_cursor_color_seq, c, end="")


fn restore_screen():
    """Restores a previously saved screen state."""
    print(csi + restore_screen_seq, end="")


fn save_screen():
    """Saves the screen state."""
    print(csi + save_screen_seq, end="")


fn alt_screen():
    """Switches to the alternate screen buffer. The former view can be restored with ExitAltScreen()."""
    print(csi + alt_screen_seq, end="")


fn exit_alt_screen():
    """Exits the alternate screen buffer and returns to the former terminal view."""
    print(csi + exit_alt_screen_seq, end="")


fn clear_screen():
    """Clears the visible portion of the terminal."""
    print(sprintf(csi + erase_display_seq, UInt16(2)), end="")
    move_cursor(1, 1)


fn move_cursor(row: UInt16, column: Int):
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    print(sprintf(csi + cursor_position_seq, row, column), end="")


fn hide_cursor():
    """TODO: Show and Hide cursor don't seem to work ATM. HideCursor hides the cursor."""
    print(csi + hide_cursor_seq, end="")


fn show_cursor():
    """Shows the cursor."""
    print(csi + show_cursor_seq, end="")


fn save_cursor_position():
    """Saves the cursor position."""
    print(csi + save_cursor_position_seq, end="")


fn restore_cursor_position():
    """Restores a saved cursor position."""
    print(csi + restore_cursor_position_seq, end="")


fn cursor_up(n: Int):
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    print(sprintf(csi + cursor_up_seq, n), end="")


fn cursor_down(n: Int):
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    print(sprintf(csi + cursor_down_seq, n), end="")


fn cursor_forward(n: Int):
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move forward.
    """
    print(sprintf(csi + cursor_forward_seq, n), end="")


fn cursor_back(n: Int):
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    print(sprintf(csi + cursor_back_seq, n), end="")


fn cursor_next_line(n: Int):
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    print(sprintf(csi + cursor_next_line_seq, n), end="")


fn cursor_prev_line(n: Int):
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    print(sprintf(csi + cursor_previous_line_seq, n), end="")


fn clear_line():
    """Clears the current line."""
    print(csi + erase_entire_line_seq, end="")


fn clear_line_left():
    """Clears the line to the left of the cursor."""
    print(csi + erase_line_left_seq, end="")


fn clear_line_right():
    """Clears the line to the right of the cursor."""
    print(csi + erase_line_right_seq, end="")


fn clear_lines(n: Int):
    """Clears a given number of lines.

    Args:
        n: The number of lines to clear.
    """
    var clear_line = sprintf(csi + erase_line_seq, UInt16(2))
    var cursor_up = sprintf(csi + cursor_up_seq, UInt16(1))
    var movement = __string__mul__(cursor_up + clear_line, n)
    print(clear_line + movement, end="")


fn change_scrolling_region(top: UInt16, bottom: UInt16):
    """Sets the scrolling region of the terminal.

    Args:
        top: The top of the scrolling region.
        bottom: The bottom of the scrolling region.
    """
    print(sprintf(csi + change_scrolling_region_seq, top, bottom), end="")


fn insert_lines(n: Int):
    """Inserts the given number of lines at the top of the scrollable
    region, pushing lines below down.

    Args:
        n: The number of lines to insert.
    """
    print(sprintf(csi + insert_line_seq, n), end="")


fn delete_lines(n: Int):
    """Deletes the given number of lines, pulling any lines in
    the scrollable region below up.

    Args:
        n: The number of lines to delete.
    """
    print(sprintf(csi + delete_line_seq, n), end="")


fn enable_mouse_press():
    """Enables X10 mouse mode. Button press events are sent only."""
    print(csi + enable_mouse_press_seq, end="")


fn disable_mouse_press():
    """Disables X10 mouse mode."""
    print(csi + disable_mouse_press_seq, end="")


fn enable_mouse():
    """Enables Mouse Tracking mode."""
    print(csi + enable_mouse_seq, end="")


fn disable_mouse():
    """Disables Mouse Tracking mode."""
    print(csi + disable_mouse_seq, end="")


fn enable_mouse_hilite():
    """Enables Hilite Mouse Tracking mode."""
    print(csi + enable_mouse_hilite_seq, end="")


fn disable_mouse_hilite():
    """Disables Hilite Mouse Tracking mode."""
    print(csi + disable_mouse_hilite_seq, end="")


fn enable_mouse_cell_motion():
    """Enables Cell Motion Mouse Tracking mode."""
    print(csi + enable_mouse_cell_motion_seq, end="")


fn disable_mouse_cell_motion():
    """Disables Cell Motion Mouse Tracking mode."""
    print(csi + disable_mouse_cell_motion_seq, end="")


fn enable_mouse_all_motion():
    """Enables All Motion Mouse mode."""
    print(csi + enable_mouse_all_motion_seq, end="")


fn disable_mouse_all_motion():
    """Disables All Motion Mouse mode."""
    print(csi + disable_mouse_all_motion_seq, end="")


fn enable_mouse_extended_mode():
    """Enables Extended Mouse mode (SGR). This should be
    enabled in conjunction with EnableMouseCellMotion, and EnableMouseAllMotion."""
    print(csi + enable_mouse_extended_mode_seq, end="")


fn disable_mouse_extended_mode():
    """Disables Extended Mouse mode (SGR)."""
    print(csi + disable_mouse_extended_mode_seq, end="")


fn enable_mouse_pixels_mode():
    """Enables Pixel Motion Mouse mode (SGR-Pixels). This
    should be enabled in conjunction with EnableMouseCellMotion, and
    EnableMouseAllMotion."""
    print(csi + enable_mouse_pixels_mode_seq, end="")


fn disable_mouse_pixels_mode():
    """Disables Pixel Motion Mouse mode (SGR-Pixels)."""
    print(csi + disable_mouse_pixels_mode_seq, end="")


fn set_window_title(title: String):
    """Sets the terminal window title.

    Args:
        title: The title to set.
    """
    print(osc + set_window_title_seq, title, end="")


fn enable_bracketed_paste():
    """Enables bracketed paste."""
    print(csi + enable_bracketed_paste_seq, end="")


fn disable_bracketed_paste():
    """Disables bracketed paste."""
    print(csi + disable_bracketed_paste_seq, end="")
