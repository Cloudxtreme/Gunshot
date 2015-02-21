{******************************************************}
{*                  TPFDATA.PAS  2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}

{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}

{$IFDEF DPMI}
{$V-,B-,R-,S-,F-,O-,A+,I-,X+,T-}
{$ELSE}
{$V-,B-,R-,S-,F+,O+,A+,I-,X+,T-}
{$ENDIF}

unit TpfData;

interface

uses
  Dos,
  OpInline,
  OpString,
  OpConst,
  OpRoot,
  OpDate,
  OpCmd,
  OpDos,
  OpDir,
  ApMisc,
  ApPort,
  DlgStuff,
  IniTools,
  OoAbsFax,
  TpfError;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

const
  ftTEXT = 0;
  ftPCX  = 1;
  ftTIFF = 2;
  ftDCX  = 3;
  ftBMP  = 4; {!!.03}
  ftAPF  = 5; {!!.03 - Modified}

  otSendFileNode   = 2000;
  veSendFileNode   = 0;
  otSendQueueEntry = 2001;
  veSendQueueEntry = 0;
  otSendQueue      = 2002;
  veSendQueue      = 0;

  dlUart   = 0;
  dlInt14  = 1;
  dlDigi   = 2;
  dlFossil = 3;

type
  CvtFileType = ftTEXT..ftAPF;

const
  FileTypeIdents : array[CvtFileType] of String[4] =
    ('TEXT', 'PCX', 'TIFF', 'DCX', 'BMP', 'APF');        {!!.03 - Updated}

  FileTypeExtensions : array[CvtFileType] of String[3] =
    ('TXT', 'PCX', 'TIF', 'DCX', 'BMP', 'APF');          {!!.03 - Updated}

  MaxUnsel = 500;
  MaxSel   = 100;

  ApGroup = 'APROFAX';

