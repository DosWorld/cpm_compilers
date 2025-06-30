/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 6)			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/31/81			*/
/********************************************************/

/* Note: Uncomment the following lines if you are using M80
#include "qstdio.h"
#include "cstddef.h"
#include "cglbdecl.c"
*/

/*					*/
/*	I/O, Error, and ASM routines	*/
/*					*/

/*					*/
/*	Get the next input file 	*/
/*					*/
getinfil()
	{
	if (holdinput) {
		input = holdinput;	/* switch back to an input file */
		holdinput = 0;		/* interrputed by a #include */
		strcpy(infil, holdfil);
		lineno = holdlineno;
		}
	else if (ninfils--) {		/* any more input files? */
		getfilname(*infilptr++, infil, "C");
		if ((input = fopen(infil,"r")) == NULL)
			cantopen(infil);
		lineno = 0;
		}
	else				/* we've got them all */
		eof = TRUE;
	}
/*					*/
/*	Open output file		*/
/*					*/
getoutfil()
	{
	if (output == stderr)		/* output to console */
		return;
	if ((output = fopen(outfil, "w")) == NULL)
		cantopen(outfil);
	}
/*					*/
/*	Close the output file		*/
/*					*/
closeout()
	{
	if(output != stderr) {
		if(fclose(output) == ERROR) {
			output = stderr; /* send error meassage to console */
			error("Can't close output file");
			}
		output = stderr; /* any more output will go to console */
		}
	}

/* getfilname - get file name, optionally append extension */

getfilname(s, filname, ext)
char *s, *filname, *ext;
	{
	register i;
	register char *ptr;
	ptr = filname;
	i = 0;
	while (*s && ++i <= FILNAMSIZE)
		*ptr++ = chupper(*s++);
	*ptr = '\0';
	if (index(filname, '.') == NULL && ++i < FILNAMSIZE) {
		*ptr++ =  '.';			/* no extension given */
		while (*ext && ++i <= FILNAMSIZE) /* use .EXT */
			*ptr++ = chupper(*ext++);
		*ptr = '\0';
		}
	}
/*					*/
/*	Open an include file		*/
/*					*/
doinclude()
	{
	int delim;
	register i;
	char filname[FILNAMSIZE + 1];

	if (match("\""))
		delim = '"';
	else if (match("<"))
		delim = '>';
	else {
		error("Missing delimeter: \" or <");
		delim = '\0';
		}
	for (i = 0; ch() != delim && i <= FILNAMSIZE; ++i) {
		if ((filname[i] = chupper(gch())) == '\0') {
			errname("Missing delimeter", &delim);
			break;
			}
		}
	filname[i] = '\0';
	holdinput = input;	/* remember the file we interrupted */
	if ((input = fopen(filname, "r")) == NULL) {
		fputs("#include file -- ", stderr);
		cantopen(filname);
		}
	holdlineno = lineno;	/* switch input file and include file */
	strcpy(holdfil, infil);
	lineno = 0;
	strcpy(infil, filname);
	kill(); 		/* clear rest of line so next read */
				/* will come from #include file */
	}
/*					*/
/*	Get the next line of input	*/
/*					*/
inline()
	{
	register int c;
	for (;;) {		/* find a non-empty line or EOF */
		if (eof)
			return;
		kill(); 		/* clear the input line */
		++lineno;
		while ((c = getc(input)) != EOF) {
			if (c == '\n' || lptr-line >= LINEMAX)
				break;
			*lptr++ = c;
			}
		*lptr = '\0';		/* terminate the line */
		if (c == EOF) {
			fclose(input);	/* all thru with this one */
			getinfil();	/* get the next input file */
			}
		if(lptr != line) {	/* anything on this line? */
			if(fullist && cmode) {
				comment(); /* print C text */
				outstr(line);
				nl();
				}
			lptr = line;	/* reset line to beginning */
			return;
			}
		}
	}
/*					*/
/*	Write a character on the	*/
/*	output file or the console	*/
/*					*/
outbyte(c)
int c;
	{
	midline = (c!='\n');	/* remember if in middle of line */
	testdone = FALSE;	/* turn off when anything written */
	if (c == '!' && codeflag == 'a')
		c = '#';	/* translate ! to # for ASM/MAC */
	if (putc(c, output) == ERROR) {
		closeout();
		error("Output file error");
		}
	return c;
	}
/*					*/
/*	Put a string out via outbyte	*/
/*					*/
outstr(ptr)
char *ptr;
	{
	while (*ptr)
		outbyte(*ptr++);
	}
/*					*/
/*	Print a newline character	*/
/*					*/
nl()
	{
	outbyte('\n');
	}
/*					*/
/*    Print a string with a leading TAB */
/*					*/
ot(s)
char *s;
	{
	outbyte('\t');
	outstr(s);
	}
/*					*/
/*	Print a line beginning with a	*/
/*	TAB and ending with newline	*/
/*					*/
ol(s)
char *s;
	{
	ot(s);
	nl();
	}
