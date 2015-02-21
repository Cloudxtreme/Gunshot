{$I APDEFINE.INC}
program ExModDB; {EXMODDB.PAS}

uses
{$IFDEF UsePModeDLL}
  ApComD;
{$ELSE}
  ApIni,
  ApIniDB,
  ApModDB,
  ApMisc;
{$ENDIF}

var
  DB : ModemDBaseRecPtr;
  TempModem : ModemData;

procedure ErrorChk(S : string);
begin
  if GetAsyncStatus <> ecOK then begin
    Writeln(S, ': ',GetAsyncStatus);
    Halt;
  end;
end;

begin
  InitModemDB(DB, 'AWMODEM.INI', False, False);
  ErrorChk('Error initializing modem database');

  RetrieveModem(DB, 'GVC 9600 V.42', TempModem);
  ErrorChk('Error retrieving modem from database');
  Writeln('The dial command for the ', TempModem.Data.Name, ' is ',
          TempModem.Data.DialCmd);

  TempModem.Data.Name := 'GVC 9600 V.42 Copy';
  AddModem(DB, TempModem);
  ErrorChk('Error adding modem copy');

  FlushModDBFile(DB);
  DoneModemDB(DB);
end.
