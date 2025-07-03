// BCPL for Zilog Z80.
// S. Kelley, 	Autumn 1987.

SECTION "LEX"
GET "COMPHDR"

STATIC $( 
CH=?; CHBUF=?; CHCOUNT=?; LINECOUNT=?
GETP=?; SKIPTAG=?; NAMETABLE=?
$)

LET START() BE
$( LET MAXMEM, TOTALERRS = 0, 0
   LET TREESIZE, TREEBASE, A = ?, ?, ?

   SOURCESTREAM := INPUT()
   OCODE := (OUTPUT() = CON) -> FINDOUTPUT("BCPL.OUT"), OUTPUT()
  
   TREESIZE := MAXVEC()-250 // Save space for 3 get files to be opened
   TREEBASE := GETVEC(TREESIZE)

   SELECTOUTPUT(CON)
   WRITEF("*NZ80 BCPL Compiler starting....*N*
            *Workspace available is %N words.*N*N", TREESIZE)

   UNLESS SOURCESTREAM DO ABORT("Can't open input file")
   UNLESS OCODE        DO ABORT("Can't open output file")

   SELECTOUTPUT(OCODE)
   BINARYOUTPUT(TRUE)
   WRITE1(S.STARTFILE)
   SELECTOUTPUT(CON)

   TREETOP := TREEBASE+TREESIZE
   LINECOUNT := 1

   $( TREEP := TREEBASE
      A := FORMTREE()
      TOTALERRS := TOTALERRS+REPORTCOUNT
      TREEPMAX := TREEP

      IF REPORTCOUNT=0 THEN
           $( SELECTOUTPUT(OCODE)
              COMPILEAE(A)
              TOTALERRS := TOTALERRS + REPORTCOUNT
              SELECTOUTPUT(CON)  
           $)

      IF TREEPMAX>MAXMEM THEN MAXMEM := TREEPMAX
     
   $) REPEATUNTIL A=0

   WRITEF("Workspace used was %n words.*N", MAXMEM-TREEBASE)
   WRITEF(TOTALERRS->"%N errors.*N","No errors.*N", TOTALERRS)


   ENDREAD()
   SELECTOUTPUT(OCODE)
   WRITE1(S.ENDFILE)
   TEST TOTALERRS=0 THEN ENDWRITE()
                    ELSE REMOVEOUTPUT() // delete a faulty output file
$)

AND NEXTSYMB() BE
$(1 NLPENDING := FALSE

    IF INTKEY() THEN ABORT("Interrupted") // Abort on ctrl-C

$(2 IF '0'<=CH<='9' THEN
        $( SYMB := S.NUMBER
           READNUMBER(10)
           RETURN
        $)

    IF 'A'<=CH<='Z' THEN
        $( RDTAG(CH)
           SYMB := LOOKUPWORD()
           UNLESS SYMB=S.GET RETURN
           // go to the include file....
           NEXTSYMB()
           UNLESS SYMB=S.STRING THEN SYNREPORT("Bad GET")

           $( LET NEWSTREAM = FINDINPUT(@(H2!WORDNODE))
              UNLESS NEWSTREAM DO SYNREPORT("Cannot open %S", @(H2!WORDNODE))
              GETP := LIST5(GETP, SOURCESTREAM, LINECOUNT, CH, WORDNODE)
              LINECOUNT := 1
              SOURCESTREAM := NEWSTREAM
              SELECTINPUT(SOURCESTREAM)
              RCH()
              LOOP
           $)
        $)

    SWITCHON CH INTO

$(S CASE '*N': LINECOUNT := LINECOUNT + 1
               NLPENDING := TRUE  // IGNORABLE CHARACTERS
    CASE '*T':
    CASE '*S': RCH() REPEATWHILE CH='*S'
               LOOP

    CASE '$': RCH()
              IF CH='$' | CH='<' | CH='>' DO
              $( LET K = CH
                 RDTAG('<')
                 SYMB := LOOKUPWORD()

                 IF K='>' DO
                 $( IF SKIPTAG=WORDNODE DO SKIPTAG := 0
                    LOOP
                 $)

                 UNLESS SKIPTAG=0 LOOP

                 IF K='$' DO
                 $( H1!WORDNODE := SYMB=S.TRUE -> S.FALSE, S.TRUE
                    LOOP
                 $)

                 // K must be '<'
                 IF SYMB=S.TRUE LOOP
                 SKIPTAG := WORDNODE
                 UNTIL SKIPTAG=0 DO NEXTSYMB()
                 RETURN
              $)

              UNLESS CH='(' | CH=')' DO SYNREPORT("'$' out of context")
              SYMB := CH='(' -> S.LSECT, S.RSECT
              RDTAG('$')
              LOOKUPWORD()
              RETURN

    CASE '[':
    CASE '(': SYMB := S.LPAREN; BREAK

    CASE ']':
    CASE ')': SYMB := S.RPAREN; BREAK

    CASE '#':
         SYMB := S.NUMBER
         RCH()
         IF '0'<=CH<='7' DO $(        READNUMBER(8);  RETURN  $)
         IF CH='B'       DO $( RCH(); READNUMBER(2);  RETURN  $)
         IF CH='O'       DO $( RCH(); READNUMBER(8);  RETURN  $)
         IF CH='X'       DO $( RCH(); READNUMBER(16); RETURN  $)
         SYNREPORT("Bad number")

    CASE '?': SYMB := S.QUERY;     BREAK
    CASE '+': SYMB := S.PLUS;      BREAK
    CASE ',': SYMB := S.COMMA;     BREAK
    CASE ';': SYMB := S.SEMICOLON; BREAK
    CASE '@': SYMB := S.LV;        BREAK
    CASE '&': SYMB := S.LOGAND;    BREAK
    CASE '|': SYMB := S.LOGOR;     BREAK
    CASE '=': SYMB := S.EQ;        BREAK
    CASE '!': SYMB := S.VECAP;     BREAK
    CASE '%': SYMB := S.BYTEAP;    BREAK
    CASE '**':SYMB := S.MULT;      BREAK

    CASE '/':
         RCH()
         IF CH='\' DO $( SYMB := S.LOGAND; BREAK $)
         IF CH='/' DO
            $( RCH() REPEATUNTIL CH='*N' | CH=ENDSTREAMCH
               LOOP  $)

         UNLESS CH='**' DO $( SYMB := S.DIV; RETURN  $)

         $( RCH()
            IF CH='**' DO
               $( RCH() REPEATWHILE CH='**'
                  IF CH='/' BREAK  $)
            IF CH='*N' DO LINECOUNT := LINECOUNT+1
            IF CH=ENDSTREAMCH DO SYNREPORT("'**/' missing")
         $) REPEAT

         RCH()
         LOOP

    CASE '\': RCH()
              IF CH='/' DO $( SYMB := S.LOGOR;  BREAK $)
              IF CH='=' DO $( SYMB := S.NE;     BREAK $)
              SYMB := S.NOT
              RETURN

    CASE '~': RCH()
              IF CH='=' DO $( SYMB := S.NE;     BREAK $)
              SYMB := S.NOT
              RETURN

    CASE '<': RCH()
              IF CH='=' DO $( SYMB := S.LE;     BREAK $)
              IF CH='<' DO $( SYMB := S.LSHIFT; BREAK $)
              SYMB := S.LS
              RETURN

    CASE '>': RCH()
              IF CH='=' DO $( SYMB := S.GE;     BREAK $)
              IF CH='>' DO $( SYMB := S.RSHIFT; BREAK $)
              SYMB := S.GR
              RETURN

    CASE '-': RCH()
              IF CH='>' DO $( SYMB := S.COND; BREAK  $)
              SYMB := S.MINUS
              RETURN

    CASE ':': RCH()
              IF CH='=' DO $( SYMB := S.ASS; BREAK  $)
              IF CH=':' DO $( SYMB := S.OF;  BREAK  $)
              SYMB := S.COLON
              RETURN


    CASE '"':
           $( LET CHARV = TREEP+H2
              LET CHARP = 0
              RCH()
              UNTIL CH = '"' DO
              $( IF CHARP=255 DO SYNREPORT("String too long")
                 CHARP := CHARP + 1
                 IF (CHARV+(CHARP/BYTESPERWORD))>TREETOP BREAK
                 CHARV%CHARP := STRCH()
                 RCH()
              $)
              RCH()
              CHARV%0 := CHARP
              H1!TREEP := S.STRING
              SYMB:=S.STRING
              WORDNODE := NEWVEC((CHARP/BYTESPERWORD)+1)
              RETURN
           $)

    CASE '*'':RCH()
              DECVAL := STRCH()
              RCH()
              SYMB := S.NUMBER
              UNLESS CH='*'' DO SYNREPORT("Bad char")
              BREAK

    CASE ENDSTREAMCH:
    CASE '.': IF GETP=0 DO $( SYMB := S.END
                              RETURN   $)
              ENDREAD()
              SOURCESTREAM := H2!GETP
              SELECTINPUT(SOURCESTREAM)
              LINECOUNT := H3!GETP
              CH := H4!GETP
              GETP := H1!GETP
              LOOP

    DEFAULT: CH := '*S'
             SYNREPORT("Illegal character")
$)S

$)2 REPEAT

    RCH()
$)1


AND LOOKUPWORD() = VALOF
$(1 LET CHARV = TREEP+H3
    LET LENGTH = CHARV%0
    LET HASHVAL = (CHARV%1+CHARV%LENGTH) & (NAMETABLESIZE-1)
                  // Nametablesize must be a power of two.
    LET I = 0

    WORDNODE := NAMETABLE!HASHVAL

    UNTIL WORDNODE=0 | I>LENGTH DO
          TEST (WORDNODE+2)%I=CHARV%I
            THEN I := I+1
            ELSE WORDNODE, I := H2!WORDNODE, 0

    IF WORDNODE=0 DO // string is already in the correct place
      $( WORDNODE := NEWVEC((LENGTH/BYTESPERWORD)+2)
         WORDNODE!0, WORDNODE!1 := S.NAME, NAMETABLE!HASHVAL
         NAMETABLE!HASHVAL := WORDNODE  $)

    RESULTIS H1!WORDNODE  $)1


AND DECLSYSWORDS() BE
$( LET D(WORDS, CODEP) BE
   $( LET I = 1
      LET LENGTH = 0
      $( LET CH = WORDS%I
         LET CHARV = TREEP+H3
         TEST CH='/'
             THEN $( IF LENGTH=0 RETURN
                     CHARV%0 := LENGTH
                     LOOKUPWORD()
                     H1!WORDNODE := !CODEP
                     CODEP := CODEP + 1
                     LENGTH := 0  $)
             ELSE $( LENGTH := LENGTH + 1
                     CHARV%LENGTH := CH  $)
         I := I + 1
      $) REPEAT
  $)

    D("AND/ABS/*
      *BE/BREAK/BY/*
      *CASE/*
      *DO/DEFAULT/*
      *EQ/EQV/ELSE/ENDCASE/*
      *FALSE/FOR/FINISH/*
      *GOTO/GE/GR/GLOBAL/GET/*
      *IF/INTO/*
      *LET/LV/LE/LS/LOGOR/LOGAND/LOOP/LSHIFT//",

      TABLE

      S.AND,S.ABS,
      S.BE,S.BREAK,S.BY,
      S.CASE,
      S.DO,S.DEFAULT,
      S.EQ,S.EQV,S.OR,S.ENDCASE,
      S.FALSE,S.FOR,S.FINISH,
      S.GOTO,S.GE,S.GR,S.GLOBAL,S.GET,
      S.IF,S.INTO,
      S.LET,S.LV,S.LE,S.LS,S.LOGOR,S.LOGAND,S.LOOP,S.LSHIFT)

    D("MANIFEST/*
      *NE/NOT/NEQV/NEEDS/*
      *OR/OF/*
      *RESULTIS/RETURN/REM/RSHIFT/RV/*
      *REPEAT/REPEATWHILE/REPEATUNTIL/*
      *SWITCHON/STATIC/SECTION/SLCT/*
      *TO/TEST/TRUE/THEN/TABLE/*
      *UNTIL/UNLESS/*
      *VEC/VALOF/*
      *WHILE/*
      *$//",

      TABLE

      S.MANIFEST,
      S.NE,S.NOT,S.NEQV,S.NEEDS,
      S.OR,S.OF,
      S.RESULTIS,S.RETURN,S.REM,S.RSHIFT,S.RV,
      S.REPEAT,S.REPEATWHILE,S.REPEATUNTIL,
      S.SWITCHON,S.STATIC,S.SECTION,S.SLCT,
      S.TO,S.TEST,S.TRUE,S.DO,S.TABLE,
      S.UNTIL,S.UNLESS,
      S.VEC,S.VALOF,
      S.WHILE,
      0)

     NULLTAG := WORDNODE  
$)

AND RCH() BE
$( CH := RDCH()
   IF CH = ENDSTREAMCH RETURN
   CHCOUNT := CHCOUNT + 1
   CHBUF%(CHCOUNT&63) := CH  
   IF 'a'<=CH<='z' THEN CH := CH + ('A'-'a') // Convert whole prog to UC
$)


AND RDTAG(CHAR1) BE
    $( LET CHARP = 1
       LET CHARV = TREEP+H3
       CHARV%1 := CHAR1 // build the string on the top
                        // of the tree, so it's
                        // in the right place
       $( RCH()
          UNLESS 'A'<=CH<='Z' | '0'<=CH<='9' | CH='.' BREAK
          CHARP := CHARP+1
          IF (CHARV+(CHARP/BYTESPERWORD))>TREETOP BREAK
          CHARV%CHARP := CH
       $)
          REPEAT

       CHARV%0 := CHARP
    $)



AND READNUMBER(RADIX) BE
    $( LET D = VALUE(CH)
       DECVAL := D
       IF D>=RADIX DO SYNREPORT("Bad number")

       $( RCH()

          D := VALUE(CH)
          IF D>=RADIX RETURN
          DECVAL := RADIX*DECVAL + D  $) REPEAT
    $)


AND VALUE(CH) = '0'<=CH<='9' -> CH-'0',
                'A'<=CH<='F' -> CH+(10-'A'),
                100

AND STRCH() = VALOF
$( // Read in a char from a string or char constant 
   IF CH < '*S' DO // Rather ASCII specific 
             SYNREPORT("Unescaped control char in string or char")
  
   UNLESS CH ='**' RESULTIS CHBUF%(CHCOUNT&63) // Char without LC->UC

   RCH()
   TEST CH='*N' | CH='*S' | CH='*T' THEN // Continuation
       $( WHILE CH='*N' | CH='*S' | CH='*T' DO
               $( IF CH='*N' DO LINECOUNT := LINECOUNT + 1
                  RCH()
               $) 
          UNLESS CH='**' DO SYNREPORT("Bad string continuation")
          RCH()
          RESULTIS STRCH()
       $)
   ELSE
       $( // Escape
          IF '0'<=CH<='9' RESULTIS (VALUE(CH)*8) + READOCTALORHEX(8)
          SWITCHON CH INTO
              $( CASE 'T': RESULTIS '*T'
                 CASE 'S': RESULTIS '*S'
                 CASE 'N': RESULTIS '*N'
                 CASE 'E': RESULTIS '*E'
                 CASE 'B': RESULTIS '*B'
                 CASE 'P': RESULTIS '*P'
                 CASE 'C': RESULTIS '*C'
                 CASE 'X': RESULTIS READOCTALORHEX(16)
                 DEFAULT:  RESULTIS CHBUF%(CHCOUNT&63)
              $)
       $)
$)             

AND READOCTALORHEX(RADIX) = VALOF
    $( LET ANSWER = 0
       FOR J = 1 TO 2 DO
          $( LET VALCH = VALUE(VALOF $( RCH(); RESULTIS CH $) )
             IF VALCH > RADIX DO SYNREPORT("Bad char constant")
             ANSWER:=ANSWER*RADIX + VALCH
          $)
       RESULTIS ANSWER
    $)

AND FORMTREE() =  VALOF
$(  LET CB = VEC 63/BYTESPERWORD
    LET NT = VEC NAMETABLESIZE
    LET R = ?
  
    CHBUF := CB // Empty chbuf
    FOR I = 0 TO 63 DO CHBUF%I := 0

    NAMETABLE := NT // clear hash table
    FOR I = 0 TO NAMETABLESIZE DO NAMETABLE!I := 0

    CHCOUNT, SKIPTAG, GETP, REPORTCOUNT := 0,0,0,0

    RCH(); IF CH=ENDSTREAMCH RESULTIS 0

    DECLSYSWORDS() // put in reserved words

    REC.P1, REC.P2, REC.L := LEVEL1(), LEVEL2(), L

 L: NEXTSYMB()
    TEST SYMB=S.SECTION THEN
       $( LET A = ?
          NEXTSYMB(); A:=RBEXP()
          UNLESS H1!A=S.STRING SYNREPORT("Bad section name")
          R := LIST3(S.SECTION, A, RDBLOCKBODY())
       $)
    ELSE  R := RDBLOCKBODY()

    UNLESS SYMB=S.END DO SYNREPORT("Incorrect termination")

    FOR I = 0 TO NAMETABLESIZE DO // clear hash chains for TRANS
       $( LET P = NAMETABLE!I
          UNTIL P=0 DO
            $( LET T = H2!P
               H2!P := 0
               P := T
            $)
       $)

    RESULTIS R        
$)

AND ABORT(S) BE 
$( SELECTOUTPUT(OCODE) // delete a partial output file
   REMOVEOUTPUT()
   SELECTOUTPUT(CON)
   WRITEF("Aborting. %s.*n*n", S)
   FINISH
$)

AND SYNREPORT(S, A) BE
$( REPORTCOUNT := REPORTCOUNT + 1
   IF REPORTCOUNT = REPORTMAX THEN
                     WRITES("*NFurther errors suppressed.*N*N")
   IF REPORTCOUNT < REPORTMAX THEN
       $( WRITEF("*NSyntax error:    %F", S, A)
          WRITEF(".*NNear line %N ", LINECOUNT)
          IF GETP THEN WRITEF("of %s", @(H2!(H5!GETP)))
          WRITES("*N...")
          $( LET P = CHCOUNT-63
             $( LET K = CHBUF%(P&63)
                UNLESS K=0 DO WRCH(K)
                P := P+1
             $) REPEATUNTIL P=CHCOUNT
          $)
          NEWLINE() 
       $)
   NLPENDING := FALSE

   UNTIL SYMB=S.LSECT | SYMB=S.RSECT |
         SYMB=S.LET | SYMB=S.AND |
         SYMB=S.END | NLPENDING DO NEXTSYMB()
   LONGJUMP(REC.P1, REC.P2, REC.L)   
$)


.

//   SYN
SECTION "SYN"

GET "COMPHDR"

LET NEWVEC(N) = VALOF
    $( LET A = TREEP
       TREEP := TREEP + N + 1;
       IF TREEP>TREETOP DO ABORT("Out of workspace")
       RESULTIS A  $)

AND LIST2(X, Y) = VALOF
    $( LET P = NEWVEC(1)
       P!0, P!1 := X, Y
       RESULTIS P   $)

AND LIST3(X, Y, Z) = VALOF
    $( LET P = NEWVEC(2)
       MEMCPY(@X, P, 3)
       RESULTIS P     $)

AND LIST4(X, Y, Z, T) = VALOF
    $( LET P = NEWVEC(3)
       MEMCPY(@X, P, 4)
       RESULTIS P   $)

AND LIST5(X, Y, Z, T, U) = VALOF
    $( LET P = NEWVEC(4)
       MEMCPY(@X, P, 5)
       RESULTIS P   $)

AND LIST6(X, Y, Z, T, U, V) = VALOF
    $( LET P = NEWVEC(5)
       MEMCPY(@X, P, 6)
       RESULTIS P  $)

AND RDBLOCKBODY() = VALOF
$(1 LET P1, P2, L = REC.P1, REC.P2, REC.L
    LET A = 0

    REC.P1, REC.P2, REC.L := LEVEL1(), LEVEL2(), RECOVER

    IGNORE(S.SEMICOLON)

    SWITCHON SYMB INTO
    $(S CASE S.MANIFEST:
        CASE S.STATIC:
        CASE S.GLOBAL:
            $(  LET OP = SYMB
                NEXTSYMB()
                A := RDSECT(RDCDEFS)
                A := LIST3(OP, A, RDBLOCKBODY())
                ENDCASE  $)


        CASE S.LET: NEXTSYMB()
                    A := RDEF()
           RECOVER: WHILE SYMB=S.AND DO
                       $( NEXTSYMB()
                          A := LIST3(S.AND, A, RDEF())  $)
                    A := LIST3(S.LET, A, RDBLOCKBODY())
                    ENDCASE

        CASE S.NEEDS: NEXTSYMB()
                      A := RBEXP()
                      UNLESS H1!A = S.STRING THEN
                                          SYNREPORT("Bad NEEDS")
                      A := LIST3(S.NEEDS, A, RDBLOCKBODY())
                      ENDCASE

        DEFAULT: A := RDSEQ()

                 UNLESS SYMB=S.RSECT | SYMB=S.END DO
                          SYNREPORT("Error in command")

        CASE S.RSECT: CASE S.END:
    $)S

    REC.P1, REC.P2, REC.L := P1, P2, L
    RESULTIS A   $)1

AND RDSEQ() = VALOF
$( LET A = ?
   IGNORE(S.SEMICOLON)
   A := RCOM()
   IF SYMB=S.RSECT | SYMB=S.END RESULTIS A
   RESULTIS LIST3(S.SEQ, A, RDSEQ())   
$)

AND RDCDEFS() = VALOF
$( LET A, B = ?, ?
   LET PTR = @A
   LET P1, P2, L = REC.P1, REC.P2, REC.L
   REC.P1, REC.P2, REC.L := LEVEL1(), LEVEL2(), RECOVER

   $( B := RNAME()
      TEST SYMB=S.EQ | SYMB=S.COLON THEN NEXTSYMB()
                                    ELSE SYNREPORT("Bad declaration")
      !PTR := LIST3(0, B, REXP(0))
      PTR := @H1!(!PTR)
RECOVER: 
      IGNORE(S.SEMICOLON) 
   $) REPEATWHILE SYMB=S.NAME

      REC.P1, REC.P2, REC.L  :=  P1, P2,L
      RESULTIS A  
$)

AND RDSECT(R) = VALOF
$(  LET TAG, A = WORDNODE, ?
    CHECKFOR(S.LSECT, "'$(' expected")
    A := R()
    UNLESS SYMB=S.RSECT DO SYNREPORT("'$)' expected")
    TEST TAG=WORDNODE
         THEN NEXTSYMB()
         ELSE IF WORDNODE=NULLTAG DO
                   $( SYMB := 0
                      SYNREPORT("Untagged '$)' mismatch")  $)
    RESULTIS A   
$)


AND RNAMELIST() = VALOF
$(  LET A = RNAME()
    UNLESS SYMB=S.COMMA RESULTIS A
    NEXTSYMB()
    RESULTIS LIST3(S.COMMA, A, RNAMELIST())   
$)


AND RNAME() = VALOF
$( LET A = WORDNODE
   CHECKFOR(S.NAME, "Name expected")
   RESULTIS A
$)

AND IGNORE(ITEM) BE IF SYMB=ITEM DO NEXTSYMB()

AND CHECKFOR(ITEM, N) BE
$( UNLESS SYMB=ITEM DO SYNREPORT(N)
   NEXTSYMB()
$)

AND RBEXP() = VALOF
$(1 LET A, OP = ?, SYMB

    SWITCHON SYMB INTO

$(  DEFAULT: SYNREPORT("Error in expr")

    CASE S.QUERY:
        NEXTSYMB()
        RESULTIS TABLE S.QUERY
// Use one static node for QUERY, (No parameters).

    CASE S.TRUE:
    CASE S.FALSE:
    CASE S.NAME:
    CASE S.STRING:
        A := WORDNODE
        NEXTSYMB()
        RESULTIS A

    CASE S.NUMBER:
// There are enough constant zeros in the average program to justify
// having a static node for number 0.
        A := DECVAL=0 -> (TABLE S.NUMBER, 0),
                         LIST2(S.NUMBER, DECVAL)
        NEXTSYMB()
        RESULTIS A

    CASE S.LPAREN:
        NEXTSYMB()
        A := REXP(0)
        CHECKFOR(S.RPAREN, "')' missing")
        RESULTIS A

    CASE S.VALOF:
        NEXTSYMB()
        RESULTIS LIST2(S.VALOF, RCOM())

    CASE S.VECAP: OP := S.RV
    CASE S.LV:
    CASE S.RV: NEXTSYMB(); RESULTIS LIST2(OP, REXP(37))

    CASE S.PLUS: NEXTSYMB(); RESULTIS REXP(34)

    CASE S.MINUS: NEXTSYMB()
                  A := REXP(34)
                  TEST H1!A=S.NUMBER
                      THEN H2!A := - H2!A
                      ELSE A := LIST2(S.NEG, A)
                  RESULTIS A

    CASE S.NOT: NEXTSYMB(); RESULTIS LIST2(S.NOT, REXP(24))

    CASE S.ABS: NEXTSYMB(); RESULTIS LIST2(S.ABS, REXP(35))

    CASE S.TABLE: $( LET PTR = @A // Build a LISP list for table
                     $( NEXTSYMB()   // so TRN can calculate consts easily
                        !PTR := LIST2(REXP(0), 0)
                        PTR := @H2!(!PTR)
                     $) REPEATWHILE SYMB =S.COMMA
                  $)

                  RESULTIS LIST2(S.TABLE, A)   

    CASE S.SLCT:  $( NEXTSYMB()
                     A := LIST4(S.SLCT, REXP(0), 0, 0)
                     IF SYMB = S.COLON THEN
                         $( NEXTSYMB()
                            H3!A := REXP(0)
                            IF SYMB = S.COLON THEN 
                                $( NEXTSYMB()
                                   H4!A := REXP(0)
                                $)
                         $)
                     RESULTIS A
                  $)
$)1



AND REXP(N) = VALOF
$(1 LET A = RBEXP()

    LET B, C, P, Q = 0, 0, ?, ?

$(2 LET OP = SYMB

    IF NLPENDING RESULTIS A

    SWITCHON OP INTO

$(S DEFAULT: RESULTIS A

    CASE S.LPAREN: NEXTSYMB()
                   B := 0
                   UNLESS SYMB=S.RPAREN DO B := REXPLIST()
                   CHECKFOR(S.RPAREN, "')' missing")
                   A := LIST3(S.FNAP, A, B)
                   LOOP

    CASE S.BYTEAP: P := 36; GOTO LASSOC
    CASE S.OF:
    CASE S.VECAP:  P := 40; GOTO LASSOC

    CASE S.REM:CASE S.MULT:CASE S.DIV: P := 35; GOTO LASSOC

    CASE S.PLUS:CASE S.MINUS: P := 34; GOTO LASSOC

    CASE S.EQ:CASE S.NE:
    CASE S.LE:CASE S.GE:
    CASE S.LS:CASE S.GR:
        IF N>=30 RESULTIS A

        $(R NEXTSYMB()
            B := REXP(30)
            A := LIST3(OP, A, B)
            TEST C=0 THEN C :=  A
                     ELSE C := LIST3(S.LOGAND, C, A)
            A, OP := B, SYMB
        $)R REPEATWHILE S.LS<=OP<=S.NE

        A := C
        LOOP

    CASE S.LSHIFT:CASE S.RSHIFT: P, Q := 25, 30; GOTO DYADIC

    CASE S.LOGAND: P := 23; GOTO LASSOC

    CASE S.LOGOR:  P := 22; GOTO LASSOC

    CASE S.EQV:CASE S.NEQV: P := 21; GOTO LASSOC

    CASE S.COND:
            IF N>=13 RESULTIS A
            NEXTSYMB()
            B := REXP(0)
            CHECKFOR(S.COMMA, "Bad conditional expr")
            A := LIST4(S.COND, A, B, REXP(0))
            LOOP

    LASSOC: Q := P

    DYADIC: IF N>=P RESULTIS A
            NEXTSYMB()
            A := LIST3(OP, A, REXP(Q))
            LOOP
$)S
$)2 REPEAT
$)1

AND REXPLIST() = VALOF
    $(1 LET A = ?
        LET PTR = @A

        $( LET B = REXP(0)
           UNLESS SYMB=S.COMMA DO $( !PTR := B
                                     RESULTIS A  $)
           NEXTSYMB()
           !PTR := LIST3(S.COMMA, B, 0)
           PTR := @H3!(!PTR)  $) REPEAT
    $)1

AND RDEF() = VALOF
$(1 LET N = RNAMELIST()

    SWITCHON SYMB INTO

 $( CASE S.LPAREN:
      $( LET A = 0
         NEXTSYMB()
         UNLESS H1!N=S.NAME DO SYNREPORT("Name expected")
         IF SYMB=S.NAME DO A := RNAMELIST()
         CHECKFOR(S.RPAREN, "')' missing")

         IF SYMB=S.BE DO
            $( NEXTSYMB()
               RESULTIS LIST5(S.RTDEF, N, A, RCOM(), ?)  $)

         IF SYMB=S.EQ DO
            $( NEXTSYMB()
               RESULTIS LIST5(S.FNDEF, N, A, REXP(0), ?)  $)

         SYNREPORT("Bad proc heading")  
      $)

    DEFAULT: SYNREPORT("Bad declaration")

    CASE S.EQ:
         NEXTSYMB()
         IF SYMB=S.VEC DO
              $( NEXTSYMB()
                 UNLESS H1!N=S.NAME DO SYNREPORT("Name expected")
                 RESULTIS LIST3(S.VECDEF, N, REXP(0))  $)
         RESULTIS LIST3(S.VALDEF, N, REXPLIST())  $)1


AND RBCOM() = VALOF
$(1 LET A, B, OP = ?, ?, SYMB

    SWITCHON SYMB INTO
 $( DEFAULT: RESULTIS 0

    CASE S.NAME:CASE S.NUMBER:CASE S.STRING:
    CASE S.TRUE:CASE S.FALSE:
    CASE S.LV:CASE S.RV:CASE S.VECAP:
    CASE S.LPAREN:
            A := REXPLIST()

            IF SYMB=S.ASS  THEN
               $( OP := SYMB
                  NEXTSYMB()
                  RESULTIS LIST3(OP, A, REXPLIST())  $)

            IF SYMB=S.COLON DO
               $( UNLESS H1!A=S.NAME DO SYNREPORT("Unexpected ':'")
                  NEXTSYMB()
                  RESULTIS LIST4(S.COLON, A, RBCOM(), ?)  $)

            IF H1!A=S.FNAP DO
                 $( H1!A := S.RTAP
                    RESULTIS A  $)

            SYNREPORT("Error in command")
            RESULTIS A

    CASE S.GOTO:CASE S.RESULTIS:
            NEXTSYMB()
            RESULTIS LIST2(OP, REXP(0))

    CASE S.IF:CASE S.UNLESS:
    CASE S.WHILE:CASE S.UNTIL:
            NEXTSYMB()
            A := REXP(0)
            IGNORE(S.DO)
            RESULTIS LIST3(OP, A, RCOM())

    CASE S.TEST:
            NEXTSYMB()
            A := REXP(0)
            IGNORE(S.DO)
            B := RCOM()
            CHECKFOR(S.OR, "ELSE expected")
            RESULTIS LIST4(S.TEST, A, B, RCOM())

    CASE S.FOR:
        $(  LET I, J, K = 0, 0, 0
            NEXTSYMB()
            A := RNAME()
            CHECKFOR(S.EQ, "Bad FOR loop")
            I := REXP(0)
            CHECKFOR(S.TO, "TO expected")
            J := REXP(0)
            IF SYMB=S.BY DO $( NEXTSYMB()
                               K := REXP(0)  $)
            IGNORE(S.DO)
            RESULTIS LIST6(S.FOR, A, I, J, K, RCOM())  $)

    CASE S.LOOP:
    CASE S.BREAK:CASE S.RETURN:CASE S.FINISH:CASE S.ENDCASE:
            A := WORDNODE
            NEXTSYMB()
            RESULTIS A

    CASE S.SWITCHON:
            NEXTSYMB()
            A := REXP(0)
            CHECKFOR(S.INTO, "INTO expected")
            RESULTIS LIST3(S.SWITCHON, A, RDSECT(RDSEQ))

    CASE S.CASE:
            NEXTSYMB()
            A := REXP(0)
            CHECKFOR(S.COLON, "':' expected")
            RESULTIS LIST3(S.CASE, A, RBCOM())

    CASE S.DEFAULT:
            NEXTSYMB()
            CHECKFOR(S.COLON, "':' needed after DEFAULT")
            RESULTIS LIST2(S.DEFAULT, RBCOM())

    CASE S.LSECT:
            RESULTIS RDSECT(RDBLOCKBODY)   $)1


AND RCOM() = VALOF
$(1 LET A = RBCOM()

    IF A=0 DO SYNREPORT("Error in command")

    WHILE SYMB=S.REPEAT | SYMB=S.REPEATWHILE |
                          SYMB=S.REPEATUNTIL DO
          $( LET OP = SYMB
             NEXTSYMB()
             TEST OP=S.REPEAT
                 THEN A := LIST2(OP, A)
                 ELSE A := LIST3(OP, A, REXP(0))   $)

    RESULTIS A  $)1


.
//  TRN0
SECTION "TRN0"
GET "COMPHDR"

STATIC $( LOCALCOUNT=?; LEAFPROC=? $)

LET TRANS(X) BE
$( LET SW = ?

NEXT: 
   IF INTKEY() THEN ABORT("Interrupted")

   SW := FALSE
   IF X=0 RETURN

   SWITCHON H1!X INTO
  $( CASE S.LET:
      $( LET B = TREEP
         LET S = SSP
         LET SD = STKDEPTH
         LET CB = CASEB

         $( LET B1, S1, S2 = TREEP, ?, SSP
            DECLNAMES(H2!X)
            CHECKDISTINCT(B1)
            S1 := SSP
            SSP := S2
            TRANSDEF(H2!X)
            UNLESS SSP=S1 DO TRANSREPORT("Unbalanced declaration")
            X:=H3!X // Repeat for chains of LETs
         $)
            REPEATWHILE X & (H1!X=S.LET) // so that we deallocate
                                         // all vectors at once
         CASEB := -1    // switch not allowed now
         DECLLABELS(X)
         TRANS(X)	// then translate the rest
         STACKTO(SD)    // lose the vector space
         STKDEPTH, SSP := SD, S
         TREEP := B
         CASEB := CB
         RETURN   
      $)


    CASE S.STATIC:
    CASE S.GLOBAL:
    CASE S.MANIFEST:
      $( LET B = TREEP
         LET Y = H2!X

         UNTIL Y=0 DO SWITCHON H1!X INTO
            $( CASE S.STATIC:
                  $( LET M = NEXTPARAM()
                     LET T = H1!Y
                     ADDNAME(H2!Y, S.LABEL, M)
                     H1!Y := S.STATIC // So dumplits isn't confused
                     H3!Y := EVALCONST(H3!Y) // evaluate init in correct environment
                     ADDLIT(M, Y)
                     Y := T
                     ENDCASE
                  $)

               CASE S.GLOBAL:
                  $( LET GN = EVALCONST(H3!Y)
                     ADDNAME(H2!Y, S.GLOBAL, GN)
                     WRITE2(S.GLOBSYM, GN)
                     WRITESTRING(@H3!(H2!Y))
                     Y := H1!Y
                     ENDCASE
                  $)
          
               CASE S.MANIFEST:
                  $( ADDNAME(H2!Y, S.NUMBER, EVALCONST(H3!Y))
                     Y := H1!Y
                     ENDCASE
                  $)

            $)

         CHECKDISTINCT(B)
         DECLLABELS(H3!X)
         TRANS(H3!X)
         TREEP := B
         RETURN
      $)

    CASE S.NEEDS:
       $( LET N = VEC 5 // Buffer for filename
          PARSE(@H2!(H2!X), N) // Parse into CPM FCB format
          WRITE1(S.NEEDS) // Send the parsed filename out.
          FOR K = 0 TO 11 DO WRITE1(N%K)
          X := H3!X
          GOTO NEXT
       $)

    CASE S.ASS:
       ASSIGN(H2!X, H3!X)
       RETURN

    CASE S.RTAP:
        TRANSCALL(X)
        RETURN


    CASE S.GOTO:
        LOAD(H2!X)
        OUT2(S.LIMIY,STKDEPTH*2) // For stack fixup
	OUT1(S.GOTO)
        STOPFLOW()
        RETURN

    CASE S.COLON:
     $( COMPLAB(H4!X)
        OUT2(S.LIMHL, -STKDEPTH*2) // Used to fixup stack by GOTO code.
        X := H3!X
        GOTO NEXT
     $)

    CASE S.UNLESS: SW := TRUE
    CASE S.IF:
     $( LET L = COMISJUMP(H3!X)
        TEST L & (RESULT2 = STKDEPTH) THEN 
              JUMPCOND(H2!X, NOT SW, L, FALSE)
        ELSE
           $( L := NEXTPARAM()
              JUMPCOND(H2!X, SW, L, FALSE)
              TRANS(H3!X)
              COMPLAB(L)
           $)
        RETURN   
     $)

    CASE S.TEST:
     $( LET L, M, N = ?, ?, ?
        L := COMISJUMP(H3!X)
        IF L & (RESULT2 = STKDEPTH) THEN
           $( JUMPCOND(H2!X, TRUE, L, FALSE)
              TRANS(H4!X)
              RETURN
           $)

        L := COMISJUMP(H4!X)
        IF L & (RESULT2=STKDEPTH) THEN
           $( JUMPCOND(H2!X, FALSE, L, FALSE)
              TRANS(H3!X)
              RETURN
           $)

        L, M, N  := NEXTPARAM(), NEXTPARAM(), ?
        JUMPCOND(H2!X, FALSE, L, FALSE)
        TRANS(H3!X)
        N := COMPJUMP(M)
        COMPLAB(L)
        TRANS(H4!X)
        IF N THEN COMPLAB(M)
        RETURN   
     $)

    CASE S.LOOP:
    CASE S.BREAK:
    CASE S.ENDCASE:
     $( LET L = COMISJUMP(X)
        TEST L THEN
             $( STACKTO(RESULT2)
                COMPJUMP(L)
             $)
        ELSE TRANSREPORT(RESULT2)
        RETURN
     $)

    CASE S.RESULTIS:
        IF RESULTLABEL<0 DO $( TRANSREPORT("Illegal RESULTIS")
                               RETURN $)
        LOAD(H2!X) // Get the expr
        IF RESULTLABEL ~=0 THEN // Normal Result, jump round
           $( STACKTO(RESULTSTACK)
              COMPJUMP(RESULTLABEL)
              RETURN
           $)
        // Drop through for function return special case (RESULTLABEL=0)

    CASE S.RETURN:
        STACKTO(0)
        COMPRETURN()
        RETURN

    CASE S.FINISH:
        OUT1(S.FINISH)
        STOPFLOW()
        RETURN

    CASE S.WHILE: SW := TRUE
    CASE S.UNTIL:
     $( LET L, M = NEXTPARAM(), NEXTPARAM()
        LET BL, LL = BREAKLABEL, LOOPLABEL
        LET LPS = LOOPSTACK

        BREAKLABEL, LOOPLABEL := 0, M
        LOOPSTACK := STKDEPTH

        COMPJUMP(M)
        COMPLAB(L)
        TRANS(H3!X)
        COMPLAB(M)
        JUMPCOND(H2!X, SW, L, FALSE)
        UNLESS BREAKLABEL=0 DO COMPLAB(BREAKLABEL)

        LOOPSTACK:= LPS
        BREAKLABEL, LOOPLABEL := BL, LL
        RETURN   $)

    CASE S.REPEATWHILE: SW := TRUE
    CASE S.REPEATUNTIL:
    CASE S.REPEAT:
     $( LET L, BL, LL = NEXTPARAM(), BREAKLABEL, LOOPLABEL
        LET LPS = LOOPSTACK

        LOOPSTACK := STKDEPTH
        BREAKLABEL, LOOPLABEL := 0, 0
        COMPLAB(L)
        TEST H1!X=S.REPEAT
            THEN $( LOOPLABEL := L
                    TRANS(H2!X)
                    COMPJUMP(L)  $)
              OR $( TRANS(H2!X)
                    UNLESS LOOPLABEL=0 DO COMPLAB(LOOPLABEL)
                    JUMPCOND(H3!X, SW, L, FALSE)  $)
        UNLESS BREAKLABEL=0 DO COMPLAB(BREAKLABEL)

        LOOPSTACK := LPS
        BREAKLABEL, LOOPLABEL := BL, LL
        RETURN   $)

    CASE S.CASE:
     $( LET L = NEXTPARAM()
        COMPLAB(L)
        TEST CASEB<0 THEN
                     $( TRANSREPORT("Illegal CASE")
                        X := H3!X $)
        ELSE
          $( LET P = CASEB // Pointer to chain of cases
             LET K = EVALCONST(H2!X) // get case constant
             UNTIL P = 0 DO // Chain down the list
             $( IF K = H2!P THEN $( TRANSREPORT("Two cases with same constant")
                                    BREAK
                                 $)
                P := H1!P // Next one
             $)
             H1!X := CASEB
             CASEB := X // put this one on the list
             H2!X := K  // replace expr by constant
             P := H3!X // See if the next instruction is another CASE
             H3!X := L // label kept here
             X := P
          $)
             REPEATWHILE (X & (H1!X=S.CASE)) // Re-use the same label if so.

        GOTO NEXT
     $)

    CASE S.DEFAULT:
        TEST CASEB<0 DO TRANSREPORT("Illegal DEFAULT")
        ELSE
        $( UNLESS DEFAULTLABEL=0 DO TRANSREPORT("Duplicate DEFAULT")
           DEFAULTLABEL := NEXTPARAM()
           COMPLAB(DEFAULTLABEL)
        $)
        X := H2!X
        GOTO NEXT

    CASE S.SWITCHON:
      $( LET B, DL = CASEB, DEFAULTLABEL
         LET ECL, CSK = ENDCASELABEL, CASESTACK
         LET L, L1 = NEXTPARAM(), NEXTPARAM()

         COMPJUMP(L)

         CASESTACK := STKDEPTH
         ENDCASELABEL, DEFAULTLABEL, CASEB := 0, 0, 0

         TRANS(H3!X)

         UNLESS COMPJUMP(L1) | (DEFAULTLABEL=0) DO L1 := 0
         IF DEFAULTLABEL=0 DO DEFAULTLABEL := L1

         COMPLAB(L)
         LOAD(H2!X)

         $( LET P, COUNT = CASEB, 0
            UNTIL P = 0 DO
               $( P := H1!P // Count no of cases
                  COUNT := COUNT + 1
               $)

            IF COUNT > 255 THEN TRANSREPORT("Too many cases")
            OUTB(S.LIMB, COUNT)

            TEST COUNT THEN OUT1(S.SWITCHON)
                       ELSE COMPJUMP(DEFAULTLABEL)
                 // zero cases is pathalogical
         $)

         UNTIL CASEB = 0 DO // Produce the switch table
           $( OUT2(S.DW, H2!CASEB)
              OUT2(S.DWLAB, H3!CASEB)
              CASEB := H1!CASEB
           $)
         OUT2(S.DWLAB, DEFAULTLABEL)

         STOPFLOW()

         IF ENDCASELABEL THEN COMPLAB(ENDCASELABEL)
         IF L1 THEN COMPLAB(L1)
         ENDCASELABEL, CASESTACK := ECL, CSK
         CASEB, DEFAULTLABEL := B, DL         
         RETURN
      $)

    CASE S.FOR:
      $( LET B = TREEP
         LET L, M, M1 = NEXTPARAM(), NEXTPARAM(), NEXTPARAM()
         LET BL, LL = BREAKLABEL, LOOPLABEL
         LET LPS = LOOPSTACK
         LET STEP = 1
         LET CONST = CONSTANT(H4!X)
         LET LIMIT = RESULT2
         LET S = SSP
         BREAKLABEL, LOOPLABEL := NEXTPARAM(), 0

         UNLESS H5!X=0 DO STEP := EVALCONST(H5!X)
         ADDNAME(H2!X, S.LOCAL, S)
         SSP := SSP + 1

         UNLESS CONST DO
            $( LOAD(H4!X) // loop limit onto the stack
               OUT1(S.PUSHHL)
               STKDEPTH := STKDEPTH + 1
            $)

         LOOPSTACK := STKDEPTH
  
         LOAD(H3!X) // initial counter
         COMPJUMP(L)

         DECLLABELS(H6!X)
         COMPLAB(M)
         OUT2(S.JPM,BREAKLABEL)
         COMPLAB(M1)
         TRANS(H6!X)
         UNLESS LOOPLABEL=0 DO COMPLAB(LOOPLABEL)
         LOAD(H2!X) // Count var
         ADDCONST(STEP)

         COMPLAB(L)
         OUTB(S.STLIX, S*2)
         OUTB(S.STHIX, (S*2)+1)
         TEST CONST THEN    OUT2(S.LIMDE, LIMIT)
                    ELSE $( OUT1(S.POPDE)
                            OUT1(S.PUSHDE) 
                         $) // now have limit in DE, count in HL
         OUT1(S.ORA)    // clear carry
         OUT1(S.MINUS)  // condition flags
         TEST STEP > 0 THEN
             $( OUT2(S.JPZ,M1)  // This lot and the test at M
                OUT2(S.JPPE,M)  // does signed hl < de
             $)                      // or hl > de depending on step
         ELSE   OUT2(S.JPPO,M)

         OUT2(S.JPM,M1)
         COMPLAB(BREAKLABEL)
         BREAKLABEL, LOOPLABEL, SSP := BL, LL, S
         LOOPSTACK := LPS
         UNLESS CONST DO
             $( STKDEPTH := STKDEPTH - 1
                OUT1(S.POPHL) // Lose the limit from the stack
             $)
         TREEP := B  
         RETURN
      $)

    CASE S.SEQ:
        TRANS(H2!X)
        X := H3!X
        GOTO NEXT 
   $)
$)

AND DECLNAMES(X) BE UNLESS X=0 SWITCHON H1!X INTO
     $(  CASE S.VECDEF: CASE S.VALDEF:
               DECLDYN(H2!X)
               RETURN

         CASE S.RTDEF: CASE S.FNDEF:
               H5!X := NEXTPARAM()
               DECLSTAT(X, H2!X, H5!X)
               RETURN

         CASE S.AND:
               DECLNAMES(H2!X)
               DECLNAMES(H3!X)
               RETURN    
     $)


AND DECLDYN(X) BE UNLESS X=0 DO
$( WHILE H1!X=S.COMMA DO
      $( ADDNAME(H2!X, S.LOCAL, SSP)
         SSP := SSP + 1
         X := H3!X   
      $)
   ADDNAME(X, S.LOCAL, SSP)
   SSP := SSP+1
$)

AND DECLSTAT(P, X, L) BE
$( TEST CELLWITHNAME(X) = S.GLOBAL DO
       $( LET N = RESULT2
          ADDNAME(X, S.GLOBAL, N)
          WRITE2(S.GORG, N)
          WRITE2(S.DWLAB, L)
       $)
   ELSE
       $( LET M = NEXTPARAM()
          ADDNAME(X, S.LABEL, M)
          ADDLIT(M, P)
       $)
 $)


AND DECLLABELS(X) BE
$( LET B = TREEP
   SCANLABELS(X)
   CHECKDISTINCT(B)
$)



AND SCANLABELS(X) BE UNLESS X=0 SWITCHON H1!X INTO
$( DEFAULT: RETURN

   CASE S.COLON:
        H4!X := NEXTPARAM()
        DECLSTAT(X, H2!X, H4!X)

   CASE S.IF: CASE S.UNLESS: CASE S.WHILE: CASE S.UNTIL:
   CASE S.SWITCHON: CASE S.CASE: CASE S.NEEDS:
        SCANLABELS(H3!X)
        RETURN

   CASE S.SEQ:
        SCANLABELS(H3!X)

   CASE S.REPEAT:
   CASE S.REPEATWHILE: CASE S.REPEATUNTIL: CASE S.DEFAULT:
        SCANLABELS(H2!X)
        RETURN

   CASE S.TEST:
        SCANLABELS(H3!X)
        SCANLABELS(H4!X)
        RETURN    
$)


AND TRANSDEF(X) BE
$( TRANSDYNDEFS(X)
   IF STATDEFS(X) DO
      $( LET L, CP, N = NEXTPARAM(), CURPROC, ?
         LET BL, LL = BREAKLABEL, LOOPLABEL
         LET RL, CB = RESULTLABEL, CASEB
         LET ECL = ENDCASELABEL
         LET S, SD, DP = SSP, STKDEPTH, DVECP
         LET SFS, ASSP = SFSIZE, ARGSSP
         N := COMPJUMP(L)
         TRANSSTATDEFS(X)
         BREAKLABEL, LOOPLABEL := BL, LL
         RESULTLABEL, CASEB := RL, CB
         ENDCASELABEL := ECL
         CURPROC := CP
         SSP, STKDEPTH, DVECP := S, SD, DP
         SFSIZE, ARGSSP := SFS, ASSP
         IF N THEN COMPLAB(L)  
      $)
$)

AND TRANSDYNDEFS(X) BE SWITCHON H1!X INTO
$( CASE S.AND:
        TRANSDYNDEFS(H2!X)
        TRANSDYNDEFS(H3!X)
        RETURN

   CASE S.VECDEF:
        $( LET SIZE = 1 + EVALCONST(H3!X)
           STKDEPTH := STKDEPTH + SIZE
           OUT2(S.LIMHL, -SIZE*2)
           OUT1(S.VEC)
           OUTB(S.STLIX, SSP*2)
           OUTB(S.STHIX, (SSP*2)+1)
           CACHE.MODE, CACHE.VAL := S.LOCAL, SSP 
           SSP := SSP + 1
           RETURN
        $)

   CASE S.VALDEF: 
            LOADLIST(H3!X, @SSP)
   DEFAULT: RETURN
$)

AND TRANSSTATDEFS(X) BE SWITCHON H1!X INTO
$( CASE S.AND:
        TRANSSTATDEFS(H2!X)
        TRANSSTATDEFS(H3!X)
        RETURN

   CASE S.FNDEF: CASE S.RTDEF:
         LOOPLABEL, RESULTLABEL := -1, -1
         CASEB, ENDCASELABEL := -1, -1

         CURPROC := (H2!X)+H3
           
         LOCALCOUNT := LENLIST(H3!X)
         SFSIZE := LOCALCOUNT
         LEAFPROC := TRUE
         COUNTLOCALS(H4!X)
         IF SFSIZE>64 THEN TRANSREPORT("Too many locals")
         IF LEAFPROC THEN SFSIZE := 0 // don't need stack frame 
                                      // for leaf procedure  

         ARGSSP, STKDEPTH := 0, 0
         SSP := -SFSIZE // Start the stack frame at most neg offset

         DVECP := TREEP
         DECLDYN(H3!X) // Declare the argument list
         CHECKDISTINCT(DVECP)

         COMPLAB(H5!X)
         BUMPP(SFSIZE)

         TEST H1!X=S.RTDEF
            THEN $( DECLLABELS(H4!X) // Routine Defn
                    TRANS(H4!X)
                 $)
            ELSE $( LET E=H4!X // Function Defn
                    TEST H1!E = S.VALOF THEN // special case for 
                       $( RESULTLABEL := 0   // Fn = VALOF.....
                          DECLLABELS(H2!E)
                          TRANS(H2!E)
                       $)
                    ELSE LOAD(E) // Ordinary case.
                 $)

         COMPRETURN()

         TREEP := DVECP

      DEFAULT: RETURN   
$)

AND STATDEFS(X) = H1!X=S.FNDEF | H1!X=S.RTDEF -> TRUE,
                  H1!X NE S.AND -> FALSE,
                  STATDEFS(H2!X) -> TRUE,
                  STATDEFS(H3!X)

AND LENLIST(X) = VALOF
$( LET ANS = 1
   IF X=0 RESULTIS 0
   WHILE H1!X=S.COMMA DO
   $( X := H3!X
      ANS := ANS+1
   $)
   RESULTIS ANS
$)

AND COUNTDECLS(X) BE
$( SWITCHON H1!X INTO
   $( CASE S.VALDEF: CASE S.VECDEF:
      LOCALCOUNT := LOCALCOUNT + LENLIST(H2!X)
      RETURN

      CASE S.AND:
      COUNTDECLS(H2!X)
      COUNTDECLS(H3!X)
      RETURN

   $)
$)

AND COUNTLOCALS(X) BE
$( IF X=0 RETURN
   SWITCHON H1!X INTO
      $( CASE S.LET:

         $( LET OCOUNT = LOCALCOUNT
            COUNTDECLS(H2!X)
            COUNTLOCALS(H2!X)
            COUNTLOCALS(H3!X)
            IF SFSIZE<LOCALCOUNT THEN SFSIZE := LOCALCOUNT 
            LOCALCOUNT := OCOUNT
            RETURN
         $)

         CASE S.RTAP: CASE S.FNAP:

         LEAFPROC := FALSE
         COUNTLOCALS(H2!X)

         CASE S.STATIC: CASE S.GLOBAL: CASE S.MANIFEST: CASE S.NEEDS:
         CASE S.COLON: CASE S.VALDEF:

         COUNTLOCALS(H3!X)
         RETURN

         CASE S.TEST: CASE S.COND:

         COUNTLOCALS(H4!X)
 
         CASE S.ASS: CASE S.IF: CASE S.UNLESS:
         CASE S.WHILE:  CASE S.UNTIL: CASE S.REPEATWHILE:
         CASE S.REPEATUNTIL: CASE S.CASE: CASE S.SWITCHON: CASE S.SEQ:
         CASE S.REM: CASE S.LS: CASE S.GR: CASE S.LE: CASE S.GE: CASE S.EQ:
         CASE S.NE: CASE S.RSHIFT: CASE S.LOGAND: CASE S.LOGOR: CASE S.EQV:
         CASE S.NEQV: CASE S.PLUS: CASE S.MINUS: CASE S.MULT: CASE S.DIV:
         CASE S.LSHIFT: CASE S.VECAP: CASE S.BYTEAP:  CASE S.OF:
         CASE S.COMMA: CASE S.AND:

         COUNTLOCALS(H3!X) 

         CASE S.GOTO: CASE S.RESULTIS: CASE S.REPEAT: CASE S.DEFAULT:
         CASE S.NEG:  CASE S.ABS: CASE S.NOT: CASE S.RV: CASE S.LV:
         CASE S.VALOF:

         COUNTLOCALS(H2!X)

         RETURN      

         CASE S.FOR:

         LOCALCOUNT := LOCALCOUNT+1
         IF SFSIZE<LOCALCOUNT THEN SFSIZE := LOCALCOUNT
         COUNTLOCALS(H3!X)
         COUNTLOCALS(H4!X)
         COUNTLOCALS(H5!X)
         COUNTLOCALS(H6!X)
         LOCALCOUNT := LOCALCOUNT-1
         RETURN

      $)
$)
 .


//TRN1

SECTION "TRN1"
GET "COMPHDR"

// expressions.....

// Load the expression in X in HL, don't save DE
// Check for a constant expr here , but not sub-exprs (in general)
LET LOAD(X) BE TEST CONSTANT(X) THEN LOADCONST(RESULT2)
                                ELSE LOADHL(X,FALSE)

AND SIMPLEOP(O) = O=S.STRING | O=S.FALSE | O=S.QUERY |
                  O=S.TRUE | O=S.NAME | O=S.NUMBER | O=S.TABLE -> TRUE,FALSE

AND LOADLR(X) BE
$( TEST SIMPLEOP(H1!(H3!X)) THEN // Get HL first to avoid saving DE
        $( LOADHL(H2!X, FALSE)
           LOADDE(H3!X, TRUE)
        $)
   ELSE
        $( LOADDE(H3!X, FALSE)
           LOADHL(H2!X, TRUE)
        $)
$)

AND LOADHL(X,SAVE) BE
$( LET OP = H1!X

   SWITCHON OP INTO
     $( CASE S.REM:
        CASE S.LS:
        CASE S.GR:
        CASE S.LE:
        CASE S.GE:
        CASE S.EQ:
        CASE S.NE:
        CASE S.RSHIFT:
        CASE S.LOGAND:
        CASE S.LOGOR:
        CASE S.EQV:
        CASE S.NEQV:
        DYAD:          PUSHDE(SAVE)
                       LOADLR(X) // get Left and Right into HL and DE
                       IF OP=S.MINUS THEN OUT1(S.ORA)
                       OUT1(OP)
                       POPDE(SAVE)
                       IF OP=S.GE | OP=S.LS |
                          OP=S.LE | OP=S.GR THEN OUT1(S.SUBHH)
                                // Convert carry to hl=0000,FFFF
                       RETURN

        CASE S.PLUS:   SWAPROUND(X)
        CASE S.MINUS:  IF CONSTANT(H3!X) THEN
                             $( LET C = OP=S.PLUS -> RESULT2, -RESULT2
                                LOADHL(H2!X, SAVE)
                                ADDCONST(C)
                                RETURN
                             $)
                       GOTO DYAD


        CASE S.MULT:   SWAPROUND(X)
        CASE S.DIV:    IF CONSTANT(H3!X) THEN
                         $( LET L = VALOF
                            $( LET P = 0         // Return log2 N or zero 
                                                 // if N is not integer power
                               IF RESULT2 <= 0 RESULTIS 0
                               UNTIL (RESULT2&1) = 1 DO 
                                     $( P := P + 1
                                        RESULT2 := RESULT2 >> 1 
                                     $)      
                               RESULTIS RESULT2=1 -> P, 0
                            $)

                            IF 0<L<=(OP=S.MULT -> 10,4) THEN
                              $( LOADHL(H2!X, SAVE)
                                 FOR I = 1 TO L DO 
                                      OUT1(OP=S.MULT -> S.ADDHH, S.TWODIV)
                                 RETURN
                              $)
                         $)
                       GOTO DYAD

        CASE S.LSHIFT: IF CONSTANT(H3!X) THEN
                         $( LET S = RESULT2 & #X1F // Short out big shifts
                            LOADHL(H2!X, SAVE)
                            FOR I = 1 TO S DO OUT1(S.ADDHH)
                            RETURN
                         $)
                        GOTO DYAD

        CASE S.VECAP:
        CASE S.RV:     PUSHDE(SAVE) // RV corrupts DE as well
                       LOADLV(X, FALSE)
                       OUT1(S.RV)
                       POPDE(SAVE)
                       RETURN

        CASE S.BYTEAP: IF BYTEADDR(X,SAVE) THEN
                         $( OUT1(S.LDBYTE)
                            OUTB(S.LDHIM,0)
                            RETURN
                         $)
                       GOTO DYAD

        CASE S.NEG:
	CASE S.ABS:
        CASE S.NOT:    LOADHL(H2!X,SAVE)
                       OUT1(OP)
                       RETURN


        CASE S.LV:     LOADLV(H2!X,SAVE)
                       RETURN
        CASE S.TRUE:   LOADCONST(TRUE)
                       RETURN
        CASE S.FALSE:  LOADCONST(FALSE)
        CASE S.QUERY:  RETURN


        CASE S.NUMBER: LOADCONST(H2!X)
                       RETURN

        CASE S.TABLE:
        CASE S.STRING:
         $( LET L = NEXTPARAM()
            OUT2(S.LABADDR,L)
            ADDLIT(L, X)
            RETURN
         $)

        CASE S.SLCT:  LOADCONST(EVALCONST(X))
                      RETURN

        CASE S.OF:    IF TRANSOF(X, SAVE) THEN
                        $( LOADCONST(0)
                           OUT1(S.SKIPZ)
                           OUT1(S.INCHL)
                        $)
                      RETURN

        CASE S.NAME:
         $( LET M = TRANSNAME(X)
            // May already be in HL
            IF CACHE.MODE = M & CACHE.VAL = RESULT2 RETURN 

            SWITCHON M INTO
            $( CASE S.LOCAL:  OUTB(S.LDLIX, RESULT2*2)
                              OUTB(S.LDHIX, (RESULT2*2)+1)
                              ENDCASE

               CASE S.GLOBAL: OUT2(S.LDHLGLB, RESULT2)
                              ENDCASE

               CASE S.LABEL:  OUT2(S.LDHLLAB, RESULT2)
                              ENDCASE

               CASE S.NUMBER: LOADCONST(RESULT2)
               DEFAULT:       RETURN
            $)
            CACHE.MODE, CACHE.VAL := M, RESULT2
            RETURN
         $)

        CASE S.VALOF:
         $( LET RL, RS = RESULTLABEL, RESULTSTACK
            LET B = TREEP
            DECLLABELS(H2!X)
            RESULTLABEL := NEXTPARAM()
            PUSHDE(SAVE)
            RESULTSTACK := STKDEPTH
            TRANS(H2!X)
            COMPLAB(RESULTLABEL)
            POPDE(SAVE)
            TREEP := B
            RESULTLABEL, RESULTSTACK := RL, RS
            RETURN  $)


        CASE S.FNAP:
         $( PUSHDE(SAVE)
            TRANSCALL(X)
            POPDE(SAVE)
            RETURN   $)

        CASE S.COND:
         $( LET L, M = NEXTPARAM(), NEXTPARAM()
            JUMPCOND(H2!X, FALSE, M, SAVE)
            LOADHL(H3!X,SAVE)
            COMPJUMP(L)
            COMPLAB(M)
            LOADHL(H4!X,SAVE)
            COMPLAB(L)
            RETURN   $)

     $)
$)

AND LOADCONST(N) BE
$( IF CACHE.MODE = S.NUMBER & CACHE.VAL = N RETURN
   OUT2(S.LIMHL, N)
   CACHE.MODE := S.NUMBER
   CACHE.VAL  := N
$)

AND SWAPROUND(X) BE
$( LET T = ?
   IF CONSTANT(H2!X) THEN
       $( T := H2!X
          H2!X := H3!X
          H3!X := T
       $)
$)

AND LOADLV(X, SAVE) BE 
$( SWITCHON H1!X INTO
   $( DEFAULT: TRANSREPORT("Cannot take address of expr")
               RETURN

        CASE S.NAME:
            $( SWITCHON TRANSNAME(X) INTO
               $( CASE S.LOCAL:  OUT2(S.LIMBC, RESULT2*2)
                                 OUT1(S.LOCADDR)
                                 RETURN

                  CASE S.GLOBAL: OUT2(S.GLBADDR, RESULT2)
                                 RETURN

                  CASE S.LABEL:  OUT2(S.LABADDR, RESULT2)
                                 RETURN

                  CASE S.NUMBER: TRANSREPORT("Cannot take addr of %s", X)
                  DEFAULT:       RETURN
               $)
            $)

        CASE S.RV:
            LOADHL(H2!X,SAVE)
            RETURN

        CASE S.VECAP:
         $( H1!X := S.PLUS
            LOADHL(X,SAVE)
            H1!X := S.VECAP
            RETURN   $)  
   $)
$)

AND LOADDE(X, SAVE) BE
// Load DE with expression
$( SWITCHON H1!X INTO
   $(   CASE S.TRUE:   OUT2(S.LIMDE,TRUE)
                       RETURN
        CASE S.FALSE:  OUT2(S.LIMDE,FALSE)
                       RETURN

        CASE S.NUMBER: OUT2(S.LIMDE,H2!X)
        CASE S.QUERY:  RETURN

        CASE S.RV:     // Need to load RV into DE a lot
        CASE S.VECAP:  // hence this hack
             IF SAVE THEN 
                 $( OUT1(S.PUSHHL)
                    STKDEPTH := STKDEPTH+1
                 $)
             LOADLV(X, FALSE)
             OUT1(S.RV)
             IF SAVE THEN
                 $( OUT1(S.POPHL)
                    STKDEPTH := STKDEPTH-1
                 $)
             RETURN

        CASE S.TABLE:
        CASE S.STRING:
         $( LET L = NEXTPARAM()
            OUT2(S.LABDEADR,L)
            ADDLIT(L,X)
            RETURN
         $)


        CASE S.NAME:
         $( LET M = TRANSNAME(X)
            IF M=CACHE.MODE & RESULT2=CACHE.VAL & ~SAVE THEN
                $( OUT1(S.EXCHG)
                   RETURN
                $)
            SWITCHON M INTO
            $( CASE S.LOCAL:  OUTB(S.LDEIX, RESULT2*2)
                              OUTB(S.LDDIX, (RESULT2*2)+1)
                              RETURN

               CASE S.GLOBAL: OUT2(S.LDDEGLB, RESULT2)
                              RETURN

               CASE S.LABEL:  OUT2(S.LDDELAB, RESULT2)
                              RETURN

               CASE S.NUMBER: OUT2(S.LIMDE, RESULT2)
               DEFAULT:       RETURN
            $)
         $)

        CASE S.PLUS:     SWAPROUND(X)
        CASE S.MINUS:    IF CONSTANT(H3!X) & RESULT2<8 THEN
                          $( LET C = RESULT2
                             LOADDE(H2!X, SAVE)
                                FOR I = 1 TO C DO
                                      OUT1(H1!X=S.PLUS -> S.INCDE, S.DECDE)
                                RETURN
                             $)
// Fall through

        DEFAULT:
            IF SAVE THEN OUT1(S.EXCHG)
            LOADHL(X, SAVE)
            OUT1(S.EXCHG)
            RETURN
    $)
$)


AND PUSHDE(B) BE IF B THEN $( OUT1(S.PUSHDE)
                              STKDEPTH := STKDEPTH + 1  $)


AND POPDE(B) BE  IF B THEN $( OUT1(S.POPDE)
                              STKDEPTH := STKDEPTH - 1  $)





AND ASSIGN(X, Y) BE
$(1 SWITCHON H1!X INTO
     $( CASE S.COMMA:
            UNLESS H1!Y=S.COMMA DO
                $( TRANSREPORT("Unbalanced assignment")
                   RETURN   $)
            ASSIGN(H2!X, H2!Y)
            ASSIGN(H3!X, H3!Y)
            RETURN

        CASE S.NAME:
         $( LET M = TRANSNAME(X)
            LET A = RESULT2

            SWITCHON  M INTO
            $( CASE S.LOCAL:  IF H1!Y = S.PLUS THEN // check for X := X+1
                                     $( SWAPROUND(Y)
                                        IF H2!Y = X & 
                                           CONSTANT(H3!Y) &
                                           RESULT2=1 THEN
                                               $( OUTB(S.INCLOC, A*2)
                                                  OUT1(S.SKIP)
	                                          OUTB(S.INCLOC, (A*2)+1)
                                                  RETURN
                                               $)
                                     $)

                              STORELOCAL(A, Y)
                              RETURN

               CASE S.GLOBAL: 
               CASE S.LABEL:  LOAD(Y)
                              $( LET CM, CV = CACHE.MODE, CACHE.VAL
                                 OUT2((M=S.LABEL->S.STHLLAB, S.STHLGLB) ,A)
                                 TEST CM = S.NUMBER THEN CACHE.MODE, CACHE.VAL := CM, CV
                                                    ELSE CACHE.MODE, CACHE.VAL := M, A
                                 RETURN
                              $)

               CASE S.NUMBER: TRANSREPORT("Cannot assign to %s", X)
               DEFAULT:       RETURN
            $)
         $)

        CASE S.BYTEAP:
            UNLESS BYTEADDR(X, FALSE) DO
               $( LOADLR(X)
                  OUT1(S.ADDHH)
                  OUT1(S.PLUS)
               $)
            // Now have byte address in HL, for easy cases, get byte
            // in A, and store, else get value in DE and store E            
            IF CONSTANT(Y) THEN
               $( OUTB(S.STBYTIM, RESULT2)
                  RETURN
               $)
 
            IF H1!Y = S.NAME THEN
               $( SWITCHON TRANSNAME(Y) INTO
                     $( CASE S.LOCAL:   OUTB(S.LDAIX, RESULT2*2)
                                        ENDCASE

                        CASE S.GLOBAL:  OUT2(S.LDAGLB, RESULT2)
                                        ENDCASE

                        CASE S.LABEL:   OUT2(S.LDALAB, RESULT2)
                        DEFAULT:        ENDCASE
  
                        // Manifest are dealt with by the constant code
                     $)

                  OUT1(S.STBYTEA)
                  RETURN
               $)

            LOADDE(Y,TRUE)
            OUT1(S.STBYTE)
            RETURN

        CASE S.RV: CASE S.VECAP:
             TEST SIMPLEOP(H1!Y) THEN // Get HL first to avoid saving DE
                $( LOADLV(X, FALSE)
                   LOADDE(Y, TRUE)
                $)
             ELSE
                $( LOADDE(Y, FALSE)
                   LOADLV(X, TRUE)
                $)
             OUT1(S.STIND)
             RETURN

        CASE S.OF:
            $( LET SEL = EVALCONST(H2!X)
               LET SIZE   = (SLCT 4:12) OF @SEL
               LET SHIFT  = (SLCT 4:8)  OF @SEL

               LOAD(H3!X)  
               ADDCONST((SLCT 8) OF @SEL)
               // Now have address in HL

               TEST CONSTANT(Y) & SIZE=1 THEN // Can use the 'set', 'res' etc
                   $( OUT1(S.ADDHH)
                      IF SHIFT>=8 THEN // High byte is second
                        $( OUT1(S.INCHL)
                           SHIFT := SHIFT-8
                        $)
                      OUTB(S.BIT, (SHIFT<<3) | (((RESULT2&1)=0) -> #B10000110,
                                                                   #B11000110))
                                                      // This rather breaks the
                   $)                                 // abstraction, sorry.
               ELSE   
                   $( LOADDE(Y, TRUE)
                      TEST SIZE=0 THEN // Size is whole word
                            OUT1(S.STIND)
                      ELSE TEST (SIZE=8) & ((SHIFT=0) | (SHIFT=8)) THEN
                         $( // Can use byte instrs
                            OUT1(S.ADDHH)
                            IF SHIFT=8 THEN OUT1(S.INCHL)
                            OUT1(S.STBYTE)
                         $)
                      ELSE            
                         $( OUT2(S.LIMBC, (-1>>(16-SIZE)) << SHIFT) // The mask
                            OUTB(S.LIMA, SHIFT)
                            OUT1(S.OFLV)
                         $)
                   $)
               RETURN
            $)


        DEFAULT: TRANSREPORT("Assignment to RTYPE expr")   
$)1

AND TRANSOF(X, SAVE) = VALOF
$( LET SEL = EVALCONST(H2!X)
   LET SIZE   = (SLCT 4:12) OF @SEL
   LET SHIFT  = (SLCT 4:8)  OF @SEL

   LOADHL(H3!X, SAVE) // Need to keep DE if this is assignment
   ADDCONST((SLCT 8) OF @SEL)
   // Now have address in HL

   TEST SIZE=1 THEN // Can use the 'bit'
      $(  OUT1(S.ADDHH)
          IF SHIFT>=8 THEN // High byte is second
            $( OUT1(S.INCHL)
               SHIFT := SHIFT-8
            $)
         OUTB(S.BIT, (SHIFT<<3) | #B01000110) // This rather breaks the
         RESULTIS TRUE                         // abstraction, sorry.
      $)
   ELSE   
      $( TEST SIZE=0 THEN // Size is whole word
                OUT1(S.RV)
         ELSE TEST (SIZE=8) & ((SHIFT=0) | (SHIFT=8)) THEN
             $( // Can use byte instrs
                OUT1(S.ADDHH)
                IF SHIFT=8 THEN OUT1(S.INCHL)
                OUT1(S.LDBYTE)
                OUTB(S.LDHIM, 0)
             $)
         ELSE
             $( OUT2(S.LIMBC, (-1>>(16-SIZE)) << SHIFT) // The mask
                OUTB(S.LIMA, SHIFT)
                OUT1(S.OFRV)
             $)
         RESULTIS FALSE
      $)
$)

AND ADDCONST(C) BE 
$( TEST -4<=C<=4 THEN
         FOR K = 1 TO ABS C DO OUT1(C<0 -> S.DECHL, S.INCHL)
   ELSE
       $( OUT2(S.LIMBC, C)
          OUT1(S.ADDHB)
       $)
$)


AND TRANSCALL(X) BE
$( LET ARGBASE = ARGSSP
   LET ARGLIST = H3!X
   UNLESS ARGLIST = 0 DO
      $( LET FIRSTARG = ?
         TEST H1!ARGLIST = S.COMMA THEN // More than one arg
            $( LET SECONDARG = H3!ARGLIST
// This is to allow ARGSSP to be zero during the evaluation of the second
// arg, thus eliminating redundant BUMPP's if it is a function call
               TEST H1!SECONDARG = S.COMMA THEN 
                    $( STORELOCAL(ARGSSP+1, H2!SECONDARG)
                       ARGSSP := ARGSSP+2
                       LOADLIST(H3!SECONDARG, @ARGSSP)
                    $)
               ELSE 
                    $( STORELOCAL(ARGSSP+1, SECONDARG)
                       ARGSSP :=  ARGSSP+2
                    $)
               FIRSTARG := H2!ARGLIST // and then first
            $)
         ELSE 
               FIRSTARG := ARGLIST   // this case when one arg only

         TEST CONSTANT(FIRSTARG) THEN OUT2(S.LIMDE, RESULT2)
                                 ELSE LOADDE(FIRSTARG, FALSE)
      $)
    LOADHL(H2!X, ARGLIST ~= 0) // Get proc value
    BUMPP(ARGBASE) // for nested calls
    OUT1(ARGLIST=0 -> S.SRTAP, S.RTAP) // srtap for zero args
    BUMPP(-ARGBASE)
    ARGSSP := ARGBASE
 $)

AND LOADLIST(X, COUNTVAR) BE
$( WHILE H1!X = S.COMMA DO
     $( STORELOCAL(!COUNTVAR, H2!X)
        !COUNTVAR := (!COUNTVAR)+1
        X := H3!X
     $)
   STORELOCAL(!COUNTVAR, X)
   !COUNTVAR := (!COUNTVAR)+1
$)

AND BYTEADDR(X, SAVE) = VALOF
// Compile code to get byte addr of X%Y if simple, return TRUE if done.
  $( IF CONSTANT(H3!X) & 0<=RESULT2<=4 THEN
         $( LET C=RESULT2
            LOADHL(H2!X,SAVE)
            FOR K = 1 TO C/2 DO OUT1(S.INCHL) // These are worth 2
            OUT1(S.ADDHH)                     // because of this.
            IF C REM 2 DO OUT1(S.INCHL)       // if c is odd.
            RESULTIS TRUE
         $)
     RESULTIS FALSE
$)

AND STORELOCAL(S, X) BE
$( IF H1!X=S.QUERY RETURN
   TEST CONSTANT(X) THEN
     $( LET M = CACHE.MODE
        LET A = (S*2) /\ #XFF
        OUT2(S.STIXIM,A+(RESULT2<<8)) // Pack the address and data bytes
        OUT2(S.STIXIM,A+1+(RESULT2&#XFF00)) // into the word arg.
        UNLESS M=S.LOCAL & CACHE.VAL=S DO CACHE.MODE := M
     $)
   ELSE
     $( LOADHL(X, FALSE)
        OUTB(S.STLIX, S*2)
        OUTB(S.STHIX, (S*2)+1)
        CACHE.MODE, CACHE.VAL := S.LOCAL, S
     $)
$)

AND EVALCONST(X) = VALOF
$( IF CONSTANT(X) THEN RESULTIS RESULT2
   
   IF H1!RESULT2 = S.QUERY RESULTIS 0 // Query is legal in const exprs
                           // But we don't want to treat it as having a value
   
   TEST H1!RESULT2 = S.NAME THEN 
               $( LET N = RESULT2
                  IF TRANSNAME(N) THEN 
                          TRANSREPORT("Variable %s used in constant expr", N)
               $)
          ELSE TRANSREPORT("Error in constant expr")
$)

AND CONSTANT(X) = VALOF
// if X is a constant expr, return TRUE, and it's value in RESULT2
// else return duff node in RESULT2
$( LET A, B, C = ?, ?, ?

   IF X=0  THEN 
        $( RESULT2 := 0
           RESULTIS TRUE  // For optional parts of SLCT
        $)

   SWITCHON H1!X INTO
     $( DEFAULT: RESULT2 := X
                 RESULTIS FALSE

        CASE S.NAME:
          TEST CELLWITHNAME(X) = S.NUMBER THEN    RESULTIS TRUE
                                          ELSE $( RESULT2 := X
                                                  RESULTIS FALSE
                                               $)
        CASE S.SLCT:

          TEST CONSTANT(H4!X) THEN C := RESULT2
                              ELSE RESULTIS FALSE

        CASE S.PLUS:   CASE S.MINUS:  CASE S.DIV: CASE S.REM: CASE S.MULT:
        CASE S.LOGOR:  CASE S.LOGAND: CASE S.EQV: CASE S.NEQV:
        CASE S.LSHIFT: CASE S.RSHIFT:

          TEST CONSTANT(H3!X) THEN B := RESULT2
                              ELSE RESULTIS FALSE

        CASE S.ABS: CASE S.NEG: CASE S.NOT:

          TEST CONSTANT(H2!X) THEN A := RESULT2
                              ELSE RESULTIS FALSE
         
        CASE S.NUMBER: CASE S.TRUE: CASE S.FALSE:

          RESULT2 := VALOF SWITCHON H1!X INTO
           $( CASE S.NUMBER: RESULTIS H2!X
              CASE S.TRUE:   RESULTIS TRUE
              CASE S.FALSE:  RESULTIS FALSE

              CASE S.NEG:    RESULTIS  -  A
              CASE S.ABS:    RESULTIS ABS A
              CASE S.NOT:    RESULTIS NOT A

              CASE S.MULT:   RESULTIS A   *    B
              CASE S.PLUS:   RESULTIS A   +    B
              CASE S.MINUS:  RESULTIS A   -    B
              CASE S.LSHIFT: RESULTIS A   <<   B
              CASE S.RSHIFT: RESULTIS A   >>   B
              CASE S.LOGOR:  RESULTIS A LOGOR  B
              CASE S.LOGAND: RESULTIS A LOGAND B
              CASE S.EQV:    RESULTIS A  EQV   B
              CASE S.NEQV:   RESULTIS A  NEQV  B

              CASE S.DIV: CASE S.REM:
                  IF B=0 THEN $( TRANSREPORT("Division by zero")
                                 B := 1
                              $)
                  RESULTIS H1!X=S.DIV -> A / B, A REM B

              CASE S.SLCT:
                  IF A=0 THEN A := 16-B // use rest of word if size is zero
                  IF A>16 | B>15 | C>255 | (A+B)>16 
                          THEN TRANSREPORT("Illegal value(s) in SLCT")
                  RESULTIS ((A&#X0F) << 12)  + (B<<8) + C
           $)
         RESULTIS TRUE
        
     $)

$)

.

//TRN2
SECTION "TRN2"
GET "COMPHDR"

// Odds and ends for TRN

STATIC $(
PARAMNUMBER=?; LIT=?; LITS=?; 
DVECBASE=?; REACHABLE=?
$)

LET NEXTPARAM() = VALOF
    $( PARAMNUMBER := PARAMNUMBER + 1
       RESULTIS PARAMNUMBER  $)

AND TRANSREPORT(S, N) BE
$( SELECTOUTPUT(CON)                                                  
   REPORTCOUNT := REPORTCOUNT + 1                                          
   IF REPORTCOUNT = REPORTMAX THEN                                         
                          WRITES("*NFurther errors suppressed.*N*N")       
   IF REPORTCOUNT < REPORTMAX THEN                                         
      $( WRITEF("Report:   %F", S, @(H3!N))                               
         WRITEF(" in procedure %S.*N",CURPROC)                            
      $)                                                                   
   SELECTOUTPUT(OCODE)                                                     
$)                                                                         


AND COMPILEAE(X) BE
$( LET B = VEC LITMAX
   LET R = VEC 63

   RETTABLE := R
   FOR K = 0 TO 63 DO RETTABLE!K := 0

   LIT, LITS := B, 0

   DVECBASE, DVECP :=  TREEP, TREEP

   CASEB, RESULTLABEL, BREAKLABEL := -1, -1, -1
   LOOPLABEL, ENDCASELABEL := -1, -1

   SSP, ARGSSP := 0, 0
   REACHABLE := FALSE
   CACHE.MODE := 0
   PARAMNUMBER := 0
   CURPROC := "Main program"

   IF X=0 RETURN

   WRITE1(S.STARTSECT)
   IF H1!X=S.SECTION THEN
      $(  WRITE1(S.SECTION)
          WRITESTRING(@H2!(H2!X))
          X:=H3!X $)

   DECLLABELS(X)
   TRANS(X)

   IF LITS \=0 THEN DUMPLITS() // Dump any remaining literals
$)

AND BUMPP(VAL) BE
$( IF VAL=0 RETURN
   IF VAL=1 THEN
      $( OUT1(S.INCIX)
         OUT1(S.INCIX)
         RETURN
      $)
   IF VAL=-1 THEN
      $( OUT1(S.DECIX)
         OUT1(S.DECIX)
         RETURN
      $)
   OUT2(S.LIMBC, VAL*2)
   OUT1(S.ADDIXBC)
$)

AND COMISJUMP(X) = VALOF
// If X is a command which can be compiled to a jump, return the
// Label and the new stack level in RESULT2. If it should be a jump
// But there is an error, return zero and message in RESULT2
// Else just return zero
$( SWITCHON H1!X INTO
   $( CASE S.LOOP:
         IF LOOPLABEL<0 THEN
            $( RESULT2 := "Illegal LOOP"
               RESULTIS 0
            $)
         IF LOOPLABEL=0 DO LOOPLABEL := NEXTPARAM()
         RESULT2 := LOOPSTACK
         RESULTIS LOOPLABEL

      CASE S.BREAK:
         IF LOOPLABEL<0 THEN
            $( RESULT2 :=  "Illegal BREAK"
               RESULTIS 0
            $)
         IF BREAKLABEL=0 DO BREAKLABEL := NEXTPARAM()
         RESULT2 := LOOPSTACK
         RESULTIS BREAKLABEL

      CASE S.ENDCASE:
         IF ENDCASELABEL<0 THEN
            $( RESULT2 := "Illegal ENDCASE"
               RESULTIS 0
            $)
         IF ENDCASELABEL=0 DO ENDCASELABEL := NEXTPARAM()
         RESULT2 := CASESTACK
         RESULTIS ENDCASELABEL

      CASE S.RETURN:
         RESULT2 := 0
         RESULTIS RETTABLE!SFSIZE
     
      DEFAULT:
         RESULTIS 0
   $)
$)
   
AND STACKTO(S) BE
TEST S+8 < STKDEPTH THEN
    $( OUT2(S.LIMIY, 2*(STKDEPTH-S))
       OUT1(S.ADDIYSP)
       OUT1(S.LDSPIY)
    $)
ELSE
    $( LET C = STKDEPTH
       UNTIL C = S DO
         $( OUT1(S.POPDE)
            C := C - 1
         $)
    $)

AND JUMPCOND(X, B, L ,SAVE) BE
$(   LET SW = B
     LET CACHE.SAVE = ?

     SWITCHON H1!X INTO
     $( CASE S.NOT: JUMPCOND(H2!X, NOT B, L, SAVE)
                    RETURN
     
        CASE S.FALSE: SW :=  NOT SW
        CASE S.TRUE:  IF SW THEN COMPJUMP(L)
                      RETURN


        CASE S.LOGAND: SW := NOT SW
        CASE S.LOGOR:
            TEST SW THEN $( JUMPCOND(H2!X, B, L, SAVE)
                            JUMPCOND(H3!X, B, L, SAVE)  $)

                      OR $( LET M = NEXTPARAM()
                            JUMPCOND(H2!X, NOT B, M, SAVE)
                            JUMPCOND(H3!X, B, L, SAVE)
                            COMPLAB(M)  $)

            RETURN

        CASE S.OF:
            TEST TRANSOF(X, SAVE) THEN GOTO JP     // Result in HL
                                  ELSE GOTO CHECKZ // Result in Z

        CASE S.LS: CASE S.GE:
            IF CONSTANT(H3!X) & RESULT2=0 THEN
                 $( IF H1!X = S.GE THEN B := NOT B
                    LOADHL(H2!X, SAVE)
                    OUT1(S.ADDHH)
                    GOTO JPC
                 $) 
// Fall through
        CASE S.LE: CASE S.GR:
            PUSHDE(SAVE)
            LOADLR(X)
            OUT1(H1!X)
            POPDE(SAVE)
JPC:
            TEST B THEN OUT2(S.JPC, L)
                   ELSE OUT2(S.JPNC, L)
            RETURN

        CASE S.EQ: B := NOT B
        CASE S.NE:
            SWAPROUND(X)
            IF CONSTANT(H3!X) THEN
                $( LET C=RESULT2
                   IF (H1!(H2!X)=S.NAME) & (CELLWITHNAME(H2!X)=S.LOCAL) THEN
                     $( // Possible special case for locals
                        IF 0<=C<=255 THEN
                        UNLESS (CACHE.MODE = S.LOCAL) & (CACHE.VAL = RESULT2) THEN
                          $( CACHE.SAVE := CACHE.MODE
                             OUTB(S.LDAIX, RESULT2*2)
                             IF C=1 THEN OUT1(S.DECA)
                             IF C>=2 THEN OUTB(S.SUBA, C)
                             OUTB(S.ORIX, (RESULT2*2)+1)
                             CACHE.MODE := CACHE.SAVE
                             GOTO JP
                          $)
                     $)
               // else fall through
                   LOADHL(H2!X, SAVE)
                   IF -3<=C<=1 THEN // best way for these
                     $( ADDCONST(-C)
                        GOTO CHECKZ
                     $)
                   TEST 2<=C<=255 THEN // and for these
                     $( CACHE.SAVE := CACHE.MODE
                        OUT1(S.LDAL)
                        OUTB(S.SUBA, C)
                        OUT1(S.ORH)
                        CACHE.MODE := CACHE.SAVE
                     $)
                   ELSE
                     $( OUT2(S.LIMBC, C) // Whats left gets awful code
                        OUT1(S.ORA)
                        OUT1(S.SUBHB)
                     $)
                   GOTO JP
                $)

            // Here is non-constant equals
            PUSHDE(SAVE)
            LOADLR(X)
            OUT1(S.ORA)
	    OUT1(S.MINUS)
            POPDE(SAVE)
            GOTO JP

        CASE S.NAME:
            IF CELLWITHNAME(X) = S.LOCAL THEN
            UNLESS (CACHE.MODE = S.LOCAL) & (CACHE.VAL = RESULT2) DO
              $( CACHE.SAVE := CACHE.MODE
                 OUTB(S.LDAIX, RESULT2*2)
                 OUTB(S.ORIX, (RESULT2*2)+1)
                 CACHE.MODE := CACHE.SAVE
                 GOTO JP
              $)
            // else fall through

        DEFAULT: LOADHL(X,SAVE)
        CHECKZ:  CACHE.SAVE := CACHE.MODE
                 OUT1(S.LDAL)
	         OUT1(S.ORH)
                 CACHE.MODE := CACHE.SAVE
        JP:      CACHE.SAVE := CACHE.MODE
                 TEST B THEN OUT2(S.JPNZ, L)
                        ELSE OUT2(S.JPZ, L)
                 CACHE.MODE := CACHE.SAVE
                 RETURN     
     $)
$)


AND CHECKDISTINCT(E) BE
       UNTIL E=TREEP DO
          $( IF E ~= H2!(H1!E) DO TRANSREPORT("%s declared twice", H1!E)
             E := E + 3  $)


AND ADDNAME(N, P, V) BE
$( LET A = TREEP+3
   IF A >= TREETOP DO ABORT("Out of workspace")
   H1!TREEP, H2!TREEP, H3!TREEP := N, P, V
   H2!N := TREEP // The hint
   TREEP := A
   IF TREEP>TREEPMAX THEN TREEPMAX := TREEP
$)  


AND CELLWITHNAME(N) = VALOF
$( LET X = H2!N // The hint
   IF X THEN // else not ever declared
      $( IF X>=TREEP THEN X := TREEP-3 // declaration superceded
         UNTIL X=(DVECBASE-3) DO
              $( IF H1!X=N THEN // Found it
                   $( LET M = H2!X
                      H2!N := X // update the hint
                      TEST M = S.LOCAL & X<DVECP THEN 
                          $( RESULT2 := FALSE // DFV error
                             RESULTIS 0 
                          $)
                      ELSE $( RESULT2 := H3!X
                              RESULTIS M // Found
                           $)
                   $)    
                 X := X-3
             $)
      $)
   
   RESULT2 := TRUE
   RESULTIS 0 // Not found
$)


AND ADDLIT(L, X) BE
$( IF LITS>=LITMAX DO
        $( LET M = NEXTPARAM() // dump overflowing literal pool
           COMPJUMP(M)         // by compiling a branch round it
           COMPLAB(M)  $)

   LIT!LITS, LIT!(LITS+1) := L, X
   LITS := LITS + 2

   IF H1!X = S.TABLE THEN
      $( LET Y = H2!X
         WHILE Y DO
            $( H1!Y := EVALCONST(H1!Y)
               Y := H2!Y
            $)
      $)
$)


AND TRANSNAME(X)=VALOF
$( LET M = CELLWITHNAME(X)
   IF M=0 THEN TRANSREPORT(RESULT2 -> "%s not declared",
                                      "Dynamic free variable %s used", X)
   RESULTIS M
$)

AND COMPRETURN() BE
$( UNLESS REACHABLE RETURN
   TEST (RETTABLE!SFSIZE)=0 THEN 
      $( UNLESS SFSIZE=0 DO
            $( RETTABLE!SFSIZE := NEXTPARAM()
               COMPLAB(RETTABLE!SFSIZE)
               BUMPP(-SFSIZE)
            $)
         OUT1(S.RET)
         STOPFLOW()
      $)
   ELSE  COMPJUMP(RETTABLE!SFSIZE)
$)

AND COMPJUMP(L) = VALOF
$( LET OLD = REACHABLE
   OUT2(S.JPLAB, L)
   STOPFLOW()
   RESULTIS OLD
$)

AND COMPLAB(L) BE
// If control can't fall into the label from above, use NEWLAB.
// this is used by the loaders jump short-circuiting
$( LET OLDR = REACHABLE
   REACHABLE := TRUE
   OUT2((OLDR -> S.LABDEF, S.NEWLAB), L)
$)

AND OUT2(I, A) BE IF REACHABLE THEN $( CACHE.MODE := 0
                                       WRITE2(I, A)
                                    $)

AND OUTB(I, A) BE IF REACHABLE THEN $( CACHE.MODE := 0
                                       WRITEB(I, A)
                                    $)

AND OUT1(I) BE    IF REACHABLE THEN $( CACHE.MODE := 0
                                       WRITE1(I)
                                    $)

AND STOPFLOW() BE
$( REACHABLE := FALSE
   IF LITS > (LITMAX/2) DUMPLITS() // Quit if reasonable room left
                              // so as not to waste bytes aligning
$)

AND DUMPLITS() BE
$( WRITE1(S.WALIGN) // This stuff must be aligned
   FOR K= 0 TO LITS-1 BY 2 DO // Dump the literal pool
     $( LET X = LIT!(K+1)
        LET LABEL = LIT!K
        SWITCHON H1!X INTO
          $( CASE S.TABLE:
             $( LET Y = H2!X
                WRITE2(S.LABDEF, LABEL)
                WHILE Y DO
                $( WRITE2(S.DW, H1!Y)
                   Y := H2!Y
                $)
                ENDCASE
             $)

             CASE S.STRING:
             $( LET S = @(H2!X)
                WRITE2(S.LABDEF, LABEL)
                FOR K = 0 TO S%0 DO WRITEB(S.DB, S%K)
                WRITE1(S.WALIGN) // realign
                ENDCASE
             $)

             CASE S.FNDEF:
             CASE S.RTDEF:
             CASE S.COLON:
             CASE S.STATIC:
                WRITE2(S.LABSYM, LABEL)
                WRITESTRING(@H3!(H2!X)) 
                TEST H1!X = S.STATIC 
                     THEN WRITE2(S.DW, H3!X)
                     ELSE WRITE2(S.DWLAB, (H1!X=S.COLON -> H4!X, H5!X))
                ENDCASE
      
         $)
    $)
    LITS := 0 // Empty the literal pool
$)

AND WRITE1(I) BE WRCH(I)

AND WRITEB(I, A) BE
$( WRCH(I)
   WRCH(A)
$)

AND WRITE2(I, A) BE
$( WRCH(I)
   WRCH(A)
   WRCH(A>>8)
$)

AND WRITESTRING(S) BE
$( WRITES(S)
   WRCH(0)
$)

.
