' ============================================================
' TITLE:    Vocabulary Flashcards
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     vocabulary, files, Leitner boxes, WRITE #, INPUT #
' SUMMARY:  Flip word cards, add your own, and let the Leitner box system show hard words more often.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps a deck of vocabulary cards in a file called VOCAB.TXT.
'   Each card has a word, its meaning and a "box" number from 1 to 5.
'   This is the Leitner system used by language learners: new and
'   hard cards live in box 1 and come up often; every time you know a
'   card it moves up a box and appears less often.  Miss it and it
'   drops back to box 1.  Your progress is saved to the file.
'
' HOW TO USE
'   S = study 10 cards, A = add a new card, L = list all cards,
'   Q = quit (saves the deck).  While studying press any key to flip
'   the card, then Y if you knew it or N if you did not.
'
' CONCEPTS YOU WILL LEARN
'   * Creating a file the first time with OPEN ... FOR OUTPUT
'   * WRITE # and INPUT # for comma-separated data with quotes
'   * ON ERROR to detect a missing file
'   * Weighted random choice: low boxes get picked more often
'
' THINGS TO TRY
'   * Change the starter deck to words in another language
'   * Add a "D" option to delete a card
'   * Show a bar chart of how many cards are in each box
' ============================================================

DECLARE SUB SaveDeck ()
DECLARE SUB ShowCard (txt$, col!)

CONST MAXC = 200
DIM SHARED word$(1 TO MAXC), mean$(1 TO MAXC), box(1 TO MAXC), count
RANDOMIZE TIMER

' ---- load the deck, or create a starter deck if there is none ----
fileOk = -1
ON ERROR GOTO NoFile
OPEN "VOCAB.TXT" FOR INPUT AS #1
ON ERROR GOTO 0
IF fileOk THEN
    DO WHILE NOT EOF(1) AND count < MAXC
        count = count + 1
        INPUT #1, word$(count), mean$(count), box(count)
    LOOP
    CLOSE #1
ELSE
    ' First run: READ the starter words from DATA
    DO
        READ w$, m$
        IF w$ = "*" THEN EXIT DO
        count = count + 1
        word$(count) = w$: mean$(count) = m$: box(count) = 1
    LOOP
    SaveDeck
END IF

DO
    CLS
    COLOR 14: PRINT "  ===== VOCABULARY FLASHCARDS ====="
    COLOR 7: PRINT "  Cards in deck:"; count
    ' Count cards per box for a quick progress report
    PRINT "  Boxes: ";
    FOR b = 1 TO 5
        n = 0
        FOR i = 1 TO count: IF box(i) = b THEN n = n + 1
        NEXT i
        COLOR 8 + b: PRINT "[" + LTRIM$(STR$(b)) + ":" + LTRIM$(STR$(n)) + "] ";
    NEXT b
    COLOR 7: PRINT
    PRINT
    PRINT "  S) Study   A) Add a card   L) List   Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "S": GOSUB Study
        CASE "A": GOSUB AddCard
        CASE "L": GOSUB ListCards
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
SaveDeck
CLS
PRINT "Deck saved to VOCAB.TXT. Keep learning!"
END

NoFile:
    fileOk = 0                  ' remember the file was not there
    RESUME NEXT

' ------------------------------------------------------------
' Study: 10 cards chosen with a weighted lottery.  A card in box b
' gets (6 - b) tickets, so box 1 cards have 5 tickets and box 5
' cards only 1 - hard words come up five times as often.
' ------------------------------------------------------------
Study:
    IF count = 0 THEN RETURN
    known = 0
    FOR q = 1 TO 10
        tickets = 0
        FOR i = 1 TO count: tickets = tickets + (6 - box(i)): NEXT i
        pick = INT(RND * tickets)          ' draw a ticket 0 .. tickets-1
        c = 0
        DO                                 ' find whose ticket it was
            c = c + 1
            pick = pick - (6 - box(c))
        LOOP UNTIL pick < 0
        CLS
        COLOR 14: PRINT "  Card"; q; "of 10   (box"; box(c); ")"
        ShowCard word$(c), 11
        LOCATE 14, 20: COLOR 7: PRINT "Think of the meaning... press a key to flip";
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        IF k$ = CHR$(27) THEN EXIT FOR
        ShowCard mean$(c), 10
        LOCATE 14, 20: PRINT SPACE$(50);
        LOCATE 14, 20: COLOR 15: PRINT "Did you know it? (Y/N)";
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
        IF k$ = CHR$(27) THEN EXIT FOR
        IF k$ = "Y" THEN
            known = known + 1
            IF box(c) < 5 THEN box(c) = box(c) + 1   ' promote
        ELSE
            box(c) = 1                               ' back to the start
        END IF
    NEXT q
    CLS
    COLOR 14: PRINT: PRINT "  You knew"; known; "cards. ";
    IF known >= 8 THEN PRINT "Wonderful memory!" ELSE PRINT "Every review makes them stick!"
    SaveDeck
    COLOR 7: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

AddCard:
    IF count >= MAXC THEN RETURN
    PRINT
    LINE INPUT "  New word (blank = cancel): "; w$
    IF LTRIM$(w$) = "" THEN RETURN
    LINE INPUT "  Its meaning: "; m$
    count = count + 1
    word$(count) = w$: mean$(count) = m$: box(count) = 1
    SaveDeck
    RETURN

ListCards:
    CLS
    FOR i = 1 TO count
        COLOR 8 + box(i): PRINT box(i);
        COLOR 15: PRINT word$(i);: COLOR 7: PRINT " - "; mean$(i)
        ' Pause every 20 lines so nothing scrolls away
        IF i MOD 20 = 0 THEN PRINT "  -- more --": DO: LOOP WHILE INKEY$ = ""
    NEXT i
    PRINT: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
    RETURN

' Starter deck: word, meaning.  "*" ends the list.
DATA enormous, "very, very big"
DATA ancient, very old
DATA brave, not afraid to do something hard
DATA curious, wanting to know or learn about things
DATA delicate, easily broken or damaged
DATA gloomy, dark and sad
DATA hesitate, to stop for a moment before doing something
DATA migrate, to move from one place to another with the seasons
DATA nocturnal, active at night
DATA predict, to say what will happen in the future
DATA *, *

' WRITE # puts quotes around strings and commas between items, so
' meanings that contain commas are read back correctly by INPUT #.
SUB SaveDeck
    OPEN "VOCAB.TXT" FOR OUTPUT AS #1
    FOR i = 1 TO count
        WRITE #1, word$(i), mean$(i), box(i)
    NEXT i
    CLOSE #1
END SUB

' Draws a card: a box of characters with the text in the middle.
SUB ShowCard (txt$, col)
    COLOR col
    LOCATE 5, 10: PRINT CHR$(201); STRING$(58, 205); CHR$(187)
    FOR r = 6 TO 10
        LOCATE r, 10: PRINT CHR$(186); SPACE$(58); CHR$(186)
    NEXT r
    LOCATE 11, 10: PRINT CHR$(200); STRING$(58, 205); CHR$(188)
    t$ = LEFT$(txt$, 56)
    LOCATE 8, 11 + (58 - LEN(t$)) \ 2: COLOR 15: PRINT t$
END SUB
