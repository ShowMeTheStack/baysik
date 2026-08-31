' ============================================================
' TITLE:    ROT13 & ROT47 Live Typewriter
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     rot13, rot47, INKEY$, self-inverse, usenet
' SUMMARY:  Type text and watch it turn into ROT13 and ROT47 letter-by-letter as you type.
' ------------------------------------------------------------
' WHAT IT DOES
'   ROT13 is a Caesar cipher with a shift of exactly 13.  Because
'   the alphabet has 26 letters, shifting by 13 twice brings every
'   letter back home:  A -> N -> A.  So the SAME operation both
'   hides and reveals a message.  That is called "self-inverse".
'
'   In the 1980s, people on Usenet (an early Internet discussion
'   system) used ROT13 to hide joke punchlines and movie spoilers.
'   It was never meant to be secret, just "don't read it by
'   accident".
'
'   ROT47 is a cousin: it rotates all 94 printable ASCII characters
'   from "!" (33) to "~" (126) by 47 places, so digits and
'   punctuation get scrambled too.  94 / 2 = 47, so it is also
'   self-inverse.
'
' HOW TO USE
'   Just type!  The top box shows your text, the next boxes show
'   ROT13 and ROT47 versions updating live.
'   Backspace deletes, Enter clears the line, Esc quits.
'   Press F1 (or TAB) to swap: your ROT13 text becomes the input,
'   proving that ROT13 of ROT13 gives back the original.
'
' CONCEPTS YOU WILL LEARN
'   * Reading single keys with INKEY$ in a loop
'   * Self-inverse functions:  f(f(x)) = x
'   * Rotating within a range:  (c - low + n) MOD size + low
'   * Updating parts of the screen with LOCATE instead of CLS
'
' THINGS TO TRY
'   * Write ROT5 for digits only (0-9 rotated by 5)
'   * Is ROT3 self-inverse?  Which shifts are?  (Hint: 2*n MOD 26 = 0)
'   * Show the character codes under each letter
' ============================================================

DECLARE FUNCTION Rot13$ (t$)
DECLARE FUNCTION Rot47$ (t$)
DECLARE SUB Box (row%, title$, txt$, clr%)

CLS
COLOR 14: PRINT "  ROT13 / ROT47 LIVE TYPEWRITER": COLOR 7
PRINT "  Type text.  Backspace = delete, Enter = clear, TAB = swap, Esc = quit"

msg$ = "Why did the chicken cross the road?"
DO
    ' ---- Redraw the three boxes -----------------------------
    Box 4, "Your text", msg$, 15
    Box 9, "ROT13 (letters only, shift 13)", Rot13$(msg$), 10
    Box 14, "ROT47 (all printable ASCII, shift 47)", Rot47$(msg$), 11
    LOCATE 19, 3: COLOR 8
    PRINT "Check: ROT13(ROT13(text)) = text ? ";
    IF Rot13$(Rot13$(msg$)) = msg$ THEN COLOR 10: PRINT "YES  " ELSE COLOR 12: PRINT "NO   "
    LOCATE 20, 3: COLOR 8
    PRINT "Check: ROT47(ROT47(text)) = text ? ";
    IF Rot47$(Rot47$(msg$)) = msg$ THEN COLOR 10: PRINT "YES  " ELSE COLOR 12: PRINT "NO   "
    COLOR 7

    ' ---- Wait for a key ---------------------------------------
    DO: k$ = INKEY$: LOOP WHILE k$ = ""

    SELECT CASE k$
    CASE CHR$(27)                       ' Esc
        EXIT DO
    CASE CHR$(8)                        ' Backspace
        IF LEN(msg$) > 0 THEN msg$ = LEFT$(msg$, LEN(msg$) - 1)
    CASE CHR$(13)                       ' Enter
        msg$ = ""
    CASE CHR$(9), CHR$(0) + CHR$(59)    ' TAB or F1 (extended key)
        msg$ = Rot13$(msg$)
    CASE ELSE
        ' Only accept ordinary printable characters, and keep the
        ' line short enough to fit inside the box.
        IF LEN(k$) = 1 AND ASC(k$) >= 32 AND LEN(msg$) < 70 THEN msg$ = msg$ + k$
    END SELECT
LOOP
CLS
PRINT Rot13$("Tbbqolr!")
END

' ------------------------------------------------------------
' Box: draws a titled frame using box-drawing characters and
' prints txt$ inside it.  Padding with SPACE$ erases old text.
' ------------------------------------------------------------
SUB Box (row%, title$, txt$, clr%)
    COLOR 7
    LOCATE row%, 2: PRINT CHR$(218); STRING$(74, 196); CHR$(191)
    LOCATE row% + 1, 2: PRINT CHR$(179); SPACE$(74); CHR$(179)
    LOCATE row% + 2, 2: PRINT CHR$(179); SPACE$(74); CHR$(179)
    LOCATE row% + 3, 2: PRINT CHR$(192); STRING$(74, 196); CHR$(217)
    LOCATE row%, 4: COLOR 14: PRINT " "; title$; " "
    LOCATE row% + 2, 4: COLOR clr%: PRINT txt$;
    COLOR 7
END SUB

' ------------------------------------------------------------
' Rot13$: shift letters by 13 inside their own case.
' "A".."Z" are codes 65..90 and "a".."z" are 97..122.
' ------------------------------------------------------------
FUNCTION Rot13$ (t$)
    r$ = t$                          ' copy, then change in place
    FOR i = 1 TO LEN(r$)
        c = ASC(MID$(r$, i, 1))
        IF c >= 65 AND c <= 90 THEN MID$(r$, i, 1) = CHR$((c - 65 + 13) MOD 26 + 65)
        IF c >= 97 AND c <= 122 THEN MID$(r$, i, 1) = CHR$((c - 97 + 13) MOD 26 + 97)
    NEXT i
    Rot13$ = r$
END FUNCTION

' ------------------------------------------------------------
' Rot47$: the printable range is 33 ("!") .. 126 ("~"), which is
' 94 characters.  Same formula as ROT13, different range:
'     new = (c - 33 + 47) MOD 94 + 33
' Spaces (32) are left alone so words stay separate.
' ------------------------------------------------------------
FUNCTION Rot47$ (t$)
    r$ = t$
    FOR i = 1 TO LEN(r$)
        c = ASC(MID$(r$, i, 1))
        IF c >= 33 AND c <= 126 THEN MID$(r$, i, 1) = CHR$((c - 33 + 47) MOD 94 + 33)
    NEXT i
    Rot47$ = r$
END FUNCTION
