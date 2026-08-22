' ============================================================
' TITLE:    Solar System Explorer
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     space, planets, science, DATA, quiz, graphics
' SUMMARY:  Visit each planet for fun facts, then take the space quiz to earn your astronaut badge.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws the Sun and the eight planets in a row (sizes are only
'   roughly to scale - the real Sun would be wider than the screen!).
'   Press a planet's number to fly to it and read its facts: distance
'   from the Sun, number of moons, how long a day and a year last,
'   and a fun fact.  The quiz asks 8 multiple-choice questions picked
'   at random from a bank of questions in DATA statements.
'
' HOW TO USE
'   Keys 1-8 visit a planet (1 = Mercury ... 8 = Neptune).
'   Z starts the quiz (answer with A-D).  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing records in DATA and READing them into arrays
'   * RESTORE to re-read DATA for the question bank
'   * Shuffling question numbers so none repeats
'   * An "astronomical unit" (AU): the Earth-Sun distance
'
' THINGS TO TRY
'   * Add Pluto as a dwarf planet with its own facts
'   * Add more questions to the question bank
'   * Show each planet's weight on the planet: your weight x gravity
' ============================================================

DECLARE SUB DrawSystem (sel!)
CONST NP = 8
DIM SHARED pname$(1 TO NP), pcol(1 TO NP), prad(1 TO NP), px(1 TO NP)
DIM au$(1 TO NP), moons$(1 TO NP), day$(1 TO NP), year$(1 TO NP), fact$(1 TO NP)
FOR i = 1 TO NP
    READ pname$(i), pcol(i), prad(i), au$(i), moons$(i), day$(i), year$(i), fact$(i)
NEXT i
RANDOMIZE TIMER
SCREEN 12

DO
    CLS
    DrawSystem 0
    COLOR 15: LOCATE 22, 8: PRINT "Press 1-8 to visit a planet,  Z = quiz,  Q = quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "Z" THEN GOSUB Quiz
    IF k$ >= "1" AND k$ <= "8" AND LEN(k$) = 1 THEN
        p = VAL(k$)
        CLS
        DrawSystem p
        COLOR 14: LOCATE 16, 6: PRINT "*** "; UCASE$(pname$(p)); " ***"
        COLOR 15
        LOCATE 18, 6: PRINT "Distance from the Sun: "; au$(p); " AU  (Earth = 1 AU)"
        LOCATE 19, 6: PRINT "Moons:                 "; moons$(p)
        LOCATE 20, 6: PRINT "One day lasts:         "; day$(p)
        LOCATE 21, 6: PRINT "One year lasts:        "; year$(p)
        COLOR 13: LOCATE 23, 6: PRINT "Fun fact:"
        COLOR 11: LOCATE 24, 6: PRINT fact$(p)
        COLOR 7: LOCATE 27, 6: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
SCREEN 0
PRINT "Keep looking up at the stars!"
END

' ------------------------------------------------------------
' Quiz: count the questions, shuffle their numbers, ask 8.
' ------------------------------------------------------------
Quiz:
    RESTORE Questions
    nq = 0
    DO
        READ q$, a$, b$, c$, d$, ans$
        IF q$ = "*" THEN EXIT DO
        nq = nq + 1
    LOOP
    DIM order(1 TO nq)
    FOR i = 1 TO nq: order(i) = i: NEXT i
    FOR i = nq TO 2 STEP -1               ' Fisher-Yates shuffle
        j = INT(RND * i) + 1: SWAP order(i), order(j)
    NEXT i
    score = 0
    FOR qn = 1 TO 8
        ' Skip forward to question number order(qn)
        RESTORE Questions
        FOR i = 1 TO order(qn): READ q$, a$, b$, c$, d$, ans$: NEXT i
        CLS
        COLOR 14: LOCATE 3, 5: PRINT "SPACE QUIZ - question"; qn; "of 8      Score:"; score
        COLOR 15: LOCATE 6, 5: PRINT q$
        COLOR 11
        LOCATE 9, 8: PRINT "A) "; a$
        LOCATE 10, 8: PRINT "B) "; b$
        LOCATE 11, 8: PRINT "C) "; c$
        LOCATE 12, 8: PRINT "D) "; d$
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL (k$ >= "A" AND k$ <= "D" AND LEN(k$) = 1) OR k$ = CHR$(27)
        IF k$ = CHR$(27) THEN EXIT FOR
        LOCATE 15, 5
        IF k$ = ans$ THEN
            COLOR 10: PRINT "Correct! Out of this world!": score = score + 1
            SOUND 1200, 1: SOUND 1600, 1
        ELSE
            COLOR 12: PRINT "Not quite - the answer was "; ans$; "."
        END IF
        COLOR 7: LOCATE 17, 5: PRINT "Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    NEXT qn
    ERASE order                           ' order() is dynamic: free it
    CLS
    COLOR 14: LOCATE 10, 20: PRINT "You scored"; score; "out of 8!"
    IF score >= 6 THEN
        ' an astronaut badge: a star made with DRAW
        COLOR 13: LOCATE 12, 20: PRINT "You earned your ASTRONAUT BADGE!"
        PSET (320, 260), 14
        DRAW "C14 U30 F20 R30 G25 F25 L30 H20 G20 L30 E25 H25 R30 E20"
    END IF
    COLOR 7: LOCATE 25, 20: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' DrawSystem: the Sun on the left, planets spaced along a line.
