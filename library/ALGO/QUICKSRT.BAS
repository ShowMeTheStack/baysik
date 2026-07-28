' ============================================================
' TITLE:    Quicksort Visualizer
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     sorting, recursion, partition, graphics
' SUMMARY:  Watch quicksort pick a pivot, split the bars into small and large, and recurse on each side.
' ------------------------------------------------------------
' WHAT IT DOES
'   Sorts 160 bars with quicksort in SCREEN 13.  The pivot is red,
'   the bar being examined is white, and the "small" region that
'   grows on the left of the current range is yellow.  You can choose
'   between a smart pivot (the middle element) and a naive pivot
'   (the last element) and compare how much work each does on
'   random data and on data that is already sorted.
'
' HOW TO USE
'   Pick a menu option with 1-4.  Esc stops a running sort.
'   Q quits from the menu.
'
' CONCEPTS YOU WILL LEARN
'   * Partitioning around a pivot (Lomuto scheme)
'   * Recursion and the call stack
'   * Average case O(n log n) vs worst case O(n^2)
'   * Why pivot choice matters (sorted input + last-element pivot!)
'
' THINGS TO TRY
'   * Try a random pivot: p = lo + INT(RND * (hi - lo + 1))
'   * Count the maximum recursion depth in each mode
' ============================================================
DECLARE SUB QuickSort (lo%, hi%)
DECLARE FUNCTION Partition% (lo%, hi%)
DECLARE SUB DrawBar (i%, c%)
DECLARE SUB Delay ()
DEFINT A-Z
CONST N = 160
DIM SHARED a(1 TO N)
DIM SHARED comps&, quit, smartPivot, depth, maxDepth
RANDOMIZE TIMER

DO
    SCREEN 0: WIDTH 80: CLS
    PRINT "QUICKSORT VISUALIZER"
    PRINT
    PRINT "  1 - random data,  middle pivot   (good)"
    PRINT "  2 - random data,  last pivot     (also fine)"
    PRINT "  3 - sorted data,  middle pivot   (still good)"
    PRINT "  4 - sorted data,  last pivot     (worst case!)"
    PRINT "  Q - quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ >= "1" AND k$ <= "4" THEN
        smartPivot = (k$ = "1" OR k$ = "3")
        SCREEN 13
        FOR i = 1 TO N
            IF k$ <= "2" THEN a(i) = INT(RND * 180) + 1 ELSE a(i) = i + 10
            DrawBar i, 9
        NEXT
        comps& = 0: quit = 0: depth = 0: maxDepth = 0
        QuickSort 1, N
        IF NOT quit THEN
            FOR i = 1 TO N: DrawBar i, 10: NEXT
        END IF
        LOCATE 1, 1
        PRINT "Comparisons:"; comps&
        PRINT "Max depth:"; maxDepth
        PRINT "n log2 n ="; INT(N * LOG(N) / LOG(2)); " n^2/2 ="; N * (N - 1) \ 2
        PRINT "Press a key";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
SCREEN 0: WIDTH 80
END

SUB Delay
    FOR t& = 1 TO 120: NEXT
    IF INKEY$ = CHR$(27) THEN quit = -1
END SUB

SUB DrawBar (i, c)
    x = (i - 1) * 2
    LINE (x, 10)-(x, 199), 0
    LINE (x, 199 - a(i))-(x, 199), c
END SUB

' --------------------------------------------------------------
' Partition (Lomuto scheme) rearranges a(lo..hi) so that:
'      [ values < pivot ] pivot [ values >= pivot ]
' and returns the pivot's final position.  That position is now
' FINAL - the pivot never has to move again.
'
'   1. Choose a pivot and move it to the end, a(hi).
'   2. "store" marks the end of the small region (starts empty).
'   3. Scan j from lo to hi-1: if a(j) < pivot, swap it into the
'      small region and grow the region by one.
'   4. Finally swap the pivot into position "store".
' This makes exactly (hi - lo) comparisons: O(n) for one partition.
' --------------------------------------------------------------
FUNCTION Partition (lo, hi)
    IF smartPivot THEN p = (lo + hi) \ 2 ELSE p = hi
    SWAP a(p), a(hi)                ' park the pivot at the end
    DrawBar hi, 12
    pivot = a(hi)
    store = lo
    FOR j = lo TO hi - 1
        comps& = comps& + 1
        DrawBar j, 15: Delay
        IF a(j) < pivot THEN
            SWAP a(j), a(store)
            DrawBar store, 14       ' yellow: part of the "small" side
            store = store + 1
        END IF
        IF j >= store THEN DrawBar j, 9
        IF quit THEN EXIT FOR
    NEXT
    SWAP a(store), a(hi)            ' pivot drops into its final slot
    FOR j = lo TO hi: DrawBar j, 9: NEXT
    DrawBar store, 10               ' green = in final position
    Partition = store
END FUNCTION

' --------------------------------------------------------------
' QuickSort sorts a(lo..hi):
'   partition around a pivot, then sort the left part and the
'   right part separately.  Nothing needs merging afterwards -
'   everything on the left is already smaller than the right.
'
' If the pivot splits each range roughly in half, there are about
' log2(n) levels of recursion with n work each: O(n log n).
' If the pivot is always the SMALLEST or LARGEST value (e.g. the
' last element of already-sorted data), one side is empty, the
' other has n-1 items, we get n levels: O(n^2) and very deep
' recursion.  Try menu option 4 to see this happen!
' --------------------------------------------------------------
SUB QuickSort (lo, hi)
    IF lo >= hi OR quit THEN EXIT SUB   ' 0 or 1 items: already sorted
    depth = depth + 1
    IF depth > maxDepth THEN maxDepth = depth
    p = Partition(lo, hi)
    QuickSort lo, p - 1
    QuickSort p + 1, hi
    depth = depth - 1
END SUB
