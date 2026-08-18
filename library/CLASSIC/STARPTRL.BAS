10 ' ============================================================
20 ' TITLE:    Star Patrol
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Advanced
50 ' TAGS:     game, space, strategy, arrays, on goto, locate
60 ' SUMMARY:  Hunt raider ships across a 4x4 galaxy of 8x8 sectors with phasers, torpedoes and starbases.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   A small original take on the famous 1970s "sector" space
100 '   games. The galaxy is a 4x4 grid of sectors; each sector is
110 '   an 8x8 grid of cells holding your ship (@), raiders (R),
120 '   starbases (B) and stars (*). Destroy every raider before
130 '   stardate 30. Raiders shoot back after each of your moves.
140 '
150 ' HOW TO USE
160 '   Press a letter key:
170 '     N  navigate   - give a direction 1-8 and a distance
180 '     P  phasers    - spend energy to hit all raiders here
190 '     T  torpedo    - fire one torpedo in a direction 1-8
200 '     L  long scan  - peek at the 8 neighbouring sectors
210 '     Q  quit
220 '   Directions:    8 1 2      Park next to a B to dock:
230 '                  7 @ 3      energy and torpedoes refill
240 '                  6 5 4      and raiders can't hurt you.
250 '
260 ' CONCEPTS YOU WILL LEARN
270 '   * Packing three numbers into one: raiders*100+bases*10+stars
280 '   * Direction tables DX()/DY() read from DATA
290 '   * ON value GOTO as a fast multi-way branch
300 '   * A screen layout built with LOCATE and COLOR
310 '   * DEF FN for a random-number helper
320 '
330 ' THINGS TO TRY
340 '   * Add shields that absorb damage before energy
350 '   * Make raiders move one cell toward you each turn
360 '   * Grow the galaxy to 8x8 sectors (change the 4s)
370 ' ============================================================
380 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS
1010 RANDOMIZE TIMER
1020 DEF FNR(N) = INT(RND * N) + 1      ' random whole number 1..N
1030 DIM G(4, 4), S(8, 8), KX(3), KY(3), KE(3), DX(8), DY(8)
1040 ' Direction table: 1=north, then clockwise round the compass.
1050 FOR I = 1 TO 8: READ DX(I), DY(I): NEXT I
1060 DATA 0,-1, 1,-1, 1,0, 1,1, 0,1, -1,1, -1,0, -1,-1
1070 '
1100 ' ---------- build the galaxy -------------------------------
1110 ' Each G(x,y) holds THREE facts squeezed into one number:
1120 '   hundreds digit = raiders, tens = bases, ones = stars.
1130 ' So 215 means 2 raiders, 1 base, 5 stars. Pull them apart
1140 ' later with \ (integer divide) and MOD.
1150 TK = 0
1160 FOR X = 1 TO 4: FOR Y = 1 TO 4
1170   R = RND: K = 0
1180   IF R > .55 THEN K = 1
1190   IF R > .85 THEN K = 2
1200   IF R > .96 THEN K = 3
1210   G(X, Y) = K * 100 + FNR(5): TK = TK + K
1220 NEXT Y, X
1230 ' Guarantee a decent fight.
1240 IF TK >= 5 THEN 1280
1250 X = FNR(4): Y = FNR(4)
1260 IF G(X, Y) \ 100 < 3 THEN G(X, Y) = G(X, Y) + 100: TK = TK + 1
1270 GOTO 1240
1280 ' Two starbases in different sectors.
1290 FOR I = 1 TO 2
1300   X = FNR(4): Y = FNR(4)
1310   IF (G(X, Y) \ 10) MOD 10 = 1 THEN 1300
1320   G(X, Y) = G(X, Y) + 10
1330 NEXT I
1340 QX = FNR(4): QY = FNR(4): SX = FNR(8): SY = FNR(8)
1350 E = 3000: TP = 8: SD = 1: SL = 30: QF = 0: DK = 0
1360 GOSUB 3000                         ' fill the starting sector
1370 GOSUB 6000                         ' maybe we start docked
1380 '
2000 ' ---------- main loop ---------------------------------------
2010 GOSUB 4000                         ' draw everything
2020 IF TK = 0 THEN 8000
2030 IF E <= 0 THEN 8100
2040 IF SD > SL THEN 8200
2050 LOCATE 24, 1: COLOR 15
2060 PRINT "Command: (N)av (P)haser (T)orpedo (L)ong scan (Q)uit ";
2070 COLOR 7
2080 C$ = INKEY$: IF C$ = "" THEN 2080
2090 C = INSTR("NnPpTtLlQq", C$): IF C = 0 THEN 2080
2100 C = (C + 1) \ 2                     ' two letters per command
2110 GOSUB 6900                         ' clear the message area
2120 ON C GOSUB 5000, 5200, 5400, 5600, 5800
2130 IF QF THEN CLS: PRINT "Patrol abandoned.": END
2140 GOTO 2000
2150 '
3000 ' ---------- enter a sector: scatter its contents ----------
3010 FOR X = 1 TO 8: FOR Y = 1 TO 8: S(X, Y) = 0: NEXT Y, X
3020 S(SX, SY) = 1
3030 V = G(QX, QY): K = V \ 100: B = (V \ 10) MOD 10: ST = V MOD 10
3040 FOR I = 1 TO 3: KE(I) = 0: NEXT I
3050 FOR I = 1 TO K
3060   GOSUB 3500: S(X, Y) = 2: KX(I) = X: KY(I) = Y: KE(I) = 200 + FNR(200)
3070 NEXT I
3080 IF B THEN GOSUB 3500: S(X, Y) = 3: BX = X: BY = Y
3090 FOR I = 1 TO ST: GOSUB 3500: S(X, Y) = 4: NEXT I
3100 RETURN
3500 ' find a random empty cell -> X,Y
3510 X = FNR(8): Y = FNR(8)
3520 IF S(X, Y) THEN 3510
3530 RETURN
3540 '
4000 ' ---------- draw sector map and status ---------------------
4010 LOCATE 1, 1: COLOR 14: PRINT "S T A R   P A T R O L": COLOR 7
4020 LOCATE 2, 4: PRINT "1 2 3 4 5 6 7 8"
4030 FOR Y = 1 TO 8
4040   LOCATE 2 + Y, 1: PRINT USING "#"; Y;
4050   FOR X = 1 TO 8
4060     V = S(X, Y)
4070     ' COLOR per object type: 8=grey 15=white 12=red 11=cyan 14=yellow
4080     COLOR VAL(MID$("0815121114", V * 2 + 1, 2))
4090     LOCATE 2 + Y, 2 + X * 2: PRINT MID$(".@RB*", V + 1, 1);
4100   NEXT X
4110 NEXT Y
4120 COLOR 7
4130 LOCATE 3, 24: PRINT "Stardate    "; SD; "of"; SL; "  "
4140 LOCATE 4, 24: PRINT "Sector      "; QX; ","; QY; "  "
4150 LOCATE 5, 24: PRINT "Position    "; SX; ","; SY; "  "
4160 LOCATE 6, 24: PRINT "Energy      "; INT(E); "    "
4170 LOCATE 7, 24: PRINT "Torpedoes   "; TP; "  "
4180 LOCATE 8, 24: PRINT "Raiders left"; TK; "  "
4190 LOCATE 9, 24
4200 IF DK THEN COLOR 10: PRINT "Status       DOCKED   " ELSE IF K THEN COLOR 12: PRINT "Status       RED ALERT" ELSE COLOR 10: PRINT "Status       green    "
4210 COLOR 7
4220 RETURN
4230 '
5000 ' ---------- navigate ----------------------------------------
5010 INPUT "Direction 1-8"; DR
5020 IF DR < 1 OR DR > 8 THEN PRINT "Bad direction.": RETURN
5030 DR = INT(DR)
5040 INPUT "Distance 1-8"; N
5050 IF N < 1 OR N > 8 THEN PRINT "Bad distance.": RETURN
5060 N = INT(N)
5070 IF E < N * 20 THEN PRINT "Not enough energy.": RETURN
5080 E = E - N * 20: BK = 0
5090 FOR J = 1 TO N
5100   IF BK = 0 THEN GOSUB 5900
5110 NEXT J
5120 SD = SD + 1
5130 GOSUB 6000: GOSUB 7000
5140 RETURN
5150 '
5200 ' ---------- phasers -----------------------------------------
5210 IF K = 0 THEN PRINT "No raiders in this sector.": RETURN
5220 INPUT "Energy to fire"; PE
5230 IF PE <= 0 THEN RETURN
5240 IF PE > E THEN PRINT "You don't have that much energy.": RETURN
5250 E = E - PE: KN = K
5260 FOR I = 1 TO 3
5270   IF KE(I) <= 0 THEN 5320
5280   DS = SQR((KX(I) - SX) ^ 2 + (KY(I) - SY) ^ 2)
5290   ' Energy is shared between targets and fades with distance.
5300   H = INT(PE / KN * 2 / SQR(DS) * (RND + .5)): KE(I) = KE(I) - H
5310   PRINT "Phasers hit raider at"; KX(I); ","; KY(I); "for"; H: IF KE(I) <= 0 THEN GOSUB 6500
5320 NEXT I
5330 GOSUB 7000
5340 RETURN
5350 '
5400 ' ---------- photon torpedo ---------------------------------
5410 IF TP = 0 THEN PRINT "No torpedoes left.": RETURN
5420 INPUT "Torpedo direction 1-8"; DR
5430 IF DR < 1 OR DR > 8 THEN PRINT "Bad direction.": RETURN
5440 DR = INT(DR): TP = TP - 1: X = SX: Y = SY: CR = CSRLIN
5450 X = X + DX(DR): Y = Y + DY(DR)
5460 IF X < 1 OR X > 8 OR Y < 1 OR Y > 8 THEN PRINT "The torpedo flies off into space.": GOTO 5540
5470 LOCATE 2 + Y, 2 + X * 2: PRINT "+"; : SOUND 900 - DR * 50, 1: LOCATE CR, 1
5490 ' S() value 0..4 -> empty, ship, raider, base, star
5500 ON S(X, Y) + 1 GOTO 5450, 5450, 5510, 5520, 5530
5510 FOR I = 1 TO 3: IF KE(I) > 0 AND KX(I) = X AND KY(I) = Y THEN GOSUB 6500
5515 NEXT I: GOTO 5540
5520 PRINT "Oops - you destroyed your own starbase!": S(X, Y) = 0: B = 0: G(QX, QY) = G(QX, QY) - 10: GOTO 5540
5530 PRINT "The torpedo is swallowed by a star."
5540 GOSUB 7000
5550 RETURN
5560 '
5600 ' ---------- long-range scan -------------------------------
5610 PRINT "Long range scan (raiders/bases/stars):"
5620 FOR Y = QY - 1 TO QY + 1
5630   PRINT "     ";
5640   FOR X = QX - 1 TO QX + 1
5650     IF X < 1 OR X > 4 OR Y < 1 OR Y > 4 THEN PRINT " *** "; : GOTO 5670
5660     PRINT " "; RIGHT$("00" + MID$(STR$(G(X, Y)), 2), 3); " ";
5670   NEXT X
5680   PRINT
5690 NEXT Y
5700 RETURN
5800 ' ---------- quit ---------------------------------------------
5810 QF = 1: RETURN
5820 '
5900 ' ---------- one step of movement (BK=1 stops engines) -----
5910 NX = SX + DX(DR): NY = SY + DY(DR)
5920 IF NX >= 1 AND NX <= 8 AND NY >= 1 AND NY <= 8 THEN 5990
5930 ' We crossed the edge: hop into the neighbouring sector.
5940 TX = QX + DX(DR): TY = QY + DY(DR)
5950 IF TX < 1 OR TX > 4 OR TY < 1 OR TY > 4 THEN PRINT "Galactic barrier ahead - engines stop.": BK = 1: RETURN
5960 IF NX < 1 THEN NX = 8 ELSE IF NX > 8 THEN NX = 1
5970 IF NY < 1 THEN NY = 8 ELSE IF NY > 8 THEN NY = 1
5980 QX = TX: QY = TY: SX = NX: SY = NY: GOSUB 3000: PRINT "Entering sector"; QX; ","; QY: BK = 1: RETURN
5990 IF S(NX, NY) THEN PRINT "Navigation halted: object ahead.": BK = 1: RETURN
5995 S(SX, SY) = 0: SX = NX: SY = NY: S(SX, SY) = 1: RETURN
6000 ' ---------- are we docked? ----------------------------------
6010 DK = 0
6020 IF B = 0 THEN RETURN
6030 IF ABS(SX - BX) > 1 OR ABS(SY - BY) > 1 THEN RETURN
6040 DK = 1: E = 3000: TP = 8
6050 PRINT "Docked at starbase. Energy and torpedoes restored."
6060 RETURN
6500 ' ---------- raider I destroyed ------------------------------
6510 PRINT "*** Raider at"; KX(I); ","; KY(I); "destroyed! ***"
6520 S(KX(I), KY(I)) = 0: KE(I) = 0
6530 K = K - 1: TK = TK - 1: G(QX, QY) = G(QX, QY) - 100
6540 SOUND 120, 3: SOUND 80, 3
6550 RETURN
6900 ' ---------- clear message area (rows 12-23) ---------------
6910 FOR R = 12 TO 24: LOCATE R, 1: PRINT SPACE$(79); : NEXT R
6920 LOCATE 12, 1
6930 RETURN
7000 ' ---------- surviving raiders fire back -------------------
7010 IF K = 0 THEN RETURN
7020 IF DK THEN PRINT "Starbase shields protect you.": RETURN
7030 FOR I = 1 TO 3
7040   IF KE(I) <= 0 THEN 7080
7050   DS = SQR((KX(I) - SX) ^ 2 + (KY(I) - SY) ^ 2)
7060   H = INT(KE(I) / DS * (RND * .6 + .4)): E = E - H
7070   PRINT "Raider at"; KX(I); ","; KY(I); "hits you for"; H: SOUND 300, 1
7080 NEXT I
7090 RETURN
7100 '
8000 ' ---------- endings ---------------------------------------
8010 GOSUB 6900: COLOR 10
8020 PRINT "The last raider is gone. The galaxy is safe!"
8030 PRINT "Mission complete on stardate"; SD
8040 PLAY "T160 O3 L8 G > C E G4 E8 G2": COLOR 7: END
8100 GOSUB 6900: COLOR 12
8110 PRINT "Your ship has run out of energy and drifts helplessly."
8120 COLOR 7: END
8200 GOSUB 6900: COLOR 12
8210 PRINT "Time is up! "; TK; "raiders escaped to attack the colonies."
8220 COLOR 7: END
