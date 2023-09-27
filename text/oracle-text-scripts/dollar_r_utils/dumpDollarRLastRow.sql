-- dumps the last row of the $R table
-- edit these lines for the rowid and index you want to find

define target_index=FOOINDEX

set serveroutput on size 1000000

create or replace package base64
as 
  function decode_rowid(enc in raw) return varchar2;
  function encode_rowid(rid in varchar2) return raw;
end;
/

create or replace package body base64
as
  type chrtab is table of char(1) index by binary_integer;
  type numtab is table of number  index by binary_integer;

  b64da chrtab;
  b64ea numtab;

  n number;

function hextonib(x in varchar2) return number
is begin
  if    (x = 'A') then return 10;
  elsif (x = 'B') then return 11;    
  elsif (x = 'C') then return 12;    
  elsif (x = 'D') then return 13;    
  elsif (x = 'E') then return 14;    
  elsif (x = 'F') then return 15;    
  else  return to_number(x);
  end if;
end hextonib;

function nibtohex(x in number) return varchar2
is begin
  if    (x = 10) then return 'A';
  elsif (x = 11) then return 'B';    
  elsif (x = 12) then return 'C';    
  elsif (x = 13) then return 'D';    
  elsif (x = 14) then return 'E';    
  elsif (x = 15) then return 'F';    
  else  return ltrim(rtrim(to_char(x)));
  end if;
end nibtohex;

function decode_rowid(enc in raw) return varchar2
is
  dec   varchar2(18);
  encc  varchar2(28) := rawtohex(enc);

  n1    number;
  n2    number;
  n3    number;
  n4    number;
  n5    number;
  n6    number;

  code1 number;
  code2 number;
  code3 number;
  code4 number;

begin

  for i in 0..3 loop

    n1 := hextonib(substr(encc, i*6 + 1, 1));
    n2 := hextonib(substr(encc, i*6 + 2, 1));
    n3 := hextonib(substr(encc, i*6 + 3, 1));
    n4 := hextonib(substr(encc, i*6 + 4, 1));
    n5 := hextonib(substr(enc, i*6 + 5, 1));
    n6 := hextonib(substr(enc, i*6 + 6, 1));

    code1 := (n1 * 4) + trunc(n2/4);
    code2 := (mod(n2,4) * 16) + n3;
    code3 := (n4 * 4) + trunc(n5/4);
    code4 := (mod(n5,4) * 16) + n6;

    dec := dec || b64da(code1) || b64da(code2) || b64da(code3) || b64da(code4);

  end loop;

  n1 := hextonib(substr(encc, 25, 1)) * 16 + hextonib(substr(encc, 26, 1));
  n2 := hextonib(substr(encc, 27, 1)) * 16 + hextonib(substr(encc, 28, 1));

  dec := dec || chr(n1) || chr(n2);

  return dec;

end decode_rowid;

function encode_rowid(rid in varchar2) return raw
is
  encc  varchar2(28);
  enc   raw(18);

  n1    number;
  n2    number;
  n3    number;
  n4    number;
  n5    number;
  n6    number;

  code1 number;
  code2 number;
  code3 number;
  code4 number;

begin

  for i in 0..3 loop

    code1 := b64ea(ascii(substr(rid, i*4 + 1, 1)));
    code2 := b64ea(ascii(substr(rid, i*4 + 2, 1)));
    code3 := b64ea(ascii(substr(rid, i*4 + 3, 1)));
    code4 := b64ea(ascii(substr(rid, i*4 + 4, 1)));

    n1 := trunc(code1/4);
    n2 := (mod(code1, 4) * 4) + trunc(code2/16);
    n3 := mod(code2, 16);
    n4 := trunc(code3/4);
    n5 := (mod(code3, 4) * 4) + trunc(code4/16);
    n6 := mod(code4, 16);

    encc := encc || nibtohex(n1) || nibtohex(n2) || nibtohex(n3) 
                 || nibtohex(n4) || nibtohex(n5) || nibtohex(n6);

  end loop;

  n1 := trunc(ascii(substr(rid, 17, 1)) / 16);
  n2 := mod(ascii(substr(rid, 17, 1)), 16);
  n3 := trunc(ascii(substr(rid, 18, 1)) / 16);
  n4 := mod(ascii(substr(rid, 18, 1)), 16);

  encc := encc || nibtohex(n1) || nibtohex(n2) || nibtohex(n3) || nibtohex(n4);
  enc := hextoraw(encc);

  return enc;

