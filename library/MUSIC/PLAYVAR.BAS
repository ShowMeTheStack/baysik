' ============================================================
' TITLE:    PLAY Subroutines with X and VARPTR$
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, varptr$, mml, substrings, blues, variables
' SUMMARY:  Uses PLAY "X" + VARPTR$ to call musical "subroutines" and "=" to read tempo and octave from variables, building a 12-bar boogie.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Music Macro Language has its own way to reuse pieces of
'   music: "X" + VARPTR$(a$) plays the string a$ as if it were
'   written right there - a bit like GOSUB for music. And the
'   "=" form, e.g. "T=" + VARPTR$(t%), reads a NUMBER from a
'   variable. These come from GW-BASIC on old PCs (they also
'   work in QBasic) and you will find them in many old programs.
'   We build a 12-bar boogie-woogie bass line out of three
'   small riffs, then play it again faster and higher.
'
' HOW TO USE
'   Watch the chord chart as the blues plays. Esc stops between
'   bars. Each chorus is faster than the last.
'
' CONCEPTS YOU WILL LEARN
'   * PLAY "X" + VARPTR$(riff$) - "call" a sub-string of music
'   * PLAY "T=" + VARPTR$(t%) + ";" - numbers from variables
'   * The 12-bar blues chord pattern (I I I I IV IV I I V IV I V)
'   * Why plain string joining (riff$ + riff$) does the same job
'
' THINGS TO TRY
'   * Write a different riff (try "C E- E G A G E- E").
'   * Use "O=" + VARPTR$(o%) to play a chorus an octave lower.
' ============================================================

' The three riffs. Each is one bar of eighth notes walking up
' and down the chord: root, 3rd, 5th, 6th, flat 7th, 6th, 5th, 3rd.
riffC$ = "C E G A B- A G E"
riffF$ = "F A > C D E- D C < A"
riffG$ = "G B > D E F E D < B"

' The 12-bar form: which riff to use in each bar.
DATA C, C, C, C, F, F, C, C, G, F, C, G
DIM bar$(12)
FOR i = 1 TO 12: READ bar$(i): NEXT

CLS
COLOR 14: PRINT " 12-BAR BOOGIE WITH PLAY X AND VARPTR$": COLOR 7
PRINT
PRINT " riffC$ = "; CHR$(34); riffC$; CHR$(34)
PRINT " riffF$ = "; CHR$(34); riffF$; CHR$(34)
PRINT " riffG$ = "; CHR$(34); riffG$; CHR$(34)
PRINT
PRINT " Each bar is played with:  PLAY "; CHR$(34); "X"; CHR$(34); " + VARPTR$(riffC$)"
PRINT " Tempo and octave come from variables:"
PRINT "   PLAY "; CHR$(34); "T="; CHR$(34); " + VARPTR$(tempo%) + "; CHR$(34); ";O="; CHR$(34); " + VARPTR$(oct%) + "; CHR$(34); ";"; CHR$(34)

tempo% = 110
oct% = 2
FOR chorus = 1 TO 3
  ' Read the tempo and octave out of the variables. The ";"
  ' after each VARPTR$ marks the end of the variable reference.
  PLAY "MS L8 T=" + VARPTR$(tempo%) + ";O=" + VARPTR$(oct%) + ";"
  LOCATE 13, 2
  PRINT USING "Chorus #   tempo% = ###   oct% = #"; chorus; tempo%; oct%

  FOR b = 1 TO 12
    ' Draw the 12-bar chord chart, 4 bars per line.
    FOR j = 1 TO 12
      LOCATE 15 + (j - 1) \ 4, 4 + ((j - 1) MOD 4) * 8
      IF j = b THEN COLOR 0, 14 ELSE COLOR 7, 0
      PRINT " "; bar$(j); "7  ";
    NEXT
    COLOR 7, 0

    ' "Call" the right riff. X + VARPTR$ is like GOSUB: PLAY runs
    ' the other string, then continues after it.
    SELECT CASE bar$(b)
      CASE "C": PLAY "X" + VARPTR$(riffC$)
      CASE "F": PLAY "X" + VARPTR$(riffF$)
      CASE "G": PLAY "X" + VARPTR$(riffG$)
    END SELECT
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  NEXT
  IF b <= 12 THEN EXIT FOR      ' Esc was pressed
  ' End each chorus on a long low C, then speed up and go higher.
  PLAY "C4 P4"
  tempo% = tempo% + 40
  oct% = oct% + 1
NEXT

' The same thing with ordinary string joining, for comparison:
' this builds the whole 12-bar line as ONE string first.
LOCATE 20, 2: PRINT "Finally, the same line built with + instead of X..."
whole$ = "MN T150 O3 L8 "
FOR b = 1 TO 12
  SELECT CASE bar$(b)
    CASE "C": whole$ = whole$ + riffC$ + " "
    CASE "F": whole$ = whole$ + riffF$ + " "
    CASE "G": whole$ = whole$ + riffG$ + " "
  END SELECT
NEXT
PLAY whole$ + "C2"
LOCATE 22, 2: PRINT "Same music - X just saves memory and typing. Done!"
END
