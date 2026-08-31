' ============================================================
' TITLE:    Vigenere Cipher with Tabula Recta
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     vigenere, polyalphabetic, keyword, tabula recta, MOD
' SUMMARY:  Encrypt and decrypt with "le chiffre indechiffrable", stepping through the key one letter at a time.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Caesar cipher uses ONE shift for the whole message.  The
'   Vigenere cipher (described by Giovan Battista Bellaso in 1553,
'   later credited to Blaise de Vigenere) uses a KEYWORD, and each
'   letter of the keyword gives a different shift:
'
'        plaintext:  A T T A C K A T D A W N
'        key:        L E M O N L E M O N L E    (repeated)
'        shift:     11 4 12 14 13 ...           (A=0, B=1, ...)
'        cipher:     L X F O P V E F R N H R
'
'   Because the same plaintext letter can turn into many different
'   cipher letters, simple frequency counting no longer works.  For
'   300 years people called it "the indecipherable cipher" - until
'   Charles Babbage and Friedrich Kasiski broke it in the 1800s
'   (see KASISKI.BAS).
'
'   Math:   encrypt  C = (P + K) MOD 26
'           decrypt  P = (C - K + 26) MOD 26
'
'   The program also shows a step-by-step table of the first
'   letters so you can follow the arithmetic by hand, plus a small
'   part of the "tabula recta" - the 26x26 square of shifted
'   alphabets that people used before computers.
'
' HOW TO USE
'   Menu: 1 = encrypt, 2 = decrypt, 3 = show tabula recta, Q = quit.
'   Enter a message and a keyword made of letters.
'
' CONCEPTS YOU WILL LEARN
'   * Polyalphabetic substitution: the shift changes every letter
'   * Cycling through a key with a counter and MOD LEN(key$)
'   * Skipping non-letters without advancing the key
'   * Printing a neat step table with PRINT USING-style columns
'
' THINGS TO TRY
'   * Encrypt "AAAAAAAAAA" - what do you see?  Why is that bad?
'   * Use a key as long as the message (that's the one-time pad idea)
'   * Make an "autokey" variant where the message extends the key
' ============================================================

DECLARE FUNCTION Vig$ (t$, key$, direction%)
DECLARE FUNCTION CleanKey$ (k$)

DO
    CLS
    COLOR 14: PRINT "VIGENERE CIPHER": COLOR 7
    PRINT "1) Encrypt   2) Decrypt   3) Tabula recta   Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO

    SELECT CASE c$
    CASE "1", "2"
        LINE INPUT "Message: "; m$
        IF m$ = "" THEN m$ = "Attack at dawn"
        LINE INPUT "Keyword: "; k$
        k$ = CleanKey$(k$)
        IF k$ = "" THEN k$ = "LEMON": PRINT "(no letters in key - using LEMON)"
        IF c$ = "1" THEN dirn% = 1 ELSE dirn% = -1
        res$ = Vig$(m$, k$, dirn%)

        ' ---- Step table for the first few letters -------------
        ' Shows exactly how each letter was computed.
        PRINT
        PRINT " In  Key  Shift   Calculation          Out"
        PRINT " --  ---  -----   -------------------  ---"
        shown = 0: j = 0
        FOR i = 1 TO LEN(m$)
            ch = ASC(UCASE$(MID$(m$, i, 1)))
            IF ch >= 65 AND ch <= 90 AND shown < 8 THEN
                kc = ASC(MID$(k$, (j MOD LEN(k$)) + 1, 1)) - 65
                p = ch - 65
                PRINT "  "; CHR$(ch); "   "; CHR$(kc + 65); "   ";
                PRINT USING "##"; kc;
                IF dirn% = 1 THEN
                    PRINT USING "     (## + ##) MOD 26 = ##"; p; kc; (p + kc) MOD 26;
                ELSE
                    PRINT USING "     (## - ##) MOD 26 = ##"; p; kc; (p - kc + 26) MOD 26;
                END IF
                PRINT "    "; UCASE$(MID$(res$, i, 1))
                shown = shown + 1
            END IF
            IF ch >= 65 AND ch <= 90 THEN j = j + 1
        NEXT i
        PRINT
        PRINT "Key used: "; k$
        COLOR 10: PRINT "Result:   "; res$: COLOR 7
        ' Prove it works by reversing the operation.
        PRINT "Reversed: "; Vig$(res$, k$, -dirn%)

    CASE "3"
        ' ---- Tabula recta ---------------------------------------
        ' Row = key letter, column = plaintext letter.  The cell
        ' where they cross is the ciphertext letter.  We show 16
        ' rows to fit the screen.
        PRINT
        PRINT "     "; : COLOR 11
        FOR col = 0 TO 25: PRINT CHR$(65 + col); " "; : NEXT col
        PRINT : COLOR 7
        FOR row = 0 TO 15
            COLOR 13: PRINT "  "; CHR$(65 + row); "  "; : COLOR 7
            FOR col = 0 TO 25
                PRINT CHR$((row + col) MOD 26 + 65); " ";
            NEXT col
            PRINT
        NEXT row
        PRINT "  (row = key letter, column = message letter)"
    CASE ELSE
        PRINT "Please choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    PRINT "Press any key (Esc quits)...";
    a$ = INPUT$(1)
    IF a$ = CHR$(27) THEN EXIT DO
LOOP
CLS
PRINT "Au revoir!"
END

' ------------------------------------------------------------
' CleanKey$: keep only letters from the key, in upper case.
' ------------------------------------------------------------
FUNCTION CleanKey$ (k$)
    r$ = ""
    FOR i = 1 TO LEN(k$)
        ch$ = UCASE$(MID$(k$, i, 1))
        IF ch$ >= "A" AND ch$ <= "Z" THEN r$ = r$ + ch$
    NEXT i
    CleanKey$ = r$
END FUNCTION

' ------------------------------------------------------------
' Vig$: the heart of the cipher.
'   j counts letters processed so far; the key letter to use is
'   number (j MOD keyLength) + 1, so the key repeats forever.
'   direction% = +1 adds the shift (encrypt), -1 subtracts it.
'   Adding 26 before MOD keeps the result from going negative.
' ------------------------------------------------------------
FUNCTION Vig$ (t$, key$, direction%)
    r$ = t$
    j = 0
    FOR i = 1 TO LEN(r$)
        c = ASC(MID$(r$, i, 1))
        IF c >= 65 AND c <= 90 THEN b0 = 65 ELSE IF c >= 97 AND c <= 122 THEN b0 = 97 ELSE b0 = 0
        IF b0 > 0 THEN
            k = ASC(MID$(key$, (j MOD LEN(key$)) + 1, 1)) - 65
            MID$(r$, i, 1) = CHR$((c - b0 + direction% * k + 26) MOD 26 + b0)
            j = j + 1
        END IF
    NEXT i
    Vig$ = r$
END FUNCTION
