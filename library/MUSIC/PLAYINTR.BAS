' ============================================================
' TITLE:    PLAY Lesson 1: Notes and Octaves
' CATEGORY: Music & Sound
' LEVEL:    Beginner
' TAGS:     play, mml, notes, octaves, sharps, flats, tutorial
' SUMMARY:  A guided first lesson in the Music Macro Language: note letters, sharps, flats and octaves.
' ------------------------------------------------------------
' WHAT IT DOES
'   Walks you through the very first ideas of the PLAY statement,
'   one small step at a time. Each step prints the exact PLAY
'   string it is about to use, plays it, and waits for a key so
'   you can read the explanation before moving on.
'
' HOW TO USE
'   Read each screen, listen, then press any key to continue.
'   Press Esc at any "press a key" prompt to quit early.
'
' CONCEPTS YOU WILL LEARN
'   * PLAY "string" - the Music Macro Language (MML)
'   * Note letters A-G, sharps (# or +) and flats (-)
'   * O n (octave 0-6) and the < > octave shortcuts
'   * N n - choosing a note by number (0-84)
'   * Using a SUB to avoid repeating code
'
' THINGS TO TRY
'   * Change the strings in the DATA lines and re-run.
'   * Write your own name as music (only A-G count!).
'   * Try the same tune in O1 and in O6 - which sounds better?
' ============================================================

DECLARE SUB Lesson (title$, explain$, mml$)

' Each lesson is three strings: a title, an explanation, and the
' actual PLAY string. Keeping them in DATA lines means you can add
' your own lessons without touching the code below.
DATA "Single notes", "Letters A to G are notes. With no other settings PLAY uses octave 4 and quarter notes.", "C D E F G A B"
DATA "Sharps", "Add # (or +) after a letter to go up one half step - like the black key to its right.", "C C# D D# E F F# G G# A A# B"
DATA "Flats", "Add - after a letter to go DOWN one half step. D- is the same pitch as C#.", "B B- A A- G G- F E E- D D- C"
DATA "Octaves with O", "O sets the octave from 0 (very low) to 6 (very high). Here is C in every octave.", "O0 C O1 C O2 C O3 C O4 C O5 C O6 C O4"
DATA "Octaves with < and >", "> moves up one octave, < moves down one. Handy for melodies that cross a C.", "O3 G A B > C D E < B A G"
DATA "Notes by number", "N picks a note by number: N1 is the lowest C, N84 the highest B, N0 is silence.", "N37 N39 N41 N42 N44 N46 N48 N49"
DATA "Putting it together", "A tiny tune using everything so far: Mary Had a Little Lamb.", "O4 E D C D E E E P4 D D D P4 E G G P4 E D C D E E E E D D E D C"
DATA "*", "", ""

CLS
COLOR 14
PRINT "PLAY LESSON 1 - NOTES AND OCTAVES"
COLOR 7
PRINT
PRINT "The PC speaker can play music using a tiny language"
PRINT "called the Music Macro Language (MML). You write the"
PRINT "music as a string of letters and give it to PLAY."
PRINT
PRINT "Press any key to begin (Esc quits)..."
k$ = INPUT$(1)
IF k$ = CHR$(27) THEN END

' Read lessons until we hit the "*" end marker.
DO
  READ t$, e$, m$
  IF t$ = "*" THEN EXIT DO
  Lesson t$, e$, m$
LOOP

CLS
PRINT "That's the end of lesson 1. Next: PLAYLEN.BAS teaches"
PRINT "note lengths, rests, dotted notes and tempo."
END

' ------------------------------------------------------------
' Lesson: show one step, play it, wait for a key.
' ------------------------------------------------------------
SUB Lesson (title$, explain$, mml$)
  CLS
  COLOR 11: PRINT title$: COLOR 7
  PRINT STRING$(LEN(title$), "-")
  PRINT
  ' Word-wrap the explanation at about 60 columns so it
  ' looks tidy. We break on the last space before the limit.
  rest$ = explain$
  DO WHILE LEN(rest$) > 60
    cut = 60
    DO WHILE MID$(rest$, cut, 1) <> " " AND cut > 1: cut = cut - 1: LOOP
    PRINT LEFT$(rest$, cut - 1)
    rest$ = MID$(rest$, cut + 1)
  LOOP
  PRINT rest$
  PRINT
  COLOR 10: PRINT "PLAY "; CHR$(34); mml$; CHR$(34): COLOR 7
  PRINT
  ' Reset to a known state first ("T120 L4 O4 MN") so every
  ' lesson starts the same way no matter what came before.
  PLAY "T120 L4 O4 MN"
  PLAY mml$
  PRINT "Press any key for the next step (Esc quits)..."
  k$ = INPUT$(1)
  IF k$ = CHR$(27) THEN END
END SUB
