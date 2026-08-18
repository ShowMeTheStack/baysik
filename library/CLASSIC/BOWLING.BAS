10 ' ============================================================
20 ' TITLE:    Bowling Scorekeeper
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     sports, scoring, arrays, algorithms, locate
60 ' SUMMARY:  Enter pins knocked down ball by ball and watch a real ten-pin scorecard fill in, strikes and spares included.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Ten-pin bowling scoring confuses lots of people: a strike
100 '   (X) scores 10 PLUS your next two balls; a spare (/) scores
110 '   10 PLUS your next one ball; the tenth frame gives bonus
120 '   balls. This program keeps the list of every ball rolled
130 '   and recalculates the whole card after each one.
140 '
150 ' HOW TO USE
160 '   Type the number of pins (0-10) for each ball. Type R for
170 '   a random ball (let the computer bowl!), Q to quit.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * Storing a game as a simple list of rolls B()
210 '   * Walking through that list frame by frame to score it
220 '   * Look-ahead: B(I+1) and B(I+2) for strike bonuses
230 '   * Drawing a scorecard with LOCATE and box characters
240 '
250 ' THINGS TO TRY
260 '   * Make the random bowler better (more 8s, 9s and 10s)
270 '   * Add a second player who takes turns
280 '   * What is the score of 12 strikes in a row? (300!)
290 ' ============================================================
300 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 DIM B(21), FS(10)
1020 NB = 0                              ' balls rolled so far
1030 FR = 1: BI = 1                      ' current frame, ball in frame
1040 GOSUB 4000                          ' draw empty card
1050 '
2000 ' ---------- ask for the next ball ----------------------------
2010 IF FR > 10 THEN 6000
2020 ' How many pins are standing? Normally 10 on ball 1, and
2030 ' 10 - first ball on ball 2. Frame 10 can reset the rack.
2040 MX = 10
2050 IF BI = 2 AND (FR < 10 OR B(NB) < 10) THEN MX = 10 - B(NB)
2060 IF FR = 10 AND BI = 3 THEN IF B(NB - 1) = 10 AND B(NB) < 10 THEN MX = 10 - B(NB)
2070 LOCATE 12, 1: PRINT SPACE$(79): LOCATE 12, 1
2080 PRINT "Frame"; FR; "ball"; BI; "- pins (0 -"; MX; "), R=random, Q=quit";
2090 LINE INPUT "? "; A$
2100 IF A$ = "q" OR A$ = "Q" THEN LOCATE 14, 1: END
2110 IF A$ = "r" OR A$ = "R" THEN P = INT(RND * (MX + 1)): IF RND < .3 THEN P = MX
2120 IF A$ = "r" OR A$ = "R" THEN 2160
2130 IF A$ = "" THEN 2070
2140 P = VAL(A$)
2150 IF P < 0 OR P > MX OR P <> INT(P) OR (P = 0 AND A$ <> "0") THEN SOUND 100, 2: GOTO 2070
2160 NB = NB + 1: B(NB) = P
2170 IF P = 10 THEN SOUND 880, 2: SOUND 1320, 3 ELSE SOUND 400 + P * 40, 1
2180 '
3000 ' ---------- move on to the next ball/frame -----------------
3010 IF FR = 10 THEN 3100
3020 IF BI = 1 AND P = 10 THEN FR = FR + 1: GOTO 3200   ' strike
3030 IF BI = 2 THEN FR = FR + 1: BI = 1: GOTO 3200
3040 BI = 2: GOTO 3200
3100 ' tenth frame: a third ball only after a strike or spare
3110 IF BI = 1 THEN BI = 2: GOTO 3200
3120 IF BI = 2 AND B(NB - 1) + B(NB) >= 10 THEN BI = 3: GOTO 3200
3130 FR = 11
3200 GOSUB 5000                          ' rescore everything
3210 GOSUB 4500                          ' show it
3220 GOTO 2000
3230 '
4000 ' ---------- empty scorecard --------------------------------
4010 COLOR 14: PRINT "BOWLING SCOREKEEPER": COLOR 7
4020 LOCATE 3, 1
4030 FOR F = 1 TO 10
4040   LOCATE 3, (F - 1) * 7 + 1: PRINT USING "  ##  "; F;
4050 NEXT F
4060 LOCATE 4, 1: PRINT STRING$(71, 196)
4070 LOCATE 7, 1: PRINT STRING$(71, 196)
4080 ' Column dividers, with proper joins where they cross the
4085 ' horizontal rules: 197 is a cross, 193 an upside-down T,
4086 ' 195/180 are side joins and 192/217 the bottom corners.
4090 FOR F = 0 TO 10
4092   X = F * 7 + 1: J = 197: K = 193
4093   IF F = 0 THEN J = 195: K = 192 ELSE IF F = 10 THEN J = 180: K = 217
4094   LOCATE 3, X: PRINT CHR$(179); : LOCATE 4, X: PRINT CHR$(J);
4096   LOCATE 5, X: PRINT CHR$(179); : LOCATE 6, X: PRINT CHR$(179);
4098   LOCATE 7, X: PRINT CHR$(K);
4100 NEXT F
4110 RETURN
4120 '
4500 ' ---------- show marks and running totals ------------------
4510 ' Replay the ball list to know which ball sits in which box.
4520 I = 1
4530 FOR F = 1 TO 10
4540   C = (F - 1) * 7 + 3              ' column of first mark
4550   IF I > NB THEN 4690
4560   IF F = 10 THEN 4620
4570   IF B(I) = 10 THEN LOCATE 5, C + 2: PRINT "X": I = I + 1: GOTO 4670
4580   LOCATE 5, C: GOSUB 4800: I = I + 1
4590   IF I > NB THEN 4690
4600   LOCATE 5, C + 2: IF B(I - 1) + B(I) = 10 THEN PRINT "/" ELSE GOSUB 4800
4610   I = I + 1: GOTO 4670
4620   ' frame 10: up to three marks side by side
4630   FOR K = 0 TO 2
4640     IF I + K > NB THEN 4660
4650     LOCATE 5, C + K * 2 - 1: GOSUB 4850
4660   NEXT K
4670   IF FS(F) >= 0 THEN LOCATE 6, C: PRINT USING "###"; FS(F)
4680 NEXT F
4690 RETURN
4800 ' print ball I as a digit, or "-" for a gutter ball
4810 IF B(I) = 0 THEN PRINT "-" ELSE PRINT CHR$(48 + B(I))
4820 RETURN
4850 ' frame-10 ball I+K: X for 10, / if it completes a spare
4860 J = I + K
4870 IF B(J) = 10 THEN PRINT "X": RETURN
4880 IF K > 0 THEN IF B(J - 1) < 10 AND B(J - 1) + B(J) = 10 AND (K = 1 OR B(J - 2) = 10 OR B(J - 2) + B(J - 1) <> 10) THEN PRINT "/": RETURN
4890 IF B(J) = 0 THEN PRINT "-" ELSE PRINT CHR$(48 + B(J))
4900 RETURN
4910 '
5000 ' ---------- score every finished frame -> FS() --------------
5010 ' FS(f) = -1 means "can't be scored yet" (waiting for bonus).
5020 T = 0: I = 1
5025 FOR F = 1 TO 10: FS(F) = -1: NEXT F
5030 FOR F = 1 TO 10
5050   IF I > NB THEN 5160
5060   IF B(I) <> 10 THEN 5100
5070   ' strike: 10 + next two balls
5080   IF I + 2 > NB THEN 5160
5090   T = T + 10 + B(I + 1) + B(I + 2): FS(F) = T: I = I + 1: GOTO 5150
5100   IF I + 1 > NB THEN 5160
5110   IF B(I) + B(I + 1) < 10 THEN T = T + B(I) + B(I + 1): FS(F) = T: I = I + 2: GOTO 5150
5120   ' spare: 10 + next one ball
5130   IF I + 2 > NB THEN 5160
5140   T = T + 10 + B(I + 2): FS(F) = T: I = I + 2
5150 NEXT F
5160 RETURN
5170 '
6000 ' ---------- game over --------------------------------------
6010 LOCATE 12, 1: PRINT SPACE$(79)
6020 LOCATE 12, 1: COLOR 10
6030 PRINT "Final score:"; FS(10)
6040 COLOR 7
6050 IF FS(10) = 300 THEN PRINT "A PERFECT GAME!!!": PLAY "T200 O4 L16 CDEFGAB>C"
6060 IF FS(10) >= 200 AND FS(10) < 300 THEN PRINT "Over 200 - you're a pro!"
6070 IF FS(10) < 100 THEN PRINT "Keep practising - the bumpers are always there."
6080 END
