{******************************************************}
{*                   TPOVR.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$V-,B-,R-,S-,F-,O-,A+,I-,X+}

unit TpfOvr; { overlay management for TPFAX }

interface

uses
  Overlay;

implementation

begin
  OvrInit('TPFAX.OVR');
  if (OvrResult <> ovrOK) then begin
    WriteLn('Overlay init failed');
    Halt;
  end;

  OvrInitEms;
end.
