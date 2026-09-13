' ============================================================
' TITLE:    Nonogram Player & Checker
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     nonogram, picross, run-length, game, strings, validation
' SUMMARY:  Fill in a picture-logic grid using the number clues, and let the checker tell you which rows and columns are right.
' ------------------------------------------------------------
' WHAT IT DOES
'   A nonogram (also called Picross or Griddlers) hides a picture.
'   Each row and column has a clue like  "3 1"  meaning: somewhere in
'   this line there is a run of 3 filled squares, then at least one
'   gap, then a run of 1.  Use logic to work out which squares to fill.
'
'   The CHECKER turns your current line into its own clue (this is
'   called run-length encoding) and compares it with the real clue.
'   Lines that match turn green.  When every line matches, you win -
'   even if your picture differs from ours, because your answer
'   satisfies all the clues!
'
' HOW TO USE
'   Arrow keys move.  Space = fill / unfill.  X = mark a square as
'   definitely empty (just a reminder for you).
'   C = check now, R = reveal the answer, N = next puzzle, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Run-length encoding: "##.#" -> "2 1"
'   * Computing clues automatically from a picture in DATA
'   * Comparing strings to validate a solution
'   * A cursor-driven grid game in text mode
'
' THINGS TO TRY
'   * Draw your own 10x10 picture in the DATA lines - the clues are
'     worked out automatically.
'   * Add a solver: for each line, try every placement of the runs
'     that fits, and fill squares that are filled in ALL of them.
' ============================================================
DECLARE FUNCTION Clue$ (isRow AS INTEGER, i AS INTEGER, fromAnswer AS INTEGER)
DECLARE SUB DrawAll ()
DECLARE SUB DrawCell (r AS INTEGER, c AS INTEGER)
DEFINT A-Z

CONST MAXN = 10
CONST X0 = 30, Y0 = 9          ' screen position of the top-left cell
DIM SHARED n, title$
DIM SHARED ans(MAXN, MAXN)     ' the hidden picture (1 = filled)
DIM SHARED cell(MAXN, MAXN)    ' player: 0 empty, 1 filled, 2 marked X
DIM SHARED rowClue$(MAXN), colClue$(MAXN)
DIM SHARED curR, curC
nPuz = 3: puz = 1

DO
    ' ---- Load puzzle number "puz" from DATA ---------------------------
    RESTORE PICTURES
    FOR p = 1 TO puz
        READ title$, n
        FOR r = 1 TO n
            READ row$
            FOR c = 1 TO n
                ans(r, c) = -(MID$(row$, c, 1) = "#")
            NEXT
        NEXT
    NEXT
    ' The clues are computed from the picture - nobody types them.
    FOR i = 1 TO n
        rowClue$(i) = Clue$(-1, i, -1)
        colClue$(i) = Clue$(0, i, -1)
        FOR j = 1 TO n: cell(i, j) = 0: NEXT
    NEXT
    curR = 1: curC = 1
    CLS
    DrawAll
    nextPuzzle = 0
    DO
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        oldR = curR: oldC = curC
        SELECT CASE UCASE$(k$)
            CASE CHR$(0) + "H": IF curR > 1 THEN curR = curR - 1
            CASE CHR$(0) + "P": IF curR < n THEN curR = curR + 1
            CASE CHR$(0) + "K": IF curC > 1 THEN curC = curC - 1
            CASE CHR$(0) + "M": IF curC < n THEN curC = curC + 1
            CASE " "
                IF cell(curR, curC) = 1 THEN cell(curR, curC) = 0 ELSE cell(curR, curC) = 1
            CASE "X"
                IF cell(curR, curC) = 2 THEN cell(curR, curC) = 0 ELSE cell(curR, curC) = 2
            CASE "C"
                DrawAll
            CASE "R"
                FOR r = 1 TO n: FOR c = 1 TO n: cell(r, c) = ans(r, c): NEXT: NEXT
                DrawAll
            CASE "N"
                puz = puz MOD nPuz + 1: nextPuzzle = -1
            CASE "Q", CHR$(27)
                CLS : END
        END SELECT
        DrawCell oldR, oldC
        DrawCell curR, curC
        IF k$ = " " THEN
            ' Re-check just this row and column after every fill.
            DrawAll
        END IF
    LOOP UNTIL nextPuzzle
LOOP

