GET "LIBHDR"

LET START() BE
$(
    LET high = ?
    LET n = ?
    LET x = ?
    LET d = ?

    LET digits = 200
    LET a = getvec( digits )

    high := digits
    x := 0
    n := high - 1

    WHILE n > 1 DO
    $(
        a!n := 1
        n := n - 1
    $)

    a!1 := 2
    a!0 := 0

    WHILE high > 9 DO
    $(
        high := high - 1
        n := high
        WHILE n > 0 DO
        $(
            d := x / n
            a!n := x REM n  // much slower than calculating it using d
            n := n - 1
            x := 10 * a!n + d
        $)

        WRITEF( "%N", x )
    $)
    
    WRITEF( "*Ndone*N" )
$)
.

