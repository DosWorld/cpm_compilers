program calc;
{ Modifications by Gerald McMullon
  Alterations to DESK: Double precision used. Output field can be
  modified by Fn.m. Screen_clear is set to ADM-3A (1AH) 191083.
}
CONST
 fieldconst= 12; prec_const= 6;
 lower     = 1.0D-4              ;    upper     = 1.0D+7;
 pi        = 3.141592653589793D0;
 deg       = 180;
 radix     = 10;
 maxscale  = 20;  maxlinelen = 80;
 blank     = ' '; comma      = ',';   semicolon = ';';
 point     = '.'; plus       = '+';   minus     = '-';
 multply   = '*'; divide     = '/';   marker    = '^';
 zero      = '0'; nine       = '9';   question  = '?';
 leftparen = '('; rightparen = ')';
TYPE
 charset   = SET OF CHAR;
 position  = 0..maxlinelen;
 six       = PACKED ARRAY[1..6] OF CHAR;
VAR
 screen_clear,
 nextchar             : CHAR;
 nextposchar,
 fieldreal, precision : position;
 invrad,maxreal,
 result,prevresult    : LONGREAL;
 validset,
 digits,addingops,
 multops,terminators  : charset;
 memory               : ARRAY[zero..nine] OF LONGREAL;

PROCEDURE readchar;
BEGIN
  REPEAT
   IF eof THEN nextchar := semicolon
          ELSE IF eoln THEN BEGIN
                             nextposchar := 1;
                             nextchar    := comma;
                             readln
                            END
                       ELSE BEGIN
                             nextposchar := succ(nextposchar);
                             read(nextchar)
                            END;
  UNTIL nextchar <> blank;
END;   { readchar }

PROCEDURE reporterror;
 BEGIN
  writeln(marker:nextposchar);
  WHILE NOT (nextchar IN terminators) DO
        readchar
 END;  { reporterror }

FUNCTION errorfunction(fname : six): LONGREAL;
 BEGIN
  writeln(fname,' out of range.');
  WHILE NOT (nextchar IN terminators) DO
        readchar;
  errorfunction := 0
 END;

FUNCTION tan(x : LONGREAL): LONGREAL;
 VAR y : LONGREAL;
 BEGIN
  y := cos(x);
  IF y=0 THEN tan:= errorfunction('  tan ')
         ELSE tan:= sin(x)/y
 END;

FUNCTION arcsin(x: LONGREAL): LONGREAL;
 CONST
  epsilon = 1.0D-16;    { machine and language dependant }
 VAR func1, func, term, n : LONGREAL;
 BEGIN
  IF abs(x)>1 THEN arcsin := errorfunction('arcsin')
  ELSE IF x=1 THEN arcsin := pi/2
              ELSE IF x=0 THEN arcsin := 0
                   ELSE BEGIN
                         term   := x;
                         n      := 1;
                         func   := x;
                         REPEAT
                          func1 := func;
                          term  := sqr(x)*term*n/(n+1);
                          n     := n+2;
                          func  := func + term/n;
                         UNTIL abs((func-func1)/func) < epsilon;
                         arcsin := func
                        END;
  END;   { function arcsin }

FUNCTION arccos(x : LONGREAL): LONGREAL;
 BEGIN
  arccos := pi/2 - arcsin(x)
 END;    { function arccos }

FUNCTION expo(x : LONGREAL ): LONGREAL;
 BEGIN
  IF abs(x) < (maxreal- lower)
     THEN expo := exp(x)
     ELSE expo := errorfunction('   exp')
 END;   {some versions of Pascal return exp(89) as 0}

FUNCTION sinh(x: LONGREAL): LONGREAL;
 VAR y : LONGREAL;
 BEGIN
  y := expo(x);
  IF y = 0 THEN sinh := 0
           ELSE sinh := (y-1/y)/2
 END;   { function sinh }

FUNCTION cosh(x : LONGREAL): LONGREAL;
 VAR y : LONGREAL;
 BEGIN
  y := expo(x);
  IF y = 0 THEN cosh := 0
           ELSE cosh := (y+1/y)/2
 END;   { function cosh }

FUNCTION tanh(x : LONGREAL): LONGREAL;
 VAR y : LONGREAL;
 BEGIN
  IF (abs(x) < maxreal/2)
  THEN BEGIN
        y:= sqr(expo(x));
        tanh := (y-1)/(y+1)
       END
   ELSE tanh := 1
 END;  { function tanh }

PROCEDURE displaymemory;
 VAR count      : zero..nine;
 PROCEDURE show;
  BEGIN
   IF (memory[count]=0) OR
      (abs(memory[count])>lower) AND (abs(memory[count])<upper)
   THEN write('M',count,blank,memory[count]:fieldreal:precision)
   ELSE write('M',count,blank,memory[count])
  END;

 BEGIN
  readln;
  writeln(screen_clear,'Memory');
  count := zero;
  WHILE (count<nine) DO
      BEGIN
       show; count:=succ(count);
       write(chr(22),chr(40),chr((ord(count)-ord('0')) DIV 2+2));
       show; IF (count<nine) THEN count:=succ(count);
       writeln
      END;
   writeln('Previous result ',prevresult)