end encode_rowid;

begin

  b64da(0) := 'A';
  b64da(1) := 'B';
  b64da(2) := 'C';
  b64da(3) := 'D';
  b64da(4) := 'E';
  b64da(5) := 'F';
  b64da(6) := 'G';
  b64da(7) := 'H';
  b64da(8) := 'I';
  b64da(9) := 'J';
  b64da(10):= 'K';
  b64da(11):= 'L';
  b64da(12):= 'M';
  b64da(13):= 'N';
  b64da(14):= 'O';
  b64da(15):= 'P';
  b64da(16):= 'Q';
  b64da(17):= 'R';
  b64da(18):= 'S';
  b64da(19):= 'T';
  b64da(20):= 'U';
  b64da(21):= 'V';
  b64da(22):= 'W';
  b64da(23):= 'X';
  b64da(24):= 'Y';
  b64da(25):= 'Z';
  b64da(26):= 'a';
  b64da(27):= 'b';
  b64da(28):= 'c';
  b64da(29):= 'd';
  b64da(30):= 'e';
  b64da(31):= 'f';
  b64da(32):= 'g';
  b64da(33):= 'h';
  b64da(34):= 'i';
  b64da(35):= 'j';
  b64da(36):= 'k';
  b64da(37):= 'l';
  b64da(38):= 'm';
  b64da(39):= 'n';
  b64da(40):= 'o';
  b64da(41):= 'p';
  b64da(42):= 'q';
  b64da(43):= 'r';
  b64da(44):= 's';
  b64da(45):= 't';
  b64da(46):= 'u';
  b64da(47):= 'v';
  b64da(48):= 'w';
  b64da(49):= 'x';
  b64da(50):= 'y';
  b64da(51):= 'z';
  b64da(52):= '0';
  b64da(53):= '1';
  b64da(54):= '2';
  b64da(55):= '3';
  b64da(56):= '4';
  b64da(57):= '5';
  b64da(58):= '6';
  b64da(59):= '7';
  b64da(60):= '8';
  b64da(61):= '9';
  b64da(62):= '+';
  b64da(63):= '/';

  for i in 0..63 loop
    b64ea(ascii(b64da(i))) := i;
  end loop;

end base64;
/

set serveroutput on
set verify off

declare
  rrid     varchar2(28);
  tbuf     raw(1400);
  tcbuf    varchar2(2800);
  loboff   number;
  loblen   number;
  bufoff   number;
  buflen   number;
  docid    number;
begin

  for c1 in (select row_no, data from DR$&target_index.$R
             where row_no =
	       (select max(row_no) from DR$&target_index.$R) ) loop
    docid := (35000 * c1.row_no) + 1;
    loboff := 1;
    loblen := dbms_lob.getlength(c1.data);
    exit when loblen = 0;

    while (loboff < loblen) loop
      buflen := 1400;
      dbms_lob.read(c1.data, buflen, loboff, tbuf);
      tcbuf := rawtohex(tbuf);
      bufoff := 1;

      while (bufoff < (buflen*2)) loop

        rrid := substr(tcbuf, bufoff, 28);
	dbms_output.put_line('d:'|| docid || ' r:'||base64.decode_rowid(hextoraw(rrid)));

        bufoff := bufoff + 28;        
        docid := docid + 1;

      end loop;

      loboff := loboff + buflen;

    end loop;

  end loop;

end;
/

