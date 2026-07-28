' ============================================================
' TITLE:    0/1 Knapsack Planner
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     dynamic programming, optimization, tables, greedy
' SUMMARY:  Pack a backpack for maximum value: fill a dynamic-programming table row by row, then trace back which items to take.
' ------------------------------------------------------------
' WHAT IT DOES
'   An adventurer can carry at most 10 kg.  Six items each have a
'   weight and a value.  Which items should go in the bag to get the
'   most value without going over the limit?  (Each item can be
'   taken once or not at all - that is the "0/1" in the name.)
'   The program fills the DP table one row (item) at a time so you
'   can watch it grow, then traces back through the table to list
'   the chosen items.  Finally it compares with a greedy approach.
'
' HOW TO USE
'   Press a key after each row.  Esc quits.  Type a new capacity
'   (1-15) at the end to solve again, or 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Dynamic programming with a 2-D table
'   * The "take it or leave it" recurrence
'   * Tracing back through a table to recover the actual choices
'   * Why trying all 2^n subsets is too slow, and DP is O(n * W)
'   * Why greedy-by-value-per-kg is NOT always optimal here
'
' THINGS TO TRY
'   * Add more items in the DATA lines (update NI)
'   * Change the recurrence to allow unlimited copies of each item
' ============================================================
DECLARE SUB ShowTable (rows%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST NI = 6               ' number of items
CONST MAXW = 15            ' biggest capacity we support
DIM SHARED nm$(1 TO NI), wt(1 TO NI), vl(1 TO NI)
' best(i, w) = the most value we can get using only the first i
' items with a bag that holds w kg.  Row 0 = "no items" = 0 value.
DIM SHARED best(0 TO NI, 0 TO MAXW), cap

DATA "Tent",6,66, "Rope",5,50, "Lamp",5,52, "Food",2,24, "Map",1,6, "Camera",3,27
FOR i = 1 TO NI: READ nm$(i), wt(i), vl(i): NEXT
DIM used(1 TO NI)          ' greedy's "already considered" flags
cap = 10

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "0/1 KNAPSACK - bag capacity"; cap; "kg": COLOR 7
    PRINT
    PRINT "Item     kg  value"
    FOR i = 1 TO NI
        PRINT USING "\      \ ##  ###"; nm$(i); wt(i); vl(i)
    NEXT

    ' ---------------- Fill the table -------------------------------
    ' For item i and capacity w there are only two choices:
    '   LEAVE it:  value = best(i-1, w)            (same as without i)
    '   TAKE it:   value = vl(i) + best(i-1, w - wt(i))
    '              (only if it fits: wt(i) <= w)  - the rest of the
    '              bag is filled in the best way using earlier items.
    ' best(i, w) = the larger of the two.  Each cell takes O(1) work,
    ' so the whole table is O(NI * cap) - versus 2^NI subsets for
    ' brute force (64 here, but 2^50 = a quadrillion for 50 items!).
    FOR w = 0 TO cap: best(0, w) = 0: NEXT
    FOR i = 1 TO NI
        FOR w = 0 TO cap
            best(i, w) = best(i - 1, w)                    ' leave it
            IF wt(i) <= w THEN
                takeIt = vl(i) + best(i - 1, w - wt(i))   ' take it
                IF takeIt > best(i, w) THEN best(i, w) = takeIt
            END IF
        NEXT
        ShowTable i
        LOCATE 23, 1: PRINT "Row"; i; "("; nm$(i); ") filled - press a key";
        WaitKey
    NEXT

    ' ---------------- Trace back ---------------------------------
    ' Start at the bottom-right cell.  If best(i, w) differs from the
    ' cell above it, item i MUST have been taken: record it and jump
    ' left by its weight.  Otherwise item i was left out.
    LOCATE 23, 1: PRINT SPACE$(60);
    LOCATE 23, 1: PRINT "Take: ";
    w = cap: totW = 0
    FOR i = NI TO 1 STEP -1
        IF best(i, w) <> best(i - 1, w) THEN
            COLOR 10: PRINT nm$(i); " "; : COLOR 7
            w = w - wt(i): totW = totW + wt(i)
        END IF
    NEXT
    PRINT "->"; best(NI, cap); "value,"; totW; "kg"

    ' ---------------- Greedy comparison ----------------------------
    ' Greedy: sort by value per kg and grab items while they fit.
    ' Simple and fast, but it can miss the best combination.
    FOR i = 1 TO NI: used(i) = 0: NEXT
    room = cap: gv = 0
    FOR pick = 1 TO NI
        bi = 0: br! = -1
        FOR i = 1 TO NI                    ' find best unused ratio
            IF NOT used(i) AND vl(i) / wt(i) > br! THEN br! = vl(i) / wt(i): bi = i
        NEXT
        used(bi) = -1
        IF wt(bi) <= room THEN room = room - wt(bi): gv = gv + vl(bi)
    NEXT
    PRINT "Greedy by value/kg gets"; gv; "value";
    IF gv < best(NI, cap) THEN PRINT " - DP wins!" ELSE PRINT " - same this time."
    LINE INPUT "New capacity 1-15 (0 = quit): "; t$
    cap = VAL(t$)
    IF cap < 1 OR cap > MAXW THEN EXIT DO
LOOP
CLS
END

' Draws rows 0..rows of the table.  Header = capacities.
SUB ShowTable (rows)
    LOCATE 11, 1
    COLOR 8: PRINT "  item\kg  ";
    FOR w = 0 TO cap: PRINT USING "####"; w; : NEXT
    PRINT
    FOR i = 0 TO rows
        COLOR 7
        IF i = 0 THEN PRINT "  (none)   "; ELSE PRINT USING "  \      \ "; nm$(i);
        FOR w = 0 TO cap
            ' highlight cells where taking item i improved things
            IF i > 0 THEN
                IF best(i, w) > best(i - 1, w) THEN COLOR 14 ELSE COLOR 7
            END IF
            PRINT USING "####"; best(i, w);
        NEXT
        PRINT
    NEXT
    COLOR 8: PRINT "  yellow = taking this item helped"
    COLOR 7
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN CLS : END
END SUB
