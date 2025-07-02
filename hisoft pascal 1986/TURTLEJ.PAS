{$T,Y  Compile this program for the PCW 8256/8512  using
   HP TURTLEJ 
 then add the neccessary GSX routines using
   GENGRAF TURTLEJ
  and then run the program using 
   TURTLEJ

 To do this you need GENGRAF.COM, GSX.SYS and ASSIGN.SYS from your Amsoft System discs
 and GSXVAR.PAS, GSXLIB.PAS and DDSCREEN.PRL from your Pascal80 master disc
}
{$L-,C-}
PROGRAM turtle;

VAR 
	
{$F GSXVAR     }

	{these variables are used by the turtle graphics routines }
	Xcor,Ycor,heading : REAL;
	penstatus : BOOLEAN;
	i , handle : INTEGER;

{$F GSXLIB    }


PROCEDURE pendown(c:INTEGER);
BEGIN
 penstatus:=TRUE;
 { the parameter is ignored for compatiblity
  with other HiSoft Turtle graphic routines }
END;

PROCEDURE penup;

BEGIN
 penstatus:=FALSE
END;

PROCEDURE sethd(angle:REAL);
BEGIN
 		heading:=angle
END;

PROCEDURE setXY(X,Y:REAL);
BEGIN
 Xcor:=X;
 Ycor:=Y
END;

PROCEDURE fwd(len:REAL);
CONST PIby180 = 1.745329E-2;
VAR newX,newY:REAL;
	t: ARRAY[1..4] OF INTEGER;
BEGIN
 newX:=Xcor+len*COS(heading*PIby180);
 newY:=Ycor+len*SIN(heading*PIby180);
 IF penstatus THEN 
	BEGIN
	 t[1]:=ROUND(Xcor*50.0); t[2]:=ROUND(Ycor*80.0);
	 t[3]:=ROUND(newX*50.0); t[4]:=ROUND(newY*80.0);
	 polyline(handle,2,ADDR(t))
	END;
 Xcor:=newX;
 Ycor:=newY
END;

PROCEDURE back(len:REAL);
BEGIN
 fwd(-len)
END;

PROCEDURE right(angle:REAL);
BEGIN
 heading:=heading-angle;
END;

PROCEDURE left(angle:REAL);
BEGIN
 heading:=heading+angle;
END;

PROCEDURE turtle;
BEGIN
 openwork(handle,1,1,1,1,1,1,1,1,1,1);
 pendown(1);
 setXY(300,200);
 sethd(0);
END;


PROCEDURE arcr(r:REAL;deg:INTEGER);
VAR i:INTEGER;
BEGIN
 FOR i:=1  TO deg DO
  BEGIN
   fwd(r); right(1)
  END;
END;


PROCEDURE polyspi(side,angle,inc:REAL);
BEGIN
 fwd(side);
 right(angle);
 polyspi(side+inc,angle,inc);
END;

PROCEDURE arcl(r:REAL;deg:INTEGER);
VAR i:INTEGER;
BEGIN
 FOR i:=1 TO deg DO
   BEGIN
    fwd(r); left(1)
   END
END;

PROCEDURE hilbert(len,level,parity:INTEGER);
BEGIN
IF level <> 0 THEN
   BEGIN
      left(parity * 90);
      hilbert(len, level-1, -parity);
      fwd(len);
      right(parity * 90);
      hilbert(len, level-1, parity);
      fwd(len);
      hilbert(len, level-1, parity);
      right(parity * 90);
      fwd(len);
      hilbert(len, level-1, -parity);
      left(parity * 90)
   END
END;


PROCEDURE poly(side,angle:REAL);
BEGIN
 fwd(side); right(angle);
 IF side<180*(2+TRUNC(angle/90))/3 THEN poly(side+1,angle)
END;

PROCEDURE P(X,Y,col:INTEGER;side,angle:REAL);
BEGIN
 pendown(col);
 sethd(0);
 setXY(X,Y);
 poly(side,angle);
END;

PROCEDURE circles;
VAR i:INTEGER;
BEGIN
 FOR i:=1 TO 9 DO
   BEGIN
    arcr(1,360);right(40)
   END;
END;

PROCEDURE petal(s:REAL);
BEGIN
 arcr(s,60);
 right(120);
 arcr(s,60);
 right(120)
END;

PROCEDURE flower(s:REAL);
VAR i:INTEGER;
BEGIN
 FOR i:=1 TO 6 DO 
  BEGIN
   petal(s);
   right(60)
  END
END;

BEGIN
 turtle;
 WRITELN('     HiSoft Turtle Graphics demonstration program');
 FOR i:=1 TO 14 DO WRITELN;
 WRITELN('     Hilbert Curve');
 WRITELN;
 WRITELN('             and 6 Petal Flower');
 setXY(320,200);
 flower(2);
 setXY(50,230);
 hilbert(10,4,1);
 READLN;
 closework(handle)
END.
 and 6 Petal Flower');