{$V-,B-,I-}
{Conditional defines that may affect this unit}
{$I APDEFINE.INC}
{$X+}
{*********************************************************}
{*                   APMODEM2.PAS 2.03                   *}
{*     Copyright (c) TurboPower Software 1995.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApModem2;
  {-Modem access}

interface

{.$DEFINE DispatchDebug}

uses
  {$IFDEF UseTPro}
  TpMemChk,
  TpDos,
  TpString,
  {$ENDIF}
  {$IFDEF UseOPro}
  OpRoot,
  OpDos,
  OpString,
  {$ENDIF}
  ApMisc,
  ApPort,
  ApTimer,
  ApCom,
  ApModDB;

{$I APMODEM2.PA0}

const
  {response constants}
  RspOK                = 1;
  RspConnect           = 2;
  RspBusy              = 3;
  RspVoice             = 4;
  RspNoCarrier         = 5;
  RspNoDialTone        = 6;
  RspError             = 7;
  RspRing              = 8;
  RspErrorCorr1        = 9;
  RspErrorCorrLast     = RspErrorCorr1 + MaxTags - 1;
  RspDataComp1         = RspErrorCorrLast + 1;
  RspDataCompLast      = RspDataComp1 + MaxTags - 1;

  TentBaudLen          = 13;  {Maximum length of a baud rate string}

type
  {string type for baud rate}
  TTentBaudStr = String[TentBaudLen];

implementation

const
  RspWaitSet  = [RspOK, RspError];
  DialWaitSet = [RspConnect, RspBusy, RspVoice, RspNoCarrier, RspNoDialTone,
                 RspError];
{$IFDEF DispatchDebug}
  DebugFileName = 'debug.rpt';

var
  DebugFile : Text;
{$ENDIF}

  {non-public modem routines}

{$IFNDEF UseOPro}
  {$IFNDEF UseTPro}
  function WordCount(S : string; WordDelims : CharSet) : Byte;
    {-Given a set of word delimiters, return number of words in S}
  var
    {I,} Count : Byte;
    I : Word;
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;

    while I <= SLen do begin
      {skip over delimiters}
      while (I <= SLen) and (S[I] in WordDelims) do
        Inc(I);

      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);

      {find the end of the current word}
      while (I <= SLen) and not(S[I] in WordDelims) do
        Inc(I);
    end;

    WordCount := Count;
  end;

  {$ENDIF}
{$ENDIF}

  function StrNewCheck(var NewSt : PStr; SrcStr : String) : Boolean;
    {-Allocate a new String on the heap, checking for available memory}

  begin
    if GetMemCheck(NewSt, Length(SrcStr) + 1) then begin
      StrNewCheck := True;
      NewSt^ := SrcStr;
    end else
      StrNewCheck := False;
  end;

  procedure StrDisposeCheck(var St : PStr);
  begin
    FreeMemCheck(St, Length(St^) + 1);
  end;

{$IFDEF DispatchDebug}

  procedure DebugOut(DebugStr : String);
    {-Writes the String to the debug file}

  begin
    Assign(DebugFile, DebugFileName);
    if not ExistFile(DebugFileName) then
      Rewrite(DebugFile)
    else
      Append(DebugFile);
    Writeln(DebugFile, DebugStr);
    if IOResult = 0 then ;
    Close(DebugFile);
    if IOResult = 0 then ;
  end;

