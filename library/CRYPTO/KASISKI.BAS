' ============================================================
' TITLE:    Breaking Vigenere: Kasiski & Index of Coincidence
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     vigenere, kasiski, index of coincidence, chi-squared, cryptanalysis
' SUMMARY:  Cracks a Vigenere message with no key: guesses the key length, then each key letter, then reads the secret.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Vigenere cipher (see VIGENERE.BAS) was "unbreakable" for
'   300 years.  In 1863 the Prussian officer Friedrich Kasiski
'   published the trick that breaks it (Charles Babbage had found it
'   privately around 1854).  This program performs the full attack:
'
'   STEP 1 - KASISKI TEST.  If a common word like "THE" happens to
'     line up with the same part of the key twice, it produces the
'     same three cipher letters twice.  The distance between the
'     repeats is then a multiple of the key length.  We find every
'     repeated trigram and count which numbers divide the distances.
'
'   STEP 2 - INDEX OF COINCIDENCE (William Friedman, 1922).  Pick
'     two letters at random from a text: how likely are they equal?
'       IC = SUM( n_i * (n_i - 1) ) / ( N * (N - 1) )
'     English text gives about 0.066 (because E, T, A... repeat a lot),
'     random letters give 1/26 = 0.038.  If we guess key length L
'     and split the ciphertext into L columns (every L-th letter),
'     each column was shifted by ONE key letter, so it is just a
'     Caesar cipher and its IC looks like English.  Wrong guesses
'     mix several shifts and look random.
'
'   STEP 3 - CHI-SQUARED.  For each column, try all 26 shifts and
'     compare the letter counts with English using
'       X^2 = SUM( (observed - expected)^2 / expected )
'     The smallest X^2 marks the right key letter.
'
' HOW TO USE
'   Enter a secret keyword (letters) to encrypt the built-in text,
'   or just press Enter for a random hidden key.  Then press a key
'   to move through the three steps and see the message recovered.
'   Esc quits at any pause.
'
' CONCEPTS YOU WILL LEARN
'   * Turning trigrams into single numbers for fast comparison
'   * Divisor counting and statistics as code-breaking tools
'   * Index of coincidence and the chi-squared goodness-of-fit test
'   * Working with letter arrays instead of strings for speed
'
' THINGS TO TRY
'   * Use a very long key (12+ letters).  When does the attack fail?
'   * Shorten the text (fewer DATA lines).  How much text is needed?
'   * Change MAXL to search longer keys
' ============================================================

DECLARE SUB Pause ()
DECLARE FUNCTION ColumnIC! (L, col)

CONST MAXL = 12              ' longest key length we will test
DIM SHARED txt%(1000), n%    ' ciphertext letters as 0..25
DIM SHARED eng!(25)          ' English letter probabilities
DIM tri&(1000), divCnt%(MAXL), avgIC!(MAXL)

FOR i = 0 TO 25: READ eng!(i): eng!(i) = eng!(i) / 100: NEXT i
DATA 8.2,1.5,2.8,4.3,12.7,2.2,2.0,6.1,7.0,0.15,0.77,4.0,2.4
DATA 6.7,7.5,1.9,0.095,6.0,6.3,9.1,2.8,0.98,2.4,0.15,2.0,0.074

' ---- Read the plaintext (letters only, upper case) ------------
plain$ = ""
DO
    READ ln$
    IF ln$ = "*" THEN EXIT DO
    FOR i = 1 TO LEN(ln$)
        ch$ = UCASE$(MID$(ln$, i, 1))
        IF ch$ >= "A" AND ch$ <= "Z" THEN plain$ = plain$ + ch$
    NEXT i
LOOP

CLS
COLOR 14: PRINT "BREAKING THE VIGENERE CIPHER": COLOR 7
PRINT
PRINT "The computer will encrypt a"; LEN(plain$); "letter English text with a"
PRINT "keyword, then try to break it WITHOUT being told the key."
PRINT
LINE INPUT "Secret keyword (Enter = random): "; k$
key$ = ""
FOR i = 1 TO LEN(k$)
    ch$ = UCASE$(MID$(k$, i, 1))
    IF ch$ >= "A" AND ch$ <= "Z" THEN key$ = key$ + ch$
