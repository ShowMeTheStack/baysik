' ============================================================
' TITLE:    Two-Pointer Tricks
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     two pointers, arrays, strings, searching
' SUMMARY:  Four classic puzzles solved by walking two indexes through an array: pair sum, de-duplicate, palindrome, reverse.
' ------------------------------------------------------------
' WHAT IT DOES
'   Demonstrates the "two pointer" technique, where two index
'   variables move through the data instead of using nested loops:
'     1. PAIR SUM   - find two numbers in a sorted list adding to a
'                     target, with L moving right and R moving left
'     2. DEDUPE     - remove repeated values from a sorted list in
'                     place, with a slow "write" and a fast "read"
'     3. PALINDROME - check a sentence from both ends at once
'     4. REVERSE    - swap the ends and walk inward
'   Pair sum is animated step by step with ^L and ^R markers.
'
' HOW TO USE
'   Choose 1-4 from the menu, Q to quit.  In the pair-sum demo type
'   a target (or Enter for a random one) and press keys to step.
'
' CONCEPTS YOU WILL LEARN
'   * Turning an O(n^2) "try every pair" loop into O(n)
'   * Loop invariants: why moving L or R can never skip the answer
'   * In-place array editing with read/write indexes
'   * String functions MID$, UCASE$, LEN
'
' THINGS TO TRY
'   * Count how many pairs the brute-force double loop would check
'   * Make pair sum report ALL pairs, not just the first
' ============================================================
DECLARE SUB ShowArr (a%(), cnt%, l%, r%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST N = 12
DIM a(1 TO N)
RANDOMIZE TIMER

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "TWO-POINTER TRICKS": COLOR 7
    PRINT
    PRINT "  1 - Pair with a given sum (sorted list)"
    PRINT "  2 - Remove duplicates in place"
    PRINT "  3 - Palindrome checker"
    PRINT "  4 - Reverse an array in place"
    PRINT "  Q - Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    CLS
    SELECT CASE k$
    CASE "1"
        ' ---------------- PAIR SUM ---------------------------------
        ' Sorted list.  Put L at the smallest and R at the biggest.
        '   sum too small? the only way to grow it is to move L right.
        '   sum too big?   the only way to shrink it is to move R left.
        ' Each step throws away one number that can't be in ANY pair,
        ' so at most n-1 steps: O(n), versus n(n-1)/2 for all pairs.
        a(1) = INT(RND * 5) + 1
        FOR i = 2 TO N: a(i) = a(i - 1) + INT(RND * 8) + 1: NEXT
        PRINT "Sorted list:"
        ShowArr a(), N, 0, 0
        PRINT
        LINE INPUT "Target sum (Enter = random): "; t$
        IF VAL(t$) > 0 AND VAL(t$) < 30000 THEN
            target = VAL(t$)
        ELSE
            target = a(INT(RND * 6) + 1) + a(INT(RND * 6) + 7)   ' surely exists
        END IF
        PRINT "Looking for two numbers that add up to"; target
        PRINT
        l = 1: r = N: steps = 0
        DO WHILE l < r
            steps = steps + 1
            s = a(l) + a(r)
            ShowArr a(), N, l, r
            PRINT "   a(L) + a(R) ="; a(l); "+"; a(r); "="; s;
            IF s = target THEN
                COLOR 10: PRINT "  FOUND!": COLOR 7: EXIT DO
            ELSEIF s < target THEN
                PRINT "  too small -> move L right"
                l = l + 1
            ELSE
                PRINT "  too big   -> move R left"
                r = r - 1
            END IF
            WaitKey
        LOOP
        IF l >= r THEN PRINT "No pair adds up to"; target
        PRINT "Steps:"; steps; "  (brute force could need"; N * (N - 1) \ 2; "checks)"

    CASE "2"
        ' ---------------- REMOVE DUPLICATES ------------------------
        ' "rd" reads every element; "wr" marks where the next NEW value
        ' is written.  Since the list is sorted, a value is new exactly
        ' when it differs from the last value we kept.
        a(1) = INT(RND * 3) + 1
        FOR i = 2 TO N: a(i) = a(i - 1) + INT(RND * 2): NEXT  ' lots of repeats
        PRINT "Before:      ";: ShowArr a(), N, 0, 0
        wr = 1                               ' a(1) is always kept
        FOR rd = 2 TO N
            IF a(rd) <> a(wr) THEN
                wr = wr + 1
                a(wr) = a(rd)                ' copy the new value forward
            END IF
        NEXT
        PRINT "After:       ";: ShowArr a(), wr, 0, 0
        PRINT
        PRINT "Kept"; wr; "unique values out of"; N; "using one pass and no extra array."

    CASE "3"
        ' ---------------- PALINDROME ------------------------------
        ' Compare the first and last LETTERS, then step inward.  Spaces
        ' and punctuation are skipped by moving the pointer past them.
        LINE INPUT "Type a sentence (Enter = 'Never odd or even'): "; s$
        IF s$ = "" THEN s$ = "Never odd or even"
        u$ = UCASE$(s$)
        l = 1: r = LEN(u$): ok = -1
        DO WHILE l < r
            cl$ = MID$(u$, l, 1): cr$ = MID$(u$, r, 1)
            IF cl$ < "A" OR cl$ > "Z" THEN
                l = l + 1                    ' not a letter: skip it
            ELSEIF cr$ < "A" OR cr$ > "Z" THEN
                r = r - 1
            ELSEIF cl$ <> cr$ THEN
                ok = 0: EXIT DO              ' mismatch: not a palindrome
            ELSE
                PRINT "  "; cl$; " = "; cr$; "   (positions"; l; "and"; r; ")"
                l = l + 1: r = r - 1
            END IF
        LOOP
        PRINT
        IF ok THEN
            COLOR 10: PRINT CHR$(34); s$; CHR$(34); " IS a palindrome!"
        ELSE
            COLOR 12: PRINT CHR$(34); s$; CHR$(34); " is NOT a palindrome ("; cl$; " <> "; cr$; ")"
        END IF
        COLOR 7

    CASE "4"
        ' ---------------- REVERSE IN PLACE ------------------------
        ' Swap the outermost pair, then move both pointers inward until
        ' they meet in the middle.  n/2 swaps, no extra array.
        FOR i = 1 TO N: a(i) = i * 10: NEXT
        l = 1: r = N
        DO WHILE l < r
            ShowArr a(), N, l, r
            SWAP a(l), a(r)
            l = l + 1: r = r - 1
        LOOP
        PRINT "Result:": ShowArr a(), N, 0, 0
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
    PRINT : PRINT "Press a key for the menu..."
    WaitKey
LOOP
CLS
END

' Prints the first cnt values.  If l or r is not 0, prints a marker
' line underneath with ^L and ^R pointing at those elements.
SUB ShowArr (a(), cnt, l, r)
    FOR i = 1 TO cnt: PRINT USING "####"; a(i); : NEXT
    PRINT
    IF l > 0 OR r > 0 THEN
        m$ = SPACE$(cnt * 4)
        IF l > 0 THEN MID$(m$, l * 4 - 1, 2) = "^L"
        IF r > 0 THEN MID$(m$, r * 4 - 1, 2) = "^R"
        COLOR 14: PRINT m$: COLOR 7
    END IF
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN CLS : END
END SUB
