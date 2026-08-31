' ============================================================
' TITLE:    Columnar Transposition Grid
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     transposition, columnar, keyword, grid, 2D arrays
' SUMMARY:  Writes a message into a grid under a keyword and reads the columns in alphabetical order.
' ------------------------------------------------------------
' WHAT IT DOES
'   Columnar transposition was a favourite field cipher from the
'   1800s through both World Wars.  Doing it TWICE ("double
'   transposition") was strong enough that it was used by resistance
'   fighters and spies in WWII, and it formed half of the German
'   ADFGVX cipher of 1918.
'
'   How it works, with keyword ZEBRAS:
'
'        Z E B R A S        Number the key letters alphabetically:
'        6 3 2 4 1 5        A=1, B=2, E=3, R=4, S=5, Z=6
'        -----------
'        W E A R E D        Write the message in rows...
'        I S C O V E
'        R E D F L E
'        E A T O N C
'        E Q K J E U        (pad the last row with filler letters)
'
'   ...then read the columns DOWN in number order:
'        column 1 (A): EVLNE   column 2 (B): ACDTK   ...
'
'   The program draws the grid, numbers the columns and highlights
'   each column as it is read off.
'
' HOW TO USE
'   E = encrypt, D = decrypt, Q = quit.  Enter a keyword (letters,
'   2-12 long) and a message.  Spaces and punctuation are removed.
'
' CONCEPTS YOU WILL LEARN
'   * A 2-D array as a grid:  grid$(row, col)
'   * Ranking keyword letters (with ties broken left-to-right)
'   * Ceiling division:  rows = (n + cols - 1) \ cols
'   * Reversing a permutation for decryption
'   * Handling an incomplete last row (short and long columns)
'
' THINGS TO TRY
'   * Encrypt twice with two different keywords (double transposition)
'   * Use a key with repeated letters, like BALLOON - see the tie-break
'   * Count how many keys of length 6 exist (6! = 720)
' ============================================================

DECLARE SUB RankKey (k$, rank%())
DECLARE SUB DrawGrid (k$, rank%(), g$(), rows%, cols%, hiCol)

DIM grid$(40, 12), rank%(12)

