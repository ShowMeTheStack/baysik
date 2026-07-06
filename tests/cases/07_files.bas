OPEN "test.txt" FOR OUTPUT AS #1
PRINT #1, "line one"
PRINT #1, 42, "x"
WRITE #1, "quoted, text", 3.5, -2
CLOSE #1
OPEN "test.txt" FOR APPEND AS #1
PRINT #1, "appended"
CLOSE
OPEN "test.txt" FOR INPUT AS #2
LINE INPUT #2, a$: PRINT "["; a$; "]"
INPUT #2, n, s$: PRINT n; s$
INPUT #2, q$, v, w: PRINT q$; v; w
LINE INPUT #2, l$: PRINT l$
PRINT EOF(2); LOF(2)
CLOSE #2
TYPE Rec
  nm AS STRING * 8
  age AS INTEGER
END TYPE
DIM r AS Rec
OPEN "people.dat" FOR RANDOM AS #1 LEN = LEN(r)
r.nm = "Alice": r.age = 30: PUT #1, 1, r
r.nm = "Bob": r.age = 25: PUT #1, 2, r
GET #1, 1, r: PRINT RTRIM$(r.nm); r.age
GET #1, 2, r: PRINT RTRIM$(r.nm); r.age; LOF(1); LOC(1)
CLOSE
OPEN "bin.dat" FOR BINARY AS #1
x& = 123456: PUT #1, , x&
t$ = "hey": PUT #1, , t$
SEEK #1, 1: y& = 0: GET #1, , y&
u$ = SPACE$(3): GET #1, , u$
PRINT y&; u$; LOF(1); SEEK(1)
CLOSE
OPEN "R", #1, "field.dat", 20
FIELD #1, 10 AS f1$, 10 AS f2$
LSET f1$ = "left": RSET f2$ = "right"
PUT #1, 1
LSET f1$ = "": GET #1, 1
PRINT "["; f1$; "]["; f2$; "]"
CLOSE
FILES "*.DAT"
KILL "bin.dat"
NAME "field.dat" AS "f2.dat"
MKDIR "sub": CHDIR "sub": OPEN "in.txt" FOR OUTPUT AS #1: PRINT #1, "deep": CLOSE: CHDIR ".."
OPEN "sub\in.txt" FOR INPUT AS #1: INPUT #1, z$: PRINT z$: CLOSE
PRINT FREEFILE
