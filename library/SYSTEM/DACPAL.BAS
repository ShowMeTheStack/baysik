' ============================================================
' TITLE:    VGA DAC Palette Editor
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     out, inp, vga, dac, palette, 3c7, 3c8, 3c9, screen 13
' SUMMARY:  Edit any of the 256 VGA colours by writing the DAC ports and reading them back through &H3C7/&H3C9.
' ------------------------------------------------------------
' WHAT IT DOES
'   The VGA card has a "Digital to Analog Converter" (DAC) with 256
'   entries.  Each entry holds three 6-bit numbers (0..63) for red,
'   green and blue.  You talk to it through three I/O ports:
'     OUT &H3C8, n   - "I want to WRITE colour n"
'     OUT &H3C9, r : OUT &H3C9, g : OUT &H3C9, b
'     OUT &H3C7, n   - "I want to READ colour n"
'     r = INP(&H3C9) : g = INP(&H3C9) : b = INP(&H3C9)
'   After three bytes the DAC moves on to the next colour by itself.
'   This editor shows all 256 colours as a 16x16 grid.  Pick one and
'   change its red, green and blue.  The numbers on screen are READ
'   BACK from the hardware, so you see what the DAC really holds.
'
' HOW TO USE
'   Arrow keys      move the selection box around the grid
'   R / r  G / g  B / b   raise / lower red, green, blue
'   I               invert the selected colour
'   Z               reset the whole palette (SCREEN 13 again)
'   Esc             quit
'
' CONCEPTS YOU WILL LEARN
'   * Port I/O with OUT and INP
'   * Index auto-increment in the DAC
'   * 6-bit colour (0..63) vs. the 8-bit (0..255) used today
'   * Why the PALETTE statement is just a friendly wrapper for this
'
' THINGS TO TRY
'   * Add a key that copies the colour to the next index
'   * Make a smooth ramp between two chosen colours
'   * Save all 768 values to a file and load them again
' ============================================================

DEFINT A-Z
DECLARE SUB GetRGB (n, r, g, b)
DECLARE SUB SetRGB (n, r, g, b)

SCREEN 13
sel = 1
GOSUB DrawGrid

DO
    GOSUB ShowInfo
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    GetRGB sel, r, g, b                  ' current values from hardware
    oldSel = sel
    SELECT CASE k$
        CASE CHR$(0) + "K": sel = (sel + 255) MOD 256          ' left
        CASE CHR$(0) + "M": sel = (sel + 1) MOD 256            ' right
        CASE CHR$(0) + "H": sel = (sel + 240) MOD 256          ' up a row
        CASE CHR$(0) + "P": sel = (sel + 16) MOD 256           ' down a row
        CASE "R": IF r < 63 THEN r = r + 1
        CASE "r": IF r > 0 THEN r = r - 1
        CASE "G": IF g < 63 THEN g = g + 1
        CASE "g": IF g > 0 THEN g = g - 1
        CASE "B": IF b < 63 THEN b = b + 1
        CASE "b": IF b > 0 THEN b = b - 1
        CASE "I", "i": r = 63 - r: g = 63 - g: b = 63 - b
        CASE "Z", "z": SCREEN 13: GOSUB DrawGrid
        CASE CHR$(27): EXIT DO
    END SELECT
    IF oldSel = sel AND UCASE$(k$) <> "Z" THEN
        SetRGB sel, r, g, b              ' write the edited colour
    ELSE
        GOSUB DrawGrid                   ' move the highlight box
    END IF
LOOP

SCREEN 0: WIDTH 80
PRINT "Palette editor closed."
END

' ---- draw a 16x16 grid of colour swatches, 10x10 pixels each ------------
DrawGrid:
    FOR i = 0 TO 255
        gx = (i MOD 16) * 10 + 4: gy = (i \ 16) * 10 + 20
        LINE (gx, gy)-(gx + 8, gy + 8), i, BF
        LINE (gx - 1, gy - 1)-(gx + 9, gy + 9), 0, B     ' clear old highlight
    NEXT i
    gx = (sel MOD 16) * 10 + 4: gy = (sel \ 16) * 10 + 20
    LINE (gx - 1, gy - 1)-(gx + 9, gy + 9), 15, B        ' highlight box
    COLOR 15
    LOCATE 1, 1: PRINT "VGA DAC PALETTE EDITOR";
RETURN

' ---- information panel on the right ----------------------------------
ShowInfo:
    GetRGB sel, r, g, b
    LINE (180, 20)-(310, 70), sel, BF                    ' big swatch
    LINE (179, 19)-(311, 71), 15, B
    LOCATE 11, 24: PRINT USING "Colour ###"; sel;
    LOCATE 13, 24: PRINT USING "Red    ##"; r;
    LOCATE 14, 24: PRINT USING "Green  ##"; g;
    LOCATE 15, 24: PRINT USING "Blue   ##"; b;
    ' the same value in the 24-bit style used on the web today
    LOCATE 17, 24: PRINT "Web #"; RIGHT$("0" + HEX$(r * 4), 2); RIGHT$("0" + HEX$(g * 4), 2); RIGHT$("0" + HEX$(b * 4), 2);
    LOCATE 20, 24: PRINT "Arrows: pick";
    LOCATE 21, 24: PRINT "R/G/B: + r/g/b: -";
    LOCATE 22, 24: PRINT "I invert Z reset";
    LOCATE 23, 24: PRINT "Esc quit";
RETURN

' Read colour n from the DAC (read-index port &H3C7).
SUB GetRGB (n, r, g, b)
    OUT &H3C7, n
    r = INP(&H3C9): g = INP(&H3C9): b = INP(&H3C9)
END SUB

' Write colour n to the DAC (write-index port &H3C8).
SUB SetRGB (n, r, g, b)
    OUT &H3C8, n
    OUT &H3C9, r: OUT &H3C9, g: OUT &H3C9, b
END SUB
