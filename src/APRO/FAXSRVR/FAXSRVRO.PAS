{$R-,S-,A+,F-,I-,V-,B-,G+}
{$M 8192, 0, 655360}

{******************************************************}
{*                 FAXSRVRO.PAS  2.03                 *}
{*    Copyright (c) TurboPower Software 1993-94.      *}
{*                All rights reserved.                *}
{******************************************************}

{$I APDEFINE.INC}

{This define allows receiving fax's while printing a fax}
{$DEFINE ReceiveDuringPrint}

program FaxSrvro;
  {-Send/Receive-fax server with fax printing}

{!!.02 numerous changes added to support fax sending}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Dos,
  Dpmi,
  ApMisc,
  ApPort,
  ApUart,
  ApTimer,
  FastW1,
  {$IFDEF UseOpro}
  OpInline,
  OpCrt,
  OpDos,
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTpro}
  TpInline,
  TpCrt,
  TpDos,
  TpMemChk,
  TpString,                                                            {!!.01}
  {$ENDIF}
  {$IFDEF StandAlone}
  Crt,
  {$ENDIF}
  OoCom,
  OoFax12,
  OoAbsFax,
  OoFaxCvt,
  OoFaxPrn,              {Fax print unit}
  TxBrowse,              {Text file browser}
  FsIni,                 {Ini file routines}
  FsMisc,                {Utilities}
  FsCList;               {Command file list and support routines}

const
  ProgramName      = 'FAXSRVRO';
  LogFilename      = ProgramName + '.LOG';
  TmpApfName       = '$TEMP$.APF';

  {$IFDEF Tracing}
  TraceFilename    = ProgramName + '.TRC';
  {$ENDIF}

  Copyright        =
 ' Send/Receive-Fax Server   (c) 1993-94 TurboPower Software ';

  PrintedFaxExt    = 'AP$';  {Printed fax files have this extension}
  AbortedFaxExt    = 'AP!';  {Used for fax files that were aborted}
  CmdFileExt       = 'CMD';  {Extension used for command files}
  CWCmdFileExt     = 'CM$';  {Completed command file extension}
  DeleteFlagChar   = '*';    {Prepended character to flag file for delete}
  FailedPrintExt   = 'AP#';  {Extension for failed print fax files}    {!!.03}

  HelpLine         =
 '<P>urge faxes  <V>iew log  <D>elete log  <S>hell to DOS  <T>oggle printing';

  DividerBar =
 '쳐컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴캑';

const
  DefHeader = '$D  $T  $S    Page $P of $N';

const
  {Typed constants - options}
  ComPort          : ComNameType = Com1;      {Default comm port}
  PortSpeed        : LongInt     = 19200;     {Default port speed}
  FaxClass         : ClassType   = ctClass2;  {Deafult to Class II}
  FaxBaudRate      : Word        = 14400;     {Default fax baud rate}
  FaxFilePath      : PathStr     = '';        {Path to fax files}
  PrintDest        : PathStr     = 'PRN';     {Default print destination}
  UseEpson         : Boolean     = False;     {True to use Epson printer}
  UseEpson24       : Boolean     = False;     {True to use Epson 24 pin printer}
  UseHP300         : Boolean     = False;     {True to use 300 dpi res}
  UseScaling       : Boolean     = True;      {Are we scaling the output}
  UsePcl5Mode      : Boolean     = False;     {Use HP PCL5 print commands}
  SuppressBlanks   : Boolean     = False;     {Suppress printing large blank areas}
  BlankSize        : Word        = 60;        {Maximum blank area to leave}   {!!.01}
  CommandBaud      : LongInt     = 0;         {Baud rate for modem init cmds} {!!.01}
  CmdFilePath      : PathStr     = '';        {Path for command files}
  RetryWaitTime    : Integer     = 5*60;      {Time to wait for a retry}
  MaxFaxRetries    : Integer     = 5;         {Maximum retry attempts}
  EraseCmdFiles    : Boolean     = False;     {Delete cmd files after processing}
  Hangup4Retry     : Boolean     = True;      {Try send twice when hangup code is 4}
  {A hangup code of 4 seems to mean that the number is bad - at least for some modems}

const
  {This stations ID string}
  StationIdStr     : string[20]  = 'FAX SERVER DEMO';

  {Command used to initialize the modem}
  ModemInitStr     : string[20]  = 'ATM0V1X4';

