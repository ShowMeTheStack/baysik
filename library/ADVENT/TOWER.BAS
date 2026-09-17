' ============================================================
' TITLE:    The Clockmaker's Tower
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     interactive fiction, inventory, save game, files, parser
' SUMMARY:  Restart a magical clock in interactive fiction with a carry limit and SAVE/LOAD.
' ------------------------------------------------------------
' WHAT IT DOES
'   The town clock has stopped and time itself is slowing down.
'   Climb the tower, unjam the gears and wind the great clock.
'   This adventure adds three things real interactive fiction needs:
'     * an inventory LIMIT - you can only carry 3 things at once
'     * a parser that ignores little words: "take the oil can"
'       works the same as "take oil"
'     * SAVE and LOAD, which write the whole game state to the
'       file TOWER.SAV so you can stop and carry on later
'
' HOW TO USE
'   Directions: N S E W U D.   Verbs: LOOK, TAKE, DROP, I, EXAMINE,
'   READ, OIL, CLIMB, WIND, SAVE, LOAD, HELP, QUIT.
'
' CONCEPTS YOU WILL LEARN
'   * What "game state" really is: a room number, flags, locations
'   * Writing and reading that state with WRITE # / INPUT #
'   * ON ERROR to handle "no saved game yet"
'   * Removing "noise words" (THE, A, AN) before parsing
'
' THINGS TO TRY
'   * Add a SCORE that rises when you solve each puzzle (and save it)
'   * Allow several save slots: TOWER1.SAV, TOWER2.SAV...
'   * Make the ladder count as 2 items because it is heavy
' ============================================================

DECLARE SUB Look ()
DECLARE FUNCTION ObjNo% (w$)
DECLARE FUNCTION Carrying% ()
DEFINT A-Z
CONST NR = 6, NO = 5, HAND = 0, NOWHERE = -1, LIMIT = 3
DIM SHARED rn$(1 TO NR), rd$(1 TO NR), dest(1 TO NR, 1 TO 6)
DIM SHARED oname$(1 TO NO), od$(1 TO NO), oloc(1 TO NO)
DIM SHARED here, oiled          ' oiled = 1 once the gears have been oiled
' ---- rooms: name, description, then where N,S,E,W,U,D lead (0 = nowhere)
DATA "Workshop","Half-built clocks cover every bench. Stairs go north; a store is east.",2,0,6,0,0,0
DATA "Stairwell","A narrow stone stair spirals upward. The workshop is south.",0,1,0,0,3,0
DATA "Gear Room","Huge brass gears fill the room, frozen in place.",0,0,0,0,4,2
DATA "Bell Chamber","A giant bronze bell hangs silent. Something glints high on a beam. A door leads east.",0,0,5,0,0,3
DATA "Clock Face","You stand behind the enormous glass clock face. A keyhole sits in the centre.",0,0,0,4,0,0
DATA "Storeroom","Dusty shelves and crates. The workshop is west.",0,0,0,1,0,0
FOR r = 1 TO NR
  READ rn$(r), rd$(r)
  FOR d = 1 TO 6: READ dest(r, d): NEXT
NEXT
' ---- objects: word, description, starting place
DATA "OIL","a small can of clock oil",6
DATA "LADDER","a wooden ladder",6
DATA "NOTE","a note in spidery writing",1
DATA "SPRING","a coiled steel spring (it does not look useful)",1
DATA "KEY","a silver winding key",-1
FOR o = 1 TO NO: READ oname$(o), od$(o), oloc(o): NEXT

here = 1
CLS
COLOR 14: PRINT "THE CLOCKMAKER'S TOWER": COLOR 7
PRINT "The great clock has stopped. Wind it before time runs down. (HELP for help)"
PRINT
Look

