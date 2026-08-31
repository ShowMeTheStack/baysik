' ============================================================
' TITLE:    Playfair Cipher Square
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     playfair, digraph, 5x5 grid, wheatstone, 2D arrays
' SUMMARY:  Builds the 5x5 Playfair key square and encrypts letter PAIRS, explaining the row/column/rectangle rule for each.
' ------------------------------------------------------------
' WHAT IT DOES
'   Invented by Charles Wheatstone in 1854 and promoted by Lord
'   Playfair, this was the first practical cipher that encrypts
'   PAIRS of letters (digraphs) instead of single letters.  The
'   British used it in the Boer War and WWI; in WWII a young John F.
'   Kennedy's rescue message after PT-109 sank was sent in Playfair.
'
'   THE KEY SQUARE: write the keyword (dropping repeated letters)
'   into a 5x5 grid, then the rest of the alphabet.  25 cells but
'   26 letters, so I and J share a cell.
'
'   PREPARE THE MESSAGE: split into pairs.  If a pair would be a
'   double letter (LL in "BALLOON"), put an X between them.  If one
'   letter is left at the end, add an X.
'
'   ENCRYPT EACH PAIR by finding both letters in the square:
'     * SAME ROW     -> take the letter to the RIGHT of each (wrap)
'     * SAME COLUMN  -> take the letter BELOW each (wrap)
'     * otherwise    -> they make a rectangle's corners: take the
'                       letter in the same ROW but the OTHER corner's
'                       COLUMN.
'   Decryption does the same but LEFT / UP.
'
'   Since there are 600 possible digraphs, single-letter frequency
'   analysis no longer works - you need statistics on pairs.
'
' HOW TO USE
'   Enter a keyword, then choose E/D and type a message.  Each pair
'   is shown with the rule that was applied.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Filling a 2-D grid and building a reverse lookup (letter -> row, col)
'   * Wrap-around with MOD 5 (and +4 MOD 5 to step backwards)
'   * Preparing input with simple rules before encrypting
'
' THINGS TO TRY
'   * Encrypt HELLO WORLD with key PLAYFAIR EXAMPLE
'   * Notice that a pair and its reverse (AB, BA) give reversed results
'   * Make a 6x6 version with digits 0-9 (no I/J merge needed)
' ============================================================

DECLARE SUB BuildSquare (k$)
DECLARE SUB ShowSquare ()
DECLARE FUNCTION Prepare$ (m$)
DECLARE FUNCTION DoPair$ (a$, b$, dirn%, rule$)

DIM SHARED sq$(4, 4), rowOf(25), colOf(25)

CLS
COLOR 14: PRINT "PLAYFAIR CIPHER": COLOR 7
LINE INPUT "Keyword (Enter = PLAYFAIR EXAMPLE): "; k$
IF k$ = "" THEN k$ = "PLAYFAIR EXAMPLE"
BuildSquare k$

DO
    CLS
    COLOR 14: PRINT "PLAYFAIR CIPHER   key: "; UCASE$(k$): COLOR 7
    ShowSquare
    LOCATE 9, 1
    LINE INPUT "E)ncrypt, D)ecrypt, K)ey change, Q)uit: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO
    IF c$ = "K" THEN
        LINE INPUT "New keyword: "; k2$
        IF k2$ <> "" THEN k$ = k2$: BuildSquare k$
    ELSEIF c$ = "E" OR c$ = "D" THEN
        LINE INPUT "Message: "; m$
        IF m$ = "" THEN m$ = "Hide the gold in the tree stump"
        p$ = Prepare$(m$)
        IF LEN(p$) > 48 THEN p$ = LEFT$(p$, 48): PRINT "(shortened to 24 pairs)"
        IF c$ = "E" THEN dirn% = 1 ELSE dirn% = -1
        PRINT "Pairs: ";
        FOR i = 1 TO LEN(p$) STEP 2: PRINT MID$(p$, i, 2); " "; : NEXT i
        PRINT
        ' Show each pair and the rule in two columns to save space.
        res$ = ""
        row = CSRLIN
        FOR i = 1 TO LEN(p$) STEP 2
            pr$ = DoPair$(MID$(p$, i, 1), MID$(p$, i + 1, 1), dirn%, rule$)
            res$ = res$ + pr$ + " "
            n = (i - 1) \ 2
            IF n < 8 THEN
                LOCATE row + n, 1
                PRINT "  "; MID$(p$, i, 2); " -> "; pr$; "  "; rule$
            END IF
        NEXT i
        LOCATE row + 9, 1
        COLOR 10: PRINT "Result: "; res$: COLOR 7
        IF dirn% = -1 THEN PRINT "(Remove the extra X's that were added as padding.)"
    END IF
    PRINT
    PRINT "Press any key...";
    a$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' BuildSquare: write the keyword then the remaining letters into
