' ============================================================
' TITLE:    Big-O Growth Lab
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     complexity, big-o, timing, graphs, experiment
' SUMMARY:  Run loops of O(1), O(log n), O(n), O(n log n) and O(n^2) for growing n, time them, and plot how the work explodes.
' ------------------------------------------------------------
' WHAT IT DOES
'   For n = 25, 50, 100, 200, 400 the program really runs five kinds
'   of loop and counts the basic steps each one performs:
'     O(1)        a fixed amount of work, whatever n is
'     O(log n)    halve n until it reaches 1 (like binary search)
'     O(n)        one loop over n items (like linear search)
'     O(n log n)  n times a halving loop (like merge sort)
'     O(n^2)      a loop inside a loop (like bubble sort)
'   It measures the time with TIMER, prints a table, shows how much
'   each count grows when n DOUBLES, then plots the curves.
'
' HOW TO USE
'   Wait for the experiment to finish (a few seconds), read the
'   table, press a key to see the graph, and a key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * What Big-O notation really measures: growth, not speed
'   * The "doubling test": x1 constant, +1 log, x2 linear,
'     a bit over x2 for n log n, x4 quadratic
'   * Timing code with TIMER (and why small times are noisy)
'   * Plotting data with WINDOW to use your own coordinates
'
' THINGS TO TRY
'   * Add an O(n^3) triple loop - how many n values can you afford?
'   * Add O(2^n) (e.g. count subsets) for n = 10..20
' ============================================================
DEFINT A-Z
CONST NS = 5
DIM nval(1 TO NS), ops#(1 TO 5, 1 TO NS), secs!(1 TO 5, 1 TO NS)
DIM nm$(1 TO 5), clr(1 TO 5)
DATA "O(1)",9, "O(log n)",10, "O(n)",11, "O(n log n)",14, "O(n^2)",12
FOR k = 1 TO 5: READ nm$(k), clr(k): NEXT

SCREEN 12
COLOR 15: PRINT "BIG-O GROWTH LAB": COLOR 7
PRINT "Running the experiment..."
nval(1) = 25
FOR i = 2 TO NS: nval(i) = nval(i - 1) * 2: NEXT

FOR i = 1 TO NS
    n = nval(i)
    FOR k = 1 TO 5
        c# = 0
        t! = TIMER
        SELECT CASE k
        CASE 1
            ' O(1): e.g. reading a(5) from an array - no loop over n
            FOR j = 1 TO 10: c# = c# + 1: NEXT
        CASE 2
            ' O(log n): how many times can n be halved?  log2(n) times
            m = n
            DO WHILE m > 1: m = m \ 2: c# = c# + 1: LOOP
        CASE 3
            ' O(n): touch every item once
            FOR j = 1 TO n: c# = c# + 1: NEXT
        CASE 4
            ' O(n log n): for each item, a halving loop
            FOR j = 1 TO n
                m = n
                DO WHILE m > 1: m = m \ 2: c# = c# + 1: LOOP
            NEXT
        CASE 5
            ' O(n^2): compare every item with every other item
            FOR j = 1 TO n
                FOR l = 1 TO n: c# = c# + 1: NEXT
            NEXT
        END SELECT
        secs!(k, i) = TIMER - t!
        ops#(k, i) = c#
    NEXT
    PRINT "  n ="; n; "done"
NEXT

' ---- The table ---------------------------------------------------
CLS
COLOR 15: PRINT "Basic steps counted:": COLOR 7
PRINT "             ";
FOR i = 1 TO NS: PRINT USING "  n=####"; nval(i); : NEXT
PRINT
FOR k = 1 TO 5
    COLOR clr(k): PRINT LEFT$(nm$(k) + SPACE$(13), 13);
    FOR i = 1 TO NS: PRINT USING " #######"; ops#(k, i); : NEXT
    PRINT
NEXT
COLOR 7
PRINT
COLOR 15: PRINT "When n doubles, the work is multiplied by:": COLOR 7
FOR k = 1 TO 5
    COLOR clr(k): PRINT LEFT$(nm$(k) + SPACE$(13), 13);
    FOR i = 2 TO NS
        PRINT USING "    x#.##"; ops#(k, i) / ops#(k, i - 1);
    NEXT
    PRINT
NEXT
COLOR 7
PRINT
PRINT "Time for the O(n^2) loop at n ="; nval(NS); ":";
PRINT USING " ##.### s"; secs!(5, NS)
PRINT "(Times under about 0.06 s are below TIMER's resolution, so we"
PRINT " count steps instead - counts don't depend on the computer.)"
PRINT
PRINT "Press a key for the graph...";
DO: LOOP WHILE INKEY$ = ""

' ---- The graph ---------------------------------------------------
' WINDOW lets us draw with our own coordinates: x = n (0..400),
' y = steps (0..maxY).  QBasic converts them to pixels for us.
' We zoom so that n log n fits; n^2 shoots off the top - which is
' exactly the point!
CLS
maxY# = ops#(4, NS) * 1.2
VIEW (60, 30)-(620, 420), 0, 7
WINDOW (0, 0)-(nval(NS), maxY#)
FOR k = 1 TO 5
    PSET (0, 0), clr(k)
    FOR i = 1 TO NS
        y# = ops#(k, i)
        IF y# > maxY# THEN y# = maxY#          ' clip at the top
        LINE -(nval(i), y#), clr(k)
        CIRCLE (nval(i), y#), nval(NS) / 120, clr(k)
    NEXT
NEXT
VIEW: WINDOW
LOCATE 1, 1: COLOR 15: PRINT "Steps vs n  (O(n^2) leaves the chart!)"
FOR k = 1 TO 5
    LOCATE 3 + k, 64: COLOR clr(k): PRINT nm$(k)
NEXT
COLOR 7
LOCATE 28, 8: PRINT "0"; TAB(76); nval(NS)
LOCATE 29, 30: PRINT "n (input size)  - press a key";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END
