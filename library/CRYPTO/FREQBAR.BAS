' ============================================================
' TITLE:    Letter Frequency Analyzer
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     frequency analysis, bar chart, al-kindi, graphics, SCREEN 12
' SUMMARY:  Counts the letters in any text and draws a colourful bar chart next to normal English frequencies.
' ------------------------------------------------------------
' WHAT IT DOES
'   Around the year 850, the Arab scholar Al-Kindi wrote "A
'   Manuscript on Deciphering Cryptographic Messages".  In it he
'   described FREQUENCY ANALYSIS, the most important code-breaking
'   idea for the next thousand years:
'
'     "count the letters in the secret message; the most common one
'      probably stands for the most common letter of the language."
'
'   In English E is the most common letter (about 12.7%), then T, A,
'   O, I, N.  Any simple substitution cipher (Caesar, Atbash, a
'   scrambled alphabet...) keeps these counts - it only moves them to
'   different letters.  This program draws the counts as a bar chart
'   so you can SEE the pattern.  Thin grey bars show normal English
'   so you can compare.
'
' HOW TO USE
'   T = type your own text (one line, up to 255 characters)
'   S = sort bars from most to least common (or back to A..Z)
'   E = show / hide the English reference bars
'   N = next built-in sample (English, Caesar, random letters)
'   Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Counting with an array indexed by letter number
'   * Drawing a bar chart with LINE (x1,y1)-(x2,y2), c, BF
'   * Sorting an index array so labels stay with their counts
'   * Shannon-style "how flat is this histogram" thinking
'
' THINGS TO TRY
'   * Type a sentence with no letter E (a "lipogram") and watch the chart
'   * Compare English and random text: which bars look flatter?
'   * Add a second chart for the most common two-letter pairs (TH, HE, IN)
' ============================================================

DECLARE SUB Analyze (t$)
DECLARE SUB DrawChart ()

DIM SHARED cnt(25), order(25), total, eng!(25), sorted, showEng
FOR i = 0 TO 25: READ eng!(i): NEXT i
DATA 8.2,1.5,2.8,4.3,12.7,2.2,2.0,6.1,7.0,0.15,0.77,4.0,2.4
DATA 6.7,7.5,1.9,0.095,6.0,6.3,9.1,2.8,0.98,2.4,0.15,2.0,0.074

' Three samples: normal English, the same text Caesar-shifted by
' 7, and random letters.  Notice that the Caesar one has exactly
' the same SHAPE as English, just slid 7 places to the right.
DIM SHARED sample$(2), sName$(2)
sName$(0) = "English text"
sample$(0) = "Frequency analysis is the study of how often letters appear. In English the letter E appears more than any other, followed by T, A, O, I and N. A spy who counts letters can often read a secret message without ever knowing the key."
sName$(1) = "Caesar shift 7"
sample$(1) = "Mylxblujf huhsfzpz pz aol zabkf vm ovd vmalu slaalyz hwwlhy. Pu Lunspzo aol slaaly L hwwlhyz tvyl aohu huf vaoly, mvssvdlk if A, H, V, P huk U. H zwf dov jvbuaz slaalyz jhu vmalu ylhk h zljyla tlzzhnl dpaovba lcly ruvdpun aol rlf."
sName$(2) = "Random letters"
RANDOMIZE TIMER
r$ = ""
FOR i = 1 TO 220: r$ = r$ + CHR$(65 + INT(RND * 26)): NEXT i
sample$(2) = r$

SCREEN 12
showEng = 1: sorted = 0: which = 0
cur$ = sample$(0): title$ = sName$(0)
DO
    Analyze cur$
    CLS
    COLOR 14: LOCATE 1, 2: PRINT "LETTER FREQUENCY ANALYZER  -  "; title$
    COLOR 7
    LOCATE 2, 2: PRINT LEFT$(cur$, 76)
    DrawChart
    COLOR 7
    LOCATE 29, 2: PRINT "T=type text  S=sort  E=English bars  N=next sample  Q=quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE "Q", CHR$(27): EXIT DO
    CASE "S": sorted = 1 - sorted
    CASE "E": showEng = 1 - showEng
    CASE "N"
        which = (which + 1) MOD 3
        cur$ = sample$(which): title$ = sName$(which)
    CASE "T"
        LOCATE 29, 1: PRINT SPACE$(79);
        LOCATE 29, 2: LINE INPUT "Text: "; t$
        IF t$ <> "" THEN cur$ = t$: title$ = "your text"
    END SELECT
