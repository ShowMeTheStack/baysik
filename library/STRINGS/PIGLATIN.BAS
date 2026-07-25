' ============================================================
' TITLE:    Pig Latin Translator
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     pig latin, words, vowels, capitalisation, translation
' SUMMARY:  Translates English into Pig Latin ("hello" -> "ellohay") and decodes a hyphenated version back.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pig Latin is a playground "secret language".  The rules:
'     * Word starts with consonants: move them to the end and add
'       "ay"                           string -> ingstray
'     * Word starts with a vowel: just add "way"
'                                      apple  -> appleway
'   "QU" stays together (quiet -> ietquay) and Y counts as a vowel
'   when it is not the first letter (rhythm -> ythmrhay).
'   Capital letters and punctuation are kept in the right places.
'
'   Classic Pig Latin can NOT always be decoded: is "ayway" from
'   "way" or from "a"?  So the program also writes a hyphenated
'   dialect ("ing-stray", "apple-ay") which keeps exactly enough
'   information to be translated back perfectly - and decodes it.
'
' HOW TO USE
'   Type a sentence and press Enter.  Empty line or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting a sentence into words and non-word characters
'   * Finding the first vowel with a loop and INSTR
'   * Preserving capitalisation (Hello -> Ellohay)
'   * Lossy vs lossless transformations - why the hyphen matters
'
' THINGS TO TRY
'   * Invent your own secret language rules (Ubbi Dubbi, Op ...)
'   * Decode classic Pig Latin by checking guesses against a word list
' ============================================================

DECLARE FUNCTION PigWord$ (w$, hyphen%)
DECLARE FUNCTION UnPigWord$ (w$)
DECLARE FUNCTION Translate$ (s$, mode%)

CLS
COLOR 14: PRINT "PIG LATIN TRANSLATOR": COLOR 7
PRINT "Igpay Atinlay anslatortray!"
s$ = "Hello there, my quiet friend! Is this string in Pig Latin yet?"
GOSUB ShowAll
DO
    PRINT
    LINE INPUT "English (Enter = quit): "; s$
    IF s$ = "" OR UCASE$(s$) = "Q" THEN EXIT DO
    GOSUB ShowAll
LOOP
PRINT "Oodbyegay!"
END

ShowAll:
    PRINT
    PRINT "English  : "; s$
    COLOR 10: PRINT "Pig Latin: "; Translate$(s$, 1): COLOR 7
    h$ = Translate$(s$, 2)
    COLOR 11: PRINT "Hyphened : "; h$: COLOR 7
    PRINT "Decoded  : "; Translate$(h$, 3)
RETURN

' ------------------------------------------------------------
' Translate$: walk through the sentence collecting letters into
' w$.  When a non-letter shows up (space, comma ...) the word is
' finished, so translate it and copy the non-letter unchanged.
'   mode% 1 = classic Pig Latin
'   mode% 2 = hyphenated Pig Latin
'   mode% 3 = decode hyphenated Pig Latin (here "-" is part of a word)
' ------------------------------------------------------------
FUNCTION Translate$ (s$, mode%)
    out$ = "": w$ = ""
    FOR i = 1 TO LEN(s$) + 1
        IF i <= LEN(s$) THEN c$ = MID$(s$, i, 1) ELSE c$ = " "
        u$ = UCASE$(c$)
        IF (u$ >= "A" AND u$ <= "Z") OR (c$ = "-" AND mode% = 3) THEN
            w$ = w$ + c$
        ELSE
            IF w$ <> "" THEN
                SELECT CASE mode%
                    CASE 1: out$ = out$ + PigWord$(w$, 0)
                    CASE 2: out$ = out$ + PigWord$(w$, 1)
                    CASE 3: out$ = out$ + UnPigWord$(w$)
                END SELECT
                w$ = ""
            END IF
            IF i <= LEN(s$) THEN out$ = out$ + c$
        END IF
    NEXT i
    Translate$ = out$
END FUNCTION

