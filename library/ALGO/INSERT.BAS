' ============================================================
' TITLE:    Insertion Sort and Shell Sort
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     sorting, arrays, step-by-step, complexity
' SUMMARY:  Step through insertion sort like sorting playing cards, then see how Shell sort's gaps make it much faster.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 sorts 10 numbers with INSERTION SORT and prints the array
'   after every step.  The number being inserted (the "key") is shown
'   in yellow and the sorted part on the left is shown in green.
'   Part 2 sorts the same kind of list with SHELL SORT, printing the
'   array after each "gap" pass.
'   Part 3 counts how many element moves each algorithm needs for
'   1000 random numbers, so you can see the difference in work.
'
' HOW TO USE
'   Press any key to advance one step.  Esc quits at any time.
'
' CONCEPTS YOU WILL LEARN
'   * Insertion sort: grow a sorted region one element at a time
'   * Shifting elements right instead of swapping
'   * Shell sort = insertion sort on elements that are "gap" apart
'   * Gap sequences (Knuth: 1, 4, 13, 40, 121, ...)
'   * Best/worst case: O(n) on sorted data, O(n^2) on reversed data
'
' THINGS TO TRY
'   * Change the gap sequence to halving (n\2, n\4, ... 1)
'   * Feed already-sorted data to Part 3 and compare the counts
' ============================================================
DECLARE SUB ShowArr (title$, lo%, keyPos%, sortedTo%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST N = 10
DIM SHARED a(1 TO N)
RANDOMIZE TIMER
COLOR 7, 0: CLS

' =============== PART 1: INSERTION SORT ======================
' Think of a hand of cards.  You pick up cards one at a time and
' slide each new card left until it sits just after a smaller card.
' The cards to the left of the new one are ALWAYS already sorted.
'
'   for i = 2 to n
'       key = a(i)                  ' the card we pick up
'       j = i - 1
'       while j >= 1 and a(j) > key ' bigger cards move right
'           a(j+1) = a(j) : j = j - 1
'       a(j+1) = key                ' drop the card in the gap
'
' Complexity: worst case (reversed list) every key slides all the
' way left: 1+2+...+(n-1) = n(n-1)/2 moves  -> O(n^2).
' Best case (already sorted) no key moves at all -> O(n).
' It is "stable" (equal items keep their order) and sorts in place.
FOR i = 1 TO N: a(i) = INT(RND * 90) + 10: NEXT
PRINT "PART 1 - INSERTION SORT  (yellow = key, green = sorted part)"
PRINT
ShowArr "start ", 1, 0, 1
FOR i = 2 TO N
    kv = a(i)                    ' "kv" = key value (KEY is a reserved word)
    j = i - 1
    ' QBasic evaluates BOTH sides of AND, so we must not read a(0).
    ' We use a flag loop instead of "WHILE j >= 1 AND a(j) > key".
    DO WHILE j >= 1
        IF a(j) <= kv THEN EXIT DO
        a(j + 1) = a(j)          ' shift the bigger value one place right
        j = j - 1
    LOOP
    a(j + 1) = kv               ' insert the key value (kv) into the hole
    ShowArr "i =" + STR$(i), 1, j + 1, i
    WaitKey
NEXT
PRINT : PRINT "Sorted!  Press a key for Shell sort..."
WaitKey

' =============== PART 2: SHELL SORT ==========================
' Insertion sort is slow because an element can only move ONE place
' per step.  Donald Shell (1959) had an idea: first do insertion
' sort on items that are far apart (a "gap" of h), so small values
' can leap long distances toward the front.  Then shrink the gap.
' The last pass always uses gap 1, which is plain insertion sort -
' but by then the list is "almost sorted", where insertion sort is
' very fast.  With Knuth's gaps (1,4,13,40..) it runs in roughly
' O(n^1.5) - a big win over O(n^2).
CLS
FOR i = 1 TO N: a(i) = INT(RND * 90) + 10: NEXT
PRINT "PART 2 - SHELL SORT (gaps 4 then 1)"
PRINT
ShowArr "start ", 1, 0, 0
h = 1
DO WHILE h * 3 + 1 < N: h = h * 3 + 1: LOOP    ' biggest Knuth gap < N
DO WHILE h >= 1
    FOR i = 1 + h TO N                 ' an insertion sort with step h
        kv = a(i)
        j = i - h
        DO WHILE j >= 1
            IF a(j) <= kv THEN EXIT DO
            a(j + h) = a(j)
            j = j - h
        LOOP
        a(j + h) = kv
    NEXT
    ShowArr "gap" + STR$(h), 1, 0, 0
    WaitKey
    h = h \ 3                          ' next smaller gap: 13->4->1->0
LOOP
PRINT : PRINT "Sorted!  Press a key to compare the work on 1000 numbers..."
WaitKey

' =============== PART 3: COUNTING THE WORK ===================
CLS
CONST BIG = 1000
DIM b(1 TO BIG), c(1 TO BIG)
FOR i = 1 TO BIG: b(i) = INT(RND * 30000): c(i) = b(i): NEXT
PRINT "PART 3 - moving 1000 random numbers"
PRINT
' -- insertion sort on b(), counting moves --
moves& = 0
FOR i = 2 TO BIG
    kv = b(i): j = i - 1
    DO WHILE j >= 1
        IF b(j) <= kv THEN EXIT DO
        b(j + 1) = b(j): j = j - 1: moves& = moves& + 1
    LOOP
    b(j + 1) = kv
NEXT
PRINT USING "Insertion sort moves: #########"; moves&
' -- shell sort on c(), counting moves --
moves2& = 0
h = 1
DO WHILE h * 3 + 1 < BIG: h = h * 3 + 1: LOOP
DO WHILE h >= 1
    FOR i = 1 + h TO BIG
        kv = c(i): j = i - h
        DO WHILE j >= 1
            IF c(j) <= kv THEN EXIT DO
            c(j + h) = c(j): j = j - h: moves2& = moves2& + 1
        LOOP
        c(j + h) = kv
    NEXT
    h = h \ 3
LOOP
PRINT USING "Shell sort moves:     #########"; moves2&
PRINT
PRINT "Expected for insertion sort: about n*n/4 ="; CLNG(BIG) * BIG \ 4
IF moves2& > 0 THEN PRINT USING "Shell sort did ##.#x less work."; moves& / moves2&
' quick sanity check that both really are sorted
ok = -1
FOR i = 2 TO BIG
    IF b(i - 1) > b(i) OR c(i - 1) > c(i) THEN ok = 0
NEXT
IF ok THEN PRINT "Both arrays verified sorted." ELSE PRINT "Something went wrong!"
PRINT : PRINT "Press any key to quit."
WaitKey
END

' Prints one line: a label and the array.  Elements 1..sortedTo are
' green, element keyPos is yellow, others grey.
SUB ShowArr (title$, lo, keyPos, sortedTo)
    COLOR 7: PRINT LEFT$(title$ + SPACE$(8), 8); ": ";
    FOR k = lo TO N
        IF k = keyPos THEN
            COLOR 14
        ELSEIF k <= sortedTo THEN
            COLOR 10
        ELSE
            COLOR 7
        END IF
        PRINT USING "### "; a(k);
    NEXT
    COLOR 7: PRINT
END SUB

' Wait for a key.  Esc ends the program immediately.
SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN COLOR 7, 0: END
END SUB
