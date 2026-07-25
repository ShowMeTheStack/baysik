' ============================================================
' TITLE:    Reverse & Rotate Lab
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     strings, reverse, rotate, LEFT$, RIGHT$, MID$
' SUMMARY:  Reverses strings and words and rotates text left or right, showing how each trick works.
' ------------------------------------------------------------
' WHAT IT DOES
'   Takes a line of text and shows several transformations:
'     * the whole string reversed      ("HELLO" -> "OLLEH")
'     * each word reversed in place    ("HI THERE" -> "IH EREHT")
'     * the order of words reversed    ("HI THERE" -> "THERE HI")
'     * rotated left / right by N      ("HELLO" left 2 -> "LLOHE")
'   Finally it plays a "marquee" animation: rotating the text one
'   step at a time makes it scroll like a shop sign.
'
' HOW TO USE
'   Type some text and a rotation amount.  Watch the marquee, then
'   press any key to stop it.  Press Enter on an empty line to quit.
'
' CONCEPTS YOU WILL LEARN
'   * LEFT$, RIGHT$ and MID$ to cut strings into pieces
'   * Building a new string backwards in a FOR ... STEP -1 loop
'   * MOD to wrap a rotation amount ("rotate 7" of a 5-letter word = 2)
'   * A simple text animation with LOCATE and a timing loop
'
' THINGS TO TRY
'   * Make the marquee scroll the other way
'   * Check whether one string is a rotation of another
'     (hint: B is a rotation of A if B is inside A + A)
' ============================================================

DECLARE FUNCTION Reverse$ (s$)
DECLARE FUNCTION RotLeft$ (s$, n)
DECLARE FUNCTION RevEachWord$ (s$)
DECLARE FUNCTION RevWordOrder$ (s$)

CLS
COLOR 14: PRINT "REVERSE & ROTATE LAB": COLOR 7
PRINT
DO
    LINE INPUT "Text (Enter = quit): "; t$
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO
    INPUT "Rotate by how many places"; r
    r = INT(r)
    PRINT
    PRINT "Original          : ["; t$; "]"
    PRINT "Reversed          : ["; Reverse$(t$); "]"
    PRINT "Each word reversed: ["; RevEachWord$(t$); "]"
    PRINT "Word order reversed:["; RevWordOrder$(t$); "]"
    PRINT "Rotated left"; r; ": ["; RotLeft$(t$, r); "]"
    ' rotating right by r is the same as rotating left by -r
    PRINT "Rotated right"; r; ": ["; RotLeft$(t$, -r); "]"
    PRINT
    ' ---- marquee ----
    PRINT "Marquee (press a key to stop):"
    row = CSRLIN
    m$ = t$ + "   *   "             ' gap so the end is visible
    k = 0
    DO
        LOCATE row, 1
        COLOR 10: PRINT LEFT$(RotLeft$(m$, k) + m$ + m$, 40): COLOR 7
        k = k + 1
        t0 = TIMER
        DO: LOOP WHILE TIMER - t0 < .12 AND TIMER >= t0
    LOOP WHILE INKEY$ = "" AND k < 200
    PRINT
LOOP
PRINT "Goodbye!"
END

' Reverse$: read the string from its last character to its first.
FUNCTION Reverse$ (s$)
    r$ = ""
    FOR i = LEN(s$) TO 1 STEP -1
        r$ = r$ + MID$(s$, i, 1)
    NEXT i
    Reverse$ = r$
END FUNCTION

' ------------------------------------------------------------
' RotLeft$: move the first n characters to the end.
' n MOD length keeps n in range; a negative n is turned into the
' equivalent positive rotation, e.g. -1 on length 5 becomes 4.
' ------------------------------------------------------------
FUNCTION RotLeft$ (s$, n)
    L = LEN(s$)
    IF L = 0 THEN RotLeft$ = "": EXIT FUNCTION
    k = n MOD L
    IF k < 0 THEN k = k + L
    RotLeft$ = MID$(s$, k + 1) + LEFT$(s$, k)
END FUNCTION

' RevEachWord$: reverse every run of non-space characters,
' leaving the spaces where they were.
FUNCTION RevEachWord$ (s$)
    out$ = "": w$ = ""
    FOR i = 1 TO LEN(s$)
        ch$ = MID$(s$, i, 1)
        IF ch$ = " " THEN
            out$ = out$ + Reverse$(w$) + " ": w$ = ""
        ELSE
            w$ = w$ + ch$
        END IF
    NEXT i
    RevEachWord$ = out$ + Reverse$(w$)
END FUNCTION

' RevWordOrder$: each word found is put IN FRONT of the result,
' so the last word ends up first.
FUNCTION RevWordOrder$ (s$)
    out$ = "": w$ = ""
    FOR i = 1 TO LEN(s$) + 1
        IF i <= LEN(s$) THEN ch$ = MID$(s$, i, 1) ELSE ch$ = " "
        IF ch$ = " " THEN
            IF w$ <> "" THEN
                IF out$ = "" THEN out$ = w$ ELSE out$ = w$ + " " + out$
                w$ = ""
            END IF
        ELSE
            w$ = w$ + ch$
        END IF
    NEXT i
    RevWordOrder$ = out$
END FUNCTION
