/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 4)			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/30/81			*/
/********************************************************/

/* Note: Uncomment the following lines if you are using M80
#include "qstdio.h"
#include "cstddef.h"
#include "cglbdecl.c"
*/

/*					*/
/*	Perform a function call 	*/
/*					*/
/* called from heir15, this routine will*/
/*	either call the named function, */
/*	or if the supplied ptr is zero, */
/*	will call the contents of HL	*/
callfunction(sym)
char *sym;	/* symbol table entry (or 0) */
	{
	register int argspace, op[2], savswap;
	argspace = 0;
	blanks();		/* already saw open paren */
	if (sym == 0 || 	/* if we're calling address in preg or */
	    pregflag)		/* primary reg contains something...*/
		cpush();	/* save it */
	while (!streq(lptr,")")) { /* process all arguments */
		if (endst())
			break;	/* premature end of function call */
		pregflag = 0;	/* start new expression */
		if (heir2(op))	/* get an arg, don't allow (,) */
			rvalp(op); /* operators at this level */
		if (sym == 0)	/* if we're calling address in preg...*/
			swapstk(); /* keep the address on top of stack */
		cpush();	/* push address or argument in preg */
		argspace += 2;	/* compute stack space used */
		if (!match(",")) /* any more arguments? */
			break;
		}
	needpunc(")");
	if (sym)
		ccall(sym+NAME); /* call named function */
	else
		callstk();	/* else call address on top of stack */
	savswap = swapneeded;	/* record previous return value flag */
	pregflag =		/* remember preg contains return value */
	swapneeded = TRUE;	/* tell modstk preg has a value */
	spcc = modstk(argspace); /* clean up arguments */
	swapneeded = savswap;	/* remember previous return value flag */
	}

/*	Flush junk from input line	*/

junk()
	{
	if(isalnum(inbyte()))		/* if curr char is a/n */
		while(isalnum(ch()))	/* flush rest of a/n chars */
			gch();
	else while(!isalnum(ch())) {	/* else flush rest of non-a/n */
		if (endst())		/* chars up to EOL or ';' */
			break;
		gch();
		}
	blanks();			/* find next token */
	}
/*	Test for end of statement	*/
endst()
	{
	blanks();	/* skip white space */
	return (ch() == ';' || ch() == 0);
	}

/*	Look for sname in the global symbol table	*/

findglb(sname)
char *sname;
	{
	register char *ptr;
	ptr = STARTGLB;
	while (ptr < glbptr) {	/* use while loop for speed */
		if (astreq(sname, ptr + NAME, NAMEMAX))
			return ptr;
		ptr += SYMSIZ;
		}
	return NULL;
	}

/*	Look for sname in the local symbol table	*/

findloc(sname)
char *sname;
	{
	register char *ptr;
	for (ptr = STARTLOC; ptr > locptr; ptr -= SYMSIZ)
		if(astreq(sname,ptr+NAME,NAMEMAX))
			return ptr;
	return NULL;
	}

/*	Add sname to the global symbol table		*/

addglb(sname,id,typ,sc,value)
char *sname,id,typ,sc;
int value;
	{
	if (cptr = findglb(sname)) {
		if (cptr[STORAGE] == CEXTDEF && sc == CEXTDEF) {
			multidef(sname); /* already defined */
			return NULL;
			}
		if (sc == CEXTDEF) {	/* this is the definition */
			cptr[STORAGE] = CEXTDEF;
			cptr[INFO] = value;
			}
		if (cptr[IDENT] != id || cptr[TYPE] != typ)
			errname("Inconsistent declaration",cptr);
		return cptr;
		}
	if (glbptr >= locptr) {
		error("Global symbol table overflow");
		return NULL;
		}
	cptr = glbptr;			/* add sname to global table */
	strcpy(cptr + NAME, sname);
	cptr[IDENT] = id;
	cptr[TYPE] = typ;
	cptr[STORAGE] = sc;
	putint(&cptr[INFO], value);
	glbptr +=  SYMSIZ;
	return cptr;
	}

/*	Add sname to the local symbol table		*/

addloc(sname,id,typ,sc,value)
char *sname,id,typ,sc;
int value;
	{
	if (locptr <= glbptr) {
		error("Local symbol table overflow");
		return NULL;
		}
	cptr = locptr;		  /* add sname to local table */
	strcpy(cptr + NAME, sname);
	cptr[IDENT] = id;
	cptr[TYPE] = typ;
	cptr[STORAGE] = sc;
	putint(&cptr[INFO], value);
	locptr -= SYMSIZ;
	return cptr;
	}

/*	Test for legal symbol name		*/

