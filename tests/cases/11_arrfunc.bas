DECLARE FUNCTION F$ (a$(), n)
DECLARE FUNCTION Total (v())
DIM w$(5), v(3)
w$(1) = "x": v(1) = 2: v(3) = 5
PRINT F$(w$(), 1); Total(v())
FUNCTION F$ (a$(), n)
  F$ = a$(n)
END FUNCTION
FUNCTION Total (v())
  FOR i = LBOUND(v) TO UBOUND(v): t = t + v(i): NEXT
  Total = t
END FUNCTION
