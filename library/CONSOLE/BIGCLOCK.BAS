' ============================================================
' TITLE:    Seven-Segment Clock
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     clock, time$, seven segment, bits, animation
' SUMMARY:  A giant digital clock built from seven-segment digits, with a blinking colon and a seconds bar.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows the current time in huge digits, like an alarm clock.
'   Each digit is made of 7 "segments" (the bars of an LED display).
'   Which segments are lit for each digit is stored as a 7-bit
'   number, and the program tests each bit to decide what to draw.
'   Below the clock there is the date, the weekday and a bar that
'   fills up as the minute goes by.
'
' HOW TO USE
'   C   change the colour of the digits
'   2   toggle 12 / 24 hour display
'   Esc or Q  quit
'
' CONCEPTS YOU WILL LEARN
'   * TIME$ ("HH:MM:SS") and DATE$ ("MM-DD-YYYY")
'   * Bit masks: (pattern AND 2^n) tells if segment n is on
'   * Only redrawing when something changes (when the second ticks)
'
' THINGS TO TRY
'   * Add an alarm: when TIME$ equals a time you choose, PLAY a tune.
'   * Draw unlit segments in dark grey, like a real LCD.
'   * Make it a stopwatch that starts at 00:00:00.
' ============================================================

DEFINT A-Z
DECLARE SUB DrawDigit (x, n)
DECLARE SUB HBar (x, y, onOff)
DECLARE SUB VBar (x, y, onOff)

DIM SHARED segs(0 TO 9), fgc
' Segment letters, the standard way:      aaaa
'                                        f    b
'                                        f    b
'                                         gggg
'                                        e    c
'                                        e    c
'                                         dddd
' Bit 0 = a, bit 1 = b, ... bit 6 = g.  For example "1" lights only
' b and c: bits 1 and 2 = 2 + 4 = 6.
FOR i = 0 TO 9: READ segs(i): NEXT i
'    0    1   2   3    4    5    6   7    8    9
DATA 63, 6, 91, 79, 102, 109, 125, 7, 127, 111

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
fgc = 10           ' digit colour (light green)
h12 = 0            ' 0 = 24 hour clock, 1 = 12 hour clock
last$ = ""

COLOR 8: LOCATE 23, 18: PRINT "C = colour    2 = 12/24 hour    Esc = quit";

DO
    t$ = TIME$
    IF t$ <> last$ THEN               ' only redraw when the second changes
        last$ = t$
        hh = VAL(LEFT$(t$, 2)): mm = VAL(MID$(t$, 4, 2)): ss = VAL(RIGHT$(t$, 2))
        ampm$ = "  "
        IF h12 THEN
            IF hh >= 12 THEN ampm$ = "PM" ELSE ampm$ = "AM"
            hh = hh MOD 12: IF hh = 0 THEN hh = 12
        END IF

        ' Six digits: H H : M M : S S.  Each digit is 8 columns wide;
        ' each colon gap is 4 columns.
        DrawDigit 10, hh \ 10
        DrawDigit 18, hh MOD 10
        DrawDigit 30, mm \ 10
        DrawDigit 38, mm MOD 10
        DrawDigit 50, ss \ 10
        DrawDigit 58, ss MOD 10

        ' The colon blinks: on for even seconds, off for odd ones.
        IF ss MOD 2 = 0 THEN COLOR fgc ELSE COLOR 0
        FOR cx = 27 TO 47 STEP 20
            LOCATE 6, cx: PRINT CHR$(254);
            LOCATE 10, cx: PRINT CHR$(254);
        NEXT cx
        COLOR 15: LOCATE 13, 68: PRINT ampm$;

        ' Date line, e.g. "Thursday, 10-15-2026"
        COLOR 7
        ' Work out the weekday with Zeller's formula (see CALENDAR.BAS).
        m = VAL(LEFT$(DATE$, 2)): d = VAL(MID$(DATE$, 4, 2)): y = VAL(RIGHT$(DATE$, 4))
        IF m < 3 THEN m = m + 12: y = y - 1
        w = (d + (13 * (m + 1)) \ 5 + y MOD 100 + (y MOD 100) \ 4 + (y \ 100) \ 4 + 5 * (y \ 100)) MOD 7
        ' w: 0 = Saturday ... 6 = Friday
        wd$ = MID$("Saturday Sunday   Monday   Tuesday  WednesdayThursday Friday   ", w * 9 + 1, 9)
        ds$ = RTRIM$(wd$) + ",  " + DATE$
        LOCATE 17, 1: PRINT SPACE$(80);
        LOCATE 17, 41 - LEN(ds$) \ 2: PRINT ds$;

        ' Seconds bar: 60 cells, one per second.
        COLOR fgc: LOCATE 19, 10: PRINT STRING$(ss, 219);
        COLOR 8: PRINT STRING$(60 - ss, 196);
    END IF

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "C"
            fgc = fgc + 1: IF fgc > 15 THEN fgc = 9
            last$ = ""                    ' force a redraw
        CASE "2"
            h12 = 1 - h12: last$ = ""
        CASE CHR$(27), "Q"
            EXIT DO
    END SELECT
LOOP

COLOR 7, 0: CLS
END

' Draw digit n with its left edge at column x (top row 3).
' The digit is 7 columns wide and 11 rows tall.
SUB DrawDigit (x, n)
    p = segs(n)
    HBar x, 3, p AND 1           ' a  top
    VBar x + 6, 4, p AND 2       ' b  upper right
    VBar x + 6, 9, p AND 4       ' c  lower right
    HBar x, 13, p AND 8          ' d  bottom
    VBar x, 9, p AND 16          ' e  lower left
    VBar x, 4, p AND 32          ' f  upper left
    HBar x, 8, p AND 64          ' g  middle
END SUB

' A horizontal segment: 5 half-height blocks between the corners.
' CHR$(223) is the upper half block, which makes thin bars.
SUB HBar (x, y, onOff)
    IF onOff THEN COLOR fgc ELSE COLOR 0
    LOCATE y, x + 1: PRINT STRING$(5, 223);
END SUB

' A vertical segment: 4 rows of a solid block.
SUB VBar (x, y, onOff)
    IF onOff THEN COLOR fgc ELSE COLOR 0
    FOR r = 0 TO 3
        LOCATE y + r, x: PRINT CHR$(219);
    NEXT r
END SUB
