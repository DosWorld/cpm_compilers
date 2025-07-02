{ GSXLIB.PAS  HiSoft Pascal80 GSX Library 
  (C) Copyright HiSoft 1986
   written by David Nutkins }

{$A-,O-,C-,S-  checks off to reduce code size }

PROCEDURE gsx;
VAR dummy:INTEGER;
BEGIN
 dummy:=CPM(115,ADDR(pblock))
END;


PROCEDURE openwork(VAR handle:INTEGER; device,linetype,linecolor,marker,
	markercolor,textface,textcolor,fillstyle,
	fillindex,fillcolor:INTEGER);

BEGIN
 pblock[0]:=ADDR(contrl);
 pblock[1]:=ADDR(intin);
 pblock[2]:=ADDR(ptsin);
 pblock[3]:=ADDR(intout);
 pblock[4]:=ADDR(ptsout);

 contrl[0]:=1;
 contrl[1]:=0;
 contrl[3]:=10;

 intin[0]:=device;
 intin[1]:=linetype;
 intin[2]:=linecolor;
 intin[3]:=marker;
 intin[4]:=markercolor;
 intin[5]:=textface;
 intin[6]:=textcolor;
 intin[7]:=fillstyle;
 intin[8]:=fillindex;
 intin[9]:=fillcolor;

 gsx;
 handle:=contrl[6]
END;

PROCEDURE closework(handle:INTEGER);
BEGIN
 contrl[0]:=2;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[6]:=handle;
 gsx;
END;

PROCEDURE clearwork(handle:INTEGER);
BEGIN
 contrl[0]:=3;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[6]:=handle;
 gsx;
END;

PROCEDURE updatework(handle:INTEGER);
BEGIN
 contrl[0]:=4;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[6]:=handle;
 gsx;
END;


PROCEDURE inqcharcells(handle:INTEGER; VAR rows,columns:INTEGER);
BEGIN
 contrl[0]:=5;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[5]:=1;
 contrl[6]:=handle;
 gsx;
 rows:=intout[0];
 columns:=intout[1];
END;

PROCEDURE gsxesc(i,handle:INTEGER);
BEGIN
 contrl[0]:=5;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[5]:=i;
 contrl[6]:=handle;
 gsx;
END;

{Switches the cursor off on the Joyce }
PROCEDURE exitalpha(handle:INTEGER);
BEGIN
 gsxesc(2,handle)
END;

{Switches the cursor on on the Joyce }
PROCEDURE enteralpha(handle:INTEGER);
BEGIN
 gsxesc(3,handle)
END;

{ Alpha cursor Up }
PROCEDURE cursorup(handle:INTEGER);
BEGIN
 gsxesc(4,handle)
END;

{ Alpha cursor Down }
PROCEDURE cursordown(handle:INTEGER);
BEGIN
 gsxesc(5,handle)
END;

{Alpha Cursor Right }
PROCEDURE cursorright(handle:INTEGER);
BEGIN
 gsxesc(6,handle)
END;

{ Alpha cursor left }
PROCEDURE cursorleft(handle:INTEGER);
BEGIN
 gsxesc(7,handle)
END;


{ Alpha cursor home }
PROCEDURE cursorhome(handle:INTEGER);
BEGIN
 gsxesc(8,handle)
END;


{ Erase to end of screen }
PROCEDURE eraseEOS(handle:INTEGER);
BEGIN
 gsxesc(9,handle)
END;

{ Erase to end of line }
PROCEDURE eraseEOL(handle:INTEGER);
BEGIN
 gsxesc(10,handle)
END;

{Direct cursor adddress }
{   top left is (1,1) }
PROCEDURE curaddress(handle,row,column:INTEGER);
BEGIN
 contrl[0]:=5;
 contrl[1]:=0;
 contrl[3]:=2;
 contrl[5]:=11;
 contrl[6]:=handle;
 intin[0]:=row;
 intin[1]:=column;
 gsx;
END;


