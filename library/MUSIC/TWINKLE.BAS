' ============================================================
' TITLE:    Twinkle Twinkle Starry Night
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, nursery rhyme, screen 13, draw, stars, lyrics
' SUMMARY:  Plays Twinkle Twinkle Little Star while a big star pulses and new stars appear with every note.
' ------------------------------------------------------------
' WHAT IT DOES
'   Plays the nursery tune (the French melody "Ah! vous dirai-je,
'   maman", 1761, public domain) one phrase at a time. Each note
'   lights up a new little star in the night sky, the big star in
'   the middle flashes, and the words of the phrase are shown.
'
' HOW TO USE
'   Sit back and watch. Esc stops early.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting a song into phrases (one string each)
'   * Walking through a PLAY string one note at a time
'   * DRAW to draw a star shape with turtle commands
'   * PSET random pixels for a starfield in SCREEN 13
'
' THINGS TO TRY
'   * Make the big star change colour on high notes.
'   * Add the second verse "When the blazing sun is gone...".
' ============================================================

DECLARE SUB BigStar (c%)

' Six phrases and their words. Each note in a phrase is one
' letter followed by an optional length digit.
DATA "CCGGAAG2", "Twinkle, twinkle, little star,"
DATA "FFEEDDC2", "How I wonder what you are!"
DATA "GGFFEED2", "Up above the world so high,"
DATA "GGFFEED2", "Like a diamond in the sky."
DATA "CCGGAAG2", "Twinkle, twinkle, little star,"
DATA "FFEEDDC2", "How I wonder what you are!"

SCREEN 13
RANDOMIZE TIMER
' A dark-blue sky: palette colour 1 is already blue, so we
' simply paint the whole screen with a filled box.
LINE (0, 0)-(319, 199), 1, BF
' A few dim background stars.
FOR i = 1 TO 60: PSET (RND * 319, RND * 150), 7: NEXT
' A little hill at the bottom, drawn as a big circle filled green.
CIRCLE (160, 330), 220, 2
PAINT (160, 199), 2, 2

PLAY "T120 O4 L4 MN"
FOR phrase = 1 TO 6
  READ tune$, words$
  ' Show the words (row 22 is near the bottom in SCREEN 13).
  LOCATE 22, 1: PRINT SPACE$(40);
  LOCATE 22, 21 - LEN(words$) \ 2: COLOR 15: PRINT words$;

  ' Walk through the phrase. A note letter may be followed by a
  ' digit (the length); we gather both and play them together.
  p = 1
  DO WHILE p <= LEN(tune$)
    nt$ = MID$(tune$, p, 1): p = p + 1
    IF p <= LEN(tune$) AND INSTR("0123456789", MID$(tune$, p, 1)) > 0 THEN
      nt$ = nt$ + MID$(tune$, p, 1): p = p + 1
    END IF
    ' A new twinkling star: bright yellow or white, in a random spot.
    PSET (RND * 319, RND * 140), 14 + INT(RND * 2)
    BigStar 14                ' flash the big star bright yellow
    PLAY nt$
    BigStar 6                 ' and dim it again (brown/orange)
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  LOOP
  PLAY "P8"                   ' tiny breath between phrases
NEXT

LOCATE 22, 1: PRINT SPACE$(40);
LOCATE 22, 14: PRINT "Good night!";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
END

' BigStar draws a five-pointed star with DRAW in colour c%.
' "BM" moves without drawing; "TA" turns the pen to an angle.
' Each point: draw forward 30 pixels, then turn 144 degrees -
' five turns of 144 = 720 degrees, which closes the star.
' TA only accepts -360..360, so we keep angles in range with MOD.
SUB BigStar (c%)
  DRAW "C" + LTRIM$(STR$(c%)) + " BM144,70 TA0"
  FOR k = 0 TO 4
    DRAW "TA" + LTRIM$(STR$((k * 144) MOD 360)) + " R32"
  NEXT
  DRAW "TA0"
END SUB
