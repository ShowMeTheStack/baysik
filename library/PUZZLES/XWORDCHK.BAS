' ============================================================
' TITLE:    Crossword Grid Checker
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     crossword, grids, flood fill, symmetry, validation
' SUMMARY:  Numbers a crossword grid like a newspaper does and checks it against the rules puzzle editors use.
' ------------------------------------------------------------
' WHAT IT DOES
'   Newspaper crossword grids follow strict house rules.  This program
'   loads a grid (# = black square, letters or . = white squares) and
'   checks:
'     1. SYMMETRY  - the grid looks the same rotated 180 degrees
'     2. CONNECTED - every white square can be reached from every
'                    other (found with a flood fill)
'     3. NO SHORTIES - every word is at least 3 letters long
'     4. ALL CHECKED - every white square is part of an Across AND a
'                    Down word
'   It then numbers the grid the standard way and lists every Across
'   and Down entry with its letters.
'
' HOW TO USE
'   Choose a sample grid 1-3.  Grid 1 obeys all the rules, grid 2
'   breaks several, and grid 3 is a filled word square.  Q quits.
'   Or type F to load your own grid from a text file (one row per
'   line, all rows the same length, at most 15 x 15).
'
' CONCEPTS YOU WILL LEARN
'   * Flood fill with an explicit stack (no recursion needed)
'   * The crossword numbering rule: a square gets a number if it
'     STARTS an Across word or a Down word
'   * 180-degree rotation: cell (r, c) matches (n+1-r, n+1-c)
'   * Reading text files with LINE INPUT # and ON ERROR
'
' THINGS TO TRY
'   * Design your own 7x7 grid in DATA and make it pass every test.
'   * Count the "word count" and "black square count" that editors
'     like to keep low.
' ============================================================
DECLARE SUB Analyse ()
DECLARE FUNCTION IsWhite% (r AS INTEGER, c AS INTEGER)
DEFINT A-Z

CONST MAXN = 15
DIM SHARED g$(MAXN)             ' grid rows as strings
DIM SHARED rows, cols
DIM SHARED fileErr

DO
    CLS
    COLOR 14: PRINT "CROSSWORD GRID CHECKER": COLOR 7
    PRINT
    PRINT "  1) A legal 7x7 grid   2) A broken 7x7 grid   3) A 5x5 word square"
    PRINT "  F) Load a grid from a text file            Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    ok = 0
    IF a$ = "1" OR a$ = "2" OR a$ = "3" THEN
        RESTORE GRIDS
        FOR i = 1 TO VAL(a$)
            READ rows
            FOR r = 1 TO rows: READ g$(r): NEXT
        NEXT
        cols = LEN(g$(1)): ok = -1
    ELSEIF a$ = "F" THEN
        LINE INPUT "  File name: "; f$
        fileErr = 0
        ON ERROR GOTO NoFile
        OPEN f$ FOR INPUT AS #1
        ON ERROR GOTO 0
        IF fileErr THEN
            PRINT "  Could not open that file."
        ELSE
            rows = 0
            DO WHILE NOT EOF(1) AND rows < MAXN
                LINE INPUT #1, l$
                l$ = UCASE$(RTRIM$(l$))
                IF l$ <> "" THEN rows = rows + 1: g$(rows) = l$
            LOOP
            CLOSE #1
            cols = LEN(g$(1)): ok = (rows > 0)
            FOR r = 1 TO rows
                IF LEN(g$(r)) <> cols OR cols > MAXN THEN ok = 0
            NEXT
            IF NOT ok THEN PRINT "  Rows must all be the same length (max 15)."
        END IF
    END IF
    IF ok THEN Analyse
    PRINT
    LINE INPUT "Press Enter to continue (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

NoFile:
    fileErr = -1
    RESUME NEXT

GRIDS:
' Grid 1: symmetric, connected, all words 3+ letters, all checked.
DATA 7
DATA "##...##"
DATA "#.....#"
DATA "......."
DATA "...#..."
DATA "......."
DATA "#.....#"
DATA "##...##"
' Grid 2: breaks the rules - 2-letter words, not symmetric, split.
DATA 7
DATA "..#...."
DATA "..#...."
DATA "###...."
DATA "....###"
DATA "....#.."
DATA "....#.."
DATA "....#.."
' Grid 3: a "double word square" - every row AND column is a word!
DATA 5
DATA "HEART"
DATA "EMBER"
DATA "ABUSE"
DATA "RESIN"
DATA "TREND"

