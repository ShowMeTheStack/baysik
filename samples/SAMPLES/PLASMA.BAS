' PLASMA.BAS - Palette rotation: the picture is drawn once, then only colors change
' Concepts: SCREEN 13, OUT to VGA DAC ports, WAIT for vertical retrace, INKEY$
DEFINT A-Z
SCREEN 13
FOR y = 0 TO 199
    FOR x = 0 TO 319
        v! = SIN(x / 16) + SIN(y / 11) + SIN((x + y) / 23) + SIN(SQR((x - 160) ^ 2 + (y - 100) ^ 2) / 9)
        PSET (x, y), 1 + INT((v! + 4) * 31.75) MOD 255
    NEXT
NEXT
LOCATE 25, 2: PRINT "Palette cycling - press any key";
DIM r(255), g(255), b(255)
FOR i = 1 TO 255
    r(i) = INT(31.5 + 31.5 * SIN(i * 6.2832 / 255))
    g(i) = INT(31.5 + 31.5 * SIN(i * 6.2832 / 255 + 2.094))
    b(i) = INT(31.5 + 31.5 * SIN(i * 6.2832 / 255 + 4.188))
NEXT
shift = 0
DO
    WAIT &H3DA, 8
    OUT &H3C8, 1
    FOR i = 1 TO 255
        j = 1 + (i + shift) MOD 255
        OUT &H3C9, r(j): OUT &H3C9, g(j): OUT &H3C9, b(j)
    NEXT
    shift = (shift + 2) MOD 255
LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
