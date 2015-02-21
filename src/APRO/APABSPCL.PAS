{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                    APABSPCL.PAS 2.03                  *}
{*     Copyright (c) TurboPower Software 1991.           *}
{* Portions copyright (c) Information Technology 1989,   *}
{*    and used under license to TurboPower Software      *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$IFDEF UseOOP}
  !! STOP COMPILE - this unit requires UseOOP to be undefined
{$ENDIF}

unit ApAbsPcl;
  {-Provides "abstract" protocol data definitions and general procedures}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpInline,
  OpDate,
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpInline,
  TpString,
  TpDate,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD;
  {$ELSE}
  ApMisc,
  ApPort,
  ApTimer,
  ApCom;
  {$ENDIF}

{$I APABSPCL.PA0}

implementation

{!!.01}
{$IFDEF DPMI}
procedure IntOff; inline($9C/$FA);      {PUSHF/CLI}
procedure IntOn; inline($58/            {POP  AX}
                        $A9/$00/$02/    {TEST AX,0200}
                        $74/$01/        {JE   @DONE}
                        $FB);           {STI}
{$ELSE}
procedure IntOff; inline($9C/$FA);      {PUSHF/CLI}
procedure IntOn; inline($9D);           {POPF}
{$ENDIF}

var
  {Set to 1/1/1970 00:00 GMT}
  StartDate : DateTimeRec;

  procedure InitProtocolData(var P : ProtocolDataPtr;
                             PortPtr : PortRecPtr;
                             Options : Word);
    {-Allocates and initializes a protocol data block}
  begin
    SetAsyncStatus(ecOk);

    {Allocate a protocol data block}
    if not GetMemCheck(P, SizeOf(ProtocolData)) then begin
      GotError(PortPtr, ecOutOfMemory);
      Exit;
    end;

    with P^ do begin

      {!!.01 moved from prepareread/write}
      if not GetMemCheck(FileBuffer, FileBufferSize) then begin
        FreeMemCheck(P, SizeOf(ProtocolData));
        GotError(PR, epFatal+ecOutOfMemory);
        Exit;
      end;

      {Save the port record}
      PR := PortPtr;

      {Initialize the protocol fields}
      UserStatus := NoStatus;
      HandshakeWait := DefHandshakeWait;
      HandshakeRetry := DefHandshakeRetry;
      BlockLen := 128;
      PathName := '';
      SrcFileLen := 0;
      SrcFileDate := 0;
      ElapsedTics := 0;
      BytesRemaining := 0;
      BytesTransferred := 0;
      InProgress := 0;
      EotCheckCount := 1;
      BatchProtocol := False;
      WriteFailOpt := WriteFail;
      FileOpen := False;
      NextFile := NextFileMask;
      SearchMask := '';
      apFlags := Options;
      LogFile := NoLogFile;
      AcceptFile := NoAcceptFile;
      UserBack := NoUserBack;
      DestDir := '';
      CheckType := bcNone;
      ActCPS := PR^.CurBaud div 10;
      StatusInterval := DefStatusInterval;
      OverHead := 0;
      TurnDelay := 0;
      InitFilePos := 0;
      TransTimeout := DefTransTimeout;
      PrepareReading := apPrepareReading;
      ReadProtocolBlock := apReadProtocolBlock;
      FinishReading := apFinishReading;
      PrepareWriting := apPrepareWriting;
      WriteProtocolBlock := apWriteProtocolBlock;
      FinishWriting := apFinishWriting;
    end;
  end;

  procedure DoneProtocolData(var P : ProtocolDataPtr);
    {-Disposes of a protocol data block}
  begin
    FreeMemCheck(P^.FileBuffer, FileBufferSize);                       {!!.01}
    FreeMemCheck(P, SizeOf(ProtocolData));
  end;

  procedure SetShowStatusProc(P : ProtocolRecPtr; SProc : ShowStatusProc);
    {-Sets a user status function}
  begin
    P^.PData^.UserStatus := SProc;
  end;

  procedure SetNextFileFunc(P : ProtocolRecPtr; NFFunc : NextFileFunc);
    {-Sets function for batch protocols to call to get file to transmit}
  begin
    P^.PData^.NextFile := NFFunc;
  end;

  procedure SetFileMask(P : ProtocolRecPtr; NewMask : PathStr);
    {-Sets dir/file mask for built-in NextFileMask function}
  begin
    P^.PData^.SearchMask := NewMask;
  end;

  procedure SetFileList(P : ProtocolRecPtr; FLP : FileListPtr);
    {-Sets the file list to use for the built-in NextFileList function}
  begin
    P^.PData^.FileList := FLP;
  end;

  procedure MakeFileList(P : ProtocolRecPtr;
                         var FLP : FileListPtr;
                         Size : Word);
    {-Allocates a new file list of Size bytes}
  begin
    SetAsyncStatus(ecOk);
    if GetMemCheck(FLP, Size) then begin
      FillChar(FLP^, Size, 0);
      P^.PData^.FileListMax := Size;
    end else
      GotError(P^.PData^.PR, epFatal+ecOutOfMemory);
  end;

  procedure DisposeFileList(P : ProtocolRecPtr;
                            var FLP : FileListPtr;                     {!!.01}
                            Size : Word);
    {-Disposes of file list FLP}
  begin
    FreeMemCheck(FLP, Size);
  end;

  procedure AddFileToList(P : ProtocolRecPtr;
                          FLP : FileListPtr;
                          PName : PathStr);
    {-Adds pathname PName to file list FLP}
  const
    {MaxList = 65535;}
    Separator = ';';
    EndOfListMark = #0;
  var
    I : Word;
  begin
    SetAsyncStatus(ecOk);

    with P^.PData^ do begin
    {Search for the current end of the list}
      for I := 0 to FileListMax-1 do
        if FLP^[I] = EndOfListMark then begin
          {Found the end of the list -- try to add the new file}
          if (LongInt(I)+Length(PName)+1) >= FileListMax then begin
            {Not enough room to add file}
            GotError(PR, epNonFatal+ecOutOfMemory);
            Exit;
          end else begin
            {There's room -- add the file}
            if I <> 0 then begin
              FLP^[I] := Separator;
              Inc(I);
            end;
            Move(PName[1], FLP^[I], Length(PName));
            FLP^[I+Length(PName)] := EndOfListMark;
            Exit;
          end;
        end;
    end;

    {Never found endoflist marker}
    GotError(P^.PData^.PR, epFatal+ecBadFileList);
  end;

  procedure SetDestinationDirectory(P : ProtocolRecPtr; Dir : DirStr);
    {-Set the destination directory for received files}
  begin
    P^.PData^.DestDir := StUpcase(Dir);
  end;

  procedure SetReceiveFilename(P : ProtocolRecPtr; Fname : PathStr);
    {-Give a name to the file to be received}
  begin
    with P^, PData^ do
      if (DestDir <> '') and (JustPathName(Fname) = '') then
        Pathname := AddBackSlash(DestDir)+Fname
      else
        Pathname := Fname;
  end;

  procedure SetLogFileProc(P : ProtocolRecPtr; LFP : LogFileProc);
    {-Sets a procedure to be called when a file is received}
  begin
    P^.PData^.LogFile := LFP;
  end;

  procedure SetAcceptFileFunc(P : ProtocolRecPtr; AFP : AcceptFileFunc);
    {-Sets a procedure to be called when a file is received}
  begin
    P^.PData^.AcceptFile := AFP;
  end;

  procedure SetBackgroundProc(P : ProtocolRecPtr; BP : UserBackProc);
    {-Sets a background procedure to be called while a file is transferred}
  begin
    P^.PData^.UserBack := BP;
  end;

  procedure SetHandshakeWait(P : ProtocolRecPtr;
                             NewHandshake, NewRetry : Word);
    {-Set the wait time for the initial handshake}
  begin
    with P^.PData^ do begin
      if NewHandshake <> 0 then
        HandshakeWait := NewHandshake;
      if NewRetry <> 0 then
        HandshakeRetry := NewRetry;
    end;
  end;

  procedure SetOverwriteOption(P : ProtocolRecPtr; Opt : WriteFailOptions);
    {-Set option for what to do when the destination file already exists}
  begin
    P^.PData^.WriteFailOpt := Opt;
  end;

  procedure SetActualBPS(P : ProtocolRecPtr; BPS : LongInt);
    {-Sets actual CPS rate (only needed if modem differs from port)}
  begin
    P^.PData^.ActCPS := BPS div 10;
  end;

  procedure SetEfficiencyParms(P : ProtocolRecPtr;
                               BlockOverhead, TurnAroundDelay : Word);
    {-Sets efficiency parameters for EstimateTransferSecs}
  begin
    with P^.PData^ do begin
      Overhead := BlockOverhead;
      TurnDelay := TurnAroundDelay;
    end;
  end;

  procedure SetProtocolPort(P : ProtocolRecPtr; PortPtr : PortRecPtr);
    {-Sets PortPtr as the port for this protocol}
  begin
    with P^.PData^ do
      PR := PortPtr;
  end;

  procedure apOptionsOn(P : ProtocolRecPtr; OptionFlags : Word);
    {-Activate multiple options}
  begin
    with P^.PData^ do
      apFlags := apFlags or (OptionFlags and not BadProtocolOptions);
  end;

  procedure apOptionsOff(P : ProtocolRecPtr; OptionFlags : Word);
    {-Deactivate multiple options}
  begin
    with P^.PData^ do
      apFlags := apFlags and not (OptionFlags and not BadProtocolOptions);
  end;

  function apOptionsAreOn(P : ProtocolRecPtr; OptionFlags : Word) : Boolean;
    {-Return True if all specified options are on}
  begin
    with P^.PData^ do
      apOptionsAreOn := (apFlags and OptionFlags = OptionFlags);
  end;

  function GetFilename(P : ProtocolRecPtr) : PathStr;
    {-Returns the name of the current file}
  begin
    with P^.PData^ do
      GetFileName := JustFilename(Pathname);
  end;

  function GetPathname(P : ProtocolRecPtr) : PathStr;
    {-Returns the complete pathname of the current file (if known)}
  begin
    with P^.PData^ do
      GetPathname := Pathname;
  end;

  function GetFileSize(P : ProtocolRecPtr) : LongInt;
    {-Returns current file size (0 if no file active)}
  begin
    with P^.PData^ do
      GetFileSize := SrcFileLen;
  end;

  function GetBytesRemaining(P : ProtocolRecPtr) : LongInt;
    {-Return bytes not yet transferred}
  var
    BR : Longint;
  begin
    with P^.PData^ do begin
      BR := SrcFileLen - GetBytesTransferred(P);
      if BR < 0 then
        BR := 0;
      GetBytesRemaining := BR;
    end;
  end;

  function GetBytesTransferred(P : ProtocolRecPtr) : LongInt;
    {-Returns bytes already transferred}
  var
    TotalOverhead : Word;
    OutBuff : Word;
    BT : LongInt;
  begin
    with P^.PData^ do begin
      OutBuff := OutBuffUsed(P^.PData^.PR);
      if OutBuff >= BlockLen then begin
        if BlockLen <> 0 then                                          {!!.01}
          TotalOverhead := Overhead * (OutBuff div BlockLen)
        else                                                           {!!.01}
          TotalOverhead := Overhead;                                   {!!.01}
        BT := BytesTransferred - (OutBuff - TotalOverhead);
        if BT > 0 then
          GetBytesTransferred := BT
        else
          GetBytesTransferred := 0;
      end else
        GetBytesTransferred := BytesTransferred;
    end;
  end;

  function GetElapsedTics(P : ProtocolRecPtr) : LongInt;
    {-Returns tics since first block was sent (or received)}
  begin
    with P^.PData^ do
      GetElapsedTics := ElapsedTics;
  end;

  function GetBlockErrors(P : ProtocolRecPtr) : Word;
    {-Returns the number of errors received this block}
  begin
    with P^.PData^ do
      GetBlockErrors := BlockErrors;
  end;

  function GetTotalErrors(P : ProtocolRecPtr) : Word;
    {-Returns the number of errors recieved this transfer}
  begin
    with P^.PData^ do
      GetTotalErrors := TotalErrors;
  end;

  function GetProtocol(P : ProtocolRecPtr) : Byte;
    {-Returns the current protocol type}
  begin
    with P^.PData^ do
      GetProtocol := ProtType;
  end;

  function GetBlockSize(P : ProtocolRecPtr) : Word;
    {-Returns the current block size}
  begin
    with P^.PData^ do
      GetBlockSize := BlockLen;
  end;

  function GetBlockNum(P : ProtocolRecPtr) : Word;
    {-Returns the current block number}
  begin
    with P^.PData^ do
      GetBlockNum := GetBytesTransferred(P) div BlockLen;
  end;

  function GetCurrentBlockNum(P : ProtocolRecPtr) : Word;
    {-Returns the block number of the block being transferred}
  var
    BT : Longint;
    Block : Word;
  begin
    with P^.PData^ do begin
      BT := GetBytesTransferred(P);
      Block := BT div BlockLen;
      if BT mod BlockLen <> 0 then
        Inc(Block);
      GetCurrentBlockNum := Block;
    end;
  end;

  function SupportsBatch(P : ProtocolRecPtr) : Boolean;
    {-Returns True if this protocol supports batch file transfers}
  begin
    with P^.PData^ do
      SupportsBatch := BatchProtocol;
  end;

  function GetCheckType(P : ProtocolRecPtr) : Byte;
    {-Returns the bcXxx code for the block check type}
  begin
    with P^.PData^ do
      GetCheckType := CheckType;
  end;

  function GetInitialFilePos(P : ProtocolRecPtr) : LongInt;
    {-Returns the file position at the start of resumed file transfer}
  begin
    with P^.PData^ do
      GetInitialFilePos := InitFilePos;
  end;

  function EstimateTransferSecs(P : ProtocolRecPtr;
                                Size : LongInt) : LongInt;
    {-Return estimated seconds to transfer Size bytes}
  var
    Efficiency : LongInt;
    EffectiveCPS : LongInt;
  begin
    with P^.PData^ do begin
      if Size = 0 then
        EstimateTransferSecs := 0
      else begin
        {Calcuate efficiency of this protocol}
        Efficiency := (BlockLen * LongInt(100)) div
                      (BlockLen + OverHead +
                      ((LongInt(TurnDelay) * ActCPS) div 1000));       {!!.02}
        EffectiveCPS := (ActCPS * Efficiency) div 100;

        {Calculate remaining seconds}
        if EffectiveCPS > 0 then
          EstimateTransferSecs := Size div EffectiveCPS
        else
          EstimateTransferSecs := 0;
      end;
    end;
  end;

  procedure ShowFirstStatus(P : ProtocolRecPtr);
    {-Show (possible) first status}
  begin
    with P^.PData^ do begin
      apUserStatus(P, (InProgress = 0), False);
      Inc(InProgress);
    end;
  end;

  procedure ShowLastStatus(P : ProtocolRecPtr);
    {-Reset field and show last status}
  begin
    with P^.PData^ do begin
      if InProgress <> 0 then begin
        Dec(InProgress);
        apUserStatus(P, False, (InProgress = 0));
      end;
    end;
  end;

  procedure ResetStatus(P : ProtocolRecPtr);
    {-Conditionally reset all status vars}
  begin
    with P^.PData^ do begin
      if InProgress = 0 then begin
        {New protocol, reset status vars}
        SrcFileLen := 0;
        BytesRemaining := 0;
      end;
      BytesTransferred := 0;
      ElapsedTics := 0;
      BlockErrors := 0;
      TotalErrors := 0;
      BlockNum := 0;
    end;
  end;

  function WaitForFreeSpace(P : ProtocolRecPtr; W, T : Word) :  Boolean;
    {Wait until buffer has W free bytes}
  var
    ET : EventTimer;
  begin
    with P^, PData^ do begin
      WaitForFreeSpace := True;
      NewTimer(ET, T);
      while (OutBuffFree(PR) < W) and
             not WaitComplete(PR, ET) do ;

      {Check for user abort during WaitComplete}
      if GetAsyncStatus <> ecOk then
        WaitForFreeSpace := False;
    end;
  end;

  function Crc32ofFile(P : ProtocolRecPtr;
                       FName : PathStr; Len : Longint) : LongInt;
    {-Returns Crc32 of FName}
  const
    BufSize = 8192;
  type
    BufArray = array[1..BufSize] of Byte;
  var
    BytesRead, I : Word;
    Result : Word;
    F : File;
    Buffer : ^BufArray;
    FileLoc : Longint;
    Crc : Longint;
    SaveMode : Byte;                                                   {!!.02}
  label
    ExitPoint;
  begin
    SetAsyncStatus(ecOk);

    {If Len is zero then check the entire file}
    if Len = 0 then
      Len := MaxLongint;

    {Get a buffer}
    if not GetMemCheck(Buffer, BufSize) then begin
      GotError(P^.PData^.PR, epNonFatal+ecOutOfMemory);
      Exit;
    end;

    {Open the file}
    SaveMode := FileMode;                                              {!!.02}
    FileMode := GetAproFileMode;                                {!!.02}{!!.03}
    Assign(F, FName);
    Reset(F, 1);
    FileMode := SaveMode;                                              {!!.02}
    Result := IOResult;
    if Result <> 0 then begin
      GotError(P^.PData^.PR, epNonFatal+Result);
      goto ExitPoint;
    end;

    {Initialize Crc}
    Crc := $FFFFFFFF;

    {Start at beginning, loop thru file calculating Crc32}
    FileLoc := 0;
    repeat
      BlockRead(F , Buffer^, BufSize, BytesRead);
      Result := IOResult;
      if Result = 0 then begin
        if Len <> MaxLongint then begin
          Inc(FileLoc, BytesRead);
          if FileLoc > Len then
            BytesRead := BytesRead - (FileLoc - Len);
        end;
        for I := 1 to BytesRead do
          Crc := UpdateCrc32(Buffer^[I], Crc);
      end;
    until (BytesRead = 0) or (Result <> 0) or (FileLoc >= Len);

    Close(F);
    if IOResult = 0 then ;

ExitPoint:
    Crc32ofFile := Crc;
    FreeMemCheck(Buffer, BufSize);
  end;

  {$F+}
  procedure NoStatus(P : ProtocolRecPtr; Starting, Ending : Boolean);
    {-Empty show status procedure}
  begin
  end;

  function NoNextFile(P : ProtocolRecPtr) : Boolean;
    {-Empty next file function -- always returns False}
  begin
    NoNextFile := False;
  end;

  procedure NoLogFile(P : ProtocolRecPtr; LogFileStatus : LogFileType);
    {-Empty LogFile procedure}
  begin
  end;

  function NoAcceptFile(P : ProtocolRecPtr) : Boolean;
    {-Empty AcceptFile function}
  begin
    NoAcceptFile := True;
  end;

  procedure NoUserBack(P : ProtocolRecPtr);
    {-Empty UserBackProc procedure }
  begin
  end;

  function AcceptOneFile(P : ProtocolRecPtr) : Boolean;
    {-Built-in function that accepts one file only}
  begin
    with P^.PData^ do begin
      AcceptOneFile := not GotOneFile;
      GotOneFile := True;
    end;
  end;

  function NextFileMask(P : ProtocolRecPtr;
                        var FName : PathStr) : Boolean;
    {-Built-in function that works with file mask fields}
  const
    AnyFileButDir = AnyFile and not (Directory or VolumeID);
  begin
    SetAsyncStatus(ecOk);
    with P^.PData^ do begin
      {Check for uninitialized search mask}
      if SearchMask = '' then begin
        GotError(PR, epFatal+ecNoSearchMask);
        SetAsyncStatus(ecNoSearchMask);
        NextFileMask := False;
        Exit;
      end;

      {Search for a matching file}
      if FindingFirst then begin
        FindFirst(SearchMask, AnyFileButDir, CurRec);
        if DosError = 18 then begin
          GotError(PR, epFatal+ecNoMatchingFiles);
          FName := '';
          NextFileMask := False;
          Exit;
        end else
          FindingFirst := False;
      end else
        FindNext(CurRec);

      {Check for errors}
      if DosError <> 0 then begin
        {Failed to find file, return error status}
        case DosError of
          3  : GotError(PR, epFatal+ecDirNotFound);
          {18 : GotError(PR, epFatal+ecNoMatchingFiles);}
        end;
        FName := '';
        NextFileMask := False;
      end else begin
        {Found a file, return fully qualified file name}
        FName := AddBackSlash(JustPathName(SearchMask)) + CurRec.Name;
        NextFileMask := True;
      end;
    end;
  end;

  function NextFileList(P : ProtocolRecPtr; var FName : PathStr) : Boolean;
    {-Built-in function that works with a list of files}
  const
    Separator = ';';
    EndOfListMark = #0;
    MaxLen = SizeOf(PathStr);
  var
    MaxNext : Word;
    I : Word;
    Len : Word;
  begin
    SetAsyncStatus(ecOk);

    with P^.PData^ do begin
      {Return immediately if no more files}
      if FileList^[FileListIndex] = EndOfListMark then begin
        NextFileList := False;
        FName := '';
        Exit;
      end;

      {Increment past the last separator}
      if FileListIndex <> 0 then
        Inc(FileListIndex);

      {Define how far to look for the next marker}
      if LongInt(FileListIndex) + MaxLen > 65535 then
        MaxNext := 65535
      else
        MaxNext := FileListIndex + MaxLen;

      {Look for the next marker}
      for I := FileListIndex to MaxNext do begin
        if (FileList^[I] = Separator) or
           (FileList^[I] = EndOfListMark) then begin
          {Extract the pathname}
          Len := I - FileListIndex;
          Move(FileList^[FileListIndex], FName[1], Len);
          FName[0] := Char(Len);
          NextFileList := True;
          Inc(FileListIndex, Len);
          Exit;
        end;
      end;

      {Bad format list (no separator) -- show error}
      GotError(PR, epFatal+ecBadFileList);
      NextFileList := False;
      FName := '';
    end;
  end;

  procedure apPrepareReading(P : ProtocolRecPtr);
    {-Prepare to send protocol blocks (usually opens a file)}
  var
    Result : Word;
  begin
    with P^, PData^ do begin
      SetAsyncStatus(ecOk);

      {If file is already open then leave without doing anything}
      if FileOpen then
        Exit;

      {Report notfound error for empty filename}
      if PathName = '' then begin
        GotError(PR, epFatal+ecFileNotFound);
        Exit;
      end;

      {!!.01 moved to init}
      {Allocate a file buffer}
      {if not GetMemCheck(FileBuffer, FileBufferSize) then begin
        GotError(PR, epFatal+ecOutOfMemory);
        Exit;
      end;}

      {Open up the previously specified file}
      SaveMode := FileMode;                                            {!!.02}
      FileMode := GetAproFileMode;                              {!!.02}{!!.03}
      Assign(WorkFile, PathName);
      Reset(WorkFile, 1);
      FileMode := SaveMode;                                            {!!.02}
      Result := IOResult;
      if Result <> 0 then begin
        GotError(PR, epFatal+Result);
        {FreeMemCheck(FileBuffer, FileBufferSize);}                    {!!.01}
        Exit;
      end;

      {Show file name and size}
      SrcFileLen := FileSize(WorkFile);
      BytesRemaining := SrcFileLen;
      apUserStatus(P, False, False);

      {Note file date/time stamp (for those protocols that care)}
      GetFTime(WorkFile, SrcFileDate);

      {Initialize the buffering variables}
      StartOfs := 0;
      EndOfs := 0;
      LastOfs := 0;
      EndPending := False;
      FileOpen := True;
    end;
  end;

  procedure apFinishReading(P : ProtocolRecPtr);
    {-Clean up after reading protocol blocks (usually closes a file)}
  begin
    with P^.PData^ do
      if FileOpen then begin
        {Error or end-of-protocol, clean up}
        Close(WorkFile);
        if IOResult <> 0 then ;
        {FreeMemCheck(FileBuffer, FileBufferSize);}                    {!!.01}
        FileOpen := False;
      end;
  end;

  function apReadProtocolBlock(P : ProtocolRecPtr;
                               var Block : DataBlockType;
                               var BlockSize : Word) : Boolean;
    {-Return with a block to transmit (True to quit)}
  var
    BytesRead : Word;
    BytesToMove : Word;
    BytesToRead : Word;
    Result : Word;
  begin
    SetAsyncStatus(ecOk);

    with P^.PData^ do begin
      {Check for a request to start further along in the file (recovering)}
      {if (LastOfs = 0) and (FileOfs > BlockSize) then}
      if FileOfs > EndOfs then
        {First call to read is asking to skip blocks -- force a reread}
        EndOfs := FileOfs;

      {Check for a request to retransmit an old block}
      if FileOfs < LastOfs then
        {Retransmit - reset end-of-buffer to force a reread}
        EndOfs := FileOfs;

      if (FileOfs + BlockSize) > EndOfs then begin
        {Buffer needs to be updated, First shift end section to beginning}
        BytesToMove := EndOfs - FileOfs;
        if BytesToMove > 0 then
          Move(FileBuffer^[FileOfs - StartOfs], FileBuffer^, BytesToMove);

        {Fill end section from file}
        BytesToRead := FileBufferSize - BytesToMove;
        Seek(WorkFile, EndOfs);
        BlockRead(WorkFile, FileBuffer^[BytesToMove], BytesToRead, BytesRead);
        Result := IOResult;
        if (Result <> 0) then begin
          {Exit on error}
          GotError(PR, epFatal+Result);
          apReadProtocolBlock := True;
          BlockSize := 0;
          Exit;
        end else begin
          {Set buffering variables}
          StartOfs := FileOfs;
          EndOfs := FileOfs + FileBufferSize;
        end;

        {Prepare for the end of the file}
        if BytesRead < BytesToRead then begin
          EndOfDataOfs := BytesToMove + BytesRead;
          FillChar(FileBuffer^[EndofDataOfs], FileBufferSize - EndOfDataOfs,
                   BlockFillChar);
          Inc(EndOfDataOfs, StartOfs);
          EndPending := True;
        end else
          EndPending := False;
      end;

      {Return the requested block}
      Move(FileBuffer^[(FileOfs - StartOfs)], Block, BlockSize);
      apReadProtocolBlock := False;
      LastOfs := FileOfs;

      {If it's the last block then say so}
      if EndPending and ((FileOfs + BlockSize) >= EndOfDataOfs) then begin
        apReadProtocolBlock := True;
        BlockSize := EndOfDataOfs - FileOfs;
      end;
    end;
  end;

  procedure apPrepareWriting(P : ProtocolRecPtr);
    {-Prepare to save protocol blocks (usually opens a file)}
  var
    Dir : DirStr;
    Name : NameStr;
    Ext : ExtStr;
    Result : Word;
  label
    ExitPoint;
  begin
    with P^.PData^ do begin

      {!!.01 moved to init}
      {Allocate a file buffer}
      {if not GetMemCheck(FileBuffer, FileBufferSize) then begin
        GotError(PR, epFatal+ecOutOfMemory);
        ShowLastStatus(P);
        Exit;
      end;}

      {Does the file exist already?}
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

      {Exit if file exists and option is WriteFail}
      if (Result = 0) and (WriteFailOpt = WriteFail) then begin
        GotError(PR, epNonFatal+ecFileAlreadyExists);
        goto ExitPoint;
      end;

      Close(WorkFile);
      if IOResult = 0 then ;

      {Change the file name if it already exists the option is WriteRename}
      if (Result = 0) and (WriteFailOpt = WriteRename) then begin
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

      {Initialized the buffer management vars}
      StartOfs := 0;
      LastOfs := 0;
      EndOfs := StartOfs + FileBufferSize;
      FileOpen := True;
      SetAsyncStatus(ecOk);
      Exit;

  ExitPoint:
      Close(WorkFile);
      if IOResult <> 0 then ;
      {FreeMemCheck(FileBuffer, FileBufferSize);}                      {!!.01}
    end;
  end;

  procedure apFinishWriting(P : ProtocolRecPtr);
    {-Cleans up after saving all protocol blocks}
  var
    BytesToWrite : Word;
    BytesWritten : Word;
    Result : Word;
  begin
    with P^.PData^ do
      if FileOpen then begin
        {Error or end-of-protocol, commit buffer and cleanup}
        BytesToWrite := FileOfs - StartOfs;
        BlockWrite(WorkFile, FileBuffer^, BytesToWrite, BytesWritten);
        Result := IOResult;
        if (Result <> 0) then
          GotError(PR, epFatal+Result);
        if (BytesToWrite <> BytesWritten) then
          GotError(PR, epFatal+ecDiskFull);

        Close(WorkFile);
        if IOResult <> 0 then ;
        {FreeMemCheck(FileBuffer, FileBufferSize);}                    {!!.01}
        FileOpen := False;
      end;
  end;

  function apWriteProtocolBlock(P : ProtocolRecPtr;
                                var Block : DataBlockType;
                                BlockSize : Word) : Boolean;
    {-Write a protocol block (return True to quit)}
  var
    Result : Word;
    BytesToWrite : Word;
    BytesWritten : Word;

    procedure BlockWriteRTS;
      {-Set RTS before BlockWrite (assumes all BlockWrite params filled in)}
    var
      OffState : Boolean;
      DTR, RTS    : Boolean;                                           {!!.01}
      CurrentlyOn : Boolean;                                           {!!.01}
    begin
      with P^, PData^ do begin
        if FlagIsSet(apFlags, apRTSLowForWrite) then begin
          IntOff;                                                      {!!.01}
          GetModem(PR, DTR, RTS);                                      {!!.01}
          if FlagIsSet(PR^.HWFRecHonor, hfUseRTS) and
             FlagIsSet(PR^.HWFRecMask, hfRTSActiveLow) then begin
            OffState := True;
            CurrentlyOn := not RTS;                                    {!!.01}
          end else begin                                               {!!.01}
            OffState := False;                                         {!!.01}
            CurrentlyOn := RTS;                                        {!!.01}
          end;                                                         {!!.01}
          if CurrentlyOn then                                          {!!.01}
            SetRTS(PR, OffState);
          IntOn;                                                       {!!.01}
        end else                                                       {!!.02}
          CurrentlyOn := False;                                        {!!.02}

        BlockWrite(WorkFile, FileBuffer^, BytesToWrite, BytesWritten);
        if FlagIsSet(apFlags, apRTSLowForWrite) and CurrentlyOn then   {!!.01}
          SetRTS(PR, not OffState);
        SetAsyncStatus(ecOk);                                          {!!.02}
      end;
    end;

  begin
    SetAsyncStatus(ecOk);
    apWriteProtocolBlock := True;

    with P^.PData^ do begin
      if not FileOpen then begin
        GotError(PR, epFatal+ecNotOpen);
        Exit;
      end;

      if FileOfs < LastOfs then
        {This is a retransmitted block}
        if FileOfs > StartOfs then begin
          {FileBuffer has some good data, commit that data now}
          Seek(WorkFile, StartOfs);
          BytesToWrite := FileOfs - StartOfs;
          BlockWriteRTS;
          Result := IOResult;
          if (Result <> 0) then begin
            GotError(PR, epFatal+Result);
            Exit;
          end;
          if (BytesToWrite <> BytesWritten) then begin
            GotError(PR, epFatal+ecDiskFull);
            Exit;
          end;
        end else begin
          {Block is before data in buffer, discard data in buffer}
          StartOfs := FileOfs;
          EndOfs := StartOfs + FileBufferSize;
          {Position file just past last good data}
          Seek(WorkFile, FileOfs);
          Result := IOResult;
          if Result <> 0 then begin
            GotError(PR, epFatal+Result);
            Exit;
          end;
        end;

      {Will this block fit in the buffer?}
      if (FileOfs + BlockSize) > EndOfs then begin
        {Block won't fit, commit current buffer to disk}
        BytesToWrite := FileOfs - StartOfs;
        BlockWriteRTS;
        Result := IOResult;
        if (Result <> 0) then begin
          GotError(PR, epFatal+Result);
          Exit;
        end;
        if (BytesToWrite <> BytesWritten) then begin
          GotError(PR, epFatal+ecDiskFull);
          Exit;
        end;

        {Reset the buffer management vars}
        StartOfs := FileOfs;
        EndOfs := StartOfs + FileBufferSize;
        LastOfs := FileOfs;
      end;

      {Add this block to the buffer}
      Move(Block, FileBuffer^[FileOfs - StartOfs], BlockSize);
      Inc(LastOfs, BlockSize);
      apWriteProtocolBlock := False;
    end;
  end;
  {$F-}

  procedure apUserStatus(P : ProtocolRecPtr; Starting, Ending : Boolean);
    {-Calls user status routine while preserving AsyncStatus}
  var
    SaveStatus : Word;
  begin
    with P^.PData^ do begin
      SaveStatus := GetAsyncStatus;
      if (GetAsyncStatus = ecNoHeader) or (GetAsyncStatus = ecGotHeader) then
        SetAsyncStatus(ecOk);
      UserStatus(P, Starting, Ending);
      SetAsyncStatus(SaveStatus);
    end;
  end;

  function TrimZeros(S : string) : string;
    {-Return a string with leading and trailing white space removed}
  var
    I : Word;
    SLen : Byte absolute S;
  begin
    while (SLen > 0) and (S[SLen] <= ' ') do
      Dec(SLen);

    I := 1;
    while (I <= SLen) and ((S[I] <= ' ') or (S[I] = '0')) do
      Inc(I);
    Dec(I);
    if I > 0 then
      Delete(S, 1, I);

    TrimZeros := S;
  end;

  function OctalStr(L : LongInt) : String;
    {-Convert L to octal base string}
  const
    Digits : array[0..7] of Char = '01234567';
  var
    I : Word;
  begin
    OctalStr[0] := #12;
    for I := 0 to 11 do begin
      OctalStr[12-I] := Digits[L and 7];
      L := L shr 3;
    end;
  end;

  function OctalStr2Long(S : String) : LongInt;
    {-Convert S from an octal string to a longint}
  const
    HiMag = 10;
    Magnitude : array[1..HiMag] of LongInt =
      (1, 8, 64, 512, 4096, 32768, 262144, 2097152, 16777216, 134217728);
    ValidDigits : set of '0'..'7' = ['0', '1', '2', '3', '4', '5', '6', '7'];
  var
    I, J : Integer;
    Len : Byte absolute S;
    Part, Result : LongInt;
    Code : Word;
  begin
    {Assume failure}
    OctalStr2Long := 0;

    {Remove leading blanks and zeros}
    S := TrimZeros(S);

    {Return 0 for invalid strings}
    if Len > HiMag then
      Exit;

    {Convert it}
    Result := 0;
    J := 1;
    for I := Len downto 1 do begin
      if not (S[I] in ValidDigits) then
        Exit;
      Val(S[I], Part, Code);
      Result := Result + Part * Magnitude[J];
      Inc(J);
    end;
    OctalStr2Long := Result
  end;

  function PackToYMTimeStamp(RawTime : LongInt) : LongInt;
    {-Return date/time stamp as octal seconds since 1/1/1970 00:00 GMT}
  var
    DT : DateTime;
    DTR : DateTimeRec;
    DiffDays : Word;
    DiffSecs : LongInt;
  begin
    {Convert to julian date}
    UnpackTime(RawTime, DT);
    with DT do begin
      DTR.D := DMYtoDate(Day, Month, Year);
      DTR.T := HMStoTime(Hour, Min, Sec);
    end;

    {Subtract GMT hour offset}
    IncDateTime(DTR, DTR, 0, -(3600 * GmtHourOffset));

    {Diff between date/time stamp and 1/1/1970 (in seconds)}
    DateTimeDiff(DTR, StartDate, DiffDays, DiffSecs);
    PackToYMTimeStamp := DiffSecs + (DiffDays * SecondsInDay);
  end;

  function YMTimeStampToPack(YMTime : LongInt) : LongInt;
    {-Return a file time stamp in packed format from a Ymodem time stamp}
  var
    DT : DateTime;
    DTR  : DateTimeRec;
    Ptime : LongInt;
    H,M,S : Byte;
  begin
    {Add the time stamp to StartDate}
    IncDateTime(StartDate, DTR, 0, YMTime);

    {Add the GMT hour offset}
    IncDateTime(DTR, DTR, 0, 3600 * GmtHourOffset);

    {Convert to DT format}
    with DT do begin
      DateToDMY(DTR.D, Integer(Day), Integer(Month), Integer(Year));
      TimeToHMS(DTR.T, H, M, S);
      Hour := H;
      Min := M;
      Sec := S;
    end;

    {Convert to packed format}
    PackTime(DT, Ptime);
    YMTimeStampToPack := Ptime;
  end;

  function CurrentTimeStamp : LongInt;
    {-Return a Ymodem format file time stamp of the current date/time}
  var
    Ptime : LongInt;
    DT : DateTime;
    Sec100, DOW : Word;
  begin
    with DT do begin
      GetTime(Hour, Min, Sec, Sec100);
      GetDate(Year, Month, Day, DOW);
    end;
    PackTime(DT, Ptime);
    CurrentTimeStamp := PackToYMTimeStamp(Ptime);
  end;

begin
  {Set StartDate to 1/1/1970 00:00 GMT}
  with StartDate do begin
    T := 0;
    D := DMYToDate(1, 1, 1970);
  end;
end.
