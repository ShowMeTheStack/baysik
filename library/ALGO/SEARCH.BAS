' ============================================================
' TITLE:    Searching Showdown
' CATEGORY: Algorithms
' LEVEL:    Beginner
' TAGS:     searching, binary search, arrays, complexity
' SUMMARY:  Find a number in a sorted list of 1000 with linear, binary and interpolation search and count the guesses.
' ------------------------------------------------------------
' WHAT IT DOES
'   Builds a sorted list of 1000 numbers.  You type a number to look
'   for and three searches go hunting for it:
'     LINEAR        - checks every item from the start
'     BINARY        - always checks the middle and throws away half
'     INTERPOLATION - guesses WHERE the value should be, like opening
'                     a dictionary near the back for "W"
'   Each one reports how many items it had to look at ("probes"),
'   and the binary search prints every step so you can follow it.
'
' HOW TO USE
'   Type a number and press Enter.  Just press Enter to pick a random
'   number from the list.  Type Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Linear search is O(n); binary search is O(log n)
'   * Binary search ONLY works on sorted data
'   * lo / hi / mid bookkeeping without off-by-one bugs
'   * Interpolation search: about O(log log n) on evenly spread data
'
' THINGS TO TRY
'   * Search for a number that is not in the list
'   * Make the data very uneven (e.g. a(i) = i * i) and watch
'     interpolation search lose its advantage
' ============================================================
DEFINT A-Z
CONST N = 1000
DIM a(1 TO N)
RANDOMIZE TIMER

' Sorted data: each value is 1..6 bigger than the one before it.
a(1) = INT(RND * 5) + 1
FOR i = 2 TO N: a(i) = a(i - 1) + 1 + INT(RND * 6): NEXT

COLOR 7, 0: CLS
DO
    COLOR 15: PRINT "List: a(1) ="; a(1); " ...  a(1000) ="; a(N): COLOR 7
    LINE INPUT "Number to find (Enter = random, Q = quit): "; t$
    t$ = UCASE$(LTRIM$(RTRIM$(t$)))
    IF t$ = "Q" THEN EXIT DO
    IF t$ = "" THEN
        target = a(INT(RND * N) + 1)
    ELSEIF VAL(t$) < 1 OR VAL(t$) > 30000 THEN
        PRINT "Please type a number from 1 to 30000.": PRINT
        GOTO NextRound
    ELSE
        target = VAL(t$)
    END IF
    PRINT "Looking for"; target
    PRINT

    ' ---------- 1. LINEAR SEARCH: O(n) ----------
    ' Look at a(1), a(2), a(3)... until we find it.  Because the
    ' list is sorted we may also stop early once a(i) > target.
    probes = 0: found = 0
    FOR i = 1 TO N
        probes = probes + 1
        IF a(i) >= target THEN
            IF a(i) = target THEN found = i
            EXIT FOR
        END IF
    NEXT
    PRINT USING "Linear search:        #### probes  "; probes;
    IF found THEN PRINT "found at"; found ELSE PRINT "not found"

    ' ---------- 2. BINARY SEARCH: O(log n) ----------
    ' Keep a window lo..hi that MUST contain the target if it is in
    ' the list.  Check the middle:
    '    too small  -> the target is to the right: lo = mid + 1
    '    too big    -> the target is to the left:  hi = mid - 1
    ' Each probe halves the window, so 1000 items need at most
    ' 10 probes (2^10 = 1024).  A million items: only 20!
    probes = 0: found = 0
    lo = 1: hi = N
    steps$ = ""
    DO WHILE lo <= hi
        mid = (lo + hi) \ 2
        probes = probes + 1
        steps$ = steps$ + STR$(mid)
        IF a(mid) = target THEN
            found = mid: EXIT DO
        ELSEIF a(mid) < target THEN
            lo = mid + 1
        ELSE
            hi = mid - 1
        END IF
    LOOP
    PRINT USING "Binary search:        #### probes  "; probes;
    IF found THEN PRINT "found at"; found ELSE PRINT "not found"
    COLOR 8: PRINT "   positions checked:"; steps$: COLOR 7

    ' ---------- 3. INTERPOLATION SEARCH ----------
    ' Instead of the middle, estimate the position by proportion:
    '   pos = lo + (target - a(lo)) / (a(hi) - a(lo)) * (hi - lo)
    ' If the values are spread evenly the first guess lands very
    ' close, so it often needs only 2-4 probes.  On badly skewed
    ' data it can fall back to O(n) - no free lunch!
    probes = 0: found = 0
    lo = 1: hi = N
    DO WHILE lo <= hi
        IF target < a(lo) OR target > a(hi) THEN EXIT DO
        IF a(hi) = a(lo) THEN
            p = lo                     ' avoid dividing by zero
        ELSE
            ' use a long/single calculation: the product can exceed 32767
            p = lo + INT((CLNG(target) - a(lo)) * (hi - lo) / (CLNG(a(hi)) - a(lo)))
        END IF
        probes = probes + 1
        IF a(p) = target THEN
            found = p: EXIT DO
        ELSEIF a(p) < target THEN
            lo = p + 1
        ELSE
            hi = p - 1
        END IF
    LOOP
    PRINT USING "Interpolation search: #### probes  "; probes;
    IF found THEN PRINT "found at"; found ELSE PRINT "not found"
    PRINT
NextRound:
LOOP
PRINT "Bye!"
END