PROCEDURE curtext(handle,string,size:INTEGER);
VAR i:INTEGER;
BEGIN
 FOR i:=0 TO size-1 DO intin[i]:=ORD(PEEK(string+i,CHAR));
 contrl[0]:=5;
 contrl[1]:=0;
 contrl[3]:=size;
 contrl[5]:=12;
 contrl[6]:=handle;
 gsx;
END;

{ Inverse video on }
PROCEDURE rvseon(handle:INTEGER);
BEGIN
 gsxesc(13,handle)
END;

{ Inverse video off }
PROCEDURE rvseoff(handle:INTEGER);
BEGIN
 gsxesc(14,handle)
END;

{ returns the current cursor address }
PROCEDURE inqcuraddress(handle:INTEGER; VAR row,column:INTEGER);
BEGIN
 contrl[0]:=5;
 contrl[1]:=0;
 contrl[3]:=0;
 contrl[5]:=15;
 contrl[6]:=handle;
 gsx;
 row:=intout[0];
 column:=intout[1];
END;

{ Displays the graphics cursor at (x,y) }
PROCEDURE dspgrcursor(handle,x,y:INTEGER);
BEGIN
 contrl[0]:=5;
 contrl[1]:=1;
 contrl[3]:=0;
 contrl[5]:=18;
 contrl[6]:=handle;
 ptsin[0]:=x;
 ptsin[1]:=y;
 gsx;
END;

{ Remove last graphics cursor  }
PROCEDURE remgrcursor(handle:INTEGER);
BEGIN
 gsxesc(19,handle)
END;


{ Draws count lines using the points in the pxyarray }
PROCEDURE polyline(handle,count,pxyarray :INTEGER);
VAR i:INTEGER;
BEGIN
 contrl[0]:=6;
 contrl[1]:=count;
 contrl[3]:=0;
 contrl[6]:=handle;
 FOR i:=0 TO count*2-1 DO
   ptsin[i]:=PEEK(pxyarray+i*2,INTEGER);
 gsx;
END;

{ Draws count markers using the points in the pxyarray }
PROCEDURE polymarker(handle,count,pxyarray :INTEGER);
VAR i:INTEGER;
BEGIN
 contrl[0]:=7;
 contrl[1]:=count;
 contrl[3]:=0;
 contrl[6]:=handle;
 FOR i:=0 TO count*2-1 DO
   ptsin[i]:=PEEK(pxyarray+i*2,INTEGER);
 gsx;
END;


PROCEDURE gtext(handle,x,y,string,size:INTEGER);
VAR i:INTEGER;
BEGIN
 FOR i:=0 TO size-1 DO intin[i]:=ORD(PEEK(string+i,CHAR));
 contrl[0]:=8;
 contrl[1]:=1;
 contrl[3]:=size;
 contrl[5]:=12;
 contrl[6]:=handle;
 ptsin[0]:=x;
 ptsin[1]:=y;
 gsx;
END;

PROCEDURE fillarea(handle,count,pxyarray :INTEGER);
VAR i:INTEGER;
BEGIN
 contrl[0]:=9;
 contrl[1]:=count;
 contrl[3]:=0;
 contrl[6]:=handle;
 FOR i:=0 TO count*2-1 DO
   ptsin[i]:=PEEK(pxyarray+i*2,INTEGER);
 gsx;
END;

PROCEDURE bar(handle,x1,y1,x2,y2:INTEGER);
BEGIN
 contrl[0]:=11;
 contrl[1]:=2;
 contrl[3]:=0;
 contrl[5]:=1;
 contrl[6]:=handle;

 ptsin[0]:=x1;
 ptsin[1]:=y1;
 ptsin[2]:=x2;
 ptsin[3]:=y2;

 gsx
END;

PROCEDURE setcharheight(handle,yheight:INTEGER; 
			 VAR setx,sety,cellx,celly:INTEGER);
BEGIN
 contrl[0]:=12;
 contrl[1]:=1;
 contrl[3]:=0;
 contrl[6]:=handle;

 ptsin[0]:=0;
 ptsin[1]:=yheight;

 gsx;

 setx :=ptsout[0];
 sety :=ptsout[1];
 cellx:=ptsout[2];
 celly:=ptsout[3];

END;

