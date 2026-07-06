DECLARE SUB Swap2 (a, b)
DECLARE FUNCTION Fact& (n%)
DECLARE FUNCTION Fib% (n%)
DIM SHARED counter AS INTEGER
x = 1: y = 2
Swap2 x, y
PRINT x; y
CALL Swap2((x), y)
PRINT x; y
PRINT Fact&(10); Fib%(15)
FOR i = 1 TO 3: Tick: NEXT
PRINT "counter"; counter
PRINT Greet$("Ada")
s = 0: Accumulate 5, s: PRINT s
DEF FNsq (v) = v * v
PRINT FNsq(7)
DEF FNmax (a, b)
  IF a > b THEN FNmax = a ELSE FNmax = b
END DEF
PRINT FNmax(3, 9)
END

SUB Swap2 (a, b)
  t = a: a = b: b = t
END SUB

FUNCTION Fact& (n%)
  IF n% <= 1 THEN Fact& = 1 ELSE Fact& = n% * Fact&(n% - 1)
END FUNCTION

FUNCTION Fib% (n%)
  IF n% < 2 THEN Fib% = n%: EXIT FUNCTION
  Fib% = Fib%(n% - 1) + Fib%(n% - 2)
END FUNCTION

SUB Tick STATIC
  calls = calls + 1
  counter = counter + calls
END SUB

FUNCTION Greet$ (n$)
  Greet$ = "Hello, " + n$ + "!"
END FUNCTION

SUB Accumulate (n, total)
  FOR i = 1 TO n: total = total + i: NEXT
END SUB
