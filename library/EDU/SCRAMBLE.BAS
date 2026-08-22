' ============================================================
' TITLE:    Word Scramble
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     words, strings, shuffle, hints, MID$
' SUMMARY:  Unscramble jumbled words from fun categories - ask for hints, but they cost points!
' ------------------------------------------------------------
' WHAT IT DOES
'   Picks a word from a category (animals, food, school or space),
'   mixes up its letters and shows them as colourful tiles.  Type the
'   real word.  Stuck?  Press Enter on an empty line for a hint: each
'   hint reveals one more letter in the right place, but the word is
'   then worth fewer points.  Type ? to shuffle the tiles again.
'
' HOW TO USE
'   Pick a category 1-4.  Type your guess and press Enter.
'   Empty Enter = hint, ? = reshuffle, Q = give up the game.
'
' CONCEPTS YOU WILL LEARN
'   * Shuffling the letters of a string by swapping characters
'   * MID$ used on the LEFT of = to change one character in place
'   * Making sure the scramble is not the same as the word
'   * RESTORE with labels to choose a word list
'
' THINGS TO TRY
'   * Add your own category with your spelling words
'   * Give bonus points for solving in under 10 seconds
'   * Make a two-player version that takes turns
' ============================================================

DECLARE FUNCTION Jumble$ (w$)
DECLARE SUB ShowTiles (s$, row!)
RANDOMIZE TIMER
DIM words$(1 TO 30)

DO
    CLS
    COLOR 14: PRINT "  W O R D   S C R A M B L E"
    COLOR 7: PRINT
    PRINT "  1) Animals   2) Food   3) School   4) Space   Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    SELECT CASE k$
        CASE "1": RESTORE Animals
        CASE "2": RESTORE Food
        CASE "3": RESTORE School
        CASE "4": RESTORE Space
        CASE ELSE: GOTO NextMenu
    END SELECT
    n = 0
    DO
        READ w$
        IF w$ = "*" THEN EXIT DO
        n = n + 1: words$(n) = w$
    LOOP
    GOSUB PlayRound
NextMenu:
LOOP
CLS
PRINT "Thanks for playing Word Scramble!"
END

' ------------------------------------------------------------
PlayRound:
    score = 0
    FOR q = 1 TO 8
        w$ = UCASE$(words$(INT(RND * n) + 1))
        s$ = Jumble$(w$)
        hints = 0
        DO
            CLS
            COLOR 14: PRINT "  Word"; q; "of 8          Score:"; score
            PRINT
            COLOR 7: PRINT "  Unscramble these letters:"
            ShowTiles s$, 5
            ' Show the hint line: revealed letters and underscores
            h$ = ""
            FOR i = 1 TO LEN(w$)
                IF i <= hints THEN h$ = h$ + MID$(w$, i, 1) + " " ELSE h$ = h$ + "_ "
            NEXT i
            LOCATE 9, 5: COLOR 11: PRINT h$
            COLOR 7: LOCATE 11, 3: PRINT "(Enter = hint, ? = reshuffle, Q = quit)"
            LOCATE 13, 3: COLOR 15: LINE INPUT "Your guess: "; g$
            g$ = UCASE$(LTRIM$(RTRIM$(g$)))
            IF g$ = "Q" THEN RETURN
            IF g$ = "" THEN
                hints = hints + 1
                IF hints >= LEN(w$) THEN EXIT DO          ' all revealed
            ELSEIF g$ = "?" THEN
                s$ = Jumble$(w$)
            ELSEIF g$ = w$ THEN
                EXIT DO
            ELSE
                LOCATE 15, 3: COLOR 12: PRINT "Not quite - keep trying!"
                SOUND 200, 2
                t0 = TIMER: DO: LOOP WHILE TIMER - t0 < 1 AND TIMER >= t0
            END IF
        LOOP
        ' Points: 10 for the word, minus 2 for each hint used
        ' (a solved word always earns at least 1 point)
        solved = (g$ = w$)
        pts = 10 - 2 * hints: IF pts < 1 THEN pts = 1
        IF NOT solved THEN pts = 0
        score = score + pts
        LOCATE 15, 3: PRINT SPACE$(60);
        LOCATE 15, 3
        IF solved THEN
            COLOR 10: PRINT "Yes! "; w$; " - you earn"; pts; "points!"
            PLAY "T220 O4 E16 G16 O5 C8"
        ELSE
            COLOR 13: PRINT "The word was "; w$; ". You'll get the next one!"
        END IF
        COLOR 7: LOCATE 17, 3: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    NEXT q
    CLS
    COLOR 14: PRINT: PRINT "  Final score:"; score; "out of 80"
    IF score >= 60 THEN PRINT "  You're a word wizard!" ELSE PRINT "  Nice unscrambling!"
    COLOR 7: PRINT: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' Jumble$: swap each letter with a random letter (Fisher-Yates on
' a string).  MID$(s$, i, 1) = x$ replaces ONE character in place.
' Repeat if by bad luck it came out the same as the word.
' ------------------------------------------------------------
FUNCTION Jumble$ (w$)
    tries = 0
    DO
        s$ = w$
        FOR i = LEN(s$) TO 2 STEP -1
            j = INT(RND * i) + 1
            t$ = MID$(s$, i, 1)
            MID$(s$, i, 1) = MID$(s$, j, 1)
            MID$(s$, j, 1) = t$
        NEXT i
        tries = tries + 1
    LOOP WHILE s$ = w$ AND tries < 20
    Jumble$ = s$
END FUNCTION

' Each letter as a coloured tile:  [ A ]
SUB ShowTiles (s$, row)
    LOCATE row, 5
    FOR i = 1 TO LEN(s$)
        COLOR 15, 1 + (i MOD 6)
        PRINT " "; MID$(s$, i, 1); " ";
        COLOR 7, 0: PRINT " ";
    NEXT i
END SUB

Animals:
DATA tiger, rabbit, giraffe, penguin, dolphin, zebra, monkey, turtle
DATA elephant, kangaroo, octopus, squirrel, *
Food:
DATA apple, banana, carrot, pizza, noodle, cheese, orange, sandwich
DATA potato, cookie, pancake, yogurt, *
School:
DATA pencil, teacher, ruler, eraser, library, science, lesson
DATA classroom, homework, backpack, crayon, *
Space:
DATA planet, rocket, comet, galaxy, astronaut, meteor, orbit
DATA gravity, telescope, satellite, *
