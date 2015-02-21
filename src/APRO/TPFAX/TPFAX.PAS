{******************************************************}
{*                   TPFAX.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$IFDEF Windows}
  !! ERROR - This program is not a Windows program
{$ENDIF}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}

{$V-,B-,R-,S-,F-,O-,A+,I-,X+}

{$IFNDEF UseDrag}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseMouse}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseScrollBars}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseHotSpots}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseShadows}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseStreams}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseDates}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseUART}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseInt14}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseFossil}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseDigi14}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseOop}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseOpro}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF BindFaxFont}
  !! ERROR - The settings in APDEFINE.INC are incompatible with this unit
{$ENDIF}

{$M $4000,0,655360}

program TpFax;
uses
  {$IFNDEF DPMI}
  {----------}
  TpfOvr,
  {----------}

  OpAbsFld,
  OpSelect,
  OpXtree,
  TpfData,
  TpfDia,
  TpfMenu,
  TpfView,
  {$ENDIF}
  {$IFDEF Tracing}
  ApPort,
  {$ENDIF}

  TpfMain;

{$IFNDEF DPMI}

{$O OpDir}
{$O OpSelect}
{$O TpfData}
{$O TpfDia}
{$O TpfMenu}
{$O TpfView}
{$O TpfMenu}

{$ENDIF}

begin
  {$IFDEF Tracing}
  InitTracing(5000);
  {$ENDIF}

  TPFaxMainLoop;

  {$IFDEF Tracing}
  DumpTrace('TPFAX.TRC');
  {$ENDIF}
end.
