' ============================================================
' TITLE:    Silly Story Maker
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     parts of speech, strings, templates, word wrap, files
' SUMMARY:  Give it nouns, verbs and adjectives (or let it pick) and it writes a silly story you can save.
' ------------------------------------------------------------
' WHAT IT DOES
'   Story templates are stored in DATA with gaps like {NOUN} or
'   {ADJECTIVE}.  In "You choose" mode the program asks you for each
'   kind of word - and explains what a noun, verb or adjective is -
'   then fills in the gaps.  In "Surprise me" mode it picks random
'   words from its own lists.  The story is printed with neat word
'   wrapping, and you can save it to STORY.TXT.
'
' HOW TO USE
'   Y = You choose the words, S = Surprise me, Q = quit.
'   After a story, press F to save it to the file.
'
' CONCEPTS YOU WILL LEARN
'   * Nouns (things), verbs (actions), adjectives (describing words)
'   * Finding and replacing text with INSTR, LEFT$ and MID$
'   * Word wrapping: breaking lines at spaces, not in mid-word
'   * Appending to a file with OPEN ... FOR APPEND
'
' THINGS TO TRY
'   * Write your own story template using the same {GAPS}
'   * Add a {COLOUR} or {FOOD} gap type
'   * Make the "Surprise me" lists bigger
' ============================================================

DECLARE FUNCTION RandomWord$ (kind$)
DECLARE FUNCTION Explain$ (kind$)
DECLARE SUB WrapPrint (t$, wid!)
RANDOMIZE TIMER
CONST NT = 3                     ' number of story templates

DO
    CLS
    COLOR 14: PRINT "  *~*~*  SILLY STORY MAKER  *~*~*"
    COLOR 7: PRINT
    PRINT "  Y) You choose the words"
    PRINT "  S) Surprise me!"
    PRINT "  Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "Y" OR k$ = "S" THEN
        ' --- pick a template: skip over the ones before it ---
        pick = INT(RND * NT) + 1
        RESTORE Stories
        FOR i = 1 TO pick: READ title$, story$: NEXT i
        CLS
        COLOR 14: PRINT "  Story: "; title$: PRINT
        ' --- fill each {GAP}, one at a time, left to right ---
        DO
            a = INSTR(story$, "{")
            IF a = 0 THEN EXIT DO
            b = INSTR(a, story$, "}")
            kind$ = MID$(story$, a + 1, b - a - 1)      ' e.g. "NOUN"
            IF k$ = "Y" THEN
                COLOR 11: PRINT "  "; Explain$(kind$)
                COLOR 15: LINE INPUT "  Type one: "; w$
                w$ = LTRIM$(RTRIM$(w$))
                IF w$ = "" THEN w$ = RandomWord$(kind$)  ' blank? we choose
            ELSE
                w$ = RandomWord$(kind$)
            END IF
            ' glue: text before the gap + word + text after the gap
            story$ = LEFT$(story$, a - 1) + w$ + MID$(story$, b + 1)
        LOOP
        CLS
        COLOR 14: PRINT: PRINT "  "; UCASE$(title$): PRINT
        COLOR 15
        WrapPrint story$, 70
        PRINT
        COLOR 7: PRINT "  F = save to STORY.TXT, any other key = menu"
        DO: f$ = UCASE$(INKEY$): LOOP UNTIL f$ <> ""
        IF f$ = "F" THEN
            ' APPEND adds to the end of the file instead of replacing it
            OPEN "STORY.TXT" FOR APPEND AS #1
            PRINT #1, UCASE$(title$)
            PRINT #1, story$
            PRINT #1, ""
            CLOSE #1
            COLOR 10: PRINT "  Saved! Press a key.": DO: LOOP WHILE INKEY$ = ""
        END IF
    END IF
LOOP
CLS
PRINT "The End!"
END

' ------------------------------------------------------------
' WrapPrint: print t$ in lines no wider than wid.  We look for the
' last space that fits and break the line there.
' ------------------------------------------------------------
SUB WrapPrint (t$, wid)
    rest$ = t$
    DO WHILE LEN(rest$) > wid
        cut = wid + 1
        DO WHILE cut > 1 AND MID$(rest$, cut, 1) <> " "
            cut = cut - 1
        LOOP
        IF cut = 1 THEN cut = wid + 1    ' no space at all: hard break
        PRINT "  "; LEFT$(rest$, cut - 1)
        rest$ = LTRIM$(MID$(rest$, cut))
    LOOP
    PRINT "  "; rest$
END SUB