{ not on Joyce }
FUNCTION setrotation(handle,angle:INTEGER):INTEGER;
BEGIN
 contrl[0]:=13;
 contrl[1]:=0;
 contrl[3]:=1;
 contrl[6]:=handle;

 intin[0]:=angle;

 gsx;

 setrotation:=intout[0];

END;

PROCEDURE colour(handle,index,red,green,blue:INTEGER);
BEGIN
 contrl[0]:=14;
 contrl[1]:=0;
 contrl[3]:=4;
 contrl[6]:=handle;

 intin[0]:=index;
 intin[1]:=red;
 intin[2]:=green;
 intin[3]:=blue;

 gsx
END;

FUNCTION gsxstyle(opcode,handle,style:INTEGER):INTEGER;
BEGIN
 contrl[0]:=opcode;
 contrl[1]:=0;
 contrl[3]:=1;
 contrl[6]:=handle;
 intin[0]:=style;
 gsx;
 gsxstyle:=intout[0]
END;

FUNCTION setlinetype(handle,style:INTEGER):INTEGER;
BEGIN
 setlinetype:=gsxstyle(15,handle,style)
END;

FUNCTION setlinecolour(handle,index:INTEGER):INTEGER;
BEGIN
 setlinecolour:=gsxstyle(17,handle,index)
END;

FUNCTION setmarktype(handle,symbol:INTEGER):INTEGER;
BEGIN
 setmarktype:=gsxstyle(18,handle,symbol)
END;

FUNCTION setmarkheight(handle,yheight:INTEGER):INTEGER;
BEGIN
 contrl[0]:=19;
 contrl[1]:=1;
 contrl[3]:=0;
 contrl[6]:=handle;

 ptsin[0]:=0;
 ptsin[1]:=yheight;

 gsx;

 setmarkheight:=ptsout[1];

END;

FUNCTION setmarkcolour(handle,style:INTEGER):INTEGER;
BEGIN
 setmarkcolour:=gsxstyle(20,handle,style)
END;

FUNCTION settextcolour(handle,index:INTEGER):INTEGER;
BEGIN
 setmarkcolour:=gsxstyle(22,handle,index)
END;

FUNCTION setfillinterior(handle,style:INTEGER):INTEGER;
BEGIN
 setfillinterior:=gsxstyle(23,handle,style)
END;

FUNCTION setfillstyle(handle,style:INTEGER):INTEGER;
BEGIN
 setfillstyle:=gsxstyle(24,handle,style)
END;

FUNCTION setfillcolour(handle,index:INTEGER):INTEGER;
BEGIN
 setfillcolour:=gsxstyle(25,handle,index)
END;


FUNCTION getlocator(handle,x,y:INTEGER; VAR xout,yout:INTEGER):CHAR;
BEGIN
 contrl[0]:=28;
 contrl[1]:=1;
 contrl[3]:=0;
 contrl[6]:=handle;

 ptsin[0]:=x;
 ptsin[1]:=y;

 gsx;

 getlocator:=CHR(intout[0]);
 xout:=ptsout[0];
 yout:=ptsout[1]

END;

FUNCTION samplelocator(handle,x,y:INTEGER;
		       VAR xout,yout:INTEGER; VAR c:CHAR):INTEGER;
BEGIN
 contrl[0]:=28;
 contrl[1]:=1;
 contrl[3]:=0;
 contrl[6]:=handle;

 ptsin[0]:=x;
 ptsin[1]:=y;

 gsx;

 c:=CHR(intout[0]);
 xout:=ptsout[0];
 yout:=ptsout[1];
 samplelocator:= contrl[2]+ contrl[4]*2;
END;


PROCEDURE setinputmode(handle,device,mode:INTEGER);
BEGIN
 contrl[0]:=33;
 contrl[1]:=0;
 contrl[3]:=2;
 contrl[6]:=handle;

 intin[0]:=device;
 intin[1]:=mode;

 gsx;
END;

{$A+,O+,C+,S+  checks on again for main program }
ontrl[6]:=handle;

 intin[0]:=device;
 intin[1]:=mode;

 gsx;
END;

{$A+,O+,C+,S+  checks on ag