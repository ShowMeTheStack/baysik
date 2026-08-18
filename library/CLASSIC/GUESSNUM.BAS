10 ' ============================================================
20 ' TITLE:    Hot and Cold
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     game, sound, input, random, beginner
60 ' SUMMARY:  Guess the secret number from 1 to 100 - the closer you get, the higher the beep.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   The computer thinks of a number. After each guess it tells
100 '   you "too high" or "too low" AND plays a tone: a low growl
110 '   when you are far away ("cold") and a high whistle when you
120 '   are close ("hot"). It remembers your best game.
130 '
140 ' HOW TO USE
150 '   Type a number and press Enter. After winning, answer Y to
160 '   play again or N to stop. Type 0 to give up a round.
170 '
180 ' CONCEPTS YOU WILL LEARN
190 '   * RND and INT to make a random whole number
200 '   * SOUND frequency, duration (duration is in clock ticks,
210 '     18.2 ticks = 1 second)
220 '   * Mapping a distance to a pitch with simple arithmetic
230 '   * IF ... THEN line-number jumps - the GW-BASIC "loop"
240 '
250 ' THINGS TO TRY
260 '   * Make the range 1 to 1000. How many guesses do you need?
270 '     (Hint: halving each time needs about 10.)
280 '   * Limit the player to 7 guesses
290 '   * Let the computer guess YOUR number instead
300 ' ============================================================
310 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 BS = 0                              ' best score (0 = none yet)
1020 COLOR 14: PRINT "HOT AND COLD": COLOR 7
1030 PRINT "I'm thinking of a number from 1 to 100."
1040 '
2000 ' ---------- new round ---------------------------------------
2010 N = INT(RND * 100) + 1
2020 G = 0
2030 PRINT
2040 INPUT "Your guess"; X
2050 IF X = 0 THEN PRINT "It was"; N; "- better luck next time.": GOTO 3000
2060 IF X < 1 OR X > 100 OR X <> INT(X) THEN PRINT "1 to 100, whole numbers only!": GOTO 2040
2070 G = G + 1
2080 IF X = N THEN 2500
2090 ' Distance 1..99 -> pitch: close = high (about 2000 Hz),
2100 ' far = low (about 100 Hz).
2110 D = ABS(X - N)
2120 F = 2000 - D * 19
2130 SOUND F, 4
2140 IF X > N THEN PRINT "Too high"; ELSE PRINT "Too low";
2150 IF D <= 3 THEN COLOR 12: PRINT " - you're BOILING!": COLOR 7: GOTO 2040
2160 IF D <= 10 THEN COLOR 14: PRINT " - warm.": COLOR 7: GOTO 2040
2170 IF D <= 25 THEN PRINT " - cool.": GOTO 2040
2180 COLOR 9: PRINT " - freezing!": COLOR 7
2190 GOTO 2040
2200 '
2500 ' ---------- got it! ------------------------------------------
2510 COLOR 10: PRINT "YES! The number was"; N: COLOR 7
2520 ' A rising arpeggio, one SOUND per note
2530 FOR I = 1 TO 4: SOUND 262 * I, 2: NEXT I
2540 PRINT "You took"; G; "guesses."
2550 IF BS = 0 OR G < BS THEN BS = G: PRINT "That's a new best score!"
2560 '
3000 ' ---------- again? ------------------------------------------
3010 INPUT "Play again (Y/N)"; A$
3020 IF A$ = "y" OR A$ = "Y" THEN PRINT "OK, I've picked a new number.": GOTO 2000
3030 IF A$ <> "n" AND A$ <> "N" THEN 3010
3040 IF BS > 0 THEN PRINT "Your best game:"; BS; "guesses."
3050 PRINT "Thanks for playing!"
3060 END
