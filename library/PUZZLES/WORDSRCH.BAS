' ============================================================
' TITLE:    Word Search Generator
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     words, strings, random, grids, files, printing
' SUMMARY:  Hides a list of words in a grid of random letters - in all 8 directions - and can save it for printing.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick a theme (or type your own words).  The program tries to hide
'   each word at a random spot and in a random direction: across,
'   down, diagonally, even backwards.  Words may cross each other if
'   they share the same letter.  Empty squares are filled with random
'   letters.  You can reveal the answers or save the puzzle to a text
'   file called WORDSRCH.TXT.
'
' HOW TO USE
'   Choose 1-3 for a theme or 4 to enter up to 12 words yourself.
'   Then:  A = show/hide answers, S = save, N = new puzzle, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Direction vectors (dx, dy) for the 8 compass directions
'   * Trying random placements and giving up after many attempts
'   * String functions: MID$, UCASE$, LEN, CHR$, ASC
'   * Writing a text file with OPEN ... FOR OUTPUT and PRINT #
'
' THINGS TO TRY
'   * Make the grid bigger, or only allow forward directions for
'     younger players.
'   * Add a "find it" mode where the player types the row, column
'     and direction of each word.
' ============================================================
DECLARE SUB ShowGrid (answers AS INTEGER)
DECLARE FUNCTION TryPlace% (w$, idx AS INTEGER)
DEFINT A-Z

CONST SIZE = 14             ' grid is SIZE x SIZE
CONST MAXW = 12             ' at most this many words
DIM SHARED grid$(SIZE, SIZE)       ' "" = empty, else one letter
DIM SHARED owner(SIZE, SIZE)       ' >0 if a hidden word uses this cell
DIM SHARED words$(MAXW), placed(MAXW), nWords
DIM SHARED dx(7), dy(7)
FOR d = 0 TO 7: READ dx(d), dy(d): NEXT
' E, SE, S, SW, W, NW, N, NE
DATA 1,0, 1,1, 0,1, -1,1, -1,0, -1,-1, 0,-1, 1,-1

RANDOMIZE TIMER
DO
    CLS
    COLOR 14: PRINT "WORD SEARCH GENERATOR": COLOR 7
    PRINT
    PRINT "  1) Animals    2) Space    3) Fruit    4) My own words    Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    t = VAL(a$)
    nWords = 0
    IF t >= 1 AND t <= 3 THEN
        ' Skip to the chosen theme in the DATA lines.
        RESTORE THEMES
        FOR i = 1 TO t
            READ title$
            DO
                READ w$
                IF i = t AND w$ <> "*" THEN nWords = nWords + 1: words$(nWords) = w$
            LOOP UNTIL w$ = "*"
        NEXT
    ELSEIF t = 4 THEN
        title$ = "MY WORDS"
        PRINT "  Type up to"; MAXW; "words (3 to"; SIZE; "letters). Empty line = done."
        DO WHILE nWords < MAXW
            LINE INPUT "  Word: "; w$
            w$ = UCASE$(LTRIM$(RTRIM$(w$)))
            IF w$ = "" OR INSTR(w$, CHR$(27)) THEN EXIT DO
            ' Keep only the letters A-Z.
            clean$ = ""
            FOR i = 1 TO LEN(w$)
                ch$ = MID$(w$, i, 1)
                IF ch$ >= "A" AND ch$ <= "Z" THEN clean$ = clean$ + ch$
            NEXT
            IF LEN(clean$) >= 3 AND LEN(clean$) <= SIZE THEN
                nWords = nWords + 1: words$(nWords) = clean$
            ELSE
                PRINT "  (skipped - needs 3 to"; SIZE; "letters)"
            END IF
        LOOP
    END IF

    IF nWords > 0 THEN
        ' ---- Build the puzzle -------------------------------------
        FOR y = 1 TO SIZE: FOR x = 1 TO SIZE
            grid$(x, y) = "": owner(x, y) = 0
        NEXT: NEXT
        ' Long words are hardest to fit, so place them first
        ' (a simple bubble sort by length, longest first).
        FOR i = 1 TO nWords - 1
            FOR j = 1 TO nWords - i
                IF LEN(words$(j)) < LEN(words$(j + 1)) THEN SWAP words$(j), words$(j + 1)
            NEXT
        NEXT
        FOR i = 1 TO nWords
            placed(i) = TryPlace%(words$(i), i)
        NEXT
        ' Fill the gaps with random letters.
        FOR y = 1 TO SIZE: FOR x = 1 TO SIZE
            IF grid$(x, y) = "" THEN grid$(x, y) = CHR$(65 + INT(RND * 26))
        NEXT: NEXT

        ' ---- Let the user play with it -----------------------------
        answers = 0
        DO
            ShowGrid answers
            DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
            SELECT CASE k$
                CASE "A": answers = NOT answers
                CASE "S"
                    OPEN "WORDSRCH.TXT" FOR OUTPUT AS #1
                    PRINT #1, "WORD SEARCH: "; title$
                    PRINT #1,
                    FOR y = 1 TO SIZE
                        FOR x = 1 TO SIZE: PRINT #1, grid$(x, y); " "; : NEXT
                        PRINT #1,
                    NEXT
                    PRINT #1,
                    FOR i = 1 TO nWords
                        IF placed(i) THEN PRINT #1, "  "; words$(i)
                    NEXT
                    CLOSE #1
                    LOCATE 24, 1: PRINT "Saved to WORDSRCH.TXT - press a key";
                    DO: LOOP WHILE INKEY$ = ""
                CASE "N", "Q", CHR$(27): EXIT DO
            END SELECT
        LOOP
        IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    END IF
