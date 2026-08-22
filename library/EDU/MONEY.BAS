' ============================================================
' TITLE:    Counting Money
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     money, coins, addition, graphics, decimals
' SUMMARY:  Count the coins and bills on the table, then try making exact change at the toy shop.
' ------------------------------------------------------------
' WHAT IT DOES
'   Game 1 "Count it": a handful of coins (and sometimes bills) is
'   drawn on the screen.  Add them up and type the total.
'   Game 2 "Toy shop": a toy has a price.  Press number keys to drop
'   coins on the counter until you have paid EXACTLY the right
'   amount.  Each coin is drawn in its own size and colour, labelled
'   with its value in cents (1c, 5c, 10c, 25c) or dollars ($1, $5).
'
' HOW TO USE
'   Choose 1 or 2 from the menu.  In "Count it", type the amount like
'   1.35 and press Enter.  In "Toy shop", press 1-6 to add a coin, U to
'   take the last coin back.  Q goes back / quits.
'
' CONCEPTS YOU WILL LEARN
'   * Working in whole cents to avoid decimal rounding troubles
'   * Arrays for coin values, sizes and colours
'   * Drawing with CIRCLE, PAINT and LINE ... BF
'   * PRINT USING "$$#.##" for money formatting
'
' THINGS TO TRY
'   * Change the coins to your own country's money
'   * In the toy shop, count how few coins you can use
'   * Add a "give change" game: pay $5 and work out the change
' ============================================================

DECLARE SUB DrawCoin (k!, x!, y!)
DIM SHARED value(1 TO 6), rad(1 TO 6), col(1 TO 6), label$(1 TO 6)
' Value of each kind of money IN CENTS.  Using whole numbers of
' cents means 0.1 + 0.2 problems never happen.
FOR k = 1 TO 6: READ value(k), rad(k), col(k), label$(k): NEXT k
DATA 1, 14, 6, "1c", 5, 18, 7, "5c", 10, 13, 7, "10c"
DATA 25, 22, 7, "25c", 100, 0, 2, "$1", 500, 0, 10, "$5"
DIM taken(1 TO 18)            ' coins put down in the toy shop
RANDOMIZE TIMER
SCREEN 12

DO
    CLS
    COLOR 14: LOCATE 4, 30: PRINT "COUNTING MONEY"
    FOR k = 1 TO 6: DrawCoin k, 120 + (k - 1) * 80, 140: NEXT k
    COLOR 15
    LOCATE 14, 25: PRINT "1) Count it"
    LOCATE 15, 25: PRINT "2) Toy shop"
    LOCATE 16, 25: PRINT "Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "1" THEN GOSUB CountIt
    IF k$ = "2" THEN GOSUB ToyShop
LOOP
SCREEN 0
PRINT "Money sense makes cents! Bye."
END

' ------------------------------------------------------------
' CountIt: five rounds of "how much is here?"
' ------------------------------------------------------------
CountIt:
    score = 0
    FOR round = 1 TO 5
        CLS
        COLOR 14: LOCATE 2, 3: PRINT "Round"; round; "of 5 - how much money is here?"
        ' Rounds 1-2 use only coins, later rounds may include bills
        IF round <= 2 THEN maxKind = 4 ELSE maxKind = 6
        n = INT(RND * 5) + 3             ' 3 to 7 pieces of money
        total = 0
        FOR i = 1 TO n
            k = INT(RND * maxKind) + 1
            total = total + value(k)
            ' place them in two rows so they don't overlap
            DrawCoin k, 70 + ((i - 1) MOD 4) * 150, 140 + ((i - 1) \ 4) * 110
        NEXT i
        COLOR 15: LOCATE 22, 10: PRINT "Type the total (for example 1.35): ";
        LINE INPUT a$
        IF UCASE$(a$) = "Q" THEN RETURN
        ' Remove a "$" if typed, then turn dollars into whole cents
        IF LEFT$(a$, 1) = "$" THEN a$ = MID$(a$, 2)
        guess = INT(VAL(a$) * 100 + .5)
        LOCATE 24, 10
        IF guess = total THEN
            COLOR 10: PRINT "Yes! ";: score = score + 1
        ELSE
            COLOR 12: PRINT "Not quite. ";
        END IF
        PRINT USING "There is $$#.## here."; total / 100
        LOCATE 26, 10: COLOR 7: PRINT "Tip: count the biggest money first, then add the small coins.";
        LOCATE 28, 10: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    NEXT round
    CLS: LOCATE 12, 25: COLOR 14: PRINT "You counted"; score; "of 5 correctly!"
    LOCATE 14, 25: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' ToyShop: pay an exact price by adding coins one at a time.
