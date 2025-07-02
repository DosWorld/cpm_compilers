program desk;
{ Modifications by Gerald McMullon }
CONST
 fieldreal = 10;  precision = 4;
 pi        = 3.141592746;
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
 nextchar             : CHAR;
 nextposchar          : position;
 invrad,maxreal,
 result,prevresult    : REAL;
 validset,
 digits,addingops,
 multops,terminators  : charset;
 memory               : ARRAY[zero..nine] OF REAL;

PROCEDURE readchar;
BEGIN
  REPEAT
   IF eof THEN nextchar := semicolon
          ELSE IF eoln THEN BEGIN
                             nextposchar := 1;
                             nextchar    := comma;
                             readln;
                            END
                       ELSE BEGIN
                             nextposchar := succ(nextposchar);
                             read(nextchar);
                            END;
  UNTIL nextchar <> blank;
END;   { readchar }

PROCEDURE reporterror;
 BEGIN
  writeln(marker:nextposchar);
  WHILE NOT (nextchar IN terminators) DO
        readchar;
 END;  { reporterror }

FUNCTION errorfunction(fname : six): REAL;
 BEGIN
  writeln(fname,' out of range.');
  WHILE NOT (nextchar IN terminators) DO
        readchar;
  errorfunction := 0;
 END;

FUNCTION tan(x : REAL): REAL;
 VAR y : REAL;
 BEGIN
  y := cos(x);
  IF y=0 THEN tan:= errorfunction('  tan ')
         ELSE tan:= sin(x)/y;
 END;

FUNCTION arcsin(x: REAL): REAL;
 CONST
  epsilon = 1.0E-8;    { machine and language dependant }
 VAR func1, func, term, n : REAL;
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
                         arcsin := func;
                        END;
  END;   { function arcsin }

FUNCTION arccos(x : REAL): REAL;
 BEGIN
  arccos := pi/2 - arcsin(x);
 END;    { function arccos }

FUNCTION expo(x : REAL ): REAL;
 BEGIN
  IF abs(x) < (maxreal- 1.0E-4)
     THEN expo := exp(x)
     ELSE expo := errorfunction('   exp');
 END;   {some versions of Pascal return exp(89) as 0}

FUNCTION sinh(x: REAL): REAL;
 VAR y : REAL;
 BEGIN
  y := expo(x);
  IF y = 0 THEN sinh := 0
           ELSE sinh := (y-1/y)/2;
 END;   { function sinh }

FUNCTION cosh(x : REAL): REAL;
 VAR y : REAL;
 BEGIN
  y := expo(x);
  IF y = 0 THEN cosh := 0
           ELSE cosh := (y+1/y)/2;
 END;   { function cosh }

FUNCTION tanh(x : REAL): REAL;
 VAR y : REAL;
 BEGIN
  IF (abs(x) < maxreal/2)
  THEN BEGIN
        y:= sqr(expo(x));
        tanh := (y-1)/(y+1);
       END
   ELSE tanh := 1;
 END;  { function tanh }

PROCEDURE displaymemory;
 VAR count      : zero..nine;
 PROCEDURE show;
  BEGIN
   IF (abs(memory[count])>1.0E-4) AND (abs(memory[count])<1.0E+7)
   THEN write('M',count,blank,memory[count]:fieldreal:precision)
   ELSE write('M',count,blank,memory[count]);
  END;

 BEGIN
  readln;
  writeln(chr(31),'Memory');
  FOR count := zero TO nine DO
      BEGIN
       show;
       writeln;
      END;  { format in pairs using screen cursor ?? }
END;  { displaymemory }

PROCEDURE clearmemory;
 VAR count : zero..nine;
 BEGIN
  FOR count := zero TO nine DO
      memory[count] := 0;
 END;  { clearmemory }

PROCEDURE listfunctions;

BEGIN
  writeln(chr(31));   { clear screen }
  writeln(blank:10,'Scientific desk calculator');
                      { select RAM characters then select ROM ??}
  writeln('The following functions are allowed :- ');
  writeln('four rules of arithmetic +,-,*,/       pi = ',
           pi:fieldreal:precision,point);
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
          'arccos(.)the inverse of cosine.      ');  writeln('tan( . ) the tangent of a number.    ',
          'arctan(.)the inverse of tangent.     ');
  writeln('sinh( . ) hyperbolic sine.           ',
          'cosh( . ) hyperbolic cosine.         ');
  writeln('tanh( . ) hyperbolic tangent.        ');
  readln;
  nextposchar := 1;
END;

PROCEDURE readnumber(VAR numvalue : REAL);
TYPE
 scalefactor = 0..maxscale;
VAR
 count, scale : scalefactor;
