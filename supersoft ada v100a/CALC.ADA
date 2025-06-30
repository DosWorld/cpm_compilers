procedure ADA_CALCULATOR is

-- define terminal dependent features

    clear_screen : constant character := character(26);
    home_cursor : constant character := character(30);
    erase_end_line : constant character := character(21);
    cr : constant character := character(13);
    back_space : constant character := character(8);

    X, Y, Z, T : float := 0.0;		-- the calculator registers
    input : character;
    roll_flag : boolean := false;
    error : boolean := false;

    procedure display is
	begin
	    put(home_cursor);
	    put(erase_end_line);put(T);newline;
	    put(erase_end_line);put(Z);newline;
	    put(erase_end_line);put(Y);newline;
	    put(erase_end_line);put(X);newline;
	    newline;
	end display;

    procedure roll_up is
	begin
	    t := z;
	    z := y;
	    y := x;
	end roll_up;

    function int(ch : character) return integer is
	begin
	    return integer(ch) - integer('0');
	end int;

    function flt(ch : character) return float is
	begin
	    return real(int(ch));
	end flt;

    function sqrt(A : float) return float is
	guess, delt : float;
	begin
	    if a = 0.0 then
		return 0.0;
	    elsif a = 1.0 then
		return 1.0;
	    else
		guess := a / 2.0;
		delt := 1.0;
		while guess ** 2 > a loop
		    guess := guess / 2.0;
		end loop;
		while abs(guess ** 2 - a) > 0.0001 loop
		    while (guess + delt) ** 2 > a loop
			if delt < 0.00001 then
			    return guess;
			else
			    delt := delt / 2.0;
			end if;
		    end loop;
		    guess := guess + delt;
		end loop;
		return guess;
	    end if;
	end sqrt;

    function sin(x : float) return float is
	n1 : float := 1.0;
	n2 : integer := -1;
	x1 : float := 0.0;
	x2 : float := 1.0;
	x3 : float := x * 0.017453;
	begin
	    for n in 1..15 loop
		n1 := n1 * real(n);
		x2 := x2 * x3;
		if n rem 2 = 1 then
		    n2 := -1 * n2;
		    x1 := x1 + ((x2 * real(n2)) / n1);
		end if;
	    end loop;
	    return x1;
	end sin;

    function cos(x : float) return float is
	n1 : float := 1.0;
	n2 : integer := 1;
	x1 : float := 1.0;
	x2 : float := x * 0.017453;
	x3 : float := x2;
	begin
	    for n in 2..16 loop
		n1 := n1 * real(n);
		x2 := x2 * x3;
		if n rem 2 = 0 then
		    n2 := -1 * n2;
		    x1 := x1 + ((x2 * real(n2)) / n1);
		end if;
	    end loop;
	    return x1;
	end cos;

    function ln(a : float) return float is
	x1 : float := 0.0;
	x2 : float := 1.0;
	begin
	    for n in 1..51 loop
		x2 := x2 * ((x - 1.0) / (x + 1.0));
		if n rem 2 = 1 then
		    x1 := x1 + x2 / real(n);
		end if;
	    end loop;
	    return 2.0 * x1;
	end ln;

    function exp(a : float) return float is
	n1, x1, x2 : float := 1.0;
	begin
	    for n in 1..51 loop
		n1 := n1 * real(n);
		x2 := x2 * x;
		x1 := x1 + x2 / n1;
	    end loop;
	    return x1;
	end exp;

begin

    put(clear_screen);
    display;
    newline;
    put("+ : add           - : subtract");  newline;
    put("* : multiply      / : divide");    newline;
    put("s : sine          c : cosine");    newline;
    put("l : ln            e : e^x");	    newline;
    put("r : square root  sp : clear registers"); newline;
    put("@ : +/-          cr : enter");     newline;
    put("q : quit");	  newline;
    newline;

    loop

	if error then
	    put(character(7));
	    error := false;
	    x := 0.0;
	end if;

-- get an input character and erase it

	get(input);
	put(back_space);put(' ');

	if (input >= '0' and input <= '9') or input = '.' then
	    declare
		decimal_point : boolean := false;
		power : float := 0.1;
	    begin
		if roll_flag then
		    roll_up;			-- entering new number, roll
		end if;

		if input = '.' then
		    decimal_point := true;	-- first character was period
		    x := 0.0;
		else
		    x := flt(input);		-- else was start of x
		end if;
    
		display;
		get(input);
		while (input >= '0' and input <= '9') or input = '.' loop
		    if input = '.' then
			decimal_point := true;	-- period in number
		    else
			if decimal_point then
			    if power > 0.00001 then	 -- process to 10**-5
				x := x + flt(input) * power;
				power := power / 10.0;
			    end if;
			else
			    x := x * 10.0 + flt(input); -- process digit
			end if;
		    end if;
		    display;
		    get(input); 		-- get next input digit
		end loop;
	    end;
	end if;
	roll_flag := true;
	case input is
	    when '+' =>
		x := x + y;
		y := z;
		z := t;

	    when '-' =>
		x := y - x;
		y := z;
		z := t;

	    when '*' =>
		x := x * y;
		y := z;
		z := t;

	    when '/' =>
		x := y / x;
		y := z;
		z := t;

	    when '@' =>
		x := -x;

	    when ' ' =>
		x := 0.0;
		y := 0.0;
		z := 0.0;
		t := 0.0;

	    when 'R' | 'r' =>
		if x < 0.0 then
		    error := true;
		else
		    x := sqrt(x);
		end if;

	    when 'S' | 's' =>
		if x < -180.0 or x > 180.0 then
		    error := true;
		else
		    x := sin(x);
		end if;

	    when 'C' | 'c' =>
		if x < -180.0 or x > 180.0 then
		    error := true;
		else
		    x := cos(x);
		end if;

	    when 'L' | 'l' =>
		if x < 0.1 or x > 10.0 then
		    error := true;
		else
		    x := ln(x);
		end if;

	    when 'E' | 'e' =>
		if x < -5.0 or x > 22.0 then
		    error := true;
		else
		    x := exp(x);
		end if;

	    when 'Q' | 'q' =>
		bdos(0);

	    when cr =>
		roll_up;
		roll_flag := false;

	    when others =>
		put(character(7));

	end case;
	display;
    end loop;

end ADA_CALCULATOR;
ll_flag := false;

	    when others =>
		put(character(7))