' ============================================================
' TITLE:    Character Set Explorer
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     ascii, cp437, chr$, video memory, poke, keyboard
' SUMMARY:  Browse all 256 PC characters in a 16x16 grid and see each one's code in decimal, hex and binary.
' ------------------------------------------------------------
' WHAT IT DOES
'   The IBM PC has 256 characters (called "code page 437"): letters,
'   digits, accented letters, Greek symbols, card suits, smiley
'   faces and the famous box-drawing lines.  This program shows
'   them all in a 16 x 16 grid.  Move a highlight around with the
'   arrow keys and a panel shows the code of the selected
'   character and the CHR$() call you would use to print it.
'
' HOW TO USE
'   Arrow keys  move the highlight
'   Home / End  jump to code 0 / code 255
'   Esc or Q    quit
'
' CONCEPTS YOU WILL LEARN
'   * Why some codes (like 7, 10, 13) cannot be PRINTed directly
'   * Writing characters straight into video memory with POKE
'   * Reading arrow keys: INKEY$ returns CHR$(0) + scan code
'   * Converting numbers to HEX$ and to binary by hand
'
' THINGS TO TRY
'   * Add a "copy" key that appends the character to a string and
'     shows the string you are building at the bottom.
'   * Highlight the box-drawing range 179-218 in a different color.
' ============================================================

DEFINT A-Z        ' all variables are integers unless told otherwise
DECLARE SUB PutChar (row%, col%, code%, attr%)
DECLARE SUB DrawCell (code%, attr%)
DECLARE FUNCTION Bin$ (n%)

' Grid placement: the top-left cell is at screen row 4, column 6.
' Each cell is 3 columns wide so the characters are not crowded.
CONST TOPROW = 4, LEFTCOL = 6
CONST NORMAL = &H17     ' attribute byte: grey (7) on blue (1)
CONST HILITE = &H4E     ' attribute byte: yellow (E) on red (4)

SCREEN 0: WIDTH 80, 25
COLOR 7, 1: CLS

COLOR 15, 1
LOCATE 1, 24: PRINT "THE 256 CHARACTERS OF CODE PAGE 437"
COLOR 11, 1
' Column headers 0..F along the top, row headers 0..F down the side.
FOR i = 0 TO 15
    LOCATE TOPROW - 1, LEFTCOL + i * 3 + 1: PRINT HEX$(i);
    LOCATE TOPROW + i, LEFTCOL - 3: PRINT HEX$(i); "_";
NEXT i

' Why POKE?  PRINT CHR$(7) beeps, CHR$(13) moves to a new line,
' CHR$(12) clears the screen, and so on.  Those are "control
' characters".  Writing directly into video memory side-steps all
' of that, so every one of the 256 shapes appears.
FOR c = 0 TO 255
    DrawCell c, NORMAL
NEXT c

' ---- Info panel labels ------------------------------------
COLOR 14, 1
LOCATE 5, 58: PRINT "Selected character"
COLOR 7, 1
LOCATE 7, 58: PRINT "Decimal :"
LOCATE 8, 58: PRINT "Hex     :"
LOCATE 9, 58: PRINT "Binary  :"
LOCATE 10, 58: PRINT "BASIC   :"
LOCATE 22, 6: PRINT "Arrows move   Home/End jump   Esc or Q quits";

cur = 65          ' start on the letter "A"
DO
    ' Highlight current cell and show the big preview & info
    DrawCell cur, HILITE
    ' A 3x3 "zoom" of the character: the same glyph in a frame.
    FOR r = 0 TO 2
        FOR k = 0 TO 4
            PutChar 13 + r, 64 + k, 32, &H70
        NEXT k
    NEXT r
    PutChar 14, 66, cur, &H70
    COLOR 15, 1
    LOCATE 7, 68: PRINT USING "###"; cur
    LOCATE 8, 68: PRINT "&H"; RIGHT$("0" + HEX$(cur), 2)
    LOCATE 9, 68: PRINT Bin$(cur)
    LOCATE 10, 68: PRINT "CHR$("; LTRIM$(STR$(cur)); ")  "
    LOCATE 18, 58: PRINT SPACE$(20)
    LOCATE 18, 58
    SELECT CASE cur
        CASE 0 TO 31: PRINT "control code"
        CASE 32: PRINT "the space"
        CASE 48 TO 57: PRINT "a digit"
        CASE 65 TO 90: PRINT "UPPERCASE letter"
        CASE 97 TO 122: PRINT "lowercase letter"
        CASE 128 TO 175: PRINT "accents & symbols"
        CASE 176 TO 178: PRINT "shading block"
        CASE 179 TO 218: PRINT "box drawing"
        CASE 219 TO 223: PRINT "solid block"
        CASE 224 TO 254: PRINT "Greek & math"
        CASE ELSE: PRINT "punctuation/other"
    END SELECT

    ' Wait for a key.  Special keys arrive as two characters:
    ' CHR$(0) followed by a "scan code" (72 = Up, 80 = Down,
    ' 75 = Left, 77 = Right, 71 = Home, 79 = End).
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    old = cur
    IF LEN(k$) = 2 THEN
        SELECT CASE ASC(RIGHT$(k$, 1))
            CASE 72: cur = cur - 16        ' up one row
            CASE 80: cur = cur + 16        ' down one row
            CASE 75: cur = cur - 1         ' left
            CASE 77: cur = cur + 1         ' right
            CASE 71: cur = 0
            CASE 79: cur = 255
        END SELECT
        ' wrap around the 0..255 range (AND 255 keeps the low 8 bits)
        cur = (cur + 256) AND 255
    ELSE
        IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN EXIT DO
        cur = ASC(k$)      ' typing a key jumps to that character!
    END IF
    DrawCell old, NORMAL   ' un-highlight the old cell
LOOP

COLOR 7, 0: CLS
END

' Binary string of an 8-bit number, e.g. 65 -> "01000001".
' We test each bit from the highest (128) down to the lowest (1).
FUNCTION Bin$ (n%)
    s$ = ""
    bit% = 128
    DO WHILE bit% > 0
        IF n% AND bit% THEN s$ = s$ + "1" ELSE s$ = s$ + "0"
        bit% = bit% \ 2
    LOOP
    Bin$ = s$
END FUNCTION

' Draw one grid cell (3 columns wide) for character "code".
SUB DrawCell (code%, attr%)
    r% = TOPROW + code% \ 16         ' which row of 16
    c% = LEFTCOL + (code% MOD 16) * 3 ' which column
    PutChar r%, c%, 32, attr%
    PutChar r%, c% + 1, code%, attr%
    PutChar r%, c% + 2, 32, attr%
END SUB

' Put a character + colour straight into text video memory.
' The text screen starts at segment &HB800.  Each screen cell uses
' 2 bytes: first the character code, then the attribute (colour).
' Rows are 80 cells = 160 bytes long.
SUB PutChar (row%, col%, code%, attr%)
    DEF SEG = &HB800
    offset% = ((row% - 1) * 80 + (col% - 1)) * 2
    POKE offset%, code%
    POKE offset% + 1, attr%
    DEF SEG
END SUB
