{$A+,F+,I-,R-,S-,V-}

{$I APDEFINE.INC}

{******************************************************}
{*                   APABSFAX.PAS 2.03                *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

unit ApAbsFax;
  {-Abstract data and routines for CAS and Class I/II fax}

interface

uses
  Dos,
  Dpmi,
  {$IFDEF UseOPro}
  OpRoot,
  OpString,
  OpDos,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpString,
  TpDos,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApFaxCvt;
  {$ELSE}
  ApTimer,
  ApMisc,
  ApPort,
  ApCom,
  ApFaxCvt;
  {$ENDIF}

{$I APABSFAX.PA0}

implementation

{FaxData routines}

  procedure InitFaxData(var PData : FaxDataPtr; ID : Str20);
    {-Allocate and initialize a FaxData structure}
  begin
    if not GetMemCheck(PData, SizeOf(FaxData)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with PData^ do begin
      StationID := ID;
      Title := '';
      CoverFile := '';
      Recipient := '';
      DestDir := '';
      Sender := '';
      CurrPage := 0;
      PageCount := 0;
      CoverCount := 0;
      ClassInUse := ctUnknown;
      MaxConnect := DefConnectAttempts;
      afFlags := DefFaxOptions;
      @afStatus := nil;
      @afNextFax := @NextFaxList;
      @afFaxName := @FaxNameMD;
      @afLogFax := nil;
      @afAcceptFax := nil;
      FaxListHead := nil;
      FaxListTail := nil;
      FaxListNode := nil;
      FaxListCount := 0;
      RemoteID := '';
    end;
  end;

  procedure DoneFaxData(var PData : FaxDataPtr);
    {-Dispose of a FaxData record}
  var
    Node : PFaxEntry;
    Next : PFaxEntry;
  begin
    with PData^ do begin
      {Dispose of faxentry list}
      if FaxListCount <> 0 then begin
        Node := FaxListHead;
        while Node <> nil do begin
          Next := Node^.fNext;
          FreeMemCheck(Node, SizeOf(TFaxEntry));
          Node := Next;
        end;
      end;
    end;
    FreeMemCheck(PData, SizeOf(FaxData));
  end;

  procedure afOptionsOn(FP : FaxRecPtr; OptionFlags : Word);
    {-Activate multiple options}
  begin
    with FP^, PData^ do
      afFlags := afFlags or (OptionFlags and not BadFaxOptions);
  end;

  procedure afOptionsOff(FP : FaxRecPtr; OptionFlags : Word);
    {-Deactivate multiple options}
  begin
    with FP^, PData^ do
      afFlags := afFlags and not (OptionFlags and not BadFaxOptions);
  end;

  function afOptionsAreOn(FP : FaxRecPtr; OptionFlags : Word) : Boolean;
    {-Return True if all specified options are on}
  begin
    with FP^, PData^ do
      afOptionsAreOn := (afFlags and OptionFlags = OptionFlags);
  end;

  procedure FaxStatus(FP : FaxRecPtr; Starting, Ending : Boolean);
  begin
    with FP^, PData^ do
      if @afStatus <> nil then
        afStatus(FP, Starting, Ending);
  end;

  procedure SetFaxStatusProc(FP : FaxRecPtr; SP : FaxStatusProc);
  begin
    with FP^, PData^ do
      afStatus := SP;
  end;

  procedure SetConnectAttempts(FP : FaxRecPtr; Attempts : Word;
                               DelayTicks : Word);
    {-Set number of connect attempts per fax, 0 = infinite}
  begin
    with FP^, PData^ do begin
      MaxConnect := Attempts;
      RetryWait := DelayTicks;
    end;
  end;

  procedure SetTitle(FP : FaxRecPtr; NewTitle : String);
  begin
    with FP^, PData^ do
      Title := NewTitle;
  end;

  procedure SetRecipientName(FP : FaxRecPtr; NewName : String);
    {-Set name of recipient}
  begin
    with FP^, PData^ do
      Recipient := NewName;
  end;

  procedure SetSenderName(FP : FaxRecPtr; NewName : String);
    {-Set name of sender}
  begin
    with FP^, PData^ do
      Sender := NewName;
  end;

  procedure SetDestinationDir(FP : FaxRecPtr; Dest : PathStr);
    {-Set a destination directory for received files}
  begin
    with FP^, PData^ do
      DestDir := StUpcase(Dest);
  end;

  procedure SetNextFaxFunc (FP : FaxRecPtr; NFF : NextFaxFunc);
    {-Set function to call for next number}
  begin
    with FP^, PData^ do
      afNextFax := NFF;
  end;

  procedure SetFaxLogProc(FP : FaxRecPtr; FLP: FaxLogProc);
    {-Set function to call for each fax sent/received}
  begin
    with FP^, PData^ do
      afLogFax := FLP;
  end;

  procedure SetFaxNameFunc(FP : FaxRecPtr; FNF : FaxNameFunc);
    {-Set function to call to name incoming faxes}
  begin
    with FP^, PData^ do
      afFaxName := FNF;
  end;

  procedure SetAcceptFaxFunc(FP : FaxRecPtr; AFF : AcceptFaxFunc);
    {-Set function to call to accept incoming faxes}
  begin
    with FP^, PData^ do
      afAcceptFax := AFF;
  end;

  procedure SetStationID(FP : FaxRecPtr; NewID : Str20);
  begin
    with FP^, PData^ do
      StationID := NewID;
  end;

  function NextFax(FP : FaxRecPtr; var Number : String;
                   var FName : PathStr; var Cover : PathStr) : Boolean;
    {-Return next number to dial}
  begin
    with FP^, PData^ do begin
      if @afNextFax <> nil then begin
        NextFax := afNextFax(FP, Number, FName, Cover);
        FName := StUpcase(FName);
        Cover := StUpcase(Cover);
      end else
        NextFax := False;
    end;
  end;

  procedure LogFax(FP : FaxRecPtr; Number : String;
                   FName: PathStr; Log : TLogFaxCode);
    {-Return next number to dial}
  begin
    with FP^, PData^ do
      if @afLogFax <> nil then
        afLogFax(FP, Number, FName, Log);
  end;

  function FaxName(FP : FaxRecPtr) : PathStr;
    {-Call FaxName hook}
  begin
    with FP^, PData^ do begin
      if @afFaxName <> nil then
        FaxName := afFaxName(FP)
      else
        FaxName := 'NONAME.APF';
    end;
  end;

  function AcceptFax(FP : FaxRecPtr; RemoteName : Str20) : Boolean;
    {-Call AcceptFax hook}
  begin
    with FP^, PData^ do begin
      if @afAcceptFax <> nil then
        AcceptFax := afAcceptFax(FP, RemoteName)
      else
        AcceptFax := True;
    end;
  end;

  function afConvertHeaderString(FP : FaxRecPtr; S : String) : String;
    {-compress a fax header string, converting tags to appropriate values}
  var
    I, N : Integer;
    T : String;
  begin
    with FP^, PData^ do begin
      {walk thru the string, converting tags to appropriate data}
      I := Pos('$', S);
      while I > 0 do begin
        {get length of tag}
        N := I;
        while (N <= Length(S)) and (S[n] <> ' ') do
          Inc(N);
        Dec(N, I);

        {preserve and delete tag from the main string}
        T := Copy(S, I, N);
        Delete(S, I, N);

        {which tag?}
        case Upcase(T[2]) of
          'D':  {insert Date}
            T := TodayString;

          'T':  {insert Time}
            T := NowString;

          'I':  {insert station Id}
            T := StationID;

          'S':  {insert Sender (Title)}
            T := Title;

          'P':  {insert current Page number}
            if CoverCount > 0 then
              if SendingCover then
                T := '1'
              else
                Str(CurrPage+1, T)
            else
              Str(CurrPage, T);

          'N':  {insert Number of pages}
            Str(PageCount+CoverCount, T);

          'F' : {insert from name}
            T := Sender;

          'R' : {insert recipient's name}
            T := Recipient;

          else  {invalid tag, do nothing}
            T := '';
        end;
        Insert(T, S, I);

        {find next tag}
        I := Pos('$', S);
      end;

      afConvertHeaderString := S;
    end;
  end;

  procedure AddFaxEntry(FP : FaxRecPtr; Number : String;
                        FName : PathStr; Cover : PathStr);
    {-Add another number to the built-in list}
  var
    Node : PFaxEntry;
  begin
    with FP^, PData^ do begin
      if GetMemCheck(Node, SizeOf(TFaxEntry)) then begin

        SetAsyncStatus(ecOk);

        {Create new node}
        with Node^ do begin
          fNumber := Number;
          fFName := FName;
          fCover := Cover;
          fNext := nil;
        end;

        if FaxListHead = nil then begin
          {Set head/tail if this is the first...}
          FaxListHead := Node;
          FaxListTail := Node;
          FaxListNode := Node;
          FaxListCount := 1;
        end else begin
          {Attach to previous tail}
          FaxListTail^.fNext := Node;
          FaxListTail := Node;
          Inc(FaxListCount);
        end;
      end else
        SetAsyncStatus(ecOutOfMemory);
    end;
  end;

  procedure ClearFaxEntries(FP : FaxRecPtr);
    {-Remove all fax entries from builtin list}
  var
    Node : PFaxEntry;
    Next : PFaxEntry;
  begin
    with FP^, PData^ do begin
      Node := FaxListHead;
      while Node <> nil do begin
        Next := Node^.fNext;
        FreeMemCheck(Node, SizeOf(TFaxEntry));
        Node := Next;
      end;
      FaxListCount := 0;
      FaxListHead := nil;
      FaxListTail := nil;
      FaxListNode := nil;
    end;
  end;

  function GetFaxName(FP : FaxRecPtr) : PathStr;
    {-Return name of current fax, with path if supplied}
  begin
    with FP^, PData^ do
      GetFaxName := FaxFileName;
  end;

  function GetFaxProgress(FP : FaxRecPtr) : Word;
    {-Return fax progress code}
  begin
    with FP^, PData^ do
      GetFaxProgress := FaxProgress;
  end;

{Builtin functions}

  function NextFaxList(FP : FaxRecPtr;
                       var Number : String;
                       var FName : PathStr;
                       var Cover : PathStr) : Boolean;
  var
    Node : PFaxEntry;
  begin
    with FP^, PData^ do begin
      if FaxListNode <> nil then begin
        NextFaxList := True;
        with FaxListNode^ do begin
          Number := fNumber;
          FName := fFName;
          Cover := fCover;
          FaxListNode := fNext;
        end;
      end else
        NextFaxList := False;
    end;
  end;

  function FaxNameMD(FP : FaxRecPtr) : PathStr;
    {-Returns name for incoming fax like MMDD0001.APF}
  var
    I : Word;
    MS, DS : String[2];
    FName1 : String[4];
    FName : String;
    Y,M,D,O : Word;

    procedure MakeFileName(I : Word);
    var
      CountS : String[4];
      J : Word;
    begin
      Str(I:4, CountS);
      for J := 1 to 4 do
        if CountS[J] = ' ' then
          CountS[J] := '0';
      FName := FName1 + CountS + '.' + FaxFileExt;
      with FP^, PData^ do
        if DestDir <> '' then
          FName := AddBackSlash(DestDir)+FName;
    end;

  begin
    with FP^, PData^ do begin
      {Get the date}
      GetDate(Y,M,D,O);
      Str(M:2, MS);
      Str(D:2, DS);
      FName1 := MS + DS;
      for I := 1 to 4 do
        if FName1[I] = ' ' then
          FName1[I] := '0';

      {Find last file with this date}
      I := 0;
      repeat
        Inc(I);
        MakeFileName(I);
      until not ExistFile(FName) or (I = 10000);

      if I < 10000 then begin
        MakeFileName(I);
        FaxNameMD := FName;
      end else begin
        SetAsyncStatus(ecTooManyFiles);
        FaxNameMD := 'NONAME.APF';
      end;
    end;
  end;

  function FaxNameCount(FP : FaxRecPtr) : PathStr;
    {-Returns name for incoming fax like FAX00001.APF}
  var
    I : Word;
    FName : String;

    procedure MakeFileName(I : Word);
    var
      CountS : String[4];
      J : Word;
    begin
      Str(I:4, CountS);
      for J := 1 to 4 do
        if CountS[J] = ' ' then
          CountS[J] := '0';
      FName := 'FAX' + CountS + '.' + FaxFileExt;
      with FP^, PData^ do
        if DestDir <> '' then
          FName := AddBackSlash(DestDir)+FName;
    end;

  begin
    with FP^, PData^ do begin
      {Find last file}
      I := 0;
      repeat
        Inc(I);
        MakeFileName(I);
      until not ExistFile(FName) or (I = 10000);

      if I < 10000 then begin
        MakeFileName(I);
        FaxNameCount := FName;
      end else begin
        SetAsyncStatus(ecTooManyFiles);
        FaxNameCount := 'NONAME.APF';
      end;
    end;
  end;

end.
