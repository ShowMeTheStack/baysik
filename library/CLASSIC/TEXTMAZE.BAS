10 ' ============================================================
20 ' TITLE:    Text Maze Runner
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     maze, algorithm, stack, inkey$, arrow keys, game
60 ' SUMMARY:  Generates a fresh random maze in text mode each game, then times you as you run from start to exit.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Builds a "perfect" maze (exactly one route between any two
100 '   spots) using the depth-first backtracking method, with a
110 '   home-made stack because GW-BASIC has no recursion. The
120 '   maze is drawn with solid block characters. Guide the
130 '   smiley face from the top-left to the exit at bottom-right.
140 '
150 ' HOW TO USE
160 '   Arrow keys (or W A S D) to move.  N = new maze.  Q = quit.
170 '
180 ' CONCEPTS YOU WILL LEARN
190 '   * Maze generation by "carving" walls out of a solid grid
200 '   * A stack built from two arrays and a pointer SP
210 '   * Reading arrow keys: INKEY$ returns TWO characters,
220 '     CHR$(0) followed by a scan code (H=up P=down K=left M=right)
230 '   * Moving a character without redrawing the whole screen
240 '
250 ' THINGS TO TRY
260 '   * Change CW and CH for bigger or smaller mazes
270 '   * Leave a trail of dots behind the player
280 '   * Add a key you must collect before the exit opens
290 ' ============================================================
300 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS: RANDOMIZE TIMER
1010 CW = 25: CH = 11                    ' maze size in cells
1020 GW = CW * 2 + 1: GH = CH * 2 + 1    ' grid size in characters
1030 DIM M(GW, GH), SX(CW * CH), SY(CW * CH), DX(4), DY(4)
1040 FOR I = 1 TO 4: READ DX(I), DY(I): NEXT I
1050 DATA 0,-2, 2,0, 0,2, -2,0
1060 '
2000 ' ---------- build a new maze ---------------------------
2010 CLS: LOCATE 12, 30: PRINT "Digging a new maze..."
2020 ' Start with solid rock everywhere (1 = wall).
2030 FOR X = 1 TO GW: FOR Y = 1 TO GH: M(X, Y) = 1: NEXT Y, X
2040 ' Cells sit at even grid positions 2,4,6...; the odd
2050 ' positions between them are the walls we may knock out.
2060 X = 2: Y = 2: M(X, Y) = 0
2070 SP = 1: SX(1) = X: SY(1) = Y
2080 '
2100 ' ---- carving loop ------------------------------------
2110 IF SP = 0 THEN 2400                 ' stack empty: finished
2120 X = SX(SP): Y = SY(SP)
2130 ' Count the neighbours (2 steps away) that are still rock.
2140 N = 0: D$ = ""
2150 FOR D = 1 TO 4
2160   NX = X + DX(D): NY = Y + DY(D)
2170   IF NX < 2 OR NX > GW - 1 OR NY < 2 OR NY > GH - 1 THEN 2190
2180   IF M(NX, NY) = 1 THEN N = N + 1: D$ = D$ + CHR$(48 + D)
2190 NEXT D
2200 IF N = 0 THEN SP = SP - 1: GOTO 2110    ' dead end: back up (pop)
2210 ' Pick one at random, knock out the wall between, move there.
2220 D = VAL(MID$(D$, INT(RND * N) + 1, 1))
2230 M(X + DX(D) / 2, Y + DY(D) / 2) = 0
2240 X = X + DX(D): Y = Y + DY(D): M(X, Y) = 0
2250 SP = SP + 1: SX(SP) = X: SY(SP) = Y    ' push
2260 GOTO 2110
2270 '
2400 ' ---------- draw it ---------------------------------------
2410 CLS
2420 FOR Y = 1 TO GH
2430   L$ = ""
2440   FOR X = 1 TO GW
2450     IF M(X, Y) THEN L$ = L$ + CHR$(219) ELSE L$ = L$ + " "
2460   NEXT X
2470   LOCATE Y, 1: COLOR 2: PRINT L$;
2480 NEXT Y
2490 EX = GW - 1: EY = GH - 1           ' exit cell
2500 LOCATE EY, EX: COLOR 14 + 16: PRINT "E";   ' +16 = blinking
2510 COLOR 7
2520 LOCATE 2, GW + 4: PRINT "TEXT MAZE RUNNER"
2530 LOCATE 4, GW + 4: PRINT "Arrows / WASD move"
2540 LOCATE 5, GW + 4: PRINT "N = new maze"
2550 LOCATE 6, GW + 4: PRINT "Q = quit"
2560 PX = 2: PY = 2: MV = 0: T0 = TIMER
2570 GOSUB 4000
2580 '
3000 ' ---------- game loop -----------------------------------------
3010 K$ = INKEY$: IF K$ = "" THEN GOSUB 4100: GOTO 3010
3020 VX = 0: VY = 0
3030 ' Arrow keys arrive as CHR$(0) + a letter. Use RIGHT$ to
3040 ' look at the second character.
3050 IF LEN(K$) = 2 THEN K$ = RIGHT$(K$, 1): ON INSTR("HPKM", K$) GOTO 3100, 3110, 3120, 3130: GOTO 3010
3060 K = INSTR("wWsSaAdDnNqQ", K$)
3070 IF K = 0 THEN 3010
3080 ON (K + 1) \ 2 GOTO 3100, 3110, 3120, 3130, 2000, 9000
3100 VY = -1: GOTO 3200
3110 VY = 1: GOTO 3200
3120 VX = -1: GOTO 3200
3130 VX = 1
3200 IF M(PX + VX, PY + VY) THEN SOUND 100, .5: GOTO 3010   ' bump!
3210 LOCATE PY, PX: PRINT " ";          ' erase old position
3220 PX = PX + VX: PY = PY + VY: MV = MV + 1
3230 GOSUB 4000
3240 IF PX = EX AND PY = EY THEN 5000
3250 GOTO 3010
3260 '
4000 ' draw the player (CHR$(2) is the solid smiley face)
4010 LOCATE PY, PX: COLOR 15: PRINT CHR$(2); : COLOR 7
4020 LOCATE 9, GW + 4: PRINT "Moves:"; MV; "  "
4030 RETURN
4100 ' update the clock display
4110 LOCATE 10, GW + 4: PRINT USING "Time: ###.# s"; TIMER - T0
4120 RETURN
4130 '
5000 ' ---------- reached the exit ----------------------------
5010 TT = TIMER - T0
5020 LOCATE 13, GW + 4: COLOR 10: PRINT "ESCAPED!": COLOR 7
5030 LOCATE 14, GW + 4: PRINT USING "###.# seconds"; TT
5040 PLAY "T180 O4 L16 C D E F G A B > C"
5050 LOCATE 16, GW + 4: PRINT "N = new maze, Q = quit"
5060 K$ = INKEY$
5070 IF K$ = "n" OR K$ = "N" THEN 2000
5080 IF K$ = "q" OR K$ = "Q" OR K$ = CHR$(27) THEN 9000
5090 GOTO 5060
9000 COLOR 7: CLS: PRINT "Thanks for running the maze!"
9010 END