symname(sname)
char *sname;
	{
	register k;
	blanks();
	if (!isalpha(ch()))
		return FALSE;	/* symbol name must begin with alpha */
	k = 0;
	while (isalnum(ch())) {
		if (k++ < NAMEMAX) /* limit size of symbol name */
			*sname++ = ch();
		gch();		/* pass entire name */
		}
	*sname = '\0';
	return TRUE;
	}

/*	Add a statement label to the		*/
/*		local symbol table		*/

addlabel(labname, type)
char *labname;
int type;
	{
	register char *ptr;
	int labno;
	/* check if labname is already in local symbol table */
	if (ptr = findloc(labname)) {
		if (ptr[IDENT] != LABEL) {
			multidef(labname); /* previously */
			return 0;	/* defined as a variable */
			}
		if (ptr[TYPE] == LABEL) {
			if (type == LABEL) /* 2nd definition */
				multidef(labname);
			}
		else /* labname previously used in goto only */
			ptr[TYPE] = type; /* define it now */
		return getint(ptr + INFO); /* return label # assigned */
		}
	/* add labname as a new entry to the local symbol table */
	addloc(labname, LABEL, type, CAUTO, labno = getlabel());
	return labno;
	}

/*	Return next available internal label number	*/

getlabel()
	{
	return (++nxtlab);
	}

/*	Print specified number as label 		*/

printlabel(label)
int label;
	{
	outstr("cc");
	outdec(label);
	}

/*	Print a line label				*/

linelabel(label)
int label;
	{
	if(midline)
		nl();	/* label must be first thing on line */
	printlabel(label);
	outbyte(':');
	}

/*	Print a global label				*/

glblabel(name)
char *name;
	{
	outstr(name);
	outbyte(':');
	if (codeflag == 'm')	/* make PUBLIC for M80 */
		outbyte(':');
	}

/*	Add an entry to the switch/loop queue		*/

addswq(ptr)
int *ptr;
	{
	int k;
	if (pswq >= SWQMAX)
		error("Too many active switches or loops");
	else {
		k = SWQSIZE;
		do {
			*pswq++ = *ptr++;
			} while (--k);
		}
	}

/*	Delete an entry from the switch/loop queue	*/

delswq()
	{
	if(getswq())
		pswq -= SWQSIZE;
	else
		error("No active switches or loops to delete");
	}

/*	Get the most recent entry in the switch/loop queue */

getswq()
	{
	return (pswq == swq) ? NULL: pswq - SWQSIZE;
	}

/*	Add an entry to the switch case table		*/

addcase(entry)
int *entry;
	{
	int k;
	if (pcasetab >= CASEMAX)
		error("Too many switch cases");
	else {
		k = CASESIZE;
		do {
			*pcasetab++ = *entry++;
			} while (--k);
		}
	}

/*	Delete an entry from the switch case table	*/

delcase()
	{
	if (pcasetab > casetab)
		return (pcasetab -= CASESIZE);
	error("No entry in case table to delete");
	return NULL;
	}

/*	Look at current character in parsing buffer	*/

ch()
	{
	return *lptr;
	}

/*	Look at next character in parsing buffer	*/

nch()
	{
	return (*lptr ? *(lptr+1) : 0);
	}

/*	Get current character in parsing buffer 	*/

gch()
	{
	return (*lptr ? *lptr++ : 0);
	}

/*	Clear current line from parsing buffer		*/

kill()
	{
	lptr = line;
	*lptr = '\0';
	}

/*	Get the next character from parsing buffer	*/
/*		refilling buffer first if at EOL	*/

inbyte()
	{
	while(ch() == 0) {
		if (eof) return 0;
		inline();	/* get next line of input */
		preprocess();	/* do any reqd preprocessing */
		}
	return gch();
	}

/* Preprocess input lines by removing	*/
/* comments and excess white space,	*/
/* passing strings and char constants	*/
/* through unchanged, and applying	*/
/* define macros to all the rest	*/

