' ============================================================
' TITLE:    Pachelbel's Canon over a Ground Bass
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, ground bass, chords, polyphony, arrays, classical
' SUMMARY:  The famous 8-chord ground bass of Pachelbel's Canon, with melody variations layered on top.
' ------------------------------------------------------------
' WHAT IT DOES
'   Johann Pachelbel's Canon in D (c. 1700, public domain) is built
'   on a "ground bass": the same eight bass notes repeated over
'   and over while the violins play ever-busier melodies above.
'   This program plays the bass alone, then adds three melody
'   variations on top. To get two notes "at once" from a speaker
'   that can only beep one tone, each sixteenth note is split
'   into two very short slices: one bass, one melody.
'
' HOW TO USE
'   Listen and watch the chord chart: the current chord lights up.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * What a ground bass and a chord progression are
'   * Filling arrays from (note, length) DATA on a time grid
'   * Two-voice "fake polyphony" with ML L32 slices
'   * Note numbers: +12 is one octave, +7 a fifth, +4 a major third
'
' THINGS TO TRY
'   * Write your own variation: any notes from the current chord
'     will sound good (e.g. D, F# or A over the D chord).
'   * Speed it up with a higher T value.
' ============================================================

CONST STEPS = 64             ' 8 chords x 8 sixteenth notes

' Bass line: one note per chord (each a half note = 8 sixteenths).
' Note numbers: N39 = D, N34 = A, N36 = B, N31 = F#, N32 = G, N27 = low D.
DATA 39, 34, 36, 31, 32, 27, 32, 34
' Chord names that go with each bass note.
DATA "D", "A", "Bm", "F#m", "G", "D", "G", "A"

' Melody variations: number of notes, then (note, length in 16ths).
' Variation 1: slow half notes stepping down - the first violin.
DATA 8, 67,8, 65,8, 63,8, 62,8, 60,8, 58,8, 60,8, 62,8
' Variation 2: the second violin's descending line.
DATA 8, 63,8, 62,8, 60,8, 58,8, 56,8, 55,8, 56,8, 53,8
' Variation 3: quarter notes that outline each chord.
DATA 16, 63,4, 67,4, 70,4, 68,4, 67,4, 63,4, 67,4, 65,4
DATA     63,4, 60,4, 63,4, 58,4, 56,4, 60,4, 58,4, 56,4

DIM bassN(7), chord$(7), mel(3, STEPS - 1)
FOR i = 0 TO 7: READ bassN(i): NEXT
FOR i = 0 TO 7: READ chord$(i): NEXT

' Expand each variation onto the 64-step grid. mel(v, s) holds
' the note sounding at step s in variation v (0 = silence).
' Variation 0 is left empty = bass alone.
FOR v = 1 TO 3
  READ cnt
  s = 0
  FOR i = 1 TO cnt
    READ nn, ln
    FOR k = 1 TO ln: mel(v, s) = nn: s = s + 1: NEXT
  NEXT
NEXT

CLS
COLOR 14: PRINT " PACHELBEL'S CANON - ground bass and variations": COLOR 7
PRINT " Esc = quit"
' Chord chart boxes.
FOR i = 0 TO 7
  LOCATE 5, 3 + i * 9: PRINT "+-------+"
  LOCATE 6, 3 + i * 9: PRINT "|"; SPACE$(7); "|"
  LOCATE 7, 3 + i * 9: PRINT "+-------+"
NEXT

PLAY "T76 ML"
DIM title$(3)
title$(0) = "Ground bass alone"
title$(1) = "+ Variation 1: first violin"
title$(2) = "+ Variation 2: second violin"
title$(3) = "+ Variation 3: arpeggios"

FOR v = 0 TO 3
  ' Play each variation twice, like the real piece repeats.
  FOR rep = 1 TO 2
    LOCATE 10, 3: PRINT title$(v); "  (time"; rep; "of 2)"; SPACE$(10)
    FOR s = 0 TO STEPS - 1
      c = s \ 8                         ' which chord we are in
      IF s MOD 8 = 0 THEN
        ' Light up the current chord, dim the others.
        FOR i = 0 TO 7
          IF i = c THEN COLOR 0, 14 ELSE COLOR 7, 0
          LOCATE 6, 4 + i * 9: PRINT LEFT$(" " + chord$(i) + SPACE$(7), 7);
        NEXT
        COLOR 7, 0
      END IF
      b$ = "N" + LTRIM$(STR$(bassN(c)))
      IF mel(v, s) = 0 THEN
        ' No melody: the bass takes the whole sixteenth.
        PLAY "L16 " + b$
      ELSE
        ' Two 32nd-note slices = one sixteenth. Bass, then melody.
        PLAY "L32 " + b$ + " N" + LTRIM$(STR$(mel(v, s)))
      END IF
      IF INKEY$ = CHR$(27) THEN EXIT FOR
    NEXT
    IF s < STEPS THEN EXIT FOR          ' Esc pressed: leave both loops
  NEXT
  IF s < STEPS THEN EXIT FOR
NEXT
PLAY "MN"
COLOR 7, 0
LOCATE 12, 3: PRINT "Fine."
END
