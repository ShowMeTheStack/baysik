' ============================================================
' TITLE:    PLAY Lesson 2: Rhythm, Rests and Tempo
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, mml, rhythm, tempo, dotted notes, rests, tutorial
' SUMMARY:  Learn L (length), dotted notes, P (pause/rest) and T (tempo) with a live beat counter.
' ------------------------------------------------------------
' WHAT IT DOES
'   The second PLAY lesson. Every example is shown together with
'   a little "rhythm bar" made of text so you can SEE how long
'   each note lasts compared to the others.
'
' HOW TO USE
'   Press a key after each example. Esc quits at any prompt.
'   At the end you can type your own tempo to hear the same
'   tune faster or slower.
'
' CONCEPTS YOU WILL LEARN
'   * L n  - default length: 1 whole, 2 half, 4 quarter, 8 eighth...
'   * Length right after a note: C8 is an eighth-note C
'   * Dots: C4. lasts 1.5 quarters, C4.. lasts 1.75 quarters
'   * P n  - a rest (silence) of length n
'   * T n  - tempo in quarter notes per minute (32-255)
'   * Computing a duration: ms = 60000 / tempo * 4 / length
'
' THINGS TO TRY
'   * Add a triplet feel by using L12 (three notes per quarter).
'   * Make the tempo speed up a little after each repetition.
' ============================================================

DECLARE SUB Example (title$, mml$, bar$)
DECLARE FUNCTION AskKey$ ()

CLS
COLOR 14: PRINT "PLAY LESSON 2 - RHYTHM, RESTS AND TEMPO": COLOR 7
PRINT
PRINT "In the bars below, each '#' is one SIXTEENTH note of time."
PRINT "A quarter note is ####, a half note ########, and so on."
PRINT "A '.' in the bar is a rest (silence)."
PRINT
PRINT "Press a key to start."
IF AskKey$ = CHR$(27) THEN END

' --- Lengths ------------------------------------------------
' The number after a note is the FRACTION of a whole note:
' 1 = whole, 2 = half, 4 = quarter, 8 = eighth, 16 = sixteenth.
Example "Whole, half, quarter, eighth, sixteenth", "T120 O4 C1 C2 C4 C8 C16", "################ ######## #### ## #"

' --- L sets the default length ------------------------------
' Instead of writing 8 after every note we can say L8 once.
Example "L8 makes every following note an eighth", "T120 O4 L8 C D E F G A B > C", "## ## ## ## ## ## ## ##"

' --- Dotted notes -------------------------------------------
' A dot adds HALF the note's own length again: C4. = 4 + 2 = 6
' sixteenths. Two dots add half and then a quarter: 4+2+1 = 7.
Example "Dotted rhythms: C4. D8 is a 'long-short' pattern", "T120 O4 C4. D8 E4. F8 G2", "###### ## ###### ## ########"

' --- Rests --------------------------------------------------
' P (for Pause) works just like a note but is silent. P4 is a
' quarter rest, P8 an eighth rest, and it can be dotted too.
Example "Rests: P4 is a quarter note of silence", "T120 O4 C4 P4 C4 P4 C8 C8 P4 C2", "#### .... #### .... ## ## .... ########"

' --- Tempo --------------------------------------------------
' T sets how many QUARTER notes play each minute. 60 means one
' per second, 120 means two per second (the default), 240 four.
Example "Same scale at T60, T120 and T240", "L8 O4 T60 CDEFG T120 CDEFG T240 CDEFG T120", "slow ... normal ... fast!"

' --- Your own tempo -----------------------------------------
CLS
PRINT "Now pick your own tempo for 'Row, Row, Row Your Boat'."
PRINT "Legal values are 32 to 255. (0 or Enter to finish)"
DO
  PRINT
  INPUT "Tempo"; t
  IF t = 0 THEN EXIT DO
  IF t < 32 OR t > 255 THEN
    PRINT "Please choose a value from 32 to 255."
  ELSE
    ' How long is one quarter note at this tempo? 60000 ms
    ' in a minute divided by t beats.
    PRINT USING "One quarter note will last #### ms."; 60000 / t
    ' STR$ adds a leading space; LTRIM$ removes it so the
    ' PLAY string looks neat ("T90" instead of "T 90").
    PLAY "T" + LTRIM$(STR$(t))
    PLAY "O4 L4 C C C8. D16 E4 E8. D16 E8. F16 G2"
    PLAY "L12 >C C C < G G G E E E C C C L8 G8. F16 E8. D16 C2"
  END IF
LOOP
PLAY "T120"
PRINT "Next lesson: PLAYSTYL.BAS (staccato, legato, background)."
END

FUNCTION AskKey$
  ' INPUT$(1) waits for exactly one keypress and returns it.
  AskKey$ = INPUT$(1)
END FUNCTION

SUB Example (title$, mml$, bar$)
  CLS
  COLOR 11: PRINT title$: COLOR 7
  PRINT
  COLOR 10: PRINT "PLAY "; CHR$(34); mml$; CHR$(34): COLOR 7
  PRINT
  COLOR 13: PRINT bar$: COLOR 7
  PRINT
  PLAY "MN L4"
  PLAY mml$
  PRINT "Press a key (Esc quits)..."
  IF AskKey$ = CHR$(27) THEN END
END SUB
