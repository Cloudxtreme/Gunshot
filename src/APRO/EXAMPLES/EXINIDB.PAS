{$I APDEFINE.INC}
program ExIniDB; {EXINIDB.PAS}

uses
{$IFDEF UsePModeDLL}
  ApComD;
{$ELSE}
  ApIni,
  ApIniDB,
  ApMisc;
{$ENDIF}

type
  TempRecType = record
    Name : String[21];
    Age : Integer;
    FavColor : String[15];
  end;

var
  DB : IniDataBaseRecPtr;
  TempRec, DefRec : TempRecType;

procedure ErrorChk(S : String);
begin
  if GetAsyncStatus <> ecOK then begin
    Writeln(S, ': ',StatusStr(GetAsyncStatus));
    Halt;
  end;
end;

begin
  InitIniDataBase(DB, 'MYINI.INI', False, False);
  ErrorChk('Error initializing database');

  AddIniDBStringField(DB, 'Name', 21, True);
  ErrorChk('Error creating name field');
  AddIniDBIntField(DB, 'Age');
  ErrorChk('Error creating age field');
  AddIniDBStringField(DB, 'FavColor', 15, False);
  ErrorChk('Error creating favorite color field');
  PrepareIniDataBase(DB, nil);
  ErrorChk('Error preparing database');

  with TempRec do begin
    Name := 'Joe Schmo';
    Age := 18;
    FavColor := 'ebony';
  end;

  AddIniRecord(DB, TempRec);
  ErrorChk('Failed to add record');

  GetIniRecord(DB, 'Jason Leveille', TempRec);
  ErrorChk('Failed to get record');

  Writeln;
  Writeln('Record information : ');
  with TempRec do begin
    Writeln(Name);
    Writeln(Age);
    Writeln(FavColor);
  end;

  FlushIniDBFile(DB);
  DoneIniDataBase(DB);
end.
