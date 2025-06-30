/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 1)			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/31/81			*/
/********************************************************/

#include "qstdio.h"
#include "cstddef.h"
#include "cglbdef.c"

main(argc,argv)
int argc,argv[];
	{
	puts("C Compiler V1.0  Copyright (c) 1981\
 Quality Computer Systems");
	init(); 		/* get everything set */
	getoptions(argc,argv);	/* get user options */
	getinfil();		/* get input file */
	getoutfil();		/* get output file */
	header();		/* intro code */
	kill(); 		/* clear the input line */
	parse();		/* process ALL input */
	dumplits();		/* then dump literal pool */
	dumpglbs();		/* and all static memory */
	trailer();		/* follow-up code */
	closeout();		/* close the output (if any) */
	summary();		/* print summary statistics */
	exit(errcnt);		/* if errcnt != 0, delete
					SUBMIT file, if any */
	}
/*					*/
/*	Initialize globals		*/
/*					*/
init()
	{
	/* Set the default assembler code generation to ASM/MAC */
	codeflag = 'a';
	/* Establish compiler table sizes */
	symtsize = 150 * SYMSIZ;/* symbol table */
	litpsize = 2000;	/* literal pool */
	macpsize = 750; 	/* macro (#define) pool */
	nswq = 10;		/* max nesting of switch/loop */
	ncases = 50;		/* max number of switch cases */
	/* Obtain compiler table space from free space */
	line = malloc(LINESIZE);
	mline = malloc(LINESIZE);
	pcasetab = casetab = malloc(ncases * CASESIZE * 2);
	pswq = swq = malloc(nswq * SWQSIZE * 2);
	symtab = malloc(symtsize);
	plitpool = litpool = malloc(litpsize);
	pmacdef = malloc(macpsize);
	macpool = pmacsym = pmacdef + macpsize - MACSIZE;
	if (symtab == NULL || plitpool == NULL || pmacdef == NULL) {
		puts("Not enough table space");
		exit(1);
		}

	glbptr = STARTGLB;	/* clear global symbols */
	minlocptr =		/* remember local symtab pointer */
	locptr = STARTLOC;	/* clear local symbols */
	spcc =		/* stack ptr (relative) */
	errcnt =	/* no errors */
	input = 	/* no input file */
	holdinput =	/* input file not held for #include */
	output =	/* no output file */
	ncmp =		/* no open compound statements */
	nxtlab =	/* default = first label is cc1 */
		0;	/* ...all set to zero.... */
	mainflag =	/* no main function found yet */
	eof =		/* not eof yet */
	swapneeded =	/* nothing to save in primary reg */
	swapending =	/* and we haven't saved it */
	testdone=	/* no test just done (e.g. ceq) */
	statflag =	/* default = no summary statistics */
	trace = 	/* default = no trace messages desired */
	fullist =	/* default = don't generate full asm list */
		FALSE;
	cmode = TRUE;	/* start out in C mode */
	}