' A friendly explanation of each kind of word, with examples
FUNCTION Explain$ (kind$)
    SELECT CASE kind$
        CASE "NOUN": Explain$ = "A NOUN is a thing or a place (like: sock, castle, banana)"
        CASE "PLURAL": Explain$ = "A PLURAL NOUN is more than one thing (like: frogs, shoes)"
        CASE "VERB": Explain$ = "A VERB is an action word (like: jump, sing, wobble)"
        CASE "VERBED": Explain$ = "A VERB in the past (like: danced, sneezed, giggled)"
        CASE "ADJECTIVE": Explain$ = "An ADJECTIVE describes something (like: fluffy, enormous)"
        CASE "ANIMAL": Explain$ = "An ANIMAL (like: hippo, parrot, snail)"
        CASE "NAME": Explain$ = "A person's NAME (like: Ada, Captain Bob)"
        CASE "NUMBER": Explain$ = "A NUMBER (like: 7, a million)"
        CASE "PLACE": Explain$ = "A PLACE (like: the moon, a bakery)"
        CASE ELSE: Explain$ = "A word for " + kind$
    END SELECT
END FUNCTION

' Picks a random word of the right kind from the lists below.
' Each list starts with a label and ends with "*".
FUNCTION RandomWord$ (kind$)
    SELECT CASE kind$
        CASE "NOUN": RESTORE LNoun
        CASE "PLURAL": RESTORE LPlural
        CASE "VERB": RESTORE LVerb
        CASE "VERBED": RESTORE LVerbed
        CASE "ADJECTIVE": RESTORE LAdj
        CASE "ANIMAL": RESTORE LAnimal
        CASE "NAME": RESTORE LName
        CASE "NUMBER": RESTORE LNumber
        CASE ELSE: RESTORE LPlace
    END SELECT
    ' count the words, then pick one
    cnt = 0
    DO: READ w$: IF w$ = "*" THEN EXIT DO
        cnt = cnt + 1
    LOOP
    which = INT(RND * cnt) + 1
    ' RESTORE again and read up to the chosen word
    SELECT CASE kind$
        CASE "NOUN": RESTORE LNoun
        CASE "PLURAL": RESTORE LPlural
        CASE "VERB": RESTORE LVerb
        CASE "VERBED": RESTORE LVerbed
        CASE "ADJECTIVE": RESTORE LAdj
        CASE "ANIMAL": RESTORE LAnimal
        CASE "NAME": RESTORE LName
        CASE "NUMBER": RESTORE LNumber
        CASE ELSE: RESTORE LPlace
    END SELECT
    FOR i = 1 TO which: READ w$: NEXT i
    RandomWord$ = w$
END FUNCTION

Stories:
DATA "The Amazing Picnic"
DATA "One {ADJECTIVE} morning, {NAME} packed a {NOUN} and {NUMBER} {PLURAL} for a picnic at {PLACE}. Suddenly a {ADJECTIVE} {ANIMAL} {VERBED} out of the bushes and began to {VERB}! Everyone laughed so hard that the {NOUN} rolled all the way home."
DATA "My Weird Pet"
DATA "My pet {ANIMAL} is called {NAME}. It is very {ADJECTIVE} and eats {NUMBER} {PLURAL} every day. Yesterday it {VERBED} onto the roof of {PLACE} and refused to come down until I promised to {VERB} with it. What a {ADJECTIVE} day!"
DATA "Space Mission"
DATA "Captain {NAME} climbed into a rocket shaped like a {NOUN}. After {NUMBER} seconds it blasted off to {PLACE}. There, a {ADJECTIVE} alien {ANIMAL} {VERBED} hello and gave the captain a box of {ADJECTIVE} {PLURAL}. Now the whole crew likes to {VERB} every Friday."

LNoun:
DATA sock, teapot, umbrella, sandwich, trampoline, banana, castle, *
LPlural:
DATA marshmallows, socks, pickles, balloons, cupcakes, pencils, *
LVerb:
DATA dance, wobble, sing, juggle, hop, sneeze, *
LVerbed:
DATA bounced, tiptoed, cartwheeled, burped, galloped, zoomed, *
LAdj:
DATA fluffy, gigantic, sparkly, grumpy, slimy, tiny, purple, *
LAnimal:
DATA hippo, penguin, llama, octopus, hamster, dragon, *
LName:
DATA Ada, Grandma Rose, Professor Pickle, Sam, Zara, *
LNumber:
DATA 3, 12, 99, "a million", 7, *
LPlace:
DATA the moon, a bakery, the zoo, the school roof, a volcano, *
