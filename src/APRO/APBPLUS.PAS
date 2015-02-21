{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                  APBPLUS.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApBPlus;
  {-Provides CIS B+ remote (not host) protocol}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpInline,
  OpString,
  OpRoot,
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
  ApAbsPcl;

{$I APBPLUS.PA0}

implementation

const
  {Default ParamsRecord values}
  DefDR : Byte = 1;   {Can handle Download Resume}
  DefBS : Byte = 16;  {Default to 128 * DefBS (2048) byte packets}
  DefWS = 1;          {Can handle send ahead}
  DefWR = 2;          {Can receive up to 2 packets ahead}
  DefCM = 1;          {Can handle CRC blockchecking}
  DefDQ = 1;          {Can handle special quoting including non-quoted NUL}
  DefUR = 0;          {Can NOT handle Upload Recovery (not supported by CIS)}
  DefFI = 1;          {Can handle File Info packet}
  DefXP = 0;          {FTP/GIF does not use TransportLayer}

  function Long2Str(L : LongInt) : string;
    {-Convert a long/word/integer/byte/shortint to a string}
  var
    S : string;
  begin
    Str(L, S);
    Long2Str := S;
  end;

  function IncSequence(Value : Integer) : Integer;
    {-Increment a Sequence Number var}
  begin
    IncSequence := (Succ(Value) mod 10);
  end;

  procedure SendByte(P : ProtocolRecPtr; C : Char);
  begin
    with BPlusPtr(P)^, PData^ do begin
      PutChar(PR, C);
      Inc(SRaw);
    end;
  end;

  function IncSA(P : ProtocolRecPtr; Value : Integer) : Integer;
  begin
    with BPlusPtr(P)^ do
      if Value = SAMax then
        IncSA := 1
      else
        IncSA := Value + 1;
  end;

  procedure UpdateBlockCheck(P : ProtocolRecPtr; CurByte : Byte);
    {-Update the CRC/checksum to reflect the new byte}

    function UpdCrc(CurByte : Byte; CurCrc : Word) : Word;
      {-Due to an oddity in the CIS handling of CRC's, we use this special
        version of UpdateCrc rather than the one in APMISC.  This function
        requires the CRC lookup table in APMISC.}
    begin
      UpdCrc := CrcTable[((CurCrc shr 8) xor CurByte) and $FF] xor
                (CurCrc shl 8);
    end;

  begin
    with BPlusPtr(P)^, PData^ do begin
      if CheckType = bcCrc16 then
        Checksum := UpdCRC(CurByte,Checksum)
      else begin
        Checksum := Checksum shl 1;
        if Checksum > 255 then
          Checksum := (Checksum and $FF) + 1;
        Checksum := Checksum + CurByte;
        if Checksum > 255 then
          Checksum := (Checksum and $FF) + 1;
      end;
    end;
  end;

  procedure SendQuotedByte(P : ProtocolRecPtr; C : Char);
    {-Quote and transmit I}
  var
    B : Byte absolute C;
  begin
    with BPlusPtr(P)^ do begin
      if QuoteTable[B] <> #0 then begin
        SendByte(P, cDLE);
        SendByte(P, QuoteTable[B]);
      end else
        SendByte(P, Chr(B));
    end;
  end;

  procedure bpSendAck(P : ProtocolRecPtr);
    {-Send Ack}
  begin
    with BPlusPtr(P)^ do begin
      SendByte(P, cDLE);
      SendByte(P, Chr(SeqNum + Ord('0')));
    end;
  end;

  procedure SendNAK(P : ProtocolRecPtr);
    {-Send Nak}
  begin
    SendByte(P, cNAK);
  end;

  procedure SendData(P : ProtocolRecPtr; BNum : Integer);
  var
    I : Integer;
  begin
    with BPlusPtr(P)^, PData^ do begin
      with SBuffer[BNum] do begin
        if BPlusMode and (CheckType = bcCrc16) then
          Checksum := $FFFF
        else
          Checksum := 0;

        SendByte(P, cDLE);
        SendByte(P, 'B');

        SendByte(P, Chr(Seq+Ord('0')));
        UpdateBlockCheck(P, Byte(Seq+Ord('0')));

        SendByte(P, PType);
        UpdateBlockCheck(P, Byte(PType));

        for I := 1 to Num do begin
          SendQuotedByte(P, Buf^[I]);
          UpdateBlockCheck(P, Byte(Buf^[I]));
        end;

        SendByte(P, cETX);
        UpdateBlockCheck(P, Byte(cETX));

        if BPlusMode and (CheckType = bcCrc16) then
          SendQuotedByte(P, Char(Hi(Checksum)));
        SendQuotedByte(P, Char(Lo(Checksum)));
      end;
    end;
  end;

  procedure SendPacket(P : ProtocolRecPtr; PacketType : Char; Size : Integer);
    {-Send a packet of data}
  begin
    with BPlusPtr(P)^, PData^ do begin
      SeqNum := IncSequence(SeqNum);
      with SBuffer[Next2Fill] do begin
        Seq   := SeqNum;
        Num   := Size;
        PType := PacketType;
      end;
      SendData(P, Next2Fill);
      Next2Fill := IncSA(P, Next2Fill);
      Inc(SAWaiting);
      Inc(SPackets);
    end;
  end;

  procedure SendFailure(P : ProtocolRecPtr; Reason : String);
    {-Send a failure packet}
  begin
    with BPlusPtr(P)^, PData^ do begin
      Next2ACK := 1;
      Next2Fill := 1;
      SAWaiting := 0;
      Aborting := True;

      with SBuffer[1] do
        Move(Reason[1], Buf^[1], Length(Reason));

      SendPacket(P, 'F', Length(Reason));
    end;
  end;

  procedure bpGetCharQuoted(P : ProtocolRecPtr; var C : Char);
    {-Return a character that was transmitted quoted}
  label
    Quote;
  begin
    with BPlusPtr(P)^, PData^ do begin
      Quoted := False;

      if QuotePending then
        goto Quote;
      GetChar(PR, C);
      if C <> cDLE then
        Exit;

    Quote:
      Quoted := True;
      if CharReady(PR) then begin
        QuotePending := False;
        GetChar(PR, C);
        if C < #$60 then
          C := Char(Ord(C) and $1F)
        else
          C := Char((Ord(C) and $1F) or $80);
      end else
        QuotePending := True;
    end;
  end;

  function CollectPacket(P : ProtocolRecPtr) : Boolean;
    {-Collect a packet}
  var
    C : Char;
  begin
    CollectPacket := False;

    with BPlusPtr(P)^, PData^ do begin
      {Reset char timer each time a new character is received}
      if CharReady(PR) then
        NewTimer(ReplyTimer, HandshakeWait);

      {Return error on timeouts}
      if TimerExpired(ReplyTimer) then begin
        {Let caller handle timeout errors}
        GotError(PR, epNonFatal+ecTimeout);
        CollectPacket := True;
        Exit;
      end;

      {Process current packet collection state}
      case PacketState of
        psGetDLE :
          begin
            if CharReady(PR) then begin
              GetChar(PR, C);
              case C of
                cDLE : PacketState := psGetB;
                cENQ : PacketState := psSendAck;
              end;
            end;
          end;

        psGetB :
          begin
            if CharReady(PR) then begin
              GetChar(PR, C);
              case C of
                'B'  : PacketState := psGetSeq;
                ';'  : PacketState := psGetDLE;
                cEnq : PacketState := psSendAck;
                else   PacketState := psGetDLE;
              end;
            end;
          end;

        psGetSeq :
          begin
            {Reset timer to discount time spent verifying CRCs}
            if ResumeFlag then begin
              NewTimer(Timer, 1);
              RRaw := 2;
            end;

            if CharReady(PR) then begin
              GetChar(PR, C);
              case C of
                cEnq : PacketState := psSendAck
                else begin
                  if CheckType = bcCrc16 then
                    CheckSum := $FFFF
                  else
                    CheckSum := 0;
                  UpdateBlockCheck(P, Byte(C));
                  PacketNum := Ord(C)-Ord('0');
                  PacketState := psGetType;
                end;
              end;
            end;
          end;

        psGetType :
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            if QuotePending then
              Exit;
            UpdateBlockCheck(P, Byte(C));
            LastType := C;
            Idx := 1;
            PacketState := psGetData;
          end;

        psGetData :
          {Stay here while data available...}
          while CharReady(PR) do begin
            bpGetCharQuoted(P, C);
            if QuotePending then
              Exit;
            UpdateBlockCheck(P, Byte(C));
            if (C = cETX) and not Quoted then begin
              PacketState := psGetCheck1;
              Exit;
            end else begin
              RBuffer^[Idx] := C;
              Inc(Idx);
            end;
          end;

        psGetCheck1 :
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            if QuotePending then
              Exit;
            if CheckType = bcCrc16 then begin
              UpdateBlockCheck(P, Byte(C));
              PacketState := psGetCheck2;
            end else begin
              NewChk := Byte(C);
              PacketState := psCheckCheck;
            end;
          end;

        psGetCheck2 :
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            if QuotePending then
              Exit;
            UpdateBlockCheck(P, Byte(C));
            NewChk := 0;
            PacketState := psCheckCheck;
          end;

        psCheckCheck :
          begin
            if NewChk <> Checksum then begin
              {Checksum/CRC error}
              GotError(PR, epNonFatal+ecBlockCheckError);
              ForceStatus := True;
              PacketState := psError;
            end else if LastType = 'F' then
              {Always accept failure packet}
              PacketState := psSuccess
            else if PacketNum = SeqNum then begin
              {Dupe packet}
              GotError(PR, epNonFatal + ecDuplicateBlock);
              ForceStatus := True;
              PacketState := psSendAck;
            end else if PacketNum <> NextSeq then begin
              {Out-of-sequence error...}
              if PacketNum <> IncSequence(NextSeq) then begin
                {...and not a possible SA packet after error}
                GotError(PR, epNonFatal + ecSequenceError);
                ForceStatus := True;
                PacketState := psGetDLE;
              end else
                PacketState := psGetDLE;
            end else
              PacketState := psSuccess;
          end;

        psError :
          begin
            Inc(TotalErrors);
            Inc(BlockErrors);
            if (BlockErrors > BPErrorMax) then begin
              CollectPacket := True;
              Exit;
            end;
            if not NAKSent or not BPlusMode then begin
              NAKSent := True;
              SendNAK(P);
            end;
            PacketState := psGetDLE;
          end;

        psSendAck :
          begin
            if not Aborting then
              bpSendAck(P);
            PacketState := psGetDLE;
          end;

        psSuccess :
          begin
            if not Aborting then
              SeqNum := PacketNum;
            ResumeFlag := False;
            RSize := Idx;
            Inc(RPackets);
            CollectPacket := True;
          end;
      end;
    end;
  end;

  function CollectAck(P : ProtocolRecPtr) : Boolean;
    {-Collect acknowledgement to last packet}
  var
    SAIdx : Integer;
    C : Char;
    I : Word;
  begin
    with BPlusPtr(P)^, PData^ do begin

      CollectAck := False;

      {Restart the character timer with each character}
      if CharReady(PR) and not Aborting then
        NewTimer(ReplyTimer, HandshakeWait);

      if TimerExpired(ReplyTimer) and (AckState <> acSendENQ) then
        AckState := acTimeout;

      case AckState of
        acGetDLE :
          if CharReady(PR) then begin
            GetChar(PR, C);
            case C of
              cDLE : AckState := acGetNum;           {Potential ACK}
              cNAK : AckState := acSendENQ;          {Packet error}
              cETX : AckState := acSendNAK;          {Sequence problem}
            end;
          end;

        acGetNum :
          if CharReady(PR) then begin
            GetChar(PR, C);
            SaveC := C;
            case C of
              '0'..'9' : AckState := acHaveAck;     {Have ACK, check it}
              'B'      : if Aborting then
                           AckState := acSkipPacket1
                         else
                           AckState := acGetPacket;
              cNak     : AckState := acSendEnq;
              ';'      : begin
                           GotError(PR, epNonFatal+ecWaitAck);
                           ForceStatus := True;
                           AckState := acGetDLE;
                         end;
              else       AckState := acGetDLE;
            end;
          end;

        acGetPacket :
          begin
            {Prepare to collect packet}
            BPlusState := rbCollectPacket;
            BlockErrors := 0;
            PacketState := psGetSeq;
            AckState := acCollectPacket;
          end;

        acCollectPacket :
          if CharReady(PR) then begin
            if CollectPacket(P) then begin
              {Got a complete packet -- finished here}
              if GetAsyncStatus = ecOk then begin
                BlockErrors := 0;
                CollectAck := True;
              end else
                {Error getting packet, retry}
                AckState := acGetDLE;
            end;
          end else if TimerExpired(ReplyTimer) then
            AckState := acGetDLE;

        acSkipPacket1 :
          if CharReady(PR) then begin
            GetChar(PR, C);
            if C = cETX then begin
              bpGetCharQuoted(P, C);
              if QuotePending then
                AckState := acSkipPacket2
              else if CheckType = bcCrc16 then
                AckState := acSkipPacket3
              else
                AckState := acGetDLE;
            end;
          end;

        acSkipPacket2 : {Collect 2nd byte of 1st check byte}
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            AckState := acSkipPacket3;
          end;

        acSkipPacket3 : {Collect 2nd check byte}
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            if QuotePending then
              AckState := acSkipPacket4
            else
              AckState := acGetDLE;
          end;

        acSkipPacket4 : {Collect 2nd byte of 2st check byte}
          if CharReady(PR) then begin
            bpGetCharQuoted(P, C);
            AckState := acGetDLE;
          end;

        acHaveACK :
           begin
            PacketNum := Byte(SaveC) - Byte('0');
            if SBuffer[Next2ACK].Seq = PacketNum then begin
              {Expected ACK}
              Next2ACK := IncSA(P, Next2ACK);
              Dec(SAWaiting);
              if SAErrors > 0 then
                Dec(SAErrors);
              CollectACK := True;
              AckState := acGetDLE;
              Exit;
            end else if (SBuffer[IncSA(P, Next2ACK)].Seq = PacketNum) and
                        (SAWaiting = 2) then begin
              {Missed ACK}
              GotError(PR, epNonFatal+ecSequenceError);
              Dec(SAWaiting, 2);

              {Inc twice to skip the miss}
              Next2ACK := IncSA(P, Next2ACK);
              Next2ACK := IncSA(P, Next2ACK);
              if SAErrors > 0 then
                Dec(SAErrors);
              CollectACK := True;
              AckState := acGetDLE;
              Exit;
            end else if SBuffer[Next2ACK].Seq = IncSequence(PacketNum) then begin
              if SentENQ then
                {Remote missed first packet}
                AckState := acSendData
              else
                {Duplicate ACK}
                AckState := acGetDLE;
            end else begin
              if Aborting then
                AckState := acGetDLE
              else
                AckState := acTimeOut;
            end;
            SentENQ := False;
          end;

        acTimeout :
          begin
            GotError(PR, epNonFatal+ecTimeout);
            ForceStatus := True;
            AckState := acSendENQ;
            NewTimer(ReplyTimer, HandshakeWait);
          end;

        acSendNAK :
          begin
            Inc(BlockErrors);
            Inc(TotalErrors);
            if (BlockErrors > BPErrorMax) or Aborting then begin
              CollectAck := True;
              Exit;
            end;
            SendNAK(P);
            AckState := acGetDLE;
          end;

        acResync1 :
          if CharReady(PR) then begin
            GetChar(PR, C);
            if C = cDLE then
              AckState := acResync2
          end;

        acResync2 :
          if CharReady(PR) then begin
            GetChar(PR, C);
            case C of
              'B' : if Aborting then
                      AckState := acSkipPacket1
                    else
                      AckState := acGetPacket;
              '0'..'9' : AckState := acResync3;
            end;
          end;

        acResync3 :
          if CharReady(PR) then begin
            GetChar(PR, C);
            if C = cDLE then
              AckState := acResync4
          end;

        acResync4 :
          if CharReady(PR) then begin
            GetChar(PR, C);
            case C of
              'B' : if Aborting then
                      AckState := acSkipPacket1
                    else
                      AckState := acGetPacket;
              '0'..'9' : AckState := acHaveAck;
            end;
          end;

        acSendENQ :
          begin
            Inc(BlockErrors);
            Inc(TotalErrors);
            if (BlockErrors > BPErrorMax) or Aborting then begin
              GotError(PR, epNonFatal+ecTooManyErrors);
              CollectACK := True;
              Exit;
            end;

            SendByte(P, cENQ);
            SendByte(P, cENQ);
            AckState := acResync1;
            SentEnq := True;
          end;

        acSendData :
          begin
            Inc(SAErrors, 3);
            if SAErrors >= 12 then
              {If too many SA errors, cease SendAhead}
              SAMax := 1;

            {Flush all pending packets to send}
            SAIdx := Next2ACK;
            for I := 1 to SAWaiting do begin
              SendData(P, SAIdx);
              SAIdx := IncSA(P, SAIdx);
            end;
            SentENQ := False;
            AckState := acGetDLE;
          end;

        acFailed :
          begin
            CollectAck := True;
            AckState := acGetDLE;
          end;
      end;
    end;
  end;

  function GetPacket(P : ProtocolRecPtr; FirstState : PacketStateType) : Boolean;
    {-Non-background method to collect entire packet}
  begin
    with BPlusPtr(P)^ do begin
      PacketState := FirstState;
      repeat
        if CollectPacket(P) then begin
          GetPacket := GetAsyncStatus = ecOk;
          Exit;
        end;
      until False;
    end;
  end;

  function GetAck(P : ProtocolRecPtr) : Boolean;
    {-Non-background method to collect Ack}
  begin
    with BPlusPtr(P)^ do begin
      AckState := acGetDLE;
      repeat
        if CollectAck(P) then begin
          GetAck := GetAsyncStatus = ecOk;
          Exit;
        end;
      until False;
    end;
  end;

  procedure bpPrepareWriting(P : ProtocolRecPtr);
    {-Opens a file to receive, handles resume/overwrite request}
  label
    ExitPoint;
  var
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
    Result : Word;
    OvrW : Boolean;
    ET : EventTimer;
    I : Integer;
    S : PathStr;
    F : LongInt;
  begin
    with BPlusPtr(P)^, PData^ do begin
      {!!.01}
      {Allocate a file buffer}
      {if not GetMemCheck(FileBuffer, FileBufferSize) then begin
        GotError(PR, ecOutOfMemory);
        ForceStatus := True;
        Exit;
      end;}

      {Does the file exist already?}
      ResumeFlag := False;
      FileOpen := False;
      OvrW := False;

      SaveMode := FileMode;                                            {!!.02}
      FileMode := GetAproFileMode;                              {!!.02}{!!.03}
      Assign(WorkFile, PathName);
      Reset(WorkFile, 1);
      FileMode := SaveMode;                                            {!!.02}
      Result := IOResult;

      {Exit on errors other than FileNotFound}
      if (Result <> 0) and (Result <> 2) then begin
        GotError(PR, epFatal+Result);
        goto ExitPoint;
      end;

      {If file exists process potential resume}
      if Result = 0 then begin
        HandleResume(P);
        case WriteFailOpt of
          WriteFail :
            begin
              GotError(PR, epNonFatal+ecFileAlreadyExists);
              goto ExitPoint;
            end;
          WriteResume :
            ResumeFlag := True;
          WriteRename :
            GotError(PR, epNonFatal+ecFileRenamed);
          WriteAnyway :
            OvrW := True;
        end;
      end;

      if ResumeFlag then begin
        {Calculate CRC on existing file's contents}
        GotError(PR, epNonFatal+ecTryResume);
        apUserStatus(P, False, False);
        NewTimer(ET, 1);
        F := FileSize(WorkFile);

        with SBuffer[Next2Fill] do begin
          Seek(WorkFile, 0);
          Checksum := $FFFF;
          repeat
            BlockRead(WorkFile,Buf^[1], 512, Result);
            for I := 1 to (Result) do
              UpdateBlockCheck(P, Byte(Buf^[I]));
            if ElapsedTimeInSecs(ET) >= 10 then begin
              {Send WACK so host knows we're busy}
              NewTimer(ET, 1);
              SendByte(P, cDLE);
              SendByte(P, ';');
              GotError(PR, epNonFatal+ecTryResume);
              apUserStatus(P, False, False);
            end;
          until (Result = 0) or (IOResult <> 0);

          {Send the host a "Tr" packet with our info}
          FillChar(Buf^, SizeOf(Buf^), 0);
          Buf^[1] := 'r';

          {Send filesize and CRC}
          S := Long2Str(F) + ' ' + Long2Str(Checksum) + ' ';
          Move(S[1], Buf^[2], Length(S));
          SendPacket(P, 'T', Length(S)+1);

          {Collect ACK here}
          if not GetAck(P) then ;

          {Assume resuming....}
          GotError(PR, epNonFatal+ecHostResume);
          apUserStatus(P, False, False);
          FileOfs := F;
          BytesTransferred := F;
          InitFilePos := F;
          StartOfs := F;
          LastOfs := F;
          EndOfs := StartOfs + FileBufferSize;

          Seek(WorkFile, F);
          SetAsyncStatus(IOResult);
          if GetAsyncStatus <> 0 then begin
            SetAsyncStatus(GetAsyncStatus + epNonFatal);
            goto ExitPoint;
          end;
          FileOpen := True;
          Exit;
        end;
      end else begin
        Close(WorkFile);
        if IOResult = 0 then ;

        {Change the file name if needed}
        if (Result = 0) and not ResumeFlag and not OvrW then begin
          FSplit(Pathname, Dir, Name, Ext);
          Name[1] := '$';
          Pathname := Dir + Name + Ext;
          GotError(PR, epNonFatal+ecFileRenamed);
        end;

        {Give status a chance to show that the file was renamed}
        apUserStatus(P, False, False);
        SetAsyncStatus(ecOk);

        {Ok to rewrite file now}
        Assign(WorkFile, Pathname);
        Rewrite(WorkFile, 1);
        Result := IOResult;
        if Result <> 0 then begin
          GotError(PR, epFatal+Result);
          goto ExitPoint;
        end;

        {Acknowledge the T packet}
        bpSendAck(P);

        {Initialized the buffer management vars}
        BytesTransferred := 0;
        BytesRemaining := 0;
        FileOfs := 0;
        StartOfs := 0;
        LastOfs := 0;
        EndOfs := StartOfs + FileBufferSize;
        FileOpen := True;
        Exit;
      end;

ExitPoint:
      Close(WorkFile);
      if IOResult <> 0 then ;
    end;
  end;

  procedure InitBPlus(var P : ProtocolRecPtr; PortPtr : PortRecPtr);
    {-Allocates and initializes a protocol control block}
  begin
    InitCustomBPlus(P, PortPtr, DefProtocolOptions);
  end;

  procedure InitCustomBPlus(var P : ProtocolRecPtr;
                            PortPtr : PortRecPtr;
                            Options : Word);
    {-Allocates and initializes a protocol control block with options}
  var
    I : Word;
    BP : BPlusPtr absolute P;
    Temp : ProtocolDataPtr;
  begin
    SetAsyncStatus(ecOk);

    {Allocate the protocol data record}
    InitProtocolData(Temp, PortPtr, Options);
    if GetAsyncStatus <> ecOk then
      Exit;

    {Allocate the BPlus record}
    if not GetMemCheck(BP, SizeOf(BPlusProtocol)) then begin
      GotError(PortPtr, epFatal+ecOutOfMemory);
      DoneProtocolData(Temp);
      Exit;
    end;

    BP^.PData := Temp;

    with BP^, PData^ do begin
      ProtType := BPlus;
      CheckType := bcChecksum1;
      RRaw      := 0;
      RPackets  := 0;
      SRaw      := 0;
      SPackets  := 0;
      case ActCPS of
        0..30   : DefBS := 1;
        31..120 : DefBS := 4;
        else      DefBS := 16;
      end;

      FinishWait := BPDefFinishWait;
      HandshakeWait := BPTimeoutMax;
      HandleResume := NoHandleResume;
      QuotePending := False;
      SentEnq := False;
      TurnDelay := BPlusTurnDelay;
      Overhead := BPlusOverHead;
      PrepareWriting := bpPrepareWriting;

      {Allocate buffers}
      Failed := not GetMemCheck(RBuffer, BPBufferMax);
      I := 1;
      while not Failed and (I <= BPSendAheadMax) do begin
        Failed := not GetMemCheck(SBuffer[I].Buf, BPBufferMax);
        Inc(I);
      end;
      if Failed then begin
        DoneBPlus(P);
        GotError(PortPtr, epFatal+ecOutOfMemory);                      {!!.01}
      end;
    end;
  end;

  procedure DoneBPlus(var P : ProtocolRecPtr);
    {-Destroy the protocol object}
  var
    I : Word;
    BP : BPlusPtr absolute P;
  begin
    DoneProtocolData(P^.PData);
    with BP^ do begin
      for I := 1 to BPSendAheadMax do
        FreeMemCheck(SBuffer[I].Buf, BPBufferMax);
      FreeMemCheck(RBuffer, BPBufferMax);
    end;
    FreeMemCheck(BP, Sizeof(BPlusProtocol));
  end;

  procedure UpdateQuoteTable(P : ProtocolRecPtr; QS : QuoteArray);
    {-Update our QuoteTable to match the QS quotearray}
  var
    I,J,K : Integer;
    B,C : Byte;
  begin
    with BPlusPtr(P)^ do begin

      K := 0;
      C := $40;

      for I := 0 to 7 do begin
        if I = 4 then begin
          K := 128;
          C := $60;
        end;
        B := QS[I];

        for J := 0 to 7 do begin
          if (B and $80) <> 0 then
            QuoteTable[K] := Char(C);
          B := B shl 1;
          Inc(C);
          Inc(K);
        end;
      end;
    end;
  end;

  procedure bpInitVars(P : ProtocolRecPtr);
    {-Init vars that need resetting each time a DLE is seen}
  begin
    with BPlusPtr(P)^, PData^ do begin
      Next2ACK  := 1;
      Next2Fill := 1;
      SAWaiting := 0;
      SAMax     := 1;
      AbortCount:= 0;
      RPackets  := 0;
      RRaw      := 0;
      SPackets  := 0;
      SRaw      := 0;
      TotalErrors := 0;
      ResumeFlag := False;
    end;
  end;

  procedure ResetProtocol(P : ProtocolRecPtr);
    {-Init important session-dependant protocol vars}
  begin
    with BPlusPtr(P)^, PData^ do begin
      SeqNum := 0;
      SAMax := 1;
      SAErrors := 0;
      BlockLen := 512;
      AbortCount := 0;
      BPlusMode := False;
      CheckType := bcChecksum1;
      FillChar(QuoteTable, SizeOf(QuoteTable), 0);
      FillChar(OurParams, SizeOf(OurParams), 0);
      OurParams.BlkSize := 4;
      OurParams.QuoteSet := DQDefault;
      UpdateQuoteTable(P, DQDefault);
    end;
  end;



  procedure SendTransportParams(P : ProtocolRecPtr);
    {-Send our params, collect ack}
  begin
    with BPlusPtr(P)^ do begin
      with SBuffer[Next2Fill] do begin
        Buf^[1] := Char(DefWS);
        Buf^[2] := Char(DefWR);
        Buf^[3] := Char(DefBS);
        Buf^[4] := Char(DefCM);
        Buf^[5] := Char(DefDQ);
        Buf^[6] := Char(DefXP);
        Move(OurParams.QuoteSet, Buf^[7], 8);
        Buf^[15] := Char(DefDR);
        Buf^[16] := Char(DefUR);
        Buf^[17] := Char(DefFI);
      end;

      {Send the transport packet}
      SendPacket(P, '+', 17);

      {Get the ack}
      if not GetAck(P) then ;
    end;
  end;

  procedure ProcessTransportParams(P : ProtocolRecPtr);
    {-Process received "+" packet, send our params}
  var
    QSP : Boolean;
  begin
    with BPlusPtr(P)^, PData^ do begin
      OurParams.QuoteSet := DQDefault;
      FillChar(RBuffer^[RSize+1], SizeOf(RBuffer^)-RSize, 0);
      Move(RBuffer^[1], HostParams.WinSend, 4);
      Move(RBuffer^[7], HostParams.QuoteSet, 11);

      {Send '+' packet under FULL quoting}
      QSP := (RSize >= 14);
      UpdateQuoteTable(P, DQFull);
      SendTransportParams(P);

      {Make a minimal set of parameters to work from}
      if HostParams.WinSend < DefWR then
        OurParams.WinSend := HostParams.WinSend
      else
        OurParams.WinSend := DefWR;

      {If > 0, we can use all windows}
      if OurParams.WinSend <> 0 then
        SAMax := BPSendAheadMax;

      if HostParams.WinRecv < DefWS then
        OurParams.WinRecv := HostParams.WinRecv
      else
        OurParams.WinRecv := DefWS;

      if HostParams.BlkSize < DefBS then
        OurParams.BlkSize := HostParams.BlkSize
      else
        OurParams.BlkSize := DefBS;

      if OurParams.BlkSize = 0 then
        OurParams.BlkSize := 4;
      BlockLen := (OurParams.BlkSize * 128);

      if HostParams.ChkType < DefCM then
        OurParams.ChkType := HostParams.ChkType
      else
        OurParams.ChkType := DefCM;

      {If = 1, we need CRC blockchecking}
      if OurParams.ChkType > 0 then
        CheckType := bcCrc16;

      if HostParams.DROpt < DefDR then
        OurParams.DROpt := HostParams.DROpt
      else
        OurParams.DROpt := DefDR;

      if HostParams.UROpt < DefUR then
        OurParams.UROpt := HostParams.UROpt
      else
        OurParams.UROpt := DefUR;

      if HostParams.FIOpt < DefFI then
        OurParams.FIOpt := HostParams.FIOpt
      else
        OurParams.FIOpt := DefFI;

      FillChar(QuoteTable, SizeOf(QuoteTable), 0);  {Clear the Quote Table}
      UpdateQuoteTable(P, OurParams.QuoteSet);      {Set our quoting}
      if QSP then                                   {If host sent a set,}
        UpdateQuoteTable(P, HostParams.QuoteSet);   {Add his as well}
      BPlusMode := True;                            {Now using full B+}
      ProtocolTypeString[ProtType] := 'B Plus';
    end;
  end;

  procedure GetTransferPacket(P : ProtocolRecPtr);
    {-Collect and process + packet}
  begin
    with BPlusPtr(P)^ do begin
      {Start collecting from body field}
      NextSeq := IncSequence(SeqNum);
      Idx := 1;

      UpdateBlockCheck(P, Byte('+'));

      {Collect packet without yielding}
      if GetPacket(P, psGetData) then
        ProcessTransportParams(P);
    end;
  end;

  procedure ProcessFileTransferParams(P : ProtocolRecPtr);
    {-Extract Tranfer parameters}
  var
    I : Word;
  begin
    with BPlusPtr(P)^, PData^ do begin
      {Start protocol status now}
      ResetStatus(P);
      ShowFirstStatus(P);

      {Note direction}
      case RBuffer^[1] of
        'D' : Direction := dDownload;
        'U' : Direction := dUpload;
        else begin
          SendFailure(P, 'NUnimplemented Transfer Function');
          GotError(PR, epNonFatal+ecUnexpectedChar);
        end;
      end;

      {Start timer now...}
      NewTimer(Timer, 1);

      {Verify file type}
      if (RBuffer^[2] <> 'A') and (RBuffer^[2] <> 'B') then begin
        SendFailure(P, 'NUnimplemented File Type');
        GotError(PR, epNonfatal+ecUnexpectedChar);
      end;

      {Retrieve pathname}
      PathName := '';
      I := 2;
      while (RBuffer^[I] <> #0) and (I < RSize-1) do begin
        Inc(I);
        PathName := PathName + Upcase(RBuffer^[I]);
      end;

      case Direction of
        dUpload :
          begin
            LogFile(P, lfTransmitStart);

            {Prepare to read file}
            PrepareReading(P);
            if GetAsyncStatus <> ecOk then begin
              SendFailure(P, 'AAborted by user');
              if not GetAck(P) then ;
              ShowLastStatus(P);
              LogFile(P, lfReceiveFail);
              SetAsyncStatus(epNonFatal+ecFileAlreadyExists);
              Exit;
            end;
            FileOfs := 0;
          end;

        dDownLoad :
          begin
            LogFile(P, lfReceiveStart);

            if not AcceptFile(P) then begin
              GotError(PR, epNonFatal+ecFileRejected);
              ForceStatus := True;
              SendFailure(P, 'AFile rejected');
              if not GetAck(P) then ;
              Exit;
            end;

            {Prepare to write file}
            PrepareWriting(P);
            if GetAsyncStatus mod 10000 = ecFileAlreadyExists then begin
              SendFailure(P, 'AAborted by user');
              if not GetAck(P) then ;
              ShowLastStatus(P);
              LogFile(P, lfReceiveFail);
              SetAsyncStatus(epNonFatal+ecFileAlreadyExists);
              Exit;
            end;
          end;
      end;
    end;
  end;

  procedure GetFileTransferPacket(P : ProtocolRecPtr);
    {-Collect and process T packet}
  begin
    with BPlusPtr(P)^ do begin
      {Start collecting from body field}
      NextSeq := IncSequence(SeqNum);
      Idx := 1;

      UpdateBlockCheck(P, Byte('T'));

      {Collect packet without yielding}
      if GetPacket(P, psGetData) then
        ProcessFileTransferParams(P);
    end;
  end;

  procedure ProcessENQ(P : ProtocolRecPtr);
    {-Called when the terminal handler receives an <ENQ>}
  begin
    with BPlusPtr(P)^, PData^ do begin
      Aborting := False;
      ResetProtocol(P);
      PutString(PR, cDLE+'++'+cDLE+'0');
    end;
  end;

  procedure ProcessESCI(P : ProtocolRecPtr; X, Y : Byte);
    {-Called by terminal handler when <ESC><'I'> seen at port}
  var
    S : String;
    T : String[5];
    I : Integer;
  begin
    with BPlusPtr(P)^, PData^ do begin
      S := ESCIResponse;

      {Make sure tailer is in place for later}
      if Pos(',+',S) = 0 then
        S := S + ',+';

      {If 'SSxx' part of string, insert screen size values}
      I := Pos('SSxx',S);
      if I > 0 then begin
        S[I+2] := Chr(Y+31);
        S[I+3] := Chr(X+31);
      end;

      {Build the string's checksum and append it to the string}
      X := 0;
      for I := 1 to Length(S) do
        Inc(X, Ord(S[I]));
      Str(X, T);
      S := S + T;

      {Send the response}
      PutString(PR, S+^M);
    end;
  end;

  procedure ProcessDLE(P : ProtocolRecPtr; var Start, Upload : Boolean);
    {-Called from terminal loop when <DLE> seen from host}
  var
    TermState : TermPacketStateType;
    Finished : Boolean;
    C : Char;
  begin
    with BPlusPtr(P)^, PData^ do begin
      Start := False;
      TermState := tpsStart;
      PR^.ProtocolActive := True;
      Finished := False;

      repeat
        case TermState of
          tpsStart :
            begin
              NewTimer(ReplyTimer, HandshakeWait);
              TermState := tpsWaitB;
            end;
          tpsWaitB :
            if CharReady(PR) then begin
              GetChar(PR, C);
              if C = 'B' then begin
                NewTimer(ReplyTimer, HandshakeWait);
                TermState := tpsWaitSeq;
              end else
                TermState := tpsError;
            end else if TimerExpired(ReplyTimer) then
              TermState := tpsError;
          tpsWaitSeq :
            if CharReady(PR) then begin
              {Get sequence byte...}
              GetChar(PR, C);
              if CheckType = bcCrc16 then
                CheckSum := $FFFF
              else
                CheckSum := 0;
              UpdateBlockCheck(P, Byte(C));
              TermState := tpsWaitType;
              PacketNum := Ord(C)-Ord('0');
            end else if TimerExpired(ReplyTimer) then
              TermState := tpsError;
          tpsWaitType :
            if CharReady(PR) then begin
              GetChar(PR, C);
              case C of
                '+' :
                  begin
                    {Collect and process + packet, send our options}
                    bpInitVars(P);
                    GetTransferPacket(P);
                    Finished := True;
                  end;
                'T' :
                  begin
                    {Collect and process T packet}
                    GetFileTransferPacket(P);
                    if GetAsyncStatus = ecOk then begin
                      Start := True;
                      Upload := Direction = dUpload;
                    end;
                    Finished := True;
                  end;
                else
                  TermState := tpsError;
              end;
            end else if TimerExpired(ReplyTimer) then
              TermState := tpsError;
          tpsError :
            {Timeout getting char or unknown packet type, just return}
            Finished := True;
        end;
      until Finished;

      PR^.ProtocolActive := False;
    end;
  end;

  procedure SetHandleResumeProc(P : ProtocolRecPtr; HRP : HandleResumeProc);
    {-Set custom HandleResume procedure}
  begin
    BPlusPtr(P)^.HandleResume := HRP;
  end;

  procedure AbortProtocol(P : ProtocolRecPtr);
    {-Aborts the protocol}
  var
    SaveStat : Word;
  begin
    with BPlusPtr(P)^, PData^ do begin
      SaveStat := GetAsyncStatus;
      GotError(PR, epFatal+ecCancelRequested);
      if SaveStat <> ecUserAbort then
        SetAsyncStatus(SaveStat);
    end;
  end;

  function HandleAbort(P : ProtocolRecPtr) : Boolean;
    {-Call user abort function, abort protocol and return True if user aborts}
  begin
    with BPlusPtr(P)^, PData^ do begin
      if PR^.UserAbort then begin
        AbortProtocol(P);
        HandleAbort := True;
      end else
        HandleAbort := False;
    end;
  end;


  procedure bpHandleResumeFail(P : ProtocolRecPtr);
    {-Resume failed, rewrite the file}
  var
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
    Result : Word;
  begin
    with BPlusPtr(P)^, PData^ do begin
      Close(WorkFile);

      {If we default to Rename, rename the file}
      if WriteFailOpt = WriteRename then begin
        FSplit(Pathname, Dir, Name, Ext);
        Name[1] := '$';
        Pathname := Dir + Name + Ext;
        Assign(WorkFile, PathName);
        GotError(PR, epNonFatal+ecFileRenamed);
      end;

      {Otherwise just overwrite}
      Rewrite(WorkFile, 1);
      Result := IoResult;
      if Result <> 0 then begin
        FileOpen := False;
        GotError(PR, epNonFatal+Result);
        apUserStatus(P, False, False);
        SendFailure(P, 'CCannot create file');
        Exit;
      end;

      {Set status vars}
      BytesTransferred := 0;
      GotError(PR, epNonFatal+ecResumeBad);
      apUserStatus(P, False, False);
      ResumeFlag := False;
      RPackets := 0;
      SPackets := 0;
      bpSendAck(P);
      NewTimer(Timer, 1);
      FileOfs := 0;
      InitFilePos := 0;
    end;
  end;

  procedure PrepareTransmitPartBP(P : ProtocolRecPtr);
    {-Prepare to transmit file in parts}
  begin
    with BPlusPtr(P)^, PData^ do begin
      {Do parent inits}
      FindingFirst := True;
      FileListIndex := 0;
      PR^.ProtocolActive := True;

      {Set initial state}
      BPlusState := tbInitial;
      SetAsyncStatus(ecOk);
      SaveStatus := ecOk;
      ErrorStatus := ecOk;
    end;
  end;

  function ProtocolTransmitPartBP(P : ProtocolRecPtr) : ProtocolStateType;
    {-Perform one increment of a protocol transmit}
  label
    ExitPoint;
  begin
    with BPlusPtr(P)^, PData^ do begin

      {Restore previous AsyncStatus}
      SetAsyncStatus(SaveStatus);

      {Check for user abort}
      case SaveStatus of
        ecCancelRequested,
        ecFileRejected : ;
        else begin
          if HandleAbort(P) then begin
            if BPlusState = tbWaitErrorAck then
              BPlusState := tbCleanup
            else begin
              {Send failure packet}
              SendFailure(P, 'AAborted by user');
              SetAsyncStatus(ecCancelRequested);
              BPlusState := tbError;
            end;
            ForceStatus := True;
          end;
        end;
      end;

      {Show status at requested intervals and after significant events}
      if ForceStatus or TimerExpired(StatusTimer) then begin
        if ErrorStatus <> ecOk then
          SetAsyncStatus(ErrorStatus);
        ElapsedTics := ElapsedTime(Timer);
        apUserStatus(P, False, False);
        NewTimer(StatusTimer, StatusInterval);
        ForceStatus := False;
      end;

      {Main state processor}
      case BPlusState of
        tbInitial :
          begin
            NewTimer(ReplyTimer, HandshakeWait);
            BPlusState := tbGetBlock;
            LastBlock := False;
          end;

        tbGetBlock :
          if LastBlock then
            BPlusState := tbEndOfFile
          else with SBuffer[Next2Fill] do begin
            if PR^.Buffered then                                       {!!.01}
              if (PR^.OutBuffLen > 4096+10) and                        {!!.01}
                 (FlagIsSet(apFlags, apBP2KTransmit)) then             {!!.01}
                Num := BlockLen                                        {!!.01}
              else                                                     {!!.01}
                Num := 1024                                            {!!.01}
            else                                                       {!!.01}
              Num := BlockLen;                                         {!!.01}
            LastBlock :=                                               {!!.01}
               ReadProtocolBlock(P, DataBlockTypePtr(Buf)^, Num);      {!!.01}
            if GetAsyncStatus = ecOk then begin
              Inc(FileOfs, Num);
              BPlusState := tbWaitFreeSpace;
              NewTimer(ReplyTimer, TransTimeout);
            end else begin
              SaveStatus := GetAsyncStatus;
              SendFailure(P, 'EFile read failure');
              BPlusState := tbError;
            end;
          end;

        tbWaitFreeSpace :
          with SBuffer[Next2Fill] do begin
            if OutBuffFree(PR) > (Num*2)+10 then
              BPlusState := tbSendData
            else if TimerExpired(ReplyTimer) then begin
              SendFailure(P, 'ETimeout waiting for output buffer space');
              BPlusState := tbError;
            end;
          end;

        tbSendData :
          with SBuffer[Next2Fill] do begin
            SendPacket(P, 'N', Num);
            LastBlockSize := Num;
            ForceStatus := True;

            if SAWaiting = 0 then begin
              NewTimer(ReplyTimer, HandshakeWait);
              AckState := acGetDLE;
            end;
            BPlusState := tbCheckAck;
          end;

        tbCheckAck :
          if SAWaiting < SAMax then
            BPlusState := tbGetBlock
          else if CollectAck(P) then begin
            if GetAsyncStatus = ecOk then begin
              BPlusState := tbGetBlock;
              Inc(BytesTransferred, LastBlockSize);
              Dec(BytesRemaining, LastBlockSize);
            end else begin
              ForceStatus := True;
              SendFailure(P, 'EToo many errors');
              BPlusState := tbError;
            end;
          end;

        tbEndOfFile :
          begin
            {Send TransferComplete packet}
            with SBuffer[Next2Fill] do begin
              Buf^[1] := 'C';
              SendPacket(P, 'T', 1);
              NewTimer(ReplyTimer, HandshakeWait);
              BPlusState := tbEofAck;
            end;
            if SAWaiting = 0 then begin
              NewTimer(ReplyTimer, HandshakeWait);
              AckState := acGetDLE;
            end;
          end;

        tbEofAck :
          if CollectAck(P) then
            if GetAsyncStatus = ecOK then
              BPlusState := tbCleanup
            else begin
              SendFailure(P, 'EToo many errors');
              ForceStatus := True;
              BPlusState := tbError;
            end;

        tbError :
          begin
            {Save failure status}
            ErrorStatus := GetAsyncStatus;

            {Start waiting for acknowledgment (failure packet already sent)}
            BPlusState := tbWaitErrorAck;
            AckState := acGetDLE;
            NewTimer(ReplyTimer, FinishWait);
          end;

        tbWaitErrorAck :
          if CollectAck(P) then begin
            SetAsyncStatus(ErrorStatus);
            ForceStatus := True;
            BPlusState := tbCleanup;
          end;

        tbCleanup :
          begin
            SaveStatus := GetAsyncStatus;
            FinishReading(P);
            SetAsyncStatus(SaveStatus);

            {Log file}
            if GetAsyncStatus = ecOk then
              LogFile(P, lfTransmitOK)
            else
              LogFile(P, lfTransmitFail);

            ShowLastStatus(P);
            FlushInBuffer(PR);
            PR^.ProtocolActive := False;
            BPlusState := tbDone;
          end;
      end;

ExitPoint:
      {Set function result}
      case BPlusState of
        tbWaitFreeSpace,
        tbCheckAck,
        tbEofAck        : ProtocolTransmitPartBP := psWaiting;

        tbInitial,
        tbGetBlock,
        tbSendData,
        tbEndOfFile,
        tbError,
        tbCleanup       : ProtocolTransmitPartBP := psReady;

        tbDone          : ProtocolTransmitPartBP := psFinished;
      end;

      {Store AsyncStatus}
      SaveStatus := GetAsyncStatus;
    end;
  end;

  procedure ProtocolTransmitBP(P : ProtocolRecPtr);
    {-Transmit all files that fit the Mask}
  begin
    with BPlusPtr(P)^, PData^ do begin
      PrepareTransmitPartBP(P);
      if GetAsyncStatus <> ecOk then
        Exit;

      repeat
        UserBack(P);
      until ProtocolTransmitPartBP(P) = psFinished;

      PR^.ProtocolActive := False;
    end;
  end;

  procedure PrepareReceivePartBP(P : ProtocolRecPtr);
    {-Prepare to receive BPlus parts}
  begin
    {Do parent inits}
    with BPlusPtr(P)^, PData^ do begin

      {Do parent inits}
      PR^.ProtocolActive := True;
      GotOneFile := False;

      {Init the state machine}
      BPlusState := rbInitial;
      SetAsyncStatus(ecOk);
      SaveStatus := ecOk;
      ErrorStatus := ecOk;
    end;
  end;

  function ProtocolReceivePartBP(P : ProtocolRecPtr) : ProtocolStateType;
    {-Perform one increment of a protocol receive}
  label
    ExitPoint;
  var
    BlockSize : Word;
    Handshake : Char;
    C : Char;
    TempStatus : Word;
    I : Word;
    S : String;
    SaveSize : LongInt;
  begin
    with BPlusPtr(P)^, PData^ do begin

      {Restore previous AsyncStatus}
      SetAsyncStatus(SaveStatus);

      {Check for user abort}
      case SaveStatus of
        ecCancelRequested,
        ecFileRejected : ;
        else begin
          if HandleAbort(P) then begin
            if BPlusState = rbWaitErrorAck then
              BPlusState := rbCleanup
            else begin
              {Send failure packet}
              SendFailure(P, 'AAborted by user');
              SetAsyncStatus(ecCancelRequested);
              BPlusState := rbError;
            end;
            ForceStatus := True;
          end;
        end;
      end;

      {Show status at requested intervals and after significant events}
      if ForceStatus or TimerExpired(StatusTimer) then begin
        if ErrorStatus <> ecOk then
          SetAsyncStatus(ErrorStatus);
        apUserStatus(P, False, False);
        NewTimer(StatusTimer, StatusInterval);
        ForceStatus := False;
      end;

      {Main state processor}
      case BPlusState of
        rbInitial :
          begin
            {Start waiting for first packet}
            NewTimer(ReplyTimer, HandshakeWait);
            ErrorStatus := ecOK;

            BPlusState := rbGetDLE;
          end;

        rbGetDLE :
          if CharReady(PR) then begin
            GetChar(PR, C);
            if C = cDLE then
              BPlusState := rbGetB
            else
              BPlusState := rbGetDLE;
          end else if TimerExpired(ReplyTimer) then begin
            BPlusState := rbSendEnq;
          end;

        rbGetB :
          if CharReady(PR) then begin
            GetChar(PR, C);
            if C = 'B' then begin
              BPlusState := rbCollectPacket;
              NAKsent := False;
              NextSeq := IncSequence(SeqNum);
              BlockErrors := 0;
              PacketState := psGetSeq;
            end else begin
              BPlusState := rbSendEnq;
            end;
          end else if TimerExpired(ReplyTimer) then begin
            BPlusState := rbSendEnq;
          end;

        rbCollectPacket :
          if CollectPacket(P) then begin
            {Got a complete packet -- process it}
            if GetAsyncStatus = ecOk then begin
              BlockErrors := 0;
              BPlusState := rbProcessPacket;
              ForceStatus := True;
            end else begin
              {Timeout or too many block errors, let rbSendEnq handle}
              BPlusState := rbSendEnq;
              NewTimer(ReplyTimer, HandshakeWait);
            end;
          end;

        rbProcessPacket :
          begin
            ForceStatus := True;

            case LastType of
              'N':  {Next data packet, write it to file}
                begin
                  {Call the write method to write this block}
                  Failed := WriteProtocolBlock(P,
                            DataBlockTypePtr(RBuffer)^, RSize-1);      {!!.01}

                  {Process result}
                  if Failed then begin
                    TempStatus := GetAsyncStatus;
                    SendFailure(P, 'EWrite failure');
                    SetAsyncStatus(TempStatus);
                    ForceStatus := True;
                    BPlusState := rbError;
                  end else begin
                    Inc(FileOfs, RSize-1);
                    Dec(BytesRemaining, RSize-1);
                    Inc(BytesTransferred, RSize-1);
                    ElapsedTics := ElapsedTime(Timer);
                    bpSendAck(P);

                    {Prepare to get next packet}
                    BPlusState := rbGetDLE;
                    NewTimer(ReplyTimer, HandshakeWait);
                  end;
                end;

              'T':     {Transfer control packet, process per second byte}
                begin
                  case RBuffer^[1] of
                    'C':   {Transfer Complete packet}
                      begin
                        FinishWriting(P);
                        bpSendAck(P);
                        BPlusState := rbCleanup;
                      end;

                    'I':   {Transfer Info packet, we only use FileSize field here}
                      begin
                        bpSendAck(P);
                        I := 4;
                        S := '';
                        while (I <= RSize-1) and
                              (RBuffer^[I] >= '0') and
                              (RBuffer^[I] <= '9') do begin
                          S := S + RBuffer^[I];
                          Inc(I);
                        end;
                        Val(S, BytesRemaining, I);
                        if I <> 0 then
                          BytesRemaining := 0;
                        SrcFileLen := BytesRemaining;

                        {Reset packet counts to reflect data}
                        RPackets := 0;
                        SPackets := 0;

                        {Get next packet}
                        BPlusState := rbGetDLE;
                      end;

                    'f':   {Host Failed Resume, rewrite the file}
                      begin
                        bpHandleResumeFail(P);
                        BPlusState := rbGetDLE;
                      end;

                    else begin
                        {Unknown T packet type}
                        GotError(PR, epNonFatal + ecUnexpectedChar);
                        SendFailure(P, 'NInvalid T Packet');
                        BPlusState := rbError;
                      end;
                  end;
                end;

              'F':    {Failure packet, exit immediately}
                begin
                  GotError(PR, epNonFatal+ecHostCan);
                  bpSendAck(P);
                  BPlusState := rbCleanup;
                end;
             else begin
                  {Unsupported packet type, exit immediately}
                  GotError(PR, epNonFatal+ecUnexpectedChar);
                  SendFailure(P, 'NUnknown packet type');
                  BPlusState := rbError;
                end;
            end;
          end;

        rbSendEnq :
          begin
            GotError(PR, epNonFatal+ecTimeout);
            Inc(BlockErrors);
            Inc(TotalErrors);
            if BlockErrors > BPErrorMax then begin
              SendFailure(P, 'ATimeout');
              BPlusState := rbError;
            end else
              BPlusState := rbGetDLE;
          end;

        rbError :
          begin
            {Save failure status}
            ErrorStatus := GetAsyncStatus;

            {Start waiting for acknowledgment (failure packet already sent)}
            BPlusState := rbWaitErrorAck;
            AckState := acGetDLE;
            NewTimer(ReplyTimer, FinishWait);
          end;

        rbWaitErrorAck :
          if CollectAck(P) then begin
            SetAsyncStatus(ErrorStatus);
            ForceStatus := True;
            BPlusState := rbCleanup;
          end;
        rbCleanup :
          begin
            {Close file}
            SaveStatus := GetAsyncStatus;
            SaveSize := SrcFileLen;
            FinishWriting(P);
            SetAsyncStatus(SaveStatus);
            SrcFileLen := SaveSize;

            {Log receive status}
            if GetAsyncStatus <> ecOk then
              LogFile(P, lfReceiveFail)
            else
              LogFile(P, lfReceiveOK);

            ShowLastStatus(P);
            FlushInBuffer(PR);
            PR^.ProtocolActive := False;
            BPlusState := rbDone;
          end;
      end;

ExitPoint:
      {Set function result}
      case BPlusState of
        rbFinished,
        rbCleanup,
        rbProcessPacket,
        rbSendEnq,
        rbError :                 ProtocolReceivePartBP := psReady;

        rbInitial,
        rbGetDLE,
        rbGetB,
        rbWaitErrorAck,
        rbCollectPacket :         ProtocolReceivePartBP := psWaiting;

        rbDone :                  ProtocolReceivePartBP := psFinished;
      end;
      {Store AsyncStatus}
      SaveStatus := GetAsyncStatus;
    end;
  end;

  procedure ProtocolReceiveBP(P : ProtocolRecPtr);
    {-Receive files}
  var
    State : ProtocolStateType;
  begin
    with BPlusPtr(P)^, PData^ do begin
      PrepareReceivePartBP(P);
      if GetAsyncStatus <> ecOk then
        Exit;

      {Get file in parts}
      repeat
        State := ProtocolReceivePartBP(P);
        if State = psWaiting then
          UserBack(P);
      until State = psFinished;
    end;
  end;

  procedure NoHandleResume(P : ProtocolRecPtr);
    {-Empty HandleResume procedure}
  begin
  end;

end.