/*					*/
/*	Get options from command line	*/
/*					*/
getoptions(argc,argv)
int argc,argv[];
	{
	static char *p;
	char defext[4];
	static int rename;

	if(argc < 2)			/* must have at least "cc" + */
		usagerr();		/* one input file name */
	infilptr = argv + 1;		/* 1st input file is 2nd arg */
	ninfils = 0;			/* no input files found yet */
	while (--argc) {		/* count down args */
		p = *++argv;
		if (*p == '-' || *p == '+')
			break;		/* stop at options */
		++ninfils;		/* found another input */
		}
	if (ninfils == 0)
		usagerr();		/* must have an input file */
	getfilname(*infilptr, infil, "C"); /* get first input filename */
	rename = NULL;			/* default: don't rename output */
	if (codeflag == 'm')		/* set default file extension */
		strcpy(defext, "MAC");
	else if (codeflag == 'a')
		strcpy(defext, "ASM");
	while (argc--) {		/* look for options */
		p = *argv++;
		if (*p == '+')		/* starting label # */
			nxtlab = atoi(++p);
		else if (*p == '-') {	/* compile options */
		    while (*++p) {
			switch (chlower(*p)) {
			case 't':	/* generate trace messages */
				trace = TRUE;
				addglb("puts",FUNCTION,CINT,CEXTERN,GLOBAL);
				continue;
			case 'a':	/* CP/M ASM/MAC */
				codeflag = 'a';
				strcpy(defext, "ASM");
				continue;
			case 'c':	/* output to console */
				output = stderr;
				continue;
			case 's':	/* print statistics */
				statflag = TRUE;
				zeromem(); /* zero free memory */
				continue;
			case 'f':	/* full asm listing */
				fullist = TRUE;
				continue;
			case 'm':	/* MACRO-80 code*/
				codeflag = 'm';
				strcpy(defext, "MAC");
				continue;
			case 'o':	/* rename output file */
				rename = 1;
				continue;
			default:
				usagerr();
				}
			}
		    }
		else if (rename == 1) { /* should be new output file name */
			getfilname(p, outfil, defext);
			if (strcmp(infil, outfil) == 0) {
				puts("Output file name same as input");
				exit(1);
				}
			rename = 2;	/* remember we did it */
			}
		else
			usagerr();
		}
	if (rename == 0 && output == 0) { /* use infil.defext as output */
		strcpy(outfil, infil);	  /* start with input filename */
		*(index(outfil, '.') + 1) = 0; /* end file name after '.' */
		strcat(outfil, defext);   /* add default extension */
		}
	else if (rename == 1)		/* new file name not found */
		usagerr();
	litlab = getlabel();		/* first label for literal pool */
	}
usagerr()
	{
	puts("Usage:cc infil ... -acfmost +label# outfil");
	exit(1);
	}
/*					*/
/*	Zero free memory space		*/
/*					*/
zeromem()
	{
	static char *freespace, *ptr;
	auto char stack;
	freespace = malloc(0);		/* beginning of free space */
	ptr = &stack;			/* stack is on stack */
	while (ptr > freespace)
		*--ptr = 0;
	}
/*					*/
/*	Process all input text		*/
/*					*/
parse()
	{
	static sc, type;
	while (!eof) {		/* do until no more input */
		if (chkdecl(&sc, &type)) {	/* is it a declaration? */
			if (type == NULL)
				type = CINT;	/* set default */
			switch (sc) {		/* check storage class */
			case CREG: case CAUTO:
				scerr();	/* invalid storage class */
				goto defsc;
			case CSTATIC:
				notavail("static external variables");
			defsc:
			case NULL:		/* use default */
				sc = CEXTDEF;
				break;
				}
			declglb(sc, type);
			}
		else if (match("#asm"))
			doasm();
		else /* it must be a function definition */
			newfunc();
		blanks();	/* force eof if pending */
		}
	/* see if anything left hanging... */
	if (ncmp)
		/* open compound statement ... */
		error("Unbalanced braces");
	}
/*					*/
/*	Dump the literal pool		*/
/*					*/
dumplits()
	{
	static int j;
	static char *ptr;
	if (plitpool == litpool)
		return; 	/* if nothing there, exit...*/
	linelabel(litlab);	/* print literal label */
	ptr = litpool;
	while (ptr < plitpool) {
		defbyte();	/* pseudo-op to define byte */
		j = 12; 	/* max bytes per line */
		while (j--) {
			outdec(*ptr++);
			if (j == 0 || ptr >= plitpool)
				break;
			outbyte(',');	/* separate bytes */
			}
		nl();
		}
	}
