{$I APDEFINE.INC}
program ExDial; {EXDIAL.PAS}

uses
{$IFDEF UseOPro}
  OpCrt,
{$ENDIF}
{$IFDEF UseTPro}
    TpCrt,
{$ENDIF}
{$IFDEF StandAlone}
    Crt,
{$ENDIF}
{$IFDEF UsePModeDLL}
  ApComD;
{$ELSE}
  ApUart,
  ApCom,
  ApMisc,
  ApPort,
  ApModem2,
  ApModDB;
{$ENDIF}

const
  {default modem parameters}
  DefModemData : ModemData =
    (Data            : (
      Name          : '';
      InitCmd       : 'ATZ^M';
      DialCmd       : 'ATDT';
      DialTerm      : '^M';
      DialCancel    : '^M';
      HangupCmd     : '+++~~~ATH0^M';
      ConfigCmd     : 'ATE1Q0X1V1^M';
      AnswerCmd     : 'ATA^M';
      OkMsg         : 'OK';
      ConnectMsg    : 'CONNECT';
      BusyMsg       : 'BUSY';
      VoiceMsg      : 'VOICE';
      NoCarrierMsg  : 'NO CARRIER';
      NoDialToneMsg : 'NO DIALTONE';
      ErrorMsg      : 'ERROR';
      RingMsg       : 'RING'
    );
    NumErrors       : 0;
    Errors          : ('', '', '', '', '');
    NumComps        : 0;
    Compression     : ('', '', '', '', '');
    LockDTE         : True;
    DefBaud         : 19200
  );

var
  ThePort : PortRecPtr;
  YourModem : ModemRecPtr;

{allows operation to be aborted by pressing ESC}
function AbortIt : Boolean;
  {$IFDEF UsePModeDLL} export; {$ELSE} far; {$ENDIF}
var
  Ch : Char;
begin
  AbortIt := False;
  if KeyPressed then
    Ch := ReadKey;
    if (Ch = #0) then
      Ch := ReadKey
    else
      AbortIt := (Ch = #27);
end;

{handles displaying of status messages}
procedure SayStatus(P : ModemRecPtr; MsgType, SecsRemaining : Word);
  {$IFDEF UsePModeDLL} export; {$ELSE} far; {$ENDIF}
begin
  case MsgType of
    ecTimeUpd :
      Writeln('Time remaining : ', SecsRemaining,' seconds.');
    ecConnect :
      Writeln('Connection established.');
    ecGotBaud :
      Writeln('Baud rate is ', GetConnectSpeed(P));
    ecGotDataCompression :
      Writeln('Data compression is now ', GetDataCompression(P));
    ecGotErrorCorrection :
      Writeln('Error correction is now ', GetErrorCorrection(P));
    else
      Writeln(StatusStr(MsgType));
  end;
end;

begin
  {creates a new port}
  InitPortFast(ThePort, Com1, 19200);
  if ThePort = nil then begin
    Writeln('Error initializing port.');
    Halt;
  end;
  SetAbortFunc(ThePort, AbortIt);

  {creates a new modem object, connected with the port specified above}
  InitModem(YourModem, ThePort, DefModemData);
  if YourModem = nil then begin
    Writeln('Error initializing modem object : ', GetAsyncStatus);
    Halt;
  end;
  SetStatusProc(YourModem, SayStatus);

  {initializes the modem}
  Initialize(YourModem, True);
  if GetAsyncStatus <> ecOk then begin
    Writeln('Error initializing modem : ', StatusStr(GetAsyncStatus));
    Halt;
  end;
  Writeln('Modem initialized.');

  {dials a number}
  Writeln('Beginning dial attempt...');
  Dial(YourModem, '260-9726', True);
  if GetAsyncStatus <> ecConnect then begin
    Writeln('Error dialing modem : ', StatusStr(GetAsyncStatus));
    Halt;
  end;

  {done with data structures}
  DoneModem(YourModem);
  DonePort(ThePort);
end.
