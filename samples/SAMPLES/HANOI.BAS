' HANOI.BAS - Towers of Hanoi: the classic recursion example
' TRY THIS: set a breakpoint (F9) on the "Move" line, run, and open the Call Stack
' panel. Watch the stack grow and shrink as the recursion unfolds!
DECLARE SUB Solve (n AS INTEGER, from AS INTEGER, dest AS INTEGER, via AS INTEGER)
DECLARE SUB Move (from AS INTEGER, dest AS INTEGER)
DECLARE SUB DrawAll ()
DIM SHARED pegs(1 TO 3, 1 TO 10) AS INTEGER, h(1 TO 3) AS INTEGER, moves AS LONG
CONST DISKS = 5
SCREEN 12
FOR i = DISKS TO 1 STEP -1: h(1) = h(1) + 1: pegs(1, h(1)) = i: NEXT
DrawAll
SLEEP 1
Solve DISKS, 1, 3, 2
LOCATE 28, 30: PRINT "Solved in"; moves; "moves!"
SLEEP

SUB DrawAll
    LINE (0, 120)-(639, 440), 0, BF
    FOR p = 1 TO 3
        x = p * 160
        LINE (x - 3, 200)-(x + 3, 400), 6, BF
        FOR k = 1 TO h(p)
            w = pegs(p, k) * 12
            LINE (x - w, 400 - k * 18)-(x + w, 400 - k * 18 + 15), pegs(p, k) + 8, BF
        NEXT
    NEXT
    LINE (40, 401)-(600, 410), 6, BF
    LOCATE 3, 30: PRINT "Moves:"; moves; "   "
END SUB

SUB Move (from AS INTEGER, dest AS INTEGER)
    h(dest) = h(dest) + 1
    pegs(dest, h(dest)) = pegs(from, h(from))
    h(from) = h(from) - 1
    moves = moves + 1
    DrawAll
    SOUND 300 + dest * 200, .5
END SUB

SUB Solve (n AS INTEGER, from AS INTEGER, dest AS INTEGER, via AS INTEGER)
    IF n = 0 THEN EXIT SUB
    Solve n - 1, from, via, dest
    Move from, dest
    Solve n - 1, via, dest, from
END SUB
