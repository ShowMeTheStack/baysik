' ============================================================
' TITLE:    Chord Arpeggiator
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, chords, arpeggio, music theory, intervals, select case
' SUMMARY:  Pick a root note, chord type and pattern, and hear the chord broken into a rippling arpeggio.
' ------------------------------------------------------------
' WHAT IT DOES
'   A chord is several notes played together. The PC speaker can
'   only play one at a time, so we play the chord's notes one
'   after another, quickly and repeatedly - an ARPEGGIO (Italian
'   for "like a harp"). Classic computer and game music used this
'   trick constantly. You choose the root, the chord type and the
'   pattern, and the arpeggio keeps running while you change them.
'
' HOW TO USE
'   C D E F G A B   choose the root note      #  toggle sharp
'   1-7             chord type (see screen)   P  next pattern
'   + / -           faster / slower
'   Space           play the "I V vi IV" pop progression
'   Esc             quit
'
' CONCEPTS YOU WILL LEARN
'   * Chords as lists of intervals (semitones above the root)
'   * Major 3rd = 4 semitones, minor 3rd = 3, perfect 5th = 7
'   * Arpeggio patterns: up, down, up-down, random, broken
'   * A responsive loop: play one note, then check the keyboard
'
' THINGS TO TRY
'   * Add a "9th" chord: 0, 4, 7, 10, 14.
'   * Make a pattern that plays root, then the rest twice.
' ============================================================

DECLARE SUB BuildArp ()
DECLARE SUB ShowInfo ()

' Chord types: name, number of notes, intervals in semitones.
DATA "Major", 3, 0, 4, 7
DATA "Minor", 3, 0, 3, 7
DATA "Dominant 7th", 4, 0, 4, 7, 10
DATA "Major 7th", 4, 0, 4, 7, 11
DATA "Minor 7th", 4, 0, 3, 7, 10
DATA "Diminished", 3, 0, 3, 6
DATA "Suspended 4th", 3, 0, 5, 7

DIM SHARED chName$(7), chLen(7), chInt(7, 4)
DIM SHARED arp(32), arpLen, root, sharp, chType, pattern, tempo
DIM SHARED patName$(4)
FOR c = 1 TO 7
  READ chName$(c), chLen(c)
  FOR i = 1 TO chLen(c): READ chInt(c, i): NEXT
NEXT
patName$(0) = "Up": patName$(1) = "Down": patName$(2) = "Up-down"
patName$(3) = "Random": patName$(4) = "Broken (1-3-2-4)"

root = 0: sharp = 0: chType = 1: pattern = 0: tempo = 150
RANDOMIZE TIMER
CLS
COLOR 14: PRINT " CHORD ARPEGGIATOR": COLOR 7
PRINT
PRINT " Root: C D E F G A B  (# = sharp)    Pattern: P    Speed: + -"
PRINT " Chord: ";
FOR c = 1 TO 7: PRINT LTRIM$(STR$(c)); "="; chName$(c); "  ";: IF c = 4 THEN PRINT: PRINT "        ";
NEXT
PRINT
PRINT " Space = I-V-vi-IV progression     Esc = quit"
BuildArp
ShowInfo

