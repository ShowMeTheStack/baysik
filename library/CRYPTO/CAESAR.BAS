' ============================================================
' TITLE:    Caesar Cipher & Brute-Force Cracker
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     caesar, shift cipher, brute force, MOD, ASCII
' SUMMARY:  Encrypt with Julius Caesar's shift cipher, then crack it by trying all 25 keys and scoring English.
' ------------------------------------------------------------
' WHAT IT DOES
'   About 2,000 years ago Julius Caesar protected his military
'   letters by replacing every letter with the one three places
'   further down the alphabet:  A->D, B->E, ... X->A, Y->B, Z->C.
'   The number of places is the KEY (Caesar used 3).
'
'   This program lets you encrypt and decrypt with any key, and
'   then shows why the cipher is weak: there are only 25 useful
'   keys, so a computer can simply try them ALL (a "brute-force
'   attack").  To pick the right answer automatically it scores
'   every attempt by how "English-looking" the letters are.
'
' HOW TO USE
'   Menu:  1 = encrypt,  2 = decrypt,  3 = crack (brute force),
'          Q = quit.   Type messages in any case; punctuation and
'   spaces are left untouched.
'
' CONCEPTS YOU WILL LEARN
'   * ASC and CHR$ - turning letters into numbers and back
'   * Modular arithmetic: (x + k) MOD 26 "wraps around" the alphabet
'   * Brute-force search over a small key space
'   * Scoring candidates with a letter-frequency table
'
' THINGS TO TRY
'   * Encrypt with key 13, then encrypt the result with 13 again
'   * Crack a very short message (3 letters) - does scoring still work?
'   * Change the scoring to count only E, T, A, O, I, N
' ============================================================

DECLARE FUNCTION Shift$ (t$, k%)
DECLARE FUNCTION EnglishScore! (t$)

' ---- English letter frequencies (percent), A..Z --------------
' These numbers come from counting letters in huge amounts of
' English text.  E is the most common letter (about 12.7%), Z the
' rarest (0.07%).  We use them to judge how "English" a string is.
DIM SHARED freq!(25)
FOR i = 0 TO 25: READ freq!(i): NEXT i
DATA 8.2,1.5,2.8,4.3,12.7,2.2,2.0,6.1,7.0,0.15,0.77,4.0,2.4
DATA 6.7,7.5,1.9,0.095,6.0,6.3,9.1,2.8,0.98,2.4,0.15,2.0,0.074

DO
    CLS
    COLOR 14: PRINT "CAESAR CIPHER": COLOR 7
    PRINT "Plain:  ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    PRINT "Key 3:  "; Shift$("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 3)
    PRINT
    PRINT "1) Encrypt   2) Decrypt   3) Crack by brute force   Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    SELECT CASE c$
    CASE "1", "2"
        LINE INPUT "Message: "; m$
        LINE INPUT "Key (1-25): "; k$
        ' VAL turns text into a number; non-numbers give 0.
        ' MOD 26 keeps any key in range 0..25.
        k% = VAL(k$) MOD 26
        IF k% < 0 THEN k% = k% + 26
        ' Decrypting is just shifting BACKWARDS by the same key,
        ' which is the same as shifting forwards by 26 - key.
        IF c$ = "2" THEN k% = (26 - k%) MOD 26
        PRINT
        COLOR 10: PRINT "Result: "; Shift$(m$, k%): COLOR 7
    CASE "3"
        LINE INPUT "Ciphertext: "; m$
        IF m$ = "" THEN m$ = "WKH HDJOH ODQGV DW PLGQLJKW"
        CLS
        PRINT "Key Score Attempt                       Key Score Attempt"
        best! = -1: bestK% = 0
        ' Try every possible key.  For each one, undo the shift
        ' and measure how English-like the result looks.
        ' Results are shown in two columns (keys 1-13 on the left,
        ' 14-25 on the right) so all 25 fit on one screen.
        FOR k% = 1 TO 25
            tryIt$ = Shift$(m$, 26 - k%)
            s! = EnglishScore!(tryIt$)
            IF s! > best! THEN best! = s!: bestK% = k%
            IF k% <= 13 THEN LOCATE k% + 1, 1 ELSE LOCATE k% - 12, 41
            PRINT USING "### ###.# "; k%; s!;
            PRINT LEFT$(tryIt$, 28);
        NEXT k%
        LOCATE 16, 1
        COLOR 10
        PRINT "Most English-looking: key"; bestK%; "-> "; Shift$(m$, 26 - bestK%)
        COLOR 7
    CASE "Q"
        EXIT DO
    CASE ELSE
        PRINT "Please choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    PRINT "Press any key..."
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT DO
LOOP
CLS
PRINT "Ave atque vale! (Hail and farewell)"
END

' ------------------------------------------------------------
' EnglishScore: add up the frequency of every letter.  Text that
' uses lots of E, T, A, O... gets a high score; gibberish full of
' Q, X, Z, J gets a low one.  We divide by the number of letters
' so long and short messages are scored on the same scale.
' ------------------------------------------------------------
FUNCTION EnglishScore! (t$)
    total! = 0: n = 0
    FOR i = 1 TO LEN(t$)
        ch = ASC(UCASE$(MID$(t$, i, 1)))
        IF ch >= 65 AND ch <= 90 THEN
            total! = total! + freq!(ch - 65)
            n = n + 1
        END IF
    NEXT i
    IF n = 0 THEN EnglishScore! = 0 ELSE EnglishScore! = total! / n * 10
END FUNCTION

' ------------------------------------------------------------
' Shift$: move every letter k places forward, wrapping Z -> A.
'   1. ASC gives the character code: "A" = 65 ... "Z" = 90,
'      "a" = 97 ... "z" = 122.
'   2. Subtract the code of A (or a) so letters become 0..25.
'   3. Add the key and take MOD 26 so 26 wraps back to 0.
'   4. Add the base back and CHR$ turns it into a letter again.
' Upper and lower case keep their case; everything else is copied.
' ------------------------------------------------------------
FUNCTION Shift$ (t$, k%)
    r$ = ""
    FOR i = 1 TO LEN(t$)
        ch$ = MID$(t$, i, 1)
        c = ASC(ch$)
        IF c >= 65 AND c <= 90 THEN
            ch$ = CHR$((c - 65 + k%) MOD 26 + 65)
        ELSEIF c >= 97 AND c <= 122 THEN
            ch$ = CHR$((c - 97 + k%) MOD 26 + 97)
        END IF
        r$ = r$ + ch$
    NEXT i
    Shift$ = r$
END FUNCTION
