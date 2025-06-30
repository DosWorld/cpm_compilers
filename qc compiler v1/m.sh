str=$(tr '[a-z]' '[A-Z]' <<< $1)

rm $str.ASM 2>/dev/null
rm $str.PRN 2>/dev/null
rm $str.HEX 2>/dev/null
rm $str.COM 2>/dev/null

ntvcm cc $str
ntvcm asm $str
ntvcm load $str

rm $str.PRN 2>/dev/null
rm $str.ASM 2>/dev/null
rm $str.HEX 2>/dev/null
