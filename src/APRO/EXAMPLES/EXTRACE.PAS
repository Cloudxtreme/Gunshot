{$I APDEFINE.INC}
{$IFNDEF Tracing}
  !! STOP COMPILE : This example program requires Tracing in APDEFINE.INC
{$ENDIF}

program ExTrace; {EXTRACE.PAS}
uses
  Crt, ApMisc, ApPort, ApUart, ApCom;
var
  P : PortRecPtr;
  ChIn, ChOut: Char;

  procedure Abort(Msg : String);
    {-Close port and halt}
  begin
    WriteLn(Msg, ': ', AsyncStatus);
    DumpTrace('TRACE.TRC');
    DonePort(P);
    Halt(1);
  end;

begin
  {Open a port}
  InitPort(P, Com2, 1200, NoParity, 8, 1, 500, 500, DefPortOptions);
  if AsyncStatus <> ecOk then
    Abort('Failed to open port');

  {Start event logging}
  InitTracing(500);
  if AsyncStatus <> ecOk then
    Abort('Failed to start event logging');

  WriteLn('Terminal ready. Press <Esc> or <^C> to Quit');
  WriteLn('Trace will be written to TRACE.TRC');

  {Simple terminal}
  ChOut := #0;
  repeat
    if KeyPressed then begin
      ChOut := ReadKey;
      if ChOut <> #0 then begin
        PutChar(P, ChOut);
        if AsyncStatus <> ecOk then
          Abort('Failed PutChar');
        if ChOut = ^M then
          WriteLn
        else if ChOut >= ' ' then
          Write(ChOut);
      end
      else case ReadKey of
        #$13 :               {AltR = Resume tracing}
          StartTracing;
        #$1E :               {AltA = Abort tracing}
          begin
            AbortTracing;
            Abort('Aborting');
          end;
        #$1F :               {AltS = Stop tracing}
          begin
            AddTraceEntry('S', ' ');
            StopTracing;
          end;
        #$2E :               {AltC = Clear trace buffer}
          ClearTracing;
      end;
    end;

    {Process chars received}
    if CharReady(P) then begin
      GetChar(P, ChIn);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'LineError');
        FlushInBuffer(P);
      end else
        Write(ChIn);
    end;
  until (ChOut = #27) or (ChOut = ^C);
  DumpTrace('TRACE.TRC');
  DonePort(P);
end.
