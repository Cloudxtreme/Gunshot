program ExXfr3; {EXXFR3.PAS}
uses
  Crt, Dos, ApMisc, ApPort, ApUart, ApCom, ApAbsPcl, ApZmodem, ApArchiv;
var
  ComPort : PortRecPtr;
  Protocol : ProtocolRecPtr;
  FML : FileMaskList;

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
function NextFileMaskList(P : ProtocolRecPtr; var FName : PathStr) : Boolean;
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
    if P^.PData^.FindingFirst then begin
      FindFirst('*.*', AnyFileButDir, P^.PData^.CurRec);
      P^.PData^.FindingFirst := False;
    end else
      FindNext(P^.PData^.CurRec);

    {Check for errors}
    if DosError <> 0 then begin
      {Failed to find file, return error status}
      case DosError of
        3  : GotError(P^.PData^.PR, epFatal+ecDirNotFound);
        18 : Finished := True;
      end;
    end else if MatchFileMask(P^.PData^.CurRec.Name, FML) then begin
      FName := P^.PData^.CurRec.Name;
      NextFileMaskList := True;
      Exit;
    end;
  until Finished;
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

  {Make a FileMaskList object}
  InitFileMaskList(FML);

  {Add a couple of file masks}
  if not AppendFileMask('*.aaa', FML) then {handle error} ;
  if not AppendFileMask('*.bbb', FML) then {handle error} ;

  {Set our next-file function}
  SetNextFileFunc(Protocol, NextFileMaskList);

  {Transmit matching files}
  ProtocolTransmitZM(Protocol);;
  if AsyncStatus = ecOk then
    WriteLn('Transfer complete OK')
  else
    WriteLn('Transfer failed: ', AsyncStatus);

  DoneZmodem(Protocol);
  DonePort(ComPort);
end.
