' ============================================================
' TITLE:    Unit Conversion Quiz
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     measurement, metric, multiplication, decimals, DATA
' SUMMARY:  Practise changing metres to centimetres, kilograms to grams, hours to minutes and more.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every unit is stored with how many "base units" it is worth
'   (for length the base unit is the millimetre, so 1 m = 1000 mm).
'   To convert, the program changes the amount into base units and
'   then into the new unit:  answer = amount * from / to.  The quiz
'   asks 10 questions and, after each one, explains whether to
'   multiply or divide and by how much.
'
' HOW TO USE
'   Choose a topic: 1 length, 2 mass, 3 capacity, 4 time, 5 mixed,
'   C = conversion chart, Q = quit.  Type answers (decimals allowed).
'
' CONCEPTS YOU WILL LEARN
'   * Converting through a common base unit
'   * Big unit -> small unit: MULTIPLY.  Small -> big: DIVIDE
'   * Comparing decimals safely with a small tolerance
'   * Records in DATA: topic, unit name, size in base units
'
' THINGS TO TRY
'   * Add imperial units: inches (25.4 mm), feet, miles
'   * Add a temperature topic (that needs a formula, not a factor!)
'   * Make a "fill the gap" question: 2 km = 2000 ?
' ============================================================

DECLARE FUNCTION Nice$ (x#)
CONST NU = 13
DIM topic(1 TO NU), uname$(1 TO NU), usize#(1 TO NU)
FOR i = 1 TO NU: READ topic(i), uname$(i), usize#(i): NEXT i
' topic: 1 length (base mm), 2 mass (base g), 3 capacity (base ml),
'        4 time (base s)
DATA 1, mm, 1, 1, cm, 10, 1, m, 1000, 1, km, 1000000
DATA 2, g, 1, 2, kg, 1000, 2, t, 1000000
DATA 3, ml, 1, 3, L, 1000
DATA 4, s, 1, 4, min, 60, 4, h, 3600, 4, day, 86400
DIM tname$(1 TO 4)
tname$(1) = "Length": tname$(2) = "Mass": tname$(3) = "Capacity": tname$(4) = "Time"
RANDOMIZE TIMER

DO
    CLS
    COLOR 14: PRINT "  ~~~ UNIT CONVERSION QUIZ ~~~"
    COLOR 7: PRINT
    PRINT "  1) Length    (mm, cm, m, km)"
    PRINT "  2) Mass      (g, kg, t = tonne)"
    PRINT "  3) Capacity  (ml, L = litre)"
    PRINT "  4) Time      (s, min, h = hour, day)"
    PRINT "  5) Mixed"
    PRINT "  C) Conversion chart     Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "C" THEN GOSUB Chart
    IF k$ >= "1" AND k$ <= "5" THEN t = VAL(k$): GOSUB Quiz
LOOP
CLS
END

' ------------------------------------------------------------
Chart:
    CLS
    COLOR 14: PRINT "  CONVERSION CHART": PRINT
    FOR tp = 1 TO 4
        COLOR 11: PRINT "  "; tname$(tp)
        COLOR 7
        ' Show each unit next to the smallest unit of its topic
        FOR i = 1 TO NU
            IF topic(i) = tp AND usize#(i) > 1 THEN
                FOR j = 1 TO NU            ' find the next smaller unit
                    IF topic(j) = tp AND usize#(j) < usize#(i) THEN sm = j
                NEXT j
                PRINT "     1 "; uname$(i); " = "; Nice$(usize#(i) / usize#(sm)); " "; uname$(sm)
            END IF
        NEXT i
    NEXT tp
    PRINT: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
Quiz:
    CLS
    score = 0
    FOR q = 1 TO 10
        IF t = 5 THEN tp = INT(RND * 4) + 1 ELSE tp = t
        ' choose two DIFFERENT units from this topic
        DO
            a = INT(RND * NU) + 1: b = INT(RND * NU) + 1
        LOOP UNTIL topic(a) = tp AND topic(b) = tp AND a <> b
        ' Choose an amount that gives a friendly answer: if converting
        ' to a bigger unit, use a multiple of the ratio.
        ratio# = usize#(a) / usize#(b)     ' how many b's in one a
        IF ratio# >= 1 THEN
            amount# = INT(RND * 9) + 1
            IF RND < .4 THEN amount# = amount# + .5   ' some halves
        ELSE
            amount# = (INT(RND * 9) + 1) / ratio# / 10 * INT(RND * 3 + 1)
            IF amount# < 1 THEN amount# = 1 / ratio#
        END IF
        answer# = amount# * ratio#

        COLOR 15
        PRINT USING "  ##) "; q;
        PRINT Nice$(amount#); " "; uname$(a); " = ? "; uname$(b); "   ";
        LINE INPUT r$
        IF UCASE$(r$) = "Q" THEN EXIT FOR
        ' Remove commas, then compare with a tiny tolerance because
        ' decimals inside a computer are not always exact.
        c$ = ""
        FOR i = 1 TO LEN(r$)
            IF MID$(r$, i, 1) <> "," THEN c$ = c$ + MID$(r$, i, 1)
        NEXT i
        IF ABS(VAL(c$) - answer#) < .0001 * (1 + ABS(answer#)) AND LEN(c$) > 0 THEN
            score = score + 1
            COLOR 10: PRINT "      Correct!"
        ELSE
            COLOR 12: PRINT "      It is "; Nice$(answer#); " "; uname$(b); ".  ";
            IF ratio# > 1 THEN
                PRINT "Big to small: MULTIPLY by "; Nice$(ratio#)
            ELSE
                PRINT "Small to big: DIVIDE by "; Nice$(1 / ratio#)
            END IF
        END IF
    NEXT q
    COLOR 14: PRINT: PRINT "  You scored"; score; "out of 10. ";
    IF score >= 8 THEN PRINT "Measured to perfection!" ELSE PRINT "Good effort - check the chart (C)!"
    COLOR 7: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

' Nice$: a number without the leading space, and without the ugly
' scientific notation that STR$ uses for big or tiny numbers.
FUNCTION Nice$ (x#)
    ' (work on a copy: changing x# itself would change the caller's
    ' variable, because BASIC passes variables by reference)
    y# = INT(x# * 10000 + .5) / 10000       ' round to 4 decimal places
    whole# = INT(y#)
    frac# = y# - whole#
    w$ = ""
    ' build the whole part digit by digit (STR$ would say 1E+06)
    IF whole# = 0 THEN w$ = "0"
    DO WHILE whole# > 0
        d = whole# - INT(whole# / 10) * 10
        w$ = CHR$(48 + d) + w$
        whole# = INT(whole# / 10)
    LOOP
    IF frac# > 0 THEN
        f$ = MID$(STR$(INT(frac# * 10000 + .5) + 10000), 3)   ' 4 digits
        DO WHILE RIGHT$(f$, 1) = "0": f$ = LEFT$(f$, LEN(f$) - 1): LOOP
        w$ = w$ + "." + f$
    END IF
    Nice$ = w$
END FUNCTION
