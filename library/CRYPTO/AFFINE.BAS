' ============================================================
' TITLE:    Affine Cipher & Modular Inverses
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     affine, modular inverse, extended euclid, GCD, number theory
' SUMMARY:  Encrypts with E(x) = (a*x + b) MOD 26 and shows the Extended Euclidean Algorithm finding the inverse to decrypt.
' ------------------------------------------------------------
' WHAT IT DOES
'   The affine cipher combines MULTIPLYING and ADDING:
'
'        encrypt:   E(x) = (a * x + b) MOD 26
'        decrypt:   D(y) = a' * (y - b) MOD 26
'
'   where x is the letter number (A=0 ... Z=25) and a' is the
'   MODULAR INVERSE of a: the number with  a * a' MOD 26 = 1.
'   (Caesar is the special case a = 1; Atbash is a = 25, b = 25.)
'
'   Not every a works!  If a shares a factor with 26 (like 2 or 13),
'   two letters land on the same cipher letter and the message can't
'   be decoded.  a must be "coprime" with 26: GCD(a, 26) = 1.  That
'   leaves 12 choices: 1 3 5 7 9 11 15 17 19 21 23 25.
'
'   To find a' we use the EXTENDED EUCLIDEAN ALGORITHM (Euclid wrote
'   about GCDs around 300 BC).  It finds whole numbers s and t with
'        a*s + 26*t = GCD(a, 26) = 1
'   Take MOD 26 of both sides:  a*s MOD 26 = 1, so s is the inverse!
'   The same algorithm is the key step in RSA (see RSATOY.BAS).
'
' HOW TO USE
'   Enter a (must be coprime with 26), b (0-25) and a message.
'   The program prints the Euclid table, the inverse, the cipher
'   alphabet, the ciphertext and the decryption.  Enter on the
'   "a" prompt quits.
'
' CONCEPTS YOU WILL LEARN
'   * GCD and coprime numbers
'   * The Extended Euclidean Algorithm, row by row
'   * Making MOD always positive: ((x MOD m) + m) MOD m
'   * Why some keys are "illegal"
'
' THINGS TO TRY
'   * Try a = 13: see the collisions in the cipher alphabet
'   * There are 12 * 26 = 312 keys.  Write a brute-force cracker!
'   * Change the alphabet size to 29 (a prime) - which a work now?
' ============================================================

DECLARE FUNCTION InverseMod% (a%, m%, showWork%)
DECLARE FUNCTION Gcd% (a%, b%)
DECLARE FUNCTION Affine$ (t$, a%, b%)

DO
    CLS
    COLOR 14: PRINT "AFFINE CIPHER   E(x) = (a*x + b) MOD 26": COLOR 7
    PRINT "Valid a values: 1 3 5 7 9 11 15 17 19 21 23 25"
    PRINT
    LINE INPUT "a (Enter to quit): "; aIn$
    IF aIn$ = "" OR UCASE$(aIn$) = "Q" THEN EXIT DO
    a% = ((VAL(aIn$) MOD 26) + 26) MOD 26
    LINE INPUT "b (0-25): "; bIn$
    b% = ((VAL(bIn$) MOD 26) + 26) MOD 26

    ' ---- Is a usable? ----------------------------------------
    IF Gcd%(a%, 26) <> 1 THEN
        COLOR 12
        PRINT "GCD("; LTRIM$(STR$(a%)); ", 26) ="; Gcd%(a%, 26); "- not coprime, so letters collide:"
        COLOR 7
        PRINT "Plain:  ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        PRINT "Cipher: "; Affine$("ABCDEFGHIJKLMNOPQRSTUVWXYZ", a%, b%)
        PRINT "Several plain letters share a cipher letter - no way back!"
    ELSE
        LINE INPUT "Message: "; m$
        IF m$ = "" THEN m$ = "Affine ciphers are fine"
        PRINT
        PRINT "Extended Euclid for"; a%; "and 26:"
        inv% = InverseMod%(a%, 26, 1)
        PRINT "Inverse a' ="; inv%; "  check:"; a%; "*"; inv%; "="; a% * inv%;
        PRINT "and"; a% * inv%; "MOD 26 ="; (a% * inv%) MOD 26
        PRINT
        PRINT "Plain:  ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        PRINT "Cipher: "; Affine$("ABCDEFGHIJKLMNOPQRSTUVWXYZ", a%, b%)
        c$ = Affine$(m$, a%, b%)
        COLOR 10: PRINT "Encrypted: "; c$: COLOR 7
        ' Decrypting is itself an affine map:
        '   x = a' * (y - b) = a'*y - a'*b   so  a2 = a', b2 = -a'*b
        a2% = inv%
        b2% = ((-inv% * b%) MOD 26 + 26) MOD 26
        PRINT "Decrypt key: a' ="; a2%; " b' ="; b2%
        PRINT "Decrypted: "; Affine$(c$, a2%, b2%)
    END IF
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' Affine$: apply (a*x + b) MOD 26 to letters, keep case.
' ------------------------------------------------------------
FUNCTION Affine$ (t$, a%, b%)
    r$ = t$
    FOR i = 1 TO LEN(r$)
        c = ASC(MID$(r$, i, 1))
        IF c >= 65 AND c <= 90 THEN MID$(r$, i, 1) = CHR$((a% * (c - 65) + b%) MOD 26 + 65)
        IF c >= 97 AND c <= 122 THEN MID$(r$, i, 1) = CHR$((a% * (c - 97) + b%) MOD 26 + 97)
    NEXT i
    Affine$ = r$
END FUNCTION

' ------------------------------------------------------------
' Gcd%: Euclid's algorithm.  Replace (a, b) by (b, a MOD b) until
' b is 0; then a is the greatest common divisor.
' ------------------------------------------------------------
FUNCTION Gcd% (a%, b%)
    x = a%: y = b%
    DO WHILE y <> 0
        t = x MOD y: x = y: y = t
    LOOP
    Gcd% = x
END FUNCTION

' ------------------------------------------------------------
' InverseMod%: Extended Euclidean Algorithm.
' We keep two rows of numbers (r, s).  At every step:
'     q      = rOld \ r                (whole-number quotient)
'     rNew   = rOld - q * r            (the remainder, like Euclid)
'     sNew   = sOld - q * s            (tracks how many a's we used)
' Invariant: every r equals  a*s + m*(something), so when r reaches
' 1, the matching s is the inverse of a (mod m).
' ------------------------------------------------------------
FUNCTION InverseMod% (a%, m%, showWork%)
    rOld = m%: r = a%
    sOld = 0: s = 1
    IF showWork% THEN PRINT "     q    remainder    s"
    IF showWork% THEN PRINT USING "     -     ####     ####"; rOld; sOld
    IF showWork% THEN PRINT USING "     -     ####     ####"; r; s
    DO WHILE r <> 0
        q = rOld \ r
        rNew = rOld - q * r: rOld = r: r = rNew
        sNew = sOld - q * s: sOld = s: s = sNew
        IF showWork% THEN PRINT USING "  ####     ####     ####"; q; r; s
    LOOP
    ' Now rOld = GCD (1) and sOld is the inverse, maybe negative.
    InverseMod% = ((sOld MOD m%) + m%) MOD m%
END FUNCTION
