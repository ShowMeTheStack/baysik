' ============================================================
' TITLE:    Emergency Room Priority Queue
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     heap, priority queue, binary heap, sift up, sift down, heapsort
' SUMMARY:  Patients are treated most-urgent-first using a binary max-heap stored in a plain array.
' ------------------------------------------------------------
' WHAT IT DOES
'   A PRIORITY QUEUE always hands out the most important item
'   next, no matter when it arrived. A BINARY HEAP does this
'   quickly. It is a tree squeezed into an array with no pointers:
'       children of slot i are slots 2*i and 2*i+1
'       parent of slot i is slot i \ 2
'   The rule ("heap property"): every parent is at least as
'   urgent as its children, so the most urgent is always slot 1.
'
'   ADD:    put the new item at the end, then SIFT UP - swap with
'           its parent while it is more urgent.
'   REMOVE: take slot 1, move the last item to slot 1, then SIFT
'           DOWN - swap with the more urgent child until in place.
'   Both take about log2(N) swaps.
'
' HOW TO USE
'   A = a new patient arrives (random illness and urgency)
'   T = treat the most urgent patient
'   S = heapsort demo        Q / Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Array index arithmetic for an implicit tree
'   * Sift up and sift down
'   * A tie-breaker (arrival order) so equal urgencies are fair
'   * Heapsort: build a heap, then remove the max repeatedly
'
' THINGS TO TRY
'   * Turn it into a MIN-heap by flipping the comparisons
'   * Print how many swaps each operation needed
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Higher% (a AS INTEGER, b AS INTEGER)
DECLARE SUB SiftUp (i AS INTEGER)
DECLARE SUB SiftDown (i AS INTEGER)
DECLARE SUB Swp (a AS INTEGER, b AS INTEGER)
DECLARE SUB Show ()

TYPE Patient
    urgency AS INTEGER       ' 1 (mild) .. 9 (critical)
    arrived AS INTEGER       ' ticket number, used to break ties
    illness AS STRING * 14
END TYPE

CONST MAXP = 31              ' 31 = a full tree of 5 levels
DIM SHARED hp(1 TO MAXP) AS Patient
DIM SHARED n, ticket, msg$
DIM ill$(1 TO 8)
DIM a(1 TO 12)              ' numbers for the heapsort demo
FOR i = 1 TO 8: READ ill$(i): NEXT i
DATA "sore throat", "broken arm", "high fever", "bee sting"
DATA "chest pain", "deep cut", "sprained ankle", "allergy"

RANDOMIZE TIMER
' A few patients already waiting.
FOR i = 1 TO 6: GOSUB Arrive: NEXT i
msg$ = "Six patients are waiting."

DO
    Show
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE "A": GOSUB Arrive
    CASE "T"
        IF n = 0 THEN
            msg$ = "Waiting room is empty!"
        ELSE
            msg$ = "Treating #" + LTRIM$(STR$(hp(1).arrived)) + " " + RTRIM$(hp(1).illness) + " (urgency" + STR$(hp(1).urgency) + ")"
            hp(1) = hp(n)         ' last patient jumps to the top...
            n = n - 1
            IF n > 0 THEN SiftDown 1   ' ...and sinks to their place
        END IF
    CASE "S": GOSUB HeapSortDemo
    CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS : PRINT "ER closed. Get well soon!"
END

Arrive:
    IF n = MAXP THEN msg$ = "Waiting room full!": RETURN
    ticket = ticket + 1
    n = n + 1
    hp(n).urgency = INT(RND * 9) + 1
    hp(n).arrived = ticket
    hp(n).illness = ill$(INT(RND * 8) + 1)
    msg$ = "Arrived #" + LTRIM$(STR$(ticket)) + " " + RTRIM$(hp(n).illness) + " urgency" + STR$(hp(n).urgency)
    SiftUp n
    RETURN

