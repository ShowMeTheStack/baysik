' ============================================================
' TITLE:    PLAY Lesson 3: Articulation and Background Music
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, mml, staccato, legato, background, mb, mf
' SUMMARY:  Hear the difference between MS, MN and ML, then make music play in the background with MB.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 plays one phrase three ways: staccato (short and
'   bouncy), normal, and legato (smooth, joined up).
'   Part 2 shows foreground vs. background music. With MF the
'   program stops and waits for the music. With MB the music is
'   queued and your program keeps running - here a ball bounces
'   across the screen while the tune plays.
'
' HOW TO USE
'   Press a key between parts. Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * MS (staccato, note sounds 3/4 of its time)
'   * MN (normal, 7/8 of its time) and ML (legato, full time)
'   * MF (foreground, the default) vs MB (background)
'   * PLAY(0) - how many notes are still waiting in the queue
'
' THINGS TO TRY
'   * Use MS for a march and ML for a lullaby.
'   * Watch PLAY(0) count down - what is the largest value you see?
' ============================================================

CLS
COLOR 14: PRINT "PLAY LESSON 3 - ARTICULATION AND BACKGROUND MUSIC": COLOR 7
PRINT
phrase$ = "O4 L8 C D E F G4 G4 A A A A G2"

' ---------- Part 1: articulation ----------
' Every note has a "time slot". The M commands decide how much
' of that slot is filled with sound; the rest is a tiny silence.
'   MS  = 3/4 sound + 1/4 silence (detached, "staccato")
'   MN  = 7/8 sound + 1/8 silence (the default)
'   ML  = all sound, no gap         (joined up, "legato")
PRINT "The same phrase three ways:"
PRINT
PRINT "  MS  staccato  ";: PLAY "T140 MS" + phrase$: PRINT "  short and bouncy"
PRINT "  MN  normal    ";: PLAY "MN" + phrase$: PRINT "  the default"
PRINT "  ML  legato    ";: PLAY "ML" + phrase$: PRINT "  smooth, notes touch"
PLAY "MN"
PRINT
PRINT "Press a key for Part 2 (Esc quits)."
IF INPUT$(1) = CHR$(27) THEN END

' ---------- Part 2: foreground ----------
CLS
PRINT "FOREGROUND (MF): the program waits while music plays."
PRINT "Watch: the counter below can't move until the tune ends."
PLAY "MF T150 O4 L8 E E F G G F E D C C D E E4. D D2"
FOR i = 1 TO 5: PRINT i;: NEXT
PRINT " <- printed only after the music finished"
PRINT
PRINT "Press a key for background music (Esc quits)."
IF INPUT$(1) = CHR$(27) THEN END

' ---------- Part 3: background ----------
' MB puts the notes into a queue (QBasic holds up to 32) and
' returns immediately. We animate a ball while it plays and
' show PLAY(0), the number of notes still waiting.
CLS
PRINT "BACKGROUND (MB): the ball moves WHILE the tune plays."
PRINT "Press Esc to stop."
PLAY "MB T150 O4 L8 E E F G G F E D C C D E D4. C C2"
PLAY "MB D D E C D E16 F16 E C D E16 F16 E D C D < G4 >"
x = 1: dx = 1
DO
  LOCATE 5, 1: PRINT USING "Notes left in queue: ##"; PLAY(0)
  LOCATE 8, x: PRINT " O ";    ' draw ball (spaces erase its trail)
  x = x + dx
  IF x >= 76 OR x <= 1 THEN dx = -dx
  t = TIMER: DO WHILE TIMER - t < .04 AND TIMER >= t: LOOP
  k$ = INKEY$
  IF k$ = CHR$(27) THEN EXIT DO
LOOP UNTIL PLAY(0) = 0
LOCATE 10, 1
PRINT "Music finished (or stopped). Back to foreground mode."
PLAY "MF"
END
