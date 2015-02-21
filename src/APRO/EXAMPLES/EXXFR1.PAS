program ExXfr1; {EXXFR1.PAS}
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
    if C = #0 then C := ReadKey;
    if C = #$1B then KbdAbort := True;
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

{$F+}
procedure ProtocolLogging(P : ProtocolRecPtr; LogFileStatus : LogFileType);
var
  FLog : Text;
begin
  Assign(FLog, 'EXAMPLE.HIS');
  Append(FLog);
  if IOResult = 2 then
    ReWrite(FLog);
  if IOResult <> 0 then
    Exit;
  case LogFileStatus of
    lfReceiveStart : WriteLn(FLog, GetFilename(P), ' receive start');
    lfReceiveOk    : WriteLn(FLog, GetFilename(P), ' receive ok');
    lfReceiveFail  : WriteLn(FLog, GetFilename(P), ' receive failed');
    lfReceiveSkip  : WriteLn(FLog, GetFilename(P), ' receive skipped');
    lfTransmitStart: WriteLn(FLog, GetFilename(P), ' transmit start');
    lfTransmitOk   : WriteLn(FLog, GetFilename(P), ' transmit ok');
    lfTransmitFail : WriteLn(FLog, GetFilename(P), ' transmit failed');
    lfTransmitSkip : WriteLn(FLog, GetFilename(P), ' transmit skipped');
  end;
  Close(FLog);
  if IOResult <> 0 then ;
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

  {Set abort and status procedure}
  SetAbortFunc(ComPort, KbdAbort);
  SetShowStatusProc(Protocol, ProtocolStatus);

  {Set logging procedure}
  SetLogFileProc(Protocol, ProtocolLogging);

  {Transmit one file}
  SetFileMask(Protocol, 'EXXFR.PAS');
  ProtocolTransmitZM(Protocol);;
  if AsyncStatus = ecOk then
    WriteLn('Transfer complete OK')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  DoneZmodem(Protocol);
  DonePort(ComPort);
end.
