program errtest;

uses mkerr;

var f:text;
    b:byte;

procedure doerr2(i:integer);
begin
 if errset then begin
  writeln('fail again, next try.. ',i);
  dec(i);
  if i<1 then
     errfree;
 end;
 writeln(f,'DoErr2 i=',i);
 errfree;
end;

procedure doerr1;
begin
 if errset then begin
  writeln(' Something went wrong.. exiting ');
  errfree;
  exit;
 end;
 writeln('DoErr1, calling DoErr2..');
 doerr2(3);
 errfree;
end;

function doerr3(s:string;b:byte):byte;
begin
 doerr3:=9;
 writeln('DoErr3. clearing error device . . ');
 errfree;
 close(f);
end;

begin
 if errset then begin
  writeln('Program failure, retrying..');
  assign(f,'CON');
  rewrite(f);
 end;
 doerr1;
 doerr2(4);
 b:=doerr3('99',33);
 writeln('Err3 closed file f. And error handler.');
 if errset then begin
  writeln('Well, seems someone already shut down the file');
  continue;
 end;
 close(f);
 errfree;
 close(f); {This is just to show you runtime errors occurs when}
           {error device is inactive..}
 done;
end.

ERRTEST:
line program                   errordevice
40: begin                     inactive
41:  if errset..               SET 1. level error handler. return false
46:  doerr1;
22:   if errset..               SET 2. level error handler. return false
27:   writeln..
28:   doerr2(3)
10:    if errset..               SET 3. level error handler. return false
16:    writeln(f,..               ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=2}
15:    end;
16:    writeln(f,..               ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=1}
15:    end;
16:    writeln(f,..               ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=0}
14:      errfree;                CLEAR 3. level error handler, active is 2.
15:    end;
16:    writeln(f,..              ERROR. File not open. go to last handler
23:    writeln(' Someth..
24:    errfree;                 CLEAR 2. level error handler, active is 1.
25:    exit;
30:   end; {of doerr1}
47:   doerr2(4)
10:    if errset..              SET 2. level error handler. return false
16:    writeln(f,..              ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=3}
15:    end;
16:    writeln(f,..              ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=2}
15:    end;
16:    writeln(f,..              ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=1}
15:    end;
16:    writeln(f,..              ERROR. File not open. go to last handler
11:     writeln('fail..
12:     dec(i)
13:     if i<1 then   {i=0}
14:      errfree;               CLEAR 2. level error handler, active is 1.
15:    end;
16:    writeln(f,..            ERROR. File not open. go to last handler
42:   writeln('Progr..
43:   assign..
44:   rewrite..
45:  end;

46:  doerr1;
22:   if errset..              SET 2. level error handler. return false
27:   writeln..
28:   doerr2(3)
10:    if errset..              SET 3. level error handler. return false
16:    writeln(f,..              OK. File is open.
17:    errfree;                 CLEAR 3. level error handler, active is 2.
18:   end;
29:   errfree;                 CLEAR 2. level error handler, active is 1.
30:  end;
47:  doerr2(4)
10:   if errset..              SET 2. level error handler. return false
16:   writeln(f,..              OK. File is open.
17:   errfree;                CLEAR 2. level error handler, active is 1.
18:  end;
48:  b:=doerr3(..
34:   doerr3:=3;
35:   errfree;               CLEAR 1. level error handler, inactive
36:   close(f);              OK. File open.
37:  end;
49:  writeln('Err3 closed..
50:  if errset..             SET 1. level error handler. return false
54:  close(f);                ERROR. File not open. go last handler.
51:   writeln('Well..
52:   continue;               JUMP back where error occured.
55:  errfree;                CLEAR 1. level error handler, inactive
56:  close(f);               ERROR. Handler inactive. Runtime error.

