' ============================================================
' TITLE:    Music on the Staff
' CATEGORY: Music & Sound
' LEVEL:    Advanced
' TAGS:     play, notation, staff, parser, graphics, screen 12, circle
' SUMMARY:  Turns a PLAY string into real sheet music on a treble staff - note heads, stems, flags, sharps - and follows along as it plays.
' ------------------------------------------------------------
' WHAT IT DOES
'   Reads a melody written in the Music Macro Language, works out
'   where each note belongs on a five-line treble staff, and draws
'   it in standard notation: hollow or filled heads, stems, flags
'   for eighth notes, dots, sharps/flats, ledger lines and rests.
'   Then it plays the tune, colouring each note red as it sounds.
'
' HOW TO USE
'   Choose 1 (Jingle Bells), 2 (Amazing Grace) or 3 to type your
'   own MML. Supported: A-G with # + -, lengths 1 2 4 8 16, dots,
'   O n, < >, P rests, T tempo. Esc stops playback; Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Writing a small parser: reading a string character by char
'   * Staff position = octave * 7 + letter (diatonic steps)
'   * CIRCLE with an aspect ratio for oval note heads, PAINT to fill
'   * Keeping parsed data in parallel arrays
'
' THINGS TO TRY
'   * Add bar lines by adding up note lengths (4 beats per bar).
'   * Add a bass clef staff for notes below middle C.
' ============================================================

DECLARE SUB Parse (m$)
DECLARE SUB DrawStaff (cy%)
DECLARE SUB DrawNote (i%, c%)

CONST MAXN = 200, LS = 12        ' max notes, pixels between staff lines
DIM SHARED nStep(MAXN), nAcc(MAXN), nLen(MAXN), nDot(MAXN), nRest(MAXN)
DIM SHARED nX(MAXN), nY0(MAXN), nPlay$(MAXN), count, tempo
DIM SHARED errMsg$

DO
  SCREEN 0: WIDTH 80: CLS
  COLOR 14: PRINT " MUSIC ON THE STAFF": COLOR 7
  PRINT
  PRINT " 1) Jingle Bells (J. Pierpont, 1857)"
  PRINT " 2) Amazing Grace (traditional American melody)"
  PRINT " 3) Type your own MML"
  PRINT " Q) Quit"
  PRINT
  PRINT " Choose: ";
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
  SELECT CASE k$
    CASE "1": m$ = "T180 O4 L4 EEE2 EEE2 EGC.D8 E1 FFF.F8 FEEE8E8 EDDE D2G2"
    CASE "2": m$ = "T100 O4 L4 <G> C2E8C8 E2D4 C2<A4 G2G4> C2E8C8 E2D8E8 G2."
    CASE "3"
      PRINT
      PRINT " Example: O4 L8 CDEF G4G4 AAAA G2"
      LINE INPUT " MML: "; m$
    CASE "Q", CHR$(27): EXIT DO
    CASE ELSE: m$ = ""
  END SELECT
  IF m$ <> "" THEN
    Parse UCASE$(m$)
    IF errMsg$ <> "" THEN
      PRINT: PRINT " Sorry: "; errMsg$; "  Press a key."
      k$ = INPUT$(1)
    ELSEIF count > 0 THEN
      SCREEN 12: CLS
      COLOR 14: LOCATE 1, 2: PRINT LEFT$(m$, 78)
      ' ---- Lay the notes out on staves ("systems") -----------
      ' x advances by an amount based on the note length, so
      ' long notes get more room - just like printed music.
      first = 1
      DO
        CLS
        COLOR 14: LOCATE 1, 2: PRINT LEFT$(m$, 78)
        sys = 0: x = 90
        DrawStaff 130
        last = first
        FOR i = first TO count
          w = 26 + 60 / nLen(i) * 2
          IF nDot(i) THEN w = w + 8
          IF x + w > 620 THEN
            IF sys = 1 THEN EXIT FOR     ' screen full: play this page
            sys = 1: x = 90: DrawStaff 330
          END IF
          nX(i) = x: nY0(i) = 130 + sys * 200
          DrawNote (i), 15
          x = x + w
          last = i
        NEXT
        ' ---- Play the page, lighting each note ----------------
        LOCATE 30, 2: COLOR 7: PRINT "Esc = stop";
        stopped = 0
        PLAY "MN T" + LTRIM$(STR$(tempo))
        FOR i = first TO last
          DrawNote (i), 12
          PLAY nPlay$(i)
          DrawNote (i), 15
          IF INKEY$ = CHR$(27) THEN stopped = 1: EXIT FOR
        NEXT
        first = last + 1
      LOOP UNTIL first > count OR stopped
      LOCATE 30, 2: COLOR 7: PRINT "Press a key for the menu.";
      k$ = INPUT$(1)
    END IF
  END IF
