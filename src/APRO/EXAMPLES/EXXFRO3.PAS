{$R-,S-,I-}
program ExXfrO3; {EXXFRO3.PAS}
uses
  Crt, Dos, ApMisc, ApPort, ApUart, OoCom, OoAbsPcl, OoZmodem, OoArchiv;
var
  ComPort : UartPortPtr;
  Protocol : ZmodemProtocolPtr;
  FML : FileMaskListPtr;

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
function NextFileMaskList(AP : AbstractProtocolPtr;
                          var FName : PathStr) : Boolean;
  {-Custom function to compare all files in dir against list of masks}
const
  AnyFileButDir = AnyFile and not Directory;
var
  Finished : Boolean;
begin
  AsyncStatus := 0;
  FName := '';
  NextFileMaskList := False;
  Finished := False;

  {Loop through all files until we find one that meets a mask}
  repeat
    if AP^.FindingFirst then begin
      FindFirst('*.*', AnyFileButDir, AP^.CurRec);
      AP^.FindingFirst := False;
    end else
      FindNext(AP^.CurRec);

    {Check for errors}
    if DosError <> 0 then begin
      {Failed to find file, return error status}
      case DosError of
        3  : AP^.APort^.GotError(epFatal+ecDirNotFound);
        18 : Finished := True;
      end;
    end else if FML^.Match(AP^.CurRec.Name) then begin
      FName := AP^.CurRec.Name;
      NextFileMaskList := True;
      Exit;
    end;
  until Finished;
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

  {Make a FileMaskList object}
  New(FML, Init);
  if FML = nil then
    Abort('Failed to initialize file mask', AsyncStatus);

  {Add a couple of file masks}
  if not FML^.Append('*.aaa') then {handle error} ;
  if not FML^.Append('*.bbb') then {handle error} ;

  {Set our next-file function}
  Protocol^.SetNextFileFunc(NextFileMaskList);

  {Transmit all matching files}
  Protocol^.ProtocolTransmit;
  if AsyncStatus = ecOk then
    WriteLn('Transfer complete OK')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  Dispose(Protocol, Done);
  Dispose(ComPort, Done);
end.
