' ============================================================
' TITLE:    Fur Elise Piano Roll
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, beethoven, piano roll, text graphics, melody
' SUMMARY:  The famous opening of Beethoven's Fur Elise, drawn as a scrolling text-mode piano roll.
' ------------------------------------------------------------
' WHAT IT DOES
'   Plays the opening theme of "Fur Elise" (Beethoven, 1810,
'   public domain). Each note is drawn as a coloured block on a
'   "piano roll": higher notes appear higher up the screen, and
'   time runs from left to right, just like in music software.
'
' HOW TO USE
'   Watch and listen. Esc stops. The theme plays twice.
'
' CONCEPTS YOU WILL LEARN
'   * Turning a note name + octave into a number (semitones)
'   * Mapping that number to a screen row
'   * Parsing small strings with MID$, INSTR and VAL
'   * Text "graphics" using CHR$(219) block characters
'
' THINGS TO TRY
'   * Make longer notes draw longer blocks.
'   * Colour the notes by octave instead of by pitch class.
' ============================================================

DECLARE FUNCTION Semitone% (note$)

' Each item: octave digit + note name + length, e.g. "5E16".
' Kept in this compact form so we can both PLAY and DRAW it.
DATA 5E16,5D#16,5E16,5D#16,5E16,4B16,5D16,5C16,4A8,P16
DATA 4C16,4E16,4A16,4B8,P16,4E16,4G#16,4B16,5C8,P16
DATA 4E16,5E16,5D#16,5E16,5D#16,5E16,4B16,5D16,5C16,4A8,P16
DATA 4C16,4E16,4A16,4B8,P16,4E16,5C16,4B16,4A4,END

CLS
COLOR 14: PRINT " FUR ELISE  (Ludwig van Beethoven, 1810)": COLOR 7
LOCATE 25, 1: PRINT " Esc = stop";

' Draw note-name labels down the left edge. Row 22 = lowest
' note we use (C4), each row up = one semitone higher.
names$ = "C C#D D#E F F#G G#A A#B "
FOR s = 0 TO 17
  LOCATE 22 - s, 1
  PRINT MID$(names$, (s MOD 12) * 2 + 1, 2); "|";
NEXT

PLAY "T100 MN"
FOR pass = 1 TO 2
  RESTORE
  x = 4
  ' Clear the roll area for this pass.
  FOR r = 5 TO 22: LOCATE r, 4: PRINT SPACE$(76);: NEXT
  DO
    READ n$
    IF n$ = "END" THEN EXIT DO
    IF LEFT$(n$, 1) = "P" THEN
      PLAY n$                      ' a rest: just wait
      x = x + 1
    ELSE
      ov$ = LEFT$(n$, 1)          ' "5"
      body$ = MID$(n$, 2)          ' "D#16"
      ' Split body into pitch part (letters, #) and length part.
      p = 1
      DO WHILE p <= LEN(body$) AND VAL(MID$(body$, p, 1)) = 0 AND MID$(body$, p, 1) <> "0"
        p = p + 1
      LOOP
      pitch$ = LEFT$(body$, p - 1)
      ln$ = MID$(body$, p)
      ' Height on the roll = semitones above C4.
      s = (VAL(ov$) - 4) * 12 + Semitone%(pitch$)
      ' Longer notes draw wider blocks (16th = 1, 8th = 2, 4th = 4).
      w = 16 / VAL(ln$)
      IF x + w > 79 THEN x = 4
      COLOR 9 + (s MOD 6)
      LOCATE 22 - s, x: PRINT STRING$(w, 219);
      COLOR 7
      PLAY "O" + ov$ + pitch$ + ln$
      x = x + w
    END IF
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  LOOP
NEXT
LOCATE 24, 1: PRINT " The End.";
END

' Semitone%: "C"->0, "C#"->1, ..., "B"->11. Sharps add one,
' flats ("-") subtract one.
FUNCTION Semitone% (note$)
  v = INSTR("C D EF G A B", LEFT$(note$, 1)) - 1
  IF MID$(note$, 2, 1) = "#" OR MID$(note$, 2, 1) = "+" THEN v = v + 1
  IF MID$(note$, 2, 1) = "-" THEN v = v - 1
  Semitone% = v
END FUNCTION
