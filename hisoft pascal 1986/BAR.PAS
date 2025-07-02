{$t,y,l-,d4000}

PROGRAM Bar;

{ This is the program that produced the cover page of the GSX documentation.
  The main program is very artificial since it uses random numbers for the
  data and the shading. However you may find the procedures pat and bar3 useful.
  Note that one of the messages is not displayed on the screen properly since
  setrotation is called.

  use BAR.SUB to compile this }

CONST title1len=8;
	title2len=8;
	textmlen=30;	
	bwidth=2000;	

TYPE point= RECORD x,y:INTEGER END;
   
VAR

{$F GSXVAR }

	h,p1,p2,p3:INTEGER;
	handle,count : INTEGER;
	i:INTEGER;
	x1,y1,x2,y2:INTEGER;
	cx,cy:REAL;
	title1: ARRAY[1..title1len] OF CHAR;
	title2: ARRAY[1..title2len] OF CHAR;
	textm:  ARRAY[1..textmlen] OF CHAR;
	lab:	CHAR;

{$F GSXLIB }

{ This procedure sets the fill index and style according to its single
  parameter 1 corresponds to (2,1)
	    2             to (2,2)
	    6		  to (2,6)
	    7		  to (3,1)
	   12		  to (3,6)
}
PROCEDURE pat(j:INTEGER);
BEGIN
	i:=setfillindex(handle,j DIV 6 + 2);
	i:=setfillstyle(handle,(j-1) MOD 6 + 1);
END;
	
FUNCTION rno:INTEGER;
VAR i:INTEGER;
BEGIN
  i:=ENTIER(RANDOM*9+1);
  IF i>7 THEN i:=i+1;
  rno:=i
END;
  
{ Draws a pseudo 3 dimensional bar starting at x1,0. y1 units high width bwidth
  with the rectangles printed in colours p1,p2 and p3}
PROCEDURE bar3(x1,y1,p1,p2,p3,bwidth:INTEGER);
VAR p: ARRAY[0..3] OF point;
BEGIN
 pat(p1);
 bar(handle,x1,5000,x1+bwidth,y1);
 p[0].x:=x1;  p[0].y:=y1;
 p[1].x:=x1+bwidth; p[1].y:=y1;
 p[2].x:=x1+ 3 * bwidth DIV 2; p[2].y:=y1 + bwidth DIV 2;
 p[3].x:=x1+ bwidth DIV 2; p[3].y:=y1 + bwidth DIV 2;
 pat(p2);
 fillarea(handle,4,ADDR(p));
 p[0].x:=p[1].x;p[0].y:=5000;
 p[3].x:=p[2].x;p[3].y:=5000 + bwidth DIV 2;
 pat(p3);
 fillarea(handle,4,ADDR(p));
END;
 
BEGIN
  openwork(handle,1,1,1,1,1,1,1,1,1,1);
  title1:='Regional';
  title2:='Analysis';
  setcharheight(handle,700,x1,y1,x2,y2);
  gtext(handle,1000,29000,ADDR(title1),title1len);
  gtext(handle,3500,26000,ADDR(title2),title2len);
 
 FOR count:=0 TO 7 DO
	BEGIN
	h:=ENTIER(RANDOM*25000)+5000;
	p1:=rno;
	REPEAT p2:=rno UNTIL p1<> p2;
	REPEAT p3:=rno UNTIL (p1<>p3) AND (p3<> p2);
	BEGIN
	bar3(count*(bwidth+1500),h,p1,p2,p3,bwidth);
	lab:=CHR(ORD('A')+count);
	gtext(handle,count*(bwidth+1500)+700,3500,ADDR(lab),1);
	END;

	END;
 i:=setrotation(handle,2700);
 textm:='1986 figures.  000''s of units.';
 gtext(handle,27000,22000,ADDR(textm),textmlen);
  READLN;
  closework(handle)
END.
 
'1986 figures.  000''s of units.';
 gtext(handle,27000,22000,ADDR(textm),textmlen);
  READLN;
  closework(handle)
END.
 