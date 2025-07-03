SECTION "BLIB"

GET "LIBHDR"

LET WRITED(N,D) BE
$( LET T = VEC 5
   AND I, K = 0, -N
   IF N<0 DO D,K := D-1, N
   T!I, K, I := -(K REM 10), K/10, I+1 REPEATUNTIL K=0
   FOR J = I+1 TO D DO WRCH('*S')
   IF N<0 DO WRCH('-')
   FOR J = I-1 TO 0 BY -1 DO WRCH(T!J + '0' )
$)

LET WRITES(X) BE FOR K = 1 TO X%0 DO WRCH(X%K)

LET NEWLINE() BE WRCH('*N')

LET NEWPAGE() BE WRCH('*P')

LET WRITEN(N) BE WRITED(N, 0)

LET WRITEOCT(N ,D) BE
$( IF D>1 DO WRITEOCT(N>>3, D-1)
   WRCH((N&7) + '0') 
$)

LET WRITEO(N) BE WRITEOCT(N,6)

LET WRITEHEX(N, D) BE
$( IF D>1 DO WRITEHEX(N>>4, D-1)
   WRCH("0123456789ABCDEF"%(1+(N&15)))  
$)

LET WRITEX(N) BE WRITEHEX(N, 4)

LET WRITEU(N, D) BE
$( LET M = (N>>1)/5
   UNLESS M=0 DO
      $( WRITED(M, D-1)
         D := 1
      $)
   WRITED(N-M*10, D)
$)

LET WRITET(S, N) BE
$( WRITES(S)
   FOR I = (S%0)+1 TO N DO WRCH('*S')
$)

LET WRITEF(FORMAT, A, B, C, D, E, F, G, H, I, J, K) BE WRITEF1(FORMAT, @A)

AND WRITEF1(FORMAT, T) = VALOF
$( FOR P = 1 TO FORMAT%0 DO
   $( TEST FORMAT%P ~= '%' THEN WRCH(FORMAT%P)
      ELSE
          $( LET ARG = !T
             LET F, CH, N = ?, ?, 0
             P := P+1
             SWITCHON FORMAT%P INTO
                  $( DEFAULT: WRCH(CH);          LOOP

                     CASE 'F': CASE 'f':
                           T := WRITEF1(ARG, T+1)
                                                 LOOP

                     CASE 'T': CASE 't':
                           F := WRITET;          GOTO M
                     CASE 'U': CASE 'u':
                           F := WRITEU;          GOTO M
                     CASE 'S': CASE 's':
                           F := WRITES;          GOTO L
                     CASE 'C': CASE 'c':
                           F := WRCH;            GOTO L
                     CASE 'O': CASE 'o':
                           F := WRITEOCT;        GOTO M
                     CASE 'X': CASE 'x':
                           F := WRITEHEX;        GOTO M
                     CASE 'I': CASE 'i':
                           F := WRITED;          GOTO M
                     CASE 'N': CASE 'n':
                           F := WRITED;          GOTO L  

                   M: P := P+1
                     CH := FORMAT%P
                      N := '0'<=CH<='9' -> CH - '0',
                           'a'<=CH<='f' -> CH + ( 10 - 'a' ),
                           'A'<=CH<='F' -> CH + ( 10 - 'A' ),0

                   L: F(ARG, N)

                     CASE '$':
                     T := T+1  

                  $)
            $)                
       $)
   RESULTIS T
$)


LET READN() = VALOF
$( LET SUM = 0
   AND NEG = FALSE

   L:TERMINATOR := RDCH()
       SWITCHON TERMINATOR INTO
       $( CASE '*S':
          CASE '*T':
          CASE '*N':   GOTO L

          CASE '-' : NEG := TRUE
          CASE '+' : TERMINATOR := RDCH()
       $)
       WHILE '0' <=TERMINATOR<= '9' DO
                     $(   SUM := 10*SUM + TERMINATOR - '0'
                          TERMINATOR := RDCH()
                     $)
       IF NEG THEN SUM := -SUM
       RESULTIS SUM
$)

LET RANDOM(N) = 41965*N + 7473