{$ENDIF}
  procedure ShowStatus(M : ModemRecPtr; MsgType, SecsRemaining : Word);

  begin
    if (@M^.DisplayStatus <> nil) then
      M^.DisplayStatus(M, MsgType, SecsRemaining);
  end;

  procedure mEnableWaitStrs(M : ModemRecPtr; StrsToEnable : ModemResponseSet);
    {-Enable one or more modem responses and set their indexes to 0}
  var
    I : Word;

  begin
    for I := 1 to NumResponses do
      if I in StrsToEnable then
        if (M^.WaitStrings[I].WaitStr <> nil) then begin
          M^.WaitStrings[I].Enabled := True;
          M^.WaitStrings[I].Idx := 0;
        end;
  end;

  procedure mDisableWaitStrs(M : ModemRecPtr; StrsToDisable : ModemResponseSet);
    {-Disable one or more modem responses}
  var
    I : Word;

  begin
    for I := 1 to NumResponses do
      if I in StrsToDisable then
        M^.WaitStrings[I].Enabled := False;
  end;

  procedure mEnableFeatureTags(M : ModemRecPtr);
  var
    I : Word;

  begin
    for I := RspErrorCorr1 to M^.LastDCNum do begin
      M^.WaitStrings[I].Enabled    := True;
      M^.WaitStrings[I].Idx        := 0;
    end;
  end;

  procedure mDisableErrorTags(M : ModemRecPtr);
  var
    I : Word;

  begin
    for I := RspErrorCorr1 to M^.LastECNum do begin
      M^.WaitStrings[I].Enabled := False;
      M^.WaitStrings[I].Idx     := 0;
    end;
  end;

  procedure mDisableCompressTags(M : ModemRecPtr);
  var
    I : Word;

  begin
    for I := RspDataComp1 to M^.LastDCNum do
      M^.WaitStrings[I].Enabled := False;
  end;

  procedure mDisableFeatureTags(M : ModemRecPtr);

  begin
    mDisableErrorTags(M);
    mDisableCompressTags(M);
  end;

  procedure mPutXlatStr(M : ModemRecPtr; Str : String);
    {-Send a String to the modem, XLATing control chars}
  var
    I     : Word;
    Len   : Word;
    Delay : Boolean;

  begin
    SetAsyncStatus(ecOK);
    Len := Length(Str);
    if (Len = 0) then
      Exit;

    I := 1;
    Delay := True;
    while (I <= Len) do begin
      {convert special characters}
      case Str[I] of
        '^':
          if (I <> Len) and (UpCase(Str[I+1]) in ['@'..'_']) then begin
            Inc(I);
            PutChar(M^.P, Char(Ord(UpCase(Str[I])) - Ord('A') + 1));
          end else
            PutChar(M^.P, Str[I]);
        '~':
          begin
            DelayTics(M^.TildeDelay);
            Delay := False;
          end;
        else
          PutChar(M^.P, Str[I]);
      end;

      if (GetAsyncStatus <> ecOK) then
        Exit;

      Inc(I);

      if Delay and (I <> Len) then
        if (M^.ModemCharDelay <> 0) then
          DelayTics(M^.ModemCharDelay);
    end;
    M^.ModemBusy := True;
    {$IFDEF DispatchDebug}
    DebugOut('Command sent: ' + Str);
    {$ENDIF}
  end;

  function mCheckWaitStrs(M : ModemRecPtr) : Byte;
    {-Checks to see if we got a String we're looking for by taking chars from
     the buffer.}
  var
    I          : Word;
    Ch         : Char;

  begin
    mCheckWaitStrs := 0;
    if CharReady(M^.P) then begin
      GetChar(M^.P, Ch);
      {$IFDEF DispatchDebug}
      DebugOut('Got a character : ' + Ch);
      {$ENDIF DispatchDebug}
      if GetAsyncStatus = ecOK then
        for I := 1 to NumWaitStrs do
          if M^.WaitStrings[I].WaitStr <> nil then
            with M^, M^.WaitStrings[I] do
              if Enabled then
                if CheckForString(Idx, Ch, WaitStr^, True) then begin
                  mCheckWaitStrs := I;
                  if (I < RspErrorCorr1) then
                    ModemBusy := False;
                  Exit;
                end;

      WaitChar(M^.P, Ch);
    end;
    if M^.P^.UserAbort then begin
      SetAsyncStatus(ecUserAbort);
      Exit;
    end;
  end;

  function mTimedCheckWaitStrs(M : ModemRecPtr; CheckTics : Word) : Byte;
  var
    I          : Byte;
    CheckTimer : EventTimer;

  begin
    SetAsyncStatus(ecOK);
    NewTimer(CheckTimer, CheckTics);
    repeat
      I := mCheckWaitStrs(M);
      mTimedCheckWaitStrs := I;
      if I <> 0 then
        M^.TicsLeft := RemainingTime(CheckTimer);
    until TimerExpired(CheckTimer) or (GetAsyncStatus = ecUserAbort) or
      (I <> 0);

    if (TimerExpired(CheckTimer)) and (I = 0) then
      SetAsyncStatus(ecTimeOut);
  end;

  function mHandleCommandResponse(M : ModemRecPtr;
                                  Wait : Boolean) : Boolean;
    {-Wait for an OK or ERROR response from the modem}
  var
    RspNum : Byte;

  begin
    mHandleCommandResponse := False;
    {set AsyncStatus according to what String we get back}
    if Wait then
      RspNum := mTimedCheckWaitStrs(M, M^.CmdTimeOut)
    else
      RspNum := mCheckWaitStrs(M);
    if GetAsyncStatus = ecOK then
      case RspNum of
        RspOK :
          begin
            mHandleCommandResponse := True;
            SetAsyncStatus(ecOK);
          end;
        RspError :
          begin
            mHandleCommandResponse := True;
            SetAsyncStatus(ecError);
          end;
      end;

    mDisableWaitStrs(M, RspWaitSet);
  end;

  procedure mHandleConnectionAttemptResponse(M : ModemRecPtr; Dialing : Boolean;
                                             Wait : Boolean);
    {-The modem is attempting to connect, be it via an answer or
      a dial.  This routine processes the responses that can
      be returned during a connect attempt}
  var
    TimeLeft : Word;
    ChkNum   : Byte;

    procedure CheckForTags(TagNum : Byte);
      {-checks to see if the character is in an error correction or
       data compression tag}

    begin
      with M^ do begin
        if TagNum in [RspErrorCorr1..LastECNum] then begin
          mDisableErrorTags(M);
          ErrorCorrection := True;
          ShowStatus(M, ecGotErrorCorrection, TimeLeft);
        end;

        if TagNum in [RspDataComp1..LastDCNum] then begin
           mDisableCompressTags(M);
           DataCompression := True;
           ShowStatus(M, ecGotDataCompression, TimeLeft);
         end;
      end;
    end;

    procedure AbortConnectAttempt(SendCancel : Boolean);
      {-Disable responses and feature tags and then optionally send the cancel
        command to the modem}

    begin
        {$IFDEF DispatchDebug}
        DebugOut('Aborting connect attempt');
        {$ENDIF}

        {-send the cancel command to the modem if necessary}
        if SendCancel then begin
          DelayTics(M^.DelayFactor * 2);
          mPutXlatStr(M, M^.DialCancel^);
          DelayTics(M^.DelayFactor);
        end;

        mDisableWaitStrs(M, DialWaitSet);
        mDisableFeatureTags(M);
        M^.ConnectSpeed := 0;
    end;

    procedure EstablishConnection(var TimeLeft : Word);
      {-After we've connected, we start waiting for the baud rate and any
        remaining feature tags}
    var
      I            : Word;
      Started      : Boolean;
      GotBaudRate  : Boolean;
      Code         : Word;
      CurrBaud     : LongInt;
      CurrDataBits : DataBitType;
      CurrStopBits : StopBitType;
      CurrParity   : ParityType;
      Ch           : Char;
      BaudTimer    : EventTimer;
      FeatureTimer : EventTimer;
      ChkNum       : Byte;
      TentBaudRate : TTentBaudStr;

    begin
      {$IFDEF DispatchDebug}
      DebugOut('Establishing a connection');
      {$ENDIF}
      Started := False;
      GotBaudRate := False;
      mDisableWaitStrs(M, DialWaitSet);

      {start waiting for baud rate}
      TentBaudRate := '';
      NewTimer(BaudTimer, M^.BaudWait);

      repeat
        if CharReady(M^.P) then begin
          GetChar(M^.P, Ch);
          {$IFDEF DispatchDebug}
          DebugOut('Got a character : ' + Ch);
          {$ENDIF DispatchDebug}

          if not Started then begin
            if (Ch in ['0'..'9']) then begin
              TentBaudRate := Ch;
              Started := True;
            end;
          end else
            if not (Ch in ['0'..'9']) then
              GotBaudRate := True
            else
              TentBaudRate := TentBaudRate + Ch;
        end;
        if GetAsyncStatus = ecTimeOut then
          Exit;
        if M^.P^.UserAbort then begin
          SetAsyncStatus(ecUserAbort);
          Exit;
        end;
      until GotBaudRate or (TimerExpired(BaudTimer));

      {convert baud rate and inform user that we got it}
      if TentBaudRate <> '' then begin
        Val(TentBaudRate, M^.ConnectSpeed, Code);
        ShowStatus(M, ecGotBaud, TimeLeft);
      end;

      {change the line speed if LockDTE is false}
      with M^ do begin
        if not LockDTE then begin
          GetLine(P, CurrBaud, CurrParity, CurrDataBits, CurrStopBits, True);
          if not GotBaudRate then
            SetLine(P, 300, CurrParity, CurrDataBits, CurrStopBits)
          else
            SetLine(P, ConnectSpeed, CurrParity, CurrDataBits, CurrStopBits);
        end;

        {check to see if any error correction or data comp tags came just now}
        for I := RspErrorCorr1 to LastDCNum do
          WaitStrings[I].Idx := 0;
        NewTimer(FeatureTimer, FeatureWait);

        repeat
          ChkNum := mTimedCheckWaitStrs(M, FeatureWait);
          if GetAsyncStatus = ecOK then
            CheckForTags(ChkNum);
        until (ErrorCorrection and DataCompression) or (TimerExpired(FeatureTimer));
      end;
    end;

    procedure ProcessResults;

    begin
      if GetAsyncStatus = ecOK then
        case ChkNum of
          RspConnect:
            begin
              ShowStatus(M, ecConnect, TimeLeft);
              EstablishConnection(TimeLeft);
              SetAsyncStatus(ecConnect);
            end;

          RspBusy:
            begin
              AbortConnectAttempt(True);
              SetAsyncStatus(ecBusy);
              ShowStatus(M, ecBusy, TimeLeft);
            end; {RspBusy}

          RspVoice:
            begin
              AbortConnectAttempt(False);
              SetAsyncStatus(ecVoice);
              ShowStatus(M, ecVoice, TimeLeft);
            end; {RspVoice}


          RspNoCarrier:
            begin
              AbortConnectAttempt(False);
              SetAsyncStatus(ecNoCarrier);
              ShowStatus(M, ecNoCarrier, TimeLeft);
            end; {RspNoCarrier}

          RspNoDialTone:
            begin
              AbortConnectAttempt(False);
              SetAsyncStatus(ecNoDialTone);
              ShowStatus(M, ecNoDialTone, TimeLeft);
            end; {RspNoDialTone}

          RspError:
            begin
              AbortConnectAttempt(False);
              SetAsyncStatus(ecError);
              ShowStatus(M, ecError, TimeLeft);
            end; {RspError}

          else
            CheckForTags(ChkNum);
        end; {case ResponseCode}
    end;


  begin
    {$IFDEF DispatchDebug}
    DebugOut('Entering the connection attempt procedure');
    {$ENDIF DispatchDebug}

    SetAsyncStatus(ecOK);
    {initialize the time remaining and the done variable before entering loop}
    if Wait then begin
      if Dialing then
        TimeLeft := M^.DialTimeOut
      else
        TimeLeft := M^.AnswerTimeOut;

      {$IFDEF DispatchDebug}
      DebugOut('Starting the repeat loop with connection attempt.');
      {$ENDIF DispatchDebug}
      repeat
        ChkNum := mTimedCheckWaitStrs(M, TicsPerSec);
        ProcessResults;
        if GetAsyncStatus = ecTimeOut then begin
          Dec(TimeLeft);
          ShowStatus(M, ecTimeUpd, TimeLeft);
          SetAsyncStatus(ecOK);
        end;

      until (GetAsyncStatus <> ecOK) or (TimeLeft = 0);

      if TimeLeft = 0 then
        SetAsyncStatus(ecTimeOut);
    end else begin
      ChkNum := mCheckWaitStrs(M);
      ProcessResults;
    end;

    if GetAsyncStatus = ecUserAbort then begin
      AbortConnectAttempt(True);
      SetAsyncStatus(ecUserAbort);
    end;
  end;

  procedure mWaitForRing(M : ModemRecPtr; NumRings : Word);
    {-Waits until NumRings rings come in, then tries to answer}
  var
    RingWait  : Word;
    CountDown : EventTimer;
    RspNum    : Byte;
    Finished  : Boolean;
    {$IFDEF DispatchDebug}
    DidDebug  : Boolean;
    {$ENDIF}

  begin
    RingWait := NumRings;
    Finished := False;
    {$IFDEF DispatchDebug}
    DebugOut('Now entering AutoAnswer mode...');
    {$ENDIF DispatchDebug}

    repeat
      RspNum := mTimedCheckWaitStrs(M, RingWait);
      if GetAsyncStatus = ecOK then
        case RspNum of
          RspRing :
            begin
              {$IFDEF DispatchDebug}
              DebugOut('Got a RING');
              DidDebug := False;
              {$ENDIF}
              Dec(RingWait);
              NewTimer(CountDown, M^.RingWaitTimeOut);

              if (RingWait = 0) then begin
                {$IFDEF DispatchDebug}
                DebugOut('Got the LAST ring, starting answer');
                {$ENDIF}
                mDisableWaitStrs(M, [RspRing]);
                Answer(M, True);
                if GetAsyncStatus = ecConnect
                  then Finished := True;
              end;
            end;
          RspError :
            begin
              SetAsyncStatus(ecError);
              Finished := True;
            end;
        end
      else
        if GetAsyncStatus = ecUserAbort then
          Finished := True;
      if TimerExpired(CountDown) then begin
        {$IFDEF DispatchDebug}
        if not DidDebug then begin
          DebugOut('Resetting dial count...');
          DidDebug := True;
        end;
        {$ENDIF}
        RingWait := NumRings;
      end;
    until Finished;

  end;
{******************************************************************************}

  procedure InitModem(var M : ModemRecPtr; Port : PortRecPtr; var Data : ModemData);
    {-Initialize the modem}
  var
    I : Word;

  begin
    if not GetMemCheck(M, SizeOf(ModemRec)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    FillChar(M^, SizeOf(ModemRec), 0);

    {initialize pointers in structure}
    with M^ do begin
      if not StrNewCheck(InitCmd, Data.Data.InitCmd) or
         not StrNewCheck(DialCmd, Data.Data.DialCmd) or
         not StrNewCheck(DialTerm, Data.Data.DialTerm) or
         not StrNewCheck(DialCancel, Data.Data.DialCancel) or
         not StrNewCheck(HangupCmd, Data.Data.HangupCmd) or
         not StrNewCheck(ConfigCmd, Data.Data.ConfigCmd) or
         not StrNewCheck(AnswerCmd, Data.Data.AnswerCmd) or
         not StrNewCheck(WaitStrings[RspOk].WaitStr, Data.Data.OkMsg) or
         not StrNewCheck(WaitStrings[RspConnect].WaitStr, Data.Data.ConnectMsg) or
         not StrNewCheck(WaitStrings[RspBusy].WaitStr, Data.Data.BusyMsg) or
         not StrNewCheck(WaitStrings[RspVoice].WaitStr, Data.Data.VoiceMsg) or
         not StrNewCheck(WaitStrings[RspNoCarrier].WaitStr, Data.Data.NoCarrierMsg) or
         not StrNewCheck(WaitStrings[RspNoDialTone].WaitStr, Data.Data.NoDialToneMsg) or
         not StrNewCheck(WaitStrings[RspError].WaitStr, Data.Data.ErrorMsg) or
         not StrNewCheck(WaitStrings[RspRing].WaitStr, Data.Data.RingMsg) then begin
        DoneModem(M);
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;

    {allocate memory for data compression and error correction Strings}
      LastECNum := RspErrorCorr1 + Data.NumErrors - 1;
      for I := RspErrorCorr1 to LastECNum do
        if not StrNewCheck(WaitStrings[I].WaitStr, Data.Errors[(I - RspErrorCorr1 + 1)]) then begin
          DoneModem(M);
          SetAsyncStatus(ecOutOfMemory);
          Exit;
        end;

      LastDCNum := RspDataComp1 + Data.NumComps - 1;
      for I := RspDataComp1 to LastDCNum do
        if not StrNewCheck(WaitStrings[I].WaitStr, Data.Compression[I - RspDataComp1 + 1]) then begin
          DoneModem(M);
          SetAsyncStatus(ecOutOfMemory);
          Exit;
        end;

      {assign fields to default values}
      DialTimeout     := DefDialTimeout;
      AnswerTimeout   := DefAnswerTimeout;
      DelayFactor     := DefDelayFactor;
      CmdTimeout      := DefCmdTimeout;
      DTRDropHold     := DefDTRDropHold;
      ModemCharDelay  := DefModemCharDelay;
      TildeDelay      := DefTildeDelay;
      RingWaitTimeout := DefRingWaitTimeout;
      FeatureWait     := DefFeatureWait;
      BaudWait        := DefBaudWait;
      LockDTE         := Data.LockDTE;
      ErrorCorrection := False;
      DataCompression := False;
      ConnectSpeed    := 300;

      SetAsyncStatus(ecOK);
      P := Port;
      @DisplayStatus := nil;
    end;

{$IFDEF DispatchDebug}
    Assign(DebugFile, DebugFileName);
    Erase(DebugFile);
    if IOResult = 0 then ;
    Close(DebugFile);
    if IOResult = 0 then ;
{$ENDIF}
  end;

  procedure DoneModem(var M : ModemRecPtr);
    {-Destroy a modem}
  var
    I : Word;

  begin
    with M^ do begin
      StrDisposeCheck(InitCmd);
      StrDisposeCheck(DialCmd);
      StrDisposeCheck(DialTerm);
      StrDisposeCheck(DialCancel);
      StrDisposeCheck(HangupCmd);
      StrDisposeCheck(ConfigCmd);
      StrDisposeCheck(AnswerCmd);

      for I := 1 to NumWaitStrs do
        if WaitStrings[I].WaitStr <> nil then
          StrDisposeCheck(WaitStrings[I].WaitStr);
    end;
    FreeMemCheck(M, SizeOf(ModemRec));
  end;

  procedure SetDialTimeout(M : ModemRecPtr; Secs : Word);
    {-Set the number of seconds before a dial attempt times out}
  begin
    M^.DialTimeOut := Secs;
  end;

  function mGetDialTimeout(M : ModemRecPtr) : Word;
    {-Get the number of seconds before the modem aborts a dial attempt}
  begin
    mGetDialTimeOut := M^.DialTimeOut;
  end;

  procedure SetAnswerTimeout(M : ModemRecPtr; Secs : Word);
    {-Set the number of seconds before an answer attempt times out}
  begin
    M^.AnswerTimeOut := Secs;
  end;

  procedure SetDelayFactor(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to wait between commands sent to the modem}
  begin
    M^.DelayFactor := Tics;
  end;

  procedure SetCmdTimeout(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to wait for a modem response}
  begin
    M^.CmdTimeOut := Tics;
  end;

  procedure SetDTRDropHold(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to hold DTR low during hangup}
  begin
    M^.DTRDropHold := Tics;
  end;

  procedure SetCharDelay(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to wait between each command character sent}
  begin
    M^.ModemCharDelay := Tics;
  end;

  procedure SetTildeDelay(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to wait when a '~' is encountered in a command}
  begin
    M^.TildeDelay := Tics;
  end;

  procedure SetRingWaitTimeout(M : ModemRecPtr; Tics : Word);
    {-Set the number of Tics to wait before mAutoAnswerModem resets}
  begin
    M^.RingWaitTimeOut := Tics;
  end;

  procedure SetStatusProc(M : ModemRecPtr; MSP : ModemStatusProc);

  begin
    M^.DisplayStatus := MSP;
  end;

  procedure PutCommand(M : ModemRecPtr; Cmd : String; Wait : Boolean);
    {-Send a command to the modem}
  begin
    if M^.ModemBusy then begin
      SetAsyncStatus(ecModemBusy);
      Exit;
    end;
    {enable response codes}
    mEnableWaitStrs(M, RspWaitSet);

    {send the command to the modem}
    mPutXlatStr(M, Cmd);
    if (GetAsyncStatus <> ecOK) then begin
      mDisableWaitStrs(M, RspWaitSet);
      Exit;
    end;

    with M^ do begin
      ModemBusy := True;
      NewTimer(ResponseTimer, CmdTimeOut);
    end;

    mHandleCommandResponse(M, Wait);
  end;

  procedure Initialize(M : ModemRecPtr; Wait : Boolean);
    {-Send the initialization String to the modem}
  begin
    PutCommand(M, M^.InitCmd^, Wait);
  end;

  function NumConfigStrings(M : ModemRecPtr) : Word;
    {-Returns number of command strings with configuration string}
  begin
    NumConfigStrings := WordCount(M^.ConfigCmd^, [CmdSepChar]);
  end;

  function GetConfigString(M : ModemRecPtr; StrNum : Word) : CmdStrType;
    {-Returns command string from configuration string}
  begin
    if (StrNum > NumConfigStrings(M)) then
      GetConfigString := ''
    else
      GetConfigString := ExtractWord(StrNum, M^.ConfigCmd^, [CmdSepChar]);
  end;

  procedure Configure(M : ModemRecPtr);
    {-Send the configuration Strings to the modem}
  var
    I        : Integer;
    HadError : Boolean;

  begin
    HadError := False;
    for I := 1 to NumConfigStrings(M) do begin
      PutCommand(M, GetConfigString(M, I), False);

      if (GetAsyncStatus <> ecOK) and (GetAsyncStatus <> ecError) then
        Exit;
      if GetAsyncStatus = ecError then
        HadError := True;

      DelayTics(M^.DelayFactor);
    end;

    if HadError then
      SetAsyncStatus(ecError)
    else
      SetAsyncStatus(ecOK);
  end;

  procedure Hangup(M : ModemRecPtr; Wait : Boolean);
    {-Send hangup command to modem}
  begin
    with M^ do begin
      ConnectSpeed := 0;

      {check to see if we want to drop DTR or not}
      if (HangupCmd^ = '') or (StUpCase(HangupCmd^) = 'DTR') then begin
        {$IFDEF DispatchDebug}
        DebugOut('Entering DropDTR state');
        {$ENDIF}
        SetDTR(P, False);
        if (GetAsyncStatus <> ecOK) then
          Exit;

        DelayTics(DTRDropHold);

        {$IFDEF DispatchDebug}
        DebugOut('Restablishing DTR');
        {$ENDIF}
        SetDtr(P, True);
      end else
        PutCommand(M, HangupCmd^, Wait);
    end;
  end;

  procedure mDialAnswer(M : ModemRecPtr; Number : String; IsDialing : Boolean;
                        Wait : Boolean);
  {-Dials or answers, depending upon IsDialing}
  begin
    if M^.ModemBusy then begin
      SetAsyncStatus(ecModemBusy);
      Exit;
    end;

    if IsDialing then
      if Number = '' then begin
        SetAsyncStatus(epNonFatal + ecInvalidArgument);
        Exit;
      end;

    {initialize dialing variables}
    with M^ do begin
      ErrorCorrection := False;
      DataCompression := False;
      ConnectSpeed    := 0;


      {enable dial response codes}
      mEnableWaitStrs(M, DialWaitSet);
      mEnableFeatureTags(M);

      {send the dial command}
      if IsDialing then begin
        {$IFDEF DispatchDebug}
        DebugOut('Sending dial command');
        {$ENDIF}
        mPutXlatStr(M, DialCmd^);
        if (GetAsyncStatus = ecOK) then begin
          mPutXlatStr(M, Number);
          if (GetAsyncStatus = ecOK) then
            mPutXlatStr(M, DialTerm^);
        end;
        NewTimer(ResponseTimer, Secs2Tics(DialTimeOut));
      end else begin
        mPutXlatStr(M, AnswerCmd^);
        NewTimer(ResponseTimer, Secs2Tics(AnswerTimeOut));
      end;
    end;

    if (GetAsyncStatus <> ecOK) then begin
      mDisableWaitStrs(M, DialWaitSet);
      mDisableFeatureTags(M);
      Exit;
    end;

    M^.ModemBusy := True;
    mHandleConnectionAttemptResponse(M, IsDialing, Wait);
  end;

  procedure Dial(M : ModemRecPtr; Number : String; Wait : Boolean);
    {-Dial the modem}
  begin
    mDialAnswer(M, Number, True, Wait);
  end;

  procedure SendCancel(M : ModemRecPtr);
    {-Sends the cancel command to the modem}
  begin
    with M^ do begin
      mPutXlatStr(M, DialCancel^);
      DelayTics(DelayFactor);
      ModemBusy := False;
    end;
  end;

  function GetConnectSpeed(M : ModemRecPtr) : LongInt;
    {-Get the actual speed of the connection}
  begin
    GetConnectSpeed := M^.ConnectSpeed;
  end;

  function GetErrorCorrection(M : ModemRecPtr) : Boolean;

  begin
    GetErrorCorrection := M^.ErrorCorrection;
  end;

  function GetDataCompression(M : ModemRecPtr) : Boolean;

  begin
    GetDataCompression := M^.DataCompression;
  end;

  function ModemWorking(M : ModemRecPtr) : Boolean;

  begin
    ModemWorking := M^.ModemBusy;
  end;

  procedure Answer(M : ModemRecPtr; Wait : Boolean);
    {-Answer the modem}
  begin
    mDialAnswer(M, '', False, Wait);
  end;

  procedure AutoAnswer(M : ModemRecPtr; Rings : Word);
    {-Answer the modem after Rings rings}
  begin
    if M^.ModemBusy then begin
      SetAsyncStatus(ecModemBusy);
      Exit;
    end;

    if (Rings = 0) then begin
      SetAsyncStatus(epNonFatal + ecInvalidArgument);
      Exit;
    end;

    mEnableWaitStrs(M, [RspRing]);
    mEnableFeatureTags(M);

    SetAsyncStatus(ecOK);
    mWaitForRing(M, Rings);
  end;

  function ProcessCommandResponse(M : ModemRecPtr) : Boolean;
  begin
    with M^ do
      if not ModemBusy then begin
        SetAsyncStatus(ecModemNotBusy);
        ProcessCommandResponse := True;
      end else
        if TimerExpired(ResponseTimer) then begin
          ProcessCommandResponse := False;
          SetAsyncStatus(ecTimeOut);
          ModemBusy := False;
        end else
          ProcessCommandResponse := mHandleCommandResponse(M, False);
  end;

  procedure ProcessConnectResponse(M : ModemRecPtr);
  begin
    with M^ do
      if not ModemBusy then
        SetAsyncStatus(ecModemNotBusy)
      else
        if TimerExpired(ResponseTimer) then begin
          ModemBusy := False;
          SetAsyncStatus(ecTimeOut);
        end else
          mHandleConnectionAttemptResponse(M, True, False);
  end;

end.