' ------------------------------------------------------------
ToyShop:
    RESTORE Toys
    nToys = 6
    t = INT(RND * nToys) + 1
    FOR i = 1 TO t: READ toy$, price: NEXT i
    paid = 0: nTaken = 0
    DO
        CLS
        COLOR 14: LOCATE 2, 3: PRINT "TOY SHOP:  The "; toy$; " costs ";
        PRINT USING "$$#.##"; price / 100
        COLOR 15: LOCATE 4, 3
        PRINT "Press 1=1c 2=5c 3=10c 4=25c 5=$1 6=$5   U=undo   Q=leave shop"
        ' Draw the coins on the counter so far
        FOR i = 1 TO nTaken
            DrawCoin taken(i), 60 + ((i - 1) MOD 6) * 100, 130 + ((i - 1) \ 6) * 80
        NEXT i
        COLOR 11: LOCATE 25, 3: PRINT USING "You have paid $$#.##"; paid / 100
        LOCATE 26, 3
        IF paid = price THEN
            COLOR 10: PRINT "EXACTLY RIGHT! Here is your "; toy$; ". Thank you!"
            PLAY "T180 O4 C8 E8 G8 O5 C4"
            LOCATE 28, 3: COLOR 7: PRINT "Press a key...";
            DO: LOOP WHILE INKEY$ = ""
            RETURN
        ELSEIF paid > price THEN
            COLOR 12: PRINT "Too much! Press U to take a coin back."
        ELSE
            COLOR 7: PRINT USING "Still to pay: $$#.##"; (price - paid) / 100
        END IF
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        IF k$ = "Q" OR k$ = CHR$(27) THEN RETURN
        IF k$ = "U" AND nTaken > 0 THEN
            paid = paid - value(taken(nTaken)): nTaken = nTaken - 1
        ELSEIF k$ >= "1" AND k$ <= "6" AND nTaken < 18 THEN
            nTaken = nTaken + 1: taken(nTaken) = VAL(k$)
            paid = paid + value(taken(nTaken))
        END IF
    LOOP

Toys:
DATA "toy car", 135, "bouncy ball", 60, "kite", 245
DATA "teddy bear", 580, "yo-yo", 87, "comic book", 199

' ------------------------------------------------------------
' DrawCoin: coins are circles (radius rad), bills are rectangles.
' ------------------------------------------------------------
SUB DrawCoin (k, x, y)
    IF value(k) >= 100 THEN
        ' A bill: green rectangle with a border and an oval in the middle
        LINE (x - 45, y - 22)-(x + 45, y + 22), col(k), BF
        LINE (x - 41, y - 18)-(x + 41, y + 18), 15, B
        CIRCLE (x, y), 14, 15, , , .7
    ELSE
        CIRCLE (x, y), rad(k), 15
        PAINT (x, y), col(k), 15
        CIRCLE (x, y), rad(k) - 3, 0          ' an inner rim line
    END IF
    ' Label the value under the money
    COLOR 14
    LOCATE INT((y + 30) / 16) + 1, INT(x / 8) + 1 - LEN(label$(k)) \ 2
    PRINT label$(k);
END SUB
