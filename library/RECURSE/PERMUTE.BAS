' ============================================================
' TITLE:    All Permutations (Backtracking)
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, permutations, backtracking, swap, combinatorics
' SUMMARY:  Lists every ordering of a word using choose-recurse-undo backtracking, and shows why n letters give n! results.
' ------------------------------------------------------------
' WHAT IT DOES
'   A permutation is one possible ordering of some items.  ABC has
'   6: ABC ACB BAC BCA CBA CAB.  The recursive recipe:
'     For each position k (from left to right):
'       try each remaining letter in position k   (CHOOSE)
'       permute the positions after k             (RECURSE)
'       put the letter back where it was          (UNDO)
'   The "undo" step is what makes this BACKTRACKING: after exploring
'   one choice, we restore the exact state so the next choice starts
'   clean.  Results are printed in columns with a running count.
'
' HOW TO USE
'   Enter a word of 1 to 6 letters (6 letters = 720 results).
'   Empty input quits.
'
'   DEBUGGER TOUR
'   1. Use ABC.  Break on <<< BREAK CHOOSE.  Watch k, i and the
'      SHARED string w$ in the Variables panel.
'   2. Open the CALL STACK when a result prints: Permute(1) ->
'      Permute(2) -> Permute(3) -> Permute(4).  Each frame has its own
'      i: that is how each level remembers "which letter am I
'      trying right now?"
'   3. Break on <<< BREAK UNDO and compare w$ before and after the
'      SWAP.  Then comment out the UNDO swap (save first) and run:
'      the output now has duplicates and misses some orderings.
'      Forgetting to undo is the #1 backtracking bug.
'
' CONCEPTS YOU WILL LEARN
'   * Backtracking: choose, explore, un-choose
'   * Each recursion level keeps its own loop counter
'   * n! grows very fast: 1, 2, 6, 24, 120, 720, 5040 ...
'   * Swapping characters in a string with MID$ (statement form)
'
' THINGS TO TRY
'   * Use a word with a repeated letter like  BOOK.  You get
'     duplicates.  Can you skip a letter that was already tried at
'     this level?
'   * Only print permutations that are real anagrams of a word list.
' ============================================================
DECLARE SUB Permute (k AS INTEGER)
DECLARE SUB SwapChars (i AS INTEGER, j AS INTEGER)

DIM SHARED w$                  ' the word being rearranged in place
DIM SHARED count AS LONG

CLS
PRINT "ALL PERMUTATIONS OF A WORD"
PRINT
DO
    LINE INPUT "Word (1-6 letters, Enter quits): "; w$
    w$ = UCASE$(LTRIM$(RTRIM$(w$)))
    IF w$ = "" THEN EXIT DO
    IF LEN(w$) > 6 THEN w$ = LEFT$(w$, 6): PRINT "(using "; w$; ")"
    count = 0
    Permute 1
    PRINT
    PRINT count; "permutations.  "; LEN(w$); "! ="; count
    PRINT
LOOP
PRINT "Bye!"
END

' Fill positions k..LEN(w$) in every possible way.
SUB Permute (k AS INTEGER)
    DIM i AS INTEGER
    IF k > LEN(w$) THEN
        ' Every position is decided: print one finished arrangement.
        count = count + 1
        PRINT w$; " ";
        IF POS(0) > 72 THEN PRINT
        EXIT SUB
    END IF
    FOR i = k TO LEN(w$)
        SwapChars k, i                  ' <<< BREAK CHOOSE: letter i goes to spot k
        Permute k + 1                   ' arrange everything after k
        SwapChars k, i                  ' <<< BREAK UNDO: put it back
    NEXT i
END SUB

' Swap two characters of w$ using the MID$ statement.
SUB SwapChars (i AS INTEGER, j AS INTEGER)
    IF i = j THEN EXIT SUB
    a$ = MID$(w$, i, 1)
    MID$(w$, i, 1) = MID$(w$, j, 1)
    MID$(w$, j, 1) = a$
END SUB