END;  { displaymemory }

PROCEDURE clearmemory;
 VAR count : zero..nine;
 BEGIN
  FOR count := zero TO nine DO
      memory[count] := 0
 END;  { clearmemory }

PROCEDURE listfunctions;

BEGIN
  writeln(screen_clear);
  writeln(blank:10,'Scientific desk calculator',blank:6,
          'Version 1.0');
  writeln('The following functions are allowed :- ');
  writeln('four rules of arithmetic +,-,*,/      pi=',
                pi:fieldreal:precision,point);
  writeln('format is a field of ',fieldreal:3,' with ',
          precision:2,' decimal places.');
  writeln('To change format  f<field>,<decimal places> eg f10,5.');
  write('d toggles between degrees and radians, currently set in ');
  IF invrad > 0.9 THEN writeln('radians.')
                  ELSE writeln('degrees.');
  writeln('p        the previous result.        ',
          'm0 to m9 the memory stores 0 to 9    ');
  writeln('r0 to r9 the memory retrival 0 to 9. ',
          'ml       a list of the memory store. ');
  writeln('sqr( . ) the square of a number.     ',
          'sqrt( . )the square root of a number.');
  writeln('exp( . ) the exponential of a number.',
          'ln( . )  the natural log of a number.');
  writeln('sin( . ) the sine of a number.       ',
          'arcsin(.)the inverse of sine.        ');
  writeln('cos( . ) the cosine of a number.     ',
          'arccos(.)the inverse of cosine.      ');
  writeln('tan( . ) the tangent of a number.    ',
          'arctan(.)the inverse of tangent.     ');
  writeln('sinh( . ) hyperbolic sine.           ',
          'cosh( . ) hyperbolic cosine.         ');
  writeln('tanh( . ) hyperbolic tangent.        ');
  writeln('To return to CP/M enter "end.".');
  readln;
  nextposchar := 1
END;

PROCEDURE readnumber(VAR numvalue : LONGREAL);
TYPE
 scalefactor = 0..maxscale;
VAR
 count, scale : scalefactor;
BEGIN
 numvalue := 0;
 WHILE nextchar IN digits DO
       BEGIN
        numvalue := radix*numvalue+ ord(nextchar)-ord(zero);
        readchar
       END;  { WHILE }
 IF nextchar = point
    THEN BEGIN
          readchar;
          scale  := 0;
          WHILE nextchar IN digits DO
                BEGIN
                 numvalue := radix*numvalue+ord(nextchar)-ord(zero);
                 readchar;
                 scale    := succ(scale)
                END;  { WHILE }
           FOR count := 1 TO scale DO
               numvalue := numvalue/radix
          END
END;  { readnumber }

