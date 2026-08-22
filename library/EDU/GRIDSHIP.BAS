' ============================================================
' TITLE:    Coordinate Battleships
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     coordinates, graphs, x and y, 2D arrays, game
' SUMMARY:  Find hidden ships by calling out (x, y) coordinates on a maths-style grid.
' ------------------------------------------------------------
' WHAT IT DOES
'   Three ships hide on a 10 x 10 grid numbered 0 to 9 like a graph in
'   maths class: x goes ACROSS, y goes UP, and (0,0) is the bottom-left
'   corner.  You type coordinates such as 3,7 to fire.  The grid shows
'   splashes (o) for misses and explosions (X) for hits.  Every few
'   misses you get a hint telling you which direction to look.  Sink
'   every ship within 35 shots to win.
'
' HOW TO USE
'   Type x,y and press Enter (for example 4,2).  Remember: "along the
'   corridor, then up the stairs" - x first, then y.  Type Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Ordered pairs (x, y) and the coordinate plane
'   * A 2D array: grid(x, y)
'   * Converting grid coordinates to screen rows (y is flipped!)
'   * Placing ships randomly without overlapping
'
' THINGS TO TRY
'   * Use a grid from -5 to 5 so you practise negative numbers
'   * Add a fourth, longer ship
'   * Let a friend place the ships by typing coordinates
' ============================================================

DECLARE SUB DrawGrid (showShips!)
RANDOMIZE TIMER
' grid(x, y): 0 = water, 1..3 = ship number, add 10 when shot at
DIM SHARED grid(0 TO 9, 0 TO 9)
DIM shipLen(1 TO 3), shipLeft(1 TO 3)
shipLen(1) = 2: shipLen(2) = 3: shipLen(3) = 4

' ---- place the ships ----
FOR s = 1 TO 3
    DO
        horiz = INT(RND * 2)                   ' 1 = across, 0 = up
        x0 = INT(RND * 10): y0 = INT(RND * 10)
        ok = -1
        FOR i = 0 TO shipLen(s) - 1
            x = x0 + i * horiz: y = y0 + i * (1 - horiz)
            IF x > 9 OR y > 9 THEN
                ok = 0                         ' falls off the grid
            ELSEIF grid(x, y) <> 0 THEN
                ok = 0                         ' bumps another ship
            END IF
        NEXT i
    LOOP UNTIL ok
    FOR i = 0 TO shipLen(s) - 1
        grid(x0 + i * horiz, y0 + i * (1 - horiz)) = s
    NEXT i
    shipLeft(s) = shipLen(s)
NEXT s