preprocess()
	{
	register char *ptr, sname[NAMESIZE];
	mptr = mline;
	/* first check for preprocessor commands */
	if (ch() == '#' && lptr == line) {/* # must be 1st char */
		if (match("#include")) {
			doinclude();	/* get include file */
			return;
			}
		if (match("#define")) {
			preprocess();	/* strip comments & apply */
			addmac();	/* definitions recursively */
			return;
			}
		}
	while (ch()) {
		if((ch()==' ') || (ch()=='\t')) { /* eliminate excess */
			keepch(' ');		/* white space */
			while((ch()==' ')|| (ch()=='\t'))
				gch();
			}
		else if(symname(sname)) {	/* is it a symbol? */
			if(!(ptr=findmac(sname))) /* macro? */
				ptr=sname;	/* just a name */
			while(*ptr)
				keepch(*ptr++);
			}
		else if(ch()=='/' && nch()=='*') {
			gch();gch();		/* discard comments */
			while(!(ch()=='*' && nch()=='/')) {
				if(gch()==0)	/* if EOL get */
					inline(); /* next line */
				if(eof) break;
				}
			gch();gch();		/* discard end of comment */
			}
		else if(ch()=='"') {
			keepch(gch());		/* pass strings through */
			while(ch()!='"') {	/* unchanged */
				if(ch()==0) {
					error("Missing quote");
					break;
					}
				if(ch()=='\\') { /* pass an escape char */
					if(nch())	/* not EOL */
						keepch(gch());
					else {	/* continue long literal */
						inline();
						continue;
						}
					}
				keepch(gch());
				}
			gch();
			keepch('"');
			}
		else if(ch()=='\'') {
			keepch(gch());	/* pass char constants */
			while(ch()!='\'') {	/* unchanged */
				if(ch()==0) {
					error("Missing apostrophe");
					break;
					}
				if(ch()=='\\')	/* pass an escape char */
					keepch(gch());
				keepch(gch());
				}
			gch();
			keepch('\'');
			}
		else keepch(gch());	/* pass all else unchanged */
		}
	keepch(0);
	if(mptr-mline>=LINEMAX)
		error("Line too long");
	strcpy(lptr=line,mline);
	}

/*	Put a char in macro buffer	*/

keepch(c)
char c;
	{
	return ((mptr-mline)<LINEMAX ? *mptr++ = c: c);
	}

/*	See if name is defined in macro pool	*/

findmac(name)
char *name;
	{
	register char *ptr;
	ptr = macpool;
	while (ptr > pmacsym) {
		if (astreq(name, ptr, NAMEMAX))
			return getint(ptr + MACPTR);
		ptr -= MACSIZE;
		}
	return NULL;
	}

/*	Add a define macro to the macro pool	*/

addmac()
	{
	if (pmacsym <= pmacdef) {
		macfull(); /* can't fit another macro */
		kill(); /* kill rest of line */
		return;
		}
	if (!symname(pmacsym)) { /* valid name? */
		illname();
		kill(); /* kill rest of line */
		return;
		}
	if (findmac(pmacsym)) { /* already defined? */
		multidef(pmacsym);
		kill(); /* kill rest of line */
		return;
		}
	putint(&pmacsym[MACPTR], pmacdef); /* record def loc */
	while (ch() == ' ' || ch() == '\t') /* skip white spc */
		gch();
	while (*pmacdef++ = gch()) { /* copy definition */
		if (pmacdef >= pmacsym) {
			macfull(); /* next char will overflow */
			kill(); /* kill rest of line */
			*(--pmacdef) = NULL; /* end macro def */
			break;
			}
		}
	pmacsym -= MACSIZE; /* point to next entry */
	}

macfull()
	{
	error("Macro (#define) pool is full");
	}

/*	Save val at the location ptr points to		*/

putint(ptr, val)
int *ptr, val;
	{
	*ptr = val;
	}

/*	Get the integer at the location pointed to by ptr */

getint(ptr)
int *ptr;
	{
	return *ptr;
	}
/* Test parse line to see if lit matches */
/*	the next sequence of characters */
/*	and skip over them if it does	*/
match(lit)
char *lit;
	{
	int k;
	blanks();	/* skip white space */
	if (k = streq(lptr, lit)) {
		lptr += k;
		return TRUE;
		}
	return FALSE;
	}
/* Test parse line to see if lit matches */
/*	the next token and skip over it */
/*	if a match is found		*/
amatch(lit)
char *lit;
	{
	int k;
	blanks();
	if (k = astreq(lptr, lit, strlen(lit))) {
		lptr += k;
		while (isalnum(ch()))
			inbyte();
		return TRUE;
		}
	return FALSE;
	}
/*	Skip white space in parse line	*/
blanks()
	{
	int c;
	for(;;) {
		while((c=ch())==0) {	/* if at eol */
			inline();	/* get next line */
			preprocess();
			if(eof) break;
			}
	/* NOTE: The following test ignores \t and \r	*/
	/*	because they are removed by preprocess	*/
	/*	and getc respectively.			*/
		if(c==' ')
			gch();
		else
			return;
		}
	}
/*	Convert an integer to decimal and output it	*/
outdec(number)
int number;
	{
	char s[7];
	outstr(itoa(number,s));
	}
testexp()
	{
	needpunc("(");
	expression();
	needpunc(")");
	}
/* Evaluate a simple constant expression	*/
/*	consisting of integer constants 	*/
/*	connected by the operators: + - *	*/
constexp(val)
int *val;
	{
	int errflag;
	errflag=0;
	*val=constadd(&errflag);
	return (!errflag); /* if no errs, it's a constant expr */
	}
