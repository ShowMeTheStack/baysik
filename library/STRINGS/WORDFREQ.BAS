' ============================================================
' TITLE:    Word Frequency Counter
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     words, counting, sorting, bar chart, DATA
' SUMMARY:  Counts how often each word appears in a passage and draws a text bar chart of the top words.
' ------------------------------------------------------------
' WHAT IT DOES
'   Splits a passage of text into words, counts each distinct
'   word, sorts the results from most to least common and draws a
'   little bar chart with block characters.  Counting words is the
'   first step of many real tools: search engines, spam filters
'   and authorship detectives all start here.
'
'   By default it analyses a built-in passage (from DATA).  You can
'   also type your own lines of text.
'
' HOW TO USE
'   At the menu press 1 for the sample passage, 2 to type your own
'   text (finish with an empty line), or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting text into words by checking each character
'   * A simple "dictionary" made of two parallel arrays
'   * Linear search to find whether a word was seen before
'   * Sorting two arrays together (swap both!)
'   * Drawing bar charts with STRING$ and CHR$(219)
'
' THINGS TO TRY
'   * Ignore "stop words" like THE, AND, OF
'   * Print the words alphabetically instead of by count
'   * Count letter frequencies instead of words
' ============================================================

DECLARE SUB AddText (t$)
DECLARE SUB AddWord (w$)
DECLARE SUB Report ()

CONST MAXW = 400
DIM SHARED wd$(MAXW), cnt(MAXW), nw, total

DO
    CLS
    COLOR 14: PRINT "WORD FREQUENCY COUNTER": COLOR 7
    PRINT
    PRINT "  1) Analyse the sample passage"
    PRINT "  2) Type your own text"
    PRINT "  Q) Quit"
    PRINT
    PRINT "Choice? ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    PRINT k$
    nw = 0: total = 0                 ' reset the counters
    SELECT CASE k$
        CASE "1"
            RESTORE Passage
            DO
                READ t$
                IF t$ = "*" THEN EXIT DO
                AddText t$
            LOOP
            Report
        CASE "2"
            PRINT "Type lines of text. An empty line finishes."
            DO
                LINE INPUT "> "; t$
                IF t$ = "" THEN EXIT DO
                AddText t$
            LOOP
            Report
        CASE "Q", CHR$(27)
            EXIT DO
    END SELECT
LOOP
CLS
PRINT "Goodbye!"
END

Passage:
DATA "The quick brown fox jumps over the lazy dog. The dog sleeps,"
DATA "and the fox runs away into the brown woods. A fox is quick;"
DATA "a dog is lazy. When the dog wakes, the fox is gone, and the"
DATA "dog dreams of the quick brown fox once more."
DATA "*"

' ------------------------------------------------------------
' AddText: chop a line into words.  A word is a run of letters
' (plus apostrophes, so DON'T stays one word).  Everything else
' - spaces, commas, full stops - ends the current word.
' ------------------------------------------------------------
SUB AddText (t$)
    w$ = ""
    FOR i = 1 TO LEN(t$) + 1
        IF i <= LEN(t$) THEN ch$ = UCASE$(MID$(t$, i, 1)) ELSE ch$ = " "
        IF (ch$ >= "A" AND ch$ <= "Z") OR ch$ = "'" THEN
            w$ = w$ + ch$                 ' still inside a word
        ELSEIF w$ <> "" THEN
            AddWord w$                    ' a word just ended
            w$ = ""
        END IF
    NEXT i
END SUB

' ------------------------------------------------------------
' AddWord: if we have seen the word, add 1 to its count,
' otherwise append it to the end of the list with count 1.
' ------------------------------------------------------------
SUB AddWord (w$)
    total = total + 1
    FOR i = 1 TO nw
        IF wd$(i) = w$ THEN cnt(i) = cnt(i) + 1: EXIT SUB
    NEXT i
    IF nw < MAXW THEN
        nw = nw + 1
        wd$(nw) = w$
        cnt(nw) = 1
    END IF
END SUB

' ------------------------------------------------------------
' Report: sort by count (biggest first; ties alphabetical),
' then print a bar chart of the top 15.
' Bubble sort is simple and plenty fast for a few hundred words.
' ------------------------------------------------------------
SUB Report
    IF nw = 0 THEN PRINT "No words found!": GOTO WaitKey
    FOR i = 1 TO nw - 1
        FOR j = 1 TO nw - i
            swp = 0
            IF cnt(j) < cnt(j + 1) THEN swp = 1
            IF cnt(j) = cnt(j + 1) AND wd$(j) > wd$(j + 1) THEN swp = 1
            IF swp THEN SWAP cnt(j), cnt(j + 1): SWAP wd$(j), wd$(j + 1)
        NEXT j
    NEXT i
    PRINT
    PRINT "Total words:"; total; "  Different words:"; nw
    PRINT
    top = nw: IF top > 15 THEN top = 15
    big = cnt(1)                          ' longest bar = most common word
    FOR i = 1 TO top
        bar = INT(cnt(i) * 40 / big + .5) ' scale bars to at most 40 wide
        IF bar < 1 THEN bar = 1
        PRINT LEFT$(wd$(i) + SPACE$(12), 12); : PRINT USING "### "; cnt(i);
        COLOR 11: PRINT STRING$(bar, 219): COLOR 7
    NEXT i
WaitKey:
    PRINT
    PRINT "Press any key for the menu...";
    DO: LOOP WHILE INKEY$ = ""
END SUB
