' ============================================================
' TITLE:    Frequency Sweep and Hearing Test
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     sound, frequency, logarithm, graphics, screen 12, hearing
' SUMMARY:  Sweeps a tone from 40 Hz to 15 kHz on a logarithmic scale while drawing it, and lets you mark where your hearing fades.
' ------------------------------------------------------------
' WHAT IT DOES
'   Plays a smoothly rising tone and draws its frequency on a
'   graph with a LOGARITHMIC axis (every doubling of frequency
'   takes the same width - just like octaves on a piano). The
'   musical note name nearest to the current frequency is shown.
'   Press Space when you can no longer hear the tone to mark your
'   upper hearing limit (it changes with age and with your
'   speakers!).
'
' HOW TO USE
'   Space = "I can't hear it any more" (marks the spot)
'   Esc   = stop.  At the end press any key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Linear vs logarithmic scales: LOG(f) / LOG(2) = octaves
'   * Converting a frequency to the nearest note name
'   * SOUND with tiny durations for a smooth glide
'   * Drawing graph axes and labels in SCREEN 12
'
' THINGS TO TRY
'   * Sweep downward instead to find your LOWEST audible pitch.
'   * Change STEPF to make the sweep faster or slower.
' ============================================================

DECLARE FUNCTION XOf! (f!)
DECLARE FUNCTION NoteOf$ (f!)

CONST FLO = 40, FHI = 15000      ' sweep range in Hz
CONST GX0 = 60, GX1 = 600        ' graph left and right in pixels
CONST GY = 300                   ' graph baseline
CONST STEPF = 1.006              ' multiply f by this each step

SCREEN 12
CLS
COLOR 14: LOCATE 2, 25: PRINT "FREQUENCY SWEEP & HEARING TEST"
COLOR 7: LOCATE 4, 8: PRINT "Space = I can't hear it any more      Esc = stop"

' ---- Axis with a tick at every octave of A (55, 110, 220 ...) ----
LINE (GX0, GY)-(GX1, GY), 7
f = 55
DO WHILE f <= FHI
  x = XOf!(f)
  LINE (x, GY - 5)-(x, GY + 5), 7
  ' Text columns are 8 pixels wide; centre the label under the tick.
  lab$ = LTRIM$(STR$(f))
  LOCATE GY \ 16 + 2, x \ 8 + 1 - LEN(lab$) \ 2: PRINT lab$;
  f = f * 2
LOOP
LOCATE GY \ 16 + 4, 30: PRINT "Hz (log scale)";

' ---- The sweep ----------------------------------------------
' Each step multiplies the frequency by STEPF, so the pitch rises
' by the same musical interval each time (exponential growth).
f = FLO: marked = 0
DO WHILE f <= FHI
  x = XOf!(f)
  ' The curve: height grows with log2(f), giving a straight line
  ' on this log-scaled graph.
  y = GY - 20 - (LOG(f / FLO) / LOG(2)) * 16
  PSET (x, y), 10
  LINE (x, GY - 1)-(x, y + 2), 1      ' fill under the curve
  LOCATE 6, 8: PRINT USING "Frequency: ##### Hz   nearest note: "; f;
  PRINT NoteOf$(f); "   ";
  SOUND f, .3
  k$ = INKEY$
  IF k$ = CHR$(27) THEN EXIT DO
  IF k$ = " " AND marked = 0 THEN
    marked = -1
    LINE (x, 120)-(x, GY), 12
    LOCATE 8, 8: COLOR 12
    PRINT USING "Your upper limit: about ##### Hz"; f
    COLOR 7
  END IF
  f = f * STEPF
LOOP
SOUND 32767, 1
LOCATE 26, 8: PRINT "Most young people hear up to ~17000 Hz; it falls with age.";
LOCATE 28, 8: PRINT "Press any key.";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
END

' NoteOf$: frequency -> nearest note name + octave.
' Semitones from A440 = 12 * log2(f / 440). Round to nearest whole
' semitone, then convert to note letter and octave number.
FUNCTION NoteOf$ (f!)
  s = INT(12 * LOG(f! / 440) / LOG(2) + .5) + 57   ' 57 = A4 counted from C0
  nm$ = MID$("C C#D D#E F F#G G#A A#B ", (s MOD 12) * 2 + 1, 2)
  NoteOf$ = RTRIM$(nm$) + LTRIM$(STR$(s \ 12))
END FUNCTION

' XOf!: frequency -> pixel column using a log scale.
FUNCTION XOf! (f!)
  XOf! = GX0 + (GX1 - GX0) * LOG(f! / FLO) / LOG(FHI / FLO)
END FUNCTION