SUB Analyse
    DIM num(MAXN, MAXN), seen(MAXN, MAXN)
    DIM stackR(MAXN * MAXN), stackC(MAXN * MAXN)
    CLS
    ' ---- Show the grid with clue numbers ---------------------------
    ' A white square gets a number if a word STARTS there:
    '   Across starts: left is black/edge AND right is white
    '   Down   starts: above is black/edge AND below is white
    nxt = 0
    FOR r = 1 TO rows
        FOR c = 1 TO cols
            IF IsWhite%(r, c) THEN
                acr = NOT IsWhite%(r, c - 1) AND IsWhite%(r, c + 1)
                dwn = NOT IsWhite%(r - 1, c) AND IsWhite%(r + 1, c)
                IF acr OR dwn THEN nxt = nxt + 1: num(r, c) = nxt
            END IF
        NEXT
    NEXT
    FOR r = 1 TO rows
        LOCATE r + 1, 2
        FOR c = 1 TO cols
            IF IsWhite%(r, c) THEN
                COLOR 0, 7
                IF num(r, c) THEN PRINT USING "##"; num(r, c); ELSE PRINT "  ";
                ch$ = MID$(g$(r), c, 1): IF ch$ = "." THEN ch$ = " "
                COLOR 1, 7: PRINT ch$;
            ELSE
                COLOR 8, 0: PRINT CHR$(219); CHR$(219); CHR$(219);
            END IF
        NEXT
        COLOR 7, 0
    NEXT

    ' ---- Rule 1: 180-degree symmetry --------------------------------
    sym = -1
    FOR r = 1 TO rows
        FOR c = 1 TO cols
            IF IsWhite%(r, c) <> IsWhite%(rows + 1 - r, cols + 1 - c) THEN sym = 0
        NEXT
    NEXT

    ' ---- Rule 2: connectivity by flood fill ----------------------------
    ' Push the first white square, then repeatedly pop a square and push
    ' its unvisited white neighbours.  Count what we reach.
    whites = 0: sr = 0
    FOR r = 1 TO rows: FOR c = 1 TO cols
        IF IsWhite%(r, c) THEN whites = whites + 1: IF sr = 0 THEN sr = r: sc = c
    NEXT: NEXT
    reached = 0
    IF sr THEN
        sp = 1: stackR(1) = sr: stackC(1) = sc: seen(sr, sc) = -1
        DO WHILE sp > 0
            r = stackR(sp): c = stackC(sp): sp = sp - 1
            reached = reached + 1
            FOR d = 0 TO 3
                nr = r: nc = c
                SELECT CASE d
                    CASE 0: nr = r - 1
                    CASE 1: nr = r + 1
                    CASE 2: nc = c - 1
                    CASE 3: nc = c + 1
                END SELECT
                IF IsWhite%(nr, nc) THEN
                    IF NOT seen(nr, nc) THEN
                        seen(nr, nc) = -1: sp = sp + 1
                        stackR(sp) = nr: stackC(sp) = nc
                    END IF
                END IF
            NEXT
        LOOP
    END IF

    ' ---- Rules 3 and 4: word lengths and checked squares --------------
    shorts = 0: unchecked = 0
    FOR r = 1 TO rows
        FOR c = 1 TO cols
            IF IsWhite%(r, c) THEN
                ' Length of the across run through this square.
                a = 1: x = c - 1
                DO WHILE IsWhite%(r, x): a = a + 1: x = x - 1: LOOP
                x = c + 1
                DO WHILE IsWhite%(r, x): a = a + 1: x = x + 1: LOOP
                d = 1: y = r - 1
                DO WHILE IsWhite%(y, c): d = d + 1: y = y - 1: LOOP
                y = r + 1
                DO WHILE IsWhite%(y, c): d = d + 1: y = y + 1: LOOP
                ' A run of 1 means "no word that way" = unchecked square.
                IF a = 1 OR d = 1 THEN unchecked = unchecked + 1
                IF a = 2 OR d = 2 THEN shorts = shorts + 1
            END IF
        NEXT
    NEXT

    ' ---- Report ------------------------------------------------------
    x = cols * 3 + 5
    LOCATE 2, x: PRINT "Grid"; rows; "x"; cols; ","; whites; "white,"; rows * cols - whites; "black"
    LOCATE 3, x: PRINT "Clue numbers used:"; nxt
    LOCATE 5, x: IF sym THEN COLOR 10: PRINT "OK   symmetric" ELSE COLOR 12: PRINT "FAIL not symmetric"
    LOCATE 6, x
    IF reached = whites THEN
        COLOR 10: PRINT "OK   all white squares connected"
    ELSE
        COLOR 12: PRINT "FAIL only"; reached; "of"; whites; "squares connected"
    END IF
    LOCATE 7, x
    IF shorts = 0 THEN COLOR 10: PRINT "OK   no 2-letter words" ELSE COLOR 12: PRINT "FAIL"; shorts; "squares in 2-letter words"
    LOCATE 8, x
    IF unchecked = 0 THEN COLOR 10: PRINT "OK   every square checked" ELSE COLOR 12: PRINT "FAIL"; unchecked; "unchecked squares"
    COLOR 7

    ' ---- List the entries ---------------------------------------------
    y = rows + 3: IF y < 10 THEN y = 10
    LOCATE y, 1
    PRINT "ACROSS: ";
    FOR r = 1 TO rows: FOR c = 1 TO cols
        IF num(r, c) AND NOT IsWhite%(r, c - 1) AND IsWhite%(r, c + 1) THEN
            w$ = "": x = c
            DO WHILE IsWhite%(r, x): w$ = w$ + MID$(g$(r), x, 1): x = x + 1: LOOP
            e$ = LTRIM$(STR$(num(r, c))) + "." + w$ + " "
            ' Start a new line rather than splitting an entry in two.
            IF POS(0) + LEN(e$) > 79 THEN PRINT : PRINT SPACE$(8);
            PRINT e$;
        END IF
    NEXT: NEXT
    PRINT : PRINT
    PRINT "DOWN:   ";
    FOR r = 1 TO rows: FOR c = 1 TO cols
        IF num(r, c) AND NOT IsWhite%(r - 1, c) AND IsWhite%(r + 1, c) THEN
            w$ = "": y = r
            DO WHILE IsWhite%(y, c): w$ = w$ + MID$(g$(y), c, 1): y = y + 1: LOOP
            e$ = LTRIM$(STR$(num(r, c))) + "." + w$ + " "
            IF POS(0) + LEN(e$) > 79 THEN PRINT : PRINT SPACE$(8);
            PRINT e$;
        END IF
    NEXT: NEXT
    PRINT
END SUB

FUNCTION IsWhite% (r AS INTEGER, c AS INTEGER)
    ' Outside the grid counts as black - that makes edge tests easy.
    IF r < 1 OR r > rows OR c < 1 OR c > cols THEN IsWhite% = 0: EXIT FUNCTION
    IsWhite% = (MID$(g$(r), c, 1) <> "#")
END FUNCTION
