' ============================================================
' TITLE:    Spelling Bee
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     spelling, DATA, strings, timer, words
' SUMMARY:  A word flashes on screen, then hides - can you spell it from memory with the clue?
' ------------------------------------------------------------
' WHAT IT DOES
'   Words and clue sentences are stored in DATA lines.  For each
'   round the program flashes the word for a few seconds, then hides
'   it and shows the clue sentence with a blank.  You type the word.
'   You have three lives (bees!) - a wrong spelling costs one bee and
'   the program shows exactly which letters were different.
'
' HOW TO USE
'   Choose easy (1) or tricky (2) words.  Watch the word, then type
'   it and press Enter.  Type Q to stop.
'
' CONCEPTS YOU WILL LEARN
'   * READ and DATA to store a word list inside the program
'   * RESTORE with a label to jump to a different DATA list
'   * Waiting a set time with TIMER
'   * Comparing two strings letter by letter with MID$
'
' THINGS TO TRY
'   * Add your own spelling list from school to the DATA lines
'   * Make the flash time shorter as your score grows
'   * Save the words you got wrong to a file to practise later
' ============================================================

RANDOMIZE TIMER
DIM w$(1 TO 40), clue$(1 TO 40), used(1 TO 40)

CLS
COLOR 14: PRINT "  ~~~ THE SPELLING BEE ~~~"
COLOR 7
PRINT
PRINT "  1) Easy words      2) Tricky words      Q) Quit"
PRINT
PRINT "  Choose: ";
DO
    k$ = UCASE$(INKEY$)
LOOP UNTIL k$ = "1" OR k$ = "2" OR k$ = "Q" OR k$ = CHR$(27)
IF k$ = "Q" OR k$ = CHR$(27) THEN END

' RESTORE tells READ where to start reading DATA from.
IF k$ = "1" THEN RESTORE EasyWords ELSE RESTORE TrickyWords

' Read words until we meet the "*" end marker.
n = 0
DO
    READ a$, b$
    IF a$ = "*" THEN EXIT DO
    n = n + 1: w$(n) = a$: clue$(n) = b$
LOOP

lives = 3: score = 0: asked = 0
DO WHILE lives > 0 AND asked < n
    ' Pick a word we have not used yet
    DO
        pick = INT(RND * n) + 1
    LOOP WHILE used(pick)
    used(pick) = -1: asked = asked + 1
    word$ = w$(pick)

    CLS
    COLOR 14: PRINT "  Score:"; score; "   Bees left: ";
    COLOR 6: PRINT STRING$(lives, "@")      ' each @ is a little bee
    PRINT
    COLOR 15: PRINT "  Look carefully at this word..."
    PRINT
    ' Show the word big and spaced out: S  C  H  O  O  L
    LOCATE 6, 10: COLOR 11
    FOR i = 1 TO LEN(word$)
        PRINT UCASE$(MID$(word$, i, 1)); "  ";
    NEXT i
    ' Wait about 3 seconds (more for long words)
    waitSecs = 2 + LEN(word$) / 4
    t0 = TIMER
    DO
        IF INKEY$ = CHR$(27) THEN lives = 0: EXIT DO
        el = TIMER - t0: IF el < 0 THEN el = el + 86400
    LOOP UNTIL el >= waitSecs
    IF lives = 0 THEN EXIT DO

    ' Hide the word and show the clue with a blank where the word was
    LOCATE 6, 1: PRINT SPACE$(79);
    s$ = clue$(pick)
    p = INSTR(s$, "~")                       ' ~ marks where the word goes
    IF p > 0 THEN s$ = LEFT$(s$, p - 1) + STRING$(LEN(word$), "_") + MID$(s$, p + 1)
    LOCATE 6, 4: COLOR 7: PRINT s$
    PRINT
    COLOR 15: LINE INPUT "  Spell it: "; guess$
    guess$ = LCASE$(LTRIM$(RTRIM$(guess$)))
    IF guess$ = "q" THEN EXIT DO

    PRINT
    IF guess$ = LCASE$(word$) THEN      ' compare ignoring capitals
        score = score + 1
        COLOR 10: PRINT "  BUZZ BUZZ! Perfect spelling!"
        PLAY "T200 O5 C16 E16 G8"
    ELSE
        lives = lives - 1
        COLOR 12: PRINT "  Oops! The word is: "; word$
        ' Show which letters differ.  ^ marks a wrong or missing letter.
        PRINT "  You typed:        "; guess$
        PRINT "                    ";
        L = LEN(word$): IF LEN(guess$) > L THEN L = LEN(guess$)
        FOR i = 1 TO L
            IF MID$(LCASE$(word$), i, 1) = MID$(guess$, i, 1) THEN PRINT " "; ELSE PRINT "^";
        NEXT i
        PRINT
    END IF
    PRINT: COLOR 7: PRINT "  Press any key...";
    DO: LOOP WHILE INKEY$ = ""
LOOP

CLS
COLOR 14
PRINT "  You spelled"; score; "word(s) correctly!"
IF score >= 8 THEN PRINT "  You are the QUEEN BEE of spelling!" ELSE PRINT "  Great effort - keep buzzing!"
COLOR 7
END

' Each word is followed by a clue sentence.  "~" marks the gap.
EasyWords:
DATA cat, "The ~ said meow and drank its milk."
DATA house, "We live in a big red ~ on the hill."
DATA green, "Grass and frogs are ~."
DATA friend, "My best ~ sits next to me at school."
DATA water, "Fish swim in the ~."
DATA happy, "A smile shows you are ~."
DATA school, "We learn to read at ~."
DATA apple, "An ~ a day keeps the doctor away."
DATA yellow, "The sun is bright ~."
DATA garden, "Flowers grow in the ~."
DATA *, *

TrickyWords:
DATA because, "I smiled ~ I was happy."
DATA beautiful, "What a ~ sunset!"
DATA necessary, "Is it really ~ to tidy my room?"
DATA rhythm, "Clap along to the ~ of the drum."
DATA separate, "Keep the eggs ~ from the flour."
DATA receive, "Did you ~ my letter?"
DATA library, "Borrow a book from the ~."
DATA February, "The shortest month is ~."
DATA Wednesday, "The middle of the week is ~."
DATA environment, "Look after the ~ - recycle!"
DATA *, *
