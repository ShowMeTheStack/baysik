10 ' ============================================================
20 ' TITLE:    Sound Effects Workshop
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     sound, menu, on gosub, peek, loops
60 ' SUMMARY:  A menu of PC-speaker sound effects - siren, laser, bomb, UFO and more - each built from SOUND loops.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   The original IBM PC had one tiny speaker that could play
100 '   a single square-wave tone. Game programmers squeezed
110 '   amazing effects out of it by changing the pitch very
120 '   quickly in loops. Pick an effect from the menu to hear it
130 '   and read the code to see how it is made. The top line
140 '   also shows the Caps/Num/Scroll Lock lights, read straight
150 '   out of BIOS memory with PEEK.
160 '
170 ' HOW TO USE
180 '   Press 1-8 to play an effect, Q to quit.
190 '
200 ' CONCEPTS YOU WILL LEARN
210 '   * SOUND freq, ticks   (18.2 ticks per second)
220 '   * Sweeping pitch up and down with FOR ... STEP
230 '   * ON n GOSUB to pick one subroutine from a menu
240 '   * DEF SEG = 0 and PEEK(&H417): the BIOS keyboard flags
250 '     (bit 4 = Scroll Lock, bit 5 = Num Lock, bit 6 = Caps)
260 '   * Using AND to test single bits
270 '
280 ' THINGS TO TRY
290 '   * Invent effect number 9 (a bouncing ball? a doorbell?)
300 '   * Change the STEP sizes to make sweeps smoother
310 '   * Combine two effects into one
320 ' ============================================================
330 '
1000 KEY OFF: SCREEN 0: WIDTH 40: CLS
1010 '
2000 ' ---------- menu -----------------------------------------
2010 COLOR 14: LOCATE 3, 7: PRINT "SOUND EFFECTS WORKSHOP": COLOR 7
2020 RESTORE 2200
2030 FOR I = 1 TO 8
2040   READ N$
2050   LOCATE 5 + I, 10: PRINT I; " "; N$
2060 NEXT I
2070 LOCATE 15, 10: PRINT " Q   Quit"
2080 LOCATE 18, 8: PRINT "Press a number key..."
2090 '
2100 ' ---- wait for a key, updating the lock lights --------
2110 GOSUB 6000
2120 K$ = INKEY$: IF K$ = "" THEN 2110
2130 IF K$ = "q" OR K$ = "Q" OR K$ = CHR$(27) THEN 9000
2140 K = VAL(K$): IF K < 1 OR K > 8 THEN 2110
2150 LOCATE 5 + K, 8: COLOR 15: PRINT CHR$(16);       ' arrow marker
2160 ON K GOSUB 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700
2170 LOCATE 5 + K, 8: COLOR 7: PRINT " ";
2180 GOTO 2110
2200 DATA Police siren, Laser blast, Falling bomb, Telephone ring
2210 DATA UFO warble, Raindrops, Red alert, Power up
2220 '
3000 ' ---- 1: siren - pitch slides up and down, twice --------
3010 FOR R = 1 TO 2
3020   FOR F = 600 TO 1200 STEP 20: SOUND F, .2: NEXT F
3030   FOR F = 1200 TO 600 STEP -20: SOUND F, .2: NEXT F
3040 NEXT R
3050 RETURN
3100 ' ---- 2: laser - a fast falling sweep, three shots -------
3110 FOR R = 1 TO 3
3120   FOR F = 3000 TO 300 STEP -150: SOUND F, .1: NEXT F
3130 NEXT R
3140 RETURN
3200 ' ---- 3: bomb - long whistle down, then a rumble ---------
3210 FOR F = 2000 TO 400 STEP -10: SOUND F, .1: NEXT F
3220 FOR I = 1 TO 40: SOUND 37 + RND * 60, .2: NEXT I   ' random low = noise
3230 RETURN
3300 ' ---- 4: phone - two tones swapped very quickly ----------
3310 FOR R = 1 TO 2
3320   FOR I = 1 TO 15: SOUND 900, .3: SOUND 700, .3: NEXT I
3330   SOUND 32767, 6                 ' too high to hear = a pause
3340 NEXT R
3350 RETURN
3400 ' ---- 5: UFO - a wobble whose centre slowly rises -------
3410 FOR C = 300 TO 700 STEP 25
3420   SOUND C + 80, .2: SOUND C - 80, .2
3430 NEXT C
3440 RETURN
3500 ' ---- 6: raindrops - short random high blips -----------
3510 FOR I = 1 TO 30
3520   SOUND 1500 + RND * 2500, .1
3530   SOUND 32767, RND * 2
3540 NEXT I
3550 RETURN
3600 ' ---- 7: red alert - a rising whoop, repeated -----------
3610 FOR R = 1 TO 3
3620   FOR F = 300 TO 900 STEP 15: SOUND F, .1: NEXT F
3630   SOUND 32767, 2
3640 NEXT R
3650 RETURN
3700 ' ---- 8: power up - an arpeggio that climbs higher -------
3710 FOR B = 200 TO 800 STEP 100
3720   SOUND B, .5: SOUND B * 1.25, .5: SOUND B * 1.5, .5
3730 NEXT B
3740 RETURN
3750 '
6000 ' ---------- keyboard lock lights from BIOS memory ---------
6010 ' Address 0000:0417 holds the shift-state byte. Each bit is
6020 ' one key or lock. AND with a power of two tests one bit.
6030 DEF SEG = 0
6040 KB = PEEK(&H417)
6050 DEF SEG
6060 LOCATE 1, 2
6070 IF KB AND 64 THEN COLOR 10 ELSE COLOR 8
6080 PRINT "CAPS ";
6090 IF KB AND 32 THEN COLOR 10 ELSE COLOR 8
6100 PRINT "NUM ";
6110 IF KB AND 16 THEN COLOR 10 ELSE COLOR 8
6120 PRINT "SCROLL";
6130 COLOR 7
6140 RETURN
6150 '
9000 CLS: PRINT "Speaker switched off. Bye!"
9010 END
