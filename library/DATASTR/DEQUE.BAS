' ============================================================
' TITLE:    Double-Ended Queue (Deque)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     deque, circular buffer, palindrome, sliding window
' SUMMARY:  A deque that adds and removes at both ends, used to check palindromes and find sliding-window maximums.
' ------------------------------------------------------------
' WHAT IT DOES
'   A DEQUE ("deck") is a queue that works at BOTH ends: you can
'   push or pop at the front and at the back. It can act as a
'   stack, a queue, or both at once.
'
'   The deque lives in a circular array (see QUEUE.BAS). Moving
'   the front BACKWARDS needs a wrap too: (front - 1 + SIZE) MOD SIZE
'   keeps the index from going negative.
'
'   Demo 1 shows the four basic operations step by step.
'   Demo 2 finds the biggest value in every window of 3 numbers
'          using the famous "monotonic deque" trick.
'   Demo 3 checks your phrases for palindromes by popping letters
'          off both ends and comparing them.
'
' HOW TO USE
'   Press a key between demos. In demo 3 type phrases such as
'   "Never odd or even". Type a blank line or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Circular indexing in both directions
'   * Implementing four operations with shared state
'   * Using a deque of INDEXES to solve a real problem fast
'
' THINGS TO TRY
'   * Change the window size W in demo 2
'   * Make demo 3 ignore digits as well as punctuation
' ============================================================

' DEFINT A-Z makes every untyped variable an INTEGER. Our SUBs take
' INTEGER parameters, and BASIC insists the argument types match.
DEFINT A-Z

DECLARE SUB PushFront (v AS INTEGER)
DECLARE SUB PushBack (v AS INTEGER)
DECLARE FUNCTION PopFront% ()
DECLARE FUNCTION PopBack% ()
DECLARE FUNCTION PeekFront% ()
DECLARE FUNCTION PeekBack% ()
DECLARE SUB ShowDeque (label$)
DECLARE SUB ClearDeque ()
DECLARE SUB WaitKey ()

CONST DSIZE = 80
DIM SHARED dq(0 TO DSIZE - 1) AS INTEGER
' front = index of first item, n = number of items.
' The back item lives at (front + n - 1) MOD DSIZE, so we only
' need these two numbers to know everything.
DIM SHARED front AS INTEGER, n AS INTEGER

CLS
PRINT "=== DEMO 1: the four deque operations ==="
PRINT
ClearDeque
PushBack 10: ShowDeque "PushBack 10"
PushBack 20: ShowDeque "PushBack 20"
PushFront 5: ShowDeque "PushFront 5"
PushFront 1: ShowDeque "PushFront 1"
x = PopBack%: ShowDeque "PopBack  -> got" + STR$(x)
x = PopFront%: ShowDeque "PopFront -> got" + STR$(x)
PRINT
PRINT "Notice front moved BACKWARDS past slot 0 and wrapped to"; DSIZE - 1
PRINT "when we did PushFront - that's the circular trick."
WaitKey

' ---------------------------------------------------------------
' DEMO 2: sliding window maximum.
' For each window of W numbers we want the largest. The slow way
' re-scans W numbers per window. The deque way keeps INDEXES of
' "useful" numbers in decreasing order of value:
'   * Before adding a new number, pop smaller numbers off the BACK
'     (they can never be a maximum again - the new one is bigger
'     and will stay in the window longer).
'   * Pop the FRONT if it has slid out of the window.
'   * The front is then always the maximum of the current window.
' Each index is pushed and popped at most once: very fast.
' ---------------------------------------------------------------
CLS
PRINT "=== DEMO 2: maximum of every window of 3 numbers ==="
PRINT
CONST W = 3
DIM a(1 TO 12) AS INTEGER
FOR i = 1 TO 12: READ a(i): NEXT i
DATA 4, 2, 12, 3, 8, 1, 7, 7, 2, 9, 5, 6
PRINT "Numbers: ";
FOR i = 1 TO 12: PRINT a(i); : NEXT i
PRINT : PRINT
ClearDeque
FOR i = 1 TO 12
    ' Throw away smaller values from the back.
    DO WHILE n > 0
        IF a(PeekBack%) <= a(i) THEN x = PopBack% ELSE EXIT DO
    LOOP
    PushBack i                       ' store the INDEX, not the value
    ' Drop the front if it is no longer inside the window.
    IF PeekFront% <= i - W THEN x = PopFront%
    IF i >= W THEN
        PRINT USING "Window ## to ##:"; i - W + 1; i;
        FOR j = i - W + 1 TO i: PRINT a(j); : NEXT j
        PRINT TAB(36); "max ="; a(PeekFront%)
    END IF
NEXT i
WaitKey

' ---------------------------------------------------------------
' DEMO 3: palindrome checker.
' Load only the letters into the deque, then repeatedly pop one
' from each end. If any pair differs, it's not a palindrome.
' ---------------------------------------------------------------
CLS
PRINT "=== DEMO 3: palindrome checker ==="
PRINT "Try: racecar, Never odd or even, Was it a car or a cat I saw"
DO
    PRINT
    LINE INPUT "Phrase (blank = quit): "; p$
    IF p$ = "" OR UCASE$(p$) = "Q" THEN EXIT DO
    ClearDeque
    FOR i = 1 TO LEN(p$)
        c$ = UCASE$(MID$(p$, i, 1))
        ' Keep letters only; ASC gives the character code.
        IF c$ >= "A" AND c$ <= "Z" AND n < DSIZE THEN PushBack ASC(c$)
    NEXT i
    ok = -1                          ' -1 is TRUE in BASIC
    DO WHILE n > 1
        l = PopFront%: r = PopBack%
        PRINT CHR$(l); "="; CHR$(r); " ";
        IF l <> r THEN ok = 0: EXIT DO
    LOOP
    PRINT
    IF ok THEN PRINT "-> YES, a palindrome!" ELSE PRINT "-> no, not a palindrome."
LOOP
PRINT "Bye!"
END

SUB ClearDeque
    front = 0: n = 0
END SUB

FUNCTION PeekBack%
    PeekBack% = dq((front + n - 1) MOD DSIZE)
END FUNCTION

FUNCTION PeekFront%
    PeekFront% = dq(front)
END FUNCTION

FUNCTION PopBack%
    ' The back is the last of n items; shrinking n removes it.
    PopBack% = dq((front + n - 1) MOD DSIZE)
    n = n - 1
END FUNCTION

FUNCTION PopFront%
    PopFront% = dq(front)
    front = (front + 1) MOD DSIZE
    n = n - 1
END FUNCTION

SUB PushBack (v AS INTEGER)
    IF n = DSIZE THEN EXIT SUB       ' full: silently ignore
    dq((front + n) MOD DSIZE) = v
    n = n + 1
END SUB

SUB PushFront (v AS INTEGER)
    IF n = DSIZE THEN EXIT SUB
    ' Step front back one slot. Adding DSIZE first keeps it >= 0,
    ' because in BASIC (-1) MOD 80 is -1, not 79.
    front = (front - 1 + DSIZE) MOD DSIZE
    dq(front) = v
    n = n + 1
END SUB

' Print the deque contents front-to-back with its indexes.
SUB ShowDeque (label$)
    PRINT LEFT$(label$ + SPACE$(24), 24); "front="; front; " [";
    FOR i = 0 TO n - 1
        PRINT dq((front + i) MOD DSIZE);
    NEXT i
    PRINT " ]"
END SUB

SUB WaitKey
    PRINT
    PRINT "Press any key to continue...";
    k$ = INPUT$(1)
END SUB