LOOP
SCREEN 0: WIDTH 80
PRINT "Thank you, Al-Kindi!"
END

' ------------------------------------------------------------
' Analyze: count each letter.  cnt(0) is A, cnt(25) is Z.
' Then build order(): a list of letter numbers.  If sorting is
' on, we bubble-sort order() by count.  We sort the INDEX list,
' not the counts themselves, so each bar keeps its letter label.
' ------------------------------------------------------------
SUB Analyze (t$)
    FOR i = 0 TO 25: cnt(i) = 0: order(i) = i: NEXT i
    total = 0
    FOR i = 1 TO LEN(t$)
        c = ASC(UCASE$(MID$(t$, i, 1))) - 65
        IF c >= 0 AND c <= 25 THEN cnt(c) = cnt(c) + 1: total = total + 1
    NEXT i
    IF sorted THEN
        FOR a = 0 TO 24
            FOR b = 0 TO 24 - a
                IF cnt(order(b)) < cnt(order(b + 1)) THEN SWAP order(b), order(b + 1)
            NEXT b
        NEXT a
    END IF
END SUB

' ------------------------------------------------------------
' DrawChart: 26 bars across a 624-pixel wide area.
'   Each slot is 24 pixels (3 text columns) wide; the coloured bar
'   is the measured percentage, the thin grey bar beside it is
'   normal English.
'   Height: 1 percent = 18 pixels, so 15% reaches 270 pixels.
' ------------------------------------------------------------
SUB DrawChart
    x0 = 16: base0 = 420: slot = 24
    ' Axis lines and percentage grid every 5%.
    FOR p = 0 TO 15 STEP 5
        y = base0 - p * 18
        LINE (x0 - 4, y)-(x0 + 26 * slot - 1, y), 8, , &HAAAA
        LOCATE y \ 16 + 1, 1: COLOR 8: PRINT USING "##"; p;
    NEXT p
    LINE (x0 - 4, base0)-(x0 + 26 * slot - 1, base0), 15
    IF total = 0 THEN
        COLOR 12: LOCATE 15, 25: PRINT "No letters to count!"
        EXIT SUB
    END IF
    mostPct! = 0: most = 0
    FOR s = 0 TO 25
        L = order(s)
        pct! = cnt(L) * 100! / total
        IF pct! > mostPct! THEN mostPct! = pct!: most = L
        h = pct! * 18: IF h > 300 THEN h = 300
        x = x0 + s * slot
        ' Colour cycles through the rainbow so bars are easy to tell apart.
        clr = 9 + (s MOD 6)
        IF h > 0 THEN LINE (x + 3, base0 - h)-(x + 15, base0 - 1), clr, BF
        IF showEng THEN
            he = eng!(L) * 18
            LINE (x + 17, base0 - he)-(x + 20, base0 - 1), 7, BF
        END IF
        ' Letter label under the bar (text rows are 16 pixels tall,
        ' columns 8 pixels wide).
        COLOR 15: LOCATE base0 \ 16 + 2, (x + 8) \ 8 + 1: PRINT CHR$(65 + L);
    NEXT s
    ' Statistics: index of coincidence (how "peaky" the counts are).
    ic! = 0
    IF total > 1 THEN
        FOR i = 0 TO 25: ic! = ic! + cnt(i) * (cnt(i) - 1#): NEXT i
        ic! = ic! / (total * (total - 1#))
    END IF
    COLOR 11
    LOCATE 4, 2: PRINT "Letters counted:"; total
    LOCATE 5, 2: PRINT "Most common: "; CHR$(65 + most);
    PRINT USING " (##.#%)"; mostPct!
    LOCATE 6, 2: PRINT USING "Index of coincidence: #.###  (English ~0.066, random ~0.038)"; ic!
    ' A substitution guess: if E is hiding as letter "most", the
    ' Caesar shift would be (most - 4).
    LOCATE 7, 2: PRINT "If "; CHR$(65 + most); " is really E, a Caesar key would be";
    PRINT (most - 4 + 26) MOD 26
    IF showEng THEN LOCATE 8, 2: COLOR 7: PRINT "Grey = normal English %";
END SUB
