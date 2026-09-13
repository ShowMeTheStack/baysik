' ============================================================
' TITLE:    24 Game Solver
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     arithmetic, recursion, fractions, search, card game
' SUMMARY:  Give it four numbers and it finds every way to make 24 with + - x / and brackets, using exact fractions.
' ------------------------------------------------------------
' WHAT IT DOES
'   The 24 Game: deal four cards (1-13) and combine ALL four numbers
'   with + - * / and brackets to make exactly 24.  Each number is used
'   once.  Example: 4 7 8 8  ->  (7 - 8 / 8) * 4 = 24
'
'   The solver's idea is simple and powerful:
'     pick any TWO numbers, replace them with their sum, difference,
'     product or quotient - now you have three numbers.  Repeat until
'     one number is left.  Is it 24?
'   Each number also carries the text of the expression that made it,
'   so we can print the answer.
'
'   Some answers need fractions!  3 3 8 8 -> 8 / (3 - 8 / 3) = 24.
'   Decimals would give 23.99999, so we store every value as an exact
'   fraction (numerator / denominator) instead.
'
' HOW TO USE
'   1 = deal a random hand and solve it, 2 = type four numbers,
'   3 = list the impossible hands made of 1-6, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Recursive search over combinations
'   * Fraction arithmetic and reducing with the GCD
'   * Building expression strings as you go
'   * Removing duplicates with a simple list lookup
'
' THINGS TO TRY
'   * Change TARGET to 10 or 36.
'   * Allow 5 numbers (just make the arrays bigger).
'   * Which hands of 1-9 have no solution at all?
' ============================================================
DECLARE SUB Search (cnt AS INTEGER)
DECLARE FUNCTION Gcd& (a&, b&)
DECLARE SUB SolveHand (show AS INTEGER)
DEFINT A-Z

CONST TARGET = 24
CONST MAXSHOW = 40
' Values at each depth: there are cnt numbers left at depth 4-cnt.
DIM SHARED nu&(4, 4), de&(4, 4), ex$(4, 4)
DIM SHARED found$(MAXSHOW), nFound
DIM SHARED hand(4)
DIM SHARED stopFirst          ' -1 = quit searching after one answer

RANDOMIZE TIMER
DO
    CLS
    COLOR 14: PRINT "THE 24 GAME SOLVER": COLOR 7
    PRINT
    PRINT "  1) Deal a random hand"
    PRINT "  2) Type in four numbers"
    PRINT "  3) Search for hands with exactly ONE solution"
    PRINT "  Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    SELECT CASE a$
        CASE "1"
            FOR i = 1 TO 4: hand(i) = INT(RND * 13) + 1: NEXT
            SolveHand -1
        CASE "2"
            PRINT "  Type four whole numbers 1-99 separated by spaces."
            LINE INPUT "  Numbers: "; t$
            t$ = t$ + " ": got = 0
            DO WHILE LEN(t$) > 0 AND got < 5
                sp = INSTR(t$, " ")
                w$ = LEFT$(t$, sp - 1): t$ = MID$(t$, sp + 1)
                IF w$ <> "" THEN
                    got = got + 1
                    IF got <= 4 THEN hand(got) = VAL(w$)
                END IF
            LOOP
            ok = (got = 4)
            FOR i = 1 TO 4
                IF hand(i) < 1 OR hand(i) > 99 THEN ok = 0
            NEXT
            IF ok THEN SolveHand -1 ELSE PRINT "  I need exactly four numbers from 1 to 99."
        CASE "3"
            ' Try every hand a <= b <= c <= d using the numbers 1..6.
            ' We only need to know IF a hand can be solved, so the
            ' search stops at the first answer (stopFirst).
            PRINT
            PRINT "  Hands of numbers 1-6 that can NOT make 24 (Esc stops):"
            PRINT "  ";
            stopFirst = -1: bad = 0: total = 0
            FOR a = 1 TO 6: FOR b = a TO 6: FOR c = b TO 6: FOR d = c TO 6
                hand(1) = a: hand(2) = b: hand(3) = c: hand(4) = d
                SolveHand 0
                total = total + 1
                IF nFound = 0 THEN
                    bad = bad + 1
                    PRINT USING "#### "; a * 1000 + b * 100 + c * 10 + d;
                    IF POS(0) > 70 THEN PRINT : PRINT "  ";
                END IF
                IF INKEY$ = CHR$(27) THEN GOTO doneHunt
            NEXT: NEXT: NEXT: NEXT
