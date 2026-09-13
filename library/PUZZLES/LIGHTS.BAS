' ============================================================
' TITLE:    Lights Out
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     game, xor, linear algebra, gaussian elimination, puzzles
' SUMMARY:  Switch off every light - but each press also flips its neighbours. Includes a hint solver using XOR algebra.
' ------------------------------------------------------------
' WHAT IT DOES
'   A 5x5 board of lights.  Pressing a light toggles it AND the lights
'   directly above, below, left and right of it.  Your goal: turn all
'   the lights off in as few presses as you can.
'
'   The hint (H) uses real maths.  Pressing a button twice does
'   nothing, and the order of presses doesn't matter, so every
'   solution is just a SET of buttons.  Each light gives one equation
'   "the presses that touch me add up to 1 if I'm lit, 0 if not",
'   where 1 + 1 = 0 (that's XOR).  25 equations in 25 unknowns - we
'   solve them with Gaussian elimination, exactly like in algebra
'   class, except we use XOR instead of subtraction.
'
' HOW TO USE
'   Arrow keys move the cursor, Space or Enter presses a light.
'   H = show which lights to press, N = new puzzle, Q / Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * XOR as "toggle"
'   * Building puzzles that are guaranteed to be solvable
'   * Gaussian elimination over GF(2) (arithmetic mod 2)
'   * Reading arrow keys with INKEY$
'
' THINGS TO TRY
'   * The 5x5 board has 4 different "shortest" solutions for each
'     puzzle.  Can you change the solver to find the shortest?
'   * Try "light chasing": press each light under a lit one, row by
'     row, and see what's left in the bottom row.
' ============================================================
DECLARE SUB Press (r AS INTEGER, c AS INTEGER)
DECLARE SUB Draw5 ()
DECLARE SUB FindHint ()
DEFINT A-Z

CONST N = 5
DIM SHARED lit(N - 1, N - 1)     ' -1 = on, 0 = off
DIM SHARED hint(N - 1, N - 1)    ' -1 = press this one
DIM SHARED showHint, curR, curC, moves

RANDOMIZE TIMER
CLS
DO
    ' ---- New puzzle: start dark and make random presses ------------
    ' Because we only ever make legal presses, the puzzle can always
    ' be solved (just press the same buttons again!).
    FOR r = 0 TO N - 1: FOR c = 0 TO N - 1: lit(r, c) = 0: NEXT: NEXT
    DO
        FOR i = 1 TO 10
            Press INT(RND * N), INT(RND * N)
        NEXT
        cnt = 0
        FOR r = 0 TO N - 1: FOR c = 0 TO N - 1: cnt = cnt - lit(r, c): NEXT: NEXT
    LOOP WHILE cnt = 0             ' don't hand out an already-solved board
    moves = 0: showHint = 0: curR = 2: curC = 2
    newGame = 0

    DO
        Draw5
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        u$ = UCASE$(k$)
        SELECT CASE u$
            CASE CHR$(0) + "H": IF curR > 0 THEN curR = curR - 1
            CASE CHR$(0) + "P": IF curR < N - 1 THEN curR = curR + 1
            CASE CHR$(0) + "K": IF curC > 0 THEN curC = curC - 1
            CASE CHR$(0) + "M": IF curC < N - 1 THEN curC = curC + 1
            CASE " ", CHR$(13)
                Press curR, curC: moves = moves + 1
            CASE "H"
                showHint = NOT showHint
            CASE "N"
                newGame = -1
            CASE "Q", CHR$(27)
                CLS : END
        END SELECT
        IF showHint THEN FindHint

        ' All dark?
        cnt = 0
        FOR r = 0 TO N - 1: FOR c = 0 TO N - 1: cnt = cnt - lit(r, c): NEXT: NEXT
        IF cnt = 0 THEN
            Draw5
            LOCATE 24, 5: COLOR 10: PRINT "All lights out in"; moves; "presses!  Press a key for a new one.": COLOR 7
            DO: k$ = INKEY$: LOOP WHILE k$ = ""
            IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN CLS : END
            newGame = -1
        END IF
    LOOP UNTIL newGame
