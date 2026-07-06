s$ = "Hello, World"
PRINT LEFT$(s$, 5); "|"; RIGHT$(s$, 5); "|"; MID$(s$, 8, 3); "|"; MID$(s$, 8)
PRINT INSTR(s$, "o"); INSTR(6, s$, "o"); INSTR(s$, "z")
PRINT UCASE$(s$); " "; LCASE$(s$)
PRINT "["; LTRIM$("  x  "); "]["; RTRIM$("  x  "); "]"
PRINT ASC("A"); CHR$(66); STRING$(3, "*"); STRING$(2, 65); SPACE$(2); "|"
PRINT VAL("12.5abc"); VAL("  -3"); VAL("&HFF"); VAL("1E3")
PRINT HEX$(255); " "; OCT$(8); " "; HEX$(-1)
MID$(s$, 1, 5) = "Jello"
PRINT s$
PRINT ABS(-3); SGN(-2); SGN(0); INT(-2.5); FIX(-2.5); CINT(2.5); CINT(3.5); CLNG(-1.5)
PRINT SQR(16); 7 \ 2; -7 \ 2; 7 MOD 3; -7 MOD 3; 2 ^ 3
PRINT 5 AND 3; 5 OR 3; 5 XOR 3; NOT 0; NOT -1
PRINT (1 < 2); (2 < 1); "a" < "b"
PRINT CVI(MKI$(1234)); CVL(MKL$(-99999)); CVS(MKS$(1.5)); CVD(MKD$(2.25))
PRINT CVSMBF(MKSMBF$(3.75)); CVDMBF(MKDMBF$(-12.5))
PRINT LEN(STR$(123))
a = 10: b = 3: PRINT a / b
d# = 10#: PRINT d# / 3
PRINT 1 + 2 * 3 - 4 / 2
PRINT -2 ^ 2
