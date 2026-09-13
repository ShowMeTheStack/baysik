' ============================================================
' TITLE:    The Josephus Problem
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     josephus, recursion, circle, binary, animation, graphics
' SUMMARY:  People stand in a circle and every k-th one is removed - watch it happen and learn the formula that predicts the survivor.
' ------------------------------------------------------------
' WHAT IT DOES
'   n people stand in a circle numbered 1..n.  Counting starts at
'   person 1; every k-th person steps out, and counting continues
'   from the next person.  Who is the last one standing?
'   (The legend says the historian Josephus used this to survive.)
'
'   The program animates the elimination on a circle of dots, then
'   checks the answer with the famous recurrence:
'       J(1) = 0,   J(m) = (J(m-1) + k) MOD m      (counting from 0)
'   and, when k = 2, with a lovely binary trick: write n in binary
'   and move the leading 1 to the end.  41 = 101001 -> 010011 = 19.
'
' HOW TO USE
'   Enter n (2-60) and k (1-20).  Press a key to step faster
'   (Esc skips the animation).  Q quits at the prompts.
'
' CONCEPTS YOU WILL LEARN
'   * Simulating a circle with an array and MOD
'   * A recurrence that turns an O(n*k) simulation into O(n)
'   * Binary representation and bit tricks
'   * Placing points on a circle with SIN and COS
'
' THINGS TO TRY
'   * Print the survivor for n = 1..32 with k = 2.  Spot the pattern?
'   * Change the program so it reports the order of elimination.
' ============================================================
DECLARE FUNCTION Bin$ (v AS INTEGER)
DECLARE SUB DrawPerson (i AS INTEGER, col AS INTEGER)
DEFINT A-Z

CONST PI = 3.14159265#
DIM SHARED n
DIM alive(60)

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "THE JOSEPHUS PROBLEM": COLOR 7
    PRINT
    DO
        LINE INPUT "How many people, 2-60 (Q quits)? "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN END
        n = VAL(a$)
    LOOP UNTIL n >= 2 AND n <= 60
    DO
        LINE INPUT "Remove every k-th person, k = 1-20? "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN END
        k = VAL(a$)
    LOOP UNTIL k >= 1 AND k <= 20

    SCREEN 12
    LOCATE 1, 2: PRINT "n ="; n; "  k ="; k; "   (any key = faster, Esc = skip)"
    FOR i = 1 TO n: alive(i) = -1: DrawPerson i, 10: NEXT

    ' ---- Simulation ------------------------------------------------
    cur = 0                   ' index of the last person counted (0 = before 1)
    remaining = n
    delay! = .3: skip = 0
    order$ = ""
    DO WHILE remaining > 1
        ' Count k living people, going round the circle.
        cnt = 0
        DO
            cur = cur MOD n + 1
            IF alive(cur) THEN cnt = cnt + 1
        LOOP UNTIL cnt = k
        alive(cur) = 0: remaining = remaining - 1
        IF LEN(order$) < 200 THEN order$ = order$ + STR$(cur)
        IF NOT skip THEN
            DrawPerson cur, 14            ' flash yellow...
            t! = TIMER
            DO
                k$ = INKEY$
                IF k$ = CHR$(27) THEN skip = -1
                IF k$ <> "" THEN delay! = delay! / 3
            LOOP UNTIL TIMER - t! >= delay! OR TIMER < t! OR skip
        END IF
        DrawPerson cur, 4                 ' ...then dark red = out
    LOOP
    FOR i = 1 TO n
        IF alive(i) THEN survivor = i
    NEXT
    DrawPerson survivor, 15
    CIRCLE (320, 215), 30, 15
    LOCATE 14, 39: PRINT USING "##"; survivor

    ' ---- Check with the recurrence ---------------------------------
    j = 0
    FOR m = 2 TO n
        j = (j + k) MOD m
    NEXT
    LOCATE 26, 2: PRINT "Survivor by simulation:"; survivor; "   by the recurrence J(m)=(J(m-1)+k) MOD m:"; j + 1
    IF k = 2 THEN
        b$ = Bin$(n)
        rot$ = MID$(b$, 2) + "1"
        v = 0
        FOR i = 1 TO LEN(rot$): v = v * 2 + VAL(MID$(rot$, i, 1)): NEXT
        LOCATE 27, 2: PRINT "k = 2 binary trick: "; b$; " -> "; rot$; " ="; v
    END IF
    LOCATE 28, 2: PRINT "Out in order:"; LEFT$(order$, 60);
    IF LEN(order$) > 60 THEN PRINT "...";
    LOCATE 30, 2: PRINT "Press a key (Q quits)";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF UCASE$(k$) = "Q" OR k$ = CHR$(27) THEN EXIT DO
LOOP
SCREEN 0: WIDTH 80: CLS
END

FUNCTION Bin$ (v AS INTEGER)
    ' Build the binary digits of v by repeated division by 2.
    s$ = "": x = v
    DO
        s$ = CHR$(48 + (x AND 1)) + s$
        x = x \ 2
    LOOP WHILE x > 0
    Bin$ = s$
END FUNCTION

SUB DrawPerson (i AS INTEGER, col AS INTEGER)
    ' Person 1 at the top, then clockwise.  Angle = 2*pi*(i-1)/n.
    a# = 2 * PI * (i - 1) / n
    x = 320 + 150 * SIN(a#)
    y = 215 - 150 * COS(a#)
    CIRCLE (x, y), 8, col
    PAINT (x, y), col, col
    ' Number labels just outside the circle.
    lx = 320 + 178 * SIN(a#): ly = 215 - 178 * COS(a#)
    COLOR 7
    LOCATE ly \ 16 + 1, lx \ 8: PRINT LTRIM$(STR$(i));
END SUB
