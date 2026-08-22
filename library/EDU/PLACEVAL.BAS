' ============================================================
' TITLE:    Place Value Explorer
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     place value, digits, number words, expanded form, quiz
' SUMMARY:  Type any number to see its digits in place-value columns, in expanded form and in words.
' ------------------------------------------------------------
' WHAT IT DOES
'   In the number 4,072 the 4 is worth four THOUSAND, but in 40 it is
'   worth only four TENS.  Where a digit sits decides what it is worth
'   - that is place value.  Type a number and this program puts each
'   digit in its labelled, coloured column, writes the expanded form
'   (4000 + 70 + 2), spells the number in words and even draws base-10
'   blocks for small numbers.  Then try the quiz!
'
' HOW TO USE
'   E = explore a number (up to 9,999,999), Z = quiz, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Pulling digits out of a number with \ (integer divide) and MOD
'   * Building number words from small pieces (a classic puzzle)
'   * Arrays of strings for column names and words
'   * Why zero matters: it holds an empty place
'
' THINGS TO TRY
'   * Add decimals: tenths and hundredths columns
'   * Make the quiz ask "what digit is in the hundreds place?"
'   * Extend NumWords$ to billions
' ============================================================

DECLARE FUNCTION NumWords$ (n&)
DECLARE FUNCTION Under1000$ (n%)
DIM SHARED ones$(0 TO 19), tens$(2 TO 9)
DIM placeName$(1 TO 7), placeVal&(1 TO 7)
FOR i = 0 TO 19: READ ones$(i): NEXT i
FOR i = 2 TO 9: READ tens$(i): NEXT i
DATA zero, one, two, three, four, five, six, seven, eight, nine, ten
DATA eleven, twelve, thirteen, fourteen, fifteen, sixteen
DATA seventeen, eighteen, nineteen
DATA twenty, thirty, forty, fifty, sixty, seventy, eighty, ninety
' Columns from biggest to smallest
FOR i = 1 TO 7: READ placeName$(i), placeVal&(i): NEXT i
DATA Millions, 1000000, "Hundred Th", 100000, "Ten Thous", 10000
DATA Thousands, 1000, Hundreds, 100, Tens, 10, Ones, 1
RANDOMIZE TIMER

DO
    CLS
    COLOR 14: PRINT "  ======  PLACE VALUE EXPLORER  ======"
    COLOR 7: PRINT
    PRINT "  E) Explore a number    Z) Quiz    Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "E" THEN GOSUB Explore
    IF k$ = "Z" THEN GOSUB Quiz
LOOP
CLS
END

' ------------------------------------------------------------
Explore:
    PRINT
    LINE INPUT "  Type a whole number (0 to 9999999): "; a$
    n& = VAL(a$)
    IF n& < 0 OR n& > 9999999 THEN PRINT "  Out of range!": SLEEP 2: RETURN
    CLS
    COLOR 14: PRINT "  Your number: "; : COLOR 15: PRINT USING "#,###,###"; n&
    PRINT
    ' --- the place value chart ---
    ' Digit for a column = (n \ columnValue) MOD 10
    ' e.g. 4072 \ 100 = 40, and 40 MOD 10 = 0 -> zero hundreds.
    started = 0
    FOR i = 1 TO 7
        d = (n& \ placeVal&(i)) MOD 10
        IF d > 0 OR i = 7 THEN started = -1      ' skip leading zeros
        LOCATE 4, 3 + (i - 1) * 11: COLOR i + 8
        PRINT LEFT$(placeName$(i) + SPACE$(10), 10);
        LOCATE 5, 3 + (i - 1) * 11: COLOR 15, i
        IF started THEN PRINT "    "; d; "   "; ELSE PRINT "          ";
        COLOR 7, 0
    NEXT i

    ' --- expanded form: add up each digit times its column value ---
    LOCATE 8, 3: COLOR 11: PRINT "Expanded form: ";
    first = -1
    FOR i = 1 TO 7
        d = (n& \ placeVal&(i)) MOD 10
        IF d > 0 THEN
            IF NOT first THEN PRINT " + ";
            PRINT LTRIM$(STR$(d * placeVal&(i)));
            first = 0
        END IF
    NEXT i
    IF n& = 0 THEN PRINT "0";
    PRINT

    LOCATE 10, 3: COLOR 10: PRINT "In words: ";
    w$ = NumWords$(n&)
    ' Wrap long words so they stay on screen
    DO WHILE LEN(w$) > 64
        cut = 64
        DO WHILE MID$(w$, cut, 1) <> " ": cut = cut - 1: LOOP
        PRINT LEFT$(w$, cut): PRINT "            ";
        w$ = MID$(w$, cut + 1)
    LOOP
    PRINT w$

    ' --- base-10 blocks for numbers below 1000 ---
    IF n& < 1000 THEN
        h = n& \ 100: t = (n& \ 10) MOD 10: o = n& MOD 10
        LOCATE 14, 3: COLOR 7: PRINT "Base-10 blocks:  ";
        COLOR 13: PRINT "[##]=100  ";: COLOR 11: PRINT "|=10  ";: COLOR 14: PRINT "o=1"
        LOCATE 16, 3
        COLOR 13: FOR i = 1 TO h: PRINT "[##] ";: NEXT i
        COLOR 11: FOR i = 1 TO t: PRINT "| ";: NEXT i
        COLOR 14: FOR i = 1 TO o: PRINT "o ";: NEXT i
    END IF
    COLOR 7: LOCATE 22, 3: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' Quiz: "What is the 7 worth in 47,302?"  Answer: 7000.
