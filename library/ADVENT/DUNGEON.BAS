' ============================================================
' TITLE:    Dungeon Crawler
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Advanced
' TAGS:     rpg, TYPE records, random generation, combat, levelling
' SUMMARY:  Descend five random dungeon levels, fight monsters and slay the dragon.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every door you open leads to a freshly invented room: an
'   adjective + a place + a detail, picked at random.  Rooms may hold
'   a monster, gold, a healing potion or the stairs down.
'   Monsters are stored as TYPE records (user-defined types) - one
'   record bundles a name, hit points, attack, defence, XP and gold
'   reward.  Win battles to gain experience and level up.  On level 5
'   waits the dragon.
'
' HOW TO USE
'   Exploring:  N/S/E/W open a door, P drinks a potion,
'               D goes down stairs (when you find them), Q quits.
'   Fighting:   A attack, P potion, R try to run away.
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE to group related fields into one record
'   * Arrays of records, and copying a template record into a "live" one
'   * Dice-style random combat: damage = attack + d6 - armor
'   * Scaling difficulty with depth and character levels
'
' THINGS TO TRY
'   * Add a new monster line to the DATA (and raise NTYPES)
'   * Give the hero a weapon slot that adds to attack
'   * Make some monsters poisonous with a new TYPE field
' ============================================================

DECLARE SUB Fight ()
DECLARE SUB StatusLine ()
DECLARE FUNCTION Roll% (n%)
DECLARE FUNCTION GetKey$ (allowed$)

DEFINT A-Z

' ----- a record describing one monster -----
TYPE Monster
  nm    AS STRING * 14
  hp    AS INTEGER
  atk   AS INTEGER
  armor AS INTEGER
  xp    AS INTEGER
  gold  AS INTEGER
  minDepth AS INTEGER     ' shallowest level where it can appear
END TYPE

' ----- a record for the player -----
TYPE Hero
  hp    AS INTEGER
  maxHp AS INTEGER
  atk   AS INTEGER
  armor AS INTEGER
  lvl   AS INTEGER
  xp    AS INTEGER
  gold  AS INTEGER
  pots  AS INTEGER
  depth AS INTEGER
END TYPE

CONST NTYPES = 7
DIM SHARED kind(1 TO NTYPES) AS Monster    ' the monster "templates"
DIM SHARED foe AS Monster                   ' the one we are fighting right now
DIM SHARED me AS Hero
DIM SHARED alive

'     name,          hp, atk, armor, xp, gold, minDepth
DATA "Giant Rat",     6,  3,  0,   3,   1,  1
DATA "Goblin",        9,  4,  1,   5,   4,  1
DATA "Skeleton",     12,  5,  2,   8,   6,  2
DATA "Orc Brute",    18,  7,  2,  12,  10,  2
DATA "Wraith",       16,  8,  4,  16,   8,  3
DATA "Troll",        28,  9,  3,  22,  18,  4
DATA "Red Dragon",   60, 12,  5, 100, 200,  5
FOR i = 1 TO NTYPES
  READ n$, kind(i).hp, kind(i).atk, kind(i).armor, kind(i).xp, kind(i).gold, kind(i).minDepth
  kind(i).nm = n$
NEXT

' word lists for inventing rooms
DIM adj$(1 TO 6), plc$(1 TO 6), det$(1 TO 6)
DATA damp,narrow,echoing,collapsed,smoky,frozen
DATA cellar,crypt,cavern,guardroom,tunnel,shrine
DATA "bones crunch underfoot","water drips from the ceiling","old torches line the walls"
DATA "a statue watches you","strange runes glow faintly","the floor is sticky"
FOR i = 1 TO 6: READ adj$(i): NEXT
FOR i = 1 TO 6: READ plc$(i): NEXT
FOR i = 1 TO 6: READ det$(i): NEXT

RANDOMIZE TIMER
me.hp = 25: me.maxHp = 25: me.atk = 5: me.armor = 1
me.lvl = 1: me.xp = 0: me.gold = 0: me.pots = 2: me.depth = 1
alive = 1: stairs = 0

CLS
COLOR 12: PRINT "DEEP DELVE": COLOR 7
PRINT "Reach level 5 and slay the Red Dragon. Good luck."
PRINT

