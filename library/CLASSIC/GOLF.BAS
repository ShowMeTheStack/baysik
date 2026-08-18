10 ' ============================================================
20 ' TITLE:    Nine Holes of Golf
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     sports, simulation, data, random, print using
60 ' SUMMARY:  Play a nine-hole text golf course with a bag of clubs, water hazards and nerve-racking putts.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Each hole has a length, a par and maybe a pond, all read
100 '   from DATA. Choose a club for each shot: the driver goes
110 '   far but wild, the wedge is short but accurate. Once you
120 '   reach the green you putt, measured in feet. A scorecard
130 '   with your total against par is printed at the end.
140 '
150 ' HOW TO USE
160 '   Type the club number (1-7) for each shot. On the green
170 '   type how hard to putt, in feet. Type 0 for a club to quit.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * Tables of clubs and holes stored in DATA
210 '   * Random spread: distance * (1 + error), where a less
220 '     accurate club has a bigger error
230 '   * Overshooting: ABS() keeps the distance left positive
240 '   * Collecting a scorecard in an array; PRINT USING
250 '
260 ' THINGS TO TRY
270 '   * Add wind that changes each hole
280 '   * Add sand bunkers that make the next shot shorter
290 '   * Design your own nine holes
300 ' ============================================================
310 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 DIM CN$(7), CD(7), CE(7), HL(9), HP(9), WF(9), WT(9), SC(9)
1020 ' ---- the bag: name, average yards, error (0.1 = +/-10%) --
1030 FOR I = 1 TO 7: READ CN$(I), CD(I), CE(I): NEXT I
1040 DATA "Driver",230,.25, "3 Wood",200,.2, "5 Iron",165,.15
1050 DATA "7 Iron",140,.12, "9 Iron",110,.1, "Wedge",60,.08
1055 DATA "Chip",25,.1
1060 ' ---- the course: yards, par, pond from..to (0 = none) --
1070 FOR I = 1 TO 9: READ HL(I), HP(I), WF(I), WT(I): NEXT I
1080 DATA 360,4,0,0, 170,3,60,140, 510,5,250,300, 410,4,0,0
1090 DATA 140,3,40,120, 390,4,180,220, 545,5,0,0, 205,3,120,175
1100 DATA 430,4,260,300
1110 COLOR 10: PRINT "NINE HOLES AT PIXEL PINES GOLF CLUB": COLOR 7
1120 '
2000 ' ---------- play each hole ---------------------------------
2010 FOR H = 1 TO 9
2020   D = HL(H): S = 0: P = 0           ' yards to go, strokes, played distance
2030   PRINT
2040   COLOR 14: PRINT "HOLE"; H; "-"; HL(H); "yards, par"; HP(H); : COLOR 7
2050   IF WF(H) THEN PRINT "  (pond from"; WF(H); "to"; WT(H); "yards)" ELSE PRINT
2060   '
2100   ' ---- shots from the fairway --------------------------
2110   IF D <= 20 THEN 2500               ' close enough: on the green
2120   PRINT USING "  ### yards to the pin. "; D;
2130   PRINT "Club (1 Dr 2 3W 3 5i 4 7i 5 9i 6 Wd 7 Chip)";
2140   INPUT C
2150   IF C = 0 THEN 9000
2160   IF C < 1 OR C > 7 OR C <> INT(C) THEN 2120
2170   S = S + 1
2180   ' Distance with random error: RND-.5 is -0.5 .. +0.5, so
2190   ' the shot is CD * (1 +/- CE). Hit with a smooth swing.
2200   L = INT(CD(C) * (1 + (RND - .5) * 2 * CE(C)))
2210   ' A wild shot sometimes goes sideways into the rough
2220   IF RND < CE(C) / 2 THEN L = INT(L * .6): PRINT "  Sliced into the rough!";
2230   NP = P + L                         ' new position along hole
2240   PRINT "  The ball flies"; L; "yards.";
2250   IF WF(H) = 0 OR NP < WF(H) OR NP > WT(H) THEN 2290
2260   ' In the water: one stroke penalty, drop before the pond.
2270   PRINT " SPLASH! Penalty stroke.": SOUND 100, 4
2280   S = S + 1: P = WF(H) - 5: D = HL(H) - P: GOTO 2110
2290   PRINT
2300   P = NP: D = ABS(HL(H) - P)         ' past the hole? walk back
2310   IF HL(H) - P < 0 THEN P = HL(H) - D
2320   GOTO 2110
2330   '
2500   ' ---- on the green: putting, in feet ------------------
2510   F = D * 3                          ' yards to feet
2520   IF F < 1 THEN F = 1
2530   PRINT USING "  On the green, ## feet from the hole. "; F;
2540   INPUT "Putt how many feet"; PT
2550   IF PT <= 0 THEN 2530
2560   S = S + 1
2570   ' Actual roll: your aim plus a wobble that grows with length
2580   R = PT + (RND - .5) * (2 + PT * .3)
2590   F = ABS(F - R)
2600   IF F < 1.2 THEN PRINT "  Plop! In the cup.": SOUND 1200, 1: GOTO 2700
2610   PRINT USING "  Missed - now ##.# feet away."; F
2620   D = F / 3: GOTO 2510
2700   SC(H) = S
2710   PRINT "  Hole"; H; "in"; S; "strokes - ";
2720   ON S - HP(H) + 3 GOSUB 2800, 2810, 2820, 2830, 2840
2730   IF S - HP(H) > 2 THEN PRINT "ouch."
2740 NEXT H
2750 GOTO 8000
2800 PRINT "EAGLE!": PLAY "T200 O4 L16 CEG>C": RETURN
2810 PRINT "Birdie!": SOUND 1500, 2: RETURN
2820 PRINT "Par.": RETURN
2830 PRINT "Bogey.": RETURN
2840 PRINT "Double bogey.": RETURN
2850 '
8000 ' ---------- scorecard -------------------------------------
8010 PRINT: COLOR 11: PRINT "SCORECARD": COLOR 7
8020 PRINT "Hole  1  2  3  4  5  6  7  8  9   Total"
8030 PRINT "Par ";: TP = 0
8040 FOR I = 1 TO 9: PRINT USING "###"; HP(I); : TP = TP + HP(I): NEXT I
8050 PRINT USING "   ###"; TP
8060 PRINT "You ";: T = 0
8070 FOR I = 1 TO 9: PRINT USING "###"; SC(I); : T = T + SC(I): NEXT I
8080 PRINT USING "   ###"; T
8090 IF T < TP THEN PRINT "Under par! Watch out, champions."
8100 IF T = TP THEN PRINT "Level par - a fine round."
8110 IF T > TP THEN PRINT T - TP; "over par. The 19th hole awaits."
8120 END
9000 PRINT "You walk off the course. Scores so far:"
9010 FOR I = 1 TO 9: PRINT SC(I); : NEXT I
9020 PRINT: END
