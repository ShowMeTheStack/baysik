10 ' ============================================================
20 ' TITLE:    The Clockmaker's House
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     adventure, text game, data, on gosub, parser
60 ' SUMMARY:  A tiny two-word text adventure whose rooms, exits and items all live in DATA statements.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   You stand in the house of a missing clockmaker. His great
100 '   tower clock has stopped. Explore seven rooms, find what
110 '   you need, and get the clock ticking again. The whole map
120 '   is stored in DATA lines, exactly the way hundreds of
130 '   1980s magazine adventures were written.
140 '
150 ' HOW TO USE
160 '   Type commands of one or two words and press Enter:
170 '     N  S  E  W         move in a direction
180 '     LOOK               describe the room again
190 '     GET LAMP           pick something up (TAKE also works)
200 '     DROP LAMP          put something down
210 '     INV                list what you carry
220 '     HELP / QUIT
230 '
240 ' CONCEPTS YOU WILL LEARN
250 '   * Storing a whole game world in DATA and READ
260 '   * Two-dimensional arrays as an exit table: X(room,dir)
270 '   * A verb table + ON ... GOSUB as a command dispatcher
280 '   * Splitting a typed line with INSTR / LEFT$ / MID$
290 '   * Upper-casing text the GW-BASIC way (MID$ statement)
300 '
310 ' THINGS TO TRY
320 '   * Add an eighth room: bump NR and add one DATA line
330 '   * Add a new verb such as READ or OPEN to the verb table
340 '   * Keep score: points for each new room you visit
345 '   * Type TRON then RUN to watch the line numbers of the verb
346 '     dispatcher fly past in [brackets]; TROFF turns it off
350 ' ============================================================
360 '
1000 ' ---------- set-up ------------------------------------------
1010 ' KEY OFF hides the function-key labels on line 25, the very
1020 ' first thing most GW-BASIC programs did.
1030 KEY OFF: CLS: DEFINT A-Z
1040 NR = 7: NI = 3: NV = 13
1050 ' R$ = room names, D$ = descriptions, X(r,d) = exits
1060 ' (d: 1=N 2=S 3=E 4=W). A 0 exit means "no way through".
1070 ' I$ = item names, P$ = item phrases, L = item location
1080 ' (a room number, or 0 when the player is carrying it).
1090 DIM R$(NR), D$(NR), X(NR, 4), I$(NI), P$(NI), L(NI)
1100 RESTORE 9100
1110 FOR I = 1 TO NR
1120   READ R$(I), D$(I), X(I, 1), X(I, 2), X(I, 3), X(I, 4)
1130 NEXT I
1140 FOR I = 1 TO NI: READ I$(I), P$(I), L(I): NEXT I
1150 P = 1: M = 0: Q = 0: W = 0
1160 COLOR 11: PRINT "THE CLOCKMAKER'S HOUSE": COLOR 7
1170 PRINT "The town clock has stopped. Perhaps you can fix it."
1180 PRINT "(Type HELP for a list of commands.)"
1190 GOSUB 4000
1200 '
2000 ' ---------- main loop -------------------------------------
2010 PRINT: LINE INPUT "> "; C$
2020 GOSUB 5000                ' upper-case and split into V$ / N$
2030 IF V$ = "" THEN 2010
2040 ' Look the verb up in the verb table (DATA at line 9000).
2050 V = 0: RESTORE 9000
2060 FOR J = 1 TO NV: READ W$: IF W$ = V$ THEN V = J
2070 NEXT J
2080 IF V = 0 THEN PRINT "I don't know how to "; V$; ".": GOTO 2010
2090 ' ON V GOSUB jumps to the V-th line number in the list.
2100 ' The four directions share one routine; it looks at V.
2110 ON V GOSUB 3000, 3000, 3000, 3000, 3100, 3200, 3200, 3300, 3400, 3400, 3500, 3500, 3600
2120 IF W THEN 8500
2130 IF Q THEN 8000
2140 GOTO 2010
2150 '
3000 ' ---------- move (V is 1..4) ------------------------------
3010 T = X(P, V)
3020 IF T = 0 THEN PRINT "You can't go that way.": RETURN
3030 IF T = 7 AND L(1) <> 0 THEN PRINT "The tower door is locked. A keyhole glints.": RETURN
3040 P = T: M = M + 1: GOSUB 4000
3050 IF P = 7 AND L(2) = 0 THEN W = 1
3060 RETURN
3100 ' ---------- look -------------------------------------------
3110 GOSUB 4000: RETURN
3200 ' ---------- get / take -------------------------------------
3210 IF N$ = "" THEN PRINT "Get what?": RETURN
3220 GOSUB 6000
3230 IF F = 0 THEN PRINT "There is no "; N$; " here.": RETURN
3240 IF L(F) = 0 THEN PRINT "You already have it.": RETURN
3250 IF L(F) <> P THEN PRINT "There is no "; N$; " here.": RETURN
3260 IF P = 6 AND L(3) <> 0 THEN PRINT "You grope about in the dark but find nothing.": RETURN
3270 L(F) = 0: PRINT "Taken.": SOUND 880, 1: RETURN
3300 ' ---------- drop -------------------------------------------
3310 IF N$ = "" THEN PRINT "Drop what?": RETURN
3320 GOSUB 6000
3330 IF F = 0 THEN PRINT "You have no "; N$; ".": RETURN
3340 IF L(F) <> 0 THEN PRINT "You have no "; N$; ".": RETURN
3350 L(F) = P: PRINT "Dropped.": RETURN
3400 ' ---------- inventory --------------------------------------
3410 K = 0: PRINT "You are carrying:"
3420 FOR J = 1 TO NI
3430   IF L(J) = 0 THEN PRINT "  "; P$(J): K = K + 1
3440 NEXT J
3450 IF K = 0 THEN PRINT "  nothing at all."
3460 RETURN
3500 ' ---------- quit -------------------------------------------
3510 Q = 1: RETURN
3600 ' ---------- help -------------------------------------------
3610 PRINT "Commands: N S E W, LOOK, GET thing, DROP thing, INV, QUIT"
3620 RETURN
3630 '
4000 ' ---------- describe the current room ---------------------
4010 PRINT: COLOR 14: PRINT R$(P): COLOR 7
4020 ' The pantry has no window. Without the lamp you see nothing.
4030 IF P = 6 AND L(3) <> 0 THEN PRINT "It is pitch dark. You hear something scuttle.": RETURN
4040 PRINT D$(P)
4050 E$ = ""
4060 FOR J = 1 TO 4
4070   IF X(P, J) THEN E$ = E$ + " " + MID$("NSEW", J, 1)
4080 NEXT J
4090 PRINT "Exits:"; E$
4100 FOR J = 1 TO NI
4110   IF L(J) = P THEN PRINT "You see "; P$(J); "."
4120 NEXT J
4130 RETURN
4140 '
5000 ' ---------- upper-case C$, then split into verb and noun ---
5010 ' GW-BASIC 2.0 had no UCASE$, so we flip each lower-case
5020 ' letter ourselves. ASC("a")=97 and ASC("A")=65: the gap is
5030 ' 32. The MID$ *statement* overwrites characters in place.
5040 FOR J = 1 TO LEN(C$)
5050   A = ASC(MID$(C$, J, 1))
5060   IF A > 96 AND A < 123 THEN MID$(C$, J, 1) = CHR$(A - 32)
5070 NEXT J
5080 ' strip leading spaces
5090 IF LEFT$(C$, 1) = " " THEN C$ = MID$(C$, 2): GOTO 5090
5100 SP = INSTR(C$, " ")
5110 IF SP = 0 THEN V$ = C$: N$ = "": RETURN
5120 V$ = LEFT$(C$, SP - 1): N$ = MID$(C$, SP + 1)
5130 RETURN
5140 '
6000 ' ---------- find item named N$ -> F (0 if unknown) --------
6010 F = 0
6020 FOR J = 1 TO NI
6030   IF I$(J) = N$ THEN F = J
6040 NEXT J
6050 RETURN
6060 '
8000 ' ---------- quit -------------------------------------------
8010 PRINT "The clock stays silent. Goodbye after"; M; "moves."
8020 END
8500 ' ---------- victory ----------------------------------------
8510 PRINT
8520 COLOR 10
8530 PRINT "You fit the brass gear onto the great wheel and give it a"
8540 PRINT "push. TICK... TOCK... The old clock is alive again!"
8550 COLOR 7
8560 PLAY "T180 O3 L8 C E G > C4 < G E C4"
8570 PRINT "You won in"; M; "moves."
8580 END
8590 '
9000 ' ---------- verb table (order matches ON V GOSUB) ---------
9010 DATA N, S, E, W, LOOK, GET, TAKE, DROP, INV, I, QUIT, Q, HELP
9100 ' ---------- rooms: name, description, N, S, E, W ----------
9110 DATA "Front Hall","Dusty portraits of clocks line the walls.",2,0,3,4
9120 DATA "Workshop","Benches covered in springs and tiny screws.",0,1,5,0
9130 DATA "Parlor","A cold fireplace and a ticking-less mantel clock.",5,0,0,1
9140 DATA "Kitchen","Copper pots hang over a long oak table.",6,0,1,0
9150 DATA "Library","Shelves of horology books. A spiral stair goes north.",7,3,0,2
9160 DATA "Pantry","Shelves of jam jars and a sack of flour.",0,4,0,0
9170 DATA "Clock Tower","Huge wheels fill the room. One gear is missing!",0,5,0,0
9200 ' ---------- items: word, phrase, starting room ------------
9210 DATA KEY,"a small iron key",6
9220 DATA GEAR,"a shiny brass gear",2
9230 DATA LAMP,"an oil lamp",4