/*					*/
/*	Dump all global variables	*/
/*					*/
dumpglbs()
	{
	static size;
	for (cptr = STARTGLB; cptr < glbptr; cptr += SYMSIZ) {
		if (cptr[IDENT] != FUNCTION &&	/* ignore functions & */
		    cptr[STORAGE] != CEXTERN) { /* extern declarations */
			glblabel(cptr + NAME);
			defstorage();
			size = getint(&cptr[INFO]);
			if(cptr[TYPE] == CINT || cptr[IDENT] == POINTER)
				size += size;	/* double it */
			outdec(size);		/* need that many */
			nl();
			}
		}
	}
/*					*/
/*	Report statistics and errors	*/
/*					*/
summary()
	{
	register char *p;
	if (statflag) { 		/* statistics requested? */
		p = malloc(0);		/* beginning of free space */
		while (*++p == 0);	/* look for bottom of stack */
		printf("Symbol table entries left: %d\n",
			(minlocptr - glbptr) / SYMSIZ, 2);
		puts("Space left (bytes)");
		printf("Literals: %d  Macros: %d  Memory: %d\n",
			litpool + litpsize - plitpool,
			pmacsym - pmacdef + MACSIZE,
			p - malloc(0), 4);
		}
	printf("%d error(s) found", errcnt, 2);
	}
/*					*/
/*	Declare a global variable	*/
/*					*/
/* Makes entries in the symbol table so sub- */
/* sequent references can call symbol by name */
declglb(sc, typ) /* type=CINT|CCHAR; sc=CEXTDEF|CEXTERN */
register sc, typ;
	{
	register int id, size;
	char sname[NAMESIZE];
	do {
		size = 1;		/* assume 1 element */
		id = match("*") ? POINTER : VARIABLE;
		if (!symname(sname))	/* name ok? */
			illname();	/* no... */
		if (match("[")) {	/* array? */
			if (id == POINTER)
				arrayerr(); /* no arrays of pointers */
			id = ARRAY;
			if ((size=needsub()) == 0 && sc == CEXTDEF) {
				error("Need explicit array size");
				size=1; /* force one element */
				}
			}
		addglb(sname, id, typ, sc, size);
		} while (match(","));
	ns();	/* check for closing semicolon */
	}
/*					*/
/*	Declare local variables 	*/
/*	(i.e. define for use)		*/
/*					*/
/* Add variables to the local symbol	*/
/* table with internal symbol name or	*/
/* appropriate offset to find again	*/

declloc(sc, type) /* type=CINT|CCHAR; sc=CSTATIC|CAUTO|CREG|CEXTERN */
register int sc, type;
	{
	register int size, id, info ,tempsc;
	char sname[NAMESIZE];
	do {
		id = (match("*")) ? POINTER : VARIABLE;
		if(!symname(sname))
			illname();
		if(findloc(sname))
			multidef(sname);
		if(match("(")) {	/* is it a function? */
			needpunc(")");
			addloc(sname, FUNCTION, type, CEXTERN, 0);
			addglb(sname, FUNCTION, type, CEXTERN, LOCAL);
			continue;
			}
		size = 1;		/* length of simple variable */
		if (match("[")) {	/* is it an array? */
			if (id == POINTER)
				arrayerr(); /* no arrays of pointers */
			id = ((size = needsub()) || sc == CEXTERN) ?
				ARRAY : POINTER;
			}
		/* figure size of this variable */
		if (id == POINTER)
			size = 2;	/* ptrs are addresses */
		else if (type == CINT)
			size += size;	/* double int's */
		switch (tempsc = sc) {
		case CEXTERN:
			addglb(sname, id, type, CEXTERN, LOCAL);
			continue;
		case CREG:		/* allow only scalar ints & ptrs */
			if (nregvar < MAXREG	/* any more regs? */
			   && ((type == CINT && id != ARRAY)
			      || id == POINTER)) {
				info = ++nregvar; /* assign reg # */
				break;
				}
			tempsc = CAUTO; /* don't put in register */
		case CAUTO:
			info = spcc -= size;
			break;
		case CSTATIC:
			/* assign internal symbol name */
			linelabel(info = getlabel());
			defstorage();
			outdec(size);
			nl();
			break;
			}
		addloc(sname, id, type, tempsc, info);
		} while (match(","));
	ns();				/* check for closing semicolon */
	}
