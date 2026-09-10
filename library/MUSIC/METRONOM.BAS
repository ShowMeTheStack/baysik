' ============================================================
' TITLE:    ON TIMER Metronome
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     on timer, events, play, background music, rhythm, gosub
' SUMMARY:  A metronome driven by ON TIMER events: accented downbeats, 2-6 beats per bar and a swinging pendulum.
' ------------------------------------------------------------
' WHAT IT DOES
'   Clicks a steady beat for practising music. Instead of a
'   busy loop counting time, it uses an EVENT: ON TIMER(1)
'   GOSUB makes QBasic jump to a handler once every second, no
'   matter what the main program is doing.
'   ON TIMER only works in whole seconds, so how do we get
'   tempos faster than 60 beats per minute? Each second the
'   handler queues one second's worth of clicks as BACKGROUND
'   music (PLAY "MB ..."): 1 click at 60 BPM, 2 at 120, 3 at 180
'   and 4 at 240. The first beat of each bar is a higher click.
'
' HOW TO USE
'   1 2 3 4   tempo 60 / 120 / 180 / 240 BPM
'   B         change beats per bar (2, 3, 4 or 6)
'   Space     pause / resume          Esc   quit
'
' CONCEPTS YOU WILL LEARN
'   * ON TIMER(n) GOSUB, TIMER ON / TIMER STOP / TIMER OFF
'   * Event handlers that end with RETURN
'   * Background music (MB) as a precise clock
'   * Animating a pendulum with SIN while the events run
'
' THINGS TO TRY
'   * Add 90 BPM: 3 clicks every 2 seconds (ON TIMER(2)).
'   * Make the off-beats (the "and"s) tick softly at a lower pitch.
' ============================================================

bps = 2                         ' beats per second: 2 -> 120 BPM
perBar = 4                      ' beats in each bar
beat = 0                        ' beats counted since the start
running = -1

CLS
COLOR 14: PRINT " ON TIMER METRONOME": COLOR 7
PRINT
PRINT " 1-4 = 60/120/180/240 BPM    B = beats per bar    Space = pause    Esc = quit"

' Install the event handler, then switch the event on.
ON TIMER(1) GOSUB Tick
TIMER ON
lastTick! = TIMER
GOSUB Tick                      ' start clicking right away

DO
  ' ---- Status line ------------------------------------------
  LOCATE 5, 2
  PRINT USING "Tempo: ### BPM   Time signature: #/4   "; bps * 60; perBar;
  IF running THEN PRINT "        " ELSE PRINT "PAUSED  "

  ' ---- Which beat are we on right now? -----------------------
  ' The handler records when the current second started; from the
  ' time elapsed since then we know which sub-beat is sounding.
  el! = TIMER - lastTick!
  IF el! < 0 THEN el! = el! + 86400
  sb = INT(el! * bps): IF sb >= bps THEN sb = bps - 1
  nowBeat = (secBeat + sb) MOD perBar

  ' ---- Beat lights: one box per beat in the bar ---------------
  LOCATE 8, 4
  FOR i = 0 TO perBar - 1
    IF i = nowBeat AND running THEN
      IF i = 0 THEN COLOR 12 ELSE COLOR 10
      PRINT CHR$(219); CHR$(219); "  ";
    ELSE
      COLOR 8: PRINT CHR$(176); CHR$(176); "  ";
    END IF
  NEXT
  COLOR 7: PRINT SPACE$(12)

  ' ---- Pendulum ----------------------------------------------
  ' It swings from one side to the other once per beat. The
  ' angle follows a cosine wave so it slows down at each end.
  ' secStart = total beats played before this second began.
  IF running THEN ph = 3.14159 * (secStart + el! * bps)
  px = 40 + INT(25 * COS(ph))
  FOR r = 11 TO 19
    LOCATE r, 10: PRINT SPACE$(62);
  NEXT
  ' Draw the rod from the pivot (row 11, col 40) to the bob.
  FOR r = 11 TO 19
    c = 40 + (px - 40) * (r - 11) \ 8
    LOCATE r, c: PRINT CHR$(249);
  NEXT
  LOCATE 19, px - 1: COLOR 14: PRINT "(O)";: COLOR 7

  ' ---- Keys ---------------------------------------------------
  k$ = UCASE$(INKEY$)
  SELECT CASE k$
    CASE "1" TO "4": bps = VAL(k$)
    CASE "B"
      SELECT CASE perBar
        CASE 2: perBar = 3
        CASE 3: perBar = 4
        CASE 4: perBar = 6
        CASE ELSE: perBar = 2
      END SELECT
      beat = 0
    CASE " "
      running = NOT running
      ' TIMER STOP remembers events but doesn't run the handler;
      ' TIMER ON resumes. We pause the handler while paused.
      IF running THEN TIMER ON ELSE TIMER STOP
    CASE CHR$(27): EXIT DO
  END SELECT
  ' A short rest so the screen does not flicker too much.
  w! = TIMER: DO WHILE TIMER - w! < .03 AND TIMER >= w!: LOOP
LOOP
TIMER OFF
CLS
PRINT "Metronome stopped."
END

' ------------------------------------------------------------
' Tick: runs once per second. Queues 'bps' clicks lasting exactly
' one second in total as background music.
'   tempo T = bps*60 means one quarter note lasts 1/bps second.
'   Each beat = a short L16 click + a dotted-eighth rest (P8.)
'   because 1/16 + 3/16 = 4/16 = one quarter.
' ------------------------------------------------------------
Tick:
  lastTick! = TIMER
  secBeat = beat MOD perBar         ' bar position at this second
  secStart = beat                   ' total beats so far (for the pendulum)
  m$ = "MB ML T" + LTRIM$(STR$(bps * 60))
  FOR i = 1 TO bps
    IF beat MOD perBar = 0 THEN
      m$ = m$ + " O6 L16 C P8."      ' high click on the downbeat
    ELSE
      m$ = m$ + " O5 L16 C P8."      ' lower click on other beats
    END IF
    beat = beat + 1
  NEXT
  PLAY m$
RETURN
