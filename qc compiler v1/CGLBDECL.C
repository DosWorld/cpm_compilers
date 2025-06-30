/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*		  Global Declarations			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/27/81			*/
/********************************************************/

/*  #include "cglbdecl.c"  */

/*	Compiler tables & pointers		*/

extern	symtsize,	/* size of symbol table */
	nswq,		/* max entries in switch/loop queue */
	ncases, 	/* max entries in switch case table */
	litpsize,	/* size of literal pool */
	macpsize,	/* size of macro (#define) pool */

	*swq,		/* ptr to start of switch/loop queue */
	*pswq,		/* ptr to next switch/loop entry */
	*casetab,	/* ptr to start of switch case table */
	*pcasetab;	/* ptr to next switch case entry */

extern char
	*line,		/* parsing buffer */
	*lptr,		/* ptr to parsing line buffer */
	*mline, 	/* temp macro buffer */
	*mptr,		/* ptr to temp macro line buffer */

	*symtab,	/* ptr to beginning of symbol table */
	*glbptr,	/* ptr to next global sym table entry */
	*locptr,	/* ptr to next local sym table entry */
	*minlocptr,	/* ptr to deepest local sym table entry */

	*litpool,	/* ptr to beginning of literal pool */
	*plitpool,	/* ptr to next char in literal pool */

	*macpool,	/* ptr to beginning of macro pool */
	*pmacsym,	/* ptr to next macro pool sym entry */
	*pmacdef;	/* ptr to next macro pool def entry */

/*	Misc variables	*/

extern char
	*cptr,		/* work ptr to any char buffer */
	infil[FILNAMSIZE + 1],	 /* input file name */
	outfil[FILNAMSIZE + 1],  /* output file name */
	holdfil[FILNAMSIZE + 1]; /* hold an interrupted input file name */

extern	fullist,	/* TRUE if full asm listing with C text desired */
	mainflag,	/* TRUE if there is a main function */
	statflag,	/* TRUE if compiler statistics requested */
	trace,		/* TRUE to include trace messages */
	codeflag,	/* a = CP/M ASM code
			   m = Microsoft relocatable Macro-80 code
			   v = Vector Graphics ZSM code */
	cmode,		/* TRUE while parsing C statements */
			/* FALSE while passing asm code thru */
	midline,	/* TRUE if not at beginning of line */
	pregflag,	/* TRUE if HL contains curr val of expr */
	swapneeded,	/* TRUE if HL contains return value */
	swapending,	/* TRUE if swap was done to save HL */
	testdone,	/* TRUE if test (e.g. cceq) just done */
	eof,		/* set TRUE on final input eof */

	nxtlab, 	/* next avail label */
	litlab, 	/* label # assigned to literal pool */
	retlab, 	/* label # of return for current func */

	spcc,		/* compiler relative stk ptr */

	argoffset,	/* function arg offset */
	argtop, 	/* total arg offset at entry to function */
	nregvar,	/* # of register variables in current function */
	ncmp,		/* # open compound statements */
	errcnt, 	/* # errors in compilation */

	ninfils,	/* # of input files */
	*infilptr,	/* ptr to name of current input file */
	input,		/* iob for current input file */
	output, 	/* iob for output file (if any) */
	holdinput,	/* hold input file iob during #include */
	lineno, 	/* line number in current input file */
	holdlineno,	/* hold input file line number during #include */
	*iptr;		/* work ptr to any int buffer */
