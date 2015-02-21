{$S-,R-,O-}
unit OverInit;
interface
uses Overlay;
implementation

uses OpDos;

const
  OvrFileName = 'OOPCOM.OVR';
  UseEmsForOverlays = False;

  procedure InitOverlaySystem;
  var
    FullName : String;
  begin
    if not ExistOnPath(OvrFileName, FullName) then
      FullName := OvrFileName;
    OvrInit(FullName);
    if ovrResult <> 0 then begin
      WriteLn('Error attempting to load overlay file: ', OvrFileName);
      Halt(1);
    end;
    if UseEmsForOverlays then
      OvrInitEms;
  end;

begin
  InitOverlaySystem;
end.