/*					*/
/*	Get required array size 	*/
/*					*/
/* invoked when declared variable is followed */
/*	by "[". this routine makes subscript */
/*	the absolute size of the array	*/
needsub()
	{
	static int num;
	if(match("]"))
		return 0;		/* null size */
	if(!constexp(&num)) { /* evaluate a constant expression */
		error("Array size must evaluate to a constant");
		num = 1;		/* it isn't, so force one */
		}
	if(num < 0) {
		error("Negative array size illegal");
		num = -num;
		}
	needpunc("]");			/* force single dimension */
	return num;			/* and return size */
	}
/*					*/
/*	Check for declarations		*/
/*					*/
/*	Used by:			*/
/*		parse (externals)	*/
/*		procarg (arguments)	*/
/*		procdecl (locals)	*/
/*					*/
chkdecl(psc, ptype)
int *psc, *ptype;
	{
	register int sc, type;
	sc = type = NULL;	/* start with no storage class or type */
	for (;;) {		/* process all declaration keywords */
		if (amatch("int")) {
			if (type == CCHAR) /* type may be CINT if we */
				typerr(); /* found long/short already */
			else
				type = CINT;
			}
		else if (amatch("char")) {
			if (type == NULL)
				type = CCHAR;
			else
				typerr();
			}
		else if (amatch("register")) {
			if (sc == NULL)
				sc = CREG;
			else
				scerr();
			}
		else if (amatch("static")) {
			if (sc == NULL)
				sc = CSTATIC;
			else
				scerr();
			}
		else if (amatch("extern")) {
			if (sc == NULL)
				sc = CEXTERN;
			else
				scerr();
			}
		else if (amatch("auto")) {
			if (sc == NULL)
				sc = CAUTO;
			else
				scerr();
			}
		else if (amatch("short")) {
			if (type == NULL)
				type = CINT;
			else
				typerr();
			}
		else if (amatch("long")) {
			notavail("long integers");
			if (type == NULL)
				type = CINT;
			else
				typerr();
			}
		else
			break;
		}
	*psc = sc;
	*ptype = type;
	return (sc || type);	/* return TRUE if it was a declaration */
	}
/*					*/
/*	Build a function		*/
/*					*/
/* called from "parse" this routine	*/
/* makes a function out of what follows */
newfunc()
	{
	char funcname[NAMESIZE];
	if(!symname(funcname)) {
		error("Illegal function or declaration");
		kill(); 	/* invalidate line */
		return;
		}
	if(astreq(funcname, "main", 4)) {
		mainflag = TRUE;/* remember there is a main function */
		shell();	/* build shell */
		}
	addglb(funcname, FUNCTION, CINT, CEXTDEF, GLOBAL);
	needpunc("(");		/* check for open parenthesis */
	procarg();		/* process all args */
	needpunc("{");		/* function must begin with { */
	procdecl();		/* process local declarations */
	prologue(funcname);	/* beginning code for function */
	compound(); /* evaluate all statements to closing } */
	epilogue(funcname);	/* ending code for function */
	}
/*					*/
/*	Process all args for a function */
/*	(called from "newfunc") 	*/
/*					*/
procarg()
	{
	int type, sc;
	char name[NAMESIZE];
	argoffset = 0;		/* init arg count */
	while(!match(")")) {	/* then count args */
		if(symname(name)) {
			if(findloc(name))
				multidef(name); /* already defined */
			else { /* add arg name to symbol table */
				addloc(name, 0, 0, CAUTO, argoffset);
				argoffset += 2;
				}
			}
		else {
			error("Illegal argument name");
			junk();
			}
		blanks();
		if(!streq(lptr, ")")) /* must be closing paren */
			if(!match(",")) 	/* or comma */
				error("Expected comma");
		if(endst()) break;
		}
	argtop = argoffset;	/* save total offset */
	while (chkdecl(&sc, &type)) {	/* look for arg declarations */
		if (type == NULL)
			type = CINT;	/* set defaults */
		if (sc == CSTATIC || sc == CEXTERN)
			scerr();	/* invalid storage class */
		getarg(type);
		}
	if (argoffset)			/* should be zero */
		error("Wrong number of arguments");
	}
