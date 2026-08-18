10 ' ============================================================
20 ' TITLE:    Artillery Duel
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Advanced
50 ' TAGS:     graphics, screen 1, physics, game, two player
60 ' SUMMARY:  Two cannons on a CGA mountain range lob shells at each other through gravity and gusting wind.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   A two-player game in 320x200 four-colour CGA graphics.
100 '   Random hills are generated, a cannon is placed at each
110 '   side, and players take turns typing an angle and a power.
120 '   The shell flies along a real ballistic curve, pushed by
130 '   the wind, and blasts a crater wherever it lands. First to
140 '   three hits wins.
150 '
160 ' HOW TO USE
170 '   Type an angle (1-89 degrees, measured up from the ground)
180 '   and a power (1-100). Watch the wind arrow at the top.
190 '   An angle of 0 quits the game.
200 '
210 ' CONCEPTS YOU WILL LEARN
220 '   * Projectile motion: velocity changes position, gravity
230 '     (and wind) change velocity, a little every time step
240 '   * SIN and COS with degrees converted to radians
250 '   * A height map H(x) for terrain, drawn with LINE
260 '   * Blowing craters by changing the height map
270 '   * SCREEN 1 text and graphics sharing one screen
280 '
290 ' THINGS TO TRY
300 '   * Change gravity GR to make a Moon level
310 '   * Let the computer play one side (guess, then adjust!)
320 '   * Make the shell bounce once before exploding
330 ' ============================================================
340 '
1000 KEY OFF: SCREEN 1: COLOR 0, 0: CLS
1010 RANDOMIZE TIMER
1020 ' Palette 0 gives colours 1 = green, 2 = red, 3 = brown/yellow.
1030 DIM H(319), TX(2), TY(2), SC(2), PX(400), PY(400)
1040 PI = 3.14159: GR = 50: DT = .04
1050 SC(1) = 0: SC(2) = 0
1060 '
2000 ' ---------- new round: hills, tanks, wind ---------------
2010 CLS
2020 ' Terrain by "random walk": each column's height is the
2030 ' last one plus a slope, and the slope itself drifts.
2040 Y = 150: SL = 0
2050 FOR X = 0 TO 319
2060   SL = SL + (RND - .5) * .6
2070   IF SL > 1.5 THEN SL = 1.5
2080   IF SL < -1.5 THEN SL = -1.5
2090   Y = Y + SL
2100   IF Y < 80 THEN Y = 80: SL = .3
2110   IF Y > 185 THEN Y = 185: SL = -.3
2120   H(X) = INT(Y)
2130 NEXT X
2140 ' Pick tank spots and flatten the ground under them.
2150 TX(1) = 20 + INT(RND * 40): TX(2) = 260 + INT(RND * 40)
2160 FOR P = 1 TO 2
2170   TY(P) = H(TX(P))
2180   FOR X = TX(P) - 8 TO TX(P) + 8: H(X) = TY(P): NEXT X
2190 NEXT P
2200 FOR X = 0 TO 319: LINE (X, H(X))-(X, 199), 1: NEXT X
2210 FOR P = 1 TO 2: GOSUB 7000: NEXT P
2220 WD = INT(RND * 21) - 10             ' wind, pixels/sec^2
2230 TU = 1                               ' whose turn
2240 '
3000 ' ---------- one turn ---------------------------------------
3010 GOSUB 7500                            ' status line
3020 LOCATE 2, 1: PRINT "Player"; TU; : INPUT " angle"; AN
3030 IF AN = 0 THEN 9000
3040 IF AN < 0 OR AN > 89 THEN GOSUB 7600: GOTO 3010
3050 LOCATE 3, 1: PRINT "Player"; TU; : INPUT " power"; PW
3060 IF PW < 1 OR PW > 100 THEN GOSUB 7600: GOTO 3010
3070 GOSUB 7600                            ' clear prompt area
3080 '
4000 ' ---------- fly the shell -------------------------------
4010 ' Degrees to radians: multiply by pi/180.
4020 A = AN * PI / 180
4030 V = PW * 1.6                          ' launch speed, pixels/sec
4040 VX = V * COS(A): VY = -V * SIN(A)     ' screen y grows DOWNWARD
4050 IF TU = 2 THEN VX = -VX               ' player 2 fires leftwards
4060 X = TX(TU): Y = TY(TU) - 8: N = 0
4070 SOUND 80, 2
4080 ' Euler steps: move by velocity, then let gravity and wind
4090 ' nudge the velocity. Small DT = smoother, slower curve.
4100 X = X + VX * DT: Y = Y + VY * DT
4110 VY = VY + GR * DT: VX = VX + WD * DT
4120 IF X < 0 OR X > 319 THEN 4300        ' flew off the side
4130 IF Y >= H(INT(X)) THEN 5000           ' hit the ground
4140 IF Y < 0 THEN 4100                    ' above the screen: keep going
4150 IF N < 400 THEN N = N + 1: PX(N) = X: PY(N) = Y: PSET (X, Y), 3
4160 FOR Z = 1 TO 20: NEXT Z               ' tiny delay so we can see it
4170 GOTO 4100
4300 LOCATE 2, 1: PRINT "Missed - right off the map!"
4310 GOSUB 6500: GOTO 6000
4320 '
5000 ' ---------- explosion & crater --------------------------
5010 R = 10
5020 FOR K = 1 TO R
5030   CIRCLE (X, Y), K, 2 + (K MOD 2)
5040   SOUND 40 + RND * 60, .3
5050 NEXT K
5060 ' Did it land near a tank?
5070 HT = 0
5080 FOR P = 1 TO 2
5090   IF SQR((X - TX(P)) ^ 2 + (Y - TY(P)) ^ 2) < 13 THEN HT = P
5100 NEXT P
5110 ' Erase the blast and carve a round crater into H().
5120 CIRCLE (X, Y), R, 0: PAINT (X, Y), 0, 0
5130 FOR XX = INT(X) - R TO INT(X) + R
5140   IF XX < 0 OR XX > 319 THEN 5190
5150   DY = R * R - (XX - X) ^ 2: IF DY < 0 THEN DY = 0 ELSE DY = SQR(DY)
5160   NB = INT(Y + DY): IF NB > 199 THEN NB = 199
5170   IF NB > H(XX) THEN LINE (XX, H(XX))-(XX, NB), 0: H(XX) = NB
5180   LINE (XX, H(XX))-(XX, 199), 1     ' redraw ground below
5190 NEXT XX
5200 GOSUB 6500
5210 FOR P = 1 TO 2: IF HT <> P THEN GOSUB 7000
5220 NEXT P
5230 IF HT = 0 THEN LOCATE 2, 1: PRINT "Close, but no hit.": GOTO 6000
5240 ' ---- a hit! ----
5250 W = 3 - HT: IF HT = TU THEN LOCATE 2, 1: PRINT "Oops! Player"; TU; "hit himself!" ELSE LOCATE 2, 1: PRINT "DIRECT HIT on player"; HT; "!"
5260 SC(W) = SC(W) + 1
5270 FOR K = 1 TO 3: SOUND 600, 2: SOUND 900, 2: NEXT K
5280 GOSUB 7500
5290 IF SC(W) >= 3 THEN 8000
5300 LOCATE 3, 1: PRINT "Press a key for the next round";
5310 IF INKEY$ = "" THEN 5310
5320 GOTO 2000
5330 '
6000 ' ---------- next player's turn ------------------------
6010 FOR Z = 1 TO 600: NEXT Z
6020 GOSUB 7600
6030 TU = 3 - TU                         ' 1 -> 2, 2 -> 1
6040 GOTO 3000
6500 ' ---------- erase the dotted trail ---------------------------
6510 FOR K = 1 TO N
6520   IF PY(K) < H(INT(PX(K))) THEN PSET (PX(K), PY(K)), 0
6530 NEXT K
6540 RETURN
7000 ' ---------- draw tank P ----------------------------------------
7010 LINE (TX(P) - 6, TY(P) - 4)-(TX(P) + 6, TY(P) - 1), 2, BF
7020 LINE (TX(P) - 3, TY(P) - 7)-(TX(P) + 3, TY(P) - 4), 2, BF
7030 RETURN
7500 ' ---------- status line with score and wind arrow -----------
7510 LOCATE 1, 1: PRINT USING "P1:#  P2:#   Wind "; SC(1); SC(2);
7520 W$ = STRING$(ABS(WD) \ 2, "=")
7530 IF WD > 0 THEN PRINT W$; ">"; SPACE$(8) ELSE IF WD < 0 THEN PRINT "<"; W$; SPACE$(8) ELSE PRINT "calm      "
7540 RETURN
7600 ' ---------- clear text rows 2 and 3 --------------------------
7610 LOCATE 2, 1: PRINT SPACE$(39): LOCATE 3, 1: PRINT SPACE$(39);
7620 RETURN
7630 '
8000 ' ---------- winner ----------------------------------------
8010 LOCATE 3, 1: PRINT "PLAYER"; W; "WINS THE DUEL!"
8020 PLAY "T150 O3 L8 G G G > C2"
8030 LOCATE 4, 1: PRINT "Press a key...";
8040 IF INKEY$ = "" THEN 8040
8050 SCREEN 0: WIDTH 80: PRINT "Final score:"; SC(1); "to"; SC(2): END
9000 SCREEN 0: WIDTH 80: PRINT "Cease fire! Score:"; SC(1); "to"; SC(2)
9010 END
