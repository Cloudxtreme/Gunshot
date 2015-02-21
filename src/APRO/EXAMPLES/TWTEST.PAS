program TWTest; {TWTEST.PAS}
uses
  OpRoot, ApMisc, ApPort, OoCom, OoModem, OoEmu,
  OpCrt, OpCmd, OpWindow, TermWin;
var
  UP : UartPort;
  HM : HayesModem;
  TW : TerminalWindow;
  AE : AnsiEmulator;
  Finished : Boolean;
begin
  {check for number to dial}
  if ParamCount = 0 then begin
    WriteLn('Usage: TWTEST nnn-nnnn');
    Halt;
  end;

  {open port}
  if not UP.InitFast(Com1, 1200) then begin
    WriteLn('Failed to initialize port: ', AsyncStatus);
    Halt(1);
  end;

  {instantiate a modem object}
  if not HM.Init(@UP) then begin
    WriteLn('Failed to initialize modem: ', AsyncStatus);
    Halt(1);
  end;

  {initialize terminal window}
  if not TW.Init(1, 1, ScreenWidth, ScreenHeight, @UP) then begin
    WriteLn('Failed to initialize terminal window: ', InitStatus);
    Halt(1);
  end;

  {allow <AltX> to be used to exit from program, as well as <AltF3>}
  TerminalCommands.AddCommand(ccQuit, 1, $2D00, 0);

  {initialize emulator and attach to terminal window}
  if not AE.Init(32) then begin
    WriteLn('Failed to initialize terminal emulator: ', AsyncStatus);
    Halt(1);
  end;
  TW.SetTerminalWinEmulator(@AE);

  {dial the number}
  Write('Dialing ', ParamStr(1), '...');
  HM.DialModem( ParamStr(1) );
  if AsyncStatus <> ecConnect then begin
    WriteLn(^M^J'Call could not be established');
    Halt;
  end;

  {get rid of the "Dialing..." message}
  Write(^M);
  ClrEol;

  {process commands}
  Finished := False;
  repeat
    TW.Process;
    case TW.GetLastCommand of
      ccQuit, ccError : Finished := True;
    end;
  until Finished;

  {hang up modem}
  HM.HangupModem(mOnHook, False);

  {destroy objects}
  TW.Done;
  HM.Done;
  AE.Done;
  UP.Done;
end.
