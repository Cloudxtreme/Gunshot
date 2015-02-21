{$I APDEFINE.INC}
program ExIniO; {EXINIO.PAS}

uses
  ApMisc,
  OoIni;

var
  I : IniMgrPtr;

procedure Error(S : string);

begin
  Writeln(S, ': ',AsyncStatus);
  Halt;
end;

begin
  New(I, Init('MYINI.INI', False));
  if I = nil then
    Error('Error initializing Ini database');
  I^.SetFlushMode(False);

  Writeln(I^.GetProfileInt('Age', 'Jason Leveille', 55));
  Writeln(I^.GetProfileString('FavColor', 'Bryan Slatner', 'No color'));

  I^.AddProfileString('Age', 'John Leier', '32');
  I^.SetProfileString('FavColor', 'Terry Hughes', 'turquoise');

  I^.DeleteProfileString('Age', 'Julian Bucknall');
  if AsyncStatus <> ecOK then
    Error('Error deleting age');
  I^.DeleteProfileGroup('Lee Inman');
  if AsyncStatus <> ecOK then
    Error('Error deleting group');

  I^.ChangeFileName('NEWINI.INI');
  I^.FlushFile;
  Dispose(I, Done);
end.