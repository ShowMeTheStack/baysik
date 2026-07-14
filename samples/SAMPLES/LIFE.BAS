' LIFE.BAS - Conway's Game of Life in text mode
DEFINT A-Z
CONST W = 78, H = 22
DIM g(0 TO W + 1, 0 TO H + 1), n(0 TO W + 1, 0 TO H + 1)
RANDOMIZE TIMER
FOR y = 1 TO H: FOR x = 1 TO W: g(x, y) = (RND < .3): NEXT: NEXT
CLS
gen = 0
DO
    FOR y = 1 TO H
        LOCATE y + 1, 2
        row$ = ""
        FOR x = 1 TO W
            IF g(x, y) THEN row$ = row$ + CHR$(254) ELSE row$ = row$ + " "
        NEXT
        COLOR 10: PRINT row$;
    NEXT
    gen = gen + 1
    COLOR 15: LOCATE 1, 2: PRINT "Generation"; gen; " (any key to stop)";
    FOR y = 1 TO H: FOR x = 1 TO W
        c = 0
        FOR dy = -1 TO 1: FOR dx = -1 TO 1
            IF dx OR dy THEN IF g(x + dx, y + dy) THEN c = c + 1
        NEXT: NEXT
        n(x, y) = (c = 3) OR (g(x, y) AND c = 2)
    NEXT: NEXT
    FOR y = 1 TO H: FOR x = 1 TO W: g(x, y) = n(x, y): NEXT: NEXT
LOOP WHILE INKEY$ = ""
COLOR 7
