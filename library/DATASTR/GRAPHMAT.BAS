' ============================================================
' TITLE:    Train Map (Adjacency Matrix)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     graph, adjacency matrix, Dijkstra, shortest path, BFS
' SUMMARY:  A train network stored as an adjacency matrix; find the fewest-stops route (BFS) and the fastest route (Dijkstra).
' ------------------------------------------------------------
' WHAT IT DOES
'   A GRAPH is a set of places (VERTICES) joined by connections
'   (EDGES). An ADJACENCY MATRIX stores it as a square table:
'   adj(i, j) is the travel time from station i to station j, or
'   0 when there is no direct track. It is simple and checking
'   "is there a track from i to j?" is instant - but it uses N*N
'   cells even if there are few tracks.
'
'   You pick two stations and the program finds:
'     * the route with the FEWEST STOPS, using breadth-first
'       search (BFS) with a queue
'     * the FASTEST route, using Dijkstra's algorithm, which keeps
'       growing a set of stations whose best time is known
'
' HOW TO USE
'   Type the letter of the start station, then of the destination.
'   Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Representing an undirected graph with a symmetric matrix
'   * BFS levels and the "came from" (parent) array
'   * Dijkstra: always settle the closest unsettled vertex next
'   * Rebuilding a path backwards from the parent links
'
' THINGS TO TRY
'   * Add a new station and some tracks to the DATA
'   * Make a track one-way (only set adj(i, j), not adj(j, i))
' ============================================================

DEFINT A-Z
DECLARE SUB ShowPath (s AS INTEGER, d AS INTEGER, label$)

CONST NV = 8, INF = 9999
DIM SHARED adj(1 TO NV, 1 TO NV), parent(1 TO NV), nm$(1 TO NV)
DIM dist(1 TO NV), done(1 TO NV), q(1 TO NV)

FOR i = 1 TO NV: READ nm$(i): NEXT i
DATA Airport, Bridge, Castle, Docks, Museum, Park, Hilltop, Station
' Tracks: from, to, minutes. Undirected = store both directions.
DO
    READ a, b, w
    IF a = 0 THEN EXIT DO
    adj(a, b) = w: adj(b, a) = w
LOOP
DATA 1,2,4, 1,3,9, 2,3,3, 2,4,7, 3,5,2, 4,5,6, 4,6,3
DATA 5,7,8, 6,7,2, 6,8,9, 7,8,3, 3,4,12, 0,0,0

DO
    CLS
    PRINT "TRAIN MAP - adjacency matrix (minutes, . = no track)"
    PRINT
    PRINT "        ";
    FOR j = 1 TO NV: PRINT "  "; LEFT$(nm$(j), 1); : NEXT j
    PRINT
    FOR i = 1 TO NV
        PRINT LEFT$(nm$(i) + "     ", 8);
        FOR j = 1 TO NV
            IF adj(i, j) THEN PRINT USING "###"; adj(i, j); ELSE PRINT "  .";
        NEXT j
        ' Count the degree (number of tracks) of station i.
        deg = 0
        FOR j = 1 TO NV
            IF adj(i, j) THEN deg = deg + 1
        NEXT j
        PRINT "   "; deg; "tracks"
    NEXT i
    PRINT
    PRINT "Note the matrix is symmetric: adj(i,j) = adj(j,i)."
    PRINT
    LINE INPUT "From station letter (Q quits): "; f$
    f$ = UCASE$(LEFT$(f$, 1))
    IF f$ = "Q" OR f$ = "" OR f$ = CHR$(27) THEN EXIT DO
    LINE INPUT "To station letter: "; t$
    t$ = UCASE$(LEFT$(t$, 1))
    s = 0: d = 0
    FOR i = 1 TO NV
        IF LEFT$(nm$(i), 1) = f$ THEN s = i
        IF LEFT$(nm$(i), 1) = t$ THEN d = i
    NEXT i
    IF s = 0 OR d = 0 THEN
        PRINT "Unknown station. Use the first letter, e.g. A or M."
    ELSE
        ' ---- BFS: fewest stops --------------------------------
        ' Visit stations in waves: first all 1 stop away, then all
        ' 2 stops away... The first time we reach d is the fewest.
        FOR i = 1 TO NV: parent(i) = 0: done(i) = 0: NEXT i
        qh = 1: qt = 1: q(1) = s: done(s) = 1
        DO WHILE qh <= qt
            u = q(qh): qh = qh + 1
            FOR v = 1 TO NV
                IF adj(u, v) <> 0 AND done(v) = 0 THEN
                    done(v) = 1: parent(v) = u
                    qt = qt + 1: q(qt) = v
                END IF
            NEXT v
        LOOP
        ShowPath s, d, "BFS (fewest stops): "

        ' ---- Dijkstra: least total minutes ------------------
        FOR i = 1 TO NV: dist(i) = INF: done(i) = 0: parent(i) = 0: NEXT i
        dist(s) = 0
        FOR rep = 1 TO NV
            ' pick the unsettled station with the smallest distance
            u = 0
            FOR i = 1 TO NV
                IF done(i) = 0 AND dist(i) < INF THEN
                    IF u = 0 THEN u = i ELSE IF dist(i) < dist(u) THEN u = i
                END IF
            NEXT i
            IF u = 0 THEN EXIT FOR       ' rest are unreachable
            done(u) = 1                  ' its distance is now final
            ' "relax" every track out of u
            FOR v = 1 TO NV
                IF adj(u, v) <> 0 AND done(v) = 0 THEN
                    IF dist(u) + adj(u, v) < dist(v) THEN
                        dist(v) = dist(u) + adj(u, v)
                        parent(v) = u
                    END IF
                END IF
            NEXT v
        NEXT rep
        ShowPath s, d, "Dijkstra (fastest): "
        PRINT "Total travel time:"; dist(d); "minutes"
    END IF
    PRINT : PRINT "Press a key...": k$ = INPUT$(1)
LOOP
PRINT "All change, please!"
END

' ShowPath: follow parent() back from d to s, then print it
' forwards. We collect names in reverse into one string.
' The number in brackets is how many hops (tracks) it uses.
SUB ShowPath (s AS INTEGER, d AS INTEGER, label$)
    p$ = nm$(d): v = d: stops = 0
    DO WHILE v <> s
        v = parent(v)
        IF v = 0 THEN PRINT label$; "no route!": EXIT SUB
        p$ = nm$(v) + " > " + p$
        stops = stops + 1
    LOOP
    PRINT label$; p$; " ("; LTRIM$(STR$(stops)); ")"
END SUB