/*					*/
/*	Declare argument types		*/
/*					*/
/* Called from "procarg" this routine	*/
/* adds an entry in the local symbol	*/
/* table for each named argument	*/
getarg(type)
int type;
	{
	register int id, legalname, *address;
	char sname[NAMESIZE], *argptr;
	do {
		if (argoffset == 0)
			return; 		/* no more args */
		id = match("*") ? POINTER: VARIABLE;
		if ((legalname = symname(sname)) == 0)
			illname();
		if (match("[")) {		/* pointer? */
			while (inbyte() != ']') /* yes, skip all */
				if (endst())	/* stuff between [] */
					break;
			id = POINTER;		/* add entry as ptr */
			}
		if (legalname) {
			if (argptr = findloc(sname)) {
				argptr[IDENT] = id; /* add type detail */
				argptr[TYPE] = type;
				address = &argptr[INFO];
				*address = argtop - *address;
				}
			else
				error("Expecting argument name");
			}
		argoffset -= 2; 	/* count down */
		} while (match(","));
	if (!endst())
		error("Expected comma");
	ns(); /* check for closing semicolon */
	}
/*					*/
/*	Do local declarations		*/
/*	(called from "newfunc") 	*/
/*					*/
procdecl()
	{
	int sc, type;

	nregvar = 0;		/* initialize # of register variables */
	while (chkdecl(&sc, &type)) {
		if (type == NULL)	/* set defaults */
			type = CINT;
		if (sc == NULL)
			sc = CAUTO;
		declloc(sc, type);
		}
	}
/*					*/
/*	Do function begin code		*/
/*	(called from "newfunc") 	*/
/*					*/
prologue(funcname)
char *funcname;
	{
	register int n;
	glblabel(funcname);	/* print function name */
	if (trace)		/* if trace requested... */
		gentrace('>', funcname); /* generate entry message */
	swapneeded = FALSE;	/* signal that HL needn't be preserved */
	modstk(spcc);		/* allocate stack space for locals */
	for (n = 1; n <= nregvar; ++n) {
		getreg(n);	/* save any registers we will use */
		cpush();
		}
	retlab = 0;		/* signal no return statement found */
	}
/*					*/
/*	Do function end code		*/
/*	(called from "newfunc") 	*/
/*					*/
epilogue(funcname)
char *funcname;
	{
	register char *sym;
	if(retlab)			/* was an early return found? */
		linelabel(retlab);	/* if so, print return label */
	for (sym = STARTLOC; sym > locptr; sym -= SYMSIZ) {
		if(sym[IDENT] == LABEL && sym[TYPE] != LABEL)
			errname("Undefined label", sym+NAME);
		}
	swapending = FALSE;
	if (nregvar) {		/* if registers were used, restore them */
		if (swapneeded) {	/* was there a return value? */
			swap(); 		/* save return val */
			swapneeded = FALSE;
			swapending = TRUE;
			}
		do {
			poppreg();		/* retrieve value */
			putreg(nregvar);	/* restore register */
			} while (--nregvar);
		}
	spcc = modstk(-spcc);			/* clean up stack */
	minlocptr = min(minlocptr, locptr);	/* remember symtab space */
	locptr = STARTLOC;			/* deallocate locals */
	if (swapending)
		swap(); 			/* restore return value */
	if (trace)				/* if trace requested... */
		gentrace('<', funcname);	/* generate exit message */
	cret(); 				/* supply return */
	}