' The selected planet gets a ring around it.
' ------------------------------------------------------------
SUB DrawSystem (sel)
    ' a few random stars (the same each time thanks to a fixed seed)
    RANDOMIZE 7
    FOR s = 1 TO 120: PSET (RND * 639, RND * 470), 7 + (s MOD 2) * 8: NEXT s
    RANDOMIZE TIMER
    ' the Sun: only its edge fits on screen
    CIRCLE (-60, 130), 120, 14: PAINT (0, 130), 14, 14
    x = 90
    FOR i = 1 TO NP
        x = x + prad(i) + 22
        px(i) = x
        CIRCLE (x, 130), prad(i), pcol(i)
        PAINT (x, 130), pcol(i), pcol(i)
        IF i = 6 THEN CIRCLE (x, 130), prad(i) + 12, 7, , , .3   ' Saturn's rings
        IF i = sel THEN CIRCLE (x, 130), prad(i) + 8, 15
        COLOR 7: LOCATE 13, INT(x / 8) + 1: PRINT LTRIM$(STR$(i));
        x = x + prad(i)
    NEXT i
    COLOR 14: LOCATE 2, 25: PRINT "THE SOLAR SYSTEM"
END SUB

' name, colour, drawn radius, distance (AU), moons, day, year, fun fact
DATA Mercury, 7, 5, "0.39", "0", "59 Earth days", "88 Earth days", "It is the smallest planet and has no air to keep it warm at night."
DATA Venus, 14, 9, "0.72", "0", "243 Earth days", "225 Earth days", "Its day is longer than its year! It spins backwards too."
DATA Earth, 9, 10, "1.00", "1", "24 hours", "365 days", "The only planet we know of with life - that's us!"
DATA Mars, 12, 7, "1.52", "2", "24.6 hours", "687 Earth days", "Home of Olympus Mons, the biggest volcano in the solar system."
DATA Jupiter, 6, 32, "5.20", "95", "10 hours", "12 Earth years", "Its Great Red Spot is a storm bigger than the whole Earth."
DATA Saturn, 14, 26, "9.58", "146", "10.7 hours", "29 Earth years", "Saturn would float in a giant bathtub - it is less dense than water."
DATA Uranus, 11, 16, "19.2", "28", "17 hours", "84 Earth years", "It spins on its side, rolling around the Sun like a ball."
DATA Neptune, 1, 15, "30.1", "16", "16 hours", "165 Earth years", "It has the fastest winds in the solar system: over 2000 km/h!"

Questions:
DATA "Which planet is closest to the Sun?", Mercury, Venus, Mars, Earth, A
DATA "Which is the biggest planet?", Saturn, Neptune, Jupiter, Earth, C
DATA "Which planet is called the Red Planet?", Venus, Mars, Jupiter, Mercury, B
DATA "Which planet has the most famous rings?", Uranus, Earth, Mars, Saturn, D
DATA "How many planets are in our solar system?", 7, 8, 9, 10, B
DATA "Which planet do we live on?", Mars, Venus, Earth, Neptune, C
DATA "What is the Sun?", A planet, A star, A moon, A comet, B
DATA "Which planet spins on its side?", Uranus, Mercury, Jupiter, Venus, A
DATA "Which planet is the hottest?", Mercury, Venus, Mars, Jupiter, B
DATA "What is the farthest planet from the Sun?", Uranus, Saturn, Neptune, Pluto, C
DATA "What is Earth's natural satellite called?", Phobos, The Moon, Titan, Io, B
DATA "Which planet has the Great Red Spot?", Mars, Saturn, Jupiter, Venus, C
DATA *, *, *, *, *, *
