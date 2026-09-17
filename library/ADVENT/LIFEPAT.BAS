' ============================================================
' TITLE:    Game of Life Pattern Library
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     cellular automata, conway, life, patterns, simulation
' SUMMARY:  A gallery of famous Conway's Life patterns - gliders, oscillators, guns and methuselahs.
' ------------------------------------------------------------
' WHAT IT DOES
'   John Conway's Game of Life (1970) is a grid of cells that are
'   alive or dead.  Every generation, all cells update at once:
'     * a live cell with 2 or 3 live neighbours survives
'     * a dead cell with exactly 3 live neighbours is born
'     * every other cell dies or stays dead
'   From those tiny rules come "creatures": gliders that walk,
'   oscillators that blink, guns that fire gliders forever, and
'   "methuselahs" - tiny seeds that churn for hundreds of turns.
'   Each pattern is stored in DATA as a little text picture.
'
' HOW TO USE
'   Pick a pattern from the menu by its letter.
'   While running:  Space = pause/resume,  S = single step,
'                   + / - = faster / slower,  Esc = back to menu.
'
' CONCEPTS YOU WILL LEARN
'   * Two-array "double buffering": compute the next grid from the old
'   * Counting neighbours with wrap-around edges (a torus world)
'   * Storing pictures as strings in DATA ("|" starts a new row,
'     a final "+" continues the picture in the next string)
'   * Emergence: complex behaviour from simple rules
'
' THINGS TO TRY
'   * Add your own pattern line to the DATA (and raise NPAT)
'   * Change the rules to "HighLife": also born with 6 neighbours
'   * Count the live cells each generation and print the number
' ============================================================

DEFINT A-Z
CONST GW = 78, GH = 21, NPAT = 10
DIM cell(0 TO GW + 1, 0 TO GH + 1), nxt(0 TO GW + 1, 0 TO GH + 1)
DIM pname$(1 TO NPAT), pdesc$(1 TO NPAT), pic$(1 TO NPAT)

DATA "Glider","walks diagonally forever",".O.|..O|OOO"
DATA "Lightweight spaceship","flies sideways",".O..O|O....|O...O|OOOO."
DATA "Blinker & Toad","period-2 oscillators","OOO.....|........|........|.....OOO|....OOO."
DATA "Beacon","blinks its corners","OO..|OO..|..OO|..OO"
DATA "Pulsar","a big period-3 oscillator","..OOO...OOO..|.............|O....O.O....O|O....O.O....O|O....O.O....O|..OOO...OOO..|.............|..OOO...OOO..|O....O.O....O|O....O.O....O|O....O.O....O|.............|..OOO...OOO.."
DATA "Pentadecathlon","period 15","..O....O..|OO.OOOO.OO|..O....O.."
DATA "Gosper glider gun","a glider every 30 turns (they wrap round and hit it!)"
DATA "........................O...........|......................O.O...........|+"
DATA "............OO......OO............OO|...........O...O....OO............OO|+"
DATA "OO........O.....O...OO..............|OO........O...O.OO....O.O...........|+"
DATA "..........O.....O.......O...........|...........O...O....................|+"
DATA "............OO......................"
DATA "R-pentomino","5 cells, busy for 1103 turns",".OO|OO.|.O."
DATA "Acorn","7 cells, grows for 5206 turns",".O.....|...O...|OO..OOO"
DATA "Diehard","vanishes after 130 turns","......O.|OO......|.O...OOO"
' A picture too long for one line ends in "+", meaning "continued on
' the next DATA string" (a QBasic line can only be 255 characters).
FOR i = 1 TO NPAT
  READ pname$(i), pdesc$(i), part$
  pic$(i) = ""
  DO WHILE RIGHT$(part$, 1) = "+"
    pic$(i) = pic$(i) + LEFT$(part$, LEN(part$) - 1)
    READ part$
  LOOP
  pic$(i) = pic$(i) + part$
NEXT