NEXT i
IF key$ = "" THEN
    ' Random key of 4 to 8 letters - we will not peek at it!
    RANDOMIZE TIMER
    FOR i = 1 TO 4 + INT(RND * 5): key$ = key$ + CHR$(65 + INT(RND * 26)): NEXT i
    hidden = 1
END IF

' ---- Encrypt into the txt%() array ---------------------------
n% = LEN(plain$)
FOR i = 1 TO n%
    p = ASC(MID$(plain$, i, 1)) - 65
    kk = ASC(MID$(key$, ((i - 1) MOD LEN(key$)) + 1, 1)) - 65
    txt%(i) = (p + kk) MOD 26
NEXT i
PRINT
PRINT "Ciphertext (first 300 letters, in groups of 5):"
COLOR 11
FOR i = 1 TO 300
    PRINT CHR$(txt%(i) + 65);
    IF i MOD 5 = 0 THEN PRINT " ";
NEXT i
COLOR 7: PRINT
Pause

' ============================================================
' STEP 1: Kasiski test
' ============================================================
CLS
COLOR 14: PRINT "STEP 1: KASISKI TEST - repeated trigrams": COLOR 7
' Encode each trigram starting at i as one number 0..17575
' (like a 3-digit number in base 26).  Comparing numbers is far
' faster than comparing strings with MID$.
FOR i = 1 TO n% - 2
    tri&(i) = txt%(i) * 676& + txt%(i + 1) * 26 + txt%(i + 2)
NEXT i
pairs = 0
FOR i = 1 TO n% - 3
    FOR j = i + 1 TO n% - 2
        IF tri&(i) = tri&(j) THEN
            d = j - i
            pairs = pairs + 1
            IF pairs <= 5 THEN
                PRINT "  "; CHR$(txt%(i) + 65); CHR$(txt%(i + 1) + 65); CHR$(txt%(i + 2) + 65);
                PRINT " at"; i; "and"; j; " distance"; d
            END IF
            ' Every L from 2 to MAXL that divides the distance gets a vote.
            FOR L = 2 TO MAXL
                IF d MOD L = 0 THEN divCnt%(L) = divCnt%(L) + 1
            NEXT L
        END IF
    NEXT j
NEXT i
PRINT "  ... "; pairs; "repeats found in total."
PRINT
PRINT "Votes: how many distances each length divides"
mx = 1
FOR L = 2 TO MAXL: IF divCnt%(L) > mx THEN mx = divCnt%(L)
NEXT L
FOR L = 2 TO MAXL
    PRINT USING "  L=##  ###  "; L; divCnt%(L);
    COLOR 10: PRINT STRING$(divCnt%(L) * 40 \ mx, 219): COLOR 7
NEXT L
PRINT "Small numbers always get many votes (every even distance votes"
PRINT "for 2), so look for the LARGEST length that still scores high."
Pause

' ============================================================
' STEP 2: Index of coincidence for each length
' ============================================================
CLS
COLOR 14: PRINT "STEP 2: INDEX OF COINCIDENCE": COLOR 7
PRINT "English ~ 0.066    random ~ 0.038"
PRINT
bestL = 1
FOR L = 1 TO MAXL
    s! = 0
    FOR col = 0 TO L - 1: s! = s! + ColumnIC!(L, col): NEXT col
    avgIC!(L) = s! / L
    PRINT USING "  L=##  IC=#.####  "; L; avgIC!(L);
    ' Draw a bar scaled so 0.030 .. 0.075 spans 45 characters.
    bar = INT((avgIC!(L) - .03) * 1000)
    IF bar < 0 THEN bar = 0
    IF bar > 45 THEN bar = 45
    IF avgIC!(L) > .055 THEN COLOR 10 ELSE COLOR 8
    PRINT STRING$(bar, 219): COLOR 7
NEXT L
' Choose the SMALLEST length that looks English.  Multiples of
' the true length (2L, 3L...) also look English, so we stop at
' the first good one.
FOR L = 1 TO MAXL
    IF avgIC!(L) > .055 THEN bestL = L: EXIT FOR
