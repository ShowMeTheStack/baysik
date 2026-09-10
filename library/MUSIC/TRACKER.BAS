' ============================================================
' TITLE:    Text-Mode Music Tracker
' CATEGORY: Music & Sound
' LEVEL:    Advanced
' TAGS:     play, tracker, sequencer, editor, files, polyphony, arrays
' SUMMARY:  A two-channel pattern sequencer in the style of 1990s trackers: enter notes, play, save and load songs.
' ------------------------------------------------------------
' WHAT IT DOES
'   A "tracker" is a music program where time runs DOWN the
'   screen in rows, and each column is an instrument channel.
'   This one has 64 rows (each row is one sixteenth note) and
'   two channels, LEAD and BASS. When both channels sound at once
'   the speaker alternates rapidly between them to fake a chord.
'   Songs can be saved to and loaded from TRACKER.SNG.
'
' HOW TO USE
'   Arrows / PgUp / PgDn   move the cursor (Left/Right = channel)
'   Z S X D C V G B H N J M  enter a note (like a piano: C C# D ...)
'   1-6    choose the octave for new notes
'   .      rest (silence)        -   hold (the note keeps sounding)
'   Del or Backspace   clear     Space   play / stop
'   [ ]    tempo down / up       L  load the demo tune
'   W      write TRACKER.SNG     R  read TRACKER.SNG    Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Two-dimensional arrays as a song "pattern"
'   * Converting note numbers <-> names like C#4
'   * Extended keys: INKEY$ returns CHR$(0) + scan code for arrows
'   * Saving and loading data with WRITE # and INPUT #
'   * ON ERROR GOTO to survive a missing file
'
' THINGS TO TRY
'   * Add a third channel for drums using short SOUND clicks.
'   * Add copy/paste of a block of rows.
' ============================================================

DEFINT A-Z            ' all plain variables are integers (faster, and they
                      ' match the % parameters of the SUBs below)
DECLARE SUB DrawAll ()
DECLARE SUB DrawRow (r%)
DECLARE SUB Status (msg$)
DECLARE SUB LoadDemo ()
DECLARE SUB PlaySong ()
DECLARE FUNCTION NoteName$ (n%)
DECLARE FUNCTION NoteNum% (s$)

CONST ROWS = 64, VIEWH = 18, TOPY = 5
' Cell values:  0 = rest, -1 = hold previous note, 1..84 = PLAY N number
DIM SHARED pat%(1, ROWS - 1)
DIM SHARED curRow%, curCh%, topRow%, tempo%, entryOct%
tempo% = 120: entryOct% = 4

LoadDemo
DrawAll

