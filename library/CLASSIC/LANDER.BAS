10 ' ============================================================
20 ' TITLE:    Lunar Lander
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     simulation, physics, on timer, on key, real time
60 ' SUMMARY:  Land on the Moon in real time: ON TIMER runs the physics each second while you work the throttle.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   You start 500 metres above the Moon, falling at 20 m/s.
100 '   Every second an ON TIMER event updates your height, speed
110 '   and fuel. You set the engine throttle from 0 (off) to 9
120 '   (full) at any time. Touch down at under 2 m/s for a
130 '   perfect landing. Run out of fuel and gravity wins...
140 '
150 ' HOW TO USE
160 '   Keys 0-9 set the throttle directly.
170 '   Up/Down arrow keys nudge it up or down by one.
180 '   Esc aborts the mission.
190 '
200 ' CONCEPTS YOU WILL LEARN
210 '   * ON TIMER(1) GOSUB - code that runs once per second
220 '     while the main loop keeps reading the keyboard
230 '   * ON KEY(11) / ON KEY(14) GOSUB - trapping the arrow keys
240 '     (key numbers 11-14 are up, left, right, down)
250 '   * Simple physics: speed += (gravity - thrust) * time
260 '   * A text "gauge" drawn with STRING$
270 '
280 ' THINGS TO TRY
290 '   * Change gravity G to Mars (3.7) - much harder!
300 '   * Give the lander sideways drift and a landing pad
310 '   * Make the fuel gauge flash red below 20 units
320 ' ============================================================
330 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS
1010 G = 1.62                    ' Moon gravity, m/s^2
1020 H = 500: V = 20: F = 150    ' height (m), speed (m/s, + = down), fuel
1030 TH = 0: T = 0: DN = 0       ' throttle 0-9, seconds, done flag
1040 COLOR 14: LOCATE 1, 30: PRINT "L U N A R   L A N D E R": COLOR 7
1050 LOCATE 23, 1: PRINT STRING$(80, 177);     ' the lunar surface
1060 LOCATE 25, 1: PRINT "0-9 = throttle   Up/Down arrows = adjust   Esc = abort";
1070 GOSUB 5000                  ' first display
1080 ' ---- install event traps ----------------------------------
1090 ON TIMER(1) GOSUB 4000: TIMER ON
1100 ON KEY(11) GOSUB 4500: KEY(11) ON     ' up arrow
1110 ON KEY(14) GOSUB 4600: KEY(14) ON     ' down arrow
1120 '
2000 ' ---------- main loop: just read keys ---------------------
2010 ' Note how little the main loop does. The physics happens
2020 ' "in the background" in the timer routine at line 4000.
2030 IF DN THEN 8000
2040 K$ = INKEY$
2050 IF K$ = CHR$(27) THEN 9000
2060 IF K$ >= "0" AND K$ <= "9" THEN TH = VAL(K$): GOSUB 5000
2070 GOTO 2030
2080 '
4000 ' ---------- TIMER event: one second of physics ------------
4010 T = T + 1
4020 IF F <= 0 THEN TH = 0: F = 0          ' no fuel, no thrust
4030 ' Full throttle (9) gives 3.6 m/s^2 of upward push, more
4040 ' than twice the Moon's gravity, burning 9 fuel per second.
4050 A = G - TH * .4                        ' net downward acceleration
4060 F = F - TH
4070 IF F < 0 THEN F = 0
4080 ' Average old and new speed for a more accurate fall.
4090 V1 = V + A
4100 H = H - (V + V1) / 2
4110 V = V1
4120 IF H <= 0 THEN H = 0: DN = 1
4130 GOSUB 5000
4140 IF TH > 0 THEN SOUND 60 + TH * 8, 2   ' engine rumble
4150 RETURN
4500 ' ---------- KEY(11): up arrow --------------------------------
4510 IF TH < 9 THEN TH = TH + 1
4520 GOSUB 5000: RETURN
4600 ' ---------- KEY(14): down arrow ---------------------------
4610 IF TH > 0 THEN TH = TH - 1
4620 GOSUB 5000: RETURN
4630 '
5000 ' ---------- draw instruments and the lander -------------------
5010 LOCATE 4, 3: PRINT USING "Time      ### s"; T
5020 LOCATE 6, 3: PRINT USING "Height    ####.# m "; H
5030 LOCATE 8, 3: PRINT USING "Speed     ###.# m/s "; ABS(V);
5040 IF V >= 0 THEN PRINT "down" ELSE PRINT "UP  "
5050 LOCATE 10, 3: PRINT USING "Fuel      ### "; F;
5060 IF F < 20 THEN COLOR 12
5070 PRINT STRING$(INT(F / 10), 219); SPACE$(16 - INT(F / 10)): COLOR 7
5080 LOCATE 12, 3: PRINT USING "Throttle    # "; TH;
5090 COLOR 14: PRINT STRING$(TH, 254); SPACE$(10 - TH): COLOR 7
5100 ' The lander moves down column 60. Row 3 = 500 m, row 22 = 0.
5110 R = 22 - INT(H / 500 * 19 + .5)
5120 IF R < 3 THEN R = 3
5130 IF R > 22 THEN R = 22
5140 IF OL > 0 AND OL <> R THEN LOCATE OL, 58: PRINT "     ": LOCATE OL + 1, 58: PRINT "     "
5150 LOCATE R, 58: COLOR 15: PRINT "/^\";
5160 IF R < 22 THEN LOCATE R + 1, 58: IF TH > 0 THEN COLOR 12: PRINT " ";CHR$(31);" "; ELSE PRINT "   ";
5170 COLOR 7: OL = R             ' remember old row for erasing
5180 RETURN
5190 '
8000 ' ---------- touchdown! -----------------------------------
8010 TIMER OFF: KEY(11) OFF: KEY(14) OFF
8020 LOCATE 16, 3
8030 IF V < 2 THEN COLOR 10: PRINT "PERFECT LANDING! The Eagle has landed.": PLAY "T120 O3 L8 C E G > C4": GOTO 8100
8040 IF V < 5 THEN COLOR 14: PRINT "Bumpy landing - but everyone walks away.": GOTO 8100
8050 COLOR 12: PRINT "CRASH! You made a new crater"; INT(V / 3); "metres deep."
8060 FOR I = 1 TO 20: SOUND 40 + RND * 80, .5: NEXT I
8100 COLOR 7: LOCATE 17, 3: PRINT USING "Impact speed ##.# m/s after ### seconds"; V; T
8110 LOCATE 18, 3: PRINT USING "Fuel left ###"; F
8120 LOCATE 24, 1: END
9000 TIMER OFF: KEY(11) OFF: KEY(14) OFF
9010 LOCATE 16, 3: PRINT "Mission aborted. The crew returns to orbit."
9020 LOCATE 24, 1: END
