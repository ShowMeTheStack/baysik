' ============================================================
' TITLE:    Course Planner (Adjacency List)
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     graph, adjacency list, DFS, topological sort, cycle detection
' SUMMARY:  Course prerequisites stored as an adjacency list; DFS explores them and a topological sort builds a valid study order.
' ------------------------------------------------------------
' WHAT IT DOES
'   An ADJACENCY LIST stores, for every vertex, only the edges that
'   actually leave it. For a sparse graph that is far smaller than
'   an adjacency matrix. In BASIC we build it with arrays:
'       firstEdge(v)  -> index of v's first edge (0 = none)
'       eTo(e)        -> where edge e goes
'       eNext(e)      -> the next edge of the same vertex
'   It's a linked list of edges per vertex, all in shared arrays.
'
'   The graph is a set of school courses. An edge A -> B means
'   "A must be taken before B". The program:
'     1. prints the adjacency lists
'     2. does a depth-first search (DFS) from a course you pick,
'        showing everything it unlocks, with indentation by depth
'     3. finds a valid study order with Kahn's TOPOLOGICAL SORT
'     4. adds a bad edge that creates a cycle and shows that the
'        sort detects it ("you can never start!")
'
' HOW TO USE
'   Press keys to move through the steps. In step 2 type a course
'   number.
'
' CONCEPTS YOU WILL LEARN
'   * Building linked edge lists with parallel arrays
'   * Recursive DFS with a "visited" array
'   * In-degree counting and Kahn's algorithm with a queue
'   * Detecting cycles in a directed graph
'
' THINGS TO TRY
'   * Add your own courses and prerequisites in DATA
'   * Change Kahn's queue into a stack - is the order still valid?
' ============================================================

DEFINT A-Z
DECLARE SUB AddEdge (a AS INTEGER, b AS INTEGER)
DECLARE SUB Dfs (v AS INTEGER, depth AS INTEGER)
DECLARE SUB TopoSort ()

CONST NV = 10, MAXE = 40
DIM SHARED firstEdge(1 TO NV), eTo(1 TO MAXE), eNext(1 TO MAXE), ne
DIM SHARED course$(1 TO NV), seen(1 TO NV)

FOR i = 1 TO NV: READ course$(i): NEXT i
DATA "Counting", "Adding", "Multiplying", "Fractions", "Algebra"
DATA "Geometry", "Trigonometry", "Coordinates", "Calculus", "Physics"
DO
    READ a, b
    IF a = 0 THEN EXIT DO
    AddEdge a, b
LOOP
DATA 1,2, 2,3, 3,4, 2,8, 4,5, 3,6, 6,7, 5,7, 8,5, 5,9, 7,9, 9,10, 7,10, 0,0

' ---- 1. Show the adjacency lists ---------------------------
CLS
PRINT "ADJACENCY LISTS  (course -> courses it unlocks)"
PRINT
FOR v = 1 TO NV
    PRINT USING "##  \           \ ->"; v; course$(v);
    e = firstEdge(v)
    DO WHILE e
        PRINT eTo(e);
        e = eNext(e)
    LOOP
    PRINT
NEXT v
PRINT
PRINT "Edges stored:"; ne; " (a matrix would need"; NV * NV; "cells)"
PRINT : PRINT "Press a key..."
k$ = INPUT$(1)

' ---- 2. DFS from a chosen course ---------------------------
DO
    CLS
    PRINT "DEPTH-FIRST SEARCH - everything a course leads to"
    PRINT
    FOR v = 1 TO NV: PRINT v; course$(v): NEXT v
    PRINT
    INPUT "Start from course number (0 = next step)"; st
    IF st < 1 OR st > NV THEN EXIT DO
    FOR v = 1 TO NV: seen(v) = 0: NEXT v
    PRINT
    Dfs st, 0
    PRINT : PRINT "Press a key...": k$ = INPUT$(1)
LOOP

' ---- 3. Topological sort -----------------------------------
CLS
PRINT "TOPOLOGICAL SORT - a study order that respects every prerequisite"
PRINT
TopoSort
PRINT : PRINT "Press a key to add a BAD rule: 'Physics before Adding'..."
k$ = INPUT$(1)

' ---- 4. Add a cycle and try again --------------------------
PRINT
AddEdge 10, 2
PRINT "Added edge 10 -> 2. Now Adding needs Physics, which needs Adding..."
PRINT
TopoSort
END

' AddEdge: push a new edge onto the FRONT of a's edge list.
SUB AddEdge (a AS INTEGER, b AS INTEGER)
    IF ne = MAXE THEN EXIT SUB
    ne = ne + 1
    eTo(ne) = b
    eNext(ne) = firstEdge(a)
    firstEdge(a) = ne
END SUB

' Dfs: visit v, then dive into each unvisited neighbour before
' trying the next one. Indentation shows how deep we are.
SUB Dfs (v AS INTEGER, depth AS INTEGER)
    seen(v) = 1
    PRINT SPACE$(depth * 3); "+-"; course$(v)
    e = firstEdge(v)
    DO WHILE e
        IF seen(eTo(e)) = 0 THEN Dfs (eTo(e)), depth + 1
        e = eNext(e)
    LOOP
END SUB

' TopoSort (Kahn's algorithm):
'   1. Count each course's in-degree (how many prerequisites).
'   2. Queue every course with in-degree 0 - ready to take now.
'   3. Take one from the queue, "complete" it, and lower the
'      in-degree of everything it unlocks; any that reach 0 join
'      the queue.
'   If some courses never reach 0, there must be a cycle.
SUB TopoSort
    DIM indeg(1 TO NV), q(1 TO NV)
    FOR v = 1 TO NV
        e = firstEdge(v)
        DO WHILE e: indeg(eTo(e)) = indeg(eTo(e)) + 1: e = eNext(e): LOOP
    NEXT v
    qh = 1: qt = 0
    FOR v = 1 TO NV
        IF indeg(v) = 0 THEN qt = qt + 1: q(qt) = v
    NEXT v
    term = 0
    DO WHILE qh <= qt
        v = q(qh): qh = qh + 1
        term = term + 1
        PRINT USING "Term ##: &"; term; course$(v)
        e = firstEdge(v)
        DO WHILE e
            w = eTo(e)
            indeg(w) = indeg(w) - 1
            IF indeg(w) = 0 THEN qt = qt + 1: q(qt) = w
            e = eNext(e)
        LOOP
    LOOP
    IF term < NV THEN
        COLOR 12
        PRINT "CYCLE DETECTED! These courses can never be started:"
        FOR v = 1 TO NV
            IF indeg(v) > 0 THEN PRINT "   "; course$(v)
        NEXT v
        COLOR 7
    ELSE
        PRINT "All"; NV; "courses scheduled."
    END IF
END SUB
