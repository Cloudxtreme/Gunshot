program ExTerm;   {EXTERM.PAS}
  {-A simple terminal}
uses
  Crt, ApMisc, ApPort, ApUart, ApCom;
var
  P : PortRecPtr;
  C : Char;
  Finished : Boolean;
  S : String;
  Len  : Word;

begin
  {Open a port}
  InitPort(P, Com2, 2400, NoParity, 8, 1, 5000, 5000, DefPortOptions);
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
      if C = #0 then begin
        C := ReadKey;
        Finished := C = #$2D
      end else begin
        while not TransReady(P) do ;
        PutChar(P, C);
      end;
    end;

    {Process chars received}
    if CharReady(P) then begin
      GetChar(P, C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'LineError ', AsyncStatus);
        FlushInBuffer(P);
      end else
        Write(C);
    end;
  until Finished;
  DonePort(P);
end.
