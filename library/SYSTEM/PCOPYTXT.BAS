' ============================================================
' TITLE:    Eight Text Pages: Flip-Book and PCOPY Pop-ups
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     pcopy, screen, active page, visual page, text mode, animation
' SUMMARY:  Draw on hidden text pages, flip between them like a flip-book, and use PCOPY to save and restore the screen under a pop-up.
' ------------------------------------------------------------
' WHAT IT DOES
'   A colour text screen of 80x25 needs 4000 bytes, but the video card
'   has room for EIGHT such pages (0..7) in its memory at &HB800 - one
'   every 4096 bytes.  BASIC lets you choose:
'     SCREEN 0, , apage, vpage
'       apage = the ACTIVE page that PRINT draws on
'       vpage = the VISUAL page that you actually see
'   Drawing on a hidden page and then showing it gives instant,
'   flicker-free screen changes.  PCOPY src, dst copies a whole page.
'
'   Part 1 draws 8 frames of a rocket launch on the 8 pages, then
'   flips between them as an animation.
'   Part 2 shows the classic pop-up trick: PCOPY the screen to a spare
'   page, draw a window over it, and PCOPY it back to "close" it.
'
' HOW TO USE
'   Part 1: watch, then press a key.  Part 2: ? opens/closes the help
'   pop-up, any other key is typed on the page, Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * SCREEN 0, , apage, vpage
'   * PCOPY source, destination
'   * Double buffering (draw hidden, then show)
'   * Where the pages live: &HB800 + page * 4096 bytes
'
' THINGS TO TRY
'   * Use DEF SEG = &HB800 and PEEK(page * 4096) to read a hidden page
'   * Make the flip-book run backwards, or ping-pong
'   * Keep pages 1-6 as "tabs" and switch between them with F-keys
' ============================================================

DEFINT A-Z
SCREEN 0: WIDTH 80, 25

' ---- PART 1: draw 8 frames, one per page, while showing page 0 -----
FOR p = 0 TO 7
    SCREEN 0, , p, 0                    ' draw on page p, keep showing page 0
    COLOR 7, 1: CLS
    LOCATE 1, 2: COLOR 15, 1: PRINT "Text page"; p; "  (frame"; p + 1; "of 8)"
    ' some stars
    COLOR 14, 1
    FOR s = 1 TO 15
        LOCATE 2 + (s * 7) MOD 18, 1 + (s * 23 + p) MOD 79: PRINT "*";
    NEXT s
    ' ground
    COLOR 2, 1: LOCATE 24, 1: PRINT STRING$(80, 219);
    ' the rocket rises 2 rows per frame
    y = 18 - p * 2
    COLOR 15, 1
    LOCATE y, 39: PRINT "/\";
    LOCATE y + 1, 38: PRINT "|  |";
    LOCATE y + 2, 38: PRINT "|NN|";
    LOCATE y + 3, 37: PRINT "/|__|\";
    ' flames get bigger as it climbs
    COLOR 12 + (p MOD 2) * 2, 1
    FOR f = 0 TO p \ 2
        IF y + 4 + f <= 23 THEN LOCATE y + 4 + f, 39: PRINT MID$("vvVV^^", 1 + (f MOD 3) * 2, 2);
    NEXT f
NEXT p

' Now flip through the pages: SCREEN 0, , active, VISUAL
FOR loops = 1 TO 4
    FOR p = 0 TO 7
        SCREEN 0, , p, p                ' show page p (instantly!)
        t! = TIMER: DO WHILE TIMER - t! < .15 AND TIMER >= t!: LOOP
        IF INKEY$ = CHR$(27) THEN EXIT FOR
    NEXT p
NEXT loops
SCREEN 0, , 7, 7
COLOR 15, 1: LOCATE 25, 1: PRINT "Lift-off!  Press a key for part 2.";
DO: k$ = INKEY$: LOOP WHILE k$ = ""

' ---- PART 2: PCOPY pop-up window -------------------------------------
SCREEN 0, , 0, 0                         ' back to page 0, both active and visible
COLOR 7, 0: CLS
PRINT "PART 2 - type anything.  ? = help pop-up, Esc = quit."
PRINT
popup = 0
DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = "?" THEN
        IF popup = 0 THEN
            r = CSRLIN: c = POS(0)       ' remember the cursor too
            PCOPY 0, 7                   ' save the whole screen to page 7
            GOSUB DrawPopup
            popup = 1
        ELSE
            PCOPY 7, 0                   ' restore: the pop-up vanishes
            LOCATE r, c
            popup = 0
        END IF
    ELSEIF popup = 0 AND LEN(k$) = 1 THEN
        IF k$ = CHR$(13) THEN PRINT ELSE IF k$ >= " " THEN PRINT k$;
    END IF
LOOP
SCREEN 0, , 0, 0
COLOR 7, 0: CLS
PRINT "Bye!"
END

DrawPopup:
    COLOR 0, 3
    FOR rr = 8 TO 16
        LOCATE rr, 20: PRINT SPACE$(40);
    NEXT rr
    LOCATE 8, 20: PRINT CHR$(201); STRING$(38, 205); CHR$(187);
    FOR rr = 9 TO 15: LOCATE rr, 20: PRINT CHR$(186); : LOCATE rr, 59: PRINT CHR$(186); : NEXT rr
    LOCATE 16, 20: PRINT CHR$(200); STRING$(38, 205); CHR$(188);
    LOCATE 10, 23: PRINT "HELP";
    LOCATE 12, 23: PRINT "The screen behind this box was";
    LOCATE 13, 23: PRINT "saved with PCOPY 0, 7.  Press ?";
    LOCATE 14, 23: PRINT "and PCOPY 7, 0 brings it back!";
    COLOR 7, 0
RETURN