' ------------------------------------------------------------
' PigWord$: translate one word.
'   1. find the first vowel (Y counts after position 1;
'      U does not count right after Q)
'   2. split into head (consonants before it) + tail (the rest)
'   3. classic : tail + head + "ay"  (or word + "way")
'      hyphen  : tail + "-" + head + "ay"  (or word + "-ay")
' Then fix capitals: if the original started with a capital,
' so does the result.
' ------------------------------------------------------------
FUNCTION PigWord$ (w$, hyphen%)
    lw$ = LCASE$(w$)
    v = 0
    FOR i = 1 TO LEN(lw$)
        c$ = MID$(lw$, i, 1)
        IF INSTR("aeiou", c$) > 0 THEN
            ' "qu" acts like one consonant: skip the u.
            ' (BASIC's AND checks BOTH sides, so we must not call
            ' MID$(lw$, 0, 1) when i = 1 - hence the separate test.)
            prev$ = ""
            IF i > 1 THEN prev$ = MID$(lw$, i - 1, 1)
            IF NOT (c$ = "u" AND prev$ = "q") THEN v = i: EXIT FOR
        ELSEIF c$ = "y" AND i > 1 THEN
            v = i: EXIT FOR
        END IF
    NEXT i
    IF v = 0 THEN v = LEN(lw$) + 1      ' no vowels at all, e.g. "hmm"
    head$ = LEFT$(lw$, v - 1)
    tail$ = MID$(lw$, v)
    IF hyphen% THEN
        r$ = tail$ + "-" + head$ + "ay"
        IF tail$ = "" THEN r$ = head$ + "-ay"   ' all consonants: hmm-ay
    ELSEIF head$ = "" THEN
        r$ = lw$ + "way"
    ELSE
        r$ = tail$ + head$ + "ay"
    END IF
    ' keep capitalisation of the first letter (and ALL CAPS words)
    IF w$ = UCASE$(w$) AND LEN(w$) > 1 THEN
        r$ = UCASE$(r$)
    ELSEIF LEFT$(w$, 1) = UCASE$(LEFT$(w$, 1)) THEN
        r$ = UCASE$(LEFT$(r$, 1)) + MID$(r$, 2)
    END IF
    PigWord$ = r$
END FUNCTION

' ------------------------------------------------------------
' UnPigWord$: decode the hyphenated form.  Pieces come in PAIRS:
' "ing-stray" -> tail "ing" + "stray"; drop the "ay" to get the
' head "str" and put it back in front: "string".
' "apple-ay" has an empty head, so it is just "apple".
' A hyphenated English word like "well-known" became
' "ell-way-own-knay": two pairs, decoded and re-joined with "-".
' Anything that does not fit the pattern is left alone.
' ------------------------------------------------------------
FUNCTION UnPigWord$ (w$)
    lw$ = LCASE$(w$) + "-"              ' extra "-" marks the last piece
    out$ = "": pieces = 0: p = 1
    DO WHILE p <= LEN(lw$)
        q = INSTR(p, lw$, "-")
        piece$ = MID$(lw$, p, q - p)
        pieces = pieces + 1
        IF pieces MOD 2 = 1 THEN
            tail$ = piece$                  ' 1st of a pair: the tail
        ELSE
            ' 2nd of a pair must end in "ay"
            IF RIGHT$(piece$, 2) <> "ay" THEN UnPigWord$ = w$: EXIT FUNCTION
            IF out$ <> "" THEN out$ = out$ + "-"
            out$ = out$ + LEFT$(piece$, LEN(piece$) - 2) + tail$
        END IF
        p = q + 1
    LOOP
    IF pieces MOD 2 = 1 THEN UnPigWord$ = w$: EXIT FUNCTION
    r$ = out$
    IF w$ = UCASE$(w$) AND LEN(r$) > 1 THEN
        r$ = UCASE$(r$)
    ELSEIF LEFT$(w$, 1) = UCASE$(LEFT$(w$, 1)) THEN
        r$ = UCASE$(LEFT$(r$, 1)) + MID$(r$, 2)
    END IF
    UnPigWord$ = r$
END FUNCTION