type
  TFileNameStr = String[12];

  PSelectedFile = ^TSelectedFile;
  TSelectedFile =
    record
      FPath : StringPtr;
      FType : CvtFileType;
      FName : TFileNameStr;
    end;

  PSelFileArray = ^TSelFileArray;
  TSelFileArray = array[1..MaxSel] of TSelectedFile;

  PUnselFileArray = ^TUnselFileArray;
  TUnselFileArray = array[1..MaxUnsel] of TFileNameStr;

  PSelectFileList = ^TSelectFileList;
  TSelectFileList =
    object(Root)
      sfUnsel     : PUnselFileArray;
      sfNumUnsel  : Word;
      sfSel       : PSelFileArray;
      sfNumSel    : Word;
      sfError     : Word;
      sfCurDir    : DirStr;
      sfCurMask   : TFileNameStr;

      constructor Init;
      destructor  Done; virtual;

      function  GetLastError : Word;
      procedure AssembleUnselected(Mask : PathStr);
      procedure Refresh;

      function  GetNumUnsel : Word;
      function  GetNumSel : Word;
      function  GetUnselFile(Num : Word) : String;
      function  GetQualUnselFile(Num : Word) : String;
      function  GetSelFile(Num : Word) : String;
      procedure GetSelFileInfo(     Num   : Word;
                                var FName : PathStr;
                                var FType : CvtFileType );
      procedure SetFileType(Num : Word; FType : CvtFileType);
      procedure SelectFile(Num : Word; FileType : CvtFileType);
      procedure UnselectFile(Num : Word);
      procedure AddToSelected(Name : PathStr; FileType : CvtFileType);
      procedure RemoveFromSelected(Name : PathStr);

      procedure sfDeallocSel(var SF : TSelectedFile);
      procedure sfSortUnsel(L, R : Word);
      function  sfIsSel(P : PathStr) : Boolean;
    end;

  PTreeIndexRec = ^TTreeIndexRec;     {!!.01}
  TTreeIndexRec =
    record
      Offset     : LongInt;
      NumEntries : LongInt;
    end;

  PTreeIndex = ^TTreeIndex;
  TTreeIndex = array['C'..'Z'] of TTreeIndexRec;

  PTreeManager = ^TTreeManager;
  TTreeManager =
    object(Root)
      tmFName  : String;
      tmIndex  : TTreeIndex;
      tmErrorP : ErrorProc;
      tmFile   : File;
      tmError  : Word;

      constructor Init(FName : PathStr);
      destructor Done; virtual;

      procedure GotError(Code : Word); virtual;
      function  GetLastError  : Word;
      function  PeekLastError : Word;
      procedure SetErrorProc(EP : ErrorProc);

      procedure ReadTree(PL : PathListPtr);
      procedure Refresh(PL : PathListPtr);
      procedure Compress;

      {+++internal+++}
      procedure tmWriteTree(PL : PathListPtr);
      procedure tmWriteBlankIndex;
      procedure tmReadIndex;
    end;

  TEntryString = String[20];

  PPhonebookEntry = ^TPhonebookEntry;
  TPhonebookEntry =
    object(DoubleListNode)
      Name   : TEntryString;
      Number : TEntryString;
    end;

  PPhonebook = ^TPhonebook;
  TPhonebook =
    object(DoubleList)
      pbModified  : Boolean;
      pbError     : Word;
      pbErrorProc : ErrorProc;

      constructor Init;
      procedure Flush;
      procedure Modified;
      procedure AddEntry(Name, Num : TEntryString);

      function PeekLastError : Word;
      function GetLastError : Word;
      procedure ClearErrors;
      procedure GotError(Code : Word); virtual;
      procedure SetErrorProc(EP : ErrorProc);
    end;

  PSendFileNode = ^TSendFileNode;
  TSendFileNode =
    object(SingleListNode)
      FName : StringPtr;
      FSize : Word;
      FType : CvtFileType;

      destructor Done; virtual;
      constructor Load(var S : IdStream);
      procedure Store(var S : IdStream);
    end;

  PSendQueueEntry = ^TSendQueueEntry;
  TSendQueueEntry =
    object(SingleListNode)
      SendTo    : TEntryString;
      SendNum   : TEntryString;
      Immediate : Boolean;
      SendDate  : Date;
      SendTime  : Time;
      FileList  : SingleList;

      constructor Init;
      destructor Done; virtual;

      constructor Copy(QE : PSendQueueEntry);

      constructor Load(var S : IdStream);
      procedure Store(var S : IdStream);
    end;

  PSendQueue = ^TSendQueue;
  TSendQueue =
    object(Root)
      sqImmed     : SingleList;
      sqDated     : SingleList;

      constructor Init;
      destructor Done; virtual;

      constructor Copy(SQ : PSendQueue);

      constructor Load(var S : IdStream);
      procedure Store(var S : IdStream);

      function  TotalEntries : Word;
      function  TotalFiles : Word;

      procedure GetFirstEntry(var QE : PSendQueueEntry);
      procedure GetNextEntry (var QE : PSendQueueEntry);
      procedure GetNthEntry  (var QE : PSendQueueEntry; N : Word);

      procedure GetFirstFile(var QE : PSendQueueEntry; var SF : PSendFileNode);
      procedure GetNextFile (var QE : PSendQueueEntry; var SF : PSendFileNode);
      procedure GetNthFile  ( var QE : PSendQueueEntry;
                              var SF : PSendFileNode;
                                  N  : Word );

      procedure Clear;
      procedure AddToQueue(QE : PsendQueueEntry; var Posn : Word);
      procedure KillKillKill(QE : PSendQueueEntry);
    end;

  PRejectFile = ^TRejectFile;
  TRejectFile =
    object(SingleListNode)
      FName : TFileNameStr;
      FDest : TEntryString;
      FErr  : Word;
    end;

  DevSupType  = dlUart..dlFossil;
  PrnSupType  = (psPCL5, psPCL4, psEpsonFX, psEpson24);

  TConfigData =
    record
      TreeFile        : PathStr;
      PhoneFile       : PathStr;
      WhatPrn         : PrnSupType;
      PrnName         : PathStr;
      Use300DPI       : Boolean;
      UseScaling      : Boolean;
      PrintFaxHeader  : Boolean;
      QueueFile       : PathStr;

      { fax specific options }
      FaxClass        : ClassType;       { class of FAX device }
      PageLen         : Word;            { # lines per page w/ text files }
      Resolution      : Boolean;         { T = HighRes, F = LowRes }
      StationID       : String[20];      { Sending station ID }
      Header          : String;          { Header to print in teensy letters }
      CoverPage       : PathStr;         { File name of default cover page }
      LogoFile        : PathStr;         { CAS logo file }
      SenderName      : String;
      ComPort         : ComNameType;     { Comport faxmodem is attached }
      DevType         : DevSupType;
      PortRate        : LongInt;         { Baud rate of com port }
      XmitBPS         : LongInt;         { Fax BPS rate }
      ErrorCorrection : Boolean;
      RetryTime       : Word;
      DialTime        : Word;
      MaxRetries      : Word;
      ModemInit       : String;
      DialPrefix      : String;
      ToneDial        : Boolean;
      UseHWFlow       : Boolean;
    end;

var
  TreeManager     : TTreeManager;
  ConfigData      : TConfigData;
  SendQueue       : TSendQueue;
  SendImmediately : Boolean;

  { history lists }
  CvtFNameHistory  : HistoryList;
  PrnFNameHistory  : HistoryList;
  ViewFNameHistory : HistoryList;
  SendFNameHistory : HistoryList;

const
  ConfigFile  : PathStr = 'TPFAX.INI';

function WriteQueue : Word;
function ReadQueue : Word;
procedure LoadConfiguration;

function IsAnAPFFile(FN : PathStr) : Boolean;
function GetFileSize(FN : PathStr) : Word;

implementation

const
  SepCh     = '|';
  CommentCh = ';';

  constructor TSelectFileList.Init;
  begin
    if not Root.Init then
      Fail;

    if not GetMemCheck(sfUnSel, SizeOf(TUnselFileArray)) or
       not GetMemCheck(sfSel, SizeOf(TSelFileArray)) then begin
      InitStatus := epFatal+ecOutOfMemory;
      Fail;
    end;

    FillChar(sfUnSel^, SizeOf(TUnselFileArray), 0);
    FillChar(sfSel^, SizeOf(TSelFileArray), 0);
    sfNumUnsel := 0;
    sfNumSel := 0;
    sfError := 0;
    sfCurDir := '';
    sfCurMask := '';
  end;

  destructor TSelectFileList.Done;
  var
    I : Word;

  begin
    for I := 1 to sfNumSel do
      sfDeallocSel(sfSel^[I]);
    FreeMemCheck(sfSel, SizeOf(TSelFileArray));
    FreeMemCheck(sfUnsel, SizeOf(TUnselFileArray));
    Root.Done;
  end;

  function TSelectFileList.GetLastError : Word;
  begin
    GetLastError := sfError;
    sfError := 0;
  end;

  procedure TSelectFileList.AssembleUnselected(Mask : PathStr);
  var
    DE : Word;
    SR : SearchRec;
    T  : String;

  begin
    sfNumUnsel := 0;
    FillChar(sfUnsel^, SizeOf(TUnselFileArray), 0);

    T := JustPathName(Mask);
    if (T <> '') then
      sfCurDir := T
    else
      Mask := AddBackslash(sfCurDir) + Mask;

    sfCurMask := JustFileName(Mask);

    { read the files in the directory }
    FindFirst(Mask, Archive, SR);
    DE := DosError;
    while (DE = 0) do begin
      if not sfIsSel(AddBackslash(sfCurDir) + SR.Name) then begin
        Inc(sfNumUnsel);
        if (sfNumUnsel > MaxUnsel) then begin
          sfError := epNonFatal+ecDirTooBig;
          Exit;
        end;

        sfUnsel^[sfNumUnsel] := SR.Name;
      end;

      FindNext(SR);
      DE := DosError;
    end;

    if (sfNumUnsel > 1) then
      sfSortUnsel(1, sfNumUnsel);
  end;

  procedure TSelectFileList.Refresh;
  begin
    AssembleUnselected(AddBackslash(sfCurDir) + sfCurMask);
  end;

  function TSelectFileList.GetNumUnsel : Word;
  begin
    GetNumUnsel := sfNumUnsel;
  end;

  function TSelectFileList.GetNumSel : Word;
  begin
    GetNumSel := sfNumSel;
  end;

  function TSelectFileList.GetUnselFile(Num : Word) : String;
  begin
    if (Num > sfNumUnsel) then
      GetUnselFile := ''
    else
      GetUnselFile := sfUnsel^[Num];
  end;

  function TSelectFileList.GetQualUnselFile(Num : Word) : String;
  begin
    if (Num > sfNumUnsel) then
      GetQualUnselFile := ''
    else
      GetQualUnselFile := AddBackslash(sfCurDir) + sfUnsel^[Num];
  end;

  function TSelectFileList.GetSelFile(Num : Word) : String;
  begin
    if (Num > sfNumSel) or (Num < 0) then
      GetSelFile := ''
    else
      GetSelFile := Pad(sfSel^[Num].FName, 14) +
        FileTypeIdents[sfSel^[Num].FType];
  end; { of function TSelectFileList.GetSelFile }

  procedure TSelectFileList.GetSelFileInfo(     Num   : Word;
                                            var FName : PathStr;
                                            var FType : CvtFileType );
  begin
    FName := AddBackslash(StringFromHeap(sfSel^[Num].FPath)) + sfSel^[Num].FName;
    FType := sfSel^[Num].FType;
  end;

  procedure TSelectFileList.SetFileType(Num : Word; FType : CvtFileType);
  begin
    sfSel^[Num].FType := FType;
  end;

  procedure TSelectFileList.SelectFile(Num : Word; FileType : CvtFileType);
  begin
    if (sfNumSel = MaxSel) then
      sfError := epNonFatal+ecTooManyFields
    else begin
      Inc(sfNumSel);
      with sfSel^[sfNumSel] do begin
        FPath := StringToHeap(sfCurDir);
        if (FPath = nil) then begin
          sfError := epFatal+ecOutOfMemory;
          Exit;
        end;
        FType := FileType;
        FName := sfUnSel^[Num];
      end;

      if (Num <> sfNumUnsel) then
        MoveFast(sfUnsel^[Succ(Num)], sfUnSel^[Num],
          SizeOf(TFileNameStr) * (sfNumUnsel - Num));
      Dec(sfNumUnsel);
    end;
  end;

  procedure TSelectFileList.UnselectFile(Num : Word);
  begin
    { if the file belongs in the unselected list, and if it will fit,
      place it there }
    if (sfCurDir = StringFromHeap(sfSel^[Num].FPath)) and (sfNumUnsel < MaxUnsel) then begin
      Inc(sfNumUnsel);
      sfUnsel^[sfNumUnsel] := sfSel^[Num].FName;
      sfSortUnsel(1, sfNumUnsel);
    end;

    sfDeallocSel(sfSel^[Num]);
    if (Num <> sfNumSel) then
      MoveFast(sfSel^[Succ(Num)], sfSel^[Num],
        SizeOf(TSelectedFile) * (sfNumSel - Num));
    Dec(sfNumSel);
  end;

  { MUST PASS A FULLY QUALIFIED PATH TO THIS ROUTINE }
  procedure TSelectFileList.AddToSelected(Name : PathStr; FileType : CvtFileType);
  var
    T : DirStr;
    F : TFileNameStr;
    I : Word;

  begin
    if (sfNumSel = MaxSel) then
      sfError := epNonFatal+ecTooManyFields
    else begin

      { first add Name to the selected list }

      Inc(sfNumSel);
      with sfSel^[sfNumSel] do begin
        T := JustPathName(Name);
        F := JustFileName(Name);

        FPath := StringToHeap(T);
        if (FPath = nil) then begin
          sfError := epFatal+ecOutOfMemory;
          Exit;
        end;

        FType := FileType;
        FName := F;
      end;

      { now, if FName is in the unselected list, then remove it }
      if (sfCurDir = T) and (sfNumUnsel > 0) then begin
        I := 1;
        while (I <= sfNumUnsel) and (sfUnsel^[I] <> F) do
          Inc(I);
        if (I <= sfNumSel) then begin
          MoveFast(sfUnsel^[Succ(I)], sfUnsel^[I],
            SizeOf(TFileNameStr) * (sfNumUnsel - I));
          Dec(sfNumUnsel);
        end;
      end;
    end;
  end;

  { MUST PASS A FULLY QUALIFIED PATH TO THIS ROUTINE }
  procedure TSelectFileList.RemoveFromSelected(Name : PathStr);
  var
    H : Word;
    I : Word;

    function NameMatches : Boolean;
    begin
      with sfSel^[I] do
        NameMatches := (Name = AddBackslash(StringFromHeap(FPath)) + FName);
    end;

  begin

    { search for Name in the selected list }
    I := 1;
    while (I <= sfNumSel) and not NameMatches do
      Inc(I);

    { if a match was found, remove it }
    if (I <= sfNumSel) then begin
      sfDeallocSel(sfSel^[I]);
      MoveFast(sfSel^[Succ(I)], sfSel^[I], SizeOf(PSelectedFile) * (sfNumSel - I));
      Dec(sfNumSel);

      { if necessary, add this puppy to the unselected list }
      if (sfCurDir = JustPathName(Name)) then begin
        Inc(sfNumUnsel);
        sfUnsel^[sfNumUnsel] := JustfileName(Name);
        sfSortUnsel(1, sfNumUnsel);
      end;
    end;
  end;

var
  Pivot : TFileNameStr;

  procedure TSelectFileList.sfDeallocSel(var SF : TSelectedFile);
  begin
    DisposeString(SF.FPath);
  end;

  {$S+}
  procedure TSelectFileList.sfSortUnsel(L, R : Word);
  var
    I : Word;
    J : Word;

  begin
    I := L;
    J := R;

    { save pivot }
    Pivot := sfUnsel^[(L + R) shr 1];
    repeat
      while (sfUnsel^[I] < Pivot) do
        Inc(I);
      while (Pivot < sfUnsel^[J]) do
        Dec(J);
      if (I <= J) then begin
        ExchangeStructs(sfUnsel^[I], sfUnsel^[J], SizeOf(TFileNameStr));
        Inc(I);
        Dec(J);
      end;
    until (I > J);
    if (L < J) then
      sfSortUnsel(L, J);
    if (I < R) then
      sfSortUnsel(I, R);
  end;
  {$S-}

  function TSelectFileList.sfIsSel(P : PathStr) : Boolean;
  var
    I : Word;

  begin
    sfIsSel := True;
    I := 1;
    while (I <= sfNumSel) do begin
      with sfSel^[I] do
        if (P = AddBackslash(StringFromHeap(FPath)) + FName) then
          Exit;
      Inc(I);
    end;

    sfIsSel := False;
  end;


  constructor TTreeManager.Init(FName : PathStr);
  begin
    if not Root.Init then
      Fail;

    tmFName := FName;

    { no error handler, by default }
    @tmErrorP := nil;
    tmError   := 0;

    { see if the tree data file already exists }
    Assign(tmFile, tmFName);

    if not ExistFile(tmFName) then begin
      Rewrite(tmFile, 1);
      InitStatus := IoResult;
      if (InitStatus <> 0) then
        Fail;

      tmWriteBlankIndex;
      InitStatus := tmError;
      if (InitStatus <> 0) then begin
        Close(tmFile); if (IoResult = 0) then ;
        Erase(tmfile); if (IoResult = 0) then ;
        Fail;
      end;
    end else begin
      System.Reset(tmFile, 1);   {!!.02}
      InitStatus := IoResult;
      if (InitStatus <> 0) then
        Fail;

      tmReadIndex;
      InitStatus := tmError;
      if (InitStatus <> 0) then begin
        Close(tmFile);
        Fail;
      end;
    end;
  end;

  destructor TTreeManager.Done;
  begin
    Compress;
    Close(tmFile);
    Root.Done;
  end;

  procedure TTreeManager.GotError(Code : Word);
  begin
    tmError := Code;
    if (@tmErrorP <> nil) then
      tmErrorP(0, tmError, emNullError)
    else
      RingBell;
  end;

  function TTreeManager.GetLastError : Word;
  begin
    GetLastError := tmError;
    tmError := 0;
  end;

  function TTreeManager.PeekLastError : Word;
  begin
    PeekLastError := tmError;
  end;

  procedure TTreeManager.SetErrorProc(EP : ErrorProc);
  begin
    tmErrorP := EP;
  end;

  procedure TTreeManager.ReadTree(PL : PathListPtr);
  var
    Err : Word;

  begin
    with PL^ do
      { is this tree on a floppy? }                     {!!.01}
      if (paDrive in ['A'..'B']) then                   {!!.01}
        PreLoadPathList                                 {!!.01}

      { do we already have a copy of this tree? }       {!!.01}
      else if (tmIndex[paDrive].Offset = -1) then begin {!!.01}
        { have the PathList object read the tree, then make a copy of it }
        PreLoadPathList;
        if (GetLastError = 0) then
          tmWriteTree(PL);
      end else begin

        { read the tree from disk }
        Seek(tmFile, tmIndex[paDrive].Offset);
        BlockRead(tmFile, PL^.paDPtr^, SizeOf(PathRec) * tmIndex[paDrive].NumEntries);
        Err := IoResult;
        if (Err <> 0) then begin
          Self.GotError(Err);
          Exit;
        end;

        paCurFiles := tmIndex[paDrive].NumEntries;
        pkItems := paCurFiles;

        if paOptionsAreOn(paSetCurDir) then
          paSetChoiceCurDir;
        ClearFlag(paFlags, paReadDir);
       end;
  end;

  procedure TTreeManager.Refresh(PL : PathListPtr);
  begin
    with PL^ do
      if (paDrive in ['C'..'Z']) then begin
        SetFlag(paFlags, paReadDir);
        PreloadPathList;
        if (GetLastError <> 0) then
          Exit;

        tmWriteTree(PL);
      end;
  end;

  procedure TTreeManager.Compress;
  var
    Temp      : File;
    Err       : Word;
    BytesLeft : Word;
    BytesRead : Word;
    Buf       : array[1..1024] of Byte;
    I         : Char;

  begin
    Assign (Temp, 'TPFAX.TMP');
    Rewrite(Temp, 1);
    Err := IoResult;
    if (Err <> 0) then
      GotError(Err);

    { write the index to the temporary file }
    BlockWrite(Temp, tmIndex, SizeOf(tmIndex));
    Err := IoResult;
    if (Err <> 0) then
      GotError(Err);

    { walk the index, rewriting trees that exist }
    for I := 'C' to 'Z' do
      if (tmIndex[I].Offset <> -1) then begin
        Seek(tmFile, tmIndex[I].Offset);

        { assign the index a new offset }
        tmIndex[I].Offset := FilePos(Temp);

        BytesLeft := SizeOf(PathRec) * tmIndex[I].NumEntries;
        while (BytesLeft <> 0) do begin
          BlockRead(tmFile, Buf, MinWord(1024, BytesLeft), BytesRead);

          BytesLeft := BytesLeft - BytesRead;
          BlockWrite(Temp, Buf, BytesRead);

          Err := IoResult;
          if (Err <> 0) then begin
            GotError(Err);
            Exit;
          end;
        end;
      end;

    { finally, rewrite the newly constructed index back to 'Temp' }
    Seek(Temp, 0);
    BlockWrite(Temp, tmIndex, SizeOf(tmIndex));
    Err := IoResult;
    if (Err <> 0) then begin
      GotError(Err);
      Exit;
    end;

    { erase and rename the 'Temp' file }
    Close(Temp);
    Close(tmFile);

    Erase(tmFile);
    Rename(Temp, tmFName);

    Assign(tmFile, tmFName);   { <-- probably not necessary, but can't hurt }
    System.Reset(tmFile, 1);   {!!.02}
    Err := IoResult;
    if (Err <> 0) then
      GotError(Err);
  end;

  procedure TTreeManager.tmWriteTree(PL : PathListPtr);
  var
    Err : Word;
    Sz  : Word;

  begin
    with PL^ do begin

      { calculate the size of the data to write }
      Sz := SizeOf(PathRec) * paCurFiles;

      { is there space for this tree in its old spot? }
      if (tmIndex[paDrive].Offset = -1) or (tmIndex[paDrive].NumEntries > paCurFiles) then begin

        { append the tree to the end of the file }
        Seek(tmFile, FileSize(tmFile));
        Err := IoResult;
        if (Err <> 0) then begin
          Self.GotError(Err);
          Exit;
        end;
        tmIndex[paDrive].Offset := FilePos(tmFile);
      end;

      tmIndex[paDrive].NumEntries := paCurFiles;

      { go to the place for the data in the file }
      Seek(tmFile, tmIndex[paDrive].Offset);

      { output the tree data }
      BlockWrite(tmFile, paDPtr^, Sz);
      Err := IoResult;

      { was there an error? }
      if (Err <> 0) then
        Self.GotError(Err);
    end;
  end;

  procedure TTreeManager.tmWriteBlankIndex;
  var
    Err : Word;
    I   : Char;

  begin
    FillChar(tmIndex, SizeOf(tmIndex), 0);

    { initialize all index values to point to nothing }
    for I := 'C' to 'Z' do
      tmIndex[I].Offset := -1;

    Seek(tmFile, 0);
    BlockWrite(tmFile, tmIndex, SizeOf(tmIndex));
    Err := IoResult;
    if (Err <> 0) then
      GotError(Err);
  end;

  procedure TTreeManager.tmReadIndex;
  var
    Err : Word;

  begin
    Seek(tmFile, 0);
    BlockRead(tmFile, tmIndex, SizeOf(tmIndex));
    Err := IoResult;
    if (Err <> 0) then
      GotError(Err);
  end;

  constructor TPhonebook.Init;
  label
    Error;

  var
    S : String;
    F : Text;
    P : PPhonebookEntry;
    I : Integer;

  begin
    if not DoubleList.Init then
      Fail;
    pbModified := False;

    Assign(F, ConfigData.PhoneFile);
    System.Reset(F); {!!.02}
    InitStatus := IoResult;
    if (InitStatus = ecFileNotFound) then begin
      Rewrite(F);
      Close(F);
      System.Reset(F);      {!!.02}
      InitStatus := IoResult;
      if (InitStatus <> 0) then
        goto Error;
    end else if (InitStatus <> 0) then
      goto Error;

    while not Eof(F) do begin
      ReadLn(F, S);
      InitStatus := IoResult;
      if (InitStatus <> 0) then
        goto Error;

      S := Trim(S);
      if (S <> '') and (S[1] <> CommentCh) then begin
        New(P, Init);
        if (P = nil) then begin
          InitStatus := epFatal+ecOutOfMemory;
          goto Error;
        end;

        I := Pos(SepCh, S);
        if (I = 0) then begin
          P^.Name   := S;
          P^.Number := '';
        end else begin
          P^.Name   := Copy(S, 1, Pred(I));
          P^.Number := Copy(S, Succ(I), 255);
        end;
        Append(P);
      end;
    end;

    pbError := 0;

    Close(F); if (IoResult = 0) then ;
    Exit;
Error:
    Clear;
    Close(F); if (IoResult = 0) then ;
    Fail;
  end;

  procedure TPhonebook.Modified;
  begin
    pbModified := True;
  end;

  procedure TPhonebook.Flush;
  var
    F : Text;
    P : PPhonebookEntry;
    E : Word;

  begin
    Assign(F, ConfigData.PhoneFile);
    if (Size = 0) then begin
      Erase(F);
      if (IoResult = 0) then ;
      Exit;
    end;

    Rewrite(F);
    E := IoResult;
    if (E <> 0) then begin
      GotError(E);
      Exit;
    end;

    P := PPhonebookEntry(Head);
    while (P <> nil) do begin
      WriteLn(F, P^.Name, SepCh, P^.Number);
      E := IoResult;
      if (E <> 0) then begin
        Close(F); if (IoResult = 0) then ;
        GotError(E);
        Exit;
      end;

      P := PPhonebookEntry(Next(P));
    end;

    Close(F); if (IoResult = 0) then ;
    pbModified := False;
  end;

  procedure TPhonebook.AddEntry(Name, Num : TEntryString);
  var
    P : PPhonebookEntry;

  begin
    New(P, Init);
    if (P = nil) then begin
      GotError(epNonFatal+ecOutOfMemory);
      Exit;
    end;

    P^.Name   := Trim(Name);
    P^.Number := Trim(Num);
    Append(P);
    Modified;
  end;

  function TPhonebook.PeekLastError : Word;
  begin
    PeekLastError := pbError;
  end;

  function TPhonebook.GetLastError : Word;
  begin
    GetLastError := pbError;
    pbError := 0;
  end;

  procedure TPhonebook.ClearErrors;
  begin
    pbError := 0;
  end;

  procedure TPhonebook.GotError(Code : Word);
  begin
    pbError := Code;
    if (@pbErrorProc = nil) then
      RingBell
    else
      pbErrorProc(0, Code, emNullError);
  end;

  procedure TPhonebook.SetErrorProc(EP : ErrorProc);
  begin
    pbErrorProc := EP;
  end;

  destructor TSendFileNode.Done;
  begin
    DisposeString(FName);
    SingleListNode.Done;
  end;

  constructor TSendFileNode.Load(var S : IdStream);
  begin
    if not SingleListNode.Init then
      Fail;
    FName := StringToHeap(S.ReadString);
    S.Read(FSize, SizeOf(Word));
    S.Read(FType, SizeOf(CvtFileType));
  end;

  procedure TSendFileNode.Store(var S : IdStream);
  begin
    S.WriteString(StringFromHeap(FName));
    S.Write(FSize, SizeOf(Word));
    S.Write(FType, SizeOf(CvtFileType));
  end;

  constructor TSendQueueEntry.Init;
  begin
    FileList.Init;
    SingleListNode.Init;
  end;

  destructor TSendQueueEntry.Done;
  begin
    FileList.Done;
    SingleListNode.Done;
  end;

  constructor TSendQueueEntry.Copy(QE : PSendQueueEntry);
  var
    NSF : PSendFileNode;
    SF  : PSendFileNode;

  begin
    if not Init then
      Fail;

    SendTo    := QE^.SendTo;
    SendNum   := QE^.SendNum;
    Immediate := QE^.Immediate;
    SendDate  := QE^.SendDate;
    SendTime  := QE^.SendTime;

    SF := PSendFileNode(QE^.FileList.Head);
    while (SF <> nil) do begin
      New(NSF, Init);
      if (NSF = nil) then begin
        InitStatus := epFatal+ecOutOfMemory;
        Done;
        Fail;
      end;

      NSF^.FName := StringToHeap(SF^.FName^);
      if (NSF^.FName = nil) then begin
        InitStatus := epFatal+ecOutOfMemory;
        Done;
        Fail;
      end;

      NSF^.FSize := SF^.FSize;
      NSF^.FType := SF^.FType;

      FileList.Append(NSF);

      SF := PSendFileNode(SF^.slNext);
    end;
  end;

  constructor TSendQueueEntry.Load(var S : IdStream);
  begin
    SendTo := S.ReadString;
    SendNum := S.ReadString;
    S.ReadRange(Immediate, FileList);
    S.Get(FileList);
  end;

  procedure TSendQueueEntry.Store(var S : IdStream);
  begin
    S.WriteString(SendTo);
    S.WriteString(SendNum);
    S.WriteRange(Immediate, FileList);
    S.Put(FileList);
  end;

  constructor TSendQueue.Init;
  begin
    if not Root.Init or not sqImmed.Init or not sqDated.Init then
      Fail;
  end;

  destructor TSendQueue.Done;
  begin
    sqDated.Done;
    sqImmed.Done;
    Root.Done;
  end;

  constructor TSendQueue.Copy(SQ : PSendQueue);
  var
    NQE : PSendQueueEntry;
    QE  : PSendQueueEntry;

  begin
    if not Init then
      Fail;

    SQ^.GetFirstEntry(QE);
    while (QE <> nil) do begin
      New(NQE, Copy(QE));
      if (NQE = nil) then begin
        InitStatus := epFatal+ecOutOfMemory;
        Done;
        Fail;
      end;

      if QE^.Immediate then
        sqImmed.Append(NQE)
      else
        sqDated.Append(NQE);

      SQ^.GetNextEntry(QE);
    end;
  end;

  constructor TSendQueue.Load(var S : IdStream);
  begin
    if not Root.Init then
      Fail;

    S.Get(sqImmed);
    S.Get(sqDated);
  end;

  procedure TSendQueue.Store(var S : IdStream);
  begin
    S.Put(sqImmed);
    S.Put(sqDated);
  end;

  function TSendQueue.TotalEntries : Word;
  begin
    TotalEntries := (sqImmed.Size + sqDated.Size);
  end;

  function TSendQueue.TotalFiles : Word;
  var
    QE : PSendQueueEntry;
    I  : Word;

  begin
    I := 0;
    GetFirstEntry(QE);
    while (QE <> nil) do begin
      Inc(I);
      GetNextEntry(QE);
    end;
    TotalFiles := I;
  end;

  procedure TSendQueue.GetFirstEntry(var QE : PSendQueueEntry);
  begin
    QE := PSendQueueEntry(sqImmed.Head);
    if (QE = nil) then
      QE := PSendQueueEntry(sqDated.Head);
  end;

  procedure TSendQueue.GetNextEntry(var QE : PSendQueueEntry);
  var
    Imm : Boolean;

  begin
    if (QE = nil) then
      Exit;

    Imm := QE^.Immediate;

    QE := PSendQueueEntry(QE^.slNext);
    if (QE = nil) and Imm then
      QE := PSendQueueEntry(sqDated.Head);
  end;

  procedure TSendQueue.GetNthEntry(var QE : PsendQueueEntry; N : Word);
  var
    I : Word;

  begin
    I := 1;
    GetFirstEntry(QE);

    while (QE <> nil) and (I < N) do begin
      Inc(I);
      GetNextEntry(QE);
    end;
  end;

  {*******************************************************************}
  {                                                                   }
  { This routine attempts to get the first file from the first entry  }
  { in the list of immediates.  If no files exist in that list, it    }
  { attempts to get the first file from the first entry of the list   }
  { of dated entries                                                  }
  {                                                                   }
  {*******************************************************************}

  procedure TSendQueue.GetFirstFile(var QE : PSendQueueEntry; var SF : PSendFileNode);
  begin
    SF := nil;

    QE := PSendQueueEntry(sqImmed.Head);
    if (QE <> nil) then
      SF := PSendFileNode(QE^.FileList.Head)
    else begin
      QE := PSendQueueEntry(sqDated.Head);
      if (QE <> nil) then
        SF := PSendFileNode(QE^.FileList.Head);
    end;
  end;


  {*******************************************************************}
  {                                                                   }
  { This routine attempts to get the next file in sequence based on   }
  { the data passed in QE and SF.  First, the routine checks to see   }
  { if SF has a sucessor.  If not, the routine attempts to get the    }
  { first file for QE's successor.  If QE has no successor, the       }
  { starts searching the dated file list (if QE isn't already a dated }
  { entry) and repeats this process.                                  }
  {                                                                   }
  {*******************************************************************}

  procedure TSendQueue.GetNextFile(var QE : PSendQueueEntry; var SF : PSendFileNode);
  var
    Imm : Boolean;

  begin
    if (QE = nil) then begin
      QE := nil;
      SF := nil;
      Exit;
    end;

    if (SF <> nil) then
      SF := PSendFileNode(SF^.slNext);
    if (SF = nil) then begin
      Imm := QE^.Immediate;

      QE := PSendQueueEntry(QE^.slNext);
      if (QE <> nil) then
        SF := PSendFileNode(QE^.FileList.Head)
      else if Imm then begin
        QE := PSendQueueEntry(sqDated.Head);
        if (QE <> nil) then
          SF := PSendFileNode(QE^.FileList.Head);
      end else begin
        QE := nil;
        SF := nil;
      end;
    end;
  end;

  procedure TSendQueue.GetNthFile(var QE : PSendQueueEntry;
                                  var SF : PSendFileNode;
                                      N  : Word );
  var
    I : Word;

  begin
    GetFirstFile(QE, SF);
    I := 1;

    while (QE <> nil) and (SF <> nil) and (I < N) do begin
      Inc(I);
      GetNextFile(QE, SF);
    end;
  end;

  procedure TSendQueue.Clear;
  begin
    sqImmed.Clear;
    sqDated.Clear;
  end;

  procedure TSendQueue.AddToQueue(QE : PSendQueueEntry; var Posn : Word);
  var
    AnEntry : PSendQueueEntry;

    function TDLessEqual : Boolean;
    begin
      TDLessEqual := ( AnEntry^.SendDate <  QE^.SendDate) or
                     ((AnEntry^.SendDate =  QE^.SendDate) and
                      (AnEntry^.SendTime <= QE^.SendTime));
    end;

  begin
    if (QE = nil) then
      Exit;

    if QE^.Immediate then begin
      sqImmed.Append(QE);
      Posn := sqImmed.Size;
    end else begin

      { find an entry in the dated list with a date/time greater than QE }

      Posn := sqImmed.Size;

      AnEntry := PSendQueueEntry(sqDated.Head);
      while (AnEntry <> nil) and TDLessEqual do begin
        Inc(Posn);
        AnEntry := PSendQueueEntry(AnEntry^.slNext);
      end;

      Inc(Posn);
      if (AnEntry = nil) then
        sqDated.Append(QE)
      else
        sqDated.PlaceBefore(QE, AnEntry);
    end;
  end;

  procedure TSendQueue.KillKillKill(QE : PSendQueueEntry);
  begin
    if (QE = nil) then
      Exit;

    if QE^.Immediate then
      sqImmed.Delete(QE)
    else
      sqDated.Delete(QE);
  end;

  function WriteQueue : Word;
  var
    OutFile : BufIdStream;

  begin
    if not OutFile.Init(ConfigData.QueueFile, SCreate, 1024) then begin
      WriteQueue := InitStatus;
      Exit;
    end;

    with OutFile do begin
      RegisterHier(SingleListStream);
      RegisterType( otSendFileNode, veSendFileNode,
                    TypeOf(TSendFileNode),
                    @TSendFileNode.Store, @TSendFileNode.Load);
      RegisterType( otSendQueueEntry, veSendQueueEntry,
                    TypeOf(TSendQueueEntry),
                    @TSendQueueEntry.Store, @TSendQueueEntry.Load);
      RegisterType( otSendQueue, veSendQueue,
                    TypeOf(TSendQueue),
                    @TSendQueue.Store, @TSendQueue.Load );
      Put(SendQueue);
      WriteQueue := GetStatus;
      Done;
    end;
  end;

  function ReadQueue : Word;
  var
    InFile : BufIdStream;

  begin
    SendQueue.Done;

    if not InFile.Init(ConfigData.QueueFile, SOpen, 1024) then begin
      SendQueue.Init;
      ReadQueue := InitStatus;
      Exit;
    end;

    with InFile do begin
      RegisterHier(SingleListStream);
      RegisterType( otSendFileNode, veSendFileNode,
                    TypeOf(TSendFileNode),
                    @TSendFileNode.Store, @TSendFileNode.Load);
      RegisterType( otSendQueueEntry, veSendQueueEntry,
                    TypeOf(TSendQueueEntry),
                    @TSendQueueEntry.Store, @TSendQueueEntry.Load);
      RegisterType( otSendQueue, veSendQueue,
                    TypeOf(TSendQueue),
                    @TSendQueue.Store, @TSendQueue.Load );
      Get(SendQueue);
      ReadQueue := GetStatus;
      Done;
    end;
  end;

  procedure LoadConfiguration;
  var
    Config : TIni;
    Temp   : String;

  begin
    if not Config.Init(ConfigFile, True) then
      Exit;

    with Config, ConfigData do begin
      if (ConfigData.PhoneFile = '') then
        PhoneFile := GetProfileString('PhoneFile', ApGroup, 'TPFAX.PB');

      TreeFile := StUpCase(GetProfileString('TreeFile', ApGroup, 'TPFAX.DT'));

      { get the printer port info }
      Temp := StUpCase(GetProfileString('PrinterPort', ApGroup, 'LPT1'));

      PrnName := Temp;

      { get printer type info }
      Temp := GetProfileString('PrinterType', ApGroup, 'PCL5');
      if (Temp = 'PCL5') then
        WhatPrn := psPCL5
      else if (Temp = 'PCL4') then
        WhatPrn := psPCL4
      else if (Temp = 'EPSON') then
        WhatPrn := psEpsonFX
      else if (Temp = 'EPSON24') then
        WhatPrn := psEpson24
      else
        Abort('Invalid printer type specified in INI file');

      Use300DPI := GetProfileBool('Use300DPI', ApGroup, False);
      UseScaling := GetProfileBool('UseScaling', ApGroup, True);
      PrintFaxHeader := GetProfileBool('PrintFaxHeader', ApGroup, True);

      if (QueueFile = '') then
        QueueFile := GetProfileString('QueueFile', ApGroup, 'TPFAX.OGQ');

      Temp := StUpCase(GetProfileString('FaxDevice', ApGroup, 'CLASS2'));
      if (Temp = 'CLASS1') then
        FaxClass := ctClass1
      else if (Temp = 'CLASS2') then
        FaxClass := ctClass2
      else if (Temp = 'DETECT') then
        FaxClass := ctDetect
      else if (Temp = 'CAS') then
        FaxClass := ctCas
      else
        Abort('Invalid fax class specified in INI file');

      PageLen := GetProfileWord('PageLength', ApGroup, 60);
      Temp := StUpcase(GetProfileString('Resolution', ApGroup, 'STANDARD'));
      if (Temp = 'STANDARD') then
        Resolution := False
      else if (Temp = 'HIGH') then
        Resolution := True
      else
        Abort('Invalid fax resolution specified in INI file');

      StationID := GetProfileString('StationID', ApGroup, '');
      Header := GetProfileString('Header', ApGroup, '');
      CoverPage := GetProfileString('DefCover', ApGroup, '');
      LogoFile := GetProfileString('CasLogoFile', ApGroup, '');
      SenderName := GetProfileString('YourNameHere', ApGroup, '');
      Temp := StUpCase(GetProfileString('ComPort', ApGroup, ''));
      if (Length(Temp) = 4) and (Copy(Temp, 1, 3) = 'COM') then
        ComPort := ComNameType(Ord(Com1) + (Ord(Temp[4]) - Ord('1')))
      else
        Abort('Invalid communications port specified in INI file');

      Temp := StUpCase(GetProfileString('DeviceLayer', ApGroup, 'UART'));
      if (Temp = 'UART') then
        DevType := dlUart
      else if (Temp = 'INT14') then
        DevType := dlInt14
      else if (Temp = 'DIGIBOARD') then
        DevType := dlDigi
      else if (Temp = 'FOSSIL') then
        DevType := dlFossil;

      PortRate := GetProfileLong('PortRate', ApGroup, 9600);
      XmitBPS := GetProfileLong('MaxFaxBPS', ApGroup, 9600);
      ErrorCorrection := GetProfileBool('ErrorCorrection', ApGroup, False);
      RetryTime := GetProfileWord('RetryTime', ApGroup, 30);
      DialTime := GetProfileWord('DialTime', ApGroup, 45);
      MaxRetries := GetProfileWord('MaxRetries', ApGroup, 5);
      ModemInit := GetProfileString('ModemInit', ApGroup, 'ATS7=30M0');
      DialPrefix := GetProfileString('DialPrefix', ApGroup, '');
      ToneDial := GetProfileBool('ToneDial', ApGroup, True);
      UseHWFlow := GetProfileBool('UseHWFlow', ApGroup, True);  {!!.01}
    end;

    Config.Done;
  end;

  function IsAnAPFFile(FN : PathStr) : Boolean;
  var
    F : File;
    S : array[0..Pred(SizeOf(DefSig))] of Char;

    procedure CloseIt;
    begin
      Close(F); if (IoResult = 0) then ;
    end;

  begin
    IsAnAPFFile := False;

    Assign(F, FN);
    Reset(F, 1);
    if (IoResult <> 0) then
      Exit;

    if (FileSize(F) < SizeOf(DefSig)) then begin
      CloseIt;
      Exit;
    end;

    BlockRead(F, S[1], SizeOf(DefSig));
    if (IoResult <> 0) then begin
      CloseIt;
    end;
    CloseIt;

    IsAnAPFFile := (CompStruct(S, DefSig, SizeOf(DefSig)) = Equal);
  end;

  function GetFileSize(FN : PathStr) : Word;
  var
    SR : SearchRec;

  begin
    FindFirst(FN, AnyFile, SR);
    if (DosError = 0) then
      GetFileSize := MaxWord(1, SR.Size div 1024)
    else
      GetFileSize := 0;
  end;

end.
