' ============================================================
' TITLE:    Power Set and Subset Sum
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, subsets, power set, include/exclude, backtracking
' SUMMARY:  Every subset of a set comes from one yes/no decision per item - recursion makes that a binary decision tree.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 prints the POWER SET of {A,B,C,D}: all 16 subsets.  For
'   each item the recursion makes two branches: leave it OUT, or
'   put it IN.  n items -> 2^n subsets.
'   Part 2 uses exactly the same shape to solve SUBSET SUM: which
'   coins from a pile add up to a target?  Here we also PRUNE: as
'   soon as a partial sum is too big we stop exploring that branch.
'
' HOW TO USE
'   Part 1 prints immediately.  For part 2, enter a target amount
'   (0 quits).
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK LEAF in PowerSet.  Each stop is one
'      finished subset.  Look at the CALL STACK: it is always exactly
'      5 PowerSet frames deep (one per decision + the leaf).
'   2. Click through the frames and look at idx in each: 1,2,3,4,5.
'      Then look at the SHARED array chosen() - it records the
'      yes/no decision made in each frame.
'   3. In part 2 set a breakpoint on <<< BREAK PRUNE.  Every stop
'      is a whole subtree we did NOT have to explore.  Add a WATCH
'      on   nodes   and compare it with 2^8 = 256 (no pruning).
'
' CONCEPTS YOU WILL LEARN
'   * Include/exclude recursion and binary decision trees
'   * 2^n growth
'   * Pruning: cutting off hopeless branches early
'   * Using a SHARED array as the "path so far"
'
' THINGS TO TRY
'   * Count how many subsets of part 1 have exactly 2 items.
'   * In part 2, stop after the FIRST solution is found.
'   * Sort the coins biggest first: does pruning get better?
' ============================================================
DECLARE SUB PowerSet (idx AS INTEGER)
DECLARE SUB SubsetSum (idx AS INTEGER, total AS INTEGER, target AS INTEGER)

CONST NITEMS = 4
CONST NCOINS = 8
DIM SHARED chosen(1 TO 10) AS INTEGER   ' -1 = item is in the subset
DIM SHARED items$(1 TO NITEMS)
DIM SHARED coin(1 TO NCOINS) AS INTEGER
DIM SHARED found AS INTEGER, nodes AS INTEGER

FOR i% = 1 TO NITEMS: items$(i%) = CHR$(64 + i%): NEXT i%
FOR i% = 1 TO NCOINS: READ coin(i%): NEXT i%
DATA 25, 10, 10, 5, 5, 2, 1, 50

CLS
PRINT "PART 1: the power set of {A, B, C, D}"
PowerSet 1
PRINT
PRINT
PRINT "PART 2: subset sum.  Coins:";
FOR i% = 1 TO NCOINS: PRINT coin(i%);: NEXT i%
PRINT
DO
    INPUT "Target amount (0 quits)"; t%
    IF t% <= 0 THEN EXIT DO
    found = 0: nodes = 0
    SubsetSum 1, 0, t%
    PRINT found; "way(s) found, after visiting"; nodes; "tree nodes (full tree = 511)."
    PRINT
LOOP
PRINT "Bye!"
END

' Decide item idx (in or out), then the rest.
SUB PowerSet (idx AS INTEGER)
    DIM k AS INTEGER, s$
    IF idx > NITEMS THEN
        s$ = "{"                        ' <<< BREAK LEAF
        FOR k = 1 TO NITEMS
            IF chosen(k) THEN s$ = s$ + items$(k)
        NEXT k
        PRINT s$; "}  ";
        EXIT SUB
    END IF
    chosen(idx) = 0: PowerSet idx + 1   ' branch 1: leave it out
    chosen(idx) = -1: PowerSet idx + 1  ' branch 2: put it in
    chosen(idx) = 0                     ' tidy up (backtrack)
END SUB

SUB SubsetSum (idx AS INTEGER, total AS INTEGER, target AS INTEGER)
    DIM k AS INTEGER
    nodes = nodes + 1
    IF total = target THEN
        found = found + 1
        PRINT "  ";
        FOR k = 1 TO idx - 1
            IF chosen(k) THEN PRINT coin(k);
        NEXT k
        PRINT
        EXIT SUB
    END IF
    IF total > target OR idx > NCOINS THEN
        EXIT SUB                        ' <<< BREAK PRUNE: dead end
    END IF
    chosen(idx) = -1
    SubsetSum idx + 1, total + coin(idx), target   ' take this coin
    chosen(idx) = 0
    SubsetSum idx + 1, total, target               ' skip this coin
END SUB
