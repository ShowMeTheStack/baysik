' ============================================================
' TITLE:    Flags and Capitals
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     geography, flags, multiple choice, DATA, graphics
' SUMMARY:  See a country's flag drawn on screen and pick its capital city from four choices.
' ------------------------------------------------------------
' WHAT IT DOES
'   Each country is stored in DATA with its capital and a short
'   "recipe" for drawing its flag: what kind of stripes or shape it
'   has and which colours.  The program draws the flag, names the
'   country, and offers four capital cities (one right, three taken
'   from other countries).  Ten questions per game.
'
' HOW TO USE
'   Press A, B, C or D to choose.  Press Esc to quit at any time.
'
' CONCEPTS YOU WILL LEARN
'   * Describing pictures with data ("V" = vertical stripes etc.)
'   * LINE ... BF for filled boxes, CIRCLE + PAINT for discs
'   * Building multiple-choice answers without duplicates
'   * Arrays of strings filled from DATA
'
' THINGS TO TRY
'   * Add more countries - the flag code letters are explained below
'   * Add a "D" flag type for diagonal stripes
'   * Ask the question the other way: show the capital, pick the flag
' ============================================================

DECLARE SUB DrawFlag (kind$, c1!, c2!, c3!)
RANDOMIZE TIMER

' Flag kinds: V = three vertical stripes, H = three horizontal
' stripes, J = disc in the middle (c1 background, c2 disc),
' X = Nordic cross (c1 background, c2 cross, c3 thin inner cross;
' use -1 for "no inner cross").  Colours are SCREEN 12 numbers:
' 0 black 1 blue 2 green 4 red 6 orange/brown 14 yellow 15 white
READ total
DIM country$(1 TO total), capital$(1 TO total), kind$(1 TO total)
DIM c1(1 TO total), c2(1 TO total), c3(1 TO total)
FOR i = 1 TO total
    READ country$(i), capital$(i), kind$(i), c1(i), c2(i), c3(i)
NEXT i

DIM choice(1 TO 4)          ' which country fills each answer slot

SCREEN 12
score = 0
FOR q = 1 TO 10
    CLS
    ans = INT(RND * total) + 1              ' the country we ask about
    COLOR 14: LOCATE 2, 3: PRINT "Question"; q; "of 10"; TAB(65); "Score:"; score
    DrawFlag kind$(ans), c1(ans), c2(ans), c3(ans)
    COLOR 15: LOCATE 17, 22: PRINT "This is the flag of "; UCASE$(country$(ans)); "."
    LOCATE 18, 22: PRINT "What is its capital city?"

    ' Build four choices.  Slot 'correctSlot' gets the right answer;
    ' the others get random different countries' capitals.
    correctSlot = INT(RND * 4) + 1
    FOR s = 1 TO 4
        IF s = correctSlot THEN
            choice(s) = ans
        ELSE
            DO
                c = INT(RND * total) + 1
                ok = (c <> ans)
                FOR t = 1 TO s - 1          ' not already offered?
                    IF choice(t) = c THEN ok = 0
                NEXT t
            LOOP UNTIL ok
            choice(s) = c
        END IF
    NEXT s
    ' A wrong choice is never 'ans' itself and never repeats an earlier
    ' slot, so all four choices are different.

    FOR s = 1 TO 4
        LOCATE 20 + s, 25: COLOR 11
        PRINT CHR$(64 + s); ")  "; capital$(choice(s))
    NEXT s

    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL (k$ >= "A" AND k$ <= "D" AND LEN(k$) = 1) OR k$ = CHR$(27)
    IF k$ = CHR$(27) THEN EXIT FOR
    picked = ASC(k$) - 64

    LOCATE 26, 22
    IF picked = correctSlot THEN
        COLOR 10: PRINT "Correct! "; capital$(ans); " is the capital of "; country$(ans); "."
        score = score + 1
        PLAY "T220 O4 G16 O5 C8"
    ELSE
        COLOR 12: PRINT "Not this time - it's "; capital$(ans); "."
        PLAY "T200 O2 C8"
    END IF
    COLOR 7: LOCATE 28, 30: PRINT "Press a key...";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT q

CLS
COLOR 14: LOCATE 12, 25: PRINT "Final score:"; score; "out of 10"
LOCATE 14, 25: COLOR 13
IF score >= 8 THEN PRINT "World traveller! Fantastic!" ELSE PRINT "Great exploring - try again!"
LOCATE 16, 25: COLOR 7: PRINT "Press a key.";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0
END

' ------------------------------------------------------------
' DrawFlag: draws a 240 x 160 flag at the top centre of the screen.
' ------------------------------------------------------------
SUB DrawFlag (kind$, c1, c2, c3)
    x0 = 200: y0 = 60: w = 240: h = 160
    SELECT CASE kind$
        CASE "V"            ' three equal stripes, left to right
            LINE (x0, y0)-(x0 + 80, y0 + h), c1, BF
            LINE (x0 + 80, y0)-(x0 + 160, y0 + h), c2, BF
            LINE (x0 + 160, y0)-(x0 + w, y0 + h), c3, BF
        CASE "H"            ' three equal stripes, top to bottom
            LINE (x0, y0)-(x0 + w, y0 + 53), c1, BF
            LINE (x0, y0 + 53)-(x0 + w, y0 + 106), c2, BF
            LINE (x0, y0 + 106)-(x0 + w, y0 + h), c3, BF
        CASE "J"            ' a disc in the middle
            LINE (x0, y0)-(x0 + w, y0 + h), c1, BF
            CIRCLE (x0 + w / 2, y0 + h / 2), 48, c2
            PAINT (x0 + w / 2, y0 + h / 2), c2, c2
        CASE "X"            ' Nordic cross: the upright is left of centre
            LINE (x0, y0)-(x0 + w, y0 + h), c1, BF
            LINE (x0, y0 + 60)-(x0 + w, y0 + 100), c2, BF
            LINE (x0 + 70, y0)-(x0 + 110, y0 + h), c2, BF
            IF c3 >= 0 THEN
                LINE (x0, y0 + 70)-(x0 + w, y0 + 90), c3, BF
                LINE (x0 + 80, y0)-(x0 + 100, y0 + h), c3, BF
            END IF
    END SELECT
    LINE (x0 - 1, y0 - 1)-(x0 + w + 1, y0 + h + 1), 7, B   ' grey frame
    LINE (x0 - 6, y0 - 4)-(x0 - 3, y0 + 185), 6, BF       ' flag pole!
END SUB

' Number of countries, then: country, capital, kind, c1, c2, c3
DATA 16
DATA France, Paris, V, 1, 15, 4
DATA Italy, Rome, V, 2, 15, 4
DATA Ireland, Dublin, V, 2, 15, 6
DATA Belgium, Brussels, V, 0, 14, 4
DATA Germany, Berlin, H, 0, 4, 14
DATA Netherlands, Amsterdam, H, 4, 15, 1
DATA Russia, Moscow, H, 15, 1, 4
DATA Austria, Vienna, H, 4, 15, 4
DATA Hungary, Budapest, H, 4, 15, 2
DATA Estonia, Tallinn, H, 9, 0, 15
DATA Japan, Tokyo, J, 15, 4, 0
DATA Bangladesh, Dhaka, J, 2, 4, 0
DATA Sweden, Stockholm, X, 1, 14, -1
DATA Denmark, Copenhagen, X, 4, 15, -1
DATA Finland, Helsinki, X, 15, 1, -1
DATA Norway, Oslo, X, 4, 15, 1
