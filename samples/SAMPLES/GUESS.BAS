' GUESS.BAS - Guess the number
' Concepts: RANDOMIZE, RND, INPUT, DO...LOOP, IF...ELSEIF
RANDOMIZE TIMER
CLS
PRINT "I'm thinking of a number between 1 and 100."
secret = INT(RND * 100) + 1
tries = 0
DO
    INPUT "Your guess"; guess
    tries = tries + 1
    IF guess < secret THEN
        PRINT "  Too low!"
    ELSEIF guess > secret THEN
        PRINT "  Too high!"
    END IF
LOOP UNTIL guess = secret
PRINT
PRINT "You got it in"; tries; "tries!"
IF tries <= 7 THEN PRINT "Excellent guessing!" ELSE PRINT "Hint: try halving the range each time."
