' ============================================================
' TITLE:    Playlist (Doubly Linked List)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     doubly linked list, TYPE, pointers, playlist, free list
' SUMMARY:  A music playlist you can walk forwards and backwards, reorder, and edit - built on a doubly linked list.
' ------------------------------------------------------------
' WHAT IT DOES
'   In a DOUBLY linked list each node knows both its NEXT and its
'   PREVIOUS neighbour. That makes it easy to walk backwards and
'   to delete a node when you only have a pointer to it (no need
'   to search for the one before it).
'
'   Songs are stored in an array of TYPE records. "Pointers" are
'   array indexes, 0 meaning none. Deleted songs go onto a free
'   list so their slots get reused.
'
' HOW TO USE
'   Right/Down arrow or N = next song   Left/Up arrow or P = previous
'   U = move current song up      D = move current song down
'   X = delete current song       A = add a song after current
'   R = show list in reverse      Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * prev/next links and keeping BOTH in sync on every change
'   * Unlinking a node in O(1) time
'   * Swapping neighbours by re-linking instead of copying data
'   * Reading arrow keys: INKEY$ returns CHR$(0) + scan code
'
' THINGS TO TRY
'   * Add a "shuffle" command
'   * Make the playlist circular (tail.nxt = head) for repeat mode
' ============================================================

' DEFINT A-Z makes every untyped variable an INTEGER. Our SUBs take
' INTEGER parameters, and BASIC insists the argument types match.
DEFINT A-Z

DECLARE SUB Unlink (i AS INTEGER)
DECLARE SUB InsertAfter (a AS INTEGER, i AS INTEGER)
DECLARE FUNCTION Alloc% (t$)
DECLARE SUB Draw1 ()

TYPE Song
    title AS STRING * 28
    prv AS INTEGER
    nxt AS INTEGER
END TYPE

CONST MAXS = 20
DIM SHARED s(1 TO MAXS) AS Song
DIM SHARED head AS INTEGER, tail AS INTEGER, freeHead AS INTEGER
DIM SHARED cur AS INTEGER, info$

' Put every slot on the free list (singly linked through nxt).
FOR i = 1 TO MAXS - 1: s(i).nxt = i + 1: NEXT i
freeHead = 1

' Load the starting playlist, appending each song at the tail.
FOR i = 1 TO 7
    READ t$
    InsertAfter tail, Alloc%(t$)
NEXT i
DATA "Twinkle Twinkle Little Star", "Fur Elise", "Ode to Joy"
DATA "Greensleeves", "The Entertainer", "Canon in D", "Minuet in G"
cur = head
info$ = "Use arrows to move around the playlist."

DO
    Draw1
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    ' Arrow keys arrive as two characters: CHR$(0) then a code.
    ' 72=Up 80=Down 75=Left 77=Right
    IF LEN(k$) = 2 THEN
        SELECT CASE ASC(RIGHT$(k$, 1))
            CASE 72, 75: k$ = "P"
            CASE 80, 77: k$ = "N"
        END SELECT
    END IF
    info$ = ""
    SELECT CASE UCASE$(k$)
    CASE "N"
        IF cur <> 0 THEN IF s(cur).nxt <> 0 THEN cur = s(cur).nxt
    CASE "P"
        IF cur <> 0 THEN IF s(cur).prv <> 0 THEN cur = s(cur).prv
    CASE "U"
        ' Move up = take the node out and put it back in front of
        ' its old previous neighbour (i.e. after prev's prev).
        IF cur <> 0 THEN
            p = s(cur).prv
            IF p <> 0 THEN
                pp = s(p).prv
                Unlink cur
                InsertAfter pp, cur
            END IF
        END IF
    CASE "D"
        ' Move down = take it out and re-insert after the old next.
        IF cur <> 0 THEN
            nx = s(cur).nxt
            IF nx <> 0 THEN Unlink cur: InsertAfter nx, cur
        END IF
    CASE "X"
        IF cur <> 0 THEN
            victim = cur
            ' Pick a new current song: next if possible, else previous.
            IF s(cur).nxt <> 0 THEN cur = s(cur).nxt ELSE cur = s(cur).prv
            info$ = "Deleted " + RTRIM$(s(victim).title)
            Unlink victim
            ' Return the slot to the free list.
            s(victim).nxt = freeHead: freeHead = victim
        END IF
    CASE "A"
        LOCATE 23, 1: LINE INPUT "New song title: "; t$
        IF t$ <> "" THEN
            n = Alloc%(t$)
            IF n = 0 THEN info$ = "Playlist full!" ELSE InsertAfter cur, n: cur = n
        END IF
    CASE "R"
        ' Walking backwards is only possible because of prv links.
        info$ = "Reverse:"
        p = tail
        DO WHILE p <> 0
            info$ = info$ + " <" + LEFT$(s(p).title, 6) + ">"
            p = s(p).prv
        LOOP
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
CLS : PRINT "Playlist closed."
END

' Alloc: grab a free slot and store the title. 0 if none left.
FUNCTION Alloc% (t$)
    IF freeHead = 0 THEN Alloc% = 0: EXIT FUNCTION
    i = freeHead: freeHead = s(i).nxt
    s(i).title = t$: s(i).prv = 0: s(i).nxt = 0
    Alloc% = i
END FUNCTION

' Draw1: show the list from head to tail with prev/next numbers.
SUB Draw1
    CLS
    PRINT "  PLAYLIST - doubly linked list"
    PRINT "  slot  prev  next  title"
    PRINT "  ----  ----  ----  ----------------------------"
    p = head
    DO WHILE p <> 0
        IF p = cur THEN COLOR 14: PRINT ">"; ELSE COLOR 7: PRINT " ";
        PRINT USING " ##    ##    ##   &"; p; s(p).prv; s(p).nxt; s(p).title
        p = s(p).nxt
    LOOP
    COLOR 7
    PRINT
    PRINT "  head ="; head; "  tail ="; tail; "  free list starts at"; freeHead
    IF cur THEN PRINT "  Now playing: "; RTRIM$(s(cur).title)
    LOCATE 21, 1: PRINT LEFT$(info$, 79)
    LOCATE 22, 1: PRINT "N/P/arrows=move  U/D=reorder  A=add  X=delete  R=reverse  Q=quit";
END SUB

' InsertAfter: link node i in right after node a.
' a = 0 means "insert at the very front".
SUB InsertAfter (a AS INTEGER, i AS INTEGER)
    IF i = 0 THEN EXIT SUB
    IF a = 0 THEN
        s(i).prv = 0
        s(i).nxt = head
        IF head <> 0 THEN s(head).prv = i ELSE tail = i
        head = i
    ELSE
        b = s(a).nxt               ' the node that will come after i
        s(i).prv = a: s(i).nxt = b
        s(a).nxt = i
        IF b <> 0 THEN s(b).prv = i ELSE tail = i
    END IF
END SUB

' Unlink: remove node i from the list. Four links may change:
' the neighbour on each side, or head/tail when i is at an end.
SUB Unlink (i AS INTEGER)
    p = s(i).prv: n = s(i).nxt
    IF p <> 0 THEN s(p).nxt = n ELSE head = n
    IF n <> 0 THEN s(n).prv = p ELSE tail = p
    s(i).prv = 0: s(i).nxt = 0
END SUB
