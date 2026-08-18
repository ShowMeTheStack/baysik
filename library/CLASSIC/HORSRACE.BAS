10 ' ============================================================
20 ' TITLE:    Derby Day
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     game, animation, locate, random, betting
60 ' SUMMARY:  Six horses gallop across the screen while you bet your pocket money on a winner.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Pick a horse, place a bet, then watch the race animated
100 '   with LOCATE and PRINT. Each horse has different odds:
110 '   long shots pay more but win less often. Keep going until
120 '   you are rich, broke, or bored.
130 '
140 ' HOW TO USE
150 '   Press 1-6 to choose a horse (or Q to leave the track),
160 '   type your bet, then enjoy the race.
170 '
180 ' CONCEPTS YOU WILL LEARN
190 '   * Animation by printing, erasing and re-printing text
200 '   * Weighted randomness: faster horses get bigger steps
210 '   * A delay loop using TIMER
220 '   * Parallel arrays: N$(), OD(), X() for each horse
230 '
240 ' THINGS TO TRY
250 '   * Add a photo finish when two horses cross together
260 '   * Give each horse a different colour
270 '   * Let horses get tired near the end
280 ' ============================================================
290 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS: RANDOMIZE TIMER
1010 DIM N$(6), OD(6), X(6)
1020 FOR I = 1 TO 6: READ N$(I), OD(I): NEXT I
1030 ' name, odds (pays OD to 1). Speed is linked to the odds:
1040 ' a 2-to-1 favourite is quicker than a 9-to-1 outsider.
1050 DATA "Thunderbolt",2, "Lucky Penny",3, "Old Rusty",9
1060 DATA "Moonbeam",4, "Pepperpot",6, "Dandelion",5
1070 MO = 100: FL = 70                 ' money, finish column
1080 '
2000 ' ---------- the betting window -----------------------------
2010 CLS: COLOR 14: PRINT "D E R B Y   D A Y": COLOR 7: PRINT
2020 FOR I = 1 TO 6
2030   PRINT I; N$(I); TAB(20); "pays"; OD(I); "to 1"
2040 NEXT I
2050 PRINT: PRINT "You have $"; MO
2060 IF MO <= 0 THEN PRINT "You're broke! Time to walk home.": END
2070 PRINT "Choose a horse (1-6) or Q to quit: ";
2080 K$ = INKEY$: IF K$ = "" THEN 2080
2090 IF K$ = "q" OR K$ = "Q" THEN PRINT: PRINT "You leave with $"; MO: END
2100 H = VAL(K$): IF H < 1 OR H > 6 THEN 2080
2110 PRINT N$(H)
2120 INPUT "How much do you bet"; BT
2130 BT = INT(BT)
2140 IF BT < 1 OR BT > MO THEN PRINT "Between 1 and"; MO; "please.": GOTO 2120
2150 '
3000 ' ---------- draw the track ------------------------------
3010 CLS
3020 LOCATE 2, 1: PRINT "START"; TAB(FL); "FINISH"
3030 FOR I = 1 TO 6
3040   X(I) = 2
3050   LOCATE 2 + I * 2, 1: PRINT I;
3060   LOCATE 3 + I * 2, 1: PRINT STRING$(FL + 2, "-");
3070   LOCATE 2 + I * 2, FL + 3: PRINT "|";
3080 NEXT I
3090 LOCATE 18, 1: PRINT "And they're off!"
3100 SOUND 523, 2: SOUND 659, 2: SOUND 784, 4
3110 '
4000 ' ---------- run the race ---------------------------------
4010 W = 0
4020 FOR I = 1 TO 6
4030   ' Random step 0..3, plus a small bonus for favourites.
4040   ' (12 - odds) / 10 gives 1.0 for odds 2, 0.3 for odds 9.
4050   S = INT(RND * 3 + RND * (12 - OD(I)) / 10 + .3)
4060   IF S = 0 THEN 4100
4070   LOCATE 2 + I * 2, X(I) + 2: PRINT SPACE$(S);   ' erase old
4080   X(I) = X(I) + S: IF X(I) > FL THEN X(I) = FL
4090   LOCATE 2 + I * 2, X(I) + 2: COLOR 15: PRINT "H"; : COLOR 7
4100   IF X(I) >= FL AND W = 0 THEN W = I
4110 NEXT I
4120 ' A short pause: wait for TIMER to move on by 0.1 seconds.
4130 T = TIMER: WHILE TIMER < T + .1 AND TIMER >= T: WEND
4140 IF W = 0 THEN 4010
4150 '
5000 ' ---------- results ------------------------------------------
5010 LOCATE 18, 1: COLOR 14
5020 PRINT "The winner is number"; W; "- "; N$(W); "!          "
5030 COLOR 7
5040 IF W = H THEN 5100
5050 PRINT "Sorry, you lost $"; BT
5060 MO = MO - BT: SOUND 150, 6
5070 GOTO 5200
5100 PRINT "You WIN $"; BT * OD(H); "!"
5110 MO = MO + BT * OD(H)
5120 PLAY "T200 O4 L16 C E G > C8"
5200 PRINT: PRINT "Press any key for the next race..."
5210 IF INKEY$ = "" THEN 5210
5220 GOTO 2000
