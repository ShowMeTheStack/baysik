10 ' ============================================================
20 ' TITLE:    Music Box
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     music, sound, data, frequencies, animation
60 ' SUMMARY:  Plays folk tunes stored as note names in DATA, lighting up the keys of an on-screen piano.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Each tune is a list of notes like "E4" or "C#5" with a
100 '   length in eighths. Instead of using PLAY, this program
110 '   works out the frequency of every note itself and plays it
120 '   with SOUND, so you can see the maths of the musical scale.
130 '   A one-octave text piano lights up as each note sounds.
140 '
150 ' HOW TO USE
160 '   Choose a tune 1-3 (or Q to quit). Press any key during a
170 '   tune to stop it.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * Equal temperament: each semitone multiplies the
210 '     frequency by the 12th root of 2 (about 1.0595)
220 '   * A4 = 440 Hz as the reference pitch
230 '   * Decoding a note name: letter, optional #, octave digit
240 '   * Finding a tune in DATA by scanning for a marker
250 '   * Inverse video (COLOR 0,7) to highlight a key
260 '
270 ' THINGS TO TRY
280 '   * Type in a tune of your own between new markers
290 '   * Add a tempo setting that changes how long an eighth is
300 '   * Transpose: add 12 semitones to make it an octave higher
310 ' ============================================================
320 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS
1010 ' Semitone number of each letter, counting from C = 0.
1020 ' Index with INSTR("CDEFGAB", letter).
1030 DIM SM(7)
1040 FOR I = 1 TO 7: READ SM(I): NEXT I
1050 DATA 0, 2, 4, 5, 7, 9, 11
1060 TP = 2.2                             ' clock ticks per eighth note
1070 '
2000 ' ---------- menu ---------------------------------------------
2010 CLS: COLOR 14: PRINT "M U S I C   B O X": COLOR 7: PRINT
2020 PRINT "1  Ode to Joy (Beethoven)"
2030 PRINT "2  Twinkle, Twinkle, Little Star"
2040 PRINT "3  Frere Jacques"
2050 PRINT "Q  Quit"
2060 GOSUB 6000                          ' draw the piano
2070 K$ = INKEY$: IF K$ = "" THEN 2070
2080 IF K$ = "q" OR K$ = "Q" OR K$ = CHR$(27) THEN CLS: END
2090 T = VAL(K$): IF T < 1 OR T > 3 THEN 2070
2100 '
3000 ' ---------- find tune T in the DATA --------------------
3010 ' Tunes start with a "*" marker line. Skip T-1 of them.
3020 RESTORE 9000
3030 C = 0
3040 READ N$
3050 IF N$ = "*" THEN C = C + 1
3060 IF C < T THEN 3040
3070 READ TI$
3080 LOCATE 8, 1: PRINT SPACE$(60): LOCATE 8, 1: COLOR 11: PRINT "Now playing: "; TI$: COLOR 7
3090 '
4000 ' ---------- play notes until the "*" of the next tune ----
4010 READ N$
4020 IF N$ = "*" OR N$ = "END" THEN 2000
4030 READ L
4040 IF INKEY$ <> "" THEN 2000          ' any key stops the tune
4050 IF N$ = "R" THEN SOUND 32767, L * TP: GOTO 4010   ' a rest
4060 ' ---- decode the note name ----
4070 ' e.g. "C#5" -> letter C, sharp, octave 5
4080 LT$ = LEFT$(N$, 1)
4090 S = SM(INSTR("CDEFGAB", LT$))
4100 IF MID$(N$, 2, 1) = "#" THEN S = S + 1
4110 OC = VAL(RIGHT$(N$, 1))
4120 ' Semitones away from A4 (which is octave 4, semitone 9):
4130 D = (OC - 4) * 12 + (S - 9)
4140 ' Every semitone multiplies by 2^(1/12); 12 of them double it.
4150 FQ = 440 * 2 ^ (D / 12)
4160 LOCATE 10, 1: PRINT USING "Note \  \  semitone ### from A4  =  ####.## Hz"; N$; D; FQ
4170 K = S MOD 12: GOSUB 6500             ' light up the key
4180 SOUND FQ, L * TP * .9
4190 SOUND 32767, L * TP * .1             ' tiny gap between notes
4200 GOSUB 6600                          ' and switch it off again
4210 GOTO 4010
4220 '
6000 ' ---------- draw a one-octave piano (rows 14-19) ----------
6010 ' White keys are 5 characters wide starting at column 10,
6020 ' with a divider in the 5th column of each. A black key is
6030 ' a 3-wide dark strip centred on a divider (rows 14-16).
6040 COLOR 0, 7
6050 FOR R = 14 TO 19
6060   LOCATE R, 10
6070   FOR W = 1 TO 7: PRINT "    "; CHR$(179); : NEXT W
6080 NEXT R
6090 COLOR 0, 0
6100 FOR I = 0 TO 5
6110   IF I = 2 THEN 6130                 ' no black key between E and F
6120   FOR R = 14 TO 16: LOCATE R, 13 + 5 * I: PRINT "   "; : NEXT R
6130 NEXT I
6140 COLOR 7, 0
6150 LOCATE 20, 10: PRINT "  C    D    E    F    G    A    B"
6160 RETURN
6170 '
6500 ' ---------- highlight key K (0-11) ----------------------
6510 ' KX = screen column of each semitone, 2 digits each.
6520 ' BK$ has a "1" for each black key (C# D# F# G# A#).
6530 KX = VAL(MID$("111316182126283133363841", K * 2 + 1, 2))
6540 BK$ = MID$("010100101010", K + 1, 1)
6550 COLOR 15, 4
6560 IF BK$ = "1" THEN LOCATE 15, KX ELSE LOCATE 18, KX
6570 PRINT " o ";
6580 COLOR 7, 0
6590 RETURN
6600 ' ---------- un-highlight key K: repaint it -----------------
6610 IF BK$ = "1" THEN COLOR 0, 0: LOCATE 15, KX ELSE COLOR 0, 7: LOCATE 18, KX
6620 PRINT "   ";
6630 COLOR 7, 0
6640 RETURN
6650 '
9000 ' ---------- tunes: note, length in eighths ---------------
9010 DATA *, "Ode to Joy"
9020 DATA E4,2, E4,2, F4,2, G4,2, G4,2, F4,2, E4,2, D4,2
9030 DATA C4,2, C4,2, D4,2, E4,2, E4,3, D4,1, D4,4
9040 DATA E4,2, E4,2, F4,2, G4,2, G4,2, F4,2, E4,2, D4,2
9050 DATA C4,2, C4,2, D4,2, E4,2, D4,3, C4,1, C4,4
9100 DATA *, "Twinkle, Twinkle, Little Star"
9110 DATA C4,2, C4,2, G4,2, G4,2, A4,2, A4,2, G4,4
9120 DATA F4,2, F4,2, E4,2, E4,2, D4,2, D4,2, C4,4
9130 DATA G4,2, G4,2, F4,2, F4,2, E4,2, E4,2, D4,4
9140 DATA G4,2, G4,2, F4,2, F4,2, E4,2, E4,2, D4,4
9150 DATA C4,2, C4,2, G4,2, G4,2, A4,2, A4,2, G4,4
9160 DATA F4,2, F4,2, E4,2, E4,2, D4,2, D4,2, C4,4
9200 DATA *, "Frere Jacques"
9210 DATA C4,2, D4,2, E4,2, C4,2, C4,2, D4,2, E4,2, C4,2
9220 DATA E4,2, F4,2, G4,4, E4,2, F4,2, G4,4
9230 DATA G4,1, A4,1, G4,1, F4,1, E4,2, C4,2
9240 DATA G4,1, A4,1, G4,1, F4,1, E4,2, C4,2
9250 DATA C4,2, G3,2, C4,4, C4,2, G3,2, C4,4
9260 DATA END
