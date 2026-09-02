' ============================================================
' TITLE:    Battleship
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     board game, ai, arrays, random placement, cursor
' SUMMARY:  Hunt down the computer's hidden fleet before it sinks yours.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two 10x10 oceans: yours on the left (you can see your ships) and
'   the enemy's on the right (hidden).  Both fleets have five ships:
'   Carrier 5, Battleship 4, Cruiser 3, Submarine 3, Destroyer 2.
'   You take turns firing.  "*" marks a hit, "o" a miss.
'   The computer hunts in a checkerboard pattern; once it hits
'   something it switches to "target mode" and tries the squares
'   around the hit until the ship is sunk.
'
' HOW TO USE
'   Before the battle: R = re-shuffle your fleet, Enter = start.
'   Arrow keys move the target cursor, Space or Enter fires.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Random placement that never overlaps (try, check, retry)
'   * 2-D arrays storing ship numbers, hits and misses
'   * A hunt/target AI using a small "to-do" stack of squares
'   * A moving cursor in text mode
'
' THINGS TO TRY
'   * Let the player place each ship by hand
'   * Make the AI smarter: once two hits line up, keep going in that line
'   * Give each side a "salvo" of three shots per turn
' ============================================================

DECLARE SUB PlaceFleet (who%)
DECLARE SUB DrawGrid (who%, showShips%)
DECLARE SUB DrawCell (who%, r%, c%, showShips%)

DEFINT A-Z
CONST N = 10
' sea(who, r, c): 0 = water, 1..5 = ship number
' shot(who, r, c): 0 = not shot yet, 1 = miss, 2 = hit  (shots INTO that sea)
DIM SHARED sea(1 TO 2, 1 TO N, 1 TO N), shot(1 TO 2, 1 TO N, 1 TO N)
DIM SHARED cursorOn               ' true while drawing the aiming cursor
DIM SHARED size(1 TO 5), shipName$(1 TO 5), hp(1 TO 2, 1 TO 5)
DATA 5,Carrier, 4,Battleship, 3,Cruiser, 3,Submarine, 2,Destroyer
FOR i = 1 TO 5: READ size(i), shipName$(i): NEXT
' the computer's target stack: squares worth trying next
DIM stkR(1 TO 100), stkC(1 TO 100)
' neighbour offsets: up, down, left, right
DIM nr(1 TO 4), nc(1 TO 4)
DATA -1,0, 1,0, 0,-1, 0,1
FOR i = 1 TO 4: READ nr(i), nc(i): NEXT

RANDOMIZE TIMER
CONST YOU = 1, CPU = 2

' ---------- set up the fleets ----------
CLS
PlaceFleet CPU
DO
  PlaceFleet YOU
  DrawGrid YOU, -1
  LOCATE 22, 2: PRINT "This is your fleet.  R = re-shuffle,  Enter = start battle"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = CHR$(13) OR k$ = CHR$(27)
  IF k$ = CHR$(27) THEN GOTO Quit
LOOP UNTIL k$ = CHR$(13)

CLS
DrawGrid YOU, -1
DrawGrid CPU, 0
youLeft = 17: cpuLeft = 17             ' 5+4+3+3+2 ship squares each
cr = 5: cc = 5                         ' your aiming cursor
sp = 0                                 ' items on the computer's stack

DO
  ' ================= YOUR SHOT =================
  LOCATE 22, 2: PRINT "Your shot: arrows to aim, Space to fire" + SPACE$(30)
  DO
    ' the cursor is shown by drawing the cell in reverse colours
    cursorOn = -1: DrawCell CPU, cr, cc, 0: cursorOn = 0
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    DrawCell CPU, cr, cc, 0
    IF k$ = CHR$(27) THEN GOTO Quit
    IF LEN(k$) = 2 THEN
      SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 72: IF cr > 1 THEN cr = cr - 1
        CASE 80: IF cr < N THEN cr = cr + 1
        CASE 75: IF cc > 1 THEN cc = cc - 1
        CASE 77: IF cc < N THEN cc = cc + 1
      END SELECT
    END IF
    fire = (k$ = " " OR k$ = CHR$(13))
    IF fire AND shot(CPU, cr, cc) <> 0 THEN fire = 0: SOUND 200, 1   ' already shot there
  LOOP UNTIL fire
  r = cr: c = cc: target = CPU: GOSUB Fire
  IF cpuLeft = 0 THEN msg$ = "VICTORY! You sank the whole enemy fleet!": EXIT DO

  ' ================= COMPUTER'S SHOT =================
  t! = TIMER: DO: LOOP WHILE TIMER < t! + .6 AND TIMER >= t!
  ' TARGET MODE: pop squares from the stack until we find an unshot one
  r = 0
  DO WHILE sp > 0 AND r = 0
    r = stkR(sp): c = stkC(sp): sp = sp - 1
    IF shot(YOU, r, c) <> 0 THEN r = 0
  LOOP
  ' HUNT MODE: random square on the checkerboard (every ship covers
  ' at least one square where r + c is even, so this finds them faster)
  IF r = 0 THEN
    tries = 0
    DO
      r = INT(RND * N) + 1: c = INT(RND * N) + 1: tries = tries + 1
    LOOP UNTIL shot(YOU, r, c) = 0 AND ((r + c) MOD 2 = 0 OR tries > 200)
  END IF
  target = YOU: GOSUB Fire
  IF youLeft = 0 THEN msg$ = "DEFEAT! The computer sank your fleet.": EXIT DO
