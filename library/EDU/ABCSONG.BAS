' ============================================================
' TITLE:    Alphabet Song
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     alphabet, music, PLAY, phonics, WIDTH 40
' SUMMARY:  Sing along to the ABC song as each letter lights up, then press letters to hear "A is for Apple".
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows all 26 letters in big, colourful 40-column text.  In Sing
'   mode the computer plays the alphabet song tune (the same tune as
'   "Twinkle Twinkle Little Star") and each letter lights up as its
'   note plays - perfect for singing along.  In Explore mode, press
'   any letter key to hear a note and see a word that starts with it.
'
' HOW TO USE
'   S = sing the song, E = explore letters, Q = quit.
'   Esc stops the song or leaves Explore mode.
'
' CONCEPTS YOU WILL LEARN
'   * The PLAY music language: notes A-G, L for length, O for octave,
'     T for tempo, and lengths written after the note (C2, D8)
'   * Storing a tune note-by-note in DATA alongside the letters
'   * WIDTH 40 for big, easy-to-read text
'   * Lining up pictures and sound: highlight, play, un-highlight
'
' THINGS TO TRY
'   * Change T150 to a faster or slower tempo
'   * Add your own words for each letter in the word list
'   * Play the song in a different octave (O3 or O5)
' ============================================================

DECLARE SUB ShowLetter (i!, hi!)
DIM SHARED tune$(1 TO 26), word$(1 TO 26)
' Each letter's piece of the tune, in PLAY language.
FOR i = 1 TO 26: READ tune$(i): NEXT i
' A    B    C    D    E    F    G       (twin-kle twin-kle lit-tle star)
DATA C4, C4, G4, G4, A4, A4, G2
' H    I    J    K    L    M    N    O    P   (L-M-N-O are quick!)
DATA F4, F4, E4, E4, D8, D8, D8, D8, C2
' Q    R    S    T    U    V
DATA G4, G4, F2, E4, E4, D2
' W (dou-ble-u)  X    Y (and)   Z
DATA G8G8G4, F2, E4E4, D2
FOR i = 1 TO 26: READ word$(i): NEXT i
DATA Apple, Ball, Cat, Dog, Egg, Fish, Goat, Hat, Igloo, Jam
DATA Kite, Lion, Moon, Nest, Octopus, Pig, Queen, Rainbow, Sun
DATA Tree, Umbrella, Van, Whale, X-ray, Yo-yo, Zebra

WIDTH 40
DO
    CLS
    COLOR 14: LOCATE 2, 12: PRINT "THE ALPHABET SONG"
    FOR i = 1 TO 26: ShowLetter i, 0: NEXT i
    COLOR 15
    LOCATE 20, 4: PRINT "S = sing   E = explore   Q = quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "S" THEN GOSUB Sing
    IF k$ = "E" THEN GOSUB Explore
LOOP
WIDTH 80
CLS
END

' ------------------------------------------------------------
Sing:
    LOCATE 20, 1: PRINT SPACE$(40);
    ' T = tempo (quarter notes per minute), O4 = middle octave,
    ' MN = "music normal" (notes slightly separated, like singing)
    PLAY "T150 O4 MN"
    FOR i = 1 TO 26
        ShowLetter i, 1                  ' light it up
        LOCATE 18, 1: PRINT SPACE$(40);
        COLOR 11: LOCATE 18, 14: PRINT CHR$(64 + i); " is for "; word$(i);
        PLAY tune$(i)                    ' plays while the letter glows
        ShowLetter i, 0                  ' back to normal
        IF INKEY$ = CHR$(27) THEN RETURN
    NEXT i
    LOCATE 18, 1: PRINT SPACE$(40);
    ' The ending: "Now I know my ABCs, next time won't you sing with me"
    COLOR 13: LOCATE 18, 7: PRINT "Now I know my A B C's...";
    PLAY "C4 C4 G4 G4 A4 A4 G2"
    LOCATE 18, 1: PRINT SPACE$(40);
    LOCATE 18, 2: PRINT "Next time won't you sing with me!";
    PLAY "F4 F4 E4 E4 D4 D4 C2"
    LOCATE 20, 9: COLOR 10: PRINT "Well sung! Press a key.";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
Explore:
    LOCATE 20, 1: PRINT SPACE$(40);
    LOCATE 20, 3: COLOR 15: PRINT "Press any letter!  (Esc = back)";
    DO
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        IF k$ = CHR$(27) THEN RETURN
        IF k$ >= "A" AND k$ <= "Z" AND LEN(k$) = 1 THEN
            i = ASC(k$) - 64
            ShowLetter i, 1
            LOCATE 18, 1: PRINT SPACE$(40);
            COLOR 11: LOCATE 18, 12: PRINT k$; " is for "; word$(i);
            ' Each letter gets its own note: climb up a scale so that
            ' A is low and Z is high.  N n plays note number n (0-84).
            PLAY "T120 O4 L4 N" + LTRIM$(STR$(24 + i))
            ShowLetter i, 0
        END IF
    LOOP

' ------------------------------------------------------------
' ShowLetter: letters sit in a grid 7 across, each in a coloured
' block.  hi = 1 draws it bright on white so it "lights up".
' ------------------------------------------------------------
SUB ShowLetter (i, hi)
    r = 5 + ((i - 1) \ 7) * 3              ' 3 rows apart
    c = 4 + ((i - 1) MOD 7) * 5            ' 5 columns apart
    IF hi THEN
        COLOR 0, 7                         ' black on white = glowing
    ELSE
        COLOR 15, 1 + (i MOD 6)            ' colourful backgrounds
    END IF
    LOCATE r, c: PRINT "   ";
    LOCATE r + 1, c: PRINT " "; CHR$(64 + i); " ";
    COLOR 7, 0
END SUB
