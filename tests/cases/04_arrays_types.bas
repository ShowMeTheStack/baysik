TYPE Pt
  x AS INTEGER
  y AS INTEGER
  label AS STRING * 5
END TYPE
DIM p AS Pt
p.x = 3: p.y = 4: p.label = "abc"
PRINT p.x; p.y; "["; p.label; "]"; LEN(p)
DIM pts(1 TO 3) AS Pt
FOR i = 1 TO 3: pts(i).x = i * 10: NEXT
PRINT pts(2).x; LBOUND(pts); UBOUND(pts)
DIM grid(2, 3) AS INTEGER
grid(2, 3) = 99
PRINT grid(2, 3); UBOUND(grid, 2)
a(5) = 7: PRINT a(5); UBOUND(a)
OPTION BASE 1
DIM b$(3)
b$(1) = "x": b$(3) = "z"
PRINT b$(1); b$(3); LBOUND(b$)
REDIM c(5): c(5) = 1: REDIM c(10): PRINT c(5); UBOUND(c)
REDIM PRESERVE c(12): c(12) = 3: PRINT c(12)
ERASE c
DIM q AS Pt
q = p
q.x = 100
PRINT p.x; q.x
SWAP p, q
PRINT p.x; q.x
CONST PI = 3.14159, NAME$ = "const"
PRINT PI; NAME$
DIM fs AS STRING * 4
fs = "abcdefg"
PRINT "["; fs; "]"
x% = 5: y% = 9: SWAP x%, y%: PRINT x%; y%
DIM m(1 TO 2, 1 TO 2)
m(1, 1) = 1: m(2, 2) = 4
PRINT m(1, 1) + m(2, 2)
