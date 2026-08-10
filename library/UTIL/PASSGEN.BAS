' ============================================================
' TITLE:    Password Generator
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     random, strings, security, entropy, rnd
' SUMMARY:  Makes random passwords or easy-to-say passphrases and rates how strong they are.
' ------------------------------------------------------------
' WHAT IT DOES
'   Builds passwords by picking random characters from a "pool"
'   of allowed characters.  You choose the length and which
'   kinds of characters to allow.  It also makes passphrases
'   from random words (like "tiger-cloud-pencil-42").
'
'   Strength is measured in BITS OF ENTROPY:
'       bits = length * log2(pool size)
'   Each extra bit doubles how many guesses an attacker needs.
'   Around 60+ bits is strong for everyday use.
'
'   NOTE: RND is fine for learning, but real password tools use
'   a cryptographically secure random generator!
'
' HOW TO USE
'   Answer the questions; five passwords are printed each time.
'   Press Q or Esc at the menu to quit.
'
' CONCEPTS YOU WILL LEARN
'   * RANDOMIZE TIMER and RND to pick random items
'   * Building strings one character at a time
'   * LOG(x) / LOG(2) to get a base-2 logarithm
'   * Removing look-alike characters (0/O, 1/l/I)
'
' THINGS TO TRY
'   * Guarantee at least one digit and one symbol.
'   * Add more words to the DATA list - with only 32 words each
'     word adds just 5 bits, so passphrases need to be long!
'   * Save generated passwords to a file (but don't really!).
' ============================================================

RANDOMIZE TIMER          ' different random numbers each run

' Word list for passphrases.
CONST NWORDS = 32
DIM w$(1 TO NWORDS)
FOR i = 1 TO NWORDS: READ w$(i): NEXT i
DATA apple,river,tiger,cloud,pencil,orange,rocket,garden
DATA silver,dragon,puzzle,window,forest,planet,candle,marble
DATA banana,yellow,pirate,castle,jungle,coffee,violin,saturn
DATA bucket,meadow,hammer,wizard,parrot,cactus,tunnel,falcon

DO
    CLS
    COLOR 10: PRINT "PASSWORD GENERATOR": COLOR 7
    PRINT
    PRINT "  1. Random characters"
    PRINT "  2. Passphrase (random words)"
    PRINT "  Q. Quit"
    PRINT
    PRINT "  Choice: ";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    PRINT k$
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO

    IF k$ = "1" THEN
        INPUT "  Length (4-64)"; L
        IF L < 4 THEN L = 4
        IF L > 64 THEN L = 64
        INPUT "  Include UPPER case (Y/N)"; up$
        INPUT "  Include digits (Y/N)"; dg$
        INPUT "  Include symbols (Y/N)"; sy$
        INPUT "  Avoid look-alikes like 0/O 1/l (Y/N)"; av$

        ' ---- Build the pool of allowed characters ----
        pool$ = "abcdefghijklmnopqrstuvwxyz"
        IF UCASE$(LEFT$(up$, 1)) = "Y" THEN pool$ = pool$ + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        IF UCASE$(LEFT$(dg$, 1)) = "Y" THEN pool$ = pool$ + "0123456789"
        IF UCASE$(LEFT$(sy$, 1)) = "Y" THEN pool$ = pool$ + "!@#$%^&*-_=+?"
        IF UCASE$(LEFT$(av$, 1)) = "Y" THEN
            ' Rebuild the pool without the confusing characters.
            clean$ = ""
            FOR i = 1 TO LEN(pool$)
                c$ = MID$(pool$, i, 1)
                IF INSTR("0O1lI", c$) = 0 THEN clean$ = clean$ + c$
            NEXT i
            pool$ = clean$
        END IF

        PRINT
        PRINT "  Pool has"; LEN(pool$); "characters."
        PRINT
        FOR p = 1 TO 5
            pw$ = ""
            FOR i = 1 TO L
                ' INT(RND * N) + 1 gives a whole number from 1 to N.
                pw$ = pw$ + MID$(pool$, INT(RND * LEN(pool$)) + 1, 1)
            NEXT i
            PRINT "    "; pw$
        NEXT p
        bits = L * LOG(LEN(pool$)) / LOG(2)
    ELSEIF k$ = "2" THEN
        INPUT "  How many words (3-8)"; nw
        IF nw < 3 THEN nw = 3
        IF nw > 8 THEN nw = 8
        PRINT
        FOR p = 1 TO 5
            pw$ = ""
            FOR i = 1 TO nw
                pw$ = pw$ + w$(INT(RND * NWORDS) + 1) + "-"
            NEXT i
            ' finish with a 2-digit number for extra strength
            pw$ = pw$ + LTRIM$(STR$(INT(RND * 90) + 10))
            PRINT "    "; pw$
        NEXT p
        ' each word adds log2(32) = 5 bits, the number log2(90)
        bits = nw * LOG(NWORDS) / LOG(2) + LOG(90) / LOG(2)
    ELSE
        bits = -1
    END IF

    IF bits >= 0 THEN
        PRINT
        PRINT USING "  Strength: ### bits  "; bits;
        IF bits < 40 THEN
            COLOR 12: PRINT "(weak)"
        ELSEIF bits < 60 THEN
            COLOR 14: PRINT "(fair)"
        ELSE
            COLOR 10: PRINT "(strong)"
        END IF
        COLOR 7
    END IF
    PRINT
    PRINT "  Press any key..."
    DO: LOOP WHILE INKEY$ = ""
LOOP
CLS
END
