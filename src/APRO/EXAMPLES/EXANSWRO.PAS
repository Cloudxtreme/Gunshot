{$I APDEFINE.INC}
program ExAnswerO; {EXANSWRO.PAS}

uses
  Crt,
  OoCom,
  ApMisc,
  ApPort,
  OoModem2,
  OoModDB;

const
  {modem defaults}
  DefModemData : ModemData =
    (Data            : (
      Name          : '';
      InitCmd       : 'ATZ^M';
      DialCmd       : 'ATD';
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

{allows operation to be halted with pressing of ESC}
function AbortIt : Boolean; far;
begin
  AbortIt := False;
  if KeyPressed then
    if ReadKey = #27 then
      AbortIt := True;
end;

{handles status checking}
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
  New(ThePort, InitFast(Com2, 19200));
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

  {answers the modem}
  Writeln('Entering auto answer mode ...');
  Writeln('(Press ESC to abort wait.)');
  ModemObj^.AutoAnswer(2);

  {disposes of objects when done}
  Dispose(ModemObj, Done);
  Dispose(ThePort, Done);
end.
