' TIMESTBL.BAS - Multiplication table with PRINT USING
CLS
COLOR 15: PRINT "     ";
FOR c = 1 TO 12: PRINT USING "####"; c; : NEXT: PRINT
COLOR 8: PRINT "     "; STRING$(48, 196)
FOR r = 1 TO 12
    COLOR 15: PRINT USING "## "; r; : COLOR 8: PRINT CHR$(179); " ";
    FOR c = 1 TO 12
        IF r = c THEN COLOR 14 ELSE COLOR 7
        PRINT USING "####"; r * c;
    NEXT c
    PRINT
NEXT r
COLOR 7
