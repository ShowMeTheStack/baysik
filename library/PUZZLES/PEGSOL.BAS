' ============================================================
' TITLE:    Peg Solitaire
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     game, board, undo, stack, arrays
' SUMMARY:  The classic English cross-shaped board: jump pegs to remove them and try to finish with one peg in the centre.
' ------------------------------------------------------------
' WHAT IT DOES
'   33 holes in a cross shape, all filled with pegs except the centre.
'   A move: pick a peg, jump it over a neighbouring peg (up, down,
'   left or right) into an empty hole.  The peg you jumped over is
'   removed.  Diagonal jumps are not allowed.
'   Perfect game: one single peg left, sitting in the centre!
'   The program checks every move, keeps a history so you can undo,
'   and tells you when no more moves are possible.
'
' HOW TO USE
'   Arrow keys move the cursor.  Space picks up the peg under the
'   cursor; then press an arrow key to jump in that direction.
'   (Space again drops it.)  U = undo, R = restart, Q / Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Storing an irregular board in a rectangular array with a mask
'   * Validating moves (in bounds, peg present, hole empty)
'   * An undo STACK that remembers every move
'   * Counting available moves to detect "game over"
'
' THINGS TO TRY
'   * Change the starting hole (e.g. a corner) - is it still possible
'     to end with one peg?
'   * Add the French 37-hole board by changing the mask.
'   * Write a solver using depth-first search (warning: it needs to be
'     clever - there are a LOT of positions).
' ============================================================
DECLARE SUB DrawBoard ()
DECLARE FUNCTION Valid% (r AS INTEGER, c AS INTEGER)
DECLARE FUNCTION CanJump% (r AS INTEGER, c AS INTEGER, d AS INTEGER)
DECLARE FUNCTION MovesLeft% ()
DEFINT A-Z

DIM SHARED b(6, 6)          ' 1 = peg, 0 = empty hole
DIM SHARED curR, curC, held  ' cursor and "is a peg picked up?"
DIM SHARED dr(3), dc(3)
dr(0) = -1: dr(1) = 1: dc(2) = -1: dc(3) = 1     ' up, down, left, right
DIM SHARED hR(40), hC(40), hD(40), nHist  ' undo history
DIM SHARED msg$

restart:
FOR r = 0 TO 6: FOR c = 0 TO 6
    b(r, c) = -Valid%(r, c)          ' a peg in every real hole...
NEXT: NEXT
b(3, 3) = 0                          ' ...except the centre
curR = 3: curC = 3: held = 0: nHist = 0
msg$ = "Pick a peg with Space, then jump with an arrow key."
CLS
DO
    DrawBoard
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    d = -1
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": d = 0
        CASE CHR$(0) + "P": d = 1
        CASE CHR$(0) + "K": d = 2
        CASE CHR$(0) + "M": d = 3
        CASE " "
            IF held THEN
                held = 0: msg$ = "Dropped."
            ELSEIF b(curR, curC) THEN
                held = -1: msg$ = "Now press an arrow to jump."
            ELSE
                msg$ = "There's no peg there."
            END IF
        CASE "U"
            IF nHist > 0 THEN
                ' Undo: put back the jumped peg and move ours back.
                r = hR(nHist): c = hC(nHist): dd = hD(nHist)
                b(r, c) = 1
                b(r + dr(dd), c + dc(dd)) = 1
                b(r + 2 * dr(dd), c + 2 * dc(dd)) = 0
                curR = r: curC = c: held = 0
                nHist = nHist - 1
                msg$ = "Move undone."
            END IF
        CASE "R": GOTO restart
        CASE "Q", CHR$(27): EXIT DO
    END SELECT

    IF d >= 0 THEN
        IF held THEN
            IF CanJump%(curR, curC, d) THEN
                ' Make the jump and remember it for undo.
                nHist = nHist + 1
                hR(nHist) = curR: hC(nHist) = curC: hD(nHist) = d
                b(curR, curC) = 0
                b(curR + dr(d), curC + dc(d)) = 0
                curR = curR + 2 * dr(d): curC = curC + 2 * dc(d)
                b(curR, curC) = 1
                held = 0
                msg$ = "Nice jump!"
            ELSE
                msg$ = "Can't jump that way."
                held = 0
            END IF
        ELSE
            ' Just move the cursor, skipping over the cut-off corners.
            nr = curR + dr(d): nc = curC + dc(d)
            DO WHILE nr >= 0 AND nr <= 6 AND nc >= 0 AND nc <= 6
                IF Valid%(nr, nc) THEN curR = nr: curC = nc: EXIT DO
                nr = nr + dr(d): nc = nc + dc(d)
            LOOP
        END IF
    END IF

    IF MovesLeft% = 0 THEN
        pegs = 32 - nHist        ' every jump removes exactly one peg
        DrawBoard
        LOCATE 20, 5: COLOR 14
        IF pegs = 1 AND b(3, 3) = 1 THEN
            PRINT "PERFECT!  One peg, right in the centre. Genius!"
        ELSEIF pegs = 1 THEN
            PRINT "One peg left - excellent! (Centre would be perfect.)"
        ELSEIF pegs <= 3 THEN
            PRINT "No moves left with"; pegs; "pegs - very good!"
        ELSE
            PRINT "No moves left with"; pegs; "pegs. Try again!"
        END IF
        COLOR 7
        LOCATE 21, 5: PRINT "U = undo, R = restart, Q = quit"
        DO
            k$ = UCASE$(INKEY$)
        LOOP UNTIL k$ = "U" OR k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
        IF k$ = "R" THEN GOTO restart
        IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
        ' Undo the last move so play can continue.
        r = hR(nHist): c = hC(nHist): dd = hD(nHist)
        b(r, c) = 1: b(r + dr(dd), c + dc(dd)) = 1
        b(r + 2 * dr(dd), c + 2 * dc(dd)) = 0
        nHist = nHist - 1: msg$ = "Move undone."
        LOCATE 20, 1: PRINT SPACE$(79): PRINT SPACE$(79)
    END IF
