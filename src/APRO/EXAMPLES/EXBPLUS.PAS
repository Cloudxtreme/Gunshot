program ExBPlus;   {EXBPLUS.PAS}
uses
  Crt, ApMisc, ApPort, ApUart, ApCom, ApAbsPcl, ApBPlus;

var
  UP : PortRecPtr;
  BP : ProtocolRecPtr;
  Finished : Boolean;
  C : Char;
  Start : Boolean;
  Upload : Boolean;
  Index : Byte;

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

  procedure ShowStatus(AP : ProtocolRecPtr; Starting, Ending : Boolean); far;
  begin
    WriteLn('BPLUS: ', GetFilename(BP), ' ',
                       GetBytesTransferred(BP), '/',
                       GetBytesRemaining(BP));
  end;


begin
  {Open port}
  InitPort(UP, Com2, 19200, NoParity, 8, 1, 2078, 8192, DefPortOptions);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to initialize port: ', AsyncStatus);
    Halt(1);
  end;
  SetAbortFunc(UP, KbdAbort);

  {Init the B+ protocol}
  InitBPlus(BP, UP);
  SetShowStatusProc(BP, ShowStatus);

  {Simple terminal}
  Index := 0;
  Finished := False;
  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then begin
        C := ReadKey;
        Finished := C = #$2D
      end else begin
        while not TransReady(UP) do ;
        PutChar(UP, C);
      end;
    end;

    {Process chars received}
    if CharReady(UP) then begin
      GetChar(UP, C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'LineError ', AsyncStatus);
        FlushInBuffer(UP);
      end else begin
        case C of
          cENQ : ProcessEnq(BP);
          cDLE : begin
                   ProcessDLE(BP, Start, Upload);
                   if Start then begin
                     if Upload then
                       ProtocolTransmitBP(BP)
                     else
                       ProtocolReceiveBP(BP);
                   end;
                 end;
          else begin
            Write(C);
            if CheckForString(Index, C, cESC+'I', False) then
              ProcessESCI(BP, 80, 25);
          end;
        end;
      end;
    end;
  until Finished;
  DoneBPlus(BP);
  DonePort(UP);
end.
