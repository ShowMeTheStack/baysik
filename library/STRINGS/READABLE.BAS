' ============================================================
' TITLE:    Readability Analyzer
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     text statistics, syllables, Flesch, sentences, heuristics
' SUMMARY:  Counts sentences, words and syllables and scores how easy a text is to read (Flesch formulas).
' ------------------------------------------------------------
' WHAT IT DOES
'   Teachers and writers use "readability formulas" to estimate how
'   hard a text is.  The famous Flesch Reading Ease score is:
'       206.835 - 1.015 * (words / sentences)
'               - 84.6  * (syllables / words)
'   Higher = easier.  90+ is easy for an 11-year-old, 30 or less
'   is university level.  The Flesch-Kincaid GRADE formula turns the
'   same numbers into a school grade:
'       0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59
'
'   Counting syllables exactly needs a dictionary, so we use a
'   classic heuristic: count groups of vowels, then fix a few
'   common cases (silent "e" at the end, "-le" endings ...).
'   It analyses three sample texts and then text you type.
'
' HOW TO USE
'   Press a key after each sample.  Then type your own lines (finish
'   with an empty line).  On the next prompt, an empty line quits.
'
' CONCEPTS YOU WILL LEARN
'   * Counting sentences by their ending punctuation
'   * A syllable-counting heuristic (and why heuristics fail sometimes)
'   * Turning raw counts into averages and a score
'   * Using SELECT CASE with ranges to label results
'
' THINGS TO TRY
'   * Print the syllable count of every word to find mistakes
'   * Add the "Gunning Fog" index: 0.4*(words/sentences + 100*complex/words)
'   * Find the longest sentence in the text
' ============================================================

DECLARE FUNCTION Syllables% (w$)
DECLARE SUB Analyse (t$)

CLS
COLOR 14: PRINT "READABILITY ANALYZER": COLOR 7
FOR s = 1 TO 3
    READ title$, t$
    PRINT
    COLOR 11: PRINT "Sample: "; title$: COLOR 7
    Analyse t$
    PRINT "(press a key)"
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN END
NEXT s

DO
    PRINT
    PRINT "Type a text (empty line to finish, empty first line to quit):"
    t$ = ""
    DO
        LINE INPUT "> "; L$
        IF L$ = "" THEN EXIT DO
        t$ = t$ + L$ + " "
    LOOP
    IF t$ = "" THEN EXIT DO
    Analyse t$
LOOP
PRINT "Goodbye!"
END

DATA "Children's book"
DATA "The cat sat on the mat. It was a fat cat. The dog came in. The cat ran off. The dog sat down."
DATA "Encyclopedia"
DATA "A computer is a programmable machine that can automatically carry out sequences of arithmetic or logical operations. Modern computers can perform generic sets of operations known as programs."
DATA "Legal contract"
DATA "Notwithstanding the aforementioned provisions, the licensee shall indemnify the licensor against all liabilities, obligations and consequential damages arising therefrom, irrespective of jurisdiction."

' ------------------------------------------------------------
' Analyse: one pass over the text.
'   * letters build up a word; anything else ends it
'   * . ! ? end a sentence (several in a row count once: "?!")
' ------------------------------------------------------------
SUB Analyse (t$)
    words = 0: sentences = 0: syl = 0: letters = 0: complex = 0
    w$ = "": endSeen = 0
    FOR i = 1 TO LEN(t$) + 1
        IF i <= LEN(t$) THEN c$ = MID$(t$, i, 1) ELSE c$ = " "
        u$ = UCASE$(c$)
        IF (u$ >= "A" AND u$ <= "Z") OR c$ = "'" THEN
            w$ = w$ + c$
            endSeen = 0
        ELSE
            IF w$ <> "" THEN
                words = words + 1
                letters = letters + LEN(w$)
                n = Syllables%(w$)
                syl = syl + n
                IF n >= 3 THEN complex = complex + 1
                w$ = ""
            END IF
            IF INSTR(".!?", c$) > 0 AND endSeen = 0 THEN sentences = sentences + 1: endSeen = 1
        END IF
    NEXT i
    IF words = 0 THEN PRINT "  No words!": EXIT SUB
    IF sentences = 0 THEN sentences = 1      ' text without a full stop
    wps = words / sentences                  ' words per sentence
    spw = syl / words                        ' syllables per word
    ease = 206.835 - 1.015 * wps - 84.6 * spw
    grade = .39 * wps + 11.8 * spw - 15.59
    PRINT USING "  Sentences ###   Words ####   Syllables ####   Long words (3+ syl) ###"; sentences; words; syl; complex
    PRINT USING "  Avg words/sentence ##.#   Avg syllables/word #.##   Avg letters/word #.#"; wps; spw; letters / words
    PRINT USING "  Flesch Reading Ease: ####.#    Grade level: ##.#"; ease; grade
    PRINT "  Verdict: ";
    SELECT CASE ease
        CASE IS >= 90: COLOR 10: PRINT "very easy (age 11)"
        CASE 70 TO 90: COLOR 10: PRINT "easy (age 12-13)"
        CASE 50 TO 70: COLOR 14: PRINT "plain English (age 13-17)"
        CASE 30 TO 50: COLOR 6: PRINT "difficult (college)"
        CASE ELSE: COLOR 12: PRINT "very difficult (university graduate)"
    END SELECT
    COLOR 7
END SUB

' ------------------------------------------------------------
' Syllables%: count groups of consecutive vowels (aeiouy).
'   "computer" -> o, u, e      = 3
'   "beautiful" -> eau, i, u   = 3
' Corrections:
'   - a final silent "e" does not count ("make" = 1), but "-le"
'     after a consonant does ("table" = 2)
'   - final "es" / "ed" are often silent ("jumped" = 1)
'   - every word has at least one syllable
' ------------------------------------------------------------
FUNCTION Syllables% (w$)
    s$ = LCASE$(w$)
    n = 0: prevV = 0
    FOR i = 1 TO LEN(s$)
        isV = INSTR("aeiouy", MID$(s$, i, 1)) > 0
        IF isV AND NOT prevV THEN n = n + 1     ' start of a vowel group
        prevV = isV
    NEXT i
    L = LEN(s$)
    IF L > 2 THEN
        e2$ = RIGHT$(s$, 2)
        before$ = MID$(s$, L - 2, 1)            ' letter before the ending
        IF RIGHT$(s$, 1) = "e" AND e2$ <> "le" AND e2$ <> "ee" AND INSTR("aeiouy", before$) = 0 THEN n = n - 1
        IF RIGHT$(s$, 3) = "les" OR RIGHT$(s$, 3) = "led" THEN
            ' "tables", "bottled": keep the syllable
        ELSEIF (e2$ = "es" OR e2$ = "ed") AND INSTR("aeiouytd", before$) = 0 THEN
            IF NOT (e2$ = "es" AND INSTR("sxzh", before$) > 0) THEN n = n - 1
        END IF
    END IF
    IF n < 1 THEN n = 1
    Syllables% = n
END FUNCTION
