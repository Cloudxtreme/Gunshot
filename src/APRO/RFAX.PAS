{$A+,F+,I-,R-,S-,V-,B+}
{$M 8192, 0, 655360}

{$I APDEFINE.INC}       {Conditional defines that may affect this program}
{$I OPDEFINE.INC}       {Conditional defines that may affect this program}

(* NOTE:
RFAX calls OPTSR.SuppressMouseHandling to avoid the hiding and restoring the
mouse cursor while popping up and popping down (which, at the frequency RFAX
works, can result in annoying mouse cursor blinking). SuppressMouseHandling
was added in OPRO 1.13 so it's in a {$IFDEF OPRO12} block to avoid compilation
errors with earlier versions of OPRO. If you have OPRO 1.13 or 1.14 you can
remove that conditional check around SuppressMouseHandling
*)

{$DEFINE SmallStatus}   {Enable for small status during background receive}

{$IFNDEF UseOPro}
  !! STOP COMPILE: This program requires Object Professional or
                   TSR's Made Easy !!
{$ENDIF}

{$IFDEF DPMI}
  !! STOP COMPILE: This program is real-mode only !!
{$ENDIF}

{$IFDEF Windows}
  !! STOP COMPILE: This program is real-mode only !!
{$ENDIF}

{******************************************************}
{*                   RFAX.PAS 2.03                    *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

program RFax;
  {-Demo TSR for receiving faxes}

uses
  Dos,
  OpString,
  OpCrt,
  OpRoot,
  OpInt,
  OpTsr,
  ApMisc,
  ApPort,
  ApUart,
  ApCom,
  ApFaxCvt,
  ApAbsFax,
  ApFax12,
  ApFaxCAS;

const
  CopyrightLine = 'RFAX 2.03 -- receive fax TSR demo   (c)1993 TurboPower Software';
  ClockHandle   = 16;
  RFaxNotLoaded = 'RFAX isn''t loaded';
  RFaxInterval  = 9;
  OutBufSize    = 128;

const
  ModuleName    : String[4] = 'RFAX';
  InBufSize     : Word = 4096;
  Disabled      : Boolean = False;

const
  WAttr      = $1B;   {Window attribute}
  FAttr      = $1E;   {Frame attribute}
  DAttr      = $1F;   {Data attribute}
  SmallAttr  = $03;   {Small status line attribute}

const
  CName           : ComNameType = Com1;
  BRate           : LongInt = 19200;
  FaxBRate        : Word = 9600;
  MInit           : String[40] = 'ATM0V1X4';
  StatID          : String[40] = 'RFAX DEMO';
  FaxPath         : PathStr = '';
  CPort           : PortRecPtr = nil;
  Receiver        : FaxRecPtr = nil;
  NeedMasterReset : Boolean = False;
  InBackground    : Boolean = True;
  FaxClass        : ClassType = ctClass2;
  IrqNum          : Byte = 0;
  CommandBaud     : LongInt = 0;                                       {!!.01}

type
  BufPtr = ^BufferArray;
  BufferArray = array[0..MaxInt] of Char;

var
  PopStack     : Array[1..6000] of Byte;
  RFaxProcHdl  : Byte;
  FaxState     : FaxStateType;

  procedure Abort(Msg : String);
  begin
    WriteLn(Msg);
    Halt(1);
  end;

  function InitAbort : Boolean;
  begin
    InitAbort := False;
    if KeyPressed then
      InitAbort := ReadKey = #27;
  end;

  procedure ClockInt(BP : Word); interrupt;
    {-INT $1C handler -- periodically invokes the RcvProc popproc}
  const
    Counter : Byte = 0;
  var
    Regs : IntRegisters absolute BP;
  begin
    {if we're active...}
    if not Disabled then begin
      {Always increment protocol interval counter}
      Inc(Counter);

      if (CPort <> nil) and (Receiver <> nil) then
        if (Counter > RFaxInterval) or
           (CharReady(CPort)) or
           (NeedMasterReset) then begin
          SetPopTicker(RFaxProcHdl, 8);
          Counter := 0;
        end;
    end;

    {Chain to previous INT $1C handler}
    ChainInt(Regs, IsrArray[ClockHandle].OrigAddr);
  end;

  function BuildWindow(XLow, YLow, XHigh, YHigh : Byte; Header : String) : Pointer;
    {-Saves the underlying screen, frames and clears a window}
  type
    FrameCharType = (ULeft, LLeft, URight, LRight, Horiz, Vert);
    FrameArray = array[FrameCharType] of Char;
  const
    FrameChars : FrameArray = 'ÕÔ¸¾Í³';
  var
    CoversP : BufPtr;
    WordsPerRow : Word;
    BufBytes : Word;
    SrcPos : Word;
    DestPos : Word;
    Row : Word;
    HeaderLen : Byte absolute Header;
    Width, HeaderPos : Byte;
    Span : string[132];
    SpanLen : Byte absolute Span;

  begin
    BuildWindow := nil;

    {Compute number of words to move per row}
    WordsPerRow := Succ(XHigh-XLow);

    {Compute bytes needed for screen buffer}
    BufBytes := (WordsPerRow*Succ(YHigh-YLow)) shl 1;

    {Make sure enough memory is available}
    if not GetMemCheck(CoversP, BufBytes) then
      Exit;

    {Save current contents to the screen buffer}
    DestPos := 0;
    SrcPos := (Pred(YLow)*ScreenWidth+Pred(XLow)) shl 1;
    for Row := YLow to YHigh do begin
      MoveScreen(Mem[VideoSegment:SrcPos], CoversP^[DestPos], WordsPerRow);
      Inc(SrcPos, ScreenWidth shl 1);
      Inc(DestPos, WordsPerRow shl 1);
    end;

    {Calculate width of window and position of header}
    SpanLen := Succ(XHigh - XLow);
    Width := SpanLen-2;

    {construct the upper border and draw it}
    FillChar(Span[2], Width, FrameChars[Horiz]);
    Span[1] := FrameChars[ULeft];
    Span[SpanLen] := FrameChars[URight];
    FastWrite(Span, YLow, XLow, FAttr);

    {Draw the vertical bars}
    for Row := Succ(YLow) to Pred(YHigh) do begin
      FastWrite(FrameChars[Vert], Row, XLow, FAttr);
      FastWrite(FrameChars[Vert], Row, XHigh, FAttr);
    end;

    {Draw the bottom border}
    Span[1] := FrameChars[LLeft];
    Span[SpanLen] := FrameChars[LRight];
    FastWrite(Span, YHigh, XLow, FAttr);

    {Draw the header}
    if HeaderLen > 0 then begin
      if HeaderLen > Width then
        HeaderLen := Width;
      HeaderPos := (SpanLen-HeaderLen) shr 1;
      FastWrite(Header, YLow, XLow + HeaderPos, FAttr);
    end;

    {Fill in the window}
    for Row := Ylow+1 to YHigh-1 do
      FastWrite(CharStr(' ', Pred(XHigh-XLow)), Row, XLow+1, FAttr);

    BuildWindow := CoversP;
  end;

  procedure RemoveWindow(P : Pointer; XLow, YLow, XHigh, YHigh : Byte);
    {-Restore screen contents and deallocate buffer space if requested}
  var
    CoversP : BufPtr absolute P;
    WordsPerRow : Word;
    SrcPos : Word;
    DestPos : Word;
    Row : Word;
  begin
    {Compute number of words to move per row}
    WordsPerRow := Succ(XHigh-XLow);

    {Restore current contents to the screen buffer}
    DestPos := 0;
    SrcPos := (Pred(YLow)*ScreenWidth+Pred(XLow)) shl 1;
    for Row := YLow to YHigh do begin
      MoveScreen(CoversP^[DestPos], Mem[VideoSegment:SrcPos], WordsPerRow);
      Inc(SrcPos, ScreenWidth shl 1);
      Inc(DestPos, WordsPerRow shl 1);
    end;

    {Deallocate buffer space}
    FreeMemCheck(CoversP, (WordsPerRow*Succ(YHigh-YLow)) shl 1);
  end;

  procedure RFaxStatus(FP : FaxRecPtr; Starting, Ending : Boolean);
  const
    P : Pointer = nil;
  var
    S : String[40];
    BPS : LongInt;
    Res : Boolean;
    ECM : Boolean;
    Progress : Word;
    Pages : Word;
    Page : Word;
    BytesTransferred : LongInt;
    PageLength : LongInt;
  begin
    {do nothing if running totally in background}
    if InBackground then
      Exit;

    if Starting then begin
      if P = nil then begin
        P := BuildWindow((ScreenWidth shr 1)-22, 8, (ScreenWidth shr 1)+22, 14, ' Receiving FAX ');
        FastWrite(' State:', 10, (ScreenWidth shr 1)-20, WAttr);
        FastWrite('Status:', 11, (ScreenWidth shr 1)-20, WAttr);
        FastWrite(' Speed:', 12, (ScreenWidth shr 1)-20, WAttr);
        FastWrite(Pad(Long2Str(FaxBRate), 33), 12, (ScreenWidth shr 1)-12, DAttr);
      end;
    end;

    if P <> nil then begin
      FastWrite(Pad(Long2Str(Ord(C12ReceiveFaxPtr(FP)^.State)), 5), 10, (ScreenWidth shr 1)-12, DAttr);
      Progress := GetFaxProgress(FP);
      case Progress of
        fpAnswer:
          S := 'Answering incoming call';
        fpIncoming:
          S := 'Incoming call is fax';
        fpGotRemoteID :
          S := 'Call from '+GetRemoteID(FP);
        fpSessionParams :
          begin
            GetSessionParams(FP, BPS, Res, ECM);
            S := Long2Str(BPS);
            if Res then
              S := S + ', high'
            else
              S := S + ', std';
            if ECM then
              S := S + ', ECM'
            else
              S := S + ', no ECM';
            FastWrite(Pad(Long2Str(BPS)+'   ', 33), 12, (ScreenWidth shr 1)-12, DAttr);
          end;
        fpGetPage:
          begin
            GetPageInfoC12(FP, Pages, Page, BytesTransferred, PageLength);
            S := 'Receiving page data: '+Long2Str(BytesTransferred);
          end;
        fpGetPageResult :
          S := 'Getting page result';
        fpCheckMorePages :
          S := 'Checking for more pages';
        fpGetHangup:
          S := 'Waiting for hangup command';
        fpGotHangup:
          S := 'Disconnect request acknowledged';
        else
          S := '';
      end;
      FastWrite(Pad(S, 33), 11, (ScreenWidth shr 1)-12, DAttr);
    end;

    if Ending then
      if P <> nil then begin
        RemoveWindow(P, (ScreenWidth shr 1)-22, 8, (ScreenWidth shr 1)+22, 14);
        P := nil;
      end;
  end;

  procedure RFaxLog(FP : FaxRecPtr;
                    Number : String;
                    FName : PathStr;
                    Log : TLogFaxCode);
  var
    FLog : Text;
  begin
    Assign(FLog, 'RFAX.HIS');
    Append(FLog);
    if IOResult = 2 then
      ReWrite(FLog);
    if IOResult <> 0 then
      Exit;
    case Log of
      lfaxReceiveStart :
        WriteLn(FLog, TodayString, ' ', NowString,
                      ' -- start fax receive: ', FName,
                      '  from ', GetRemoteID(FP));
      lfaxReceiveOk :
        begin
          WriteLn(FLog, TodayString, ' ', NowString,
                        ' -- end fax receive: ', FName);
          WriteLn(FLog);
        end;
      lfaxReceiveSkip :
        begin
          WriteLn(FLog, TodayString, ' ', NowString,
                        ' -- fax rejected from ', GetRemoteID(FP));
          WriteLn(FLog);
        end;
      lfaxReceiveFail :
        begin
          WriteLn(FLog, TodayString, ' ', NowString,
                        ' -- fail fax receive(', AsyncStatus, '): ', FName);
          WriteLn(FLog);
        end;
    end;
    Close(FLog);
    if IOResult <> 0 then ;
  end;

  function OpenPort : Boolean;
    {-Open the com port}
  begin
    OpenPort := False;
    if IrqNum <> 0 then begin
      SetUart(CName, 0, IrqNum, IrqNum+8);
      if (CName = Com3) or (CName = Com4) then
        PS2DetectMode := PS2Ignore;
    end;
    InitPort(CPort, CName, BRate, NoParity, 8, 1,
                    InBufSize, OutBufSize, DefPortOptions);
    OpenPort := (CPort <> nil);
  end;

  function InitFaxModem(Startup : Boolean) : Boolean;
  var
    Class : Char;
    Model, Chip, Rev : String;
    OK : Boolean;                                                      {!!.01}
  begin
    InitFaxModem := False;
    NeedMasterReset := False;

    if not Startup then begin
      if CPort <> nil then begin
        SetModem(CPort, False, False);
        DonePort(CPort);
        CPort := nil;
      end;
      if not OpenPort then
        WriteLn('Unable to initialize port')
      else
        SetModem(CPort, True, True);
    end;

    afOptionsOn(Receiver, afExitOnError);                              {!!.03}
    SetFaxPort(Receiver, CPort);
    SetDestinationDir(Receiver, FaxPath);
    SetFaxStatusProc(Receiver, RFaxStatus);
    SetFaxLogProc(Receiver, RFaxLog);
    SetModemInit(Receiver, MInit);
    if CommandBaud <> 0 then                                           {!!.01}
      SetInitBaudRate(Receiver, CommandBaud, 0);                       {!!.01}

    if Startup then begin
      if GetModemInfo(Receiver, Class, Model, Chip, Rev, True) then begin
        if Class = 'B' then                                            {!!.02}
          WriteLn('Highest class: 2.0')                                {!!.02}
        else                                                           {!!.02}
          WriteLn('Highest class: ', Class);
        if Class = '1' then
          {Force to class 1}
          FaxClass := ctClass1;
      end else
        Abort('Unable to identify modem');

      {Set desired class}
      FaxClass := SetClassType(Receiver, FaxClass);
      case FaxClass of
        ctClass1 : WriteLn('Fax class is set to Class 1');
        ctClass2 : WriteLn('Fax class is set to Class 2');
        else begin
          WriteLn('Failed to set fax class');
          Exit;
        end;
      end;
    end;
    OK := InitModemForFaxReceive(Receiver);                            {!!.01}
    if OK then                                                         {!!.01}
      PrepareFaxReceivePartC12(Receiver);                              {!!.01}
    InitFaxModem := OK;                                                {!!.01}
  end;

  procedure PrepareFaxModem;
  begin
    InitC12ReceiveFax(Receiver, StatID, CPort);
    if AsyncStatus <> ecOk then
      Abort('Unable to init fax manager');

    {Set abort function for initialization only}
    SetAbortFunc(CPort, InitAbort);

    {Prepare for receive}
    WriteLn('Identifying and initializing modem...');
    if not InitFaxModem(True) then
      Abort('Unable to initialize modem');

    {Remove abort function}
    SetAbortFunc(CPort, NoAbortFunc);
  end;

  procedure RFaxProc(var Regs : Registers);
    {-Do a small portion of the protocol}
  const
    First : Boolean = True;
  var
    Pages : Word;
    Page : Word;
    Bytes : LongInt;
    Total : LongInt;
  begin
    if NeedMasterReset then
      if InitFaxModem(False) then ;

    if (not InBackground) and (C12ReceiveFaxPtr(Receiver)^.State >= rfAnswer) then begin
      {Stay in popup if not in background and already answered phone}
      SetOneFax(Receiver, True);
      repeat
        FaxState := FaxReceivePartC12(Receiver);
      until (AsyncStatus <> ecOK) or (FaxState = faxFinished);  {!!.03}
      C12ReceiveFaxPtr(Receiver)^.State := rfInit;
    end else begin
      {Call state machine once and show little status}
      repeat
        FaxState := FaxReceivePartC12(Receiver);
        {$IFDEF SmallStatus}
        if InTextMode and InBackground then begin
          case C12ReceiveFaxPtr(Receiver)^.State of
            rfAnswer :
              FastWrite('Answering...        ', 1, 60, SmallAttr);
            rfGetPageData :
              if First then begin
                FastWrite('Rec: '+ Pad(GetFaxName(Receiver), 15), 1, 60, SmallAttr);
                First := False;
              end else begin
                GetPageInfoC12(Receiver, Pages, Page, Bytes, Total);
                FastWrite('Page ' + Pad(Long2Str(Page), 2) +
                          ': ' + Pad(Long2Str(Bytes), 5) +
                          '       ', 1, 60, SmallAttr);
              end;
            rfComplete,
            rfAbort :
              begin
                FastWrite('Receive complete    ', 1, 60, SmallAttr);
                First := True;
              end;
          end;
        end;
        {$ENDIF}
      until FaxState <> faxCritical;
    end;
  end;

  procedure ExternalIFC(BP : Word); interrupt;
    {-Entry point for external requests}
  var
    Regs : IntRegisters absolute BP;
    SavePSP : Word;
  begin
    {Unload TSR if requested}
    case Regs.AH of
      1 : begin   {Unload}
            {$IFDEF Tracing}
            DumpTrace('RFAX.TRC');
            {$ENDIF}

            DonePort(CPort);
            SavePSP := GetPSP;
            SetPSP(PrefixSeg);
            Regs.AL := Ord(DisableTSR);
            SetPSP(SavePSP);
          end;
      2 : begin
            Disabled := False;
            SetModem(CPort, True, True);
            NeedMasterReset := True;
          end;
      3 : if C12ReceiveFaxPtr(Receiver)^.State > rfWaiting then
            Regs.AL := 1
          else begin
            Regs.AL := 0;
            Disabled := True;
            SetModem(CPort, False, False);
          end;
    end;
  end;

  procedure UnloadRFax;
    {-Try to unload the resident copy}
  var
    P : IfcPtr;
    Regs : IntRegisters;
  begin
    P := ModulePtrByName(ModuleName);
    if P = nil then
      WriteLn(RFaxNotLoaded)
    else if (P^.CmdEntryPtr <> nil) then begin
      RestoreAllVectors;
      Regs.AH := 1;
      EmulateInt(Regs, P^.CmdEntryPtr);
      if Regs.AL = 1 then
        WriteLn('RFAX Unloaded')
      else
        WriteLn('Can''t unload RFAX');
    end;
    Halt;
  end;

  procedure ResetRFax;
    {-Try to reset the resident copy}
  var
    P : IfcPtr;
    Regs : IntRegisters;
  begin
    P := ModulePtrByName(ModuleName);
    if P = nil then
      WriteLn(RFaxNotLoaded)
    else if (P^.CmdEntryPtr <> nil) then begin
      RestoreAllVectors;
      Regs.AH := 2;
      EmulateInt(Regs, P^.CmdEntryPtr);
      WriteLn('RFAX reset');
    end;
    Halt;
  end;

  procedure DisableRFax;
    {-Try to disable the resident copy}
  var
    P : IfcPtr;
    Regs : IntRegisters;
  begin
    P := ModulePtrByName(ModuleName);
    if P = nil then
      WriteLn(RFaxNotLoaded)
    else if (P^.CmdEntryPtr <> nil) then begin
      RestoreAllVectors;
      Regs.AH := 3;
      EmulateInt(Regs, P^.CmdEntryPtr);
      if Regs.AL = 0 then
        WriteLn('RFAX disabled, run RFAX /R to re-enable')
      else
        WriteLn('Receive in progress, can''t disable right now.');
    end;
    Halt;
  end;

  procedure ShowHelp;
  begin
    WriteLn('Usage: RFAX ComPort [options]');
    WriteLn('  /U             Unload resident copy of RFAX');
    WriteLn('  /R             Tell the resident copy of RFAX to reset the modem');
    WriteLn('  /D             Disable (but leave loaded) resident copy of RFAX');
    WriteLn('  /T             Load as pop-up (default=full background)');
    WriteLn('  /B Baud        Set port baud rate (4800, 7200, 9600, 19200; default = 19200)');
    WriteLn('  /L LowBaud     Set low baud rate for modem init (same as above; default=none)'); {!!.01}
    WriteLn('  /F FaxBPS      Set fax BPS rate (2400, 4800, 7200, 9600, 12000, 14400;');
    WriteLn('                                   default=9600)');
    WriteLn('  /M InitString  Set modem initialization string');
    WriteLn('  /I StationID   Set station ID');
    WriteLn('  /P Path        Set received fax files path');
    WriteLn('  /S FaxClass    Set fax class (1, 2, A(uto); default=2)');
    WriteLn('  /?             Display this help screen');
    Halt(0);
  end;

  procedure ParseCmdLine;
  var
    S : String;
    I : Integer;
    C : Integer;
    GotC : Boolean;

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
    WriteLn(CopyrightLine);

    GotC := False;
    for I := 1 to ParamCount do begin
      S := ParamStr(i);

      if S[1] in ['/','-'] then begin
        case Upcase(S[2]) of
          '?' :
            ShowHelp;
          'B' :
            begin
              Val(NextS, BRate, C);
              if C <> 0 then
                BRate := 19200;
            end;
          'L' :                                                        {!!.01}
            begin                                                      {!!.01}
              Val(NextS, CommandBaud, C);                              {!!.01}
              if C <> 0 then                                           {!!.01}
                CommandBaud := 0;                                      {!!.01}
            end;                                                       {!!.01}
          'F' :
            begin
              Val(NextS, FaxBRate, C);
              if C <> 0 then
                FaxBRate := 9600;
            end;
          'M' :
            MInit := NextS;
          'U' :
            UnloadRFax;
          'R' :
            ResetRFax;
          'D' :
            DisableRFax;
          'I' :
            StatID := GetDelimited;
          'P' :
            FaxPath := NextS;
          'T' :
            InBackground := False;
          'S' :
            begin
              S := NextS;
              case S[1] of
                '1' : FaxClass := ctClass1;
                '2' : FaxClass := ctClass2;
                'A' : FaxClass := ctDetect;
                else ShowHelp;
              end;
            end;
          'Q' :
            Val(NextS, IrqNum, C);
          else
            begin
              WriteLn(^G'Unknown parameter "'+S+'"');
              ShowHelp;
            end;
        end;
      end else begin
        GotC := True;
        case S[1] of
          '1': CName := Com1;
          '2': CName := Com2;
          '3': CName := Com3;
          '4': CName := Com4;
          else ShowHelp;
        end;
      end;
    end;

    if not GotC then
      ShowHelp;
  end;

begin
  {Warn about CAS}
  if CASInstalled then
    Abort('CASMODEM.EXE detected, RFAX is aborting');

  {Process command line arguments}
  ParseCmdLine;

  {Don't install twice}
  if ModuleInstalled(ModuleName) then begin
    WriteLn('RFAX already installed');
    Halt;
  end;

  {$IFDEF Tracing}
  InitTracing(10000);
  {$ENDIF}

  {Open port, fax objects; initalize modem for receive}
  if not OpenPort then
    Halt;
  PrepareFaxModem;

  {Install the module}
  InstallModule(ModuleName, @ExternalIfc);

  {Don't hide mouse during popup}
  SuppressMouseHandling;

  {Setup entry points and go resident}
  if DefinePopProc(RFaxProcHdl, RFaxProc, @PopStack[SizeOf(PopStack)]) then begin
    {Install clock ISR}
    if not InitVector($1C, ClockHandle, @ClockInt) then begin
      WriteLn('Failed to set clock int');
      Halt;
    end;

    Write('RFAX loaded');
    if InBackground then
      WriteLn(', full background operation.')
    else
      WriteLn(', will pop up when fax received.');
    WriteLn('Enter "RFAX /U" to unload, "RFAX /R" to reset modem');

    {Enable popups}
    PopupsOn;

    {Terminate and stay resident}
    if InBackground then
      StayRes(ParagraphsToKeep, 0)
    else
      StayRes(ParagraphsToKeep+200, 0);
  end;

  WriteLn('Failed to load RFAX');
  RestoreVector(ClockHandle);
end.
