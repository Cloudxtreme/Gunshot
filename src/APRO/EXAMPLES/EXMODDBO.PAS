{$I APDEFINE.INC}
program ExModDBO; {EXMODDBO.PAS}

uses
  OoIni,
  OoIniDB,
  OoModDB,
  ApMisc;

var
  DB : ModemDBasePtr;
  TempModem : ModemData;

procedure ErrorChk(S : string);
begin
  if AsyncStatus <> ecOK then begin
    Writeln(S, ': ',AsyncStatus);
    Halt;
  end;
end;

begin
  New(DB, Init('AWMODEM.INI', False, False));
  if DB = nil then begin
    Writeln('Error initializing modem database : ', AsyncStatus);
    Halt;
  end;

  DB^.RetrieveModem('GVC 9600 V.42', TempModem);
  ErrorChk('Error retrieving modem from database');
  Writeln('The dial command for the ', TempModem.Data.Name, ' is ',
          TempModem.Data.DialCmd);

  TempModem.Data.Name := 'GVC 9600 V.42 Copy';
  DB^.AddModem(TempModem);
  ErrorChk('Error adding modem copy');

  DB^.FlushFile;
  Dispose(DB, Done);
end.
