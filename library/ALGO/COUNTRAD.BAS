' ============================================================
' TITLE:    Counting Sort and Radix Sort
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     sorting, counting, buckets, linear time
' SUMMARY:  Sort without comparing: tally values into buckets, then use digit-by-digit radix sort on bigger numbers.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 sorts 30 quiz scores (0-10) with COUNTING SORT.  It shows
'   the tally (a little bar chart), the running totals (prefix sums)
'   and the sorted result.
'   Part 2 sorts 12 three-digit numbers with LSD RADIX SORT: one
'   pass for the ones digit, one for the tens, one for the hundreds.
'   After each pass it shows which "bucket" (0-9) each number fell in.
'
' HOW TO USE
'   Press a key to move to the next step.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Sorting in O(n + k) time when values are small integers
'   * Prefix sums to find where each value starts in the output
'   * Stability: equal keys keep their order (radix sort needs it!)
'   * Extracting digits with \ (integer divide) and MOD
'   * Comparison sorts can't beat O(n log n) - these don't compare!
'
' THINGS TO TRY
'   * Radix sort in base 16 or base 100 - fewer passes, more buckets
'   * Make the scores range 0-1000 - what happens to the count array?
' ============================================================
DECLARE SUB WaitKey ()
DEFINT A-Z
RANDOMIZE TIMER
COLOR 7, 0: CLS

' =================== PART 1: COUNTING SORT ===================
' Idea: if every value is between 0 and K, just COUNT how many of
' each value there are.  Then write out "count(0) zeros, count(1)
' ones, ..." and you are done.  No value is ever compared with
' another!  Work: n steps to count + K steps to write = O(n + K).
CONST NS = 30, K = 10
DIM score(1 TO NS), cnt(0 TO K), startAt(0 TO K), outp(1 TO NS)
FOR i = 1 TO NS: score(i) = INT(RND * (K + 1)): NEXT
PRINT "PART 1 - COUNTING SORT of 30 quiz scores (0..10)"
PRINT : PRINT "Input: ";
FOR i = 1 TO NS: PRINT score(i); : NEXT
PRINT

' Step 1: tally.  cnt(v) = how many times value v appears.
FOR i = 1 TO NS
    cnt(score(i)) = cnt(score(i)) + 1
NEXT
PRINT : PRINT "Step 1 - tally each value:"
FOR v = 0 TO K
    PRINT USING "  ##: ## "; v; cnt(v);
    COLOR 11: PRINT STRING$(cnt(v), 219): COLOR 7   ' CHR$(219) = solid block
NEXT

' Step 2: prefix sums.  startAt(v) = the output slot where the first
' copy of value v goes = 1 + (number of values smaller than v).
startAt(0) = 1
FOR v = 1 TO K
    startAt(v) = startAt(v - 1) + cnt(v - 1)
NEXT
PRINT "Step 2 - first output slot for each value:"
PRINT "  ";
FOR v = 0 TO K: PRINT USING "##:## "; v; startAt(v); : NEXT
PRINT

' Step 3: place.  Walk the INPUT from left to right and drop each
' value into its slot, then move that slot forward.  Because we walk
' left to right, equal values stay in input order: this is STABLE.
' (With plain numbers stability is invisible, but if each score had
' a student name attached, the names would keep their order.)
FOR i = 1 TO NS
    v = score(i)
    outp(startAt(v)) = v
    startAt(v) = startAt(v) + 1
NEXT
PRINT "Step 3 - sorted:"
COLOR 10
FOR i = 1 TO NS: PRINT outp(i); : NEXT
COLOR 7: PRINT
PRINT : PRINT "Press a key for radix sort..."
WaitKey

' =================== PART 2: RADIX SORT ======================
' Counting sort is great for small ranges, but 0..999 would need
' 1000 counters.  Radix sort applies a STABLE counting sort once
' per DIGIT, starting with the least significant (LSD = ones).
' After sorting by ones, then (stably) by tens, numbers with equal
' tens digits are still in ones order.  After the hundreds pass the
' whole list is sorted.  Work: d passes * O(n + 10) = O(d * n),
' where d = number of digits (3 here).
CLS
CONST NR = 12
DIM a(1 TO NR), b(1 TO NR), bucket(0 TO 9), first(0 TO 9)
FOR i = 1 TO NR: a(i) = INT(RND * 900) + 100: NEXT
PRINT "PART 2 - LSD RADIX SORT of 12 three-digit numbers"
PRINT : PRINT "Start:          ";
FOR i = 1 TO NR: PRINT USING "#### "; a(i); : NEXT
PRINT
place = 1                               ' 1 = ones, 10 = tens, 100 = hundreds
FOR pass = 1 TO 3
    ' counting sort keyed on the current digit
    FOR d = 0 TO 9: bucket(d) = 0: NEXT
    FOR i = 1 TO NR
        d = (a(i) \ place) MOD 10       ' e.g. (472 \ 10) MOD 10 = 7
        bucket(d) = bucket(d) + 1
    NEXT
    first(0) = 1
    FOR d = 1 TO 9: first(d) = first(d - 1) + bucket(d - 1): NEXT
    FOR i = 1 TO NR
        d = (a(i) \ place) MOD 10
        b(first(d)) = a(i)
        first(d) = first(d) + 1
    NEXT
    FOR i = 1 TO NR: a(i) = b(i): NEXT  ' copy back for the next pass

    SELECT CASE place
        CASE 1: nm$ = "ones"
        CASE 10: nm$ = "tens"
        CASE ELSE: nm$ = "hundreds"
    END SELECT
    PRINT
    PRINT "Pass"; pass; "- by the "; nm$; " digit:"
    PRINT "  Result:        ";
    FOR i = 1 TO NR: PRINT USING "#### "; a(i); : NEXT
    PRINT
    ' show the digit that decided the order, highlighted underneath
    PRINT "  Digit used:    ";
    COLOR 14
    FOR i = 1 TO NR: PRINT USING "#### "; (a(i) \ place) MOD 10; : NEXT
    COLOR 7: PRINT
    place = place * 10
    PRINT "  (press a key)"
    WaitKey
NEXT
PRINT
COLOR 10: PRINT "Sorted after 3 passes - and not a single comparison!"
COLOR 7: PRINT "Press a key to quit."
WaitKey
END

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN END
END SUB
