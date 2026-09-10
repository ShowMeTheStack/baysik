' ============================================================
' TITLE:    Frere Jacques Four-Voice Round
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, round, polyphony, arpeggio, arrays, folk
' SUMMARY:  Sings Frere Jacques as a 4-part round on a one-voice speaker by rapidly alternating the voices.
' ------------------------------------------------------------
' WHAT IT DOES
'   "Frere Jacques" is a traditional French round: the same
'   tune sung by several groups, each starting two bars after
'   the previous one. The PC speaker can only make ONE tone at a
'   time, so how can we hear four voices? We cheat, the way old
'   video games did: every eighth-note step is chopped into tiny
'   slices and each singing voice gets its own slice. Played fast
'   enough, your ear blends them into a chord.
'   The screen shows all four voices with a marker under the
'   note each one is singing.
'
' HOW TO USE
'   First the tune is played once alone, then the full round.
'   Esc stops at any time.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a melody on a time grid (one cell per eighth note)
'   * Offsetting the same array to make a round (canon)
'   * "Fake polyphony" by fast arpeggios: L8, L16, L24, L32
'   * PLAY "N" note numbers computed from semitone offsets
'
' THINGS TO TRY
'   * Make voices 3 and 4 sing an octave lower (subtract 12).
'   * Try "Row, Row, Row Your Boat" - it is a round too!
' ============================================================

CONST STEPS = 64          ' 8 bars x 8 eighth-notes
CONST GAP = 16            ' each voice enters 2 bars (16 eighths) later
CONST BASEN = 49          ' PLAY note number of the tune's "C"

DIM pitch(STEPS - 1)      ' semitone offset at each eighth-note step
DIM attack(STEPS - 1)     ' 1 if a new syllable starts on this step
DIM lyric$(STEPS - 1)

' The tune: four 1-bar phrases, each sung twice.
' Pairs are (semitone offset from C, length in eighth notes).
' -5 is the G below C.  Then the words for that bar.
DATA 0,2, 2,2, 4,2, 0,2, "Frere Jacques,"
DATA 4,2, 5,2, 7,4, "Dormez-vous?"
DATA 7,1, 9,1, 7,1, 5,1, 4,2, 0,2, "Sonnez les matines,"
DATA 0,2, -5,2, 0,4, "Ding, dang, dong."

' ---- Fill the time grid --------------------------------------
' Each phrase is read once into small temporary arrays (tp =
' pitches, tl = lengths) and then copied into the grid twice.
DIM tp(8), tl(8)
t = 0
FOR phrase = 1 TO 4
  cnt = 0: total = 0
  DO WHILE total < 8
    cnt = cnt + 1
    READ tp(cnt), tl(cnt)
    total = total + tl(cnt)
  LOOP
  READ w$
  FOR rep = 1 TO 2
    lyric$(t) = w$
    FOR i = 1 TO cnt
      FOR k = 0 TO tl(i) - 1
        pitch(t) = tp(i)
        IF k = 0 THEN attack(t) = 1
        t = t + 1
      NEXT
    NEXT
  NEXT
NEXT

CLS
COLOR 14: PRINT " FRERE JACQUES - a round in four voices": COLOR 7
PRINT " (traditional French)          Esc = stop"
LOCATE 4, 2: PRINT "First, the tune on its own..."
PLAY "T120 MN"
FOR s = 0 TO STEPS - 1
  IF lyric$(s) <> "" THEN LOCATE 6, 2: PRINT lyric$(s); SPACE$(20)
  IF attack(s) THEN
    ' Count how many steps this note lasts, play it as one note.
    ln = 1
    DO WHILE s + ln < STEPS
      IF attack(s + ln) THEN EXIT DO
      ln = ln + 1
    LOOP
    PLAY "L" + LTRIM$(STR$(8 \ ln)) + " N" + LTRIM$(STR$(BASEN + pitch(s)))
  END IF
  IF INKEY$ = CHR$(27) THEN END
NEXT

' ---- The round -----------------------------------------------
CLS
COLOR 14: PRINT " FRERE JACQUES - a round in four voices": COLOR 7
PRINT " Each voice starts two bars after the one above.   Esc = stop"
DIM n(4)
FOR s = 0 TO STEPS + 3 * GAP - 1
  voices = 0
  FOR v = 0 TO 3
    ps = s - v * GAP             ' where is voice v in the tune?
    row = 5 + v * 4
    IF ps >= 0 AND ps < STEPS THEN
      voices = voices + 1
      n(voices) = BASEN + pitch(ps)
      IF lyric$(ps) <> "" THEN
        LOCATE row, 2: COLOR 10 + v: PRINT "Voice"; v + 1; ": "; lyric$(ps); SPACE$(20)
      END IF
      ' Draw a little progress bar: one dot per step sung so far.
      LOCATE row + 1, 2: COLOR 8: PRINT STRING$(ps, 249);
      COLOR 15: PRINT CHR$(14 + attack(ps));
    ELSEIF ps >= STEPS THEN
      LOCATE row, 2: COLOR 8: PRINT "Voice"; v + 1; ": (finished)"; SPACE$(20)
    ELSE
      LOCATE row, 2: COLOR 8: PRINT "Voice"; v + 1; ": waiting..."
    END IF
  NEXT
  COLOR 7

  ' Fake polyphony: one eighth note shared by 'voices' slices.
  ' 1 voice -> L8, 2 -> L16, 3 -> L24, 4 -> L32. Every case adds
  ' up to exactly one eighth, so the beat stays steady.
  ' Legato (ML) so the slices join smoothly without gaps.
  m$ = "ML L" + LTRIM$(STR$(8 * voices))
  FOR i = 1 TO voices
    m$ = m$ + " N" + LTRIM$(STR$(n(i)))
  NEXT
  PLAY m$
  IF INKEY$ = CHR$(27) THEN EXIT FOR
NEXT
PLAY "MN"
LOCATE 22, 2: PRINT "Ding, dang, dong!  Press a key."
k$ = INPUT$(1)
END