DO
  PRINT
  LINE INPUT "> ", c$
  ' ---- clean up the command: upper case, drop noise words ----
  c$ = " " + UCASE$(c$) + " "
  FOR pass = 1 TO 3
    FOR k = 1 TO 4
      SELECT CASE k
        CASE 1: nw$ = " THE "
        CASE 2: nw$ = " A "
        CASE 3: nw$ = " AN "
        CASE 4: nw$ = " CAN "        ' so "oil can" is just "oil"
      END SELECT
      p = INSTR(c$, nw$)
      IF p THEN c$ = LEFT$(c$, p) + MID$(c$, p + LEN(nw$))
    NEXT
  NEXT
  c$ = LTRIM$(RTRIM$(c$))
  sp = INSTR(c$, " ")
  IF sp THEN v$ = LEFT$(c$, sp - 1): n$ = LTRIM$(MID$(c$, sp + 1)) ELSE v$ = c$: n$ = ""
  o = ObjNo(n$)

  SELECT CASE v$
    CASE "N", "S", "E", "W", "U", "D"
      d = INSTR("NSEWUD", v$)
      IF here = 3 AND v$ = "U" AND oiled = 0 THEN
        PRINT "A hatch above is held shut by the jammed gears."
      ELSEIF dest(here, d) = 0 THEN
        PRINT "You can't go that way."
      ELSE
        here = dest(here, d)
        Look
      END IF
    CASE "LOOK", "L", "": Look
    CASE "I", "INV", "INVENTORY"
      PRINT "You carry ("; LTRIM$(STR$(Carrying)); " of"; STR$(LIMIT); "):"
      FOR o = 1 TO NO
        IF oloc(o) = HAND THEN PRINT "  "; od$(o)
      NEXT
    CASE "TAKE", "GET"
      IF o = 0 THEN
        PRINT "Take what?"
      ELSEIF oloc(o) <> here THEN
        PRINT "That isn't here."
      ELSEIF Carrying >= LIMIT THEN
        PRINT "Your hands are full. Drop something first."
      ELSE
        oloc(o) = HAND: PRINT "Taken."
      END IF
    CASE "DROP"
      IF o = 0 THEN
        PRINT "Drop what?"
      ELSEIF oloc(o) <> HAND THEN
        PRINT "You don't have it."
      ELSE
        oloc(o) = here: PRINT "Dropped."
      END IF
    CASE "EXAMINE", "X", "READ"
      IF o = 0 THEN
        PRINT "Examine what?"
      ELSEIF oloc(o) <> HAND AND oloc(o) <> here THEN
        PRINT "You can't see that here."
      ELSEIF o = 3 THEN
        PRINT "'The gears must be OILED. The key hangs high in the bell chamber."
        PRINT " A ladder from the store will reach it.  - the Clockmaker'"
      ELSE
        PRINT "It is "; od$(o); "."
      END IF
    CASE "OIL"
      IF oloc(1) <> HAND THEN
        PRINT "You have no oil."
      ELSEIF here <> 3 THEN
        PRINT "Nothing here needs oiling."
      ELSEIF oiled THEN
        PRINT "The gears are already turning smoothly."
      ELSE
        oiled = 1
        PRINT "You oil every gear. With a groan they turn, and a hatch above swings open!"
      END IF
    CASE "CLIMB"
      IF here <> 4 THEN
        PRINT "There is nothing to climb here."
      ELSEIF oloc(2) <> here THEN
        PRINT "The beam is far too high. If only you had something to stand on..."
        IF oloc(2) = HAND THEN PRINT "(Try dropping the ladder first.)"
      ELSEIF oloc(5) <> NOWHERE THEN
        PRINT "You climb up, but there's nothing more up there."
      ELSE
        PRINT "You climb the ladder and find a silver key on the beam."
        IF Carrying < LIMIT THEN oloc(5) = HAND: PRINT "You take it." ELSE oloc(5) = here: PRINT "Your hands are full, so you drop it to the floor."
      END IF
    CASE "WIND", "USE", "TURN"
      IF oloc(5) <> HAND THEN
        PRINT "You need a winding key."
      ELSEIF here <> 5 THEN
        PRINT "There's no keyhole here."
      ELSE
        COLOR 10
        PRINT "You fit the key and turn... and turn... TICK. TOCK. The great"
        PRINT "clock lurches into life and the bell booms over the town. Time"
        PRINT "flows again. YOU HAVE SAVED THE DAY!"
        COLOR 7: END
      END IF
    CASE "SAVE"
      ' The whole game is just these numbers - save them all.
      OPEN "TOWER.SAV" FOR OUTPUT AS #1
      WRITE #1, here, oiled
      FOR o = 1 TO NO: WRITE #1, oloc(o): NEXT
      CLOSE #1
      PRINT "Game saved to TOWER.SAV."
    CASE "LOAD", "RESTORE"
      okLoad = 1
      ON ERROR GOTO NoSave
      OPEN "TOWER.SAV" FOR INPUT AS #1
      ON ERROR GOTO 0
      IF okLoad THEN
        INPUT #1, here, oiled
        FOR o = 1 TO NO: INPUT #1, oloc(o): NEXT
        CLOSE #1
        PRINT "Game loaded."
        Look
      ELSE
        PRINT "There is no saved game yet. Type SAVE first."
      END IF
    CASE "HELP"
      PRINT "Try: N S E W U D, LOOK, TAKE x, DROP x, I, EXAMINE x, READ x,"
      PRINT "OIL, CLIMB, WIND, SAVE, LOAD, QUIT.  You can carry"; LIMIT; "things."
    CASE "QUIT", "Q"
      PRINT "The clock stays silent. Goodbye.": END
    CASE ELSE
      PRINT "I don't understand "; CHR$(34); v$; CHR$(34); "."
  END SELECT
LOOP

NoSave:
  okLoad = 0
  RESUME NEXT

FUNCTION Carrying%
  n = 0
  FOR o = 1 TO NO
    IF oloc(o) = HAND THEN n = n + 1
  NEXT
  Carrying% = n
END FUNCTION

SUB Look
  COLOR 11: PRINT rn$(here): COLOR 7
  PRINT rd$(here)
  IF here = 3 AND oiled THEN PRINT "The gears tick round; an open hatch leads up."
  FOR o = 1 TO NO
    IF oloc(o) = here THEN PRINT "You see "; od$(o); "."
  NEXT
END SUB

' Match the first 3 letters of a word to an object name.
FUNCTION ObjNo% (w$)
  ObjNo% = 0
  IF LEN(w$) < 3 THEN EXIT FUNCTION
  FOR o = 1 TO NO
    IF LEFT$(oname$(o), 3) = LEFT$(w$, 3) THEN ObjNo% = o: EXIT FUNCTION
  NEXT
END FUNCTION