/* Check for constant expression add/subtract */
constadd(errflag)
int *errflag;
	{
	register val;
	val=constmult(errflag);
	for (;;) {
		if(match("+"))
			val += constmult(errflag);
		else if(match("-"))
			val -= constmult(errflag);
		else
			return val;
		}
	}
/* Check for constant expression multiply */
constmult(errflag)
int *errflag;
	{
	register val;
	val=getval(errflag);
	while(match("*"))
		val *= getval(errflag);
	return val;
	}
/* Check for constant or parenthesized constant expression */
getval(errflag)
int *errflag;
	{
	int val;
	if(match("(")) { /* eval parenthesized expression */
		if(!constexp(&val))
			*errflag=1;
		needpunc(")");
		}
	else if(!intconst(&val)) {
		*errflag=1;
		junk();
		}
	return val;
	}
/* Check to see if we have an integer */
/*	constant and return its value */
intconst(val)
int *val;
	{
	return (hex(val) || octal(val) || decimal(val)
		|| charconst(val));
	}
/* Check to see if we have a hexidecimal constant */
/*	If so, compute its value. */
hex(val)
int *val;
	{
	register c, k;

	if(!match("0x") && !match("0X")) /* is it a hex number? */
		return FALSE;
	k = 0;
	for(;;) {
		if(isdigit(ch()))
			k = k * 16 + gch() - '0';
		else if((c=chupper(ch())) >= 'A' && c <= 'F') {
			k = k * 16 + gch() - 'A' + 10;
			}
		else
			break;
		}
	*val = k;
	return TRUE;
	}
/* Check to see if we have a octal constant. */
/* If so, convert the number from ASCII to its value */
octal(val)
int *val;
	{
	register k;
	if (!match("0"))
		return FALSE;
	k = 0;
	while (isdigit(ch()))
		k = k * 8 + gch() - '0';
	*val = k;
	return TRUE;
	}
/* Check to see if we have a decimal constant. */
/* If so, convert the number from ASCII to its value */
decimal(val)
int *val;
	{
	register k;
	int minus;
	match("+");		/* skip over plus sign, if any */
	minus = match("-");
	if (!isdigit(ch()))
		return FALSE;
	k = 0;
	while( isdigit(ch()))
		k = k * 10 + gch() - '0';
	*val = minus ? -k : k;
	return TRUE;
	}
/* Check to see if we have a character constant. */
/* If so, convert it to its numeric equivalent */
charconst(val)
int *val;
	{
	register c, k;
	if (!match("'"))
		return FALSE;		/* not a char constant */
	k = 0;
	while ((c=gch()) != '\'' && c != 0) {
		if (c == '\\')
			c = escape();
		k = (k << 8) + (c & 0xFF);
		}
	*val = k;
	return TRUE;
	}
/* Check to see if we have a string. */
/* If so, add it to the literal pool */
/* and return its location in litpool */
string(val)
int *val;
	{
	register c;
	if (!match("\""))
		return FALSE;		/* not a string */
	*val = plitpool - litpool;	/* offset from start of litpool */
	while ((c = gch()) != '"' && c != 0) {
		if (plitpool >= LITMAX) {
			error("String space exhausted");
			while (!match("\"")) /* discard rest */
				if (gch() == 0) break;
			break;
			}
		*plitpool++ = (c=='\\') ? escape() : c;
		}
	*plitpool++ = '\0';		/* terminate string */
	return TRUE;
	}

/*	Evaluate an escape character constant		*/

escape()
	{
	register c,count,octal;
	switch (c = gch()) {
	case 'f':
		return '\f';
	case 'r':
		return '\r';
	case 'b':
		return '\b';
	case 't':
		return '\t';
	case 'n':
		return '\n';
		}
	if (isdigit(c)) {	  /* octal sequence */
		count = 0;
		octal = c - '0';
		while (isdigit(ch()) && ++count<3)
			octal = octal * 8 + gch() - '0';
		return octal;
		}
	return c;
	}

/*	Check op to see if it is a pointer		*/

ptrtype(op)
int op[];
	{
	register char *sym;
	if (sym = op[0]) {	/* constants (op[0] == 0) are not pointers */
		switch (op[1]) {
		case PTRTOCHAR:
			return PTRTOCHAR;
		case PTRTOINT:
			return PTRTOINT;
		case 0: 	/* check for unloaded pointer or array */
			if (sym[IDENT] == POINTER || sym[IDENT] == ARRAY)
				if (sym[TYPE] == CCHAR)
					return PTRTOCHAR;
				else
					return PTRTOINT;
			}
		}
	return NULL;
	}
