program ExSend;  {EXSEND.PAS}
uses
  Dos, Crt, ApMisc, ApPort, ApUart, ApCom, ApFaxCvt, ApAbsFax, ApFax12;
var
  Sender : FaxRecPtr;
  ComPort  : PortRecPtr;
  Class1, Class2 : Boolean;

{$F+}
function FaxAbort : Boolean;
begin
  if KeyPressed then
    FaxAbort := ReadKey = #27
  else
    FaxAbort := False;
end;

procedure FaxStatus(FP : FaxRecPtr; Starting, Ending : Boolean);
begin
  Write(^M'Transmit status: ', AsyncStatus mod 10000);
  ClrEol;
end;
{$F-}

begin
  InitPort(ComPort, Com3, 19200, NoParity, 8, 1,
           8192, 8192, DefPortOptions);
  InitC12SendFax(Sender, 'EXSEND', ComPort);
  if (ComPort = nil) or (Sender = nil) then begin
    WriteLn('Unable to create port or fax, status: ', AsyncStatus);
    Halt;
  end;
  HWFlowEnable(ComPort, 0, 0, hfRequireCTS);

  SetAbortFunc(ComPort, FaxAbort);
  SetFaxStatusProc(Sender, FaxStatus);

  if GetModemClassSupport(Sender, Class1, Class2, True) then begin
    if not Class1 and not Class2 then begin
      WriteLn('Not a class 1 or class 2 modem');
      Halt;
    end;
  end else begin
    WriteLn('Failed to identify modem, status: ', AsyncStatus);
    Halt;
  end;

  AddFaxEntry(Sender, '260-7151', 'EXCVT.APF', '');
  FaxTransmitC12(Sender);
  WriteLn(^M^J'Results of fax send: ', AsyncStatus);

  DoneC12SendFax(Sender);
  DonePort(ComPort);
end.

