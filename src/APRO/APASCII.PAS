{$S-,R-,I-,O+,F+}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{Include OPro's define file if UseOPro is specified}
{$IFDEF UseOPro}
{$I OPDEFINE.INC}
{$ENDIF}

{*********************************************************}
{*                 APASCII.PAS 2.03                      *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApAscii;
  {-Provides ASCII recieve and transmit functions}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpInline,
  OpString,
  OpRoot,
  OpDate,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpInline,
  TpString,
  TpDate,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  {$ELSE}
  ApPort,
  ApTimer,
  ApMisc,
  ApCom,
  {$ENDIF}
  ApAbsPcl;

{$I APASCII.PA0}

implementation

  procedure InitAscii(var P : ProtocolRecPtr;
                      PortPtr : PortRecPtr);
    {-Allocates and initializes a protocol control block}
  begin
    InitCustomAscii(P, PortPtr,
                    DefInterCharDelay, DefInterLineDelay,
                    DefProtocolOptions);
  end;

  procedure InitCustomAscii(var P : ProtocolRecPtr;
                            PortPtr : PortRecPtr;
                            InterCharDelay, InterLineDelay : Word;
                            Options : Word);
    {-Allocates and initializes a protocol control block}
  var
    AP : AsciiProtocolPtr absolute P;
    Temp : ProtocolDataPtr;
  begin
    SetAsyncStatus(ecOk);

    {Allocate the protocol data record}
    InitProtocolData(Temp, PortPtr, Options);
    if GetAsyncStatus <> ecOk then
      Exit;

    {Allocate the ascii protocol record}
    if not GetMemCheck(AP, SizeOf(AsciiProtocol)) then begin
      DoneProtocolData(Temp);
      GotError(PortPtr, epFatal+ecOutOfMemory);
      Exit;
    end;

    with AP^ do begin
      PData := Temp;

      {Get a protocol DataBlock}
      if not GetMemCheck(DataBlock, SizeOf(DataBlockType)) then begin
        DoneProtocolData(Temp);
        FreeMemCheck(AP, SizeOf(AsciiProtocol));
        GotError(PData^.PR, epFatal+ecOutOfMemory);
        Exit;
      end;

      PData^.ProtType := Ascii;
      apInterCharDelay := InterCharDelay;
      apInterLineDelay := InterLineDelay;
      apEOLChar        := DefEOLChar;
      CtrlZEncountered := False;
      RcvTimeout       := DefRcvTimeout;
      MaxAccumDelay    := DefMaxAccumDelay;

      {Pick an arbitrary block size}
      PData^.BlockLen := DefBlockLen;
    end;
  end;

  procedure DoneAscii(var P : ProtocolRecPtr);
    {-Disposes of the protocol record}
  begin
    with P^ do begin
      DoneProtocolData(P^.PData);
      FreeMemCheck(AsciiProtocolPtr(P)^.DataBlock, SizeOf(DataBlockType));
      FreeMemCheck(P, SizeOf(AsciiProtocol));
    end;
  end;

  procedure SetDelays(P : ProtocolRecPtr; InterCharDelay, InterLineDelay : Word);
    {-Set the delay (in ms) between each character and each line}
  var
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^ do begin
      apInterCharDelay := InterCharDelay;
      apInterLineDelay := InterLineDelay;
    end;
  end;

  procedure SetEOLChar(P : ProtocolRecPtr; C : Char);
    {-Set the character used to mark the end of line}
  begin
    AsciiProtocolPtr(P)^.apEOLChar := C;
  end;

  function GetLineNumber(P : ProtocolRecPtr) : LongInt;
    {-Return the current line number}
  begin
    GetLineNumber := P^.PData^.BlockNum;
  end;

  function HandleAbort(P : ProtocolRecPtr) : Boolean;
    {-Calls user abort function, aborts protocol and returns True if aborting}
  begin
    with P^, PData^ do begin
      if PR^.UserAbort then begin
        SetAsyncStatus(ecUserAbort);
        HandleAbort := True;
      end else
        HandleAbort := False;
    end;
  end;

  function SendBlockPart(P : ProtocolRecPtr;
                         var Block : DataBlockType) : Boolean;
    {-Transmits one data block, handling delays}
  var
    C : Char;
    AccumDelay : Byte;
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^, PData^ do begin
      {Assume not finished}
      SendBlockPart := False;

      AccumDelay := 0;
      repeat
        C := Block[SendIndex];

        {Check for ^Z exit}
        if (C = ^Z) and FlagIsSet(apFlags, apSuppressCtrlZ) then begin
          SendBlockPart := True;
          Exit;
        end;

        {Send the character}
        PutChar(PR, C);
        Inc(SendIndex);
        Inc(BytesTransferred);

        {Handle char delay}
        if apInterCharDelay > 0 then begin
          Delay(apInterCharDelay);
          Inc(AccumDelay);
          if AccumDelay > MaxAccumDelay then
            Exit;
        end;

        {Handle line delay}
        if (C = apEOLChar) and (apInterLineDelay > 0) then begin
          Delay(apInterLineDelay);
          Inc(AccumDelay);
          if AccumDelay > MaxAccumDelay then
            Exit;
        end;
      until (SendIndex > LastBlockSize);
      SendBlockPart := True;
    end;
  end;

  procedure ReceiveBlock(P : ProtocolRecPtr;
                         var Block : DataBlockType;
                         var BlockSize : Word;
                         var HandShake : Char);
    {-Receive block into Buffer}
  var
    I : Word;
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^, PData^ do begin
      {Check for ^Z}
      for I := 1 to BlockSize do begin
        if Block[I] = ^Z then begin
          BlockSize := I;
          CtrlZEncountered := True;
        end;
      end;

      {Update data areas and show status}
      Inc(BytesTransferred, BlockSize);
      Dec(BytesRemaining, BlockSize);
      if BytesRemaining < 0 then
        BytesRemaining := 0;
      ElapsedTics := ElapsedTime(Timer);
    end;
  end;

  procedure PrepareTransmitPartAS(P : ProtocolRecPtr);
    {-Starts Ascii protocol transmit}
  var
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^, PData^ do begin
      {Do parent inits}
      FindingFirst := True;
      FileListIndex := 0;
      PR^.ProtocolActive := True;
      SetAsyncStatus(ecOk);

      {Do startup and init stuff}
      ResetStatus(P);
      ShowFirstStatus(P);
      CtrlZEncountered := False;
      BlockNum := 0;
      FindingFirst := True;

      {Transmit one file}
      if not NextFile(P, Pathname) then begin
        {AsyncStatus already set}
        ShowLastStatus(P);
        PR^.ProtocolActive := False;
        Exit;
      end;

      ForceStatus := True;
      AsciiState := taInitial;
      {DataBlock := nil;}                                              {!!.01}
    end;
  end;

  function ProtocolTransmitPartAS(P : ProtocolRecPtr) : ProtocolStateType;
    {-Performs one increment of a protocol transmit and returns}
  label
    ExitPoint;
  var
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^, PData^ do begin
      {Check for user abort}
      if HandleAbort(P) then begin
        AsciiState := taFinished;
        ForceStatus := False;
      end;

      {Show status periodically}
      if TimerExpired(StatusTimer) or ForceStatus then begin
        ForceStatus := False;
        NewTimer(StatusTimer, StatusInterval);
        apUserStatus(P, False, False);
      end;

      {Process current state}
      case AsciiState of
        taInitial :
          begin
            {Reset status vars}
            ResetStatus(P);
            NoMoreData := False;

            {!!.01 moved to init}
            {Get a protocol DataBlock}
            {if not GetMemCheck(DataBlock, SizeOf(DataBlockType)) then begin
              GotError(PR, epFatal+ecOutOfMemory);
              ShowLastStatus(P);
              ProtocolTransmitPartAS := psFinished;
              PR^.ProtocolActive := False;
              Exit;
            end;}

            {Pathname must already be set before we get here}
            Pathname := StUpcase(Pathname);

            {Show file name to user logging routine}
            LogFile(P, lfTransmitStart);

            {Go prepare for reading protocol blocks}
            apPrepareReading(P);
            if GetAsyncStatus <> ecOk then begin
              AsciiState := taFinished;
              goto ExitPoint;
            end;

            {Start sending blocks}
            FileOfs := 0;
            AsciiState := taGetBlock;
            NewTimer(Timer, 1);
          end;

        taGetBlock :
          begin
            LastBlockSize := BlockLen;
            NoMoreData := apReadProtocolBlock(P, DataBlock^, LastBlockSize);
            AsciiState := taWaitFreespace;
            NewTimer(ReplyTimer, TransTimeout);
            SendIndex := 1;
          end;

        taWaitFreeSpace :
          begin
            if OutBuffFree(PR) > BlockLen then
              AsciiState := taSendBlock
            else if TimerExpired(ReplyTimer) then begin
              {Must be buffer full error}
              GotError(PR, epFatal+ecBufferIsFull);
              AsciiState := taFinished;
            end;
          end;

        taSendBlock :
          begin
            {Don't send empty blocks (will only happen with empty files)}
            if LastBlockSize <= 0 then
              AsciiState := taFinished
            else begin
              {If no errors, then send this block to the remote}
              if GetAsyncStatus = ecOk then begin
                if SendBlockPart(P, DataBlock^) then begin

                  {If SendBlockPart failed, go clean up}
                  if GetAsyncStatus <> ecOk then begin
                    FlushOutBuffer(PR);
                    AsciiState := taFinished;
                    goto ExitPoint;
                  end;

                  {Adjust block number and file position}
                  Inc(BlockNum);
                  Inc(FileOfs, BlockLen);

                  {Go get next block to send}
                  if NoMoreData then begin
                    AsciiState := taFinishDrain;
                    NewTimer(ReplyTimer, TransTimeout);
                  end else
                    AsciiState := taGetBlock;

                  {Force a status update}
                  ForceStatus := True;
                  ElapsedTics := ElapsedTime(Timer);
                end;
              end else begin
                {Most likely a disk read error, have to give up}
                AsciiState := taFinished;
              end;
            end;
          end;

        taFinishDrain :
          begin
            if OutBuffUsed(PR) <= 1 then begin
              AsciiState := taFinished;
              SetAsyncStatus(ecEndFile);
            end;
            if TimerExpired(ReplyTimer) then begin
              GotError(PR, epNonFatal+ecTimeout);
              AsciiState := taFinished;
            end;
          end;

        taFinished :
          begin
            if GetAsyncStatus = ecCancelRequested then
              FlushInBuffer(PR);

            {Close the file (or whatever was giving us blocks)}
            apFinishReading(P);

            {Show status, user logging, and clean up}
            if GetAsyncStatus = ecEndFile then begin
              SetAsyncStatus(ecOk);
              LogFile(P, lfTransmitOk)
            end else
              LogFile(P, lfTransmitFail);
            ShowLastStatus(P);

            {FreeMemCheck(DataBlock, SizeOf(DataBlockType));}          {!!.01}
            AsciiState := taDone;
            PR^.ProtocolActive := False;
          end;
      end;

  ExitPoint:
      {Set function result}
      case AsciiState of
        taInitial,
        taGetBlock,
        taSendBlock,
        taFinished             : ProtocolTransmitPartAS := psReady;

        taFinishDrain,
        taWaitFreeSpace        : ProtocolTransmitPartAS := psWaiting;

        taDone                 : ProtocolTransmitPartAS := psFinished;
      end;
    end;
  end;

  procedure ProtocolTransmitAS(P : ProtocolRecPtr);
    {-Starts Ascii protocol transmit}
  var
    AS : AsciiProtocolPtr absolute P;
    State : ProtocolStateType;
  begin
    with AS^, PData^ do begin
      PrepareTransmitPartAS(P);
      if GetAsyncStatus <> ecOk then
        Exit;

      AsciiState := taInitial;
      repeat
        State := ProtocolTransmitPartAS(P);
        if State = psWaiting then
          UserBack(P);
      until State = psFinished;
    end;
  end;

  procedure PrepareReceivePartAS(P : ProtocolRecPtr);
    {-Prepare for calling ProtocolReceivePart}
  var
    AP : AsciiProtocolPtr absolute P;
  begin
    with AP^, PData^ do begin
      {Do parent inits}
      PR^.ProtocolActive := True;
      GotOneFile := False;
      SetAsyncStatus(ecOk);

      {Prepare to enter state machine}
      TimerPending := False;
      AsciiState := raInitial;
      {DataBlock := nil;}                                              {!!.01}
      ResetStatus(P);
      SetAsyncStatus(ecOk);
      ShowFirstStatus(P);
    end;
  end;

  function ProtocolReceivePartAS(P : ProtocolRecPtr) : ProtocolStateType;
    {-Performs one increment of a protocol receive and returns}
  label
    ExitPoint;
  var
    AP : AsciiProtocolPtr absolute P;
    C : Char;
    BlockSize : Word;
    Error : Boolean;
    Handshake : Char;
    SaveStatus : Word;
    Aborted : Boolean;                                                 {!!.02}
  begin
    with AP^, PData^ do begin
      {Check for user abort}
      if AsciiState <> raFinished then                                 {!!.02}
        if HandleAbort(P) then begin
          AsciiState := raProcessBlock;                                {!!.02}
          SetAsyncStatus(ecEndFile);
          ForceStatus := False;
          Aborted := True;                                             {!!.02}
        end else                                                       {!!.02}
          Aborted := False;                                            {!!.02}

      {Show status periodically}
      if AsciiState <> raFinished then                                 {!!.02}
        if TimerExpired(StatusTimer) or ForceStatus then begin
          ForceStatus := False;
          NewTimer(StatusTimer, StatusInterval);
          SaveStatus := GetAsyncStatus;
          if GetAsyncStatus = ecOk then
            SetAsyncStatus(ecAsciiReceiveInProgress);
          apUserStatus(P, False, False);
          SetAsyncStatus(SaveStatus);
        end;

      {Process current state}
      case AsciiState of
        raInitial :
          begin
            {!!.01}
            {Get a protocol DataBlock}
            {if not GetMemCheck(DataBlock, SizeOf(DataBlockType)) then begin
              GotError(PR, epFatal+ecOutOfMemory);
              AsciiState := raFinished;
              goto ExitPoint;
            end;}

            {Pathname should already have name of file to receive}
            if Pathname = '' then begin
              GotError(PR, epFatal+ecNoFilename);
              AsciiState := raFinished;
              goto ExitPoint;
            end else begin
              {Merge in destdir if not already done}
              if (JustPathname(Pathname) = '') and (DestDir <> '') then
                Pathname := AddBackslash(DestDir)+Pathname;
              PathName := StUpcase(PathName);
            end;

            {Send file name to user's LogFile procedure}
            LogFile(P, lfReceiveStart);

            {Accept this file}
            if not AcceptFile(P) then begin
              GotError(PR, epNonFatal+ecFileRejected);
              AsciiState := raFinished;
              goto ExitPoint;
            end;

            {Prepare file for writing protocol blocks}
            apPrepareWriting(P);
            if GetAsyncStatus <> ecOk then begin
              AsciiState := raFinished;
              goto ExitPoint;
            end;

            {Prepare to collect first block}
            AsciiState := raCollectBlock;
            FileOfs := 0;
            BlockNum := 1;
            NewTimer(ReplyTimer, RcvTimeout);
            TimerPending := True;
            BlkIndex := 0;
            ForceStatus := True;
          end;

        raCollectBlock :
          begin
            while CharReady(PR) and (BlkIndex < BlockLen) do begin

              {Start the protocol timer on the first received character}
              if TimerPending then begin
                TimerPending := False;
                NewTimer(Timer, 1);
              end;

              GetChar(PR, C);
              Inc(BlkIndex);
              DataBlock^[BlkIndex] := C;
            end;

            if BlkIndex >= BlockLen then
              {Got a complete block, go process it}
              AsciiState := raProcessBlock
            else if TimerExpired(ReplyTimer) then begin
              {Timeout out waiting for complete block, assume EOF}
              CtrlZEncountered := True;
              AsciiState := raProcessBlock;
            end;
          end;

        raProcessBlock :
          begin
            {Go process what's in DataBlock}
            BlockSize := BlkIndex;
            ReceiveBlock(P, DataBlock^, BlockSize, Handshake);
            if (GetAsyncStatus = ecOk) or                              {!!.02}
               (GetAsyncStatus = ecEndFile) then begin                 {!!.02}
              Error := apWriteProtocolBlock(P, DataBlock^, BlockSize);
              if GetAsyncStatus = ecOk then begin
                {Normal received block}
                Inc(FileOfs, BlockSize);
                NewTimer(ReplyTimer, RcvTimeout);
                ForceStatus := True;
                BlkIndex := 0;
                if CtrlZEncountered or Aborted then                    {!!.02}
                  AsciiState := raFinished
                else
                  AsciiState := raCollectBlock;
              end else
                {Error during write, clean up and exit}
                AsciiState := raFinished;
            end else
              {End of file}
              AsciiState := raFinished;
          end;

        raFinished :
          begin
            apFinishWriting(P);
            LogFile(P, lfReceiveOk);
            ShowLastStatus(P);
            PR^.ProtocolActive := False;
            {FreeMemCheck(DataBlock, SizeOf(DataBlock^));}             {!!.01}
            AsciiState := raDone;
            SetAsyncStatus(ecOk);
          end;
      end;

  ExitPoint:
      {Set function result}
      case AsciiState of
        raInitial,
        raProcessBlock,
        raFinished           : ProtocolReceivePartAS := psReady;

        raCollectBlock       : ProtocolReceivePartAS := psWaiting;

        raDone               : ProtocolReceivePartAS := psFinished;
      end;
    end;
  end;

  procedure ProtocolReceiveAS(P : ProtocolRecPtr);
    {-Starts Ascii protocol receive}
  var
    AS : AsciiProtocolPtr absolute P;
    State : ProtocolStateType;
  begin
    with AS^, PData^ do begin
      {Prepare}
      PrepareReceivePartAS(P);
      if GetAsyncStatus <> ecOk then
        Exit;

      {Get the file, calling the user background procedure periodically}
      repeat
        State := ProtocolReceivePartAS(P);
        if State = psWaiting then
          UserBack(P);
      until State = psFinished;
    end;
  end;

end.
