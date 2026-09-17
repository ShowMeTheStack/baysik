' ============================================================
' TITLE:    The Haunted House
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     text adventure, random events, grid map, timer
' SUMMARY:  Explore a spooky mansion by candlelight and banish the wandering ghost.
' ------------------------------------------------------------
' WHAT IT DOES
'   The ground floor of Blackwood Manor is a 3 x 3 grid of rooms,
'   with an attic above the central hall.  A ghost drifts from
'   room to room at random.  Every time it finds you, your FEAR
'   grows - three frights and you run screaming into the night.
'   Your candle also burns down one notch per move.
'   Collect the SALT, the BELL and the BOOK, climb to the attic and
'   READ the book to banish the ghost forever.
'
' HOW TO USE
'   N S E W to walk, U and D for the stairs.
'   TAKE <thing>, I (inventory), LOOK, RING BELL, READ BOOK, MAP, QUIT.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a map as a grid: room = (row - 1) * 3 + column
'   * Exits written as little strings ("NE", "SW") and tested with INSTR
'   * A computer-controlled character that moves on its own
'   * Win/lose conditions: an item set, a fear counter, a time limit
'
' THINGS TO TRY
'   * Let the ghost follow you instead of wandering randomly
'   * Add a cellar under the kitchen with a second ghost
'   * Make the candle shorter for a harder game
' ============================================================

DEFINT A-Z
CONST ROOMS = 10, ITEMS = 3, ATTIC = 10
DIM rn$(1 TO ROOMS), exits$(1 TO ROOMS), feel$(1 TO ROOMS)
DIM item$(1 TO ITEMS), itemAt(1 TO ITEMS)     ' itemAt = room, or 0 when carried
RANDOMIZE TIMER

' ----- the ground floor, numbered like a phone keypad -----
'      1 Library   2 Ballroom   3 Conservatory
'      4 Study     5 Hall       6 Dining Room
'      7 Kitchen   8 Foyer      9 Parlour
'   Each DATA line: name, open exits, a creepy detail
DATA "Library","SE","Books whisper as you pass the shelves."
DATA "Ballroom","EWS","A music box plays a waltz by itself."
DATA "Conservatory","W","Dead roses scratch at the glass."
DATA "Study","NSE","A portrait's eyes follow you."
DATA "Great Hall","NSEWU","A grand staircase climbs into darkness."
DATA "Dining Room","WS","Twelve places are set for dinner. Nobody is eating."
DATA "Kitchen","NE","Something drips in the sink. It is not water."
DATA "Foyer","NEW","The front door is nailed shut from the outside!"
DATA "Parlour","NW","An armchair is still warm."
DATA "Attic","D","Moonlight through a round window. This is where it began."
FOR r = 1 TO ROOMS: READ rn$(r), exits$(r), feel$(r): NEXT

DATA SALT,7, BELL,2, BOOK,1
FOR i = 1 TO ITEMS: READ item$(i), itemAt(i): NEXT

here = 8: ghost = 3: fear = 0: candle = 60
CLS
COLOR 13: PRINT "BLACKWOOD MANOR": COLOR 7
PRINT "The door slams behind you. Find the salt, the bell and the book,"
PRINT "then read the book in the attic. Type HELP for commands."
GOSUB ShowRoom

