' ============================================================
' TITLE:    Ear Training Quiz
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, quiz, intervals, chords, random, music theory
' SUMMARY:  Three ear-training games: higher or lower, major or minor chord, and name-that-interval, with scores.
' ------------------------------------------------------------
' WHAT IT DOES
'   Musicians train their ears to recognise sounds. This quiz
'   plays random notes and asks you questions about them:
'     1. Higher or lower?  Is the second note above or below?
'     2. Major or minor?   Is the chord happy or sad sounding?
'     3. Intervals         How far apart are the two notes?
'   Each round has 10 questions. Press R to hear it again.
'
' HOW TO USE
'   Pick a game from the menu (1-3), Q or Esc to quit.
'   Answer with the keys shown on screen. R = replay.
'
' CONCEPTS YOU WILL LEARN
'   * Generating random musical questions with RND
'   * Intervals measured in semitones (a 5th = 7 semitones)
'   * Major chord = 0,4,7   minor chord = 0,3,7
'   * Reusing one quiz loop for different games
'
' THINGS TO TRY
'   * Add "diminished" and "augmented" chords to game 2.
'   * Keep a high-score file for each game.
' ============================================================

DECLARE SUB PlayN (n%, l$)
DECLARE FUNCTION GetKey$ (allowed$)

' Interval names, by number of semitones (0-12) and keys to answer.
DATA "unison","minor 2nd","major 2nd","minor 3rd","major 3rd","perfect 4th"
DATA "tritone","perfect 5th","minor 6th","major 6th","minor 7th","major 7th","octave"
DIM SHARED ivName$(12)
FOR i = 0 TO 12: READ ivName$(i): NEXT
' Game 3 only uses these intervals, to keep it fair for beginners.
ivSet$ = "2 4 5 7 12"       ' semitones: maj 2nd, maj 3rd, 4th, 5th, octave

RANDOMIZE TIMER
DO
  CLS
  COLOR 14: PRINT " EAR TRAINING QUIZ": COLOR 7
  PRINT
  PRINT " 1) Higher or lower?"
  PRINT " 2) Major or minor chord?"
  PRINT " 3) Name that interval"
  PRINT " Q) Quit"
  PRINT
  PRINT " Choose: ";
  g$ = GetKey$("123Q" + CHR$(27))
  IF g$ = "Q" OR g$ = CHR$(27) THEN EXIT DO
  game = VAL(g$)
  score = 0
  FOR q = 1 TO 10
    CLS
    COLOR 11: PRINT " Question"; q; "of 10"; TAB(50); "Score:"; score: COLOR 7
    PRINT
    ' ---- Make up a question -------------------------------
    ' Root note between N37 (C3) and N55 (F#4) so the answers
    ' stay in a comfortable range.
    root = 37 + INT(RND * 19)
    SELECT CASE game
      CASE 1
        ' Second note is 1 to 7 semitones away, up or down.
        d = (1 + INT(RND * 7)) * SGN(RND - .5)
        IF d = 0 THEN d = 1
        IF d > 0 THEN answer$ = "H" ELSE answer$ = "L"
        prompt$ = "Is the 2nd note H)igher or L)ower?"
        keys$ = "HL"
      CASE 2
        IF RND < .5 THEN third = 4: answer$ = "M" ELSE third = 3: answer$ = "N"
        prompt$ = "Was that chord M)ajor (happy) or N) minor (sad)?"
        keys$ = "MN"
      CASE 3
        ' Pick one of the intervals in ivSet$.
        pick = INT(RND * 5)
        d = VAL(MID$(ivSet$, pick * 2 + 1, 2))
        answer$ = LTRIM$(STR$(pick + 1))
        prompt$ = "Which interval? "
        FOR i = 0 TO 4
          prompt$ = prompt$ + LTRIM$(STR$(i + 1)) + "=" + ivName$(VAL(MID$(ivSet$, i * 2 + 1, 2))) + "  "
        NEXT
        keys$ = "12345"
    END SELECT

    ' ---- Play it, and allow replays ------------------------
    DO
      PLAY "MN T120"
      SELECT CASE game
        CASE 1, 3
          PlayN (root), "4": PlayN root + d, "4"
        CASE 2
          ' First as a quick arpeggio, then "held" (fast repeats).
          PlayN (root), "8": PlayN root + third, "8": PlayN root + 7, "8"
          FOR r = 1 TO 6
            PlayN (root), "64": PlayN root + third, "64": PlayN root + 7, "64"
          NEXT
      END SELECT
      PRINT " "; prompt$
      PRINT " (R = hear it again)"
      a$ = GetKey$(keys$ + "R" + CHR$(27))
      IF a$ <> "R" THEN EXIT DO
    LOOP
    IF a$ = CHR$(27) THEN EXIT FOR

    ' ---- Mark it ----------------------------------------------
    PRINT
    IF a$ = answer$ THEN
      score = score + 1
      COLOR 10: PRINT " Correct!": COLOR 7
      PLAY "T200 L16 O5 CEG"
    ELSE
      COLOR 12: PRINT " Not quite.": COLOR 7
      PLAY "T200 L8 O2 C"
    END IF
    SELECT CASE game
      CASE 1: IF answer$ = "H" THEN PRINT " It went up." ELSE PRINT " It went down."
      CASE 2: IF answer$ = "M" THEN PRINT " Major: 0, 4, 7 semitones." ELSE PRINT " Minor: 0, 3, 7 semitones."
      CASE 3: PRINT " It was a "; ivName$(d); " ("; LTRIM$(STR$(d)); " semitones)."
    END SELECT
    PRINT: PRINT " Press a key..."
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT FOR
  NEXT
  CLS
  PRINT
  PRINT " You scored"; score; "out of"; q - 1
  SELECT CASE score
    CASE 10: PRINT " Perfect pitch... nearly!"
    CASE 7 TO 9: PRINT " Great ears!"
    CASE 4 TO 6: PRINT " Good - keep practising."
    CASE ELSE: PRINT " Every musician starts somewhere!"
  END SELECT
  PRINT: PRINT " Press a key for the menu."
  k$ = INPUT$(1)
LOOP
CLS
PRINT "Goodbye!"
END

' GetKey$ waits for one of the allowed keys (upper case).
FUNCTION GetKey$ (allowed$)
  DO
    k$ = UCASE$(INPUT$(1))
  LOOP UNTIL INSTR(allowed$, k$) > 0
  GetKey$ = k$
END FUNCTION

' PlayN plays note number n% with length l$ ("4", "8" ...).
SUB PlayN (n%, l$)
  PLAY "L" + l$ + " N" + LTRIM$(STR$(n%))
END SUB
