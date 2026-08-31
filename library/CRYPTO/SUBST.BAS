' ============================================================
' TITLE:    Cryptogram Solver's Workbench
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     substitution cipher, cryptogram, shuffle, frequency, puzzle
' SUMMARY:  Solve newspaper-style cryptograms with a helper that tracks your letter guesses and shows frequencies.
' ------------------------------------------------------------
' WHAT IT DOES
'   A simple substitution cipher replaces every letter with another
'   letter using a scrambled alphabet.  There are 26! (about
'   4 x 10^26) possible keys - far too many to try them all - yet
'   puzzle fans solve these "cryptograms" in newspapers every day!
'   Mary Queen of Scots trusted a substitution cipher in 1586; it was
'   broken by Thomas Phelippes, and she was executed.
'
'   The tricks solvers use:
'     * The most common cipher letter is probably E (then T, A, O...)
'     * One-letter words are A or I
'     * A common three-letter word is often THE or AND
'     * Doubled letters are often LL, EE, SS, OO, TT
'
'   This workbench picks a famous quote, scrambles it with a random
'   alphabet, and lets you try guesses.  Your guesses appear in
'   green under each cipher letter; unknown letters show as "_".
'
' HOW TO USE
'   Type two letters and Enter:  XE  means "cipher X is plain E".
'   Type a letter and a dash:    X-  removes the guess for X.
'   ?  = reveal one correct letter (a hint)
'   N  = new puzzle,   Q = quit  (Enter alone also quits)
'
' CONCEPTS YOU WILL LEARN
'   * Fisher-Yates shuffle to build a random key
'   * A derangement: making sure no letter maps to itself
'   * Two lookup tables (cipher->plain guesses, plain->cipher)
'   * Word-wrapping text with cipher and guess lines kept aligned
'
' THINGS TO TRY
'   * Add your own quotes to the DATA list
'   * Show a warning when two cipher letters get the same guess
'   * Highlight one-letter and three-letter words in a special colour
' ============================================================

DECLARE SUB NewPuzzle ()
DECLARE SUB Show ()

DIM SHARED quote$, cipher$, keyMap(25), guess(25), nQuotes, msg$
' keyMap(p) = cipher letter for plain letter p   (the real key)
' guess(c)  = player's plain guess for cipher letter c (-1 = none)

' Count the quotes once so we can choose one at random.
DO
    READ q$
    IF q$ = "*" THEN EXIT DO
    nQuotes = nQuotes + 1
LOOP
RANDOMIZE TIMER
NewPuzzle

DO
    Show
    LOCATE 23, 1: PRINT SPACE$(79);
    LOCATE 23, 1: LINE INPUT "Guess (e.g. XE), X- to clear, ? hint, N new, Q quit: "; g$
    g$ = UCASE$(LTRIM$(RTRIM$(g$)))
    msg$ = ""
    IF g$ = "" OR g$ = "Q" THEN EXIT DO
    IF g$ = "N" THEN
        NewPuzzle
    ELSEIF g$ = "?" THEN
        ' Find a cipher letter in the puzzle that is not yet guessed
        ' correctly, and fill it in.
        FOR p = 0 TO 25
            c = keyMap(p)
            IF INSTR(cipher$, CHR$(65 + c)) > 0 AND guess(c) <> p THEN
                guess(c) = p
                msg$ = "Hint: " + CHR$(65 + c) + " is " + CHR$(65 + p)
                EXIT FOR
            END IF
        NEXT p
    ELSEIF LEN(g$) = 2 THEN
        c = ASC(g$) - 65
        IF c < 0 OR c > 25 THEN
            msg$ = "First character must be a cipher letter A-Z."
        ELSEIF MID$(g$, 2, 1) = "-" THEN
            guess(c) = -1
        ELSE
            p = ASC(MID$(g$, 2, 1)) - 65
            IF p < 0 OR p > 25 THEN
                msg$ = "Second character must be a letter or '-'."
            ELSE
                ' A plain letter can only come from ONE cipher letter,
                ' so remove the same guess anywhere else first.
                FOR i = 0 TO 25: IF guess(i) = p THEN guess(i) = -1
                NEXT i
                guess(c) = p
            END IF
        END IF
    ELSE
        msg$ = "Type two letters like  QE  (cipher Q = plain E)."
    END IF
LOOP
CLS
PRINT "The quote was:"
PRINT quote$
END

DATA "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG."
DATA "IMAGINATION IS MORE IMPORTANT THAN KNOWLEDGE. - EINSTEIN"
DATA "THE ONLY WAY TO DO GREAT WORK IS TO LOVE WHAT YOU DO."
DATA "THREE MAY KEEP A SECRET, IF TWO OF THEM ARE DEAD. - FRANKLIN"
DATA "IT ALWAYS SEEMS IMPOSSIBLE UNTIL IT IS DONE. - NELSON MANDELA"
DATA "WE CAN ONLY SEE A SHORT DISTANCE AHEAD, BUT WE CAN SEE PLENTY THERE THAT NEEDS TO BE DONE. - ALAN TURING"
DATA "ANY SUFFICIENTLY ADVANCED TECHNOLOGY IS INDISTINGUISHABLE FROM MAGIC. - ARTHUR C CLARKE"
DATA "*"