LOOP

LOCATE 22, 2: PRINT msg$; SPACE$(30)
DrawGrid CPU, -1                       ' reveal the enemy ships
IF cpuLeft = 0 THEN PLAY "MB T150 L8 CEG>C<G>C" ELSE PLAY "MB T90 L4 EC<A"
LOCATE 24, 2: PRINT "Press Esc to exit.";
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
COLOR 7, 0: CLS
PRINT "Battleship ended."
END

' ---- fire at (r, c) in sea "target" and report ----
Fire:
  s = sea(target, r, c)
  IF target = CPU THEN who$ = "You fire at " ELSE who$ = "Computer fires at "
  LOCATE 23, 2: PRINT who$; CHR$(64 + c); LTRIM$(STR$(r)); ": ";
  IF s = 0 THEN
    shot(target, r, c) = 1
    PRINT "miss.                              "
    SOUND 300, 1
  ELSE
    shot(target, r, c) = 2
    hp(target, s) = hp(target, s) - 1
    IF target = CPU THEN cpuLeft = cpuLeft - 1 ELSE youLeft = youLeft - 1
    IF hp(target, s) = 0 THEN
      PRINT "HIT - and sank the "; shipName$(s); "!       "
      PLAY "MB T200 L32 O2 CC<G"
    ELSE
      PRINT "HIT!                               "
      SOUND 900, 2
    END IF
    ' the computer remembers the neighbours of every hit
    IF target = YOU THEN
      FOR d = 1 TO 4
        rr = r + nr(d): cc2 = c + nc(d)
        IF rr >= 1 AND rr <= N AND cc2 >= 1 AND cc2 <= N THEN
          IF shot(YOU, rr, cc2) = 0 AND sp < 100 THEN
            sp = sp + 1: stkR(sp) = rr: stkC(sp) = cc2
          END IF
        END IF
      NEXT
    END IF
  END IF
  DrawCell target, r, c, (target = YOU)
RETURN

SUB DrawCell (who, r, c, showShips)
  ' Each cell is 2 characters wide.  Colours: red hits, grey ships,
  ' blue water - or black-on-yellow when the cursor is on it.
  x = 5 + (who - 1) * 36 + (c - 1) * 2
  LOCATE 3 + r, x
  IF cursorOn THEN
    COLOR 0, 14
  ELSEIF shot(who, r, c) = 2 THEN
    COLOR 12
  ELSEIF shot(who, r, c) = 0 AND showShips AND sea(who, r, c) > 0 THEN
    COLOR 7
  ELSE
    COLOR 9
  END IF
  SELECT CASE shot(who, r, c)
    CASE 1: PRINT "o ";
    CASE 2: PRINT "* ";
    CASE ELSE
      IF showShips AND sea(who, r, c) > 0 THEN
        PRINT CHR$(219); CHR$(219);
      ELSE
        PRINT CHR$(250); " ";              ' a small dot = open water
      END IF
  END SELECT
  COLOR 7, 0
END SUB

SUB DrawGrid (who, showShips)
  x = 5 + (who - 1) * 36
  LOCATE 1, x
  IF who = 1 THEN PRINT "YOUR FLEET" ELSE PRINT "ENEMY WATERS"
  LOCATE 3, x
  FOR c = 1 TO N: PRINT CHR$(64 + c); " "; : NEXT     ' column letters A-J
  FOR r = 1 TO N
    LOCATE 3 + r, x - 3: PRINT USING "##"; r;
    FOR c = 1 TO N
      DrawCell who, r, c, showShips
    NEXT
  NEXT
  COLOR 7
END SUB

SUB PlaceFleet (who)
  ' Clear the sea, then place each ship at a random spot and direction.
  ' If it would stick out of the grid or touch another ship's square,
  ' just try again - with plenty of room this finishes quickly.
  FOR r = 1 TO N: FOR c = 1 TO N
    sea(who, r, c) = 0: shot(who, r, c) = 0
  NEXT: NEXT
  FOR s = 1 TO 5
    hp(who, s) = size(s)
    DO
      horiz = INT(RND * 2)                    ' 1 = across, 0 = down
      r = INT(RND * N) + 1: c = INT(RND * N) + 1
      ok = -1
      FOR i = 0 TO size(s) - 1
        rr = r + i * (1 - horiz): cc = c + i * horiz
        IF rr > N OR cc > N THEN ok = 0: EXIT FOR
        IF sea(who, rr, cc) <> 0 THEN ok = 0: EXIT FOR
      NEXT
    LOOP UNTIL ok
    FOR i = 0 TO size(s) - 1
      sea(who, r + i * (1 - horiz), c + i * horiz) = s
    NEXT
  NEXT
END SUB
