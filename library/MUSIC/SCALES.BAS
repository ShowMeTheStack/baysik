' ============================================================
' TITLE:    Scale Explorer
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, scales, music theory, modes, text graphics, arrays
' SUMMARY:  Explore 12 scales in any key on a text-mode piano: see the whole/half-step pattern and hear it played.
' ------------------------------------------------------------
' WHAT IT DOES
'   A scale is a recipe of steps. For example the major scale is
'   W W H W W W H (W = whole step = 2 semitones, H = half step).
'   Pick a key and a scale; the program marks its notes on a
'   drawn piano keyboard, prints the step recipe and the note
'   names, then plays it up and down while lighting each key.
'
' HOW TO USE
'   Left/Right arrows  change key (C, C#, D ...)
'   Up/Down arrows     change scale
'   Space or Enter     play the scale     Esc   quit
'
' CONCEPTS YOU WILL LEARN
'   * Scales stored as interval lists in DATA
'   * Turning intervals into step names (W, H, W+H)
'   * Drawing piano keys with box characters and COLOR
'   * MOD 12 arithmetic for wrapping around the octave
'
' THINGS TO TRY
'   * Add the Hungarian minor: 0 2 3 6 7 8 11.
'   * Play each scale in thirds (1-3, 2-4, 3-5 ...).
' ============================================================

DECLARE SUB DrawPiano (lit%)
DECLARE SUB ShowScale ()

' name, count, semitones above the root
DATA "Major (Ionian)", 7, 0,2,4,5,7,9,11
DATA "Natural minor (Aeolian)", 7, 0,2,3,5,7,8,10
DATA "Harmonic minor", 7, 0,2,3,5,7,8,11
DATA "Melodic minor (up)", 7, 0,2,3,5,7,9,11
DATA "Dorian", 7, 0,2,3,5,7,9,10
DATA "Phrygian", 7, 0,1,3,5,7,8,10
DATA "Lydian", 7, 0,2,4,6,7,9,11
DATA "Mixolydian", 7, 0,2,4,5,7,9,10
DATA "Major pentatonic", 5, 0,2,4,7,9
DATA "Minor pentatonic", 5, 0,3,5,7,10
DATA "Blues", 6, 0,3,5,6,7,10
DATA "Whole tone", 6, 0,2,4,6,8,10

CONST NSC = 12
DIM SHARED scName$(NSC), scN(NSC), scI(NSC, 7)
DIM SHARED key%, sc%, names$
names$ = "C C#D D#E F F#G G#A A#B "
FOR s = 1 TO NSC
  READ scName$(s), scN(s)
  FOR i = 1 TO scN(s): READ scI(s, i): NEXT
NEXT
key% = 0: sc% = 1

CLS
COLOR 14: PRINT " SCALE EXPLORER": COLOR 7
PRINT " Left/Right = key    Up/Down = scale    Space = play    Esc = quit"
ShowScale

DO
  k$ = INKEY$
  IF k$ <> "" THEN
    IF LEN(k$) = 2 THEN
      SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 75: key% = (key% + 11) MOD 12        ' Left: down a semitone
        CASE 77: key% = (key% + 1) MOD 12         ' Right: up a semitone
        CASE 72: sc% = sc% - 1: IF sc% < 1 THEN sc% = NSC
        CASE 80: sc% = sc% + 1: IF sc% > NSC THEN sc% = 1
      END SELECT
      ShowScale
    ELSEIF k$ = " " OR k$ = CHR$(13) THEN
      ' Play up, then down. N number: 37 = C in octave 3, so the
      ' root is 37 + key. Light each key while it sounds.
      PLAY "MN T160 L8"
      n = scN(sc%)
      FOR i = 1 TO n + 1 + n
        IF i <= n THEN
          s = scI(sc%, i)                   ' going up
        ELSEIF i = n + 1 THEN
          s = 12                            ' top: root an octave up
        ELSE
          s = scI(sc%, 2 * n + 2 - i)       ' coming back down
        END IF
        DrawPiano key% + s
        IF i = n + 1 THEN
          PLAY "L4 N" + LTRIM$(STR$(37 + key% + s)) + " L8"
        ELSE
          PLAY "N" + LTRIM$(STR$(37 + key% + s))
        END IF
      NEXT
      PLAY "L4 N" + LTRIM$(STR$(37 + key%))
      DrawPiano -1
    ELSEIF k$ = CHR$(27) THEN
      EXIT DO
    END IF
  END IF