DO
  ' ---------------- menu ----------------
  COLOR 7: CLS
  COLOR 14: PRINT "CONWAY'S GAME OF LIFE - PATTERN LIBRARY": COLOR 7
  PRINT
  FOR i = 1 TO NPAT
    COLOR 11: PRINT "  "; CHR$(64 + i); ") ";: COLOR 15: PRINT pname$(i);
    COLOR 8: PRINT " - "; pdesc$(i): COLOR 7
  NEXT
  PRINT : PRINT "  Esc) Quit"
  DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
  IF k$ = CHR$(27) OR k$ = "Q" THEN EXIT DO
  p = ASC(k$) - 64
  IF p >= 1 AND p <= NPAT THEN GOSUB RunPattern
LOOP
CLS: PRINT "Life goes on without you. Bye!"
END

RunPattern:
  ' ---- clear the world and stamp the picture in the middle ----
  FOR x = 0 TO GW + 1: FOR y = 0 TO GH + 1: cell(x, y) = 0: NEXT y, x
  ' first measure the picture: rows = number of "|" + 1
  t$ = pic$(p) + "|"
  rows = 0: wid = 0: start = 1
  DO
    bar = INSTR(start, t$, "|")
    IF bar = 0 THEN EXIT DO
    rows = rows + 1
    IF bar - start > wid THEN wid = bar - start
    start = bar + 1
  LOOP
  ox = (GW - wid) \ 2: oy = (GH - rows) \ 2
  IF p = 7 THEN ox = 3: oy = 2           ' the gun needs room to shoot
  y = oy: x = ox
  FOR i = 1 TO LEN(t$)
    c$ = MID$(t$, i, 1)
    IF c$ = "|" THEN
      y = y + 1: x = ox
    ELSE
      x = x + 1
      IF c$ = "O" THEN cell(x, y + 1) = 1
    END IF
  NEXT

  CLS
  gen = 0: paused = 0: delay! = .05
  DO
    ' ---- draw: build each row as one string, then print it ----
    alive = 0
    FOR y = 1 TO GH
      r$ = ""
      FOR x = 1 TO GW
        IF cell(x, y) THEN r$ = r$ + CHR$(254): alive = alive + 1 ELSE r$ = r$ + " "
      NEXT
      LOCATE y + 1, 2: COLOR 10: PRINT r$;
    NEXT
    LOCATE 1, 1: COLOR 14
    PRINT LEFT$(pname$(p), 22); "  gen"; gen; " cells"; alive; "  [Space S + - Esc]   ";
    COLOR 7

    ' ---- keyboard ----
    stepOnce = 0
    DO
      k$ = UCASE$(INKEY$)
      IF k$ = CHR$(27) THEN RETURN
      IF k$ = " " THEN paused = 1 - paused
      IF k$ = "S" THEN stepOnce = 1: paused = 1
      IF k$ = "+" AND delay! > .01 THEN delay! = delay! / 2
      IF k$ = "-" AND delay! < 1 THEN delay! = delay! * 2
    LOOP WHILE paused AND stepOnce = 0
    t! = TIMER: DO: LOOP WHILE TIMER - t! < delay! AND TIMER >= t!

    ' ---- wrap the edges: copy each border into the opposite margin ----
    ' so a glider leaving on the right comes back on the left.
    FOR x = 1 TO GW: cell(x, 0) = cell(x, GH): cell(x, GH + 1) = cell(x, 1): NEXT
    FOR y = 0 TO GH + 1: cell(0, y) = cell(GW, y): cell(GW + 1, y) = cell(1, y): NEXT

    ' ---- apply the rules into nxt(), then copy back ----
    FOR y = 1 TO GH
      FOR x = 1 TO GW
        n = cell(x - 1, y - 1) + cell(x, y - 1) + cell(x + 1, y - 1)
        n = n + cell(x - 1, y) + cell(x + 1, y)
        n = n + cell(x - 1, y + 1) + cell(x, y + 1) + cell(x + 1, y + 1)
        IF n = 3 OR (n = 2 AND cell(x, y) = 1) THEN nxt(x, y) = 1 ELSE nxt(x, y) = 0
      NEXT
    NEXT
    FOR y = 1 TO GH: FOR x = 1 TO GW: cell(x, y) = nxt(x, y): NEXT x, y
    gen = gen + 1
  LOOP
RETURN
