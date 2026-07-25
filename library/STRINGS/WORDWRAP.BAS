' ============================================================
' TITLE:    Word Wrap & Justify
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     word wrap, justification, alignment, greedy algorithm
' SUMMARY:  Wraps a paragraph to any width and aligns it left, right, centred or fully justified.
' ------------------------------------------------------------
' WHAT IT DOES
'   Word processors constantly re-flow text to fit the page.  This
'   program shows how: it breaks a paragraph into words, then fills
'   each line with as many words as fit (the "greedy" algorithm).
'   Each finished line can then be aligned four ways:
'     L  left       ragged right edge (normal)
'     R  right      ragged left edge
'     C  centre
'     J  justify    extra spaces spread between words so both
'                   edges are straight (like a newspaper column)
'   A ruler and a box show the chosen width.
'
' HOW TO USE
'   Press + / - to change the width, L R C J to change alignment,
'   and Q (or Esc) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting text into a word array
'   * The greedy line-filling algorithm
'   * Spreading leftover spaces evenly with \ and MOD
'   * Handling words longer than the line (hard break)
'
' THINGS TO TRY
'   * Hyphenate long words instead of breaking them anywhere
'   * Never justify the last line of a paragraph (already done - why?)
'   * Wrap text you type in yourself
' ============================================================

DECLARE SUB ShowWrapped (wid%, mode$)
DECLARE SUB FlushLine (lw$(), n, wid%, mode$, lastLine)

CONST MAXW = 300
DIM SHARED w$(MAXW), nw

' ---- collect all words of the paragraph into w$() ----
DO
    READ t$
    IF t$ = "*" THEN EXIT DO
    t$ = t$ + " "
    cur$ = ""
    FOR i = 1 TO LEN(t$)
        c$ = MID$(t$, i, 1)
        IF c$ = " " THEN
            IF cur$ <> "" AND nw < MAXW THEN nw = nw + 1: w$(nw) = cur$
            cur$ = ""
        ELSE
            cur$ = cur$ + c$
        END IF
    NEXT i
LOOP

wid% = 40: mode$ = "J"
DO
    CLS
    COLOR 14: PRINT "WORD WRAP & JUSTIFY";
    COLOR 7: PRINT "   width:"; wid%; "  mode: "; mode$
    PRINT "+/- width   L)eft R)ight C)entre J)ustify   Q)uit"
    ShowWrapped wid%, mode$
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "+", "=": IF wid% < 70 THEN wid% = wid% + 2
        CASE "-", "_": IF wid% > 26 THEN wid% = wid% - 2
        CASE "L", "R", "C", "J": mode$ = k$
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
PRINT "Goodbye!"
END

DATA "Computers are good at following instructions, but not at reading"
DATA "your mind. Word wrapping looks simple, yet every word processor,"
DATA "web browser and e-book reader has to decide where each line ends."
DATA "The greedy method puts as many words as possible on each line and"
DATA "only then moves on. Supercalifragilisticexpialidocious words that"
DATA "are wider than the column must be chopped."
DATA "*"

' ------------------------------------------------------------
' ShowWrapped: build lines word by word (the greedy algorithm).
'   lw$() holds the words of the line being filled, n of them,
'   using "used" characters (counting one space per gap).
'   If the next word does not fit, the line is flushed (printed)
'   and a new line starts with that word.
'   A word wider than the whole line is cut: the first piece gets
'   a "-" and the rest is handled like the next word.
' ------------------------------------------------------------
SUB ShowWrapped (wid%, mode$)
    DIM lw$(40)
    PRINT
    PRINT "+"; STRING$(wid%, "-"); "+"
    n = 0: used = 0: i = 0: wd$ = ""
    DO
        IF wd$ = "" THEN                 ' need a fresh word?
            i = i + 1
            IF i > nw THEN EXIT DO
            wd$ = w$(i)
        END IF
        IF LEN(wd$) > wid% THEN
            piece$ = LEFT$(wd$, wid% - 1) + "-": rest$ = MID$(wd$, wid%)
        ELSE
            piece$ = wd$: rest$ = ""
        END IF
        need = LEN(piece$): IF n > 0 THEN need = need + 1   ' + a space
        IF used + need > wid% THEN
            FlushLine lw$(), n, wid%, mode$, 0
            n = 0: used = 0: need = LEN(piece$)
        END IF
        n = n + 1: lw$(n) = piece$: used = used + need
        wd$ = rest$
    LOOP
    FlushLine lw$(), n, wid%, mode$, -1     ' the last line
    PRINT "+"; STRING$(wid%, "-"); "+"
END SUB

' ------------------------------------------------------------
' FlushLine: print n words aligned inside the box.
' Justification: the line has g = n-1 gaps and "extra" spaces
' still missing.  Every gap gets extra \ g more spaces, and the
' first (extra MOD g) gaps get one more, so the line is exactly
' wid% wide.  The LAST line of a paragraph is never justified -
' stretching three words across a whole line looks silly.
' ------------------------------------------------------------
SUB FlushLine (lw$(), n, wid%, mode$, lastLine)
    IF n = 0 THEN EXIT SUB
    s$ = ""
    IF mode$ = "J" AND n > 1 AND NOT lastLine THEN
        used = n - 1                         ' the single spaces
        FOR k = 1 TO n: used = used + LEN(lw$(k)): NEXT k
        gaps = n - 1
        extra = wid% - used
        FOR k = 1 TO n
            s$ = s$ + lw$(k)
            IF k < n THEN
                sp = 1 + extra \ gaps
                IF k <= extra MOD gaps THEN sp = sp + 1
                s$ = s$ + SPACE$(sp)
            END IF
        NEXT k
    ELSE
        FOR k = 1 TO n
            IF k > 1 THEN s$ = s$ + " "
            s$ = s$ + lw$(k)
        NEXT k
        pad = wid% - LEN(s$)
        SELECT CASE mode$
            CASE "R": s$ = SPACE$(pad) + s$
            CASE "C": s$ = SPACE$(pad \ 2) + s$
        END SELECT
    END IF
    PRINT "|"; s$; SPACE$(wid% - LEN(s$)); "|"
END SUB
