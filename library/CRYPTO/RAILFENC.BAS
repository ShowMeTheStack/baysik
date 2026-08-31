' ============================================================
' TITLE:    Rail Fence Cipher - Zigzag Writer
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     rail fence, transposition, zigzag, arrays, animation
' SUMMARY:  Writes your message in a zigzag across 2-8 rails, animates it, then reads the rails off to scramble it.
' ------------------------------------------------------------
' WHAT IT DOES
'   All the ciphers so far REPLACE letters.  A TRANSPOSITION cipher
'   keeps the letters but MIXES UP THEIR ORDER.  The rail fence (or
'   zigzag) cipher was used in the American Civil War.
'
'   Write the message going down and up across N "rails":
'
'        W . . . E . . . C . . . R . . . L . . . T . . . E
'        . E . R . D . S . O . E . E . F . E . A . O . C .
'        . . A . . . I . . . V . . . D . . . E . . . N . .
'
'   then read each rail from left to right:
'        WECRLTE  ERDSOEEFEAOC  AIVDEN
'
'   The KEY is just the number of rails, so it is weak - but it is a
'   lovely way to see that order matters as much as letters do.
'
'   DECRYPTING is a neat puzzle: we first work out which rail every
'   position belongs to, count how many letters each rail gets,
'   cut the ciphertext into those pieces, then follow the zigzag
'   again taking the next letter from the right rail.
'
' HOW TO USE
'   Choose E (encrypt), D (decrypt) or Q (quit), type a message
'   and the number of rails (2-8).  Encryption is animated: watch
'   the letters bounce down and up the rails.
'
' CONCEPTS YOU WILL LEARN
'   * A "bouncing" counter: rail goes 0,1,2,1,0,1,2... using a
'     direction variable that flips at the top and bottom
'   * Two-pass decoding: first measure, then fill
'   * The period of the zigzag: 2 * (rails - 1)
'
' THINGS TO TRY
'   * Encrypt with 2 rails - it just splits odd and even letters!
'   * What happens if rails >= message length?
'   * Brute-force decrypt: try every rail count from 2 to 10
' ============================================================

DECLARE FUNCTION RailOf% (i%, rails%)
DECLARE FUNCTION Encrypt$ (m$, rails%, animate%)
DECLARE FUNCTION Decrypt$ (c$, rails%)

DO
    CLS
    COLOR 14: PRINT "RAIL FENCE CIPHER": COLOR 7
    PRINT
    LINE INPUT "E)ncrypt, D)ecrypt or Q)uit: "; ch$
    ch$ = UCASE$(LEFT$(ch$, 1))
    IF ch$ = "Q" OR ch$ = CHR$(27) THEN EXIT DO
    IF ch$ = "E" OR ch$ = "D" THEN
        LINE INPUT "Message: "; m$
        ' Remove spaces - real rail fence messages were sent as one
        ' continuous block so word lengths gave no clues.
        t$ = ""
        FOR i = 1 TO LEN(m$)
            IF MID$(m$, i, 1) <> " " THEN t$ = t$ + UCASE$(MID$(m$, i, 1))
        NEXT i
        IF t$ = "" THEN t$ = "WEAREDISCOVEREDFLEEATONCE"
        IF LEN(t$) > 75 THEN t$ = LEFT$(t$, 75): PRINT "(cut to 75 letters to fit the screen)"
        LINE INPUT "Rails (2-8): "; r$
        rails% = VAL(r$)
        IF rails% < 2 THEN rails% = 2
        IF rails% > 8 THEN rails% = 8
        IF ch$ = "E" THEN
            res$ = Encrypt$(t$, rails%, 1)
            COLOR 10: PRINT : PRINT "Ciphertext: "; res$: COLOR 7
            PRINT "Check by decrypting: "; Decrypt$(res$, rails%)
        ELSE
            res$ = Decrypt$(t$, rails%)
            COLOR 10: PRINT : PRINT "Plaintext: "; res$: COLOR 7
            ' Show the zigzag of the recovered message for clarity.
            dummy$ = Encrypt$(res$, rails%, 0)
        END IF
    END IF
    PRINT
    PRINT "Press any key...";
    a$ = INPUT$(1)
LOOP
CLS
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' Decrypt$: undo the zigzag.
'  Pass 1 - count how many positions land on each rail.
'  Pass 2 - cut the ciphertext into rail pieces of those lengths.
'  Pass 3 - walk the zigzag again, taking the next unused letter
'           from whichever rail we are on.
' ------------------------------------------------------------
FUNCTION Decrypt$ (c$, rails%)
    n% = LEN(c$)
    DIM cnt(7), startAt(7), used(7)
    FOR i% = 1 TO n%
        r = RailOf%(i%, rails%)
        cnt(r) = cnt(r) + 1
    NEXT i%
    ' Rail 0 begins at character 1; each next rail begins where the
    ' previous one ended.
    startAt(0) = 1
    FOR r = 1 TO rails% - 1: startAt(r) = startAt(r - 1) + cnt(r - 1): NEXT r
    p$ = ""
    FOR i% = 1 TO n%
        r = RailOf%(i%, rails%)
        p$ = p$ + MID$(c$, startAt(r) + used(r), 1)
        used(r) = used(r) + 1
    NEXT i%
    Decrypt$ = p$
END FUNCTION

' ------------------------------------------------------------
' Encrypt$: place each letter on its rail, optionally animated on
' screen (rows 10.. with one row per rail), then read the rails.
' ------------------------------------------------------------
FUNCTION Encrypt$ (m$, rails%, animate%)
    DIM railText$(7)
    top = 9
    ' Dotted background so the empty spots of the fence show.
    FOR r = 0 TO rails% - 1
        LOCATE top + r, 3: COLOR 8: PRINT STRING$(LEN(m$), 250);
    NEXT r
    FOR i% = 1 TO LEN(m$)
        r = RailOf%(i%, rails%)
        railText$(r) = railText$(r) + MID$(m$, i%, 1)
        LOCATE top + r, 2 + i%: COLOR 9 + r: PRINT MID$(m$, i%, 1);
        IF animate% THEN
            ' Short delay so the zigzag "draws" itself.
            t! = TIMER: DO WHILE TIMER - t! < .05 AND TIMER >= t!: LOOP
        END IF
    NEXT i%
    LOCATE top + rails% + 1, 1
    res$ = ""
    FOR r = 0 TO rails% - 1
        COLOR 9 + r: PRINT "  Rail"; r + 1; ": "; railText$(r)
        res$ = res$ + railText$(r)
    NEXT r
    COLOR 7
    Encrypt$ = res$
END FUNCTION

' ------------------------------------------------------------
' RailOf%: which rail does character number i% (1-based) sit on?
'   The pattern repeats every  cycle = 2 * (rails - 1)  letters.
'   Inside a cycle, position p goes DOWN for the first rails-1
'   steps (rail = p) and back UP after that (rail = cycle - p).
'   Example, 3 rails: cycle 4, positions 0 1 2 3 -> rails 0 1 2 1.
' ------------------------------------------------------------
FUNCTION RailOf% (i%, rails%)
    cycle = 2 * (rails% - 1)
    p = (i% - 1) MOD cycle
    IF p < rails% THEN RailOf% = p ELSE RailOf% = cycle - p
END FUNCTION