DO
  StatusLine
  PRINT "Doors: N S E W   (P)otion"; : IF stairs THEN PRINT "  (D)own stairs";
  PRINT "  (Q)uit"
  k$ = GetKey$("NSEWPDQ")
  SELECT CASE k$
    CASE "Q"
      PRINT "You climb back to daylight with"; me.gold; "gold.": END
    CASE "P"
      IF me.pots > 0 THEN
        me.pots = me.pots - 1: me.hp = me.maxHp
        PRINT "You drink a potion. Fully healed!"
      ELSE
        PRINT "No potions left."
      END IF
    CASE "D"
      IF stairs THEN
        me.depth = me.depth + 1: stairs = 0
        COLOR 13: PRINT "You descend to level"; me.depth; "...": COLOR 7
      END IF
    CASE ELSE
      ' ---- invent a new room ----
      PRINT
      PRINT "You enter a "; adj$(Roll(6)); " "; plc$(Roll(6)); "; "; det$(Roll(6)); "."
      stairs = 0
      r = Roll(100)
      IF me.depth = 5 AND r <= 25 THEN
        foe = kind(NTYPES)                   ' the dragon lives on level 5
        Fight
      ELSEIF r <= 50 THEN
        ' pick a random monster that is allowed at this depth (not the dragon)
        DO
          t = Roll(NTYPES - 1)
        LOOP UNTIL kind(t).minDepth <= me.depth
        foe = kind(t)                        ' copy the whole record at once
        foe.hp = foe.hp + me.depth           ' deeper = a bit tougher
        Fight
      ELSEIF r <= 65 THEN
        g = Roll(10) * me.depth
        PRINT "You find"; g; "gold coins!": me.gold = me.gold + g
      ELSEIF r <= 75 THEN
        PRINT "A healing potion sits on a ledge. Yoink.": me.pots = me.pots + 1
      ELSEIF r <= 90 AND me.depth < 5 THEN
        PRINT "Stone stairs lead DOWN into darkness.": stairs = 1
      ELSE
        PRINT "The room is empty."
      END IF
  END SELECT
  IF alive = 0 THEN
    COLOR 12: PRINT "You have fallen on level"; me.depth; ". GAME OVER.": COLOR 7: END
  END IF
LOOP

' The combat loop.  Runs until the foe or the hero is dead, or the
' hero escapes.  Damage = attacker's atk + a d6 roll - defender's armor.
SUB Fight
  COLOR 12: PRINT "A "; RTRIM$(foe.nm); " attacks!": COLOR 7
  DO
    PRINT "  "; RTRIM$(foe.nm); " HP"; foe.hp; "  |  You HP"; me.hp; "  (A)ttack (P)otion (R)un"
    k$ = GetKey$("APR")
    IF k$ = "A" THEN
      dmg = me.atk + Roll(6) - foe.armor
      IF dmg < 1 THEN dmg = 1
      IF Roll(10) = 10 THEN dmg = dmg * 2: PRINT "  Critical hit!";
      foe.hp = foe.hp - dmg
      PRINT "  You hit for"; dmg
    ELSEIF k$ = "P" THEN
      IF me.pots > 0 THEN
        me.pots = me.pots - 1: me.hp = me.maxHp: PRINT "  Gulp! Healed."
      ELSE
        PRINT "  No potions!"
      END IF
    ELSE
      ' running away works half the time (never from the dragon)
      IF Roll(2) = 1 AND RTRIM$(foe.nm) <> "Red Dragon" THEN
        PRINT "  You escape!": EXIT SUB
      END IF
      PRINT "  You can't get away!"
    END IF

    IF foe.hp <= 0 THEN
      COLOR 10: PRINT "  The "; RTRIM$(foe.nm); " is defeated! +"; LTRIM$(STR$(foe.xp)); " XP, +"; LTRIM$(STR$(foe.gold)); " gold": COLOR 7
      me.xp = me.xp + foe.xp: me.gold = me.gold + foe.gold
      IF RTRIM$(foe.nm) = "Red Dragon" THEN
        COLOR 14
        PRINT "The dragon crashes down! Its hoard is yours. YOU ARE VICTORIOUS!"
        PRINT "Final gold:"; me.gold; " Level:"; me.lvl
        COLOR 7: END
      END IF
      ' level up every 20 XP x current level
      DO WHILE me.xp >= 20 * me.lvl
        me.xp = me.xp - 20 * me.lvl
        me.lvl = me.lvl + 1
        me.maxHp = me.maxHp + 6: me.hp = me.maxHp
        me.atk = me.atk + 2: me.armor = me.armor + 1
        COLOR 14: PRINT "  ** LEVEL UP! You are now level"; me.lvl; "**": COLOR 7
      LOOP
      EXIT SUB
    END IF

    ' the monster strikes back
    dmg = foe.atk + Roll(6) - 3 - me.armor
    IF dmg < 0 THEN dmg = 0
    me.hp = me.hp - dmg
    PRINT "  The "; RTRIM$(foe.nm); " hits you for"; dmg
    IF me.hp <= 0 THEN alive = 0: EXIT SUB
  LOOP
END SUB

' Wait for one of the allowed keys and return it in upper case.
FUNCTION GetKey$ (allowed$)
  DO
    k$ = UCASE$(INKEY$)
  LOOP UNTIL k$ <> "" AND INSTR(allowed$, k$) > 0
  GetKey$ = k$
END FUNCTION

' Roll an n-sided die: a random whole number from 1 to n.
FUNCTION Roll% (n)
  Roll% = INT(RND * n) + 1
END FUNCTION

SUB StatusLine
  PRINT
  COLOR 11
  PRINT "[Depth"; me.depth; "] HP"; me.hp; "/"; LTRIM$(STR$(me.maxHp)); "  Lv"; me.lvl;
  PRINT " XP"; me.xp; " Gold"; me.gold; " Potions"; me.pots
  COLOR 7
END SUB