DO
  k$ = INKEY$
  IF k$ <> "" THEN
    IF LEN(k$) = 2 THEN
      ' Extended key: the second character is the scan code.
      SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 72: curRow% = curRow% - 1          ' Up
        CASE 80: curRow% = curRow% + 1          ' Down
        CASE 73: curRow% = curRow% - 16         ' PgUp
        CASE 81: curRow% = curRow% + 16         ' PgDn
        CASE 75: curCh% = 0                     ' Left
        CASE 77: curCh% = 1                     ' Right
        CASE 83: pat%(curCh%, curRow%) = 0      ' Del
      END SELECT
    ELSE
      u$ = UCASE$(k$)
      semi = INSTR("ZSXDCVGBHNJM", u$) - 1
      IF semi >= 0 THEN
        ' A note key. N number = octave*12 + semitone + 1.
        pat%(curCh%, curRow%) = entryOct% * 12 + semi + 1
        ' Play it so you can hear what you typed.
        PLAY "MN T" + LTRIM$(STR$(tempo%)) + " L16 N" + LTRIM$(STR$(pat%(curCh%, curRow%)))
        curRow% = curRow% + 1                   ' advance like a typewriter
      ELSE
        SELECT CASE u$
          CASE "1" TO "6": entryOct% = VAL(u$)
          CASE ".": pat%(curCh%, curRow%) = 0: curRow% = curRow% + 1
          CASE "-": pat%(curCh%, curRow%) = -1: curRow% = curRow% + 1
          CASE CHR$(8): pat%(curCh%, curRow%) = 0: curRow% = curRow% - 1
          CASE "[": IF tempo% > 40 THEN tempo% = tempo% - 10
          CASE "]": IF tempo% < 250 THEN tempo% = tempo% + 10
          CASE " ": PlaySong
          CASE "L": LoadDemo: Status "Demo loaded."
          CASE "W"
            OPEN "TRACKER.SNG" FOR OUTPUT AS #1
            WRITE #1, tempo%
            FOR r = 0 TO ROWS - 1: WRITE #1, pat%(0, r), pat%(1, r): NEXT
            CLOSE #1
            Status "Saved to TRACKER.SNG"
          CASE "R"
            ON ERROR GOTO NoFile
            fileOk = -1
            OPEN "TRACKER.SNG" FOR INPUT AS #1
            ON ERROR GOTO 0
            IF fileOk THEN
              INPUT #1, tempo%
              FOR r = 0 TO ROWS - 1: INPUT #1, pat%(0, r), pat%(1, r): NEXT
              CLOSE #1
              Status "Loaded TRACKER.SNG"
            ELSE
              Status "No TRACKER.SNG yet - press W to save first."
            END IF
          CASE CHR$(27): EXIT DO
        END SELECT
      END IF
    END IF
    ' Keep the cursor inside the pattern (wrap around the ends).
    IF curRow% < 0 THEN curRow% = ROWS - 1
    IF curRow% >= ROWS THEN curRow% = 0
    DrawAll
  END IF
LOOP
COLOR 7, 0: CLS
PRINT "Tracker closed."
END

' Error handler for OPEN: note the failure and carry on.
NoFile:
  fileOk = 0
  RESUME NEXT

SUB DrawAll
  ' Scroll the view so the cursor row is always visible.
  IF curRow% < topRow% THEN topRow% = curRow%
  IF curRow% >= topRow% + VIEWH THEN topRow% = curRow% - VIEWH + 1
  COLOR 14, 1
  LOCATE 1, 1: PRINT LEFT$(" TEXT TRACKER" + SPACE$(80), 80);
  COLOR 7, 0
  LOCATE 2, 2: PRINT USING "Tempo ###   Entry octave #   Row ## / ##"; tempo%; entryOct%; curRow%; ROWS - 1
  LOCATE 3, 2: PRINT "Keys: ZSXDCVGBHNJM notes  1-6 oct  . rest  - hold  Space play  [ ] tempo"
  LOCATE TOPY - 1, 2: COLOR 15: PRINT "ROW   LEAD   BASS": COLOR 7
  FOR i = 0 TO VIEWH - 1
    DrawRow topRow% + i
  NEXT
  LOCATE 24, 2: PRINT "L demo   W save   R load   Esc quit";
END SUB

SUB DrawRow (r%)
  IF r% < topRow% OR r% >= topRow% + VIEWH THEN EXIT SUB
  y = TOPY + r% - topRow%
  ' Every 4th row (each beat) is shown brighter to help counting.
  IF r% MOD 4 = 0 THEN COLOR 11 ELSE COLOR 3
  LOCATE y, 2: PRINT USING "##"; r%;
  PRINT "   ";
  FOR ch = 0 TO 1
    IF r% = curRow% AND ch = curCh% THEN COLOR 0, 7 ELSE COLOR 15, 0
    PRINT " "; NoteName$(pat%(ch, r%)); " ";
    COLOR 7, 0: PRINT "  ";
  NEXT
END SUB