LOOP

SUB Draw5
    ' Each light is a 7x3 block of colour.  A * in the middle marks a
    ' hint, and the cursor is shown as [ ].
    LOCATE 1, 5: COLOR 14: PRINT "L I G H T S   O U T": COLOR 7
    FOR r = 0 TO N - 1
        FOR c = 0 TO N - 1
            ' Lit = amber (colour 6), dark = blue (colour 1).  The cursor
            ' square gets bright red brackets around its letter.
            IF lit(r, c) THEN bg = 6 ELSE bg = 1
            IF r = curR AND c = curC THEN fg = 12 ELSE fg = 15
            COLOR 15, bg
            FOR y = 0 TO 2
                LOCATE 3 + r * 4 + y, 5 + c * 8: PRINT SPACE$(7);
            NEXT
            LOCATE 4 + r * 4, 7 + c * 8
            COLOR fg, bg
            mark$ = " "
            IF showHint AND hint(r, c) THEN mark$ = "*"
            IF r = curR AND c = curC THEN PRINT "["; mark$; "]"; ELSE PRINT " "; mark$; " ";
            COLOR 7, 0
        NEXT
    NEXT
    LOCATE 23, 5: PRINT "Presses:"; moves; "   ";
    IF showHint THEN PRINT "Hint: press the lights marked *     " ELSE PRINT SPACE$(40)
    LOCATE 25, 5: PRINT "Arrows move, Space/Enter = press   H = hint   N = new   Q = quit";
END SUB

SUB FindHint
    ' Solve  M * x = b  over GF(2).  Row i = light i, column j = button
    ' j.  M(i, j) = 1 if pressing button j toggles light i.  Column 25
    ' holds b (1 if light i is currently on).
    DIM m(24, 25)
    FOR i = 0 TO 24
        ri = i \ N: ci = i MOD N
        FOR j = 0 TO 24
            rj = j \ N: cj = j MOD N
            IF ABS(ri - rj) + ABS(ci - cj) <= 1 THEN m(i, j) = 1
        NEXT
        m(i, 25) = -lit(ri, ci)
    NEXT
    ' Forward elimination: for each column find a row with a 1 in it,
    ' swap it up, then XOR it into every other row that has a 1 there.
    DIM pivotCol(24)
    row = 0
    FOR col = 0 TO 24
        p = -1
        FOR i = row TO 24
            IF m(i, col) THEN p = i: EXIT FOR
        NEXT
        IF p >= 0 THEN
            FOR j = 0 TO 25: SWAP m(p, j), m(row, j): NEXT
            FOR i = 0 TO 24
                IF i <> row AND m(i, col) THEN
                    FOR j = col TO 25: m(i, j) = m(i, j) XOR m(row, j): NEXT
                END IF
            NEXT
            pivotCol(row) = col
            row = row + 1
        END IF
    NEXT
    ' The matrix is now "reduced": each pivot row says x(pivotCol) = b
    ' (free buttons are simply left unpressed).
    FOR r = 0 TO N - 1: FOR c = 0 TO N - 1: hint(r, c) = 0: NEXT: NEXT
    FOR i = 0 TO row - 1
        IF m(i, 25) THEN
            j = pivotCol(i)
            hint(j \ N, j MOD N) = -1
        END IF
    NEXT
END SUB

SUB Press (r AS INTEGER, c AS INTEGER)
    ' Toggle (r, c) and its four neighbours - NOT means toggle.
    lit(r, c) = NOT lit(r, c)
    IF r > 0 THEN lit(r - 1, c) = NOT lit(r - 1, c)
    IF r < N - 1 THEN lit(r + 1, c) = NOT lit(r + 1, c)
    IF c > 0 THEN lit(r, c - 1) = NOT lit(r, c - 1)
    IF c < N - 1 THEN lit(r, c + 1) = NOT lit(r, c + 1)
END SUB
