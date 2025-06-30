procedure TO_UPPER is

    error_flag : boolean;
    ch : character;
    eof : constant character := character(26);

    function up (A : character) return character is
	begin
	    if integer(A) < integer('a') then
		return A;
	    elsif integer(A) > integer ('z') then
		return A;
	    else
		return character(integer(A)-32);
	    end if;
	end up;
begin

    open(ufcb,"",error_flag);

    if not error_flag then
	put(name(ufcb));
	put(" not found");
	bdos(0);
    else
	read(ufcb,ch,error_flag);
	while ch /= eof and error_flag loop
		put(up(ch));
		read(ufcb,ch,error_flag);
	end loop;

	if not error_flag then
	    newline;
	    put("File error.");
	    newline;
	end if;
    end if;

    close(ufcb,error_flag);
    newline;

end TO_UPPER;

	    put("File error.");
	    newline;
	end if;
    end if;

    close(ufcb,error_flag);
    newline;