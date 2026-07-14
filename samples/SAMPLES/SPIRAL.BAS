' SPIRAL.BAS - Colorful spirals in 640x480 VGA (SCREEN 12)
SCREEN 12
CONST PI = 3.14159265#
cx = 320: cy = 240
FOR k = 0 TO 5
    a0 = k * PI / 3
    PSET (cx, cy)
    FOR t = 0 TO 12 * PI STEP .05
        r = t * 6
        x = cx + r * COS(t + a0)
        y = cy + r * SIN(t + a0) * .9
        LINE -(x, y), (k MOD 15) + 9
    NEXT t
NEXT k
COLOR 15
LOCATE 29, 2: PRINT "SCREEN 12: 640 x 480, 16 colors.  Press any key.";
SLEEP
