' ============================================================
' TITLE:    Perceptron: A Neuron That Learns
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     neural network, perceptron, machine learning, logic gates, ai
' SUMMARY:  Trains a single artificial neuron to behave like AND, OR - and shows why XOR defeats it.
' ------------------------------------------------------------
' WHAT IT DOES
'   A perceptron (Frank Rosenblatt, 1958) is the simplest neural
'   network: one "neuron" with two inputs.
'        sum = w1*x1 + w2*x2 + bias
'        output = 1 if sum > 0, otherwise 0
'   It starts with random weights.  For every training example it
'   checks its answer and nudges the weights:
'        error = target - output            (-1, 0 or +1)
'        w1 = w1 + rate * error * x1        (and the same for w2)
'        bias = bias + rate * error
'   For AND and OR this always settles on correct weights.  For XOR
'   it never does - no single straight line can split XOR's points.
'   That discovery (Minsky & Papert, 1969) is why real networks use
'   many neurons in LAYERS.
'
' HOW TO USE
'   Choose a gate: 1 = AND, 2 = OR, 3 = NAND, 4 = XOR, Q = quit.
'   Watch each training round (an "epoch") and the final truth table.
'
' CONCEPTS YOU WILL LEARN
'   * Weighted sums and a step "activation" function
'   * The perceptron learning rule
'   * Linear separability: a line drawn by the weights
'   * Epochs and convergence
'
' THINGS TO TRY
'   * Change the learning RATE to 1 or 0.01
'   * Add a third input and teach it a 3-input AND
'   * Solve XOR with TWO layers: XOR = (A OR B) AND (A NAND B)
' ============================================================

DEFINT I-N
CONST RATE = .2, MAXEPOCH = 30
DIM x1(1 TO 4), x2(1 TO 4), target(1 TO 4)
DIM gateName$(1 TO 4), table$(1 TO 4)
' The four input pairs are always 00, 01, 10, 11.
' table$ holds the wanted outputs for those four rows.
DATA AND,0001, OR,0111, NAND,1110, XOR,0110
FOR i = 1 TO 4: READ gateName$(i), table$(i): NEXT
DATA 0,0, 0,1, 1,0, 1,1
FOR i = 1 TO 4: READ x1(i), x2(i): NEXT
RANDOMIZE TIMER

DO
  CLS
  COLOR 14: PRINT "PERCEPTRON - one neuron learning a logic gate": COLOR 7
  PRINT
  PRINT "Teach it:  1) AND   2) OR   3) NAND   4) XOR (impossible!)   Q) Quit"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL INSTR("1234Q" + CHR$(27), k$) > 0 AND k$ <> ""
  IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
  gate = VAL(k$)
  FOR i = 1 TO 4: target(i) = VAL(MID$(table$(gate), i, 1)): NEXT

  ' random starting weights between -1 and +1
  w1 = RND * 2 - 1: w2 = RND * 2 - 1: bias = RND * 2 - 1
  PRINT
  PRINT "Learning "; gateName$(gate); ".  Start: w1="; : PRINT USING "##.##"; w1;
  PRINT "  w2="; : PRINT USING "##.##"; w2;: PRINT "  bias="; : PRINT USING "##.##"; bias
  PRINT
  PRINT "Epoch  mistakes   w1      w2     bias"

  FOR epoch = 1 TO MAXEPOCH
    mistakes = 0
    FOR i = 1 TO 4
      ' --- the neuron fires (1) or stays quiet (0) ---
      s = w1 * x1(i) + w2 * x2(i) + bias
      IF s > 0 THEN fire = 1 ELSE fire = 0
      ' --- learning rule: only changes anything when it was wrong ---
      e = target(i) - fire
      IF e <> 0 THEN
        mistakes = mistakes + 1
        w1 = w1 + RATE * e * x1(i)
        w2 = w2 + RATE * e * x2(i)
        bias = bias + RATE * e
      END IF
    NEXT
    PRINT USING " ###     #      ##.##  ##.##  ##.##"; epoch; mistakes; w1; w2; bias
    IF mistakes = 0 THEN EXIT FOR
    IF CSRLIN > 20 THEN EXIT FOR         ' keep the screen tidy
  NEXT

  ' ---------- test the trained neuron ----------
  PRINT
  PRINT " A  B   wanted  neuron"
  correct = 0
  FOR i = 1 TO 4
    s = w1 * x1(i) + w2 * x2(i) + bias
    IF s > 0 THEN fire = 1 ELSE fire = 0
    IF fire = target(i) THEN correct = correct + 1: COLOR 10 ELSE COLOR 12
    PRINT USING " #  #     #       #"; x1(i); x2(i); target(i); fire
    COLOR 7
  NEXT
  IF correct = 4 THEN
    PRINT "Learned it!  The neuron draws the line  ";
    PRINT USING "##.##*A + ##.##*B + ##.## = 0"; w1; w2; bias
  ELSE
    PRINT "Still wrong on"; 4 - correct; "row(s). XOR can't be split by one straight"
    PRINT "line - you need a second layer of neurons."
  END IF
  PRINT : PRINT "Press any key..."
  DO: LOOP WHILE INKEY$ = ""
LOOP
PRINT "Neuron switched off."
