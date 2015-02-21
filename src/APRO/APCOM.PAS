{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                    APCOM.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1991.           *}
{* Portions copyright (c) Information Technology 1989,   *}
{*    and used under license to TurboPower Software      *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$IFDEF UseOOP}
!! STOP COMPILE - this unit requires UseOOP to be undefined
{$ENDIF}

unit ApCom;
  {-Interface layer for serial I/O}

interface

uses
  {$IFDEF DPMI}
  WinApi,
  {$ENDIF}
  {$IFDEF UseOPro}
  OpRoot,
  OpInline,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpInline,
  {$ENDIF}
  ApMisc,
  ApPort,
  ApTimer;

{$I APCOM.PA0}

{!!.03 moved up}
var
  {Global routine that handles received chars during "waits"}
  WaitChar : WaitCharProc;

  {========================================================================}

implementation

type
  OS = record
    Ofs : Word;
    Seg : Word;
  end;

const
  EmptySet : CharSet = [];

  {$IFDEF DPMI}
  procedure IntOff; inline($9C/$FA);      {PUSHF/CLI}
  procedure IntOn; inline($58/            {POP  AX}
                          $A9/$00/$02/    {TEST AX,0200}
                          $74/$01/        {JE   @DONE}
                          $FB);           {STI}
  {$ELSE}
  procedure IntOff; inline($9C/$FA);      {PUSHF/CLI}
  procedure IntOn; inline($9D);           {POPF}
  {$ENDIF}

  {$I APCOM.PA1}   {Gets, puts, flow, modem status}
  {$I APCOM.PA2}   {Line status, misc}

begin
  @WaitChar := @NoWaitChar;
end.
