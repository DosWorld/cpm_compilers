BEGIN

INTEGER movecount;
INTEGER ARRAY board[ 0:8 ];

INTEGER PROCEDURE winner;
BEGIN
    INTEGER t, p;

    p := 0;
    t := board[ 0 ];
    IF 0 # t THEN BEGIN
        IF ( ( ( t = board[1] ) AND ( t = board[2] ) ) OR
             ( ( t = board[3] ) AND ( t = board[6] ) ) ) THEN
            p := t;
    END;

    IF 0 = p THEN BEGIN
        t := board[1];
        IF ( 0 # t ) AND ( t = board[4] ) AND ( t = board[7] ) THEN
            p := t
        ELSE BEGIN
            t := board[2];
            IF ( 0 # t ) AND ( t = board[5] ) AND ( t = board[8] ) THEN
                p := t
            ELSE BEGIN
                t := board[3];
                IF ( 0 # t ) AND ( t = board[4] ) AND ( t = board[5] ) THEN
                    p := t
                ELSE BEGIN
                    t := board[6];
                    IF ( 0 # t ) AND ( t = board[7] ) AND ( t = board[8] ) THEN
                        p := t
                    ELSE BEGIN
                        t := board[4];
                        IF ( 0 # t ) THEN BEGIN
                            IF ( ( ( t = board[0] ) AND ( t = board[8] ) ) OR
                                 ( ( t = board[2] ) AND ( t = board[6] ) ) ) THEN
                                p := t;
                        END;
                    END;
                END;
            END;
        END;
    END;
  
    winner := p;
END;

INTEGER PROCEDURE win2( move );
    VALUE move;
    INTEGER move;
BEGIN
    INTEGER x;
    x := board[ move ];

    BEGIN SWITCH cases := case0, case1, case2, case3, case4, case5, case6, case7, case8;
        GOTO cases[ move + 1 ];

        case0:
            IF NOT ( ( ( x = board[1] ) AND ( x = board[2] ) ) OR
                     ( ( x = board[3] ) AND ( x = board[6] ) ) OR
                     ( ( x = board[4] ) AND ( x = board[8] ) ) )
                THEN x := 0;
            GOTO alldone;
        case1: 
            IF NOT ( ( ( x = board[0] ) AND ( x = board[2] ) ) OR
                     ( ( x = board[4] ) AND ( x = board[7] ) ) )
                THEN x := 0;
            GOTO alldone;
        case2:
            IF NOT ( ( ( x = board[0] ) AND ( x = board[1] ) ) OR
                     ( ( x = board[5] ) AND ( x = board[8] ) ) OR
                     ( ( x = board[4] ) AND ( x = board[6] ) ) )
                THEN x := 0;
            GOTO alldone;
        case3:
            IF NOT ( ( ( x = board[4] ) AND ( x = board[5] ) ) OR
                     ( ( x = board[0] ) AND ( x = board[6] ) ) )
                THEN x := 0;
            GOTO alldone;
        case4:
            IF NOT ( ( ( x = board[0] ) AND ( x = board[8] ) ) OR
                     ( ( x = board[2] ) AND ( x = board[6] ) ) OR
                     ( ( x = board[1] ) AND ( x = board[7] ) ) OR
                     ( ( x = board[3] ) AND ( x = board[5] ) ) )
                THEN x := 0;
            GOTO alldone;
        case5:
            IF NOT ( ( ( x = board[3] ) AND ( x = board[4] ) ) OR
                     ( ( x = board[2] ) AND ( x = board[8] ) ) )
                THEN x := 0;
            GOTO alldone;
        case6:
            IF NOT ( ( ( x = board[7] ) AND ( x = board[8] ) ) OR
                     ( ( x = board[0] ) AND ( x = board[3] ) ) OR
                     ( ( x = board[4] ) AND ( x = board[2] ) ) )
                THEN x := 0;
            GOTO alldone;
        case7:
            IF NOT ( ( ( x = board[6] ) AND ( x = board[8] ) ) OR
                     ( ( x = board[1] ) AND ( x = board[4] ) ) )
                THEN x := 0;
            GOTO alldone;
        case8:
            IF NOT ( ( ( x = board[6] ) AND ( x = board[7] ) ) OR
                     ( ( x = board[2] ) AND ( x = board[5] ) ) OR
                     ( ( x = board[0] ) AND ( x = board[4] ) ) )
                THEN x := 0;
    END;

alldone:
    win2 := x;
END;

INTEGER PROCEDURE minmax( alpha, beta, depth, move );
    VALUE alpha, beta, depth, move;
    INTEGER alpha, beta, depth, move;
BEGIN
    INTEGER value, p, score, piecemove;
    value := 0;

    movecount := movecount + 1;

    IF depth >= 4 THEN BEGIN
        p := win2( move );
        IF p # 0 THEN BEGIN
            IF p = 1 THEN value := 6
            ELSE value := 4;
        END
        ELSE BEGIN
            IF depth = 8 THEN value := 5;
        END;
    END;

    IF value = 0 THEN BEGIN
        IF 2 = board[ move ] THEN BEGIN
            value := 2;
            piecemove := 1;
        END
        ELSE BEGIN
            value := 9;
            piecemove := 2;
        END;

        FOR p := 0 STEP 1 UNTIL 8 DO BEGIN
            IF board[ p ] = 0 THEN BEGIN
                board[ p ] := piecemove;
                score := minmax( alpha, beta, depth + 1, p );
                board[ p ] := 0;
            
                IF 2 = board[ move ] THEN BEGIN
                    IF score > value THEN BEGIN
                        value := score;
                        IF ( ( value = 6 ) OR ( value >= beta ) ) THEN
                            p := 10
                        ELSE BEGIN
                            IF ( value > alpha ) THEN alpha := value;
                        END;
                    END;
                END
                ELSE BEGIN
                    IF score < value THEN BEGIN
                        value := score;
                        IF ( value = 4 ) OR ( value <= alpha ) THEN
                            p := 10
                        ELSE BEGIN
                            IF ( value < beta ) THEN beta := value;
                        END;
                    END;
                END;
            END;
        END;
    END;

    minmax := value;
END;

PROCEDURE findsolution( move ); VALUE move;
    INTEGER move;
BEGIN
    INTEGER result;

    board[ move ] := 1;
    result := minmax( 2, 9, 0, move );
    board[ move ] := 0;
END;

BEGIN
    INTEGER i, j;

    FOR i := 0 STEP 1 UNTIL 8 DO BEGIN board[ i ] := 0; END;

    FOR j := 1 STEP 1 UNTIL 10 DO BEGIN
        movecount := 0;

        findsolution( 0 );
        findsolution( 1 );
        findsolution( 4 );
    END;

    text(1,"moves: ");
    write(1,movecount);
    ioc(22)
END;
END
FINISH