LOOP
SCREEN 0: WIDTH 80
CLS
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' DrawNote: draws note i in colour c%. The staff's middle line
' is at nY0(i); B4 sits on that line (step 4*7 + 6 = 34).
' Each diatonic step is half a line-space (LS / 2 pixels).
' ------------------------------------------------------------
SUB DrawNote (i%, c%)
  x = nX(i%)
  IF nRest(i%) THEN
    ' Rests: a block for whole/half, a zig-zag for shorter ones.
    y = nY0(i%)
    IF nLen(i%) <= 2 THEN
      LINE (x - 6, y - 6)-(x + 6, y - 2), c%, BF
    ELSE
      LINE (x - 3, y - 12)-(x + 3, y - 4), c%
      LINE (x + 3, y - 4)-(x - 3, y + 4), c%
      LINE (x - 3, y + 4)-(x + 3, y + 12), c%
    END IF
    EXIT SUB
  END IF
  y = nY0(i%) - (nStep(i%) - 34) * (LS / 2)
  ' Ledger lines for notes above or below the staff.
  FOR s = 28 TO nStep(i%) STEP -2
    ly = nY0(i%) - (s - 34) * (LS / 2)
    LINE (x - 10, ly)-(x + 10, ly), 7
  NEXT
  FOR s = 40 TO nStep(i%) STEP 2
    ly = nY0(i%) - (s - 34) * (LS / 2)
    LINE (x - 10, ly)-(x + 10, ly), 7
  NEXT
  ' The head: an oval (aspect .7 squashes the circle).
  CIRCLE (x, y), 6, c%, , , .7
  ' Quarter notes and shorter are filled in.
  IF nLen(i%) >= 4 THEN PAINT (x, y), c%, c%
  ' Stem: up on the right for low notes, down on the left for
  ' notes on or above the middle line. Whole notes have none.
  IF nLen(i%) >= 2 THEN
    IF nStep(i%) < 34 THEN
      LINE (x + 6, y)-(x + 6, y - 34), c%: sx = x + 6: sy = y - 34: fd = 1
    ELSE
      LINE (x - 6, y)-(x - 6, y + 34), c%: sx = x - 6: sy = y + 34: fd = -1
    END IF
    ' Flags: one for eighths, two for sixteenths.
    IF nLen(i%) >= 8 THEN LINE (sx, sy)-(sx + 9, sy + 12 * fd), c%
    IF nLen(i%) >= 16 THEN LINE (sx, sy + 6 * fd)-(sx + 9, sy + 18 * fd), c%
  END IF
  ' Dot to the right of the head.
  IF nDot(i%) THEN CIRCLE (x + 11, y - 2), 1, c%
  ' Accidentals drawn to the left: # as two slanted + two flat lines.
  IF nAcc(i%) = 1 THEN
    LINE (x - 16, y - 7)-(x - 16, y + 7), c%: LINE (x - 12, y - 8)-(x - 12, y + 6), c%
    LINE (x - 19, y - 2)-(x - 9, y - 4), c%: LINE (x - 19, y + 3)-(x - 9, y + 1), c%
  ELSEIF nAcc(i%) = -1 THEN
    ' A flat: a tall line with a little bowl at the bottom.
    LINE (x - 16, y - 12)-(x - 16, y + 3), c%
    CIRCLE (x - 13, y), 3, c%, 4.71, 1.57
  END IF
END SUB

