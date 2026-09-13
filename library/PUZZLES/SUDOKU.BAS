' ============================================================
' TITLE:    Sudoku Solver & Generator
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     sudoku, backtracking, recursion, bitmasks, generator
' SUMMARY:  Solves any Sudoku with smart backtracking and builds brand-new puzzles that have exactly one answer.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Sudoku is a 9x9 grid split into nine 3x3 boxes.  Every row,
'   every column and every box must contain the digits 1-9 once.
'   This program can:
'     1. solve one of three built-in puzzles,
'     2. GENERATE a fresh puzzle (and prove it has a unique answer),
'     3. solve a puzzle that you type in yourself.
'   It reports how many "search nodes" (guesses) it needed.
'
' HOW TO USE
'   Pick a menu option by typing its number and pressing Enter.
'   When typing your own puzzle, enter 9 rows of 9 characters,
'   using 0 or . for empty squares, e.g.  53..7....
'   Type Q at any prompt to go back / quit.
'
' CONCEPTS YOU WILL LEARN
'   * Recursive backtracking: guess, recurse, undo the guess
'   * Bitmasks: one INTEGER remembers which digits a row has used
'   * The "most constrained cell first" heuristic (MRV)
'   * Counting solutions to prove a puzzle is unique
'   * Generating puzzles by removing clues from a full grid
'
' THINGS TO TRY
'   * Turn off the MRV heuristic (always pick the first empty cell)
'     and compare the node counts.
'   * Make the generator stop at 30 clues for easier puzzles.
'   * Add a "hint" option that fills just one square.
' ============================================================
DECLARE SUB Search ()
DECLARE SUB Place (c AS INTEGER, d AS INTEGER)
DECLARE SUB Unplace (c AS INTEGER, d AS INTEGER)
DECLARE SUB ShowGrid (title$, which AS INTEGER)
DECLARE SUB LoadBuiltIn (n AS INTEGER)
DECLARE SUB Generate ()
DECLARE SUB ClearAll ()
DECLARE SUB SolveAndShow ()
DECLARE FUNCTION TypeIn% ()
DEFINT A-Z

' ---- The board -------------------------------------------------
' Cells are numbered 0..80, left to right, top to bottom.
' Row  = c \ 9      Column = c MOD 9
' Box  = (row \ 3) * 3 + (column \ 3)
DIM SHARED g(80)            ' current grid, 0 = empty
DIM SHARED given(80)        ' 1 if the square was a clue in the puzzle
DIM SHARED sol(80)          ' first solution found is copied here

' ---- Bitmasks --------------------------------------------------
' rowM(r) has bit d set (value 2^d) if digit d is already used in
' row r.  Same idea for columns and boxes.  Checking whether digit d
' is legal in a cell then takes ONE test instead of 27 comparisons.
DIM SHARED rowM(8), colM(8), boxM(8)
DIM SHARED pw(9)            ' pw(d) = 2^d, precomputed
DIM SHARED bc(1023)         ' bc(m) = how many bits are set in m
' Lookup tables: which row / column / box each cell belongs to.
' Looking a number up is faster than dividing every time.
DIM SHARED rr(80), cc(80), bb(80)

DIM SHARED solutions        ' how many solutions found so far
DIM SHARED limit            ' stop searching after this many
DIM SHARED randomOrder      ' -1 = try digits in a random order
DIM SHARED nodes&           ' search-tree nodes visited
DIM SHARED aborted          ' -1 if the user pressed Esc mid-search

' Precompute the power and bit-count tables once.
FOR d = 0 TO 9: pw(d) = 2 ^ d: NEXT
FOR m = 1 TO 1023
    bc(m) = bc(m \ 2) + (m AND 1)   ' bits(m) = bits(m/2) + lowest bit
NEXT
FOR c = 0 TO 80
    rr(c) = c \ 9: cc(c) = c MOD 9: bb(c) = (rr(c) \ 3) * 3 + cc(c) \ 3
NEXT
RANDOMIZE TIMER

' ---- Main menu ---------------------------------------------------
DO
    CLS
    COLOR 14: PRINT "  SUDOKU SOLVER & GENERATOR": COLOR 7
    PRINT
    PRINT "  1) Solve built-in puzzle: Easy"
    PRINT "  2) Solve built-in puzzle: Hard"
    PRINT "  3) Solve built-in puzzle: 'World's hardest' (slow! ~25000 nodes)"
    PRINT "  4) Generate a brand-new puzzle"
    PRINT "  5) Type in your own puzzle"
    PRINT "  Q) Quit"
    PRINT
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(RTRIM$(a$)))
    IF INSTR(a$, "Q") > 0 OR INSTR(a$, CHR$(27)) > 0 THEN EXIT DO
    SELECT CASE a$
        CASE "1", "2", "3"
            LoadBuiltIn VAL(a$)
            SolveAndShow
        CASE "4"
            Generate
        CASE "5"
            IF TypeIn% THEN SolveAndShow
        CASE ELSE
            PRINT "  Please type 1-5 or Q.": PRINT
    END SELECT
    IF a$ >= "1" AND a$ <= "5" THEN
        PRINT : LINE INPUT "  Press Enter for the menu (Q quits) "; k$
        IF INSTR(UCASE$(k$), "Q") > 0 THEN EXIT DO
    END IF
