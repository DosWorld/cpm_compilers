/********************************************************
*							*
*	   Q / C   R E S E T   P R O G R A M		*
*							*
*		     10/31/81				*
*							*
*  This program allows you to change the size of the	*
*  compiler internal tables and the default assembler	*
*  code produced without recompiling the compiler.	*
*  If you want to compile Q/C with itself following	*
*  the procedures given in the Q/C User's Manual, the	*
*  recommended miminum sizes below should be used.	*
*							*
*  To run say						*
*							*
*		QRESET					*
*							*
*  and answer the questions.  CC.COM on the currently	*
*  logged disk will be changed with your new values.	*
*							*
*							*
*  NOTES ON COMPILING Q/C WITH ITSELF			*
*							*
*  The patch locations PCODEFLAG through PCASSIZ are	*
*  correct for the version of Q/C which comes on your	*
*  Q/C disk. It was compiled for M80.			*
*							*
*  If you recompile the compiler, you will have to	*
*  find out what sizes you need and also make any	*
*  adjustments needed in the paatch locations.		*
*							*
*  Q/C comes set up large enough to compile the parts	*
*  of the compiler separately as you do for M80.	*
*  To compile everything together as you would do for	*
*  ASM/MAC, you must have a true 48K CP/M system to	*
*  be able to allocate large enough internal tables.	*
*  This means that the address of the FDOS (referred	*
*  to as FBASE: in the CP/M documentation) which can	*
*  be found at location 6H in memory must be 0AC06H or	*
*  higher. The symptoms of running out of space are	*
*  generally that the compiler mysteriously dies as	*
*  the stack grows down into the file buffers. This	*
*  destroys your function return addresses sending	*
*  you off to strange places in memory. 		*
*							*
*  To compile Q/C for ASM/MAC set:			*
*							*
*	Symbol table =	    280 entries 		*
*	Literal pool =	    2600 characters		*
*	Macro pool =	    750 characters		*
*	Switch/loop table = 10 levels			*
*	Switch/case table = 50 entries			*
*							*
*  To compile Q/C for M80 set:				*
*							*
*	Symbol table =	    150 entries 		*
*	Literal pool =	    2000 characters		*
*	Macro pool   =	    750 characters		*
*	Switch/loop table = 10 levels			*
*	Switch/case table = 50 entries			*
*							*
********************************************************/

#define READ	0	/* flag for open function */
#define WRITE	1	/* flag for open function */
#define CPM20K	0x3C	/* high order byte of fbase: in standard 20K CP/M */

/*	Locations in CC.COM to modify	*/

#define PCODEFLAG 0x5C	/* location of assembler code flag */
#define PSYMSIZ 0x62	/* location of symbol table size in cc.com */
#define PLITSIZ 0x6E	/* location of literal pool size */
#define PMACSIZ 0x74	/* location of macro (#define) pool size */
#define PSWQSIZ 0x7A	/* location of switch/loop table size */
#define PCASSIZ 0x80	/* location of case table size */

#include <qstdio.h>

main()
	{
	int size, *psize, newsize, fd, chgflag;
	char buffer[256], num[7], *fbase;
	char codeflag, newcodeflag;

/* Figure out the size of the CP/M system running */

	fbase = 0x7;		/* high order byte of address of fbase: */
	size = *fbase & 0xFF;		/* defeat sign extension */
	size = (size - CPM20K) / 4 + 20; /* compare to 20K CP/M */
	printf("\nYour true CP/M system size is: %dK\n", size, 2);

/* Get first two records from CC.COM on the currently logged disk */

	if ((fd = open("cc.com", READ)) == ERROR) {
		puts("Can't open: cc.com");
		exit(0);
		}

	if(read(fd, buffer, 2) == 0) {
		puts("Error reading cc.com");
		exit(0);
		}

	close(fd);

/* Report old sizes and get new sizes */

	chgflag = FALSE;		/* rememeber if any changes */

/*	SYMBOL TABLE:	*/

	psize = &buffer[PSYMSIZ];
	size = *psize;
	printf("\nSYMBOL TABLE currently allows         %d entries\n",
		size, 2);
	printf("Enter new size or <CR> for no change: ", 1);
	if (newsize = atoi(gets(num))) {
		printf("New SYMBOL TABLE size =\
               %d entries\n", newsize, 2);
		*psize = newsize;
		chgflag = TRUE;
		}

/*	LITERAL POOL:	*/

	psize = &buffer[PLITSIZ];
	size = *psize;
	printf("\nLITERAL POOL size currently =         %d characters\n",
		size, 2);
	printf("Enter new size or <CR> for no change: ", 1);
	if (newsize = atoi(gets(num))) {
		printf("New LITERAL POOL size =\
               %d characters\n", newsize, 2);
		*psize = newsize;
		chgflag = TRUE;
		}

/*	MACRO (#define) POOL:	*/

	psize = &buffer[PMACSIZ];
	size = *psize;
	printf("\nMACRO (#define) POOL size currently = %d characters\n",
		size, 2);
	printf("Enter new size or <CR> for no change: ", 1);
	if (newsize = atoi(gets(num))) {
		printf("New MACRO POOL size =\
                 %d characters\n",newsize, 2);
		*psize = newsize;
		chgflag = TRUE;
		}

/*	SWITCH/LOOP QUEUE:	*/

	psize = &buffer[PSWQSIZ];
	size = *psize;
	printf("\nSWITCH/LOOP nesting currently =       %d levels\n",
		size, 2);
	printf("Enter new size or <CR> for no change: ", 1);
	if (newsize = atoi(gets(num))) {
		printf("New SWITCH/LOOP nesting depth =\
       %d levels\n", newsize, 2);
		*psize = newsize;
		chgflag = TRUE;
		}

/*	SWITCH/CASE TABLE:	*/

	psize = &buffer[PCASSIZ];
	size = *psize;
	printf("\nSWITCH/CASE TABLE currently allows    %d cases\n",
		size, 2);
	printf("Enter new size or <CR> for no change: ", 1);
	if (newsize = atoi(gets(num))) {
		printf("New SWITCH/CASE TABLE size =\
          %d cases\n", newsize, 2);
		*psize = newsize;
		chgflag = TRUE;
		}

/*	ASSEMBLER CODE FLAG	*/

	codeflag = buffer[PCODEFLAG];
	printf("\nCurrently compiler will generate code for %s\n",
		(codeflag == 'a') ? "ASM/MAC" : "M80", 2);
	do {
		printf("Enter A (ASM/MAC), M (M80) or <CR> for no change: ",
			1);
		newcodeflag = chlower(getchar());
		} while (newcodeflag != 'a' && newcodeflag != 'm'
			&& newcodeflag != '\n');
	if (newcodeflag != '\n') {
		printf("\nCompiler changed to generate code for %s\n",
			(newcodeflag == 'a') ? "ASM/MAC" : "M80", 2);
		buffer[PCODEFLAG] = newcodeflag;
		chgflag = TRUE;
		}

/* Rewrite the first two records of CC.COM with the new sizes */

	if (chgflag == FALSE)		/* no changes made */
		exit(0);
	if ((fd = open("cc.com", WRITE)) == ERROR) {
		puts("Can't open: cc.com");
		exit(0);
		}
	if(write(fd, buffer, 2) == 0) {
		puts("Error writing cc.com");
		exit(0);
		}
	close(fd);
	}
