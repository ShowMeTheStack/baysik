' ============================================================
' TITLE:    ON PLAY Jukebox (Background Music Queue)
' CATEGORY: Music & Sound
' LEVEL:    Advanced
' TAGS:     on play, events, background music, mb, queue, animation
' SUMMARY:  A never-ending background jukebox: ON PLAY(n) refills the music queue while the main loop animates.
' ------------------------------------------------------------
' WHAT IT DOES
'   Games need music that plays forever while the game runs.
'   QBasic's background music (MB) queue only holds about 32
'   notes, so a long song must be fed in pieces. ON PLAY(n)
'   GOSUB does this automatically: whenever the number of notes
'   left in the queue drops BELOW n, QBasic calls our handler,
'   which adds the next phrase. The main program never has to
'   think about the music at all - here it just animates a
'   jukebox display with a queue meter.
'
' HOW TO USE
'   N = skip to next song    Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * ON PLAY(n) GOSUB, PLAY ON / PLAY OFF
'   * PLAY(0): how many notes are waiting in the queue
'   * A playlist stored as an array of phrase strings
'   * Separating "what the program does" from "the music"
'
' THINGS TO TRY
'   * Try ON PLAY(1) and ON PLAY(10) - what changes?
'   * Add a third song to the DATA (end each song with "*").
' ============================================================

' Playlist: song title, then phrases, ending with "*".
' "**" marks the end of the whole list.
DATA "Yankee Doodle (traditional)"
DATA "T150 O4 L8 CCDE CED<G>", "CCDE C4<B4>", "CCDE FEDC", "<BGAB> C4C4"
DATA "F8.G16F8E8 F8G8A4", "E8.F16E8D8 C4E4", "F8.G16F8E8 F8G8A8F8", "E8C8D8<G8> C4C4", "*"
DATA "Oh! Susanna (Stephen Foster, 1848)"
DATA "T140 O4 L4 C8D8 EGG.A8", "GEC.D8 EEDC", "D2.C8D8 EGG.A8", "GEC.D8 EEDD C2."
DATA "F2F2 AA2A", "GGEC D2.C8D8", "EGG.A8 GEC.D8", "EEDD C2.", "*"
DATA "**"

DIM SHARED phr$(60), songOf(60), title$(10)
nPhr = 0: nSong = 0
DO
  READ t$
  IF t$ = "**" THEN EXIT DO
  nSong = nSong + 1: title$(nSong) = t$
  DO
    READ p$
    IF p$ = "*" THEN EXIT DO
    nPhr = nPhr + 1: phr$(nPhr) = p$: songOf(nPhr) = nSong
  LOOP
LOOP

CLS
COLOR 14: PRINT " ON PLAY JUKEBOX": COLOR 7
PRINT " N = next song    Esc = quit"
' Draw the jukebox cabinet.
COLOR 6
LOCATE 4, 20: PRINT CHR$(201); STRING$(38, 205); CHR$(187)
FOR r = 5 TO 15: LOCATE r, 20: PRINT CHR$(186); SPACE$(38); CHR$(186): NEXT
LOCATE 16, 20: PRINT CHR$(200); STRING$(38, 205); CHR$(188)
COLOR 7

' ---- Start the music engine ------------------------------------
nextP = 1
PLAY "MB"                    ' background mode for everything after
ON PLAY(4) GOSUB Refill      ' call Refill when fewer than 4 notes remain
PLAY ON
GOSUB Refill                 ' queue the first two phrases ourselves
GOSUB Refill

RANDOMIZE TIMER
DIM lvl(8)
DO
  ' ---- Now playing --------------------------------------------
  LOCATE 6, 22: COLOR 15: PRINT "Now playing:"; SPACE$(20)
  LOCATE 7, 22: COLOR 11: PRINT LEFT$(title$(curSong) + SPACE$(36), 36)

  ' ---- Queue meter: one block per waiting note ---------------
  q = PLAY(0)
  IF q > 30 THEN q = 30          ' the meter only has room for 30
  LOCATE 9, 22: COLOR 7: PRINT "Queue:";
  COLOR 10: PRINT STRING$(q, 254); : COLOR 8: PRINT STRING$(30 - q, 250);
  COLOR 7: LOCATE 10, 22: PRINT USING "## notes waiting, refills: ####"; q; refills

  ' ---- Fake "equalizer" bars, just for fun ------------------
  FOR b = 1 TO 8
    lvl(b) = lvl(b) + INT(RND * 3) - 1
    IF lvl(b) < 0 THEN lvl(b) = 0
    IF lvl(b) > 3 THEN lvl(b) = 3
    FOR h = 0 TO 3
      LOCATE 14 - h, 24 + b * 3
      IF h <= lvl(b) THEN COLOR 9 + h: PRINT CHR$(219); CHR$(219); ELSE PRINT "  ";
    NEXT
  NEXT
  COLOR 7

  k$ = UCASE$(INKEY$)
  IF k$ = CHR$(27) THEN EXIT DO
  IF k$ = "N" THEN
    ' Jump nextP to the first phrase of the following song. The
    ' notes already queued still finish - just like a real queue.
    s = songOf(nextP)
    DO WHILE songOf(nextP) = s
      nextP = nextP + 1: IF nextP > nPhr THEN nextP = 1: EXIT DO
    LOOP
  END IF
  w! = TIMER: DO WHILE TIMER - w! < .05 AND TIMER >= w!: LOOP
LOOP
PLAY OFF                      ' stop calling Refill
PLAY "MF"
LOCATE 18, 20: PRINT "The jukebox goes quiet. Goodbye!"
END

' ------------------------------------------------------------
' Refill: event handler. Adds the next phrase to the queue and
' moves along the playlist, wrapping back to the first song.
' ------------------------------------------------------------
Refill:
  PLAY phr$(nextP)
  curSong = songOf(nextP)
  refills = refills + 1
  nextP = nextP + 1
  IF nextP > nPhr THEN nextP = 1
RETURN
