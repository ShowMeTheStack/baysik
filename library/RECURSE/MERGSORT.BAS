' ============================================================
' TITLE:    Merge Sort, Split and Merge
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, sorting, merge sort, arrays, divide and conquer
' SUMMARY:  Watch an array get split into halves all the way down, then merged back together in order, level by level.
' ------------------------------------------------------------
' WHAT IT DOES
'   Merge sort is the textbook divide-and-conquer algorithm:
'     1. SPLIT: sort the left half and the right half (recursively)
'     2. MERGE: two sorted halves are easy to combine - repeatedly
'        take the smaller of the two front elements.
'   A list of 0 or 1 items is already sorted (base case).
'   The program prints every split and every merge, indented by
'   depth, so you can read the whole recursion tree from the screen.
'
' HOW TO USE
'   Just run it.  It sorts 12 random numbers and prints the trace.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK SPLIT.  Each stop shows lo and hi for
'      one piece.  Open the CALL STACK: the chain of MergeSort
'      frames is the path from the whole array down to this piece.
'   2. Break on <<< BREAK MERGE in MergeHalves.  Add WATCH expressions
'          i      j      k      a(i)     a(j)
'      and Step Over the loop to see the two "fingers" i and j
'      walk along the halves while k fills the temp array.
'   3. Look at the SHARED array a() in the Variables panel after
'      each merge - one more stretch of it is sorted each time.
'
' CONCEPTS YOU WILL LEARN
'   * Divide and conquer with two recursive calls
'   * Merging two sorted lists in linear time
'   * Why merge sort is always O(n log n): log n levels, n work each
'   * Using a SHARED temporary array
'
' THINGS TO TRY
'   * Count comparisons and compare with bubble sort.
'   * Sort strings instead of numbers (DIM a(...) AS STRING).
'   * Make it sort descending by changing ONE character.
' ============================================================
DECLARE SUB MergeSort (lo AS INTEGER, hi AS INTEGER, depth AS INTEGER)
DECLARE SUB MergeHalves (lo AS INTEGER, mid AS INTEGER, hi AS INTEGER, depth AS INTEGER)
DECLARE FUNCTION Show$ (lo AS INTEGER, hi AS INTEGER)

CONST N = 12
DIM SHARED a(1 TO N) AS INTEGER     ' the data
DIM SHARED tmp(1 TO N) AS INTEGER   ' scratch space for merging

RANDOMIZE TIMER
FOR i% = 1 TO N: a(i%) = INT(RND * 90) + 10: NEXT i%

CLS
PRINT "MERGE SORT TRACE"
PRINT "start: "; Show$(1, N)
PRINT
MergeSort 1, N, 0
PRINT
PRINT "done:  "; Show$(1, N)
END

SUB MergeSort (lo AS INTEGER, hi AS INTEGER, depth AS INTEGER)
    DIM mid AS INTEGER
    IF lo >= hi THEN EXIT SUB           ' 0 or 1 element: sorted already
    mid = (lo + hi) \ 2                 ' <<< BREAK SPLIT
    PRINT SPACE$(depth * 2); "split "; Show$(lo, mid); "| "; Show$(mid + 1, hi)
    MergeSort lo, mid, depth + 1        ' sort left half
    MergeSort mid + 1, hi, depth + 1    ' sort right half
    MergeHalves lo, mid, hi, depth      ' combine them
END SUB

' Merge sorted a(lo..mid) with sorted a(mid+1..hi).
SUB MergeHalves (lo AS INTEGER, mid AS INTEGER, hi AS INTEGER, depth AS INTEGER)
    DIM i AS INTEGER, j AS INTEGER, k AS INTEGER
    i = lo: j = mid + 1: k = lo         ' <<< BREAK MERGE
    ' While BOTH halves still have items, take the smaller front one.
    DO WHILE i <= mid AND j <= hi
        IF a(i) <= a(j) THEN            ' <= keeps equal items in order (stable)
            tmp(k) = a(i): i = i + 1
        ELSE
            tmp(k) = a(j): j = j + 1
        END IF
        k = k + 1
    LOOP
    ' One half ran out - copy whatever is left of the other.
    DO WHILE i <= mid: tmp(k) = a(i): i = i + 1: k = k + 1: LOOP
    DO WHILE j <= hi: tmp(k) = a(j): j = j + 1: k = k + 1: LOOP
    ' Copy the merged run back into the real array.
    FOR k = lo TO hi: a(k) = tmp(k): NEXT k
    PRINT SPACE$(depth * 2); "merge "; Show$(lo, hi)
END SUB

' Return a(lo..hi) as text, for the trace.
FUNCTION Show$ (lo AS INTEGER, hi AS INTEGER)
    DIM s$, k AS INTEGER
    s$ = ""
    FOR k = lo TO hi: s$ = s$ + LTRIM$(STR$(a(k))) + " ": NEXT k
    Show$ = s$
END FUNCTION
