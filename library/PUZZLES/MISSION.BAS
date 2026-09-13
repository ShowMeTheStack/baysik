' ============================================================
' TITLE:    Missionaries and Cannibals Solver
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     bfs, state space, river crossing, search, classic
' SUMMARY:  Get everyone across the river safely - BFS finds the shortest plan for any group size and boat.
' ------------------------------------------------------------
' WHAT IT DOES
'   N missionaries and N cannibals must cross a river in a boat that
'   holds at most K people (and needs at least 1 to row).  If on
'   either bank the cannibals ever outnumber the missionaries (while
'   at least one missionary is there), the missionaries are eaten!
'
'   Every situation is a STATE: (missionaries on the left bank,
'   cannibals on the left bank, which side the boat is on).  BFS
'   explores states in order of distance from the start, so the first
'   plan it finds is the shortest one.  It then animates the plan.
'
' HOW TO USE
'   Enter N (1-6) and the boat size K (1-4).  The classic puzzle is
'   N = 3, K = 2 (11 crossings).  Some combinations are impossible -
'   try N = 4, K = 2.  Press a key to step through the crossings.
'
' CONCEPTS YOU WILL LEARN
'   * Encoding a state as one integer
'   * Checking safety constraints with a FUNCTION
'   * Breadth-first search with a parent array
'   * Printing a simple animated scene in text mode
'
' THINGS TO TRY
'   * Also require safety INSIDE the boat.
'   * Count how many states are reachable for each N and K.
' ============================================================
DECLARE FUNCTION Safe% (m AS INTEGER, c AS INTEGER)
DECLARE FUNCTION AskNum% (prompt$, lo AS INTEGER, hi AS INTEGER)
DECLARE SUB Scene (id AS INTEGER, msg$)
DEFINT A-Z

DIM SHARED n, cap
' id = (m * (n + 1) + c) * 2 + side   side 0 = boat on left bank
DIM parent(97), queue(97), path(97)

DO
    CLS
    COLOR 14: PRINT "MISSIONARIES AND CANNIBALS": COLOR 7
    PRINT
    n = AskNum%("How many missionaries (= cannibals), 1-6", 1, 6): IF n < 0 THEN EXIT DO
    cap = AskNum%("Boat capacity, 1-4", 1, 4): IF cap < 0 THEN EXIT DO

    total = (n + 1) * (n + 1) * 2
    FOR i = 0 TO total - 1: parent(i) = -1: NEXT
    start = (n * (n + 1) + n) * 2 + 0      ' everyone on the left
    goal = 1                                ' (0, 0, boat on right)
    parent(start) = start
    head = 0: tail = 1: queue(0) = start
    found = 0
    DO WHILE head < tail AND NOT found
        id = queue(head): head = head + 1
        side = id MOD 2: c = (id \ 2) MOD (n + 1): m = (id \ 2) \ (n + 1)
        ' Try every boat load: dm missionaries + dc cannibals.
        FOR dm = 0 TO cap
            FOR dc = 0 TO cap - dm
                IF dm + dc >= 1 THEN
                    ' The boat carries people AWAY from its own side.
                    IF side = 0 THEN nm = m - dm: nc = c - dc ELSE nm = m + dm: nc = c + dc
                    IF nm >= 0 AND nm <= n AND nc >= 0 AND nc <= n THEN
                        ' Both banks must be safe: left has (nm,nc),
                        ' right has (n-nm, n-nc).
                        IF Safe%(nm, nc) AND Safe%(n - nm, n - nc) THEN
                            nid = (nm * (n + 1) + nc) * 2 + (1 - side)
                            IF parent(nid) = -1 THEN
                                parent(nid) = id
                                queue(tail) = nid: tail = tail + 1
                                IF nid = goal THEN found = -1
                            END IF
                        END IF
                    END IF
                END IF
            NEXT
        NEXT
    LOOP

    IF NOT found THEN
        COLOR 12
        PRINT : PRINT "No solution!  Only"; tail; "safe states can be reached,"
        PRINT "and none of them has everybody on the right bank."
        COLOR 7
    ELSE
        ' Rebuild the path backwards, then play it forwards.
        steps = 0: id = goal
        DO WHILE id <> start
            path(steps) = id: steps = steps + 1: id = parent(id)
        LOOP
        path(steps) = start
        CLS : COLOR 14: PRINT "MISSIONARIES AND CANNIBALS:"; n; "of each, boat holds"; cap: COLOR 7
        PRINT : PRINT "Found a plan with"; steps; "crossings. Press a key to step through it (Esc skips)."
        skip = 0
        FOR s = steps TO 0 STEP -1
            IF s = steps THEN
                msg$ = "Start"
            ELSE
                ' Work out who was in the boat by comparing states.
                a = path(s + 1): b = path(s)
                am = (a \ 2) \ (n + 1): ac = (a \ 2) MOD (n + 1)
                bm = (b \ 2) \ (n + 1): bc = (b \ 2) MOD (n + 1)
                pm = ABS(am - bm): pc = ABS(ac - bc)
                msg$ = "Crossing" + STR$(steps - s) + ": " + LTRIM$(STR$(pm)) + " M + " + LTRIM$(STR$(pc)) + " C row "
                IF b MOD 2 = 1 THEN msg$ = msg$ + "right -->" ELSE msg$ = msg$ + "<-- left"
            END IF
            Scene path(s), msg$
            IF NOT skip THEN
                DO: k$ = INKEY$: LOOP WHILE k$ = ""
                IF k$ = CHR$(27) THEN skip = -1
            END IF
        NEXT
        LOCATE 20, 1: COLOR 10: PRINT "Everyone is safely across!": COLOR 7
    END IF
    PRINT
    LINE INPUT "Try again (Y/N)? "; a$
    IF UCASE$(LEFT$(LTRIM$(a$), 1)) <> "Y" THEN EXIT DO
