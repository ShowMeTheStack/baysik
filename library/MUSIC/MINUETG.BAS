' ============================================================
' TITLE:    Minuet in G - Live Controls
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, bach, petzold, tempo, articulation, transpose, inkey
' SUMMARY:  The Minuet in G from Anna Magdalena Bach's Notebook, with live keys to change tempo, style and octave.
' ------------------------------------------------------------
' WHAT IT DOES
'   Plays the first 16 bars of the well-known Minuet in G major
'   (BWV Anh. 114, by Christian Petzold, long credited to J. S.
'   Bach, 1725 - public domain) bar by bar. While it plays you
'   can change the tempo, the articulation (staccato / normal /
'   legato) and the octave, and hear the result straight away.
'   The current settings and the PLAY string for each bar are
'   shown on screen.
'
' HOW TO USE
'   +  / -   faster / slower          S N L   staccato/normal/legato
'   U  / D   octave up / down          R       restart from bar 1
'   Esc      quit
'   The minuet repeats until you press Esc.
'
' CONCEPTS YOU WILL LEARN
'   * Building a PLAY string from settings each time round a loop
'   * Relative octave moves with < and > inside each bar
'   * Reading live keys with INKEY$ between bars
'   * SELECT CASE for keyboard commands
'
' THINGS TO TRY
'   * Add a "swing" key that changes every 8 8 pair into 8. 16.
'   * Add the second half of the minuet (bars 17-32).
' ============================================================

' Each bar of the melody. Every bar starts by setting the octave
' it needs with O, written as a "relative" octave: we store 0
' for the home octave and add the user's shift when playing.
' Format: octave offset, then the notes.
DATA 1,"D4 < G8 A8 B8 > C8"
DATA 1,"D4 < G4 G4"
DATA 1,"E4 C8 D8 E8 F#8"
DATA 1,"G4 < G4 G4"
DATA 1,"C4 D8 C8 < B8 A8"
DATA 0,"B4 > C8 < B8 A8 G8"
DATA 0,"F#4 G8 A8 B8 G8"
DATA 0,"A2."
DATA 1,"D4 < G8 A8 B8 > C8"
DATA 1,"D4 < G4 G4"
DATA 1,"E4 C8 D8 E8 F#8"
DATA 1,"G4 < G4 G4"
DATA 1,"C4 D8 C8 < B8 A8"
DATA 0,"B4 > C8 < B8 A8 G8"
DATA 0,"A4 B8 A8 G8 F#8"
DATA 0,"G2."

CONST BARS = 16
DIM bOct(BARS), bNotes$(BARS)
FOR i = 1 TO BARS: READ bOct(i), bNotes$(i): NEXT

tempo = 132: style$ = "N": shift = 0
CLS
COLOR 14: PRINT " MINUET IN G  (Petzold / Bach Notebook, 1725)": COLOR 7
PRINT
PRINT " +/- tempo    S/N/L staccato/normal/legato"
PRINT " U/D octave   R restart    Esc quit"

bar = 1
DO
  ' ---- Build this bar's PLAY string --------------------------
  ' The home octave is 4 (the default octave). The bar's own
  ' offset and the user's shift are added to it.
  o = 4 + bOct(bar) + shift
  ' Notes inside a bar step < down one octave (and > back up),
  ' so keep o in 1..6 to stay inside the legal range 0..6.
  IF o < 1 THEN o = 1
  IF o > 6 THEN o = 6
  m$ = "T" + LTRIM$(STR$(tempo)) + " M" + style$ + " O" + LTRIM$(STR$(o)) + " " + bNotes$(bar)

  ' ---- Show status -------------------------------------------
  LOCATE 7, 2: PRINT USING "Bar ## of ##"; bar; BARS
  LOCATE 8, 2: PRINT "Tempo"; tempo; "  Style: ";
  SELECT CASE style$
    CASE "S": PRINT "staccato";
    CASE "N": PRINT "normal  ";
    CASE "L": PRINT "legato  ";
  END SELECT
  PRINT "   Octave shift:"; shift; "  "
  LOCATE 10, 2: COLOR 10: PRINT "PLAY "; CHR$(34); m$; CHR$(34); SPACE$(20): COLOR 7
  ' A progress bar of the 16 bars.
  LOCATE 12, 2
  FOR i = 1 TO BARS
    IF i = bar THEN COLOR 14 ELSE COLOR 8
    PRINT CHR$(219); " ";
  NEXT
  COLOR 7

  PLAY m$

  ' ---- Handle keys pressed during that bar -------------------
  ' INKEY$ returns "" if nothing was pressed. We loop to use up
  ' every key that arrived while the bar was playing.
  restart = 0
  DO
    k$ = UCASE$(INKEY$)
    SELECT CASE k$
      CASE "+", "=": tempo = tempo + 12: IF tempo > 255 THEN tempo = 255
      CASE "-", "_": tempo = tempo - 12: IF tempo < 32 THEN tempo = 32
      CASE "S", "N", "L": style$ = k$
      CASE "U": IF shift < 1 THEN shift = shift + 1
      CASE "D": IF shift > -2 THEN shift = shift - 1
      CASE "R": restart = 1
      CASE CHR$(27): EXIT DO
    END SELECT
  LOOP UNTIL k$ = ""
  IF k$ = CHR$(27) THEN EXIT DO

  bar = bar + 1
  IF bar > BARS OR restart THEN bar = 1
LOOP

LOCATE 14, 2: PRINT "Bravo!"
END