LOOP
CLS : PRINT "Bye!"
END

' Built-in puzzles: each is 81 characters, "." = empty.
PUZZLES:
DATA "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"
DATA "..9748...7.........2.1.9.....7...24..64.1.59..98...3.....8.3.2.........6...2759.."
DATA "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4.."

SUB ClearAll
    ' Empty the board and reset every bitmask.
    FOR c = 0 TO 80: g(c) = 0: given(c) = 0: NEXT
    FOR i = 0 TO 8: rowM(i) = 0: colM(i) = 0: boxM(i) = 0: NEXT
END SUB

SUB Generate
    ' Step 1: make a random COMPLETE grid.  We drop a shuffled 1..9
    ' into the top-left box, then let the solver fill the rest in a
    ' random digit order.
    ClearAll
    DIM p(8)
    FOR i = 0 TO 8: p(i) = i + 1: NEXT
    FOR i = 8 TO 1 STEP -1               ' Fisher-Yates shuffle
        j = INT(RND * (i + 1)): SWAP p(i), p(j)
    NEXT
    FOR i = 0 TO 8: Place (i \ 3) * 9 + (i MOD 3), p(i): NEXT
    solutions = 0: limit = 1: randomOrder = -1: nodes& = 0: aborted = 0
    Search
    FOR c = 0 TO 80: g(c) = 0: NEXT
    FOR i = 0 TO 8: rowM(i) = 0: colM(i) = 0: boxM(i) = 0: NEXT
    FOR c = 0 TO 80: Place c, sol(c): NEXT
    randomOrder = 0

    ' Step 2: visit the cells in random order and try to erase each.
    ' If the puzzle still has exactly ONE solution, keep it erased;
    ' otherwise put the digit back.  The result is "minimal-ish".
    DIM order(80)
    FOR i = 0 TO 80: order(i) = i: NEXT
    FOR i = 80 TO 1 STEP -1
        j = INT(RND * (i + 1)): SWAP order(i), order(j)
    NEXT
    clues = 81
    CLS : PRINT "Generating: removing clues while the answer stays unique..."
    FOR i = 0 TO 80
        c = order(i): d = g(c)
        Unplace c, d
        solutions = 0: limit = 2       ' we only need to know: 1 or more?
        Search
        IF solutions = 1 THEN
            clues = clues - 1
        ELSE
            Place c, d                  ' removing it broke uniqueness
        END IF
        LOCATE 3, 1: PRINT "Cells tried:"; i + 1; "  clues left:"; clues; "  "
        IF INKEY$ = CHR$(27) OR aborted THEN EXIT FOR
    NEXT
    FOR c = 0 TO 80: given(c) = -(g(c) > 0): NEXT
    ShowGrid "Your new puzzle (" + LTRIM$(STR$(clues)) + " clues)", 0
    PRINT : LINE INPUT "  Press Enter to see the solution "; k$
    SolveAndShow
END SUB

SUB LoadBuiltIn (n AS INTEGER)
    ' Skip to the n-th DATA string and copy its digits into the grid.
    ClearAll
    RESTORE PUZZLES
    FOR i = 1 TO n: READ s$: NEXT
    FOR c = 0 TO 80
        d = VAL(MID$(s$, c + 1, 1))     ' VAL(".") is 0 = empty
        IF d > 0 THEN Place c, d: given(c) = 1
    NEXT
END SUB

SUB Place (c AS INTEGER, d AS INTEGER)
    ' Put digit d in cell c and mark it used in its row, column, box.
    r = c \ 9: k = c MOD 9: b = (r \ 3) * 3 + k \ 3
    g(c) = d
    rowM(r) = rowM(r) OR pw(d)
    colM(k) = colM(k) OR pw(d)
    boxM(b) = boxM(b) OR pw(d)
END SUB

SUB Search
    ' The heart of the program: recursive backtracking.
    IF solutions >= limit THEN EXIT SUB
    nodes& = nodes& + 1
    ' Every 1000 nodes show progress and let the user give up with Esc.
    ' Setting limit to 0 makes every level of the recursion stop.
    IF nodes& MOD 1000 = 0 THEN
        LOCATE 25, 3: PRINT "nodes so far:"; nodes&; " (Esc = give up)";
        IF INKEY$ = CHR$(27) THEN aborted = -1: limit = 0: EXIT SUB
    END IF

    ' 1. Find the empty cell with the FEWEST legal digits (MRV).
    '    A cell with only one choice is forced; a cell with zero
    '    choices means an earlier guess was wrong -> back up.
    best = -1: bestCnt = 10
    FOR c = 0 TO 80
        IF g(c) = 0 THEN
            ' Digits NOT used in row, column or box.  1022 = bits 1..9.
            av = 1022 AND NOT (rowM(rr(c)) OR colM(cc(c)) OR boxM(bb(c)))
            n = bc(av)
            IF n < bestCnt THEN
                best = c: bestCnt = n: bestAv = av
                IF bestCnt <= 1 THEN EXIT FOR
            END IF
        END IF
    NEXT

    ' 2. No empty cell at all?  Then the grid is solved!
    IF best = -1 THEN
        solutions = solutions + 1
        IF solutions = 1 THEN
            FOR c = 0 TO 80: sol(c) = g(c): NEXT
        END IF
        EXIT SUB
    END IF
    IF bestCnt = 0 THEN EXIT SUB        ' dead end

    ' 3. Try each legal digit, recurse, then UNDO (the "backtrack").
    start = 0
    IF randomOrder THEN start = INT(RND * 9)
    FOR t = 0 TO 8
        d = (start + t) MOD 9 + 1
        IF bestAv AND pw(d) THEN
            Place best, d
            Search
            Unplace best, d
            IF solutions >= limit THEN EXIT FOR
        END IF
    NEXT
