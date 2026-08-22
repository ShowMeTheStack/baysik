' ============================================================
' TITLE:    Periodic Table Quiz
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     chemistry, science, periodic table, DATA, quiz
' SUMMARY:  A colour-coded periodic table of the first 36 elements with three quiz games.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws the top four rows (periods) of the periodic table, from
'   hydrogen (1) to krypton (36), colour-coded: metals, non-metals,
'   metalloids and noble gases.  Then it quizzes you in one of three
'   ways: give the NAME for a symbol, give the SYMBOL for a name, or
'   spot the element that is blinking on the table.
'
' HOW TO USE
'   Choose a game 1-3 (or T to just look at the table, Q to quit).
'   Type your answer and press Enter.  10 questions per game.
'
' CONCEPTS YOU WILL LEARN
'   * Working out an element's row and column from its atomic number
'   * Using COLOR with a blink attribute (colour + 16)
'   * Case-insensitive comparing with UCASE$
'   * Parallel arrays: name$(z), sym$(z), kind$(z)
'
' THINGS TO TRY
'   * Add period 5 (rubidium to xenon, numbers 37-54)
'   * Add atomic masses to the DATA and ask "which is heavier?"
'   * Time each game and record the fastest
' ============================================================

DECLARE SUB DrawTable (blinkZ!)
DECLARE SUB Place (z!, row!, col!)

CONST MAXZ = 36
DIM SHARED nam$(1 TO MAXZ), sym$(1 TO MAXZ), kind$(1 TO MAXZ)
FOR z = 1 TO MAXZ
    READ sym$(z), nam$(z), kind$(z)
NEXT z
RANDOMIZE TIMER

DO
    CLS
    DrawTable 0
    LOCATE 15, 3: COLOR 14: PRINT "PERIODIC TABLE QUIZ"
    COLOR 7
    LOCATE 17, 3: PRINT "1) Symbol -> name     2) Name -> symbol     3) Find the blinking element"
    LOCATE 18, 3: PRINT "T) Just look at the table     Q) Quit"
    LOCATE 20, 3: PRINT "Choose: ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "T" THEN
        LOCATE 20, 3: PRINT "Press any key to go back.";
        DO: LOOP WHILE INKEY$ = ""
    ELSEIF k$ >= "1" AND k$ <= "3" THEN
        game = VAL(k$): score = 0
        FOR q = 1 TO 10
            z = INT(RND * MAXZ) + 1
            CLS
            IF game = 3 THEN DrawTable z ELSE DrawTable 0
            LOCATE 15, 3: COLOR 14: PRINT "Question"; q; "of 10      Score:"; score
            LOCATE 17, 3: COLOR 15
            SELECT CASE game
                CASE 1
                    PRINT "Which element has the symbol "; sym$(z); "? ";
                    LINE INPUT a$: good = (UCASE$(LTRIM$(RTRIM$(a$))) = UCASE$(nam$(z)))
                CASE 2
                    PRINT "What is the symbol for "; nam$(z); "? ";
                    LINE INPUT a$: good = (UCASE$(LTRIM$(RTRIM$(a$))) = UCASE$(sym$(z)))
                CASE 3
                    PRINT "Which element is blinking? Type its symbol: ";
                    LINE INPUT a$: good = (UCASE$(LTRIM$(RTRIM$(a$))) = UCASE$(sym$(z)))
            END SELECT
            LOCATE 19, 3
            IF good THEN
                score = score + 1
                COLOR 10: PRINT "Correct! ";
            ELSE
                COLOR 12: PRINT "Not quite. ";
            END IF
            PRINT nam$(z); " ("; sym$(z); ") is element number"; z
            COLOR 7: LOCATE 21, 3: PRINT "Press a key...";
            DO: k$ = INKEY$: LOOP WHILE k$ = ""
            IF k$ = CHR$(27) THEN EXIT FOR
        NEXT q
        LOCATE 23, 3: COLOR 14
        PRINT "You scored"; score; "out of 10.";
        IF score >= 8 THEN PRINT " Super scientist!" ELSE PRINT " Nice work - try again!"
        COLOR 7: LOCATE 24, 3: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
COLOR 7: CLS
END

' ------------------------------------------------------------
' DrawTable: works out where each element goes.
' Period (row) 1 holds 2 elements, periods 2 and 3 hold 8 (groups
' 1, 2 then 13-18), period 4 holds 18 (all groups 1-18).
' ------------------------------------------------------------
SUB DrawTable (blinkZ)
    FOR z = 1 TO MAXZ
        IF z <= 2 THEN
            period = 1
            IF z = 1 THEN grp = 1 ELSE grp = 18
        ELSEIF z <= 18 THEN
            ' periods 2 and 3 start at z = 3 and z = 11
            IF z <= 10 THEN period = 2: first = 3 ELSE period = 3: first = 11
            idx = z - first + 1               ' 1..8 along the row
            IF idx <= 2 THEN grp = idx ELSE grp = idx + 10   ' skip the gap
        ELSE
            period = 4: grp = z - 18          ' 19..36 fill groups 1..18
        END IF
        ' Each cell is 4 characters wide, each period 3 rows tall
        row = 2 + (period - 1) * 3
        col = 3 + (grp - 1) * 4
        IF z = blinkZ THEN
            COLOR 15 + 16, 4                  ' +16 makes it blink
            LOCATE row, col: PRINT "  ? ";
            LOCATE row + 1, col: PRINT "    ";
            COLOR 7, 0
        ELSE
            Place z, row, col
        END IF
    NEXT z
    ' A key for the colours
    LOCATE 13, 3
    COLOR 0, 6: PRINT " metal ";: COLOR 7, 0: PRINT " ";
    COLOR 0, 2: PRINT " non-metal ";: COLOR 7, 0: PRINT " ";
    COLOR 0, 3: PRINT " metalloid ";: COLOR 7, 0: PRINT " ";
    COLOR 0, 5: PRINT " noble gas ";: COLOR 7, 0
END SUB

' Draws one element cell: symbol on top, atomic number below.
SUB Place (z, row, col)
    SELECT CASE kind$(z)
        CASE "M": bg = 6
        CASE "N": bg = 2
        CASE "S": bg = 3
        CASE ELSE: bg = 5
    END SELECT
    COLOR 15, bg
    LOCATE row, col: PRINT " "; LEFT$(sym$(z) + "  ", 2); " ";
    COLOR 0, bg
    LOCATE row + 1, col: PRINT RIGHT$("   " + LTRIM$(STR$(z)), 3); " ";
    COLOR 7, 0
END SUB

' symbol, name, kind (M = metal, N = non-metal, S = metalloid, G = noble gas)
DATA H, Hydrogen, N, He, Helium, G
DATA Li, Lithium, M, Be, Beryllium, M, B, Boron, S, C, Carbon, N
DATA N, Nitrogen, N, O, Oxygen, N, F, Fluorine, N, Ne, Neon, G
DATA Na, Sodium, M, Mg, Magnesium, M, Al, Aluminium, M, Si, Silicon, S
DATA P, Phosphorus, N, S, Sulfur, N, Cl, Chlorine, N, Ar, Argon, G
DATA K, Potassium, M, Ca, Calcium, M, Sc, Scandium, M, Ti, Titanium, M
DATA V, Vanadium, M, Cr, Chromium, M, Mn, Manganese, M, Fe, Iron, M
DATA Co, Cobalt, M, Ni, Nickel, M, Cu, Copper, M, Zn, Zinc, M
DATA Ga, Gallium, M, Ge, Germanium, S, As, Arsenic, S, Se, Selenium, N
DATA Br, Bromine, N, Kr, Krypton, G
