program ExCvt;  {EXCVT.PAS}
uses
  Dos, Crt, ApMisc, ApFaxCvt;
var
  FC : FaxConverterPtr;

{$F+}
function CvtStatusFunc(FC : FaxConverterPtr;
                       Starting, Ending : Boolean) : Boolean;
var
  Line : LongInt;
  Page : Integer;
begin
  GetStatusInfo(FC, Line, Page);
  Write(^M'Processing line ', Line:4, ' of page ', Page:4);
  if KeyPressed then
    CvtStatusFunc := ReadKey = #27
  else
    CvtStatusFunc := False;
end;
{$F-}

begin
  InitTextConverter(FC);
  if FC = nil then begin
    WriteLn('Error initializing converter: ', AsyncStatus);
    Halt;
  end;

  {Set hooks}
  SetStatusFunc(FC, CvtStatusFunc);

  {Convert it}
  ConvertFaxText(FC, 'EXCVT.PAS');
  WriteLn(^M^J'Conversion results: ', AsyncStatus);
  DoneTextConverter(FC);
end.
