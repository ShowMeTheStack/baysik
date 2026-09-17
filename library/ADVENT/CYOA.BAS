' ============================================================
' TITLE:    The Lighthouse Keeper's Secret
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     story, branching, choose your own adventure, data
' SUMMARY:  A branching choose-your-own-adventure story with five different endings.
' ------------------------------------------------------------
' WHAT IT DOES
'   Tells a short story in "pages".  At the end of each page you
'   pick option 1 or 2, and the story jumps to a different page.
'   Some pages are endings - good, bad or strange.  The whole story
'   is stored in DATA lines, so the program itself is tiny.
'   At the end it tells you how many of the endings you have found.
'
' HOW TO USE
'   Read each page and press 1 or 2 (Esc quits).  After an ending, press Y to
'   play again or N to stop.
'
' CONCEPTS YOU WILL LEARN
'   * A story as a "graph": pages are nodes, choices are arrows
'   * Arrays filled from DATA with READ
'   * Using page number 0 to mean "this page is an ending"
'   * Keeping score across several play-throughs
'
' THINGS TO TRY
'   * Draw the story on paper as boxes and arrows first
'   * Add a page 13 and point one of the choices at it
'   * Give some pages THREE choices
' ============================================================

DEFINT A-Z
CONST PAGES = 12

' For each page:  the text, then choice 1 text and page, then choice 2 text and page.
' A page whose two targets are 0 is an ENDING.  Use "|" in the text to start a new line.
DIM txt$(1 TO PAGES), c1$(1 TO PAGES), p1(1 TO PAGES), c2$(1 TO PAGES), p2(1 TO PAGES)
DIM seen(1 TO PAGES)       ' 1 if you have reached this ending before

DATA "A storm drives your boat onto Gull Rock. The old lighthouse is dark,|but you see a lantern bobbing near the cliff path."
DATA "Climb up to the lighthouse",2,"Follow the bobbing lantern",3
DATA "The lighthouse door is open. Inside, a spiral stair rises and a|trapdoor leads down."
DATA "Climb the stairs",4,"Open the trapdoor",5
DATA "The lantern belongs to a girl in a yellow raincoat. 'You shouldn't|be here,' she says. 'The keeper never came back.'"
DATA "Ask about the keeper",6,"Walk with her along the beach",11
DATA "At the top, the great lamp is cold. A ship's horn sounds out at sea -|it is heading straight for the rocks!"
DATA "Try to light the lamp",7,"Signal with your torch",8
DATA "Below is a cave full of glittering jars. Each one holds a tiny|ship... and one holds a tiny lighthouse keeper, waving at you."
DATA "Open the jar",9,"Back away slowly",10
DATA "'He went down to the cave to catch the sea's last secret,' she|whispers. 'He said it was in a bottle.'"
DATA "Go to the cave",5,"Go up to the lamp",4
DATA "You find matches and oil. With a WHOOSH the lamp blazes into life.|The ship turns away just in time. ENDING: THE NEW KEEPER.","",0,"",0
DATA "Your torch is too weak. The ship strikes the rocks... but everyone|swims ashore and you all share soup till dawn. ENDING: A LONG NIGHT.","",0,"",0
DATA "The keeper pops out and grows to full size. 'Thank you! Twenty years|in a jar is enough for anyone.' ENDING: THE RESCUE.","",0,"",0
DATA "You back into a jar marked YOUR NAME. It is empty. For now.|You row home at sunrise and never speak of it. ENDING: THE WARNING.","",0,"",0
DATA "On the beach lies the keeper's old rowing boat, oars and all. Far out,|a ship's lights are drifting closer to the rocks."
DATA "Row out to warn the ship",12,"Run up to the lighthouse",4
DATA "You row hard through the waves, shouting until the captain hears you.|The ship swings clear of the rocks. ENDING: THE BRAVE ROWER.","",0,"",0

FOR p = 1 TO PAGES
  READ txt$(p), c1$(p), p1(p), c2$(p), p2(p)
NEXT

' How many real endings are there?  Count pages with no exits.
endings = 0
FOR p = 1 TO PAGES
  IF p1(p) = 0 THEN endings = endings + 1
NEXT

DO
  page = 1
  DO
    CLS
    COLOR 14: PRINT "THE LIGHTHOUSE KEEPER'S SECRET": COLOR 8: PRINT "page"; page: COLOR 7
    PRINT
    ' print the page text, turning each "|" into a new line
    t$ = txt$(page)
    FOR i = 1 TO LEN(t$)
      ch$ = MID$(t$, i, 1)
      IF ch$ = "|" THEN PRINT ELSE PRINT ch$;
    NEXT
    PRINT : PRINT

    IF p1(page) = 0 THEN EXIT DO      ' an ending: leave the inner loop

    COLOR 11
    PRINT "  1) "; c1$(page)
    PRINT "  2) "; c2$(page)
    COLOR 7
    ' wait for a 1 or a 2 (anything else is ignored)
    DO
      k$ = INKEY$
    LOOP UNTIL k$ = "1" OR k$ = "2" OR k$ = CHR$(27)
    IF k$ = CHR$(27) THEN PRINT "The End (for now).": END
    IF k$ = "1" THEN page = p1(page) ELSE page = p2(page)
  LOOP

  ' ----- we reached an ending -----
  IF seen(page) = 0 THEN
    seen(page) = 1
    COLOR 10: PRINT "You found a NEW ending!": COLOR 7
  END IF
  found = 0
  FOR p = 1 TO PAGES: found = found + seen(p): NEXT
  PRINT "Endings discovered:"; found; "of"; endings
  PRINT
  PRINT "Play again? (Y/N)"
  DO
    k$ = UCASE$(INKEY$)
  LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"
PRINT "Thanks for reading!"
