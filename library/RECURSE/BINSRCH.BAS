' ============================================================
' TITLE:    Recursive Binary Search
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, binary search, arrays, divide and conquer
' SUMMARY:  Find a number in a sorted list of 100 by halving the search range each call - never more than 7 steps.
' ------------------------------------------------------------
' WHAT IT DOES
'   Builds a sorted array of 100 numbers (multiples of 3 plus a
'   little randomness).  To find a target it looks at the MIDDLE
'   element: if the target is smaller, search the left half; if
'   bigger, the right half.  Each call throws away half the list,
'   so 100 items need at most 7 calls (2^7 = 128).
'   A little map shows the shrinking range [lo .. hi] at each step.
'
' HOW TO USE
'   Enter a number to look for (the list is printed first).
'   Enter -1 to quit.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK in BSearch.  Search for a number from the
'      list.  At each stop look at lo, hi and mid in the Variables
'      panel.  The gap hi - lo halves every time.
'   2. Add a WATCH on   a(mid)   to see the value being compared.
'   3. Search for a number NOT in the list.  Notice the last frame
'      has lo > hi: the range became empty - that is the "not found"
'      base case.
'   4. While paused, EDIT target in the Variables panel to a
'      different number and continue.  The search follows the new
'      target from that point on - a quick way to test "what if".
'
' CONCEPTS YOU WILL LEARN
'   * Binary search: O(log n) instead of O(n)
'   * Two base cases (found / empty range)
'   * Passing a range (lo, hi) instead of copying the array
'
' THINGS TO TRY
'   * Make the array 1000 items.  How many steps at most now?
'   * Count the steps of a plain linear search for comparison.
'   * Change (lo + hi) \ 2 to lo + (hi - lo) \ 2: this form avoids
'     overflow when lo and hi are huge - a famous real-world bug!
' ============================================================
DECLARE FUNCTION BSearch% (target AS INTEGER, lo AS INTEGER, hi AS INTEGER, stepNo AS INTEGER)

CONST N = 100
DIM SHARED a(1 TO N) AS INTEGER

' ---- build a sorted list: each value is 1..3 bigger than the last
RANDOMIZE 7                       ' fixed seed = same list every run
a(1) = INT(RND * 3) + 1
FOR i% = 2 TO N
    a(i%) = a(i% - 1) + INT(RND * 3) + 1
NEXT i%

CLS
PRINT "RECURSIVE BINARY SEARCH - the sorted list:"
FOR i% = 1 TO N
    PRINT USING "####"; a(i%);
NEXT i%
PRINT
PRINT

DO
    INPUT "Number to find (-1 quits)"; t%
    IF t% < 0 THEN EXIT DO
    pos% = BSearch%(t%, 1, N, 1)
    IF pos% > 0 THEN
        PRINT "  Found"; t%; "at position"; pos%
    ELSE
        PRINT "  "; LTRIM$(STR$(t%)); " is not in the list."
    END IF
    PRINT
LOOP
PRINT "Bye!"
END

' Search a(lo..hi) for target.  Returns its position, or 0.
FUNCTION BSearch% (target AS INTEGER, lo AS INTEGER, hi AS INTEGER, stepNo AS INTEGER)
    DIM mid AS INTEGER
    IF lo > hi THEN                     ' <<< BREAK
        PRINT USING "  step ## : range is empty (lo > hi)"; stepNo
        BSearch% = 0                    ' base case 1: nothing left
        EXIT FUNCTION
    END IF

    mid = (lo + hi) \ 2
    PRINT USING "  step ## : lo=### hi=### mid=### a(mid)=####"; stepNo; lo; hi; mid; a(mid)

    IF a(mid) = target THEN
        BSearch% = mid                  ' base case 2: found it
    ELSEIF target < a(mid) THEN
        ' target is in the LEFT half; mid itself is ruled out
        BSearch% = BSearch%(target, lo, mid - 1, stepNo + 1)
    ELSE
        ' target is in the RIGHT half
        BSearch% = BSearch%(target, mid + 1, hi, stepNo + 1)
    END IF
END FUNCTION
