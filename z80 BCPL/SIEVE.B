GET "LIBHDR"

LET START() BE
$(
    LET prime = ?
    LET k = ?
    LET count = ?
    LET l = ?
    LET i = ?

    LET size = 8190 
    LET flags = getvec(size + 1)
    LET iterLimit = 10 

    WRITEF( "10 iterations*N" ) 
    
    FOR l = 1 TO iterLimit DO
    $(
        FOR i = 0 TO size DO flags!i := 1
    
        count := 0
        FOR i = 0 TO size DO
        $(
            IF flags!i EQ 1 DO
            $(
                prime := i + i + 3 
                k := i + prime

                WHILE k <= size DO
                $(
                    flags!k := 0 
                    k := k + prime
                $)

                count := count + 1 
            $)
        $)
    $)

    WRITEF( "*N%N primes*N", count )
$)
.

