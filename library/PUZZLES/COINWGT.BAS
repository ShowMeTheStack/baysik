' ============================================================
' TITLE:    The 12 Coins Puzzle
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     balance, ternary, logic, information, classic puzzle
' SUMMARY:  One of 12 coins is fake - heavier OR lighter. Three weighings on a balance always find it, and the program shows how.
' ------------------------------------------------------------
' WHAT IT DOES
'   You have 12 coins that look identical.  One is counterfeit: it is
'   either a bit heavier or a bit lighter (you don't know which).
'   With only THREE uses of a balance scale, find the fake coin AND
'   say whether it is heavy or light.
'
'   Why is three enough?  Each weighing has 3 outcomes (left down,
'   right down, balanced), so 3 weighings give 3*3*3 = 27 outcomes.
'   We need to tell apart 12 coins x 2 (heavy/light) = 24 cases.
'   24 <= 27, so it might just be possible - and it is!
'
'   This program uses a clever FIXED plan (decided in advance, not
'   depending on earlier results).  Each coin gets a 3-letter code:
'   L = on the left pan, R = on the right pan, - = not weighed.
'   A heavy coin makes its pans go down; a light one makes them go
'   up.  Every heavy/light coin produces a DIFFERENT pattern.
'
' HOW TO USE
'   1 = You secretly choose a fake coin.  The program tells you what
'       to weigh; you report which side went down.  It names the coin.
'   2 = Watch: the computer hides a fake and solves it on its own.
'   3 = Show the weighing plan and the decoding table.
'   Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Counting outcomes: information and powers of 3
'   * Encoding with signs: +1 / -1 / 0
'   * Matching an observed pattern against a table
'
' THINGS TO TRY
'   * Can you solve 13 coins in 3 weighings?  (Almost - you can find
'     the coin but not always whether it is heavy or light.)
'   * Prove no 2 coins share a pattern by checking the table.
' ============================================================
DECLARE SUB ShowPlan ()
DECLARE FUNCTION Decode% (r1 AS INTEGER, r2 AS INTEGER, r3 AS INTEGER, heavy AS INTEGER)
DECLARE SUB DrawScale (w AS INTEGER, tilt AS INTEGER)
DEFINT A-Z

' code(coin, weighing): +1 = left pan, -1 = right pan, 0 = off.
DIM SHARED code(1 TO 12, 1 TO 3)
FOR c = 1 TO 12
    READ p$
    FOR w = 1 TO 3
        SELECT CASE MID$(p$, w, 1)
            CASE "L": code(c, w) = 1
            CASE "R": code(c, w) = -1
            CASE ELSE: code(c, w) = 0
        END SELECT
    NEXT
NEXT
' Coin:   1      2      3      4      5      6
DATA    "LLL", "LLR", "LL-", "R-L", "R-R", "R--"
' Coin:   7      8      9     10     11     12
DATA    "-RL", "-RR", "-R-", "LRL", "RL-", "--R"

