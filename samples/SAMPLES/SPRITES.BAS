' SPRITES.BAS - Flicker-free animation with GET/PUT sprites and page flipping
' Concepts: SCREEN 7 with 2 pages (draw on page 1 while showing page 0), PCOPY, GET, PUT
DEFINT A-Z
SCREEN 7, 0, 1, 0
DIM ball(200)
CIRCLE (8, 8), 7, 14: PAINT (8, 8), 12, 14
CIRCLE (6, 6), 2, 15: PAINT (6, 6), 15, 15
GET (0, 0)-(16, 16), ball
CONST NB = 6
DIM x(NB), y(NB), dx(NB), dy(NB)
RANDOMIZE TIMER
FOR i = 1 TO NB
    x(i) = RND * 280 + 10: y(i) = RND * 150 + 10
    dx(i) = INT(RND * 5) - 2: IF dx(i) = 0 THEN dx(i) = 3
    dy(i) = INT(RND * 5) - 2: IF dy(i) = 0 THEN dy(i) = -2
NEXT
DO
    CLS
    LINE (0, 0)-(319, 199), 9, B
    LOCATE 24, 2: PRINT "Page flipping demo - any key quits";
    FOR i = 1 TO NB
        x(i) = x(i) + dx(i): y(i) = y(i) + dy(i)
        IF x(i) < 2 OR x(i) > 300 THEN dx(i) = -dx(i)
        IF y(i) < 2 OR y(i) > 170 THEN dy(i) = -dy(i)
        PUT (x(i), y(i)), ball, PSET
    NEXT
    PCOPY 1, 0
    WAIT &H3DA, 8
LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
