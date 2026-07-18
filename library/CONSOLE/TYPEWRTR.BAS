' ============================================================
' TITLE:    Typewriter Story
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     typewriter, sound, timer, strings, data
' SUMMARY:  Types out a short spooky story one letter at a time with clicks, pauses and a blinking cursor.
' ------------------------------------------------------------
' WHAT IT DOES
'   Prints a story the way an old typewriter or a computer in a
'   movie would: one character at a time, with a little click
'   sound, a longer pause after full stops and commas, and a
'   "ding!" at the end of each line.  Some words appear in colour
'   using simple codes hidden inside the text.
'
' HOW TO USE
'   Watch the story type itself.  Hold SPACE to type faster.
'   Press Esc to skip to the end.
'
' CONCEPTS YOU WILL LEARN
'   * Looping over a string with MID$(s$, i, 1)
'   * Making delays with TIMER (not empty FOR loops!)
'   * SOUND frequency, duration for tiny sound effects
'   * Embedding "control codes" in text (here ~ changes colour)
'
' THINGS TO TRY
'   * Write your own story in the DATA lines.
'   * Add a code that makes the text wait for a key press.
'   * Make the click sound random so it feels more mechanical.
' ============================================================

DECLARE SUB Pause (seconds!)

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS

COLOR 10
PRINT "  TERMINAL 7  --  INCOMING TRANSMISSION"
PRINT "  "; STRING$(38, 196)
PRINT
COLOR 7

' The story lives in DATA.  Special codes inside the text:
'   ~N   switch to colour number N (a single hex digit 0..F)
'   |    pause for half a second (dramatic effect!)
'   ^    print a double quote (DATA strings cannot contain one)
'   END  marks the end of the story
skip = 0               ' becomes 1 if the user presses Esc
DO
    READ ln$
    IF ln$ = "END" THEN EXIT DO
    PRINT "  ";                 ' left margin
    i = 1
    DO WHILE i <= LEN(ln$)
        ch$ = MID$(ln$, i, 1)
        IF ch$ = "~" THEN
            ' colour code: the next character is a hex digit.
            ' VAL("&H" + digit) turns "E" into 14, for example.
            COLOR VAL("&H" + MID$(ln$, i + 1, 1))
            i = i + 2
        ELSEIF ch$ = "|" THEN
            IF skip = 0 THEN Pause .5
            i = i + 1
        ELSE
            IF ch$ = "^" THEN ch$ = CHR$(34)   ' CHR$(34) is the " character
            PRINT ch$;
            i = i + 1
            IF skip = 0 THEN
                k$ = INKEY$
                IF k$ = CHR$(27) THEN skip = 1
                ' A key click: a very short high sound for letters only.
                IF ch$ <> " " THEN SOUND 1800 + RND * 400, .15
                ' Choose how long to wait after this character.
                SELECT CASE ch$
                    CASE ".", "!", "?": d = .35
                    CASE ",", ";", ":": d = .18
                    CASE ELSE: d = .045
                END SELECT
                IF k$ = " " THEN d = 0        ' space = fast forward
                Pause d
            END IF
        END IF
    LOOP
    PRINT                          ' end of line
    IF skip = 0 THEN SOUND 2600, 1: Pause .25   ' the carriage-return "ding!"
LOOP

COLOR 8
PRINT
PRINT "  [transmission ends]  press any key"
COLOR 7
k$ = INPUT$(1)
CLS
END

DATA "Log entry 47. The night shift is ~Equiet~7.|"
DATA "Too quiet. The servers hum, the coffee is cold,"
DATA "and the old terminal in the corner is ~Aon~7 again.|"
DATA ""
DATA "Nobody switched it on.| Nobody has used it since 1987."
DATA "Yet the cursor blinks, patient, waiting..."
DATA ""
DATA "I typed:  ~FHELLO?~7|"
DATA "It answered:  ~CHELLO. I HAVE BEEN WAITING.~7||"
DATA ""
DATA "I asked what it wanted.| It printed one line:"
DATA "~E   10 PRINT ^PLAY WITH ME^~7"
DATA "~E   20 GOTO 10~7||"
DATA ""
DATA "I think I will stay a little longer tonight."
DATA "END"

' Wait for a number of seconds without freezing the computer in a
' busy FOR loop of fixed length.  TIMER counts seconds since midnight,
' so we wait until it has moved on far enough.  The second test stops
' us waiting forever if the clock passes midnight during the pause.
SUB Pause (seconds!)
    t! = TIMER
    DO WHILE TIMER - t! < seconds! AND TIMER >= t!
    LOOP
END SUB
