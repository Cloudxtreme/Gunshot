{$A+,F+,I-,R-,S-,V-}

{$I APDEFINE.INC}

{******************************************************}
{*                   APFAXCAS.PAS 2.03                *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

unit ApFaxCas;
  {-CAS fax send/receive objects}

interface

uses
  {$IFDEF DPMI}
  WinAPI,
  {$ENDIF}
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
  ApAbsFax,
  ApFaxCvt;
  {$ENDIF}

{$I APFAXCAS.PA0}

implementation

type
  TCharArray = array[0..255] of Char;

const
  {CAS function codes}
  cfIsInstalled               = $00;
  cfSubmitTask                = $01;
  cfAbortEvent                = $02;
  cfFindFirst                 = $05;
  cfFindNext                  = $06;
  cfOpenFile                  = $07;
  cfDeleteFile                = $08;
  cfDeleteAll                 = $09;
  cfGetEventDate              = $0A;
  cfSetTaskDate               = $0B;
  cfGetEventTime              = $0C;
  cfSetTaskTime               = $0D;
  cfGetEDB                    = $0E;
  cfGetSetAutoReceive         = $0F;
  cfGetEventStatus            = $10;
  cfGetQueueStatus            = $11;
  cfGetHardwareStatus         = $12;
  cfRunDiagnostics            = $13;
  cfMoveReceivedFile          = $14;
  cfSubmitFile                = $15;

  dosCloseFile                = $3E;

  function StrLen(var A) : Byte;
    {-Return length of pchar S}
  var
    N : Byte;
    S : TCharArray absolute A;
  begin
    N := 0;
    while (N < 255) and (S[N+1] <> #0) do
      Inc(N);
    StrLen := N;
  end;

  procedure Prep(var R : Registers; CASFunc : Byte);
    {-Prepare to call CAS manager}
  begin
    FillChar(R, SizeOf(R), 0);
    R.AL := CASFunc;
  end;

  procedure CASCall(var R : Registers);
    {-Call CAS manager}
  {$IFDEF DPMI}
  var
    DRegs : DPMIRegisters;
  {$ENDIF}
  begin
    R.AH := $CB;
    LastCasFunc := R.AL;
    {$IFDEF DPMI}
    FillChar(DRegs, SizeOf(DRegs), 0);
    with DRegs do begin
      AX := R.AX;
      BX := R.BX;
      CX := R.CX;
      DX := R.DX;
      DS := R.DS;
      if SimulateRealModeInt($2F, DRegs) = 0 then ;
      R.AX := AX;
      R.BX := BX;
      R.CX := CX;
      R.DX := DX;
    end;
    {$ELSE}
    Intr($2F, R);
    {$ENDIF}
    LastCasReturn := R.AX;
  end;

  function CASInstalled : Boolean;
    {-Return True if CAS manager TSR is installed}
  var
    R : Registers;
  begin
    Prep(R, cfIsInstalled);
    CASCall(R);
    CASInstalled := (R.AL = $FF);
  end;

  procedure InitCasFax(var FP : FaxRecPtr; ID : Str20);
    {-Init CASFax record}
  begin
    if not CASInstalled then begin
      SetAsyncStatus(ecFaxNoCASManager);
      Exit;
    end;

    if not GetMemCheck(FP, SizeOf(CasFax)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with CasFaxPtr(FP)^ do begin
      InitFaxData(PData, ID);
      if GetAsyncStatus <> ecOk then begin
        FreeMemCheck(FP, Sizeof(CasFax));
        Exit;
      end;

      with PData^ do begin
        StatusWait := DefStatusTimeout;
        ClassInUse := ctCAS;
        Resolution := 1;
        LogoFile := '';
        @CASAbort := nil;
      end;
    end;
  end;

  procedure DoneCasFax(var FP : FaxRecPtr);
    {-Destroy CASFax record}
  begin
    with FP^ do
      DoneFaxData(PData);
    FreeMemCheck(FP, SizeOf(CasFax));
  end;

  procedure SubmitTask(FP : FaxRecPtr; FName : PathStr; var Handle : Word);
    {-Submit a CAS task, function 01}
  var
    FNameZ : array[0..80] of Char;
    {$IFDEF DPMI}
    M : DosMemRec;
    {$ENDIF}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      Prep(Regs, cfSubmitTask);
      Move(FName[1], FNameZ, Length(FName));
      FNameZ[Length(FName)] := #0;
      with Regs do begin
        {$IFDEF DPMI}
        LongInt(M) := GlobalDosAlloc(SizeOf(FName));
        if LongInt(M) = 0 then begin
          SetAsyncStatus(ecOutOfMemory);
          Handle := 0;
          Exit;
        end;
        Move(FNameZ, Ptr(M.Sele, 0)^, SizeOf(FName));
        DS := M.Segm;
        DX := 0;
        {$ELSE}
        DS := Seg(FNameZ);
        DX := Ofs(FNameZ);
        {$ENDIF}
        CASCall(Regs);
        {$IFDEF DPMI}
        M.Sele := GlobalDosFree(M.Sele);
        {$ENDIF}
        if Integer(AX) > 0 then begin
          SetAsyncStatus(ecOk);
          Handle := AX;
        end else begin
          Handle := 0;
          SetAsyncStatus(Word(-AX));
        end;
      end;
    end;
  end;

  procedure AbortCurrentEvent(FP : FaxRecPtr; var Handle : Word);
    {-Aborts the current CAS event, may take up to 30 seconds, function 02}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfAbortEvent);
      CASCall(Regs);
      if Integer(AX) > 0 then begin
        SetAsyncStatus(ecOk);
        Handle := AX;
      end else begin
        SetAsyncStatus(Word(-AX));
        Handle := 0;
      end;
    end;
  end;

  procedure FindFirstCAS(FP : FaxRecPtr; Q : QueueType; Direction : Boolean;
                         Status : Integer; var Handle : Word);
    {-Find the first event in the specified queue, function 5}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfFindFirst);
      CX := Word(Status);
      DH := Byte(Direction);
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        Handle := BX
      end else begin
        SetAsyncStatus(Word(-AX));
        Handle := 0;
      end;
    end;
  end;

  procedure FindNextCAS(FP : FaxRecPtr; Q : QueueType; var Handle : Word);
    {-Find the next event in the specified queue, function 6}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfFindNext);
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        Handle := BX;
      end else begin
        SetAsyncStatus(Word(-AX));
        Handle := 0;
      end;
    end;
  end;

  procedure OpenFile(FP : FaxRecPtr; Q : QueueType; FileNumber : Word;
                     Handle : Word; var FHandle : Word);
    {-Open a queue file, function 07}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfOpenFile);
      BX := Handle;
      CX := FileNumber;
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        FHandle := BX;
      end else begin
        SetAsyncStatus(Word(-AX));
        FHandle := 0;
      end;
    end;
  end;

  procedure CloseFile(FP : FaxRecPtr; Handle : Word);
    {-Close a previously-opened file handle}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      FillChar(Regs, SizeOf(Regs), 0);
      with Regs do begin
        AH := dosCloseFile;
        BX := Handle;
        MsDos(Regs);
      end;
    end;
  end;

  procedure DeleteFile(FP : FaxRecPtr; Handle : Word;
                       FileNumber : Word; Q : QueueType);
    {-Delete the file associated with Handle from queue Q, function 08}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfDeleteFile);
      BX := Handle;
      CX := FileNumber;
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure DeleteAllFiles(FP : FaxRecPtr; Q : QueueType);
    {-Delete all files in queue Q, function 09}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfDeleteAll);
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure GetEventDate(FP : FaxRecPtr; Handle : Word; Q : QueueType;
                         var Year, Month, Day : Word);
    {-Get the date info for event Handle in queue Q, function 0A}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetEventDate);
      BX := Handle;
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        Year  := CX;
        Month := DH;
        Day   := DL;
      end else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure SetTaskDate(FP : FaxRecPtr; Handle : Word; Year, Month, Day : Word);
    {-Set the date info for event Handle in queue Q, function 0B}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfSetTaskDate);
      BX := Handle;
      CX := Year;
      DH := Byte(Month);
      DL := Byte(Day);
      CASCall(Regs);
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure GetEventTime(FP : FaxRecPtr; Handle : Word; Q : QueueType;
                         var Hour, Min, Sec : Word);
    {-Get the time info for event Handle in queue Q, function 0C}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetEventTime);
      BX := Handle;
      DL := Byte(Q);
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        Hour := CH;
        Min  := CL;
        Sec  := DH;
      end else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure SetTaskTime(FP : FaxRecPtr; Handle : Word; Hour, Min, Sec : Word);
    {-Set the time info for event Handle in queue Q, function 0D}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfSetTaskTime);
      BX := Handle;
      CH := Hour;
      CL := Min;
      DH := Sec;                                                       {!!.01}
      CASCall(Regs);
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure GetExternalDataBlock(FP : FaxRecPtr; var EDB : ExternalDataBlock);
    {-Return data in external data block, function 0E}
    {$IFDEF DPMI}
  var
    M : DosMemRec;
    {$ENDIF}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      FillChar(EDB, SizeOf(EDB), 0);
      Prep(Regs, cfGetEDB);
      {$IFDEF DPMI}
      LongInt(M) := GlobalDosAlloc(SizeOf(EDB));
      if LongInt(M) = 0 then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
      DS := M.Segm;
      DX := 0;
      {$ELSE}
      DS := Seg(EDB);
      DX := Ofs(EDB);
      {$ENDIF}
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        {$IFDEF DPMI}
        Move(Ptr(M.Sele, 0)^, EDB, SizeOf(EDB));
        {$ENDIF}
      end else
        SetAsyncStatus(Word(-AX));
      {$IFDEF DPMI}
      M.Sele := GlobalDosFree(M.Sele);
      {$ENDIF}
    end;
  end;

  procedure GetSetAutoReceive(FP : FaxRecPtr; var Rings : Word; GetSet : Word);
    {-Enable/disable autoreceive, function 0F}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetSetAutoReceive);
      DL := GetSet;
      DH := Rings;
      CASCall(Regs);
      if Integer(AX) >= 0 then begin
        SetAsyncStatus(ecOk);
        Rings := AX;
      end else begin
        Rings := 0;
        SetAsyncStatus(Word(-AX));
      end;
    end;
  end;

  procedure GetEventStatus(FP : FaxRecPtr; var SRec : StatusRecord);
    {-Return status of current event, function 10}
  {$IFDEF DPMI}
  var
    M : DosMemRec;
  {$ENDIF}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetEventStatus);
      {$IFDEF DPMI}
      LongInt(M) := GlobalDosAlloc(SizeOf(SRec));
      if LongInt(M) = 0 then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
      FillChar(Ptr(M.Sele,0)^, SizeOf(SRec), 0);
      DS := M.Segm;
      DX := 0;
      {$ELSE}
      DS := Seg(SRec);
      DX := Ofs(SRec);
      {$ENDIF}
      CASCall(Regs);
      if AX = 0 then begin
        SetAsyncStatus(ecOk);
        {$IFDEF DPMI}
        Move(Ptr(M.Sele, 0)^, SRec, SizeOf(SRec));
        {$ENDIF}
      end else
        SetAsyncStatus(Word(-AX));
      {$IFDEF DPMI}
      M.Sele := GlobalDosFree(M.Sele);
      {$ENDIF}
    end;
  end;

  procedure GetQueueStatus(FP : FaxRecPtr; Q : QueueType;
                           var Changes, ControlFiles, ReceivedFiles : Word);
    {-Get status of a queue, function 11}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetQueueStatus);
      DL := Ord(Q);
      CASCall(Regs);
      Changes := AX;
      ControlFiles := BX;
      ReceivedFiles := CX;
      SetAsyncStatus(ecOk);
    end;
  end;

  procedure GetHardwareStatus(FP : FaxRecPtr; var SArray : StatusArray);
    {-Return vendor-specific hardware status info, function 12}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfGetHardwareStatus);
      DS := Seg(SArray);
      DX := Ofs(SArray);
      CASCall(Regs);
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX));
    end;
  end;

  procedure RunDiagnostics(FP : FaxRecPtr; Mode : Word);
    {-Run hardware diagnostics, function 13}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Prep(Regs, cfRunDiagnostics);
      CASCall(Regs);
      DX := Mode;
      if AX <> 0 then
        SetAsyncStatus(Word(-AX))
      else
        SetAsyncStatus(ecOk);
    end;
  end;

  procedure MoveReceivedFile(FP : FaxRecPtr; Handle : Word;
                             FileNumber : Word;
                             NewName : PathStr);
    {-Move a received file to NewName (path and filename), function 14}
  var
    FNameZ : array[0..80] of Char;
    {$IFDEF DPMI}
    M : DosMemRec;
    {$ENDIF}
  begin
    with CasFaxPtr(FP)^, PData^, Regs do begin
      Move(NewName[1], FNameZ, Length(NewName));
      FNameZ[Length(NewName)] := #0;
      Prep(Regs, cfMoveReceivedFile);
      BX := Handle;
      CX := FileNumber;
      {$IFDEF DPMI}
      LongInt(M) := GlobalDosAlloc(SizeOf(FNameZ));
      if LongInt(M) = 0 then begin
        SetAsyncStatus(ecOutOfMemory);
        Handle := 0;
        Exit;
      end;
      Move(FNameZ, Ptr(M.Sele, 0)^, SizeOf(FNameZ));
      DS := M.Segm;
      DX := 0;
      {$ELSE}
      DS := Seg(FNameZ);
      DX := Ofs(FNameZ);
      {$ENDIF}
      CASCall(Regs);
      {$IFDEF DPMI}
      M.Sele := GlobalDosFree(M.Sele);
      {$ENDIF}
      if AX = 0 then
        SetAsyncStatus(ecOk)
      else
        SetAsyncStatus(Word(-AX))
    end;
  end;

  procedure SubmitSingleFile(FP : FaxRecPtr;
                             TransType : Word;
                             TextSize : Word;
                             Time : Word;
                             Date : Word;
                             Dest : String;
                             FName : PathStr;
                             Number : String;
                             Cover : PathStr;
                             var Handle : Word);
    {-Submit a single file, function 15}
  const
    CRLF : array[0..1] of Char = (cCR, cLF);
  var
    CFRSize : Word;
    CoverLen  : Word;
    Len : Word;
    BytesWritten : Word;
    DotLoc : Byte;
    CF : ControlFileRecordPtr;
    P  : ControlFileRecordPtr;
    FT : FileTransferRecord;
    TempF : File;
    S : String;
    Dir : PathStr;
    {$IFDEF DPMI}
    M : DosMemRec;
    {$ENDIF}

  function ReadCover(var Buf) : Boolean;
  var
    F : Text;
    Index : Word;
    Finished : Boolean;
    Buffer : CoverData absolute Buf;
    SaveMode : Byte;                                                   {!!.02}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      ReadCover := False;

      {Read data from cover file into cover buffer}
      SaveMode := FileMode;                                            {!!.02}
      FileMode := GetAproFileMode;                              {!!.02}{!!.03}
      Assign(F, Cover);
      Reset(F);
      FileMode := SaveMode;                                            {!!.02}
      SetAsyncStatus(IoResult);
      if GetAsyncStatus <> 0 then
        Exit;
      FillChar(Buffer, MaxCoverData, 0);
      Index := 0;
      Finished := False;
      repeat
        ReadLn(F, S);
        Finished := Eof(F);
        S := afConvertHeaderString(FP, S);
        if (Length(S) + Index) < MaxCoverData then begin
          Move(S[1], Buffer[Index], Length(S));
          Inc(Index, Length(S));
          Move(CRLF, Buffer[Index], 2);
          Inc(Index, 2);
        end else
          Finished := True;
      until Finished;
      Close(F);
      if IoResult <> 0 then ;

      CoverLen := Index;
      ReadCover := True;
    end;
  end;

  {!!.01 new}
  function CalcPages : Word;
    {-Return the proper page count}
  type
    DcxHeader = record
      DcxCheck : LongInt;
      Offsets  : array[1..1024] of LongInt;
    end;
  var
    LineCnt : Word;
    PageCnt : Word;
    Max     : Word;
    BW      : Word;
    I       : Word;
    F1      : File;
    F2      : Text;
    DH      : DcxHeader;
    SaveMode: Byte;
  begin
    {Make sure function result is assigned for error exits}
    CalcPages := 0;

    case FT.FileType of
      {Text files, scan for pages}
      0 : begin
            SaveMode := FileMode;                                      {!!.02}
            FileMode := GetAproFileMode;                        {!!.02}{!!.03}
            Assign(F2, FName);
            Reset(F2);
            FileMode := SaveMode;                                      {!!.02}
            SetAsyncStatus(IoResult);
            LineCnt := 0;
            PageCnt := 0;
            while (GetAsyncStatus = ecOk) and not Eof(F2) do begin
              ReadLn(F2, S);
              SetAsyncStatus(IoResult);
              Inc(LineCnt);
              if (Pos(cFF, S) <> 0) or (LineCnt > LinesPerPage) then begin
                Inc(PageCnt);
                LineCnt := 0;
              end;
            end;
            Close(F2);
            if IoResult <> 0 then ;
            if LineCnt <> 0 then
              Inc(PageCnt);
            CalcPages := PageCnt;
          end;

      {PCX files, always one page}
      1 : CalcPages := 1;

      {DCX files, get page count}
      2 : begin
            {Read DCX header}
            SaveMode := FileMode;                                      {!!.02}
            FileMode := GetAproFileMode;                        {!!.02}{!!.03}
            Assign(F1, FName);
            Reset(F1, 1);
            FileMode := SaveMode;                                      {!!.02}
            BlockRead(F1, DH, SizeOf(DH), BW);
            Close(F1);
            SetAsyncStatus(IoResult);
            if GetAsyncStatus <> ecOk then
              Exit;
            if BW < 1028 then
              Max := (BW-4) div 4
            else
              Max := 1024;

            {Scan thru header, count pages}
            I := 1;
            while (I <= Max) and (DH.Offsets[I] <> 0) do
              Inc(I);

            CalcPages := I-1;
          end;

      {Unknown file type, say one page}
      else
        CalcPages := 1;
    end;
  end;

  begin
    with CasFaxPtr(FP)^, PData^ do begin
      if not FlagIsSet(afFlags, afCASSubmitUseControl) then begin
        {Use function 15}
        FillChar(SubmitFile, SizeOf(SubmitFile), 0);
        with SubmitFile do begin
          EventType := TransType;
          XferType := TextSize;
          SendTime := Time;
          SendDate := Date;
          Move(Dest[1], DestName, Length(Dest));
          Move(FName[1], FaxName, Length(FName));
          Move(Number[1], PNumber, Length(Number));
          CoverYesNo := 0;
          if (Cover <> '') then begin
            if not ReadCover(CoverBuffer) then
              Exit;
            CoverYesNo := 1;
          end;
        end;

        {Submit buffer to CAS}
        with Regs do begin
          Prep(Regs, cfSubmitFile);
          {$IFDEF DPMI}
          LongInt(M) := GlobalDosAlloc(SizeOf(SubmitFile));
          if LongInt(M) = 0 then begin
            SetAsyncStatus(ecOutOfMemory);
            Exit;
          end;
          Move(SubmitFile, Ptr(M.Sele, 0)^, SizeOf(SubmitFile));
          DS := M.Segm;
          DX := 0;
          {$ELSE}
          DS := Seg(SubmitFile);
          DX := Ofs(SubmitFile);
          {$ENDIF}
          CASCall(Regs);
          {$IFDEF DPMI}
          M.Sele := GlobalDosFree(M.Sele);
          {$ENDIF}
          if AX > 0 then begin
            SetAsyncStatus(ecOk);
            Handle := AX;
          end else begin
            SetAsyncStatus(Word(-AX));
            Handle := 0;
          end;
        end;
      end else begin
        {Create a ControlFile and submit it ourselves}

        {Get a ControlFile block with room for a file transfer record}
        Len := SizeOf(ControlFileRecord) +
               SizeOf(FileTransferRecord) +
               MaxCoverData;
        if not GetMemCheck(CF, Len) then begin
          Handle := 0;
          SetAsyncStatus(ecOutOfMemory);
          Exit;
        end;

        FillChar(CF^, Len, 0);
        with CF^ do begin
          EventType := 0;
          XferType := TransType;
          SendTime := Time;
          SendDate := Date;
          if FName = '' then
            FilesToXfer := 0
          else
            FilesToXfer := 1;
          Move(Number[1], PhoneNum, Length(Number));
          Move(Dest[1], DestName, Length(Dest));
          Move(Sender[1], SenderName, Length(Sender));
          Move(LogoFile[1], Logo, Length(LogoFile));
        end;

        FillChar(FT, SizeOf(FT), 0);
        FT.TextSize := TextSize;
        with FT do begin
          DotLoc := Pos('.', FName);
          if DotLoc = 0 then
            FileType := 0
          else begin
            S := Copy(FName, DotLoc+1, 3);
            S := StUpcase(S);
            if S = 'PCX' then
              FileType := 1
            else if S = 'DCX' then
              FileType := 2
            else
              FileType := 0;
          end;

          {Get size of file to transmit}
          SaveMode := FileMode;                                        {!!.02}
          FileMode := GetAproFileMode;                          {!!.02}{!!.03}
          Assign(TempF, FName);
          Reset(TempF, 1);
          FileMode := SaveMode;                                        {!!.02}
          SizeTotal := FileSize(TempF);
          Close(TempF);
          if IoResult <> 0 then ;

          PagesTotal := CalcPages;                                     {!!.01}
          if GetAsyncStatus <> ecOk then                               {!!.01}
            Exit;                                                      {!!.01}
          Move(FName[1], Path, Length(FName));
        end;

        {Handle cover}
        P := CF;
        Inc(P);
        with CF^ do begin
          if Cover <> '' then begin
            if not ReadCover(P^) then begin
              FreeMemCheck(CF, Len);
              Exit;
            end;
            CoverPage := 1;
            OfsToFTR := SizeOf(CF^) + CoverLen;
          end else begin
            CoverLen := 0;
            CoverPage := 0;
            OfsToFTR := SizeOf(CF^);
          end;
        end;

        {Move FT to proper position}
        Move(FT, PByteBuffer(CF)^[CF^.OfsToFTR], SizeOf(FT));

        {Create and write control file}
        GetDir(0, Dir);
        S := AddBackSlash(Dir) + 'TEMP.QUE';

        Assign(TempF, S);
        Rewrite(TempF, 1);
        BlockWrite(TempF, CF^, SizeOf(CF^)+SizeOf(FT)+CoverLen, BytesWritten);
        Close(TempF);
        SetAsyncStatus(IoResult);
        if BytesWritten <> SizeOf(CF^)+SizeOf(FT)+CoverLen then
          SetAsyncStatus(ecDiskFull);

        FreeMemCheck(CF, Len);

        {Submit the control file to CAS}
        SubmitTask(FP, S, Handle);
      end;
    end;
  end;

  procedure SetCASAbortFunc(FP : FaxRecPtr; CAF : AbortFunc);
    {-Set a CAS abort func}
  begin
    with CasFaxPtr(FP)^, PData^ do
      CASAbort := CAF;
  end;

  procedure GetAllStatus(FP : FaxRecPtr;
                         var Event : Byte;
                         var AStatus : Word;
                         var Pages : Word;
                         var PageTotal : Word;
                         var Bytes : LongInt;
                         var FName : PathStr;
                         var Remote : String);
    {Make status call and return these fields}
  var
    SRec : StatusRecord;
    Len : Byte;
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      GetEventStatus(FP, SRec);
      if GetAsyncStatus = ecOk then begin
        with SRec do begin
          with CFRec do begin
            Event := EventType;
            AStatus := Word(Status);
            Pages := PagesSent;

            Len := StrLen(RemoteCSID);
            Move(RemoteCsId, Remote[1], Len);
            Remote[0] := Char(Len);
          end;

          with FTRec do begin
            Bytes := BytesSent;
            PageTotal := PagesTotal;

            Len := StrLen(Path);
            Move(Path, FName[1], Len);
            FName[0] := Char(Len);
          end;
        end;
      end;
    end;
  end;

  function csHandleAbort(FP : FaxRecPtr) : Boolean;
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      if @CASAbort <> nil then begin
        if CASAbort then begin
          SetAsyncStatus(ecUserAbort);
          csHandleAbort := True;
        end else
          csHandleAbort := False;
      end else
        csHandleAbort := False;
    end;
  end;

  procedure SetLogoFile(FP : FaxRecPtr; LF : PathStr);
    {-Set PCX logo file}
  begin
    with CasFaxPtr(FP)^, PData^ do
      LogoFile := LF;
  end;

  procedure GetPageInfoCAS(FP : FaxRecPtr;
                           var Pages : Word;
                           var Page : Word;
                           var BytesTransferred : LongInt;
                           var PageLength : LongInt);
  var
    Handle : Word;
    Event : Byte;
    AStatus : Word;
    FName : PathStr;
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      if not FlagIsSet(afFlags, afCASWaitTillDone) then begin
        GetAllStatus(FP, Event, AStatus, Page, Pages, BytesTransferred,
                         FName, RemoteID);
      end else begin
        Pages := CurPages;
        Page := CurPage;
        BytesTransferred := CurBytes;
        PageLength := 0;
      end;
    end;
  end;

  procedure SetCASResolution(FP : FaxRecPtr; High : Boolean);
    {-Pass true to set high resolution}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      if High then
        Resolution := 0
      else
        Resolution := 1;
    end;
  end;

  function FaxTransmitPartCas(FP : FaxRecPtr) : FaxStateType;
    {-Do one part of CAS send process}
  var
    Handle : Word;
    Event : Byte;
    AStatus : Word;
    Pages : Word;
    PageTotal : Word;
    Bytes : LongInt;
    FName : PathStr;
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      {Check for user abort request}
      if GetAsyncStatus <> ecUserAbort then
        if csHandleAbort(FP) then
          State := csAbort;

      {Show status periodically}
      if (State <> csInit) and TimerExpired(StatusTimer) then begin
        {Get status info}
        GetAllStatus(FP, Event, AStatus, Pages, PageTotal, Bytes,
                         FName, RemoteID);
        CurPages := PageTotal;
        CurPage := Pages;
        CurBytes := Bytes;

        {Convert status to closest AsyncStatus value}
        if GetAsyncStatus = ecOk then begin
          case AStatus of
            0,1 : FaxProgress := fpWaiting;
            2   : FaxProgress := fpDialing;
            3   : FaxProgress := fpSendPage;
            5   : SetAsyncStatus(ecUserAbort);
          end;

          {Reset progress timer}
          NewTimer(ReplyTimer, TransmitWait);
        end else if GetAsyncStatus = $202 then
          {No current event, say we're waiting}
          FaxProgress := fpWaiting
        else
          {Error, we're done}
          State := csAbort;

        FaxStatus(FP, False, False);
        NewTimer(StatusTimer, StatusWait)
      end;

      {Main state machine}
      case State of
        csInit :
          begin
            FaxProgress := fpWaiting;
            FaxStatus(FP, True, False);
            NewTimer(StatusTimer, StatusWait);
            State := csSubmitting;
            InProgress := False;
          end;

        csSubmitting :
          if NextFax(FP, PhoneNum, FaxFileName, CoverFile) then begin
            LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitStart);
            SubmitSingleFile(FP,
                             Resolution,              {Resolution}
                             0,                       {Text size, 80}
                             0,                       {Send time}
                             0,                       {Send date}
                             Recipient,               {Dest}
                             FaxFileName,             {File to fax}
                             PhoneNum,                {Number to dial}
                             CoverFile,               {Cover file}
                             Handle);                 {Returned handle}

            {Log results of submission}
            if GetAsyncStatus = ecOk then
              LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitOk)
            else
              LogFax(FP, PhoneNum, FaxFileName, lfaxTransmitFail);
          end else begin
            if FlagIsSet(afFlags, afCASWaitTillDone) then
              State := csWaiting
            else begin
              SetAsyncStatus(ecOk);
              FaxStatus(FP, False, True);
              State := csDone
            end;

            {Set progress timer}
            NewTimer(ReplyTimer, TransmitWait);
          end;

        csWaiting :
          if TimerExpired(ReplyTimer) then begin
            {Too much time elapsed without a current event, must be finished}
            SetAsyncStatus(ecOk);
            FaxStatus(FP, False, True);
            State := csDone;
          end;

        csAbort :
          begin
            FaxStatus(FP, False, True);
            State := csDone;
          end;
      end;

      if State = csDone then
        FaxTransmitPartCas := faxFinished
      else
        FaxTransmitPartCas := faxWaiting;
    end;
  end;

  procedure PrepareFaxTransmitPartCas(FP : FaxRecPtr);
    {-Prepare to call FaxTransmitPart}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      SetAsyncStatus(ecOk);
      FaxProgress := fpWaiting;
      State := csInit;
      NewTimer(StatusTimer, StatusWait);
    end;
  end;

  procedure FaxTransmitCas(FP : FaxRecPtr);
    {-Call CAS function to submit all fax entries}
  var
    Status : FaxStateType;
  begin
    PrepareFaxTransmitPartCas(FP);

    repeat
      Status := FaxTransmitPartCas(FP);
    until Status = faxFinished;
  end;

  function FaxReceivePartCas(FP : FaxRecPtr) : FaxStateType;
    {-Do one part of CAS receive process}
  var
    Handle : Word;
    Event : Byte;
    AStatus : Word;
    Pages : Word;
    PageTotal : Word;
    Bytes : LongInt;
    FName : PathStr;
    Number : String;
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      {Check for user abort request}
      if GetAsyncStatus <> ecUserAbort then
        if csHandleAbort(FP) then
          State := csAbort;

      {Show status periodically}
      if (State <> csInit) and TimerExpired(StatusTimer) then begin
        {Get status info}
        GetAllStatus(FP, Event, AStatus, Pages, PageTotal, Bytes,
                         FName, RemoteID);
        CurPages := PageTotal;
        CurPage := Pages;
        CurBytes := Bytes;

        {InProgress is set True after first non-zero status}
        if (GetAsyncStatus = ecOk) and not InProgress then begin
          InProgress := AStatus <> 0;
          if InProgress then
            FaxStatus(FP, True, False);
        end else if (GetAsyncStatus <> ecOk) and InProgress then begin
          {Current receive is finished, prepare to move it}
          NewTimer(ReplyTimer, 0);
          InProgress := False;
          SetAsyncStatus(ecOk);
          FaxStatus(FP, False, True);
        end;

        {Convert status to closest AsyncStatus value}
        if GetAsyncStatus = ecOk then begin
          case AStatus of
            0 : if InProgress then begin
                  {Current receive is finished, prepare to move it}
                  NewTimer(ReplyTimer, 0);
                  InProgress := False;
                  SetAsyncStatus(ecOk);
                  FaxStatus(FP, False, True);
                end else
                  FaxProgress := fpWaiting;
            1 : FaxProgress := fpWaiting;
            4 : FaxProgress := fpGetPage;
            5 : SetAsyncStatus(ecUserAbort);
          end;
        end else if GetAsyncStatus = $202 then begin
          {No current event, say we're waiting}
          FaxProgress := fpWaiting;
          SetAsyncStatus(ecOk);
        end else
          {Error, we're done}
          State := csAbort;

        if InProgress then begin
          FaxStatus(FP, False, False);
          NewTimer(StatusTimer, StatusWait)
        end;
      end;

      {Main state machine}
      case State of
        csInit :
          begin
            FaxProgress := fpWaiting;
            NewTimer(StatusTimer, StatusWait);
            State := csWaiting;
            InProgress := False;
            FirstReceive := True;
          end;

        csWaiting :
          {Check for file in receive log, move it to dest dir}
          begin
            {Don't check while receiving a file}
            if InProgress then begin
              FaxReceivePartCas := faxWaiting;
              Exit;
            end;

            {Don't check too often}
            if FirstReceive then
              if not TimerExpired(ReplyTimer) then begin
                FaxReceivePartCas := faxWaiting;
                Exit;
              end;

            if FirstReceive then begin
              FindFirstCAS(FP, qReceive, False, 0, Handle);
              FirstReceive := False;
            end else begin
              FindNextCAS(FP, qReceive, Handle);
            end;

            if GetAsyncStatus = ecOk then begin
              FaxFileName := FaxName(FP);
              LogFax(FP, '', FaxFileName, lfaxReceiveStart);
              MoveReceivedFile(FP, Handle, 1, FaxFileName);
              if GetAsyncStatus = ecOk then begin
                LogFax(FP, '', FaxFileName, lfaxReceiveOk);
                DeleteFile(FP, Handle, 0, qReceive);
              end else
                LogFax(FP, '', FaxFileName, lfaxReceiveFail);
            end else begin
              FirstReceive := True;
              if not FlagIsSet(afFlags, afCASWaitTillDone) then begin
                FaxStatus(FP, False, True);
                State := csDone;
              end else begin
                NewTimer(ReplyTimer, ReceiveWait);
              end;
            end;
          end;

        csAbort :
          begin
            if InProgress then
              FaxStatus(FP, False, True);
            State := csDone;
          end;
      end;

      if State = csDone then
        FaxReceivePartCas := faxFinished
      else
        FaxReceivePartCas := faxWaiting;
    end;
  end;

  procedure PrepareFaxReceivePartCas(FP : FaxRecPtr);
    {-Prepare to call FaxReceivePart}
  begin
    with CasFaxPtr(FP)^, PData^ do begin
      FaxProgress := fpWaiting;
      State := csInit;
      NewTimer(StatusTimer, StatusWait);
      NewTimer(ReplyTimer, 0);
    end;
  end;

  procedure FaxReceiveCas(FP : FaxRecPtr);
    {-Call FaxReceivePart until fax is sent}
  var
    Status : FaxStateType;
  begin
    PrepareFaxReceivePartCas(FP);

    repeat
      Status := FaxReceivePartCas(FP);
    until Status = faxFinished;
  end;

end.
