' ============================================================
' TITLE:    Atbash - The Mirror Alphabet
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     atbash, hebrew, mirror, substitution, strings
' SUMMARY:  The ancient Hebrew cipher that flips the alphabet backwards, A<->Z, B<->Y, shown with a mirror diagram.
' ------------------------------------------------------------
' WHAT IT DOES
'   Atbash is one of the oldest known ciphers (around 500 BC).  It
'   appears in the Hebrew Bible: the word "Sheshach" in the book of
'   Jeremiah is Atbash for "Babel".  The name comes from the Hebrew
'   letters Aleph-Tav-Beth-Shin: first<->last, second<->second-last.
'
'   In English: A<->Z, B<->Y, C<->X ... M<->N.  The math is simple:
'   if a letter is number p (A=0 ... Z=25), its partner is 25 - p.
'   Just like ROT13, doing it twice gives back the original
'   because 25 - (25 - p) = p.
'
'   The program draws the alphabet folded in half like a mirror,
'   then encodes your messages and highlights every swap.
'
' HOW TO USE
'   Type a message and press Enter to see its Atbash version.
'   An empty line (or Q) quits.
'
' CONCEPTS YOU WILL LEARN
'   * A fixed substitution rule: c -> 25 - c
'   * Self-inverse ciphers
'   * Simplifying a formula: 65 + (25 - (c - 65)) = 155 - c
'
' THINGS TO TRY
'   * Find English words whose Atbash is also a word: try "HOLD" and
'     "GLOW".  And WIZARD -> DRAZIW is WIZARD spelled backwards!
'   * Combine Atbash with a Caesar shift (the "Affine" cipher does this)
' ============================================================

DECLARE FUNCTION Atbash$ (t$)

CLS
COLOR 14: PRINT "ATBASH - THE MIRROR ALPHABET": COLOR 7
PRINT
' ---- Draw the fold ------------------------------------------
' The top row is A..M, the bottom row is Z..N.  Every letter sits
' directly above its partner, like a reflection in a mirror.
PRINT "  Fold the alphabet in half and each letter meets its partner:"
PRINT
PRINT "     ";
FOR i = 0 TO 12: COLOR 11: PRINT CHR$(65 + i); "  "; : NEXT i
PRINT
PRINT "     ";
FOR i = 0 TO 12: COLOR 8: PRINT CHR$(179); "  "; : NEXT i
PRINT
PRINT "     ";
FOR i = 0 TO 12: COLOR 13: PRINT CHR$(90 - i); "  "; : NEXT i
PRINT
COLOR 7
PRINT
PRINT "  Math: letter number p (A=0..Z=25) becomes 25 - p."
PRINT "  Example:  C = 2  ->  25 - 2 = 23 = X"
PRINT

DO
    LINE INPUT "Message (Enter to quit): "; m$
    IF m$ = "" OR UCASE$(m$) = "Q" THEN EXIT DO
    e$ = Atbash$(m$)
    PRINT "  Atbash: ";
    ' Print letter by letter, coloring changed characters so you
    ' can see which ones were swapped and which were copied.
    FOR i = 1 TO LEN(e$)
        IF MID$(e$, i, 1) <> MID$(m$, i, 1) THEN COLOR 10 ELSE COLOR 8
        PRINT MID$(e$, i, 1);
    NEXT i
    COLOR 7: PRINT
    PRINT "  Twice:  "; Atbash$(e$); "   (back to the start!)"
    PRINT
LOOP
PRINT "SVOOL / HELLO - goodbye!"
END

' ------------------------------------------------------------
' Atbash$: for each letter compute its alphabet position p and
' replace it with letter 25 - p, keeping upper/lower case.
' For capitals: 65 + (25 - (c - 65)) simplifies to 155 - c.
' For small letters: 97 + (25 - (c - 97)) = 219 - c.
' ------------------------------------------------------------
FUNCTION Atbash$ (t$)
    r$ = t$
    FOR i = 1 TO LEN(r$)
        c = ASC(MID$(r$, i, 1))
        IF c >= 65 AND c <= 90 THEN MID$(r$, i, 1) = CHR$(155 - c)
        IF c >= 97 AND c <= 122 THEN MID$(r$, i, 1) = CHR$(219 - c)
    NEXT i
    Atbash$ = r$
END FUNCTION
