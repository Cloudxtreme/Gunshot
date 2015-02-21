{$S-,R-,V-,I-,B-,F-,O-,A+}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                    APZIP.PAS 2.03                     *}
{*          Copyright (c) TurboPower Software.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApZip;
  {-ZIP file access, dearchiving}

interface

uses
  Dos,
  {$IFDEF UseOpro}
  OpInline,
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpInline,
  TpMemChk,
  TpString,
  {$ENDIF}
  ApMisc,
  ApArchiv;

{$I APZIP.PA0}

  {==========================================================================}

implementation

var
  Crc : LongInt;                  {running CRC counter}
  UpdateCrcAddr : Pointer;        {addr of CRC function}

  {$I APZIP.PA1}    {Private data, primitives and decompression routines}
  {$I APZIP.PA2}    {Zip file list and compression routines}
  {$I APZIP.PA3}    {Implode routines}
  {$I APZIP.PA4}    {Inflate/Deflate routines}                         {!!.01}

begin
  UpdateCrcAddr := @UpdateCrc;

  @glOKF := nil;
  @glSCP := nil;
  @glSMP := nil;
  @glESF := nil;
  @glSPF := nil;
  @glOKC := nil;
  @glCSF := nil;
  @glFCF := nil;

  {$IFDEF UsePModeDLL}
  Assign(Output, '');
  Rewrite(Output);
  {$ENDIF}
end.

