' ============================================================
' TITLE:    Sound Effects Library
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     sound, sound effects, games, sub, loops, random
' SUMMARY:  Twelve classic PC-speaker sound effects - sirens, lasers, explosions, birds and more - each in its own SUB.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a menu of sound effects made only with the SOUND
'   statement. Each effect is a short SUB you can copy straight
'   into your own games. The comment above each SUB explains
'   the trick behind the sound.
'
' HOW TO USE
'   Press a letter A-L to hear an effect. Press Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * SOUND frequency (37-32767 Hz), duration (in 1/18.2 s ticks)
'   * Fractional durations (SOUND f, .5) for very fast effects
'   * Sweeping frequencies with FOR ... STEP loops
'   * Random noise with RND for explosions
'   * SIN for smooth wobbles (sirens, UFOs)
'
' THINGS TO TRY
'   * Change the STEP values - smaller steps = smoother sweeps.
'   * Invent a new effect: a "power down" or a "teleporter".
' ============================================================

DECLARE SUB Siren ()
DECLARE SUB Laser ()
DECLARE SUB Explosion ()
DECLARE SUB Bird ()
DECLARE SUB Phone ()
DECLARE SUB Ufo ()
DECLARE SUB Bounce ()
DECLARE SUB Alarm ()
DECLARE SUB Coin ()
DECLARE SUB PowerUp ()
DECLARE SUB Bomb ()
DECLARE SUB Robot ()

RANDOMIZE TIMER
DIM nm$(12)
DATA "Police siren", "Laser zap", "Explosion", "Bird chirp", "Telephone ring", "UFO wobble"
DATA "Bouncing ball", "Alarm clock", "Coin pickup", "Power-up", "Falling bomb", "Robot chatter"
FOR i = 1 TO 12: READ nm$(i): NEXT

CLS
COLOR 14: PRINT " SOUND EFFECTS LIBRARY": COLOR 7
PRINT
FOR i = 1 TO 12
  PRINT "   "; CHR$(64 + i); ")  "; nm$(i)
NEXT
PRINT
PRINT "   Esc) Quit"
DO
  k$ = UCASE$(INKEY$)
  IF k$ = CHR$(27) THEN EXIT DO
  IF k$ >= "A" AND k$ <= "L" THEN
    n = ASC(k$) - 64
    LOCATE 18, 4: COLOR 10: PRINT "Playing: "; nm$(n); SPACE$(20): COLOR 7
    SELECT CASE n
      CASE 1: Siren
      CASE 2: Laser
      CASE 3: Explosion
      CASE 4: Bird
      CASE 5: Phone
      CASE 6: Ufo
      CASE 7: Bounce
      CASE 8: Alarm
      CASE 9: Coin
      CASE 10: PowerUp
      CASE 11: Bomb
      CASE 12: Robot
    END SELECT
    LOCATE 18, 4: PRINT SPACE$(40)
  END IF
LOOP
CLS
PRINT "Bye!"
END

' Alarm: two fast beeps, a pause, repeated. The pause uses the
' special frequency 32767, which SOUND treats as silence.
SUB Alarm
  FOR r = 1 TO 4
    SOUND 2000, 1: SOUND 32767, 1
    SOUND 2000, 1: SOUND 32767, 4
  NEXT
END SUB

' Bird: quick upward chirps. Each chirp sweeps 2000 -> 4000 Hz
' in tiny steps of .1 tick, so the whole chirp is very short.
SUB Bird
  FOR c = 1 TO 3
    FOR f = 2000 TO 4000 STEP 250
      SOUND f, .1
    NEXT
    SOUND 32767, 1 + RND * 3
  NEXT
  FOR f = 3500 TO 2500 STEP -100: SOUND f, .1: NEXT
END SUB

' Bomb: a long falling whistle (high to low) then a boom.
SUB Bomb
  FOR f = 3000 TO 400 STEP -20
    SOUND f, .15
  NEXT
  Explosion
END SUB

' Bounce: each bounce is a short "boing" sweep. The gap between
' bounces shrinks, just like a real ball losing energy.
SUB Bounce
  gap = 8
  FOR b = 1 TO 8
    FOR f = 300 TO 600 STEP 50: SOUND f, .1: NEXT
    SOUND 32767, gap
    gap = gap * .7
  NEXT
END SUB

' Coin: the classic two-note "ba-ding!" - a short note followed
' by a longer note a fourth higher.
SUB Coin
  SOUND 988, 1.5           ' B5
  SOUND 1319, 5            ' E6
END SUB

' Explosion: random low frequencies = noise. As the explosion
' fades we make the range lower and the notes longer.
SUB Explosion
  FOR i = 1 TO 60
    SOUND 40 + RND * (400 - i * 5), .2 + i / 200
  NEXT
END SUB

' Laser: a very fast DOWNWARD sweep. Fast + high + falling =
' science fiction!
SUB Laser
  FOR z = 1 TO 3
    FOR f = 3000 TO 300 STEP -150
      SOUND f, .05
    NEXT
  NEXT
END SUB

' Phone: real phones mix two tones; we alternate two tones
' really fast (every .2 tick) to get a buzzy trill.
SUB Phone
  FOR ring = 1 TO 2
    FOR i = 1 TO 20
      SOUND 1000, .2: SOUND 1300, .2
    NEXT
    SOUND 32767, 10
  NEXT
END SUB

' PowerUp: arpeggio climbing up the major chord, octave by octave.
SUB PowerUp
  FOR o = 0 TO 3
    FOR n = 0 TO 2
      ' 1, 1.25, 1.5 = the frequency ratios of a major chord.
      SOUND 262 * 2 ^ o * (1 + n * .25), .4
    NEXT
  NEXT
END SUB

' Robot: random notes picked from a small range, with random
' lengths, sound like a robot "talking".
SUB Robot
  FOR i = 1 TO 25
    SOUND 300 + INT(RND * 8) * 100, .5 + RND * 1.5
  NEXT
END SUB

' Siren: the pitch rises and falls smoothly. We use SIN so the
' change speeds up and slows down like a real wailing siren.
SUB Siren
  FOR t = 0 TO 6.28 * 2 STEP .1
    SOUND 800 + 400 * SIN(t), .3
  NEXT
END SUB

' Ufo: a fast wobble (SIN with a big multiplier) on a pitch that
' slowly rises.
SUB Ufo
  FOR t = 0 TO 120
    SOUND 500 + t * 4 + 120 * SIN(t * 1.3), .2
  NEXT
END SUB