LOOP
CLS
END

THEMES:
DATA "ANIMALS", ELEPHANT, GIRAFFE, PENGUIN, ZEBRA, OCTOPUS, KANGAROO
DATA TIGER, DOLPHIN, OWL, CHEETAH, RABBIT, FOX, *
DATA "SPACE", PLANET, GALAXY, COMET, NEBULA, ASTEROID, ROCKET
DATA ORBIT, SATURN, JUPITER, MARS, STAR, ECLIPSE, *
DATA "FRUIT", BANANA, MANGO, CHERRY, APPLE, PAPAYA, KIWI
DATA PINEAPPLE, LEMON, GRAPE, PEAR, LYCHEE, PLUM, *

SUB ShowGrid (answers AS INTEGER)
    CLS
    COLOR 14: PRINT "  WORD SEARCH": COLOR 7
    PRINT
    FOR y = 1 TO SIZE
        PRINT "   ";
        FOR x = 1 TO SIZE
            ' In answer mode, letters that belong to a word glow yellow.
            IF answers AND owner(x, y) > 0 THEN COLOR 14, 1 ELSE COLOR 7, 0
            PRINT grid$(x, y);
            COLOR 7, 0: PRINT " ";
        NEXT
        PRINT
    NEXT
    ' Word list on the right-hand side.
    LOCATE 3, 36: PRINT "Find these words:"
    row = 4
    FOR i = 1 TO nWords
        LOCATE row + i, 38
        IF placed(i) THEN
            PRINT words$(i)
        ELSE
            COLOR 8: PRINT words$(i); " (did not fit)": COLOR 7
        END IF
    NEXT
    LOCATE 22, 1
    PRINT "A = answers on/off   S = save to file   N = new puzzle   Q = quit"
END SUB

FUNCTION TryPlace% (w$, idx AS INTEGER)
    ' Pick random start squares and directions up to 300 times.
    L = LEN(w$)
    FOR attempt = 1 TO 300
        d = INT(RND * 8)
        x = INT(RND * SIZE) + 1: y = INT(RND * SIZE) + 1
        ' Where would the LAST letter land?  It must be on the grid.
        ex = x + dx(d) * (L - 1): ey = y + dy(d) * (L - 1)
        IF ex >= 1 AND ex <= SIZE AND ey >= 1 AND ey <= SIZE THEN
            ' Every cell must be empty or already hold the same letter.
            ok = -1
            FOR i = 0 TO L - 1
                g$ = grid$(x + dx(d) * i, y + dy(d) * i)
                IF g$ <> "" AND g$ <> MID$(w$, i + 1, 1) THEN ok = 0: EXIT FOR
            NEXT
            IF ok THEN
                FOR i = 0 TO L - 1
                    grid$(x + dx(d) * i, y + dy(d) * i) = MID$(w$, i + 1, 1)
                    owner(x + dx(d) * i, y + dy(d) * i) = idx
                NEXT
                TryPlace% = -1
                EXIT FUNCTION
            END IF
        END IF
    NEXT
    TryPlace% = 0
END FUNCTION
