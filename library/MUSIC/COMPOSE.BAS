' ============================================================
' TITLE:    Random Melody Composer
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, random, scales, composition, strings, algorithms
' SUMMARY:  Composes brand-new tunes from a chosen scale using a random walk, rhythm patterns and an A-A-B-A form.
' ------------------------------------------------------------
' WHAT IT DOES
'   Purely random notes sound like a cat on a piano. This program
'   uses a few simple rules that composers use, so the results
'   sound surprisingly musical:
'     1. Only notes from one SCALE are allowed.
'     2. The melody mostly moves by small steps (a "random walk").
'     3. Rhythms come from a short list of pleasant patterns.
'     4. Phrases are arranged in A A B A form, so ideas repeat.
'     5. The last note is always the "home" note (the tonic).
'   The finished tune is printed as a PLAY string you can copy
'   into your own programs.
'
' HOW TO USE
'   Choose a scale (1-5). The tune plays and its MML is shown.
'   Then: Space = play again, N = new tune, S = save to
'   TUNE.TXT, M = back to the scale menu, Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Scales as lists of semitone steps
'   * Random walks with weighted choices (RND)
'   * Building long strings piece by piece
'   * Musical form: repetition and contrast (A A B A)
'
' THINGS TO TRY
'   * Add your own rhythm patterns to the DATA.
'   * Make the B phrase use a different octave.
' ============================================================

DECLARE FUNCTION Phrase$ (startDeg%, endDeg%)
DECLARE FUNCTION DegNote$ (d%)

' Scales: name, number of notes, then semitones above the tonic.
DATA "Major (happy)", 7, 0,2,4,5,7,9,11
DATA "Natural minor (sad)", 7, 0,2,3,5,7,8,10
DATA "Pentatonic (folk/Asian)", 5, 0,2,4,7,9
DATA "Blues", 6, 0,3,5,6,7,10
DATA "Dorian (medieval)", 7, 0,2,3,5,7,9,10

' Rhythm patterns. Each adds up to one 4/4 bar (16 sixteenths).
' Numbers are PLAY lengths; "4." is a dotted quarter.
DATA "4 4 4 4", "8 8 4 4 4", "4. 8 4 4", "4 8 8 4 4", "8 8 8 8 4 4", "4 4 2"

DIM SHARED scName$(5), scLen(5), scSemi(5, 7), rhythm$(6), cur
FOR s = 1 TO 5
  READ scName$(s), scLen(s)
  FOR i = 1 TO scLen(s): READ scSemi(s, i): NEXT
NEXT
FOR i = 1 TO 6: READ rhythm$(i): NEXT
RANDOMIZE TIMER

DO
  ' ---------------- Scale menu ----------------
  CLS
  COLOR 14: PRINT "RANDOM MELODY COMPOSER": COLOR 7
  PRINT
  FOR s = 1 TO 5: PRINT s; ") "; scName$(s): NEXT
  PRINT "  Esc) Quit"
  PRINT
  PRINT "Choose a scale: ";
  DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
  IF k$ = CHR$(27) THEN EXIT DO
  cur = VAL(k$)
  IF cur >= 1 AND cur <= 5 THEN
    DO
      ' ---------------- Compose ----------------
      ' Degrees count scale notes: 1 = tonic, scLen+1 = tonic an
      ' octave higher, and so on. Phrase A starts and ends on the
      ' tonic; B wanders higher and ends on the 5th-ish degree to
      ' create tension before A returns.
      top = scLen(cur) + 1
      a$ = Phrase$(1, 1 + scLen(cur) \ 2)       ' A: ends "open"
      a2$ = Phrase$(1, 1)                       ' A': ends at home
      b$ = Phrase$((top), 1 + scLen(cur) \ 2 + 1)  ' B: starts high
      tune$ = "T" + LTRIM$(STR$(100 + INT(RND * 60))) + " " + a$ + a2$ + b$ + a2$
      DO
        CLS
        COLOR 14: PRINT "Scale: "; scName$(cur): COLOR 7
        PRINT
        PRINT "Form: A A' B A'"
        PRINT
        COLOR 10: PRINT "PLAY "; CHR$(34); tune$; CHR$(34): COLOR 7
        PRINT
        PRINT "Space=again  N=new tune  S=save  M=menu  Esc=quit"
        PLAY "MN"
        PLAY tune$
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        IF k$ = "S" THEN
          OPEN "TUNE.TXT" FOR APPEND AS #1
          PRINT #1, scName$(cur); ": "; tune$
          CLOSE #1
          PRINT "Saved (added to TUNE.TXT). Press a key."
          k$ = UCASE$(INPUT$(1))
        END IF
      LOOP WHILE k$ = " " OR k$ = "S"
      IF k$ <> "N" THEN EXIT DO
    LOOP
    IF k$ = CHR$(27) THEN EXIT DO
  END IF
LOOP
CLS
PRINT "Happy composing!"
END

' DegNote$ turns a scale degree into "O4 E" style text.
' Degree 1 = tonic C in octave 4. Every scLen degrees = 1 octave.
FUNCTION DegNote$ (d%)
  n = scLen(cur)
  o = 4 + (d% - 1) \ n                  ' which octave
  idx = (d% - 1) MOD n + 1              ' which note of the scale
  semi = scSemi(cur, idx)
  ' Name the semitone using sharps.
  nm$ = MID$("C C#D D#E F F#G G#A A#B ", semi * 2 + 1, 2)
  DegNote$ = "O" + LTRIM$(STR$(o)) + RTRIM$(nm$)
END FUNCTION

' Phrase$ writes a 2-bar phrase starting on degree startDeg% and
' finishing on endDeg%.
FUNCTION Phrase$ (startDeg%, endDeg%)
  p$ = ""
  d = startDeg%
  hi = scLen(cur) * 2                   ' stay within two octaves
  FOR bar = 1 TO 2
    r$ = rhythm$(INT(RND * 6) + 1)       ' pick a rhythm pattern
    ' Walk through the pattern's lengths (separated by spaces).
    r$ = r$ + " "
    DO WHILE LEN(LTRIM$(r$)) > 0
      r$ = LTRIM$(r$)
      sp = INSTR(r$, " ")
      ln$ = LEFT$(r$, sp - 1)
      r$ = MID$(r$, sp + 1)
      lastNote = (bar = 2 AND LEN(LTRIM$(r$)) = 0)
      IF lastNote THEN
        d = endDeg%                     ' force the planned ending
      ELSEIF NOT (bar = 1 AND p$ = "") THEN
        ' Random walk: mostly steps of 1, sometimes 2, rarely a leap.
        x = RND
        IF x < .35 THEN
          stp = 1
        ELSEIF x < .7 THEN
          stp = -1
        ELSEIF x < .85 THEN
          stp = 2 * SGN(RND - .5)
        ELSEIF x < .93 THEN
          stp = 0                      ' repeat the note
        ELSE
          stp = 4 * SGN(RND - .5)      ' an occasional leap
        END IF
        d = d + stp
        IF d < 1 THEN d = 2
        IF d > hi THEN d = hi - 1
      END IF
      ' Glue octave+note and length together, e.g. "O4E" + "4." ->
      ' "O4E4." (the dot goes after the length, never before).
      p$ = p$ + DegNote$((d)) + ln$ + " "
    LOOP
  NEXT
  Phrase$ = p$
END FUNCTION