NEXT L
IF bestL = 1 AND avgIC!(1) <= .055 THEN
    ' Nothing passed the threshold; fall back to the highest IC.
    FOR L = 2 TO MAXL: IF avgIC!(L) > avgIC!(bestL) THEN bestL = L
    NEXT L
END IF
PRINT
COLOR 10: PRINT "Best guess for key length:"; bestL: COLOR 7
Pause

' ============================================================
' STEP 3: Chi-squared on each column to find each key letter
' ============================================================
CLS
COLOR 14: PRINT "STEP 3: CHI-SQUARED - one Caesar shift per column": COLOR 7
PRINT
guess$ = ""
DIM cnt(25)
FOR col = 0 TO bestL - 1
    ' Count letters in this column.
    FOR c = 0 TO 25: cnt(c) = 0: NEXT c
    total = 0
    FOR i = col + 1 TO n% STEP bestL
        cnt(txt%(i)) = cnt(txt%(i)) + 1: total = total + 1
    NEXT i
    ' Try every shift; shifting back by s should give English.
    bestChi! = 1E+30: bestS = 0
    FOR s = 0 TO 25
        chi! = 0
        FOR c = 0 TO 25
            obs = cnt((c + s) MOD 26)     ' cipher letter that would become c
            ex! = eng!(c) * total
            chi! = chi! + (obs - ex!) ^ 2 / ex!
        NEXT c
        IF chi! < bestChi! THEN bestChi! = chi!: bestS = s
    NEXT s
    guess$ = guess$ + CHR$(65 + bestS)
    PRINT USING "  Column ##: best shift ## = letter "; col + 1; bestS;
    PRINT CHR$(65 + bestS);
    PRINT USING "   (chi-squared ####.#)"; bestChi!
NEXT col
PRINT
COLOR 10: PRINT "Recovered key: "; guess$: COLOR 7
IF hidden THEN PRINT "Actual key:    "; key$ ELSE PRINT "Your key:      "; key$
PRINT
PRINT "Decryption (first 240 letters):"
COLOR 15
FOR i = 1 TO 240
    kk = ASC(MID$(guess$, ((i - 1) MOD LEN(guess$)) + 1, 1)) - 65
    PRINT CHR$((txt%(i) - kk + 26) MOD 26 + 65);
NEXT i
COLOR 7: PRINT
PRINT
PRINT "(If the key repeats itself, e.g. ABAB, the shorter key is found -"
PRINT " it decrypts just the same!)  Press a key to finish."
a$ = INPUT$(1)
END

' The secret message: plain English, many sentences, so the
' statistics have enough letters to work with.
DATA "It was the best of times, it was the worst of times, it was"
DATA "the age of wisdom, it was the age of foolishness, it was the"
DATA "epoch of belief, it was the epoch of incredulity, it was the"
DATA "season of light, it was the season of darkness, it was the"
DATA "spring of hope, it was the winter of despair, we had everything"
DATA "before us, we had nothing before us, we were all going direct"
DATA "to heaven, we were all going direct the other way. In short,"
DATA "the period was so far like the present period, that some of its"
DATA "noisiest authorities insisted on its being received, for good"
DATA "or for evil, in the superlative degree of comparison only."
DATA "*"

' ------------------------------------------------------------
' ColumnIC: index of coincidence of column col when the text is
' split into L columns (letters col+1, col+1+L, ...).
' ------------------------------------------------------------
FUNCTION ColumnIC! (L, col)
    DIM c(25)
    total = 0
    FOR i = col + 1 TO n% STEP L
        c(txt%(i)) = c(txt%(i)) + 1: total = total + 1
    NEXT i
    IF total < 2 THEN ColumnIC! = 0: EXIT FUNCTION
    s& = 0
    FOR k = 0 TO 25: s& = s& + c(k) * (c(k) - 1): NEXT k
    ColumnIC! = s& / (total * (total - 1#))
END FUNCTION

' ------------------------------------------------------------
' Pause: wait for a key; Esc ends the program.
' ------------------------------------------------------------
SUB Pause
    PRINT
    COLOR 8: PRINT "Press any key to continue (Esc = quit)"; : COLOR 7
    a$ = INPUT$(1)
    IF a$ = CHR$(27) THEN CLS : END
END SUB
