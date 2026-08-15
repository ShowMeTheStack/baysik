' ============================================================
' TITLE:    Traffic Flow and Phantom Jams
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     cellular automata, traffic, nagel-schreckenberg, space-time diagram
' SUMMARY:  Cars on a ring road follow four simple rules - and traffic jams appear out of nowhere.
' ------------------------------------------------------------
' WHAT IT DOES
'   Ever been stuck in a jam that had no accident, no roadworks -
'   nothing?  This is the Nagel-Schreckenberg model (1992).  The road
'   is a loop of cells; each cell holds at most one car.  Every tick
'   each car, at the same time:
'     1. ACCELERATE: speed + 1 (up to the limit VMAX = 5)
'     2. BRAKE: never drive into the car ahead (speed <= gap)
'     3. DAWDLE: with probability P, slow down by 1 for no reason
'        (a driver looking at their phone...)
'     4. MOVE forward by its speed
'   Each row of the picture is one moment in time; time runs down
'   the screen.  Cars are coloured by speed (red = stopped,
'   green = fast).  Jams show up as red stripes that drift BACKWARDS
'   even though every car drives forwards!
'
' HOW TO USE
'   + / -   more / fewer cars        P / p   more / less dawdling
'   ESC     quit
'
' CONCEPTS YOU WILL LEARN
'   * Agent-based modelling with simple rules
'   * Periodic (wrap-around) boundaries using MOD
'   * Space-time diagrams
'   * The "fundamental diagram": flow = density * average speed
'
' THINGS TO TRY
'   * Set dawdling to 0: jams vanish (until the road is very full).
'   * Find the density that gives the highest flow of cars.
'   * Add a slow lorry with VMAX = 2 and watch the queue behind it.
' ============================================================

DEFINT A-Z
CONST L = 320                   ' road length in cells (2 pixels each)
CONST VMAX = 5

DIM road(L - 1)                 ' -1 = empty, otherwise the car's speed
DIM nroad(L - 1)
DIM spcol(VMAX)
' colours for speeds 0..5: red, light red, yellow, white, light green, green
FOR i = 0 TO VMAX: READ spcol(i): NEXT
DATA 4, 12, 14, 15, 10, 2

RANDOMIZE TIMER
nCars = 60
pDawdle! = .25
SCREEN 12
GOSUB PlaceCars
row = 0

DO
    k$ = INKEY$
    SELECT CASE k$
        CASE "+", "=": nCars = nCars + 10: IF nCars > L - 10 THEN nCars = L - 10
            GOSUB PlaceCars
        CASE "-": nCars = nCars - 10: IF nCars < 10 THEN nCars = 10
            GOSUB PlaceCars
        CASE "P": pDawdle! = pDawdle! + .05: IF pDawdle! > .9 THEN pDawdle! = .9
        CASE "p": pDawdle! = pDawdle! - .05: IF pDawdle! < 0 THEN pDawdle! = 0
        CASE CHR$(27): EXIT DO
    END SELECT

    ' ---- update every car -------------------------------------------
    FOR i = 0 TO L - 1: nroad(i) = -1: NEXT
    moved = 0
    FOR i = 0 TO L - 1
        IF road(i) >= 0 THEN
            v = road(i)
            ' 1. accelerate
            IF v < VMAX THEN v = v + 1
            ' 2. look ahead for the next car (wrap around with MOD)
            gap = 0
            DO WHILE gap < v
                IF road((i + gap + 1) MOD L) >= 0 THEN EXIT DO
                gap = gap + 1
            LOOP
            IF v > gap THEN v = gap
            ' 3. random dawdling
            IF v > 0 AND RND < pDawdle! THEN v = v - 1
            ' 4. move
            nroad((i + v) MOD L) = v
            moved = moved + v
        END IF
    NEXT
    FOR i = 0 TO L - 1: road(i) = nroad(i): NEXT

    ' ---- draw this moment as one row of the space-time diagram ----
    y = 48 + row
    LINE (0, y)-(639, y), 0
    FOR i = 0 TO L - 1
        IF road(i) >= 0 THEN LINE (i * 2, y)-(i * 2 + 1, y), spcol(road(i))
    NEXT
    row = (row + 1) MOD 430
    LINE (0, 48 + row)-(639, 48 + row), 8     ' "now" marker line

    ' ---- statistics: flow = cars passing a point per tick ---------
    density! = nCars / L
    avgV! = moved / nCars
    LOCATE 1, 1: COLOR 15
    PRINT USING "Cars ###  density #.##  dawdle #.##  avg speed #.##  flow #.###"; nCars; density!; pDawdle!; avgV!; density! * avgV!
    LOCATE 2, 1: COLOR 7
    PRINT "Road ->  (time runs down)   +/- cars   P/p dawdle   ESC quit";
    LOCATE 3, 1
    FOR i = 0 TO VMAX: COLOR spcol(i): PRINT "speed"; i; " "; : NEXT
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' PlaceCars: put nCars cars at random empty cells, all stopped
' ------------------------------------------------------------
PlaceCars:
    FOR i = 0 TO L - 1: road(i) = -1: NEXT
    placed = 0
    DO WHILE placed < nCars
        c = INT(RND * L)
        IF road(c) < 0 THEN road(c) = 0: placed = placed + 1
    LOOP
RETURN
