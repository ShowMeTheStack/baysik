' ============================================================
' TITLE:    Even or Odd Sorter
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     even, odd, MOD, game loop, SCREEN 13, speed
' SUMMARY:  Numbers fall from the sky - flick each one into the EVEN or ODD basket before it lands!
' ------------------------------------------------------------
' WHAT IT DOES
'   A number drops down the middle of the screen.  Press the LEFT
'   arrow (or E) to throw it into the EVEN basket, RIGHT arrow (or O)
'   for the ODD basket.  Correct sorts score points and the numbers
'   fall faster and get bigger as you go.  Three mistakes (or letting
'   a number hit the ground) and the game ends.
'
' HOW TO USE
'   Left / E = even, Right / O = odd, Esc = quit.
'   Remember the trick: only the LAST digit matters!
'   Ends in 0, 2, 4, 6, 8 -> even.  Ends in 1, 3, 5, 7, 9 -> odd.
'
' CONCEPTS YOU WILL LEARN
'   * n MOD 2 gives 0 for even numbers and 1 for odd numbers
'   * A game loop: move, draw, read keys, check, repeat
'   * Timing animation frames with TIMER so speed is the same on
'     every computer
'   * SCREEN 13: 320 x 200 pixels with 256 colours
'
' THINGS TO TRY
'   * Add a third basket for "multiples of 5"
'   * Show the last digit in a different colour as a hint
'   * Make the game last exactly 60 seconds instead of 3 lives
' ============================================================

DECLARE SUB DrawBaskets ()
RANDOMIZE TIMER
SCREEN 13

' Title screen
COLOR 14: LOCATE 5, 12: PRINT "EVEN or ODD?"
COLOR 15: LOCATE 9, 3: PRINT "LEFT arrow or E  = EVEN basket"
LOCATE 11, 3: PRINT "RIGHT arrow or O = ODD basket"
COLOR 11: LOCATE 14, 3: PRINT "Hint: only look at the LAST digit!"
LOCATE 16, 5: PRINT "0 2 4 6 8 = even   1 3 5 7 9 = odd"
COLOR 7: LOCATE 20, 8: PRINT "Press a key to start"
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN SCREEN 0: END

score = 0: lives = 3: speed = 25          ' speed in pixels per second
biggest = 20                              ' numbers go up to this
DO WHILE lives > 0
    n = INT(RND * biggest) + 1
    n$ = LTRIM$(STR$(n))
    y = 20                                ' the number's top edge in pixels
    lastT = TIMER
    choice = 0                            ' 1 = even, 2 = odd
    DO
        ' --- move: distance = speed x time since last frame ---
        now = TIMER
        dt = now - lastT: IF dt < 0 THEN dt = 0
        lastT = now
        y = y + speed * dt

        ' --- draw ---
        LINE (0, 0)-(319, 199), 0, BF      ' clear (cheap at 320x200)
        DrawBaskets
        COLOR 15: LOCATE 1, 1: PRINT "Score:"; score;
        LOCATE 1, 30: COLOR 12: PRINT "Lives:"; STRING$(lives, 3);
        ' Convert pixel y to a text row (8 pixels per row in SCREEN 13)
        row = INT(y / 8) + 1
        IF row > 22 THEN row = 22
        COLOR 14: LOCATE row, 21 - LEN(n$) \ 2: PRINT n$;

        ' --- keys ---
        k$ = INKEY$
        SELECT CASE UCASE$(k$)
            CASE "E", CHR$(0) + "K": choice = 1
            CASE "O", CHR$(0) + "M": choice = 2
            CASE CHR$(27): lives = 0: EXIT DO
        END SELECT
        IF choice > 0 THEN EXIT DO
        ' Wait a little so each frame is ~1/20 second
        t0 = TIMER: DO: LOOP WHILE TIMER - t0 < .05 AND TIMER >= t0
    LOOP UNTIL y >= 170                   ' it reached the ground!

    IF lives = 0 THEN EXIT DO
    ' --- check the answer ---
    ' n MOD 2 is the remainder after dividing by 2: 0 = even, 1 = odd
    IF n MOD 2 = 0 THEN correct = 1 ELSE correct = 2
    LOCATE 23, 1
    IF choice = 0 THEN
        lives = lives - 1
        COLOR 12: PRINT " Too slow! "; n$; " was ";
        IF correct = 1 THEN PRINT "EVEN"; ELSE PRINT "ODD";
        SOUND 120, 4
    ELSEIF choice = correct THEN
        score = score + 1
        COLOR 10: PRINT " Yes! "; n$; " ends in "; RIGHT$(n$, 1);
        SOUND 900, 1
        ' Every 5 points: faster and bigger numbers
        IF score MOD 5 = 0 THEN speed = speed + 8: biggest = biggest * 3
        IF biggest > 30000 THEN biggest = 30000
    ELSE
        lives = lives - 1
        COLOR 12: PRINT " Oops! "; n$; " ends in "; RIGHT$(n$, 1); " so it's ";
        IF correct = 1 THEN PRINT "EVEN"; ELSE PRINT "ODD";
        SOUND 120, 4
    END IF
    t0 = TIMER: DO: LOOP WHILE TIMER - t0 < 1 AND TIMER >= t0   ' pause 1 s
LOOP

LINE (0, 0)-(319, 199), 0, BF
COLOR 14: LOCATE 9, 14: PRINT "GAME OVER"
COLOR 15: LOCATE 12, 10: PRINT "You sorted"; score; "numbers!"
LOCATE 14, 8
IF score >= 15 THEN PRINT "You are an even/odd expert!" ELSE PRINT "Great sorting - play again!"
COLOR 7: LOCATE 18, 10: PRINT "Press a key to finish"
DO: LOOP WHILE INKEY$ = ""
SCREEN 0
END

' Two baskets at the bottom, labelled EVEN and ODD
SUB DrawBaskets
    LINE (10, 150)-(110, 185), 2, BF       ' green basket
    LINE (210, 150)-(310, 185), 5, BF      ' purple basket
    ' a criss-cross weave pattern on each basket
    FOR x = 10 TO 100 STEP 10
        LINE (x, 150)-(x + 10, 185), 10
        LINE (x + 200, 150)-(x + 210, 185), 13
    NEXT x
    COLOR 15
    LOCATE 25, 5: PRINT "<- EVEN";
    LOCATE 25, 30: PRINT "ODD ->";
END SUB
