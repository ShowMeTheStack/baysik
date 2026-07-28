' ============================================================
' TITLE:    Permutations, Combinations and Subsets
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     combinatorics, recursion, backtracking, bitmasks
' SUMMARY:  Generate every arrangement, every choice of k items, and every subset - three ways to enumerate possibilities.
' ------------------------------------------------------------
' WHAT IT DOES
'   1. PERMUTATIONS: lists every ordering of the letters you type,
'      in dictionary order, using the "next permutation" algorithm
'      (the same one C++ uses).  Repeated letters are handled, so
'      "AAB" gives only 3 results, not 6.
'   2. COMBINATIONS: lists every way to choose k of n items with a
'      recursive backtracking procedure.
'   3. SUBSETS: counts from 0 to 2^n - 1 in binary; each bit says
'      whether an item is in or out.
'   Each list ends with the count and the formula that predicts it.
'
' HOW TO USE
'   Choose 1, 2 or 3 from the menu and answer the questions.
'   Q quits.  Long lists pause after each screenful (Esc stops).
'
' CONCEPTS YOU WILL LEARN
'   * n! permutations, C(n,k) = n! / (k! (n-k)!) combinations, 2^n subsets
'   * Lexicographic "next permutation" step by step
'   * Recursion with a "choose / explore / un-choose" pattern
'   * Bitmasks: testing bit b with  (mask AND 2^b)
'
' THINGS TO TRY
'   * Use permutations to solve SEND + MORE = MONEY by brute force
'   * Print combinations of 3 from 7 and check C(7,3) = 35
' ============================================================
DECLARE SUB Combo (start%, depth%)
DECLARE SUB Emit (s$)
DECLARE FUNCTION Fact# (n%)
DEFINT A-Z
DIM SHARED items$, k, pick(1 TO 10), count&, lineCount, stopped
DIM s(1 TO 7)                  ' letter codes for the permutation demo

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "PERMUTATIONS, COMBINATIONS AND SUBSETS": COLOR 7
    PRINT
    PRINT "  1 - Permutations of a word"
    PRINT "  2 - Combinations: choose k of n letters"
    PRINT "  3 - All subsets (binary counting)"
    PRINT "  Q - Quit"
    DO: m$ = UCASE$(INKEY$): LOOP WHILE m$ = ""
    IF m$ = "Q" OR m$ = CHR$(27) THEN EXIT DO
    IF m$ >= "1" AND m$ <= "3" THEN
        PRINT
        LINE INPUT "Letters (2-7, Enter = ABCD): "; items$
        items$ = UCASE$(LEFT$(items$, 7))
        IF LEN(items$) < 2 THEN items$ = "ABCD"
        n = LEN(items$)
        count& = 0: lineCount = 0: stopped = 0
        CLS
        SELECT CASE m$
        CASE "1"
            ' ---------- NEXT PERMUTATION ---------------------------
            ' Start with the letters sorted (the "smallest" ordering).
            ' To get the next one in dictionary order:
            '  1. From the right, find the first i with s(i) < s(i+1).
            '     If none, this was the last (largest) permutation.
            '  2. From the right, find the first j with s(j) > s(i).
            '  3. Swap s(i) and s(j).
            '  4. Reverse everything after position i.
            ' Example: 1 3 2 -> i=1 (1<3), j=3 (2>1), swap -> 2 3 1,
            '          reverse after i -> 2 1 3.
            ' Total output is n!, and each step costs O(n).
            FOR i = 1 TO n: s(i) = ASC(MID$(items$, i, 1)): NEXT
            FOR i = 1 TO n - 1                  ' simple sort to start
                FOR j = i + 1 TO n
                    IF s(j) < s(i) THEN SWAP s(i), s(j)
                NEXT
            NEXT
            DO
                w$ = ""
                FOR i = 1 TO n: w$ = w$ + CHR$(s(i)): NEXT
                Emit w$
                IF stopped THEN EXIT DO
                i = n - 1                          ' step 1
                DO WHILE i >= 1
                    IF s(i) < s(i + 1) THEN EXIT DO
                    i = i - 1
                LOOP
                IF i < 1 THEN EXIT DO              ' last permutation
                j = n                              ' step 2
                DO WHILE s(j) <= s(i): j = j - 1: LOOP
                SWAP s(i), s(j)                    ' step 3
                lo = i + 1: hi = n                 ' step 4
                DO WHILE lo < hi
                    SWAP s(lo), s(hi): lo = lo + 1: hi = hi - 1
                LOOP
            LOOP
            PRINT : PRINT : PRINT count&; "permutations.  n! ="; Fact#(n);
            PRINT "(fewer if letters repeat)"
        CASE "2"
            LINE INPUT "Choose how many (k)? "; t$
            k = VAL(t$)
            IF k < 1 OR k > n THEN k = 2
            PRINT "Choosing"; k; "of "; items$
            Combo 1, 1
            PRINT : PRINT : PRINT count&; "combinations.  C(n,k) = n!/(k!(n-k)!) =";
            PRINT Fact#(n) / (Fact#(k) * Fact#(n - k))
        CASE "3"
            ' ---------- SUBSETS BY BINARY COUNTING ------------------
            ' Each number from 0 to 2^n - 1 is a pattern of n bits.
            ' Bit b = 1 means "letter b+1 is in the subset".
            '   n = 3:  000 = {}, 001 = {A}, 010 = {B}, 011 = {A,B} ...
            FOR mask = 0 TO 2 ^ n - 1
                w$ = "{"
                FOR b = 0 TO n - 1
                    IF mask AND 2 ^ b THEN w$ = w$ + MID$(items$, b + 1, 1)
                NEXT
                Emit w$ + "}"
                IF stopped THEN EXIT FOR
            NEXT
            PRINT : PRINT : PRINT count&; "subsets.  2^n ="; 2 ^ n
        END SELECT
        PRINT "Press a key for the menu...";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
CLS
END

' --------------------------------------------------------------
' Combo: recursive backtracking for combinations.
' pick(1..depth-1) already holds chosen positions.  For the slot
' "depth" try every position from "start" onward, then recurse to
' fill the next slot using only LATER positions - that is what stops
' us producing both AB and BA.  When k slots are filled, print.
' The "+ (n - k) ..." limit stops early when too few letters remain.
' --------------------------------------------------------------
SUB Combo (start, depth)
    IF stopped THEN EXIT SUB
    IF depth > k THEN                         ' all k chosen: output
        w$ = ""
        FOR i = 1 TO k: w$ = w$ + MID$(items$, pick(i), 1): NEXT
        Emit w$
        EXIT SUB
    END IF
    FOR p = start TO LEN(items$) - (k - depth)
        pick(depth) = p                       ' choose
        Combo p + 1, depth + 1                ' explore
    NEXT                                      ' (un-choose = overwrite)
END SUB

' Prints one result in neat columns and pauses every screenful.
SUB Emit (s$)
    count& = count& + 1
    PRINT LEFT$(s$ + SPACE$(10), 10);
    IF POS(0) > 70 THEN
        PRINT
        lineCount = lineCount + 1
        IF lineCount MOD 20 = 0 THEN
            PRINT "-- more (any key, Esc = stop) --";
            DO: k$ = INKEY$: LOOP WHILE k$ = ""
            IF k$ = CHR$(27) THEN stopped = -1
            PRINT
        END IF
    END IF
END SUB

' n! as a double (7! = 5040)
FUNCTION Fact# (n)
    f# = 1
    FOR i = 2 TO n: f# = f# * i: NEXT
    Fact# = f#
END FUNCTION
