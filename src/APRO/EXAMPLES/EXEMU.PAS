{$I APDEFINE.INC}
program ExEmu;  {EXEMU.PAS}
  {-A simple ANSI terminal}
uses
  {$IFDEF UseOpro} OpCrt, {$ENDIF}
  {$IFDEF UseTpro} TpCrt, {$ENDIF}
  {$IFDEF Standalone} Crt, {$ENDIF}
  ApMisc, ApPort, ApUart, OoCom, OoEmu;
var
  UP : UartPort;
  AE : AnsiEmulator;
  CR : CommandRecord;
  C : Char;
  Finished : Boolean;
begin
  {Open a port}
  UP.InitCustom(Com1, 2400, NoParity, 8, 1, 500, 500, DefPortOptions);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to open port: ', AsyncStatus);
    Halt;
  end;

  {Instantiate an emulator}
  AE.Init(32);

  {Simple terminal -- quit on <Alt>X}
  Finished := False;
  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then
        Finished := ReadKey = #$2D
      else if UP.TransReady then
        UP.PutChar(C);
    end;

    {Process chars received}
    if UP.CharReady then begin
      UP.GetChar(C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'Line error ', AsyncStatus);
        UP.FlushInBuffer;
      end else begin
        AE.ProcessChar(C, CR);
        case CR.Cmd of
          eNone        : {do nothing};
          eChar        : Write(CR.Ch);
          eClearScreen : ClrScr;
          eGotoXY      : GotoXY(CR.X, CR.Y);
          {... handle other commands ...}
        end;
      end;
    end;
  until Finished;
  UP.Done;
  AE.Done;
end.

