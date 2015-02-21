{$R-,S-}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}

{*********************************************************}
{*                   OOPCOM.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$IFNDEF UseOpro}
  !! STOP COMPILE - This program requires that UseOpro be defined in APDEFINE.INC
{$ENDIF}
{$IFNDEF UseOOP}
  !! STOP COMPILE - This program requires that UseOOP be defined in APDEFINE.INC
{$ENDIF}
{$IFNDEF PickListFields}
  !! STOP COMPILE - This program requires that PickListFields be defined in OPDEFINE.INC
{$ENDIF}
{$IFNDEF UseStreams}
  !! STOP COMPILE - This program requires that UseStreams be defined in OPDEFINE.INC
{$ENDIF}

program OopCom;
  {-Object Oriented Communications Program}
uses
  {$IFNDEF DPMI}
  Overlay,
  OverInit,
  {$ENDIF}
  opstring,                       {string handling}
  opdos,                          {misc. DOS/BIOS routines}
  opframe,                        {frames, shadows, etc.}
  opwindow,                       {window management}
  opbrowse,                       {file browser}
  opmemo,                         {memo editor}
  opeditor,                       {text editor}
  opabsfld,                       {abstract field, picture mask stuff}
  opfield,                        {field definitions}
  opedit,                         {line editor}
  opselect,                       {selectors}
  opentry,                        {entry screens}
  oppick,                         {pick lists}
  opdir,                          {directory lists}
  opmenu,                         {menus}
  ophelp,
  ooui,                           {object oriented user interface}
  ApPort,
  {$IFDEF UseUart}                                                     {!!.01}
  ApUart,
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseFossil}                                                   {!!.01}
  ApFossil,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseDigi14}                                                   {!!.01}
  ApDigi14,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseInt14}                                                    {!!.01}
  ApInt14,                                                             {!!.01}
  {$ENDIF}                                                             {!!.01}
  ApMisc,
  ApTimer,
  OOAbsPcl,
  OOAscii,
  OOXModem,
  OOYModem,
  OOZModem,
  OOKermit,
  OOBPlus,
  OOCom,
  OOModem,
  OOEmu,
  termwin,                        {APRO terminal windows}
  OopMain0,
  OopMain1,
  OopMain2,
  OopMain;

{$IFNDEF DMPI}
{.O OpBrowse}
{$O OpEditor}
{.O OpMenu}
{$O OpEdit}
{$O OpHelp}
{$O OpDir}
{$O OpEntry}
{$O OopMain1}
{$O OopMain2}
{$O OOAscii}
{$O OOXModem}
{$O OOYModem}
{$O OOZModem}
{$O OOKermit}
{$O OOBPlus}
{$O OOModem}
{$ENDIF}

begin
  DoOopCom;
end.
