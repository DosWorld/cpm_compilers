/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*		 Standard Definitions			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/30/81			*/
/********************************************************/

/* #include "cstddef.h" */

/*	define code generation parameters	*/

#define MAXREG	5
#define POP	0
#define NOPOP	1
#define LVALUE	1
#define CONSTANT 2
#define COMMUT	TRUE
#define NONCOMMUT FALSE
#define FILNAMSIZE 14

/*	define the symbol table parameters	*/

#define SYMSIZ	14
#define STARTGLB symtab
#define STARTLOC (symtab + symtsize - SYMSIZ)

/*	define symbol table entry format	*/

#define IDENT	0
#define TYPE	1
#define STORAGE 2
#define INFO	3
#define NAME	5

/*	system wide name size (for symbols)	*/

#define NAMESIZE 9
#define NAMEMAX  8

/*	define possible entries for "IDENT"	*/

#define VARIABLE 1
#define POINTER  2
#define ARRAY	 3
#define FUNCTION 4
#define LABEL	 5

/*	define possible entries for "TYPE"	*/

#define CINT	1
#define CCHAR	2
#define PTRTOINT 3
#define PTRTOCHAR 4

/*	define possible entries for "STORAGE"	*/

#define CEXTERN 1
#define CEXTDEF 2
#define CAUTO	3
#define CSTATIC 4
#define CREG	5

/*	define possible entries for "INFO"	*/

#define GLOBAL	-1
#define LOCAL	-2

/*	define the switch/loop queue		*/

#define SWQSIZE 2
#define SWQMAX	(swq + (nswq * SWQSIZE))

/*	define switch/loop queue entry format	*/

#define LOOP	0
#define EXIT	1

/*	define the switch case table		*/

#define CASESIZE 2
#define CASEMAX (casetab + (ncases * CASESIZE))

/*	define switch case table entry format	*/

#define CASEVALUE 0
#define CASELABEL 1

/*	define the literal pool 		*/

#define LITMAX	(litpool + litpsize - 1)

/*	define the macro (#define) pool 	*/

#define MACPTR	8
#define MACSIZE 10

/*	define the input line			*/

#define LINESIZE 128
#define LINEMAX (LINESIZE-1)
