' ============================================================
' TITLE:    Longest Common Subsequence
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     dynamic programming, strings, tables, diff
' SUMMARY:  Find the longest sequence of letters two words share in order - the idea behind "diff" and DNA comparison.
' ------------------------------------------------------------
' WHAT IT DOES
'   You type two words or short phrases.  The program builds the LCS
'   table: cell (i, j) holds the LCS length of the first i letters of
'   word A and the first j letters of word B.  It prints the table
'   (for short inputs), traces back to recover one longest common
'   subsequence, and shows both words with the shared letters lit up.
'   Finally it prints a tiny "diff": which letters were deleted (-)
'   from A and which were added (+) to make B.
'
' HOW TO USE
'   Type the first string, then the second (up to 30 characters
'   each).  Press Enter on an empty first string to use an example.
'   Type Q as the first string to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Subsequence (letters in order, gaps allowed) vs substring
'   * The LCS recurrence and filling a 2-D table
'   * Tracing back through the table to recover the answer
'   * O(m * n) time and space instead of 2^m brute force
'   * REDIM for arrays sized at run time
'
' THINGS TO TRY
'   * Compare "AGGTAB" and "GXTXAYB" (answer: GTAB)
'   * Compare two versions of a sentence word-by-word instead of
'     letter-by-letter - that's how real diff tools work
' ============================================================
DEFINT A-Z
COLOR 7, 0: CLS
DO
    COLOR 15: PRINT "LONGEST COMMON SUBSEQUENCE": COLOR 7
    LINE INPUT "String A (Enter = example, Q = quit): "; a$
    IF UCASE$(a$) = "Q" THEN EXIT DO
    IF a$ = "" THEN
        a$ = "ALGORITHM": b$ = "LOGARITHM"
        PRINT "Using A = "; a$; "   B = "; b$
    ELSE
        LINE INPUT "String B: "; b$
    END IF
    a$ = LEFT$(a$, 30): b$ = LEFT$(b$, 30)
    m = LEN(a$): n = LEN(b$)

    ' --------- Build the table ---------------------------------
    ' L(i, j) = length of the LCS of A(1..i) and B(1..j).
    ' Row 0 and column 0 are 0 (an empty string shares nothing).
    '   If A(i) = B(j): that letter can end the common subsequence,
    '      so L(i, j) = L(i-1, j-1) + 1          (diagonal + 1)
    '   Otherwise one of the two letters is not used:
    '      L(i, j) = max( L(i-1, j), L(i, j-1) ) (up or left)
    ' m*n cells, O(1) each -> O(m*n).  Trying every subsequence of A
    ' would be 2^m possibilities - over a billion for 30 letters.
    REDIM L(0 TO m, 0 TO n)
    FOR i = 1 TO m
        FOR j = 1 TO n
            IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN
                L(i, j) = L(i - 1, j - 1) + 1
            ELSEIF L(i - 1, j) >= L(i, j - 1) THEN
                L(i, j) = L(i - 1, j)
            ELSE
                L(i, j) = L(i, j - 1)
            END IF
        NEXT
    NEXT

    ' --------- Print the table if it fits on screen ------------
    IF m <= 14 AND n <= 18 THEN
        PRINT
        PRINT "      ";
        FOR j = 1 TO n: PRINT "  "; MID$(b$, j, 1); : NEXT
        PRINT
        FOR i = 1 TO m
            PRINT "   "; MID$(a$, i, 1); " ";
            FOR j = 1 TO n
                ' a match on the diagonal is shown in yellow
                IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN COLOR 14 ELSE COLOR 7
                PRINT USING "###"; L(i, j);
            NEXT
            COLOR 7: PRINT
        NEXT
    END IF

    ' --------- Trace back --------------------------------------
    ' Start at (m, n) and walk toward (0, 0):
    '   letters equal  -> part of the LCS: record it, go diagonal
    '   else           -> move toward the bigger neighbour (up/left)
    ' We collect letters backwards, so we prepend them.
    ' inA / inB mark which positions belong to the LCS.
    lcs$ = "": inA$ = STRING$(m, "."): inB$ = STRING$(n, ".")
    i = m: j = n
    DO WHILE i > 0 AND j > 0
        IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN
            lcs$ = MID$(a$, i, 1) + lcs$
            MID$(inA$, i, 1) = "*": MID$(inB$, j, 1) = "*"
            i = i - 1: j = j - 1
        ELSEIF L(i - 1, j) >= L(i, j - 1) THEN
            i = i - 1
        ELSE
            j = j - 1
        END IF
    LOOP

    PRINT
    PRINT "LCS length:"; L(m, n); "   one LCS: "; : COLOR 10: PRINT CHR$(34); lcs$; CHR$(34): COLOR 7
    ' show both strings with LCS letters highlighted
    PRINT "A: ";
    FOR i = 1 TO m
        IF MID$(inA$, i, 1) = "*" THEN COLOR 10 ELSE COLOR 8
        PRINT MID$(a$, i, 1);
    NEXT
    COLOR 7: PRINT
    PRINT "B: ";
    FOR j = 1 TO n
        IF MID$(inB$, j, 1) = "*" THEN COLOR 10 ELSE COLOR 8
        PRINT MID$(b$, j, 1);
    NEXT
    COLOR 7: PRINT

    ' --------- A tiny diff -------------------------------------
    ' Walk both strings together: LCS letters are kept, the other
    ' letters of A were deleted (-), the other letters of B added (+).
    PRINT "Diff: ";
    i = 1: j = 1
    DO WHILE i <= m OR j <= n
        IF i <= m THEN
            IF MID$(inA$, i, 1) = "." THEN
                COLOR 12: PRINT "-"; MID$(a$, i, 1); : i = i + 1: GOTO NextDiff
            END IF
        END IF
        IF j <= n THEN
            IF MID$(inB$, j, 1) = "." THEN
                COLOR 11: PRINT "+"; MID$(b$, j, 1); : j = j + 1: GOTO NextDiff
            END IF
        END IF
        ' both point at matching LCS letters: keep it
        COLOR 7: PRINT MID$(a$, i, 1); : i = i + 1: j = j + 1
NextDiff:
    LOOP
    COLOR 7: PRINT : PRINT
LOOP
END
