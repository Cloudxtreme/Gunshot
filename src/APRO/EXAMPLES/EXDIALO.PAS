{$I APDEFINE.INC}
program ExDialO; {EXDIALO.PAS}

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
  OoCom,
  ApMisc,
  ApPort,
  OoModem2,
  OoModDB;

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
  ThePort : UartPortPtr;
  ModemObj : ModemPtr;

{allows operation to be aborted by pressing ESC}
function AbortIt : Boolean; far;
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

{handles displaying status information}
procedure SayStatus(P : ModemPtr; MsgType, SecsRemaining : Word); far;
begin
  case MsgType of
    ecTimeUpd :
      Writeln('Time remaining : ', SecsRemaining,' seconds.');
    ecConnect :
      Writeln('Connection established.');
    ecGotBaud :
      Writeln('Baud rate is ', P^.GetConnectSpeed);
    ecGotDataCompression :
      Writeln('Data compression is now ', P^.GetDataCompression);
    ecGotErrorCorrection :
      Writeln('Error correction is now ', P^.GetErrorCorrection)
    else
      Writeln(StatusStr(MsgType));
  end;
end;

begin
  {creates a new port}
  New(ThePort, InitFast(Com1, 19200));
  if ThePort = nil then begin
    Writeln('Error initializing port.');
    Halt;
  end;
  ThePort^.SetAbortFunc(AbortIt);

  {creates a new modem object, connected with the port specified above}
  New(ModemObj, Init(ThePort, DefModemData));
  if ModemObj = nil then begin
    Writeln('Error initializing modem object : ');
    Halt;
  end;
  ModemObj^.SetStatusProc(SayStatus);

  {initializes the modem}
  ModemObj^.Initialize(True);
  if AsyncStatus <> ecOk then begin
    Writeln('Error initializing modem : ', StatusStr(AsyncStatus));
    Halt;
  end;
  Writeln('Modem initialized.');

  {dials the modem}
  Writeln('Beginning dial attempt...');
  ModemObj^.Dial('260-9726', True);
  if AsyncStatus <> ecConnect then begin
    Writeln('Error dialing modem : ', StatusStr(AsyncStatus));
    Halt;
  end;

  {disposes of objects}
  Dispose(ModemObj, Done);
  Dispose(ThePort, Done);
end.
