' ============================================================
' TITLE:    Morse Code Beeper and Trainer
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     sound, morse code, timing, strings, data, quiz
' SUMMARY:  Type a message and hear it in Morse code, or practise copying random letters by ear.
' ------------------------------------------------------------
' WHAT IT DOES
'   Morse code turns letters into short and long beeps (dots and
'   dashes). Mode 1 sends any message you type, showing the
'   dots and dashes as they play. Mode 2 is a trainer: it sends a
'   random letter and you type what you heard.
'   The speed is set in words per minute (WPM) using the standard
'   "PARIS" timing: one dot lasts 1200 / WPM milliseconds.
'
' HOW TO USE
'   Pick 1 (send), 2 (trainer), 3 (change speed) or Q (quit).
'   In the trainer, press the letter you heard, or Esc to stop.
'
' CONCEPTS YOU WILL LEARN
'   * SOUND frequency, duration  (duration in clock ticks, 18.2/s)
'   * Converting milliseconds to ticks: ticks = ms / 54.9
'   * Using SOUND 32767 for a silent gap of exact length
'   * A lookup table built from DATA and INSTR
'
' THINGS TO TRY
'   * Add punctuation: "." is .-.-.- and "?" is ..--..
'   * Use "Farnsworth" timing: fast letters, longer gaps between.
' ============================================================

DECLARE SUB SendChar (c$)
DECLARE SUB Tone (units%, on%)

' Morse for A-Z then 0-9, in the same order as alpha$.
DATA .-,-...,-.-.,-..,.,..-.,--.,....,..,.---,-.-,.-..,--
DATA -.,---,.--.,--.-,.-.,...,-,..-,...-,.--,-..-,-.--,--..
DATA -----,.----,..---,...--,....-,.....,-....,--...,---..,----.

DIM SHARED code$(36), alpha$, unitTicks!, pitch%
alpha$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
FOR i = 1 TO 36: READ code$(i): NEXT

wpm = 15
pitch% = 700                 ' a typical comfortable Morse tone in Hz
RANDOMIZE TIMER

DO
  ' One dot in ticks: 1200/wpm ms, and 1 tick = 1000/18.2 = 54.9 ms.
  unitTicks! = (1200 / wpm) / 54.9
  CLS
  COLOR 14: PRINT "MORSE CODE BEEPER": COLOR 7
  PRINT "Speed:"; wpm; "WPM   (one dot ="; INT(1200 / wpm); "ms)"
  PRINT
  PRINT "1) Send a message"
  PRINT "2) Letter trainer"
  PRINT "3) Change speed"
  PRINT "Q) Quit"
  PRINT
  PRINT "Choice? ";
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
  PRINT k$
  SELECT CASE k$
    CASE "1"
      PRINT
      LINE INPUT "Message: "; msg$
      msg$ = UCASE$(msg$)
      PRINT
      FOR i = 1 TO LEN(msg$)
        c$ = MID$(msg$, i, 1)
        IF c$ = " " THEN
          PRINT "/ ";
          Tone 4, 0            ' word gap is 7 units; 3 already follow a letter
        ELSE
          PRINT c$; " ";
          SendChar c$
          Tone 2, 0            ' letter gap: 3 units (1 already after last element)
        END IF
        IF INKEY$ = CHR$(27) THEN EXIT FOR
      NEXT
      PRINT: PRINT: PRINT "Done. Press a key."
      k$ = INPUT$(1)
    CASE "2"
      score = 0: tries = 0
      PRINT
      PRINT "Listen and press the letter you hear (Esc to stop)."
      DO
        target$ = MID$(alpha$, INT(RND * 26) + 1, 1)
        PLAY "P4"              ' short pause before each letter
        SendChar target$
        a$ = UCASE$(INPUT$(1))
        IF a$ = CHR$(27) THEN EXIT DO
        tries = tries + 1
        IF a$ = target$ THEN
          score = score + 1
          COLOR 10: PRINT "Yes! "; target$; " = "; code$(INSTR(alpha$, target$)): COLOR 7
        ELSE
          COLOR 12: PRINT "No - it was "; target$; " = "; code$(INSTR(alpha$, target$)): COLOR 7
        END IF
      LOOP
      PRINT "Score:"; score; "out of"; tries; " Press a key."
      k$ = INPUT$(1)
    CASE "3"
      PRINT
      INPUT "Words per minute (5-40)"; w
      IF w >= 5 AND w <= 40 THEN wpm = w
    CASE "Q", CHR$(27)
      EXIT DO
  END SELECT
LOOP
CLS
PRINT "73 (best regards)!"
END

' SendChar plays one character's dots and dashes, printing them.
SUB SendChar (c$)
  p = INSTR(alpha$, c$)
  IF p = 0 THEN EXIT SUB            ' ignore characters we don't know
  m$ = code$(p)
  FOR j = 1 TO LEN(m$)
    COLOR 11: PRINT MID$(m$, j, 1);: COLOR 7
    IF MID$(m$, j, 1) = "." THEN Tone 1, 1 ELSE Tone 3, 1
    Tone 1, 0                       ' 1-unit gap between elements
  NEXT
  PRINT " ";
END SUB

' Tone sounds (on%=1) or stays silent (on%=0) for units% dots.
' 32767 Hz is the special "silence" frequency for SOUND.
SUB Tone (units%, on%)
  IF on% THEN f = pitch% ELSE f = 32767
  SOUND f, units% * unitTicks!
END SUB
