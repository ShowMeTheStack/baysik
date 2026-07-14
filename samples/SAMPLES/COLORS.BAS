' COLORS.BAS - The 16 text colors and box-drawing characters
SCREEN 0: WIDTH 80: CLS
COLOR 15, 1
LOCATE 2, 20: PRINT CHR$(201); STRING$(38, 205); CHR$(187)
LOCATE 3, 20: PRINT CHR$(186); "      TEXT MODE COLOR CHART         "; CHR$(186)
LOCATE 4, 20: PRINT CHR$(200); STRING$(38, 205); CHR$(188)
COLOR 7, 0
FOR fg = 0 TO 15
    LOCATE 6 + fg, 10
    COLOR 7, 0: PRINT USING "COLOR ## "; fg;
    COLOR fg, 0: PRINT STRING$(10, 219); " ";
    COLOR fg, 7: PRINT " Sample ";
    COLOR fg + 16, 0: PRINT " Blinking ";
NEXT fg
COLOR 7, 0
LOCATE 23, 10: PRINT "Background colors: ";
FOR bg = 0 TO 7: COLOR 15, bg: PRINT bg; : NEXT
COLOR 7, 0: PRINT
