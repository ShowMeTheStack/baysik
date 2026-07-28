' ============================================================
' TITLE:    Sorting Race
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     sorting, timing, complexity, comparison, benchmark
' SUMMARY:  Six sorting algorithms race on the same data; a table and bar chart show their times and comparison counts.
' ------------------------------------------------------------
' WHAT IT DOES
'   Generates one list of random numbers and gives an identical copy
'   to six algorithms: bubble, selection, insertion, Shell, quick and
'   heap sort.  For each one it measures the time with TIMER and
'   counts the comparisons, checks the result really is sorted, then
'   draws a bar chart of the comparison counts.
'
' HOW TO USE
'   Choose a list size from the menu (1-4).  Bigger lists make the
'   O(n^2) sorts fall far behind.  Q or Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Measuring running time with TIMER
'   * Counting basic operations as a fairer measure than time
'   * O(n^2) vs O(n log n) - doubling n quadruples the slow sorts
'   * Keeping a master copy so each algorithm gets the same input
'
' THINGS TO TRY
'   * Run size 1 and size 2: did bubble sort's count go up 4x?
'   * Add counting sort or merge sort to the race
'   * Give them already-sorted data and see who wins now
' ============================================================
DECLARE SUB Bubble ()
DECLARE SUB Selection ()
DECLARE SUB Insertion ()
DECLARE SUB ShellSort ()
DECLARE SUB Quick (lo%, hi%)
DECLARE SUB HeapSort ()
DECLARE SUB Sift (root%, size%)
DECLARE FUNCTION IsSorted% ()
DEFINT A-Z
CONST MAXN = 800
DIM SHARED a(1 TO MAXN), master(1 TO MAXN)
DIM SHARED n, comps&
DIM nm$(1 TO 6), cmp&(1 TO 6), secs!(1 TO 6)
DATA "Bubble","Selection","Insertion","Shell","Quick","Heap"
FOR i = 1 TO 6: READ nm$(i): NEXT
RANDOMIZE TIMER

DO
    SCREEN 0: WIDTH 80: COLOR 7, 0: CLS
    COLOR 15: PRINT "SORTING RACE": COLOR 7
    PRINT
    PRINT "  1 - 100 numbers"
    PRINT "  2 - 200 numbers"
    PRINT "  3 - 400 numbers"
    PRINT "  4 - 800 numbers   (be patient!)"
    PRINT "  Q - quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    SELECT CASE k$
        CASE "1": n = 100
        CASE "2": n = 200
        CASE "3": n = 400
        CASE "4": n = 800
        CASE ELSE: n = 0
    END SELECT
    IF n > 0 THEN
        FOR i = 1 TO n: master(i) = INT(RND * 32000): NEXT
        CLS
        PRINT "Racing on"; n; "random numbers..."
        PRINT
        PRINT "Algorithm     Comparisons    Seconds   Sorted?"
        PRINT "---------     -----------    -------   -------"
        FOR alg = 1 TO 6
            ' Every algorithm starts from an identical copy of the data.
            FOR i = 1 TO n: a(i) = master(i): NEXT
            comps& = 0
            t! = TIMER
            SELECT CASE alg
                CASE 1: Bubble
                CASE 2: Selection
                CASE 3: Insertion
                CASE 4: ShellSort
                CASE 5: Quick 1, n
                CASE 6: HeapSort
            END SELECT
            secs!(alg) = TIMER - t!
            IF secs!(alg) < 0 THEN secs!(alg) = secs!(alg) + 86400  ' midnight!
            cmp&(alg) = comps&
            IF IsSorted THEN ok$ = "yes" ELSE ok$ = "NO!"
            PRINT USING "\         \  ###########   ####.##   &"; nm$(alg); comps&; secs!(alg); ok$
        NEXT

        ' --- bar chart of comparisons, scaled to the biggest ---
        big& = 1
        FOR alg = 1 TO 6: IF cmp&(alg) > big& THEN big& = cmp&(alg)
        NEXT
        PRINT : PRINT "Comparisons (longest bar ="; big&; ")"
        FOR alg = 1 TO 6
            w = INT(cmp&(alg) / big& * 60)
            IF w < 1 THEN w = 1
            COLOR 7: PRINT USING "\         \"; nm$(alg);
            IF alg <= 3 THEN COLOR 12 ELSE COLOR 10   ' red = O(n^2), green = fast
            PRINT STRING$(w, 219)
        NEXT
        COLOR 7
        PRINT
        PRINT "n^2/2 ="; CLNG(n) * (n - 1) \ 2; "   n*log2(n) ="; INT(n * LOG(n) / LOG(2))
        PRINT "Press any key for the menu...";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
