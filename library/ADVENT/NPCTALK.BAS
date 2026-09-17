' ============================================================
' TITLE:    The Blacksmith's Bargain (NPC Dialogue Tree)
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     dialogue tree, npc, game design, conditions, data
' SUMMARY:  Talk your way to a cheaper sword repair in a dialogue tree with moods, gold and conditions.
' ------------------------------------------------------------
' WHAT IT DOES
'   Role-playing games let you chat with NPCs (non-player
'   characters).  Behind the scenes it is a DIALOGUE TREE: every
'   node is something the NPC says, and each reply you can choose
'   leads to another node.  Unlike a plain story, replies can have
'     CONDITIONS - only possible if, say, you have 30 gold, or the
'                  NPC likes you enough (mood >= 2)
'     EFFECTS    - paying gold, raising or lowering her mood, or
'                  setting a "flag" the story remembers
'   Locked replies are shown in grey with what they need, so you
'   can see how your earlier choices open new doors.
'
' HOW TO USE
'   Press the number of the reply you want.  Esc quits.
'   You start with 20 gold - not enough for the full price...
'
' CONCEPTS YOU WILL LEARN
'   * A dialogue tree stored in DATA (nodes and options)
'   * Tiny "codes" like G30 or M+1 decoded with LEFT$ / MID$ / VAL
'   * Game state: gold, mood and flags changing the conversation
'
' THINGS TO TRY
'   * Add a node where you can sell her something for gold
'   * Make mood show as a face:  :(  :|  :)
'   * Add a second NPC who remembers what you told the first one
' ============================================================

DECLARE FUNCTION CondOK% (c$)
DECLARE FUNCTION CondText$ (c$)
DEFINT A-Z
CONST MAXN = 20, MAXO = 40
DIM SHARED gold, mood, flag(1 TO 5)
DIM nodeText$(1 TO MAXN)
DIM oNode(1 TO MAXO), oText$(1 TO MAXO), oGo(1 TO MAXO), oCond$(1 TO MAXO), oEff$(1 TO MAXO)
DIM shown(1 TO 9)

' ---- the conversation ----
' N, node number, what Brenna says
' O, reply text, node it leads to (0 = conversation ends), condition, effect
'   condition: ""  none   G30 = needs 30 gold   M2 = needs mood 2+
'   effect:    ""  none   G-30 = pay 30 gold   M+1 / M-2 = mood   F3 = set flag 3
DATA N,1,"Brenna wipes soot from her hands. 'Forge is hot, traveller. What d'you need?'"
DATA O,"I need my sword repaired.",2,"",""
DATA O,"That's a fine forge you have.",3,"","M+1"
DATA O,"Nothing. Goodbye.",0,"",""
DATA N,2,"She turns the broken blade over. 'Snapped clean through. That'll be 30 gold.'"
DATA O,"Here's 30 gold.",4,"G30","G-30"
DATA O,"Could you do it any cheaper?",5,"",""
DATA O,"Let's talk about something else.",1,"",""
DATA N,3,"'Built it with my own two hands - and my gran before me.' She smiles a little."
DATA O,"Your gran was a smith too?",6,"","M+1"
DATA O,"Anyway, about my sword...",2,"",""
DATA N,4,"'Come back at sunset and it'll be good as new.' She gets to work."
DATA O,"Thank you, Brenna!",0,"","F2"
DATA N,5,"'Cheaper?' Her eyes narrow."
DATA O,"Everyone says you're the best smith in the valley.",7,"M2",""
DATA O,"Fine. Thirty it is.",2,"",""
DATA O,"Your prices are daylight robbery!",8,"","M-2"
DATA N,6,"'Aye. She forged the old king's crown, she did. Lost now, of course.'"
DATA O,"Tell me about the crown.",9,"","F1"
DATA O,"About my sword...",2,"",""
DATA N,7,"She laughs out loud. 'Flattery and good manners! Fifteen gold, then.'"
DATA O,"Deal! Here's 15 gold.",4,"G15","G-15"
DATA O,"Still too much for me.",1,"",""
DATA N,8,"'Then find yourself another smith!' She turns her back on you."
DATA O,"(Leave.)",0,"",""
DATA N,9,"'Folk say it's down the old mine. Bring it back and I'll mend your sword for free.'"
DATA O,"I'll find it!",0,"","F3"
DATA O,"About my sword...",2,"",""
DATA END

