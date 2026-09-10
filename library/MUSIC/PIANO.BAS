' ============================================================
' TITLE:    Computer Keyboard Piano
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     sound, piano, keyboard, graphics, screen 12, frequency, recording
' SUMMARY:  Play a drawn piano with your computer keys, change octaves, and record and replay your tunes.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a 17-key piano (ten white keys, seven black) in
'   SCREEN 12. The middle row of your keyboard plays the white
'   keys and the row above plays the black keys, laid out just
'   like a real piano. Pressed keys light up. You can also record
'   what you play and hear it back.
'
' HOW TO USE
'   White keys:  A S D F G H J K L ;     (C D E F G A B C D E)
'   Black keys:   W E   T Y U   O P      (C# D#  F# G# A#  C# D#)
'   Z / X  octave down / up      R  start/stop recording
'   P      play back recording   Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * The equal-temperament formula: f = 440 * 2 ^ (n / 12)
'   * SOUND frequency, duration for instant notes
'   * Drawing and highlighting a keyboard with LINE ,BF
'   * INSTR as a quick "which key was that?" lookup
'   * Recording events with timestamps from TIMER
'
' THINGS TO TRY
'   * Add more keys (Q for the B below middle C?).
'   * Save the recording to a file and load it next time.
' ============================================================

DECLARE SUB DrawKey (idx, lit)
DECLARE FUNCTION Freq! (semi)

' Key maps. whiteKeys$ position i -> white key i (0-based).
' blackKeys$ uses "." for gaps where a piano has no black key
' (between E-F and B-C).
DIM SHARED whiteKeys$, blackKeys$, octave%
whiteKeys$ = "ASDFGHJKL;"
blackKeys$ = "WE.TYU.OP"
' Semitone of each white key above C: C D E F G A B C D E
DIM SHARED whiteSemi(9)
FOR i = 0 TO 9: READ whiteSemi(i): NEXT
DATA 0, 2, 4, 5, 7, 9, 11, 12, 14, 16

CONST KX = 70, KY = 180, KW = 50, KH = 200   ' piano position & key size
octave% = 4

' Recording storage: semitone and the time it was played.
DIM recSemi(500), recTime!(500)
recCount = 0: recording = 0

SCREEN 12
CLS
COLOR 14: LOCATE 2, 28: PRINT "COMPUTER KEYBOARD PIANO"
COLOR 7
LOCATE 4, 10: PRINT "White: A S D F G H J K L ;    Black: W E T Y U O P"
LOCATE 5, 10: PRINT "Z/X octave   R record   P playback   Esc quit"
FOR i = 0 TO 9: DrawKey i, 0: NEXT          ' white keys first...
FOR i = 0 TO 8: DrawKey 100 + i, 0: NEXT    ' ...then black keys on top

DO
  LOCATE 8, 10: PRINT USING "Octave: #   "; octave%;
  IF recording THEN COLOR 12: PRINT "* RECORDING *  "; ELSE PRINT "               ";
  COLOR 7: PRINT USING "Notes recorded: ###"; recCount

  k$ = UCASE$(INKEY$)
  IF k$ = "" THEN
    ' Nothing pressed - nothing to do this time round.
  ELSEIF k$ = CHR$(27) THEN
    EXIT DO
  ELSEIF k$ = "Z" THEN
    IF octave% > 2 THEN octave% = octave% - 1
  ELSEIF k$ = "X" THEN
    IF octave% < 6 THEN octave% = octave% + 1
  ELSEIF k$ = "R" THEN
    recording = NOT recording
    IF recording THEN recCount = 0: recStart! = TIMER
  ELSEIF k$ = "P" THEN
    ' ---- Playback ---------------------------------------------
    ' Wait until each note's recorded time, then play it.
    recording = 0
    t0! = TIMER
    FOR i = 1 TO recCount
      DO
        IF INKEY$ = CHR$(27) THEN EXIT FOR
        el! = TIMER - t0!
        IF el! < 0 THEN el! = el! + 86400
      LOOP UNTIL el! >= recTime!(i)
      SOUND Freq!(recSemi(i)), 3
    NEXT
  ELSE
    ' ---- Is it a piano key? -----------------------------------
    w = INSTR(whiteKeys$, k$)
    b = INSTR(blackKeys$, k$)
    IF k$ = "." THEN b = 0           ' "." is only a gap marker
    semi = -1
    IF w > 0 THEN semi = whiteSemi(w - 1): idx = w - 1
    IF b > 0 THEN
      ' Black key b sits just right of white key b-1, so its
      ' semitone is that white key's semitone + 1.
      semi = whiteSemi(b - 1) + 1: idx = 100 + b - 1
    END IF
    IF semi >= 0 THEN
      ' Store absolute semitones from C0 so playback keeps the
      ' octave that was used when recording.
      an = octave% * 12 + semi
      IF recording AND recCount < 500 THEN
        recCount = recCount + 1
        recSemi(recCount) = an
        el! = TIMER - recStart!
        IF el! < 0 THEN el! = el! + 86400
        recTime!(recCount) = el!
      END IF
      DrawKey idx, 1
      SOUND Freq!(an), 3         ' 3 ticks = about 1/6 second
      DrawKey idx, 0
      IF idx >= 100 THEN
        ' Redrawing a black key is enough. Redrawing a white key
        ' would cover the black keys, so redraw those after.
      ELSE
        FOR i = 0 TO 8: DrawKey 100 + i, 0: NEXT
      END IF
    END IF
  END IF
LOOP
SCREEN 0: WIDTH 80
PRINT "Thanks for playing!"
END

' DrawKey: idx 0-9 = white key, 100-108 = black key.
' lit = 1 draws it highlighted (yellow).
SUB DrawKey (idx, lit)
  IF idx < 100 THEN
    x = KX + idx * KW
    IF lit THEN c = 14 ELSE c = 15
    LINE (x, KY)-(x + KW - 2, KY + KH), c, BF
    LINE (x, KY)-(x + KW - 2, KY + KH), 8, B
    ' Label each key with the computer key that plays it.
    COLOR 0
    LOCATE (KY + KH - 20) \ 16, (x + KW \ 2) \ 8
    COLOR 9: PRINT MID$(whiteKeys$, idx + 1, 1);
  ELSE
    b = idx - 100
    IF MID$(blackKeys$, b + 1, 1) = "." THEN EXIT SUB   ' no key here
    ' Black keys straddle the line between two white keys.
    x = KX + (b + 1) * KW - 16
    IF lit THEN c = 14 ELSE c = 0
    LINE (x, KY)-(x + 30, KY + KH * .6), c, BF
    LINE (x, KY)-(x + 30, KY + KH * .6), 7, B
  END IF
  COLOR 7
END SUB

' Freq!: semitones counted from C in octave 0 -> Hertz.
' A in octave 4 (semitone 57) is 440 Hz; every 12 semitones
' doubles the frequency, so each semitone multiplies by 2^(1/12).
FUNCTION Freq! (semi)
  Freq! = 440 * 2 ^ ((semi - 57) / 12)
END FUNCTION
