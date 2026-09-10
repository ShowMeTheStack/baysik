' ============================================================
' TITLE:    Drum Rhythm Game
' CATEGORY: Music & Sound
' LEVEL:    Advanced
' TAGS:     game, rhythm, timer, sound, timing, arrays, text graphics
' SUMMARY:  Notes scroll toward a hit line on two drum lanes; tap F and J in time for Perfect and Good ratings.
' ------------------------------------------------------------
' WHAT IT DOES
'   A text-mode rhythm game in the style of arcade drum games.
'   Drum notes slide from the right towards the hit line on the
'   left. Press F for the low drum (top lane) and J for the high
'   drum (bottom lane) exactly as a note reaches the line.
'   Timing is measured with TIMER: within 0.07 s is PERFECT,
'   within 0.15 s is GOOD, otherwise it is a MISS. Your combo
'   (hits in a row) multiplies your score.
'
' HOW TO USE
'   F = low drum, J = high drum, Esc = quit.
'   A 4-beat count-in plays first so you can feel the tempo.
'
' CONCEPTS YOU WILL LEARN
'   * Game time from TIMER (seconds since midnight, with decimals)
'   * Turning "time until a note" into a screen position
'   * Judging accuracy with ABS(noteTime - now)
'   * Drawing a whole row at once from a string (no flicker)
'   * A song chart written as DATA strings
'
' THINGS TO TRY
'   * Change TEMPO, or the SPEED that notes travel across.
'   * Write your own chart: one 8-character string per bar.
' ============================================================

CONST TEMPO = 100                 ' beats (quarter notes) per minute
CONST SPEED = 30                  ' columns travelled per second
CONST HITX = 8                    ' screen column of the hit line
CONST WIDE = 70                   ' how many columns the lanes use
CONST PERFECT = .07, GOOD = .15   ' timing windows in seconds

' The chart: each string is one bar of eight eighth-notes.
'   F = low drum, J = high drum, B = both, . = nothing
DATA "F...F...", "F...F...", "F.J.F.J.", "F.J.F.J."
DATA "F.JJF.J.", "F.JJF.J.", "FJFJFJFJ", "F...B..."
DATA "F.J.F.J.", "FF.JF.J.", "F.J.FFJ.", "F.JJF.JJ"
DATA "FJ.JFJ.J", "FJFJFJJJ", "B.B.B.J.", "B......."
DATA "END"

' Load the chart into arrays: time (in seconds) and lane of
' every note. Lane 1 = F (low), lane 2 = J (high).
DIM nTime!(300), nLane(300), judged(300)
eighth! = 60 / TEMPO / 2            ' seconds per eighth note
lead! = 4 * 60 / TEMPO              ' 4-beat count-in before the music
n = 0: bar = 0
DO
  READ b$
  IF b$ = "END" THEN EXIT DO
  FOR i = 1 TO 8
    c$ = MID$(b$, i, 1)
    t! = lead! + (bar * 8 + i - 1) * eighth!
    IF c$ = "F" OR c$ = "B" THEN n = n + 1: nTime!(n) = t!: nLane(n) = 1
    IF c$ = "J" OR c$ = "B" THEN n = n + 1: nTime!(n) = t!: nLane(n) = 2
  NEXT
  bar = bar + 1
LOOP
songEnd! = lead! + bar * 8 * eighth! + 1

' ---- Screen layout ---------------------------------------------
CLS
COLOR 14: PRINT " DRUM RHYTHM GAME": COLOR 7
PRINT " F = low drum (top lane)    J = high drum (bottom lane)    Esc = quit"
DIM laneRow(2)                    ' screen row of each lane
laneRow(1) = 10: laneRow(2) = 14
FOR L = 1 TO 2
  LOCATE laneRow(L) - 1, 2: COLOR 8: PRINT STRING$(WIDE + 6, 196)
  LOCATE laneRow(L) + 1, 2: PRINT STRING$(WIDE + 6, 196)
