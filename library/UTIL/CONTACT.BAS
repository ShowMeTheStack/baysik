' ============================================================
' TITLE:    Contact Card Printer
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     lprint, printer, strings, boxes, formatting
' SUMMARY:  Type in a name and details, preview a boxed business card on screen, then send it to the printer with LPRINT.
' ------------------------------------------------------------
' WHAT IT DOES
'   Asks for a person's name, job title, phone, e-mail and
'   address, then draws a neat "business card" inside a box made
'   of + - | characters.  You can print one card or a whole
'   sheet of copies with LPRINT, which sends text to the printer
'   (LPT1) instead of the screen.  In Compendium the output
'   appears in the Printer panel.
'
'   We use plain ASCII + - | for the printed box because old
'   printers often couldn't print the fancy line-drawing
'   characters you see on screen.
'
' HOW TO USE
'   Fill in the questions (press Enter to skip any line).  Then:
'   P = print one card, S = print a sheet of 4, E = edit again,
'   Q or Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * LPRINT and LPRINT USING - printing to paper
'   * Building every line of the card in an array first, then
'     sending the same lines to the screen OR the printer
'   * Centring text: SPACE$((width - LEN(t$)) \ 2)
'   * CHR$(12) "form feed" to start a new page
'
' THINGS TO TRY
'   * Print two cards side by side across the page.
'   * Add a little ASCII-art logo on the left.
'   * Read many contacts from a file and print them all.
' ============================================================

DECLARE SUB BuildCard ()

CONST W = 40                ' width of the card inside the box
DIM SHARED fld$(1 TO 6), card$(1 TO 10), nCard
DIM label$(1 TO 6)
FOR i = 1 TO 6: READ label$(i): NEXT i
DATA "Full name","Job title","Phone","E-mail","Street","Town / postcode"

' Example details so you can try printing straight away.
FOR i = 1 TO 6: READ fld$(i): NEXT i
DATA "Ada Lovelace","Analyst & Programmer","+44 20 7946 0000"
DATA "ada@engine.example","12 St James's Square","London SW1Y 4JH"

GOSUB EditCard
DO
    BuildCard
    CLS
    COLOR 11: PRINT "CONTACT CARD PRINTER": COLOR 7
    PRINT
    ' ---- Preview on screen ----
    FOR i = 1 TO nCard
        PRINT TAB(15); card$(i)
    NEXT i
    PRINT
    PRINT "  P = print card   S = print sheet of 4   E = edit   Q = quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "P"
            ' The SAME lines, but LPRINT sends them to the printer.
            FOR i = 1 TO nCard: LPRINT card$(i): NEXT i
            LPRINT
            msg$ = "Card sent to the printer."
            GOSUB Note
        CASE "S"
            ' Four copies with a dotted cutting line between them.
            FOR copy = 1 TO 4
                FOR i = 1 TO nCard: LPRINT card$(i): NEXT i
                IF copy < 4 THEN LPRINT STRING$(W + 4, "."); "  cut here"
            NEXT copy
            ' A footer using LPRINT USING, then a form feed (new page).
            LPRINT
            LPRINT USING "Printed on & at &"; DATE$; TIME$
            LPRINT CHR$(12);
            msg$ = "Sheet of 4 cards sent to the printer."
            GOSUB Note
        CASE "E": GOSUB EditCard
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

' ---- Ask for each field; Enter keeps the current value ----
EditCard:
    CLS
    PRINT "Enter the details (just press Enter to keep what's in [ ])"
    PRINT
    FOR i = 1 TO 6
        PRINT label$(i); " ["; fld$(i); "]";
        LINE INPUT ": "; t$
        IF t$ <> "" THEN fld$(i) = LEFT$(LTRIM$(RTRIM$(t$)), W - 2)
    NEXT i
    RETURN

Note:
    LOCATE 23, 3: COLOR 10: PRINT msg$; " (see the Printer panel)  - press a key": COLOR 7
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' Build the card lines into card$() so they can go anywhere.
SUB BuildCard
    edge$ = "+" + STRING$(W + 2, "-") + "+"
    nCard = 0
    nCard = nCard + 1: card$(nCard) = edge$
    FOR i = 1 TO 6
        t$ = fld$(i)
        SELECT CASE i
            CASE 1
                ' Name centred, in capitals, with a blank line after.
                t$ = UCASE$(t$)
                t$ = SPACE$((W - LEN(t$)) \ 2) + t$
            CASE 2
                t$ = SPACE$((W - LEN(t$)) \ 2) + t$
            CASE 3: IF t$ <> "" THEN t$ = "Tel:   " + t$
            CASE 4: IF t$ <> "" THEN t$ = "Email: " + t$
        END SELECT
        ' Skip empty lines (except keep the shape for name/title)
        IF t$ <> "" OR i <= 2 THEN
            ' Pad to exactly W characters so the right edge lines up.
            nCard = nCard + 1
            card$(nCard) = "| " + LEFT$(t$ + SPACE$(W), W) + " |"
        END IF
        IF i = 2 THEN
            nCard = nCard + 1: card$(nCard) = "| " + SPACE$(W) + " |"
        END IF
    NEXT i
    nCard = nCard + 1: card$(nCard) = edge$
END SUB
