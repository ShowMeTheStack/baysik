' ============================================================
' TITLE:    40-Column Flash Cards
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     width 40, quiz, math, input, color
' SUMMARY:  A times-table quiz in chunky 40-column text mode, with big friendly cards and a score bar.
' ------------------------------------------------------------
' WHAT IT DOES
'   WIDTH 40 switches the text screen to 40 columns: every letter
'   becomes twice as wide, which is great for young readers (and
'   was the normal mode on many home computers hooked up to TVs).
'   This program uses it for a 10-question times-table quiz.
'   Each question appears on a coloured "flash card", you type the
'   answer, and a row of stars shows your score.
'
' HOW TO USE
'   Choose a table (2 to 12) or 0 for a mix, then answer each
'   question and press Enter.  Type Q as an answer to quit early.
'
' CONCEPTS YOU WILL LEARN
'   * WIDTH 40 vs WIDTH 80 (columns go 1..40 now!)
'   * Centring text: column = (40 - LEN(text)) \ 2 + 1
'   * LINE INPUT + VAL to read numbers safely
'   * Drawing a "card" with coloured spaces
'
' THINGS TO TRY
'   * Add a timer and show how fast each answer was.
'   * Ask division questions too.
'   * Keep asking the questions the player got wrong.
' ============================================================

DEFINT A-Z
DECLARE SUB Card (bg, line1$, line2$)
DECLARE SUB Centre (row, txt$)

RANDOMIZE TIMER
SCREEN 0
WIDTH 40, 25        ' 40 columns x 25 rows: big letters!

COLOR 15, 1: CLS
COLOR 14, 1: Centre 3, "FLASH  CARDS"
COLOR 11, 1: Centre 5, "Times tables in giant letters"
COLOR 15, 1
Centre 9, "Which table shall we practise?"
Centre 10, "(2 to 12, or 0 for a mix)"
LOCATE 12, 16: LINE INPUT "> "; t$
tbl = VAL(t$)
IF tbl < 2 OR tbl > 12 THEN tbl = 0       ' anything odd -> mixed

score = 0
quit = 0
FOR q = 1 TO 10
    ' Pick the two numbers for this question.
    IF tbl = 0 THEN a = INT(RND * 11) + 2 ELSE a = tbl
    b = INT(RND * 12) + 1
    ' Swap them half the time so the table number moves around.
    IF RND < .5 THEN SWAP a, b

    Card 2 + (q MOD 5), "Question" + STR$(q) + " of 10", LTRIM$(STR$(a)) + " x" + STR$(b) + " = ?"

    ' The score bar at the bottom: one star per right answer.
    COLOR 14, 1: LOCATE 22, 1: PRINT SPACE$(40);
    LOCATE 22, 3: PRINT "Score: "; STRING$(score, 15); STRING$(q - 1 - score, 250);

    COLOR 15, 1
    LOCATE 18, 1: PRINT SPACE$(40);
    LOCATE 18, 14: LINE INPUT "Answer: "; ans$
    IF UCASE$(LEFT$(ans$, 1)) = "Q" THEN quit = 1: EXIT FOR

    ' The feedback line
    LOCATE 20, 1: PRINT SPACE$(40);
    IF VAL(ans$) = a * b THEN
        score = score + 1
        COLOR 10, 1: Centre 20, "Correct!  Well done."
        SOUND 880, 2: SOUND 1320, 3
    ELSE
        COLOR 12, 1: Centre 20, "Oops! " + LTRIM$(STR$(a)) + " x" + STR$(b) + " =" + STR$(a * b)
        SOUND 200, 6
    END IF
    t! = TIMER: DO WHILE TIMER - t! < 1.2 AND TIMER >= t!: LOOP
    LOCATE 20, 1: PRINT SPACE$(40);
NEXT q

' ---- Results --------------------------------------------------
asked = q - 1
IF quit = 0 THEN asked = 10
COLOR 15, 1: CLS
COLOR 14, 1: Centre 5, "ALL DONE!"
COLOR 15, 1
Centre 9, "You got" + STR$(score) + " out of" + STR$(asked)
SELECT CASE score
    CASE 10: m$ = "PERFECT! You are a maths star!"
    CASE 8, 9: m$ = "Excellent work!"
    CASE 5 TO 7: m$ = "Good - keep practising!"
    CASE ELSE: m$ = "Practice makes perfect. Try again!"
END SELECT
COLOR 11, 1: Centre 12, m$
COLOR 14, 1: Centre 15, STRING$(score, 15)
COLOR 7, 1: Centre 22, "Press any key"
k$ = INPUT$(1)
WIDTH 80, 25         ' put the screen back to normal
COLOR 7, 0: CLS
END

' A flash card: a coloured rectangle 30 x 7 with two lines of text.
SUB Card (bg, line1$, line2$)
    COLOR 15, bg
    FOR r = 7 TO 14
        LOCATE r, 6: PRINT SPACE$(30);
    NEXT r
    ' top and bottom edges drawn with half blocks for rounded-ish corners
    COLOR bg, 1
    LOCATE 6, 6: PRINT STRING$(30, 220);
    LOCATE 15, 6: PRINT STRING$(30, 223);
    COLOR 14, bg: Centre 8, line1$
    COLOR 15, bg: Centre 12, line2$
    COLOR 15, 1
END SUB

' Print text centred on a 40-column line.
SUB Centre (row, txt$)
    LOCATE row, (40 - LEN(txt$)) \ 2 + 1
    PRINT txt$;
END SUB
