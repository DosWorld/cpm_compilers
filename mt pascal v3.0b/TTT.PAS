{ App to prove you can't win at Tic-Tac-Toe }

{ turn off checks to improve performance }
{$A-,O-,C-}

{ enable local variables for recursion }
{$S+}

PROGRAM TTT;

CONST
    SCOREWIN = 6;
    SCORETIE = 5;
    SCORELOSE = 4;
    SCOREMAX = 9;
    SCOREMIN = 2;
    SCOREINVALID = 0;

    PIECEBLANK = 0;
    PIECEX = 1;
    PIECEO = 2;

    ITERATIONS = 10;

TYPE
    BOARDTYPE = ARRAY[ 0..8 ] OF INTEGER;

VAR
    EVALUATED: INTEGER;
    BOARD: BOARDTYPE;
    I: INTEGER;

FUNCTION LOOKFORWINNER : INTEGER;
VAR
    T, P : INTEGER;
BEGIN
    {DUMPBOARD;}
    P := PIECEBLANK;
    T := BOARD[ 0 ];
    IF PIECEBLANK <> T THEN
    BEGIN
        IF ( ( ( T = BOARD[1] ) AND ( T = BOARD[2] ) ) OR
             ( ( T = BOARD[3] ) AND ( T = BOARD[6] ) ) ) THEN
            P := T;
    END;

    IF PIECEBLANK = P THEN
    BEGIN
        T := BOARD[1];
        IF ( T = BOARD[4] ) AND ( T = BOARD[7] ) THEN
            P := T
        ELSE
        BEGIN
            T := BOARD[2];
            IF ( T = BOARD[5] ) AND ( T = BOARD[8] ) THEN
                P := T
            ELSE
            BEGIN
                T := BOARD[3];
                IF ( T = BOARD[4] ) AND ( T = BOARD[5] ) THEN
                    P := T
                ELSE
                BEGIN
                    T := BOARD[6];
                    IF ( T = BOARD[7] ) AND ( T = BOARD[8] ) THEN
                        P := T
                    ELSE
                    BEGIN
                      T := BOARD[4];
                      IF ( ( ( T = BOARD[0] ) AND ( T = BOARD[8] ) ) OR
                           ( ( T = BOARD[2] ) AND ( T = BOARD[6] ) ) ) THEN
                          P := T
                    END;
                END;
            END;
        END;
    END;

    LOOKFORWINNER := P;
END;

FUNCTION WINNER2( M: INTEGER ) : INTEGER;
VAR
    X : INTEGER;
BEGIN
    CASE M OF
        0:  BEGIN
            X := BOARD[ 0 ];
            IF NOT ( ( ( X = BOARD[1] ) AND ( X = BOARD[2] ) ) OR
                     ( ( X = BOARD[3] ) AND ( X = BOARD[6] ) ) OR
                     ( ( X = BOARD[4] ) AND ( X = BOARD[8] ) ) )
                THEN X := PIECEBLANK;
            END;
        1:  BEGIN
            X := BOARD[ 1 ];
            IF NOT ( ( ( X = BOARD[0] ) AND ( X = BOARD[2] ) ) OR
                     ( ( X = BOARD[4] ) AND ( X = BOARD[7] ) ) )
                THEN X := PIECEBLANK;
            END;
        2:  BEGIN
            X := BOARD[ 2 ];
            IF NOT ( ( ( X = BOARD[0] ) AND ( X = BOARD[1] ) ) OR
                     ( ( X = BOARD[5] ) AND ( X = BOARD[8] ) ) OR
                     ( ( X = BOARD[4] ) AND ( X = BOARD[6] ) ) )
                THEN X := PIECEBLANK;
            END;
        3:  BEGIN
            X := BOARD[ 3 ];
            IF NOT ( ( ( X = BOARD[4] ) AND ( X = BOARD[5] ) ) OR
                     ( ( X = BOARD[0] ) AND ( X = BOARD[6] ) ) )
                THEN X := PIECEBLANK;
            END;
        4:  BEGIN
            X := BOARD[ 4 ];
            IF NOT ( ( ( X = BOARD[0] ) AND ( X = BOARD[8] ) ) OR
                     ( ( X = BOARD[2] ) AND ( X = BOARD[6] ) ) OR
                     ( ( X = BOARD[1] ) AND ( X = BOARD[7] ) ) OR
                     ( ( X = BOARD[3] ) AND ( X = BOARD[5] ) ) )
                THEN X := PIECEBLANK;
            END;
        5:  BEGIN
            X := BOARD[ 5 ];
            IF NOT ( ( ( X = BOARD[3] ) AND ( X = BOARD[4] ) ) OR
                     ( ( X = BOARD[2] ) AND ( X = BOARD[8] ) ) )
                THEN X := PIECEBLANK;
            END;
        6:  BEGIN
            X := BOARD[ 6 ];
            IF NOT ( ( ( X = BOARD[7] ) AND ( X = BOARD[8] ) ) OR
                     ( ( X = BOARD[0] ) AND ( X = BOARD[3] ) ) OR
                     ( ( X = BOARD[4] ) AND ( X = BOARD[2] ) ) )
                THEN X := PIECEBLANK;
            END;
        7:  BEGIN
            X := BOARD[ 7 ];
            IF NOT ( ( ( X = BOARD[6] ) AND ( X = BOARD[8] ) ) OR
                     ( ( X = BOARD[1] ) AND ( X = BOARD[4] ) ) )
                THEN X := PIECEBLANK;
            END;
        8:  BEGIN
            X := BOARD[ 8 ];
            IF NOT ( ( ( X = BOARD[6] ) AND ( X = BOARD[7] ) ) OR
                     ( ( X = BOARD[2] ) AND ( X = BOARD[5] ) ) OR
                     ( ( X = BOARD[0] ) AND ( X = BOARD[4] ) ) )
                THEN X := PIECEBLANK;
            END
    END;

    WINNER2 := X;
END;

FUNCTION MINMAX( ALPHA: INTEGER; BETA: INTEGER; DEPTH: INTEGER; M: INTEGER ):
         INTEGER;
VAR
    P, VALUE, PIECEMOVE, SCORE : INTEGER;
BEGIN
(*
    write( 'move ', EVALUATED, ' depth ', DEPTH, ' move ', M );
    writeln( ' ', BOARD[0], BOARD[1], BOARD[2], BOARD[3],
             BOARD[4], BOARD[5], BOARD[6], BOARD[7], BOARD[8] );
*)
    EVALUATED := EVALUATED + 1;
    VALUE := SCOREINVALID;
    IF DEPTH >= 4 THEN
    BEGIN
        { P := LOOKFORWINNER; }  { THIS IS MUCH SLOWER }
        P := WINNER2( M );
        IF P <> PIECEBLANK THEN
        BEGIN
            IF P = PIECEX THEN
                VALUE := SCOREWIN
            ELSE
                VALUE := SCORELOSE
        END
        ELSE IF DEPTH = 8 THEN
            VALUE := SCORETIE;
    END;

    IF VALUE = SCOREINVALID THEN
    BEGIN
        IF ODD( DEPTH ) THEN
        BEGIN
            VALUE := SCOREMIN;
            PIECEMOVE := PIECEX;
        END
        ELSE
        BEGIN
            VALUE := SCOREMAX;
            PIECEMOVE := PIECEO;
        END;

        P := 0;
        REPEAT
            IF BOARD[ P ] = PIECEBLANK THEN
            BEGIN
                BOARD[ P ] := PIECEMOVE;
                SCORE := MINMAX( ALPHA, BETA, DEPTH + 1, P );
                BOARD[ P ] := PIECEBLANK;

                IF ODD( DEPTH ) THEN
                BEGIN
                    IF ( SCORE > VALUE ) THEN
                    BEGIN
                        VALUE := SCORE;
                        IF ( VALUE = SCOREWIN ) OR ( VALUE >= BETA ) THEN
                                 P := 10
                        ELSE IF ( VALUE > ALPHA ) THEN
                                 ALPHA := VALUE;
                    END;
                END
                ELSE
                BEGIN
                    IF ( SCORE < VALUE ) THEN
                    BEGIN
                        VALUE := SCORE;
                        IF ( VALUE = SCORELOSE ) OR ( VALUE <= ALPHA ) THEN
                                 P := 10
                        ELSE IF ( VALUE < BETA ) THEN
                                 BETA := VALUE;
                    END;
                END;
            END;
            P := P + 1;
        UNTIL P > 8;
    END;

    MINMAX := VALUE;
END;

PROCEDURE RUNIT( M : INTEGER );
VAR
    SCORE, DEPTH: INTEGER;
BEGIN
    BOARD[M] := PIECEX;
    SCORE := MINMAX( SCOREMIN, SCOREMAX, 0, M );
    BOARD[M] := PIECEBLANK;
END;

BEGIN
    FOR I := 0 TO 8 DO
        BOARD[I] := PIECEBLANK;
    
    FOR I := 1 TO ITERATIONS DO
    BEGIN
        EVALUATED := 0;  { ONCE PER LOOP TO PREVENT OVERFLOW }
        RUNIT( 0 );
        RUNIT( 1 );
        RUNIT( 4 ); 
    END;
    
    WRITE( 'moves evaluated: ' ); WRITE( EVALUATED ); WRITELN;
    WRITE( 'iterations: ' ); WRITE( ITERATIONS ); WRITELN;
END.        
