' ============================================================
' TITLE:    Palette Color Picker
' CATEGORY: Utilities & Tools
' LEVEL:    Advanced
' TAGS:     palette, vga, rgb, screen 12, graphics, colour mixing
' SUMMARY:  Mix your own VGA colours with red/green/blue sliders and get the exact PALETTE statement to use.
' ------------------------------------------------------------
' WHAT IT DOES
'   SCREEN 12 can show 16 colours at once, but EACH of those 16
'   "attributes" can be set to any of 262,144 shades with the
'   PALETTE statement.  This tool shows the 16 attributes as
'   swatches.  Pick one, then slide its Red, Green and Blue
'   levels (each 0-63, because the VGA uses 6 bits per channel)
'   and watch it change instantly.
'
'   The value PALETTE wants packs the three channels together:
'       value = 65536 * blue + 256 * green + red
'   The program prints the ready-to-copy statement, and the
'   modern 24-bit "#RRGGBB" web colour (each channel scaled from
'   0-63 up to 0-255).
'
' HOW TO USE
'   Left/Right   choose an attribute (swatch) 0-15
'   Up/Down      choose the channel (R, G or B)
'   + / -        change the channel by 1   (PgUp/PgDn: by 8)
'   D            restore the default palette
'   Q / Esc      quit
'
' CONCEPTS YOU WILL LEARN
'   * PALETTE attribute, colour  and the packed RGB number
'   * Why VGA DAC values are 0..63 (6 bits)
'   * LINE ... BF to draw filled boxes
'   * Remembering per-attribute settings in arrays
'   * Changing a palette entry recolours everything already
'     drawn in that attribute - no redrawing needed!
'
' THINGS TO TRY
'   * Add a "gradient" key that fills attributes 1-14 smoothly
'     between the colours of attribute 0 and 15.
'   * Save your palette to a file and load it in another program.
'   * Do the same in SCREEN 13 with OUT &H3C8 / &H3C9 (256 colours).
' ============================================================

DECLARE SUB DrawUI ()
DECLARE SUB SetColour (a%)

' DEFINT A-Z makes every untyped variable an INTEGER.  That matters
' here: SetColour wants an INTEGER argument, and passing a SINGLE
' loop variable would cause a "Parameter type mismatch" error.
DEFINT A-Z

SCREEN 12                  ' 640x480, 16 colours

' Keep our own copy of each attribute's R, G, B (0..63).
DIM SHARED r%(15), g%(15), b%(15), sel%, chan%

' The standard 16 colours, written as R,G,B in 0..63 steps.
FOR i = 0 TO 15: READ r%(i), g%(i), b%(i): NEXT i
DATA 0,0,0, 0,0,42, 0,42,0, 0,42,42, 42,0,0, 42,0,42, 42,21,0, 42,42,42
DATA 21,21,21, 21,21,63, 21,63,21, 21,63,63, 63,21,21, 63,21,63, 63,63,21, 63,63,63

sel% = 1: chan% = 0
FOR i = 0 TO 15: SetColour i: NEXT i
' Attribute 15 is used for text, attribute 0 is the background.
' If you change those you change the whole screen - try it!
DrawUI

