' SNAKE.BAS - Eat the stars, don't bite yourself!
' Keys: arrow keys to steer, Esc to quit.
' Concepts: arrays as a queue, INKEY$ extended keys, TIMER delays, SOUND, SCREEN function
DEFINT A-Z
DECLARE SUB PlaceFood ()
DIM SHARED sx(1000), sy(1000), fx, fy
RANDOMIZE TIMER
CLS
COLOR 9: LOCATE 1, 1: PRINT STRING$(80, 177)
FOR r = 2 TO 23: LOCATE r, 1: PRINT CHR$(177); : LOCATE r, 80: PRINT CHR$(177); : NEXT
LOCATE 24, 1: PRINT STRING$(80, 177);
head = 3: tail = 1: dx = 1: dy = 0: grow = 0: score = 0
FOR i = 1 TO 3: sx(i) = 38 + i: sy(i) = 12: LOCATE 12, 38 + i: COLOR 10: PRINT CHR$(219); : NEXT
PlaceFood
delay! = .09
DO
    t! = TIMER
    DO
        k$ = INKEY$
        IF k$ = CHR$(27) THEN EXIT DO
        IF LEN(k$) = 2 THEN
            SELECT CASE ASC(RIGHT$(k$, 1))
                CASE 72: IF dy = 0 THEN dx = 0: dy = -1
                CASE 80: IF dy = 0 THEN dx = 0: dy = 1
                CASE 75: IF dx = 0 THEN dx = -1: dy = 0
                CASE 77: IF dx = 0 THEN dx = 1: dy = 0
            END SELECT
        END IF
    LOOP WHILE TIMER - t! < delay! AND TIMER >= t!
    IF k$ = CHR$(27) THEN EXIT DO
    nx = sx(head) + dx: ny = sy(head) + dy
    c = SCREEN(ny, nx)
    IF c = 177 OR c = 219 THEN EXIT DO
    head = head MOD 1000 + 1: sx(head) = nx: sy(head) = ny
    COLOR 10: LOCATE ny, nx: PRINT CHR$(219);
    IF nx = fx AND ny = fy THEN
        score = score + 10: grow = grow + 3: SOUND 880, 1
        IF delay! > .03 THEN delay! = delay! - .004
        PlaceFood
    END IF
    IF grow > 0 THEN
        grow = grow - 1
    ELSE
        LOCATE sy(tail), sx(tail): PRINT " ";
        tail = tail MOD 1000 + 1
    END IF
    COLOR 15: LOCATE 25, 2: PRINT "Score:"; score;
LOOP
SOUND 110, 6
COLOR 12: LOCATE 12, 33: PRINT " GAME  OVER ";
COLOR 7: LOCATE 25, 40: PRINT "Final score:"; score;
END

SUB PlaceFood
    DO
        fx = INT(RND * 77) + 2: fy = INT(RND * 21) + 2
    LOOP UNTIL SCREEN(fy, fx) = 32
    COLOR 14: LOCATE fy, fx: PRINT "*";
END SUB
