/*
   This version builds with old compilers including:
       Aztec C 1.06 for 8080 & Z80 on CP/M.
       Microsoft C Compiler V1.04 for 8086 on DOS. (This is Lattice C)
       Microsoft C Compiler V2.03 for 8086 on DOS. (Still Lattice C)
       Microsoft C Compiler V3.00 for 8086 on DOS.
       QuickC 1.0
       Turbo C 2.0
   The syntax is old and reminds me of 7th grade summer vacation.
   Much of this code is awkward to satisfy the lowest common denominator of many compilers.
   unsigned long isn't supported in many older compilers, so long is used instead.
   Early DOS and CP/M require variabes to be int, not char or other types.
   The perf improvement of using register-int instead of stack-char is worth it.
*/

#include "qstdio.h"

#define LINTARGS

#define true 1
#define false 0

/* Function Pointers are the fastest implementation for almost every compiler */
#define UseFunPointers 1
#define UseWinner2 2
#define UseLookForWinner 3
#define WinMethod UseFunPointers

#define ABPrune true         /* alpha beta pruning */
#define WinLosePrune true    /* stop early on win/lose */
#define ScoreWin 6
#define ScoreTie 5
#define ScoreLose  4
#define ScoreMax 9
#define ScoreMin 2
#define DefaultIterations 10

#define PieceX 1
#define PieceO 2
#define PieceBlank 0

#define ttype char

int gIterations;
int gIMoves;
ttype gboard[ 9 ];

main()
{
    int moves;
    moves = 0;
    gIMoves = 0;
    gIterations = DefaultIterations;

    moves = FindSolution( 0 );
    moves += FindSolution( 1 );
    moves += FindSolution( 4 );

    printf( "move count:      %d\n", moves, 2 ); /* 6493 * gIterations */
    printf( "iteration count: %d\n", gIterations, 2 );
    return 0;
} /*main*/

winner2( move ) ttype move;
{
    int x;  /* faster than ttype x on the stack */

    switch( move ) /* msc v3 from 1985 generates a jump table! */
    {
        case 0:
        {
            x = gboard[ 0 ];
            if ( ( ( x == gboard[1] ) && ( x == gboard[2] ) ) ||
                 ( ( x == gboard[3] ) && ( x == gboard[6] ) ) ||
                 ( ( x == gboard[4] ) && ( x == gboard[8] ) ) )
               return x;
            break;
        }
        case 1:
        {
            x = gboard[ 1 ];
            if ( ( ( x == gboard[0] ) && ( x == gboard[2] ) ) ||
                 ( ( x == gboard[4] ) && ( x == gboard[7] ) ) )
                return x;
            break;
        }
        case 2:
        {
            x = gboard[ 2 ];
            if ( ( ( x == gboard[0] ) && ( x == gboard[1] ) ) ||
                 ( ( x == gboard[5] ) && ( x == gboard[8] ) ) ||
                 ( ( x == gboard[4] ) && ( x == gboard[6] ) ) )
                return x;
            break;
        }
        case 3:
        {
            x = gboard[ 3 ];
            if ( ( ( x == gboard[4] ) && ( x == gboard[5] ) ) ||
                 ( ( x == gboard[0] ) && ( x == gboard[6] ) ) )
                return x;
            break;
        }
        case 4:
        {
            x = gboard[ 4 ];
            if ( ( ( x == gboard[0] ) && ( x == gboard[8] ) ) ||
                 ( ( x == gboard[2] ) && ( x == gboard[6] ) ) ||
                 ( ( x == gboard[1] ) && ( x == gboard[7] ) ) ||
                 ( ( x == gboard[3] ) && ( x == gboard[5] ) ) )
                return x;
            break;
        }
        case 5:
        {
            x = gboard[ 5 ];
            if ( ( ( x == gboard[3] ) && ( x == gboard[4] ) ) ||
                 ( ( x == gboard[2] ) && ( x == gboard[8] ) ) )
                return x;
            break;
        }
        case 6:
        {
            x = gboard[ 6 ];
            if ( ( ( x == gboard[7] ) && ( x == gboard[8] ) ) ||
                 ( ( x == gboard[0] ) && ( x == gboard[3] ) ) ||
                 ( ( x == gboard[4] ) && ( x == gboard[2] ) ) )
                return x;
            break;
        }
        case 7:
        {
            x = gboard[ 7 ];
            if ( ( ( x == gboard[6] ) && ( x == gboard[8] ) ) ||
                 ( ( x == gboard[1] ) && ( x == gboard[4] ) ) )
                return x;
            break;
        }
        case 8:
        {
            x = gboard[ 8 ];
            if ( ( ( x == gboard[6] ) && ( x == gboard[7] ) ) ||
                 ( ( x == gboard[2] ) && ( x == gboard[5] ) ) ||
                 ( ( x == gboard[0] ) && ( x == gboard[4] ) ) )
                return x;
            break;
         }
    }

    return PieceBlank;
} /*winner2*/

