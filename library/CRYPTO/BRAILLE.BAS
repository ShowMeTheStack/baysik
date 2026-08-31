' ============================================================
' TITLE:    Braille Writer
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     braille, bit patterns, 6-dot cell, text graphics, accessibility
' SUMMARY:  Shows any message as 6-dot Braille cells and reveals the clever pattern behind the whole alphabet.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1824 a 15-year-old blind French student, Louis Braille,
'   improved a military "night writing" code (Charles Barbier's
'   system for reading messages in the dark without a light) into
'   the tactile alphabet that blind people read all over the world.
'
'   Each Braille CELL has 6 dot positions, numbered like this:
'
'           1 o o 4
'           2 o o 5
'           3 o o 6
'
'   6 dots, each raised or flat, gives 2^6 = 64 patterns.
'   Braille's alphabet has a beautiful system:
'     * a-j use only the top four dots (1, 2, 4, 5)
'     * k-t are a-j PLUS dot 3
'     * u, v, x, y, z are a-e PLUS dots 3 and 6
'     * w was added later (French had no W) and is the odd one out
'   Digits 1-9,0 are the letters a-j after a "number sign".
'   A "capital sign" (dot 6) goes before a capital letter.
'
'   This program stores ONLY the ten patterns for a-j and builds
'   every other letter with those rules.
'
' HOW TO USE
'   Type a message (up to 60 characters).  Raised dots are bright,
'   flat dots are dim.  Enter on an empty line shows the alphabet;
'   type Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Storing 6 on/off dots in one number (a bit mask)
'   * Testing a bit with AND:  IF mask AND 4 THEN dot 3 is raised
'   * Building a table from rules instead of typing it all in
'   * Laying out "big characters" on a text screen with LOCATE
'
' THINGS TO TRY
'   * Add punctuation (period = dots 2,5,6; comma = dot 2)
'   * Make a reverse quiz: show a cell, guess the letter
'   * Print the cells using CHR$(219) blocks to make them bigger
' ============================================================

DECLARE FUNCTION Pattern% (ch$)
DECLARE SUB DrawCell (row0, col0, mask, label$)
DECLARE SUB ShowText (t$)

' Bit values for each dot:  dot1=1 dot2=2 dot3=4 dot4=8 dot5=16 dot6=32
CONST D1 = 1, D2 = 2, D3 = 4, D4 = 8, D5 = 16, D6 = 32
CONST NUMSIGN = D3 + D4 + D5 + D6   ' dots 3-4-5-6
CONST CAPSIGN = D6                  ' dot 6

DIM SHARED aToJ(9)
' a=1  b=12  c=14  d=145  e=15  f=124  g=1245  h=125  i=24  j=245
aToJ(0) = D1: aToJ(1) = D1 + D2: aToJ(2) = D1 + D4
aToJ(3) = D1 + D4 + D5: aToJ(4) = D1 + D5: aToJ(5) = D1 + D2 + D4
aToJ(6) = D1 + D2 + D4 + D5: aToJ(7) = D1 + D2 + D5
aToJ(8) = D2 + D4: aToJ(9) = D2 + D4 + D5

t$ = ""
DO
    CLS
    COLOR 14: PRINT "BRAILLE WRITER": COLOR 7
    IF t$ = "" THEN
        PRINT "The alphabet - notice how each row of ten repeats the first,"
        PRINT "adding dot 3 (second row) and dots 3+6 (third row):"
        ShowText "abcdefghij|klmnopqrst|uvxyz     w"
    ELSE
        ShowText t$
    END IF
    LOCATE 23, 1
    LINE INPUT "Message (Enter = alphabet, Q = quit): "; t$
    IF UCASE$(t$) = "Q" THEN EXIT DO
    IF LEN(t$) > 60 THEN t$ = LEFT$(t$, 60)
LOOP
CLS
END

' ------------------------------------------------------------
' DrawCell: draw one 2x3 cell.  For each dot we test its bit with
' AND.  Raised dots: bright CHR$(254); flat dots: dim CHR$(250).
' ------------------------------------------------------------
SUB DrawCell (row0, col0, mask, label$)
    FOR r = 0 TO 2
        LOCATE row0 + r, col0
        ' left column: dots 1,2,3 = bits 1,2,4   (2 ^ r)
        ' right column: dots 4,5,6 = bits 8,16,32 (2 ^ (r + 3))
        IF mask AND 2 ^ r THEN COLOR 15: PRINT CHR$(254); ELSE COLOR 8: PRINT CHR$(250);
        PRINT " ";
        IF mask AND 2 ^ (r + 3) THEN COLOR 15: PRINT CHR$(254); ELSE COLOR 8: PRINT CHR$(250);
    NEXT r
    LOCATE row0 + 3, col0: COLOR 11: PRINT label$;
    COLOR 7
END SUB

' ------------------------------------------------------------
' Pattern%: Braille bit mask for one lower-case letter or digit.
' ------------------------------------------------------------
FUNCTION Pattern% (ch$)
    c = ASC(ch$)
    SELECT CASE ch$
    CASE "a" TO "j": Pattern% = aToJ(c - 97)
    CASE "k" TO "t": Pattern% = aToJ(c - 107) + D3           ' add dot 3
    CASE "w": Pattern% = aToJ(9) + D6                         ' j + dot 6
    CASE "u", "v": Pattern% = aToJ(c - 117) + D3 + D6         ' a,b + 3,6
    CASE "x" TO "z": Pattern% = aToJ(c - 118) + D3 + D6       ' c,d,e + 3,6
    CASE "1" TO "9": Pattern% = aToJ(c - 49)                  ' 1=a ... 9=i
    CASE "0": Pattern% = aToJ(9)                              ' 0=j
    CASE ELSE: Pattern% = 0                                   ' blank cell
    END SELECT
END FUNCTION

' ------------------------------------------------------------
' ShowText: lay out cells 5 columns apart, 16 cells per line, 5
' rows per line of cells (3 dots + label + gap); "|" forces a new line.  Capital letters
' get a capital sign first; a run of digits gets one number sign.
' ------------------------------------------------------------
SUB ShowText (t$)
    row = 5: col = 2: inNumber = 0
    FOR i = 1 TO LEN(t$)
        ch$ = MID$(t$, i, 1)
        ' "|" is our own "start a new line" marker.
        IF ch$ = "|" THEN col = 2: row = row + 5: ch$ = ""
        isDigit = (ch$ >= "0" AND ch$ <= "9")
        isCap = (ch$ >= "A" AND ch$ <= "Z")
        ' Build a little list of cells (up to 2) for this character.
        n = 0
        IF isDigit AND NOT inNumber THEN n = n + 1: m1 = NUMSIGN: l1$ = "#"
        IF isCap THEN n = n + 1: m1 = CAPSIGN: l1$ = "^"
        inNumber = isDigit
        IF ch$ = " " THEN inNumber = 0
        IF ch$ = "" THEN n = -1        ' nothing to draw for "|"
        FOR k = 1 TO n + 1
            IF k <= n THEN
                m = m1: lb$ = l1$
            ELSE
                m = Pattern%(LCASE$(ch$)): lb$ = ch$
            END IF
            IF col > 76 THEN col = 2: row = row + 5
            IF row > 20 THEN EXIT SUB
            DrawCell row, col, m, lb$
            col = col + 5
        NEXT k
    NEXT i
    LOCATE 22, 2: COLOR 8
    PRINT "^ = capital sign (dot 6)    # = number sign (dots 3,4,5,6)"
    COLOR 7
END SUB