' ------------------------------------------------------------
' NewPuzzle: choose a random quote and a random key.
'   Fisher-Yates shuffle: walk from the end of the list; swap each
'   item with a random item at or before it.  Every one of the 26!
'   orders is equally likely.  We repeat until no letter maps to
'   itself (a "derangement"), otherwise some letters would be free.
' ------------------------------------------------------------
SUB NewPuzzle
    RESTORE
    pick = INT(RND * nQuotes)
    FOR i = 0 TO pick: READ quote$: NEXT i
    DO
        FOR i = 0 TO 25: keyMap(i) = i: NEXT i
        FOR i = 25 TO 1 STEP -1
            j = INT(RND * (i + 1))
            SWAP keyMap(i), keyMap(j)
        NEXT i
        fixed = 0
        FOR i = 0 TO 25: IF keyMap(i) = i THEN fixed = 1
        NEXT i
    LOOP WHILE fixed
    FOR i = 0 TO 25: guess(i) = -1: NEXT i
    ' Encrypt the quote with the key.
    cipher$ = quote$
    FOR i = 1 TO LEN(cipher$)
        p = ASC(MID$(cipher$, i, 1)) - 65
        IF p >= 0 AND p <= 25 THEN MID$(cipher$, i, 1) = CHR$(65 + keyMap(p))
    NEXT i
    msg$ = "New puzzle!  Tip: the most frequent letter is often E."
END SUB

' ------------------------------------------------------------
' Show: draw the puzzle.  Each line of cipher text (cyan) has the
' player's guesses printed directly below it (green), so letters
' line up column for column.  Lines break at spaces near 70 chars.
' ------------------------------------------------------------
SUB Show
    CLS
    COLOR 14: PRINT "CRYPTOGRAM WORKBENCH": COLOR 7
    PRINT
    row = 3: start = 1: L = LEN(cipher$)
    DO WHILE start <= L
        ' Find a good place to break the line.
        stop1 = start + 69
        IF stop1 >= L THEN
            stop1 = L
        ELSE
            DO WHILE MID$(cipher$, stop1, 1) <> " " AND stop1 > start: stop1 = stop1 - 1: LOOP
        END IF
        piece$ = MID$(cipher$, start, stop1 - start + 1)
        LOCATE row, 3: COLOR 11: PRINT piece$
        LOCATE row + 1, 3
        FOR i = 1 TO LEN(piece$)
            c = ASC(MID$(piece$, i, 1)) - 65
            IF c >= 0 AND c <= 25 THEN
                IF guess(c) >= 0 THEN COLOR 10: PRINT CHR$(65 + guess(c)); ELSE COLOR 8: PRINT "_";
            ELSE
                COLOR 7: PRINT MID$(piece$, i, 1);
            END IF
        NEXT i
        row = row + 3: start = stop1 + 1
    LOOP

    ' ---- Frequency table of the cipher letters -------------
    DIM f(25)
    FOR i = 1 TO L
        c = ASC(MID$(cipher$, i, 1)) - 65
        IF c >= 0 AND c <= 25 THEN f(c) = f(c) + 1
    NEXT i
    LOCATE 14, 2: COLOR 14
    PRINT "Cipher letter (cyan), how often it appears, your guess (green):"
    FOR c = 0 TO 25
        LOCATE 15, 3 + c * 3: COLOR 11: PRINT CHR$(65 + c);
        LOCATE 16, 2 + c * 3: COLOR 7
        IF f(c) > 0 THEN PRINT USING "##"; f(c); ELSE PRINT " .";
        LOCATE 17, 3 + c * 3
        IF guess(c) >= 0 THEN COLOR 10: PRINT CHR$(65 + guess(c)); ELSE COLOR 8: PRINT "-";
    NEXT c

    ' ---- Solved? ---------------------------------------------
    solved = 1
    FOR i = 1 TO L
        c = ASC(MID$(cipher$, i, 1)) - 65
        IF c >= 0 AND c <= 25 THEN
            ' Correct means: the guessed plain letter really encrypts
            ' to this cipher letter under the secret key.
            IF guess(c) < 0 THEN
                solved = 0
            ELSEIF keyMap(guess(c)) <> c THEN
                solved = 0
            END IF
        END IF
    NEXT i
    LOCATE 20, 1
    IF solved THEN
        COLOR 10: PRINT "*** SOLVED!  Press N for a new puzzle. ***"
    ELSE
        COLOR 13: PRINT msg$
    END IF
    COLOR 7
END SUB
