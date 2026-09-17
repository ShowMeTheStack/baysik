' ============================================================
' TITLE:    Space Station Escape
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     adventure, menus, state flags, puzzle, countdown
' SUMMARY:  Your station is losing air - restore power, find the keycard and launch the pod.
' ------------------------------------------------------------
' WHAT IT DOES
'   A meteor has holed orbital station KESTREL-7 and you are the
'   only one awake.  Each action uses up oxygen.  Instead of typing
'   free text you choose from a numbered menu - but the menu CHANGES
'   depending on where you are and what you have already done.
'   Solve the chain of puzzles: fuse -> power -> command deck ->
'   keycard -> launch code -> escape pod.
'
' HOW TO USE
'   Type the number of an action and press Enter.  0 quits.
'   Read everything carefully - the launch code is hidden in a log.
'
' CONCEPTS YOU WILL LEARN
'   * "Flags": true/false variables that remember the story so far
'   * Building a menu on the fly from the current situation
'   * Gating progress: an action only appears when it makes sense
'   * A resource (oxygen) that turns any game into a race
'
' THINGS TO TRY
'   * Add a second oxygen canister hidden somewhere else
'   * Randomise the launch code each game (see how it is chosen)
'   * Add a "hull breach" event that seals a module for good
' ============================================================

DECLARE SUB AddAct (t$, id%)
DEFINT A-Z
DIM SHARED act$(1 TO 10), actId(1 TO 10), nAct
DIM place$(1 TO 6)
DATA "Crew Quarters","Central Hub","Engineering","Storage Bay","Command Deck","Escape Pod Bay"
FOR i = 1 TO 6: READ place$(i): NEXT

RANDOMIZE TIMER
' The launch code is a random 4-digit number, so you must really
' read the log every game instead of remembering it.
code$ = LTRIM$(STR$(1000 + INT(RND * 9000)))

' ----- story flags (0 = not yet, 1 = done) -----
here = 1: oxygen = 40
hasLog = 0: hasFuse = 0: powerOn = 0: hasCard = 0: hasCan = 0: podReady = 0

CLS
COLOR 11
PRINT "*** KESTREL-7 ORBITAL STATION ***"
COLOR 7
PRINT "Alarms wake you. A computer voice: "; CHR$(34); "Hull breach. Oxygen failing."; CHR$(34)
PRINT "Every action costs one unit of oxygen. Get to the escape pod!"

DO
  PRINT
  COLOR 14: PRINT "== "; place$(here); " ==";: COLOR 7
  PRINT "   (oxygen:"; oxygen; ")"

  ' ---------- build the menu for THIS place and THIS moment ----------
  nAct = 0
  SELECT CASE here
    CASE 1   ' quarters
      PRINT "Bunks float loose. The commander's tablet blinks on a shelf."
      IF hasLog = 0 THEN AddAct "Pick up the tablet", 10 ELSE AddAct "Re-read the tablet", 11
      AddAct "Go to the Central Hub", 102
    CASE 2   ' hub
      PRINT "A round corridor with hatches in four directions."
      AddAct "Go to Crew Quarters", 101
      AddAct "Go to Engineering", 103
      AddAct "Go to Storage Bay", 104
      AddAct "Go to Command Deck", 105
      AddAct "Go to Escape Pod Bay", 106
    CASE 3   ' engineering
      IF powerOn THEN
        PRINT "The reactor hums happily. Lights are green."
      ELSE
        PRINT "The reactor is dark. An empty fuse socket gapes on the panel."
        IF hasFuse THEN AddAct "Fit the fuse and restart the reactor", 30
      END IF
      AddAct "Return to the Hub", 102
    CASE 4   ' storage
      PRINT "Crates are strapped to the walls."
      IF hasFuse = 0 THEN AddAct "Search the crates", 40
      IF hasCan = 0 THEN AddAct "Open the emergency locker", 41
      AddAct "Return to the Hub", 102
    CASE 5   ' command
      PRINT "Screens show Earth turning slowly below."
      IF hasCard = 0 THEN AddAct "Search the captain's chair", 50
      AddAct "Return to the Hub", 102
    CASE 6   ' pod bay
      PRINT "The escape pod waits behind a glass door with a card slot."
      IF podReady = 0 THEN AddAct "Swipe a keycard", 60 ELSE AddAct "Climb in and enter the launch code", 61
      AddAct "Return to the Hub", 102
  END SELECT
  IF hasCan = 1 THEN AddAct "Attach the oxygen canister (+15)", 90

  FOR i = 1 TO nAct: PRINT USING "  ## "; i;: PRINT act$(i): NEXT
  PRINT "   0 Give up"
  LINE INPUT "Choice? ", a$
  k = VAL(a$)
  IF a$ = "0" THEN PRINT "You close your eyes and wait...": END
  IF k < 1 OR k > nAct THEN PRINT "Pick a number from the list.": GOTO Skip
  id = actId(k)
  oxygen = oxygen - 1

  ' ---------- perform the chosen action ----------
  IF id > 100 THEN
    ' Moves are encoded as 100 + destination.
    dest = id - 100
    IF dest = 5 AND powerOn = 0 THEN
      PRINT "The Command Deck door has no power. It won't budge."
    ELSE
      here = dest
    END IF
  ELSE
    SELECT CASE id
      CASE 10, 11
        hasLog = 1
        PRINT "COMMANDER'S LOG: 'Pod launch code changed to "; code$; ". Spare"
        PRINT "fuses are in Storage. My keycard is under the chair cushion.'"
      CASE 40
        PRINT "Under some ration packs you find a reactor fuse!": hasFuse = 1
      CASE 41
        PRINT "Inside: a full oxygen canister.": hasCan = 1
      CASE 30
        PRINT "Sparks fly... then the reactor roars to life! Doors unlock."
        powerOn = 1: hasFuse = 0
      CASE 50
        PRINT "You find the commander's keycard tucked in the cushion.": hasCard = 1
      CASE 60
        IF hasCard = 0 THEN
          PRINT "You have no keycard."
        ELSEIF powerOn = 0 THEN
          PRINT "The slot is dead - the station has no power."
        ELSE
          PRINT "Beep! The glass door slides open.": podReady = 1
        END IF
      CASE 61
        LINE INPUT "Enter 4-digit launch code: ", g$
        IF LTRIM$(RTRIM$(g$)) = code$ THEN
          COLOR 10
          PRINT "Clamps release. The pod drops away from KESTREL-7 and"
          PRINT "turns toward the blue Earth. You made it home!"
          COLOR 7: END
        ELSE
          PRINT "WRONG CODE. Maybe the commander's tablet knows it."
        END IF
      CASE 90
        PRINT "Hiss... you breathe deeply.": oxygen = oxygen + 15: hasCan = 2
    END SELECT
  END IF

  IF oxygen = 8 THEN COLOR 12: PRINT "WARNING: oxygen low!": COLOR 7
  IF oxygen <= 0 THEN
    COLOR 12: PRINT "The air runs out. Your vision fades to black. GAME OVER."
    COLOR 7: END
  END IF
Skip:
LOOP

' Add one numbered line to the menu: its text and the action code
' the main program will act on if it is chosen.
SUB AddAct (t$, id)
  nAct = nAct + 1
  act$(nAct) = t$
  actId(nAct) = id
END SUB
