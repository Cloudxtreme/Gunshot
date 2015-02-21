{$R-,S-,I-}
program ExXfrO; {EXXFRO.PAS}
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
    if C = #0 then C := ReadKey
    else if C = #$1B then KbdAbort := True;
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

begin
  {Make port and protocol objects}
  New(ComPort, InitCustom(Com2, 9600, NoParity, 8, 1, 2048, 2078, DefPortOptions));
  if ComPort = nil then
    Abort('Failed to open port', AsyncStatus);
  New(Protocol, Init(ComPort));
  if Protocol = nil then
    Abort('Failed to initialize protocol', AsyncStatus);

  {Set abort and status procedures}
  ComPort^.SetAbortFunc(KbdAbort);
  Protocol^.SetShowStatusProc(ProtocolStatus);

  {Transmit one file}
  Protocol^.SetFileMask('EXXFRO.PAS');
  Protocol^.ProtocolTransmit;
  if AsyncStatus = ecOk then
    WriteLn('Transfer completed')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  Dispose(Protocol, Done);
  Dispose(ComPort, Done);
end.
