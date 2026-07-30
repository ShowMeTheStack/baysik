' ============================================================
' TITLE:    Circular Queue Checkout
' CATEGORY: Data Structures
' LEVEL:    Beginner
' TAGS:     queue, circular buffer, FIFO, simulation, MOD
' SUMMARY:  A supermarket line stored in a circular array - watch head and tail chase each other around.
' ------------------------------------------------------------
' WHAT IT DOES
'   A QUEUE is a line of people: new arrivals join at the BACK
'   (the tail) and the person at the FRONT (the head) is served
'   first. "FIFO" = First In, First Out.
'
'   A simple array queue has a problem: as people leave from the
'   front, empty slots pile up at the start of the array and the
'   tail runs off the end. The fix is a CIRCULAR BUFFER: when an
'   index reaches the end of the array it wraps back to slot 0
'   using MOD. The program simulates a checkout lane and draws
'   the array with H (head) and T (tail) markers so you can see
'   them go round and round.
'
' HOW TO USE
'   Just watch. Customers arrive at random and the cashier serves
'   them. Press + or - to change how busy the store is.
'   Press Q or Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Enqueue / dequeue on a fixed-size array
'   * Wrap-around indexes with (index + 1) MOD size
'   * Keeping a separate count to tell "full" from "empty"
'   * A simple time-step simulation with RND and TIMER
'
' THINGS TO TRY
'   * Make QSIZE smaller so the queue fills up and customers leave
'   * Add a second cashier (dequeue twice per tick)
'   * Track the longest line seen and print it at the end
' ============================================================

DECLARE SUB DrawQueue ()

CONST QSIZE = 12                 ' slots in the circular array
DIM SHARED q(0 TO QSIZE - 1) AS INTEGER   ' customer numbers (0 = empty)
DIM SHARED head AS INTEGER       ' index of the front customer
DIM SHARED tail AS INTEGER       ' index where the NEXT arrival goes
DIM SHARED count AS INTEGER      ' how many people are waiting
DIM SHARED served AS INTEGER, turnedAway AS INTEGER, nextId AS INTEGER

RANDOMIZE TIMER
CLS
busy = 50                        ' % chance a customer arrives each tick
nextId = 1

DO
    ' ---- Arrival: maybe a new customer joins the back ----------
    IF RND * 100 < busy THEN
        IF count = QSIZE THEN
            ' Queue full: the customer gives up and leaves.
            turnedAway = turnedAway + 1
            event$ = "Line full! Customer" + STR$(nextId) + " left angry."
        ELSE
            q(tail) = nextId                 ' ENQUEUE at the tail
            tail = (tail + 1) MOD QSIZE      ' move tail, wrapping 11 -> 0
            count = count + 1
            event$ = "Customer" + STR$(nextId) + " joined the line."
        END IF
        nextId = nextId + 1
    END IF

    ' ---- Service: the cashier finishes with the front person ---
    ' (about 45% chance per tick, so the line can grow or shrink)
    IF count > 0 AND RND < .45 THEN
        who = q(head)                        ' DEQUEUE from the head
        q(head) = 0                          ' blank the slot (just for the picture)
        head = (head + 1) MOD QSIZE          ' move head, wrapping too
        count = count - 1
        served = served + 1
        event$ = event$ + "  Served customer" + STR$(who) + "."
    END IF

    DrawQueue
    LOCATE 16, 1: PRINT LEFT$(event$ + SPACE$(79), 79);
    LOCATE 18, 1: PRINT "Arrival chance:"; busy; "%   (+/- to change, Q to quit)   ";
    event$ = ""

    ' ---- Wait about 0.4 s, checking the keyboard meanwhile ------
    t! = TIMER
    DO
        k$ = UCASE$(INKEY$)
        IF k$ = "+" AND busy < 95 THEN busy = busy + 5
        IF k$ = "-" AND busy > 5 THEN busy = busy - 5
        IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    LOOP WHILE TIMER - t! < .4 AND TIMER >= t!
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)

CLS
PRINT "Customers served:"; served
PRINT "Customers turned away:"; turnedAway
END

' ------------------------------------------------------------
' DrawQueue: shows every array slot in a row, plus the line of
' people in FIFO order (front first) underneath.
' ------------------------------------------------------------
SUB DrawQueue
    LOCATE 1, 1: PRINT "CIRCULAR QUEUE  -  the array slots 0 .."; QSIZE - 1
    LOCATE 3, 1: PRINT "slot:";
    LOCATE 4, 1: PRINT "data:";
    LOCATE 5, 1: PRINT SPACE$(79);
    FOR i = 0 TO QSIZE - 1
        col = 7 + i * 6
        LOCATE 3, col: PRINT USING "##"; i;
        LOCATE 4, col
        IF q(i) = 0 THEN PRINT "[  ]"; ELSE PRINT USING "[##]"; q(i) MOD 100;
        ' Markers: H under the head slot, T under the tail slot.
        m$ = ""
        IF i = head THEN m$ = "H"
        IF i = tail THEN m$ = m$ + "T"
        LOCATE 5, col + 1: PRINT m$;
    NEXT i

    ' Walk the queue from head, count steps, wrapping with MOD.
    ' This is how you visit a circular buffer in order.
    LOCATE 8, 1: PRINT "Line (front -> back):"; SPACE$(55);
    LOCATE 9, 1: PRINT SPACE$(79);
    LOCATE 9, 1: PRINT " CASHIER <";
    idx = head
    FOR n = 1 TO count
        PRINT q(idx);
        idx = (idx + 1) MOD QSIZE
    NEXT n
    LOCATE 11, 1
    PRINT "head ="; head; " tail ="; tail; " count ="; count; "   "
    PRINT "Served:"; served; "  Turned away:"; turnedAway; "   "
END SUB