PICTURES:
DATA "Heart", 7
DATA ".##.##."
DATA "#######"
DATA "#######"
DATA ".#####."
DATA "..###.."
DATA "...#..."
DATA "......."
DATA "Sailboat", 8
DATA "...#...."
DATA "...##..."
DATA "...###.."
DATA "...####."
DATA "...#...."
DATA "########"
DATA ".######."
DATA "..####.."
DATA "Cat", 10
DATA "#.......#."
DATA "##.....##."
DATA "#########."
DATA "#.##.###.."
DATA "#########."
DATA ".#######.."
DATA "..#####..."
DATA "..#####.#."
DATA "..######.#"
DATA "..##..##.."

FUNCTION Clue$ (isRow AS INTEGER, i AS INTEGER, fromAnswer AS INTEGER)
    ' Run-length encode row (or column) i.  For example "##.#.###"
    ' gives "2 1 3".  An empty line gives "0".
    s$ = "": runLen = 0
    FOR j = 1 TO n + 1
        IF j <= n THEN
            IF isRow THEN r = i: c = j ELSE r = j: c = i
            IF fromAnswer THEN f = ans(r, c) ELSE f = (cell(r, c) = 1)
        ELSE
            f = 0                    ' a pretend empty square at the end
        END IF
        IF f THEN
            runLen = runLen + 1
        ELSEIF runLen > 0 THEN
            s$ = s$ + " " + LTRIM$(STR$(runLen)): runLen = 0
        END IF
    NEXT
    IF s$ = "" THEN s$ = " 0"
    Clue$ = MID$(s$, 2)
END FUNCTION

SUB DrawAll
    ' Draw clues (green if the line already matches) and all cells.
    LOCATE 1, 2: COLOR 14: PRINT "NONOGRAM: "; title$; " ("; LTRIM$(STR$(n)); "x"; LTRIM$(STR$(n)); ")    "
    solved = -1
    ' Row clues to the left of each row.
    FOR r = 1 TO n
        ok = (Clue$(-1, r, 0) = rowClue$(r))
        IF NOT ok THEN solved = 0
        IF ok THEN COLOR 10 ELSE COLOR 7
        LOCATE Y0 + r - 1, X0 - 16: PRINT RIGHT$(SPACE$(14) + rowClue$(r), 14);
    NEXT
    ' Column clues are written vertically, one number per line,
    ' bottom-aligned just above the grid.
    FOR c = 1 TO n
        ok = (Clue$(0, c, 0) = colClue$(c))
        IF NOT ok THEN solved = 0
        IF ok THEN COLOR 10 ELSE COLOR 7
        t$ = colClue$(c) + " "
        cnt = 0
        FOR k = 1 TO LEN(t$)
            IF MID$(t$, k, 1) = " " THEN cnt = cnt + 1
        NEXT
        FOR y = 2 TO Y0 - 1: LOCATE y, X0 + (c - 1) * 3 - 1: PRINT "  "; : NEXT
        y = Y0 - cnt
        DO WHILE LEN(t$) > 0
            sp = INSTR(t$, " ")
            LOCATE y, X0 + (c - 1) * 3 - 1: PRINT RIGHT$(" " + LEFT$(t$, sp - 1), 2);
            t$ = MID$(t$, sp + 1): y = y + 1
        LOOP
    NEXT
    FOR r = 1 TO n: FOR c = 1 TO n: DrawCell r, c: NEXT: NEXT
    COLOR 7
    LOCATE Y0 + n + 1, 2
    IF solved THEN
        COLOR 10: PRINT "Every clue is satisfied - puzzle solved!  (N = next puzzle)    "
    ELSE
        COLOR 7: PRINT "Green clues are already correct.                                "
    END IF
    COLOR 7
    LOCATE 24, 2: PRINT "Arrows move  Space fill  X mark  R reveal  N next  Q quit";
END SUB

SUB DrawCell (r AS INTEGER, c AS INTEGER)
    LOCATE Y0 + r - 1, X0 + (c - 1) * 3 - 1
    ' The cursor square is shown with brackets.
    IF r = curR AND c = curC THEN COLOR 14: PRINT "["; ELSE PRINT " ";
    SELECT CASE cell(r, c)
        CASE 0: COLOR 8: PRINT CHR$(250);       ' small dot = unknown
        CASE 1: COLOR 15: PRINT CHR$(219);      ' solid block = filled
        CASE 2: COLOR 4: PRINT "x";             ' x = marked empty
    END SELECT
    IF r = curR AND c = curC THEN COLOR 14: PRINT "]"; ELSE PRINT " ";
    COLOR 7
END SUB
