' ============================================================
' TITLE:    Word Counter (like "wc")
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, text, counting, words, frequency, strings
' SUMMARY:  Count the lines, words and characters of a text file and find its most common words.
' ------------------------------------------------------------
' WHAT IT DOES
'   Writes a short story to STORY.TXT (or uses a file you name),
'   then reads it line by line and counts:
'     * lines, words, characters (letters, spaces, everything)
'     * the longest word and the average word length
'     * the 10 most frequent words, with a bar chart
'
' HOW TO USE
'   Press Enter to use the story, or type another file's name.
'
' CONCEPTS YOU WILL LEARN
'   * Reading a file with LINE INPUT # until EOF
'   * Splitting text into words one character at a time
'   * A simple word->count table with two parallel arrays
'   * Sorting by count to find the "top 10"
'
' THINGS TO TRY
'   * Ignore boring words like "the" and "a" (a "stop list").
'   * Count how many times each LETTER appears instead.
' ============================================================

DECLARE SUB AddWord (w$)

CONST MAXW = 400
DIM SHARED words$(1 TO MAXW), counts(1 TO MAXW), nWords

' ---- create the sample story -----------------------------------
OPEN "STORY.TXT" FOR OUTPUT AS #1
DO
    READ l$
    IF l$ = "*" THEN EXIT DO
    PRINT #1, l$
LOOP
CLOSE #1

CLS
PRINT "WORD COUNTER"
LINE INPUT "File (Enter = STORY.TXT): "; f$
IF f$ = "" THEN f$ = "STORY.TXT"

ON ERROR GOTO NotFound
OPEN f$ FOR INPUT AS #1
ON ERROR GOTO 0

lines = 0: totalWords = 0: chars& = 0: letters& = 0
longest$ = ""
DO WHILE NOT EOF(1)
    LINE INPUT #1, l$
    lines = lines + 1
    chars& = chars& + LEN(l$)
    ' Walk along the line building up the current word w$.
    ' A letter (or an apostrophe inside a word, as in "don't") extends
    ' the word; anything else ends it.
    w$ = ""
    FOR i = 1 TO LEN(l$) + 1
        ' The extra step past the end acts like a final space, so the
        ' last word on the line gets counted too.
        IF i <= LEN(l$) THEN c$ = LCASE$(MID$(l$, i, 1)) ELSE c$ = " "
        IF (c$ >= "a" AND c$ <= "z") OR (c$ = "'" AND w$ <> "") THEN
            w$ = w$ + c$
        ELSE
            IF w$ <> "" THEN
                totalWords = totalWords + 1
                letters& = letters& + LEN(w$)
                IF LEN(w$) > LEN(longest$) THEN longest$ = w$
                AddWord w$
                w$ = ""
            END IF
        END IF
    NEXT
LOOP
CLOSE #1

PRINT
PRINT "File:            "; UCASE$(f$)
PRINT "Lines:          "; lines
PRINT "Words:          "; totalWords
PRINT "Characters:     "; chars&; "(plus"; lines * 2; "line-end bytes)"
PRINT "Different words:"; nWords
IF totalWords > 0 THEN
    PRINT USING "Average length:  ##.# letters"; letters& / totalWords
    PRINT "Longest word:    "; longest$; " ("; LTRIM$(STR$(LEN(longest$))); " letters)"
END IF

' ---- sort by count, biggest first (simple selection sort) ------
FOR i = 1 TO nWords - 1
    best = i
    FOR j = i + 1 TO nWords
        IF counts(j) > counts(best) THEN best = j
    NEXT
    SWAP counts(i), counts(best)
    SWAP words$(i), words$(best)
NEXT

PRINT
PRINT "Top words:"
top = 10: IF nWords < top THEN top = nWords
FOR i = 1 TO top
    ' Bar length scaled so the most common word gets 40 blocks.
    bar = INT(40 * counts(i) / counts(1))
    PRINT USING "  \        \ ### "; words$(i); counts(i);
    PRINT STRING$(bar, 254)
NEXT
PRINT
PRINT "Press a key."
k$ = INPUT$(1)
END

NotFound:
    PRINT "Sorry, "; f$; " was not found."
    END

STORY:
DATA "Once upon a time there was a little robot called Bit."
DATA "Bit lived in a box of old computer parts, and Bit was bored."
DATA "One day Bit found a floppy disk. On the disk was a file,"
DATA "and in the file was a story about a robot who could not read."
DATA "Bit read the story again and again, until the robot in the"
DATA "story learned to read too. Then Bit wrote a story of its own."
DATA "*"

' Add one to the count for w$, or add it to the table if it is new.
SUB AddWord (w$)
    FOR i = 1 TO nWords
        IF words$(i) = w$ THEN counts(i) = counts(i) + 1: EXIT SUB
    NEXT
    IF nWords < MAXW THEN
        nWords = nWords + 1
        words$(nWords) = w$
        counts(nWords) = 1
    END IF
END SUB