NEXT
COLOR 7
LOCATE laneRow(1), 2: PRINT "F";
LOCATE laneRow(2), 2: PRINT "J";

score = 0: combo = 0: best = 0: perf = 0: goods = 0: miss = 0
t0! = TIMER
lastBeat = -1
DO
  ' ---- What time is it in the song? -------------------------
  now! = TIMER - t0!
  IF now! < 0 THEN now! = now! + 86400          ' passed midnight

  ' ---- Count-in clicks and beat ticks ------------------------
  beat = INT(now! / (eighth! * 2))
  IF beat <> lastBeat THEN
    lastBeat = beat
    IF beat < 4 THEN
      LOCATE 6, 30: COLOR 14: PRINT "Count-in: "; 4 - beat; " ": COLOR 7
      SOUND 1200, .4
    ELSE
      LOCATE 6, 30: PRINT SPACE$(20)
    END IF
  END IF

  ' ---- Build each lane as a string, then print it in one go --
  ' Position of a note = hit line + (seconds until it is due) *
  ' SPEED. A note due right now sits exactly on the hit line.
  FOR L = 1 TO 2
    row$ = STRING$(WIDE, " ")
    FOR i = 1 TO n
      IF nLane(i) = L AND judged(i) = 0 THEN
        x = INT((nTime!(i) - now!) * SPEED + .5)
        IF x >= 0 AND x < WIDE THEN MID$(row$, x + 1, 1) = "O"
      END IF
    NEXT
    LOCATE laneRow(L), HITX: COLOR 15: PRINT row$;
    LOCATE laneRow(L), HITX - 1: COLOR 12: PRINT "["; : LOCATE laneRow(L), HITX + 1: PRINT "]";
    COLOR 7
  NEXT

  ' ---- Notes that slipped past are misses --------------------
  FOR i = 1 TO n
    IF judged(i) = 0 AND now! - nTime!(i) > GOOD THEN
      judged(i) = 1: miss = miss + 1: combo = 0: msg$ = "MISS"
    END IF
  NEXT

  ' ---- Player input ------------------------------------------
  k$ = UCASE$(INKEY$)
  IF k$ = CHR$(27) THEN EXIT DO
  L = 0
  IF k$ = "F" THEN L = 1: SOUND 110, .5      ' low thud
  IF k$ = "J" THEN L = 2: SOUND 440, .5      ' higher tap
  IF L > 0 THEN
    ' Find the closest un-judged note in this lane.
    bestI = 0: bestD! = 99
    FOR i = 1 TO n
      IF nLane(i) = L AND judged(i) = 0 THEN
        d! = ABS(nTime!(i) - now!)
        IF d! < bestD! THEN bestD! = d!: bestI = i
      END IF
    NEXT
    IF bestI > 0 AND bestD! <= GOOD THEN
      judged(bestI) = 1
      combo = combo + 1
      IF combo > best THEN best = combo
      IF bestD! <= PERFECT THEN
        perf = perf + 1: msg$ = "PERFECT!": score = score + 100 * (1 + combo \ 10)
      ELSE
        goods = goods + 1: msg$ = "GOOD": score = score + 50 * (1 + combo \ 10)
      END IF
    ELSE
      msg$ = "too early": combo = 0
    END IF
  END IF

  ' ---- Status -------------------------------------------------
  LOCATE 18, 4: COLOR 11: PRINT LEFT$(msg$ + SPACE$(12), 12);
  COLOR 7: PRINT USING "Score ######   Combo ###   Perfect ###  Good ###  Miss ###"; score; combo; perf; goods; miss
LOOP UNTIL now! > songEnd!

LOCATE 21, 4: COLOR 14
total = perf + goods + miss
IF total = 0 THEN total = 1
PRINT USING "Final score ######.  Best combo ###.  Accuracy ###%"; score; best; (perf + goods) * 100 / total
COLOR 7
LOCATE 23, 4: PRINT "Press any key."
DO WHILE INKEY$ <> "": LOOP          ' throw away leftover keys
k$ = INPUT$(1)
END
