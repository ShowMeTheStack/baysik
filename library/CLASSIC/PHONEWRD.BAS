10 ' ============================================================
20 ' TITLE:    Phone Word Speller
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     strings, combinatorics, keypad, instr, data
60 ' SUMMARY:  Turns words into telephone digits and hunts for real words hidden in your phone number.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Telephone keypads put letters on the digits: 2=ABC, 3=DEF
100 '   ... 9=WXYZ. Businesses love numbers like 1-800-FLOWERS.
110 '   Option 1 converts any word to its digits. Option 2 takes
120 '   a phone number, counts how many letter spellings it has,
130 '   lists the first few with an "odometer" counter, and then
140 '   searches a built-in word list for words hiding inside it.
150 '
160 ' HOW TO USE
170 '   Choose 1, 2 or 3 (quit). Type words or numbers when asked.
180 '   Dashes and spaces in phone numbers are ignored.
190 '
200 ' CONCEPTS YOU WILL LEARN
210 '   * A lookup string: the digit for a letter is found with
220 '     INSTR on the keypad layout
230 '   * Counting combinations: multiply the choices per digit
240 '   * An "odometer" loop to step through every combination
250 '     without recursion (just like a car's mileage counter)
260 '   * Searching for a substring with INSTR
270 '
280 ' THINGS TO TRY
290 '   * Add your own words to the DATA list
300 '   * Show ALL the spellings, a page at a time
310 '   * Find the number with the MOST hidden words
320 ' ============================================================
330 '
1000 KEY OFF: CLS
1010 ' Keypad: letters for digits 0-9. 0 and 1 have no letters.
1020 DIM KP$(9), C(10), DG(10)
1030 FOR I = 0 TO 9: READ KP$(I): NEXT I
1040 DATA "", "", ABC, DEF, GHI, JKL, MNO, PQRS, TUV, WXYZ
1050 '
2000 ' ---------- menu --------------------------------------------
2010 PRINT
2020 COLOR 14: PRINT "PHONE WORD SPELLER": COLOR 7
2030 PRINT "1  Word to digits"
2040 PRINT "2  Find words in a phone number"
2050 PRINT "3  Quit"
2060 INPUT "Choice"; CH
2070 IF CH < 1 OR CH > 3 OR CH <> INT(CH) THEN 2060
2080 ON CH GOSUB 3000, 4000, 9000
2090 GOTO 2000
2100 '
3000 ' ---------- word -> digits --------------------------------
3010 LINE INPUT "Word: "; W$
3020 GOSUB 7000                          ' W$ upper case, D$ digits
3030 PRINT W$; " = "; D$
3040 RETURN
3050 '
4000 ' ---------- number -> words ---------------------------------
4010 LINE INPUT "Phone number: "; P$
4020 ' Keep only the digits.
4030 N$ = ""
4040 FOR I = 1 TO LEN(P$)
4050   IF MID$(P$, I, 1) >= "0" AND MID$(P$, I, 1) <= "9" THEN N$ = N$ + MID$(P$, I, 1)
4060 NEXT I
4070 L = LEN(N$)
4080 IF L = 0 OR L > 10 THEN PRINT "Please type 1 to 10 digits.": RETURN
4090 ' How many spellings? Multiply the letter counts (a digit
4100 ' with no letters counts as 1 - it just stays a digit).
4110 T# = 1
4120 FOR I = 1 TO L
4130   DG(I) = VAL(MID$(N$, I, 1))
4140   K = LEN(KP$(DG(I))): IF K = 0 THEN K = 1
4150   T# = T# * K
4160 NEXT I
4170 PRINT N$; " can be spelled"; T#; "ways. The first few:"
4180 '
4200 ' ---- odometer: C(I) is the letter choice for digit I ----
4210 FOR I = 1 TO L: C(I) = 1: NEXT I
4220 SH = 0
4230 ' build and print the current spelling
4240 S$ = ""
4250 FOR I = 1 TO L
4260   IF KP$(DG(I)) = "" THEN S$ = S$ + MID$(N$, I, 1) ELSE S$ = S$ + MID$(KP$(DG(I)), C(I), 1)
4270 NEXT I
4280 PRINT S$; "  ";
4290 SH = SH + 1
4300 IF SH >= 24 THEN PRINT: GOTO 4500
4310 ' advance the rightmost wheel; when it rolls over, carry left
4320 I = L
4330 MX = LEN(KP$(DG(I))): IF MX = 0 THEN MX = 1
4340 C(I) = C(I) + 1
4350 IF C(I) <= MX THEN 4240
4360 C(I) = 1: I = I - 1
4370 IF I >= 1 THEN 4330
4380 PRINT                                ' every wheel rolled over: done
4390 '
4500 ' ---- search the dictionary for hidden words ----------------
4510 PRINT: PRINT "Words hiding in your number:"
4520 F = 0
4530 RESTORE 8000
4540 READ W$: IF W$ = "*" THEN 4620
4550 GOSUB 7000
4560 P = INSTR(N$, D$)
4570 IF P = 0 THEN 4540
4580 ' Show the number with the word dropped into place.
4590 COLOR 10: PRINT "  "; LEFT$(N$, P - 1); W$; MID$(N$, P + LEN(D$)): COLOR 7
4600 F = F + 1
4610 GOTO 4540
4620 IF F = 0 THEN PRINT "  (none from my word list - try 555-2287)"
4630 RETURN
4640 '
7000 ' ---------- W$ -> capitals, and D$ = keypad digits -------
7010 D$ = ""
7020 FOR J = 1 TO LEN(W$)
7030   A$ = MID$(W$, J, 1)
7040   IF A$ >= "a" AND A$ <= "z" THEN A$ = CHR$(ASC(A$) - 32): MID$(W$, J, 1) = A$
7050   ' Which digit's letters contain A$? Try 2..9.
7060   G$ = ""
7070   FOR K = 2 TO 9
7080     IF INSTR(KP$(K), A$) THEN G$ = MID$(STR$(K), 2)
7090   NEXT K
7100   IF G$ = "" AND A$ >= "0" AND A$ <= "9" THEN G$ = A$
7110   D$ = D$ + G$
7120 NEXT J
7130 RETURN
7140 '
8000 ' ---------- word list (end with *) ---------------------------
8010 DATA BASIC, CAT, CATS, DOG, DOGS, PIZZA, CAKE, BOOK, BOOKS, CODE
8020 DATA GAME, GAMES, HELLO, HELP, HOME, CALL, CALLME, FOOD, TAXI
8030 DATA CAR, CARS, BUS, FUN, PET, PETS, SUN, MOON, STAR, STARS
8040 DATA COOL, NICE, BEST, WIN, JAZZ, ROCK, PLAY, TOYS, SHOP, LOVE
8050 DATA DISK, BYTE, BYTES, BUG, BUGS, LOOP, GOTO, FIX, MAP, ART
8060 DATA *
9000 PRINT "Goodbye!": END
