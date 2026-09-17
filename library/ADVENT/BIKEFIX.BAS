' ============================================================
' TITLE:    Bike Doctor Expert System
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     expert system, rules, backward chaining, ai, diagnosis
' SUMMARY:  A rule-based expert system that asks smart questions to diagnose bicycle trouble.
' ------------------------------------------------------------
' WHAT IT DOES
'   Expert systems were the big AI idea of the 1980s.  A human
'   expert's knowledge is written as IF ... THEN rules, e.g.
'       IF tyre is soft AND you hear hissing THEN it is a puncture.
'   The "inference engine" tries the rules one at a time.  When a
'   rule needs a fact it does not know yet, it ASKS you - and it
'   remembers the answer so it never asks twice.  The first rule
'   whose conditions are all true gives the diagnosis.
'   Answer W ("why?") to any question and it shows which rule it is
'   testing - expert systems can explain their reasoning!
'
' HOW TO USE
'   Answer each question with Y, N or W (why).  After the
'   diagnosis press Y to check another problem, N to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Knowledge (rules in DATA) kept separate from the engine (code)
'   * Backward chaining: only ask what a rule actually needs
'   * Caching answers: facts can be unknown, true or false
'   * Explanations: "because you said ..."
'
' THINGS TO TRY
'   * Add a rule for a broken spoke (and a new fact to ask about)
'   * Change rule order and see how the questions change
'   * Adapt it to diagnose a computer that won't start
' ============================================================

DEFINT A-Z
CONST NF = 12, NR = 13

DIM fq$(1 TO NF)          ' the question that discovers each fact
DIM fact(1 TO NF)         ' 0 = unknown, 1 = yes, 2 = no
DIM cond$(1 TO NR), diag$(1 TO NR), cure$(1 TO NR)

' ---------- the facts ----------
DATA "Does a tyre feel soft when you squeeze it"
DATA "Can you hear air hissing out of the tyre"
DATA "Has the chain come off the gears"
DATA "Is there a squeak or grinding noise when you pedal"
DATA "Does the chain look dry, dirty or rusty"
DATA "Do the brakes feel weak"
DATA "Are the brake pads worn smooth (no grooves left)"
DATA "Does the chain jump or slip when you pedal hard"
DATA "Does a wheel wobble side to side when you spin it"
DATA "Does a wheel rub against the brakes"
DATA "Does the brake lever pull all the way to the handlebar"
DATA "Was the tyre pumped up within the last week"
FOR i = 1 TO NF: READ fq$(i): NEXT

' ---------- the rules ----------
' Conditions are fact numbers each followed by Y or N, separated by
' spaces.  "1Y 2Y" means: IF fact 1 is yes AND fact 2 is yes.
DATA "1Y 2Y","a PUNCTURE","Find the hole, patch the inner tube or fit a new one."
DATA "1Y 12Y","a SLOW PUNCTURE","Pump it up, dunk the tube in water and look for bubbles."
DATA "1Y 12N","an UNDER-INFLATED tyre","Pump to the pressure printed on the tyre's side."
DATA "3Y","a DROPPED CHAIN","Shift to the smallest gear and lift the chain back on."
DATA "8Y 5Y","a WORN or DRY CHAIN","Clean and oil the chain. If it still slips, replace it."
DATA "8Y 5N","OUT-OF-TUNE GEARS","Turn the gear cable's barrel adjuster a quarter turn at a time."
DATA "4Y 5Y","a THIRSTY CHAIN","Wipe the chain and add a drop of oil to every link."
DATA "4Y 5N","LOOSE PEDALS or CRANKS","Tighten the pedals and crank bolts with the right tools."
DATA "6Y 7Y","WORN BRAKE PADS","Fit new brake pads and line them up with the rim."
DATA "6Y 11Y","a STRETCHED BRAKE CABLE","Tighten the cable with the barrel adjuster on the lever."
DATA "6Y 7N 11N","GREASY RIMS or PADS","Clean the rims and pads with soapy water."
DATA "9Y 10Y","a BUCKLED WHEEL","Have the wheel 'trued' by adjusting the spokes."
DATA "10Y 9N","a CROOKED WHEEL","Loosen the axle, centre the wheel in the frame, re-tighten."
FOR i = 1 TO NR: READ cond$(i), diag$(i), cure$(i): NEXT

DO
  CLS
  COLOR 14: PRINT "BIKE DOCTOR - an expert system": COLOR 7
  PRINT "Answer Y, N, or W to ask why I need to know."
  PRINT
  FOR i = 1 TO NF: fact(i) = 0: NEXT
  found = 0

  ' ---------- the inference engine ----------
  FOR r = 1 TO NR
    ok = 1
    c$ = cond$(r) + " "
    p = 1
    ' walk through the conditions "1Y 2Y " one token at a time
    DO WHILE p < LEN(c$) AND ok
      sp = INSTR(p, c$, " ")
      tok$ = MID$(c$, p, sp - p)
      p = sp + 1
      f = VAL(tok$)                         ' the fact number
      want = 1: IF RIGHT$(tok$, 1) = "N" THEN want = 2
      ' unknown fact?  ask the user (this is "backward chaining")
      DO WHILE fact(f) = 0
        PRINT fq$(f); "? ";
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = "W" OR k$ = CHR$(27)
        IF k$ = CHR$(27) THEN PRINT : END
        PRINT k$
        IF k$ = "Y" THEN fact(f) = 1
        IF k$ = "N" THEN fact(f) = 2
        IF k$ = "W" THEN
          COLOR 8
          PRINT "   I am testing rule"; r; ": IF "; cond$(r); " THEN it is "; diag$(r)
          PRINT "   (the numbers are facts; Y/N is the answer the rule needs)"
          COLOR 7
        END IF
      LOOP
      IF fact(f) <> want THEN ok = 0         ' this rule fails - try the next one
    LOOP
    IF ok THEN found = r: EXIT FOR
  NEXT

  ' ---------- report ----------
  PRINT
  IF found THEN
    COLOR 10: PRINT "DIAGNOSIS: Your bike has "; diag$(found); ".": COLOR 7
    PRINT "FIX: "; cure$(found)
    PRINT
    PRINT "I decided this because you told me:"
    c$ = cond$(found) + " ": p = 1
    DO WHILE p < LEN(c$)
      sp = INSTR(p, c$, " ")
      tok$ = MID$(c$, p, sp - p): p = sp + 1
      f = VAL(tok$)
      IF fact(f) = 1 THEN a$ = "yes" ELSE a$ = "no"
      PRINT "  * "; fq$(f); "? "; a$
    LOOP
  ELSE
    COLOR 12: PRINT "None of my rules match. Time to visit a bike shop!": COLOR 7
  END IF
  PRINT
  PRINT "Check another problem? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"
PRINT "Ride safely!"
