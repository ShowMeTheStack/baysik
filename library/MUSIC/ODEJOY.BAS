' ============================================================
' TITLE:    Ode to Joy Karaoke
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, melody, beethoven, lyrics, data, karaoke
' SUMMARY:  Beethoven's Ode to Joy played note by note while the lyric syllables light up karaoke-style.
' ------------------------------------------------------------
' WHAT IT DOES
'   Stores the melody of Beethoven's "Ode to Joy" (1824, public
'   domain) as pairs of (note, syllable) in DATA statements.
'   The program prints the words, then plays one note at a time,
'   highlighting the matching syllable as it sounds.
'
' HOW TO USE
'   Just watch and sing along! Press Esc to stop early.
'   At the end, choose to play it again faster.
'
' CONCEPTS YOU WILL LEARN
'   * Keeping music in DATA and reading it with READ
'   * Arrays of strings to remember positions on screen
'   * Playing one note per PLAY call so the screen can keep up
'   * RESTORE to read the same DATA again
'
' THINGS TO TRY
'   * Translate the lyrics into another language.
'   * Add a second verse with new DATA lines.
' ============================================================

' Each pair is: a PLAY note (with its length) and the syllable
' sung on it. "/" as a syllable means "start a new line".
' Lyrics are the English hymn "Joyful, Joyful" (Henry van Dyke,
' 1907, public domain).
DATA E4,Joy-,E4,ful,F4,joy-,G4,ful,G4,we,F4,a-,E4,dore,D4,thee
DATA C4,God,C4,of,D4,glo-,E4,ry,E4.,Lord,D8,of,D2,love,X,/
DATA E4,Hearts,E4,un-,F4,fold,G4,like,G4,"flowers",F4,be-,E4,fore,D4,thee
DATA C4,O-,C4,"p'ning",D4,to,E4,the,D4.,sun,C8,a-,C2,bove,X,/
DATA *,*

DIM nt$(100), sy$(100), row(100), col(100)

' ---- Load the song into arrays --------------------------------
' We also work out WHERE each syllable will be printed, so the
' highlight can jump straight to it later.
CLS
COLOR 14: PRINT "  ODE TO JOY  -  Ludwig van Beethoven, Symphony No. 9": COLOR 7
r = 4: c = 3: n = 0
DO
  READ a$, b$
  IF a$ = "*" THEN EXIT DO
  IF b$ = "/" THEN
    r = r + 2: c = 3          ' new lyric line, two rows lower
  ELSE
    n = n + 1
    nt$(n) = a$: sy$(n) = b$
    row(n) = r: col(n) = c
    c = c + LEN(b$) + 1       ' leave a space after each syllable
  END IF
LOOP

DO
  ' ---- Print all the words in dim grey -----------------------
  COLOR 8
  FOR i = 1 TO n: LOCATE row(i), col(i): PRINT sy$(i);: NEXT
  COLOR 7
  LOCATE 12, 3: PRINT "Esc = stop"

  ' ---- Sing! -------------------------------------------------
  ' Choose tempo; MN gives a small gap so repeated notes are
  ' heard separately ("Joy-ful" on two E's).
  PLAY "MN O4 T" + LTRIM$(STR$(tempo + 120))
  FOR i = 1 TO n
    ' Light up the current syllable in bright yellow...
    COLOR 14: LOCATE row(i), col(i): PRINT sy$(i);
    ' ...and show the note name underneath the title.
    COLOR 11: LOCATE 14, 3: PRINT "Note: "; nt$(i); "   ";
    PLAY nt$(i)
    ' ...then make it white to show it has been sung.
    COLOR 15: LOCATE row(i), col(i): PRINT sy$(i);
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  NEXT
  COLOR 7
  LOCATE 16, 3: INPUT "Again, a bit faster (Y/N)"; ans$
  LOCATE 16, 3: PRINT SPACE$(40)
  IF UCASE$(LEFT$(ans$, 1)) <> "Y" THEN EXIT DO
  tempo = tempo + 20
  IF tempo > 120 THEN tempo = 120   ' 120+120 = 240, under the 255 limit
LOOP
CLS
PRINT "Freude, schoner Gotterfunken!  Goodbye."
END
