' ============================================================
' TITLE:    Hero Character Creator
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     dice, rpg, random, character sheet, files
' SUMMARY:  Roll 4d6-drop-lowest stats, pick a race and class, and print a character sheet.
' ------------------------------------------------------------
' WHAT IT DOES
'   Tabletop role-playing games create heroes with dice.  For each
'   of six abilities we roll FOUR six-sided dice and throw away the
'   lowest one, then add up the other three (a score from 3 to 18).
'   You can see every roll, with the dropped die in grey.
'   Then you choose a race (which adds bonuses) and a class.  The
'   program suggests the class that suits your best ability, makes
'   up a fantasy name from random syllables, works out hit points,
'   and can save the finished sheet to HERO.TXT.
'
' HOW TO USE
'   Press R to re-roll the stats or Enter to keep them.
'   Choose race and class with number keys.
'   Type a name, or just press Enter for a random one.
'   S saves the sheet, any other key creates a new hero, Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Simulating dice with RND
'   * Finding the smallest of several values (to drop it)
'   * Ability "modifiers": (score - 10) \ 2
'   * Writing a neat report to a text file with PRINT #
'
' THINGS TO TRY
'   * Try "3d6 straight" - are heroes weaker on average?
'   * Add a dwarf race and a bard class
'   * Let the player swap two stats before choosing a class
' ============================================================

DECLARE FUNCTION Modi% (score%)
DEFINT A-Z
DIM ab$(1 TO 6), st(1 TO 6), race$(1 TO 4), bonus$(1 TO 4)
DIM job$(1 TO 4), keyAb(1 TO 4), hitDie(1 TO 4)
DIM syl$(1 TO 12), dice(1 TO 4)
DATA STR,DEX,CON,INT,WIS,CHA
FOR i = 1 TO 6: READ ab$(i): NEXT
' race name, then bonus per ability as a 6-digit string (0-2 each)
DATA Human,111111, Elf,020100, Halfling,020001, Orc,201000
FOR i = 1 TO 4: READ race$(i), bonus$(i): NEXT
' class name, its key ability (1-6), its hit die
DATA Fighter,1,10, Rogue,2,8, Wizard,4,6, Cleric,5,8
FOR i = 1 TO 4: READ job$(i), keyAb(i), hitDie(i): NEXT
DATA ka,ra,thi,mor,el,dun,vi,ash,gor,lin,wen,ul
FOR i = 1 TO 12: READ syl$(i): NEXT
RANDOMIZE TIMER

DO
  ' ================= 1. roll the abilities =================
  DO
    CLS
    COLOR 14: PRINT "HERO CHARACTER CREATOR - rolling 4d6, dropping the lowest": COLOR 7
    PRINT
    total = 0
    FOR a = 1 TO 6
      ' roll four dice and remember which one is the lowest
      lo = 7: loAt = 0: sum = 0
      FOR d = 1 TO 4
        dice(d) = INT(RND * 6) + 1
        sum = sum + dice(d)
        IF dice(d) < lo THEN lo = dice(d): loAt = d
      NEXT
      st(a) = sum - lo
      total = total + st(a)
      PRINT "  "; ab$(a); ":  ";
      FOR d = 1 TO 4
        IF d = loAt THEN COLOR 8 ELSE COLOR 15
        PRINT "["; LTRIM$(STR$(dice(d))); "] ";
      NEXT
      COLOR 11: PRINT " = "; st(a): COLOR 7
    NEXT
    PRINT
    PRINT "  Total of all six:"; total; " (average is about 73)"
    PRINT
    PRINT "  R = roll again,  Enter = keep these,  Esc = quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = CHR$(13) OR k$ = CHR$(27)
    IF k$ = CHR$(27) THEN END
  LOOP WHILE k$ = "R"

  ' ================= 2. choose a race =================
  PRINT
  PRINT "  Choose a race:"
  FOR i = 1 TO 4
    PRINT "    "; i; race$(i); " (";
    FOR a = 1 TO 6
      b = VAL(MID$(bonus$(i), a, 1))
      IF b THEN PRINT " +"; LTRIM$(STR$(b)); " "; ab$(a);
    NEXT
    PRINT " )"
  NEXT
  DO: k$ = INKEY$: LOOP UNTIL k$ >= "1" AND k$ <= "4"
  race = VAL(k$)
  FOR a = 1 TO 6: st(a) = st(a) + VAL(MID$(bonus$(race), a, 1)): NEXT

  ' ================= 3. choose a class =================
  ' suggest the class whose key ability is highest
  best = 1
  FOR i = 2 TO 4
    IF st(keyAb(i)) > st(keyAb(best)) THEN best = i
  NEXT
  PRINT
  PRINT "  Choose a class (your best fit is the "; job$(best); "):"
  FOR i = 1 TO 4
    PRINT "    "; i; job$(i); " - uses "; ab$(keyAb(i)); " ("; LTRIM$(STR$(st(keyAb(i)))); ")"
  NEXT
  DO: k$ = INKEY$: LOOP UNTIL k$ >= "1" AND k$ <= "4"
  klass = VAL(k$)

  ' ================= 4. a name =================
  PRINT
  LINE INPUT "  Hero's name (Enter for a random one): ", nm$
  nm$ = LTRIM$(RTRIM$(nm$))
  IF nm$ = "" THEN
    ' glue 2 or 3 random syllables together, then capitalise
    FOR i = 1 TO INT(RND * 2) + 2: nm$ = nm$ + syl$(INT(RND * 12) + 1): NEXT
    nm$ = UCASE$(LEFT$(nm$, 1)) + MID$(nm$, 2)
  END IF

  ' hit points: the class's full hit die plus the CON modifier
  hp = hitDie(klass) + Modi(st(3))
  IF hp < 1 THEN hp = 1

  ' ================= 5. the character sheet =================
  CLS
  COLOR 14: PRINT STRING$(44, "=")
  PRINT "  "; nm$; " the "; race$(race); " "; job$(klass)
  PRINT STRING$(44, "="): COLOR 7
  FOR a = 1 TO 6
    PRINT USING "  \ \  ##   modifier +#"; ab$(a); st(a); Modi(st(a))
  NEXT
  PRINT
  PRINT "  Hit points:"; hp; "   Armour class:"; 10 + Modi(st(2))
  PRINT
  PRINT "  S = save to HERO.TXT,  any other key = new hero,  Esc = quit"
  DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
  IF k$ = "S" THEN
    OPEN "HERO.TXT" FOR OUTPUT AS #1
    PRINT #1, nm$; " the "; race$(race); " "; job$(klass)
    FOR a = 1 TO 6
      PRINT #1, USING "\ \  ##   modifier +#"; ab$(a); st(a); Modi(st(a))
    NEXT
    PRINT #1, "Hit points:"; hp
    CLOSE #1
    PRINT "  Saved! Press any key."
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
  END IF
LOOP UNTIL k$ = CHR$(27)

' The ability modifier: 10-11 is average (+0), every 2 points
' above or below adds or removes 1.  We floor it so 9 gives -1.
FUNCTION Modi% (score)
  Modi% = INT((score - 10) / 2)
END FUNCTION
