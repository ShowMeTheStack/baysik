' ============================================================
' TITLE:    Speed Typer with Saved High Scores
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, high scores, WRITE#, INPUT#, game, TIMER, sorting
' SUMMARY:  A quick letter-typing game whose top-10 table is saved to disk between runs.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows 15 random letters one at a time; type each as fast as you
'   can. Your score depends on speed and accuracy. The best 10 scores
'   live in SCORES.DAT, so they survive after the program ends - run
'   it again tomorrow and your name is still there.
'
' HOW TO USE
'   Press a key to start, then type the letter shown (Esc gives up).
'   If you make the table, type your name. Y plays again, N quits.
'
' CONCEPTS YOU WILL LEARN
'   * Loading a table from a file at start-up (or making a default)
'   * Saving it with WRITE # so names with commas are safe
'   * Inserting into a sorted list by shifting entries down
'   * Measuring time with TIMER (and surviving midnight!)
'
' THINGS TO TRY
'   * Use whole words instead of single letters.
'   * Add a "reset scores" option that KILLs the file.
' ============================================================

DECLARE SUB LoadScores ()
DECLARE SUB SaveScores ()
DECLARE SUB ShowScores (hl)

CONST NTOP = 10
CONST SCOREFILE = "SCORES.DAT"
DIM SHARED nm$(1 TO NTOP), sc(1 TO NTOP), dt$(1 TO NTOP)

RANDOMIZE TIMER
LoadScores

DO
    CLS
    ShowScores 0
    PRINT
    PRINT "Type each letter as fast as you can. Press a key to start..."
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT DO

    ' ---- the game -------------------------------------------------
    CLS
    hits = 0: misses = 0
    t0! = TIMER
    FOR i = 1 TO 15
        target$ = CHR$(65 + INT(RND * 26))       ' random A..Z
        LOCATE 10, 30: PRINT "Letter"; i; "of 15:   ";
        COLOR 14: PRINT target$: COLOR 7
        k$ = UCASE$(INPUT$(1))
        IF k$ = CHR$(27) THEN EXIT FOR
        IF k$ = target$ THEN hits = hits + 1 ELSE misses = misses + 1: BEEP
    NEXT
    secs! = TIMER - t0!
    ' TIMER restarts at 0 at midnight; add a day's seconds if needed.
    IF secs! < 0 THEN secs! = secs! + 86400
    IF secs! < .5 THEN secs! = .5

    ' Score: 100 per hit, minus 50 per miss, scaled by speed.
    score = INT((hits * 100 - misses * 50) * 10 / secs!)
    IF score < 0 THEN score = 0
    LOCATE 13, 25: PRINT USING "Hits ##  Misses ##  Time ##.##s"; hits; misses; secs!
    LOCATE 14, 25: PRINT "SCORE:"; score

    ' ---- does it make the table? ---------------------------------
    ' Scores are kept in descending order, so we look for the first
    ' slot whose score is lower than ours.
    slot = 0
    FOR i = 1 TO NTOP
        IF score > sc(i) THEN slot = i: EXIT FOR
    NEXT
    IF slot > 0 THEN
        LOCATE 16, 25: PRINT "NEW HIGH SCORE - place"; slot
        LOCATE 17, 25: LINE INPUT "Your name: "; who$
        who$ = LEFT$(LTRIM$(RTRIM$(who$)), 16)
        IF who$ = "" THEN who$ = "Anonymous"
        ' Shift everyone from slot down by one; the last one drops off.
        FOR i = NTOP TO slot + 1 STEP -1
            nm$(i) = nm$(i - 1): sc(i) = sc(i - 1): dt$(i) = dt$(i - 1)
        NEXT
        nm$(slot) = who$: sc(slot) = score: dt$(slot) = DATE$
        SaveScores                 ' save right away - never lose a record
        CLS
        ShowScores slot
    ELSE
        LOCATE 16, 25: PRINT "Not quite enough for the table."
    END IF
    PRINT
    PRINT "Play again (Y/N)? ";
    DO: a$ = UCASE$(INPUT$(1)): LOOP UNTIL a$ = "Y" OR a$ = "N" OR a$ = CHR$(27)
    IF a$ <> "Y" THEN EXIT DO
LOOP
CLS
PRINT "Scores saved in "; SCOREFILE; ". See you next time!"
END

NoFile:
    noScores = -1
    RESUME NEXT

' Read the table, or create a default one the first time.
SUB LoadScores
    SHARED noScores
    noScores = 0
    ON ERROR GOTO NoFile
    OPEN SCOREFILE FOR INPUT AS #1
    ON ERROR GOTO 0
    IF noScores THEN
        ' First run: invent some scores to beat.
        FOR i = 1 TO NTOP
            nm$(i) = "CPU-" + LTRIM$(STR$(i)): sc(i) = (NTOP + 1 - i) * 50: dt$(i) = "--"
        NEXT
        SaveScores
    ELSE
        ' Each record is one line written by WRITE #: "name",score,"date"
        FOR i = 1 TO NTOP
            IF EOF(1) THEN EXIT FOR
            INPUT #1, nm$(i), sc(i), dt$(i)
        NEXT
        CLOSE #1
    END IF
END SUB

SUB SaveScores
    OPEN SCOREFILE FOR OUTPUT AS #1
    FOR i = 1 TO NTOP
        WRITE #1, nm$(i), sc(i), dt$(i)
    NEXT
    CLOSE #1
END SUB

' Print the table; row hl (if any) is highlighted.
SUB ShowScores (hl)
    PRINT TAB(25); "*** SPEED TYPER HALL OF FAME ***"
    PRINT
    FOR i = 1 TO NTOP
        IF i = hl THEN COLOR 0, 14 ELSE COLOR 7, 0
        LOCATE , 22
        PRINT USING "##. \              \ ######   \        \"; i; nm$(i); sc(i); dt$(i)
    NEXT
    COLOR 7, 0
END SUB
