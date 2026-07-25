' ============================================================
' TITLE:    Find & Replace Utility
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     INSTR, search, replace, case-insensitive, whole words
' SUMMARY:  A mini editor command: find all matches in a document and replace them, with options.
' ------------------------------------------------------------
' WHAT IT DOES
'   Holds a short document (a few lines loaded from DATA) and lets
'   you search it like a text editor does:
'     F - find: highlights every match and reports line / column
'     R - replace: replaces every match and reports how many
'   Two options can be toggled:
'     C - match case on/off   ("cat" vs "Cat")
'     W - whole words only    ("cat" should not match "concatenate")
'
' HOW TO USE
'   Press F, R, C, W, U (undo all = reload), or Q to quit.
'   Follow the prompts for the text to find and replace.
'
' CONCEPTS YOU WILL LEARN
'   * INSTR(start, text$, find$) to find EVERY occurrence, not just one
'   * Why a replace loop must continue AFTER the inserted text
'     (otherwise replacing "a" with "aa" would loop forever!)
'   * Case-insensitive search by comparing UCASE$ copies
'   * Checking word boundaries with the characters on each side
'
' THINGS TO TRY
'   * Add a "replace only the first N" option
'   * Support a wildcard: "?" matches any one character
'   * Load the document from a file with LINE INPUT #
' ============================================================

DECLARE FUNCTION FindNext% (s$, f$, start)
DECLARE FUNCTION IsWordChar% (c$)

CONST NLINES = 6
DIM SHARED doc$(NLINES), matchCase%, wholeWord%

GOSUB LoadDoc
matchCase% = 0: wholeWord% = 0

DO
    CLS
    COLOR 14: PRINT "FIND & REPLACE": COLOR 7
    PRINT STRING$(60, 196)
    FOR i = 1 TO NLINES
        PRINT USING "##: "; i; : PRINT doc$(i)
    NEXT i
    PRINT STRING$(60, 196)
    PRINT "Options:  match case = ";
    IF matchCase% THEN PRINT "ON "; ELSE PRINT "off";
    PRINT "   whole words = ";
    IF wholeWord% THEN PRINT "ON" ELSE PRINT "off"
    PRINT
    PRINT "[F]ind  [R]eplace  [C]ase  [W]hole  [U]ndo all  [Q]uit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "F": GOSUB DoFind
        CASE "R": GOSUB DoReplace
        CASE "C": matchCase% = NOT matchCase%
        CASE "W": wholeWord% = NOT wholeWord%
        CASE "U": GOSUB LoadDoc
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
PRINT "Goodbye!"
END

LoadDoc:
    RESTORE DocText
    FOR i = 1 TO NLINES: READ doc$(i): NEXT i
RETURN

DocText:
DATA "The cat sat on the mat. The CAT was fat."
DATA "A concatenated catalogue of cats is not a cat."
DATA "Category: animals. Cat food is in the cupboard."
DATA "the end of the story is near, then the cat sleeps."
DATA "There is a theme in the theatre: the cat!"
DATA "Scatter the seeds, said the cat."

' ---- F: show every match, highlighting it in yellow ----------
DoFind:
    PRINT
    LINE INPUT "Find what: "; f$
    IF f$ = "" THEN RETURN
    total = 0
    PRINT
    FOR i = 1 TO NLINES
        p = FindNext%(doc$(i), f$, 1)
        IF p > 0 THEN
            ' print the line in pieces: normal text, highlighted match ...
            PRINT USING "##: "; i; : last = 1
            DO WHILE p > 0
                PRINT MID$(doc$(i), last, p - last);
                COLOR 0, 14: PRINT MID$(doc$(i), p, LEN(f$)); : COLOR 7, 0
                total = total + 1
                last = p + LEN(f$)
                p = FindNext%(doc$(i), f$, last)
            LOOP
            PRINT MID$(doc$(i), last)
        END IF
    NEXT i
    PRINT
    PRINT total; "match(es) found.  Press a key...";
    DO: LOOP WHILE INKEY$ = ""
RETURN

' ---- R: replace every match ---------------------------------
DoReplace:
    PRINT
    LINE INPUT "Find what   : "; f$
    IF f$ = "" THEN RETURN
    LINE INPUT "Replace with: "; r$
    total = 0
    FOR i = 1 TO NLINES
        p = FindNext%(doc$(i), f$, 1)
        DO WHILE p > 0
            ' glue: text before + replacement + text after
            doc$(i) = LEFT$(doc$(i), p - 1) + r$ + MID$(doc$(i), p + LEN(f$))
            total = total + 1
            ' IMPORTANT: continue searching AFTER the new text,
            ' never inside it, or "cat" -> "cats" would never end.
            p = FindNext%(doc$(i), f$, p + LEN(r$))
        LOOP
    NEXT i
    PRINT total; "replacement(s) made.  Press a key...";
    DO: LOOP WHILE INKEY$ = ""
RETURN

' ------------------------------------------------------------
' FindNext%: position of the next match of f$ in s$ at or after
' "start", obeying the matchCase and wholeWord options.
' Returns 0 when there are no more matches.
' ------------------------------------------------------------
FUNCTION FindNext% (s$, f$, start)
    IF matchCase% THEN
        a$ = s$: b$ = f$
    ELSE
        a$ = UCASE$(s$): b$ = UCASE$(f$)   ' compare upper-case copies
    END IF
    p = start
    DO
        IF p > LEN(a$) THEN FindNext% = 0: EXIT FUNCTION
        p = INSTR(p, a$, b$)
        IF p = 0 THEN FindNext% = 0: EXIT FUNCTION
        IF wholeWord% = 0 THEN FindNext% = p: EXIT FUNCTION
        ' whole word: the characters just before and just after the
        ' match must NOT be letters or digits
        okL = -1: okR = -1
        IF p > 1 THEN IF IsWordChar%(MID$(a$, p - 1, 1)) THEN okL = 0
        q = p + LEN(b$)
        IF q <= LEN(a$) THEN IF IsWordChar%(MID$(a$, q, 1)) THEN okR = 0
        IF okL AND okR THEN FindNext% = p: EXIT FUNCTION
        p = p + 1                          ' not a whole word; keep looking
    LOOP
END FUNCTION

' IsWordChar%: TRUE for letters and digits.
FUNCTION IsWordChar% (c$)
    u$ = UCASE$(c$)
    IsWordChar% = (u$ >= "A" AND u$ <= "Z") OR (u$ >= "0" AND u$ <= "9")
END FUNCTION
