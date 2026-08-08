' ============================================================
' TITLE:    Hex Viewer
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, hex, dump, SEEK, GET, paging
' SUMMARY:  A scrolling hex + ASCII dump of any file, just like the tools programmers use.
' ------------------------------------------------------------
' WHAT IT DOES
'   Opens a file in BINARY mode and shows 16 bytes per row: the
'   offset, the bytes in hexadecimal, and the printable characters.
'   If you do not name a file it creates SAMPLE.BIN (a mix of text,
'   numbers packed with MKI$/MKS$, and all byte values 0-255) so
'   there is something interesting to explore.
'
' HOW TO USE
'   Enter a file name (or just Enter for the sample).
'   Up/Down arrows = 1 row, PgUp/PgDn = 1 page, Home/End,
'   G = go to an offset (hex like &H100 works too), Q or Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * BINARY mode: any byte, any position
'   * GET #n, position, string$ to read a block of bytes
'   * HEX$ and zero padding for neat columns
'   * Reading extended keys from INKEY$ (CHR$(0) + scan code)
'
' THINGS TO TRY
'   * Highlight bytes that are 0 in a different colour.
'   * Add a "/" search command that finds a text string.
' ============================================================

DECLARE SUB MakeSample (f$)
DECLARE SUB DrawPage (top&)

DIM SHARED fileLen&
CONST ROWS = 20           ' rows of 16 bytes shown per page

CLS
PRINT "HEX VIEWER"
PRINT
LINE INPUT "File to view (Enter = SAMPLE.BIN): "; f$
IF f$ = "" THEN f$ = "SAMPLE.BIN": MakeSample f$

' Opening a missing file FOR BINARY would create an empty one, so
' first try FOR INPUT, which fails with error 53 if it is missing.
ON ERROR GOTO Missing
OPEN f$ FOR INPUT AS #1
CLOSE #1
ON ERROR GOTO 0

OPEN f$ FOR BINARY AS #1
fileLen& = LOF(1)
top& = 0                  ' offset of the first byte on screen
maxTop& = ((fileLen& - 1) \ 16 - ROWS + 1) * 16
IF maxTop& < 0 THEN maxTop& = 0

CLS
COLOR 15, 1
LOCATE 1, 1: PRINT SPACE$(80);
LOCATE 1, 2: PRINT "File: "; UCASE$(f$); "   Size:"; fileLen&; "bytes";
LOCATE 25, 1: PRINT SPACE$(80);
LOCATE 25, 2: PRINT "Arrows/PgUp/PgDn/Home/End move   G goto   Q quit";
COLOR 7, 0
DrawPage top&

DO
    k$ = INKEY$
    IF k$ <> "" THEN
        old& = top&
        SELECT CASE UCASE$(k$)
        CASE "Q", CHR$(27): EXIT DO
        CASE CHR$(0) + "H": top& = top& - 16             ' up arrow
        CASE CHR$(0) + "P": top& = top& + 16             ' down arrow
        CASE CHR$(0) + "I": top& = top& - 16 * ROWS      ' PgUp
        CASE CHR$(0) + "Q": top& = top& + 16 * ROWS      ' PgDn
        CASE CHR$(0) + "G": top& = 0                     ' Home
        CASE CHR$(0) + "O": top& = maxTop&               ' End
        CASE "G"
            LOCATE 24, 1: PRINT SPACE$(79);
            LOCATE 24, 1: LINE INPUT "Go to offset: "; g$
            ' VAL understands &H hex numbers. Round down to a row.
            top& = (VAL(g$) \ 16) * 16
            LOCATE 24, 1: PRINT SPACE$(79);
        END SELECT
        IF top& > maxTop& THEN top& = maxTop&
        IF top& < 0 THEN top& = 0
        DrawPage top&
    END IF
LOOP
CLOSE #1
COLOR 7, 0
CLS
END

Missing:
    PRINT "Cannot open "; f$; " (error"; ERR; ")"
    END

' Draw ROWS lines starting at byte offset top& (0-based).
SUB DrawPage (top&)
    buf$ = SPACE$(16)
    FOR r = 0 TO ROWS - 1
        LOCATE 3 + r, 1
        off& = top& + r * 16
        IF off& >= fileLen& THEN
            PRINT SPACE$(79);
        ELSE
            ' How many bytes are on this row? (the last row may be short)
            n = 16
            IF fileLen& - off& < 16 THEN n = fileLen& - off&
            buf$ = SPACE$(n)
            ' BASIC file positions start at 1, offsets at 0: hence +1.
            GET #1, off& + 1, buf$
            COLOR 14
            PRINT RIGHT$("0000000" + HEX$(off&), 8); "  ";
            COLOR 7
            hx$ = "": asc$ = ""
            FOR i = 1 TO 16
                IF i <= n THEN
                    b = ASC(MID$(buf$, i, 1))
                    hx$ = hx$ + RIGHT$("0" + HEX$(b), 2) + " "
                    ' Only show "safe" printable characters; others as a dot.
                    IF b >= 32 AND b < 127 THEN asc$ = asc$ + CHR$(b) ELSE asc$ = asc$ + "."
                ELSE
                    hx$ = hx$ + "   "
                END IF
                IF i = 8 THEN hx$ = hx$ + " "    ' gap in the middle
            NEXT
            PRINT hx$; " ";
            COLOR 11: PRINT asc$; SPACE$(16 - n);
            COLOR 7
        END IF
    NEXT
END SUB

' Build a 400-ish byte file with recognisable parts.
SUB MakeSample (f$)
    OPEN f$ FOR OUTPUT AS #1: CLOSE #1          ' make sure it is empty
    OPEN f$ FOR BINARY AS #1
    t$ = "Hello from the Compendium hex viewer! "
    PUT #1, , t$
    t$ = MKI$(1234) + MKI$(-1) + MKL$(65536) + MKS$(3.14159)
    PUT #1, , t$
    t$ = "<-- packed numbers. Now every byte 0..255:"
    PUT #1, , t$
    FOR i = 0 TO 255
        t$ = CHR$(i)
        PUT #1, , t$
    NEXT
    t$ = "THE END"
    PUT #1, , t$
    CLOSE #1
END SUB
