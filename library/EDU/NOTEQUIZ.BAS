' ============================================================
' TITLE:    Music Note Quiz
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     music, reading notes, staff, PLAY, graphics
' SUMMARY:  Name the note on the treble staff - hear it played - and race the clock to read music faster.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a five-line treble staff with a note on it.  Press the
'   letter name of the note (A to G).  Every note is played aloud, so
'   you learn how it sounds as well as where it sits.  After a wrong
'   answer the program reminds you of the memory tricks:
'     Lines (bottom to top):  E G B D F  - "Every Good Boy Deserves Fudge"
'     Spaces (bottom to top): F A C E    - they spell FACE!
'   Level 1 uses only the lines, level 2 only the spaces, level 3 all
'   notes including middle C and the ledger lines.
'
' HOW TO USE
'   Choose a level 1-3, then press A-G for each note.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Turning a "step" number into a screen y position and a letter
'   * MOD 7 to cycle through the 7 note letters C D E F G A B
'   * Building PLAY strings like "O4 E" from numbers
'   * Drawing note heads with CIRCLE's aspect ratio (an oval)
'
' THINGS TO TRY
'   * Add the bass clef (bottom line is G, spaces are A C E G)
'   * Show two notes and ask which is higher
'   * Add sharps and flats with a # or b symbol
' ============================================================

DECLARE SUB DrawStaff ()
DECLARE SUB DrawNote (s!, col!)
DECLARE FUNCTION NoteLetter$ (s!)

' Step numbers: s = 0 is E on the bottom line.  Each step up the
' staff (line -> space -> line) is half a line gap = 10 pixels.
CONST BOTTOM = 300            ' y of the bottom line (s = 0)
CONST GAP = 10                ' pixels per step
CONST NX = 380                ' x of the note
RANDOMIZE TIMER
SCREEN 12

COLOR 14: LOCATE 3, 30: PRINT "MUSIC NOTE QUIZ"
COLOR 15
LOCATE 7, 20: PRINT "1) Notes on the LINES   (E G B D F)"
LOCATE 8, 20: PRINT "2) Notes in the SPACES  (F A C E)"
LOCATE 9, 20: PRINT "3) Everything, with ledger lines"
LOCATE 11, 20: PRINT "Choose 1-3 (Esc = quit): ";
DO: k$ = INKEY$: LOOP UNTIL (k$ >= "1" AND k$ <= "3" AND LEN(k$) = 1) OR k$ = CHR$(27)
IF k$ = CHR$(27) THEN SCREEN 0: END
level = VAL(k$)

score = 0: total = 0: lastS = 99
t0 = TIMER
FOR q = 1 TO 12
    ' choose a step for this level (never the same note twice in a row)
    DO
        SELECT CASE level
            CASE 1: s = INT(RND * 5) * 2          ' 0,2,4,6,8 = lines
            CASE 2: s = INT(RND * 4) * 2 + 1      ' 1,3,5,7   = spaces
            CASE ELSE: s = INT(RND * 13) - 2      ' -2 (middle C) .. 10 (A)
        END SELECT
    LOOP WHILE s = lastS
    lastS = s

    CLS
    DrawStaff
    DrawNote s, 15
    COLOR 14: LOCATE 2, 3: PRINT "Note"; q; "of 12"; TAB(60); "Score:"; score
    COLOR 15: LOCATE 24, 25: PRINT "Which note is this? (A-G)"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL (k$ >= "A" AND k$ <= "G" AND LEN(k$) = 1) OR k$ = CHR$(27)
    IF k$ = CHR$(27) THEN EXIT FOR
    total = total + 1

    ' Play the note: octave 4 starts at middle C (s = -2).  Steps
    ' -2..4 are C4..B4 and steps 5..11 are C5..B5.
    octave = 4 + (s + 2) \ 7
    PLAY "T160 L4 O" + LTRIM$(STR$(octave)) + NoteLetter$(s)

    LOCATE 26, 25
    IF k$ = NoteLetter$(s) THEN
        score = score + 1
        COLOR 10: PRINT "Correct - that's "; NoteLetter$(s); "!"
        DrawNote s, 10
    ELSE
        COLOR 12: PRINT "That was "; NoteLetter$(s); ", not "; k$; "."
        DrawNote s, 12
        COLOR 11: LOCATE 27, 10
        IF s MOD 2 = 0 THEN
            PRINT "It's on a LINE: Every Good Boy Deserves Fudge (E G B D F)"
        ELSE
            PRINT "It's in a SPACE: the spaces spell F A C E"
        END IF
    END IF
    COLOR 7: LOCATE 29, 25: PRINT "Press a key...";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT q