' ------------------------------------------------------------
Quiz:
    score = 0
    FOR q = 1 TO 8
        CLS
        ' Make a 5-digit number with all different digits so the
        ' question is never ambiguous.
        used$ = "": n& = 0
        FOR i = 1 TO 5
            DO
                d = INT(RND * 10)
                IF i = 1 AND d = 0 THEN d = 1 + INT(RND * 9)   ' no leading zero
            LOOP WHILE INSTR(used$, LTRIM$(STR$(d))) > 0
            used$ = used$ + LTRIM$(STR$(d))
            n& = n& * 10 + d
        NEXT i
        DO: p = INT(RND * 5) + 1: LOOP WHILE MID$(used$, p, 1) = "0"
        d = VAL(MID$(used$, p, 1))
        worth& = d * 10 ^ (5 - p)
        COLOR 14: LOCATE 2, 3: PRINT "Question"; q; "of 8   Score:"; score
        COLOR 15: LOCATE 5, 3: PRINT "In the number ";
        COLOR 11: PRINT USING "##,###"; n&;
        COLOR 15: PRINT " what is the digit"; d; "worth?"
        LOCATE 7, 3: LINE INPUT "Your answer: "; a$
        IF UCASE$(a$) = "Q" THEN RETURN
        ' allow commas in the answer: 7,000
        clean$ = ""
        FOR i = 1 TO LEN(a$)
            IF MID$(a$, i, 1) <> "," THEN clean$ = clean$ + MID$(a$, i, 1)
        NEXT i
        LOCATE 9, 3
        IF VAL(clean$) = worth& AND LEN(clean$) > 0 THEN
            COLOR 10: PRINT "Correct! ";: score = score + 1
        ELSE
            COLOR 12: PRINT "Not quite. ";
        END IF
        PRINT "The"; d; "is in the "; placeName$(2 + p); " place, so it is worth"; worth&
        COLOR 7: LOCATE 11, 3: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    NEXT q
    LOCATE 13, 3: COLOR 14: PRINT "Final score:"; score; "out of 8!"
    SLEEP 2
    RETURN

' ------------------------------------------------------------
' NumWords$: split into millions, thousands and the rest, each a
' number under 1000 that Under1000$ knows how to say.
' ------------------------------------------------------------
FUNCTION NumWords$ (n&)
    IF n& = 0 THEN NumWords$ = "zero": EXIT FUNCTION
    m% = n& \ 1000000
    th% = (n& \ 1000) MOD 1000
    r% = n& MOD 1000
    w$ = ""
    IF m% > 0 THEN w$ = Under1000$(m%) + " million"
    IF th% > 0 THEN
        IF w$ <> "" THEN w$ = w$ + " "
        w$ = w$ + Under1000$(th%) + " thousand"
    END IF
    IF r% > 0 THEN
        IF w$ <> "" THEN w$ = w$ + " "
        w$ = w$ + Under1000$(r%)
    END IF
    NumWords$ = w$
END FUNCTION

' Says 1..999: "three hundred and forty-two"
FUNCTION Under1000$ (n%)
    h% = n% \ 100: rest% = n% MOD 100
    w$ = ""
    IF h% > 0 THEN w$ = ones$(h%) + " hundred"
    IF rest% > 0 THEN
        IF w$ <> "" THEN w$ = w$ + " and "
        IF rest% < 20 THEN
            w$ = w$ + ones$(rest%)                ' 1..19 have their own words
        ELSE
            w$ = w$ + tens$(rest% \ 10)
            IF rest% MOD 10 > 0 THEN w$ = w$ + "-" + ones$(rest% MOD 10)
        END IF
    END IF
    Under1000$ = w$
END FUNCTION
