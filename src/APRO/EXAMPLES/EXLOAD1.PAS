{$I APDEFINE.INC}
{$IFNDEF UseOpro}
  !! STOP COMPILE - this unit requires UseOpro to be defined
{$ENDIF}
{$I OPDEFINE.INC}
{$IFNDEF UseStreams}
  !! STOP COMPILE - this unit requires UseStreams to be defined
{$ENDIF}

program ExLoad1; {EXLOAD1.PAS}
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
      Ch := ReadKey
    else if Ch = Escape then
      KbdAbort := True;
  end;
end;
{$F-}

begin
  {Open the existing stream}
  if not S.Init('UPORT.STM', SOpen, 1024) then
    Abort('Failed to open stream: ', InitStatus);

  {Register the port object hierarchy}
  S.RegisterHier(UartPortStream);
  S.RegisterPointer(ptErrorProc, @MyErrorProc);
  S.RegisterPointer(ptAbortProc, @KbdAbort);
  Status := S.GetStatus;
  if Status <> 0 then
    Abort('Error registering port object: ', Status);

  {Load UP from the stream}
  S.Get(UP);
  Status := S.GetStatus;
  if Status <> 0 then
    Abort('Error loading port object: ', Status);
  S.Done;

  {Use the port in a simple terminal}
  Writeln('Press <AltX> to quit');
  Finished := False;
  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then begin
        C := ReadKey;
        if C = #$2D then
          Finished := True;
      end
      else if UP.TransReady then
        UP.PutChar(C);
    end;

    {Process chars received}
    if UP.CharReady then begin
      UP.GetChar(C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'Line error ', AsyncStatus);
        UP.FlushInBuffer;
      end else
        Write(C);
    end;
  until Finished;
  UP.Done;
end.