doneHunt:
            stopFirst = 0
            PRINT : PRINT
            PRINT "  "; bad; "of"; total; "hands checked are impossible."
        CASE ELSE
            PRINT "  Please choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    LINE INPUT "  Press Enter for the menu (Q quits) "; k$
    IF INSTR(UCASE$(k$), "Q") OR INSTR(k$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

FUNCTION Gcd& (a&, b&)
    x& = ABS(a&): y& = ABS(b&)
    DO WHILE y& <> 0
        r& = x& MOD y&: x& = y&: y& = r&
    LOOP
    IF x& = 0 THEN x& = 1
    Gcd& = x&
END FUNCTION

SUB Search (cnt AS INTEGER)
    ' cnt numbers are left, stored at depth L = 4 - cnt.
    L = 4 - cnt
    IF stopFirst AND nFound > 0 THEN EXIT SUB
    IF cnt = 1 THEN
        ' One number left: is it exactly TARGET/1 ?
        IF nu&(L, 1) = TARGET * de&(L, 1) THEN
            ' Strip the outer brackets and skip duplicates.
            e$ = ex$(L, 1)
            IF LEFT$(e$, 1) = "(" THEN e$ = MID$(e$, 2, LEN(e$) - 2)
            FOR i = 1 TO nFound
                IF found$(i) = e$ THEN EXIT SUB
            NEXT
            IF nFound < MAXSHOW THEN nFound = nFound + 1: found$(nFound) = e$
        END IF
        EXIT SUB
    END IF
    ' Choose a pair (i, j) and an operation.
    FOR i = 1 TO cnt - 1
        FOR j = i + 1 TO cnt
            ' Copy all OTHER numbers to the next depth first.
            m = 0
            FOR q = 1 TO cnt
                IF q <> i AND q <> j THEN
                    m = m + 1
                    nu&(L + 1, m) = nu&(L, q): de&(L + 1, m) = de&(L, q): ex$(L + 1, m) = ex$(L, q)
                END IF
            NEXT
            m = m + 1                    ' slot for the combined number
            an& = nu&(L, i): ad& = de&(L, i): a$ = ex$(L, i)
            bn& = nu&(L, j): bd& = de&(L, j): b$ = ex$(L, j)
            FOR op = 1 TO 6
                ok = -1
                SELECT CASE op
                    CASE 1   ' a + b      (a/b + c/d = (ad + cb) / bd)
                        rn& = an& * bd& + bn& * ad&: rd& = ad& * bd&: e$ = "(" + a$ + " + " + b$ + ")"
                    CASE 2   ' a * b
                        rn& = an& * bn&: rd& = ad& * bd&: e$ = "(" + a$ + " * " + b$ + ")"
                    CASE 3   ' a - b
                        rn& = an& * bd& - bn& * ad&: rd& = ad& * bd&: e$ = "(" + a$ + " - " + b$ + ")"
                    CASE 4   ' b - a
                        rn& = bn& * ad& - an& * bd&: rd& = ad& * bd&: e$ = "(" + b$ + " - " + a$ + ")"
                    CASE 5   ' a / b  (dividing = multiplying by the flipped fraction)
                        IF bn& = 0 THEN ok = 0 ELSE rn& = an& * bd&: rd& = ad& * bn&: e$ = "(" + a$ + " / " + b$ + ")"
                    CASE 6   ' b / a
                        IF an& = 0 THEN ok = 0 ELSE rn& = bn& * ad&: rd& = bd& * an&: e$ = "(" + b$ + " / " + a$ + ")"
                END SELECT
                IF ok THEN
                    ' Keep the fraction in lowest terms, denominator > 0.
                    IF rd& < 0 THEN rn& = -rn&: rd& = -rd&
                    g& = Gcd&(rn&, rd&)
                    nu&(L + 1, m) = rn& \ g&: de&(L + 1, m) = rd& \ g&: ex$(L + 1, m) = e$
                    Search cnt - 1
                END IF
            NEXT
        NEXT
    NEXT
END SUB

SUB SolveHand (show AS INTEGER)
    nFound = 0
    FOR i = 1 TO 4
        nu&(0, i) = hand(i): de&(0, i) = 1: ex$(0, i) = LTRIM$(STR$(hand(i)))
    NEXT
    Search 4
    IF NOT show THEN EXIT SUB
    PRINT
    PRINT "  Hand:"; hand(1); hand(2); hand(3); hand(4)
    PRINT
    IF nFound = 0 THEN
        COLOR 12: PRINT "  No way to make"; TARGET; "- this hand is impossible.": COLOR 7
    ELSE
        COLOR 10
        PRINT "  Found"; nFound; "expression(s)";
        IF nFound = MAXSHOW THEN PRINT " (showing the first"; MAXSHOW; ")";
        PRINT ":": COLOR 7
        FOR i = 1 TO nFound
            ' Two columns so more fit on screen.
            IF i MOD 2 = 1 THEN PRINT "  "; LEFT$(found$(i) + SPACE$(36), 36); ELSE PRINT found$(i)
            IF i >= 30 THEN EXIT FOR
        NEXT
        PRINT
    END IF
END SUB
