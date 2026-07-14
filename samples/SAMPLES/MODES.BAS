' MODES.BAS - A tour of every screen mode. Press a key to advance.
DECLARE SUB Demo (m%, w%, h%, colors%, txt$)
Demo 1, 320, 200, 4, "CGA 4-color"
Demo 2, 640, 200, 2, "CGA hi-res mono"
Demo 3, 720, 348, 2, "Hercules mono"
Demo 7, 320, 200, 16, "EGA 16-color"
Demo 8, 640, 200, 16, "EGA 16-color"
Demo 9, 640, 350, 16, "EGA 16 of 64"
Demo 10, 640, 350, 4, "EGA monochrome"
Demo 11, 640, 480, 2, "VGA mono"
Demo 12, 640, 480, 16, "VGA 16-color"
Demo 13, 320, 200, 256, "VGA 256-color"
SCREEN 0: WIDTH 80: PRINT "That's all the modes!"

SUB Demo (m%, w%, h%, colors%, txt$)
    SCREEN m%
    n% = colors%: IF n% > 16 THEN n% = 16
    bw% = w% \ n%
    FOR c% = 0 TO n% - 1
        LINE (c% * bw%, h% \ 2)-((c% + 1) * bw% - 1, h% - 1), c%, BF
    NEXT
    IF colors% > 16 THEN FOR c% = 16 TO 255: LINE (c% - 16 + 32, h% \ 2 - 30)-(c% - 16 + 32, h% \ 2 - 5), c%: NEXT
    CIRCLE (w% \ 2, h% \ 4), h% \ 6, colors% - 1
    LINE (0, 0)-(w% - 1, h% - 1), colors% - 1, B
    LOCATE 2, 2: PRINT "SCREEN"; m%; "-"; w%; "x"; h%
    LOCATE 3, 2: PRINT txt$
    SLEEP
END SUB
