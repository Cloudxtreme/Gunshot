{$M 32768,32768,655360}
{$S-,R-,V-,I-,B-,F+,A-}

{*********************************************************}
{*                  OOPINST.PAS 2.03                     *}
{*       Copyright (c) TurboPower Software 1991.         *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I OPDEFINE.INC}

{***************************************************************************
 This program requires that OPDEFINE.INC activate the following defines:
   UseShadows, UseScrollBars, UseHotSpots, UseAdjustableWindows,
 This program will use features activated with the following defines:
   UseMouse
 ***************************************************************************}

{$IFNDEF UseScrollBars}
  !! STOP COMPILE - settings in OPDEFINE.INC not compatible with this program.
{$ENDIF}

{$IFNDEF UseHotSpots}
  !! STOP COMPILE - settings in OPDEFINE.INC not compatible with this program.
{$ENDIF}

{$IFNDEF UseAdjustableWindows}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this program.
{$ENDIF}

{$IFNDEF UseShadows}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this program.
{$ENDIF}

program OopInst;
  {-Installation program for OOPCOM}
uses
  Dos,
  OpInline,
  OpString,
  OpDos,
  OpRoot,
  OpClone,
  OpCrt,
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpAbsFld,
  OpCmd,
  OpField,
  OpFrame,
  OpWindow,
  OpSEdit,
  OpSelect,
  OpPick,
  OpEntry,
  OpMenu,
  ApPort,
  {ApUart,}                                                            {!!.01}
  ApMisc,
  MakeMisc,
  OOUI,       {User Interface}
  OopMain0,   {OOPCOM globals}
  OopMain1,   {load/store config code}
  OopInstM;

begin
  DoOopInst;
end.

