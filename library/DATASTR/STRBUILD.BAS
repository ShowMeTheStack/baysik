' ============================================================
' TITLE:    String Builder
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     strings, buffer, MID$ statement, amortized growth, performance
' SUMMARY:  Builds a long string inside a growing pre-allocated buffer with the MID$ statement, and counts how much copying it saves.
' ------------------------------------------------------------
' WHAT IT DOES
'   Writing  s$ = s$ + piece$  in a loop looks innocent, but each
'   time BASIC makes a brand-new string and copies ALL the old
'   characters into it. Adding 1000 pieces copies the early text
'   about 1000 times!
'
'   A STRING BUILDER keeps a big buffer (made with SPACE$) and a
'   length counter. New text is written INTO the buffer with the
'   MID$ *statement* (MID$ on the left of =), which changes
'   characters in place without making a new string. When the
'   buffer is full it DOUBLES in size, so copying happens rarely.
'
'   The program builds the same text both ways, counting the
'   characters copied, then uses the builder to
'   make a neat report.
'
' HOW TO USE
'   Press a key between steps. Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * The MID$ statement: MID$(buf$, start, n) = text$
'   * Capacity vs. length - a buffer bigger than its contents
'   * Doubling growth: total copying stays proportional to length
'   * Measuring work by counting operations instead of timing
'
' THINGS TO TRY
'   * Grow by +100 instead of doubling and compare the copy counts
'   * Add a SB.Insert that opens a gap in the middle
' ============================================================

DEFINT A-Z
DECLARE SUB SbInit ()
DECLARE SUB SbAdd (t$)
DECLARE FUNCTION SbText$ ()

' The builder's state: buffer, used length, and statistics.
DIM SHARED buf$, used, grows
DIM SHARED copied AS LONG

CONST PIECES = 1500
CLS
PRINT "STRING BUILDER vs. plain concatenation"
PRINT
PRINT "Building a string from"; PIECES; "pieces like 'item123;'"
PRINT

' ---- Way 1: plain concatenation -----------------------------
' We can't see inside BASIC, but we know s$ + p$ copies LEN(s$)
' old characters plus the new ones, so we add that up ourselves.
s$ = "": naive& = 0
FOR i = 1 TO PIECES
    p$ = "item" + LTRIM$(STR$(i)) + ";"
    naive& = naive& + LEN(s$) + LEN(p$)
    s$ = s$ + p$
NEXT i

' ---- Way 2: the builder -------------------------------------
SbInit
FOR i = 1 TO PIECES
    SbAdd "item" + LTRIM$(STR$(i)) + ";"
NEXT i
r$ = SbText$

PRINT "Final length:"; LEN(s$); "characters"
PRINT "Both results identical? "; : IF r$ = s$ THEN PRINT "YES" ELSE PRINT "NO (bug!)"
PRINT
PRINT "                      characters copied"
PRINT USING "Plain  s$ = s$ + p$     ###,###,###"; naive&
PRINT USING "String builder          ###,###,###"; copied
PRINT
PRINT "The builder grew its buffer only"; grows; "times (doubling each time)."
PRINT USING "Plain concatenation copied ###.# times more characters."; naive& / copied
PRINT "(Copy counts don't depend on how fast the computer is.)"
PRINT
PRINT "Press a key for a builder at work..."
k$ = INPUT$(1)
IF k$ = CHR$(27) THEN END

' ---- A builder making a formatted report ---------------------
CLS
SbInit
nl$ = CHR$(13)                     ' carriage return = "new line" when PRINTed
SbAdd "TIMES TABLE built with the string builder" + nl$
SbAdd STRING$(44, "-") + nl$
FOR r = 1 TO 9
    FOR c = 1 TO 9
        n$ = STR$(r * c)
        SbAdd RIGHT$("    " + n$, 4)       ' right-align in 4 chars
    NEXT c
    SbAdd nl$
NEXT r
SbAdd STRING$(44, "-") + nl$
report$ = SbText$
PRINT report$;
PRINT "Report is"; LEN(report$); "chars; buffer capacity"; LEN(buf$); "; grew"; grows; "times."
END

' SbAdd: append t$ into the buffer, growing it first if needed.
SUB SbAdd (t$)
    need = used + LEN(t$)
    IF need > LEN(buf$) THEN
        ' Double the capacity until it fits. Making the new buffer
        ' copies the old text once - that's the only big copy.
        cap = LEN(buf$)
        DO WHILE cap < need: cap = cap * 2: LOOP
        buf$ = LEFT$(buf$, used) + SPACE$(cap - used)
        copied = copied + used
        grows = grows + 1
    END IF
    ' Write the new text in place. No new string is created.
    MID$(buf$, used + 1, LEN(t$)) = t$
    copied = copied + LEN(t$)
    used = need
END SUB

' SbInit: start empty with a small 16-character buffer.
SUB SbInit
    buf$ = SPACE$(16)
    used = 0: grows = 0: copied = 0
END SUB

' SbText$: the finished string is just the used part of the buffer.
FUNCTION SbText$
    SbText$ = LEFT$(buf$, used)
END FUNCTION
