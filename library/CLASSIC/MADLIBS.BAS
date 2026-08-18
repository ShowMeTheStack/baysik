10 ' ============================================================
20 ' TITLE:    Silly Stories
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     words, strings, instr, data, word wrap
60 ' SUMMARY:  A fill-in-the-blanks story game: give it nouns, verbs and adjectives, get back a ridiculous tale.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Stories are stored in DATA lines with blanks written like
100 '   [NOUN] or [ANIMAL]. The program finds each blank, asks you
110 '   for that kind of word (without showing the story!), puts
120 '   your words in, and then prints the finished story neatly
130 '   word-wrapped to fit the screen.
140 '
150 ' HOW TO USE
160 '   Pick a story 1-3, then type a word for each request.
170 '   Choose 0 to quit.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * Searching a string with INSTR(start, text, find)
210 '   * Cutting and joining text with LEFT$, MID$ and +
220 '   * Skipping through DATA to the Nth story with RESTORE
230 '   * Word wrap: break lines at the last space that fits
240 '
250 ' THINGS TO TRY
260 '   * Write a fourth story (add DATA lines and change NS)
270 '   * Make it remember the words and print them at the end
280 '   * Save each finished story to a file with OPEN "A"
290 ' ============================================================
300 '
1000 KEY OFF: CLS
1010 NS = 3                              ' number of stories
1020 WD = 60                             ' wrap width
1030 '
2000 COLOR 14: PRINT "SILLY STORIES": COLOR 7: PRINT
2010 PRINT "1  The School Trip"
2020 PRINT "2  My Robot Butler"
2030 PRINT "3  The Pirate's Breakfast"
2040 INPUT "Choose a story (0 to quit)"; N
2050 IF N = 0 THEN PRINT "Goodbye!": END
2060 IF N < 1 OR N > NS OR N <> INT(N) THEN 2040
2070 '
3000 ' ---------- read story N into S$ -------------------------
3010 ' Each story is several DATA strings, ending with "#".
3020 ' To reach story N we read past N-1 "#" markers.
3030 RESTORE 9000
3040 K = 1
3050 IF K = N THEN 3090
3060 READ T$
3070 IF T$ = "#" THEN K = K + 1
3080 GOTO 3050
3090 S$ = ""
3100 READ T$: IF T$ = "#" THEN 4000
3110 S$ = S$ + T$ + " "
3120 GOTO 3100
3130 '
4000 ' ---------- ask for each [BLANK] ----------------------------
4010 PRINT
4020 P = INSTR(S$, "[")
4030 IF P = 0 THEN 5000                  ' no more blanks
4040 Q = INSTR(P, S$, "]")
4050 B$ = MID$(S$, P + 1, Q - P - 1)     ' e.g. "PLURAL NOUN"
4060 A$ = "a": IF INSTR("AEIOU", LEFT$(B$, 1)) THEN A$ = "an"
4070 PRINT "Give me "; A$; " "; B$;
4080 LINE INPUT ": "; W$
4090 IF W$ = "" THEN W$ = "thingamajig"
4100 ' Glue: everything before "[", your word, everything after "]"
4110 S$ = LEFT$(S$, P - 1) + W$ + MID$(S$, Q + 1)
4120 GOTO 4020
4130 '
5000 ' ---------- print with word wrap ------------------------------
5010 CLS: COLOR 11: PRINT "Here is your story:": COLOR 15: PRINT
5020 IF LEN(S$) <= WD THEN PRINT S$: GOTO 5100
5030 ' Look backwards from column WD+1 for a space to break at.
5040 B = WD + 1
5050 IF MID$(S$, B, 1) <> " " AND B > 1 THEN B = B - 1: GOTO 5050
5060 IF B = 1 THEN B = WD          ' one enormous word: chop it
5070 PRINT LEFT$(S$, B)
5080 S$ = MID$(S$, B + 1)
5090 GOTO 5020
5100 COLOR 7: PRINT
5110 GOTO 2000
5120 '
9000 ' ---------- the stories ---------------------------------
9010 DATA "Last week our class went on a trip to the [PLACE]."
9020 DATA "Our teacher, Mr. [SILLY NAME], brought [NUMBER] [PLURAL NOUN]"
9030 DATA "in a bag. When we arrived a [ADJECTIVE] [ANIMAL] ran up and"
9040 DATA "began to [VERB] all over the bus! Everyone screamed [EXCLAMATION]"
9050 DATA "and we had to go home early. Best trip ever.", "#"
9060 DATA "I built a robot butler out of a [HOUSEHOLD OBJECT] and"
9070 DATA "[NUMBER] old [PLURAL NOUN]. Every morning it says"
9080 DATA "'Good morning, [YOUR NAME], shall I [VERB] your [BODY PART]?'"
9090 DATA "Yesterday it got confused and served me [FOOD] in a"
9100 DATA "[ADJECTIVE] sock. I think I need to check its wiring.", "#"
9110 DATA "Captain [SILLY NAME] woke up in a [ADJECTIVE] mood."
9120 DATA "'Bring me [NUMBER] barrels of [FOOD]!' he roared to the"
9130 DATA "[PLURAL NOUN]. His parrot, who was secretly a [ANIMAL], said"
9140 DATA "'[EXCLAMATION]!' and flew off to [PLACE]. The crew decided"
9150 DATA "to [VERB] instead.", "#"
