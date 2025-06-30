#include "qstdio.h"

#define DIGITS 200 /*9009;*/
main()
{
  int high;
  int x;
  int a[ DIGITS ];
  int n;

  x = 0;
  high = DIGITS;

  for (n = high - 1; n > 0; --n) {
      a[n] = 1;
  }

  a[1] = 2, a[0] = 0;
  while (high > 9) {
      n = high--;
      while (--n) {
          a[n] = x % n;

          x = 10 * a[n-1] + x/n;
      }
      printf( "%d", x, 2);
  }

  printf( "\ndone\n", 1 );

  return 0;
}
