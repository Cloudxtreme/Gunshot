{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                  APZMODEM.PAS 2.03                    *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApZmodem;
  {-Provides Zmodem receive and transmit functions}

interface

uses
  Dos,
  {$IFDEF UseOPro}
  OpRoot,
  OpInline,
  OpString,
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

{$I APZMODEM.PA0}

procedure UpdateBlockCheck(P : ProtocolRecPtr; CurByte: Byte);
procedure SendBlockCheck(P : ProtocolRecPtr);
function VerifyBlockCheck(P : ProtocolRecPtr) : Boolean;
procedure Cancel(P : ProtocolRecPtr);
procedure AbortProtocol(P : ProtocolRecPtr);
function HandleAbort(P : ProtocolRecPtr) : Boolean;
procedure GetCharStripped(P : ProtocolRecPtr; var C : Char);
procedure PutAttentionString(P : ProtocolRecPtr);
procedure PutCharHex(P : ProtocolRecPtr; C : Char);
procedure PutHexHeader(P : ProtocolRecPtr; FrameType : Char);
procedure GetCharEscaped(P : ProtocolRecPtr; var C : Char);
procedure GetCharHex(P : ProtocolRecPtr; var C : Char);
procedure CheckForHeader(P : ProtocolRecPtr);
procedure zpPrepareWriting(P : ProtocolRecPtr);
procedure zpFinishWriting(P : ProtocolRecPtr);
procedure WriteDataBlock(P : ProtocolRecPtr);
function ReceiveBlock(P : ProtocolRecPtr;
                      var Block : DataBlockType;
                      var BlockSize : Word;
                      var Handshake : Char) : Boolean;
procedure ExtractFileInfo(P : ProtocolRecPtr);
procedure PutCharEscaped(P : ProtocolRecPtr; C : Char);
function EscapeChar(P : ProtocolRecPtr; C : Char) : Str2;
procedure PutBinaryHeader(P : ProtocolRecPtr; FrameType : Char);
procedure TransmitBlock(P : ProtocolRecPtr);

implementation

const
  {For various hex char manipulations}
  HexDigits : array[0..15] of Char = '0123456789abcdef';

  {For manipulating file management masks}
  FileMgmtMask = 7;                {Isolate file mgmnt values}
  FileSkipMask = $80;              {Skip file if dest doesn't exist}

  {Only supported conversion option}
  FileRecover = $03;               {Resume interrupted file transfer}

  {Data subpacket terminators}
  ZCrcE      = 'h';                {End  - last data subpacket of file}
  ZCrcG      = 'i';                {Go   - no response necessary}
  ZCrcQ      = 'j';                {Ack  - requests ZACK or ZRPOS}
  ZCrcW      = 'k';                {Wait - sender waits for answer}

  {Translate these escaped sequences}
  ZRub0      = 'l';                {Translate to $7F}
  ZRub1      = 'm';                {Translate to $FF}

  {Byte offsets for pos/flag bytes}
  ZF0 = 3;                         {Flag byte 0}
  ZF1 = 2;                         {Flag byte 0}
  ZF2 = 1;                         {Flag byte 0}
  ZF3 = 0;                         {Flag byte 0}
  ZP0 = 0;                         {Position byte 0}
  ZP1 = 1;                         {Position byte 1}
  ZP2 = 2;                         {Position byte 1}
  ZP3 = 3;                         {Position byte 1}

  {Bit masks for ZrInit}
  CanFdx  = $0001;           {Can handle full-duplex}
  CanOvIO = $0002;           {Can do disk and serial I/O overlaps}
  CanBrk  = $0004;           {Can send a break}
  CanCry  = $0008;           {Can encrypt/decrypt, not supported}
  CanLzw  = $0010;           {Can LZ compress, not supported}
  CanFc32 = $0020;           {Can use 32 bit CRC}
  EscAll  = $0040;           {Escapes all control chars}               {!!.02}
  Esc8    = $0080;           {Escapes the 8th bit, not supported}

  {Bit masks for ZsInit}
  TEscAll  = $0040;          {Sender needs escaped ctl chars}          {!!.02}
  TEsc8    = $0080;          {Sender needs escaped 8th bit, not supported} {!!.02}

  {Character constants}
  Hibit   = $80;
  cDleHi  = Char(Ord(cDle) + HiBit);
  cXonHi  = Char(Ord(cXon) + HiBit);
  cXoffHi = Char(Ord(cXoff) + HiBit);
  CanChar = #24;

{$I APZMODEM.PA1}         {Zmodem primitives}
{$I APZMODEM.PA2}         {Zmodem receive/transmit}

end.