/*					*/
/*	Generate trace message		*/
/*					*/
gentrace(inout, funcname)
char inout, *funcname;
	{
	int lab1, lab2;
	jump(lab1 = getlabel());	/* jump over trace message */
	linelabel(lab2 = getlabel());	/* label for trace message */
	defbyte();			/* build trace message */
	outdec(inout);			/* enter (>) or exit (<) */
	while (*funcname) {		/* print function name */
		outbyte(',');
		outdec(*funcname++);
		}
	outstr(",10,0");		/* finish trace message */
	linelabel(lab1);		/* set up call to prt message */
	cpush();			/* save primary register */
	pimmed();			/* load address of message */
	printlabel(lab2);
	nl();
	cpush();			/* put on stack as arg */
	ccall("puts");			/* print message */
	poppreg();			/* clear arg off stack */
	poppreg();			/* restore primary register */
	}

/* Print an erroneous line with a pointer (^) to	*/
/*	the location where the error was discovered	*/
/*	and a message describing the error		*/

error(mesg)
char *mesg;
	{
	errptr();
	outstr(mesg);
	nl();
	}
errname(mesg,name)
char *mesg,*name;
	{
	errptr();
	outstr(mesg);
	outstr(": ");
	outstr(name);
	nl();
	}
errptr()
	{
	register char *ptr;
	++errcnt;
	comment(); outstr(line); nl();	/* print erroneous line */
	comment();
	ptr = line;
	while (ptr < lptr)		/* get to error location */
		outbyte((*ptr++ == '\t') ? '\t': ' ');
	outstr("^\n");			/* print error pointer ^ */
	outstr(";**** <");		/* start error message line */
	if (holdinput) {		/* are we in a #include file? */
		outstr(holdfil);	/* interrupted file name */
		outstr("> @ ");
		outdec(holdlineno);	/* interrupted line number */
		outstr(": #include <");
		}
	outstr(infil);			/* current file name */
	outstr("> @ ");
	outdec(lineno); 		/* line number of error */
	outstr(": ");
	}

/*	Common error messages		*/

scerr()
	{
	error("Invalid storage class");
	}
typerr()
	{
	error("Invalid type");
	}
ptrerr()
	{
	error("Illegal use of pointers");
	}
illname()
	{
	error("Illegal symbol name");
	junk();
	}
needlval()
	{
	error("Must be lvalue");
	}
arrayerr()
	{
	notavail("array of pointers");
	}
notavail(feature)
char *feature;
	{
	errname("Not implemented", feature);
	}
multidef(sname)
char *sname;
	{
	errname("Already defined", sname);
	}
needpunc(str)
char *str;
	{
	if(!match(str))
	    errname("Missing punctuation -- assumed present",str);
	}
/*					*/
/* Test two strings for equality up to	*/
/*	the end of the second string	*/
/*					*/
streq()
	{
#asm
;streq(s1, s2)
;char *s1, *s2;
	POP	B	;return address
	POP	D	;s2
	POP	H	;s1
	PUSH	H	;restore stack
	PUSH	D
	PUSH	B
	MVI	B,0	;init match length counter
ccstlp: LDAX	D	;current char of s2
	ORA	A	;is this end-of-string (0)?
	JZ	ccsteq	;they match to end-to-string
	CMP	M	;compare to current char of s1
	JNZ	ccstne	;they don't match here
	INX	D	;get to next char of s2
	INX	H	;same for s1
	INR	B	;count one more char matched
	JMP	ccstlp	;repeat loop
#endasm
	}
/*					*/
/* Test two strings for equality of	*/
/*	contents up to len (<256)	*/
/*					*/
astreq()
	{
#asm
;astreq(s1, s2, len)
;char *s1, *s2;
;int len;
	POP	PSW	;return address
	POP	B	;length
	POP	D	;s2
	POP	H	;s1
	PUSH	H	;restore stack
	PUSH	D
	PUSH	B
	PUSH	PSW
	MVI	B,0	;init match length counter (max = 255)
ccaslp: DCR	C
	JM	ccasan	;strings match to specified length
	LDAX	D	;current char of s2
	ORA	A	;is this end-of-string (0)?
	JZ	ccasan	;they match to end-to-string
	CMP	M	;compare to current char of s1
	JNZ	ccstne	;they don't match here
	INX	D	;get to next char of s2
	INX	H	;same for s1
	INR	B	;count one more char matched
	JMP	ccaslp	;repeat loop
ccasan: MOV	A,M	;is next char in s1 alphanumeric?
	CPI	48	;'1'
	JC	ccsteq	;< 1
	CPI	58	;'9' + 1
	JC	ccstne	;numeric
	ORI	32	;convert upper case to lower
	CPI	97	;'a'
	JC	ccsteq
	CPI	123	;'z' + 1
	JC	ccstne	;lower case alpha
ccsteq: MOV	L,B	;set matched length in return
	MVI	H,0
	RET
ccstne: LXI	H,0	;set FALSE
	RET
#endasm
	}
