{$R-,S-,I-}

{$DEFINE TestIn}           {For testing input}
{$DEFINE TestOut}          {For testing output}

program ExTFDDO;          {EXTFDDO.PAS}
  {-Test a serial port TFDD}
uses
  Crt,
  ApMisc,
  ApPort,
  ApUart,
  OoCom,
  OoTFDD;

var
  UP : UartPort;
  C : Char;
  ComPort : Text;
  R : Real;
  S : String;
  Result : Word;

procedure Abort(Msg : String; Code : Integer);
  {-Close port and halt}
begin
  WriteLn(Msg, Code);
  Halt(1);
end;

{$F+}
function KbdAbort : Boolean;
  {-Default abort function}
const
  Escape = #$1B;
var
  Ch : Char;
begin
  KbdAbort := False;
  if KeyPressed then begin
    Ch := ReadKey;
    if Ch = #0 then
      Ch := ReadKey;
    if Ch = Escape then
      KbdAbort := True;
  end;
end;
{$F-}

begin
  {Open a port}
  UP.InitCustom(Com2,
                4800, NoParity, 8, 1,
                50, 50,
                DefPortOptions);
  if AsyncStatus <> ecOk then
    Abort('Failed to open port: ', AsyncStatus);
  UP.SetAbortFunc(KbdAbort);

{$IFDEF TestIn}
  {Assign the opened port to a text file device driver}
  AssignPortDev(ComPort, @UP);
  Reset(ComPort);

  {Read strings until keypressed}
  WriteLn('Reads strings from remote -- press ^C to abort');
  repeat
    ReadLn(ComPort, S);
    Result := IOResult;
    WriteLn(S);
  until (Result <> 0) or Eof(ComPort);
  if Result <> 0 then
    WriteLn('ReadLn failed: ', Result);
{$ENDIF}

{$IFDEF TestOut}
  {Assign the opened port to a text file device driver}
  AssignPortDev(ComPort, @UP);
  Rewrite(ComPort);

  {Write some formatted strings}
  R := 123.456;
  WriteLn(ComPort, 'This is an unformatted real number: ', R);
  WriteLn(ComPort, 'This is a formatted real number: ', R:0:3);
  WriteLn(ComPort, 'Test':20, 'Test':20);
{$ENDIF}

  Close(ComPort);
  UP.Done;
end.
