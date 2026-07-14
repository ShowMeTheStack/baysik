' MANDEL.BAS - The Mandelbrot set in 320x200x256 (SCREEN 13)
' Concepts: nested loops, floating point, programming the VGA palette with OUT
DEFINT I, P, X, Y
SCREEN 13
' Build a smooth blue-to-gold palette in DAC registers 1..63
FOR i = 1 TO 63
    OUT &H3C8, i
    OUT &H3C9, i \ 2: OUT &H3C9, i \ 3: OUT &H3C9, 63 - i \ 2
    OUT &H3C8, i + 64
    OUT &H3C9, 63: OUT &H3C9, 32 + i \ 2: OUT &H3C9, i \ 4
NEXT
maxIter = 120
FOR y = 0 TO 199
    ci! = (y - 100) / 80
    FOR x = 0 TO 319
        cr! = (x - 210) / 100
        zr! = 0: zi! = 0: iter = 0
        DO WHILE iter < maxIter AND zr! * zr! + zi! * zi! < 4
            t! = zr! * zr! - zi! * zi! + cr!
            zi! = 2 * zr! * zi! + ci!
            zr! = t!
            iter = iter + 1
        LOOP
        IF iter = maxIter THEN PSET (x, y), 0 ELSE PSET (x, y), 1 + (iter * 3) MOD 127
    NEXT x
NEXT y
SLEEP
