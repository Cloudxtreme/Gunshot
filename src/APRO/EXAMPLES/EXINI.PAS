{$I APDEFINE.INC}
program ExIni; {EXINI.PAS}

uses
{$IFDEF UsePModeDLL}
  ApComD;
{$ELSE}
  ApMisc,
  ApIni;
{$ENDIF}

var
  I : IniMgrRecPtr;

procedure Error(S : string);

begin
  Writeln(S, ': ',GetAsyncStatus);
  Halt;
end;

begin
  InitIniMgr(I, 'MYINI.INI', False);
  if I = nil then
    Error('Error initializing Ini file record');
  SetFlushMode(I, False);

  Writeln(GetProfileInt(I, 'Age', 'Jason Leveille', 55));
  Writeln(GetProfileString(I, 'FavColor', 'Bryan Slatner', 'No color'));

  AddProfileString(I, 'Age', 'John Leier', '32');
  SetProfileString(I, 'FavColor', 'Terry Hughes', 'turquoise');

  DeleteProfileString(I, 'Age', 'Julian Bucknall');
  if GetAsyncStatus <> ecOK then
    Error('Error deleting age');
  DeleteProfileGroup(I, 'Lee Inman');
  if GetAsyncStatus <> ecOK then
    Error('Error deleting group');

  ChangeFileName(I, 'NEWINI.INI');
  FlushFile(I);
  DoneIniMgr(I);
end.