PROCEDURE readexpression(VAR expvalue : LONGREAL);
 VAR
  addop       : CHAR;
  nexttermval : LONGREAL;
 PROCEDURE readterm(VAR termvalue : LONGREAL);
  VAR
   mulop       : CHAR;
   nextfacval  : LONGREAL;
  PROCEDURE readfactor(VAR factorvalue : LONGREAL);

   PROCEDURE getfunction(VAR factorvalue : LONGREAL);
    VAR
     fname    : six;
     i        : 0..6;
    BEGIN
     i := 0;
     fname := '      ';
     REPEAT
      i := succ(i);
      fname[i] := nextchar;
      readchar
     UNTIL (i=6) OR (nextchar= leftparen) OR (fname ='end   ');
     nextposchar := nextposchar + i;
     IF nextchar = leftparen
     THEN
     BEGIN
      readfactor(factorvalue);
      IF fname = 'sin   ' THEN factorvalue:= sin(factorvalue*invrad)
      ELSE IF fname = 'cos   ' THEN factorvalue:=cos(factorvalue*invrad)
      ELSE IF fname = 'tan   ' THEN factorvalue:=   tan(factorvalue*invrad)
      ELSE IF fname = 'exp   ' THEN factorvalue:=  expo(factorvalue)
      ELSE IF fname = 'ln    ' THEN factorvalue:=    ln(factorvalue)
      ELSE IF fname = 'sqr   ' THEN factorvalue:=   sqr(factorvalue)
      ELSE IF fname = 'sqrt  ' THEN factorvalue:=  sqrt(factorvalue)
      ELSE IF fname = 'arctan' THEN factorvalue:=arctan(factorvalue)/invrad
      ELSE IF fname = 'arcsin' THEN factorvalue:=arcsin(factorvalue)/invrad
      ELSE IF fname = 'arccos' THEN factorvalue:=arccos(factorvalue)/invrad
      ELSE IF fname = 'sinh  ' THEN factorvalue:=  sinh(factorvalue)
      ELSE IF fname = 'cosh  ' THEN factorvalue:=  cosh(factorvalue)
      ELSE IF fname = 'tanh  ' THEN factorvalue:=  tanh(factorvalue)
      ELSE BEGIN
            reporterror;
            factorvalue := 0
           END
     END
     ELSE IF (fname='end   ')
          THEN BEGIN
                writeln('Bye.'); readln; nextchar := semicolon
               END
          ELSE BEGIN
                 reporterror;
                 factorvalue := 0
               END
    END;  { getfunction }

    FUNCTION trun(factorvalue:LONGREAL):position;
    VAR result : INTEGER;
    BEGIN
     result := trunc(factorvalue);
     IF result <= maxlinelen THEN trun := result MOD maxlinelen
                             ELSE trun := 1
    END;

    BEGIN  { readfactor }
     IF nextchar IN validset THEN
     CASE nextchar OF
      zero,'1','2','3','4','5','6','7','8',nine
                  : readnumber(factorvalue);
      'p','P'     : BEGIN
                     readchar;
                     IF (nextchar IN ['i','I'])
                        THEN BEGIN
                              factorvalue := pi;
                              readchar
                             END
                        ELSE factorvalue := prevresult
                    END;
      'm','M'     : BEGIN
                     readchar;
                     IF nextchar IN [zero..nine,'l','L','c','C']
                     THEN CASE nextchar OF
                           zero,'1','2','3','4','5','6','7','8',nine
                                     : BEGIN
                                        memory[nextchar]:= prevresult;
                                        readchar;
                                        IF (nextchar IN terminators)
                                           THEN nextchar := question
                                       END;
                            'l','L'  : BEGIN
                                        displaymemory;
                                        nextposchar := 1;
                                        nextchar    := question
                                       END;
                            'c','C'  : BEGIN
                                        clearmemory;
                                        readchar
                                       END;
                           END { CASE }
                     ELSE reporterror
                    END;
      'r','R'     : BEGIN
                     readchar;
                     IF (nextchar IN digits)
                        THEN factorvalue := memory[nextchar]
                        ELSE reporterror;
                     readchar;
                    END;
       leftparen  : BEGIN
                     readchar;
                     readexpression(factorvalue);
                     IF nextchar = rightparen
                        THEN readchar
                        ELSE reporterror
                    END;
       'd','D'    : BEGIN
                     IF invrad > 0.9 THEN invrad := pi/deg
                                     ELSE invrad := 1;
                     readln;
                     nextposchar := 1;
                     nextchar    := question
                    END;
        'f','F'   : BEGIN
                     readchar;
                     readexpression(factorvalue);
                     IF nextchar IN terminators
                        THEN BEGIN
                              fieldreal := trun(factorvalue);
                              readchar;
                              readexpression(factorvalue);
                              precision := trun(factorvalue);
                              IF NOT ((fieldreal>precision) AND (precision>0))
                              THEN BEGIN
                                    fieldreal := fieldconst;
                                    precision := prec_const;
                                    reporterror
                                   END;
                               nextchar := question
                             END
                        ELSE reporterror
                    END;
        question  : listfunctions;
        'a','c','e','l','s','t': getfunction(factorvalue)
      END  { CASE }
      ELSE BEGIN
            reporterror;
            factorvalue := 0
           END;
    END;   { readfactor }

  BEGIN  { readterm }
   readfactor(termvalue);
   WHILE nextchar IN multops DO
         BEGIN
          mulop := nextchar;
          readchar;
          readfactor(nextfacval);
          CASE mulop OF
           multply : termvalue := termvalue*nextfacval;
           divide  : IF nextfacval = 0
                        THEN reporterror
                        ELSE termvalue := termvalue/nextfacval
           END;  { CASE }
          END  { WHILE }
  END;  { readterm }

 BEGIN  { readexpression }
  readterm(expvalue);
  WHILE nextchar IN addingops DO
        BEGIN
         addop := nextchar;
         readchar;
         readterm(nexttermval);
         CASE addop OF
          plus : expvalue := expvalue + nexttermval;
          minus: expvalue := expvalue - nexttermval;
         END; {case}
        END;  {while}
 END;   { readexpression }

BEGIN                           { calculator }
 screen_clear:= chr(26);
 digits     := [zero..nine];
 addingops  := [plus,minus];
 multops    := [multply,divide];
 terminators:= [comma,semicolon];
 validset   := digits+['D','F','M','P','R','a','c','d','e','f','l','m','p','r',
              's','t',leftparen,question];
 writeln(screen_clear,'Calculator ready.  (version 1.0)');
 invrad := pi/deg;  fieldreal := fieldconst; precision := prec_const;
 maxreal:= 1024*ln(2); {710.4D0, machine and language dependant }
 prevresult:= 0;        nextposchar := 1;
 clearmemory;
 readchar;
 WHILE nextchar <> semicolon DO
   BEGIN
    readexpression(result);
    IF nextchar = comma
       THEN BEGIN
             IF (abs(result)>lower) AND (abs(result)<upper) OR
               (abs(result-1.0D-13)<1.0D-10)
                THEN writeln(result:fieldreal:precision)
                ELSE writeln(result);
             prevresult := result
            END
       ELSE IF NOT (nextchar IN [question,semicolon]) THEN reporterror;
       IF nextchar <> semicolon THEN readchar;
    END   { WHILE }
END.  { calculator }

 