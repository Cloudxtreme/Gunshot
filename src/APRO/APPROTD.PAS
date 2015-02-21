{$S-,R-,V-,I-}

{$I APDEFINE.INC}

{$IFNDEF DPMI}
  !! STOP COMPILE - this unit is for protected mode only
{$ENDIF}

{$IFNDEF UsePModeDLL}
  !! STOP COMPILE - this import unit requires UsePModeDLL to be defined
{$ENDIF}

{*********************************************************}
{*                   APPROTD.PAS 2.03                    *}
{*     Copyright (c) TurboPower Software 1993.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApProtD;

interface

uses
  Dos,
  ApComD;

{$UNDEF UsePModeDLL}
{$DEFINE CompilingImport}
{$I APABSPCL.PA0}
{$I APXMODEM.PA0}
{$I APYMODEM.PA0}
{$I APZMODEM.PA0}
{$I APKERMIT.PA0}
{$I APASCII.PA0}
{$I APBPLUS.PA0}
{$UNDEF CompilingImport}
{$DEFINE UsePModeDLL}

implementation

{from APABSPCL}
procedure InitProtocolData;       external 'APPROTD' index indexAPABSPCL + 1;
procedure DoneProtocolData;       external 'APPROTD' index indexAPABSPCL + 2;
procedure SetShowStatusProc;      external 'APPROTD' index indexAPABSPCL + 3;
procedure SetNextFileFunc;        external 'APPROTD' index indexAPABSPCL + 4;
procedure SetFileMask;            external 'APPROTD' index indexAPABSPCL + 5;
procedure SetFileList;            external 'APPROTD' index indexAPABSPCL + 6;
procedure MakeFileList;           external 'APPROTD' index indexAPABSPCL + 7;
procedure DisposeFileList;        external 'APPROTD' index indexAPABSPCL + 8;
procedure AddFileToList;          external 'APPROTD' index indexAPABSPCL + 9;
procedure SetDestinationDirectory;external 'APPROTD' index indexAPABSPCL + 0;
procedure SetReceiveFilename;     external 'APPROTD' index indexAPABSPCL + 11;
procedure SetLogFileProc;         external 'APPROTD' index indexAPABSPCL + 12;
procedure SetAcceptFileFunc;      external 'APPROTD' index indexAPABSPCL + 13;
procedure SetBackgroundProc;      external 'APPROTD' index indexAPABSPCL + 14;
procedure SetHandshakeWait;       external 'APPROTD' index indexAPABSPCL + 15;
procedure SetOverwriteOption;     external 'APPROTD' index indexAPABSPCL + 16;
procedure SetActualBPS;           external 'APPROTD' index indexAPABSPCL + 17;
procedure SetEfficiencyParms;     external 'APPROTD' index indexAPABSPCL + 18;
procedure SetProtocolPort;        external 'APPROTD' index indexAPABSPCL + 19;
procedure apOptionsOn;            external 'APPROTD' index indexAPABSPCL + 20;
procedure apOptionsOff;           external 'APPROTD' index indexAPABSPCL + 21;
function apOptionsAreOn;          external 'APPROTD' index indexAPABSPCL + 22;
function GetFilename;             external 'APPROTD' index indexAPABSPCL + 23;
function GetPathname;             external 'APPROTD' index indexAPABSPCL + 24;
function GetFileSize;             external 'APPROTD' index indexAPABSPCL + 25;
function GetBytesRemaining;       external 'APPROTD' index indexAPABSPCL + 26;
function GetBytesTransferred;     external 'APPROTD' index indexAPABSPCL + 27;
function GetElapsedTics;          external 'APPROTD' index indexAPABSPCL + 28;
function GetBlockErrors;          external 'APPROTD' index indexAPABSPCL + 29;
function GetTotalErrors;          external 'APPROTD' index indexAPABSPCL + 30;
function GetProtocol;             external 'APPROTD' index indexAPABSPCL + 31;
function GetBlockSize;            external 'APPROTD' index indexAPABSPCL + 32;
function GetBlockNum;             external 'APPROTD' index indexAPABSPCL + 33;
function GetCurrentBlockNum;      external 'APPROTD' index indexAPABSPCL + 34;
function SupportsBatch;           external 'APPROTD' index indexAPABSPCL + 35;
function GetCheckType;            external 'APPROTD' index indexAPABSPCL + 36;
function GetInitialFilePos;       external 'APPROTD' index indexAPABSPCL + 37;
function EstimateTransferSecs;    external 'APPROTD' index indexAPABSPCL + 38;
procedure ShowFirstStatus;        external 'APPROTD' index indexAPABSPCL + 39;
procedure ShowLastStatus;         external 'APPROTD' index indexAPABSPCL + 40;
procedure ResetStatus;            external 'APPROTD' index indexAPABSPCL + 41;
function WaitForFreeSpace;        external 'APPROTD' index indexAPABSPCL + 42;
function Crc32ofFile;             external 'APPROTD' index indexAPABSPCL + 43;
procedure NoStatus;               external 'APPROTD' index indexAPABSPCL + 44;
function NoNextFile;              external 'APPROTD' index indexAPABSPCL + 45;
procedure NoLogFile;              external 'APPROTD' index indexAPABSPCL + 46;
function NoAcceptFile;            external 'APPROTD' index indexAPABSPCL + 47;
procedure NoUserBack;             external 'APPROTD' index indexAPABSPCL + 48;
function NextFileMask;            external 'APPROTD' index indexAPABSPCL + 49;
function NextFileList;            external 'APPROTD' index indexAPABSPCL + 50;
function AcceptOneFile;           external 'APPROTD' index indexAPABSPCL + 51;
procedure apPrepareReading;       external 'APPROTD' index indexAPABSPCL + 52;
procedure apFinishReading;        external 'APPROTD' index indexAPABSPCL + 53;
function apReadProtocolBlock;     external 'APPROTD' index indexAPABSPCL + 54;
procedure apPrepareWriting;       external 'APPROTD' index indexAPABSPCL + 55;
procedure apFinishWriting;        external 'APPROTD' index indexAPABSPCL + 56;
function apWriteProtocolBlock;    external 'APPROTD' index indexAPABSPCL + 57;
procedure apUserStatus;           external 'APPROTD' index indexAPABSPCL + 58;
function TrimZeros;               external 'APPROTD' index indexAPABSPCL + 59;
function OctalStr;                external 'APPROTD' index indexAPABSPCL + 60;
function OctalStr2Long;           external 'APPROTD' index indexAPABSPCL + 61;
function PackToYMTimeStamp;       external 'APPROTD' index indexAPABSPCL + 62;
function YMTimeStampToPack;       external 'APPROTD' index indexAPABSPCL + 63;
function CurrentTimeStamp;        external 'APPROTD' index indexAPABSPCL + 64;

{from APXMODEM}
procedure InitXmodem;             external 'APPROTD' index indexAPXMODEM + 1;
procedure InitCustomXmodem;       external 'APPROTD' index indexAPXMODEM + 2;
procedure DoneXmodem;             external 'APPROTD' index indexAPXMODEM + 3;
procedure Set1KMode;              external 'APPROTD' index indexAPXMODEM + 4;
procedure SetGMode;               external 'APPROTD' index indexAPXMODEM + 5;
procedure SetBlockWait;           external 'APPROTD' index indexAPXMODEM + 6;
procedure SetFinishWaitXM;        external 'APPROTD' index indexAPXMODEM + 7;
procedure SendHandshakeChar;      external 'APPROTD' index indexAPXMODEM + 8;
procedure PrepareTransmitPartXM;  external 'APPROTD' index indexAPXMODEM + 9;
function ProtocolTransmitPartXM;  external 'APPROTD' index indexAPXMODEM + 10;
procedure ProtocolTransmitXM;     external 'APPROTD' index indexAPXMODEM + 11;
procedure PrepareReceivePartXM;   external 'APPROTD' index indexAPXMODEM + 12;
function ProtocolReceivePartXM;   external 'APPROTD' index indexAPXMODEM + 13;
procedure ProtocolReceiveXM;      external 'APPROTD' index indexAPXMODEM + 14;

{from APYMODEM}
procedure InitYmodem;             external 'APPROTD' index indexAPYMODEM + 1;
procedure InitCustomYmodem;       external 'APPROTD' index indexAPYMODEM + 2;
procedure DoneYmodem;             external 'APPROTD' index indexAPYMODEM + 3;
procedure ProtocolTransmitYM;     external 'APPROTD' index indexAPYMODEM + 4;
procedure PrepareTransmitPartYM;  external 'APPROTD' index indexAPYMODEM + 5;
function ProtocolTransmitPartYM;  external 'APPROTD' index indexAPYMODEM + 6;
procedure ProtocolReceiveYM;      external 'APPROTD' index indexAPYMODEM + 7;
procedure PrepareReceivePartYM;   external 'APPROTD' index indexAPYMODEM + 8;
function ProtocolReceivePartYM;   external 'APPROTD' index indexAPYMODEM + 9;

{from APZMODEM}
procedure InitZmodem;             external 'APPROTD' index indexAPZMODEM + 1;
procedure InitCustomZmodem;       external 'APPROTD' index indexAPZMODEM + 2;
procedure DoneZmodem;             external 'APPROTD' index indexAPZMODEM + 3;
procedure SetFileMgmtOptions;     external 'APPROTD' index indexAPZMODEM + 4;
procedure SetRecoverOption;       external 'APPROTD' index indexAPZMODEM + 5;
procedure SetBigSubpacketOption;  external 'APPROTD' index indexAPZMODEM + 6;
procedure SetFinishWaitZM;        external 'APPROTD' index indexAPZMODEM + 7;
procedure PrepareTransmitPartZM;  external 'APPROTD' index indexAPZMODEM + 8;
function ProtocolTransmitPartZM;  external 'APPROTD' index indexAPZMODEM + 9;
procedure ProtocolTransmitZM;     external 'APPROTD' index indexAPZMODEM + 10;
procedure PrepareReceivePartZM;   external 'APPROTD' index indexAPZMODEM + 11;
function ProtocolReceivePartZM;   external 'APPROTD' index indexAPZMODEM + 12;
procedure ProtocolReceiveZM;      external 'APPROTD' index indexAPZMODEM + 13;

{from APKERMIT}
procedure InitKermit;             external 'APPROTD' index indexAPKERMIT + 1;
procedure InitCustomKermit;       external 'APPROTD' index indexAPKERMIT + 2;
procedure DoneKermit;             external 'APPROTD' index indexAPKERMIT + 3;
procedure SetKermitOptions;       external 'APPROTD' index indexAPKERMIT + 4;
procedure SetMaxPacketLen;        external 'APPROTD' index indexAPKERMIT + 5;
procedure SetMaxLongPacketLen;    external 'APPROTD' index indexAPKERMIT + 6;
procedure SetMaxWindows;          external 'APPROTD' index indexAPKERMIT + 7;
procedure SetSWCTurnDelay;        external 'APPROTD' index indexAPKERMIT + 8;
procedure SetMaxTimeoutSecs;      external 'APPROTD' index indexAPKERMIT + 9;
procedure SetPacketPadding;       external 'APPROTD' index indexAPKERMIT + 10;
procedure SetTerminator;          external 'APPROTD' index indexAPKERMIT + 11;
procedure SetCtlPrefix;           external 'APPROTD' index indexAPKERMIT + 12;
procedure SetHibitPrefix;         external 'APPROTD' index indexAPKERMIT + 13;
procedure SetRepeatPrefix;        external 'APPROTD' index indexAPKERMIT + 14;
procedure SetKermitCheck;         external 'APPROTD' index indexAPKERMIT + 15;
function GetSwcSize;              external 'APPROTD' index indexAPKERMIT + 16;
procedure GetLPStatus;            external 'APPROTD' index indexAPKERMIT + 17;
function WindowsUsed;             external 'APPROTD' index indexAPKERMIT + 18;
procedure PrepareTransmitPartKM;  external 'APPROTD' index indexAPKERMIT + 19;
function ProtocolTransmitPartKM;  external 'APPROTD' index indexAPKERMIT + 20;
procedure ProtocolTransmitKM;     external 'APPROTD' index indexAPKERMIT + 21;
procedure PrepareReceivePartKM;   external 'APPROTD' index indexAPKERMIT + 22;
function ProtocolReceivePartKM;   external 'APPROTD' index indexAPKERMIT + 23;
procedure ProtocolReceiveKM;      external 'APPROTD' index indexAPKERMIT + 24;
procedure kpFinishWriting;        external 'APPROTD' index indexAPKERMIT + 25;

{from APASCII}
procedure InitAscii;              external 'APPROTD' index indexAPASCII + 1;
procedure InitCustomAscii;        external 'APPROTD' index indexAPASCII + 2;
procedure DoneAscii;              external 'APPROTD' index indexAPASCII + 3;
procedure SetDelays;              external 'APPROTD' index indexAPASCII + 4;
procedure SetEOLChar;             external 'APPROTD' index indexAPASCII + 5;
function GetLineNumber;           external 'APPROTD' index indexAPASCII + 6;
procedure PrepareTransmitPartAS;  external 'APPROTD' index indexAPASCII + 7;
function ProtocolTransmitPartAS;  external 'APPROTD' index indexAPASCII + 8;
procedure ProtocolTransmitAS;     external 'APPROTD' index indexAPASCII + 9;
procedure PrepareReceivePartAS;   external 'APPROTD' index indexAPASCII + 10;
function ProtocolReceivePartAS;   external 'APPROTD' index indexAPASCII + 11;
procedure ProtocolReceiveAS;      external 'APPROTD' index indexAPASCII + 12;

procedure InitBPlus;              external 'APPROTD' index indexAPBPLUS + 1;
procedure InitCustomBPlus;        external 'APPROTD' index indexAPBPLUS + 2;
procedure DoneBPlus;              external 'APPROTD' index indexAPBPLUS + 3;
procedure ProcessENQ;             external 'APPROTD' index indexAPBPLUS + 4;
procedure ProcessESCI;            external 'APPROTD' index indexAPBPLUS + 5;
procedure ProcessDLE;             external 'APPROTD' index indexAPBPLUS + 6;
procedure SetHandleResumeProc;    external 'APPROTD' index indexAPBPLUS + 7;
procedure PrepareTransmitPartBP;  external 'APPROTD' index indexAPBPLUS + 8;
function ProtocolTransmitPartBP;  external 'APPROTD' index indexAPBPLUS + 9;
procedure ProtocolTransmitBP;     external 'APPROTD' index indexAPBPLUS + 10;
procedure PrepareReceivePartBP;   external 'APPROTD' index indexAPBPLUS + 11;
function ProtocolReceivePartBP;   external 'APPROTD' index indexAPBPLUS + 12;
procedure ProtocolReceiveBP;      external 'APPROTD' index indexAPBPLUS + 13;
procedure NoHandleResume;         external 'APPROTD' index indexAPBPLUS + 14;

begin
end.
