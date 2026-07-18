' ============================================================
' TITLE:    Hex Viewer
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     hex, binary files, hex$, paging, keyboard
' SUMMARY:  A scrolling hex-dump viewer showing any file as offsets, hex bytes and characters side by side.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every file is just a list of bytes (numbers 0-255).  A hex viewer
'   shows them the way programmers look at them: 16 bytes per line,
'   each written as two hex digits, with the matching characters on
'   the right.  The program first writes a demo file (HEXDEMO.BIN)
'   so there is always something to look at, then lets you open it
'   or any other file on the disk - try one of the .BAS programs!
'
' HOW TO USE
'   Type a file name (or just Enter for the demo file).
'   Up / Down     scroll one line        PgUp / PgDn  one page
'   Home / End    start / end of file    O  open another file
'   Esc or Q      quit
'
' CONCEPTS YOU WILL LEARN
'   * OPEN ... FOR BINARY, LOF, SEEK and GET with a string buffer
'   * HEX$ and padding with RIGHT$("0" + ..., 2)
'   * Paging through data bigger than the screen
'   * Showing unprintable bytes safely
'
' THINGS TO TRY
'   * Add a search: type some text and jump to where it appears.
'   * Highlight all zero bytes in dark grey.
'   * Add editing: move a cursor over a byte and type new hex digits.
' ============================================================

DEFINT A-Z
DECLARE SUB ShowPage (f, top&, size&, nm$)
DECLARE FUNCTION Hex2$ (n)

CONST LINES = 20          ' lines of 16 bytes on one page
CONST DEMO = "HEXDEMO.BIN"

SCREEN 0: WIDTH 80, 25

' ---- 1. Make a demo file -----------------------------------------
' A short message, then every byte value from 0 to 255, so you can
' see what each value looks like in the hex and character columns.
f = FREEFILE
OPEN DEMO FOR OUTPUT AS #f: CLOSE #f        ' empty it first
OPEN DEMO FOR BINARY AS #f
msg$ = "Hello from the Hex Viewer! Every byte 0-255 follows:" + CHR$(13) + CHR$(10)
PUT #f, , msg$
FOR i = 0 TO 255
    b$ = CHR$(i)
    PUT #f, , b$
NEXT i
msg$ = CHR$(13) + CHR$(10) + "The End." + CHR$(13) + CHR$(10)
PUT #f, , msg$
CLOSE #f

ON ERROR GOTO BadFile
DO
    ' ---- 2. Ask for a file name -------------------------------------
    COLOR 7, 0: CLS
    COLOR 15: PRINT "HEX VIEWER": COLOR 7
    PRINT
    PRINT "Files on this disk:"
    FILES                      ' lists the current directory
    PRINT
    LINE INPUT "File to view (Enter = HEXDEMO.BIN, Q = quit): "; nm$
    nm$ = UCASE$(LTRIM$(RTRIM$(nm$)))
    IF nm$ = "Q" THEN EXIT DO
    IF nm$ = "" THEN nm$ = DEMO
    ' Check the file exists: opening a missing file FOR INPUT raises
    ' an error, which BadFile turns into the flag "failed".
    failed = 0
    f = FREEFILE
    OPEN nm$ FOR INPUT AS #f
    IF failed THEN
        PRINT "Can't open "; nm$; " - press a key.": k$ = INPUT$(1)
    ELSE
        CLOSE #f
        f = FREEFILE
        OPEN nm$ FOR BINARY AS #f
        size& = LOF(f)
        top& = 0                    ' offset of the first byte on screen
        page& = LINES * 16          ' bytes per page
        DO
            ShowPage f, top&, size&, nm$
            DO: k$ = INKEY$: LOOP WHILE k$ = ""
            SELECT CASE UCASE$(k$)
                CASE CHR$(0) + "H": top& = top& - 16           ' Up
                CASE CHR$(0) + "P": top& = top& + 16           ' Down
                CASE CHR$(0) + "I": top& = top& - page&        ' PgUp
                CASE CHR$(0) + "Q": top& = top& + page&        ' PgDn
                CASE CHR$(0) + "G": top& = 0                   ' Home
                CASE CHR$(0) + "O": top& = size& - page&       ' End
                CASE "O": EXIT DO
                CASE CHR$(27), "Q": CLOSE #f: GOTO Done
            END SELECT
            ' Keep the window inside the file, on a multiple of 16.
            last& = ((size& - 1) \ 16) * 16 - (LINES - 1) * 16
            IF top& > last& THEN top& = last&
            IF top& < 0 THEN top& = 0
            top& = (top& \ 16) * 16
        LOOP
        CLOSE #f
    END IF
LOOP
Done:
COLOR 7, 0: CLS
END

BadFile:
    failed = 1
    RESUME NEXT

' Two-digit hex: HEX$(10) is "A", so add a leading 0 when needed.
FUNCTION Hex2$ (n)
    Hex2$ = RIGHT$("0" + HEX$(n), 2)
END FUNCTION

SUB ShowPage (f, top&, size&, nm$)
    COLOR 7, 0: CLS
    COLOR 15, 1: LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 2: PRINT nm$;
    LOCATE 1, 40: PRINT USING "size ######## bytes   offset &H"; size&;
    PRINT RIGHT$("00000" + HEX$(top&), 6);
    COLOR 11, 0
    LOCATE 3, 1: PRINT "Offset  ";
    FOR i = 0 TO 15
        PRINT Hex2$(i); " ";
        IF i = 7 THEN PRINT " ";
    NEXT i
    LOCATE 3, 61: PRINT "0123456789ABCDEF";

    ' Read one page worth of bytes in a single GET.
    want& = size& - top&
    IF want& > LINES * 16 THEN want& = LINES * 16
    IF want& <= 0 THEN EXIT SUB
    buf$ = SPACE$(want&)
    GET #f, top& + 1, buf$          ' BINARY positions start at 1

    FOR ln = 0 TO LINES - 1
        IF ln * 16 >= LEN(buf$) THEN EXIT FOR
        row = 4 + ln
        COLOR 8, 0
        LOCATE row, 1: PRINT RIGHT$("00000" + HEX$(top& + ln * 16), 6); "  ";
        hx$ = "": ch$ = ""
        FOR i = 0 TO 15
            p = ln * 16 + i + 1
            IF p <= LEN(buf$) THEN
                b = ASC(MID$(buf$, p, 1))
                hx$ = hx$ + Hex2$(b) + " "
                ' Control codes (below 32) would move the cursor or beep
                ' if printed, so show a dot instead.
                IF b < 32 THEN ch$ = ch$ + "." ELSE ch$ = ch$ + CHR$(b)
            ELSE
                hx$ = hx$ + "   ": ch$ = ch$ + " "
            END IF
            IF i = 7 THEN hx$ = hx$ + " "      ' gap in the middle
        NEXT i
        COLOR 7: PRINT hx$;
        COLOR 14: LOCATE row, 61: PRINT ch$;
    NEXT ln

    COLOR 0, 7: LOCATE 25, 1: PRINT SPACE$(80);
    LOCATE 25, 2: PRINT "Up/Down line  PgUp/PgDn page  Home/End  O = open another file  Esc = quit";
END SUB
