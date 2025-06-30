/* compare filname1 filname2 - compare two files */
/* adapted from "Software Tools" page 73 */

#include <qstdio.h>

#define MAXLINE 132
main(argc,argv)
int argc, argv[];
	{
	register int lineno, m1, m2, *fp1, *fp2;
	char line1[MAXLINE], line2[MAXLINE];
	if (argc < 3) {
		puts("usage: compare file1 file2");
		exit(1);
		}
	if ((fp1 = fopen(argv[1], "r")) == NULL) {
		printf("can't open:%s\n", argv[1], 2);
		exit(1);
		}
	if ((fp2 = fopen(argv[2], "r")) == NULL) {
		printf("can't open:%s\n", argv[2], 2);
		exit(1);
		}
	lineno = 0;
	for (;;) {
		m1 = fgets(line1, MAXLINE, fp1);
		m2 = fgets(line2, MAXLINE, fp2);
		if (m1 == NULL || m2 == NULL)
			break;
		++lineno;
		if (strcmp(line1, line2)) {
			printf("%d:\n%s%s", lineno, line1, line2, 4);
			exit(0);
			}
		}
	if (m1 == NULL && m2 != NULL)
		printf("eof on %s\n", argv[1], 2);
	else if (m1 != NULL && m2 == NULL)
		printf("eof on %s\n", argv[2], 2);
	/* else they match */
	}
