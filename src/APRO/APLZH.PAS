{$S-,R-,V-,I-,B-,F-,O-,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                   APLZH.PAS 2.03                      *}
{*         Copyright (c) TurboPower Software             *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApLzh;
  {-LZH file access, dearchiving and archiving}

interface

uses
  Dos,
  {$IFDEF UseOpro}
  OpString,
  OpRoot,
  OpDos,
  OpInline,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  TpMemChk,
  TpDos,
  {$ENDIF}
  ApMisc,
  ApArchiv;

{$I APLZH.PA0}

  {==========================================================================}

implementation

var
  CompressMode : CompressionMode;        {Current compression mode}

procedure lhaExtractFile(var LN : LzhNode; OutName : PathStr); Forward;
  {-Extract the specified file from the archive}

procedure lhaFreezeFile(FName : PathStr; var LH : LzhHeader); Forward;
  {-Compress the specified file and store in the archive}


  {$I APLZH.PA1}            {Tables, declarations and externals}
  {$I APLZH.PA2}            {Compression/decompression routines}
  {$I APLZH.PA3}            {LHA compression method routines}

begin
  @glOKF := nil;
  @glSNP := nil;
  @glSMP := nil;
  @glESF := nil;
  @glSPF := nil;
  @glOKC := nil;
  @glCSF := nil;
  CompressMode := cmBestMethod;

  {$IFDEF UsePModeDLL}
  Assign(Output, '');
  Rewrite(Output);
  {$ENDIF}
end.
