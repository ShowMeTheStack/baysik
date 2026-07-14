' SIERPIN.BAS - The chaos game: random jumps draw an ordered fractal
SCREEN 12
RANDOMIZE TIMER
DIM vx(2), vy(2)
vx(0) = 320: vy(0) = 20: vx(1) = 40: vy(1) = 460: vx(2) = 600: vy(2) = 460
x = 320: y = 240
FOR i = 1 TO 60000
    v = INT(RND * 3)
    x = (x + vx(v)) / 2: y = (y + vy(v)) / 2
    PSET (x, y), 10 + v
    IF INKEY$ <> "" THEN EXIT FOR
NEXT
LOCATE 2, 2: PRINT "Sierpinski triangle from 60,000 random jumps"
SLEEP
