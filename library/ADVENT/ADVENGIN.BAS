' ============================================================
' TITLE:    Text Adventure Engine
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     text adventure, parser, data, arrays, game engine
' SUMMARY:  A tiny data-driven adventure engine with rooms, objects and a two-word parser.
' ------------------------------------------------------------
' WHAT IT DOES
'   Classic adventure games like Colossal Cave and Zork are really
'   two things: an ENGINE (code that understands commands and moves
'   things around) and a WORLD (rooms, exits and objects).  Here the
'   whole world lives in DATA statements, so you can build a brand
'   new adventure without touching the engine code at all.
'   The sample world is a small castle: find the key, open the vault
'   and carry the crown back to the gatehouse.
'
' HOW TO USE
'   Type two-word commands such as:
'     GO NORTH   N   S   E   W   LOOK   TAKE LAMP   DROP KEY
'     EXAMINE CROWN   OPEN DOOR   INVENTORY (or I)   HELP   QUIT
'
' CONCEPTS YOU WILL LEARN
'   * Separating data (the world) from code (the engine)
'   * A verb/noun parser that splits a line at the first space
'   * Synonym tables (GET = TAKE, X = EXAMINE, N = GO NORTH)
'   * Object locations: a room number, or "carried by the player"
'
' THINGS TO TRY
'   * Add a seventh room and connect it with new exit numbers
'   * Add a new verb such as READ or EAT to the verb table
'   * Make the cellar dark unless the lamp is carried
' ============================================================

DECLARE SUB Describe ()
DECLARE SUB Wrap (t$)
DECLARE FUNCTION FindObj% (n$)

DEFINT A-Z
CONST NROOMS = 6, NOBJ = 5, NVERBS = 25
CONST CARRIED = 99                 ' an object's location when the player has it

' ---------- the world tables ----------
' rName$ = short room name, rDesc$ = long description
' ex(room, d) = room you reach going in direction d (1=N 2=S 3=E 4=W)
'               0 means no exit, a NEGATIVE number means "locked door"
DIM SHARED rName$(1 TO NROOMS), rDesc$(1 TO NROOMS), ex(1 TO NROOMS, 1 TO 4)
DIM SHARED oName$(1 TO NOBJ), oDesc$(1 TO NOBJ), oLoc(1 TO NOBJ)
DIM SHARED here                       ' the room the player stands in
DIM vWord$(1 TO NVERBS), vCode(1 TO NVERBS)
DIM dirName$(1 TO 4)
dirName$(1) = "north": dirName$(2) = "south"
dirName$(3) = "east": dirName$(4) = "west"

' ---- ROOMS: name, description, N, S, E, W ----
DATA "Gatehouse","You stand in a crumbling gatehouse. A courtyard lies north.",2,0,0,0
DATA "Courtyard","Weeds push through the flagstones. Paths lead in every direction.",5,1,3,4
DATA "Armoury","Empty weapon racks line the walls. A heavy iron door is set in the east wall.",0,0,-6,2
DATA "Kitchen","Pots hang from hooks. A greasy side door leads back east to the courtyard.",0,0,2,0
DATA "Great Hall","A long table is covered with dust. The courtyard is south.",0,2,0,0
DATA "Vault","A tiny stone room. Light glints from a velvet cushion.",0,0,0,3
FOR r = 1 TO NROOMS
  READ rName$(r), rDesc$(r)
  FOR d = 1 TO 4: READ ex(r, d): NEXT d
NEXT r

' ---- OBJECTS: name (one word, the noun the player types), description, start room ----
DATA "LAMP","A brass oil lamp. It still has some oil.",1
DATA "KEY","A large iron key with a crown stamped on it.",4
DATA "CROWN","A golden crown set with rubies. Treasure!",6
DATA "BREAD","A loaf of stale bread.",4
DATA "SHIELD","A dented shield bearing a dragon crest.",5
FOR o = 1 TO NOBJ: READ oName$(o), oDesc$(o), oLoc(o): NEXT o

' ---- VERBS: word the player may type, internal verb code ----
' Several words share one code -- that is how synonyms work.
'  1=GO 2..5=directions 6=TAKE 7=DROP 8=LOOK 9=INVENTORY 10=EXAMINE
' 11=OPEN 12=QUIT 13=HELP
DATA GO,1,WALK,1,NORTH,2,N,2,SOUTH,3,S,3,EAST,4,E,4,WEST,5,W,5
DATA TAKE,6,GET,6,DROP,7,LOOK,8,L,8,INVENTORY,9,I,9,INV,9
DATA EXAMINE,10,X,10,OPEN,11,UNLOCK,11,QUIT,12,Q,12,HELP,13
FOR v = 1 TO NVERBS: READ vWord$(v), vCode(v): NEXT v

