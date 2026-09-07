' ============================================================
' TITLE:    Sine Wave Scroller
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     sine scroller, demoscene, bit columns, page flipping
' SUMMARY:  Rainbow text glides across the screen riding a rolling sine wave, with a mirror reflection below - a demoscene favourite.
' ------------------------------------------------------------
' WHAT IT DOES
'   First the message is turned into a strip of pixel columns:
'   each 8-pixel-tall column of every letter is stored as one
'   number whose bits say which pixels are lit (we read the
'   font with POINT).  Then, every frame, each column is drawn
'   at its own height:  y = middle + amplitude * SIN(x / width + time)
'   so the text bends into a wave.  As "time" grows, the wave
'   rolls, and as the scroll offset grows, the text slides left.
'   A dimmer, upside-down copy underneath looks like a reflection
'   in water.  Drawing happens on a hidden page (SCREEN 7).
'
' HOW TO USE
'   Up / Down    bigger / smaller wave
'   Left / Right slower / faster scrolling
'   Esc          quit
'
' CONCEPTS YOU WILL LEARN
'   * Sine waves: amplitude (height) and wavelength (width)
'   * Bit columns: testing bit b with  (col AND 2 ^ b)
'   * Scrolling through a long strip with an offset and MOD
'   * Flicker-free drawing with SCREEN 7 pages and PCOPY
'
' THINGS TO TRY
'   * Make each LETTER bob instead of each column
'   * Add a second, smaller scroller going the other way
' ============================================================
DEFINT A-Z

CONST CW = 2                      ' each font column is drawn 2 pixels wide
CONST PH = 3                      ' each font pixel is drawn 3 pixels tall
CONST NCOLS = 160                 ' columns visible (160 * 2 = 320 pixels)

DIM strip(1500)                   ' bit columns of the whole message
DIM bitV(7)                       ' bitV(b) = 2 ^ b, computed once
DIM sinT!(359)                    ' a sine table: SIN is slow, lookups are fast

msg$ = "     HELLO FROM QBASIC!  THIS IS A SINE SCROLLER ...  "
msg$ = msg$ + "GREETINGS TO ALL DEMO CODERS ...  PRESS ESC TO EXIT ...  "

SCREEN 7, , 1, 0                  ' draw on page 1, show page 0
' ---- 1. Build the column strip -------------------------------
n = 0
FOR i = 1 TO LEN(msg$)
    LOCATE 1, 1: PRINT MID$(msg$, i, 1);
    FOR x = 0 TO 7
        v = 0
        FOR y = 0 TO 7
            IF POINT(x, y) <> 0 THEN v = v + 2 ^ y
        NEXT
        strip(n) = v: n = n + 1
    NEXT
NEXT
stripLen = n
FOR b = 0 TO 7: bitV(b) = 2 ^ b: NEXT
FOR a = 0 TO 359: sinT!(a) = SIN(a * 3.14159 / 180): NEXT

' ---- 2. Animate -----------------------------------------------
offs = 0: t = 0: amp = 30: spd = 1
DO
    CLS
    ' Water line and a few "stars".
    LINE (0, 140)-(319, 140), 1
    FOR s = 0 TO 15: PSET ((s * 83 + offs) MOD 320, (s * 37) MOD 60 + 5), 8: NEXT

    FOR c = 0 TO NCOLS - 1
        col = strip((offs + c) MOD stripLen)
        IF col THEN
            x = c * CW
            ' The wave: angle depends on x AND on time t, both in
            ' degrees so we can use the table.
            y0 = 60 + amp * sinT!((c * 2 + t) MOD 360)
            ' (offs + c) \ 8 is the letter number: one color per letter.
            clr = 9 + ((offs + c) \ 8) MOD 6
            FOR b = 0 TO 7
                IF col AND bitV(b) THEN
                    yy = y0 + b * PH
                    LINE (x, yy)-STEP(CW - 1, PH - 1), clr, BF
                    ' Reflection: mirrored around the water line y = 140,
                    ' squashed to half height, in the dim version of
                    ' the color (bright colors 9-14 minus 8 = 1-6).
                    ry = 140 + (140 - yy) \ 2
                    IF ry <= 199 THEN LINE (x, ry)-STEP(CW - 1, 0), clr - 8
                END IF
            NEXT
        END IF
    NEXT
    PCOPY 1, 0
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    offs = (offs + spd) MOD stripLen
    t = (t + 4) MOD 360

    k$ = INKEY$
    SELECT CASE k$
        CASE CHR$(0) + "H": IF amp < 45 THEN amp = amp + 5
        CASE CHR$(0) + "P": IF amp > 0 THEN amp = amp - 5
        CASE CHR$(0) + "K": IF spd > 1 THEN spd = spd - 1
        CASE CHR$(0) + "M": IF spd < 4 THEN spd = spd + 1
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
