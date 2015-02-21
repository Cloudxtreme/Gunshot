{$V-,B-,I-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}
{$X+}
{*********************************************************}
{*                   APINIDB.PAS 2.03                    *}
{*     Copyright (c) TurboPower Software 1995.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApIniDB;
  {-INI file database management}

interface

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
  ApIni;

const
  dbNumEntries   = '_Entries';  {Number of entries key name}
  NonValue       = '#';         {Value of DB fields SPECIFICALLY left blank}
  DbBogus        = 'None';      {Bogus key name for creating sections}

{$I APINIDB.PA0}

implementation

  function Long2Str(L : LongInt) : String;
    {-Convert a long/word/integer/byte/shortint to a String}
  var
    S : String;

  begin
    Str(L, S);
    Long2Str := S;
  end;

  procedure InitIniDataBase(var D : IniDataBaseRecPtr; FName : String;
                            ReadOnly : Boolean; AlwaysRW: Boolean);
    {-Initialize a .INI file database}
  begin
    if not GetMemCheck(D, SizeOf(IniDataBaseRec)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;
    with D^ do begin
      InitIniMgr(IData, FName, ReadOnly);
      if GetAsyncStatus <> ecOK then
        Exit;
      if ReadOnly = False then
        SetFlushMode(IData, AlwaysRW);
      DictionaryHead := nil;
      DictionaryTail := nil;
      NumRecords     := 0;
      RecordSize     := 0;
      DefaultRecord  := nil;
      Prepared       := False;
    end;
  end;

  procedure DoneIniDatabase(D : IniDataBaseRecPtr);
    {-Destroy an .INI file database}
  var
    Temp : IniDataBaseKeyPtr;

  begin
    with D^ do begin
      while (DictionaryHead <> nil) do begin
        Temp := DictionaryHead^.Next;
        FreeMemCheck(DictionaryHead, SizeOf(IniDataBaseKey));
        DictionaryHead := Temp;
      end;
      FreeMemCheck(DefaultRecord, RecordSize);
    DoneIniMgr(IData);
    end;
    FreeMemCheck(D, SizeOf(IniDataBaseRec));
  end;

  procedure iAddIniKeyPrim(D : IniDataBaseRecPtr;
                           AKeyName  : String;
                           AStrType  : Boolean;
                           AIndex    : Boolean;
                           ADataSize : Word );
    {-Add an .INI key with these attributes to the dictionary}
  var
    NewKey : IniDataBaseKeyPtr;

  begin
    if (LongInt(D^.RecordSize + ADataSize) > $FFF0) then begin
      SetAsyncStatus(ecDataTooLarge);
      Exit;
    end;

    if AIndex and (Pred(ADataSize) > MaxIndexLen) then begin
      SetAsyncStatus(ecIndexDataTooLarge);
      Exit;
    end;

    if (Length(AKeyName) > MaxNameLen) then begin
      SetAsyncStatus(ecKeyTooLong);
      Exit;
    end;

    if not GetMemCheck(NewKey, SizeOf(IniDataBaseKey)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    NewKey^.KeyName := AKeyName;

    with NewKey^ do begin
      DataSize := ADataSize;
      StrType  := AStrType;
      Index    := AIndex;
      Next     := nil;

      with D^ do begin
        if (DictionaryHead = nil) then begin
          DictionaryHead := NewKey;
          DictionaryTail := NewKey;
        end else begin
          DictionaryTail^.Next := NewKey;
          DictionaryTail       := NewKey;
        end;

        Inc(RecordSize, DataSize);
      end;
    end;

    SetAsyncStatus(ecOK);
  end;

  procedure AddIniDBStringField(D : IniDataBaseRecPtr; FieldName : String;
                                MaxLen : Word; Index : Boolean);
    {-Add a String field to the .INI file database}
  begin
    iAddIniKeyPrim(D, FieldName, True, Index, MaxLen + 1);
  end;

  procedure AddIniDBIntField(D : IniDataBaseRecPtr; FieldName : String);
    {-Add an integer field to the .INI file database}
  begin
    iAddIniKeyPrim(D, FieldName, False, False, SizeOf(Integer));
  end;

  function iIniIndexKey(D : IniDataBaseRecPtr) : IniDataBaseKeyPtr;
    {-Return a pointer to the indexed key}
  var
    CurItem : IniDataBaseKeyPtr;

  begin
    CurItem := D^.DictionaryHead;
    while (CurItem <> nil) do begin
      if CurItem^.Index then begin
        iIniIndexKey := CurItem;
        Exit;
      end;
      CurItem := CurItem^.Next;
    end;
    iIniIndexKey := nil;
  end;

  procedure PrepareIniDatabase(D : IniDataBaseRecPtr; Defaults : Pointer);
    {-Prepare the databse for reading/writing}
  var
    CurItem : IniDataBaseKeyPtr;
    TempRec : Pointer;
    TempStr : String;

  begin
    {if there are no items defined, it's an error}
    if (D^.DictionaryHead = nil) then begin
      SetAsyncStatus(ecNoFieldsDefined);
      Exit;
    end;

    if (iIniIndexKey(D) = nil) then begin
      SetAsyncStatus(ecNoIndexKey);
      Exit;
    end;

    {allocate the default data record}
    with D^, IData^ do begin
      if not GetMemCheck(DefaultRecord, RecordSize) then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
      FillChar(DefaultRecord^, RecordSize, 0);

      {if the .INI file doesn't exist, create a default one}
      if not ExistFile(IniName) then begin
        {create the index section}
        SetProfileString(IData, dbBogus, dbIndex, dbBogus);
        if GetAsyncStatus <> ecOK then begin
          FreeMemCheck(DefaultRecord, RecordSize);
          Exit;
        end;
        DeleteProfileString(IData, dbBogus, dbIndex);
        if GetAsyncStatus <> ecOK then begin
          FreeMemCheck(DefaultRecord, RecordSize);
          Exit;
        end;
        {create the defaults section}
        SetProfileString(IData, dbNumEntries, dbDefaultTitle, Long2Str(NumRecords));
        if GetAsyncStatus <> ecOK then begin
          FreeMemCheck(DefaultRecord, RecordSize);
          Exit;
        end;

        if (Defaults <> nil) then begin
          Prepared := True;
          ChangeIniDefaults(D, Defaults^);
          if (GetAsyncStatus <> ecOK) then begin
            Prepared := False;
            FreeMemCheck(DefaultRecord, RecordSize);
            Exit;
          end;
        end;

        NumRecords := 0;
        {since we've created only a default file, we don't need to save it
         if no changes are made after it.}
        NeedUpd := False;

      end else begin
        {load the number of database entries}
        NumRecords := GetProfileInt(IData, dbNumEntries, dbDefaultTitle, 0);

        {load the default record}
        TempRec := DefaultRecord;
        CurItem := DictionaryHead;
        while (CurItem <> nil) do begin
          if not CurItem^.Index then
            if CurItem^.StrType then begin
              TempStr := GetProfileString(IData, CurItem^.KeyName,
                                          dbDefaultTitle, '');
              Move(TempStr[0], TempRec^, Length(TempStr) + 1);
            end else
              Integer(TempRec^) := GetProfileInt(IData, CurItem^.KeyName,
                                                 dbDefaultTitle, 0);
          TempRec := AddWordToPtr(TempRec, CurItem^.DataSize);
          CurItem := CurItem^.Next;
        end;
      end;

      Prepared := True;
    end;
    SetAsyncStatus(ecOK);
  end;

  procedure ChangeIniDefaults(D : IniDataBaseRecPtr; var DefaultRec);
    {-Change the default values for record fields}
  var
    CurItem : IniDataBaseKeyPtr;
    TempRec : Pointer;
    TempInt : Integer;
    TempStr : String;

  begin
    with D^ do begin
    {if there are no items defined, it's an error}
      if (DictionaryHead = nil) then begin
        SetAsyncStatus(ecNoFieldsDefined);
        Exit;
      end;

      if not Prepared then begin
        SetAsyncStatus(ecDatabaseNotPrepared);
        Exit;
      end;

      Move(DefaultRec, DefaultRecord^, RecordSize);

      TempRec := DefaultRecord;
      CurItem := DictionaryHead;
      while (CurItem <> nil) do begin
        if not CurItem^.Index then
          if CurItem^.StrType then begin
            Move(TempRec^, TempStr, CurItem^.DataSize);
            SetProfileString(IData, CurItem^.KeyName, dbDefaultTitle, TempStr);
            if GetAsyncStatus <> ecOK then
              Exit;
          end else begin
            Move(TempRec^, TempInt, CurItem^.DataSize);
            SetProfileString(IData, CurItem^.KeyName, dbDefaultTitle,
                             Long2Str(TempInt));
            if GetAsyncStatus <> ecOK then
              Exit;
          end;
          TempRec := AddWordToPtr(TempRec, CurItem^.DataSize);
          CurItem := CurItem^.Next;
      end;
    end;
    SetAsyncStatus(ecOK);
  end;

  function KeyExists(D : IniDataBaseRecPtr; Key : String) : Boolean;
    {-Return TRUE if an entry with an index of 'Name' exists}
  var
    Temp : String[5];

  begin
    with D^ do begin
      if not Prepared then begin
        KeyExists := False;
        Exit;
      end;

      Temp := GetProfileString(IData, Key, dbIndex, '');
      KeyExists := (Temp =  NonValue);
    end;
  end;

  function iGetIniDataString(D : IniDataBaseRecPtr; var Rec;
                             Key : IniDataBaseKeyPtr) : String;
    {-Get a String from an INI data record}
  var
    CurItem : IniDataBaseKeyPtr;
    TempRec : Pointer;
    TempStr : String;

  begin
    CurItem := D^.DictionaryHead;
    TempRec := @Rec;
    while (CurItem <> nil) and (CurItem <> Key) do begin
      TempRec := AddWordToPtr(TempRec, CurItem^.DataSize);
      CurItem := CurItem^.Next;
    end;
    if (CurItem = Key) then begin
      Move(TempRec^, TempStr, CurItem^.DataSize);
      iGetIniDataString := TempStr;
    end else
      iGetIniDataString := '';
  end;

  procedure iUpdateIniRecCount(D : IniDataBaseRecPtr);
    {-Update the NumEntries field in the .INI file}
  var
    Temp : String[5];

  begin
    with D^ do begin
      Temp := Long2Str(NumRecords);
      SetProfileString(IData, dbNumEntries, dbDefaultTitle, Temp);
    end;
  end;

  procedure iPutIniString(D : IniDataBaseRecPtr; Name, Key, Str : String);
    {-Put a String to the .INI file}
  var
    TempStr : String[Length(NonValue)];

  begin
    SetAsyncStatus(ecOK);
    with D^ do begin
      {if the String is intentionally left blank, exit}
      if (Str = '') then begin
        TempStr := GetProfileString(IData, Key, Name, '');
        if (TempStr = NonValue) then
          Exit;
      end;

      {if the String <> '', write it out}
      if (Str <> '') then
        SetProfileString(IData, Key, Name, Str)
      else
        {if the String = '', delete its database entry}
        DeleteProfileString(IData, Key, Name);
    end;
  end;

  procedure iSaveIniRecord(D : IniDataBaseRecPtr; SecName : String; var Rec;
                           WriteIni : Boolean);
    {-Save an INI record to the database}
  var
    CurItem : IniDataBaseKeyPtr;
    TempRec : Pointer;
    Temp    : String[5];
    TempStr : String;

  begin
    {if there are no items defined, it's an error}
    if (D^.DictionaryHead = nil) then begin
      SetAsyncStatus(ecNoFieldsDefined);
      Exit;
    end;

    if not D^.Prepared then begin
      SetAsyncStatus(ecDatabaseNotPrepared);
      Exit;
    end;

    CurItem := D^.DictionaryHead;
    TempRec := @Rec;
    while (CurItem <> nil) do begin
      if not CurItem^.Index then begin
        if CurItem^.StrType then
          Move(TempRec^, TempStr, CurItem^.DataSize)
        else begin
          Move(TempRec^, TempStr, CurItem^.DataSize);
          TempStr := Long2Str(Integer(TempRec^));
        end;
        if TempStr <> '' then begin
          iPutIniString(D, SecName, CurItem^.KeyName, TempStr);
          if GetAsyncStatus <> ecOK then
            Exit;
        end;
      end else
        if WriteIni then begin
          Move(TempRec^, TempStr, CurItem^.DataSize);
          iPutIniString(D, SecName, CurItem^.KeyName, TempStr);
          if GetAsyncStatus <> ecOK then
            Exit;
        end;

      TempRec := AddWordToPtr(TempRec, CurItem^.DataSize);
      CurItem := CurItem^.Next;
    end;

    SetAsyncStatus(ecOK);
  end;


  procedure AddIniRecord(D : IniDataBaseRecPtr; var Rec);
    {-Add a record to the database}
  var
    IndexKey  : IniDataBaseKeyPtr;
    IndexName : String;

  begin
    with D^ do begin
      {if there are no items defined, it's an error}
      if (DictionaryHead = nil) then begin
        SetAsyncStatus(ecNoFieldsDefined);
        Exit;
      end;

      if not Prepared then begin
        SetAsyncStatus(ecDatabaseNotPrepared);
        Exit;
      end;

      if (NumRecords = MaxDBRecs) then begin
        SetAsyncStatus(ecDatabaseFull);
        Exit;
      end;
    end;

    IndexKey  := iIniIndexKey(D);
    IndexName := iGetIniDataString(D, Rec, IndexKey);

    if KeyExists(D, IndexName) then begin
      SetAsyncStatus(ecRecordExists);
      Exit;
    end;

    {add the entry to the index}
    SetProfileString(D^.IData, IndexName, dbIndex, NonValue);
    if GetAsyncStatus <> ecOK then
      Exit;

    iSaveIniRecord(D, IndexName, Rec, False);
    if (GetAsyncStatus <> ecOK) then
      Exit;

    Inc(D^.NumRecords);
    iUpdateIniRecCount(D);
  end;

  procedure UpdIniRecord(D : IniDataBaseRecPtr; Key : String; var Rec);
    {-Update a record in the database}
  var
    IndexKey  : IniDataBaseKeyPtr;
    IndexName : String;

  begin
    {if there are no items defined, it's an error}
    if (D^.DictionaryHead = nil) then begin
      SetAsyncStatus(ecNoFieldsDefined);
      Exit;
    end;

    if not D^.Prepared then begin
      SetAsyncStatus(ecDatabaseNotPrepared);
      Exit;
    end;

    IndexKey  := iIniIndexKey(D);
    IndexName := iGetIniDataString(D, Rec, IndexKey);

    if not KeyExists(D, Key) then begin
      SetAsyncStatus(ecRecordNotFound);
      Exit;
    end;

    if StUpCase(Key) <> StUpCase(IndexName) then begin
      {if the name has changed, first delete the old entry}
      DelIniRecord(D, Key);
      if (GetAsyncStatus <> ecOK) then
        Exit;

      {add a new entry}
      AddIniRecord(D, Rec);
    end else
      iSaveIniRecord(D, Key, Rec, False);
  end;

  procedure DelIniRecord(D : IniDataBaseRecPtr; Key : String);
    {-Remove a record from the database}
  begin
    {if there are no items defined, it's an error}
    if (D^.DictionaryHead = nil) then begin
      SetAsyncStatus(ecNoFieldsDefined);
      Exit;
    end;

    if not D^.Prepared then begin
      SetAsyncStatus(ecDatabaseNotPrepared);
      Exit;
    end;

    if not KeyExists(D, Key) then begin
      SetAsyncStatus(ecRecordNotFound);
      Exit;
    end;

    {delete the index entry}
    DeleteProfileString(D^.IData, Key, dbIndex);
    if GetAsyncStatus <> ecOK then
      Exit;

    {delete the record}
    DeleteProfileGroup(D^.IData, Key);
    if GetAsyncStatus <> ecOK then
      Exit;

    {update the record count}
    Dec(D^.NumRecords);
    iUpdateIniRecCount(D);
  end;

  procedure iRetrieveIniRecord(D : IniDataBaseRecPtr; SecName : String; var Rec;
                               ReadIni : Boolean);
    {-Get a record from the database}
  var
    TempRec : Pointer;
    DefRec  : Pointer;
    CurItem : IniDataBaseKeyPtr;
    DefInt  : Integer;
    TempStr : String;
    DefStr  : String;

  begin
    with D^ do begin
      {if there are no items defined, it's an error}
      if (DictionaryHead = nil) then begin
        SetAsyncStatus(ecNoFieldsDefined);
        Exit;
      end;

      if not Prepared then begin
        SetAsyncStatus(ecDatabaseNotPrepared);
        Exit;
      end;

      if not KeyExists(D, SecName) then begin
        SetAsyncStatus(ecRecordNotFound);
        Exit;
      end;

      TempRec := @Rec;
      DefRec  := DefaultRecord;

      CurItem := DictionaryHead;
      while (CurItem <> nil) do begin
        if CurItem^.StrType then
          if CurItem^.Index then
            if ReadIni then
              TempStr := GetProfileString(IData, CurItem^.KeyName, SecName, '')
            else
              Move(SecName[0], TempRec^, Length(SecName) + 1)
          else begin
            Move(DefRec^, DefStr, CurItem^.DataSize);
            TempStr := GetProfileString(IData, CurItem^.KeyName, SecName, DefStr);
            Move(TempStr, TempRec^, Length(TempStr) + 1);
            if TempStr = NonValue then
              PChar(TempRec)[0] := #0;
          end
        else begin
          Move(DefRec^, DefInt, CurItem^.DataSize);
          Integer(TempRec^) := GetProfileInt(IData, CurItem^.KeyName, SecName, DefInt);
        end;
        TempRec := AddWordToPtr(TempRec, CurItem^.DataSize);
        DefRec  := AddWordToPtr(DefRec, CurItem^.DataSize);
        CurItem := CurItem^.Next;
      end;
    end;
    SetAsyncStatus(ecOK);
  end;

  procedure GetIniRecord(D : IniDataBaseRecPtr; Key : String; var Rec);

  begin
    iRetrieveIniRecord(D, Key, Rec, False);
  end;

  function NumIniRecs(D : IniDataBaseRecPtr) : Integer;
    {-Return the number of records in an INI database}
  begin
    NumIniRecs := D^.NumRecords;
  end;

  procedure WriteToIni(D : IniDataBaseRecPtr; var Rec; Group, IniFile : String);
    {-Write the record to a user-specified .INI file}
  var
    DestIni : IniDataBaseRecPtr;

  begin
    with D^ do begin
      {if there are no items defined, it's an error}
      if (DictionaryHead = nil) then begin
        SetAsyncStatus(ecNoFieldsDefined);
        Exit;
      end;

      if not Prepared then begin
        SetAsyncStatus(ecDatabaseNotPrepared);
        Exit;
      end;

      InitIniDataBase(DestIni, IniFile, False, True);
      if DestIni = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;

      DestIni^.DictionaryHead := DictionaryHead;
      DestIni^.DictionaryTail := DictionaryTail;


      PrepareIniDataBase(DestIni, DefaultRecord);
      if GetAsyncStatus <> ecOK then
        Exit;
    end;

    iSaveIniRecord(DestIni, Group, Rec, True);

    DoneIniDataBase(DestIni);
  end;

  procedure ReadFromIni(D : IniDataBaseRecPtr; var Rec; Group, IniFile : String);
    {-Read the record from a user-specified .INI file}
  var
    SourceIni : IniDataBaseRecPtr;

  begin
    with D^ do begin
      {if there are no items defined, it's an error}
      if (DictionaryHead = nil) then begin
        SetAsyncStatus(ecNoFieldsDefined);
        Exit;
      end;

      if not Prepared then begin
        SetAsyncStatus(ecDatabaseNotPrepared);
        Exit;
      end;

      InitIniDataBase(SourceIni, IniFile, False, True);
      if SourceIni = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;

      SourceIni^.DictionaryHead := DictionaryHead;
      SourceIni^.DictionaryTail := DictionaryTail;


      PrepareIniDataBase(SourceIni, DefaultRecord);
      if GetAsyncStatus <> ecOK then
        Exit;
    end;

    iRetrieveIniRecord(SourceIni, Group, Rec, True);

    DoneIniDataBase(SourceIni);
  end;

  procedure FlushIniDBFile(D : IniDataBaseRecPtr);
    {-Write an INI database to disk}
  begin
    FlushFile(D^.IData);
  end;

  procedure SetIniDBFileName(D : IniDataBaseRecPtr; NewName : String);
  begin
  end;
end.
