' ============================================================
' TITLE:    Levenshtein Edit Distance
' CATEGORY: Strings & Text Processing
' LEVEL:    Advanced
' TAGS:     dynamic programming, edit distance, 2D arrays, backtracking
' SUMMARY:  Computes how many edits turn one word into another, shows the full DP table and the edit steps.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Levenshtein distance between two strings is the smallest
'   number of single-character edits - insert, delete or substitute
'   - that change one into the other.
'       KITTEN -> SITTING  needs 3 edits:
'         Kitten -> Sitten   (substitute K with S)
'         sittEn -> sittIn   (substitute E with I)
'         sittin -> sittinG  (insert G)
'   Spell checkers, DNA comparison and "did you mean...?" search
'   boxes all use it.
'
'   The program fills in the famous dynamic-programming table, shows
'   it on screen (the answer is in the bottom-right corner), then
'   walks BACK through the table to list the actual edits.
'
' HOW TO USE
'   Enter two words (up to 12 letters so the table fits).
'   Enter an empty first word to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Dynamic programming: build big answers from small ones
'   * 2-D arrays with DIM d(0 TO 12, 0 TO 12)
'   * MIN of three values
'   * Backtracking through a table to recover HOW we got the answer
'
' THINGS TO TRY
'   * Add "transposition" as a 4th edit (Damerau-Levenshtein)
'   * Give substitutions a cost of 2 and see what changes
'   * Use it to rank suggestions in the Spell Checker program
' ============================================================

DECLARE FUNCTION Min3 (a, b, c)

CONST MAXL = 12
DIM d(0 TO MAXL, 0 TO MAXL)
DIM steps$(30)

CLS
COLOR 14: PRINT "LEVENSHTEIN EDIT DISTANCE": COLOR 7
a$ = "KITTEN": b$ = "SITTING"
GOSUB Solve
DO
    PRINT
    LINE INPUT "First word  (Enter = quit): "; a$
    IF a$ = "" THEN EXIT DO
    LINE INPUT "Second word: "; b$
    a$ = UCASE$(LEFT$(a$, MAXL)): b$ = UCASE$(LEFT$(b$, MAXL))
    CLS
    GOSUB Solve
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' Solve: d(i, j) = distance between the first i letters of a$
' and the first j letters of b$.
'   d(i, 0) = i      (delete all i letters)
'   d(0, j) = j      (insert all j letters)
'   d(i, j) = smallest of
'       d(i-1, j)   + 1     delete a$'s i-th letter
'       d(i, j-1)   + 1     insert b$'s j-th letter
'       d(i-1, j-1) + cost  cost = 0 if the letters match, else 1
' ------------------------------------------------------------
Solve:
    m = LEN(a$): n = LEN(b$)
    FOR i = 0 TO m: d(i, 0) = i: NEXT i
    FOR j = 0 TO n: d(0, j) = j: NEXT j
    FOR i = 1 TO m
        FOR j = 1 TO n
            IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN cost = 0 ELSE cost = 1
            d(i, j) = Min3(d(i - 1, j) + 1, d(i, j - 1) + 1, d(i - 1, j - 1) + cost)
        NEXT j
    NEXT i

    ' ---- draw the table: b$ across the top, a$ down the side ----
    PRINT
    PRINT "        ";
    FOR j = 1 TO n: PRINT "  "; MID$(b$, j, 1); : NEXT j
    PRINT
    FOR i = 0 TO m
        IF i = 0 THEN PRINT "    "; ELSE PRINT "  "; MID$(a$, i, 1); " ";
        FOR j = 0 TO n
            IF i = m AND j = n THEN COLOR 14 ELSE IF i = j THEN COLOR 8 ELSE COLOR 7
            PRINT USING "###"; d(i, j);
        NEXT j
        COLOR 7: PRINT
    NEXT i
    PRINT
    PRINT "Distance from "; a$; " to "; b$; " = ";
    COLOR 14: PRINT LTRIM$(STR$(d(m, n))): COLOR 7

    ' ---- backtrack from the corner to (0,0) ----
    ' At each cell, ask which neighbour could have produced it.
    ' We collect the steps in reverse, then print them forwards.
    ns = 0: i = m: j = n
    DO WHILE i > 0 OR j > 0
        same = 0
        IF i > 0 AND j > 0 THEN IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN same = 1
        IF same THEN
            IF d(i, j) = d(i - 1, j - 1) THEN i = i - 1: j = j - 1: GOTO NextStep
        END IF
        ns = ns + 1
        IF i > 0 AND j > 0 THEN
            IF d(i, j) = d(i - 1, j - 1) + 1 THEN
                steps$(ns) = "substitute " + MID$(a$, i, 1) + " with " + MID$(b$, j, 1)
                i = i - 1: j = j - 1: GOTO NextStep
            END IF
        END IF
        IF i > 0 THEN
            IF d(i, j) = d(i - 1, j) + 1 THEN
                steps$(ns) = "delete " + MID$(a$, i, 1)
                i = i - 1: GOTO NextStep
            END IF
        END IF
        steps$(ns) = "insert " + MID$(b$, j, 1)
        j = j - 1
NextStep:
    LOOP
    IF ns = 0 THEN PRINT "The words are identical - no edits needed."
    FOR k = ns TO 1 STEP -1
        PRINT "  "; ns - k + 1; ": "; steps$(k)
    NEXT k
RETURN

FUNCTION Min3 (a, b, c)
    m = a
    IF b < m THEN m = b
    IF c < m THEN m = c
    Min3 = m
END FUNCTION