LOOP
CLS
END

FUNCTION CanJump% (r AS INTEGER, c AS INTEGER, d AS INTEGER)
    ' Legal if: peg at (r,c), peg next to it, empty hole after that.
    CanJump% = 0
    mr = r + dr(d): mc = c + dc(d)
    tr = r + 2 * dr(d): tc = c + 2 * dc(d)
    IF NOT Valid%(tr, tc) THEN EXIT FUNCTION
    IF b(r, c) = 1 AND b(mr, mc) = 1 AND b(tr, tc) = 0 THEN CanJump% = -1
END FUNCTION

SUB DrawBoard
    LOCATE 2, 5: COLOR 14: PRINT "P E G   S O L I T A I R E": COLOR 7
    FOR r = 0 TO 6
        FOR c = 0 TO 6
            LOCATE 5 + r * 2, 10 + c * 5
            IF Valid%(r, c) THEN
                IF r = curR AND c = curC THEN
                    IF held THEN COLOR 12 ELSE COLOR 14
                    PRINT "[";
                ELSE
                    PRINT " ";
                END IF
                IF b(r, c) THEN COLOR 11: PRINT "O"; ELSE COLOR 8: PRINT CHR$(250);
                IF r = curR AND c = curC THEN
                    IF held THEN COLOR 12 ELSE COLOR 14
                    PRINT "]";
                ELSE
                    PRINT " ";
                END IF
                COLOR 7
            END IF
        NEXT
    NEXT
    LOCATE 5, 50: PRINT "Pegs left:"; 32 - nHist; " "
    LOCATE 6, 50: PRINT "Moves possible:"; MovesLeft%; " "
    LOCATE 8, 50: PRINT "Space = pick up"
    LOCATE 9, 50: PRINT "Arrows = move / jump"
    LOCATE 10, 50: PRINT "U = undo  R = restart"
    LOCATE 11, 50: PRINT "Q = quit"
    LOCATE 23, 5: PRINT LEFT$(msg$ + SPACE$(60), 60)
END SUB

FUNCTION MovesLeft%
    ' Count every legal jump on the board.
    cnt = 0
    FOR r = 0 TO 6
        FOR c = 0 TO 6
            IF b(r, c) = 1 THEN
                FOR d = 0 TO 3
                    IF CanJump%(r, c, d) THEN cnt = cnt + 1
                NEXT
            END IF
        NEXT
    NEXT
    MovesLeft% = cnt
END FUNCTION

FUNCTION Valid% (r AS INTEGER, c AS INTEGER)
    ' The cross: inside the 7x7 square but not in a 2x2 corner.
    IF r < 0 OR r > 6 OR c < 0 OR c > 6 THEN Valid% = 0: EXIT FUNCTION
    Valid% = ((r >= 2 AND r <= 4) OR (c >= 2 AND c <= 4))
END FUNCTION
