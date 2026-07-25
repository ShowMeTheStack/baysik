' ============================================================
' TITLE:    Mad Libs Generator
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     templates, placeholders, INSTR, string replacement, games
' SUMMARY:  Asks for nouns, verbs and adjectives, then fills them into a silly story template.
' ------------------------------------------------------------
' WHAT IT DOES
'   Mad Libs is a word game: someone asks you for "a noun", "an
'   adjective" etc. WITHOUT telling you the story, then reads the
'   story back with your words in it - usually hilarious.
'
'   The stories are templates stored in DATA, with placeholders
'   in curly brackets:
'       "The {adjective} {animal} {verb, past tense} over the moon."
'   The program finds each {placeholder}, asks you for that kind of
'   word, and swaps it in.  If you do not want to type, press Enter
'   and the computer picks a random word for you.
'
' HOW TO USE
'   Pick a story (1-3), answer the prompts (Enter = random word),
'   read your story.  Press Q at the menu to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Finding text between two markers with INSTR("{") and INSTR("}")
'   * Replacing a piece of a string: LEFT$ + new + MID$
'   * Reusing earlier answers with numbered placeholders {1:name}
'   * Word-wrapping the finished story to fit the screen
'
' THINGS TO TRY
'   * Write your own story template (keep "*" as the end marker)
'   * Save finished stories to a file
'   * Add "a" vs "an" correction: "a apple" -> "an apple"
' ============================================================

DECLARE FUNCTION RandomFor$ (kind$)
DECLARE SUB WrapPrint (s$, wid)

RANDOMIZE TIMER
DIM saved$(9)                 ' answers for numbered placeholders {1:...}

DO
    CLS
    COLOR 14: PRINT "MAD LIBS GENERATOR": COLOR 7
    PRINT
    PRINT "  1) A Day at School"
    PRINT "  2) The Space Mission"
    PRINT "  3) My Robot Pet"
    PRINT "  Q) Quit"
    PRINT
    PRINT "Choose a story: ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ >= "1" AND k$ <= "3" THEN
        PRINT k$
        ' ---- read the chosen template: skip to story number k ----
        RESTORE Stories
        story$ = "": num = 0
        DO
            READ tline$
            IF tline$ = "*" THEN
                num = num + 1
                IF num = VAL(k$) THEN EXIT DO
                story$ = ""
            ELSE
                story$ = story$ + tline$
            END IF
        LOOP
        FOR i = 1 TO 9: saved$(i) = "": NEXT i
        PRINT
        PRINT "Give me some words (press Enter for a random one):"
        ' ---- fill every {placeholder}, left to right ----
        DO
            a = INSTR(story$, "{")
            IF a = 0 THEN EXIT DO
            b = INSTR(a, story$, "}")
            kind$ = MID$(story$, a + 1, b - a - 1)
            slot = 0
            ' "{1:name}" means: remember this answer as number 1;
            ' a later "{1}" alone reuses it without asking again
            IF MID$(kind$, 2, 1) = ":" OR LEN(kind$) = 1 THEN
                slot = VAL(LEFT$(kind$, 1))
                kind$ = MID$(kind$, 3)
            END IF
            IF slot > 0 AND kind$ = "" THEN
                ans$ = saved$(slot)
            ELSE
                IF INSTR("aeiou", LEFT$(kind$, 1)) THEN art$ = "an " ELSE art$ = "a "
                ' LINE INPUT only accepts a fixed prompt, so PRINT ours first
                PRINT "  "; art$; kind$; ": ";
                LINE INPUT ans$
                ans$ = LTRIM$(RTRIM$(ans$))
                IF ans$ = "" THEN
                    ans$ = RandomFor$(kind$)
                    COLOR 8: PRINT "    (I picked: "; ans$; ")": COLOR 7
                END IF
                IF slot > 0 THEN saved$(slot) = ans$
            END IF
            ' swap the placeholder for the answer (in CAPITALS so it stands out)
            story$ = LEFT$(story$, a - 1) + UCASE$(ans$) + MID$(story$, b + 1)
        LOOP
        PRINT
        COLOR 11: PRINT "Here is your story:": COLOR 7
        PRINT
        WrapPrint story$, 76
        PRINT
        PRINT "Press any key...";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
PRINT
PRINT "Goodbye!"
END

Stories:
DATA "Today my teacher, {1:name}, brought a {adjective} {animal} to school. "
DATA "It {verb, past tense} all over the desks and ate my {noun}! "
DATA "{1} shouted '{exclamation}!' and we all had to {verb} outside "
DATA "for {number} minutes. Best. Day. Ever.", "*"
DATA "Captain {1:name} climbed into the {adjective} rocket. "
DATA "After {number} days in space, the crew found a planet made of {food}. "
DATA "A {adjective} alien {verb, past tense} out and said, "
DATA "'Take me to your {noun}!' Captain {1} just laughed.", "*"
DATA "My robot pet, {1:name}, runs on {food} and {noun}s. "
DATA "Every morning {1} likes to {verb} in the garden while singing "
DATA "about {animal}s. Yesterday it became {adjective} and {verb, past tense} "
DATA "the neighbour's {noun}. {exclamation}!", "*"

' ------------------------------------------------------------
' RandomFor$: a random word of the right kind.  Each list is one
' string with words separated by "/".  We count the words, pick
' one, then find it.
' ------------------------------------------------------------
FUNCTION RandomFor$ (kind$)
    SELECT CASE kind$
        CASE "name": l$ = "Zog/Bubbles/Mrs Fizz/Sir Wobble/Dr Pickles"
        CASE "adjective": l$ = "sticky/gigantic/glittery/grumpy/invisible/wobbly"
        CASE "animal": l$ = "hippo/penguin/llama/goldfish/octopus"
        CASE "verb, past tense": l$ = "bounced/sneezed/tap-danced/wriggled/exploded"
        CASE "verb": l$ = "juggle/dance/hop/sing/yodel"
        CASE "noun": l$ = "sandwich/sock/trumpet/homework/teapot"
        CASE "food": l$ = "spaghetti/custard/pickles/jelly/cheese"
        CASE "exclamation": l$ = "Yikes/Holy guacamole/Great Scott/Oh no"
        CASE "number": l$ = STR$(INT(RND * 99) + 2)
        CASE ELSE: l$ = "thing"
    END SELECT
    n = 1
    FOR i = 1 TO LEN(l$)
        IF MID$(l$, i, 1) = "/" THEN n = n + 1
    NEXT i
    pick = INT(RND * n) + 1
    l$ = l$ + "/"
    FOR i = 1 TO pick - 1
        l$ = MID$(l$, INSTR(l$, "/") + 1)      ' drop the first word
    NEXT i
    RandomFor$ = LTRIM$(LEFT$(l$, INSTR(l$, "/") - 1))
END FUNCTION

' WrapPrint: print s$ without breaking words, at most wid per line.
SUB WrapPrint (s$, wid)
    rest$ = s$
    DO WHILE LEN(rest$) > wid
        cut = wid + 1
        DO WHILE cut > 1 AND MID$(rest$, cut, 1) <> " "
            cut = cut - 1                       ' back up to a space
        LOOP
        IF cut = 1 THEN cut = wid + 1           ' one giant word: just chop
        PRINT LEFT$(rest$, cut - 1)
        rest$ = LTRIM$(MID$(rest$, cut))
    LOOP
    PRINT rest$
END SUB