' sq$(row, col).  'used' remembers which letters are already in.
' J is treated as I.  We also store each letter's row and column
' so we can find any letter instantly instead of searching.
' ------------------------------------------------------------
SUB BuildSquare (k$)
    DIM used(25)
    src$ = UCASE$(k$) + "ABCDEFGHIKLMNOPQRSTUVWXYZ"
    pos1 = 0
    FOR i = 1 TO LEN(src$)
        ch$ = MID$(src$, i, 1)
        IF ch$ = "J" THEN ch$ = "I"
        c = ASC(ch$) - 65
        IF c >= 0 AND c <= 25 THEN
            IF used(c) = 0 THEN
                used(c) = 1
                r = pos1 \ 5: cl = pos1 MOD 5
                sq$(r, cl) = ch$
                rowOf(c) = r: colOf(c) = cl
                pos1 = pos1 + 1
            END IF
        END IF
    NEXT i
    ' J lives in the same cell as I.
    rowOf(9) = rowOf(8): colOf(9) = colOf(8)
END SUB

' ------------------------------------------------------------
' ShowSquare: print the grid with a little frame.
' ------------------------------------------------------------
SUB ShowSquare
    FOR r = 0 TO 4
        LOCATE 3 + r, 4
        FOR c = 0 TO 4
            COLOR 11: PRINT " "; sq$(r, c); " ";
        NEXT c
    NEXT r
    COLOR 8
    LOCATE 3, 26: PRINT "same row    -> letter to the right"
    LOCATE 4, 26: PRINT "same column -> letter below"
    LOCATE 5, 26: PRINT "rectangle   -> swap the columns"
    LOCATE 6, 26: PRINT "(decrypt: left / up)   I and J share a cell"
    COLOR 7
END SUB

' ------------------------------------------------------------
' Prepare$: letters only, J->I, split doubles with X, even length.
' If the doubled letter is itself X we use Q as the filler.
' ------------------------------------------------------------
FUNCTION Prepare$ (m$)
    t$ = ""
    FOR i = 1 TO LEN(m$)
        ch$ = UCASE$(MID$(m$, i, 1))
        IF ch$ = "J" THEN ch$ = "I"
        IF ch$ >= "A" AND ch$ <= "Z" THEN t$ = t$ + ch$
    NEXT i
    r$ = ""
    i = 1
    DO WHILE i <= LEN(t$)
        a$ = MID$(t$, i, 1)
        b$ = MID$(t$, i + 1, 1)          ' "" if past the end
        IF b$ = "" THEN
            IF a$ = "X" THEN b$ = "Q" ELSE b$ = "X"
            r$ = r$ + a$ + b$: i = i + 1
        ELSEIF a$ = b$ THEN
            IF a$ = "X" THEN r$ = r$ + a$ + "Q" ELSE r$ = r$ + a$ + "X"
            i = i + 1                   ' b$ starts the next pair
        ELSE
            r$ = r$ + a$ + b$: i = i + 2
        END IF
    LOOP
    Prepare$ = r$
END FUNCTION

' ------------------------------------------------------------
' DoPair$: apply the three Playfair rules to one pair.
' dirn% = 1 encrypt (right/down), -1 decrypt (left/up).
' Adding 5 before MOD keeps negative numbers away.
' ------------------------------------------------------------
FUNCTION DoPair$ (a$, b$, dirn%, rule$)
    ca = ASC(a$) - 65: cb = ASC(b$) - 65
    ra = rowOf(ca): ka = colOf(ca)
    rb = rowOf(cb): kb = colOf(cb)
    IF ra = rb THEN
        rule$ = "same row"
        DoPair$ = sq$(ra, (ka + dirn% + 5) MOD 5) + sq$(rb, (kb + dirn% + 5) MOD 5)
    ELSEIF ka = kb THEN
        rule$ = "same column"
        DoPair$ = sq$((ra + dirn% + 5) MOD 5, ka) + sq$((rb + dirn% + 5) MOD 5, kb)
    ELSE
        rule$ = "rectangle"
        DoPair$ = sq$(ra, kb) + sq$(rb, ka)
    END IF
END FUNCTION
