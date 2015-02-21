{
   --- Version 3.3 91-11-25 14:02 ---

   EXTEST.PAS: EXEC function with memory swap - Test program.

   Public domain software by

        Thomas Wagner
        Ferrari electronic GmbH
        Beusselstrasse 27
        D-1000 Berlin 21
        Germany
}
program extest;
uses
   crt,
   dos,
   exec;

type
   string4 = string [4];

{>e}
{$DEFINE ENGLISH}
{<}

function hexdig (d: integer): char;
   begin
   if d < 10
      then hexdig := chr (d + ord('0'))
      else hexdig := chr (d - 10 + ord ('A'));
   end;

function hexstr (num: integer): string4;
   var
      i: integer;
      s: string4;
   begin
   for i := 4 downto 1 do
      begin
      s [i] := hexdig (num mod 16);
      num := num div 16;
      end;
   s [0] := chr(4);
   hexstr := s;
   end;


{$IFDEF ENGLISH}
procedure help;
   begin
   writeln ('Usage: EXTEST [options]');
   writeln ('Options:');
   writeln ('     -E    do not use EMS  for swapping');
   writeln ('     -X    do not use XMS  for swapping');
   writeln ('     -F    do not use File for swapping');
   writeln ('     -T    Terminate after EXEC (no swap)');
   writeln ('     -N    do Not swap');
   writeln ('     -C    do not Copy environment');
   writeln ('     -H    Hide swapfile');
   writeln ('     -Z    Try XMS first, then EMS');
   end;
{$ELSE}
procedure help;
   begin;
   writeln ('Benutzung: EXTEST [Optionen]');
   writeln ('Optionen:');
   writeln ('     -E    bei Auslagern kein EMS benutzen');
   writeln ('     -X    bei Auslagern kein XMS benutzen');
   writeln ('     -F    bei Auslagern keine Datei benutzen');
   writeln ('     -T    Terminieren nach EXEC (keine Auslagerung)');
   writeln ('     -N    Nicht Auslagern');
   writeln ('     -C    Umgebungsvariablen nicht kopieren');
   writeln ('     -H    Auslagerungsdatei "hidden"');
   writeln ('     -Z    Zuerst XMS versuchen, dann EMS');
   end;
{$ENDIF}

{$F+}
{$IFDEF ENGLISH}
function spcheck (cmdbat: integer; swapping: integer; var execfn: string;
                  var progpars: string): integer;
   var
     tmp: string [82];
     l: integer;
   begin
   if swapping > 0
      then begin
      case swap_prep.swapmethod of
         USE_EMS:
               writeln ('Swapping to EMS handle ', swap_prep.handle);

         USE_XMS:
               writeln ('Swapping to XMS handle ', swap_prep.handle);

         USE_FILE:
               begin
               l := 0;
               while swap_prep.swapfilename [l] <> chr(0) do
                  l := l + 1;
               move (swap_prep.swapfilename, tmp [1], l);
               tmp [0] := chr (l);
               writeln ('Swapping to File <', tmp, '>');
               end;
         end;
      end;
   writeln ('Executing ', execfn, ' ', progpars);
   writeln;
   if (cmdbat = 3) and (pos ('/c', progpars) = 0)
      then writeln ('Enter EXIT to return to EXTEST');

   spcheck := 0;
   end;
{$ELSE}
function spcheck (cmdbat: integer; swapping: integer;
                  var execfn: string; var progpars: string)
                  : integer;
   var
     tmp: string [82];
     l: integer;
   begin
   if swapping > 0
      then begin
      case swap_prep.swapmethod of
         USE_EMS:
               writeln ('Auslagerung auf EMS Handle ', swap_prep.handle);

         USE_XMS:
               writeln ('Auslagerung auf XMS Handle ', swap_prep.handle);

         USE_FILE:
               begin
               l := 0;
               while swap_prep.swapfilename [l] <> chr(0) do
                  l := l + 1;
               move (swap_prep.swapfilename, tmp [1], l);
               tmp [0] := chr (l);
               writeln ('Auslagerung auf Datei <', tmp, '>');
               end;
         end;
      end;
   writeln ('AusfÅhren ', execfn, ' ', progpars);
   writeln;
   if (cmdbat = 3) and (pos ('/c', progpars) = 0)
      then writeln ('Geben Sie EXIT ein um zu EXTEST zurÅckzukehren');

   spcheck := 0;
   end;
{$ENDIF}
{$F-}

var
   method: integer;
   needed: word;
   env: boolean;
   i, j: integer;
   argv: string;
   fn: string;
   par: string;

begin
@spawn_check := @spcheck;

method := USE_ALL;
needed := $ffff;
env := true;

for i := 1 to ParamCount do
   begin
   argv := ParamStr (i);
   if (argv [1] <> '-') and (argv [1] <> '/')
      then begin
      help;
      exit;
      end;
   for j := 2 to length (argv) do
      case upcase (argv [j]) of
         'E':   method := method and not USE_EMS;
         'X':   method := method and not USE_XMS;
         'F':   method := method and not USE_FILE;
         'T':   method := 0;
         'N':   needed := 0;
         'C':   env := false;
         'H':   method := method or HIDE_FILE;
         'Z':   method := method or XMS_FIRST;
         '-':   ;
         '/':   ;
         else   begin
                help;
                exit;
                end;
         end;
   end;

{$IFDEF ENGLISH}
putenv ('XYZ=This is a test string for the spawned process');
{$ELSE}
putenv ('XYZ=Dies ist eine Umgebungsvariable fÅr den aufgerufenen Proze·');
{$ENDIF}

repeat
{$IFDEF ENGLISH}
   writeln; write ('EXEC filename,params ("." to exit): ');
{$ELSE}
   writeln; write ('Dateiname,Parameter ("." beendet): ');
{$ENDIF}
   readln (fn);
   writeln;
   if fn = '.'
      then exit;
   i := pos (',', fn);
   if i > 0
      then begin
      par := copy (fn, i + 1, length (fn) - i);
      fn [0] := chr (i - 1);
      end
      else par := '';

   i := RunExec (fn, par, method, needed, env);

{$IFDEF ENGLISH}
   writeln ('DO_EXEC returned ', hexstr (i));
{$ELSE}
   writeln ('DO_EXEC liefert ', hexstr (i));
{$ENDIF}
until false;
end.


