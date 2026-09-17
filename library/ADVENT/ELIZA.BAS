' ============================================================
' TITLE:    Pixel the Chatbot
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     chatbot, eliza, keywords, string processing, ai
' SUMMARY:  An ELIZA-style chatbot that spots keywords and reflects your words back at you.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1966 Joseph Weizenbaum wrote ELIZA, a program that seemed to
'   understand people but really just looked for KEYWORDS and turned
'   the rest of the sentence around.  Pixel works the same way:
'     1. find the most important keyword in what you typed
'     2. take the words AFTER the keyword ("the remainder")
'     3. swap pronouns: "my" -> "your", "I am" -> "you are"...
'     4. drop the remainder into a reply template at the "*"
'   Each keyword has several replies that are used in turn, so Pixel
'   does not repeat itself too quickly.
'
' HOW TO USE
'   Type a sentence and press Enter.  Type BYE to leave.
'   Try: "I feel tired", "my brother annoys me", "I want a robot",
'        "because it is raining", "can you dance"
'
' CONCEPTS YOU WILL LEARN
'   * Pattern matching with INSTR
'   * Word-by-word substitution ("reflection")
'   * Keyword priority: earlier rules in the table win
'   * Why simple tricks can feel surprisingly "intelligent"
'
' THINGS TO TRY
'   * Add your own keyword with three replies (and raise NKEYS)
'   * Make Pixel remember something you said earlier and bring it up
' ============================================================

DECLARE FUNCTION Reflect$ (s$)
DECLARE FUNCTION Clean$ (s$)
DEFINT A-Z
CONST NKEYS = 14, NREPLY = 3, NSWAP = 10

DIM kw$(1 TO NKEYS), reply$(1 TO NKEYS, 1 TO NREPLY), nextR(1 TO NKEYS)
DIM SHARED swapA$(1 TO NSWAP), swapB$(1 TO NSWAP)

' ---- keyword rules, most specific first.  Note the spaces: " I AM "
' only matches whole words.  "*" marks where the reflected
' remainder of the sentence is inserted.
DATA " I FEEL ","Why do you feel *?","How long have you felt *?","Does feeling * happen often?"
DATA " I AM ","Why are you *?","Did you come to me because you are *?","How do you like being *?"
DATA " I WANT ","What would it mean to you if you got *?","Why do you want *?","Suppose you got * soon. Then what?"
DATA " I CAN'T ","What makes you think you can't *?","Have you really tried to *?","Perhaps you could * if you tried."
DATA " CAN YOU ","Would you like me to *?","Robots like me can't always *. Can you?","Why do you ask if I can *?"
DATA " BECAUSE ","Is that the real reason?","Does any other reason come to mind?","Does that explain anything else?"
DATA " MY MOTHER","Tell me more about your family.","How do you get along with your mother?","Who else in your family do you talk to?"
DATA " MY FATHER","Tell me more about your family.","What is your father like?","Do you get along with your father?"
DATA " MY ","Your *?","Why do you say your *?","Is it important to you that your *?"
DATA "COMPUTER","Do computers worry you?","Are you talking about me?","What do you think about machines?"
DATA "DREAM","What does that dream suggest to you?","Do you dream often?","Who appears in your dreams?"
DATA "SORRY","Please don't apologise.","Apologies are not necessary.","No harm done!"
DATA "HELLO","Hi there! How are you feeling today?","Hello! What is on your mind?","Hey! What shall we talk about?"
DATA " NO ","Why not?","You seem quite sure.","Are you saying no just to be difficult?"
FOR k = 1 TO NKEYS
  READ kw$(k)
  FOR r = 1 TO NREPLY: READ reply$(k, r): NEXT
  nextR(k) = 1
NEXT

' replies when no keyword is found at all
DIM vague$(1 TO 5)
DATA "Please go on.","That is interesting. Tell me more.","I see.","How does that make you feel?","Why do you say that?"
FOR i = 1 TO 5: READ vague$(i): NEXT

' ---- pronoun swaps (both directions are listed) ----
DATA "I","YOU", "ME","YOU", "MY","YOUR", "AM","ARE", "MYSELF","YOURSELF"
DATA "YOU","I", "YOUR","MY", "ARE","AM", "YOURS","MINE", "MINE","YOURS"
FOR i = 1 TO NSWAP: READ swapA$(i), swapB$(i): NEXT

RANDOMIZE TIMER
CLS
COLOR 13: PRINT "PIXEL: Hello, I'm Pixel. What would you like to talk about?": COLOR 7
DO
  PRINT
  LINE INPUT "YOU:   ", t$
  s$ = " " + Clean$(t$) + " "          ' pad with spaces so " NO" etc. match at the ends
  IF INSTR(s$, " BYE ") OR INSTR(s$, " QUIT ") OR s$ = " Q " THEN EXIT DO

  ' ---- search the keyword list in priority order ----
  found = 0
  FOR k = 1 TO NKEYS
    p = INSTR(s$, kw$(k))
    IF p > 0 THEN found = k: EXIT FOR
  NEXT

  IF RTRIM$(LTRIM$(s$)) = "" THEN
    say$ = "Cat got your tongue?"
  ELSEIF found = 0 THEN
    say$ = vague$(INT(RND * 5) + 1)
  ELSE
    ' pick the next reply for this keyword, rotating 1,2,3,1,2,3...
    say$ = reply$(found, nextR(found))
    nextR(found) = nextR(found) MOD NREPLY + 1
    ' everything after the keyword, with the pronouns flipped
    rest$ = Reflect$(MID$(s$, p + LEN(kw$(found))))
    IF rest$ = "" THEN rest$ = "that"
    star = INSTR(say$, "*")
    IF star THEN say$ = LEFT$(say$, star - 1) + LCASE$(rest$) + MID$(say$, star + 1)
  END IF
  COLOR 13: PRINT "PIXEL: "; say$: COLOR 7
LOOP
COLOR 13: PRINT "PIXEL: Goodbye! It was nice talking to you.": COLOR 7

' Upper-case the text and throw away punctuation, so "Hello!!" and
' "hello" look the same to the keyword search.  The apostrophe is
' kept because "CAN'T" needs it.
FUNCTION Clean$ (s$)
  u$ = UCASE$(s$): o$ = ""
  FOR i = 1 TO LEN(u$)
    c$ = MID$(u$, i, 1)
    IF (c$ >= "A" AND c$ <= "Z") OR (c$ >= "0" AND c$ <= "9") OR c$ = "'" THEN
      o$ = o$ + c$
    ELSE
      o$ = o$ + " "
    END IF
  NEXT
  Clean$ = o$
END FUNCTION

' Swap first- and second-person words, one word at a time:
'   "MY CAT HATES ME"  ->  "YOUR CAT HATES YOU"
' We must split into words first; replacing inside the whole string
' would turn "YOUR" into "YOUR" -> "MYR" and other nonsense.
FUNCTION Reflect$ (s$)
  o$ = "": w$ = ""
  t$ = s$ + " "
  FOR i = 1 TO LEN(t$)
    c$ = MID$(t$, i, 1)
    IF c$ <> " " THEN
      w$ = w$ + c$
    ELSEIF w$ <> "" THEN
      FOR j = 1 TO NSWAP
        IF w$ = swapA$(j) THEN w$ = swapB$(j): EXIT FOR
      NEXT
      IF o$ <> "" THEN o$ = o$ + " "
      o$ = o$ + w$
      w$ = ""
    END IF
  NEXT
  Reflect$ = o$
END FUNCTION