shots = 0: misses = 0: sunk = 0
msg$ = "Fire away, captain!  Type x,y"
CLS
DO
    DrawGrid 0
    COLOR 14: LOCATE 2, 50: PRINT "COORDINATE BATTLESHIPS"
    COLOR 7: LOCATE 4, 50: PRINT "Shots used:"; shots; "of 35"
    LOCATE 5, 50: PRINT "Ships sunk:"; sunk; "of 3"
    LOCATE 7, 50: COLOR 11: PRINT "x = across  (0-9)"
    LOCATE 8, 50: PRINT "y = up      (0-9)"
    LOCATE 10, 50: COLOR 7: PRINT "o = miss   X = hit"
    LOCATE 20, 3: COLOR 15: PRINT LEFT$(msg$ + SPACE$(70), 70)
    IF sunk = 3 OR shots >= 35 THEN EXIT DO

    LOCATE 22, 3: PRINT SPACE$(60);
    LOCATE 22, 3: LINE INPUT "Coordinates x,y: "; a$
    a$ = UCASE$(LTRIM$(RTRIM$(a$)))
    IF a$ = "Q" THEN EXIT DO
    ' Accept "3,7" or "(3,7)" or "3 7"
    IF LEFT$(a$, 1) = "(" THEN a$ = MID$(a$, 2)
    c = INSTR(a$, ","): IF c = 0 THEN c = INSTR(a$, " ")
    IF c = 0 THEN
        msg$ = "Please use a comma, like 4,2  (x first, then y)"
    ELSE
        x = VAL(LEFT$(a$, c - 1)): y = VAL(MID$(a$, c + 1))
        IF x < 0 OR x > 9 OR y < 0 OR y > 9 OR x <> INT(x) OR y <> INT(y) THEN
            msg$ = "Both numbers must be whole numbers from 0 to 9."
        ELSEIF grid(x, y) >= 10 THEN
            msg$ = "You already fired at (" + LTRIM$(STR$(x)) + "," + LTRIM$(STR$(y)) + ")."
        ELSE
            shots = shots + 1
            s = grid(x, y)
            grid(x, y) = s + 10            ' mark the square as shot
            IF s > 0 THEN
                shipLeft(s) = shipLeft(s) - 1
                SOUND 100, 3: SOUND 60, 3
                IF shipLeft(s) = 0 THEN
                    sunk = sunk + 1
                    msg$ = "BOOM! You SANK a ship of length" + STR$(shipLen(s)) + "!"
                ELSE
                    msg$ = "HIT at (" + LTRIM$(STR$(x)) + "," + LTRIM$(STR$(y)) + ")! Try the squares next to it."
                END IF
            ELSE
                misses = misses + 1
                msg$ = "Splash - a miss at (" + LTRIM$(STR$(x)) + "," + LTRIM$(STR$(y)) + ")."
                ' Every 3rd miss: find the nearest unhit ship square and
                ' say which way it is.  Compare x for left/right and y
                ' for up/down - that's what coordinates are for!
                IF misses MOD 3 = 0 THEN
                    best = 999
                    FOR i = 0 TO 9: FOR j = 0 TO 9
                        IF grid(i, j) > 0 AND grid(i, j) < 10 THEN
                            d = ABS(i - x) + ABS(j - y)
                            IF d < best THEN best = d: bx = i: by = j
                        END IF
                    NEXT j: NEXT i
                    h$ = " Hint: look"
                    IF bx > x THEN h$ = h$ + " RIGHT (bigger x)"
                    IF bx < x THEN h$ = h$ + " LEFT (smaller x)"
                    IF by > y THEN h$ = h$ + " UP (bigger y)"
                    IF by < y THEN h$ = h$ + " DOWN (smaller y)"
                    msg$ = msg$ + h$
                END IF
            END IF
        END IF
    END IF
LOOP

DrawGrid 1                                  ' reveal everything
LOCATE 22, 3: PRINT SPACE$(70);
LOCATE 22, 3: COLOR 14
IF sunk = 3 THEN
    PRINT "VICTORY! All ships found in"; shots; "shots. Great map reading!"
    PLAY "T160 O4 C8 C8 G8 G8 A8 A8 G4"
ELSE
    PRINT "Game over - the hidden ships are shown as #. Try again!"
END IF
COLOR 7: LOCATE 24, 3: PRINT "Press a key...";
DO: LOOP WHILE INKEY$ = ""
CLS
END

' ------------------------------------------------------------
' DrawGrid: in maths, y grows UPWARD, but screen rows grow
' DOWNWARD.  So we flip it: y = 9 goes on row 3 (near the top) and
' y = 0 on row 12, using  row = 3 + (9 - y).  Each x gets 4 columns.
' ------------------------------------------------------------
SUB DrawGrid (showShips)
    FOR y = 9 TO 0 STEP -1
        row = 3 + (9 - y)
        COLOR 14: LOCATE row, 2: PRINT USING "#"; y;
        COLOR 8: PRINT " |";
        FOR x = 0 TO 9
            g = grid(x, y)
            IF g >= 11 THEN
                COLOR 12: PRINT " X  ";
            ELSEIF g = 10 THEN
                COLOR 9: PRINT " o  ";
            ELSEIF g > 0 AND showShips THEN
                COLOR 13: PRINT " #  ";
            ELSE
                COLOR 3: PRINT " .  ";
            END IF
        NEXT x
    NEXT y
    COLOR 8: LOCATE 13, 4: PRINT "+"; STRING$(40, "-")
    COLOR 14: LOCATE 14, 5
    FOR x = 0 TO 9: PRINT USING " #  "; x;: NEXT x
    COLOR 7: LOCATE 15, 20: PRINT "x -->";
    LOCATE 2, 2: PRINT "y ^";
END SUB
