{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                 APYMODEM.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1991.           *}
{* Portions copyright (c) Information Technology 1989,   *}
{*    and used under license to TurboPower Software      *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApYmodem;
  {-Provides (true) Ymodem/G batch recieve and transmit}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpRoot,
  OpInline,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpInline,
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  {$ELSE}
  ApMisc,
  ApPort,
  ApTimer,
  ApCom,
  {$ENDIF}
  ApAbsPcl,
  ApXmodem;

{$I APYMODEM.PA0}

implementation

  procedure InitYmodem(var P : ProtocolRecPtr;
                       PortPtr : PortRecPtr;
                       Use1K, UseGMode : Boolean);
  {-Allocates and initializes and Ymodem control block}
  begin
    InitCustomYmodem(P, PortPtr, Use1K, UseGMode, DefProtocolOptions);
  end;

  procedure InitCustomYmodem(var P : ProtocolRecPtr;
                             PortPtr : PortRecPtr;
                             Use1K, UseGMode : Boolean;
                             Options : Word);
    {-Allocates and initializes and Ymodem control block with options}
  var
    YM : YmodemPtr absolute P;
    Temp : ProtocolDataPtr;
  begin
    SetAsyncStatus(ecOk);
    P := nil;

    {Allocate the protocol data record}
    InitProtocolData(Temp, PortPtr, Options);
    if GetAsyncStatus <> ecOk then
      Exit;

    {Allocate the Ymodem record}
    if not GetMemCheck(YM, SizeOf(YModemProtocol)) then begin
      DoneProtocolData(Temp);
      GotError(PortPtr, epFatal+ecOutOfMemory);
      Exit;
    end;

    {Allocate the name block buffer}
    if not GetMemCheck(YM^.FileHeader, SizeOf(YM^.FileHeader^)) then begin
      DoneProtocolData(Temp);
      FreeMemCheck(YM, SizeOf(YModemProtocol));
      GotError(PortPtr, epFatal+ecOutOfMemory);
      Exit;
    end;

    {!!.01 copied from xmodem state machine}
    {Get a protocol DataBlock}
    if not GetMemCheck(YM^.DataBlock, SizeOf(DataBlockType)+5) then begin
      DoneProtocolData(Temp);
      FreeMemCheck(YM^.FileHeader, SizeOf(YM^.FileHeader^));
      FreeMemCheck(YM, SizeOf(YmodemProtocol));
      Exit;
    end;

    YM^.PData := Temp;

    with YM^, PData^ do begin
      {Set block mode}
      OneKMode := Use1K;
      Set1KMode(P, Use1K);

      {Miscellaneous inits}
      BlockWait := DefBlockWait;
      MaxBlockErrors := DefMaxBlockErrors;
      FirstBlockNum := 1;
      Overhead := XmodemOverhead;
      TurnDelay := XmodemTurnDelay;

      {Assume crc mode}
      CheckType := bcCrc16;

      {Ymodem specific stuff}
      BatchProtocol := True;
      GMode := UseGMode;
      if GMode then begin
        ProtType := YmodemG;
        TurnDelay := 0;
      end else
        ProtType := Ymodem;

      {Don't ask for any EOT retries}
      EotCheckCount := 0;

      {Set write fail option to rename}
      WriteFailOpt := WriteRename;
    end;
  end;

  procedure DoneYmodem(var P : ProtocolRecPtr);
    {-Disposes of P}
  var
    YM : YmodemPtr absolute P;
  begin
    with YM^ do begin
      DoneProtocolData(P^.PData);
      FreeMemCheck(FileHeader, SizeOf(FileHeader^));
      FreeMemCheck(YM^.DataBlock, SizeOf(DataBlockType)+5);
    end;
    FreeMemCheck(P, SizeOf(YmodemProtocol));
  end;

  procedure PrepareTransmitPartYM(P : ProtocolRecPtr);
    {-Prepare to transmit a Ymodem batch}
  var
    YM : YmodemPtr absolute P;

  begin
    with YM^, PData^ do begin
      FindingFirst := True;
      FileListIndex := 0;
      FilesSent := False;
      PR^.ProtocolActive := True;

      {Reset status vars}
      ResetStatus(P);

      {Show first status}
      SetAsyncStatus(ecHandshakeInProgress);
      ShowFirstStatus(P);
      SetAsyncStatus(ecOk);

      {Set first state}
      YmodemState := tyInitial;
    end;
  end;

  function ProtocolTransmitPartYM(P : ProtocolRecPtr) : ProtocolStateType;
    {-Transmit a batch of files}
  var
    YM : YmodemPtr absolute P;
    S : String;
    Len : Byte;
    I : Integer;
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
    C : Char;
    SaveState : ProtocolStateType;

    function CheckErrors : Boolean;
      {-Increment block errors, return True if too many}
    begin
      with YM^, PData^ do begin
        Inc(BlockErrors);
        Inc(TotalErrors);
        CheckErrors := BlockErrors > MaxBlockErrors;
      end;
    end;

  begin
    with YM^, PData^ do begin
      {General stuff - only do if not dropping through to Xmodem state machine}
      if YmodemState <> tySendXmodem then begin

        {Check for user abort}
        if (YmodemState <> tyFinishDrain) and                          {!!.01}
           (YmodemState <> tyFinished) and                             {!!.01}
           HandleAbort(P) then begin                                   {!!.01}
          YmodemState := tyFinished;
          {Need to log cancellation here since APXMODEM won't see it}
          LogFile(P, lfTransmitFail);
        end;

        {Show status periodically}
        if TimerExpired(StatusTimer) or ForceStatus then begin
          ForceStatus := False;
          NewTimer(StatusTimer, StatusInterval);
          apUserStatus(P, False, False);
        end;
      end;

      {Process current state}
      case YmodemState of
        tyInitial :
          begin
            {Check for handshake character}
            YmodemState := tyHandshake;
            HandshakeAttempt := 0;
            if not PrepHandshake(P) then
              YmodemState := tyFinished;
          end;

        tyHandshake :
          begin
            if CharReady(PR) then
              if ProcessHandshake(P) then begin
                {Start protocol timer now}
                NewTimer(Timer, 1);
                {Use reply timer to wait for buffer freespace}
                NewTimer(ReplyTimer, TransTimeout);
                YmodemState := tyGetFileName;
                {If GMode don't allow any more errors}
                if GMode then
                  MaxBlockErrors := 0;
              end else begin
                if GetAsyncStatus = ecInitCancel then
                  YmodemState := tyFinished
                else if not PrepHandshake(P) then
                  YmodemState := tyFinished
              end
            else
              if TimerExpired(ReplyTimer) then
                if not PrepHandshake(P) then
                  YmodemState := tyFinished;
          end;

        tyGetFileName :
          begin
            if NextFile(P, SaveName) then begin
              {Format a file name block}
              Pathname := StUpcase(SaveName);

              {Make a Ymodem file header record}
              FillChar(FileHeader^, SizeOf(FileHeader^), 0);

              {Fill in the file name}
              FSplit(SaveName, Dir, Name, Ext);
              if FlagIsSet(apFlags, apIncludeDirectory) then
                S := SaveName
              else
                S := Name + Ext;

              {Change name to lower case, change '\' to '/'}
              Len := Length(S);
              for I := 1 to Len do begin
                S[I] := LoCaseMac(S[I]);
                if S[I] = '\' then
                  S[I] := '/';
              end;
              Move(S[1], FileHeader^, Len);

              {Open file now to get size and date stamp}
              PrepareReading(P);

              {Continue only if the file was opened ok}
              if GetAsyncStatus = ecOk then begin
                {Save the file length}
                SaveLen := SrcFileLen;

                {Fill in file size}
                Str(SrcFileLen, S);
                Move(S[1], FileHeader^[Len+2], Length(S));
                Inc(Len, Length(S));

                {Convert time stamp to Ymodem format and stuff in FileHeader}
                if SrcFileDate <> 0 then begin
                  S := ' ' + OctalStr(PackToYMTimeStamp(SrcFileDate));
                  Move(S[1], FileHeader^[Len+2], Length(S));
                  Len := Len + 2 + Length(S);
                end;

                {Determine block size from the used part of the FileHeader}
                if Len <= 128 then begin
                  BlockLen := 128;
                  OneKMode := False;
                  StartChar := cSoh;
                end else begin
                  BlockLen := 1024;
                  OneKMode := True;
                  StartChar := cStx;
                end;

                {Init status vars for the header transfer}
                SrcFileLen := BlockLen;
                BytesRemaining := BlockLen;
                BytesTransferred := 0;
                ElapsedTics := 0;
                Pathname := '';

                {Go send the file header}
                YmodemState := tySendFileName;
                CharsLeft := 0;
                OutBufPos := 1;
              end else begin
                GotError(PR, GetAsyncStatus);
                ShowLastStatus(P);
                YmodemState := tyDone;
                PR^.ProtocolActive := False;
              end;
            end else
              YmodemState := tyFinished;
          end;

        tySendFileName :
          begin
            {Send the file header}
            BlockNum := 0;
            TransmitBlock(P, FileHeader^, BlockLen, ' ');
            if GetAsyncStatus <> ecOk then begin
              YmodemState := tyFinished;
              ProtocolTransmitPartYM := psReady;
              Exit;
            end;

            {If we get this far we will eventually need a cleanup block}
            FilesSent := True;

            {Wait for the buffer to drain}
            YmodemState := tyDraining;
            NewTimer(ReplyTimer, DrainWait);
          end;

        tyDraining :
          begin
            if (OutBuffUsed(PR) <= 1) or TimerExpired(ReplyTimer) then begin
              NewTimer(ReplyTimer, BlockWait);
              YmodemState := tyReplyPending;
            end;
          end;

        tyReplyPending :
          begin
            if CharReady(PR) then begin
              if GMode then
                YmodemState := tyPrepXmodem
              else if ProcessBlockReply(P) then
                YmodemState := tyPrepXmodem
              else if CheckErrors then
                YmodemState := tyFinished
              else
                YmodemState := tySendFilename;
            end else
              if TimerExpired(ReplyTimer) then
                if CheckErrors then
                  YmodemState := tyFinished
                else
                  YmodemState := tySendFilename;
          end;

        tyPrepXmodem :
          begin
            {Reset some status vars}
            BytesTransferred := 0;
            ElapsedTics := 0;
            Inc(InProgress);

            {Restore the pathname and file size}
            Pathname := StUpcase(SaveName);
            SrcFileLen := SaveLen;
            BytesRemaining := SaveLen;

            {Start transmitting the file with 1K blocks}
            OneKMode := True;
            BlockLen := 1024;
            StartChar := cStx;
            FirstBlockNum := 1;

            CheckType := bcChecksum1;
            ForceStatus := True;
            XmodemState := txInitial;
            YmodemState := tySendXmodem;
            SaveState := psReady;
            {DataBlock := nil;}                                        {!!.01}
          end;

        tySendXmodem :
          begin
            {Let the Xmodem state machine handle it}
            SaveState := ProtocolTransmitPartXM(P);
            if SaveState = psFinished then
              if GetAsyncStatus = ecOk then
                YmodemState := tyInitial
              else begin
                FilesSent := False;
                YmodemState := tyFinished;
              end;

            {Say we're still in the protocol}
            PR^.ProtocolActive := True;
          end;

        tyFinished :
          begin
            YmodemState := tyFinishDrain;
            FinishReading(P);
            if (GetAsyncStatus = ecUserAbort) or
               (GetAsyncStatus = ecCancelRequested) then begin
              ShowLastStatus(P);
              YmodemState := tyDone;
              PR^.ProtocolActive := False;
            end;

            if FilesSent and (YmodemState <> tyDone) then begin        {!!.01}
              {Send an empty header block to indicate end of Batch}
              FillChar(FileHeader^, 128, 0);
              BlockNum := 0;
              OneKMode := False;
              BlockLen := 128;
              StartChar := cSoh;
              CharsLeft := 0;
              OutBufPos := 1;
              TransmitBlock(P, FileHeader^, BlockLen, ' ');
            end;
            NewTimer(ReplyTimer, FinishWait);
          end;

        tyFinishDrain :
          if (OutBuffUsed(PR) <= 1) or TimerExpired(ReplyTimer) then begin
            {Wait for ACK}
            YmodemState := tyFinishAck;
            NewTimer(ReplyTimer, BlockWait);
          end;

        tyFinishAck :
          if CharReady(PR) or TimerExpired(ReplyTimer) then begin
            {Get and discard Ack, or whatever}
            if CharReady(PR) then
              GetChar(PR, C);
            YmodemState := tyDone;
            ShowLastStatus(P);
            PR^.ProtocolActive := False;
          end;
      end;

      {Set function result}
      case YmodemState of
        tySendXmodem       : ProtocolTransmitPartYM := SaveState;

        tyInitial,
        tyGetFileName,
        tySendFileName,
        tyPrepXmodem,
        tyFinished         : ProtocolTransmitPartYM := psReady;

        tyFinishAck,
        tyFinishDrain,
        tyHandshake,
        tyDraining,
        tyReplyPending     : ProtocolTransmitPartYM := psWaiting;

        tyDone             : ProtocolTransmitPartYM := psFinished;
      end;
    end;
  end;

  procedure ProtocolTransmitYM(P : ProtocolRecPtr);
    {-Transmit a batch of files}
  var
    YM : YmodemPtr absolute P;
    State : ProtocolStateType;
  begin
    with YM^, PData^ do begin
      PrepareTransmitPartYM(P);
      if GetAsyncStatus <> ecOk then
        Exit;
      repeat
        State := ProtocolTransmitPartYM(P);
        if State = psWaiting then
          UserBack(P);
      until State = psFinished;
    end;
  end;

  procedure PrepareReceivePartYM(P : ProtocolRecPtr);
    {-Prepare to enter the Ymodem receive state machine}
  var
    YM : YmodemPtr absolute P;
  begin
    with YM^, PData^ do begin
      PR^.ProtocolActive := True;
      GotOneFile := False;

      {Reset status vars}
      ResetStatus(P);
      ShowFirstStatus(P);

      ForceStatus := True;
      YmodemState := ryInitial;
    end;
  end;

  function ProtocolReceivePartYM(P : ProtocolRecPtr) : ProtocolStateType;
    {-Ymodem receive state machine}
  label
    ExitPoint;
  var
    YM : YmodemPtr absolute P;
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
    C : Char;
    F : File;
    S : String;
    SLen : Byte absolute S;
    CurSize : LongInt;
    BlockSize : Word;
    BlockPos, I : Integer;
    Finished : Boolean;
    Code : Word;
    Result : Word;
    SaveState : ProtocolStateType;
    RcvStatus : Word;
    {Cnt : Word;}                                                      {!!.03}

    function CheckErrors : Boolean;
      {-Increment block errors, return True if too many}
    begin
      with YM^, PData^ do begin
        Inc(BlockErrors);
        Inc(TotalErrors);
        CheckErrors := BlockErrors > MaxBlockErrors;
      end;
    end;

  begin
    with YM^, PData^ do begin
      {General stuff - only do if not dropping through to Xmodem state machine}
      if YmodemState <> ryReceiveXmodem then begin

        {Check for user abort}
        if HandleAbort(P) then
          YmodemState := ryFinished;

        {Show status periodically}
        if TimerExpired(StatusTimer) or ForceStatus then begin
          ForceStatus := False;
          NewTimer(StatusTimer, StatusInterval);
          if InProgress <> 0 then
            apUserStatus(P, False, False);
        end;
      end;

      {Process current state}
      case YmodemState of
        ryInitial :
          begin
            {Manually reset status vars before getting a file header}
            SrcFileLen := 0;
            BytesRemaining := 0;
            BytesTransferred := 0;
            ElapsedTics := 0;
            BlockNum := 0;
            Pathname := '';

            {Get a ymodem header block (really a 1 block xmodem transfer)}
            FillChar(FileHeader^[1], SizeOf(FileHeader^), 0);
            CheckType := bcCrc16;
            OverheadLen := 4;
            OneKMode := False;
            BlockSize := 128;
            BlockNum := 0;

            {Testing shows a short delay is required here for Telix}
            NewTimer(ReplyTimer, TelixDelay);
            YmodemState := ryDelay;
          end;

        ryDelay :
          if TimerExpired(ReplyTimer) then begin
            {Send handshake}
            HandshakeChar := GetHandshakeChar(P);
            PutChar(PR, HandshakeChar);
            EotCounter := 0;
            CanCounter := 0;

            {Start waiting for handshake reply}
            YmodemState := ryWaitForHSReply;
            NewTimer(ReplyTimer, HandshakeWait);
            TimerPending := True;
          end;

        ryWaitForHSReply :
          begin
            if CharReady(PR) then begin
              YmodemState := ryWaitForBlockStart;
            end else
              if TimerExpired(ReplyTimer) then begin
                if CheckErrors then
                  YmodemState := ryFinished
                else begin
                  if BlockErrors > 3 then begin
                    CheckType := bcChecksum1;
                    HandshakeChar := cNak;
                    OverheadLen := 3;
                  end;
                  PutChar(PR, HandshakeChar);
                  NewTimer(ReplyTimer, HandshakeWait);
                end;
              end;
            end;

        ryWaitForBlockStart :
          begin
            if CharReady(PR) then begin
              if CheckForBlockStart(P, C) then begin
                case C of
                  cSoh,
                  cStx :
                    begin
                      if C = cSoh then
                        BlockLen := 128
                      else
                        BlockLen := 1024;
                      if TimerPending then
                        NewTimer(Timer, 1);
                      YmodemState := ryCollectBlock;
                      BlkIndex := 0;
                      if GMode then
                        MaxBlockErrors := 0;
                    end;
                  cCan :
                    begin
                      EotCounter := 0;
                      Inc(CanCounter);
                      if CanCounter > 2 then begin
                        Cancel(P);
                        YmodemState := ryFinished;
                      end;
                    end;
                  cEot :
                    begin
                      CanCounter := 0;
                      Inc(EotCounter);
                      if EotCounter = 1 then
                        PutChar(PR, cNak)
                      else begin
                        PutChar(PR, cAck);
                        YmodemState := ryFinished;
                      end;
                    end;
                end;
              end;
            end else begin
              {No chars yet, check timeout}
              if TimerExpired(ReplyTimer) then
                if CheckErrors then
                  YmodemState := ryFinished
                else begin
                  FlushInBuffer(PR);
                  YmodemState := ryDelay;
                end;
            end;
          end;

        ryCollectBlock :
          if CharReady(PR) then begin
            {Cnt := 1;}                                                {!!.03}
            while CharReady(PR) and
                  {(Cnt < 10) and}                                     {!!.03}
                  (BlkIndex < BlockLen + OverheadLen) do begin
              GetChar(PR, C);
              Inc(BlkIndex);
              {Inc(Cnt);}                                              {!!.03}
              FileHeader^[BlkIndex] := C;
            end;

            if BlkIndex >= BlockLen + OverheadLen then
              {Got a complete block, go process it}
              YmodemState := ryProcessBlock
            else if TimerExpired(ReplyTimer) then
              if CheckErrors then
                YmodemState := ryFinished
              else
                {Timeout out waiting for initial block, resend handshake}
                YmodemState := ryInitial;
          end;

        ryProcessBlock :
          begin
            {Go process data already in DataBlock}
            ReceiveBlock(P, FileHeader^, BlockSize, HandshakeChar);
            RcvStatus := GetAsyncStatus;
            SendHandshakeChar(P, HandshakeChar);

            {Extract file info if we got block ok}
            if RcvStatus = ecOk then begin
              {Finished if entire block is null}
              Finished := True;
              I := 1;
              while (I < 120) and Finished do begin                    {!!.03}
                if FileHeader^[I] <> #0 then
                  Finished := False;
                Inc(I);
              end;

              {If finished, send last ack and exit}
              if Finished then begin
                YmodemState := ryFinished;
                goto ExitPoint;
              end;

              {Extract the file name from the header}
              BlockPos := 1;
              I := 0;
              while (FileHeader^[BlockPos] <> #0) and (BlockPos < 255) do begin
                Inc(I);
                S[I] := FileHeader^[BlockPos];
                Inc(BlockPos);
              end;
              SLen := I;

              {Change all '/' to '\'. Change name to all upper case}
              for I := 1 to SLen do begin
                if S[I] = '/' then
                  S[I] := '\';
                S[I] := Upcase(S[I]);
              end;
              Pathname := S;

              {Check the existance of the directory and file name}
              FSplit(Pathname, Dir, Name, Ext);

              {Should we use its directory or ours?}
              if not FlagIsSet(apFlags, apHonorDirectory) then
                PathName := AddBackSlash(DestDir) + Name + Ext;

              {Extract the file size}
              I := 1;
              Inc(BlockPos);
              while (FileHeader^[BlockPos] <> #0) and
                    (FileHeader^[BlockPos] <> ' ') and
                    (I <= 255) do begin
                S[I] := FileHeader^[BlockPos];
                Inc(I);
                Inc(BlockPos);
              end;
              Dec(I);
              SLen := I;
              if SLen = 0 then
                SrcFileLen := 0
              else begin
                Val(S, SrcFileLen, Code);
                if Code <> 0 then
                  SrcFileLen := 0;
              end;
              BytesRemaining := SrcFileLen;

              {Extract the file date/time stamp}
              I := 1;
              Inc(BlockPos);
              while (FileHeader^[BlockPos] <> #0) and
                    (FileHeader^[BlockPos] <> ' ') and
                    (I <= 255) do begin
                S[I] := FileHeader^[BlockPos];
                Inc(I);
                Inc(BlockPos);
              end;
              Dec(I);
              SLen := I;
              if SLen = 0 then
                NewDT := 0
              else begin
                NewDT := OctalStr2Long(S);
                if NewDT = 0 then begin
                  {Invalid char in date/time stampt, show the error and continue}
                  GotError(PR, epNonFatal+ecInvalidDateTime);
                  NewDT := 0;
                  UserStatus(P, False, False);
                  SetAsyncStatus(ecOk);
                end;
              end;

              {Manually reset status vars before getting file}
              BytesTransferred := 0;
              ElapsedTics := 0;

              {Receive the file using CRC and 1K blocks}
              CheckType := bcCrc16;
              OneKMode := True;
              BlockLen := 1024;
              FirstBlockNum := 1;
              SaveLen := SrcFileLen;

              {Go prep Xmodem}
              YmodemState := ryPrepXmodem;
            end else
              {Error getting name block...}
              if GMode then
                {Can't recover when in GMode, go quit}
                YmodemState := ryFinished
              else begin
                {Nak already sent, go get block again}
                YmodemState := ryWaitForHSReply;
                NewTimer(ReplyTimer, HandshakeWait);
              end;
          end;

        ryPrepXmodem :
          begin
            PrepareReceivePartXM(P);
            YmodemState := ryReceiveXmodem;
            SaveState := psReady;
          end;

        ryReceiveXmodem :
          begin
            SaveState := ProtocolReceivePartXM(P);
            if SaveState = psFinished then begin
              if GetAsyncStatus = ecOk then begin
                {If this is a file, check for truncation and file date}
                {SaveMode := FileMode;}                         {!!.02}{!!.03}
                {FileMode := $40;}                              {!!.02}{!!.03}
                Assign(F, Pathname);
                Reset(F, 1);
                {FileMode := SaveMode;}                         {!!.02}{!!.02}
                if IOResult = 0 then begin
                  {If a new file size was supplied, truncate to that length}
                  if SaveLen <> 0 then begin

                    {Get the file size of the file (as received)}
                    CurSize := FileSize(F);

                    {If the requested file size is within one block, truncate the file}
                    if (CurSize - SaveLen) < 1024 then begin
                      Seek(F, SaveLen);
                      Truncate(F);
                      Result := IOResult;
                      if Result <> 0 then begin
                        GotError(PR, epNonFatal+Result);
                        SetAsyncStatus(ecOk);
                      end;
                    end;
                  end;

                  {If a new date/time stamp was specified, update the file time}
                  if NewDT <> 0 then begin
                    NewDT := YMTimeStampToPack(NewDT);
                    SetFTime(F, NewDT);
                    Result := IOResult;
                    if Result <> 0 then begin
                      GotError(PR, epNonFatal+Result);
                      SetAsyncStatus(ecOk);
                    end;
                  end;
                end;
                Close(F);
                if IOResult <> 0 then ;

                {Go look for another file}
                YmodemState := ryInitial;
                NewTimer(ReplyTimer, HandshakeWait);
                ForceStatus := True;
              end else
                YmodemState := ryFinished;
            end;
            PR^.ProtocolActive := True;
          end;

        ryFinished :
          begin
            ShowLastStatus(P);
            YmodemState := ryDone;
            PR^.ProtocolActive := False;
          end;
      end;

ExitPoint:
      {Set function result}
      case YmodemState of
        ryReceiveXmodem     : ProtocolReceivePartYM := SaveState;

        ryInitial,
        ryOpenFile,
        ryProcessBlock,
        ryFinished,
        ryPrepXmodem        : ProtocolReceivePartYM := psReady;

        ryDelay,
        ryWaitForHSReply,
        ryWaitForBlockStart,
        ryCollectBlock      : ProtocolReceivePartYM := psWaiting;

        ryDone              : ProtocolReceivePartYM := psFinished;
      end;
    end;
  end;

  procedure ProtocolReceiveYM(P : ProtocolRecPtr);
    {-Receive a batch of Ymodem files}
  var
    YM : YmodemPtr absolute P;
    State : ProtocolStateType;
  begin
    with YM^, PData^ do begin
      PrepareReceivePartYM(P);
      if GetAsyncStatus <> ecOk then
        Exit;
      repeat
        State := ProtocolReceivePartYM(P);
        if State = psWaiting then
          UserBack(P);
      until State = psFinished;
    end;
  end;

end.