END SUB

SUB ShowGrid (title$, which AS INTEGER)
    ' Draw the board.  which = 0 shows g(), which = 1 shows sol().
    ' Clues are white, digits found by the solver are bright green.
    CLS
    COLOR 14: PRINT "  "; title$: COLOR 7
    PRINT
    FOR r = 0 TO 8
        IF r MOD 3 = 0 THEN PRINT "  +-------+-------+-------+"
        PRINT "  ";
        FOR k = 0 TO 8
            IF k MOD 3 = 0 THEN COLOR 7: PRINT "| ";
            c = r * 9 + k
            IF which THEN d = sol(c) ELSE d = g(c)
            IF d = 0 THEN
                COLOR 8: PRINT ". ";
            ELSEIF given(c) THEN
                COLOR 15: PRINT CHR$(48 + d); " ";
            ELSE
                COLOR 10: PRINT CHR$(48 + d); " ";
            END IF
        NEXT
        COLOR 7: PRINT "|"
    NEXT
    PRINT "  +-------+-------+-------+"
END SUB

SUB SolveAndShow
    ShowGrid "Puzzle", 0
    PRINT : PRINT "  Solving..."
    solutions = 0: limit = 2: randomOrder = 0: nodes& = 0
    t! = TIMER: aborted = 0
    Search
    LOCATE 25, 1: PRINT SPACE$(60);
    IF aborted THEN PRINT : PRINT "  Search abandoned after"; nodes&; "nodes.": EXIT SUB
    ' We asked for up to 2 solutions so we can warn about bad puzzles.
    IF solutions = 0 THEN
        PRINT "  This puzzle has NO solution (check your typing)."
        EXIT SUB
    END IF
    ShowGrid "Solved!", 1
    PRINT
    PRINT "  Search nodes visited:"; nodes&
    PRINT USING "  Time: ##.## seconds"; TIMER - t!
    IF solutions > 1 THEN
        COLOR 12: PRINT "  Warning: more than one solution exists - not a proper Sudoku.": COLOR 7
    ELSE
        PRINT "  The solution is unique."
    END IF
END SUB

FUNCTION TypeIn%
    ' Read 9 rows from the keyboard.  Returns -1 if all went well.
    ClearAll
    TypeIn% = 0
    PRINT "  Enter 9 rows of 9 characters (digits, 0 or . for blank), Q to cancel."
    FOR r = 0 TO 8
        DO
            PRINT "  Row"; r + 1;
            LINE INPUT ": "; s$
            s$ = UCASE$(LTRIM$(RTRIM$(s$)))
            IF INSTR(s$, "Q") > 0 OR INSTR(s$, CHR$(27)) > 0 THEN EXIT FUNCTION
            ok = (LEN(s$) = 9)
            IF ok THEN
                FOR k = 1 TO 9
                    ch$ = MID$(s$, k, 1)
                    IF INSTR("0123456789.", ch$) = 0 THEN ok = 0
                NEXT
            END IF
            IF NOT ok THEN PRINT "  Need exactly 9 characters from 0-9 or '.'"
        LOOP UNTIL ok
        FOR k = 0 TO 8
            d = VAL(MID$(s$, k + 1, 1)): c = r * 9 + k
            IF d > 0 THEN
                ' Refuse digits that clash with ones already entered.
                b = (r \ 3) * 3 + k \ 3
                IF (rowM(r) OR colM(k) OR boxM(b)) AND pw(d) THEN
                    PRINT "  Digit"; d; "clashes at row"; r + 1; "col"; k + 1; "- ignored."
                ELSE
                    Place c, d: given(c) = 1
                END IF
            END IF
        NEXT
    NEXT
    TypeIn% = -1
END FUNCTION

SUB Unplace (c AS INTEGER, d AS INTEGER)
    ' Exact opposite of Place: clear the cell and the three bits.
    r = c \ 9: k = c MOD 9: b = (r \ 3) * 3 + k \ 3
    g(c) = 0
    rowM(r) = rowM(r) AND NOT pw(d)
    colM(k) = colM(k) AND NOT pw(d)
    boxM(b) = boxM(b) AND NOT pw(d)
END SUB
