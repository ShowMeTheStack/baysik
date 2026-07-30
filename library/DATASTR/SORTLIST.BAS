' ============================================================
' TITLE:    High Score Table (Sorted Linked List)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     sorted linked list, insertion, merge, TYPE, high scores
' SUMMARY:  Keeps a top-10 high score table as a sorted linked list, then merges two sorted lists into one.
' ------------------------------------------------------------
' WHAT IT DOES
'   A SORTED linked list keeps its items in order all the time.
'   To insert, you walk along until you find the first node that
'   should come AFTER the new one and splice the new node in just
'   before it - no shifting of other items like an array needs.
'
'   Part 1: scores arrive one at a time (from DATA lines). Each is
'   inserted in descending order. If the table grows past 10, the
'   last node (the lowest score) is cut off and recycled.
'   Part 2: two separately sorted lists are MERGED into one sorted
'   list by repeatedly taking the smaller head - the heart of
'   merge sort.
'
' HOW TO USE
'   Watch the table fill up; press a key to step through. You can
'   then type your own name and score to see where you rank.
'
' CONCEPTS YOU WILL LEARN
'   * Ordered insertion with a trailing "prev" pointer
'   * Trimming a list to a maximum length
'   * Merging two sorted lists using a dummy head node
'
' THINGS TO TRY
'   * Sort ascending instead (change one comparison)
'   * Break ties by name alphabetically
' ============================================================

DEFINT A-Z
DECLARE SUB InsertSorted (nm$, sc AS LONG)
DECLARE SUB ShowTable (hilite AS INTEGER)
DECLARE FUNCTION GetNode% ()

TYPE Entry
    who AS STRING * 10
    score AS LONG
    nxt AS INTEGER
END TYPE

CONST POOL = 40, KEEP = 10
DIM SHARED e(1 TO POOL) AS Entry
DIM SHARED head AS INTEGER, freeHead AS INTEGER, lastNew AS INTEGER

FOR i = 1 TO POOL - 1: e(i).nxt = i + 1: NEXT i
freeHead = 1

' ---------------- PART 1: the high score table ----------------
DO
    READ nm$, sc&
    IF nm$ = "END" THEN EXIT DO
    InsertSorted nm$, sc&
    CLS
    PRINT "New score: "; nm$; sc&
    ShowTable lastNew
    PRINT : PRINT "Press a key for the next score...";
    k$ = INPUT$(1)
LOOP
DATA ANN,4200, BOB,1500, CY,9800, DEE,3100, ED,7600, FAY,500
DATA GUS,6200, HAL,8800, IVY,2500, JO,5100, KIM,7000, LEO,300
DATA MAX,9900, END,0

CLS
PRINT "Your turn! (blank name skips)"
LINE INPUT "Your name: "; nm$
IF nm$ <> "" THEN
    INPUT "Your score"; sc&
    InsertSorted UCASE$(LEFT$(nm$, 10)), sc&
    ShowTable lastNew
    IF lastNew = 0 THEN PRINT "Sorry, not high enough to make the table."
    PRINT "Press a key...": k$ = INPUT$(1)
END IF

' ---------------- PART 2: merging two sorted lists ------------
' Build list A and list B (ascending) straight from DATA.
CLS
PRINT "MERGING TWO SORTED LISTS"
PRINT
FOR L = 1 TO 2
    first = 0: last = 0
    DO
        READ v&
        IF v& < 0 THEN EXIT DO
        n = GetNode%: e(n).score = v&: e(n).nxt = 0
        IF first = 0 THEN first = n ELSE e(last).nxt = n
        last = n
    LOOP
    IF L = 1 THEN a = first ELSE b = first
NEXT L
DATA 2, 9, 14, 20, 31, -1
DATA 1, 3, 10, 11, 25, 40, 41, -1

PRINT "List A:"; : p = a: DO WHILE p: PRINT e(p).score; : p = e(p).nxt: LOOP: PRINT
PRINT "List B:"; : p = b: DO WHILE p: PRINT e(p).score; : p = e(p).nxt: LOOP: PRINT
PRINT

' A DUMMY node saves us from special-casing the first item:
' we always append after "tl", starting at the dummy.
dummy = GetNode%: e(dummy).nxt = 0
tl = dummy
PRINT "Taking the smaller front each time:"
DO WHILE a <> 0 AND b <> 0
    IF e(a).score <= e(b).score THEN
        e(tl).nxt = a: tl = a: a = e(a).nxt
    ELSE
        e(tl).nxt = b: tl = b: b = e(b).nxt
    END IF
    PRINT e(tl).score;
LOOP
' One list ran out; the rest of the other is already sorted.
IF a <> 0 THEN e(tl).nxt = a ELSE e(tl).nxt = b
PRINT " + leftovers"
PRINT
PRINT "Merged:"; : p = e(dummy).nxt
DO WHILE p: PRINT e(p).score; : p = e(p).nxt: LOOP
PRINT : PRINT
PRINT "No numbers were copied - only the nxt links changed!"
END

FUNCTION GetNode%
    n = freeHead
    IF n = 0 THEN PRINT "Out of nodes!": END
    freeHead = e(n).nxt
    GetNode% = n
END FUNCTION

' InsertSorted: put a new entry in descending score order, then
' trim the list so only KEEP entries remain.
SUB InsertSorted (nm$, sc AS LONG)
    n = GetNode%
    e(n).who = nm$: e(n).score = sc
    ' Walk until cur is the first node with a SMALLER score.
    ' New node goes between prev and cur. (Equal scores: the older
    ' entry stays ahead, which feels fair.)
    prev = 0: cur = head
    DO WHILE cur <> 0
        IF e(cur).score < sc THEN EXIT DO
        prev = cur: cur = e(cur).nxt
    LOOP
    e(n).nxt = cur
    IF prev = 0 THEN head = n ELSE e(prev).nxt = n
    lastNew = n

    ' Trim: walk KEEP nodes, then cut everything after.
    p = head: c = 1
    DO WHILE p <> 0 AND c < KEEP
        p = e(p).nxt: c = c + 1
    LOOP
    IF p <> 0 THEN
        cut = e(p).nxt
        e(p).nxt = 0
        DO WHILE cut <> 0           ' recycle the cut-off nodes
            nx = e(cut).nxt
            IF cut = lastNew THEN lastNew = 0   ' new score fell off
            e(cut).nxt = freeHead: freeHead = cut
            cut = nx
        LOOP
    END IF
END SUB

SUB ShowTable (hilite AS INTEGER)
    PRINT
    PRINT "  RANK  NAME        SCORE"
    p = head: r = 1
    DO WHILE p <> 0
        IF p = hilite THEN COLOR 14 ELSE COLOR 7
        PRINT USING "   ##   \        \ ######"; r; e(p).who; e(p).score;
        IF p = hilite THEN PRINT "  <- NEW" ELSE PRINT
        p = e(p).nxt: r = r + 1
    LOOP
    COLOR 7
END SUB
