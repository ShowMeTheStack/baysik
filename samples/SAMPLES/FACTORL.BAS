' FACTORL.BAS - Recursion and the debugger
' 1. Click the gutter next to the line marked <-- to set a breakpoint (or press F9 there).
' 2. Press F5. When it stops, open the Call Stack and Variables panels.
' 3. Click different frames: each one has its own n%!
' 4. Press F8 to step, F10 to step over, Shift+F8 to step out.
' 5. Double-click a variable's value to change it while paused.
DECLARE FUNCTION Factorial# (n%)
DECLARE FUNCTION Fib& (n%)
CLS
FOR i% = 0 TO 12
    PRINT USING "##_! = ###,###,###"; i%; Factorial#(i%)
NEXT
PRINT
PRINT "Fibonacci numbers:";
FOR i% = 1 TO 15: PRINT Fib&(i%); : NEXT
PRINT

FUNCTION Factorial# (n%)
    IF n% <= 1 THEN
        Factorial# = 1            ' <-- try a breakpoint here
    ELSE
        Factorial# = n% * Factorial#(n% - 1)
    END IF
END FUNCTION

FUNCTION Fib& (n%)
    IF n% < 3 THEN Fib& = 1 ELSE Fib& = Fib&(n% - 1) + Fib&(n% - 2)
END FUNCTION
