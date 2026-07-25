' ============================================================
' TITLE:    Vowel & Consonant Counter
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     counting, INSTR, letters, arrays, histogram
' SUMMARY:  Counts vowels, consonants, digits, spaces and every letter A-Z in your text.
' ------------------------------------------------------------
' WHAT IT DOES
'   Looks at every character of the text you type and puts it in
'   a category: vowel, consonant, digit, space or other.  It also
'   keeps a separate tally for each letter A..Z and prints a
'   colourful mini histogram, so you can see which letters you use
'   the most.  (In English, E is usually the winner!)
'
' HOW TO USE
'   Type a line of text and press Enter.  Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * INSTR("AEIOU", ch$) as a quick "is it one of these?" test
'   * ASC() to turn a letter into an array index (A=1 ... Z=26)
'   * Counting with an array of 26 counters
'   * Percentages and rounding
'
' THINGS TO TRY
'   * Treat Y as a vowel when it is not the first letter of a word
'   * Keep a running total over all the lines you type
'   * Print the letters sorted from most to least frequent
' ============================================================

DIM letter(26)

CLS
COLOR 14: PRINT "VOWEL & CONSONANT COUNTER": COLOR 7
PRINT
DO
    LINE INPUT "Text (Enter = quit): "; t$
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO

    ' reset all counters for this line
    vow = 0: con = 0: dig = 0: spaces = 0: oth = 0
    FOR i = 1 TO 26: letter(i) = 0: NEXT i

    FOR i = 1 TO LEN(t$)
        ch$ = UCASE$(MID$(t$, i, 1))
        IF ch$ >= "A" AND ch$ <= "Z" THEN
            ' ASC("A") is 65, so subtracting 64 gives A=1, B=2 ...
            idx = ASC(ch$) - 64
            letter(idx) = letter(idx) + 1
            IF INSTR("AEIOU", ch$) > 0 THEN vow = vow + 1 ELSE con = con + 1
        ELSEIF ch$ >= "0" AND ch$ <= "9" THEN
            dig = dig + 1
        ELSEIF ch$ = " " THEN
            spaces = spaces + 1
        ELSE
            oth = oth + 1
        END IF
    NEXT i

    letters = vow + con
    PRINT
    PRINT "  Characters :"; LEN(t$)
    COLOR 10: PRINT "  Vowels     :"; vow;
    IF letters > 0 THEN PRINT USING "  (###%)"; vow * 100 / letters ELSE PRINT
    COLOR 11: PRINT "  Consonants :"; con;
    IF letters > 0 THEN PRINT USING "  (###%)"; con * 100 / letters ELSE PRINT
    COLOR 7
    PRINT "  Digits     :"; dig
    PRINT "  Spaces     :"; spaces
    PRINT "  Other      :"; oth
    PRINT
    ' ---- letter histogram: only letters that appeared ----
    IF letters > 0 THEN
        PRINT "  Letter counts:"
        FOR i = 1 TO 26
            IF letter(i) > 0 THEN
                L$ = CHR$(64 + i)
                IF INSTR("AEIOU", L$) THEN COLOR 10 ELSE COLOR 11
                n = letter(i): IF n > 50 THEN n = 50
                PRINT "    "; L$; " "; STRING$(n, 254); letter(i)
            END IF
        NEXT i
        COLOR 7
    END IF
    PRINT
LOOP
PRINT "Goodbye!"
END
