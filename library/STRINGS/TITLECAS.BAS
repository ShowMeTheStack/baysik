' ============================================================
' TITLE:    Title Case & Sentence Case
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     case conversion, UCASE$, LCASE$, INSTR, small words
' SUMMARY:  Converts text to UPPER, lower, Title Case (with proper small words) and Sentence case.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows four ways of writing the same text:
'     UPPER CASE, lower case,
'     Title Case  - every important word gets a capital, but small
'                   words like "of", "the", "and" stay lower case
'                   unless they are the first or last word,
'     Sentence case - only the first letter of each sentence (after
'                   . ! or ?) is a capital, plus the word "I".
'   Also includes "tOGGLE cASE" just for fun.
'
' HOW TO USE
'   Type a line of text and press Enter.  Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * UCASE$ and LCASE$
'   * Remembering "state" while scanning (start of word / sentence)
'   * Using INSTR to check membership in a list: INSTR(" A AN THE ", " X ")
'   * ASC and CHR$ to flip letter case by hand (+/- 32)
'
' THINGS TO TRY
'   * Add more small words (VIA, PER, VS ...)
'   * Keep words that are already ALL CAPS (like NASA) unchanged
'   * Make "camelCase" and "snake_case" converters
' ============================================================

DECLARE FUNCTION TitleCase$ (s$)
DECLARE FUNCTION SentenceCase$ (s$)
DECLARE FUNCTION ToggleCase$ (s$)

CLS
COLOR 14: PRINT "TITLE CASE & SENTENCE CASE": COLOR 7
PRINT
PRINT "Example:"
ex$ = "the lord of the rings. a tale of hobbits and wizards! i liked it."
GOSUB ShowAll
DO
    PRINT
    LINE INPUT "Your text (Enter = quit): "; ex$
    IF ex$ = "" OR UCASE$(ex$) = "Q" THEN EXIT DO
    GOSUB ShowAll
LOOP
PRINT "Goodbye!"
END

ShowAll:
    PRINT "  UPPER   : "; UCASE$(ex$)
    PRINT "  lower   : "; LCASE$(ex$)
    PRINT "  Title   : "; TitleCase$(ex$)
    PRINT "  Sentence: "; SentenceCase$(ex$)
    PRINT "  tOGGLE  : "; ToggleCase$(ex$)
RETURN

' ------------------------------------------------------------
' TitleCase$: split into words (by spaces).  For each word:
'   - if it is a "small word" and not first/last -> all lower
'   - otherwise first letter upper, rest lower
' To spot the last word we first count how many words there are.
' ------------------------------------------------------------
FUNCTION TitleCase$ (s$)
    small$ = " A AN THE AND BUT OR NOR FOR OF IN ON AT TO BY UP AS "
    ' count words
    nwords = 0: inword = 0
    FOR i = 1 TO LEN(s$)
        IF MID$(s$, i, 1) <> " " THEN
            IF inword = 0 THEN nwords = nwords + 1
            inword = 1
        ELSE
            inword = 0
        END IF
    NEXT i
    ' build the result word by word
    out$ = "": w$ = "": k = 0: newSent = 0
    FOR i = 1 TO LEN(s$) + 1
        IF i <= LEN(s$) THEN ch$ = MID$(s$, i, 1) ELSE ch$ = " "
        IF ch$ <> " " THEN
            w$ = w$ + ch$
        ELSE
            IF w$ <> "" THEN
                k = k + 1
                ' strip punctuation for the small-word test ("of," -> "OF")
                bare$ = UCASE$(w$)
                DO WHILE LEN(bare$) > 0 AND INSTR(".,;:!?", RIGHT$(bare$, 1)) > 0
                    bare$ = LEFT$(bare$, LEN(bare$) - 1)
                LOOP
                ' small words stay lower case - except first, last,
                ' or straight after a sentence ending (newSent)
                IF k > 1 AND k < nwords AND newSent = 0 AND INSTR(small$, " " + bare$ + " ") > 0 THEN
                    w$ = LCASE$(w$)
                ELSE
                    w$ = UCASE$(LEFT$(w$, 1)) + LCASE$(MID$(w$, 2))
                END IF
                ' does this word end a sentence?  then the next starts one
                newSent = 0
                IF INSTR(".!?", RIGHT$(w$, 1)) > 0 THEN newSent = 1
                out$ = out$ + w$
                w$ = ""
            END IF
            IF i <= LEN(s$) THEN out$ = out$ + " "    ' keep the spaces
        END IF
    NEXT i
    TitleCase$ = out$
END FUNCTION

' ------------------------------------------------------------
' SentenceCase$: lower-case everything, but capitalise the first
' letter we meet after the start or after . ! ?
' "capNext" is a flag that remembers we are waiting for a capital.
' Also fixes the lonely word "i" -> "I".
' ------------------------------------------------------------
FUNCTION SentenceCase$ (s$)
    t$ = LCASE$(s$)
    capNext = -1
    FOR i = 1 TO LEN(t$)
        ch$ = MID$(t$, i, 1)
        IF ch$ >= "a" AND ch$ <= "z" THEN
            IF capNext THEN MID$(t$, i, 1) = UCASE$(ch$): capNext = 0
        ELSEIF INSTR(".!?", ch$) > 0 THEN
            capNext = -1
        END IF
    NEXT i
    ' the pronoun "i": pad with spaces so words at either end count too
    p$ = " " + t$ + " "
    FOR i = 2 TO LEN(p$) - 1
        IF MID$(p$, i, 1) = "i" THEN
            b$ = MID$(p$, i - 1, 1): a$ = MID$(p$, i + 1, 1)
            IF INSTR(" '", b$) > 0 AND INSTR(" .,!?'", a$) > 0 THEN MID$(p$, i, 1) = "I"
        END IF
    NEXT i
    SentenceCase$ = MID$(p$, 2, LEN(t$))
END FUNCTION

' ------------------------------------------------------------
' ToggleCase$: in ASCII, "a" is 97 and "A" is 65 - exactly 32
' apart.  So we can flip case by adding or subtracting 32.
' ------------------------------------------------------------
FUNCTION ToggleCase$ (s$)
    t$ = s$
    FOR i = 1 TO LEN(t$)
        c = ASC(MID$(t$, i, 1))
        IF c >= 65 AND c <= 90 THEN
            MID$(t$, i, 1) = CHR$(c + 32)
        ELSEIF c >= 97 AND c <= 122 THEN
            MID$(t$, i, 1) = CHR$(c - 32)
        END IF
    NEXT i
    ToggleCase$ = t$
END FUNCTION