DO
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    k$ = UCASE$(k$)
    stp% = 0
    SELECT CASE k$
        CASE CHR$(0) + "K": sel% = (sel% + 15) MOD 16       ' left
        CASE CHR$(0) + "M": sel% = (sel% + 1) MOD 16        ' right
        CASE CHR$(0) + "H": chan% = (chan% + 2) MOD 3       ' up
        CASE CHR$(0) + "P": chan% = (chan% + 1) MOD 3       ' down
        CASE "+", "=": stp% = 1
        CASE "-", "_": stp% = -1
        CASE CHR$(0) + "I": stp% = 8                        ' PgUp
        CASE CHR$(0) + "Q": stp% = -8                       ' PgDn
        CASE "D"
            RESTORE
            FOR i = 0 TO 15: READ r%(i), g%(i), b%(i): SetColour i: NEXT i
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
    IF stp% THEN
        ' Change the chosen channel, clamped to 0..63.
        SELECT CASE chan%
            CASE 0: r%(sel%) = r%(sel%) + stp%: IF r%(sel%) < 0 THEN r%(sel%) = 0 ELSE IF r%(sel%) > 63 THEN r%(sel%) = 63
            CASE 1: g%(sel%) = g%(sel%) + stp%: IF g%(sel%) < 0 THEN g%(sel%) = 0 ELSE IF g%(sel%) > 63 THEN g%(sel%) = 63
            CASE 2: b%(sel%) = b%(sel%) + stp%: IF b%(sel%) < 0 THEN b%(sel%) = 0 ELSE IF b%(sel%) > 63 THEN b%(sel%) = 63
        END SELECT
        SetColour sel%
    END IF
    DrawUI
LOOP
PALETTE                    ' PALETTE with no arguments = restore defaults
SCREEN 0: WIDTH 80
END

' Draw swatches, sliders and the code line.
SUB DrawUI
    ' ---- 16 swatches across the top ----
    FOR i = 0 TO 15
        x = 20 + i * 38
        LINE (x, 40)-(x + 32, 110), i, BF        ' filled box in colour i
        LINE (x - 2, 38)-(x + 34, 112), 0, B     ' erase old highlight
        LINE (x, 40)-(x + 32, 110), 7, B         ' thin outline
        IF i = sel% THEN LINE (x - 2, 38)-(x + 34, 112), 15, B
        LOCATE 9, (x + 8) \ 8 + 1: PRINT RIGHT$(" " + LTRIM$(STR$(i)), 2);
    NEXT i
    LOCATE 1, 25: PRINT "VGA PALETTE COLOUR PICKER"

    ' ---- A big preview of the selected colour ----
    LINE (420, 160)-(620, 330), sel%, BF
    LINE (420, 160)-(620, 330), 15, B

    ' ---- Three sliders: R, G, B ----
    names$ = "RGB"
    FOR c = 0 TO 2
        SELECT CASE c
            CASE 0: v = r%(sel%)
            CASE 1: v = g%(sel%)
            CASE 2: v = b%(sel%)
        END SELECT
        y = 180 + c * 50
        LOCATE y \ 16 + 1, 3
        IF c = chan% THEN PRINT ">"; ELSE PRINT " ";
        PRINT MID$(names$, c + 1, 1);
        PRINT USING " ##"; v
        ' slider track 0..63 mapped to 64*5 = 320 pixels
        LINE (74, y - 2)-(406, y + 12), 0, BF          ' erase old knob
        LINE (80, y + 4)-(80 + 320, y + 6), 8, BF
        LINE (80 + v * 5 - 3, y - 2)-(80 + v * 5 + 3, y + 12), 15, BF
    NEXT c

    ' ---- The code to copy ----
    value& = 65536 * b%(sel%) + 256& * g%(sel%) + r%(sel%)
    ' Scale 0..63 to 0..255 for a web colour: x * 255 / 63.
    web$ = "#"
    web$ = web$ + RIGHT$("0" + HEX$(r%(sel%) * 255 \ 63), 2)
    web$ = web$ + RIGHT$("0" + HEX$(g%(sel%) * 255 \ 63), 2)
    web$ = web$ + RIGHT$("0" + HEX$(b%(sel%) * 255 \ 63), 2)
    LOCATE 23, 3: PRINT "PALETTE"; STR$(sel%); ","; STR$(value&); SPACE$(10)
    LOCATE 24, 3: PRINT "web colour "; web$; "    attribute"; sel%; "  "
    LOCATE 26, 3: PRINT "<- -> pick   Up/Dn channel   + - adjust   PgUp/PgDn x8   D defaults   Q quit";
END SUB

' Send attribute a%'s colour to the VGA using PALETTE.
SUB SetColour (a%)
    PALETTE a%, 65536 * b%(a%) + 256& * g%(a%) + r%(a%)
END SUB
