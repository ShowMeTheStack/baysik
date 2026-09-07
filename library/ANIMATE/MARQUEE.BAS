' ============================================================
' TITLE:    LED Marquee Sign
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     scrolling text, bitmaps, POINT, bit masks, marquee
' SUMMARY:  A glowing dot-matrix sign scrolls your message across the screen, one LED column at a time.
' ------------------------------------------------------------
' WHAT IT DOES
'   Turns a text message into a long strip of 8-dot columns,
'   like the moving signs in shop windows and train stations.
'   It "reads the font" by PRINTing each letter on the screen
'   and checking every pixel with POINT.  Each column of a letter
'   is packed into one number using bits (1, 2, 4, ... 128).
'   The sign then shows a 40-column window into that strip and
'   slides the window one column per step.
'
' HOW TO USE
'   T      type a new message
'   + / -  faster / slower
'   C      change LED color
'   Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * Reading pixels back with POINT
'   * Bit masks: storing 8 on/off dots in one number, and
'     testing a dot with  (value AND bit) <> 0
'   * A sliding window over a long array (MOD wraps it around)
'   * Redrawing only what changed to keep it fast
'
' THINGS TO TRY
'   * Make the sign 2 rows tall with two messages
'   * Make letters wobble up and down as they scroll
' ============================================================
DEFINT A-Z
DECLARE SUB BuildStrip (m$)

CONST VISIBLE = 40               ' LED columns shown on the sign
CONST DOT = 7                    ' each LED is 7x7 pixels + 1 gap
CONST SIGNX = 0, SIGNY = 70      ' top-left corner of the sign

DIM SHARED strip(2000)           ' one 8-bit column per entry
DIM SHARED stripLen
DIM shown(VISIBLE, 7)            ' what each LED shows now (0/1)

SCREEN 13
msg$ = "*** WELCOME TO THE COMPENDIUM ***  QBASIC ANIMATION IS FUN!  "
BuildStrip msg$
onColor = 12                     ' bright red LEDs (off LEDs are dark grey, 8)
speed = 3

GOSUB DrawBoard
pos0 = 0
DO
    ' ---- draw the window strip(pos0) .. strip(pos0+39) ------
    FOR c = 0 TO VISIBLE - 1
        col = strip((pos0 + c) MOD stripLen)
        FOR r = 0 TO 7
            ' Bit r of the column tells if LED row r is lit.
            ' 2 ^ r is the bit's value: 1, 2, 4, 8 ... 128.
            lit = -((col AND 2 ^ r) <> 0)        ' 1 = on, 0 = off
            IF lit <> shown(c, r) THEN           ' only redraw changes
                shown(c, r) = lit
                IF lit THEN clr = onColor ELSE clr = 8
                LINE (SIGNX + c * (DOT + 1) + 1, SIGNY + r * (DOT + 1) + 1)-STEP(DOT - 1, DOT - 1), clr, BF
            END IF
        NEXT
    NEXT
    pos0 = (pos0 + 1) MOD stripLen

    FOR d = 1 TO speed: WAIT &H3DA, 8, 8: WAIT &H3DA, 8: NEXT

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "+", "=": IF speed > 1 THEN speed = speed - 1
        CASE "-": IF speed < 10 THEN speed = speed + 1
        CASE "C"
            onColor = onColor + 1: IF onColor > 15 THEN onColor = 9
            GOSUB DrawBoard
        CASE "T"
            LOCATE 20, 1: PRINT SPACE$(40);
            LOCATE 20, 1: LINE INPUT "Message: "; m$
            IF LEN(m$) > 0 THEN BuildStrip m$ + "   ": pos0 = 0
            LOCATE 20, 1: PRINT SPACE$(40);
            GOSUB DrawBoard
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

DrawBoard:
    ' The black frame plus every LED switched off.
    LINE (SIGNX, SIGNY - 4)-(SIGNX + 319, SIGNY + 8 * (DOT + 1) + 3), 0, BF
    LINE (SIGNX, SIGNY - 4)-(SIGNX + 319, SIGNY + 8 * (DOT + 1) + 3), 7, B
    FOR c = 0 TO VISIBLE - 1
        FOR r = 0 TO 7
            shown(c, r) = 0
            LINE (SIGNX + c * (DOT + 1) + 1, SIGNY + r * (DOT + 1) + 1)-STEP(DOT - 1, DOT - 1), 8, BF
        NEXT
    NEXT
    COLOR 7: LOCATE 2, 1: PRINT "T text  +/- speed  C color  Esc quit"
    RETURN

SUB BuildStrip (m$)
    ' Convert the message to columns of bits.
    ' We print each character at the bottom-left of the screen,
    ' read its 8x8 pixels with POINT, then rub it out.
    stripLen = 0
    FOR i = 1 TO LEN(m$)
        IF stripLen > 1990 THEN EXIT FOR
        LOCATE 25, 1: COLOR 15: PRINT MID$(m$, i, 1);
        FOR x = 0 TO 7
            v = 0
            FOR y = 0 TO 7
                IF POINT(x, 192 + y) <> 0 THEN v = v OR 2 ^ y
            NEXT
            strip(stripLen) = v
            stripLen = stripLen + 1
        NEXT
    NEXT
    LOCATE 25, 1: PRINT " ";
    ' Make sure the strip is at least as wide as the sign.
    WHILE stripLen < VISIBLE: strip(stripLen) = 0: stripLen = stripLen + 1: WEND
END SUB
