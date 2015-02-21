{$I APDEFINE.INC}
{$IFNDEF UseOpro}
  !! STOP COMPILE - this unit requires UseOpro to be defined
{$ENDIF}
{$I OPDEFINE.INC}
{$IFNDEF UseStreams}
  !! STOP COMPILE - this unit requires UseStreams to be defined
{$ENDIF}

program ExStore1; {EXSTORE1.PAS}
uses
  Crt, OpRoot, ApMisc, ApPort, ApUart, OOCom;
var
  UP : UartPort;
  C : Char;
  Finished : Boolean;
  S : BufIdStream;
  Status : Word;

procedure Abort(Msg : String; Code : Integer);
  {-Close port and halt}
begin
  WriteLn(Msg, Code);
  Halt(1);
end;

{$F+}
procedure MyErrorProc(P : Pointer; var StatusCode : Word);
begin
  with PortRecPtr(P)^ do
    WriteLn(StatusStr(StatusCode mod 10000)+'  Press <Enter>');
  Readln;
end;

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
  if not UP.InitCustom(Com1,
                       1200, NoParity, 8, 1,
                       500, 500,
                       DefPortOptions) then
    Abort('Failed to open port: ', AsyncStatus);

  {Set various port options}
  UP.SetErrorProc(MyErrorProc);
  UP.SetAbortFunc(KbdAbort);

  {Create a new stream}
  if not S.Init('UPORT.STM', SCreate, 1024) then
    Abort('Failed to make stream: ', InitStatus);

  {Register the port object hierarchy}
  S.RegisterHier(UartPortStream);
  S.RegisterPointer(ptErrorProc, @MyErrorProc);
  S.RegisterPointer(ptAbortProc, @KbdAbort);
  Status := S.GetStatus;
  if Status <> 0 then
    Abort('Error registering port object: ', Status);

  {Store the port}
  S.Put(UP);
  Status := S.GetStatus;
  if Status <> 0 then
    Abort('Error storing UP: ', Status);

  {Clean up}
  UP.Done;
  S.Done;
end.

