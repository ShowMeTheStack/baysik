' ============================================================
' TITLE:    Topological Sort: Getting Dressed
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     graphs, topological sort, queue, dependencies, DAG
' SUMMARY:  Use Kahn's algorithm to put tasks with "must come before" rules into a valid order - and catch impossible circular rules.
' ------------------------------------------------------------
' WHAT IT DOES
'   Nine items of clothing have rules such as "socks before shoes"
'   and "shirt before tie".  These rules form a directed graph.  A
'   TOPOLOGICAL ORDER lists every item so that each rule is obeyed.
'   The program runs Kahn's algorithm step by step, showing each
'   item's in-degree (number of unmet rules) and the queue of items
'   that are ready to put on.
'   Then you can add your own rule.  If it creates a cycle (like
'   "shoes before socks"), the algorithm detects that no valid order
'   exists and lists the items that are blocked.
'
' HOW TO USE
'   Press a key to take each step.  At the end type two item numbers
'   to add a rule "A before B" and run again, or press Enter to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Directed graphs stored as an adjacency matrix
'   * In-degree: how many arrows point INTO a node
'   * Kahn's algorithm: repeatedly take a node with in-degree 0
'   * Detecting cycles: nodes that never reach in-degree 0
'   * O(V + E) with adjacency lists (O(V^2) with our matrix)
'
' THINGS TO TRY
'   * Use a stack instead of a queue - you get a different but
'     equally valid order
'   * Model your school's course prerequisites instead of clothes
' ============================================================
DECLARE SUB RunKahn ()
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST N = 9
DIM SHARED item$(1 TO N), edge(1 TO N, 1 TO N)   ' edge(a, b) = a before b
DATA "underwear","pants","belt","shirt","tie","jacket","socks","shoes","watch"
FOR i = 1 TO N: READ item$(i): NEXT
' The rules, as pairs of item numbers: first before second.
DATA 1,2, 2,8, 2,3, 4,3, 4,5, 5,6, 3,6, 7,8, 0,0
DO
    READ a, b
    IF a = 0 THEN EXIT DO
    edge(a, b) = -1
LOOP

DO
    RunKahn
    PRINT
    PRINT "Add a rule 'A before B' (e.g. 8 7 = shoes before socks)."
    LINE INPUT "Two numbers, or Enter to quit: "; t$
    t$ = LTRIM$(RTRIM$(t$))
    IF t$ = "" THEN EXIT DO
    sp = INSTR(t$, " ")
    IF sp = 0 THEN sp = INSTR(t$, ",")
    IF sp > 0 THEN
        a = VAL(LEFT$(t$, sp - 1)): b = VAL(MID$(t$, sp + 1))
        IF a >= 1 AND a <= N AND b >= 1 AND b <= N AND a <> b THEN
            edge(a, b) = -1
        END IF
    END IF
LOOP
END

' --------------------------------------------------------------
' Kahn's algorithm
'   1. Count the in-degree of every node (rules it must wait for).
'   2. Put every node with in-degree 0 into a queue: these are
'      ready right now.
'   3. Repeat: take a node from the queue and add it to the order.
'      "Remove" its outgoing arrows: each target's in-degree drops
'      by one, and any target that reaches 0 joins the queue.
'   4. If the order has all N nodes, done.  If the queue runs dry
'      early, the remaining nodes wait on each other: a CYCLE.
' Every node and every arrow is handled once: O(V + E).
' --------------------------------------------------------------
SUB RunKahn
    DIM indeg(1 TO N), q(1 TO N), order(1 TO N)
    COLOR 7, 0: CLS
    COLOR 15: PRINT "TOPOLOGICAL SORT (Kahn's algorithm)": COLOR 7
    PRINT
    PRINT "Rules:"
    cnt = 0
    FOR a = 1 TO N
        FOR b = 1 TO N
            IF edge(a, b) THEN
                PRINT USING "  #\        \ before #\      \"; a; item$(a); b; item$(b);
                cnt = cnt + 1
                IF cnt MOD 2 = 0 THEN PRINT
            END IF
        NEXT
    NEXT
    IF cnt MOD 2 = 1 THEN PRINT
    ' ---- step 1: in-degrees ----
    FOR b = 1 TO N
        indeg(b) = 0
        FOR a = 1 TO N
            IF edge(a, b) THEN indeg(b) = indeg(b) + 1
        NEXT
    NEXT
    ' ---- step 2: queue all nodes with in-degree 0 ----
    head = 1: tail = 0
    FOR i = 1 TO N
        IF indeg(i) = 0 THEN tail = tail + 1: q(tail) = i
    NEXT
    ' ---- step 3: process the queue ----
    done = 0
    PRINT
    DO WHILE head <= tail
        PRINT "Ready queue:";
        COLOR 11
        FOR i = head TO tail: PRINT " "; item$(q(i)); : NEXT
        COLOR 7: PRINT
        WaitKey
        u = q(head): head = head + 1
        done = done + 1: order(done) = u
        COLOR 10: PRINT "  Put on:"; done; item$(u); : COLOR 7
        FOR v = 1 TO N
            IF edge(u, v) THEN
                indeg(v) = indeg(v) - 1      ' one rule for v is now met
                IF indeg(v) = 0 THEN
                    tail = tail + 1: q(tail) = v
                    PRINT " -> "; item$(v); " is ready";
                END IF
            END IF
        NEXT
        PRINT
    LOOP
    ' ---- step 4: success or cycle? ----
    PRINT
    IF done = N THEN
        COLOR 14: PRINT "A valid order:"
        FOR i = 1 TO N: PRINT " "; item$(order(i)); : NEXT
        PRINT
    ELSE
        COLOR 12
        PRINT "Stuck after"; done; "items - the rules contain a CYCLE!"
        PRINT "Blocked (in or behind the cycle):";
        FOR i = 1 TO N
            IF indeg(i) > 0 THEN PRINT " "; item$(i);
        NEXT
        PRINT
    END IF
    COLOR 7
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN CLS : END
END SUB
