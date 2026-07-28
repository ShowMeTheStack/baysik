' ============================================================
' TITLE:    Bubble Sort Visualizer
' CATEGORY: Algorithms
' LEVEL:    Beginner
' TAGS:     sorting, arrays, graphics, animation
' SUMMARY:  Watch colored bars bubble into order while the program counts every comparison and swap.
' ------------------------------------------------------------
' WHAT IT DOES
'   Fills an array with random heights, draws each value as a vertical
'   bar, then runs bubble sort on it.  The two bars being compared are
'   highlighted in white; bars that are known to be in their final
'   place turn green.  A status line shows the pass number and how
'   many comparisons and swaps have been made so far.
'
' HOW TO USE
'   Just run it and watch.  While it is sorting:
'     +  /  -   make the animation faster / slower
'     Esc       stop and quit
'   When it finishes: R = run again with new data, Q or Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * How bubble sort works: compare neighbours, swap if out of order
'   * The "early exit" trick: stop when a whole pass makes no swaps
'   * Why bubble sort is O(n^2): roughly n*n/2 comparisons
'   * SCREEN 13 graphics, LINE ... BF for filled boxes
'   * SUB procedures and DIM SHARED arrays
'
' THINGS TO TRY
'   * Change N to 20 or 160 and see how the work grows
'   * Start with already-sorted data: how many passes does it take?
'   * Start with reverse-sorted data: that is the worst case
' ============================================================
DECLARE SUB DrawBar (i AS INTEGER, c AS INTEGER)
DECLARE SUB Pause ()
DECLARE SUB Status (msg$)
DEFINT A-Z

' ---- Settings -------------------------------------------------
CONST N = 64            ' how many bars (values) to sort
CONST BARW = 5          ' width of each bar in pixels (64*5 = 320)
CONST TOPY = 16         ' bars are drawn below the status line

DIM SHARED a(1 TO N)    ' the data we are sorting
DIM SHARED delay&       ' how many empty loops per animation step
DIM SHARED quit         ' becomes -1 (true) when the user presses Esc
DIM SHARED comps&, swaps&, pass

delay& = 300
SCREEN 13
RANDOMIZE TIMER

DO
    ' ---- 1. Make random data and draw it ----------------------
    CLS
    FOR i = 1 TO N
        a(i) = INT(RND * 180) + 1       ' heights from 1 to 180 pixels
    NEXT
    FOR i = 1 TO N: DrawBar i, 9: NEXT  ' 9 = light blue
    comps& = 0: swaps& = 0: quit = 0

    ' ---- 2. Bubble sort ---------------------------------------
    ' Each PASS walks from left to right comparing neighbours
    ' a(j) and a(j+1).  If the left one is bigger they swap.
    ' The biggest value "bubbles" all the way to the right end,
    ' so after pass 1 the last bar is final, after pass 2 the
    ' last two are final, and so on.  That is why the inner loop
    ' only needs to go up to lastUnsorted - 1.
    lastUnsorted = N
    pass = 0
    DO
        pass = pass + 1
        swapped = 0                      ' did this pass change anything?
        FOR j = 1 TO lastUnsorted - 1
            comps& = comps& + 1
            DrawBar j, 15: DrawBar j + 1, 15     ' highlight the pair
            Pause
            IF quit THEN EXIT DO
            IF a(j) > a(j + 1) THEN
                SWAP a(j), a(j + 1)      ' QBasic's SWAP exchanges two variables
                swaps& = swaps& + 1
                swapped = -1
            END IF
            DrawBar j, 9: DrawBar j + 1, 9       ' back to normal colour
        NEXT
        DrawBar lastUnsorted, 10         ' 10 = green: this bar is done
        lastUnsorted = lastUnsorted - 1
        ' EARLY EXIT: if a full pass made no swaps, everything left
        ' of here is already in order, so we can stop.  On sorted
        ' input this makes bubble sort O(n) instead of O(n^2).
    LOOP WHILE swapped AND lastUnsorted > 1

    IF quit THEN EXIT DO
    FOR i = 1 TO N: DrawBar i, 10: NEXT  ' paint everything green
    Status "Done! R=again Q=quit"
    LOCATE 25, 1
    PRINT USING "Comparisons ####  Swaps ####"; comps&; swaps&;

    ' ---- 3. Wait for R or Q -----------------------------------
    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
LOOP WHILE k$ = "R"

SCREEN 0: WIDTH 80
PRINT "Bubble sort finished."
PRINT "Worst case: about n*n/2 comparisons. For n ="; N; "that is"; N * (N - 1) \ 2
END

' Draws bar number i in colour c.  First erase the whole column
' (colour 0 = black) then draw the bar from the bottom upward.
SUB DrawBar (i AS INTEGER, c AS INTEGER)
    x = (i - 1) * BARW
    LINE (x, TOPY)-(x + BARW - 2, 199), 0, BF
    LINE (x, 199 - a(i))-(x + BARW - 2, 199), c, BF
END SUB

' Slows the animation down so humans can see it, and checks keys.
SUB Pause
    FOR t& = 1 TO delay&: NEXT       ' a simple "busy wait"
    k$ = INKEY$
    SELECT CASE k$
        CASE "+", "=": delay& = delay& \ 2
        CASE "-", "_": delay& = delay& * 2 + 10
        CASE CHR$(27): quit = -1
    END SELECT
    IF comps& MOD 8 = 0 THEN
        Status "Pass" + STR$(pass) + "  Comps" + STR$(comps&) + "  Swaps" + STR$(swaps&)
    END IF
END SUB

' Prints a message on the top line, padded so old text is erased.
SUB Status (msg$)
    LOCATE 1, 1
    PRINT LEFT$(msg$ + SPACE$(40), 40);
END SUB