' DrawStaff: five lines centred on y = cy%, plus a simple clef.
SUB DrawStaff (cy%)
  FOR l = -2 TO 2
    LINE (20, cy% + l * LS)-(625, cy% + l * LS), 7
  NEXT
  ' A stylised treble clef: a curl around the G line and a spine.
  COLOR 7
  CIRCLE (42, cy% + LS), 9, 15
  LINE (46, cy% - 3 * LS)-(40, cy% + 3 * LS), 15
  CIRCLE (44, cy% - 2 * LS), 6, 15, 0, 3.14
  LOCATE (cy% + 3 * LS) \ 16 + 2, 3: PRINT "treble";
END SUB

' ------------------------------------------------------------
' Parse: reads the MML string m$ into the note arrays.
' Keeps track of the current octave and default length just like
' PLAY does, and builds a small PLAY string for each note.
' ------------------------------------------------------------
SUB Parse (m$)
  errMsg$ = "": count = 0: tempo = 120
  oc = 4: dl = 4
  p = 1
  DO WHILE p <= LEN(m$)
    c$ = MID$(m$, p, 1): p = p + 1
    ' ReadNum: gather digits that follow a command letter.
    num$ = ""
    DO WHILE p <= LEN(m$) AND INSTR("0123456789", MID$(m$, p, 1)) > 0 AND INSTR("OLTP", c$) > 0
      num$ = num$ + MID$(m$, p, 1): p = p + 1
    LOOP
    SELECT CASE c$
      CASE " "
      CASE "O": oc = VAL(num$): IF oc > 6 THEN oc = 6
      CASE "L": dl = VAL(num$): IF dl < 1 THEN dl = 4
      CASE "T": tempo = VAL(num$): IF tempo < 32 OR tempo > 255 THEN tempo = 120
      CASE "<": IF oc > 0 THEN oc = oc - 1
      CASE ">": IF oc < 6 THEN oc = oc + 1
      CASE "A" TO "G", "P"
        IF count = MAXN THEN errMsg$ = "too many notes": EXIT SUB
        count = count + 1
        nAcc(count) = 0: nDot(count) = 0: nRest(count) = 0
        IF c$ = "P" THEN
          nRest(count) = 1
          ln = VAL(num$)
        ELSE
          ' Sharps and flats right after the letter.
          IF MID$(m$, p, 1) = "#" OR MID$(m$, p, 1) = "+" THEN nAcc(count) = 1: p = p + 1
          IF MID$(m$, p, 1) = "-" THEN nAcc(count) = -1: p = p + 1
          ' Then an optional length.
          num$ = ""
          DO WHILE p <= LEN(m$) AND INSTR("0123456789", MID$(m$, p, 1)) > 0
            num$ = num$ + MID$(m$, p, 1): p = p + 1
          LOOP
          ln = VAL(num$)
          ' Staff step: C=0 D=1 ... B=6, plus 7 per octave.
          nStep(count) = oc * 7 + INSTR("CDEFGAB", c$) - 1
        END IF
        IF ln = 0 THEN ln = dl
        IF ln <> 1 AND ln <> 2 AND ln <> 4 AND ln <> 8 AND ln <> 16 THEN
          errMsg$ = "only lengths 1, 2, 4, 8 and 16 can be drawn": EXIT SUB
        END IF
        nLen(count) = ln
        IF MID$(m$, p, 1) = "." THEN nDot(count) = 1: p = p + 1
        ' The PLAY string for just this note, e.g. "O4C#8.".
        IF nRest(count) THEN
          nPlay$(count) = "P" + LTRIM$(STR$(ln))
        ELSE
          nPlay$(count) = "O" + LTRIM$(STR$(oc)) + c$
          IF nAcc(count) = 1 THEN nPlay$(count) = nPlay$(count) + "#"
          IF nAcc(count) = -1 THEN nPlay$(count) = nPlay$(count) + "-"
          nPlay$(count) = nPlay$(count) + LTRIM$(STR$(ln))
        END IF
        IF nDot(count) THEN nPlay$(count) = nPlay$(count) + "."
      CASE ELSE
        errMsg$ = "I don't understand '" + c$ + "'": EXIT SUB
    END SELECT
  LOOP
END SUB
