program ExTerm1;   {EXTERM1.PAS}
uses
  Crt, ApMisc, ApPort, ApUart;
var
  P : PortRecPtr;
  C : Char;
begin
  {Open a port}
  InitPort(P, Com3, 2400, NoParity, 8, 1, 5000, 5000, DefPortOptions);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to open port: ', AsyncStatus);
    Halt;
  end;

  Delay(100);
  PutChar(P, 'A');
  PutChar(P, 'T');
  PutChar(P, 'Z');
  PutChar(P, cCR);
  Delay(2000);

  while CharReady(P) do begin
    GetChar(P, C);
    Write(C);
  end;

  DonePort(P);
end.
