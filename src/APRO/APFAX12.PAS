{$A+,F+,I-,R-,S-,V-}

{$I APDEFINE.INC}

{$IFNDEF UseSWFlow}
{$IFNDEF UseHWFlow}
!! STOP COMPILE - this unit requires hardware and/or software flow control
{$ENDIF}
{$ENDIF}

{******************************************************}
{*                   APFAX12.PAS 2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

unit ApFax12;
  {-Class 1/2 FAX send/receive objects}

interface

uses
  Dos,
  Dpmi,
  {$IFDEF UseOPro}
  OpInline,
  OpRoot,
  OpString,
  OpDos,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpInline,
  TpMemChk,
  TpString,
  TpDos,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApFaxCvt,
  ApAbsFax;
  {$ELSE}
  ApMisc,
  ApTimer,
  ApPort,
  ApCom,
  ApFaxCvt,
  ApAbsFax;
  {$ENDIF}

{$I APFAX12.PA0}

implementation

const
  {For calculating minimum bytes per line}
  ScanTimes : array[0..7, Boolean] of Byte = (
    (0,0),    {0}
    (5,5),    {1}
    (10,5),   {2}
    (10,10),  {3}
    (20,10),  {4}
    (20,20),  {5}
    (40,20),  {6}
    (40,40)); {7}

  {!!.01 new}
  {For calculating scan time response in DCS frame}
  ScanTimeResponse : array[0..7, Boolean] of Byte = (
    ($70, $70),
    ($10, $10),
    ($20, $10),
    ($20, $20),
    ($00, $20),
    ($00, $00),
    ($40, $00),
    ($40, $40));
  ZeroScanTime = $70;

  {For managing Class 1 modulations}
  ModArray : array[1..MaxModIndex] of String[3] = (
    '24', '48', '72', '96', '121', '145');

  {For getting MaxFaxBPS from modulation index}
  Class1BPSArray : array[1..MaxModIndex] of Word = (
    2400, 4800, 7200, 9600, 12000, 14400);

{General purpose}

  function RotateByte(Code : Char) : Byte; assembler;
    {-Flip code MSB for LSB}
  asm
    mov dl,Code
    xor ax,ax
    mov cx,8
@1: shr dl,1
    rcl al,1
    loop @1
  end;

{C12AbsData}

  procedure InitC12AbsData(var DP : C12AbsDataPtr; ComPort : PortRecPtr);
    {-Allocate and initialize a C12AbsData record}
  begin
    if not GetMemCheck(DP, SizeOf(C12AbsData)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with DP^ do begin
      if not GetMemCheck(DataBuffer, DataBufferSize) then begin
        SetAsyncStatus(ecOutOfMemory);
        DoneC12AbsData(DP);
        Exit;
      end;

      CPort        := ComPort;
      ToneDial     := True;
      ModemInit    := '';
      DialPrefix   := '';
      DialWait     := DefDialTimeout;
      MaxFaxBPS    := 9600;
      CheckChar    := '0';
      AnswerOnRing := 1;
      CurrOfs      := 0;
      ReplyWait    := DefCmdTimeout;
      TransWait    := DefTransTimeout;
      StatusWait   := DefStatusTimeout;
      Critical     := False;
      FaxAndData   := '0';
      SessionBPS   := 0;
      SessionScan  := 0;
      SessionRes   := False;
      SessionWid   := False;                                           {!!.03}
      SessionECM   := False;
      InitSent     := False;
      SlowBaud     := False;                                           {!!.01}
      InitBaud     := 0;                                               {!!.01}
    end;
  end;

  procedure DoneC12AbsData(var DP : C12AbsDataPtr);
  begin
    with DP^ do begin
      FreeMemCheck(DataBuffer, DataBufferSize);
      FreeMemCheck(DP, SizeOf(C12AbsData));
    end;
  end;

  procedure SetFaxPort(FP : FaxRecPtr; ComPort : PortRecPtr);
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do
      CPort := ComPort;
  end;

  procedure SetModemInit(FP : FaxRecPtr; MIS : String);
    {-set modem init string}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      ModemInit := StUpcase(MIS);
      if (ModemInit <> '') and (ModemInit[1] <> 'A') then
        ModemInit := 'AT'+ModemInit;
    end;
  end;

  function SetClassType(FP : FaxRecPtr; CT : ClassType) : ClassType;
    {-Set type of modem, return detected or set type}
  var
    Class1 : Boolean;
    Class2 : Boolean;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      if CT = ctDetect then begin
        if GetModemClassSupport(FP, Class1, Class2, False) then begin
          if Class2 then
            ClassInUse := ctClass2
          else if Class1 then
            ClassInUse := ctClass1
          else
            ClassInUse := ctUnknown;
        end else
          ClassInUse := ctUnknown;
      end else
        ClassInUse := CT;

      SetClassType := ClassInUse;
    end;
  end;

  {!!.01 new}
  procedure caSwitchBaud(FP : FaxRecPtr; High : Boolean);
    {-Switch baud rates}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      if High then begin
        {Switch to the high normal baud rate}
        if (InitBaud <> 0) and SlowBaud then begin
          Delay(BaudChangeDelay);
          ChangeBaud(CPort, NormalBaud);
          SlowBaud := False;
        end;
      end else begin
        {Switch to low initialization baud rate}
        if (InitBaud <> 0) and not SlowBaud then begin
          Delay(BaudChangeDelay);
          ChangeBaud(CPort, InitBaud);
          SlowBaud := True;
        end;
      end;
    end;
  end;

  {!!.01 new}
  procedure SetInitBaudRate(FP : FaxRecPtr; InitRate, NormalRate : LongInt);
    {-Set baud rate to use when initializing modem}
  var
    Parity : ParityType;
    DataBits : DataBitType;
    StopBits : StopBitType;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      InitBaud := InitRate;
      if NormalRate = 0 then
        GetLine(CPort, NormalBaud, Parity, DataBits, StopBits, False)
      else
        NormalBaud := NormalRate;

      {Start in low baud}                                              {!!.02}
      caSwitchBaud(FP, False);                                         {!!.02}
    end;
  end;

  function afHandleAbort(FP : FaxRecPtr) : Boolean;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      if CPort^.UserAbort then begin
        GotError(CPort, ecUserAbort);                                  {!!.02}
        afHandleAbort := True;
      end else
        afHandleAbort := False;
    end;
  end;

  function LocatePage(FP : FaxRecPtr; PgNo : Word) : Integer;
  var
    W : Word;
    L : LongInt;
    Result : Word;
    P : PageHeaderRec;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      LocatePage := ecDiskRead;                                        {!!.02}

      {validate number}
      if (PgNo = 0) or (PgNo > FaxHeader.PageCount) then
        Exit;

      {start at head of file and walk the list of pages}
      Seek(InFile, FaxHeader.PageOfs);
      Result := IOResult;
      if Result <> 0 then begin
        LocatePage := Result;
        Exit;
      end;

      if PgNo > 1 then begin
        for W := 1 to (PgNo-1) do begin
          BlockRead(InFile, P, SizeOf(P));
          Result := IOResult;
          if Result <> 0 then begin
            LocatePage := Result;
            Exit;
          end;
          L := FilePos(InFile);
          Inc(L, P.ImgLength);

          Seek(InFile, L);
          Result := IoResult;
          if Result <> ecOk then begin                                 {!!.02}
            LocatePage := Result;                                      {!!.02}
            Exit;                                                      {!!.02}
          end;                                                         {!!.02}
        end;
      end;

      LocatePage := Result;
    end;
  end;

  function caOkResponse(FP : FaxRecPtr) : Boolean;
    {-Return True if Response contains OK}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      caOkResponse := Pos('OK', Response) > 0;
  end;

  function caConnectResponse(FP : FaxRecPtr) : Boolean;
    {-Return True if Response contains CONNECT}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      caConnectResponse := Pos('CONNECT', Response) > 0;
  end;

  function caNoCarrierResponse(FP : FaxRecPtr) : Boolean;
    {-Return True if Response contains NO CARRIER}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      caNoCarrierResponse := Pos('CARRIER', Response) > 0;
  end;

  function caErrorResponse(FP : FaxRecPtr) : Boolean;
    {-Return True if Response contains ERROR}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      caErrorResponse := Pos('ERROR', Response) > 0;
  end;

  function caFHNGResponse(FP : FaxRecPtr) : Boolean;
    {-Return True if Response contains FHNG}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      caFHNGResponse := Pos('FHNG', Response) > 0;
  end;

  function caExtractFHNGCode(FP : FaxRecPtr) : Word;
    {-Return numeric FHNG response}
  var
    S : String[20];
    W : Word;
    I : Byte;
    Code : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      I := Pos(':', Response);
      if I <> 0 then begin
        S := Copy(Response, I+1, 3);
        S := Trim(S);
        W := 0;
        Val(S, W, Code);
        caExtractFHNGCode := W;
      end else
        caExtractFHNGCode := 0;
    end;
  end;

  function caAddReceivedCmd(FP : FaxRecPtr; var S : String) : Boolean;
    {-if char(s) pending, add to command string; return True if complete
      response has been assembled}
  var
    C : Char;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      caAddReceivedCmd := False;
      SetAsyncStatus(ecOK);
      while CharReady(CPort) do begin
        GetChar(CPort, C);
        if C = #13 then begin
          if S <> '' then begin
            caAddReceivedCmd := True;
            Exit;
          end;
        end else if C >= #32 then
          Merge(S, C);
      end;
    end;
  end;

  procedure caPrepResponse(FP : FaxRecPtr);
    {-Prepare to receive/parse a new modem response}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Response := '';
      CRLFIndex := 0;
      ETXIndex := 0;
      CollectResponse := True;
      NewTimer(ReplyTimer, ReplyWait);
    end;
  end;

  procedure caPutModemSlow(FP : FaxRecPtr; S : String);
    {-Send a modem command and prepare to wait for a response}
  var
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      for I := 1 to Length(S) do begin
        Delay(InterCharDelay);
        PutChar(CPort, S[I]);
      end;
    end;
  end;

  procedure caPutModem(FP : FaxRecPtr; S : String);
    {-Send a modem command and prepare to wait for a response}
  var
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Delay(PreCommandDelay);
      caPutModemSlow(FP, S+^M);
      caPrepResponse(FP);
    end;
  end;

  procedure caPutFaxCommand(FP : FaxRecPtr; S : String);
    {-Send FTM/FRM modem command}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Delay(PreFaxDelay);
      caPutModemSlow(FP, S+^M);
      caPrepResponse(FP);
    end;
  end;

  procedure caPutFrameR(FP : FaxRecPtr);
    {-Send FRH=3 modem command}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Delay(PreFaxDelay);
      caPutModemSlow(FP, 'AT+FRH=3'^M);
      caPrepResponse(FP);
    end;
  end;

  procedure caPutFrameT(FP : FaxRecPtr);
    {-Send FTH=3 modem command}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Delay(PreFaxDelay);
      caPutModemSlow(FP, 'AT+FTH=3'^M);
      caPrepResponse(FP);
    end;
  end;

  function caProcessModemCmd(FP : FaxRecPtr; S : String) : Boolean;
  var
    C : Char;
    OkString : String;
    Finished : Boolean;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Send the command}
      caProcessModemCmd := False;
      caPutModem(FP, S);

      repeat
        {Collect the reponse}
        Finished := False;
        Response := '';
        repeat
          Finished := caAddReceivedCmd(FP, Response);
        until Finished or WaitComplete(CPort, ReplyTimer);
        if (GetAsyncStatus <> ecOk) then
          Exit;
      until (Response <> '');

      {Check for errors}
      if not caErrorResponse(FP) then begin
        {Collect and discard the OK if above response was data}
        if Pos('OK', Response) = 0 then begin
          OkString := '';
          Finished := False;
          repeat
            Finished := caAddReceivedCmd(FP, OkString);
          until Finished or WaitComplete(CPort, ReplyTimer);
          if GetAsyncStatus = ecUserAbort then
            Exit;
        end;
        caProcessModemCmd := True
      end else begin
        caProcessModemCmd := False;
        SetAsyncStatus(ecError);
      end;
    end;
  end;

  procedure caFlushModem(FP : FaxRecPtr);
    {-"Flush" modem for init}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {"reset" modem}
      FlushInBuffer(CPort);
      FlushOutBuffer(CPort);
      SetModem(CPort, False, False);
      Delay(FlushWait);
      SetModem(CPort, True, True);
      Delay(FlushWait);
    end;
  end;

  function GetModemClassSupport(FP : FaxRecPtr;
                                var Class1, Class2 : Boolean;
                                Reset : Boolean) : Boolean;
  var
    LC, C : Integer;
    Tmp : Str20;
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      {assume failure}
      GetModemClassSupport := False;

      {get class to init}
      Class1 := False;
      Class2 := False;

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      if Reset then begin
        LC := 0;
        repeat
          caFlushModem(FP);

          Inc(LC);
          if (LC > 2) or not caProcessModemCmd(FP, DefInit) then
            Exit;
        until caOkResponse(FP);
      end;

      if not caProcessModemCmd(FP, 'AT+FCLASS=?') then
        Exit;
      StripPrefix(Response);
      Class1 := Pos('1', Response) > 0;
      Class2 := Pos('2', Response) > 0;

      GetModemClassSupport := True;
    end;
  end;

  {!!.02 new}
  function GetModemClassSupportEx(FP : FaxRecPtr;
                                  var Class1, Class2, Class2_0 : Boolean;
                                  Reset : Boolean) : Boolean;
  var
    LC, C : Integer;
    Tmp : Str20;
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      {Assume failure}
      GetModemClassSupportEx := False;
      Class1 := False;
      Class2 := False;
      Class2_0 := False;

      {Reset the modem}
      if Reset then begin
        LC := 0;
        repeat
          caFlushModem(FP);

          Inc(LC);
          if (LC > 2) or not caProcessModemCmd(FP, DefInit) then
            Exit;
        until caOkResponse(FP);
      end;

      {Ask the modem...}
      if not caProcessModemCmd(FP, 'AT+FCLASS=?') then
        Exit;
      StripPrefix(Response);

      {...see what it said}
      Class1 := Pos('1', Response) > 0;
      if Pos('2.0', Response) > 0 then begin
        Class2_0 := True;
        Class2 := Pos('2,', Response) > 0;
      end else
        Class2 := Pos('2', Response) > 0;

      GetModemClassSupportEx := True;
    end;
  end;

  function GetModemInfo(FP : FaxRecPtr; var Class : Char;
                        var Model, Chip, Rev : String;
                        Reset : Boolean) : Boolean;
  var
    C1, C2, C2_0 : Boolean;                                            {!!.02}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      {assume failure}
      GetModemInfo := False;

      {Get class to init}
      Class := '0';
      Model := '';
      Chip  := '';
      Rev   := '';

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      if Reset then begin
        caFlushModem(FP);

        if (ModemInit <> '') and (not caProcessModemCmd(FP, ModemInit)) then
          Exit;

        if not caProcessModemCmd(FP, DefInit) then
          Exit;
      end;
      InitSent := True;

      if not GetModemClassSupportEx(FP, C1, C2, C2_0, False) then      {!!.02}
        Exit;

      if C2_0 then                                                     {!!.02}
        Class := 'B'                                                   {!!.02}
      else if C2 then                                                  {!!.02}
        Class := '2'
      else if C1 then
        Class := '1'
      else
        Exit;

      if caProcessModemCmd(FP, 'AT+FMDL?') then begin
        StripPrefix(Response);
        Model := Response;
      end;

      if caProcessModemCmd(FP, 'AT+FMFR?') then begin
        StripPrefix(Response);
        Chip := Response;
      end;

      if caProcessModemCmd(FP, 'AT+FREV?') then begin
        StripPrefix(Response);
        Rev := Response;
      end;

      SetAsyncStatus(ecOk);                                            {!!.02}
      GetModemInfo := True;
    end;
  end;

  procedure GetModemFeatures(FP : FaxRecPtr; var BPS : LongInt;
                             var Correction : Char);
    {-Return highest possible codes}
  var
    C : Char;
    BitChar : Char;
    Finished : Boolean;
    C1, C2 : Boolean;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      BPS := 0;
      Correction := '0';

      {Assure we're a class 2 modem first}
      if ClassInUse <> ctClass2 then
        Exit;

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      {Test bit rates}
      C := '5';
      Finished := False;
      repeat
        if caProcessModemCmd(FP, 'AT+FDIS=0,'+C+',0,0,0,0,0,3') and
           caOkResponse(FP) then begin
          BitChar := C;
          Finished := True;
        end;
        Dec(Byte(C));
        if (C = '1') and not Finished then begin
          BitChar := C;
          Finished := True;
        end;
      until Finished;
      case BitChar of
        '0' : BPS := 2400;
        '1' : BPS := 4800;
        '2' : BPS := 7200;
        '3' : BPS := 9600;
        '4' : BPS := 12000;
        '5' : BPS := 14400;
      end;

      {Test error correction}
      {Finished := False;}                                             {!!.03}
      if caProcessModemCmd(FP, 'AT+FDIS=0,0,0,0,0,1,0,3') and
         caOkResponse(FP) then
        Correction := '1'
      else begin                                                       {!!.03}
        Correction := '0';
        SetAsyncStatus(ecOK);                                          {!!.03}
      end;                                                             {!!.03}
    end;
  end;

  procedure SetModemFeatures(FP : FaxRecPtr; BPS : LongInt;
                             Correction : Char);
    {-Set modem features for this session}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      MaxFaxBPS := BPS;
      CheckChar := Correction;
    end;
  end;

  function caSpeedCode(FP : FaxRecPtr) : Char;
    {-returns char code for speed}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      case MaxFaxBPS of
        2400 : caSpeedCode := '0';
        4800 : caSpeedCode := '1';
        7200 : caSpeedCode := '2';
        12000: caSpeedCode := '4';
        14400: caSpeedCode := '5';
        else   caSpeedCode := '3';
      end;
    end;
  end;

  procedure GetPageInfoC12(FP : FaxRecPtr;
                           var Pages : Word;
                           var Page : Word;
                           var BytesTransferred : LongInt;
                           var PageLength : LongInt);
  var
    OutBuf : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      if Sending then begin
        {Transmit data}
        Pages := FaxHeader.PageCount;
        if SendingCover then
          Page := 0
        else
          Page := CurrPage;
        OutBuf := OutBuffUsed(CPort);
        if OutBuf = 1 then
          OutBuf := 0;
        BytesTransferred := DataCount - OutBuf;
        if BytesTransferred < 0 then
          BytesTransferred := 0;
        PageLength := PageSize;
      end else begin
        Pages := 0;
        Page := CurrPage;
        BytesTransferred := DataCount;
        PageLength := 0;
      end;
    end;
  end;

  function GetLastPageStatus(FP : FaxRecPtr) : Boolean;
    {-Return True if last page received OK, false otherwise}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      GetLastPageStatus := LastPageOk;
  end;

  function GetRemoteID(FP : FaxRecPtr) : Str20;
    {-Return remote station ID}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      GetRemoteID := PData^.RemoteID;
  end;

  procedure GetSessionParams(FP : FaxRecPtr;
                             var BPS : LongInt;
                             var Resolution : Boolean;
                             var Correction : Boolean);
    {-Return remote or session parameters}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      BPS := SessionBPS;
      Resolution := SessionRes;
      Correction := SessionECM;
    end;
  end;

  function GetHangupResult(FP : FaxRecPtr) : Word;
    {-Return last hangup result, class 2 only}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      GetHangupResult := HangupCode;
  end;

  procedure caCalcMinBytesPerLine(FP : FaxRecPtr);
    {-Calculate minimum byte per line}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do
      MinBytes := ((SessionBPS * ScanTimes[SessionScan, SessionRes]) div 8000);
  end;

  procedure caExtractClass1Params(FP : FaxRecPtr; DIS : Boolean; B2, B3 : Byte);
    {-Extract bps, res, ecm from 2nd byte of DCS/DIS}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      FillChar(RmtMods, SizeOf(RmtMods), False);
      RmtMods[1] := True;
      RmtMods[2] := True;

      if DIS then begin
        RmtMods[6] := B2 and $20 = $20;
        RmtMods[5] := B2 and $10 = $10;
        case B2 and $0C of
          $04 : RmtMods[4] := True;
          $0C : begin
                  RmtMods[3] := True;
                  RmtMods[4] := True;
                end;
        end;

        {Set SessionBPS from lowest common btween local and remote capabilities}
        {and less than or equal to MaxFaxBPS}
        BPSIndex := MaxModIndex+1;
        repeat
          Dec(BPSIndex);
        until (LocalMods[BPsIndex] and RmtMods[BPSIndex]) and
              (Class1BPSArray[BPSIndex] <= MaxFaxBPS);
        SessionBPS := Class1BPSArray[BPSIndex];

      end else begin
        if B2 and $20 = $20 then
          BPSIndex := 6                                                {!!.02}
        else if B2 and $10 = $10 then
          BPSIndex := 5                                                {!!.02}
        else begin
          case B2 and $0C of
            $00 : BPSIndex := 1;
            $08 : BPSIndex := 2;
            $04 : BPSIndex := 4;
            else  BPSIndex := 3;
          end;
        end;
        SessionBPS := Class1BPSArray[BPSIndex];
      end;

      {Set resolution and error correction}
      if DIS then                                                      {!!.01}
        SessionRes := ResC = '1'                                       {!!.01}
      else                                                             {!!.01}
        SessionRes := B2 and $40 = $40;

      {!!.03 - Added}
      if DIS then
        SessionWid := PageHeader.ImgFlags and ffHighWidth <> 0
      else
        SessionWid := B3 and $03 = $01;

      SessionECM := False;

      {!!.03 - added}
      if DIS then begin
        CanDoHighRes := B2 and $40 = $40;
        CanDoHighWid := B3 and $03 = $01;
      end;

      {Set scan times}
      case B3 and $70 of
        $70 : SessionScan := 0;   {0,0}
        $10 : SessionScan := 1;   {5,5}
        $60 : SessionScan := 2;   {10,5}
        $20 : SessionScan := 3;   {10,10}
        $30 : SessionScan := 4;   {20,10}
        $00 : SessionScan := 5;   {20,20}
        $50 : SessionScan := 6;   {40,20}
        $40 : SessionScan := 7;   {40,40}
      end;
      caCalcMinBytesPerLine(FP);
    end;
  end;

  procedure ExtractClass2Params(FP : FaxRecPtr; S : String);
    {-Extract bps, res, ecm from S, as data from FDCS/FDIS}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      case S[3] of
        '0': SessionBPS := 2400;
        '1': SessionBPS := 4800;
        '2': SessionBPS := 7200;
        '4': SessionBPS := 12000;
        '5': SessionBPS := 14400;
        else SessionBPS := 9600;
      end;

      SessionRes   := S[1] = '1';
      CanDoHighRes := SessionRes;   {!!.03}
      SessionWid   := S[5] = '1';   {!!.03}
      CanDoHighWid := SessionWid;   {!!.03}

      case Response[11] of
        '1', '2' : SessionECM := True;
        else       SessionECM := False;
      end;

      SessionScan := Ord(Response[15])-$30;

      caCalcMinBytesPerLine(FP);
    end;
  end;

  function ModulationCode(FP : FaxRecPtr; B : Byte) : String;
    {-Returns highest modulation string from 2nd byte of DCS/DIS}
  begin
    with C12FaxRecPtr(FP)^, CData^ do begin
      if B and $20 = $20 then
        ModulationCode := '145'
      else if B and $10 = $10 then
        ModulationCode := '121'
      else begin
        case B and $0C of
          $00 : ModulationCode := '24';
          $08 : ModulationCode := '48';
          $04 : ModulationCode := '96';
          $0C : ModulationCode := '72';
        end;
      end;
    end;
  end;

  function caNextBPS(FP : FaxRecPtr) : Boolean;
    {-Return next lower BPS, False if at 2400}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      repeat
        Dec(BPSIndex);
      until (BPSIndex = 0) or (LocalMods[BPSIndex] and RmtMods[BPSIndex]);
      caNextBPS := BPSIndex <> 0;
      if BPSIndex <> 0 then                                            {!!.03}
        SessionBPS := Class1BPSArray[BPSIndex];                        {!!.03}
      caCalcMinBytesPerLine(FP);
    end;
  end;

  procedure caGetClass1Modulations(FP : FaxRecPtr; Transmit : Boolean);
    {-Get this faxmodem's transmit/receive modulation capabilities}
  var
    Finished : Boolean;
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Set defaults}
      FillChar(LocalMods, SizeOf(LocalMods), False);
      LocalMods[1] := True;
      LocalMods[2] := True;
      BPSIndex := 1;                                                   {!!.03}

      if Transmit then
        caPutModem(FP, 'AT+FTM=?')
      else
        caPutModem(FP, 'AT+FRM=?');
      NewTimer(ReplyTimer, ReplyWait);
      repeat

        {Collect the response}
        Finished := False;
        Response := '';
        repeat
          Finished := caAddReceivedCmd(FP, Response);
        until Finished or WaitComplete(CPort, ReplyTimer);

        {If this is a modulation response string, parse it}
        if Pos(',', Response) <> 0 then begin                          {!!.02}
          for I := 3 to 6 do
            LocalMods[I] := Pos(ModArray[I], Response) <> 0;

          {Note highest mod}
          BPSIndex := MaxModIndex;
          while not LocalMods[BPSIndex] do
            Dec(BPSIndex);
        end;

        {!!.01 rewritten}
        {Wait briefly for OK}
        if GetAsyncStatus = ecTimeout then begin
          SetAsyncStatus(ecOk);
          Finished := True;
        end else begin
          NewTimer(ReplyTimer, 36);
          Finished := caOkResponse(FP) or caErrorResponse(FP);
        end;
      until Finished or WaitComplete(CPort, ReplyTimer);
    end;
  end;

  procedure caHDLCStart(FP : FaxRecPtr; Last : Boolean);
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Delay(FrameWait);
      PutChar(CPort, AddrField);
      if Last then
        PutChar(CPort, ControlFieldLast)
      else
        PutChar(CPort, ControlField);
    end;
  end;

  procedure caHDCLEnd(FP : FaxRecPtr);
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      PutChar(CPort, cDLE);
      PutChar(CPort, cETX);
    end;
  end;

  procedure caPutStandardFrame(FP : FaxRecPtr; Frame : Byte);
    {-Transmit an standard frame of type Frame}
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Send HDLC address and control fields}
      caHDLCStart(FP, True);

      {Send fax control field, EOP format}
      PutChar(CPort, Char(Frame));

      {Send message terminator}
      caHDCLEnd(FP);
    end;
  end;

  procedure caPutTSIFrame(FP : FaxRecPtr);
    {-Transmit a TSI frame}
  var
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Send HDLC address and control fields}
      caHDLCStart(FP, False);

      {Send fax control field, TSI format}
      PutChar(CPort, Char(TSIFrame or $01));

      {Send TSI data}
      for I := 19 downto Length(StationID) do
        PutChar(CPort, ' ');
      for I := Length(StationID) downto 1 do
        PutChar(CPort, Char(StationID[I]));

      {Send message terminator}
      caHDCLEnd(FP);
    end;
  end;

  procedure caPutDCSDISFrame(FP : FaxRecPtr; UseDIS : Boolean);
    {-Transmit a DCS or DIS frame}
  var
    B : Byte;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Send HDLC address and control fields}
      caHDLCStart(FP, True);

      {Send fax control field, DCS format}
      if UseDIS then
        PutChar(CPort, Char(DISFrame))
      else
        PutChar(CPort, Char(DCSFrame or $01));

      {Send DCS/DIS data, first byte is static}
      PutChar(CPort, Char(DISGroup1));

      {Second byte contains resolution and BPS info}
      B := DISGroup3_1;

      {Can receive at high resolution, set when transmitting high res} {!!.01}
      if UseDIS  or (ResC = '1') then                                  {!!.01}
        B := B or DISHighResolution;

      if UseDIS then begin
        case BPSIndex of
          6 :  B := B or DIS9600BPS or DIS14400BPS;
          5 :  B := B or DIS9600BPS or DIS12000BPS;
          3 :  B := B or DIS7200BPS;
          2 :  B := B or DIS4800BPS;
          1 :  B := B or DIS2400BPS;
          else B := B or DIS7200BPS
        end;
      end else begin
        case BPSIndex of
          6 :  B := B or DIS14400BPS;
          5 :  B := B or DIS12000BPS;
          3 :  B := B or DIS7200BPS;
          2 :  B := B or DIS4800BPS;
          1 :  B := B or DIS2400BPS;
          else B := B or DIS9600BPS;
        end;
      end;
      PutChar(CPort, Char(B));

      {Note modulation code for training and message transmission}
      if not UseDIS then
        ModCode := ModArray[BPSIndex];

      {Third byte}                                                     {!!.01}
      if UseDIS then                                                   {!!.01}
        B := DISGroup3_2 or ZeroScanTime                               {!!.01}
      else                                                             {!!.01}
        B := DISGroup3_2 or ScanTimeResponse[SessionScan, SessionRes]; {!!.01}

      if UseDIS or ((PageHeader.ImgFlags and ffHighWidth) <> 0) then   {!!.03}
        B := B or DISWideWidth;                                        {!!.03}

      PutChar(CPort, Char(B));                                         {!!.01}

      {Last byte is static}
      PutChar(CPort, Char(DISGroup3_3));

      {Send message terminator}
      caHDCLEnd(FP);
    end;
  end;

  procedure caPutCSIFrame(FP : FaxRecPtr);
    {-Transmit a CSI frame}
  var
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Send HDLC address and control fields}
      caHDLCStart(FP, False);

      {Send fax control field, CSI format}
      PutChar(CPort, Char(CSIFrame));

      {Send CSI data}
      for I := 19 downto Length(StationID) do
        PutChar(CPort, ' ');
      for I := Length(StationID) downto 1 do
        PutChar(CPort, Char(StationID[I]));

      {Send message terminator}
      caHDCLEnd(FP);
    end;
  end;

  procedure caPutTCFData(FP : FaxRecPtr);
    {-Put zeros for 1.5 seconds}
  var
    Required : Word;
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      {Assumes free space is available}

      Required := 17 * (MaxFaxBPS div 100);
      for I := 1 to Required do
        PutChar(CPort, #0);

      caHDCLEnd(FP);
    end;
  end;

  function ProcessFrame(FP : FaxRecPtr; var Retrain : Boolean) : Boolean;
    {-Process the frame in Response}
  var
    I : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Retrain := False;

      {Discard till flag byte}
      while (Response[1] <> #255) and (Length(Response) > 1) do
        Delete(Response, 1, 1);

      {If last frame, return True}
      ProcessFrame := Byte(Response[2]) and $10 = $10;

      ReceivedFrame := Ord(Response[3]);

      {Process frame}
      case (ReceivedFrame and $FE )of
        TSIFrame,
        CSIFrame :
          begin
            {Extract remote station ID}
            for I := 1 to 20 do
              RemoteID[I] := Response[24-I];
            RemoteID[0] := #20;
            FaxProgress := fpGotRemoteID;
            ForceStatus := True;
          end;
        DISFrame :
          begin
            {Extract session parameters}
            caExtractClass1Params(FP, True, Ord(Response[5]), Ord(Response[6]));

            {!!.03 - Added}
            if (not CanDoHighRes and ((PageHeader.ImgFlags and ffHighRes  ) <> 0)) or
               (not CanDoHighWid and ((PageHeader.ImgFlags and ffHighWidth) <> 0)) then
              SetAsyncStatus(ecIncompatibleMachine)
            else begin
              {!!.03 - Moved to new else clause}
              FaxProgress := fpSessionParams;
              ForceStatus := True;
            end;
          end;
        DCSFrame :
          begin
            {Extract session parameters}
            caExtractClass1Params(FP, False, Ord(Response[5]), Ord(Response[6]));

            {Set modulation code}
            ModCode := ModArray[BPSIndex];

            FaxProgress := fpSessionParams;
            ForceStatus := True;
          end;
        CFRFrame :
          GotCFR := True;                                              {!!.02}
        NSFFrame :
          {Nothing to do for NSF frames} ;
        RTNFrame,
        FTTFrame :
          Retrain := True;
        DCNFrame :                                                     {!!.01}
          {Unexpected disconnect request}                              {!!.01}
          SetAsyncStatus(ecCancelRequested);                           {!!.01}
      end;
      caPrepResponse(FP);
    end;
  end;


{C12SendFax}

  procedure InitC12SendFax(var FP : FaxRecPtr; ID : Str20;
                           ComPort : PortRecPtr);
  begin
    if not GetMemCheck(FP, SizeOf(C12SendFax)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with C12SendFaxPtr(FP)^ do begin
      Converter := nil;
      InitC12AbsData(CData, ComPort);
      if CData = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        DoneC12SendFax(FP);
        Exit;
      end;
      InitFaxData(PData, ID);
      if PData = nil then begin
        DoneC12SendFax(FP);
        Exit;
      end;
      CvrOpen := False;                                                {!!.02}
    end;

    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      InitAbsConverter(Converter);
      if Converter = nil then begin
        SetAsyncStatus(ecOk);
        DoneC12SendFax(FP);
        Exit;
      end;

      RemoteID     := '';
      InFileName  := '';
      HeaderLine  := '';
      Title := '';
      Sender := '';
      Recipient := '';
      MaxRetries  := DefMaxRetries;
      DataCount   := 0;
      PageSize     := 0;
      Sending := True;
    end;
  end;

  procedure DoneC12SendFax(var FP : FaxRecPtr);
  begin
    with C12SendFaxPtr(FP)^ do begin
      DoneFaxData(PData);
      if Converter <> nil then
        DoneAbsConverter(Converter);
      DoneC12AbsData(CData);
      FreeMemCheck(FP, SizeOf(C12SendFax));
    end;
  end;

  procedure SetHeaderText(FP : FaxRecPtr; S : String);
    {-set HeaderLine to S}
  begin
    with C12SendFaxPtr(FP)^ do
      HeaderLine := S;
  end;

  procedure SetToneDial(FP : FaxRecPtr; Tone : Boolean);
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      ToneDial := Tone;
  end;

  procedure SetDialPrefix(FP : FaxRecPtr; P : String);
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      DialPrefix := P;
  end;

  procedure SetDialTime(FP : FaxRecPtr; DT : Integer);
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      DialWait := DT;
  end;

  procedure csSendWhiteRasterLines(FP : FaxRecPtr; Count : Word);
    {-Send white raster lines to create a phsyical top margin}
  const
    WhiteLine = #$00#$80#$B2'Y'#$01#$00;
  var
    I, J : Word;
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      for I := 1 to Count do begin
        PutString(CPort, WhiteLine);
        for J := Length(WhiteLine) to MinBytes do
          PutChar(CPort, #0);
      end;
    end;
  end;

  procedure SetMaxRetries(FP : FaxRecPtr; MR : Integer);
    {-set MaxRetries to MR}
  begin
    with C12SendFaxPtr(FP)^ do
      MaxRetries := MR;
  end;

  procedure csPutBuffer(FP : FaxRecPtr; var Buffer; Len : Word);
  type
    BA = Array[1..$FFF0] of Char;
  var
    I : Word;
    C : Char;
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      for I := 1 to Len do begin

        {Quote and send char}
        if BA(Buffer)[I] = cDLE then
          PutChar(CPort, cDLE);

        PutChar(CPort, BA(Buffer)[I]);
      end;
    end;
  end;

  procedure csPutLineBuffer(FP : FaxRecPtr; var Buffer; Len : Word);
    {Buffer has <lengthword><data> raster lines}
  type
    BA = Array[1..$FFF0] of Char;
  var
    I : Word;
    Index : Word;
    LineLen : Word;
  begin
    with C12FaxRecPtr(FP)^, CData^, PData^ do begin
      Index := 1;
      repeat

        {Get and transmit one raster line}
        LineLen := Ord(BA(Buffer)[Index]);
        LineLen := LineLen + (Ord(BA(Buffer)[Index+1]) shl 8);
        Inc(Index, 2);
        for I := Index to (Index+LineLen-1) do begin
          {Quote and send char}
          if BA(Buffer)[I] = cDLE then
            PutChar(CPort, cDLE);
          PutChar(CPort, BA(Buffer)[I]);
        end;

        {Assure line has minimum number of bytes}
        if LineLen < MinBytes then begin
          for I := 1 to (MinBytes-LineLen) do
            PutChar(CPort, #0);
          Inc(DataCount, MinBytes);
        end else
          Inc(DataCount, LineLen);

        Inc(Index, LineLen);
      until (Index >= Len);
    end;
  end;

  function csOpenFaxFile(FP : FaxRecPtr; Document : PathStr) : Word;
  var
    W : Word;
    S : String[6];
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      InFileName := ForceExtension(Document, FaxFileExt);
      SaveMode := FileMode;                                            {!!.02}
      FileMode := $40;                                                 {!!.02}
      Assign(InFile, InFileName);
      Reset(InFile, 1);
      FileMode := SaveMode;                                            {!!.02}
      W := IOResult;
      if W <> 0 then begin
        csOpenFaxFile := W;
        Exit;
      end;

      BlockRead(InFile, FaxHeader, SizeOf(FaxHeaderRec));
      W := IOResult;
      if W <> 0 then begin
        Close(InFile);
        if IOResult = 0 then ;
        csOpenFaxFile := W;
        Exit;
      end;

      Move(FaxHeader, S[1], 6);
      S[0] := #6;
      if S <> DefSig then begin
        csOpenFaxFile := ecFaxBadFormat;
        Close(InFile);
        if IoResult <> 0 then ;
      end else
        csOpenFaxFile := ecOK;
    end;
  end;

  function csAdvancePage(FP : FaxRecPtr) : Boolean;
    {-Advance CurrPage and read new page, return False on any error}
  var
    Result : Word;
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      {Assume failure}
      csAdvancePage := False;

      {Set page number}
      if SendingCover then begin
        if CoverIsAPF then begin
          Close(InFile);
          SetAsyncStatus(csOpenFaxFile(FP, FaxFileName));              {!!.03}
          if GetAsyncStatus <> ecOK then begin
            GotError(CPort, GetAsyncStatus);
            Exit;
          end;
        end else begin
          Close(CvrF);
          if IoResult <> 0 then ;
          CvrOpen := False;                                            {!!.02}
        end;
        SendingCover := False;
        CoverFile := '';
      end else begin                                                   {!!.01}
        Inc(CurrPage);
        DataCount := 0;                                                {!!.01}
      end;                                                             {!!.01}

      {Seek to page}
      SetAsyncStatus(LocatePage(FP, CurrPage));                        {!!.02}
      if GetAsyncStatus <> ecOK then begin                             {!!.02}
        GotError(CPort, GetAsyncStatus);                               {!!.02}
        Exit;                                                          {!!.02}
      end;                                                             {!!.02}

      {Read in the page header}
      BlockRead(InFile, PageHeader, SizeOf(PageHeaderRec));
      UseLengthWord := FlagIsSet(PageHeader.ImgFlags, ffLengthWords);
      SetAsyncStatus(IOResult);
      if GetAsyncStatus <> ecOk then begin
        GotError(CPort, GetAsyncStatus);
        Exit;
      end;

      {Build FDIS command params}
      if (PageHeader.ImgFlags and ffHighRes) <> 0 then
        ResC := '1'
      else
        ResC := '0';

      csAdvancePage := True;
    end;
  end;

  {!!.03}
  function csOpenCoverPage(FP : FaxRecPtr) : Boolean;
    {-Open the cover file}
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      csOpenCoverPage := False;
      if CoverIsAPF then begin
        {Open as an APF file}
        Close(InFile);
        if IOResult <> 0 then ;
        SetAsyncStatus(csOpenFaxFile(FP, CoverFile));
        if GetAsyncStatus <> ecOk then begin
          GotError(CPort, GetAsyncStatus);
          Exit;
        end;

        {Goto the first page}
        SetAsyncStatus(LocatePage(FP, 1));
        if GetAsyncStatus <> ecOk then begin
          GotError(CPort, GetAsyncStatus);
          Exit;
        end;

        {Read in the page header}
        BlockRead(InFile, PageHeader, SizeOf(PageHeaderRec));
        UseLengthWord := FlagIsSet(PageHeader.ImgFlags, ffLengthWords);
        SetAsyncStatus(IOResult);
        if GetAsyncStatus <> ecOk then begin
          GotError(CPort, GetAsyncStatus);
          Exit;
        end;

      end else begin
        {Open as text file}
        SaveMode := FileMode;
        FileMode := $40;
        Assign(CvrF, CoverFile);
        Reset(CvrF);
        FileMode := SaveMode;
        SetAsyncStatus(IoResult);
        if GetAsyncStatus <> 0 then begin
          GotError(CPort, GetAsyncStatus);
          Exit;
        end else begin
          CvrOpen := True;
          {Select font for cover page text}
          if not LoadFont(Converter, StandardFont, (ResC = '1')) then begin
            GotError(CPort, ecFaxNoFontFile);
            Exit;
          end;
        end;
      end;

      {Success}
      csOpenCoverPage := True;
    end;
  end;

  function FaxTransmitPartC12(FP : FaxRecPtr) : FaxStateType;
  label
    ExitPoint;
  const
    OldState : SendStates = tfDone;
  var
    Finished : Boolean;
    GotResponse : Boolean;
    Retrain : Boolean;
    C : Char;
    FaxWid : Char;  {!!.03}
    Result : Word;
    I : Word;
    Count : Word;
    S : String;

    procedure CheckResponse;
      {-Check for text responses, check for and process HDLC frames}
    begin
      with C12SendFaxPtr(FP)^, CData^, PData^ do begin
        {Collect chars till CR/LF or DLE/ETX}
        Finished := False;
        GotResponse := False;
        while CharReady(CPort) and not Finished do begin
          GetChar(CPort, C);
          Response := Response + C;
          if CheckForString(CRLFIndex, C, ^M^J, False) then begin
            Response := Trim(Response);
            if Response <> '' then begin
              {Got a text response}
              Finished := True;
              GotResponse := True;

              {Most error responses are aborts}
              if caErrorResponse(FP) then begin
                case State of
                  tf1WaitEOP,                                          {!!.02}
                  tf1WaitMCF,                                          {!!.02}
                  tf1SendEOP : {Let state machine handle}
                  else begin
                    {It's an error}
                    GotError(CPort, ecUnknownModemResult);
                    State := tfAbort;
                  end;
                end;
              end else if caFHNGResponse(FP) and (State <> tf2WaitFET) then begin
                {Unexpected FHNGs are also aborts}
                GotError(CPort, ecFaxSessionError);
                HangupCode := caExtractFHNGCode(FP);
                State := tfAbort;
              end;
            end;
          end else if CheckForString(EtxIndex, C, #16#3, False) then begin
            {An HDLC frame, process it now}
            LastFrame := ProcessFrame(FP, Retrain);

            {Abort if we got a DCN frame - or if machine does not have the}
            {capability to receive the document we're sending}
            if (GetAsyncStatus = ecCancelRequested) or                 {!!.03}
               (GetAsyncStatus = ecIncompatibleMachine) then begin     {!!.03}
              GotError(CPort, GetAsyncStatus);                         {!!.01}
              State := tfAbort;                                        {!!.01}
              GotResponse := True;                                     {!!.01}
            end;                                                       {!!.01}

            {If this is a retrain request change the current state}
            if Retrain then begin
              if caNextBPS(FP) then begin
                caPutFrameT(FP);
                State := tf1TSIResponse;
              end else begin
                GotError(CPort, ecFaxTrainError);
                State := tfAbort;
              end;
            end;
          end;
        end;
      end;
    end;

    function ReadNextLine : Word;
      {-Read the next wordlength raster line}
    var
      Len : Word;
      I : Word;
    begin
      with C12SendFaxPtr(FP)^, CData^, PData^ do begin
        BlockRead(InFile, Len, 2, BytesRead);
        if Len > DataBufferSize then
          Len := DataBufferSize;
        BlockRead(InFile, DataBuffer^, Len, BytesRead);
        ReadNextLine := IoResult;
        if Len < MinBytes then begin
          FillChar(DataBuffer^[Len], MinBytes-BytesRead, 0);
          BytesRead := MinBytes;
        end;
        Inc(DataCount, Len+2);
      end;
    end;

    procedure ForceHangup;
    begin
      with C12SendFaxPtr(FP)^, CData^, PData^ do begin
        if CheckDCD(CPort) then begin
          Delay(AbortDelay);
          PutString(CPort, '+++');
          Delay(AbortDelay);
          caPutModem(FP, 'ATH0');
          Delay(AbortDelay);                                           {!!.02}
          FlushInBuffer(CPort);                                        {!!.02}

          {If DCD still set then toggle DTR}
          if CheckDCD(CPort) then
            caFlushModem(FP);
        end else
          {Just make sure we're back on hook}
          caPutModem(FP, 'ATH0');
      end;
    end;

  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin

      {Restore AsyncStatus in case something outside state machine changed it}
      SetAsyncStatus(SaveStatus);

      {Check for user abort request}
      if GetAsyncStatus <> ecUserAbort then
        if afHandleAbort(FP) then begin
          FlushOutbuffer(CPort);
          PutString(CPort, cDLE+cETX);
          if (ClassInUse = ctClass2) and
             (State > tf2Connect) and (State < tfClose) then
              {Send abort string but don't worry about response}
              PutString(CPort, 'AT+FK'^M);
          {Set status back to ecUserAbort}
          SetAsyncStatus(ecUserAbort);
          State := tfAbort;
        end;

      {Show status periodically and after major events}
      if TimerExpired(StatusTimer) or ForceStatus then begin
        ForceStatus := False;
        NewTimer(StatusTimer, StatusWait);
        FaxStatus(FP, False, False);
      end;

      {Preprocess pending modem responses}
      case State of
        tfGetEntry,
        tfInit,
        tfDial,
        tfRetryWait,
        tfOpenCover,
        tfSendCover,
        tfWaitXon,
        tfWaitFreeHeader,
        tfSendPageHeader,
        tfPrepPage,
        tfSendPage,
        tfDrainPage,
        tf1PrepareEOP,
        tf2SendEOP,
        tf2NextPage,
        tfClose,
        tfCompleteOK,
        tfAbort : {Don't preprocess these states} ;

        else begin
          {Preprocess all other states, check for text responses and HDLC frames}
          CheckResponse;

          {Check for timeouts}
          if TimerExpired(ReplyTimer) then begin
            case State of
              tf1WaitMCF :
                begin
                  PutChar(CPort, ' ');
                  State := tf1PrepareEOP;
                end;
              tf1WaitHangup :
                {Timeout waiting for normal hangup, force hangup and close OK}
                begin
                  ForceHangup;
                  State := tfClose;
                end;
              else begin
                GotError(CPort, ecTimeout);
                State := tfAbort;
              end;
            end;
          end else begin
            {Skip state machine if we don't have a response yet}
            if not GotResponse then
              goto ExitPoint;
          end;
        end;
      end;

      case State of
        tfGetEntry :
          if NextFax(FP, PhoneNum, FaxFileName, CoverFile) then begin

            {Log transmit started}
            LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitStart);

            {Prepare for transmit}
            ConnectCnt := 0;
            SendingCover := False;
            CoverIsAPF := False;
            PageCount := 0;
            CoverCount := 0;
            CurrPage := 1;
            Retries := 0;
            HangupCode := 0;

            {Open fax file}
            if FaxFileName <> '' then begin
              SetAsyncStatus(csOpenFaxFile(FP, FaxFileName));
              if GetAsyncStatus <> ecOK then begin
                GotError(CPort, GetAsyncStatus);
                State := tfAbort;
                goto ExitPoint;
              end;

              {Verify it's one of ours}
              Move(FaxHeader, S[1], 6);
              S[0] := #6;
              if S <> DefSig then begin
                GotError(CPort, ecFaxBadFormat);
                State := tfAbort;
                goto ExitPoint;
              end;

              {Note page count and continue}
              PageCount := (FaxHeader.PageCount);
            end else if CoverFile <> '' then begin
              {Sending just cover}
              PageCount := 0;
            end else begin
                GotError(CPort, ecNoFilename);
                State := tfAbort;
                goto ExitPoint;
            end;

            State := tfInit;
            FaxProgress := fpInitModem;

            {$IFDEF UseSWFlow}
            {Make sure flow control is off to start}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowDisable(CPort);
            {$ENDIF}
          end else
            State := tfCompleteOK;

        tfInit :
          begin
            {Make sure station ID is all uppercase}
            StationID := StUpcase(StationID);

            {!!.03 moved up}
            if CoverFile <> '' then begin
              CoverCount := 1;
              SendingCover := True;
              CoverIsAPF := Pos('.'+FaxFileExt, CoverFile) <> 0;
            end;

            {Read first page header}
            if FaxFileName <> '' then begin
              SetAsyncStatus(LocatePage(FP, CurrPage));
              if GetAsyncStatus <> 0 then begin
                GotError(CPort, GetAsyncStatus);
                State := tfAbort;
                goto ExitPoint;
              end;

              BlockRead(InFile, PageHeader, SizeOf(PageHeaderRec));
              UseLengthWord := FlagIsSet(PageHeader.ImgFlags, ffLengthWords);
              SetAsyncStatus(IOResult);
              if GetAsyncStatus <> ecOk then begin
                GotError(CPort, GetAsyncStatus);
                State := tfAbort;
                goto ExitPoint;
              end;

              {Set resolution character for DIS/DCS commands/frames}
              if (PageHeader.ImgFlags and ffHighRes) <> 0 then
                ResC := '1'
              else
                ResC := '0';
            end else begin                                               {!!.03}
              {Just sending cover, assume low res}
              ResC := '0';
              {If cover is APF, open to get its res}                     {!!.03}
              if CoverIsAPF then begin                                   {!!.03}
                if not csOpenCoverPage(FP) then                          {!!.03}
                  goto ExitPoint;                                        {!!.03}
                if (PageHeader.ImgFlags and ffHighRes) <> 0 then         {!!.03}
                  ResC := '1'                                            {!!.03}
                else                                                     {!!.03}
                  ResC := '0';                                           {!!.03}
                Close(InFile);                                           {!!.03}
                if IoResult <> 0 then ;                                  {!!.03}
              end;
            end;                                                         {!!.03}

            {Say we're initializing}
            FaxProgress := fpInitModem;
            ForceStatus := True;

            {Select next state for Class1 or Class2 modems}
            if ClassInUse = ctClass1 then begin
              State := tf1Init1;
              caPutModem(FP, 'AT+FCLASS=1');
            end else begin
              caPutModem(FP, 'AT+FCLASS=2');
              State := tf2Init1;
            end;
          end;

        tf1Init1 :
          if caOkResponse(FP) then
            State := tfDial
          else begin
            GotError(CPort, ecFaxInitError);
            State := tfAbort;
          end;

        tf2Init1 :
          if caOkResponse(FP) then begin
            caPutModem(FP, 'AT+FLID="'+StationID+'"');
            State := tf2Init2;
          end else begin
            GotError(CPort, ecFaxInitError);
            State := tfAbort;
          end;

        tf2Init2 :
          if caOkResponse(FP) then begin
            if ((PageHeader.ImgFlags and ffHighWidth) <> 0) then  {!!.03}
              FaxWid := '1'                                       {!!.03}
            else                                                  {!!.03}
              FaxWid := '0';                                      {!!.03}

            caPutModem(FP, 'AT+FDIS='+ResC+','+
                         caSpeedCode(FP)+','+                     {!!.03}
                         FaxWid+                                  {!!.03}
                         ',2,0,'+                                 {!!.03}
                         CheckChar+
                         ',0,0');
            State := tf2Init3;
          end else begin
            GotError(CPort, ecFaxInitError);
            State := tfAbort;
          end;

        tf2Init3 :
          if caOkResponse(FP) then
            State := tfDial
          else begin
            GotError(CPort, ecFaxInitError);
            State := tfAbort;
          end;

        tfDial:
          begin
            {Build modem dial string}
            if ToneDial then
              S := 'ATDT'
            else
              S := 'ATDP';
            S := S + DialPrefix + PhoneNum;
            caPutModem(FP, S);
            NewTimer(ReplyTimer, DialWait);
            FaxProgress := fpDialing;
            ForceStatus := True;
            if ClassInUse = ctClass1 then
              State := tf1Connect
            else
              State := tf2Connect;
          end;

        tfRetryWait :
          begin
            FaxProgress := fpBusyWait;
            if TimerExpired(ReplyTimer) then
              State := tfDial;
          end;

        tf1Connect :
          if caConnectResponse(FP) then
            caPrepResponse(FP)
          else if caOkResponse(FP) then begin
            if LastFrame then begin
              {Last frame was processed, prepare to transmit TSI}
              Delay(ExtraCommandDelay);
              caPutFrameT(FP);
              LastFrame := False;
              State := tf1SendTSI;
            end else begin
              {Ask for another frame}
              caPutFrameR(FP);
            end;
          end else if (Pos('BUSY', Response) <> 0) or
                      (Pos('ANSWER', Response) <> 0) then begin
            Inc(ConnectCnt);
            if (ConnectCnt < MaxConnect) or (MaxConnect = 0) then begin
              {No connect, delay and retry}
              FaxProgress := fpBusyWait;
              ForceStatus := True;
              State := tfRetryWait;
              NewTimer(ReplyTimer, RetryWait);
            end else begin
              {Too many failed connect attempts}
              FaxStatus(FP, False, False);

              if FlagIsSet(afFlags, afAbortNoConnect) then begin
                GotError(CPort, ecFaxBusy);
                State := tfAbort;
              end else begin
                {Get next fax entry}
                Close(InFile);
                if IOResult = 0 then ;
                GotError(CPort, ecFaxBusy);
                LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitFail);
                SetAsyncStatus(ecOk);
                FaxProgress := fpInitModem;
                State := tfGetEntry;
              end;
            end
          end else if Pos('VOICE', Response) > 0 then begin
            {Modem is receiving a voice call}
            GotError(CPort, ecFaxVoiceCall);
            State := tfAbort;
          end else if Pos('NO DIAL', Response) > 0 then begin          {!!.02}
            {No dialtone when trying to dial}                          {!!.02}
            GotError(CPort, ecNoDialTone);                             {!!.02}
            State := tfAbort;                                          {!!.02}
          end else if caNoCarrierResponse(FP) then begin               {!!.02}
            {No carrier when trying to call}                           {!!.02}
            GotError(CPort, ecNoCarrier);                              {!!.02}
            State := tfAbort;                                          {!!.02}
          end else
            {Must have been the command echo, discard it and keep going}
            caPrepResponse(FP);

        tf1SendTSI :
          if caConnectResponse(FP) then begin
            caPutTSIFrame(FP);
            caPrepResponse(FP);
            State := tf1TSIResponse;
          end else
            caPrepResponse(FP);

        tf1TSIResponse :
          if caConnectResponse(FP) then begin
            caPutDCSDISFrame(FP, False);
            caPrepResponse(FP);
            State := tf1DCSResponse;
          end else
            caPrepResponse(FP);

        tf1DCSResponse :
          if caOkResponse(FP) then begin
            {Start training...}
            caPutFaxCommand(FP, 'AT+FTM='+ModCode);
            State := tf1TrainStart;
          end else
            caPrepResponse(FP);

        tf1TrainStart :
          if caConnectResponse(FP) then begin
            {Send training data}
            {$IFDEF UseSWFlow}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowEnableOpt(CPort, 0, 0, sfTransmitFlow);
            {$ENDIF}
            caPutTCFData(FP);
            caPrepResponse(FP);
            State := tf1TrainFinish;
          end else
            caPrepResponse(FP);

        tf1TrainFinish :
          if caOkResponse(FP) then begin
            {Ask for CFR frame}
            {$IFDEF UseSWFlow}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowDisable(CPort);
            {$ENDIF}
            Delay(ExtraCommandDelay);                                  {!!.02}
            caPutFrameR(FP);
            State := tf1WaitCFR;
            GotCFR := False;                                           {!!.02}
          end;

        {!!.02 modified}
        tf1WaitCFR :
          if caOkResponse(FP) then begin
            if LastFrame then begin
              {Send carrier}
              if GotCFR then begin
                Delay(ExtraCommandDelay);
                caPutFaxCommand(FP, 'AT+FTM='+ModCode);
                LastFrame := False;
                State := tf1WaitPageConnect;
              end else begin
                {Must be a re-negotiate, restart from DCS again}
                Delay(ExtraCommandDelay);
                caPutFrameT(FP);
                State := tf1TSIResponse;
              end;
            end else begin
              {Ask for another frame}
              caPutFrameR(FP);
              caPrepResponse(FP);
            end;
          end else
            caPrepResponse(FP);

        tf1WaitPageConnect :
          if caConnectResponse(FP) then begin
            State := tfWaitXon;
            NewTimer(ReplyTimer, 18);
          end else
            caPrepResponse(FP);

        tf2Connect :
          if Pos('+FCON', Response) <> 0 then begin
            NewTimer(ReplyTimer, ReplyWait);
            Response := '';
            State := tf2GetParams;
          end else if (Pos('BUSY', Response) <> 0) or
                      (Pos('ANSWER', Response) <> 0) then begin
            Inc(ConnectCnt);
            if (ConnectCnt < MaxConnect) or (MaxConnect = 0) then begin
              {No connect, delay and retry}
              FaxProgress := fpBusyWait;
              ForceStatus := True;
              State := tfRetryWait;
              NewTimer(ReplyTimer, RetryWait);
            end else begin
              {Too many failed connect attempts}
              FaxStatus(FP, False, False);

              if FlagIsSet(afFlags, afAbortNoConnect) then begin
                GotError(CPort, ecFaxBusy);
                ForceStatus := True;
                State := tfAbort;
              end else begin
                {Get next fax entry}
                Close(InFile);
                if IOResult = 0 then ;
                GotError(CPort, ecFaxBusy);
                LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitFail);
                SetAsyncStatus(ecOk);
                State := tfGetEntry;
              end;
            end
          end else if Pos('VOICE', Response) > 0 then begin
            {Modem is receiving a voice call}
            GotError(CPort, ecFaxVoiceCall);
            State := tfAbort;
          end else
            {Unknown but probably acceptable response, just ignore it}
            caPrepResponse(FP);

        tf2GetParams :
          if Pos('+FDIS', Response) <> 0 then begin
            StripPrefix(Response);
            ExtractClass2Params(FP, Response);

            {!!.03 - added}
            if (((PageHeader.ImgFlags and ffHighWidth) <> 0) and not CanDoHighWid) or
              (((PageHeader.ImgFlags and ffHighRes  ) <> 0) and not CanDoHighRes) then begin
              SetAsyncStatus(ecIncompatibleMachine);
              State := tfAbort;
            end else begin
              FaxProgress := fpSessionParams;
              ForceStatus := True;
              caPrepResponse(FP);
            end;
          end else if Pos('FCSI', Response) <> 0 then begin
            StripPrefix(Response);
            RemoteID := TrimStationID(Response);
            FaxProgress := fpGotRemoteID;
            ForceStatus := True;
            caPrepResponse(FP);
          end else if (Pos('+FDCS', Response) > 0) then begin
            StripPrefix(Response);
            ExtractClass2Params(FP, Response);
            FaxProgress := fpSessionParams;
            ForceStatus := True;
            caPrepResponse(FP);
          end else if caOkResponse(FP) then
            caPutModem(FP, 'AT+FDT')
            {Stay in this state to handle the response}
          else if caConnectResponse(FP) then begin
            State := tfWaitXon;
            NewTimer(ReplyTimer, 18);
          end else                                                     {!!.01}
            caPrepResponse(FP);                                        {!!.01}

        tfWaitXon :
          begin
            if CharReady(CPort) then
              GetChar(CPort, C)
            else
              C := #0;
            if (C = cXOn) or TimerExpired(ReplyTimer) then begin
              State := tfWaitFreeHeader;
              NewTimer(ReplyTimer, TransWait);
            end;
          end;

        tfWaitFreeHeader :
          begin
            {$IFDEF UseSWFlow}
            {Finished with handshaking, turn on flow control}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowEnableOpt(CPort, 0, 0, sfTransmitFlow);
            {$ENDIF}

            {Say we're now sending page}
            FaxProgress := fpSendPage;

            {Wait for buffer free space}
            if OutBuffFree(CPort) >= MaxData then
              State := tfSendPageHeader
            else if TimerExpired(ReplyTimer) then begin                {!!.02}
              GotError(CPort, ecTimeout);                              {!!.02}
              State := tfAbort;
            end;                                                       {!!.02}
          end;

        tfSendPageHeader :
          begin
            {DataCount := 0;}                                          {!!.01}

            {Select font for title line}
            if not LoadFont(Converter, SmallFont, (ResC = '1')) then begin
              GotError(CPort, ecFaxNoFontFile);
              State := tfAbort;
              goto ExitPoint;
            end;

            {Convert and send header line}
            if HeaderLine <> '' then begin
              {!!.01 change start}
              S := afConvertHeaderString(FP, HeaderLine);

              {Force a small top margin}
              csSendWhiteRasterLines(FP, PhysicalTopMargin);

              {Add some zeros to give state machine caller some breathing room}
              Count := OutBuffUsed(CPort);                             {!!.02}
              for I := Count to BufferMinimum do                       {!!.02}
                PutChar(CPort, #0);                                    {!!.02}

              {Send all raster rows in header}
              for I := 1 to Converter^.PData^.FontRec.Height do begin
                acCompressStringRow(Converter, S, I, DataBuffer^,
                                    BytesRead, True);

                {Send raster row}
                csPutLineBuffer(FP, DataBuffer^, BytesRead);
              end;
              {!!.01 change end}

              {Force the first disk read}
              BytesRead := 1;
            end else
              csSendWhiteRasterLines(FP, PhysicalTopMargin);

            {Add some zeros to give state machine caller some breathing room}
            Count := OutBuffUsed(CPort);
            for I := Count to BufferMinimum do
              PutChar(CPort, #0);

            if CoverFile = '' then
              State := tfPrepPage
            else
              State := tfOpenCover;
          end;

        {!!.03 rewritten}
        tfOpenCover:
          begin
            DataCount := 0;
            if not csOpenCoverPage(FP) then
              goto ExitPoint;

            if CoverIsAPF then
              State := tfPrepPage
            else begin
              State := tfSendCover;
              NewTimer(ReplyTimer, TransWait);
              FaxProgress := fpSendPage;
            end;
          end;

        tfSendCover:
          if OutBuffFree(CPort) >= DataBufferSize then begin
            if not Eof(CvrF) then begin
              ReadLn(CvrF, S);
              SetAsyncStatus(IoResult);
              if GetAsyncStatus <> ecOk then begin
                GotError(CPort, GetAsyncStatus);
                State := tfAbort;
                goto ExitPoint;
              end;
              S := afConvertHeaderString(FP, S);                       {!!.01}
              for I := 1 to Converter^.PData^.FontRec.Height do begin  {!!.01}
                acCompressStringRow(Converter, S, I, DataBuffer^,      {!!.01}
                                    BytesRead, True);                  {!!.01}
                csPutLineBuffer(FP, DataBuffer^, BytesRead);           {!!.01}
              end;                                                     {!!.01}
            end else begin
              acMakeEndOfPage(Converter, DataBuffer^, BytesRead);
              csPutBuffer(FP, DataBuffer^, BytesRead);
              for I := BytesRead to MinBytes do
                PutChar(CPort, #0);
              if ClassInUse = ctClass1 then begin
                caHDCLEnd(FP);
                FaxProgress := fpSendPage;
              end;
              State := tfDrainPage;
            end;
            FaxProgress := fpSendPage;
            ForceStatus := True;
            NewTimer(ReplyTimer, TransWait);
          end else if TimerExpired(ReplyTimer) then begin
            GotError(CPort, ecBufferIsFull);
            ForceStatus := True;
            State := tfAbort;
            goto ExitPoint;
          end;

        tfPrepPage :
          begin
            {Position at the start of data}
            DataCount := 0;
            PageSize := PageHeader.ImgLength;
            State := tfSendPage;
            ForceStatus := True;
            NewTimer(ReplyTimer, TransWait);
          end;

        tfSendPage :
          if OutBuffFree(CPort) >= DataBufferSize then begin
            Count := 0;
            while (Count < MaxSendCount) and
                  (OutBuffUsed(CPort) <= BufferMinimum) and
                  (OutBuffFree(CPort) >= DataBufferSize) do begin
              Inc(Count);                                              {!!.02}
              if DataCount < PageSize then begin
                {Get next block of data to send}
                if UseLengthWord then
                  {Reads line and increments DataCount}
                  SetAsyncStatus(ReadNextLine)
                else begin
                  BlockRead(InFile, DataBuffer^, DataBufferSize, BytesRead);
                  Inc(DataCount, BytesRead);
                  SetAsyncStatus(IoResult);
                end;

                if GetAsyncStatus <> ecOk then begin
                  GotError(CPort, GetAsyncStatus);
                  State := tfAbort;
                  goto ExitPoint;
                end;

                {Send data}
                csPutBuffer(FP, DataBuffer^, BytesRead);

                {Wait for enough space to send next buffer full}
                NewTimer(ReplyTimer, TransWait);

              end else begin
                {End of this page, add Class 1 termination}
                if ClassInUse = ctClass1 then begin
                  caHDCLEnd(FP);
                  FaxProgress := fpSendPage;
                end;

                {Wait for page to drain}
                State := tfDrainPage;
                NewTimer(ReplyTimer, TransWait);

                {Force exit from while loop}
                Count := MaxSendCount + 1;
              end;
            end;
          end else if TimerExpired(ReplyTimer) then begin
            GotError(CPort, ecBufferIsFull);
            ForceStatus := True;
            State := tfAbort;
            goto ExitPoint;
          end;

        tfDrainPage :
          if OutBuffUsed(CPort) <= 1 then begin

            {$IFDEF UseSWFlow}
            {Finished with data, turn off flow control}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowDisable(CPort);
            {$ENDIF}

            if ClassInUse = ctClass1 then
              State := tf1PageEnd
            else
              State := tf2SendEOP;

            {Force status one more time so user's display shows 100%}
            ForceStatus := True;
            FaxProgress := fpSendPage;
          end else if TimerExpired(ReplyTimer) then begin
            GotError(CPort, ecTimeout);
            ForceStatus := True;
            State := tfAbort;
          end;

        tf1PageEnd :
          if caOkResponse(FP) then begin
            Retry := 0;
            State := tf1PrepareEOP;
            FaxProgress := fpSendPageStatus;
          end else
            caPrepResponse(FP);

      tf1PrepareEOP :
        begin
          Inc(Retry);
          if Retry > 3 then begin
            GotError(CPort, ecTimeout);
            ForceStatus := True;
            State := tfAbort;
          end else begin
            Delay(PreEOPDelay);
            caPutFrameT(FP);
            State := tf1SendEOP;
          end;
        end;

        tf1SendEOP :
          if caConnectResponse(FP) then begin
            if (FaxFileName <> '') and
               ((CurrPage < FaxHeader.PageCount) or SendingCover) then
              caPutStandardFrame(FP, MPSFrame or $01)
            else
              {Send end of page frame}
              caPutStandardFrame(FP, EOPFrame or $01);

            caPrepResponse(FP);
            State := tf1WaitMPS;
          end else
            caPrepResponse(FP);

        tf1WaitMPS :
          if caOkResponse(FP) then begin
            {Ask for comfirmation}
            Delay(ExtraCommandDelay);
            caPutFrameR(FP);
            State := tf1WaitMCF;
            NewTimer(ReplyTimer, 54);
            MCFConnect := False;
        end else
            caPrepResponse(FP);

        tf1WaitEOP :
          if caOkResponse(FP) then begin
            {Ask for comfirmation}
            Delay(ExtraCommandDelay);
            caPutFrameR(FP);
            State := tf1WaitMCF;
            NewTimer(ReplyTimer, 54);
            MCFConnect := False;
          end else
            caPrepResponse(FP);

        tf1WaitMCF :
          if caConnectResponse(FP) then begin
            MCFConnect := True;
            caPrepResponse(FP);
          end else if caErrorResponse(FP) then begin
            State := tf1PrepareEOP;
          end else if caOkResponse(FP) then begin
            if LastFrame then begin
              LastFrame := False;
              case ReceivedFrame of
                RTPFrame :
                  if (CurrPage < FaxHeader.PageCount) or SendingCover then begin
                    {Advance to next page}
                    if not csAdvancePage(FP) then begin
                      State := tfAbort;
                      goto ExitPoint;
                    end;
                    caPutFrameT(FP);
                    State := tf1TSIResponse;
                  end else begin
                    {No more pages}
                    caPutFrameT(FP);
                    State := tf1SendDCN;
                  end;
                RTNFrame :
                  begin                                                {!!.02}
                    GotError(CPort, ecFaxSessionError);                {!!.02}
                    State := tfAbort;
                  end;                                                 {!!.02}
                MCFFrame :
                  if (CurrPage < FaxHeader.PageCount) or               {!!.03}
                     (SendingCover and (FaxFileName <> '')) then begin {!!.03}
                    {Advance to next page}
                    if not csAdvancePage(FP) then begin
                      State := tfAbort;
                      goto ExitPoint;
                    end;
                    caPutFaxCommand(FP, 'AT+FTM='+ModCode);
                    State := tf1WaitPageConnect;
                  end else begin
                    {No more pages}
                    caPutFrameT(FP);
                    State := tf1SendDCN;
                  end;
              end;
            end else begin
              {Ask for another frame}
              caPutFrameR(FP);
            end;
          end else
            caPrepResponse(FP);

        tf1SendDCN :
          if caConnectResponse(FP) then begin
            caPutStandardFrame(FP, DCNFrame or $01);
            caPrepResponse(FP);
            State := tf1Hangup;
          end else
            caPrepResponse(FP);

        tf1HangUp :
          if caOkResponse(FP) then begin
            {Hangup}
            caPutModem(FP, 'ATH');

            {Special short (2 seconds) wait for hangup result}
            NewTimer(ReplyTimer, 36);
            State := tf1WaitHangup;
          end else
            caPrepResponse(FP);

        tf1WaitHangup :
          if caOkResponse(FP) then
            State := tfClose
          else
            caPrepResponse(FP);

        tf2SendEOP :
          begin
            PutChar(CPort, cDLE);
            PutChar(CPort, cETX);
            State := tf2WaitFPTS;
            Response := '';
            NewTimer(ReplyTimer, TransWait);
            FaxProgress := fpSendPageStatus;
            ForceStatus := True;
          end;

        tf2WaitFPTS:
          if caOkResponse(FP) then begin
            if (FaxFileName <> '') and                                   {!!.02}
               ((SendingCover) or (CurrPage < FaxHeader.PageCount)) then {!!.02}
              S := 'AT+FET=0'
             else
              S := 'AT+FET=2';
            caPutModem(FP, S);
            State := tf2WaitFET;
            NewTimer(ReplyTimer, ReplyWait);
          end else begin                                               {!!.02}
            GotError(CPort, ecFaxSessionError);                        {!!.02}
            State := tfAbort;
          end;                                                         {!!.02}

        tf2WaitFET :
          if caOkResponse(FP) then
            {Got OK from FPTS:1}
            State := tf2NextPage
          else if caFHNGResponse(FP) then begin
            HangupCode := caExtractFHNGCode(FP);
            caPrepResponse(FP);
          end else if Pos('FPTS', Response) <> 0 then begin
            StripPrefix(Response);
            RetryPage := False;                                        {!!.02}
            case Response[1] of
              '1', '3' : {page good}                                   {!!.02}
                begin
                  FaxProgress := fpPageOK;
                  ForceStatus := True;
                  caPrepResponse(FP);
                  {Stay in this state for OK}
                end;

              '2' : {page bad, retry requested}                        {!!.02}
                begin                                                  {!!.02}
                  RetryPage := True;                                   {!!.02}
                  FaxProgress := fpPageError;                          {!!.02}
                  State := tf2WaitPageOK;                              {!!.02}
                  ForceStatus := True;                                 {!!.02}
                  caPrepResponse(FP);                                  {!!.02}
                end;                                                   {!!.02}

              '4', '5' :  {page good/bad, interrupt requested}
                begin
                  GotError(CPort, ecCancelRequested);
                  ForceStatus := True;
                  State := tfAbort;
                end;
              else begin
                GotError(CPort, ecFaxPageError);                       {!!.02}
                ForceStatus := True;
                State := tfAbort;
              end;
            end;
          end else begin
            GotError(CPort, ecFaxPageError);
            ForceStatus := True;
            State := tfAbort;
          end;

        {!!.02 modified}
        tf2WaitPageOK :
          if caOkResponse(FP) then begin
            Inc(Retries);
            if Retries > MaxRetries then begin
              {Abort}
              PutString(CPort, 'AT+FK');
              GotError(CPort, ecFaxSessionError);
              ForceStatus := True;
              State := tfAbort;
            end else begin
              {Let modem start retraining...}
              caPutModem(FP, 'AT+FDT');

              {Reset to beginning of this same page}
              if FaxFileName <> '' then begin
                SetAsyncStatus(LocatePage(FP, CurrPage));
                if GetAsyncStatus <> 0 then begin
                  GotError(CPort, GetAsyncStatus);
                  State := tfAbort;
                  goto ExitPoint;
                end;

                BlockRead(InFile, PageHeader, SizeOf(PageHeaderRec));
                UseLengthWord := FlagIsSet(PageHeader.ImgFlags, ffLengthWords);
                SetAsyncStatus(IOResult);
                if GetAsyncStatus <> ecOk then begin
                  GotError(CPort, GetAsyncStatus);
                  State := tfAbort;
                  goto ExitPoint;
                end;
              end else begin
                {Sending cover only, close to prepare for re-open above}
                Close(CvrF);
                if IoResult <> 0 then ;
                CvrOpen := False;                                      {!!.02}
              end;
            end;
          end else begin
            GotError(CPort, ecFaxSessionError);
            ForceStatus := True;
            State := tfAbort;
          end;

        tf2NextPage :
          if (FaxFileName <> '') and
             ((CurrPage < FaxHeader.PageCount) or SendingCover) then begin

            {Advance to next page}
            if not csAdvancePage(FP) then begin
              State := tfAbort;
              goto ExitPoint;
            end;

            caPutModem(FP, 'AT+FDT');
            State := tf2GetParams;
          end else
            State := tfClose;

        tfClose :
          begin
            if CvrOpen then begin                                      {!!.02}
              Close(CvrF);
              if IOResult = 0 then ;
              CvrOpen := False;                                        {!!.02}
            end;                                                       {!!.02}
            Close(InFile);
            if IoResult = 0 then ;
            Retries := 0;
            SendingCover := False;

            {Log this successful transfer}
            LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitOk);

            {Look for another fax to send}
            State := tfGetEntry;

            caSwitchBaud(FP, False);                                   {!!.02}
          end;

        tfAbort :
          begin
            {Assure files are closed}                                  {!!.02}
            Close(InFile);                                             {!!.02}
            if IoResult <> 0 then ;                                    {!!.02}
            if CvrOpen then begin                                      {!!.02}
              Close(CvrF);                                             {!!.02}
              if IoResult <> 0 then ;                                  {!!.02}
              CvrOpen := False;                                        {!!.02}
            end;                                                       {!!.02}

            SaveStatus := GetAsyncStatus;
            LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitFail);
            ForceHangup;
            SetAsyncStatus(SaveStatus);

            {Exit or remain in state machine}
            if FlagIsSet(afFlags, afExitOnError) or
               FlagIsSet(afFlags, afAbortNoConnect) or
               (GetAsyncStatus = ecUserAbort) then begin
              FaxStatus(FP, False, True);
              CPort^.FaxActive := False;
              State := tfDone;
            end else
              State := tfGetEntry;

            SaveStatus := GetAsyncStatus;                              {!!.03}
            caSwitchBaud(FP, False);                                   {!!.03}
            SetAsyncStatus(SaveStatus);                                {!!.03}
          end;

        tfCompleteOK :
          begin
            SetAsyncStatus(ecOk);
            FaxStatus(FP, False, True);
            State := tfDone;
            CPort^.FaxActive := False;
          end;
      end;

  ExitPoint:
      {Assume a waiting state}
      FaxTransmitPartC12 := faxWaiting;

      {Change ready, critical and finished states}
      case State of
        {Critical states}
        tf1Connect,
        tf1SendTSI,
        tf1TSIResponse,
        tf1DCSResponse,
        tf1TrainStart,
        tf1TrainFinish,
        tf1WaitCFR,
        tf1WaitPageConnect : FaxTransmitPartC12 := faxCritical;

        {Ready states}
        tfGetEntry,
        tfDial,
        tfOpenCover,
        tfSendPageHeader,
        tfPrepPage,
        tfClose,
        tfCompleteOk,
        tfAbort         :  FaxTransmitPartC12 := faxReady;

        tfDone          :  FaxTransmitPartC12 := faxFinished;
      end;

      {Save status in case something outside of state machine changes it}
      SaveStatus := GetAsyncStatus;
    end;
  end;

  procedure PrepareFaxTransmitPartC12(FP : FaxRecPtr);
    {-Send fax}
  var
    I : Word;
  begin
    with C12SendFaxPtr(FP)^, CData^, PData^ do begin
      {Inits}
      CPort^.FaxActive := True;
      FillChar(FaxHeader, SizeOf(FaxHeader), 0);
      FaxStatus(FP, True, False);
      SetAsyncStatus(ecOk);
      SaveStatus := ecOk;
      State := tfGetEntry;
      FaxProgress := fpInitModem;
      FaxListNode := FaxListHead;

      {If Class hasn't been set yet then figure out highest class}
      if ClassInUse = ctDetect then
        if SetClassType(FP, ctDetect) = ctUnknown then begin
          SetAsyncStatus(ecUnknownModemResult);
          Exit;
        end;

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      {If not sent already, send modem and def init strings}
      if not InitSent then begin
        {Send user init}
        if (ModemInit <> '') and (not caProcessModemCmd(FP, ModemInit)) then
          Exit;

        {Send required inits}
        if not caProcessModemCmd(FP, DefInit) then
          Exit;
        InitSent := True;
      end;

      {Set class}
      if ClassInUse = ctClass1 then begin
        if not caProcessModemCmd(FP, 'AT+FCLASS=1') then
          Exit;
      end else begin
        if not caProcessModemCmd(FP, 'AT+FCLASS=2') then
          Exit;
      end;

      {Switch to normal baud rate}                                     {!!.01}
      caSwitchBaud(FP, True);                                          {!!.01}

      {Get class1 get modulation capabilities}
      if ClassInUse = ctClass1 then
        caGetClass1Modulations(FP, True);
    end;
  end;

  procedure FaxTransmitC12(FP : FaxRecPtr);
    {-Send fax}
  var
    Result : FaxStateType;
  begin
    PrepareFaxTransmitPartC12(FP);

    {State in state machine until finished}
    repeat
    until FaxTransmitPartC12(FP) = faxFinished;
  end;

{C12ReceiveFax}

  procedure InitC12ReceiveFax(var FP : FaxRecPtr; ID : Str20;
                              ComPort : PortRecPtr);
  begin
    if not GetMemCheck(FP, SizeOf(C12ReceiveFax)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with C12ReceiveFaxPtr(FP)^ do begin
      InitC12AbsData(CData, ComPort);
      if CData = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        DoneC12ReceiveFax(FP);
        Exit;
      end;

      InitFaxData(PData, ID);
      if PData = nil then begin
        DoneC12ReceiveFax(FP);
        Exit;
      end;
    end;

    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      FillChar(FaxHeader, SizeOf(FaxHeader), 0);
      FillChar(PageHeader, SizeOf(PageHeader), 0);
      CurrPage     := 1;
      CurrOfs      := 0;
      Last         := #255;
      Sending      := False;
      State        := rfInit;
      OneFax       := False;
      ShowStatus   := False;
      FirstState   := rfInit;
    end;
  end;

  procedure DoneC12ReceiveFax(var FP : FaxRecPtr);
  begin
    with C12ReceiveFaxPtr(FP)^ do begin
      DoneFaxData(PData);
      DoneC12AbsData(CData);
      FreeMemCheck(FP, SizeOf(C12ReceiveFax));
    end;
  end;

  function InitModemForFaxReceive(FP : FaxRecPtr) : Boolean;
    {-Send nessessary commands to initialize modem for fax receive}
  var
    LC : Integer;
    ClassStr : String[3];
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      InitModemForFaxReceive := False;
      caFlushModem(FP);

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      if (ModemInit <> '') and (not caProcessModemCmd(FP, ModemInit)) then
        Exit;

      if not caProcessModemCmd(FP, DefInit) then
          Exit;
      InitSent := True;

      if ClassInUse = ctDetect then
        ClassInUse := SetClassType(FP, ClassInUse);
      case ClassInUse of
        ctClass1 : ClassStr := '1';
        ctClass2 : ClassStr := '2';
        else begin
          GotError(CPort, ecFaxInitError);
          Exit;
        end;
      end;

      if not caProcessModemCmd(FP, 'AT+FCLASS='+ClassStr) then
        Exit;

      {Switch to normal baud rate}                                     {!!.01}
      caSwitchBaud(FP, True);                                          {!!.01}

      if ClassInUse = ctClass2 then begin
        if not caProcessModemCmd(FP, 'AT+FCR=1') then
          Exit;
        if not caProcessModemCmd(FP, 'AT+FLID="'+StationID+'"') then
          Exit;
        if not caProcessModemCmd(FP, 'AT+FAA='+FaxAndData) then
          Exit;
        {if not caProcessModemCmd(FP, 'AT+FPHCTO=50') then              !!.01}
        { Exit;                                                         !!.01}

        {!!.03 - Changed parameters}
        if not caProcessModemCmd(FP, 'AT+FDCC=1,'+caSpeedCode(FP)+',1,2,0,0,0,0') then
          Exit;
      end;

      InitModemForFaxReceive := True;
    end;
  end;

  procedure SetConnectState(FP : FaxRecPtr);
    {-Force the receiver to pick up a connection in progress}
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      {Init to midstream values}
      FirstState := rf2GetSenderID;
      PageStatus := rpsNewDocument;
      InitSent := True;
      Response := '';
      Critical := True;
      SetAsyncStatus(ecOk);

      CurrPage := 0;
      DataCount := 0;
      InFileName := '';
      RemoteID := '';
      PhoneNum := '';
      FaxFileName := '';

      {Show the first status here}
      ShowStatus := True;
      FaxStatus(FP, True, False);

      {Start a timer for collecting the next fax response}
      NewTimer(ReplyTimer, ReplyWait);
    end;
  end;

  procedure SetAnswerOnRing(FP : FaxRecPtr; AOR : Integer);
    {-set Nth ring for modem answer}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      AnswerOnRing := AOR;
  end;

  procedure SetFaxAndData(FP : FaxRecPtr; OnOff : Boolean);
    {-True for fax to answer either fax or data, False for fax only}
  begin
    with C12FaxRecPtr(FP)^, CData^ do
      if OnOff then
        FaxAndData := '1'
      else
        FaxAndData := '0';
  end;

  procedure SetOneFax(FP : FaxRecPtr; OnOff : Boolean);
    {-Set "one fax" receive behavior on/off}
  begin
    with C12ReceiveFaxPtr(FP)^ do
      OneFax := OnOff;
  end;

  procedure crFlushBuffer(FP : FaxRecPtr);
    {-write current buffered data to InFile}
  var
    BytesWritten : Word;
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      {Write the block}
      BlockWrite(InFile, DataBuffer^, CurrOfs, BytesWritten);
      SetAsyncStatus(IOResult);
      if BytesWritten <> CurrOfs then
        SetAsyncStatus(ecDeviceWrite);
      if GetAsyncStatus <> ecOk then
        GotError(CPort, GetAsyncStatus);
      CurrOfs := 0;
    end;
  end;

  function crAddReceivedData(FP : FaxRecPtr) : Boolean;
    {-Get waiting FAX stream data.  Returns True if EOP seen.}
  var
    C : Char;
    Count : Word;

    function AddToStream(C : Char) : Boolean;
    begin
      with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
        AddToStream := True;
        if ClassInUse = ctClass2 then
          DataBuffer^[CurrOfs] := RotateByte(C)
        else
          DataBuffer^[CurrOfs] := Byte(C);
        Inc(CurrOfs);
        if CurrOfs >= DataBufferSize then begin
          crFlushBuffer(FP);
          if GetAsyncStatus <> ecOK then
            AddToStream := False;
        end;
      end;
    end;

  begin
    with C12ReceiveFaxPtr(FP)^ , CData^, PData^do begin
      crAddReceivedData := False;
      SetAsyncStatus(ecOK);

      if CharReady(CPort) then begin

        {Process while received data ready}
        Count := 0;
        while CharReady(CPort) do begin

          {Periodically exit back to state machine to check abort and status}
          Inc(Count);
          if Count > DefStatusBytes then
            Exit;

          GetChar(CPort, C);
          SetAsyncStatus(ecOk);

          {check for <DLE><ETX> pair indicating end of page}
          if C = cETX then
            if Last = cDLE then begin
              crFlushBuffer(FP);
              crAddReceivedData := True;
              Exit;
            end;

            {Write data, DLE is data link escape}
            if (C <> cDLE) or ((C = cDLE) and (Last = cDLE)) then begin
              if AddToStream(C) then
                Inc(DataCount)
              else begin
                {Error writing to file, let state machine handle error}
                crAddReceivedData := True;
                Exit;
              end;
              if Last = cDLE then
                Last := #255
              else
                Last := C;
            end else
              Last := C;
        end;

        {update our timeout}
        NewTimer(ReplyTimer, ReplyWait);
        Exit;
      end;

      if TimerExpired(ReplyTimer) then begin
        SetAsyncStatus(ecTimeout);
        crAddReceivedData := True;
      end;
    end;
  end;

  function crUpdateMainHeader(FP : FaxRecPtr) : Integer;
    {-Update the contents of the main header in the file}
  var
    I : Integer;
    L : LongInt;
    W : Word;
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      {Refresh needed fields of MainHeader rec}
      with FaxHeader do begin
        SenderID := RemoteID;                                          {!!.03}
        FDateTime := GetPackedDateTime;
      end;

      {Save current file position for later}
      L := FilePos(InFile);
      I := IOResult;
      if I <> 0 then begin
        crUpdateMainHeader := I;
        Exit;
      end;

      {seek to head of file}
      Seek(InFile, 0);
      if I <> 0 then begin
        crUpdateMainHeader := I;
        Exit;
      end;

      {Write the header}
      BlockWrite(InFile, FaxHeader, SizeOf(FaxHeader), W);
      I := IOResult;
      if (I = 0) and (W <> SizeOf(FaxHeader)) then
        I := ecDeviceWrite;
      if I <> 0 then begin
        crUpdateMainHeader := I;
        Exit;
      end;

      {Return to original position}
      Seek(InFile, L);
      I := IOResult;
      crUpdateMainHeader := I;
    end;
  end;

  function crUpdatePageHeader(FP : FaxRecPtr; PgNo : Word;
                            var PgInfo : PageHeaderRec) : Integer;
    {-Update the contents of the PgNo-th page header in the file}
  var
    I : Integer;
    W : Word;
    L : LongInt;
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      {save current file position for later}
      L := FilePos(InFile);
      I := IOResult;
      if I <> 0 then begin
        crUpdatePageHeader := I;
        Exit;
      end;

      {find the page in question}
      I := LocatePage(FP, PgNo);
      if I <> 0 then begin
        crUpdatePageHeader := I;
        Exit;
      end;

      {update the header}
      BlockWrite(InFile, PgInfo, SizeOf(PageHeaderRec), W);
      I := IOResult;
      if (I = 0) and (W <> SizeOf(PageHeaderRec)) then
        I := ecDeviceWrite;
      if I <> 0 then begin
        crUpdatePageHeader := I;
        Exit;
      end;

      {Return to original position}
      Seek(InFile, L);
      I := IOResult;
      crUpdatePageHeader := I;
    end;
  end;

  function FaxReceivePartC12(FP : FaxRecPtr) : FaxStateType;
    {-Receive fax state machine}
  label
    ExitPoint;
  var
    Result : Word;
    C : Char;
    Finished : Boolean;
    GotResponse : Boolean;
    Retrain : Boolean;
    PercentBad : Word;

    procedure CheckResponse;
      {-Check for text responses, check for and process HDLC frames}
    begin
      with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
        {Collect chars till CR/LF or DLE/ETX}
        Finished := False;
        GotResponse := False;
        while CharReady(CPort) and not Finished do begin
          GetChar(CPort, C);
          Response := Response + C;
          if CheckForString(CRLFIndex, C, ^M^J, False) then begin
            Response := Trim(Response);
            if Response <> '' then begin
              {Got a text response}
              Finished := True;
              GotResponse := True;

              {All error responses are aborts}
              if caErrorResponse(FP) then begin
                GotError(CPort, ecUnknownModemResult);
                State := rfAbort;
              end else if caFHNGResponse(FP) and (State <> rf2GetFHNG) then begin
                {Unexpected FHNGs are also aborts}
                GotError(CPort, ecFaxSessionError);
                HangupCode := caExtractFHNGCode(FP);
                State := rfAbort;
              end;
            end;
          end else if CheckForString(EtxIndex, C, #16#3, False) then begin
            {An HDLC frame, process it now}
            LastFrame := ProcessFrame(FP, Retrain);

            {Abort if we got a DCN frame}                              {!!.01}
            if GetAsyncStatus = ecCancelRequested then                 {!!.01}
              if State <> rf1WaitDCN then begin                        {!!.01}
                GotError(CPort, GetAsyncStatus);                       {!!.01}
                State := rfAbort;                                      {!!.01}
                GotResponse := True;                                   {!!.01}
              end else                                                 {!!.01}
                SetAsyncStatus(ecOk);                                  {!!.01}

            {If this is a retrain request change the current state}
            if Retrain then begin
              Delay(ExtraCommandDelay);
              caPutFrameR(FP);
              State := rf1CollectFrames;
            end;
          end;
        end;
      end;
    end;

    function OpenIncomingFile : Boolean;
    begin
      with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
        OpenIncomingFile := False;
        CurrPage := 1;
        FillChar(FaxHeader, SizeOf(FaxHeader), 0);
        Move(DefSig, FaxHeader, SizeOf(DefSig));
        FaxHeader.FDateTime := GetPackedDateTime;
        FaxHeader.SenderID  := PadCh(RemoteID, ' ', 20);
        FaxHeader.PageCount := 0;
        FaxHeader.PageOfs   := SizeOf(FaxHeader);
        FaxFileName := FaxName(FP);
        Assign(InFile, FaxFileName);
        Rewrite(InFile, 1);
        SetAsyncStatus(IOResult);
        if GetAsyncStatus = ecOk then begin
          BlockWrite(InFile, FaxHeader, SizeOf(FaxHeader));
          SetAsyncStatus(IOResult);
          if GetAsyncStatus <> 0 then
            Exit;
        end else
          Exit;
        OpenIncomingFile := True;
      end;
    end;

    function WritePage : Word;
      {-Commit the received page}
    var
      Result : Word;
    begin
      with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
        {Write received page}
        Inc(FaxHeader.PageCount);
        Result := crUpdateMainHeader(FP);
        if Result = ecOk then begin
          PageHeader.ImgLength := DataCount;
          Result := crUpdatePageHeader(FP, CurrPage, PageHeader);
        end;
        WritePage := Result;
      end;
    end;

  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      {Restore previous AsyncStatus}
      SetAsyncStatus(SaveStatus);

      {Check for user abort request}
      if GetAsyncStatus <> ecUserAbort then
        if afHandleAbort(FP) then begin
          if (ClassInUse = ctClass2) and (State > rfAnswer) then
              {Send abort string but don't worry about response}
              PutString(CPort, 'AT+FK'^M);
          SetAsyncStatus(ecUserAbort);
          State := rfAbort;
        end;

      {Show status periodically and after major events}
      if ShowStatus then
        if TimerExpired(StatusTimer) or ForceStatus then begin
          ForceStatus := False;
          NewTimer(StatusTimer, StatusWait);
          FaxStatus(FP, False, False);
        end;

      {Preprocess pending modem responses}
      case State of
        rf1Init1,                                                      {!!.02}
        rf2Init1,
        rf2Init2,
        rf2Init3,
        rfWaiting,
        rf1SendCSI,
        rf1SendDIS,
        rf1CollectFrames,
        rf1Timeout,                                                    {!!.02}
        rf1StartTrain,
        rf1Retrain,
        rf1FinishTrain,
        rf1SendCFR,
        rf1WaitPageConnect,
        rf1FinishPage,
        rf1WaitEOP,
        rf1SendMCF,
        rf1WaitDCN,
        rf1WaitHangup,
        rf2GetConnect,
        rf2ValidConnect,
        rf2GetSenderID,
        rf2GetPageResult,
        rf2GetFHNG :
          begin
            {Preprocess these states, check for text responses and HDLC frames}
            CheckResponse;

            {Don't let rfWaiting state ever timeout}
            if State = rfWaiting then
              NewTimer(ReplyTimer, ReplyWait);

            {Check for timeouts}
            if TimerExpired(ReplyTimer) then begin
              {Handle timeout in various ways}
              case State of
                {!!.02 new}
                rf1CollectFrames :
                  if RetryCnt < MaxClass1Retry then begin
                    Inc(RetryCnt);
                    PutChar(CPort, 'g');
                    NewTimer(ReplyTimer, Class1Wait);
                    State := rf1Timeout;
                    goto ExitPoint;
                  end else begin
                    GotError(CPort, ecTimeout);
                    State := rfAbort;
                  end;
                rf1WaitDCN :
                  {Exit normally if the DCN never comes}
                  State := rfComplete;
                else begin
                  GotError(CPort, ecTimeout);
                  State := rfAbort;
                end;
              end;
            end else begin
              {Skip state machine if we don't have a response yet}
              if not GotResponse then
                goto ExitPoint;
            end;
          end;
      end;

      {Main state machine}
      case State of
        rfInit :
          begin
            CurrOfs := 0;
            Last := #255;
            Response := '';
            PageStatus := rpsNewDocument;
            CurrPage := 0;
            RingCounter := 0;
            DataCount := 0;
            InFileName := '';
            RemoteID := '';
            PhoneNum := '';
            FaxFileName := '';
            RetryCnt := 0;                                             {!!.02}

            LastPageOk := False;
            SetModem(CPort, True, True);
            if ClassInUse = ctClass1 then begin
              State := rf1Init1;
              caPutModem(FP, 'AT+FCLASS=1');
            end else begin
              State := rf2Init1;
              caPutModem(FP, 'AT+FCLASS=2');
            end;
            NewTimer(ReplyTimer, ReplyWait);
            FlushInBuffer(CPort);

            {$IFDEF UseSWFlow}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowDisable(CPort);
            {$ENDIF}
          end;

        rf1Init1 :
          if caOkResponse(FP) then begin
            caSwitchBaud(FP, True);                                    {!!.02}
            State := rfWaiting;
            FaxProgress := fpWaiting;                                  {!!.02}
          end else begin
            GotError(CPort, ecFaxInitError);
            State := rfAbort;
          end;

        rf2Init1 :
          if caOkResponse(FP) then begin
            caSwitchBaud(FP, True);                                    {!!.02}

            {!!.03 - Changed parameters}
            caPutModem(FP, 'AT+FDCC=1,'+caSpeedCode(FP)+',1,2,0,'+CheckChar+',0,0');
            State := rf2Init3;                                         {!!.01}
          end else begin
            GotError(CPort, ecFaxInitError);
            State := rfAbort;
          end;

        {!!.01 removed}
        {rf2Init2 :
          if caOkResponse(FP) then begin
            caPutModem(FP, 'AT+FCR=1;+FLID="'+StationID+'";+FAA='+FaxAndData);
            State := rf2Init3;
          end else begin
            GotError(CPort, ecFaxInitError);
            State := rfAbort;
          end;}

        rf2Init3 :
          if caOkResponse(FP) then begin                               {!!.02}
            State := rfWaiting;                                        {!!.02}
            FaxProgress := fpWaiting;                                  {!!.02}
          end else begin                                               {!!.02}
            GotError(CPort, ecFaxInitError);
            State := rfAbort;
          end;

        rfWaiting :
          if Pos('RING', Response) > 0 then begin
            Inc(RingCounter);
            if RingCounter >= AnswerOnRing then begin
              PageStatus := rpsNewDocument;
              State := rfAnswer;

              {Show the first status here}
              ShowStatus := True;
              FaxStatus(FP, True, False);

              NewTimer(ReplyTimer, ReplyWait);
            end;
          end else if (Pos('NO C', Response) > 0) then begin
            {Report connection failure, stay in this state}
            FaxProgress := fpNoConnect;
            ForceStatus := True;
          end else if caConnectResponse(FP) then begin
            {Modem is receiving a data call}
            GotError(CPort, ecFaxDataCall);
            State := rfAbort;
          end else if Pos('VOICE', Response) > 0 then begin
            {Modem is receiving a voice call}
            GotError(CPort, ecFaxVoiceCall);
            State := rfAbort;
          end else
            caPrepResponse(FP);

        rfAnswer :
          begin
            NewTimerSecs(ReplyTimer, ReplyWait);
            caPutModem(FP, 'ATA');
            FaxProgress := fpAnswer;
            ForceStatus := True;
            if ClassInUse = ctClass1 then
              State := rf1SendCSI
            else
              State := rf2ValidConnect;
          end;

        rf1SendCSI :
          if caConnectResponse(FP) then begin
            caPutCSIFrame(FP);
            State := rf1SendDIS;
            caPrepResponse(FP);
            Critical := True;
          end else
            caPrepResponse(FP);

        rf1SendDIS :
          if caConnectResponse(FP) then begin
            caPutDCSDISFrame(FP, True);
            caPrepResponse(FP);
          end else if caOkResponse(FP) then begin
            {Delay(ExtraCommandDelay);}                                {!!.02}
            caPutFrameR(FP);
            NewTimer(ReplyTimer, Class1Wait);                          {!!.02}
            State := rf1CollectFrames;
          end else
            caPrepResponse(FP);

        rf1CollectFrames :
          if caConnectResponse(FP) then
            caPrepResponse(FP)
          else if caOkResponse(FP) then begin
            if LastFrame then begin
              caPutFaxCommand(FP, 'AT+FRM='+ModCode);
              State := rf1StartTrain;

              {$IFDEF UseSWFlow}
              if not FlagIsSet(afFlags, afNoSoftwareFlow) then
                with CPort^ do
                  SWFlowEnableOpt(CPort, InBuffLen - (InBuffLen shr 2),
                                         InBuffLen shr 2, sfReceiveFlow);
              {$ENDIF}
            end else begin
              {Ask for next frame}
              caPutFrameR(FP);
            end;
          end else
            caPrepResponse(FP);

        {!!.02 new}
        rf1Timeout :
          if caOkResponse(FP) then begin
            caPutFrameT(FP);
            State := rf1SendCSI;
          end else begin
            Inc(RetryCnt);
            caPrepResponse(FP);
          end;

        rf1StartTrain :
          if caConnectResponse(FP) then begin
            State := rf1CollectTrain;
            DataCount := 0;
            BadData := 0;
            NewTimer(ReplyTimer, ReplyWait);
            SaveStatus := GetAsyncStatus;
          end else
            caPrepResponse(FP);

        rf1CollectTrain :
          if CharReady(CPort) then begin
            SaveStatus := GetAsyncStatus;
            while CharReady(CPort) and (State = rf1CollectTrain) do begin
              GetChar(CPort, C);
              Inc(DataCount);
              if C <> #0 then
                Inc(BadData);
              if C = cDLE then begin
                Delay(10);
                GetChar(CPort, C);
                if C = cETX then begin
                  {Calculate amount of valid training data}
                  PercentBad := (BadData * LongInt(100)) div DataCount;
                  if PercentBad < MaxBadPercent then begin
                    State := rf1FinishTrain;
                    caPrepResponse(FP);
                  end else begin
                    {Failed to train, prepare to send FTT}
                    caPutFrameT(FP);
                    State := rf1Retrain;
                  end;
                end;
              end;
            end;
            SetAsyncStatus(SaveStatus);
          end;

        rf1Retrain :
          if caConnectResponse(FP) then begin
            caPutStandardFrame(FP, FTTFrame);
            if ModCode <> '24' then begin
              {Step down and try again}
              caPrepResponse(FP);
              {Stay in this state to wait for OK}
            end else begin
              {Fatal error, couldn't train at any baud rate}
              GotError(CPort, ecFaxTrainError);
              {Don't bother waiting for OK}
              State := rfAbort;
            end;
          end else if caOkResponse(FP) then begin
            {Expect DCS again}
            caPutFrameR(FP);
            State := rf1CollectFrames;
          end else
            caPrepResponse(FP);

        rf1FinishTrain :
          if caNoCarrierResponse(FP) then begin

            {$IFDEF UseSWFlow}
            {Turn off flow control for HDLC frames}
            if not FlagIsSet(afFlags, afNoSoftwareFlow) then
              SWFlowDisable(CPort);
            {$ENDIF}

            caPutFrameT(FP);
            State := rf1SendCFR;
          end else
            caPrepResponse(FP);

        rf1SendCFR :
          if caConnectResponse(FP) then begin
            caPutStandardFrame(FP, CFRFrame);
            caPrepResponse(FP);

            {$IFDEF UseSWFlow}
            {Finished with Phase B, turn on flow control}
            with CPort^ do
              SWFlowEnableOpt(CPort, InBuffLen - (InBuffLen shr 2),
                                     InBuffLen shr 2,
                                     sfReceiveFlow);
            {$ENDIF}

          end else if caOkResponse(FP) then begin
            caPutFaxCommand(FP, 'AT+FRM='+ModCode);
            State := rf1WaitPageConnect;
            Critical := False;

            {!!.01 start}
            {Not critical anymore, here's our chance to accept and log}
            if not AcceptFax(FP, RemoteID) then begin
              GotError(CPort, epNonFatal+ecFileRejected);
              ForceStatus := True;
              LogFax(FP, RemoteID, '', lfaxReceiveSkip);
              State := rfComplete;
            end else begin
              {File accepted, open file and log it}
              if OpenIncomingFile then begin
                {Log receive started}
                LogFax(FP, RemoteID, FaxFileName, lfaxReceiveStart);
                PageStatus := rpsNewPage;
                CurrPage := 0;
              end else begin
                GotError(CPort, GetAsyncStatus);
                State := rfAbort;
                goto ExitPoint;
              end;
            end;
            {!!.01 end}

          end else
            caPrepResponse(FP);

        rf1WaitPageConnect :
          if caConnectResponse(FP) then begin
            State := rfStartPage;
            FaxProgress := fpSessionParams;
            ForceStatus := True
          end else
            caPrepResponse(FP);

        rf2ValidConnect :
          if Pos('+FCON', Response) > 0 then begin
            NewTimer(ReplyTimer, ReplyWait);
            FaxProgress := fpIncoming;
            State := rf2GetSenderID;
            Critical := True;
          end else
            caPrepResponse(FP);

        rf2GetSenderID :
          if Pos('+FTSI', Response) > 0 then begin
            NewTimerSecs(ReplyTimer, ReplyWait);
            StripPrefix(Response);
            RemoteID := TrimStationID(Response);

            {Let user accept or reject this fax}
            if not AcceptFax(FP, RemoteID) then begin
              PutString(CPort, 'AT+FKS'^M);
              GotError(CPort, epNonFatal+ecFileRejected);
              ForceStatus := True;
              LogFax(FP, RemoteID, '', lfaxReceiveSkip);
              State := rfComplete;
            end else begin
              {File accepted, keep going}
              FaxProgress := fpGotRemoteID;
              ForceStatus := True;

              {Open incoming file and log now}                         {!!.01}
              if OpenIncomingFile then begin                           {!!.01}
                {Log receive started}                                  {!!.01}
                LogFax(FP, RemoteID, FaxFileName, lfaxReceiveStart);   {!!.01}
                PageStatus := rpsNewPage;                              {!!.01}
                CurrPage := 0;                                         {!!.01}
              end else begin                                           {!!.01}
                GotError(CPort, GetAsyncStatus);                       {!!.01}
                State := rfAbort;                                      {!!.01}
                goto ExitPoint;                                        {!!.01}
              end;                                                     {!!.01}
            end;
          end else if Pos('+FDCS', Response) > 0 then begin
            NewTimerSecs(ReplyTimer, ReplyWait);
            StripPrefix(Response);
            ExtractClass2Params(FP, Response);
            FaxProgress := fpSessionParams;
            ForceStatus := True;
          end else if caOkResponse(FP) then begin
            caPutModem(FP, 'AT+FDR');
            Critical := False;
            ForceStatus := True;
            State := rf2GetConnect;
            NewTimerSecs(ReplyTimer, ReplyWait);
          end else
            caPrepResponse(FP);

        rf2GetConnect :
          if Pos('+FDCS', Response) > 0 then begin
            {Got current session parameters}
            NewTimer(ReplyTimer, ReplyWait);
            StripPrefix(Response);
            ExtractClass2Params(FP, Response);
            FaxProgress := fpSessionParams;
            ForceStatus := True;
          end else if caConnectResponse(FP) then begin

            {$IFDEF UseSWFlow}
            {Finished with Phase B, turn on flow control}
            with CPort^ do
              SWFlowEnableOpt(CPort, InBuffLen - (InBuffLen shr 2),
                                     InBuffLen shr 2,
                                     sfReceiveFlow);
            {$ENDIF}

            State := rfStartPage;
            Critical := True;
          end else
            caPrepResponse(FP);

        rfStartPage :
          begin
            Critical := False;
            Inc(CurrPage);

            {Start or continue fax file}
            case PageStatus of
              rpsNewPage:
                begin
                  FillChar(PageHeader, SizeOf(PageHeader), 0);
                  if SessionRes then
                    PageHeader.ImgFlags := PageHeader.ImgFlags or ffHighRes;

                  {!!.03 - added}
                  if SessionWid then
                    PageHeader.ImgFlags := PageHeader.ImgFlags or ffHighWidth;

                  BlockWrite(InFile, PageHeader, SizeOf(PageHeader));
                  SetAsyncStatus(IoResult);
                  if GetAsyncStatus <> 0 then begin
                    GotError(CPort, GetAsyncStatus);
                    State := rfAbort;
                    goto ExitPoint;
                  end;
                end;
              rpsNewDocument:
                begin
                  Close(InFile);
                  if IOResult = 0 then ;
                  if OpenIncomingFile then begin
                    {Log receive started}
                    LogFax(FP, RemoteID, FaxFileName, lfaxReceiveStart);

                    FillChar(PageHeader, SizeOf(PageHeader), 0);
                    if SessionRes then
                      PageHeader.ImgFlags := PageHeader.ImgFlags or ffHighRes;

                    {!!.03 - added}
                    if SessionWid then
                      PageHeader.ImgFlags := PageHeader.ImgFlags or ffHighWidth;

                    BlockWrite(InFile, PageHeader, SizeOf(PageHeader));
                    SetAsyncStatus(IOResult);
                    if GetAsyncStatus <> 0 then begin
                      GotError(CPort, GetAsyncStatus);
                      State := rfAbort;
                      goto ExitPoint;
                    end;
                  end else begin
                    GotError(CPort, GetAsyncStatus);
                    State := rfAbort;
                    goto ExitPoint;
                  end;
                end;
            end;

            {Init vars for receiving a new page}
            CurrOfs := 0;
            Last := #255;
            NewTimer(ReplyTimer, ReplyWait);
            DataCount := 0;

            {Say we're ready to receive fax data}
            if ClassInUse = ctClass2 then begin
              {PutChar(CPort, cXON);}                                  {!!.01}
              PutChar(CPort, cDC2);
            end;

            {Set next state and show new status}
            State := rfGetPageData;
            FaxProgress := fpGetPage;
            ForceStatus := True;
          end;

        rfGetPageData :
          if crAddReceivedData(FP) then begin
            if GetAsyncStatus = ecOk then begin
              {Normal end of page}
              Last := #255;
              FaxProgress := fpGetPage;
              ForceStatus := True;
              caPrepResponse(FP);

              {$IFDEF UseSWFlow}
              {Finished with Phase C, turn off flow control}
              if not FlagIsSet(afFlags, afNoSoftwareFlow) then
                SWFlowDisable(CPort);
              {$ENDIF}

              if ClassInUse = ctClass1 then
                State := rf1FinishPage
              else begin
                Critical := True;
                State := rf2GetPageResult;
              end;
            end else begin
              {Error writing page}
              State := rfAbort;
              ForceStatus := True;
            end;
          end;

        rf1FinishPage :
          if caNoCarrierResponse(FP) then begin
            caPutFrameR(FP);
            State := rf1WaitEOP;
            Critical := True;
          end else
            caPrepResponse(FP);

        rf1WaitEOP :
          if caConnectResponse(FP) then
            caPrepResponse(FP)
          else if caOkResponse(FP) then begin
            if LastFrame then begin
              LastFrame := False;
              MorePages := ReceivedFrame and $FE = MPSFrame;
              State := rf1WritePage;
              FaxProgress := fpGetPageResult;
              LastPageOk := True;
              ForceStatus := True;
            end else begin
              {Ask for another frame}
              caPutFrameR(FP);
            end;
          end else
            caPrepResponse(FP);

        rf1WritePage :
          begin
            {Write received page}
            Result := WritePage;
            if Result <> ecOk then begin
              State := rfAbort;
              goto ExitPoint;
            end;

            {Prepare to send MCF}
            caPutFrameT(FP);
            State := rf1SendMCF;

            FaxProgress := fpCheckMorePages;
            LastPageOk := True;
            ForceStatus := True;
          end;

        rf1SendMCF :
          if caConnectResponse(FP) then begin
            caPutStandardFrame(FP, MCFFrame);
            caPrepResponse(FP);
          end else if caOkResponse(FP) then begin
            Critical := False;
            {Get more pages or done}
            if MorePages then begin
              {Prepare to receive another page}
              caPutFaxCommand(FP, 'AT+FRM='+ModCode);
              PageStatus := rpsNewPage;
              State := rfStartPage;
            end else begin
              {Ask for DCN}
              Delay(ExtraCommandDelay);
              caPutFrameR(FP);
              State := rf1WaitDCN;

              {No more pages, close and log this fax}
              Close(InFile);
              if IOResult = 0 then ;
              LogFax(FP, RemoteID, FaxFileName, lfaxReceiveOK);
              FaxFileName := '';

              FaxProgress := fpGetHangup;
              ForceStatus := True;
            end;
          end else
            caPrepResponse(FP);

        rf1WaitDCN :
          if caConnectResponse(FP) then
            caPrepResponse(FP)
          else if caOkResponse(FP) then begin
            if LastFrame then begin
              {hang up}
              caPutModem(FP, 'ATH0');
              State := rf1WaitHangup;
            end else
              caPutFrameR(FP);
          end else
            caPrepResponse(FP);

        rf1WaitHangup :
          if caOkResponse(FP) then begin
            FaxProgress := fpGotHangup;
            ForceStatus := True;
            State := rfComplete;
          end else
            caPrepResponse(FP);

        rf2GetPageResult :
          if Pos('+FPTS', Response) > 0 then begin
            FaxProgress := fpGetPageResult;
            ForceStatus := True;
            StripPrefix(Response);
            case Response[1] of
              '1','3','5':  {page good}
                begin
                  LastPageOk := True;
                  SetAsyncStatus(WritePage);
                  if GetAsyncStatus <> ecOk then begin
                    GotError(CPort, GetAsyncStatus);
                    State := rfAbort;
                    goto ExitPoint;
                  end;
                end;

              else  {page bad, discard}
                begin
                  LastPageOk := False;
                  if LocatePage(FP, CurrPage) <> 0 then
                    State := rfAbort
                  else begin
                    Truncate(InFile);
                    SetAsyncStatus(IOResult);
                    if GetAsyncStatus <> 0 then begin
                      GotError(CPort, GetAsyncStatus);
                      State := rfAbort;
                      goto ExitPoint;
                    end;
                  end;
                end;
            end;
          end else if Pos('+FET', Response) > 0 then begin
            FaxProgress := fpCheckMorePages;
            ForceStatus := True;
            StripPrefix(Response);
            case Response[1] of
              '0':  PageStatus := rpsNewPage;
              '1':  PageStatus := rpsNewDocument;
              '2':  PageStatus := rpsEndOfDocument;
              '3':  PageStatus := rpsMoreSame;
              else  PageStatus := rpsBadPage;
            end;
          end else if caOkResponse(FP) then begin
            Critical := False;
            caPutModem(FP, 'AT+FDR');
            if PageStatus = rpsEndOfDocument then begin
              {Close and log receive OK}
              Close(InFile);
              if IOResult = 0 then ;
              LogFax(FP, RemoteID, FaxFileName, lfaxReceiveOK);
              FaxFileName := '';

              State := rf2GetFHNG;
              FaxProgress := fpGetHangup;
              ForceStatus := True;
            end else
              State := rf2GetConnect;
          end else
            caPrepResponse(FP);

        rf2GetFHNG :
          if caFHNGResponse(FP) then begin
            HangupCode := caExtractFHNGCode(FP);
            FaxProgress := fpGotHangup;
            ForceStatus := True;
            Response := '';
          end else if Pos('+FET', Response) > 0 then begin
            {allow redundant FET}
            FaxProgress := fpGetHangup;
            ForceStatus := True;
            Response := '';
          end else if caOkResponse(FP) then
            State := rfComplete
          else
            caPrepResponse(FP);

        rfAbort :
          begin
            Critical := False;
            SaveStatus := GetAsyncStatus;

            {Log receive failed}
            if FaxFileName <> '' then begin                            {!!.02}
              if WritePage <> 0 then ;                                 {!!.02}
              Close(InFile);                                           {!!.02}
              if IoResult <> 0 then ;                                  {!!.02}
              LogFax(FP, RemoteID, FaxFileName, lfaxReceiveFail);
            end;                                                       {!!.02}

            {Try to hangup modem}
            (*if CheckDCD(CPort) then begin*)                          {!!.03}
              Delay(AbortDelay);
              PutString(CPort, '+++');
              Delay(AbortDelay);
              caPutModem(FP, 'ATH');
              Delay(AbortDelay);                                       {!!.03}
              FlushInBuffer(CPort);                                    {!!.03}
            (*end;*)                                                   {!!.03}

            if CheckDCD(CPort) then
              caFlushModem(FP);

            SetAsyncStatus(SaveStatus);

            {Finished with status}
            if ShowStatus then begin
              FaxStatus(FP, False, True);
              ShowStatus := False;
            end;

            {Exit on errors or stay?}
            if FlagIsSet(afFlags, afExitOnError) or
               (GetAsyncStatus = ecUserAbort) then begin
              State := rfDone;
              CPort^.FaxActive := False;
            end else
              State := rfInit;
          end;

        rfComplete :
          begin
            caSwitchBaud(FP, False);                                   {!!.02}

            {Finished with status}
            FaxStatus(FP, False, True);
            ShowStatus := False;

            {Finished or go look for more faxes?}
            if OneFax then begin
              State := rfDone;
              SetAsyncStatus(ecOk);
              CPort^.FaxActive := False;
            end else
              State := rfInit;
          end;
      end;

ExitPoint:
      {Assume a critical state}
      FaxReceivePartC12 := faxCritical;

      case State of
        {waiting states}
        rf1Init1,
        rf2Init1,
        rf2Init2,
        rf2Init3,
        rfWaiting,
        rf1SendCSI,
        rf1SendDIS,
        rf1CollectFrames,
        rf1StartTrain,
        rf1CollectTrain,
        rf1Retrain,
        rf1FinishTrain,
        rf1SendCFR,
        rf1WaitPageConnect,
        rf2ValidConnect,
        rf2GetSenderID,
        rf2GetConnect,
        rfGetPageData,
        rf2GetPageResult,
        rf1FinishPage,
        rf1WaitEOP,
        rf1WritePage,
        rf1SendMCF,
        rf1WaitDCN,
        rf1WaitHangup,
        rf2GetFHNG         :  if Critical then
                                FaxReceivePartC12 := faxCritical
                              else
                                FaxReceivePartC12 := faxWaiting;

        {ready states}
        rfInit,
        rfAnswer,
        rfStartPage,
        rfComplete,
        rfAbort           :  if Critical then
                               FaxReceivePartC12 := faxCritical
                             else
                               FaxReceivePartC12 := faxReady;

        rfDone            :  FaxReceivePartC12 := faxFinished;
      end;

      {Save last AsyncStatus}
      SaveStatus := GetAsyncStatus;
    end;
  end;

  procedure PrepareFaxReceivePartC12(FP : FaxRecPtr);
  begin
    with C12ReceiveFaxPtr(FP)^, CData^, PData^ do begin
      State := FirstState;
      SetAsyncStatus(ecOk);
      SaveStatus := ecOk;
      CPort^.FaxActive := True;

      {Removed in !!.02}
      {Switch to initialization baud rate}                             {!!.01}
      {caSwitchBaud(FP, False);}                                       {!!.01}

      {If Class hasn't been set yet then figure out highest class}
      if ClassInUse = ctDetect then
        if SetClassType(FP, ctDetect) = ctUnknown then begin
          SetAsyncStatus(ecUnknownModemResult);
          Exit;
        end;

      {If not sent already, send modem and def init strings}
      if not InitSent then begin
        {Send user init}
        if (ModemInit <> '') and (not caProcessModemCmd(FP, ModemInit)) then
          Exit;

        {Send required inits}
        if not caProcessModemCmd(FP, DefInit) then
          Exit;
        InitSent := True;
      end;

      {Set class}
      if (FirstState <> rf2GetSenderID) then                           {!!.01}
        if ClassInUse = ctClass1 then begin
          if not caProcessModemCmd(FP, 'AT+FCLASS=1') then
            Exit;
          caSwitchBaud(FP, True);                                      {!!.02}
        end else begin
          if not caProcessModemCmd(FP, 'AT+FCLASS=2') then
            Exit;
          caSwitchBaud(FP, True);                                      {!!.02}
          if not caProcessModemCmd(FP, 'AT+FCR=1') then                {!!.01}
            Exit;                                                      {!!.01}
          if not caProcessModemCmd(FP, 'AT+FLID="'+StationID+'"') then {!!.01}
            Exit;                                                      {!!.01}
          if not caProcessModemCmd(FP, 'AT+FAA='+FaxAndData) then      {!!.01}
            Exit;                                                      {!!.01}
        end;

      {Get class1 get modulation capabilities}
      if ClassInUse = ctClass1 then begin
        caGetClass1Modulations(FP, False);

        {Set highest BPSIndex from MaxFaxBPS and local modulation capabilities}
        Inc(BPSIndex);
        repeat
          Dec(BPSIndex)
        until Class1BPSArray[BPSIndex] <= MaxFaxBPS;
      end;

      {Removed in !!.02}
      {Switch to normal baud rate}                                     {!!.01}
      {caSwitchBaud(FP, True);}                                        {!!.01}
    end;
  end;

  procedure FaxReceiveC12(FP : FaxRecPtr);
    {-wrapper routine to receive a fax}
  begin
    with C12ReceiveFaxPtr(FP)^ do begin
      PrepareFaxReceivePartC12(FP);

      repeat
      until FaxReceivePartC12(FP) = faxFinished;
    end;
  end;

end.

