' ============================================================
' TITLE:    Word Wrap & Justify
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     word wrap, strings, justify, instr, formatting
' SUMMARY:  Watch a paragraph re-flow live as you change the column width and switch between left, right, centre and full justification.
' ------------------------------------------------------------
' WHAT IT DOES
'   Splits a paragraph into words and lays them out in lines that
'   fit a chosen width - the same job a word processor does every
'   time you type.  You can make the column narrower or wider and
'   switch the alignment.  "Full" justification spreads extra
'   spaces between the words so both edges are straight, like in
'   a newspaper.
'
' HOW TO USE
'   Left / Right (or - and +)   make the column narrower / wider
'   L  R  C  J                  left, right, centre, justified
'   Esc or Q                    quit
'
' CONCEPTS YOU WILL LEARN
'   * Splitting a string into words with INSTR
'   * The "greedy" wrapping algorithm: add words until the next one
'     will not fit, then start a new line
'   * Distributing extra spaces evenly with \ and MOD
'   * Drawing a ruler so you can see the width
'
' THINGS TO TRY
'   * Break words that are longer than the whole line.
'   * Count how many lines the paragraph uses at each width.
'   * Load the paragraph from a text file instead of DATA.
' ============================================================

DEFINT A-Z
DECLARE SUB OutLine (row, txt$, isLast)

DIM SHARED words$(1 TO 300), nw, wid, mode$

' ---- 1. Build the paragraph from DATA and split into words -------
para$ = ""
DO
    READ s$
    IF s$ = "*" THEN EXIT DO
    para$ = para$ + s$ + " "
LOOP
DATA "Once upon a time, computers had no windows and no mice. People"
DATA "talked to them by typing, and the computer answered with letters"
DATA "on a dark screen, eighty columns wide and twenty-five rows tall."
DATA "Programmers became artists of the text screen. They drew boxes"
DATA "with special characters, painted menus with colour, and wrote"
DATA "their own little word processors - which all had to solve this"
DATA "exact problem: how do you fit words neatly into a column?"
DATA "*"

' Walk through the string; every space ends a word.
nw = 0
p = 1
DO
    sp = INSTR(p, para$, " ")        ' next space after position p
    IF sp = 0 THEN EXIT DO
    w$ = MID$(para$, p, sp - p)      ' the characters between
    IF w$ <> "" THEN nw = nw + 1: words$(nw) = w$
    p = sp + 1
LOOP

SCREEN 0: WIDTH 80, 25
wid = 40: mode$ = "J"

DO
    ' ---- 2. Draw the frame, ruler and status ---------------------
    COLOR 7, 0: CLS
    COLOR 15, 1: LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 3: PRINT "WORD WRAP & JUSTIFY";
    SELECT CASE mode$
        CASE "L": m$ = "Left"
        CASE "R": m$ = "Right"
        CASE "C": m$ = "Centre"
        CASE "J": m$ = "Justified"
    END SELECT
    LOCATE 1, 45: PRINT USING "Width: ##   Mode: &"; wid; m$;

    ' A ruler: a tick every 5 columns, a number every 10.
    COLOR 8
    LOCATE 3, 5
    FOR c = 1 TO wid
        IF c MOD 10 = 0 THEN
            PRINT RIGHT$(STR$(c \ 10), 1);
        ELSEIF c MOD 5 = 0 THEN
            PRINT "+";
        ELSE
            PRINT CHR$(250);
        END IF
    NEXT c
    ' edge markers on each side of the column
    FOR r = 4 TO 21
        LOCATE r, 4: PRINT CHR$(179);
        LOCATE r, 5 + wid: PRINT CHR$(179);
    NEXT r

    ' ---- 3. The greedy wrapping algorithm ------------------------
    COLOR 15
    row = 4
    ln$ = ""
    FOR i = 1 TO nw
        IF ln$ = "" THEN
            try$ = words$(i)
        ELSE
            try$ = ln$ + " " + words$(i)
        END IF
        IF LEN(try$) <= wid OR ln$ = "" THEN
            ln$ = try$                ' it fits (or it's alone): keep going
        ELSE
            OutLine row, ln$, 0       ' line is full: print it
            row = row + 1
            ln$ = words$(i)           ' this word starts the next line
        END IF
    NEXT i
    IF ln$ <> "" THEN OutLine row, ln$, 1   ' the last line
    COLOR 7
    LOCATE 23, 5: PRINT USING "The paragraph has ### words on ## lines."; nw; row - 3

    COLOR 3
    LOCATE 25, 5: PRINT "Left/Right = width   L R C J = alignment   Esc = quit";

    ' ---- 4. Keys ------------------------------------------------
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "K", "-": IF wid > 12 THEN wid = wid - 1
        CASE CHR$(0) + "M", "+", "=": IF wid < 74 THEN wid = wid + 1
        CASE "L", "R", "C", "J": mode$ = UCASE$(k$)
        CASE CHR$(27), "Q": EXIT DO
    END SELECT
LOOP
COLOR 7, 0: CLS
END

' Print one wrapped line in the current alignment mode.
SUB OutLine (row, txt$, isLast)
    IF row > 21 THEN EXIT SUB          ' too narrow: ran out of room
    gap = wid - LEN(txt$)              ' spare columns on this line
    SELECT CASE mode$
        CASE "L": LOCATE row, 5: PRINT txt$;
        CASE "R": LOCATE row, 5 + gap: PRINT txt$;
        CASE "C": LOCATE row, 5 + gap \ 2: PRINT txt$;
        CASE "J"
            ' The last line of a paragraph is never stretched.
            spaces = 0                  ' count the gaps between words
            FOR i = 1 TO LEN(txt$)
                IF MID$(txt$, i, 1) = " " THEN spaces = spaces + 1
            NEXT i
            IF isLast OR spaces = 0 THEN
                LOCATE row, 5: PRINT txt$;
                EXIT SUB
            END IF
            ' Share the spare columns between the gaps.  Every gap
            ' gets "each" extra spaces, and the first "extra" gaps get
            ' one more, so the total comes out exactly right.
            each = gap \ spaces
            extra = gap MOD spaces
            res$ = ""
            n = 0
            FOR i = 1 TO LEN(txt$)
                ch$ = MID$(txt$, i, 1)
                res$ = res$ + ch$
                IF ch$ = " " THEN
                    n = n + 1
                    res$ = res$ + SPACE$(each)
                    IF n <= extra THEN res$ = res$ + " "
                END IF
            NEXT i
            LOCATE row, 5: PRINT res$;
    END SELECT
END SUB
