program ExAnsi;   {EXANSI.PAS}
  {-A simple ANSI terminal}
uses
  Crt, ApMisc, ApPort, ApUart, ApCom, ApAnsi;
var
  P : PortRecPtr;
  C : Char;
  Finished : Boolean;
begin
  {Open a port}
  InitPort(P, Com3, 2400, NoParity, 8, 1, 5000, 5000, DefPortOptions);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to open port: ', AsyncStatus);
    Halt;
  end;

  {Simple terminal}
  Finished := False;
  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then
        Finished := ReadKey = #$2D
      else if TransReady(P) then
        PutChar(P, C);
    end;

    {Process chars received}
    if CharReady(P) then begin
      GetChar(P, C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'LineError ', AsyncStatus);
        FlushInBuffer(P);
      end else
        WriteCharAnsi(C);
    end;
  until Finished;
  DonePort(P);
end.
