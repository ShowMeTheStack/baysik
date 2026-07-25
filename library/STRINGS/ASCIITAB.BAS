' ============================================================
' TITLE:    ASCII & Code Page 437 Explorer
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     ASCII, CP437, CHR$, ASC, HEX$, character codes, POKE
' SUMMARY:  Browse all 256 PC characters in a grid and inspect any one in decimal, hex, binary and octal.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every character a computer shows is really a number.  "A" is
'   65, "a" is 97, a space is 32.  Codes 0-127 are standard ASCII;
'   the IBM PC added codes 128-255 ("code page 437") with accented
'   letters, Greek maths symbols and the famous box-drawing and
'   block characters used in DOS programs.
'
'   This explorer draws all 256 characters in a 16 x 16 grid.
'   Move the highlight with the arrow keys; the panel shows the
'   code in decimal, hexadecimal, octal and binary plus its name
'   or category.  Type any key to jump straight to that character.
'
' HOW TO USE
'   Arrow keys move.  Any printable key jumps to its character.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * CHR$(n) turns a code into a character, ASC(c$) the reverse
'   * HEX$ and OCT$ number bases; building binary yourself with \ and MOD
'   * Codes 0-31 are "control codes" - printing them with PRINT may
'     move the cursor, so we POKE them straight into video memory
'   * Reading arrow keys: INKEY$ returns CHR$(0) + scan code
'
' THINGS TO TRY
'   * Draw a box using codes 201, 205, 187, 186, 200, 188
'   * Find the codes of the card suits and smiley faces (1-6)
'   * Notice that "A" (65) and "a" (97) differ by exactly 32 = bit 5
' ============================================================

DECLARE SUB DrawCell (code, hilite)
DECLARE SUB ShowInfo (code)
DECLARE FUNCTION Binary$ (n)

CONST TOP = 3, LEFTCOL = 4      ' screen position of the grid

CLS
COLOR 14: PRINT "ASCII & CODE PAGE 437 EXPLORER": COLOR 7
' column headings 0..F
LOCATE TOP - 1, LEFTCOL + 3
FOR c = 0 TO 15: PRINT HEX$(c); "  "; : NEXT c
' draw the whole grid once, with row headings 0x .. Fx
FOR r = 0 TO 15
    LOCATE TOP + r, LEFTCOL - 1: COLOR 8: PRINT HEX$(r); "x"; : COLOR 7
    FOR c = 0 TO 15
        DrawCell r * 16 + c, 0
    NEXT c
NEXT r
LOCATE 21, 1
COLOR 8
PRINT "  Arrows move   any key jumps to it   Esc quits"
COLOR 7

cur = 65                         ' start on the letter A
DrawCell cur, 1: ShowInfo cur
DO
    k$ = INKEY$
    IF k$ <> "" THEN
        old = cur
        IF LEN(k$) = 2 THEN                  ' extended key: CHR$(0)+code
            SELECT CASE ASC(RIGHT$(k$, 1))
                CASE 72: cur = cur - 16      ' up
                CASE 80: cur = cur + 16      ' down
                CASE 75: cur = cur - 1       ' left
                CASE 77: cur = cur + 1       ' right
            END SELECT
            cur = (cur + 256) MOD 256        ' wrap around the table
        ELSEIF k$ = CHR$(27) THEN
            EXIT DO
        ELSE
            cur = ASC(k$)                    ' jump to the typed character
        END IF
        IF cur <> old THEN DrawCell old, 0: DrawCell cur, 1: ShowInfo cur
    END IF
LOOP
COLOR 7, 0
CLS
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' DrawCell: put one character in its grid cell.
' Text-mode video memory starts at segment &HB800.  Each screen
' cell uses 2 bytes: the character code, then its colour
' (background * 16 + foreground).  POKEing the code shows the
' character's GLYPH even for control codes like 7 (bell) or
' 13 (carriage return), which PRINT would act on instead.
' ------------------------------------------------------------
SUB DrawCell (code, hilite)
    r = code \ 16: c = code MOD 16
    row = TOP + r: col = LEFTCOL + 3 + c * 3      ' 1-based screen position
    IF hilite THEN attr = 14 * 16 + 0 ELSE attr = 7  ' black on yellow / grey
    DEF SEG = &HB800
    ofs = ((row - 1) * 80 + (col - 1)) * 2
    POKE ofs, code
    POKE ofs + 1, attr
    DEF SEG
END SUB

' ShowInfo: the information panel to the right of the grid.
SUB ShowInfo (code)
    x = 58
    LOCATE 3, x: COLOR 15: PRINT "Character:       ";
    DEF SEG = &HB800: POKE ((3 - 1) * 80 + 69) * 2, code: DEF SEG
    LOCATE 5, x: COLOR 7: PRINT USING "Decimal : ###  "; code
    LOCATE 6, x: PRINT "Hex     : "; RIGHT$("0" + HEX$(code), 2); "  "
    LOCATE 7, x: PRINT "Octal   : "; RIGHT$("00" + OCT$(code), 3); " "
    LOCATE 8, x: PRINT "Binary  : "; Binary$(code)
    SELECT CASE code
        CASE 0 TO 31: kind$ = "control code"
        CASE 32: kind$ = "space"
        CASE 48 TO 57: kind$ = "digit"
        CASE 65 TO 90: kind$ = "upper-case letter"
        CASE 97 TO 122: kind$ = "lower-case letter"
        CASE 33 TO 47, 58 TO 64, 91 TO 96, 123 TO 126: kind$ = "punctuation"
        CASE 127: kind$ = "delete (house glyph)"
        CASE 128 TO 175: kind$ = "accented / foreign"
        CASE 176 TO 178: kind$ = "shade block"
        CASE 179 TO 218: kind$ = "box drawing"
        CASE 219 TO 223: kind$ = "solid block"
        CASE 224 TO 254: kind$ = "Greek / maths"
        CASE ELSE: kind$ = "non-breaking space"
    END SELECT
    ' a few famous control codes get their real names
    SELECT CASE code
        CASE 7: kind$ = "BEL - beeps the speaker"
        CASE 8: kind$ = "BS - backspace"
        CASE 9: kind$ = "TAB - tab"
        CASE 10: kind$ = "LF - line feed"
        CASE 13: kind$ = "CR - carriage return"
        CASE 27: kind$ = "ESC - escape"
    END SELECT
    LOCATE 10, x: PRINT "Type    :"
    LOCATE 11, x: COLOR 11: PRINT LEFT$(kind$ + SPACE$(22), 22): COLOR 7
    ' upper/lower-case partner: flip bit 5 (value 32)
    LOCATE 13, x
    IF (code >= 65 AND code <= 90) OR (code >= 97 AND code <= 122) THEN
        PRINT "Other case: "; CHR$(code XOR 32); " ("; LTRIM$(STR$(code XOR 32)); ")  "
    ELSE
        PRINT SPACE$(21)
    END IF
    LOCATE 15, x: PRINT "In BASIC: CHR$("; LTRIM$(STR$(code)); ")   "
END SUB

' Binary$: repeatedly take the remainder after dividing by 2.
' The remainders, read backwards, are the binary digits.
FUNCTION Binary$ (n)
    b$ = "": v = n
    FOR i = 1 TO 8
        b$ = LTRIM$(STR$(v MOD 2)) + b$
        v = v \ 2
    NEXT i
    Binary$ = LEFT$(b$, 4) + " " + RIGHT$(b$, 4)
END FUNCTION
