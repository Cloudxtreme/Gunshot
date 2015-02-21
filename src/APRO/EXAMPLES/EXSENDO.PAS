program ExSendO;  {EXSENDO.PAS}
uses
  Dos, Crt, ApMisc, ApPort, ApUart, OoCom, OoAbsFax, OoFax12;
var
  Sender : C12SendFaxPtr;
  ComPort  : UartPortPtr;
  Class1, Class2 : Boolean;

{$F+}
function FaxAbort : Boolean;
begin
  if KeyPressed then
    FaxAbort := ReadKey = #27
  else
    FaxAbort := False;
end;

procedure FaxStatus(FP : AbstractFaxPtr; Starting, Ending : Boolean);
begin
  Write(^M'Transmit status: ', AsyncStatus mod 10000);
  ClrEol;
end;
{$F-}

begin
  ComPort := New(UartPortPtr, InitCustom(Com3, 19200, NoParity, 8, 1,
                                       8192, 8192, DefPortOptions));
  Sender := New(C12SendFaxPtr, Init('EXSENDO', ComPort));
  if (ComPort = nil) or (Sender = nil) then begin
    WriteLn('Unable to create port or fax, status: ', AsyncStatus);
    Halt;
  end;
  ComPort^.HWFlowEnable(0, 0, hfRequireCTS);

  ComPort^.SetAbortFunc(FaxAbort);
  Sender^.SetFaxStatusProc(FaxStatus);

  if Sender^.GetModemClassSupport(Class1, Class2, True) then begin
    if not Class1 and not Class2 then begin
      WriteLn('Not a class 1 or class 2 modem');
      Halt;
    end;
  end else begin
    WriteLn('Failed to identify modem, status: ', AsyncStatus);
    Halt;
  end;

  Sender^.AddFaxEntry('260-7151', 'read.APF', '');
  Sender^.FaxTransmit;
  WriteLn(^M^J'Results of fax send: ', AsyncStatus);

  Dispose(Sender, Done);
  Dispose(ComPort, Done);
end.