LookForWinner()
{
    int p;
    p = gboard[0]; /* faster as int than ttype on 8086 and Z80 */
    if ( PieceBlank != p )
    {
        if ( p == gboard[1] && p == gboard[2] )
            return p;

        if ( p == gboard[3] && p == gboard[6] )
            return p;
    }

    p = gboard[3];
    if ( PieceBlank != p && p == gboard[4] && p == gboard[5] )
        return p;

    p = gboard[6];
    if ( PieceBlank != p && p == gboard[7] && p == gboard[8] )
        return p;

    p = gboard[1];
    if ( PieceBlank != p && p == gboard[4] && p == gboard[7] )
        return p;

    p = gboard[2];
    if ( PieceBlank != p && p == gboard[5] && p == gboard[8] )
        return p;

    p = gboard[4];
    if ( PieceBlank != p )
    {
        if ( ( p == gboard[0] ) && ( p == gboard[8] ) )
            return p;

        if ( ( p == gboard[2] ) && ( p == gboard[6] ) )
            return p;
    }

    return PieceBlank;
} /*LookForWinner*/

MinMax( alpha, beta, depth, move ) ttype alpha; ttype beta; ttype depth; ttype move;
{
    ttype pieceMove, score;   /* better perf with char than int. out of registers so use stack */
    int p, value;    /* better perf with these as an int on Z80, 8080, and 8086 */

    gIMoves++;

    if ( depth >= 4 )
    {
/*
        p = ( * winfunctions[ move ] )(); 
*/
        p = winner2( move );
/*
        p = LookForWinner();
*/

        if ( PieceBlank != p )
        {
            if ( PieceX == p )
                return ScoreWin;

            return ScoreLose;
        }

        if ( 8 == depth )
            return ScoreTie;
    }

    if ( depth & 1 ) 
    {
        value = ScoreMin;
        pieceMove = PieceX;
    }
    else
    {
        value = ScoreMax;
        pieceMove = PieceO;
    }

    for ( p = 0; p < 9; p++ )
    {
        if ( PieceBlank == gboard[ p ] )
        {
            gboard[p] = pieceMove;
            score = MinMax( alpha, beta, depth + 1, p );
            gboard[p] = PieceBlank;

            if ( depth & 1 ) 
            {
                if ( ScoreWin == score )
                    return ScoreWin;

                if ( score > value )
                {
                    value = score;

                    if ( value >= beta )
                        return value;
                    if ( value > alpha )
                        alpha = value;
                }
            }
            else
            {
                if ( ScoreLose == score )
                    return ScoreLose;

                if ( score < value )
                {
                    value = score;

                    if ( value <= alpha )
                        return value;
                    if ( value < beta )
                        beta = value;
                }
            }
        }
    }

    return value;
}  /*MinMax*/

FindSolution( position ) ttype position;
{
    int i;

    for ( i = 0; i < 9; i++ )
        gboard[ i ] = PieceBlank;

    gboard[ position ] = PieceX;

    for ( i = 0; i < gIterations; i++ )
    {
        gIMoves = 0;
        MinMax( ScoreMin, ScoreMax, 0, position );
    }

    return gIMoves;
} /*FindSolution*/


