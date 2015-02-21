{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{Include OPro's define file if UseOPro is specified}
{$IFDEF UseOPro}
{$I OPDEFINE.INC}
{$ENDIF}

{*********************************************************}
{*                  APKERMIT.PAS 2.03                    *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApKermit;
  {-Provides Kermit receive and transmit functions}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpInline,
  OpString,
  OpRoot,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  TpInline,
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  {$ELSE}
  ApMisc,
  ApPort,
  ApTimer,
  ApCom,
  {$ENDIF}
  ApAbsPcl;

{$I APKERMIT.PA0}

implementation

const
  {'S' - SendInit packet option index}
  MaxL    = 1;     {Max packet length sender can receive (Def = none)}
  Time    = 2;     {Max seconds to wait before timing out (Def = none)}
  NPad    = 3;     {Number of padding chars before packets (Def = none)}
  PadC    = 4;     {Padding character (Def = Nul)}
  EOL     = 5;     {Packet terminator character (Def = CR)}
  QCtl    = 6;     {Prefix char for control-char encoding (Def = #)}
  QBin    = 7;     {Prefix char for hi-bit encoding (Def = ' ' none)}
  Chkt    = 8;     {1=chksum, 2=2 byte chksum, 3=CRC (Def = 1)}
  Rept    = 9;     {Prefix char for repeat-count encoding (Def = ' ' none)}
  Capa    = 10;    {Advanced capabilities bit masks}
  Windo   = 11;    {Size of the sliding window (in packets)}
  MaxLx1  = 12;    {long packet size div 95}
  MaxLx2  = 13;    {Long packet size mod 95}
  SendInitLen = 13; {Size of SendInit data block}
  MaxKermitOption = 13;

  {Advanced capability bit masks}
  LastMask       = $01;  {Set if more bit masks follow}
  LongPackets    = $02;  {Set if using long packets}
  SlidingWindows = $04;  {Set if using sliding windows}
  FileAttribute  = $08;  {Set if using Attribut packets, not supported}

  {Text strings for various error/abort conditions}
  eRecInitTO = 'Timeout waiting for RecInit packet';
  eFileTO = 'Timeout waiting for File packet';
  eDataTO = 'Timeout waiting for Data packet';
  eSync = 'Failed to syncronize protocol';
  eAsync = 'Blockcheck or other error';
  eCancel = 'Canceled';
  eFileExists = 'Not allowed to overwrite existing file';
  eFileError = 'Error opening or writing file';

  {Check to CheckType conversion array}
  CheckVal : array[1..3] of Byte = (bcChecksum1, bcChecksum2, bcCrcK);

  {Used in ProtocolReceivePart/ProtocolTransmitPart}
  FirstDataState : array[Boolean] of KDataStateType = (dsData, dsCheck1);
  FreeMargin = 20;

  {$I APKERMIT.PA1}   {Kermit part 1}
  {$I APKERMIT.PA2}   {Kermit part 2}
end.

