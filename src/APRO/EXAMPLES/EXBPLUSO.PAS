program EXBPlusO;  {EXBPLUSO.PAS}
uses
  OpRoot, ApMisc, ApPort, OoCom, OoModem, OoEmu,
  OpCrt, OpCmd, OpWindow, OoAbsPcl, OoBPlus, TermWin;

type
  BPlusTermWin = object(TerminalWindow)
    Started : Boolean;
    function StartBPlus : Boolean;
    procedure GetNextCommand; virtual;
  end;

var
  UP : UartPort;
  BP : BPlusProtocol;
  TW : BPlusTermWin;
  AE : AnsiEmulator;
  SW : StackWindow;
  Finished : Boolean;

  function KbdAbort : Boolean; far;
  const
    Escape = #$1B;
  var
    Ch : Char;
  begin
    KbdAbort := False;
    if KeyPressed then begin
      Ch := ReadKey;
      if Ch = #0 then
        Ch := ReadKey;
      if Ch = Escape then
        KbdAbort := True;
    end;
  end;

  procedure ShowStatus(AP : AbstractProtocolPtr;
                       Starting, Ending : Boolean); far;
  begin
    if Starting then begin
      SW.InitCustom(10, 10, 70, 16,
                    DefaultColorSet,
                    DefWindowOptions or wBordered);
      SW.Draw;
    end;

    with AP^ do
    WriteLn('BPLUS: ', GetFilename, ' ',
                       GetBytesTransferred, '/',
                       GetBytesRemaining);

    if Ending then begin
      SW.Erase;
      SW.Done;
    end;
  end;

  function BPlusTermWin.StartBPlus : Boolean;
    {-Start BPlus}
  begin
    if not Started then begin
      BP.Init(@UP);
      if AsyncStatus <> ecOk then begin                                {!!.01}
        WriteLn('Failed to instantiate the BPlus protocol object');    {!!.01}
        WriteLn('Do NOT attempt a B+ upload or download');             {!!.01}
        StartBPlus := False;
        Exit;                                                          {!!.01}
      end;                                                             {!!.01}
      BP.apOptionsOn(apBP2KTransmit);                                  {!!.01}
      BP.SetShowStatusProc(ShowStatus);
      Started := True;
    end;
    StartBPlus := True;
  end;

  procedure BPlusTermWin.GetNextCommand;
  const
    Index : Byte = 0;
  var
    C : Char;
    Start, IsUpload : Boolean;
  begin
    while not cwCmdPtr^.cpKeyPressed do
      if GetIncomingChar(C) then begin
        case C of
          cENQ : if StartBPlus then
                   BP.ProcessENQ;
          cDLE : if StartBPlus then begin
                   BP.ProcessDLE(Start, IsUpload);

                   if Start then begin
                     if IsUpload then
                       cwCmd := ccUser1
                     else
                       cwCmd := ccUser2;
                     Exit;
                   end;
                 end;
          else begin
            if CheckForString(Index, C, cEsc+'I', True) then begin
              BP.ProcessEscI(80, 25);
              AnsiEmulatorPtr(twEmulator)^.InitParser;
            end else begin
              cwCmd := ccIncomingChar;
              cwKey := Word(C);
              Exit;
            end;
          end;
        end;
      end;
    cwCmdPtr^.cpOptionsOn(cpCtrlsAreChars);
    TerminalWindow.GetNextCommand;
  end;

begin
  {Open port}
  if not UP.InitCustom(Com2, 19200, NoParity, 8, 1,                    {!!.01}
                       2078, 8192, DefPortOptions) then begin          {!!.01}
    WriteLn('Failed to initialize port: ', AsyncStatus);
    Halt(1);
  end;
  UP.SetAbortFunc(KbdAbort);

  {Initialize terminal window}
  if not TW.Init(1, 1, ScreenWidth, ScreenHeight, @UP) then begin
    WriteLn('Failed to initialize terminal window: ', InitStatus);
    Halt(1);
  end;

  {Allow <AltX> to be used to exit from program, as well as <AltF3>}
  TerminalCommands.AddCommand(ccQuit, 1, $2D00, 0);

  {Initialize emulator and attach to terminal window}
  if not AE.Init(32) then begin
    WriteLn('Failed to initialize terminal emulator: ', AsyncStatus);
    Halt(1);
  end;
  TW.SetTerminalWinEmulator(@AE);

  {Process commands}
  Finished := False;
  repeat
    TW.Process;
    case TW.GetLastCommand of
      ccUser1 : begin
                  BP.ProtocolTransmit;
                  {BP.Done;}                                           {!!.01}
                end;
      ccUser2 : begin
                  BP.ProtocolReceive;
                  {BP.Done;}                                           {!!.01}
                end;
      ccQuit, ccError : Finished := True;
    end;
  until Finished;
  writeln(tw.getlasterror);

  {Destroy objects}
  if TW.Started then                                                   {!!.01}
    BP.Done;                                                           {!!.01}
  TW.Done;
  AE.Done;
  UP.Done;
end.
