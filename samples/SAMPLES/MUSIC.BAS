' MUSIC.BAS - The PC speaker plays music with PLAY (Music Macro Language)
' O=octave  L=note length  T=tempo  < > change octave  P=pause  MS/ML/MN=staccato/legato/normal
CLS
PRINT "Ode to Joy (Beethoven)"
PLAY "T140 O3 L4 EEFG GFED CCDE E.D8D2"
PLAY "EEFG GFED CCDE D.C8C2"
PRINT "A scale, staccato then legato"
PLAY "MS T200 O3 L8 CDEFGAB>C"
PLAY "ML <CBAGFEDC"
PRINT "Sound effects with SOUND frequency, duration"
FOR f = 200 TO 1200 STEP 100: SOUND f, 1: NEXT
FOR f = 1200 TO 200 STEP -100: SOUND f, 1: NEXT
PRINT "Twinkle Twinkle, in the background (MB) while we count:"
PLAY "MB T120 O3 L4 CCGGAAG2FFEEDDC2"
FOR i = 1 TO 8: PRINT i; : SLEEP 1: NEXT
PRINT
PRINT "Done!"
