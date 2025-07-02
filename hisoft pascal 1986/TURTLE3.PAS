{$T,Y

 Compile this program using
   HP TURTLE3
}
{$L-,C-}
PROGRAM turtle;
    
VAR
  Xcor,Ycor,heading : REAL;
  penstatus : BOOLEAN;

PROCEDURE mode(m:INTEGER);
BEGIN
 INLINE(#DD,#7E,2,		{ LD A,(IX+2)	}
        #CD,#5A,#FC,#0E,#BC	{ FIRM #BC0E	}
        )
END;

PROCEDURE pen(i:INTEGER);
BEGIN
 INLINE(#DD,#7E,2,		{ LD A,(IX+2)	}
        #CD,#5A,#FC,#DE,#BB	{ FIRM #BBDE	}
        )
END;

PROCEDURE paper(i:INTEGER);
BEGIN
 INLINE(#DD,#7E,2,		{ LD A,(IX+2)	}
        #CD,#5A,#FC,#E4,#BB	{ FIRM #BBE4	}
        )
END;

PROCEDURE ink(i,c1,c2:INTEGER);
BEGIN
 INLINE(#DD,#7E,6,		{ LD A,(IX+6)	}
	#DD,#46,4,		{ LD B,(IX+4)	}
	#DD,#4E,2,		{ LD C,(IX+2)	}
        #CD,#5A,#FC,#32,#BC	{ FIRM #BC32	}
        )
END;

PROCEDURE plot(X,Y:INTEGER);
BEGIN
 INLINE(#DD,#6E,2,		{ LD L,(IX+2)	}
        #DD,#66,3,		{ LD H,(IX+3)	}
        #DD,#5E,4,		{ LD E,(IX+4)	}
        #DD,#56,5,		{ LD D,(IX+5)	}
        #CD,#5A,#FC,#EA,#BB	{ FIRM #BBEA	}
       )
END;

PROCEDURE line(x,y:INTEGER);
BEGIN
 INLINE(#DD,#6E,2,		{ LD L,(IX+2)	}
        #DD,#66,3,		{ LD H,(IX+3)	}
        #DD,#5E,4,		{ LD E,(IX+4)	}
        #DD,#56,5,		{ LD D,(IX+5)	}
        #CD,#5A,#FC,#F6,#BB	{ FIRM #BBF6	}
       )
END;

PROCEDURE pendown(c:INTEGER);
BEGIN
 penstatus:=TRUE;
 pen(c)
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
BEGIN
 IF penstatus THEN plot(ROUND(Xcor),ROUND(Ycor));
 newX:=Xcor+len*COS(heading*PIby180);
 newY:=Ycor+len*SIN(heading*PIby180);
 IF penstatus THEN line(ROUND(newX),ROUND(newY));
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
 ink(0,24,24);
 ink(1,2,2);
 paper(0);
 pendown(1);
 mode(2);
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

PROCEDURE setcursor(col,row:INTEGER);
BEGIN
 INLINE(#DD,#6E,2,		{ LD L,(IX+2)	}
        #DD,#66,4,		{ LD H,(IX+4)	}
        #CD,#5A,#FC,#75,#BB	{ FIRM #BB75	}
       )
END;

BEGIN
 turtle;
 setcursor(12,0);
 
 WRITE('Hisoft Pascal Turtle Graphics Package Demonstration');
 flower(2);
 setXY(50,200);
 hilbert(10,4,1);
END.
0);
 
 WRITE('Hisoft Pascal Turtle Graphics Package Demonstration');
 flower(2);
 setXY(50,200);
 hilbert(10,4,1);