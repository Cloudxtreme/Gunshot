{$I APDEFINE.INC}
program ExAnswer;

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
  ThePort : PortRecPtr;
  YourModem : ModemRecPtr;

function AbortIt : Boolean;
  {$IFDEF UsePModeDLL} export; {$ELSE} far; {$ENDIF}
begin
  AbortIt := False;
  if KeyPressed then
    if ReadKey = #27 then
      AbortIt := True;
end;

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
  InitPortFast(ThePort, Com2, 19200);
  if ThePort = nil then begin
    Writeln('Error initializing port.');
    Halt;
  end;
  SetAbortFunc(ThePort, AbortIt);

  {creates a new modem object, connected with the port specified above}
  InitModem(YourModem, ThePort, DefModemData);
  if YourModem = nil then begin
    Writeln('Error initializing modem object : ');
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

  {answers the modem}
  Writeln('Entering auto answer mode ...');
  Writeln('(Press ESC to abort wait.)');
  AutoAnswer(YourModem, 2);
  DoneModem(YourModem);
  DonePort(ThePort);
end.