DO
    CLS
    COLOR 14: PRINT "COLUMNAR TRANSPOSITION": COLOR 7
    LINE INPUT "E)ncrypt, D)ecrypt, Q)uit: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO
    IF c$ = "E" OR c$ = "D" THEN
        LINE INPUT "Keyword: "; k$
        ' Keep letters only, upper case, max 12.
        key$ = ""
        FOR i = 1 TO LEN(k$)
            ch$ = UCASE$(MID$(k$, i, 1))
            IF ch$ >= "A" AND ch$ <= "Z" AND LEN(key$) < 12 THEN key$ = key$ + ch$
        NEXT i
        IF LEN(key$) < 2 THEN key$ = "ZEBRAS": PRINT "Using keyword ZEBRAS"
        LINE INPUT "Message: "; m$
        t$ = ""
        FOR i = 1 TO LEN(m$)
            ch$ = UCASE$(MID$(m$, i, 1))
            IF ch$ >= "A" AND ch$ <= "Z" THEN t$ = t$ + ch$
        NEXT i
        IF t$ = "" THEN t$ = "WEAREDISCOVEREDFLEEATONCE"
        cols% = LEN(key$)
        IF LEN(t$) > cols% * 12 THEN t$ = LEFT$(t$, cols% * 12): PRINT "(message cut to fit 12 rows)"
        RankKey key$, rank%()
        ' Ceiling division: enough rows to hold every letter.
        rows% = (LEN(t$) + cols% - 1) \ cols%

        IF c$ = "E" THEN
            ' ---- Fill the grid row by row, padding the end ------
            ' Padding letters are random so they don't stand out.
            RANDOMIZE TIMER
            FOR r = 1 TO rows%
                FOR col = 1 TO cols%
                    p = (r - 1) * cols% + col
                    IF p <= LEN(t$) THEN
                        grid$(r, col) = MID$(t$, p, 1)
                    ELSE
                        grid$(r, col) = CHR$(65 + INT(RND * 26))
                    END IF
                NEXT col
            NEXT r
            ' ---- Read columns in rank order -------------------
            res$ = ""
            FOR n = 1 TO cols%
                FOR col = 1 TO cols%
                    IF rank%(col) = n THEN
                        DrawGrid key$, rank%(), grid$(), rows%, cols%, col
                        FOR r = 1 TO rows%: res$ = res$ + grid$(r, col): NEXT r
                        res$ = res$ + " "
                        LOCATE 22, 1: COLOR 10: PRINT "Ciphertext: "; res$: COLOR 7
                        t! = TIMER: DO WHILE TIMER - t! < .6 AND TIMER >= t!: LOOP
                    END IF
                NEXT col
            NEXT n
        ELSE
            ' ---- Decrypt ------------------------------------------
            ' If the sender did not pad, the last row is only partly
            ' full: the first 'longCols' columns have rows% letters and
            ' the rest have one fewer.  We must know each column's
            ' length before we can cut the ciphertext into columns.
            longCols = LEN(t$) - (rows% - 1) * cols%
            ' Pour each chunk down the column whose rank is 1, then
            ' 2, and so on - the exact reverse of encryption.
            p = 1
            FOR n = 1 TO cols%
                FOR col = 1 TO cols%
                    IF rank%(col) = n THEN
                        IF col <= longCols THEN h = rows% ELSE h = rows% - 1
                        FOR r = 1 TO rows%
                            IF r <= h THEN
                                grid$(r, col) = MID$(t$, p, 1): p = p + 1
                            ELSE
                                grid$(r, col) = ""   ' empty cell
                            END IF
                        NEXT r
                    END IF
                NEXT col
            NEXT n
            DrawGrid key$, rank%(), grid$(), rows%, cols%, 0
            res$ = ""
            FOR r = 1 TO rows%
                FOR col = 1 TO cols%: res$ = res$ + grid$(r, col): NEXT col
            NEXT r
            LOCATE 22, 1: COLOR 10: PRINT "Plaintext (read across): "; res$: COLOR 7
        END IF
    END IF
    LOCATE 24, 1: PRINT "Press any key...";
    a$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' DrawGrid: show the keyword, the column numbers, and the grid.
' Column hiCol (if not 0) is drawn in bright yellow.
' ------------------------------------------------------------
SUB DrawGrid (k$, rank%(), g$(), rows%, cols%, hiCol)
    top = 6
    FOR col = 1 TO cols%
        x = 10 + col * 4
        IF col = hiCol THEN fg = 14 ELSE fg = 11
        LOCATE top, x: COLOR fg: PRINT MID$(k$, col, 1);
        LOCATE top + 1, x - 1: COLOR 13: PRINT USING "##"; rank%(col);
        LOCATE top + 2, x - 1: COLOR 8: PRINT "---";
        FOR r = 1 TO rows%
            IF col = hiCol THEN COLOR 14 ELSE COLOR 7
            LOCATE top + 2 + r, x: PRINT g$(r, col);
        NEXT r
    NEXT col
    COLOR 7
END SUB

' ------------------------------------------------------------
' RankKey: rank(i) = position of key letter i in alphabetical
' order.  For each letter we count how many letters are smaller,
' plus equal letters that come earlier (so ties go left-to-right).
'   ZEBRAS -> Z=6 E=3 B=2 R=4 A=1 S=5
' ------------------------------------------------------------
SUB RankKey (k$, rank%())
    n = LEN(k$)
    FOR i = 1 TO n
        a$ = MID$(k$, i, 1)
        smaller = 0
        FOR j = 1 TO n
            b$ = MID$(k$, j, 1)
            IF b$ < a$ OR (b$ = a$ AND j < i) THEN smaller = smaller + 1
        NEXT j
        rank%(i) = smaller + 1
    NEXT i
END SUB