LOOP
CLS
PRINT "Keep practising your scales!"
END

' DrawPiano draws 2 octaves (24 keys) starting at C. Scale notes
' are marked; the key whose number = lit% is shown lit up.
' Keys are numbered 0..23 counting semitones from the left C.
SUB DrawPiano (lit%)
  ' Which of the 24 keys belong to the scale?
  DIM inSc(23)
  FOR o = 0 TO 1
    FOR i = 1 TO scN(sc%)
      p = (key% + scI(sc%, i)) MOD 12 + o * 12
      inSc(p) = 1
    NEXT
  NEXT
  ' White keys are 3 columns wide. Black keys are drawn on the top
  ' rows between them. isBlack: pattern of black keys in an octave.
  black$ = "010100101010"
  x = 6: top = 6
  FOR p = 0 TO 23
    IF MID$(black$, p MOD 12 + 1, 1) = "0" THEN
      ' White key: three rows tall body + label row.
      IF p = lit% THEN
        COLOR 14, 6
      ELSEIF inSc(p) THEN
        COLOR 0, 11
      ELSE
        COLOR 0, 7
      END IF
      FOR r = top TO top + 5
        LOCATE r, x: PRINT "   ";
      NEXT
      LOCATE top + 5, x
      IF inSc(p) THEN PRINT " "; CHR$(4); " ";
      COLOR 7, 0: LOCATE top, x + 3: PRINT CHR$(179);
      FOR r = top + 1 TO top + 5: LOCATE r, x + 3: PRINT CHR$(179);: NEXT
      x = x + 4
    END IF
  NEXT
  ' Now draw black keys on top, centred on the line between whites.
  x = 6
  FOR p = 0 TO 23
    IF MID$(black$, p MOD 12 + 1, 1) = "1" THEN
      IF p = lit% THEN
        COLOR 14, 6
      ELSEIF inSc(p) THEN
        COLOR 11, 1
      ELSE
        COLOR 8, 0
      END IF
      FOR r = top TO top + 2
        LOCATE r, x - 2: PRINT CHR$(219); CHR$(219);
      NEXT
      IF inSc(p) THEN LOCATE top + 2, x - 2: PRINT CHR$(4); CHR$(4);
    ELSE
      x = x + 4
    END IF
  NEXT
  COLOR 7, 0
END SUB

SUB ShowScale
  LOCATE 4, 2: COLOR 15
  PRINT LEFT$("Key: " + RTRIM$(MID$(names$, key% * 2 + 1, 2)) + "   Scale: " + scName$(sc%) + SPACE$(60), 70)
  COLOR 7
  DrawPiano -1
  ' Note names.
  LOCATE 14, 2: PRINT "Notes: ";
  FOR i = 1 TO scN(sc%)
    PRINT RTRIM$(MID$(names$, ((key% + scI(sc%, i)) MOD 12) * 2 + 1, 2)); " ";
  NEXT
  PRINT SPACE$(30)
  ' Step recipe: gap between each note and the next.
  LOCATE 16, 2: PRINT "Steps: ";
  FOR i = 1 TO scN(sc%)
    IF i < scN(sc%) THEN g = scI(sc%, i + 1) - scI(sc%, i) ELSE g = 12 - scI(sc%, i)
    SELECT CASE g
      CASE 1: PRINT "H ";
      CASE 2: PRINT "W ";
      CASE 3: PRINT "W+H ";
      CASE ELSE: PRINT LTRIM$(STR$(g)); " ";
    END SELECT
  NEXT
  PRINT SPACE$(30)
  LOCATE 17, 2: PRINT "(W = whole step, 2 semitones; H = half step, 1 semitone)"
END SUB
