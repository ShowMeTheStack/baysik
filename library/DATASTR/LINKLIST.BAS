' ============================================================
' TITLE:    Linked List with a Free List
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     linked list, pointers, free list, TYPE, memory pool
' SUMMARY:  Build a singly linked list inside an array of TYPE records, recycling deleted nodes through a free list.
' ------------------------------------------------------------
' WHAT IT DOES
'   BASIC has no pointers, but we can fake them! We make a "pool"
'   of nodes in an array. Each node holds a value and the INDEX of
'   the next node. An index works just like a pointer: it tells
'   us where to go next. Index 0 means "nothing" (like NULL).
'
'   Unused nodes are chained together into a second list called
'   the FREE LIST. Allocating a node = pop one off the free list.
'   Freeing a node = push it back. This is exactly how real
'   memory allocators recycle memory.
'
'   The program runs a little interactive menu and always shows
'   both the logical list (in order) and the raw pool table.
'
' HOW TO USE
'   1 = insert at front   2 = append at end   3 = delete a value
'   4 = reverse the list  5 = search          Q = quit
'
' CONCEPTS YOU WILL LEARN
'   * TYPE records with an "index pointer" field
'   * Walking a list:  p = head: DO WHILE p <> 0 ... p = pool(p).nxt
'   * Deleting needs the PREVIOUS node to re-link around the victim
'   * Reversing a list in place with three pointers
'
' THINGS TO TRY
'   * Add "insert after value X"
'   * Keep a tail pointer so append doesn't have to walk the list
'   * Make POOLSIZE tiny and watch "out of memory" happen
' ============================================================

' DEFINT A-Z makes every untyped variable an INTEGER. Our SUBs take
' INTEGER parameters, and BASIC insists the argument types match.
DEFINT A-Z

DECLARE FUNCTION NewNode% (v AS INTEGER)
DECLARE SUB FreeNode (i AS INTEGER)
DECLARE SUB Show ()

TYPE ListNode
    value AS INTEGER
    nxt AS INTEGER          ' index of the next node, 0 = end of list
    used AS INTEGER         ' 1 if in the list, 0 if free (for display)
END TYPE

CONST POOLSIZE = 10
DIM SHARED pool(1 TO POOLSIZE) AS ListNode
DIM SHARED head AS INTEGER       ' first node of our list (0 = empty)
DIM SHARED freeHead AS INTEGER   ' first node of the free list

' ---- Initialise: every node starts on the free list ----------
' Chain 1 -> 2 -> 3 -> ... -> POOLSIZE -> 0
FOR i = 1 TO POOLSIZE - 1
    pool(i).nxt = i + 1
NEXT i
pool(POOLSIZE).nxt = 0
freeHead = 1
head = 0

' Start with a few values so there is something to see.
FOR i = 1 TO 3
    READ v
    p = NewNode%(v)
    pool(p).nxt = head: head = p     ' insert at front
NEXT i
DATA 30, 20, 10

DO
    CLS
    Show
    PRINT
    PRINT "1) Insert front  2) Append  3) Delete  4) Reverse  5) Search  Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    SELECT CASE c$
    CASE "1", "2"
        INPUT "Value"; v
        p = NewNode%(INT(v))
        IF p = 0 THEN
            PRINT "Out of memory - the free list is empty! (press a key)": k$ = INPUT$(1)
        ELSEIF c$ = "1" OR head = 0 THEN
            ' FRONT insert: new node points at old head, becomes head.
            pool(p).nxt = head
            head = p
        ELSE
            ' APPEND: walk to the last node (whose nxt is 0).
            t = head
            DO WHILE pool(t).nxt <> 0
                t = pool(t).nxt
            LOOP
            pool(t).nxt = p
        END IF
    CASE "3"
        INPUT "Value to delete"; v
        ' Walk with two pointers: prev trails one step behind cur.
        prev = 0: cur = head
        DO WHILE cur <> 0
            IF pool(cur).value = v THEN EXIT DO
            prev = cur: cur = pool(cur).nxt
        LOOP
        IF cur <> 0 THEN
            ' Re-link around cur. If cur was the head, move head.
            IF prev = 0 THEN head = pool(cur).nxt ELSE pool(prev).nxt = pool(cur).nxt
            FreeNode cur
        END IF
    CASE "4"
        ' REVERSE: flip every arrow. prev, cur, nxt walk together.
        '   before: prev  cur -> nx -> ...
        '   after : prev <- cur   nx -> ...
        prev = 0: cur = head
        DO WHILE cur <> 0
            nx = pool(cur).nxt
            pool(cur).nxt = prev
            prev = cur
            cur = nx
        LOOP
        head = prev
    CASE "5"
        INPUT "Find value"; v
        p = head: pos1 = 1
        DO WHILE p <> 0
            IF pool(p).value = v THEN EXIT DO
            p = pool(p).nxt: pos1 = pos1 + 1
        LOOP
        IF p THEN PRINT "Found at list position"; pos1; "(pool slot"; p; ")" ELSE PRINT "Not found."
        PRINT "Press a key...": k$ = INPUT$(1)
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
PRINT "Bye!"
END

' FreeNode: give a node back by pushing it on the free list.
SUB FreeNode (i AS INTEGER)
    pool(i).used = 0
    pool(i).nxt = freeHead
    freeHead = i
END SUB

' NewNode: take the first node off the free list. Returns 0 if none.
FUNCTION NewNode% (v AS INTEGER)
    IF freeHead = 0 THEN NewNode% = 0: EXIT FUNCTION
    i = freeHead
    freeHead = pool(i).nxt       ' free list now starts at the next one
    pool(i).value = v
    pool(i).nxt = 0
    pool(i).used = 1
    NewNode% = i
END FUNCTION

' Show: print the list in order, then the raw pool table.
SUB Show
    PRINT "LIST:  head ->";
    p = head
    DO WHILE p <> 0
        PRINT " ["; LTRIM$(STR$(pool(p).value)); "] ->";
        p = pool(p).nxt
    LOOP
    PRINT " 0 (end)"
    PRINT "FREE:  freeHead ->";
    p = freeHead
    DO WHILE p <> 0
        PRINT p; "->";
        p = pool(p).nxt
    LOOP
    PRINT " 0"
    PRINT
    PRINT "POOL  slot  value   next   status"
    FOR i = 1 TO POOLSIZE
        PRINT USING "      ##  ######   ##     "; i; pool(i).value; pool(i).nxt;
        IF pool(i).used THEN PRINT "in list"; ELSE PRINT "free";
        IF i = head THEN PRINT "  <- head";
        IF i = freeHead THEN PRINT "  <- freeHead";
        PRINT
    NEXT i
END SUB