i = 1
DO
  ' Play ONE note of the arpeggio, then look at the keyboard.
  ' Doing just one note per loop keeps the program responsive.
  PLAY "MN T" + LTRIM$(STR$(tempo)) + " L16 N" + LTRIM$(STR$(arp(i)))
  i = i + 1
  IF i > arpLen THEN i = 1: IF pattern = 3 THEN BuildArp   ' reshuffle random

  k$ = UCASE$(INKEY$)
  IF k$ <> "" THEN
    changed = -1
    SELECT CASE k$
      CASE "C", "D", "E", "F", "G", "A", "B"
        ' INSTR position -> semitone: C=0 D=2 E=4 F=5 G=7 A=9 B=11
        root = INSTR("C D EF G A B", k$) - 1
      CASE "#": sharp = 1 - sharp
      CASE "1" TO "7": chType = VAL(k$)
      CASE "P": pattern = (pattern + 1) MOD 5
      CASE "+", "=": IF tempo < 250 THEN tempo = tempo + 10
      CASE "-": IF tempo > 50 THEN tempo = tempo - 10
      CASE " "
        ' I - V - vi - IV: the "four chord song" progression.
        ' Built on the current root: +0 major, +7 major,
        ' +9 minor, +5 major. Two runs of the arpeggio each.
        saveR = root: saveT = chType: saveS = sharp
        FOR stp = 0 TO 3
          SELECT CASE stp
            CASE 0: root = saveR: chType = 1
            CASE 1: root = saveR + 7: chType = 1
            CASE 2: root = saveR + 9: chType = 2
            CASE 3: root = saveR + 5: chType = 1
          END SELECT
          BuildArp: ShowInfo
          FOR rep = 1 TO 2
            FOR j = 1 TO arpLen
              PLAY "L16 N" + LTRIM$(STR$(arp(j)))
            NEXT
          NEXT
        NEXT
        root = saveR: chType = saveT: sharp = saveS
      CASE CHR$(27): EXIT DO
      CASE ELSE: changed = 0
    END SELECT
    IF changed THEN BuildArp: ShowInfo: i = 1
  END IF
LOOP
CLS
PRINT "Arpeggiator off."
END

' BuildArp fills arp() with PLAY note numbers for the current
' root, chord and pattern. The chord is spread over two octaves.
SUB BuildArp
  DIM notes(10)
  bn = 37 + root + sharp            ' N37 = C in octave 3
  n = 0
  FOR octv = 0 TO 1
    FOR k = 1 TO chLen(chType)
      n = n + 1
      notes(n) = bn + octv * 12 + chInt(chType, k)
    NEXT
  NEXT
  n = n + 1: notes(n) = bn + 24     ' finish on the root, 2 octaves up
  arpLen = 0
  SELECT CASE pattern
    CASE 0                            ' up
      FOR k = 1 TO n: arpLen = arpLen + 1: arp(arpLen) = notes(k): NEXT
    CASE 1                            ' down
      FOR k = n TO 1 STEP -1: arpLen = arpLen + 1: arp(arpLen) = notes(k): NEXT
    CASE 2                            ' up then down (no repeated top/bottom)
      FOR k = 1 TO n: arpLen = arpLen + 1: arp(arpLen) = notes(k): NEXT
      FOR k = n - 1 TO 2 STEP -1: arpLen = arpLen + 1: arp(arpLen) = notes(k): NEXT
    CASE 3                            ' random order (shuffle)
      FOR k = 1 TO n: arp(k) = notes(k): NEXT
      arpLen = n
      FOR k = n TO 2 STEP -1
        j = INT(RND * k) + 1
        SWAP arp(k), arp(j)
      NEXT
    CASE 4                            ' broken: 1 3 2 4 3 5 ...
      FOR k = 1 TO n - 2
        arpLen = arpLen + 1: arp(arpLen) = notes(k)
        arpLen = arpLen + 1: arp(arpLen) = notes(k + 2)
      NEXT
  END SELECT
END SUB

SUB ShowInfo
  nm$ = MID$("C C#D D#E F F#G G#A A#B ", ((root + sharp) MOD 12) * 2 + 1, 2)
  LOCATE 10, 2: COLOR 15
  PRINT "Chord: "; RTRIM$(nm$); " "; chName$(chType); SPACE$(20)
  COLOR 7
  LOCATE 11, 2: PRINT "Pattern: "; LEFT$(patName$(pattern) + SPACE$(18), 18); "Tempo:"; tempo; "  "
  LOCATE 12, 2: PRINT "Notes: ";
  FOR k = 1 TO chLen(chType)
    s = (root + sharp + chInt(chType, k)) MOD 12
    PRINT RTRIM$(MID$("C C#D D#E F F#G G#A A#B ", s * 2 + 1, 2)); " ";
  NEXT
  PRINT "   (intervals:";
  FOR k = 1 TO chLen(chType): PRINT chInt(chType, k);: NEXT
  PRINT ")"; SPACE$(10)
END SUB
