' ============================================================
' TITLE:    Merge Sort Visualizer
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     sorting, recursion, divide and conquer, graphics
' SUMMARY:  A recursive merge sort drawn as bars, showing how two sorted halves zip together into one.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws 128 random bars in SCREEN 12 and sorts them with merge sort.
'   Under the bars a coloured strip shows which range is currently
'   being merged: the left half in cyan, the right half in magenta.
'   At the end it compares the number of comparisons with n*log2(n).
'
' HOW TO USE
'   Watch.  Esc quits early.  When finished, R runs again, Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Divide and conquer: split, solve the halves, combine
'   * Recursion: a SUB that calls itself on smaller pieces
'   * Merging two sorted lists with two "fingers" (indexes)
'   * Why merge sort is O(n log n) in EVERY case
'   * Using a temporary array (merge sort needs O(n) extra memory)
'
' THINGS TO TRY
'   * Feed it already-sorted data - the time barely changes!
'   * Switch to insertion sort for ranges smaller than 8 (a "hybrid")
' ============================================================
DECLARE SUB MergeSort (lo%, hi%, depth%)
DECLARE SUB MergeRuns (lo%, mid%, hi%)
DECLARE SUB DrawBar (i%, c%)
DECLARE SUB Strip (lo%, mid%, hi%)
DEFINT A-Z
CONST N = 128           ' number of values
CONST BW = 5            ' bar width in pixels  (128 * 5 = 640)
CONST BASEY = 400       ' bottom of the bars

DIM SHARED a(1 TO N), tmp(1 TO N)
DIM SHARED comps&, quit, maxDepth

SCREEN 12
RANDOMIZE TIMER
DO
    CLS
    FOR i = 1 TO N: a(i) = INT(RND * 360) + 5: NEXT
    FOR i = 1 TO N: DrawBar i, 11: NEXT
    comps& = 0: quit = 0: maxDepth = 0
    LOCATE 1, 1: PRINT "Merge sort: split in half, sort each half, merge."

    MergeSort 1, N, 1          ' sort the WHOLE array, recursion depth 1

    IF quit THEN EXIT DO
    FOR i = 1 TO N: DrawBar i, 10: NEXT
    LOCATE 28, 1
    PRINT "Comparisons:"; comps&; "   n*log2(n) ="; INT(N * LOG(N) / LOG(2));
    PRINT "   max recursion depth:"; maxDepth
    PRINT "R = run again,  Q = quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
LOOP WHILE k$ = "R"
SCREEN 0: WIDTH 80
END

' Draws bar i in colour c (erasing the old bar first).
SUB DrawBar (i, c)
    x = (i - 1) * BW
    LINE (x, BASEY - 370)-(x + BW - 2, BASEY), 0, BF
    LINE (x, BASEY - a(i))-(x + BW - 2, BASEY), c, BF
END SUB

' --------------------------------------------------------------
' MergeRuns: a(lo..mid) is sorted and a(mid+1..hi) is sorted.
' Combine them into one sorted run a(lo..hi).
'
' Picture two piles of cards, each sorted, face up.  Look at the
' top card of each pile, take the smaller one, repeat.  When one
' pile runs out, copy the rest of the other pile.  Each step takes
' one card, so merging k cards costs O(k) work.
' --------------------------------------------------------------
SUB MergeRuns (lo, mid, hi)
    i = lo          ' finger in the left run
    j = mid + 1     ' finger in the right run
    k = lo          ' where the next output goes in tmp()
    DO WHILE i <= mid AND j <= hi
        comps& = comps& + 1
        ' "<=" (not "<") takes from the LEFT run on ties, which keeps
        ' equal items in their original order: merge sort is STABLE.
        IF a(i) <= a(j) THEN
            tmp(k) = a(i): i = i + 1
        ELSE
            tmp(k) = a(j): j = j + 1
        END IF
        k = k + 1
    LOOP
    DO WHILE i <= mid: tmp(k) = a(i): i = i + 1: k = k + 1: LOOP
    DO WHILE j <= hi: tmp(k) = a(j): j = j + 1: k = k + 1: LOOP
    ' Copy back and redraw so we can watch the merged run appear.
    FOR k = lo TO hi
        a(k) = tmp(k)
        DrawBar k, 14
        FOR d& = 1 TO 150: NEXT          ' tiny delay for the animation
    NEXT
    FOR k = lo TO hi: DrawBar k, 11: NEXT
END SUB

' --------------------------------------------------------------
' MergeSort sorts a(lo..hi).
'   1. A range of 0 or 1 items is already sorted - stop (base case).
'   2. Otherwise split it at the middle,
'   3. sort each half by calling MergeSort recursively,
'   4. merge the two sorted halves.
' The array is halved log2(n) times (7 levels for 128 items) and
' each level does about n comparisons while merging, so the total
' is about n * log2(n) - for 128 items about 896 instead of the
' 8128 a bubble sort might need.
' --------------------------------------------------------------
SUB MergeSort (lo, hi, depth)
    IF quit THEN EXIT SUB
    IF depth > maxDepth THEN maxDepth = depth
    IF hi <= lo THEN EXIT SUB                 ' base case
    mid = (lo + hi) \ 2
    MergeSort lo, mid, depth + 1
    MergeSort mid + 1, hi, depth + 1
    IF INKEY$ = CHR$(27) THEN quit = -1: EXIT SUB
    Strip lo, mid, hi
    MergeRuns lo, mid, hi
END SUB

' Shows the left half (cyan) and right half (magenta) being merged.
SUB Strip (lo, mid, hi)
    LINE (0, BASEY + 4)-(639, BASEY + 12), 0, BF
    LINE ((lo - 1) * BW, BASEY + 4)-(mid * BW - 2, BASEY + 12), 3, BF
    LINE (mid * BW, BASEY + 4)-(hi * BW - 2, BASEY + 12), 5, BF
END SUB