SUB LoadDemo
  ' The demo is Ode to Joy (Beethoven). Each DATA pair is a note
  ' name and its length in rows. The loader writes the note, then
  ' "hold" for all but the last row, then a rest so repeated
  ' notes are heard separately.
  FOR ch = 0 TO 1: FOR r = 0 TO ROWS - 1: pat%(ch, r) = 0: NEXT: NEXT
  RESTORE DemoSong
  FOR ch = 0 TO 1
    r = 0
    DO
      READ n$, ln
      IF n$ = "END" THEN EXIT DO
      pat%(ch, r) = NoteNum%(n$)
      FOR k = 1 TO ln - 2: pat%(ch, r + k) = -1: NEXT
      r = r + ln
    LOOP
  NEXT
  tempo% = 120
END SUB

SUB PlaySong
  ' Plays from the cursor row to the end, then loops back to the
  ' top, until Space or Esc is pressed. cur(ch) is the note each
  ' channel is sounding right now (0 = silent).
  DIM cur(1)
  Status "Playing... Space or Esc stops."
  PLAY "ML T" + LTRIM$(STR$(tempo%))
  r = curRow%
  DO
    FOR ch = 0 TO 1
      v = pat%(ch, r)
      IF v >= 0 THEN cur(ch) = v      ' -1 means keep the old one
    NEXT
    ' Highlight the playing row by moving the cursor there.
    old = curRow%: curRow% = r
    IF r < topRow% OR r >= topRow% + VIEWH THEN DrawAll ELSE DrawRow old: DrawRow r
    ' Build this row's sound.
    IF cur(0) > 0 AND cur(1) > 0 THEN
      ' Both channels: two 32nd slices = one 16th row.
      m$ = "L32 N" + LTRIM$(STR$(cur(0))) + " N" + LTRIM$(STR$(cur(1)))
    ELSEIF cur(0) > 0 THEN
      m$ = "L16 N" + LTRIM$(STR$(cur(0)))
    ELSEIF cur(1) > 0 THEN
      m$ = "L16 N" + LTRIM$(STR$(cur(1)))
    ELSE
      m$ = "P16"
    END IF
    PLAY m$
    r = (r + 1) MOD ROWS
    k$ = INKEY$
  LOOP UNTIL k$ = " " OR k$ = CHR$(27)
  PLAY "MN"
  Status ""
END SUB

SUB Status (msg$)
  LOCATE 25, 2: COLOR 14: PRINT LEFT$(msg$ + SPACE$(70), 70);: COLOR 7
END SUB

' NoteName$: 0 -> "...", -1 -> "---", 49 -> "C-4", 50 -> "C#4"
FUNCTION NoteName$ (n%)
  IF n% = 0 THEN NoteName$ = "...": EXIT FUNCTION
  IF n% < 0 THEN NoteName$ = "---": EXIT FUNCTION
  s = (n% - 1) MOD 12
  o = (n% - 1) \ 12
  NoteName$ = MID$("C-C#D-D#E-F-F#G-G#A-A#B-", s * 2 + 1, 2) + LTRIM$(STR$(o))
END FUNCTION

' NoteNum%: "E-4" or "F#3" -> PLAY N number (the reverse of above)
FUNCTION NoteNum% (s$)
  s = INSTR("C D EF G A B", LEFT$(s$, 1)) - 1
  IF MID$(s$, 2, 1) = "#" THEN s = s + 1
  NoteNum% = VAL(MID$(s$, 3, 1)) * 12 + s + 1
END FUNCTION

DemoSong:
' Lead: Ode to Joy, quarter notes = 4 rows.
DATA E-5,4, E-5,4, F-5,4, G-5,4, G-5,4, F-5,4, E-5,4, D-5,4
DATA C-5,4, C-5,4, D-5,4, E-5,4, E-5,6, D-5,2, D-5,8, END,0
' Bass: one note per half bar.
DATA C-3,8, C-3,8, G-2,8, G-2,8, A-2,8, F-2,8, G-2,8, G-2,8, END,0