DO
  PRINT
  COLOR 8: PRINT "[candle"; candle; " fear"; fear; "]  ";: COLOR 7
  LINE INPUT "> ", c$
  c$ = UCASE$(LTRIM$(RTRIM$(c$)))
  sp = INSTR(c$, " ")
  IF sp THEN v$ = LEFT$(c$, sp - 1): n$ = MID$(c$, sp + 1) ELSE v$ = c$: n$ = ""
  moved = 0: acted = 1

  SELECT CASE v$
    CASE "N", "S", "E", "W", "U", "D"
      ' Is that letter in this room's exit string?
      IF INSTR(exits$(here), v$) = 0 THEN
        PRINT "A wall blocks your way."
        acted = 0
      ELSE
        ' Grid arithmetic: north is 3 rooms back, east is +1, etc.
        SELECT CASE v$
          CASE "N": here = here - 3
          CASE "S": here = here + 3
          CASE "E": here = here + 1
          CASE "W": here = here - 1
          CASE "U": here = ATTIC
          CASE "D": here = 5
        END SELECT
        moved = 1
      END IF
    CASE "TAKE", "GET"
      found = 0
      FOR i = 1 TO ITEMS
        IF item$(i) = n$ AND itemAt(i) = here THEN itemAt(i) = 0: found = 1
      NEXT
      IF found THEN PRINT "You take the "; LCASE$(n$); "." ELSE PRINT "It isn't here."
    CASE "I", "INV"
      PRINT "You hold: a candle";
      FOR i = 1 TO ITEMS
        IF itemAt(i) = 0 THEN PRINT ", the "; LCASE$(item$(i));
      NEXT
      PRINT "."
    CASE "LOOK", "L", ""
      GOSUB ShowRoom: acted = 0
    CASE "RING"
      IF itemAt(2) <> 0 THEN
        PRINT "You have no bell."
      ELSEIF ghost = here THEN
        PRINT "The bell's pure note drives the ghost through the wall!"
        DO: ghost = INT(RND * 9) + 1: LOOP WHILE ghost = here
      ELSE
        PRINT "The bell rings out. Somewhere, something shrieks."
      END IF
    CASE "READ"
      IF itemAt(3) <> 0 THEN
        PRINT "You have nothing to read."
      ELSEIF here <> ATTIC THEN
        PRINT "The pages are blank... perhaps it must be read where it began."
      ELSEIF itemAt(1) <> 0 THEN
        PRINT "You begin to read, but the ghost rushes at you! You need a"
        PRINT "circle of something to protect you."
      ELSE
        COLOR 10
        PRINT "You pour a circle of salt and read the old words aloud."
        PRINT "A long sigh fills the house... and then silence. The ghost"
        PRINT "is at peace, and the front door creaks open. YOU WIN!"
        COLOR 7: END
      END IF
    CASE "MAP"
      PRINT " Library  - Ballroom - Conservatory"
      PRINT " Study      Hall(up)   Dining Room"
      PRINT " Kitchen  - Foyer    - Parlour"
      acted = 0
    CASE "HELP"
      PRINT "N S E W U D, TAKE x, I, LOOK, RING BELL, READ BOOK, MAP, QUIT"
      acted = 0
    CASE "QUIT", "Q"
      PRINT "You curl up in a corner until dawn.": END
    CASE ELSE
      PRINT "You whisper "; CHR$(34); c$; CHR$(34); " into the dark. Nothing happens."
      acted = 0
  END SELECT

  IF moved THEN GOSUB ShowRoom

  ' ----- the world takes its turn -----
  IF acted THEN
    candle = candle - 1
    ' The ghost drifts through a random wall (it ignores exits!)
    ' but never climbs into the attic.
    IF RND < .6 THEN
      DO
        g = ghost + INT(RND * 3) - 1 + 3 * (INT(RND * 3) - 1)
      LOOP UNTIL g >= 1 AND g <= 9
      ghost = g
    END IF
    IF ghost = here THEN
      fear = fear + 1
      COLOR 12
      PRINT "A cold shape glides out of the wall and screams in your face!"
      COLOR 7
    ELSEIF ABS(ghost - here) = 1 OR ABS(ghost - here) = 3 THEN
      PRINT "(You hear moaning nearby.)"
    END IF
    IF fear >= 3 THEN PRINT "Too frightened to go on, you smash a window and flee. GAME OVER.": END
    IF candle = 10 THEN PRINT "Your candle is guttering..."
    IF candle <= 0 THEN PRINT "Your candle goes out. In the dark, cold fingers touch your neck. GAME OVER.": END
  END IF
LOOP

ShowRoom:
  COLOR 14: PRINT rn$(here): COLOR 7
  PRINT feel$(here)
  FOR i = 1 TO ITEMS
    IF itemAt(i) = here THEN PRINT "You notice the "; LCASE$(item$(i)); " here."
  NEXT
  PRINT "Ways out: ";
  FOR k = 1 TO LEN(exits$(here)): PRINT MID$(exits$(here), k, 1); " ";: NEXT
  PRINT
RETURN
