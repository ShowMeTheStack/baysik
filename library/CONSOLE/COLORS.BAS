' ============================================================
' TITLE:    Text Color Chart
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     color, locate, text mode, attributes
' SUMMARY:  A full chart of all 16 foreground and 8 background text colors with their numbers.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a grid showing every combination of the 16 foreground
'   colors and the 8 background colors you can use in SCREEN 0.
'   Each cell shows the foreground number on its background, so
'   you can pick nice-looking combinations for your own programs.
'   Below the grid it lists the names of the 16 colors.
'
' HOW TO USE
'   Just run it and look.  Press any key to see the "blink" page
'   (colors 16-31), then any key again to quit.
'
' CONCEPTS YOU WILL LEARN
'   * COLOR foreground, background
'   * LOCATE row, column to place text anywhere on the screen
'   * Nested FOR loops to build a table
'   * READ / DATA to store a list of names
'   * Adding 16 to a foreground color makes it blink
'
' THINGS TO TRY
'   * Change the cell width from 4 to 5 characters.
'   * Show the color names inside the cells instead of numbers.
'   * Find your favourite "readable" combination and use it in
'     another program.
' ============================================================

SCREEN 0          ' SCREEN 0 is the normal 80x25 text mode
WIDTH 80, 25
COLOR 7, 0        ' light grey on black: the standard DOS look
CLS

' ---- Title -------------------------------------------------
COLOR 15, 1
LOCATE 1, 1: PRINT SPACE$(80);          ' paint a blue bar across the top
LOCATE 1, 26: PRINT "SCREEN 0  TEXT COLOR CHART"
COLOR 7, 0

' ---- Column headings: foreground numbers 0..15 --------------
' Each cell is 4 characters wide; the grid starts at column 9.
LOCATE 3, 1: PRINT "BG \ FG"
FOR fg = 0 TO 15
    LOCATE 3, 9 + fg * 4
    PRINT USING "###"; fg      ' PRINT USING lines the numbers up neatly
NEXT fg

' ---- The grid ---------------------------------------------
' Outer loop = background row (0..7), inner loop = foreground column.
FOR bg = 0 TO 7
    row = 5 + bg * 2            ' leave a blank line between rows
    COLOR 7, 0
    LOCATE row, 2: PRINT USING "BG #"; bg
    FOR fg = 0 TO 15
        COLOR fg, bg            ' set BOTH colours for this one cell
        LOCATE row, 9 + fg * 4
        PRINT USING " ## "; fg; ' 4 characters: space, 2 digits, space
    NEXT fg
NEXT bg

' ---- Colour names ------------------------------------------
COLOR 7, 0
LOCATE 21, 1: PRINT "Color numbers:"
FOR c = 0 TO 15
    READ nm$
    ' four columns of 4 names each, on rows 22..25
    r = 22 + (c MOD 4)
    col = 1 + (c \ 4) * 20
    LOCATE r, col
    COLOR c, 0
    IF c = 0 THEN COLOR 0, 7      ' black text on black would be invisible!
    PRINT USING "##"; c;
    PRINT " "; nm$;
NEXT c

DATA Black,Blue,Green,Cyan,Red,Magenta,Brown,White (grey)
DATA Dark grey,Light blue,Light green,Light cyan
DATA Light red,Light magenta,Yellow,Bright white

k$ = INPUT$(1)     ' wait for one key press

' ---- Page 2: blinking colours --------------------------------
' In text mode, foreground colors 16-31 are the same as 0-15
' but they BLINK.  (The hardware uses the top bit of the
' attribute byte for blinking.)
COLOR 7, 0: CLS
COLOR 14, 4
LOCATE 2, 25: PRINT " BLINKING COLORS: 16 TO 31 "
FOR fg = 16 TO 31
    COLOR fg, 0
    LOCATE 5 + (fg - 16), 30
    PRINT "COLOR"; fg; "="; fg - 16; "+ 16  "
NEXT fg
COLOR 7, 0
LOCATE 23, 20: PRINT "Press any key to quit."
k$ = INPUT$(1)
COLOR 7, 0: CLS
END