const
  {Misc action and status flags}
  RingIsrInstalled : Boolean = False;  {True when ring ISR is installed}
  AlarmIsrInstalled: Boolean = False;  {True when alarm ISR is installed}
  InitComplete     : Boolean = False;  {Are init's complete}
  ScreenSaved      : Boolean = False;  {Is the screen saved}           {!!.01}
  IsDiskFull       : Boolean = False;  {Set when a disk error received}
  Receiving        : Boolean = False;  {Are we receiving a fax}
  Sending          : Boolean = False;  {Are we sending a fax}
  Printing         : Boolean = False;  {Are we printing}
  PrintSuspended   : Boolean = False;  {Has printing been suspended}
  FaxSendError     : Boolean = False;  {True if we had a fax error}

const
  {Misc constants}
  RingToAnswerOn   = 1;                {Ring count to answer on}
  RingCheckTics    = 36;               {How long to wait between ring checks}
  AlarmTics        = 182;              {10 seconds between alarms}
  MaxInitRetries   = 5;                {Modem init retry count}
  MaxPrintAttempts = 5;                {Number of failures before pausing}
  WaitTimeout      = 30;               {Time to wait for user input}
  OnOffStr         : array[Boolean] of string[3] = ('Off', 'On ');
  MinFaxPrnSize    = 512;              {Smallest failed fax file to print}

const
  {Window color attributes}
  WAttr            : Byte = $1B;       {Window attribute}
  FAttr            : Byte = $1E;       {Frame attribute}
  DAttr            : Byte = $1F;       {Data attribute}
  SAttr            : Byte = $30;       {Browser status attribute}

const
  {Fax log file labels}
  frlOnLine        = '[ OnLine      ] ';
  frlOffLine       = '[ OffLine     ] ';
  frlStart         = '[ StartReceive] ';
  frlEnd           = '[ EndReceive  ] ';
  frlRecFail       = '[*FailReceive ] ';
  frlSkip          = '[ SkipReceive ] ';
  frlPrint         = '[ PrintFax    ] ';
  frlPFail         = '[*PrintFail   ] ';
  frlPPaused       = '[ PrintPaused ] ';
  frlPResumed      = '[ PrintResumed] ';
  frlTransStart    = '[ StartSend   ] ';
  frlTransOk       = '[ EndSend     ] ';
  frlTransFail     = '[*FailSend    ] ';
  frlNote          = '[ Note:       ] ';
  frlBusyNoDial    = '[ BusyNoDial  ] ';
  frlUnk           = '[*UnkStatus   ] ';

const
  {Fax progress strings}
  fpsWaiting       = 'Idle, waiting, nothing to do...';
  fpsNoConnect     = 'No connect on this call';
  fpsAnswer        = 'Answering incoming call';
  fpsIncoming      = 'Incoming call validated as fax';
  fpsGetPage       = 'Getting page data';
  fpsGetPageResult = 'Getting end-of-page signal';
  fpsCheckMorePages= 'Getting end-of-document status';
  fpsGetHangup     = 'Getting hangup command';
  fpsGotHangup     = 'Got Class 2 FHNG code';
  fpsSessionParams = 'Getting connection params';
  fpsGotRemoteID   = 'Got station ID';
  fpsInitModem     = 'Initializing modem for fax processing';
  fpsDialing       = 'Dialing';
  fpsBusyWait      = 'Busy, FaxTransmit is waiting';
  fpsSendPage      = 'Sending document page data';
  fpsSendPageStatus= 'Sending end-of-page signal';
  fpsPageError     = 'Error sending page';
  fpsPageOK        = 'Page accepted by remote';

const
  {General message strings}
  msgAbortQuestion   = 'Abort current process and exit this program (Y/N)?';
  msgBusyRetry       = 'Too many busy/no-dialtone retry attempts';
  msgCoverSheet      = 'Cover Sheet';
  msgFailedToCombine = 'Failed to combine requested fax files. Error: ';
  msgFailedToReset   = 'Failed to reset modem, Status: ';
  msgNoFaxFile       = 'No fax file or cover page to send.';
  msgNothing         = '(Nothing)';
  msgPaused          = '(Paused)';
  msgPressAnyKey     = ' Press any key to continue, <Esc> to quit ';
  msgPrintInitFailed = 'Failed to initialize print object';
  msgVoiceOrData     = 'Voice or Data connection';

const
  {Progress/status display}
  FaxSpinner       = 1;
  PrintSpinner     = 2;

const
  SSSaveTime       = 5*60;  {Time delay for screen save - 5 min}
  SSMoveTime       = 15;    {Time between moves - 15 sec}
  CmdFileScanDelay = 5*60;  {Time between scans for command files}
  FaxQProcessDelay = 15;    {Delay between FaxQ scans}

type
  {Possible user commands}
  CmdType          = (cmdNone,
                      cmdExit,
                      cmdCommandMode,
                      cmdViewLog,
                      cmdPrintLog,
                      cmdDeleteLog,
                      cmdDeleteFaxes,
                      cmdDeleteFailed,
                      cmdTogglePrint,
                      cmdToggleBlank,
                      cmdResetSessionCounts,
                      cmdShell);

  {Screen save actions}
  SSActionType     = (ssSave, ssRestore, ssMove);

var
  Fax              : C12ReceiveFaxPtr; {Receive fax object}
  Port             : UartPortPtr;      {Com port object}
  Printer          : AbstractPrinterPtr;  {Our printer}
  FaxPrinter       : FaxPrinterPtr;    {The fax printer object}
  FaxState         : FaxStateType;     {Current fax engine state}
  RingSaveInt1C    : Pointer;          {Saved timer vector}
  AlarmSaveInt1C   : Pointer;          {Saved timer vector}
  FaxPrnCount      : LongInt;          {Counter of faxes waiting for print}
  FaxRecCount      : LongInt;          {Counter of faxes received}
  FaxSndCount      : LongInt;          {Counter of faxes sent}
  FailedFaxCount   : LongInt;          {Total number of failed faxes}  {!!.01}
  FileToPrint      : PathStr;          {Current fax file to print}
  Done             : Boolean;          {Global exit flag}
  SaveExitProc     : Pointer;          {Pointer to old exit proc}
  Command          : CmdType;          {User command}
  FLF              : Text;             {Fax log file}
  PrintAttempt     : Byte;             {Current print attempt count}

  HighClass        : Char;             {Highest class supported by modem}
  Model,                               {Modem model string}
  Chip,                                {Modem chip id string}
  Rev              : string[60];       {Modem revision string}
  BPS              : LongInt;          {Connect speed}
  Resolution       : Boolean;          {High resolution flag}
  Correction       : Boolean;          {Error correction flag}
  RemoteID         : string[40];       {ID of current connection}
  FaxFilename      : PathStr;          {Incomming fax file name}

  SSPtr            : Pointer;          {Pointer to saved screen}
  SSTimer          : EventTimer;       {Timer for screen saves}

  FaxQ             : CmdFileList;      {Structure for the fax queue}
  ScanTimer        : EventTimer;       {Timer for file scan}
  FaxQProcessTimer : EventTimer;       {Timer for FaxQ processing}
  CommandFileName  : PathStr;          {Name of the current command file}
  AcceptedBPSRate  : LongInt;          {The negotiated connect speed}
  HangupResult     : Word;             {Last modem hangup result}

  procedure UpdateClockDisplay;
    {-update the time if the screen isn't saved}
  var
    DT   : DateTime;
    HS   : Word;
  begin
    if (not ScreenSaved) and (not Receiving) then begin
      FillChar(DT, SizeOf(DT), 0);
      with DT do GetTime(Hour, Min, Sec, HS);
      FastWrite(' '+TimeString(DT)+' ', 1, 70, DAttr);
    end;
  end;

  procedure HandleScreenSave(Action : SSActionType);
  const
    LastMoveTime : LongInt = 0;
    W            = 60;
    H            = 8;
    Msg          : string[W] = ' Press any key to restore screen ';

  var
    T    : LongInt;
    X, Y : Integer;
    DT   : DateTime;
    HS   : Word;

    procedure ShowWindow;
    begin
      X := Random(80-W)+1;
      Y := Random(25-H)+1;

      BuildWindow(X, Y, X+W, Y+H, Copyright, $07);

      FastWrite(Msg, Y+H, X+((W-Length(Msg)) div 2), $07);
      FillChar(DT, SizeOf(DT), 0);
      with DT do GetTime(Hour, Min, Sec, HS);
      FastWrite(' '+TimeString(DT)+' ', Y+H, X+W-10, $07);

      FastWrite(' Faxes received this session: ' +
                Long2Str(FaxRecCount), Y+02, X+13, $07);
      FastWrite('     Faxes sent this session: ' +
                Long2Str(FaxSndCount), Y+03, X+13, $07);
      FastWrite('           Fax failure count: ' +                     {!!.01}
                Long2Str(FailedFaxCount), Y+04, X+13, $07);            {!!.01}
      FastWrite('   Fax send requests pending: ' +
                Long2Str(FaxQ.Count), Y+05, X+13, $07);
      if (FaxQ.Count > 0) and (FaxQ.Head <> nil) then begin
        UnpackTime(FaxQ.Head^.Scheduled, DT);
        FastWrite('         Schd: ' +
                  DateString(DT) + ' ' + TimeString(DT),
                  Y+06, X+13, $07);
      end else
        FastWrite('         Schd:                ', Y+06, X+13, $07);
    end;

  begin
    {Save and clear the screen}
    if (Action = ssSave) and not ScreenSaved then begin
      SSPtr := SaveScreen(1, 1, 80, 25);
      ClrScr;
      ScreenSaved := True;
      ShowWindow; {Display a status window}
      LastMoveTime := GetPackedTime;
    end;

    {Restore the screen and reset start time}
    if (Action = ssRestore) and ScreenSaved then begin
      NewTimerSecs(SSTimer, SSSaveTime);
      RestoreScreen(SSPtr, 1, 1, 80, 25);
      ScreenSaved := False;
      UpdateClockDisplay;
    end;

    if (Action = ssMove) then begin
      NewTimerSecs(SSTimer, SSSaveTime);
      T := GetPackedTime;
      if (T - LastMoveTime > SSMoveTime) or (T < LastMoveTime) then begin
        ClrScr;
        ShowWindow; {Display a status window}
        LastMoveTime := T;
      end;
    end;

  end;

  procedure RingWatcher; interrupt;
    {-Timer interrupt that beeps when the phone rings}
  const
    Busy    : Boolean = False;
    Counter : Byte = 0;
  begin
    asm
      pushf
      call   DWORD PTR RingSaveInt1C
      sti
    end;
    Inc(Counter);
    if (Counter > RingCheckTics) and (not Busy) then begin
      Busy := True;
      if Port^.CheckDeltaRI then
        Ring;
      Counter := 0;
      Busy := False;
    end;
  end;

  procedure NotifyAlarm; interrupt;
    {-Timer interrupt that beeps every "AlarmTics" clock tics}
  const
    Busy    : Boolean = False;
    Counter : Byte = 0;
  begin
    asm
      pushf
      call   DWORD PTR AlarmSaveInt1C
      sti
    end;
    Inc(Counter);
    if (Counter > AlarmTics) and (not Busy) then begin  {10 sec}
      Busy := True;
      Ring;
      Counter := 0;
      Busy := False;
    end;
  end;

  procedure EnableRingWatcher;
    {-Install the ring watcher isr}
  begin
    if RingIsrInstalled then
      Exit;

    {Call once to clear previous state}
    if Port^.CheckDeltaRI then {};

    {Save current timer vector}
    GetIntVec($1C, RingSaveInt1C);

    {Install ring watcher timer ISR}
    SetIntVec($1C, Addr(RingWatcher));
    RingIsrInstalled := True;
  end;

  procedure DisableRingWatcher;
    {-Remove the ring watcher isr}
  begin
    if not RingIsrInstalled then Exit;

    {Restore original timer vector}
    SetIntVec($1C, RingSaveInt1C);
    RingIsrInstalled := False;
  end;

  procedure EnableNotifyAlarm;
    {-Install the notify alray isr}
  begin
    if AlarmIsrInstalled then
      Exit;

    {Save current timer vector}
    GetIntVec($1C, AlarmSaveInt1C);

    {Install notify alram timer ISR}
    SetIntVec($1C, Addr(NotifyAlarm));
    AlarmIsrInstalled := True;
  end;

  procedure DisableNotifyAlarm;
    {-Remove the notify alarm isr}
  begin
    if not AlarmIsrInstalled then Exit;

    {Restore original timer vector}
    SetIntVec($1C, AlarmSaveInt1C);
    AlarmIsrInstalled := False;
  end;

  function AskYesNo(Msg : string) : Boolean;
    {-Prompt for a Y/N response and return true for "Y"}
  var
    Ch      : Char;
    Len     : Byte absolute Msg;
    P       : Pointer;
    T       : string[77];
  begin
    EnableRingWatcher;
    ShowCursor;
    AskYesNo := False;
    P := SaveScreen(1, 23, 80, 25);
    if P = nil then
      Exit;
    FillChar(T, SizeOf(T), ' ');
    Move(Msg[1], T[1], Len);
    T[0] := Char(77);
    FastWrite(T, 24, 3, DAttr);
    GotoXY(3+Len+1, 24);

    repeat
      Ch := UpCase(ReadKeyTimeOut(WaitTimeout, 'N'));
    until Ch in ['Y', 'N'];

    FastWrite(Ch, 24, 3+Len+1, DAttr);
    Delay(250);
    AskYesNo := Ch = 'Y';
    ClearKeyboardBuffer;
    RestoreScreen(P, 1, 23, 80, 25);
    HideCursor;
    DisableRingWatcher;
  end;

  function WaitForKeyPress(Y : Byte) : Boolean;
    {-Display wait message on line "Y" and wait for any key press}
  var
    Ch : Char;
  begin
    FastWrite(msgPressAnyKey, Y, 5, DAttr);
    Ch := ReadKeyTimeout(WaitTimeout, #0);
    ClearKeyboardBuffer;
    WaitForKeyPress := Ch <> #27;
  end;

  procedure RenameFaxFile(Path : PathStr; NewExtension : ExtStr);
    {-Renames the "just printed" fax file}
  var
    F    : file of Byte;
    Dir  : DirStr;
    Name : NameStr;
    Ext  : ExtStr;
    L    : LongInt;
  begin
    FSplit(Path, Dir, Name, Ext);
    {delete any existing file with this name}
    Assign(F, Dir + Name + '.' + NewExtension);
    Erase(F);
    if IoResult <> 0 then {};
    Assign(F, Path);
    Rename(F, Dir + Name + '.' + NewExtension);
    if IoResult <> 0 then {};

    {if this is a failed fax receive file -- erase it if file size is 0}
    if NewExtension = AbortedFaxExt then begin
      Reset(F);
      if IoResult = 0 then begin
        L := FileSize(F);
        if (IoResult = 0) and (L = 0) then begin
          Close(F);
          if IoResult <> 0 then {};
          Erase(F);
        end else
          Close(F);
        if IoResult <> 0 then {};
      end;
    end;
  end;

  procedure ShowSpinner(Kind : Byte; On : Boolean);
    {-Display on of two types of progress spinners}
  const
    X1 = 39; Y1 = 01;                    {Fax}
    X2 = 42; Y2 = 19;                    {Printing}
    S1Count          : Byte = 0;         {Progress counter}
    S2Count          : Byte = 0;         {Progress counter}
    Spinner1         : array[0..3] of Char =
                       ('.', 'o', 'O', 'o');
    Spinner2         : array[0..7] of Char =
                       ('/', '-', '\', '|', '/', '-', '\', '|');
  begin
    case Kind of
      1 : if On then begin
            FastWrite(Spinner1[S1Count], Y1, X1, DAttr);
            S1Count := (S1Count + 1) mod SizeOf(Spinner1);
          end else begin
            FastWrite('c', Y1, X1, FAttr); {restore copyright (c)}
            S1Count := 0;
          end;
      2 : if On then begin
            FastWrite(Spinner2[S2Count], Y2, X2, DAttr);
            S2Count := (S2Count + 1) mod SizeOf(Spinner2);
          end else begin
            FastWrite(' ', Y2, X2, WAttr);
            S2Count := 0;
          end;
    end;
  end;

  procedure SetStatusLine(Msg : string);
    {-Display text on the status line}
  const
    MaxMsgLen = 60;
  var
    Len       : Byte absolute Msg;
    S         : string[MaxMsgLen];
  begin
    S := Msg;
    FillChar(S[Len+1], MaxMsgLen-Len, ' ');
    S[0] := Char(MaxMsgLen);
    FastWrite(S, 24, 11, DAttr);
  end;

  function MyReadKey : Char;
    {-Process key presses and set command variable}
  var
    Ch : Char;
  begin
    Ch := ReadKeyTimeout(WaitTimeout, #0);
    Command := cmdNone;
    case UpCase(Ch) of
      #27 : if AskYesNo(msgAbortQuestion)
            then begin
              Command := cmdExit;
              if InitComplete then
                SetStatusLine('Shutting down...');
            end else Ch := #0;
      'D' : Command := cmdDeleteLog;
      'S' : Command := cmdShell;
      'P' : Command := cmdDeleteFaxes;
      'T' : Command := cmdTogglePrint;
      'V' : Command := cmdViewLog;
    else
      if (Ch = #0) and KeyPressed then begin
        Ch := ReadKey;
        if Ch = #68 then  {F10}
          Command := cmdCommandMode
      end;
    end;
    MyReadKey := Ch;
    ClearKeyboardBuffer;
  end;

  procedure HandleDiskError(Full : Boolean);
    {-Set global disk full flag and install/remove our ISR}
  begin
    {Ignore call if "full" status hasn't changed}
    if Full = IsDiskFull then
      Exit;
    if IsDiskFull and (not Full) then begin
      DisableNotifyAlarm;
      FastWrite(DividerBar, 6, 1, FAttr);
    end else if (not IsDiskFull) and Full then begin
      EnableNotifyAlarm;
      FastWrite(' ** DISK ERROR - ALL FAXES REFUSED ** ', 6, 19, DAttr);
    end;

    {Set global disk full flag}
    IsDiskFull := Full;
  end;

  procedure ShellOutAndListen;
    {-Installs a timer int and shells out to dos}
  var
    Screen  : Pointer;  {Saved screen pointer}
    HoldDir : PathStr;  {Saved current directory}                      {!!.01}
  begin
    {Clear the disk full flag assuming this shell will free up disk space}
    HandleDiskError(False);
    Screen := SaveScreen(1, 1, 80, 25);
    if Screen = nil then
      Exit;
    ClrScr;
    ShowCursor;
    GetDir(0, HoldDir);                                                {!!.01}
    EnableRingWatcher;
    if ShellToDos <> 0 then {};
    DisableRingWatcher;
    ChDir(HoldDir);                                                    {!!.01}
    if IoResult <> 0 then {};                                          {!!.01}
    HideCursor;
    RestoreScreen(Screen, 1, 1, 80, 25);
    NewTimerSecs(SSTimer, SSSaveTime);  {Reset screen timeout}
  end;

  function MyAbortFunc : Boolean; far;
    {-Set global command if key pressed and return true if aborting}
  var
    Ch : Char;
  begin
    MyAbortFunc := False;
    if KeyPressed then begin
      {Restore screen if saved}
      if ScreenSaved then begin
        HandleScreenSave(ssRestore);
        Ch := ReadKey;
      end else begin
        Ch := MyReadKey;
        MyAbortFunc := Ch = #27;
      end;
    end;
  end;

  function MyFaxName(AP : AbstractFaxPtr) : PathStr; far;
    {-Return the next sequential fax name}
  var
    I       : Word;
    SRec    : SearchRec;
    MS, DS  : string[2];
    FName1  : string[4];
    FName   : string;
    Y,M,D,O : Word;

    procedure MakeFileName(I : Word);
    var
      CountS : string[4];
      J      : Word;
    begin
      Str(I:4, CountS);
      for J := 1 to 4 do
        if CountS[J] = ' ' then
          CountS[J] := '0';
      FName := FName1 + CountS;
    end;

  begin
    {Get the date}
    GetDate(Y,M,D,O);
    Str(M:2, MS);
    Str(D:2, DS);
    FName1 := MS + DS;
    for I := 1 to 4 do
      if FName1[I] = ' ' then
        FName1[I] := '0';
    FillChar(SRec, SizeOf(SRec), #0);

    {Search until file does not exist or 999 checks}
    I := 0;
    repeat
      Inc(I);
      MakeFileName(I);
      FindFirst(FaxFilePath + FName + '.*', AnyFile, SRec);
    until (DosError <> 0) or (I = 999);

    if (I <= 999) and (DosError <> 0) then begin
      MyFaxName := FaxFilePath + FName + '.' + FaxFileExt;
    end else begin
      AsyncStatus := ecTooManyFiles;
      MyFaxName := 'NONAME.' + FaxFileExt;
    end;
  end;

  function MyAcceptFax(CP : AbstractFaxPtr;
                       RemoteName : Str20) : Boolean; far;
    {-Accept or reject fax based on value of "RemoteName"}
  begin
    {If disk full flag is set, reject incomming faxes}
    MyAcceptFax := not IsDiskFull;
  end;

  procedure UpdateStatusMsg;
    {-Translate the current AsyncStatus into a status message}
  const
    LastStatus : Word = 65535;
    MaxMsgLen = 60;
  var
    Msg : String[MaxMsgLen];
    Status : Word;
  begin
    Status := AsyncStatus;
    if (Status <> LastStatus) and (Status <> ecOk) then begin
      Msg := StatusStr(Status);
      SetStatusLine(Msg);
    end;
  end;

  procedure ClearByteAndPageCounts;
  begin
    {Clear displayed byte and page counts}
    FastWrite('      ', 15, 61, DAttr);
    FastWrite('0 ', 16, 54, DAttr);
    FastWrite('0 ', 16, 61, DAttr);
  end;

  procedure BuildStatusWindow;
    {-Draw the status window}
  begin
    BuildWindow(1, 1, 80, 25, Copyright, FAttr);
    FastWrite(' Press <Esc> to exit ', 25, 58, DAttr);

    FastWrite('      Station ID:', 03, 03, WAttr);
    FastWrite('   Fax file path:', 03, 43, WAttr);
    FastWrite(' Modem fax class:', 04, 03, WAttr);
    FastWrite('   Cmd file path:', 04, 43, WAttr);

    FastWrite(DividerBar,          06, 01, FAttr);

    FastWrite('   Faxes to send:', 08, 03, WAttr);
    FastWrite('      Faxes sent:', 08, 43, WAttr);
    FastWrite('       Next send:', 09, 03, WAttr);
    FastWrite('  Faxes received:', 09, 43, WAttr);
    FastWrite('  Faxes to print:', 10, 03, WAttr);
    FastWrite('          Errors:', 10, 43, WAttr);

    FastWrite(DividerBar,          12, 01, FAttr);


    FastWrite('Connection speed:', 14, 03, WAttr);
    FastWrite('   Fax file name:', 14, 43, WAttr);
    FastWrite('       Remote ID:', 15, 03, WAttr);
    FastWrite('Bytes transfered:', 15, 43, WAttr);
    FastWrite('Error Correction:', 16, 03, WAttr);
    FastWrite('     Page:    of:', 16, 43, WAttr);
    FastWrite(' High resolution:', 17, 03, WAttr);

    FastWrite(' Print file name:', 18, 43, WAttr);
    FastWrite('     Page:    of:', 19, 43, WAttr);

    FastWrite(DividerBar,          21, 01, FAttr);

    {Help area}
    FastWrite(HelpLine,            22, 03, DAttr);
    FastWrite(DividerBar,          23, 01, FAttr);

    {Status area}
    FastWrite('Status:',           24, 03, WAttr);

    ClearByteAndPageCounts;
  end;

  procedure DisplayHelpLine(Enabled : Boolean);
    {-Display text on the help line}
  begin
    if Enabled then
      {Show help line disabled}
      FastWrite(HelpLine, 22, 3, DAttr)
    else
      {Show help line enabled}
      FastWrite(HelpLine, 22, 3, WAttr);
  end;

  procedure ShowStaticSettings;
  const
    ClassStr : array[ClassType] of string[10] = (
               'Unknown', 'Detect', 'Class 1', 'Class 2', 'Class 2.0', 'CAS');
  var
    S        : PathStr;
  begin
    {Station id}
    FastWrite(StationIdStr,       03, 21, DAttr);  {Station ID}
    {Fax file path}
    S := FaxFilePath;
    if (S = '') or (S = '.') or (S = '.\') then
      GetDir(0, S);
    if Length(S) > 45 then  {Limit to 45 characters}
      S[0] := Char(45);
    FastWrite(S, 03, 61, DAttr);
    {Fax class}
    FastWrite(ClassStr[FaxClass], 04, 21, DAttr);  {Class used}
    {Command file path}
    S := CmdFilePath;
    if (S = '') or (S = '.') or (S = '.\') then
      GetDir(0, S);
    if Length(S) > 45 then  {Limit to 45 characters}
      S[0] := Char(45);
    FastWrite(S, 04, 61, DAttr);
  end;

  procedure ShowPrintStatus(FName : PathStr);
    {-Display current printing status}
  var
    S   : string[12];
  begin
    S := Pad(Long2Str(FaxPrnCount), 5);
    FastWrite(S, 10, 21, DAttr);

    if PrintSuspended then
      S := msgPaused
    else
      S := JustFilename(FName);
    if Length(S) = 0 then begin
      S := msgNothing;
      FastWrite('0 ', 19, 54, DAttr);
      FastWrite('0 ', 19, 61, DAttr)
    end;

    FastWrite(Pad(S, 12), 18, 61, DAttr)
  end;

  procedure HandleAsyncErrors(Error : Word);
    {-Respond to general errors}
  begin
    {Look for a possible disk full error and set our flag}
    if (Error = ecDiskFull) or (Error = ecDeviceWrite) then
      HandleDiskError(True);
  end;

  function OpenFaxLog : Boolean;
  begin
    OpenFaxLog := False;
    Assign(FLF, LogFileName);
    Append(FLF);
    if IOResult = 2 then
      ReWrite(FLF);
    if IOResult <> 0 then
      Exit;
    OpenFaxLog := True;
  end;

  procedure CloseFaxLog;
  begin
    Close(FLF);
    if IOResult <> 0 then ;
  end;

  procedure MakeLogEntry(S : String);
    {-Write S to the log file}
  begin
    if not OpenFaxLog then
      Exit;
    Write(FLF, TodayString, ' ', Time24String, ' ');
    WriteLn(FLF, frlNote, S);
    CloseFaxLog;
  end;

  procedure MyStatus(FP        : AbstractFaxPtr;
                     Starting,
                     Ending    : Boolean); far;
    {-Called by the fax engine to show status}
  const
    LastPrnCount : LongInt = 0;
  var
    S          : string[12];
    T          : string[29];
    Pages,
    PageNum    : Word;
    XferBytes,
    TotalBytes : LongInt;
    Progress   : Word;
  begin
    {Restore screen if saved}
    if ScreenSaved then
      HandleScreenSave(ssRestore);

    {Check current progress status}
    Progress := FP^.GetFaxProgress;
    case Progress of
      fpWaiting        : SetStatusLine(fpsWaiting);
      fpNoConnect      : SetStatusLine(fpsNoConnect);
      fpAnswer         : SetStatusLine(fpsAnswer);
      fpIncoming       : SetStatusLine(fpsIncoming);
      fpGetPage        :
        begin
          SetStatusLine(fpsGetPage);
          with C12ReceiveFaxPtr(FP)^ do begin
            GetPageInfo(Pages, PageNum, XferBytes, TotalBytes);
            T := Pad(Long2Str(XferBytes), 6);
            FastWrite(T, 15, 61, DAttr);
            T := Pad(Long2Str(PageNum), 2);
            FastWrite(T, 16, 54, DAttr);
            {clear the "of:" section}
            FastWrite('??', 16, 61, DAttr);
            {Get and display the fax file name}
            FaxFileName := JustFileName(GetFaxName);
            if FaxFileName = '' then
              FaxFileName := msgCoverSheet;
            T := Pad(FaxFilename, 12);
            FastWrite(T, 14, 61, DAttr);
          end;
        end;
      fpGetPageResult  : SetStatusLine(fpsGetPageResult);
      fpCheckMorePages : SetStatusLine(fpsCheckMorePages);
      fpGetHangup      : SetStatusLine(fpsGetHangup);
      fpGotHangup      : SetStatusLine(fpsGotHangup);
      fpSessionParams  :
        begin
          SetStatusLine(fpsSessionParams);
          C12ReceiveFaxPtr(FP)^.GetSessionParams(BPS, Resolution, Correction);
          T := Pad(Long2Str(BPS), 6);
          FastWrite(T,                      14, 21, DAttr);
          AcceptedBPSRate := BPS;
          FastWrite(OnOffStr[Correction],   16, 21, DAttr);
          FastWrite(OnOffStr[Resolution],   17, 21, DAttr);
        end;
      fpGotRemoteId    :
        begin
          SetStatusLine(fpsGotRemoteId);
          RemoteId := C12ReceiveFaxPtr(FP)^.GetRemoteID;
          T := RemoteId;
          T := Pad(T, 20);
          FastWrite(T, 15, 21, DAttr);
        end;
      fpInitModem      : SetStatusLine(fpsInitModem);
      fpDialing        :
        begin
          SetStatusLine(fpsDialing+' '+FP^.PhoneNum);
          {Get and display the fax file name}
          FaxFilename := JustFileName(FP^.GetFaxName);
          if FaxFilename = '' then
            FaxFilename := msgCoverSheet;
          T := Pad(FaxFilename, 12);
          FastWrite(T, 14, 61, DAttr);
        end;
      fpBusyWait       : SetStatusLine(fpsBusyWait);
      fpSendPage       :
        begin
          SetStatusLine(fpsSendPage);
          with C12SendFaxPtr(FP)^ do begin
            GetPageInfo(Pages, PageNum, XferBytes, TotalBytes);
            T := Pad(Long2Str(XferBytes), 6);
            FastWrite(T, 15, 61, DAttr);
            T := Pad(Long2Str(PageNum), 2);
            FastWrite(T, 16, 54, DAttr);
            T := Pad(Long2Str(Pages), 2);
            FastWrite(T, 16, 61, DAttr);
          end;
        end;
      fpSendPageStatus : SetStatusLine(fpsSendPageStatus);
      fpPageError      : SetStatusLine(fpsPageError);
      fpPageOK         : SetStatusLine(fpsPageOk);
    end;

    if AsyncStatus div 10000 = epFatal then
      HandleAsyncErrors(AsyncStatus mod 10000);

    if Starting then begin
      Ring;  {Sound alarm}

      {Clear fax file name}
      FaxFilename := '';

      ClearByteAndPageCounts;

      {Clear remote ID field}
      T := Pad(' ', 20);
      FastWrite(T, 15, 21, DAttr);

      {Set sending and receiving flags}
      Receiving := not FP^.Sending;
      Sending := FP^.Sending;

      {Show help line disabled}
      DisplayHelpLine((not Receiving) and (not Printing) and (not Sending));

      ShowSpinner(FaxSpinner, True);
      {clear hangup result}
      HangupResult := 0;
    end else if Ending then begin
      S := Pad(Long2Str(FaxSndCount), 5);
      FastWrite(S, 08, 61, DAttr);
      S := Pad(Long2Str(FaxRecCount), 5);
      FastWrite(S, 09, 61, DAttr);
      FastWrite(Long2Str(FailedFaxCount), 10, 61, DAttr);

      Receiving := False;
      Sending := False;

      NewTimerSecs(SSTimer, SSSaveTime);  {Reset screen timeout}

      {Show help line enabled if not printing}
      DisplayHelpLine((not Receiving) and (not Printing) and (not Sending));

      ClearByteAndPageCounts;

      SetStatusLine(fpsWaiting);
      ShowSpinner(FaxSpinner, False);  {Erase fax spinner}

      if (AcceptedBPSRate > 0) and (AsyncStatus = ecOk) then
        MakeLogEntry('Negotiated connect speed: ' + Long2Str(AcceptedBPSRate));

      {record last hangup result}
      HangupResult := C12AbstractFaxPtr(FP)^.GetHangupResult;
    end else begin
      {If the fax print count changed - update status and reset last printed}
      if FaxPrnCount <> LastPrnCount then begin
        ShowPrintStatus(FileToPrint);
        LastPrnCount := FaxPrnCount;
      end;
      ShowSpinner(FaxSpinner, True);
    end;
    UpdateStatusMsg;
  end;

  function OkToPrintFailedFax(Path : string) : Boolean;
  var
    F : file of Byte;
    L : LongInt;
  begin
    OkToPrintFailedFax := False;
    Assign(F, Path);
    Reset(F);
    if IoResult <> 0 then Exit;
    L := FileSize(F);
    OkToPrintFailedFax := (IoResult = 0) and (L > MinFaxPrnSize);
    Close(F);
    if IoResult <> 0 then {};
  end;

  procedure MyFaxLog(CP     : AbstractFaxPtr;
                     Number : string;
                     FName  : PathStr;
                     Log    : TLogFaxCode); far;
    {-Called by the fax engine to log fax activity}
  begin
    if not OpenFaxLog then
      Exit;

    {Restore screen if saved}
    if ScreenSaved then
      HandleScreenSave(ssRestore);

    with CP^ do begin
      Write(FLF, TodayString, ' ', Time24String, ' ');
      case Log of
        lfaxReceiveStart :
            WriteLn(FLF,   frlStart, FName, '  Remote ID: ', Number);
        lfaxReceiveOk :
          begin
            WriteLn(FLF, frlEnd, FName);
            Inc(FaxRecCount);
            Inc(FaxPrnCount);
          end;
        lfaxReceiveFail :
          begin
            WriteLn(FLF, frlRecFail, '(', StatusStr(AsyncStatus), '): ', FName);
            if not OkToPrintFailedFax(FaxFilePath + FName) then
              RenameFaxFile(FaxFilePath + FName, AbortedFaxExt)
            else
              Inc(FaxPrnCount);
            Inc(FailedFaxCount);                                       {!!.01}
          end;
        lfaxReceiveSkip :
          WriteLn(FLF, frlSkip, '(', StatusStr(AsyncStatus), '): ', FName);
        lfaxTransmitStart :
            WriteLn(FLF, frlTransStart, CommandFileName, '  to ', Number);
        lfaxTransmitOk :
          begin
            Inc(FaxSndCount);
            WriteLn(FLF, frlTransOk, CommandFileName);
          end;
        lfaxTransmitFail :
          begin
            case AsyncStatus of
              ecNoDialTone, ecFaxBusy :
                WriteLn(FLF, frlBusyNoDial, '(', StatusStr(AsyncStatus), '): ',
                             CommandFileName);
            else
              WriteLn(FLF, frlTransFail, '(', StatusStr(AsyncStatus), '): ',
                           CommandFileName);
              Inc(FailedFaxCount);
              {$IFDEF Tracing}
              DumpTraceHex(ForceExtension(CommandFileName, 'TRC'));
              InitTracing(10000);
              {$ENDIF}
            end;
            FaxSendError := True;
          end;
        else
          WriteLn(FLF, frlUnk, '(', StatusStr(AsyncStatus), '): ', CommandFileName);
      end;
    end;

    CloseFaxLog;
  end;

  procedure LogFaxPrinting(FName  : PathStr);
    {-Write fax print information to the fax log}
  begin
    if not OpenFaxLog then
      Exit;

    Write(FLF, TodayString, ' ', Time24String, ' ');
    if AsyncStatus = ecOk then
      WriteLn(FLF, frlPrint, FName)
    else
      WriteLn(FLF, frlPFail, '(', StatusStr(AsyncStatus), '): ', FName);

    CloseFaxLog;
  end;

  procedure LogOnLine(On : Boolean);
    {-Write On\Off Line entry to the fax log}
  begin
    if not OpenFaxLog then
      Exit;

    if On then
      WriteLn(FLF, TodayString, ' ', Time24String,' ', frlOnLine)
    else
      WriteLn(FLF, TodayString, ' ', Time24String,' ', frlOffLine);

    CloseFaxLog;
  end;

  procedure LogSuspendResumePrint(Suspended : Boolean);
    {-Write suspend/resume entry to the fax log}
  begin
    {Create entry for print suspend/resume}
    if not OpenFaxLog then
      Exit;
    Write(FLF, TodayString, ' ', Time24String, ' ');
    if Suspended then
      WriteLn(FLF, frlPPaused)
    else
      WriteLn(FLF, frlPResumed);
    CloseFaxLog;
  end;

  procedure CommandWindow;
    {-Display a command window and accept commands}
  const
    X1 = 20; Y1 = 05;
    X2 = 60; Y2 = 20;
  var
    P  : Pointer;
    Ch : Char;
    T  : string[20];
  begin
    EnableRingWatcher;
    {Save underlying screen area}
    P := SaveScreen(X1, Y1, X2, Y2);

    {Build the command window}
    BuildWindow(X1, Y1, X2, Y2, ' Available Commands ', FAttr);
    FastWrite('<A> View fax log',                    Y1+02, X1+02, DAttr);
    FastWrite('<B> Print fax log',                   Y1+03, X1+02, DAttr);
    FastWrite('<C> Delete fax log',                  Y1+04, X1+02, DAttr);
    FastWrite('<D> Delete printed fax files',        Y1+05, X1+02, DAttr);
    FastWrite('<E> Delete failed fax files',         Y1+06, X1+02, DAttr);
    FastWrite('<F> Reset session fax counts',        Y1+07, X1+02, DAttr);
    FastWrite('<H> Turn fax printing ' +
      OnOffStr[PrintSuspended],                      Y1+08, X1+02, DAttr);
    FastWrite('<I> Turn blank line suppression ' +
      OnOffStr[not SuppressBlanks],                  Y1+09, X1+02, DAttr);
    FastWrite('<J> Shell to DOS',                    Y1+10, X1+02, DAttr);

    FastWrite('<X> Exit',                            Y1+12, X1+02, DAttr);

    FastWrite('Enter choice: ',                      Y2-01, X1+02, DAttr);
    ShowCursor;
    GotoXY(X1+16, Y2-01);

    Ch := UpCase(ReadKeyTimeout(WaitTimeout, #0));

    if Ch In ['A'..'X'] then begin
      FastWrite(Ch, Y2-01, X1+16, DAttr);
      Delay(250);
    end;
    HideCursor;
    ClearKeyboardBuffer;

    {Restore covered screen area}
    RestoreScreen(P, X1, Y1, X2, Y2);

    case Ch of
      'A' : Command := cmdViewLog;
      'B' : Command := cmdPrintLog;
      'C' : Command := cmdDeleteLog;
      'D' : Command := cmdDeleteFaxes;
      'E' : Command := cmdDeleteFailed;
      'F' : Command := cmdResetSessionCounts;
      'H' : Command := cmdTogglePrint;
      'I' : Command := cmdToggleBlank;
      'J' : Command := cmdShell;
      'X' : Command := cmdExit;
    else
      Command := cmdNone;
    end;

    DisableRingWatcher;
  end;

  procedure ResetForReceive;
  var
    Try : Integer;
    Ok  : Boolean;
  begin
    Try := 0;
    Fax^.SetFaxAndData(True);
    repeat
      Inc(Try);
      Ok := Fax^.InitModemForFaxReceive;
      if not Ok then Ring;
    until Ok or KeyPressed or (Try > MaxInitRetries);
    if not Ok then
      SetStatusLine(msgFailedToReset + StatusStr(AsyncStatus));

    {Get fax engine ready to continue}
    Fax^.PrepareFaxReceivePart;
  end;

  procedure CallFaxEngine;
    {-Calls the fax engine until its not in a critical state}
  begin
    repeat
      FaxState := Fax^.FaxReceivePart;
    until FaxState <> faxCritical;  {Don't yield if critical}

    {In cases where a receive error occured the fax engine has finished}
    {so, we may need to clean up and reset the fax engine.}
    if (FaxState = faxFinished) and (Command <> cmdExit) then begin

      {Rename the fax file so it doesn't get printed}
      if FaxFilename <> '' then
        if not OkToPrintFailedFax(FaxFilePath + FaxFilename) then
          RenameFaxFile(FaxFilePath + FaxFilename, AbortedFaxExt)
        else
          Inc(FaxPrnCount);

      {Try to reset modem after receive failure}
      ResetForReceive;
    end;
  end;

  function MyPageNotifyFunc(Page, Pages: Word) : Boolean; far;
    {-Called for each page sent to the fax printer}
  var
    S : string[5];
  begin
    MyPageNotifyFunc := False;  {Don't abort}
    S := Pad(Long2Str(Page), 2);
    FastWrite(S, 19, 54, DAttr);
    if (Pages > 0) and (Pages >= Page) then begin
      S := Pad(Long2Str(Pages), 2);
      FastWrite(S, 19, 61, DAttr)
    end else
      FastWrite('??', 19, 61, DAttr)
  end;

  function MyLineNotifyFunc(Lines, LineSize : Word) : Boolean; far;
    {-Called for each raster line sent to the fax printer}
  begin
    MyLineNotifyFunc := False;  {Don't abort}
    ShowSpinner(PrintSpinner, True);
  end;

  function MyWriteNotifyFunc(BytesWritten : Word) : Boolean; far;
    {-Called for each write of data to the print device}
  begin
    MyWriteNotifyFunc := False;  {Don't abort}
    CallFaxEngine;
  end;

  procedure AbortMsg(S : string);
    {-Writes an error message and then halts}
  begin
    ClrScr;
    WriteLn('Error: ', S);
    Halt(1);
  end;

  procedure ReadIniFile;
  var
    Ini : PIni;
    S   : string;
  begin
    Ini := nil;
    Ini := new(PIni, Init(ProgramName, True));
    if Ini = nil then
      AbortMsg('Out of memory.');

    with Ini^ do begin
      case GetProfileInt('Port', '[Port]', 2) of
        1 : ComPort := Com1;
        2 : ComPort := Com2;
        3 : ComPort := Com3;
        4 : ComPort := Com4;
      else
        ComPort := Com1;
      end;

      PortSpeed      := GetProfileLong('PortSpeed', '[Port]', PortSpeed);
      CommandBaud    := GetProfileLong('CommandBaud', '[Modem]', CommandBaud);
      ModemInitStr   := GetProfileString('InitStr', '[Modem]', ModemInitStr);
      FaxBaudRate    := GetProfileLong('BaudRate', '[Fax]', FaxBaudRate);
      FaxFilePath    := StUpCase(AddBackSlash(GetProfileString('FaxPath', '[Fax]', FaxFilePath)));
      if FaxFilePath = '.\' then FaxFilePath := '';
      StationIdStr   := StUpCase(GetProfileString('StationID', '[Fax]', StationIdStr));
      CmdFilePath    := StUpCase(AddBackSlash(GetProfileString('CmdFilePath', '[Fax]', CmdFilePath)));
      if CmdFilePath = '.\' then CmdFilePath := '';
      RetryWaitTime  := GetProfileInt('RetyrWaitTime', '[Fax]', RetryWaitTime);
      MaxFaxRetries  := GetProfileInt('MaxFaxRetries', '[Fax]', MaxFaxRetries);
      EraseCmdFiles  := GetProfileBool('EraseCmdFiles', '[Fax]', EraseCmdFiles);
      PrintDest      := StUpCase(GetProfileString('PrintDest', '[Printing]', PrintDest));
      PrintSuspended := GetProfileBool('PrintSuspended', '[Printing]', PrintSuspended);
      SuppressBlanks := GetProfileBool('SuppressBlanks', '[Printing]', SuppressBlanks);
      BlankSize      := GetProfileInt('BlankSize', '[Printing]', BlankSize);
      UseScaling     := GetProfileBool('ScaleOutput', '[Printing]', UseScaling);
      UsePcl5Mode    := GetProfileBool('Pcl5Commands', '[Printing]', UsePcl5Mode);
      S := StUpCase(GetProfileString('Printer', '[Printing]', 'HP150'));
      if S = 'HP300' then
        UseHP300 := True
      else if S = 'EPSON' then
        UseEpson := True
      else if S = 'EPSON24' then
        UseEpson24 := True;
      Hangup4Retry   := GetProfileBool('Hangup4Retry', '[Fax]', Hangup4Retry);
    end;
    if PrintSuspended then
      LogSuspendResumePrint(True);

    dispose(Ini, Done);
  end;

  procedure ShowHelp(ErrMsg : string);
    {-Display command line syntax}
  begin
    WriteLn('Syntax:  ', ProgramName, ' [ComPort]');
    WriteLn;
    WriteLn('  ComPort       Set comm port to "ComPort" (1-4)');
  end;

  procedure ParseCommandLine;
  var
    Param   : string;
  begin
    if Paramcount > 0 then begin
      Param := ParamStr(1);
      case Param[1] of
        '1' : ComPort := Com1;
        '2' : ComPort := Com2;
        '3' : ComPort := Com3;
        '4' : ComPort := Com4;
      else
        ShowHelp('Invalid comm port: ' + Param);
      end;
    end;
  end;

  procedure Initialize;
    {-General initialization}
  begin
    {Create out printer object}
    Printer := nil;
    if UseEpson then
      New(EpsonPrinterPtr(Printer), Init)
    else if UseEpson24 then
      New(Epson24PinPrinterPtr(Printer), Init)
    else if UseHP300 then begin                                        {!!.01}
      BLSSize := BlankSize;                                            {!!.01}
      New(HP300PrinterPtr(Printer), Init);                             {!!.01}
    end else begin                                                     {!!.01}
      BLSSize := BlankSize;                                            {!!.01}
      New(HP150PrinterPtr(Printer), Init);                             {!!.01}
    end;                                                               {!!.01}
    if Printer = nil then
      AbortMsg(msgPrintInitFailed);

    FaxPrinter := nil;
    New(FaxPrinter, Init(Printer));
    if FaxPrinter = nil then
      AbortMsg(msgPrintInitFailed);

    {Set print hooks}
    FaxPrinter^.SetPageNotifyFunc(MyPageNotifyFunc);
    FaxPrinter^.SetLineNotifyFunc(MyLineNotifyFunc);
  {$IFDEF ReceiveDuringPrint}
    FaxPrinter^.SetWriteNotifyFunc(MyWriteNotifyFunc);
  {$ENDIF}

    {Set options}
    if not(UseEpson or UseEpson24) then
      FaxPrinter^.SetPcl5Mode(UsePcl5Mode);
    FaxPrinter^.SetScaling(UseScaling);
    {Always use header}
    FaxPrinter^.SetHeader(True);
    FaxPrinter^.SetBlankLineSuppression(SuppressBlanks);

    if VideoMode = 7 then begin
      TextMode(BW80);
      {Change color attributes to mono}
      WAttr   := $07;    {Window attribute}
      FAttr   := $07;    {Frame attribute}
      DAttr   := $0F;    {Data attribute}
    end else
      TextMode(CO80);

    {Misc inits}
    Command := cmdNone;
    FaxPrnCount := 0;
    FaxRecCount := 0;
    FaxSndCount := 0;
    FailedFaxCount := 0;                                               {!!.01}
    FileToPrint := '';
    PrintAttempt := 0;

    {Init screen saver start time and saved flag}
    NewTimerSecs(SSTimer, SSSaveTime);
    ScreenSaved := False;

    {$IFDEF Tracing}
    InitTracing(10000);
    {$ENDIF}
    HideCursor;

    InitCmdFileList(FaxQ);
  end;

  function InitializePort : Boolean;
    {-Initializes the port}
  begin
    InitializePort := False;
    SetStatusLine('Initializing port...');
    Port := nil;
    New(Port, InitCustom(ComPort, PortSpeed, NoParity, 8, 1,
                         8192, 8192, DefPortOptions));
    if Port = nil then begin
      SetStatusLine('Failed to initialize com port');
      Exit;
    end;

    {Install the user abort function}
    Port^.SetAbortFunc(MyAbortFunc);
    InitializePort := True;
  end;

  function InitializeFax : Boolean;
    {-Initializes the modem for fax receive and sets fax hooks}
  var
    Try : Integer;
    Ok  : Boolean;
  begin
    InitializeFax := False;
    SetStatusLine('Initializing fax settings...');
    Fax := nil;
    New(Fax, Init(StationIdStr, Port));
    if Fax = nil then begin
      SetStatusLine('Failed to Initialize fax settings');
      Exit;
    end;

    with Fax^ do begin
      SetFaxNameFunc(MyFaxName);         {set fax name function}
      SetFaxStatusProc(MyStatus);        {set status procedure}
      SetFaxLogProc(MyFaxLog);           {set fax logging procedure}
      SetAcceptFaxFunc(MyAcceptFax);     {set fax accept function}
      if FaxFilePath <> '' then
        SetDestinationDir(FaxFilePath);  {set destination fax file path}

      SetModemInit(ModemInitStr);
      SetAnswerOnRing(RingToAnswerOn);
      SetModemFeatures(FaxBaudRate, '0');

      if CommandBaud <> 0 then                                         {!!.01}
        SetInitBaudRate(CommandBaud, 0);                               {!!.01}

      SetStatusLine('Retrieving modem information...');

      {Some modems get stuck -- this seems to wake them up}
      Try := 0;
      repeat
        Inc(Try);
        Ok := GetModemInfo(HighClass, Model, Chip, Rev, True);
      until Ok or (Try > MaxInitRetries) or (Command = cmdExit);

      if Ok then begin
        if HighClass <> '2' then
          FaxClass := ctClass1;  {Force to class 1}
      end else begin
        SetStatusLine('Unable to identify modem');
        Exit;
      end;

      {Set desired class}
      FaxClass := SetClassType(FaxClass);
      if not (FaxClass in [ctClass1, ctClass2, ctCAS]) then begin
        SetStatusLine('Failed to set fax class');
        Exit;
      end;
    end;

    Fax^.SetFaxAndData(True);
    SetStatusLine('Initializing modem for fax receive...');
    if not Fax^.InitModemForFaxReceive then begin
      SetStatusLine('Failed to prepare modem, Status: ' +
                StatusStr(AsyncStatus));
      Exit;
    end;

    {Get fax engine ready}
    Fax^.PrepareFaxReceivePart;
    InitializeFax := True;
  end;

  function CountFaxesToPrint(Dir : string) : Longint;
    {-Returns the number of fax files in the fax directory}
  var
    SRec : SearchRec;
    Cnt  : LongInt;
  begin
    CountFaxesToPrint := 0;
    Cnt := 0;
    FillChar(SRec, SizeOf(SRec), #0);
    FindFirst(AddBackSlash(Dir) + '*.' + FaxFileExt , AnyFile, SRec);
    while DosError = 0 do begin
      Inc(Cnt);
      FindNext(SRec);
    end;
    CountFaxesToPrint := Cnt;
  end;

  function GetFileToPrint : string;
    {-Returns the name of the oldest fax file in the fax directory}
  var
    SRec : SearchRec;
    TRec : SearchRec;
  begin
    GetFileToPrint := '';
    FillChar(SRec, SizeOf(SRec), #0);
    FindFirst(FaxFilePath + '*.' + FaxFileExt , AnyFile, SRec);
    if DosError <> 0 then  {If no match, exit}
      Exit;
    TRec := SRec;
    {Find oldest one}
    while DosError = 0 do begin
      FindNext(SRec);
      if (DosError = 0) and (SRec.Time < TRec.Time) then
        TRec := SRec;
    end;
    GetFileToPrint := FaxFilePath + TRec.Name;
  end;

  procedure DeleteFile(Path : PathStr; LogIt : Boolean);
  var
    F : file;
  begin
    Assign(F, Path);
    Erase(F);
    if IoResult <> 0 then {};
    if LogIt then
      MakeLogEntry('Deleted: '+Path);
  end;

  procedure PurgePrintedFaxes;
    {-Deletes all printed fax files in the fax file directory}
  var
    SRec : SearchRec;
  begin
    if AskYesNo('Delete all printed fax files (Y/N)?') then begin
      FillChar(SRec, SizeOf(SRec), #0);
      FindFirst(FaxFilePath + '*.' + PrintedFaxExt , AnyFile, SRec);
      while DosError = 0 do begin
        DeleteFile(FaxFilePath + SRec.Name, False);
        FindNext(SRec);
      end;
    end;
  end;

  procedure PurgeFailedFaxes;
    {-Deletes all failed received fax files in the fax file directory}
  var
    F    : file;
    SRec : SearchRec;
  begin
    if AskYesNo('Delete "Receive Failed" fax files (Y/N)?') then begin
      FillChar(SRec, SizeOf(SRec), #0);
      FindFirst(FaxFilePath + '*.' + AbortedFaxExt , AnyFile, SRec);
      while DosError = 0 do begin
        DeleteFile(FaxFilePath + SRec.Name, False);
        FindNext(SRec);
      end;
    end;
  end;

  function MyReadKeyTimeout : Char; far;
  begin
    {if no input after five minutes, return an escape character}
    MyReadKeyTimeout := ReadKeyTimeout(5*60, #27);
  end;

  procedure MyBrowseStatus(TopLine, TopOfs, LastOfs : LongInt;
                           LeftOfs : Word; var StatusData); far;
  var
    S, T : String;
    Y, W : Byte;
  begin
    Y := ScreenHeight-1;
    W := ScreenWidth-2;
    FillChar(S[1], W, ' ');
    S[0] := Char(W);
    T := 'Line :           Column:';
    Move(T[1], S[2], Length(T));
    Str(TopLine, T);
    Move(T[1], S[9], Length(T));
    Str(LeftOfs, T);
    Move(T[1], S[27], Length(T));
    FastWrite(S, Y, 2, SAttr);
  end;

  procedure ViewFaxLog;
    {-Displays the fax log file}
  const
    X1 = 01; Y1 = 01;
    X2 = 80; Y2 = 25;
  var
    P       : Pointer;
    Status  : Word;
    TopLine : LongInt;
    LeftOfs : Word;
    ExitKey : Char;
    Dummy   : Word;
  begin
    EnableRingWatcher;
    P := SaveScreen(X1, Y1, X2, Y2);
    if P = nil then Exit;
    TopLine := -1; {start at bottom of file}
    LeftOfs := 0;
    BuildWindow(1, 1, 80, 25, Copyright, FAttr);
    FastWrite(' Press <Esc> to exit ', 25, 58, DAttr);
    Status := BrowseFile(X1+1, Y1+1, X2-1, Y2-2, DAttr,
              TopLine, LeftOfs, LogFileName, MyReadKeyTimeout,
              [#27], ExitKey, MyBrowseStatus, Dummy);
    RestoreScreen(P, X1, Y1, X2, Y2);
    DisableRingWatcher;
  end;

  function PrintFaxLog : Boolean;
    {-Print the fax log file}
  var
    F, P    : Text;
    Ok      : Boolean;
    S       : string;
  begin
    PrintFaxLog := False;
    Assign(F, LogFileName);
    Reset(F);
    if IoResult = 0 then begin
      Assign(P, PrintDest);
      ReWrite(P);
      if IoResult = 0 then begin
        WriteLn(P, 'Fax Log  -  Printed: ', TodayString, ' ', Time24String);
        WriteLn(P);
        while not Eof(F) do begin
          ReadLn(F, S);
          WriteLn(P, S);
        end;
        Write(P, ^L);
        Close(P);
        if IoResult <> 0 then {};
        PrintFaxLog := True;
      end;
      Close(F);
      if IoResult <> 0 then {};
    end;
  end;

  procedure DeleteFaxLog;
    {-Deletes the fax log file}
  var
    Ok      : Boolean;
  begin
    if AskYesNo('Delete the fax log file (Y/N)?') then begin
      Ok := True;
      if AskYesNo('Print the log file before deleting (Y/N)?') then
        if not PrintFaxLog then
          Ok := AskYesNo('Log print failed. Continue with deletion (Y/N)?');
      if Ok then
        DeleteFile(LogFileName, False);
    end;
  end;

  procedure MyExitProc; far;
  begin
    ExitProc := SaveExitProc;

    {Remove ISR's if installed}
    if RingIsrInstalled then
      DisableRingWatcher;
    if AlarmIsrInstalled then
      DisableNotifyAlarm;

    {$IFDEF Tracing}
    DumpTraceHex(TraceFilename);
    {$ENDIF}

    {Restore screen if saved}
    if ScreenSaved then
      HandleScreenSave(ssRestore);

    {reset irq priorities}
    RotateIrqPriority(0);

    ShowCursor;
  end;

  procedure ReadCommandFile(Filename : PathStr; var Node : CmdFileNode);
    {-Read contents of command file and fill record structure}
  var
    Ini  : PIni;
    Code : Integer;
    D    : DateTime;
    S    : string;
    I    : Integer;
    Tag  : string[10];
  begin
    Ini := nil;
    Ini := new(PIni, Init(Filename, True));
    if Ini = nil then
      Exit;

    with Ini^, Node do begin
      for I := 1 to MaxFilesToSend do begin
        Str(I, Tag);
        Tag := 'File' + Tag;
        FileName[I] := StUpCase(Trim(GetProfileString(Tag, '[FaxSend]', '')));
        if FileName[I] <> '' then
          if FileName[I][1] = DeleteFlagChar then begin
            System.Delete(FileName[I], 1, 1);
            DeleteFlag[I] := True;
          end;
      end;
      SenderID := GetProfileString('SenderID', '[FaxSend]', StationIDStr);
      CoverPage := StUpCase(GetProfileString('CoverPage', '[FaxSend]', ''));
      Sender := GetProfileString('Sender', '[FaxSend]', '');
      Recipient := GetProfileString('Recipient', '[FaxSend]', '');
      UseHeaderLine := GetProfileBool('UseHeaderLine', '[FaxSend]', False);
      HeaderText := GetProfileString('HeaderText', '[FaxSend]', '');
      SendBaudRate := GetProfileLong('SendBaudRate', '[FaxSend]', FaxBaudRate);
      Phone := GetProfileString('Phone', '[FaxSend]', '');
      {pack date and time}
      FillChar(D, SizeOf(D), #0);
      Code := 0;
      S := GetProfileString('Date', '[FaxSend]', '10/13/87');
      if Length(S) = 8 then begin
        if Code = 0 then
          Val(Copy(S, 1, 2), D.Month, Code);
        if Code = 0 then
          Val(Copy(S, 4, 2), D.Day, Code);
        if Code = 0 then begin
          Val(Copy(S, 7, 4), D.Year, Code);
          if D.Year < 1900 then
            D.Year := D.Year + 1900;
        end;
      end else
        Code := 1;
      S := GetProfileString('Time', '[FaxSend]', '00:01');
      if Length(S) = 5 then begin
        if Code = 0 then
          Val(Copy(S, 1, 2), D.Hour, Code);
        if Code = 0 then
          Val(Copy(S, 4, 2), D.Min, Code);
      end else
        Code := 1;

      if Code <> 0 then
        FillChar(D, SizeOf(D), #0);
      PackTime(D, Scheduled);
    end;
    dispose(Ini, Done);
  end;

  procedure DisplayCmdFileCount;
  var
    S    : string[10];
    DT   : DateTime;
  begin
    if ScreenSaved then Exit;
    {display number of command files in queue}
    S := Pad(Long2Str(FaxQ.Count), 5);
    FastWrite(S, 08, 21, DAttr);

    if (FaxQ.Count > 0) and (FaxQ.Head <> nil) then begin
      UnpackTime(FaxQ.Head^.Scheduled, DT);
      FastWrite(DateString(DT) + ' ' + TimeString(DT), 09, 21, DAttr);
    end else
      FastWrite('                ', 09, 21, DAttr);
  end;

  procedure ScanCommandFiles;
  var
    SRec : SearchRec;
    Node : CmdFileNode;
    NP   : CmdFileNodePtr;
    HS   : Word;
    F    : File;
  begin
    UpdateClockDisplay;
    FillChar(SRec, SizeOf(SRec), #0);
    FindFirst(CmdFilePath + '*.' + CmdFileExt , AnyFile, SRec);
    while DosError = 0 do begin
      {see if we can open the file in case its currently being modified}
      Assign(F, CmdFilePath + SRec.Name);
      Reset(F);
      if IOResult = 0 then begin
        Close(F);
        NP := FindCmdFileNode(FaxQ, SRec.Name);
        {if we didn't find a match or if we found a}
        {match and the command file has been changed}
        if (NP = nil) or (NP^.CmdFileTime <> SRec.Time) then begin
          if NP <> nil then
            DeleteCmdFileNode(FaxQ, NP);
          FillChar(Node, SizeOf(Node), #0);
          Node.CmdFilename := CmdFilePath + SRec.Name;
          Node.CmdFileTime := SRec.Time;
          ReadCommandFile(CmdFilePath + SRec.Name, Node);
          if not AddCmdFileNode(FaxQ, Node) then {};
        end;
      end;
      FindNext(SRec);
    end;
    {reset time for next scan}
    NewTimerSecs(ScanTimer, CmdFileScanDelay);

    DisplayCmdFileCount;
  end;

  procedure RenameCommandFile(CF : PathStr);
    {-Renames the fax command file}
  var
    F : file;
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
  begin
    FSplit(CF, Dir, Name, Ext);
    {erase any existing file with this new name first}
    Assign(F, Dir + Name + '.' + CWCmdFileExt);
    Erase(F);
    if IoResult <> 0 then {};
    Assign(F, CF);
    Rename(F, Dir + Name + '.' + CWCmdFileExt);
    if IoResult <> 0 then {};
  end;

  procedure DeleteCommandFile(CF : PathStr);
  begin
    if EraseCmdFiles then
      DeleteFile(CF, False)
    else
      RenameCommandFile(CF);
  end;

  procedure AppendFax(DestFName : PathStr; FName : PathStr; PageBreak : Boolean);
  const
    ReadBufferSize = 4096;
  var
    BytesInEOP     : Word;
    OnPage         : Word;
    InBytes        : Word;
    LastPageOfs    : LongInt;
    ReadBuf        : PByteBuffer;
    DestHeader     : FaxHeaderRec;
    FaxHeader      : FaxHeaderRec;
    DestPageHeader : PageHeaderRec;
    PageHeader     : PageHeaderRec;
    DestFile       : File;
    AppendFile     : File;

  label
    Error;

    function UpdatePageHeader(Ofs : LongInt) : Boolean;
    var
      SavePos : LongInt;

    begin
      SavePos := FilePos(DestFile);
      Seek(DestFile, Ofs);
      BlockWrite(DestFile, DestPageHeader, SizeOf(PageHeaderRec));
      Seek(DestFile, SavePos);
      AsyncStatus := IoResult;

      UpdatePageHeader := (AsyncStatus = ecOK);
    end;

  begin

    DestFName := DefaultExtension(DestFName, 'APF');
    FName := DefaultExtension(FName, 'APF');

    { check to see if both input files exist }
    if not ExistFile(DestFName) or not ExistFile(FName) then begin
      AsyncStatus := epFatal+ecFileNotFound;
      Exit;
    end;

    { attempt to allocate the read buffer }
    if not GetMemCheck(ReadBuf, ReadBufferSize) then begin
      AsyncStatus := epFatal+ecOutOfMemory;
      Exit;
    end;

    { attempt to open destination file }
    Assign(DestFile, DestFName);
    Reset(DestFile, 1);
    AsyncStatus := IoResult;
    if (AsyncStatus <> ecOK) then
      Exit;

    { read in the fax header for the destination file }
    BlockRead(DestFile, DestHeader, SizeOf(FaxHeaderRec));
    AsyncStatus := IoResult;
    if (AsyncStatus <> ecOK) then
      goto Error;

    { find the last page in the destination file }
    Seek(DestFile, DestHeader.PageOfs);

    for OnPage := 1 to DestHeader.PageCount do begin

      LastPageOfs := FilePos(DestFile);

      BlockRead(DestFile, DestPageHeader, SizeOf(PageHeaderRec));
      AsyncStatus := IoResult;
      if (AsyncStatus <> ecOK) then
        goto Error;

      Seek(DestFile, FilePos(DestFile) + DestPageHeader.ImgLength);

    end;

    { open the append file }
    Assign(AppendFile, FName);
    Reset(AppendFile, 1);
    AsyncStatus := IoResult;
    if (AsyncStatus <> ecOK) then
      goto Error;

    { get the fax header for the append file }
    BlockRead(AppendFile, FaxHeader, SizeOf(FaxHeaderRec));
    AsyncStatus := IoResult;
    if (AsyncStatus <> ecOK) then
      goto Error;

    { get the first page header }
    Seek(AppendFile, FaxHeader.PageOfs);
    BlockRead(AppendFile, PageHeader, SizeOf(PageHeaderRec));
    AsyncStatus := IoResult;
    if (AsyncStatus <> ecOK) then
      goto Error;

    { if the resolutions of the last Dest page and the first Append page }
    { are different, force a page break                                  }
    if (PageHeader.ImgFlags <> DestPageHeader.ImgFlags) then
      PageBreak := True;

    if not PageBreak then begin

      { eat the last end-of-page marker }
      BytesInEOP := 9;

      if FlagIsSet(DestPageHeader.ImgFlags, ffLengthWords) then
        BytesInEOP := BytesInEOP + 2;

      Seek(DestFile,  LastPageOfs +
                      SizeOf(PageHeaderRec) +
                      DestPageHeader.ImgLength -
                      BytesInEOP );

      Truncate(DestFile);
      AsyncStatus := IoResult;
      if (AsyncStatus <> ecOK) then
        goto Error;

      { update the page header for the last page }
      DestPageHeader.ImgLength := DestPageHeader.ImgLength - BytesInEOP;
      if not UpdatePageHeader(LastPageOfs) then
        goto Error;
    end;

    { if we need to break the page, then we start copying from }
    { the page header of the first page, otherwise, we start   }
    { copying from the start of the data                       }

    if PageBreak then
      Seek(AppendFile, FaxHeader.PageOfs)
    else
      Seek(AppendFile, FaxHeader.PageOfs + SizeOf(PageHeaderRec));

    while not Eof(AppendFile) do begin

      BlockRead (AppendFile, ReadBuf^, ReadBufferSize, InBytes);
      BlockWrite(DestFile, ReadBuf^, InBytes);

      AsyncStatus := IoResult;
      if (AsyncStatus <> ecOK) then
        goto Error;

    end;

    { update the header with the new image length }
    if not PageBreak then begin

      Seek(AppendFile, FaxHeader.PageOfs);
      BlockRead(AppendFile, PageHeader, SizeOf(PageHeaderRec));
      AsyncStatus := IoResult;
      if (AsyncStatus <> ecOK) then
        goto Error;

      DestPageHeader.ImgLength := DestPageHeader.ImgLength + PageHeader.ImgLength;
      if not UpdatePageHeader(LastPageOfs) then
        goto Error;

    end;

    { update the fax header }
    DestHeader.PageCount := DestHeader.PageCount + FaxHeader.PageCount -
                            Ord(not PageBreak);
    Seek(DestFile, 0);
    BlockWrite(DestFile, DestHeader, SizeOf(FaxHeaderRec));
    AsyncStatus := IoResult;

  Error:

    Close(DestFile); if (IoResult   = 0) then ;
    Close(AppendFile); if (IoResult = 0) then ;

    FreeMemCheck(ReadBuf, ReadBufferSize);
  end;

  function MakeFaxFile(Node : CmdFileNodePtr; var TmpUsed : Boolean) : PathStr;
    {-if more than one fax file, combine and use temp file name}
  type
    FileArray = array[1..MaxFilesToSend] of PathStr;
  var
    I        : Byte;
    Ok       : Boolean;
    NumFiles : Byte;
    Buffer   : Pointer;
    Files    : FileArray;

    procedure CheckFile(F : PathStr);
    begin
      if F <> '' then begin
        Inc(NumFiles);
        Files[NumFiles] := F;
      end;
    end;

  begin
    TmpUsed := False;
    MakeFaxFile := '';
    FillChar(Files, SizeOf(Files), #0);
    with Node^ do begin
      NumFiles := 0;
      for I := 1 to MaxFilesToSend do
        CheckFile(Trim(FileName[I]));

      if NumFiles = 1 then
        MakeFaxFile := Files[1]
      else if NumFiles > 1 then begin
        TmpUsed := True;
        {combine all fax files into one}
        if GetMemCheck(Buffer, 4096) then begin
          CopyFile(Files[1], TmpApfName, Buffer, 4096);
          Ok := AsyncStatus = ecOk;
          FreeMemCheck(Buffer, 4096);
          if Ok then begin
            for I := 2 to NumFiles do begin
              if Ok then
                AppendFax(TmpApfName, Files[I], True);
              Ok := AsyncStatus = ecOk;
            end;
            if Ok then
              MakeFaxFile := TmpApfName;
          end;
        end else
          AsyncStatus := epFatal+ecOutOfMemory;
      end;
    end;
  end;

  {$IFDEF Tracing}
  procedure PrintFailureReport(NP : CmdFileNodePtr; Msg : string);
  var
    P    : Text;
    I    : Integer;
    DT   : DateTime;
  begin
    Assign(P, PrintDest);
    ReWrite(P);
    if IoResult = 0 then begin
      WriteLn(P, '**************** Fax error report ****************        ',
                           TodayString, ' ', Time24String);
      WriteLn(P);
      WriteLn(P, '      Error reported: ', Msg);
      WriteLn(P, '  Last hangup result: ', HexW(HangupResult));
      WriteLn(P);
      with NP^ do begin
      WriteLn(P, '   Command file name: ', CmdFileName);
        WriteLn(P, '               Phone: ', Phone);
        UnpackTime(Scheduled, DT);
        WriteLn(P, '           Scheduled: ', DateString(DT) + ' ' + TimeString(DT));
        WriteLn(P, '    Negotiated speed: ' + Long2Str(AcceptedBPSRate));
        WriteLn(P, '      Send baud rate: ', SendBaudRate);
        WriteLn(P, '          File names: ');
        for I := 1 to MaxFilesToSend do
          if FileName[I] <> '' then
            WriteLn(P, '                      ', FileName[I]);
        WriteLn(P, '           Sender ID: ', Sender);
        WriteLn(P, '          Cover page: ', CoverPage);
        WriteLn(P, '             Retries: ', Retries);
      end;
      Write(P, ^L);
      Close(P);
      if IoResult <> 0 then {};
    end;
  end;
  {$ENDIF}

  procedure ProcessQueueEntry;
  var
    I          : Integer;
    Entry      : Integer;
    NP         : CmdFileNodePtr;
    SFax       : C12SendFaxPtr;    {Send fax object}
    FaxFile    : PathStr;
    TmpApfUsed : Boolean;
    DT         : DateTime;
  begin
    {clear the fax send error flag}
    FaxSendError := False;

    {is there an entry ready for sending}
    NP := FaxQ.Head;
    if (NP = nil) or (NP^.Scheduled > GetPackedDateTime) then begin
      {reset time for our next process}
      NewTimerSecs(FaxQProcessTimer, FaxQProcessDelay);
      Exit;
    end;

    {see if the command file still exists}
    if not ExistFile(NP^.CmdFileName) then begin
      MakeLogEntry('Command file killed: '+NP^.CmdFileName);
      {remove queue entry}
      DeleteCmdFileNode(FaxQ, NP);
      Exit;
    end;

    {Restore screen if saved}
    if ScreenSaved then
      HandleScreenSave(ssRestore);

    {get the fax file to send - may be multiple}
    FaxFile := MakeFaxFile(NP, TmpApfUsed);
    if AsyncStatus <> ecOk then begin
      MakeLogEntry(msgFailedToCombine+StatusStr(AsyncStatus));
      RenameCommandFile(NP^.CmdFilename);
      {$IFDEF Tracing}
      PrintFailureReport(NP, msgFailedToCombine+StatusStr(AsyncStatus));
      {$ENDIF}
      DeleteCmdFileNode(FaxQ, NP);
      Exit;
    end;

    {do we have anything to fax?}
    if (FaxFile = '') and (NP^.CoverPage = '') then begin
      SetStatusLine(msgNoFaxFile);
      MakeLogEntry(msgNoFaxFile);
      RenameCommandFile(NP^.CmdFilename);
      {$IFDEF Tracing}
      PrintFailureReport(NP, msgNoFaxFile);
      {$ENDIF}
      DeleteCmdFileNode(FaxQ, NP);
      Exit;
    end;

    {Init fax object}
    SFax := nil;
    new(SFax, Init(NP^.SenderID, Port));
    if SFax = nil then begin
      SetStatusLine('Failed to initialize fax send object.');
      MakeLogEntry('Init error : ('+StatusStr(AsyncStatus)+'): ');
      Exit;
    end;

    SetStatusLine('Initializing modem for fax send...');
    {Set up fax options}
    with SFax^ do begin
      SetFaxStatusProc(MyStatus);
      SetFaxLogProc(MyFaxLog);
      SetModemInit(ModemInitStr);
      SetConnectAttempts(1, 1092);
      afOptionsOn(afAbortNoConnect);
      {Force an exit on errors, since we're only sending one fax}
      afOptionsOn(afExitOnError);
      SetModemFeatures(NP^.SendBaudRate, '0');
      if CommandBaud <> 0 then
        SetInitBaudRate(CommandBaud, 0);
      {Set desired class}
      FaxClass := SetClassType(FaxClass);
      if NP^.UseHeaderLine then begin
        SetHeaderText(DefHeader);
        SetTitle(NP^.HeaderText);
      end;
      SetRecipientName(NP^.Recipient);
      SetSenderName(NP^.Sender);

      AddFaxEntry(NP^.Phone, FaxFile, NP^.CoverPage);
    end;

    {store the command file name for the log method}
    CommandFileName := NP^.CmdFileName;

    {Send the fax}
    SetStatusLine('Sending fax to '+NP^.Phone+'...');
    SFax^.FaxTransmit;

    if TmpApfUsed then
      DeleteFile(FaxFile, False);

    UpdateStatusMsg;
    case AsyncStatus of
      ecOk :
        begin
          if not FaxSendError then begin
            DeleteCommandFile(NP^.CmdFileName);
            if TmpApfUsed then
              for I := 1 to MaxFilesToSend do
                if NP^.FileName[I] <> '' then
                  MakeLogEntry('Actual file name(s): '+NP^.FileName[I]);
            {delete tagged fax files}
            for I := 1 to MaxFilesToSend do
              if NP^.DeleteFlag[I] then
                DeleteFile(NP^.Filename[I], True);
            {remove queue entry}
            DeleteCmdFileNode(FaxQ, NP);
            SetStatusLine(fpsWaiting);
          end else begin
            RenameCommandFile(NP^.CmdFilename);
            MakeLogEntry('Funny (Ok) error received');
            {$IFDEF Tracing}
            PrintFailureReport(NP, StatusStr(AsyncStatus));
            {$ENDIF}
            DeleteCmdFileNode(FaxQ, NP);
          end;
        end;
      ecNoDialTone,
      ecFaxBusy :
        begin
          NP^.Scheduled := AddTime(GetPackedDateTime, RetryWaitTime);
          {!!NP^.Scheduled := GetPackedDateTime + RetryWaitTime div 2;}
          Inc(NP^.Retries);
          if NP^.Retries >= MaxFaxRetries then begin
            MakeLogEntry(msgBusyRetry);
            RenameCommandFile(NP^.CmdFilename);
            {$IFDEF Tracing}
            PrintFailureReport(NP, msgBusyRetry);
            {$ENDIF}
            DeleteCmdFileNode(FaxQ, NP);
          end else
            {sort the command list by date/time}
            SortCmdFileList(FaxQ);
        end;
      ecFaxVoiceCall,
      ecFaxDataCall :
        begin
          MakeLogEntry(msgVoiceOrData);
          RenameCommandFile(NP^.CmdFilename);
          {$IFDEF Tracing}
          PrintFailureReport(NP, msgVoiceOrData);
          {$ENDIF}
          DeleteCmdFileNode(FaxQ, NP);
        end;
    else
      {try failed sends two times before giving up}
      NP^.Scheduled := AddTime(GetPackedDateTime, RetryWaitTime);
      Inc(NP^.Retries);
      if (NP^.Retries >= 2) or (not Hangup4Retry and (HangupResult = 4)) then begin
        RenameCommandFile(NP^.CmdFilename);
        MakeLogEntry('Last hangup result: '+HexW(HangupResult));
        {$IFDEF Tracing}
        PrintFailureReport(NP, StatusStr(AsyncStatus));
        {$ENDIF}
        DeleteCmdFileNode(FaxQ, NP);
      end else
        {sort the command list by date/time}
        SortCmdFileList(FaxQ);
    end;

    {destroy the send fax object}
    Dispose(SFax, Done);

    {reset the modem for fax receive}
    ResetForReceive;

    DisplayCmdFileCount;
    UpdateClockDisplay;

    {reset timer for our next process}
    NewTimerSecs(FaxQProcessTimer, FaxQProcessDelay);
  end;


begin
  ReadIniFile;
  ParseCommandLine;
  CommandFileName := '';

  {Install our exit procedure}
  SaveExitProc := ExitProc;
  ExitProc := @MyExitProc;

  {put our irq at the head of the list}
  RotateIrqPriority(DefIrqNumber[ComPort]);

  Initialize;
  BuildStatusWindow;
  InitComplete := True;                                                {!!.03}

  FaxPrnCount := CountFaxesToPrint(FaxFilePath);

  {fill queue with any existing command requests}
  ScanCommandFiles;
  {init the FaxQ process timer}
  NewTimerSecs(FaxQProcessTimer, FaxQProcessDelay);

  if (not InitializePort) or (not InitializeFax) then begin
    ShowCursor;
    ClrScr;
    WriteLn;
    WriteLn('Unable to initialize: ', StatusStr(AsyncStatus));
    Halt(1);
  end;

  ShowStaticSettings;
  ShowPrintStatus(FileToPrint);

  LogOnLine(True);
  SetStatusLine(fpsWaiting);

  Done := False;
  repeat
    CallFaxEngine;  {Call fax engine}

    if not Receiving then begin
      UpdateClockDisplay;
      {process possible queue entry}
      if (FaxState = faxWaiting) and (FaxQ.Count > 0) and
         TimerExpired(FaxQProcessTimer) then
        {if a queue entry is ready process it}
        ProcessQueueEntry;

      {if its time to scan for new commands, do it}
      if (FaxState = faxWaiting) and TimerExpired(ScanTimer) then
        ScanCommandFiles;
    end;

    {Restore the screen if a command was entered}
    if ScreenSaved and (Command <> cmdNone) then
      HandleScreenSave(ssRestore);

    {Is it time to save the screen}
    if not ScreenSaved then begin
      if (not Receiving) and TimerExpired(SSTimer) then
        HandleScreenSave(ssSave);
    end else
      HandleScreenSave(ssMove);

    if Command <> cmdNone then
      NewTimerSecs(SSTimer, SSSaveTime);  {Reset screen timeout}

    {Check for user commands, execute if allowed}
    if Command = cmdCommandMode then  {F10 pressed?}
      CommandWindow;

    {Process command}
    case Command of
      cmdNone    : ;
      cmdExit    :
        Done := True;
      cmdShell   :
        if (not Printing) and (not Sending) and (not Receiving) then
          ShellOutAndListen;
      cmdDeleteFaxes :
        if (not Printing) and (not Sending) and (not Receiving) then
          PurgePrintedFaxes;
      cmdDeleteFailed :
        if (not Printing) and (not Sending) and (not Receiving) then
          PurgeFailedFaxes;
      cmdTogglePrint  :
        if (not Printing) then begin
          PrintSuspended := not PrintSuspended;
          PrintAttempt := 0;  {Reset attempt counter}
          LogSuspendResumePrint(PrintSuspended);
          {Recount faxes to print}
          FaxPrnCount := CountFaxesToPrint(FaxFilePath);
          ShowPrintStatus(FileToPrint);
        end;
      cmdViewLog    :
        if (not Sending) and (not Receiving) and (not Printing) then
          ViewFaxLog;
      cmdPrintLog :
        if (not Sending) and (not Receiving) and (not Printing) then
          if not PrintFaxLog then {};
      cmdDeleteLog  :
        if (not Sending) and (not Printing) and (not Receiving) then
          DeleteFaxLog;
      cmdToggleBlank :
        if (not Printing) then begin
          SuppressBlanks := not SuppressBlanks;
          FaxPrinter^.SetBlankLineSuppression(SuppressBlanks);
        end;
      cmdResetSessionCounts :
        begin
          FaxSndCount := 0;
          FaxRecCount := 0;
        end;
    end;

    {Clear command}
    Command := cmdNone;

    if AsyncStatus = ecUserAbort then
      Done := True;

    if (FaxState = faxWaiting) and (FaxPrnCount > 0) and
       (not Done) and (not PrintSuspended) then begin

      {Restore screen if saved}
      if ScreenSaved then
        HandleScreenSave(ssRestore);

      FileToPrint := GetFileToPrint;
      ShowPrintStatus(FileToPrint);
      if FileToPrint > '' then begin
        Printing := True;
        DisplayHelpLine((not Receiving) and (not Printing) and (not Sending));

        FaxPrinter^.PrintFax(PrintDest, FileToPrint);
        if AsyncStatus = ecOk then begin
          PrintAttempt := 0;  {Reset attempt counter}
          LogFaxPrinting(FileToPrint);
          RenameFaxFile(FileToPrint, PrintedFaxExt);
          FileToPrint := '';
          Dec(FaxPrnCount);
          SetStatusLine(fpsWaiting);
        end else begin
          Inc(PrintAttempt);
          if PrintAttempt = 1 then  {Log the error first time only}
            LogFaxPrinting(FileToPrint);

            {if a bad format fax file, rename it and continue}         {!!.03}
            if (AsyncStatus = ecDiskRead) or                           {!!.03}
               (AsyncStatus = ecFaxBadFormat) then begin               {!!.03}
              PrintAttempt := 0;  {Reset attempt counter}              {!!.03}
              RenameFaxFile(FileToPrint, FailedPrintExt);              {!!.03}
              FileToPrint := '';                                       {!!.03}
              Dec(FaxPrnCount);                                        {!!.03}
            end;                                                       {!!.03}

          if PrintAttempt > MaxPrintAttempts then begin
            PrintSuspended := True;
            LogSuspendResumePrint(PrintSuspended);
          end;
          UpdateStatusMsg;
        end;
        Printing := False;
        DisplayHelpLine((not Receiving) and (not Printing) and (not Sending));
        ShowPrintStatus(FileToPrint);
      end;
      ShowSpinner(PrintSpinner, False);  {Clear the printing spinner}
    end;

  until Done;

  {Clear the disk full flag just in case it is set}
  HandleDiskError(False);

  Dispose(FaxPrinter, Done); {Dispose of fax printer object}

  {Dispose of printer object}
  if UseEpson then
    Dispose(EpsonPrinterPtr(Printer), Done)
  else if UseEpson24 then
    Dispose(Epson24PinPrinterPtr(Printer), Done)
  else if UseHP300 then
    Dispose(HP300PrinterPtr(Printer), Done)
  else
    Dispose(HP150PrinterPtr(Printer), Done);

  Dispose(Fax, Done);        {Dispose of fax object}
  Dispose(Port, Done);       {Dispose of port object}
  DoneCmdFileList(FaxQ);

  LogOnLine(False);
  ShowCursor;
  ClrScr;
end.
