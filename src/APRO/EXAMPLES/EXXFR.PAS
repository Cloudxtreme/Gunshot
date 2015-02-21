program ExXfr; {EXXFR.PAS}
uses
  Crt, ApMisc, ApPort, ApUart, ApCom, ApAbsPcl, ApZmodem;
var
  ComPort : PortRecPtr;
  Protocol : ProtocolRecPtr;

procedure Abort(Msg : String; Code : Word);
begin
  WriteLn(Msg, ': ', Code);
  Halt;
end;

{$F+}
function KbdAbort : Boolean;
var
  C : Char;
begin
  KbdAbort := False;
  if KeyPressed then begin
    C := ReadKey;
    if C = #0 then C := ReadKey
    else if C = #$1B then KbdAbort := True;
  end;
end;
{$F-}

{$F+}
procedure ProtocolStatus(P : ProtocolRecPtr; Starting, Ending : Boolean);
begin
  if Starting then
    WriteLn(ProtocolTypeString[GetProtocol(P)], ' started');

  WriteLn('Bytes transferred: ', GetBytesTransferred(P),
          '   Bytes remaining: ', GetBytesRemaining(P));

  if Ending then
    WriteLn(ProtocolTypeString[GetProtocol(P)], ' ended');
end;
{$F-}

begin
  {Make port and protocol records}
  InitPort(ComPort, Com2, 9600, NoParity, 8, 1, 2048, 2078, DefPortOptions);
  if AsyncStatus <> ecOk then
    Abort('Failed to open port', AsyncStatus);
  InitZmodem(Protocol, ComPort);
  if AsyncStatus <> ecOk then
    Abort('Failed to initialize protocol', AsyncStatus);

  {Set abort and status procedures}
  SetAbortFunc(ComPort, KbdAbort);
  SetShowStatusProc(Protocol, ProtocolStatus);

  {Transmit one file}
  SetFileMask(Protocol, 'EXXFR.PAS');
  ProtocolTransmitZM(Protocol);;
  if AsyncStatus = ecOk then
    WriteLn('Transfer completed')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  DoneZmodem(Protocol);
  DonePort(ComPort);
end.
