program ExTerm1;     {EXTERM1.PAS}
  {-A simple oop terminal}
uses
  Crt, ApMisc, ApPort, ApUart, OoCom;
var
  UP : UartPort;
  C : Char;
  Finished : Boolean;
begin
  {Open a port}
  PS2DetectMode := PS2Ignore;
  SetUart(Com3, $3E8, 5, 5+8);
  UP.InitCustom(Com3, 2400, NoParity, 8, 1, 500, 500, DefPortOptions);
  if AsyncStatus <> ecOk then begin
    WriteLn('Failed to open port: ', AsyncStatus);
    Halt;
  end;

  {Simple terminal -- quit on <Alt>X}
  Finished := False;
  repeat
    {Process chars to send}
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then
        Finished := ReadKey = #$2D
      else begin
        while not UP.TransReady do ;
        UP.PutChar(C);
      end;
    end;

    {Process chars received}
    if UP.CharReady then begin
      UP.GetChar(C);
      if AsyncStatus <> ecOk then begin
        WriteLn(^M^J'Line error ', AsyncStatus);
        UP.FlushInBuffer;
      end else
        Write(C);
    end;
  until Finished;
  UP.Done;
end.
