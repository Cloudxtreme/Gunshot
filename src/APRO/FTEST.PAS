{$R-,S-,F+}
{$M 8192, 0, 655350}

{$I APDEFINE.INC}       {Defines we care about it}

{$IFDEF UseUart}
{$IFDEF UseFossil}
  Error - This program only supports one device layer at a time.
          Disable UseUart or UseFossil in APDEFINE.INC
          (See COMTEST for an example of multiple device layers.)
{$ENDIF}
{$ENDIF}

{******************************************************}
{*                    FTEST.PAS 2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

program FossilTest;
  {-A simple terminal}
uses
  {$IFDEF UseOpro}
  OpCrt,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpCrt,
  {$ENDIF}
  {$IFDEF Standalone}
  Crt,
  {$ENDIF}
  ApMisc,
  ApPort,
  ApAnsi,
  {$IFDEF UseFossil}
  ApFossil,
  {$ENDIF}
  {$IFDEF UseUart}
  ApUart,
  {$ENDIF}
  ApCom,
  ApAbsPcl,
  ApXmodem,
  ApYmodem,
  ApZmodem,
  ApKermit,
  ApAscii;

const
  {Change these constants as required}
  DesiredPort = Com2;
  Speed       = 19200;

var
  ComPort : PortRecPtr;
  C : Char;
  Finished : Boolean;

function KbdAbort : Boolean;
  {-Return True if user wants to abort}
var
  C : Char;
begin
  KbdAbort:=False;
  if KeyPressed then begin
    C:=ReadKey;
    if C=#0 then
      C:=ReadKey
    else if C = #$1B then
      KbdAbort:=True;
  end;
end;

procedure ProtocolStatus(P : ProtocolRecPtr;
                         Starting, Ending : Boolean);
  {-Display simple protocol status}
const
  LastFileName : String = '';
var
  FileName : String;
begin
  if Starting then
    Writeln(ProtocolTypeString[GetProtocol(P)],' starting');

  FileName := GetPathName(P);
  if FileName = '' then
    FileName := GetFileName(P);
  if LastFileName <> FileName then begin
    WriteLn;
    LastFileName := FileName;
  end;

  if FileName <> '' then begin
    GotoXY(1, 25);
    ClrEol;
    Write(FileName, ': ', GetBytesTransferred(P),
          '/', GetBytesRemaining(P));
  end;

  if Ending then begin
    Writeln;
    Writeln(ProtocolTypeString[GetProtocol(P)],' ending');
  end;
end;

function GetProtocol : ProtocolRecPtr;
  {-Ask which protocol}
var
  C : Char;
  PP : ProtocolRecPtr;
begin
  PP := nil;
  repeat
    WriteLn;
    WriteLn;
    WriteLn('A - ASCII');
    WriteLn('X - Xmodem  K - Xmodem1K  L - Xmodem1KG');
    WriteLn('Y - Ymodem  G - YmodemG');
    WriteLn('Z - Zmodem');
    WriteLn('F - Kermit');
    WriteLn('Q - cancel protocol');
    Write('Protocol: ');
    C := Upcase(ReadKey);
    Write(C);

    case C of
      'X' : InitXmodem(PP, ComPort, False, False);
      'K' : InitXmodem(PP, ComPort, True, False);
      'L' : InitXmodem(PP, ComPort, True, True);
      'Y' : InitYmodem(PP, ComPort, True, False);
      'G' : InitYmodem(PP, ComPort, True, True);
      'Z' : InitZmodem(PP, ComPort);
      'F' : InitKermit(PP, ComPort);
      'A' : InitAscii(PP, ComPort);
    end;
  until C in ['X', 'K', 'L', 'Y', 'G', 'Z', 'F', 'A', 'Q'];
  GetProtocol := PP;
end;

procedure UploadFile;
  {-Transmit a file}
var
  FileName : String;
  Protocol  : ProtocolRecPtr;
label
  ExitPoint;
begin
  Protocol := GetProtocol;
  if Protocol = nil then begin
    Writeln('Failed to initialize protocol object: ',AsyncStatus);
    Exit;
  end;
  SetAbortFunc(ComPort, KbdAbort);

  WriteLn;
  Write('Upload file name: ');
  Readln(FileName);
  if FileName = '' then
    goto ExitPoint;

  SetShowStatusProc(Protocol, ProtocolStatus);
  SetFileMask(Protocol, FileName);
  case Protocol^.PData^.ProtType of
    Xmodem..Xmodem1KG : ProtocolTransmitXM(Protocol);
    Ymodem..YmodemG   : ProtocolTransmitYM(Protocol);
    Zmodem            : ProtocolTransmitZM(Protocol);
    Kermit            : ProtocolTransmitKM(Protocol);
    Ascii             : ProtocolTransmitAS(Protocol);
  end;

  if AsyncStatus = ecOk then
    Writeln('Upload completed successfully!')
  else
    Writeln('Upload failed: ',AsyncStatus);

ExitPoint:
  case Protocol^.PData^.ProtType of
    Xmodem..Xmodem1KG : DoneXmodem(Protocol);
    Ymodem..YmodemG   : DoneYmodem(Protocol);
    Zmodem            : DoneZmodem(Protocol);
    Kermit            : DoneKermit(Protocol);
    Ascii             : DoneAscii(Protocol);
  end;
end;

procedure DownloadFile;
  {-Receive a file}
var
  FilePath : String;
  Protocol : ProtocolRecPtr;
label
  ExitPoint;
begin
  Protocol := GetProtocol;
  if Protocol = nil then begin
    Writeln('Failed to initialize protocol object: ',AsyncStatus);
    Exit;
  end;

  WriteLn;
  if SupportsBatch(Protocol) then
    Write('Download path: ')
  else
    Write('File name and path:');
  Readln(FilePath);
  SetAbortFunc(ComPort, KbdAbort);

  SetShowStatusProc(Protocol, ProtocolStatus);
  if SupportsBatch(Protocol) then
    SetDestinationDirectory(Protocol, FilePath)
  else
    SetReceiveFileName(Protocol, FilePath);

  case Protocol^.PData^.ProtType of
    Xmodem..Xmodem1KG : ProtocolReceiveXM(Protocol);
    Ymodem..YmodemG   : ProtocolReceiveYM(Protocol);
    Zmodem            : ProtocolReceiveZM(Protocol);
    Kermit            : ProtocolReceiveKM(Protocol);
    Ascii             : ProtocolReceiveAS(Protocol);
  end;

  if AsyncStatus = ecOk then
    Writeln('Download completed successfully!')
  else
    Writeln('Download failed: ',AsyncStatus);

ExitPoint:
  case Protocol^.PData^.ProtType of
    Xmodem..Xmodem1KG : DoneXmodem(Protocol);
    Ymodem..YmodemG   : DoneYmodem(Protocol);
    Zmodem            : DoneZmodem(Protocol);
    Kermit            : DoneKermit(Protocol);
    Ascii             : DoneAscii(Protocol);
  end;
end;

begin
  {Open a port}
  InitPortFast(ComPort, DesiredPort, Speed);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to open port: ', AsyncStatus);
    Halt;
  end;

  {$IFDEF UseFossil}
  {Handle FOSSIL OutBuffUsed bug}
  ptOptionsOn(ComPort, ptHandleFossilBug or ptPutCharWait);
  {$ENDIF}

  Finished := False;
  Writeln('<PGUP> to upload, <PGDN> to download, ALT-X to exit');

  {$IFDEF TRACING}
  InitTracing(4000);
  {$ENDIF}

  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then
      begin
        C := ReadKey;
        Case C of
          #$2D: Finished := True;
          #$49: UploadFile;
          #$51: DownloadFile;
        end;
      end else begin
        while not TransReady(ComPort) do ;
        PutChar(ComPort, C);
      end;
    end;

    {Process chars received}
    if CharReady(ComPort) then begin
      GetChar(ComPort, C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'Line error ', AsyncStatus);
        FlushInBuffer(ComPort);
      end else
        WriteCharAnsi(C);
    end;
  until Finished;

  {$IFDEF TRACING}
  DumpTrace('FTEST.TRC');
  {$ENDIF}

  DonePort(ComPort);
end.