RANDOMIZE TIMER
DIM res(3)
DO
    CLS
    COLOR 14: PRINT "THE 12 COINS PUZZLE": COLOR 7
    PRINT
    PRINT "  1) You hide the fake, I find it"
    PRINT "  2) Watch me find a randomly hidden fake"
    PRINT "  3) Show the weighing plan"
    PRINT "  Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    SELECT CASE a$
        CASE "1", "2"
            IF a$ = "2" THEN
                fake = INT(RND * 12) + 1
                IF RND < .5 THEN sign = 1 ELSE sign = -1   ' 1 heavy, -1 light
            ELSE
                PRINT
                PRINT "  Pick a coin 1-12 and decide heavy or light. Keep it secret!"
                PRINT "  For each weighing type  L  (left side down),  R  (right side"
                PRINT "  down)  or  E  (even).  Press Enter to start."
                LINE INPUT ""; k$
            END IF
            aborted = 0
            FOR w = 1 TO 3
                CLS
                PRINT "  Weighing"; w; "of 3"
                ' Work out who goes on each pan.
                l$ = "": r$ = ""
                FOR c = 1 TO 12
                    IF code(c, w) = 1 THEN l$ = l$ + STR$(c)
                    IF code(c, w) = -1 THEN r$ = r$ + STR$(c)
                NEXT
                PRINT
                PRINT "  Left pan: "; l$; "      Right pan: "; r$
                IF a$ = "2" THEN
                    ' The scale tips by the fake coin's weight difference.
                    tilt = code(fake, w) * sign
                    res(w) = tilt
                    DrawScale w, tilt
                    PRINT : PRINT "  (press a key)"
                    DO: k$ = INKEY$: LOOP WHILE k$ = ""
                ELSE
                    DrawScale w, 0
                    DO
                        LINE INPUT "  Which side went down (L / R / E)? "; k$
                        k$ = UCASE$(LEFT$(LTRIM$(k$), 1))
                        IF k$ = "Q" OR k$ = CHR$(27) THEN aborted = -1: EXIT DO
                    LOOP UNTIL k$ = "L" OR k$ = "R" OR k$ = "E"
                    IF aborted THEN EXIT FOR
                    IF k$ = "L" THEN res(w) = 1 ELSE IF k$ = "R" THEN res(w) = -1 ELSE res(w) = 0
                END IF
            NEXT
            IF NOT aborted THEN
                CLS
                PRINT "  Results: ";
                FOR w = 1 TO 3
                    IF res(w) = 1 THEN PRINT "L "; ELSE IF res(w) = -1 THEN PRINT "R "; ELSE PRINT "E ";
                NEXT
                PRINT
                c = Decode%(res(1), res(2), res(3), heavy)
                PRINT
                IF c = 0 THEN
                    COLOR 12
                    PRINT "  That pattern is impossible - did a coin really differ?"
                    PRINT "  (Or a result was typed wrongly.)"
                ELSE
                    COLOR 10
                    PRINT "  The fake is coin"; c; "and it is ";
                    IF heavy THEN PRINT "HEAVY." ELSE PRINT "LIGHT."
                    COLOR 7
                    PRINT
                    PRINT "  How: coin"; c; "has code ";
                    FOR w = 1 TO 3: PRINT MID$("R-L", code(c, w) + 2, 1); : NEXT
                    PRINT ". The results ";
                    IF heavy THEN PRINT "match it exactly, so it is heavy." ELSE PRINT "are its exact opposite, so it is light."
                    IF a$ = "2" THEN
                        PRINT "  (I had hidden coin"; fake; "- ";
                        IF sign = 1 THEN PRINT "heavy)" ELSE PRINT "light)"
                    END IF
                END IF
                COLOR 7
            END IF
        CASE "3"
            ShowPlan
        CASE ELSE
            PRINT "  Please choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    LINE INPUT "  Press Enter for the menu (Q quits) "; k$
    IF INSTR(UCASE$(k$), "Q") OR INSTR(k$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

FUNCTION Decode% (r1 AS INTEGER, r2 AS INTEGER, r3 AS INTEGER, heavy AS INTEGER)
    ' Find the coin whose code equals the results (heavy) or the
    ' negated results (light).  0 = no match.
    Decode% = 0
    FOR c = 1 TO 12
        IF code(c, 1) = r1 AND code(c, 2) = r2 AND code(c, 3) = r3 THEN
            heavy = -1: Decode% = c: EXIT FUNCTION
        END IF
        IF code(c, 1) = -r1 AND code(c, 2) = -r2 AND code(c, 3) = -r3 THEN
            heavy = 0: Decode% = c: EXIT FUNCTION
        END IF
    NEXT
END FUNCTION

SUB DrawScale (w AS INTEGER, tilt AS INTEGER)
    ' A simple text balance.  tilt = 1: left down, -1: right down.
    PRINT
    SELECT CASE tilt
        CASE 0
            PRINT "         [=====]-------^-------[=====]"
            PRINT "                      /_\"
        CASE 1
            PRINT "                       ____----[=====]"
            PRINT "         [=====]---^^^^    "
            PRINT "                      /_\       left side is DOWN"
        CASE -1
            PRINT "         [=====]----____"
            PRINT "                        ^^^^---[=====]"
            PRINT "                      /_\       right side is DOWN"
    END SELECT
END SUB

SUB ShowPlan
    CLS
    COLOR 14: PRINT "  THE FIXED WEIGHING PLAN": COLOR 7
    FOR w = 1 TO 3
        PRINT "  Weighing"; w; ": ";
        FOR c = 1 TO 12: IF code(c, w) = 1 THEN PRINT c;
        NEXT
        PRINT "  vs ";
        FOR c = 1 TO 12: IF code(c, w) = -1 THEN PRINT c;
        NEXT
        PRINT
    NEXT
    PRINT
    PRINT "  Coin  code   if HEAVY you see   if LIGHT you see"
    FOR c = 1 TO 12
        PRINT USING "   ##   "; c;
        FOR w = 1 TO 3: PRINT MID$("R-L", code(c, w) + 2, 1); : NEXT
        PRINT "        ";
        FOR w = 1 TO 3: PRINT MID$("REL", code(c, w) + 2, 1); : NEXT
        PRINT "                ";
        FOR w = 1 TO 3: PRINT MID$("LER", code(c, w) + 2, 1); : NEXT
        PRINT
    NEXT
    PRINT
    PRINT "  (L = left pan down, R = right pan down, E = even)"
END SUB