BEGIN
 numvalue := 0;
 WHILE nextchar IN digits DO
       BEGIN
        numvalue := radix*numvalue+ ord(nextchar)-ord(zero);
        readchar;
       END;  { WHILE }
 IF nextchar = point
    THEN BEGIN
          readchar;
          scale  := 0;
          WHILE nextchar IN digits DO
                BEGIN
                 numvalue := radix*numvalue+ord(nextchar)-ord(zero);
                 readchar;
                 scale    := succ(scale);
                END;  { WHILE }
           FOR count := 1 TO scale DO
               numvalue := numvalue/radix;
          END;
END;  { readnumber }

PROCEDURE readexpression(VAR expvalue : REAL);
 VAR
  addop       : CHAR;
  nexttermval : REAL;
 PROCEDURE readterm(VAR termvalue : REAL);
  VAR
   mulop       : CHAR;
   nextfacval  : REAL;
  PROCEDURE readfactor(VAR factorvalue : REAL);

   PROCEDURE getfunction(VAR factorvalue : REAL);
    VAR
     fname    : six;
     i        : 0..6;
    BEGIN
     i := 0;
     fname := '      ';
     REPEAT
      i := succ(i);
      fname[i] := nextchar;
      readchar;
     UNTIL (i=6) OR (nextchar= leftparen);
     IF nextchar = leftparen THEN readfactor(factorvalue)
        ELSE BEGIN
              reporterror;
              factorvalue := 0;
             END;
     IF fname = 'sin   ' THEN factorvalue:=sin(factorvalue*invrad)        ELSE IF fname='cos   ' THEN factorvalue:=cos(factorvalue*invrad)
        ELSE IF fname='tan   ' THEN factorvalue:=tan(factorvalue*invrad)
        ELSE IF fname='exp   ' THEN factorvalue:=expo(factorvalue)
        ELSE IF fname='ln    ' THEN factorvalue:=    ln(factorvalue)
        ELSE IF fname='sqr   ' THEN factorvalue:=   sqr(factorvalue)
        ELSE IF fname='sqrt  ' THEN factorvalue:=  sqrt(factorvalue)
        ELSE IF fname='arctan' THEN factorvalue:=arctan(factorvalue)/invrad
        ELSE IF fname='arcsin' THEN factorvalue:=arcsin(factorvalue)/invrad
        ELSE IF fname='arccos' THEN factorvalue:=arccos(factorvalue)/invrad
        ELSE IF fname='sinh  ' THEN factorvalue:=  sinh(factorvalue)
        ELSE IF fname='cosh  ' THEN factorvalue:=  cosh(factorvalue)
        ELSE IF fname='tanh  ' THEN factorvalue:=  tanh(factorvalue)
        ELSE BEGIN
              reporterror;
              factorvalue := 0;
             END;
    END;  { getfunction }

    BEGIN  { readfactor }
     IF nextchar IN validset THEN
     CASE nextchar OF
      zero,'1','2','3','4','5','6','7','8',nine
     {zero..nine} : readnumber(factorvalue);
      'p','P'     : BEGIN
                     readchar;
                     IF (nextchar IN ['i','I'])
                        THEN BEGIN
                              factorvalue := pi;
                              readchar;
                             END
                        ELSE factorvalue := prevresult;
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
                                           THEN nextchar := question;
                                       END;
                            'l','L'  : BEGIN
                                        displaymemory;
                                        nextposchar := 1;
                                        nextchar    := question;
                                       END;
                            'c','C'  : BEGIN
                                        clearmemory;
                                        readchar;
                                       END;
                           END { CASE }
                     ELSE reporterror;
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
                        ELSE reporterror;
                    END;
       'd','D'    : BEGIN
                     IF invrad > 0.9 THEN invrad := pi/deg
                                     ELSE invrad := 1;
                     readln;
                     nextposchar:= 1;
                     nextchar   := question;
                    END;
        question  : listfunction;
        'a','c','e','l','s','t': getfunction(factorvalue);
      END  { CASE }
      ELSE BEGIN
            reporterror;
            factorvalue := 0;
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
                        ELSE termvalue := termvalue/nextfacval;
          END;  { CASE }
         END;  { WHILE }
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
         END; {case }
        END;  { WHILE } END;  { readexpession }

BEGIN                           { calculator }
 digits     := [zero..nine];
 addingops  := [plus,minus];
 multops    := [multply,divide];
 terminators:= [comma,semicolon];
 validset := digits+[,'D','M','P','R','a','c','d','e','l','m','p','r',
                         's','t',leftparen,question];
 writeln('Calculator ready.');
 invrad := pi/deg;
 maxreal:= 126*ln(2);  { machine and language dependant }
 prevresult := 0;
 nextposchar:= 1;
 clearmemory;
 readchar;
 WHILE nextchar <> semicolon DO
   BEGIN
    readexpression(result);
    IF nextchar IN terminators
       THEN BEGIN
             IF (abs(result)>1.0E-4) AND (abs(result)<1.0E+7) OR (result=0)
                THEN writeln(result:fieldreal:precision)
                ELSE writeln(result);
             prevresult := result;
            END
       ELSE IF nextchar <> question THEN reporterror;
     readchar;
    END;  { WHILE }
END.  { desk }
 