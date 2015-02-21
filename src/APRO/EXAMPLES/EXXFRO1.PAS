{$R-,S-,I-}
program ExXfrO1; {EXXFRO1.PAS}
uses
  Crt, ApMisc, ApPort, ApUart, OoCom, OoAbsPcl, OoZmodem;
var
  ComPort : UartPortPtr;
  Protocol : ZmodemProtocolPtr;

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
procedure ProtocolStatus(AP : AbstractProtocolPtr; Starting, Ending : Boolean);
begin
  if Starting then
    WriteLn(ProtocolTypeString[AP^.GetProtocol], ' started');

  WriteLn('Bytes transferred: ', AP^.GetBytesTransferred,
          '   Bytes remaining: ', AP^.GetBytesRemaining);

  if Ending then
    WriteLn(ProtocolTypeString[AP^.GetProtocol], ' ended');
end;
{$F-}

{$F+}
procedure ProtocolLogging(AP : AbstractProtocolPtr; LogFileStatus : LogFileType);
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
    lfReceiveStart : WriteLn(FLog, AP^.GetFilename, ' receive start');
    lfReceiveOk    : WriteLn(FLog, AP^.GetFilename, ' receive ok');
    lfReceiveFail  : WriteLn(FLog, AP^.GetFilename, ' receive failed');
    lfReceiveSkip  : WriteLn(FLog, AP^.GetFilename, ' receive skipped');
    lfTransmitStart: WriteLn(FLog, AP^.GetFilename, ' transmit start');
    lfTransmitOk   : WriteLn(FLog, AP^.GetFilename, ' transmit ok');
    lfTransmitFail : WriteLn(FLog, AP^.GetFilename, ' transmit failed');
    lfTransmitSkip : WriteLn(FLog, AP^.GetFilename, ' transmit skipped');
  end;
  Close(FLog);
  if IOResult <> 0 then ;
end;
{$F-}

begin
  {Make port and protocol objects}
  New(ComPort, InitCustom(Com2, 9600, NoParity, 8, 1, 2078, 2078, DefPortOptions));
  if ComPort = nil then
    Abort('Failed to open port', AsyncStatus);
  New(Protocol, Init(ComPort));
  if Protocol = nil then
    Abort('Failed to initialize protocol', AsyncStatus);

  {Set abort and status procedures}
  ComPort^.SetAbortFunc(KbdAbort);
  Protocol^.SetShowStatusProc(ProtocolStatus);

  {Set logging procedure}
  Protocol^.SetLogFileProc(ProtocolLogging);

  {Transmit one file}
  Protocol^.SetFileMask('EXXFR.PAS');
  Protocol^.ProtocolTransmit;
  if AsyncStatus = ecOk then
    WriteLn('Transfer complete OK')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  Dispose(Protocol, Done);
  Dispose(ComPort, Done);
end.