' ---- load the tree into arrays ----
nOpt = 0
DO
  READ kind$
  IF kind$ = "END" THEN EXIT DO
  IF kind$ = "N" THEN
    READ cur, nodeText$(cur)
  ELSE
    nOpt = nOpt + 1
    oNode(nOpt) = cur                     ' this option belongs to the latest node
    READ oText$(nOpt), oGo(nOpt), oCond$(nOpt), oEff$(nOpt)
  END IF
LOOP

gold = 20: mood = 0
node = 1
DO
  CLS
  COLOR 14: PRINT "THE BLACKSMITH'S BARGAIN";
  COLOR 8: PRINT "        gold:"; gold; "  Brenna's mood:"; mood: COLOR 7
  PRINT
  COLOR 15: PRINT nodeText$(node): COLOR 7
  PRINT
  ' ---- list this node's options, greyed out when locked ----
  n = 0
  FOR o = 1 TO nOpt
    IF oNode(o) = node THEN
      n = n + 1: shown(n) = o
      IF CondOK(oCond$(o)) THEN
        COLOR 11: PRINT "  "; n; oText$(o)
      ELSE
        COLOR 8: PRINT "  "; n; oText$(o); "  [needs "; CondText$(oCond$(o)); "]"
      END IF
    END IF
  NEXT
  COLOR 7
  ' ---- wait for a valid, unlocked choice ----
  DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN END
    c = VAL(k$)
    ok = 0
    IF c >= 1 AND c <= n THEN ok = CondOK(oCond$(shown(c)))
  LOOP UNTIL ok
  o = shown(c)

  ' ---- apply the effect code ----
  e$ = oEff$(o)
  IF e$ <> "" THEN
    v = VAL(MID$(e$, 2))                  ' "G-30" -> -30, "M+1" -> 1, "F3" -> 3
    SELECT CASE LEFT$(e$, 1)
      CASE "G": gold = gold + v
      CASE "M": mood = mood + v
      CASE "F": flag(v) = 1
    END SELECT
  END IF
  node = oGo(o)
LOOP UNTIL node = 0

' ---- how did it go? the flags tell the story ----
PRINT
COLOR 10
IF flag(2) THEN
  PRINT "Your sword will be mended. You kept"; gold; "gold."
  IF gold > 0 THEN PRINT "Good haggling!"
ELSEIF flag(3) THEN
  PRINT "You set off for the old mine to find the lost crown... a new quest begins!"
ELSEIF mood < 0 THEN
  COLOR 12: PRINT "Brenna won't be fixing anything for you. Maybe try kindness next time."
ELSE
  PRINT "You leave the forge with a broken sword and"; gold; "gold."
END IF
COLOR 7

' Is the condition met?  "" always is; G30 = gold >= 30; M2 = mood >= 2.
FUNCTION CondOK% (c$)
  CondOK% = -1
  IF c$ = "" THEN EXIT FUNCTION
  v = VAL(MID$(c$, 2))
  SELECT CASE LEFT$(c$, 1)
    CASE "G": IF gold < v THEN CondOK% = 0
    CASE "M": IF mood < v THEN CondOK% = 0
  END SELECT
END FUNCTION

' Turn a condition code into words for the player.
FUNCTION CondText$ (c$)
  v$ = MID$(c$, 2)
  SELECT CASE LEFT$(c$, 1)
    CASE "G": CondText$ = v$ + " gold"
    CASE "M": CondText$ = "Brenna to like you (mood " + v$ + ")"
    CASE ELSE: CondText$ = c$
  END SELECT
END FUNCTION
