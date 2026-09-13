' ============================================================
' TITLE:    Water Jug Puzzle (Breadth-First Search)
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     bfs, search, state space, queue, gcd
' SUMMARY:  Measure exactly T litres with two unmarked jugs - BFS finds the shortest list of pours.
' ------------------------------------------------------------
' WHAT IT DOES
'   You have two jugs with no markings, holding A and B litres, and
'   a tap.  You may fill a jug, empty a jug, or pour one into the
'   other until the first is empty or the second is full.  Can you
'   end up with exactly T litres in one jug?  (Think of the movie
'   "Die Hard 3": 5 and 3 litre jugs, make 4!)
'
'   The program treats every possible (amountInA, amountInB) pair as
'   a STATE and explores them with breadth-first search (BFS).  BFS
'   looks at all states 1 move away, then 2 moves away, and so on, so
'   the first time it reaches the goal it has found a SHORTEST answer.
'
' HOW TO USE
'   Enter the size of jug A, jug B (1-20) and the target amount.
'   Read the step-by-step solution.  Answer Y to try again.
'
' CONCEPTS YOU WILL LEARN
'   * Modelling a puzzle as a graph of states
'   * A queue built from an array and two pointers (head, tail)
'   * Remembering each state's parent to rebuild the path
'   * Number theory: T is reachable only if GCD(A,B) divides T
'
' THINGS TO TRY
'   * Try 6 and 4 with target 3 - why is it impossible?
'   * Add a third jug (states become triples).
'   * Change BFS to depth-first search: answers get longer!
' ============================================================
DECLARE FUNCTION GCD% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION AskNum% (prompt$, lo AS INTEGER, hi AS INTEGER)
DECLARE SUB DrawJugs (a AS INTEGER, b AS INTEGER)
DEFINT A-Z

CONST MAXC = 20
' A state (a, b) is stored as one number: id = a * (capB + 1) + b
DIM SHARED capA, capB
DIM parent((MAXC + 1) * (MAXC + 1))    ' state we came from, -1 = unseen
DIM how((MAXC + 1) * (MAXC + 1))       ' which of the 6 actions got here
DIM queue((MAXC + 1) * (MAXC + 1))     ' BFS queue of state ids
DIM path(500)
DIM act$(6)
act$(1) = "Fill A from tap"
act$(2) = "Fill B from tap"
act$(3) = "Empty A"
act$(4) = "Empty B"
act$(5) = "Pour A into B"
act$(6) = "Pour B into A"

DO
    CLS
    COLOR 14: PRINT "THE WATER JUG PUZZLE": COLOR 7
    PRINT
    capA = AskNum%("Size of jug A (1-20)", 1, MAXC): IF capA < 0 THEN EXIT DO
    capB = AskNum%("Size of jug B (1-20)", 1, MAXC): IF capB < 0 THEN EXIT DO
    big = capA: IF capB > big THEN big = capB
    target = AskNum%("Target amount", 1, big): IF target < 0 THEN EXIT DO

    ' Quick maths check before searching (the search would agree).
    g = GCD%(capA, capB)
    PRINT
    PRINT "GCD(" + LTRIM$(STR$(capA)) + "," + LTRIM$(STR$(capB)) + ") ="; g;
    PRINT ": only multiples of"; g; "can ever be measured."

    ' ---- Breadth-first search -------------------------------------
    nStates = (capA + 1) * (capB + 1)
    FOR i = 0 TO nStates - 1: parent(i) = -1: NEXT
    head = 0: tail = 0
    queue(tail) = 0: tail = tail + 1      ' start: both jugs empty (0,0)
    parent(0) = 0
    goal = -1
    DO WHILE head < tail
        id = queue(head): head = head + 1    ' take from the FRONT
        a = id \ (capB + 1): b = id MOD (capB + 1)
        IF a = target OR b = target THEN goal = id: EXIT DO
        ' Generate the 6 possible next states.
        FOR k = 1 TO 6
            na = a: nb = b
            SELECT CASE k
                CASE 1: na = capA
                CASE 2: nb = capB
                CASE 3: na = 0
                CASE 4: nb = 0
                CASE 5                      ' A -> B: pour what fits
                    p = a: IF capB - b < p THEN p = capB - b
                    na = a - p: nb = b + p
                CASE 6                      ' B -> A
                    p = b: IF capA - a < p THEN p = capA - a
                    na = a + p: nb = b - p
            END SELECT
            nid = na * (capB + 1) + nb
            IF parent(nid) = -1 THEN          ' never seen: add to BACK
                parent(nid) = id: how(nid) = k
                queue(tail) = nid: tail = tail + 1
            END IF
        NEXT
    LOOP

    IF goal < 0 THEN
        COLOR 12: PRINT "Impossible!  BFS explored all"; tail; "reachable states.": COLOR 7
    ELSE
        ' Walk backwards from the goal to the start through parent().
        steps = 0: id = goal
        DO WHILE id <> 0
            path(steps) = id: steps = steps + 1
            id = parent(id)
        LOOP
        COLOR 10: PRINT "Solved in"; steps; "steps ("; tail; "states queued):": COLOR 7
        PRINT
        FOR s = steps - 1 TO 0 STEP -1
            id = path(s)
            a = id \ (capB + 1): b = id MOD (capB + 1)
            PRINT USING "##. "; steps - s;
            PRINT LEFT$(act$(how(id)) + SPACE$(16), 16);
            DrawJugs a, b
            IF CSRLIN > 22 AND s > 0 THEN
                LINE INPUT "-- more (Enter) --"; k$
                CLS
            END IF
        NEXT
    END IF
    PRINT
    LINE INPUT "Try again (Y/N)? "; a$
    IF UCASE$(LEFT$(LTRIM$(a$), 1)) <> "Y" THEN EXIT DO
LOOP
PRINT "Bye!"
END

FUNCTION AskNum% (prompt$, lo AS INTEGER, hi AS INTEGER)
    ' Keep asking until we get a whole number in range.  Q returns -1.
    DO
        PRINT prompt$;
        LINE INPUT "? "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN AskNum% = -1: EXIT FUNCTION
        v = VAL(a$)
        IF v >= lo AND v <= hi THEN AskNum% = v: EXIT FUNCTION
        PRINT "  Please type a number from"; lo; "to"; hi; "(or Q to quit)."
    LOOP
END FUNCTION

SUB DrawJugs (a AS INTEGER, b AS INTEGER)
    ' A tiny text picture: # = water, . = empty space in the jug.
    PRINT "A[" + STRING$(a, "#") + STRING$(capA - a, ".") + "]";
    PRINT USING "## "; a;
    PRINT "B[" + STRING$(b, "#") + STRING$(capB - b, ".") + "]";
    PRINT USING "##"; b
END SUB

FUNCTION GCD% (x AS INTEGER, y AS INTEGER)
    ' Euclid's algorithm: gcd(x, y) = gcd(y, x MOD y) until y = 0.
    p = x: q = y
    DO WHILE q <> 0
        r = p MOD q: p = q: q = r
    LOOP
    GCD% = p
END FUNCTION
