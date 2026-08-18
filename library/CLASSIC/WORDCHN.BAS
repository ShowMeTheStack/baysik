10 ' ============================================================
20 ' TITLE:    Word Chain
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     words, strings, inkey$, timer, game
60 ' SUMMARY:  Take turns with the computer naming animals; each must start with the last letter of the one before.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   The computer says an animal, e.g. TIGER. You must reply
100 '   with an animal starting with R (RABBIT), then it answers
110 '   with one starting with T, and so on. No repeats allowed,
120 '   and you only have 20 seconds per answer! If the computer
130 '   runs out of animals for a letter, you win.
140 '
150 ' HOW TO USE
160 '   Type your word and press Enter. Backspace works.
170 '   Press Esc to give up.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * Writing your own line editor with INKEY$, so the clock
210 '     can keep ticking while you type (INPUT would freeze it)
220 '   * TIMER for a countdown
230 '   * Remembering used words in one long string and looking
240 '     them up with INSTR
250 '   * RIGHT$ / LEFT$ to compare first and last letters
260 '
270 ' THINGS TO TRY
280 '   * Change the theme: put countries or foods in the DATA
290 '   * Score points for longer words
300 '   * Make the time limit shrink every round
310 ' ============================================================
320 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 NW = 0
1020 ' Count the words in the DATA list (it ends with "*").
1030 READ W$: IF W$ <> "*" THEN NW = NW + 1: GOTO 1030
1040 DIM W$(NW)
1050 RESTORE
1060 FOR I = 1 TO NW: READ W$(I): NEXT I
1070 ' U$ holds every used word between slashes: "/CAT/DOG/".
1080 ' Searching for "/DOG/" can't accidentally match "DOGFISH".
1090 U$ = "/": SC = 0: TL = 20
1100 COLOR 14: PRINT "WORD CHAIN - ANIMALS": COLOR 7
1110 PRINT "Each animal must begin with the last letter of the one before."
1120 PRINT
1130 ' Computer starts with a random word.
1140 C$ = W$(INT(RND * NW) + 1)
1150 GOTO 3060
1160 '
2000 ' ---------- player's turn ----------------------------------
2010 L$ = RIGHT$(C$, 1)
2020 PRINT "Your animal starting with "; L$; ": ";
2030 GOSUB 6000                         ' timed input -> A$
2040 IF A$ = CHR$(27) THEN PRINT: PRINT "You give up!": GOTO 9000
2050 IF A$ = "" THEN PRINT: COLOR 12: PRINT "Time's up!": COLOR 7: GOTO 9000
2060 PRINT
2070 IF LEFT$(A$, 1) <> L$ THEN PRINT "That doesn't start with "; L$; "!": GOTO 9000
2080 IF LEN(A$) < 3 THEN PRINT "At least three letters, please.": GOTO 2020
2090 IF INSTR(U$, "/" + A$ + "/") THEN PRINT A$; " has already been used!": GOTO 9000
2100 U$ = U$ + A$ + "/": SC = SC + 1
2110 SOUND 1000, 1
2120 '
3000 ' ---------- computer's turn --------------------------------
3010 L$ = RIGHT$(A$, 1)
3020 ' Start at a random spot in the list and wrap round, so the
3030 ' computer doesn't always pick the same word.
3040 S = INT(RND * NW): C$ = ""
3050 FOR K = 1 TO NW: I = (S + K) MOD NW + 1
3055   IF C$ = "" AND LEFT$(W$(I), 1) = L$ AND INSTR(U$, "/" + W$(I) + "/") = 0 THEN C$ = W$(I)
3058 NEXT K
3059 IF C$ = "" THEN 8000
3060 U$ = U$ + C$ + "/"
3070 COLOR 11: PRINT "Computer: "; C$: COLOR 7
3080 GOTO 2000
3090 '
6000 ' ---------- timed line input -> A$ --------------------------
6010 ' Returns A$ in capitals, "" if time ran out, CHR$(27) on Esc.
6020 A$ = "": T0 = TIMER
6030 R = CSRLIN: C = POS(0)
6040 ' Show the seconds left at the right of the line.
6050 TR = TL - INT(TIMER - T0)
6060 IF TIMER < T0 THEN T0 = T0 - 86400  ' midnight wrap-around
6070 LOCATE R, 72: PRINT USING "[##s]"; TR; : LOCATE R, C + LEN(A$)
6080 IF TR <= 0 THEN A$ = "": RETURN
6090 K$ = INKEY$: IF K$ = "" THEN 6050
6100 IF K$ = CHR$(27) THEN A$ = K$: RETURN
6110 IF K$ = CHR$(13) THEN IF A$ = "" THEN 6050 ELSE RETURN
6120 IF K$ = CHR$(8) AND LEN(A$) > 0 THEN A$ = LEFT$(A$, LEN(A$) - 1): LOCATE R, C: PRINT A$; " "; : GOTO 6050
6130 ' keep letters only; make lower case into capitals
6140 IF K$ >= "a" AND K$ <= "z" THEN K$ = CHR$(ASC(K$) - 32)
6150 IF K$ < "A" OR K$ > "Z" OR LEN(A$) > 20 THEN 6050
6160 A$ = A$ + K$: LOCATE R, C: PRINT A$;
6170 GOTO 6050
6180 '
8000 ' ---------- computer stuck: player wins ----------------
8010 COLOR 10
8020 PRINT "I can't think of an animal starting with "; L$; ". You win!"
8030 COLOR 7
8040 PLAY "T180 O4 L8 E G > C4"
8050 PRINT "You named"; SC; "animals."
8060 END
9000 ' ---------- player loses ------------------------------------
9010 PRINT "Game over. You named"; SC; "animals."
9020 SOUND 200, 4: SOUND 150, 8
9030 END
9100 ' ---------- the computer's vocabulary ----------------------
9110 DATA ANT,BEAR,CAMEL,DONKEY,EAGLE,EMU,FERRET,GOAT,HORSE,IBIS
9120 DATA JACKAL,KOALA,LION,LLAMA,MOLE,NEWT,OTTER,OWL,PANDA,QUAIL
9130 DATA RABBIT,RAT,SEAL,SNAKE,TIGER,TOAD,URCHIN,VOLE,WOLF,YAK
9140 DATA ZEBRA,ELK,ELEPHANT,EEL,KANGAROO,TURTLE,TROUT,TAPIR,TERMITE
9150 DATA RHINO,RAVEN,REINDEER,ROBIN,HYENA,HAMSTER,DEER,DOLPHIN,DUCK
9160 DATA LEOPARD,LEMUR,LOBSTER,NARWHAL,ORCA,OCTOPUS,SHEEP,SKUNK
9170 DATA SALMON,SPIDER,KIWI,KESTREL,YETI,GECKO,GIRAFFE,GORILLA
9180 DATA *
