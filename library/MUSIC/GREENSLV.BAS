' ============================================================
' TITLE:    Greensleeves Visualizer
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, n command, graphics, screen 12, folk, data
' SUMMARY:  Plays the English folk tune Greensleeves using note NUMBERS and draws it as a coloured pitch graph.
' ------------------------------------------------------------
' WHAT IT DOES
'   Greensleeves is a traditional English tune from the 1500s.
'   Here the melody is stored as note NUMBERS (the PLAY "N"
'   command) plus a length for each note. As each note plays the
'   program draws a bar: its HEIGHT shows pitch and its WIDTH
'   shows how long it lasts, so you can see the shape of the
'   melody rise and fall. Vertical lines mark each measure.
'
' HOW TO USE
'   Watch and listen. Esc stops. Any key at the end quits.
'
' CONCEPTS YOU WILL LEARN
'   * PLAY "N n" - choose notes by number (12 numbers = 1 octave)
'   * Building a PLAY string from numbers with STR$ and LTRIM$
'   * Converting musical time (eighth notes) into pixels
'   * LINE ... ,BF filled boxes in SCREEN 12
'
' THINGS TO TRY
'   * Transpose the tune: add 2 to every note number in PlayNote.
'   * Draw circles instead of bars, or colour by note length.
' ============================================================

' DATA format: note number, length.  Length is a PLAY length
' string ("4." = dotted quarter).  Note -1 marks a bar line and
' note 0 ends the song.
' Some handy numbers: N58 = A (440 Hz), N61 = C, N68 = high G.
' One semitone = 1, one octave = 12.
DATA 58,4
DATA -1,0, 61,2, 63,4, -1,0, 65,4., 66,8, 65,4, -1,0, 63,2, 60,4, -1,0, 56,4., 58,8, 60,4
DATA -1,0, 61,2, 58,4, -1,0, 58,4., 57,8, 58,4, -1,0, 60,2, 57,4, -1,0, 53,2, 58,4
DATA -1,0, 61,2, 63,4, -1,0, 65,4., 66,8, 65,4, -1,0, 63,2, 60,4, -1,0, 56,4., 58,8, 60,4
DATA -1,0, 61,4., 60,8, 58,4, -1,0, 57,4., 55,8, 57,4, -1,0, 58,2., -1,0, 58,2.
DATA -1,0, 68,2., -1,0, 68,4., 67,8, 65,4, -1,0, 63,2, 60,4, -1,0, 56,4., 58,8, 60,4
DATA -1,0, 61,2, 58,4, -1,0, 58,4., 57,8, 58,4, -1,0, 60,2, 57,4, -1,0, 53,2.
DATA -1,0, 68,2., -1,0, 68,4., 67,8, 65,4, -1,0, 63,2, 60,4, -1,0, 56,4., 58,8, 60,4
DATA -1,0, 61,4., 60,8, 58,4, -1,0, 57,4., 55,8, 57,4, -1,0, 58,2., -1,0, 58,2.
DATA 0,0

SCREEN 12
CLS
COLOR 14
LOCATE 1, 2: PRINT "GREENSLEEVES  - traditional English, 16th century"
COLOR 7
LOCATE 2, 2: PRINT "bar height = pitch, bar width = length.   Esc = stop"

CONST PXPER8 = 10          ' pixels for one eighth note of time
CONST LOWN = 50            ' note number drawn at the bottom of a row
CONST STEPY = 5            ' pixels per semitone
x = 20: rowBase = 130      ' first row: notes sit on y = 130

PLAY "T110 MN"
DO
  READ n, l$
  IF n = 0 THEN EXIT DO

  IF n = -1 THEN
    ' A bar line: thin grey vertical line through the row.
    LINE (x - 1, rowBase - 90)-(x - 1, rowBase), 8
  ELSE
    ' ---- How many eighth notes long is this note? -----------
    ' Length "2" = half = 4 eighths, "4" = 2 eighths, "8" = 1.
    ' Each dot adds half of the base value again.
    bv = 8 / VAL(l$)
    eighths = bv
    IF RIGHT$(l$, 1) = "." THEN eighths = bv * 1.5
    w = eighths * PXPER8

    ' ---- Wrap to a new row when we run out of room -----------
    IF x + w > 630 THEN
      x = 20: rowBase = rowBase + 105
    END IF

    ' ---- Draw the bar ----------------------------------------
    ' Higher note number -> taller bar. COLOR cycles through the
    ' 12 pitch classes so every "A" has the same colour.
    h = (n - LOWN) * STEPY
    clr = 1 + (n MOD 12)
    IF clr = 8 THEN clr = 13     ' avoid dark grey (hard to see)
    LINE (x, rowBase - h)-(x + w - 2, rowBase), clr, BF
    LINE (x, rowBase - h)-(x + w - 2, rowBase), 15, B

    ' ---- Play it ---------------------------------------------
    ' Set the length with L, then name the note with N. A dot
    ' cannot go after L, so it goes after the note number:
    ' "4." becomes "L4 N58." = dotted quarter A.
    dot$ = ""
    IF RIGHT$(l$, 1) = "." THEN dot$ = "."
    PLAY "L" + LTRIM$(STR$(VAL(l$))) + " N" + LTRIM$(STR$(n)) + dot$
    x = x + w
  END IF
  IF INKEY$ = CHR$(27) THEN EXIT DO
LOOP

LOCATE 30, 2: PRINT "Press any key to quit.";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
END
