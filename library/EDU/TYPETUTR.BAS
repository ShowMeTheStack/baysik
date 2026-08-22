' ============================================================
' TITLE:    Typing Tutor
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     typing, keyboard, INKEY$, timer, words per minute
' SUMMARY:  Learn touch typing row by row with a glowing on-screen keyboard and a WPM score.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a line of practice text and an on-screen keyboard.  The key
'   you should press next lights up.  As you type, correct letters
'   turn green and mistakes turn red (with a little buzz).  When the
'   line is finished you get your speed in words per minute (WPM) and
'   your accuracy.  Lessons go from the home row up to whole
'   sentences.
'
' HOW TO USE
'   Choose a lesson 1-5.  Type the text exactly as shown.  You cannot
'   go on until you press the right key, so look at the screen, not
'   your fingers!  Esc returns to the menu; Q on the menu quits.
'
' CONCEPTS YOU WILL LEARN
'   * Reading single keys with INKEY$ without pressing Enter
'   * Measuring time with TIMER and computing a rate
'   * The typing world's rule: one "word" = 5 characters
'   * Finding a character's position on a drawn keyboard with INSTR
'
' THINGS TO TRY
'   * Add a lesson with numbers and symbols
'   * Pick a random line from several for each lesson
'   * Show which key you got wrong most often
' ============================================================

DECLARE SUB DrawKeyboard (hi$)

DIM SHARED row$(1 TO 3)
row$(1) = "qwertyuiop"
row$(2) = "asdfghjkl;"
row$(3) = "zxcvbnm,./"

DO
    CLS
    COLOR 14: PRINT "  ****  TYPING TUTOR  ****"
    COLOR 7: PRINT
    PRINT "  1) Home row         (a s d f   j k l ;)"
    PRINT "  2) Top row          (q w e r t y u i o p)"
    PRINT "  3) Bottom row       (z x c v b n m)"
    PRINT "  4) Easy words"
    PRINT "  5) Whole sentences"
    PRINT "  Q) Quit"
    PRINT
    COLOR 11
    PRINT "  Tip: rest your fingers on A S D F and J K L ;"
    PRINT "  The F and J keys have little bumps to help you find them."
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ >= "1" AND k$ <= "5" THEN
        ' Pick the practice text for the lesson
        SELECT CASE VAL(k$)
            CASE 1: t$ = "asdf jkl; fjdk slaj fads lass jall dads asks"
            CASE 2: t$ = "were trip quit your type pour tire wipe pretty"
            CASE 3: t$ = "zinc mix cab vex numb box calm men van bank"
            CASE 4: t$ = "the sun is hot and the sky is blue today"
            CASE 5: t$ = "Practice every day. Slow and steady wins the race!"
        END SELECT
        GOSUB TypeLine
    END IF
LOOP
CLS
PRINT "Happy typing!"
END

' ------------------------------------------------------------
' TypeLine: the actual exercise.
' ------------------------------------------------------------
TypeLine:
    CLS
    COLOR 14: LOCATE 2, 5: PRINT "Type this line:"
    COLOR 8: LOCATE 4, 5: PRINT t$          ' grey until typed
    p = 1: errors = 0: started = 0
    DO WHILE p <= LEN(t$)
        want$ = MID$(t$, p, 1)
        DrawKeyboard LCASE$(want$)
        LOCATE 4, 4 + p, 1                    ' blinking cursor on the letter
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        IF k$ = CHR$(27) THEN RETURN
        ' Start the clock on the first key, not when the screen appears
        IF NOT started THEN t0 = TIMER: started = -1
        IF k$ = want$ THEN
            COLOR 10: LOCATE 4, 4 + p: PRINT want$;
            p = p + 1
        ELSE
            errors = errors + 1
            COLOR 12: LOCATE 4, 4 + p: PRINT want$;   ' show this one in red
            SOUND 150, 1
        END IF
    LOOP
    secs = TIMER - t0
    IF secs < 0 THEN secs = secs + 86400
    IF secs < 1 THEN secs = 1
    LOCATE , , 0                              ' hide the cursor again

    ' Typists count a "word" as 5 keystrokes (including spaces).
    wpm = (LEN(t$) / 5) / (secs / 60)
    accuracy = 100 * LEN(t$) / (LEN(t$) + errors)
    COLOR 15
    LOCATE 18, 5: PRINT USING "Time: ###.# seconds"; secs
    LOCATE 19, 5: PRINT USING "Speed: ### words per minute"; wpm
    LOCATE 20, 5: PRINT USING "Accuracy: ###%  (## mistakes)"; accuracy; errors
    LOCATE 22, 5: COLOR 13
    IF accuracy >= 95 THEN
        PRINT "Excellent accuracy! Now try to go a little faster."
    ELSE
        PRINT "Slow down a little - accuracy first, speed comes later."
    END IF
    COLOR 7: LOCATE 24, 5: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' DrawKeyboard: three rows of keys, each row shifted right like a
' real keyboard.  The key in hi$ is drawn highlighted.
' ------------------------------------------------------------
SUB DrawKeyboard (hi$)
    FOR r = 1 TO 3
        x = 10 + (r - 1) * 2                 ' stagger the rows
        FOR i = 1 TO 10
            c$ = MID$(row$(r), i, 1)
            IF c$ = hi$ THEN COLOR 0, 14 ELSE COLOR 7, 1
            LOCATE 6 + r * 2, x + (i - 1) * 4
            PRINT " "; UCASE$(c$); " ";
            COLOR 7, 0
        NEXT i
    NEXT r
    ' Space bar
    IF hi$ = " " THEN COLOR 0, 14 ELSE COLOR 7, 1
    LOCATE 14, 20: PRINT "     SPACE      ";
    COLOR 7, 0
    ' Which hand should press it?  Left half of each row = left hand.
    LOCATE 16, 10
    hand$ = ""
    FOR r = 1 TO 3
        idx = INSTR(row$(r), hi$)
        IF idx > 0 THEN IF idx <= 5 THEN hand$ = "LEFT" ELSE hand$ = "RIGHT"
    NEXT r
    msg$ = ""
    IF hand$ <> "" THEN msg$ = "Use your " + hand$ + " hand"
    IF hi$ = " " THEN msg$ = "Use a THUMB on the space bar"
    COLOR 11: PRINT LEFT$(msg$ + SPACE$(40), 40);: COLOR 7
END SUB
