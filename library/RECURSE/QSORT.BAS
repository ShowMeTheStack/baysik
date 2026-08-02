' ============================================================
' TITLE:    Quicksort Partition Explorer
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, sorting, quicksort, partition, pivot, worst case
' SUMMARY:  Quicksort with a visible pivot and partition at every level, plus a max-depth meter that exposes its worst case.
' ------------------------------------------------------------
' WHAT IT DOES
'   Quicksort picks a PIVOT value, then rearranges the array so
'   everything smaller is on the left and everything bigger on the
'   right (PARTITION).  Now the pivot is in its final place, and the
'   two sides are sorted the same way, recursively.
'   We sort three kinds of data and record the deepest the call
'   stack got:
'     random data      -> depth about 2 * log2(n)
'     sorted data      -> with "last element" pivot, depth = n !
'     sorted, middle   -> choosing the middle element fixes it
'
' HOW TO USE
'   Run it.  Round 1 shows a full trace on 10 numbers; round 2 shows
'   just the depth statistics on 60 numbers.  Press a key between.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK PIVOT.  Look at lo, hi and pivot.  Then
'      Step Over the FOR loop in Partition while watching
'          i     j     a(j)
'      i marks the end of the "small" zone; j scans ahead.
'   2. Set a CONDITIONAL breakpoint on <<< BREAK DEPTH with
'          depth > 20
'      It only fires in the sorted / last-pivot test.  Open the
'      CALL STACK and scroll: dozens of QSort frames, each with hi
'      just one less than the frame below.  That is the O(n^2)
'      worst case, and the reason real libraries pick pivots wisely.
'
' CONCEPTS YOU WILL LEARN
'   * Lomuto partition scheme
'   * How pivot choice changes recursion depth and speed
'   * Measuring max depth with a SHARED variable
'   * SWAP statement
'
' THINGS TO TRY
'   * Use a random pivot: SWAP a(lo + INT(RND * (hi - lo + 1))), a(hi)
'   * Count comparisons for each test.
'   * Recurse into the SMALLER side first and loop on the bigger
'     one: depth is then guaranteed to be at most log2(n).
' ============================================================
DECLARE SUB QSort (lo AS INTEGER, hi AS INTEGER, depth AS INTEGER)
DECLARE FUNCTION Partition% (lo AS INTEGER, hi AS INTEGER)
DECLARE SUB RunTest (title$, kind AS INTEGER, n AS INTEGER, mode AS INTEGER)
DECLARE SUB ShowArr (n AS INTEGER)

DIM SHARED a(1 TO 100) AS INTEGER
DIM SHARED maxDepth AS INTEGER, calls AS INTEGER
DIM SHARED trace AS INTEGER         ' -1 = print every partition
DIM SHARED middlePivot AS INTEGER   ' -1 = use middle element as pivot
DIM SHARED cnt AS INTEGER           ' how many elements are in use

RANDOMIZE TIMER
CLS
PRINT "QUICKSORT - round 1: full trace of 10 random numbers"
PRINT
trace = -1
RunTest "random, last-element pivot", 1, 10, 0
PRINT
PRINT "Press any key for round 2..."
k$ = INPUT$(1)

CLS
PRINT "QUICKSORT - round 2: how deep does the call stack get? (n = 60)"
PRINT
trace = 0
RunTest "random data, last-element pivot ", 1, 60, 0
RunTest "SORTED data, last-element pivot ", 2, 60, 0
RunTest "SORTED data, middle pivot       ", 2, 60, -1
PRINT
PRINT "Sorted input + last-element pivot = every partition is lopsided,"
PRINT "so the stack grows one frame per element: the worst case."
END

' kind 1 = random, kind 2 = already sorted
SUB RunTest (title$, kind AS INTEGER, n AS INTEGER, mode AS INTEGER)
    DIM i AS INTEGER
    cnt = n
    FOR i = 1 TO n
        IF kind = 1 THEN a(i) = INT(RND * 90) + 10 ELSE a(i) = i + 9
    NEXT i
    middlePivot = mode
    maxDepth = 0: calls = 0
    IF trace THEN PRINT "start  ";: ShowArr n
    QSort 1, n, 1
    IF trace THEN PRINT "sorted ";: ShowArr n
    PRINT title$; " calls:"; calls; "  max depth:"; maxDepth
END SUB

SUB QSort (lo AS INTEGER, hi AS INTEGER, depth AS INTEGER)
    DIM p AS INTEGER
    calls = calls + 1
    IF depth > maxDepth THEN maxDepth = depth   ' <<< BREAK DEPTH
    IF lo >= hi THEN EXIT SUB                   ' 0 or 1 element
    p = Partition%(lo, hi)                      ' pivot lands at p
    IF trace THEN
        PRINT SPACE$(depth); "pivot"; a(p); "-> ";: ShowArr cnt
    END IF
    QSort lo, p - 1, depth + 1                  ' smaller ones
    QSort p + 1, hi, depth + 1                  ' bigger ones
END SUB

' Lomuto partition: uses a(hi) as the pivot.
FUNCTION Partition% (lo AS INTEGER, hi AS INTEGER)
    DIM pivot AS INTEGER, i AS INTEGER, j AS INTEGER
    ' Optional fix for sorted data: move the middle element to the
    ' end first, so it becomes the pivot.
    IF middlePivot THEN SWAP a((lo + hi) \ 2), a(hi)
    pivot = a(hi)                               ' <<< BREAK PIVOT
    i = lo - 1                                  ' end of the "small" zone
    FOR j = lo TO hi - 1
        IF a(j) < pivot THEN
            i = i + 1
            SWAP a(i), a(j)                     ' grow the small zone
        END IF
    NEXT j
    SWAP a(i + 1), a(hi)                        ' put pivot between zones
    Partition% = i + 1
END FUNCTION

SUB ShowArr (n AS INTEGER)
    DIM i AS INTEGER
    FOR i = 1 TO n: PRINT a(i);: NEXT i
    PRINT
END SUB
