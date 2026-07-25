' ============================================================
' TITLE:    Acronym Maker
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     acronyms, initials, words, INSTR, RND
' SUMMARY:  Builds acronyms from phrases (Portable Network Graphics -> PNG) and invents silly backronyms.
' ------------------------------------------------------------
' WHAT IT DOES
'   Computer people love acronyms: BASIC, GIF, RAM, CPU ...
'   This program takes a phrase and builds its acronym from the
'   first letter of each word.  It skips small words like "of" and
'   "by" (so LASER, not LABSEOR), and splits a hyphenated word only
'   when the second half has a capital: "Read-Only Memory" -> ROM
'   but "All-purpose" stays one word, so BASIC comes out right.
'
'   Then for fun it does the opposite: give it a word and it makes
'   up a "backronym" - a random phrase whose initials spell it.
'       CAT -> "Cheerful Atomic Toaster"
'
' HOW TO USE
'   Menu: 1 = make an acronym, 2 = make a backronym, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Spotting the start of each word while scanning a string
'   * A list of "stop words" kept in one string and tested with INSTR
'   * Picking random words that start with a given letter
'
' THINGS TO TRY
'   * Keep the small words as lower-case letters: "DoD"
'   * Add more words to the backronym word lists
'   * Make the backronym pick an adjective, then nouns
' ============================================================

DECLARE FUNCTION Acronym$ (s$)
DECLARE FUNCTION RandomWord$ (L$)

DIM SHARED wl$(26)         ' wl$(1) = words for A, wl$(2) = words for B ...

' ---- load the backronym word lists: "A:word word word" ----
RESTORE WordLists
FOR i = 1 TO 26
    READ a$
    wl$(ASC(a$) - 64) = " " + MID$(a$, 3) + " "
NEXT i

RANDOMIZE TIMER
CLS
COLOR 14: PRINT "ACRONYM MAKER": COLOR 7
PRINT
PRINT "Famous examples:"
RESTORE Famous
DO
    READ p$
    IF p$ = "*" THEN EXIT DO
    PRINT "  "; LEFT$(p$ + SPACE$(56), 56); "-> ";
    COLOR 11: PRINT Acronym$(p$): COLOR 7
LOOP

DO
    PRINT
    PRINT "1) acronym from a phrase   2) backronym from a word   Q) quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1"
            LINE INPUT "Phrase: "; p$
            a$ = Acronym$(p$)
            IF a$ = "" THEN PRINT "  (no words found)" ELSE COLOR 11: PRINT "  "; a$: COLOR 7
        CASE "2"
            LINE INPUT "Word: "; w$
            w$ = UCASE$(w$)
            FOR t = 1 TO 3                     ' three different tries
                PRINT "  "; w$; " = ";
                FOR i = 1 TO LEN(w$)
                    c$ = MID$(w$, i, 1)
                    IF c$ >= "A" AND c$ <= "Z" THEN COLOR 11: PRINT RandomWord$(c$); " "; : COLOR 7
                NEXT i
                PRINT
            NEXT t
        CASE "Q", CHR$(27)
            EXIT DO
    END SELECT
LOOP
PRINT "Goodbye!"
END

Famous:
DATA "Beginner's All-purpose Symbolic Instruction Code"
DATA "Portable Network Graphics", "Central Processing Unit"
DATA "Read-Only Memory", "Federal Bureau of Investigation"
DATA "Light Amplification by Stimulated Emission of Radiation"
DATA "Self-Contained Underwater Breathing Apparatus", "*"

' word lists for backronyms
WordLists:
DATA "A:atomic angry amazing awkward", "B:bouncy brave binary banana"
DATA "C:cheerful crispy cosmic cat", "D:dancing digital dizzy dragon"
DATA "E:electric eager elastic engine", "F:fuzzy flying funky fox"
DATA "G:giant groovy glowing goblin", "H:happy hungry hyper hamster"
DATA "I:invisible icy instant igloo", "J:jolly jumping jazzy jelly"
DATA "K:kooky kind kinetic kitten", "L:lazy lucky laser llama"
DATA "M:mighty magic mega muffin", "N:noisy nimble neon noodle"
DATA "O:odd orbital orange owl", "P:purple pixel peppy penguin"
DATA "Q:quick quirky quiet quokka", "R:robotic rapid rubber rocket"
DATA "S:sneaky super sparkly sandwich", "T:tiny turbo tasty toaster"
DATA "U:ultra unusual upside umbrella", "V:violet vivid velvet volcano"
DATA "W:wobbly wild wise walrus", "X:xenon x-ray xtra xylophone"
DATA "Y:yellow yummy young yak", "Z:zany zippy zesty zebra"

' ------------------------------------------------------------
' Acronym$: a new word starts after a space, or after a hyphen
' that is followed by a CAPITAL letter in the original text.
' If the word is a small "stop word" it is skipped - unless it is
' the very first word.  Apostrophes ("Beginner's") stay in the word.
' ------------------------------------------------------------
FUNCTION Acronym$ (s$)
    stopw$ = " OF AND THE BY FOR IN ON A AN TO "
    o$ = s$ + " "                    ' original, to check capitals
    t$ = UCASE$(o$)
    out$ = "": w$ = "": nwords = 0
    FOR i = 1 TO LEN(t$)
        c$ = MID$(t$, i, 1)
        brk = (c$ = " ")
        IF c$ = "-" THEN
            nx$ = MID$(o$, i + 1, 1)
            IF nx$ >= "A" AND nx$ <= "Z" THEN brk = -1
        END IF
        IF brk THEN
            IF w$ <> "" THEN
                nwords = nwords + 1
                IF nwords = 1 OR INSTR(stopw$, " " + w$ + " ") = 0 THEN
                    out$ = out$ + LEFT$(w$, 1)
                END IF
                w$ = ""
            END IF
        ELSEIF (c$ >= "A" AND c$ <= "Z") OR (c$ >= "0" AND c$ <= "9") OR c$ = "'" THEN
            w$ = w$ + c$
        END IF
    NEXT i
    Acronym$ = out$
END FUNCTION

' ------------------------------------------------------------
' RandomWord$: the list for letter L$ looks like " w1 w2 w3 w4 ".
' Count its spaces to know how many words there are, choose one
' at random, then walk to it.  The first letter is capitalised.
' ------------------------------------------------------------
FUNCTION RandomWord$ (L$)
    lst$ = wl$(ASC(L$) - 64)
    n = 0
    FOR i = 2 TO LEN(lst$)
        IF MID$(lst$, i, 1) = " " THEN n = n + 1
    NEXT i
    pick = INT(RND * n) + 1
    p = 1
    FOR i = 1 TO pick - 1
        p = INSTR(p + 1, lst$, " ")      ' jump to the next space
    NEXT i
    q = INSTR(p + 1, lst$, " ")
    w$ = MID$(lst$, p + 1, q - p - 1)
    RandomWord$ = UCASE$(LEFT$(w$, 1)) + MID$(w$, 2)
END FUNCTION
