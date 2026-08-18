10 ' ============================================================
20 ' TITLE:    One-Armed Bandit
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     game, random, sound, locate, string$
60 ' SUMMARY:  A three-reel slot machine with spinning reels, a pay table and plenty of beeps.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   You start with 50 coins. Each pull costs one coin. The
100 '   three reels spin (they flicker through symbols) and stop
110 '   one by one. Matching symbols pay out from the table on
120 '   the right. The house always wins in the end... or does it?
130 '
140 ' HOW TO USE
150 '   SPACE or ENTER pulls the handle.  Q cashes out.
160 '
170 ' CONCEPTS YOU WILL LEARN
180 '   * Drawing boxes with the IBM line-drawing characters
190 '   * Weighted reels: common symbols appear more than once
200 '     in the reel string, so they come up more often
210 '   * Using MID$ to pick one character from a string
220 '   * SOUND for clicks and jingles
230 '
240 ' THINGS TO TRY
250 '   * Change REEL$ to make 7s rarer or commoner
260 '   * Add a "hold" button for one reel
270 '   * Track the biggest win of the session
280 ' ============================================================
290 '
1000 KEY OFF: SCREEN 0: WIDTH 40: CLS: RANDOMIZE TIMER
1010 ' The reel: each letter is a symbol. C=cherry B=bar L=lemon
1020 ' 7=seven, $=jackpot. Seven C's but only one $ - so cherries
1030 ' are seven times more likely than the jackpot symbol.
1040 RL$ = "CCCCCCCLLLLLBBBB777$"
1050 DIM R$(3)
1060 CN = 50: PL = 0
1070 COLOR 14: LOCATE 1, 8: PRINT "ONE-ARMED BANDIT": COLOR 7
1080 ' Draw three boxes with codes 201,187,200,188,205,186
1090 ' (the double-line border set of the IBM PC).
1100 FOR I = 0 TO 2
1110   X = 5 + I * 8
1120   LOCATE 4, X: PRINT CHR$(201); STRING$(5, 205); CHR$(187)
1130   LOCATE 5, X: PRINT CHR$(186); SPACE$(5); CHR$(186)
1140   LOCATE 6, X: PRINT CHR$(186); SPACE$(5); CHR$(186)
1150   LOCATE 7, X: PRINT CHR$(186); SPACE$(5); CHR$(186)
1160   LOCATE 8, X: PRINT CHR$(200); STRING$(5, 205); CHR$(188)
1170 NEXT I
1180 ' Pay table
1190 LOCATE 11, 5: PRINT "PAYS:   $ $ $ ..... 100"
1200 LOCATE 12, 5: PRINT "        7 7 7 .....  25"
1210 LOCATE 13, 5: PRINT "        B B B .....  10"
1220 LOCATE 14, 5: PRINT "        L L L .....   5"
1230 LOCATE 15, 5: PRINT "        C C C .....   4"
1240 LOCATE 16, 5: PRINT "        C C any ...   2"
1250 LOCATE 22, 3: PRINT "SPACE = pull     Q = cash out";
1260 '
2000 ' ---------- wait for a pull ------------------------------
2010 LOCATE 18, 5: PRINT "Coins:"; CN; "  Pulls:"; PL; "   "
2020 IF CN < 1 THEN LOCATE 20, 5: PRINT "Out of coins. Game over!": END
2030 K$ = INKEY$: IF K$ = "" THEN 2030
2040 IF K$ = "q" OR K$ = "Q" THEN 9000
2050 IF K$ <> " " AND K$ <> CHR$(13) THEN 2030
2060 CN = CN - 1: PL = PL + 1
2070 LOCATE 20, 1: PRINT SPACE$(39);
2080 '
3000 ' ---------- spin! ------------------------------------------
3010 ' Reel I keeps spinning for 6*I frames, so reel 1 stops
3020 ' first, then reel 2, then reel 3 - just like the real thing.
3030 FOR F = 1 TO 18
3040   FOR I = 1 TO 3
3050     IF F > 6 * I THEN 3080
3060     R$(I) = MID$(RL$, INT(RND * LEN(RL$)) + 1, 1)
3070     LOCATE 6, 8 + (I - 1) * 8: PRINT R$(I)
3080   NEXT I
3090   SOUND 200 + F * 30, .5
3100 NEXT F
3110 '
4000 ' ---------- pay out -----------------------------------------
4010 W = 0
4020 IF R$(1) = R$(2) AND R$(2) = R$(3) THEN W = VAL(MID$("004005010025100", INSTR("CLB7$", R$(1)) * 3 - 2, 3)): GOTO 4050
4030 IF R$(1) = "C" AND R$(2) = "C" THEN W = 2
4040 ' (VAL of a 3-digit slice of the string gives the prize)
4050 IF W = 0 THEN LOCATE 20, 12: PRINT "No luck.": GOTO 2000
4060 CN = CN + W
4070 COLOR 10: LOCATE 20, 10: PRINT "WIN"; W; "COINS!": COLOR 7
4080 FOR J = 1 TO W: IF J > 20 THEN 4100
4090   SOUND 1500, .3: SOUND 32767, .3
4100 NEXT J
4110 GOTO 2000
4120 '
9000 ' ---------- cash out --------------------------------------
9010 LOCATE 20, 3: PRINT "You walk away with"; CN; "coins."
9020 IF CN > 50 THEN LOCATE 21, 3: PRINT "You beat the bandit!"
9030 END
