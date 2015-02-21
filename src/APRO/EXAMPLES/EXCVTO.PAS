program ExCvtO;  {EXCVTO.PAS}
uses
  Dos, Crt, ApMisc, OoFaxCvt;
var
  FCP : TextFaxConverterPtr;

{$F+}
function CvtStatusFunc(FCP : AbstractFaxConverterPtr;
                       Starting, Ending : Boolean) : Boolean;
var
  Line : LongInt;
  Page : Integer;
begin
  with FCP^ do begin
    GetStatusInfo(Line, Page);
    Write(^M'Processing line ', Line:4, ' of page ', Page:4);
    if KeyPressed then
      CvtStatusFunc := ReadKey = #27
    else
      CvtStatusFunc := False;
  end;
end;
{$F-}

begin
  FCP := New(TextFaxConverterPtr, Init);
  if FCP = nil then begin
    WriteLn('Error creating converter: ', AsyncStatus);
    Halt;
  end;

  {Set hook}
  FCP^.SetStatusFunc(CvtStatusFunc);

  {Convert it}
  FCP^.ConvertFax('EXCVTO.PAS');
  WriteLn(^M^J'Conversion results: ', AsyncStatus);
  Dispose(FCP, Done);
end.