CLS
END

' ---- O(n^2): compare neighbours, swap, repeat ----------------
SUB Bubble
    FOR last = n TO 2 STEP -1
        sw = 0
        FOR j = 1 TO last - 1
            comps& = comps& + 1
            IF a(j) > a(j + 1) THEN SWAP a(j), a(j + 1): sw = -1
        NEXT
        IF sw = 0 THEN EXIT FOR              ' no swaps: already sorted
    NEXT
END SUB

' ---- O(n^2): find the smallest remaining, put it next --------
' Always exactly n(n-1)/2 comparisons, but only n-1 swaps.
SUB Selection
    FOR i = 1 TO n - 1
        m = i
        FOR j = i + 1 TO n
            comps& = comps& + 1
            IF a(j) < a(m) THEN m = j
        NEXT
        SWAP a(i), a(m)
    NEXT
END SUB

' ---- O(n^2) worst, O(n) best: slide each item left -----------
SUB Insertion
    FOR i = 2 TO n
        v = a(i): j = i - 1
        DO WHILE j >= 1
            comps& = comps& + 1
            IF a(j) <= v THEN EXIT DO
            a(j + 1) = a(j): j = j - 1
        LOOP
        a(j + 1) = v
    NEXT
END SUB

' ---- about O(n^1.5): insertion sort with shrinking gaps ------
SUB ShellSort
    h = 1
    DO WHILE h * 3 + 1 < n: h = h * 3 + 1: LOOP
    DO WHILE h >= 1
        FOR i = h + 1 TO n
            v = a(i): j = i - h
            DO WHILE j >= 1
                comps& = comps& + 1
                IF a(j) <= v THEN EXIT DO
                a(j + h) = a(j): j = j - h
            LOOP
            a(j + h) = v
        NEXT
        h = h \ 3
    LOOP
END SUB

' ---- O(n log n) average: partition around a pivot ------------
' This version uses Hoare's two-finger partition: one finger walks
' right past small values, the other walks left past big values,
' and when both stop they swap.
SUB Quick (lo, hi)
    IF lo >= hi THEN EXIT SUB
    pivot = a((lo + hi) \ 2)
    i = lo: j = hi
    DO WHILE i <= j
        DO
            comps& = comps& + 1
            IF a(i) >= pivot THEN EXIT DO
            i = i + 1
        LOOP
        DO
            comps& = comps& + 1
            IF a(j) <= pivot THEN EXIT DO
            j = j - 1
        LOOP
        IF i <= j THEN SWAP a(i), a(j): i = i + 1: j = j - 1
    LOOP
    Quick lo, j
    Quick i, hi
END SUB

' ---- O(n log n) always: build a max-heap, pop the max --------
SUB HeapSort
    FOR i = n \ 2 TO 1 STEP -1: Sift i, n: NEXT
    FOR size = n TO 2 STEP -1
        SWAP a(1), a(size)
        Sift 1, size - 1
    NEXT
END SUB

SUB Sift (root, size)
    r = root
    DO
        c = r * 2
        IF c > size THEN EXIT DO
        IF c < size THEN
            comps& = comps& + 1
            IF a(c + 1) > a(c) THEN c = c + 1
        END IF
        comps& = comps& + 1
        IF a(r) >= a(c) THEN EXIT DO
        SWAP a(r), a(c): r = c
    LOOP
END SUB

' Returns true (-1) if a(1..n) is in non-decreasing order.
FUNCTION IsSorted
    IsSorted = -1
    FOR i = 2 TO n
        IF a(i - 1) > a(i) THEN IsSorted = 0: EXIT FUNCTION
    NEXT
END FUNCTION
