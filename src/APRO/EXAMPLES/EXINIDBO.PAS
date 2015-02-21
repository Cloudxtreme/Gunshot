{$I APDEFINE.INC}
program ExIniDBO; {EXINIDBO.PAS}

uses
  OoIni,
  OoIniDB,
  ApMisc;

type
  TempRecType = record
    Name : String[21];
    Age : Integer;
    FavColor : String[15];
  end;

var
  DB : IniDataBasePtr;
  TempRec, DefRec : TempRecType;

procedure ErrorChk(S : String);

begin
  if AsyncStatus <> ecOK then begin
    Writeln(S, ': ',StatusStr(AsyncStatus));
    Halt;
  end;
end;

begin
  New(DB, Init('MYINI.INI', False, False));
  if DB = nil then begin
    Writeln('Error initializing database : ', AsyncStatus);
    Halt;
  end;

  DB^.AddIniDBStringField('Name', 21, True);
  ErrorChk('Error creating name field');
  DB^.AddIniDBIntField('Age');
  ErrorChk('Error creating age field');
  DB^.AddIniDBStringField('FavColor', 15, False);
  ErrorChk('Error creating favorite color field');
  DB^.PrepareIniDataBase(nil);
  ErrorChk('Error preparing database');

  with TempRec do begin
    Name := 'Joe Schmo';
    Age := 18;
    FavColor := 'ebony';
  end;

  DB^.AddIniRecord(TempRec);
  ErrorChk('Failed to add record');

  DB^.GetIniRecord('Jason Leveille', TempRec);
  ErrorChk('Failed to get record');

  Writeln('Record information : ');
  with TempRec do begin
    Writeln(Name);
    Writeln(Age);
    Writeln(FavColor);
  end;

  DB^.FlushFile;
  Dispose(DB, Done);
end.
