{$S-,R-,V-,I-,B-,F+,A-}
{$M 16384, 0, 655360}

{$I APDEFINE.INC}    {Conditional defines that may affect this program}

{$DEFINE AutoRetry}  {Enable to allow the fax object to automatically
                      retry busy fax numbers. Disable to give the
                      application control over retries.}

{$DEFINE FaxHWFlow}  {Enable to turn on one-way hardware flow control}

{******************************************************}
{*                 SIMPSND.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

program SimpSnd;
  {-Simple send-fax demo}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Dos,
  {$IFDEF UseOPro}
  OpCrt,
  OpString,                                                            {!!.03}
  {$ENDIF}
  {$IFDEF UseTPro}
  TpCrt,
  TpString,                                                            {!!.03}
  {$ENDIF}
  {$IFDEF Standalone}
  Crt,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApFaxD;
  {$ELSE}
  ApMisc,
  ApTimer,
  ApPort,
  ApUart,
  ApCom,
  ApFaxCvt,
  ApAbsFax,
  ApFax12,
  ApFaxCas;
  {$ENDIF}

const
  CopyrightLine = 'SIMPSND 2.03 -- send fax demo   (c)1993 TurboPower Software';
  Header = '$D  $T   From: $S  $I                            Page $P of $N';

const
  MInit       : String[40] = '';
  FaxFile     : PathStr = '';                    {Fax file to send}
  CoverPage   : PathStr = '';                    {cover page file}
  PNumber     : PathStr = '';                    {number to dial}
  StatID      : PathStr = 'SIMPSND DEMO';        {this station's ID}
  DefTitle    : PathStr = 'TurboPower Software'; {this station's title}
  CName       : ComNameType = Com1;              {port to use}
  BRate       : LongInt = 19200;                 {bit rate}
  FaxBRate    : Word = 9600;                     {FAX bit rate}
  SetFeatures : Boolean = False;                 {True to get/set features}
  SetFaxBRate : Boolean = False;                 {True to set fax bit rate}
  FaxClass    : ClassType = ctClass2;            {Class1,2 or CAS}
  IrqNum      : Byte = 0;                        {Undocumented IRQ switch}
  InitBaud    : LongInt = 0;                     {Baud rate for init cmds} {!!.01}

var
  Sender : FaxRecPtr;
  CPort  : PortRecPtr;
  Class : Char;
  Model, Chip, Rev : String;
  BitRate : LongInt;
  Check : Char;

  procedure AbortMsg(S : String);
    {-Display message and halt}
  begin
    {$IFDEF Tracing}
    DumpTraceHex('SIMPSND.TRC');
    {$ENDIF}

    if Sender <> nil then                                              {!!.01}
      if FaxClass = ctCAS then                                         {!!.01}
        DoneCasFax(Sender)                                             {!!.01}
      else                                                             {!!.01}
        DoneC12SendFax(Sender);                                        {!!.01}
    if CPort <> nil then                                               {!!.01}
      DonePort(CPort);                                                 {!!.01}

    WriteLn(S);
    Halt(1);
  end;

  function Long2Str(L : LongInt) : String;
  var
    S : String[20];
  begin
    Str(L, S);
    Long2Str := S;
  end;

  function ExistFile(FN : PathStr) : Boolean;
    {-True if file FN exists}
  var
    F : File;
    SaveMode : Byte;                                                   {!!.02}
  begin
    SaveMode := FileMode;                                              {!!.02}
    FileMode := $40;                                                   {!!.02}
    Assign(F, FN);
    Reset(F);
    FileMode := SaveMode;                                              {!!.02}
    ExistFile := (IOResult = 0);
    Close(F);
    if IOResult = 0 then ;
  end;

  procedure ShowHelp;
    {-Display cmd line params options and halt}
  begin
    WriteLn('Usage: SIMPSND [options] FaxFile');
    WriteLn('  /I StationID   Set Station ID');
    WriteLn('  /N Number      Set fax phone number to call');
    WriteLn('  /C ComPort     Set com port (1-4, default=1)');
    WriteLn('  /B Baud        Set port baud rate (4800 or 19200; default=19200)');
    WriteLn('  /L LowBaud     Set low baud rate for modem init (same as above; default=none)'); {!!.01}
    WriteLn('  /F FaxBPS      Set fax BPS rate (2400, 4800, 7200, 9600, 12000, 14400;');
    WriteLn('                                   default=9600)');
    WriteLn('  /M InitString  Set modem initialization string');
    WriteLn('  /V CoverFile   Use cover page file');
    WriteLn('  /H             Use highest possible bit rate and ECM if available');
    WriteLn('  /S FaxClass    Set fax class (1, 2, A(uto), C(AS); default=2)');
    WriteLn('  /?             Display help screen');
    Halt(0);
  end;

  procedure MyFaxErrorProc(P : Pointer; var StatusCode : Word);
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
  var
    AP : PortRecPtr absolute P;
  begin
    WriteLn(^M^J'Error: ', StatusStr(StatusCode mod 10000));
  end;

  function MyFaxAbort : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Abort fax send process if user presses <ESC>}
  var
    C : Char;
  begin
    MyFaxAbort := False;
    if KeyPressed then begin
      C := ReadKey;
      if C = #27 then
        MyFaxAbort := True
      else begin
        if C = #0 then
          C := ReadKey;
      end;
    end;
  end;

  procedure MyFaxStatus(FP : FaxRecPtr; Starting, Ending : Boolean);
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Status display routine}
  const
    First : Boolean = True;
    LastProgress : Word = 65535;
    PrevBPS : LongInt = 0;                                             {!!.03}
  var
    L : LongInt;
    Pages : Word;
    Page : Word;
    Bytes : LongInt;
    Total : LongInt;
    BPS : LongInt;
    Res : Boolean;
    ECM : Boolean;
    Progress : Word;
  begin
    {Check for errors first}
    if GetAsyncStatus <> ecOk then
      {Do nothing, we'll display an error message after FaxTransmit aborts}
      Exit;

    {No errors, show current progress. Show most progress values only once}
    Progress := GetFaxProgress(FP);
    if Progress <> LastProgress then begin
      First := True;
      if (LastProgress = fpBusyWait) or (LastProgress = fpSendPage) then
        WriteLn;
      LastProgress := Progress;
    end else
      First := False;

    {$IFNDEF AutoRetry}
    {Ignore open/close requests if in manual retry and fax is busy}
    if (Starting or Ending) and (Progress = fpBusyWait) then
      Exit;
    {$ENDIF}

    if Starting then begin
      WriteLn('--------------------------');
      WriteLn('Fax transmission beginning');
      LastProgress := 65535;
    end else if Ending then begin
      WriteLn;
      WriteLn('Fax transmission ended');
      WriteLn('----------------------');
    end else begin
      {Exit if we've already shown this status}
      if not First then
        case Progress of
          fpSendPage, fpBusyWait, fpSessionParams : ;                  {!!.03}
          else Exit;
        end;

      case Progress of
        fpWaiting :
          WriteLn('Waiting to process CAS send event');
        fpInitModem :
          WriteLn('Initializing fax modem');
        fpDialing :
          begin
            WriteLn('fax file to send: ', GetFaxName(FP));
            WriteLn('Dialing/waiting for connection');
          end;
        {$IFDEF AutoRetry}
        fpBusyWait:
          if FP^.PData^.ClassInUse = ctCas then
            Write(^M'Busy, waiting for redial: ', RemainingTimeInSecs(CasFaxPtr(FP)^.ReplyTimer):2)
          else
            Write(^M'Busy, waiting for redial: ', RemainingTimeInSecs(C12FaxRecPtr(FP)^.CData^.ReplyTimer):2);
        {$ENDIF}
        fpGotRemoteID :
          WriteLn('Connected to ', GetRemoteID(FP));
        fpSessionParams :
          begin
            GetSessionParams(FP, BPS, Res, ECM);
            if PrevBPS <> BPS then begin                               {!!.03}
              Write('Session capabilities: ', BPS, ' bps');
              if Res then
                Write(',  high resolution')
              else
                Write(',  standard resolution');
              if ECM then
                WriteLn(',  ECM')
              else
                WriteLn(',  no ECM');
            end;                                                       {!!.03}
            PrevBPS := BPS;                                            {!!.03}
          end;
        fpSendPage :
          case FaxClass of
            ctClass1, ctClass2 :
              begin
                GetPageInfoC12(FP, Pages, Page, Bytes, Total);
                if Page = 0 then
                  Write(^M'Sending cover: ', Bytes)
                else begin
                  if Total <> 0 then
                    L := Trunc(((Bytes * 1.0) / Total) * 100.0)
                  else
                    L := 0;
                  Write(^M'Sending page ', Page, ': ', Bytes, ' (',L,'%)');
                  ClrEol;
                end;
              end;
            ctCAS :
              begin
                GetPageInfoCas(FP, Pages, Page, Bytes, Total);
                Write(^M'Pages sent, total bytes sent: ', Page, ', ', Bytes);
              end;
          end;
        fpSendPageStatus:
          WriteLn('Sending end-of-page');
        fpPageOK:
          WriteLn('Page accepted');
      end;
    end;
  end;

  procedure MyFaxLog(CP : FaxRecPtr;
                     Number : String;
                     FName : PathStr;
                     Log : TLogFaxCode);
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
  var
    FLog : Text;
    F : File;
  begin
    with CP^ do begin
      Assign(FLog, 'SIMPSND.HIS');
      Append(FLog);
      if IOResult = 2 then
        ReWrite(FLog);
      if IOResult <> 0 then
        Exit;
      case Log of
        lfaxTransmitStart :
          WriteLn(FLog, TodayString, ' ', NowString,
                        ' -- start fax transmit: ', FName,
                        '  to ', Number);
        lfaxTransmitOk :
          begin
            WriteLn(FLog, TodayString, ' ', NowString,
                          ' -- end fax transmit:', FName);
            WriteLn(FLog);
          end;
        lfaxTransmitFail :
          begin
            WriteLn(FLog, TodayString, ' ', NowString,
                          ' -- fail fax transmit(', GetAsyncStatus, '): ', FName);
            WriteLn(FLog);
          end;
      end;
      Close(FLog);
      if IOResult <> 0 then ;
    end;
  end;

  procedure OurSendFax;
    {-send the fax using special repeat-on-busy logic}

    procedure Wait30;
    var
      C  : Char;
      ET : EventTimer;
    begin
      NewTimer(ET, Secs2Tics(30));
      while not TimerExpired(ET) do begin
        if KeyPressed then begin
          C := Upcase(ReadKey);
          if C = #27 then begin
            SetAsyncStatus(ecUserAbort);
            Exit;
          end else if C = 'C' then
            Exit;
        end;
      end;
    end;

  begin
    {Add single fax file info from command line data}
    AddFaxEntry(Sender, PNumber, FaxFile, CoverPage);

    {$IFDEF AutoRetry}
    if FaxClass = ctCas then
      FaxTransmitCas(Sender)
    else
      FaxTransmitC12(Sender);
    {$ELSE}
    repeat
      if FaxClass = ctCas then
        FaxTransmitCas(Sender)
      else
        FaxTransmitC12(Sender);
      if GetAsyncStatus = ecFaxBusy then begin
        WriteLn('Busy, waiting 30 seconds for redial (<ESC> aborts, <"C"> cycles): ');
        Wait30;
        WriteLn;
      end;
    until GetAsyncStatus <> ecFaxBusy;
    {$ENDIF}
  end;

  procedure ParseCmdLine;
    {-Get command line params and validate}
  var
    S : String;
    L : LongInt;
    N : Integer;
    I : Integer;

    function NextS : String;
    begin
      Inc(I);
      NextS := ParamStr(I);
    end;

    function GetDelimited : String;
    var
      S, SPart: String[20];
    begin
      Inc(I);
      S := ParamStr(I);
      if S[1] = '"' then begin
        Delete(S, 1, 1);
        while (S[Length(S)] <> '"') and (I < ParamCount) do begin
          Inc(I);
          SPart := ParamStr(I);
          S := S + ' ' + SPart;
        end;
        Dec(Byte(S[0]));
      end;
      GetDelimited := S;
    end;

  begin
    if ParamCount = 0 then
      ShowHelp;

    I := 1;
    while I <= ParamCount do begin
      S := ParamStr(i);
      if S[1] = '?' then
        ShowHelp;

      if S[1] in ['-','/'] then begin
        case upcase(S[2]) of
          '?':
            ShowHelp;
          'I':  {station ID}
            StatID := GetDelimited;
          'N':  {number to dial}
            PNumber := NextS;
          'C':  {comm port to use}
            begin
              S := NextS;
              case S[1] of
                '1': CName := Com1;
                '2': CName := Com2;
                '3': CName := Com3;
                '4': CName := Com4;
                else ShowHelp;
               end;
            end;
          'B':  {baud}
            begin
              Val(NextS, L, N);
              if N = 0 then
                BRate := L;
            end;
          'L':  {lowbaud}                                              {!!.01}
            begin                                                      {!!.01}
              Val(NextS, L, N);                                        {!!.01}
              if N = 0 then                                            {!!.01}
                InitBaud := L;                                         {!!.01}
            end;                                                       {!!.01}
          'F':  {max fax bit rate}
            begin
              Val(NextS, L, N);
              if N = 0 then begin
                FaxBRate := Word(L);
                SetFaxBRate := True;
              end;
            end;
          'M':  {modem init string}
            MInit := NextS;
          'T':  {sender title}
            DefTitle := NextS;
          'V':  {cover page filename}
            CoverPage := NextS;
          'H' : {use highest features}
            SetFeatures := True;
          'S' : {set fax class}
            begin
              S := NextS;
              case Upcase(S[1]) of
                '1' : FaxClass := ctClass1;
                '2' : FaxClass := ctClass2;
                'A' : FaxClass := ctDetect;
                'C' : FaxClass := ctCAS;
                else ShowHelp;
              end;
            end;
          'Q' :
            Val(NextS, IrqNum, N);
          else begin
            WriteLn(^G'Unknown parameter "'+S+'"');
            ShowHelp;
          end;
        end;
      end else
        FaxFile := S;

      Inc(I);
    end;

    if (FaxFile = '') and (CoverPage = '')  then
      ShowHelp
    else begin
      if FaxClass <> ctCas then
        FaxFile := ForceExtension(FaxFile, 'APF');
      if not ExistFile(FaxFile) then
        AbortMsg('Specified fax file not found');
    end;
  end;

  procedure SendFaxCAS;
    {-Submit file to CAS manager}
  begin
    {Init fax object}
    InitCasFax(Sender, StatID);
    if GetAsyncStatus <> ecOk then
      AbortMsg('Could not initialize CAS fax record, status = ' +
                Long2Str(GetAsyncStatus));

    {Set an abort hook just for CAS}
    SetCASAbortFunc(Sender, MyFaxAbort);
    SetFaxStatusProc(Sender, MyFaxStatus);
    SetFaxLogProc(Sender, MyFaxLog);

    (*
    {Uncomment this line to have SubmitSingleFile use a control file}
    Sender^.afOptionsOn(afCASSubmitUseControl);
    *)

    OurSendFax;

    DoneCasFax(Sender);
  end;

  procedure SendFaxClass12;
    {-Send faxes with APRO's class 1/2 engine}
  begin
    {$IFDEF Tracing}
    InitTracing(20000);
    if GetAsyncStatus <> ecOk then
      AbortMsg('Failed to start trace');
    {$ENDIF}

    {Init port}
    if IrqNum <> 0 then begin
      SetUart(CName, 0, IrqNum, IrqNum+8);
      if (CName = Com3) or (CName = Com4) then
        PS2DetectMode := PS2Ignore;
    end;
    InitPort(CPort, CName, BRate, NoParity, 8, 1,
             2048, 8192, DefPortOptions);
    if CPort = nil then
      AbortMsg('Unable to open port, status = '+Long2Str(GetAsyncStatus));

    {$IFDEF FaxHWFlow}
    {Modem may want to flow control us (but we can't flow control it)}
    HWFlowEnable(CPort, 2000, 50, hfRequireCTS or hfUseRTS);
    if GetAsyncStatus <> ecOk then
      AbortMsg('Failed to set hardware flow control, status = '+Long2Str(GetAsyncStatus));
    {$ENDIF}

    {Init fax sender}
    InitC12SendFax(Sender, StatID, CPort);
    if Sender = nil then begin
      DonePort(CPort);
      AbortMsg('Could not initialize fax send engine, status = '+Long2Str(GetAsyncStatus));
    end;

    {Set up fax options}
    SetAbortFunc(CPort, MyFaxAbort);
    SetErrorProc(CPort, MyFaxErrorProc);
    SetFaxStatusProc(Sender, MyFaxStatus);
    SetHeaderText(Sender, Header);
    SetTitle(Sender, DefTitle);
    SetModemInit(Sender, MInit);
    SetFaxLogProc(Sender, MyFaxLog);
    {$IFDEF AutoRetry}
    SetConnectAttempts(Sender, 3, 1092);
    {$ELSE}
    SetConnectAttempts(Sender, 1, 1092);
    afOptionsOn(Sender, afAbortNoConnect);
    {$ENDIF}

    if InitBaud <> 0 then                                              {!!.01}
      SetInitBaudRate(Sender, InitBaud, 0);                            {!!.01}

    {Force an exit on errors, since we're only sending one fax}
    afOptionsOn(Sender, afExitOnError);

    {Make sure modem supports class 1/2}
    WriteLn('Identifying modem...');
    if GetModemInfo(Sender, Class, Model, Chip, Rev, True) then begin
      if Class = 'B' then                                              {!!.02}
        WriteLn('Highest class: 2.0')                                  {!!.02}
      else                                                             {!!.02}
        WriteLn('Highest class: ', Class);
      WriteLn('Chip: ', Chip);
      WriteLn('Model: ', Model);
      WriteLn('Revision: ', Rev);
      WriteLn;
      if Class = '1' then
        FaxClass := ctClass1;
    end else
      AbortMsg('Unable to identify modem');

    {Set desired class}
    FaxClass := SetClassType(Sender, FaxClass);
    case FaxClass of
      ctClass1 : WriteLn('Fax class is set to Class 1');
      ctClass2 : WriteLn('Fax class is set to Class 2');
      ctCAS    : WriteLn('Fax class is CAS');
      else       AbortMsg('Failed to set fax class');
    end;

    {Test modem features and set best possible compression and error checking}
    if FaxClass = ctClass2 then begin
      WriteLn('Testing modem features...');
      GetModemFeatures(Sender, BitRate, Check);
      WriteLn('Max bits/second: ', BitRate, ',   Error checking: ', Check);
      if SetFeatures then
        SetModemFeatures(Sender, FaxBRate, Check);
    end;

    {Check for request to set fax bitrate}
    if SetFaxBRate then
      SetModemFeatures(Sender, FaxBRate, '0');

    {Send the fax}
    OurSendFax;
    case GetAsyncStatus of
      ecOk               : WriteLn('Fax transmit session complete');
      ecTimeout          : WriteLn('Timeout waiting for data');
      ecUserAbort        : WriteLn('Fax aborted by user');
      ecFaxVoiceCall     : WriteLn('Voice answered phone');
      ecFaxDataCall      : WriteLn('Data modem answered phone');
      ecFaxBusy          : WriteLn('Line was busy');
      ecFaxNoFontFile    : WriteLn('Font file not found');
      ecFaxInitError     : WriteLn('Error initializing modem');
      ecFaxTrainError    : WriteLn('Error during modem training');
      ecFaxSessionError : begin
                            WriteLn('Error during session');
                            WriteLn('Hangup result was ', GetHangupResult(Sender));
                          end;
      else                WriteLn('Unknown error: ', GetAsyncStatus);
    end;

    {Cleanup}
    DoneC12SendFax(Sender);
    DonePort(CPort);

    {$IFDEF Tracing}
    DumpTracehex('SIMPSND.TRC');
    {$ENDIF}
  end;

begin
  WriteLn(CopyrightLine);

  Sender := nil;                                                       {!!.01}
  CPort := nil;                                                        {!!.01}

  {Set stdout for output}
  Assign(Output, '');
  Rewrite(Output);

  {Get parameters}
  ParseCmdLine;

  if FaxClass = ctCAS then
    SendFaxCAS
  else
    SendFaxClass12;
end.