' ---------- main loop ----------
CLS
COLOR 14: PRINT "THE CASTLE OF THE LOST CROWN": COLOR 7
PRINT "Bring the crown back to the gatehouse. Type HELP for commands."
PRINT
here = 1
Describe
DO
  PRINT
  LINE INPUT "> ", cmd$
  cmd$ = UCASE$(LTRIM$(RTRIM$(cmd$)))
  IF cmd$ = "" THEN cmd$ = "LOOK"

  ' --- the parser: split into VERB and NOUN at the first space ---
  sp = INSTR(cmd$, " ")
  IF sp > 0 THEN
    verb$ = LEFT$(cmd$, sp - 1)
    noun$ = LTRIM$(MID$(cmd$, sp + 1))
  ELSE
    verb$ = cmd$: noun$ = ""
  END IF

  ' look the verb up in the synonym table
  code = 0
  FOR v = 1 TO NVERBS
    IF vWord$(v) = verb$ THEN code = vCode(v): EXIT FOR
  NEXT v

  ' "GO NORTH" becomes the same as "NORTH": turn the noun into a direction code
  IF code = 1 THEN
    code = 0
    FOR v = 1 TO NVERBS
      IF vWord$(v) = noun$ AND vCode(v) >= 2 AND vCode(v) <= 5 THEN code = vCode(v)
    NEXT v
    IF code = 0 THEN PRINT "Go where?": GOTO NextTurn
  END IF

  SELECT CASE code
    CASE 0
      PRINT "I don't know how to "; CHR$(34); verb$; CHR$(34); "."
    CASE 2 TO 5                                 ' movement
      d = code - 1
      dest = ex(here, d)
      IF dest = 0 THEN
        PRINT "You can't go "; dirName$(d); "."
      ELSEIF dest < 0 THEN
        PRINT "A locked iron door blocks the way."
      ELSE
        here = dest
        Describe
      END IF
    CASE 6                                      ' TAKE
      o = FindObj(noun$)
      IF o = 0 THEN
        PRINT "Take what?"
      ELSEIF oLoc(o) = CARRIED THEN
        PRINT "You already have it."
      ELSEIF oLoc(o) <> here THEN
        PRINT "I see no "; LCASE$(noun$); " here."
      ELSE
        oLoc(o) = CARRIED: PRINT "Taken."
      END IF
    CASE 7                                      ' DROP
      o = FindObj(noun$)
      IF o = 0 THEN
        PRINT "Drop what?"
      ELSEIF oLoc(o) <> CARRIED THEN
        PRINT "You aren't carrying that."
      ELSE
        oLoc(o) = here: PRINT "Dropped."
      END IF
    CASE 8
      Describe
    CASE 9                                      ' INVENTORY
      PRINT "You are carrying:"
      n = 0
      FOR o = 1 TO NOBJ
        IF oLoc(o) = CARRIED THEN PRINT "  a "; LCASE$(oName$(o)): n = n + 1
      NEXT o
      IF n = 0 THEN PRINT "  nothing at all."
    CASE 10                                     ' EXAMINE
      o = FindObj(noun$)
      IF o = 0 THEN
        PRINT "Examine what?"
      ELSEIF oLoc(o) = CARRIED OR oLoc(o) = here THEN
        Wrap oDesc$(o)
      ELSE
        PRINT "It isn't here."
      END IF
    CASE 11                                     ' OPEN / UNLOCK DOOR
      IF here <> 3 OR noun$ <> "DOOR" THEN
        PRINT "There is nothing here to open."
      ELSEIF ex(3, 3) > 0 THEN
        PRINT "It is already open."
      ELSEIF oLoc(2) <> CARRIED THEN
        PRINT "It is locked. You need a key."
      ELSE
        ex(3, 3) = -ex(3, 3)       ' flip the negative "locked" marker to a real exit
        PRINT "The key turns with a groan. The iron door swings open!"
      END IF
    CASE 12
      PRINT "Farewell, adventurer.": END
    CASE 13
      PRINT "Verbs: GO, N/S/E/W, TAKE, DROP, LOOK, I, EXAMINE (X), OPEN, QUIT"
  END SELECT

  ' ---- win check: crown carried into the gatehouse ----
  IF oLoc(3) = CARRIED AND here = 1 THEN
    PRINT
    COLOR 10: PRINT "You carry the crown out through the gate. You have won!": COLOR 7
    END
  END IF
NextTurn:
LOOP

' Print the current room: name, description, visible objects, exits.
SUB Describe
  COLOR 11: PRINT rName$(here): COLOR 7
  Wrap rDesc$(here)
  FOR o = 1 TO NOBJ
    IF oLoc(o) = here THEN PRINT "There is a "; LCASE$(oName$(o)); " here."
  NEXT o
  e$ = ""
  IF ex(here, 1) <> 0 THEN e$ = e$ + " north"
  IF ex(here, 2) <> 0 THEN e$ = e$ + " south"
  IF ex(here, 3) <> 0 THEN e$ = e$ + " east"
  IF ex(here, 4) <> 0 THEN e$ = e$ + " west"
  PRINT "Exits:"; e$
END SUB

' Return the number of the object whose name matches n$, or 0.
' Only the first 4 letters must match, so abbreviations
' like "SHIE" for SHIELD work too.
FUNCTION FindObj% (n$)
  FindObj% = 0
  IF n$ = "" THEN EXIT FUNCTION
  FOR o = 1 TO NOBJ
    IF LEFT$(oName$(o), 4) = LEFT$(n$, 4) THEN FindObj% = o: EXIT FUNCTION
  NEXT o
END FUNCTION

' Print a long string, breaking lines between words so nothing is
' split in the middle of a word at the right edge of the screen.
SUB Wrap (t$)
  w$ = t$
  DO WHILE LEN(w$) > 78
    cut = 78
    DO WHILE cut > 1 AND MID$(w$, cut, 1) <> " ": cut = cut - 1: LOOP
    PRINT LEFT$(w$, cut - 1)
    w$ = MID$(w$, cut + 1)
  LOOP
  PRINT w$
END SUB