' --------------------------------------------------------------
' Heapsort on plain numbers. We reuse the same idea but in place:
' 1. "heapify": sift down every parent, from the last one up.
' 2. Swap the max (slot 1) to the end, shrink the heap, sift down.
' --------------------------------------------------------------
HeapSortDemo:
    CLS
    PRINT "HEAPSORT  12 random numbers"
    FOR i = 1 TO 12: a(i) = INT(RND * 90) + 10: PRINT a(i); : NEXT i: PRINT
    m = 12
    FOR start = m \ 2 TO 1 STEP -1
        GOSUB SinkA
    NEXT start
    PRINT "As a heap:  "; : FOR i = 1 TO 12: PRINT a(i); : NEXT i: PRINT
    DO WHILE m > 1
        SWAP a(1), a(m)           ' biggest goes to its final place
        m = m - 1
        start = 1: GOSUB SinkA
        PRINT "heap"; : FOR i = 1 TO m: PRINT a(i); : NEXT i
        PRINT " |"; : FOR i = m + 1 TO 12: PRINT a(i); : NEXT i: PRINT
    LOOP
    PRINT : PRINT "Sorted! Press a key..."
    k$ = INPUT$(1)
    RETURN

' Sift a(start) down inside a(1..m).
SinkA:
    i = start
    DO
        c = i * 2
        IF c > m THEN EXIT DO
        IF c < m THEN IF a(c + 1) > a(c) THEN c = c + 1
        IF a(i) >= a(c) THEN EXIT DO
        SWAP a(i), a(c): i = c
    LOOP
    RETURN

' Higher%: TRUE if patient a should be seen before patient b.
FUNCTION Higher% (a AS INTEGER, b AS INTEGER)
    IF hp(a).urgency <> hp(b).urgency THEN
        Higher% = hp(a).urgency > hp(b).urgency
    ELSE
        Higher% = hp(a).arrived < hp(b).arrived    ' earlier ticket wins
    END IF
END FUNCTION

' Show the heap as a tree (by levels) and as the raw array.
SUB Show
    CLS
    PRINT "EMERGENCY ROOM - binary max-heap   (A)rrive (T)reat (S)ort demo (Q)uit"
    PRINT
    ' Level L holds slots 2^L .. 2^(L+1)-1. Spread them out evenly.
    lvl = 0: first = 1
    DO WHILE first <= n
        cnt = first                    ' a level has as many slots as its first index
        spacing = 80 \ cnt
        FOR i = first TO first + cnt - 1
            IF i <= n THEN
                LOCATE 3 + lvl * 2, (i - first) * spacing + spacing \ 2 - 1
                IF hp(i).urgency >= 7 THEN COLOR 12 ELSE IF hp(i).urgency >= 4 THEN COLOR 14 ELSE COLOR 10
                PRINT LTRIM$(STR$(hp(i).urgency));
                COLOR 7
            END IF
        NEXT i
        lvl = lvl + 1: first = first * 2
    LOOP
    LOCATE 13, 1
    PRINT "slot urg ticket illness            slot urg ticket illness"
    FOR i = 1 TO n
        IF i <= 8 THEN LOCATE 13 + i, 1 ELSE IF i <= 16 THEN LOCATE 5 + i, 36 ELSE LOCATE 1, 1
        IF i <= 16 THEN PRINT USING "##   #   ###   \            \"; i; hp(i).urgency; hp(i).arrived; hp(i).illness;
    NEXT i
    IF n > 16 THEN LOCATE 22, 1: PRINT "(+"; n - 16; "more in the array)";
    LOCATE 23, 1: PRINT "Waiting:"; n; "  "; LEFT$(msg$, 60);
END SUB

' SiftDown: move hp(i) down while a child is more urgent.
SUB SiftDown (i AS INTEGER)
    p = i
    DO
        c = p * 2                        ' left child
        IF c > n THEN EXIT DO            ' no children: done
        ' pick the more urgent of the two children
        IF c < n THEN IF Higher%(c + 1, c) THEN c = c + 1
        IF NOT Higher%(c, p) THEN EXIT DO
        Swp p, c
        p = c
    LOOP
END SUB

' SiftUp: move hp(i) up while it beats its parent.
SUB SiftUp (i AS INTEGER)
    c = i
    DO WHILE c > 1
        p = c \ 2
        IF NOT Higher%(c, p) THEN EXIT DO
        Swp c, p
        c = p
    LOOP
END SUB

SUB Swp (a AS INTEGER, b AS INTEGER)
    SWAP hp(a), hp(b)        ' SWAP works on whole TYPE records
END SUB
