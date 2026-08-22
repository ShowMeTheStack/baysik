' ============================================================
' TITLE:    What Time Is It?
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     time, clock, trigonometry, graphics, quiz
' SUMMARY:  Read the hands on a big analog clock and type the time - ten rounds per game.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a colourful clock face with an hour hand and a minute hand
'   pointing at a random time.  You type the time you see, like 3:45.
'   Easy mode uses o'clock and half past; medium uses quarters; hard
'   uses any 5 minutes.  If you get it wrong, the program explains
'   how to read each hand.
'
' HOW TO USE
'   Pick a level 1-3.  For each clock type the time as H:MM (for
'   example 7:05 or 12:30) and press Enter.  Type Q to stop early.
'
' CONCEPTS YOU WILL LEARN
'   * Turning a time into angles: 6 degrees per minute, 30 per hour
'   * SIN and COS to find points around a circle
'   * Why the hour hand moves a little between the numbers
'   * Splitting text with INSTR, LEFT$ and MID$
'
' THINGS TO TRY
'   * Add a red second hand that ticks using TIMER
'   * Show the time in words too: "quarter to four"
'   * Draw Roman numerals instead of 1-12
' ============================================================

DECLARE SUB DrawClock (h!, m!)
DECLARE SUB Hand (angleDeg!, length!, col!, thick!)

CONST PI = 3.14159265#
CONST CX = 320, CY = 220, R = 150      ' clock centre and radius
RANDOMIZE TIMER

SCREEN 12
COLOR 14: LOCATE 2, 30: PRINT "WHAT TIME IS IT?"
COLOR 15
LOCATE 5, 20: PRINT "1 = o'clock and half past"
LOCATE 6, 20: PRINT "2 = quarter past and quarter to"
LOCATE 7, 20: PRINT "3 = any five minutes"
LOCATE 9, 20: PRINT "Choose a level (1-3), Q to quit: ";
DO
    k$ = UCASE$(INKEY$)
LOOP UNTIL (k$ >= "1" AND k$ <= "3" AND k$ <> "") OR k$ = "Q" OR k$ = CHR$(27)
IF k$ = "Q" OR k$ = CHR$(27) THEN SCREEN 0: END
level = VAL(k$)

score = 0
FOR round = 1 TO 10
    ' --- choose a time to show ---
    h = INT(RND * 12) + 1
    SELECT CASE level
        CASE 1: m = INT(RND * 2) * 30          ' 0 or 30
        CASE 2: m = INT(RND * 4) * 15          ' 0, 15, 30, 45
        CASE ELSE: m = INT(RND * 12) * 5       ' 0, 5, 10 ... 55
    END SELECT

    CLS
    DrawClock h, m
    COLOR 14: LOCATE 1, 2: PRINT "Clock"; round; "of 10"; TAB(60); "Score:"; score
    COLOR 15: LOCATE 27, 25: PRINT "What time is it (H:MM)? ";
    LINE INPUT a$
    a$ = UCASE$(LTRIM$(RTRIM$(a$)))
    IF a$ = "Q" THEN EXIT FOR

    ' --- split the answer at the colon ---
    c = INSTR(a$, ":")
    IF c = 0 THEN c = INSTR(a$, ".")      ' allow 3.45 too
    IF c > 0 THEN
        ah = VAL(LEFT$(a$, c - 1)): am = VAL(MID$(a$, c + 1))
    ELSE
        ah = VAL(a$): am = 0               ' "3" means 3 o'clock
    END IF

    LOCATE 28, 10
    IF ah = h AND am = m THEN
        COLOR 10: PRINT "Brilliant! That's right!";
        score = score + 1
        SOUND 880, 2
    ELSE
        COLOR 12
        PRINT USING "It is ##:##.  "; h; m;
        ' Explain how to read it
        IF m = 0 THEN
            PRINT "Long hand on 12 means o'clock.";
        ELSE
            PRINT "Long hand on"; m \ 5; "means"; m; "minutes.";
        END IF
    END IF
    COLOR 7: LOCATE 29, 25: PRINT "Press a key for the next clock";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
NEXT round

CLS
COLOR 14: LOCATE 12, 25: PRINT "You read"; score; "clocks correctly!"
LOCATE 14, 25
IF score >= 9 THEN PRINT "You are a real time-teller!" ELSE PRINT "Keep practising - you are getting there!"
LOCATE 16, 25: COLOR 7: PRINT "Press a key to finish.";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0
END

' ------------------------------------------------------------
' DrawClock: face, tick marks, numbers and two hands.
' ------------------------------------------------------------
SUB DrawClock (h, m)
    CIRCLE (CX, CY), R + 8, 9
    CIRCLE (CX, CY), R, 15
    PAINT (CX, CY), 1, 15                  ' dark blue face
    ' 60 tick marks; every fifth one (an hour) is longer
    FOR t = 0 TO 59
        a = t * 6 * PI / 180
        IF t MOD 5 = 0 THEN inner = R - 15 ELSE inner = R - 6
        LINE (CX + inner * SIN(a), CY - inner * COS(a))-(CX + R * SIN(a), CY - R * COS(a)), 15
    NEXT t
    ' Numbers: find the pixel position, then convert it to a text
    ' cell (each character in SCREEN 12 is 8 pixels wide, 16 tall).
    FOR n = 1 TO 12
        a = n * 30 * PI / 180
        x = CX + (R - 32) * SIN(a)
        y = CY - (R - 32) * COS(a)
        n$ = LTRIM$(STR$(n))
        col = INT(x / 8) + 1 - LEN(n$) \ 2
        row = INT(y / 16) + 1
        LOCATE row, col: COLOR 14: PRINT n$;
    NEXT n
    ' The minute hand turns 6 degrees per minute (360 / 60).
    ' The hour hand turns 30 degrees per hour (360 / 12) PLUS half a
    ' degree per minute, so at 2:30 it sits halfway between 2 and 3.
    Hand m * 6, R - 25, 11, 2
    Hand (h MOD 12) * 30 + m * .5, R - 65, 12, 3
    CIRCLE (CX, CY), 5, 15
    PAINT (CX, CY), 15
END SUB

' Draws a thick hand by drawing a few lines side by side.
SUB Hand (angleDeg, length, col, thick)
    a = angleDeg * PI / 180
    ex = CX + length * SIN(a)
    ey = CY - length * COS(a)            ' minus: screen y grows downward
    FOR d = -thick TO thick
        LINE (CX + d, CY)-(ex + d, ey), col
        LINE (CX, CY + d)-(ex, ey + d), col
    NEXT d
END SUB