LOOP
PRINT "Bye!"
END

FUNCTION AskNum% (prompt$, lo AS INTEGER, hi AS INTEGER)
    DO
        PRINT prompt$;
        LINE INPUT "? "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN AskNum% = -1: EXIT FUNCTION
        v = VAL(a$)
        IF v >= lo AND v <= hi THEN AskNum% = v: EXIT FUNCTION
        PRINT "  Please type a number from"; lo; "to"; hi; "(Q quits)."
    LOOP
END FUNCTION

FUNCTION Safe% (m AS INTEGER, c AS INTEGER)
    ' A bank is safe if it has no missionaries, or at least as many
    ' missionaries as cannibals.
    Safe% = (m = 0) OR (m >= c)
END FUNCTION

SUB Scene (id AS INTEGER, msg$)
    ' Draw the river: left bank | water with boat | right bank.
    side = id MOD 2: c = (id \ 2) MOD (n + 1): m = (id \ 2) \ (n + 1)
    LOCATE 12, 1: PRINT SPACE$(79)
    LOCATE 12, 1: COLOR 15: PRINT msg$
    LOCATE 14, 1
    COLOR 14: PRINT LEFT$(STRING$(m, "M") + SPACE$(6), 6);
    COLOR 12: PRINT LEFT$(STRING$(c, "C") + SPACE$(6), 6);
    COLOR 9: PRINT " ~~~";
    COLOR 6
    IF side = 0 THEN PRINT "\_/"; : COLOR 9: PRINT "~~~~~~~~~~~~ ";
    IF side = 1 THEN COLOR 9: PRINT "~~~~~~~~~~~~"; : COLOR 6: PRINT "\_/"; : PRINT " ";
    COLOR 14: PRINT LEFT$(STRING$(n - m, "M") + SPACE$(6), 6);
    COLOR 12: PRINT STRING$(n - c, "C"); SPACE$(6)
    COLOR 7
    LOCATE 16, 1: PRINT "left bank          river           right bank"
END SUB