secs = TIMER - t0: IF secs < 0 THEN secs = secs + 86400
CLS
COLOR 14: LOCATE 10, 22: PRINT "You named"; score; "of"; total; "notes correctly."
LOCATE 12, 22: PRINT USING "Total time: #### seconds"; secs
LOCATE 14, 22: COLOR 13
IF total > 0 AND score = total THEN
    PRINT "Perfect pitch - er, perfect reading!"
    PLAY "T200 O4 C8 E8 G8 O5 C4 O4 G8 O5 C2"
ELSE
    PRINT "Keep practising and you'll read music like a pro!"
END IF
COLOR 7: LOCATE 17, 22: PRINT "Press a key to finish.";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0
END

' ------------------------------------------------------------
' DrawStaff: five lines (steps 0, 2, 4, 6, 8) and a simple clef.
' ------------------------------------------------------------
SUB DrawStaff
    FOR s = 0 TO 8 STEP 2
        y = BOTTOM - s * GAP
        LINE (80, y)-(560, y), 15
    NEXT s
    ' A simplified treble (G) clef: a tall line with loops.  The
    ' curl wraps around the 2nd line - the G line - which is why it
    ' is called the G clef.
    gy = BOTTOM - 2 * GAP                  ' the G line
    LINE (130, BOTTOM + 30)-(130, BOTTOM - 8 * GAP - 25), 14
    CIRCLE (130, BOTTOM - 8 * GAP - 15), 10, 14, 0, 3.14
    CIRCLE (130, gy), 18, 14
    CIRCLE (130, gy), 8, 14
    CIRCLE (124, BOTTOM + 30), 6, 14
END SUB

' ------------------------------------------------------------
' DrawNote: an oval note head at step s with a stem.  Notes below
' or above the staff get short "ledger lines" through or under them.
' ------------------------------------------------------------
SUB DrawNote (s, col)
    y = BOTTOM - s * GAP
    ' ledger lines are needed for even steps outside 0..8
    IF s <= -2 THEN
        FOR l = -2 TO s STEP -2
            LINE (NX - 18, BOTTOM - l * GAP)-(NX + 18, BOTTOM - l * GAP), 15
        NEXT l
    END IF
    IF s >= 10 THEN
        FOR l = 10 TO s STEP 2
            LINE (NX - 18, BOTTOM - l * GAP)-(NX + 18, BOTTOM - l * GAP), 15
        NEXT l
    END IF
    CIRCLE (NX, y), 11, col, , , .7        ' aspect .7 makes an oval
    PAINT (NX, y), col, col
    ' Stem: up on the right for low notes, down on the left for high
    IF s < 4 THEN
        LINE (NX + 10, y)-(NX + 10, y - 60), col
    ELSE
        LINE (NX - 10, y)-(NX - 10, y + 60), col
    END IF
END SUB

' Step s -> letter.  s = -2 is C, so (s + 2) counts up from C.
' The + 70 keeps the number positive before MOD.
FUNCTION NoteLetter$ (s)
    NoteLetter$ = MID$("CDEFGAB", ((s + 2 + 70) MOD 7) + 1, 1)
END FUNCTION
