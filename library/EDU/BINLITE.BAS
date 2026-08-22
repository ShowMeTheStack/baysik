' ============================================================
' TITLE:    Binary Light Bulbs
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     binary, bits, place value, AND, graphics
' SUMMARY:  Eight light bulbs count in binary - watch them, flip them yourself, then make target numbers.
' ------------------------------------------------------------
' WHAT IT DOES
'   Computers store numbers as rows of switches that are ON (1) or
'   OFF (0).  Here each switch is a light bulb.  Each bulb is worth
'   double the one to its right: 1, 2, 4, 8, 16, 32, 64, 128.  Add up
'   the lit bulbs to get the number.
'     A) Auto-count: the bulbs count 0, 1, 2, 3 ... by themselves.
'     F) Flip:       press keys 1-8 to switch bulbs on and off.
'     Z) Challenge:  light up the bulbs to make a target number.
'
' HOW TO USE
'   Choose A, F or Z.  In Flip and Challenge, keys 1-8 toggle bulbs
'   (key 1 is the right-most bulb, worth 1).  Enter checks your
'   answer in the challenge.  Esc goes back, Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Binary place value: each place is worth 2x the one before
'   * Testing a bit with AND:  (n AND 4) <> 0 means the "4" bulb is on
'   * Flipping a bit with XOR
'   * Animation timed with TIMER
'
' THINGS TO TRY
'   * Make it 10 bulbs - what is the biggest number now?
'   * Show the number in hexadecimal too with HEX$
'   * Count DOWN, or count only odd numbers - which bulb never goes out?
' ============================================================

DECLARE SUB ShowBulbs (n!, msg$)
SCREEN 12
RANDOMIZE TIMER

DO
    ShowBulbs 0, "A = auto-count   F = flip bulbs   Z = challenge   Q = quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "A": GOSUB AutoCount
        CASE "F": GOSUB Flip
        CASE "Z": GOSUB Challenge
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0
END

' ------------------------------------------------------------
AutoCount:
    FOR n = 0 TO 255
        ShowBulbs n, "Counting...  any key = stop"
        t0 = TIMER
        DO
            IF INKEY$ <> "" THEN RETURN
        LOOP WHILE TIMER - t0 < .6 AND TIMER >= t0
    NEXT n
    RETURN

' ------------------------------------------------------------
Flip:
    n = 0
    DO
        ShowBulbs n, "Keys 1-8 flip a bulb (1 = right-most).  Esc = back"
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
        IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN RETURN
        IF k$ >= "1" AND k$ <= "8" THEN
            ' Key 1 -> bit worth 1, key 2 -> 2, key 3 -> 4 ... key 8 -> 128
            bitVal = 2 ^ (VAL(k$) - 1)
            n = n XOR bitVal           ' XOR flips just that one bit
        END IF
    LOOP

' ------------------------------------------------------------
Challenge:
    score = 0
    FOR round = 1 TO 5
        target = INT(RND * 255) + 1
        n = 0
        DO
            ShowBulbs n, "Make" + STR$(target) + " !  Keys 1-8 flip, Enter = check   (score" + STR$(score) + ")"
            DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
            IF k$ = CHR$(27) THEN RETURN
            IF k$ >= "1" AND k$ <= "8" THEN n = n XOR 2 ^ (VAL(k$) - 1)
        LOOP UNTIL k$ = CHR$(13)
        IF n = target THEN
            score = score + 1
            ShowBulbs n, "BRIGHT IDEA! That's right!  Press a key"
            PLAY "T200 O5 C16 E16 G8"
        ELSE
            ShowBulbs target, "Here is" + STR$(target) + " (you made" + STR$(n) + ").  Press a key"
        END IF
        DO: LOOP WHILE INKEY$ = ""
    NEXT round
    ShowBulbs 0, "You scored" + STR$(score) + " out of 5!  Press a key"
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' ShowBulbs: draw 8 bulbs for the number n plus the working-out.
' ------------------------------------------------------------
SUB ShowBulbs (n, msg$)
    CLS
    COLOR 14: LOCATE 2, 30: PRINT "BINARY LIGHT BULBS"
    total$ = "": bits$ = ""
    FOR i = 7 TO 0 STEP -1                ' i = bit number, 7 is on the left
        v = 2 ^ i                         ' what this bulb is worth
        x = 570 - i * 72                  ' bulb 0 on the right
        y = 160
        lit = (n AND v) <> 0              ' is this bit switched on?
        ' the glass bulb
        IF lit THEN
            CIRCLE (x, y), 28, 14: PAINT (x, y), 14, 14
            ' glow rays
            FOR a = 0 TO 7
                LINE (x + 32 * COS(a * .785), y + 32 * SIN(a * .785))-(x + 40 * COS(a * .785), y + 40 * SIN(a * .785)), 14
            NEXT a
            bits$ = bits$ + "1"
            IF total$ <> "" THEN total$ = total$ + " + "
            total$ = total$ + LTRIM$(STR$(v))
        ELSE
            CIRCLE (x, y), 28, 8: PAINT (x, y), 0, 8
            bits$ = bits$ + "0"
        END IF
        ' the metal screw base
        LINE (x - 12, y + 26)-(x + 12, y + 44), 7, BF
        LINE (x - 12, y + 32)-(x + 12, y + 32), 8
        LINE (x - 12, y + 38)-(x + 12, y + 38), 8
        ' labels: value and key number
        r = INT((y + 60) / 16) + 1
        c = INT(x / 8) + 1
        COLOR 11: LOCATE r, c - LEN(STR$(v)) \ 2: PRINT LTRIM$(STR$(v));
        COLOR 8: LOCATE r + 1, c - 2: PRINT "key"; i + 1;
        COLOR 15: LOCATE 6, c: IF lit THEN PRINT "1"; ELSE PRINT "0";
    NEXT i
    COLOR 15
    LOCATE 19, 10: PRINT "Binary:  "; bits$
    LOCATE 20, 10: PRINT "Decimal:"; n
    IF total$ = "" THEN total$ = "0"
    LOCATE 21, 10: COLOR 10: PRINT "Working out: "; total$; " ="; n
    COLOR 7: LOCATE 26, 4: PRINT msg$;
END SUB
