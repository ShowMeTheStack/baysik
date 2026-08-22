' ============================================================
' TITLE:    Morse Code Trainer
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     morse code, SOUND, strings, lookup tables, history
' SUMMARY:  Hear and see Morse code: learn letters, take a listening quiz, or beep out your own messages.
' ------------------------------------------------------------
' WHAT IT DOES
'   Morse code turns letters into short beeps (dots) and long beeps
'   (dashes).  It was used to send messages along telegraph wires and
'   by radio - SOS is  ... --- ...
'     1) Learn:     press any letter or digit to see and hear its code.
'     2) Listen:    the computer beeps a letter; you type which one.
'     3) Translate: type a message and hear it sent in Morse.
'   A chart of the whole alphabet is shown in Learn mode.
'
' HOW TO USE
'   Choose 1-3 from the menu.  Esc goes back to the menu, Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * A lookup table: code$(ASC(letter)) holds each pattern
'   * SOUND frequency, duration (duration is in 1/18.2 s "ticks")
'   * Timing rules: dash = 3 dots, gap between letters = 3 dots
'   * Walking through a string with MID$
'
' THINGS TO TRY
'   * Change TICK to make the Morse faster or slower
'   * Reverse it: type dots and dashes and decode them to letters
'   * Flash a box on screen in time with the beeps (a signal lamp!)
' ============================================================

DECLARE SUB SendChar (c$)
DECLARE SUB Pause (units!)
DECLARE SUB ShowCode (c$, row!, col!)

CONST TICK = 1.5              ' length of one dot, in SOUND ticks
CONST PITCH = 700             ' beep frequency in hertz
DIM SHARED code$(0 TO 127)
' Fill the lookup table from DATA: character, pattern
FOR i = 1 TO 36
    READ c$, p$
    code$(ASC(c$)) = p$
NEXT i
RANDOMIZE TIMER

DO
    CLS
    COLOR 14: PRINT "  -.-. --- -.. .   MORSE CODE TRAINER   -.-. --- -.. ."
    COLOR 7: PRINT
    PRINT "  1) Learn the letters"
    PRINT "  2) Listening quiz"
    PRINT "  3) Translate a message"
    PRINT "  Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1": GOSUB Learn
        CASE "2": GOSUB Listen
        CASE "3": GOSUB Translate
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

' ------------------------------------------------------------
Learn:
    CLS
    COLOR 14: PRINT "  Press a letter or digit to hear it.  Esc = back": PRINT
    ' Print the chart in three columns
    FOR i = 0 TO 35
        IF i < 26 THEN c$ = CHR$(65 + i) ELSE c$ = CHR$(48 + i - 26)
        ShowCode c$, 4 + (i MOD 12), 3 + (i \ 12) * 25
    NEXT i
    DO
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        IF k$ = CHR$(27) OR k$ = "Q" THEN RETURN
        IF LEN(k$) = 1 THEN
            IF code$(ASC(k$)) <> "" THEN
                LOCATE 18, 3: PRINT SPACE$(60);
                ShowCode k$, 18, 30
                SendChar k$
            END IF
        END IF
    LOOP

' ------------------------------------------------------------
Listen:
    score = 0
    FOR q = 1 TO 10
        CLS
        COLOR 14: PRINT "  Listening quiz - question"; q; "of 10.  Score:"; score
        c$ = CHR$(65 + INT(RND * 26))       ' letters only
        COLOR 7: PRINT: PRINT "  Listen carefully... (press R to repeat)"
        SendChar c$
        DO
            LOCATE 6, 3: COLOR 15: PRINT "Which letter was that? ";
            DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
            IF k$ = "R" AND c$ <> "R" THEN SendChar c$
        LOOP WHILE k$ = "R" AND c$ <> "R"
        IF k$ = CHR$(27) THEN RETURN
        PRINT k$
        PRINT
        IF k$ = c$ THEN
            COLOR 10: PRINT "  Correct! ";: score = score + 1
        ELSE
            COLOR 12: PRINT "  It was ";
        END IF
        ShowCode c$, CSRLIN, POS(0)
        COLOR 7: PRINT: PRINT: PRINT "  Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    NEXT q
    PRINT: PRINT: COLOR 14: PRINT "  You scored"; score; "out of 10."
    IF score >= 8 THEN PRINT "  Excellent ears - you'd make a fine radio operator!"
    COLOR 7: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
Translate:
    CLS
    COLOR 14: PRINT "  Type a message (letters, digits, spaces):"
    COLOR 15: LINE INPUT "  > "; m$
    m$ = UCASE$(m$)
    PRINT
    COLOR 11: PRINT "  ";
    FOR i = 1 TO LEN(m$)
        c$ = MID$(m$, i, 1)
        IF c$ = " " THEN
            PRINT " / ";             ' / shows a gap between words
            Pause 7                  ' word gap = 7 dot lengths
        ELSEIF ASC(c$) < 128 THEN
            ' (BASIC's AND checks BOTH sides, so we test the range first
            ' in its own IF - otherwise code$(200) would be an error.)
            IF code$(ASC(c$)) <> "" THEN
                PRINT code$(ASC(c$)); " ";
                SendChar c$
                Pause 3              ' letter gap = 3 dot lengths
            END IF
        END IF
        IF INKEY$ = CHR$(27) THEN EXIT FOR
    NEXT i
    PRINT: PRINT: COLOR 7: PRINT "  Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' SendChar: beeps one character.  A dot lasts 1 unit, a dash lasts
' 3 units, and there is a 1-unit silence between them.
' ------------------------------------------------------------
SUB SendChar (c$)
    p$ = code$(ASC(c$))
    FOR j = 1 TO LEN(p$)
        IF MID$(p$, j, 1) = "." THEN SOUND PITCH, TICK ELSE SOUND PITCH, TICK * 3
        Pause 1
    NEXT j
END SUB

' Silence for a number of dot-lengths.  SOUND with frequency 32767
' is too high to hear, so it works as a rest that stays in step
' with the beeps that are queued before it.
SUB Pause (units)
    SOUND 32767, TICK * units
END SUB

' Prints "A  .-" with the dots and dashes in colour
SUB ShowCode (c$, row, col)
    LOCATE row, col
    COLOR 15: PRINT c$; "  ";
    COLOR 11: PRINT code$(ASC(c$));
END SUB

DATA A, .-, B, -..., C, -.-., D, -.., E, ., F, ..-., G, --., H, ....
DATA I, .., J, .---, K, -.-, L, .-.., M, --, N, -., O, ---, P, .--.
DATA Q, --.-, R, .-., S, ..., T, -, U, ..-, V, ...-, W, .--, X, -..-
DATA Y, -.--, Z, --.., 0, -----, 1, .----, 2, ..---, 3, ...--
DATA 4, ....-, 5, ....., 6, -...., 7, --..., 8, ---.., 9, ----.
