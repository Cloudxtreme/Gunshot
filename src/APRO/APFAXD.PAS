{$S-,R-,V-,I-}

{$I APDEFINE.INC}

{$IFNDEF DPMI}
  !! STOP COMPILE - this unit is for protected mode only
{$ENDIF}

{$IFNDEF UsePModeDLL}
  !! STOP COMPILE - this import unit requires UsePModeDLL to be defined
{$ENDIF}

{*********************************************************}
{*                   APFAXD.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1993.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApFaxD;

interface

uses
  Dos,
  ApComD;

{$UNDEF UsePModeDLL}
{$DEFINE CompilingImport}
{$I APFAXCVT.PA0}
{$I APABSFAX.PA0}
{$I APFAX12.PA0}
{$I APFAXCAS.PA0}
{$UNDEF CompilingImport}
{$DEFINE UsePModeDLL}

implementation

{from APFAXCVT}
procedure InitConverterData;      external 'APFAXD' index indexAPFAXCVT + 1;
procedure DoneConverterData;      external 'APFAXD' index indexAPFAXCVT + 2;
procedure InitAbsConverter;       external 'APFAXD' index indexAPFAXCVT + 3;
procedure DoneAbsConverter;       external 'APFAXD' index indexAPFAXCVT + 4;
procedure acCompressStringRow;    external 'APFAXD' index indexAPFAXCVT + 5; {!!.01}
procedure acMakeEndOfPage;        external 'APFAXD' index indexAPFAXCVT + 6;
procedure fcOptionsOn;            external 'APFAXD' index indexAPFAXCVT + 7;
procedure fcOptionsOff;           external 'APFAXD' index indexAPFAXCVT + 8;
function fcOptionsAreOn;          external 'APFAXD' index indexAPFAXCVT + 9;
procedure SetStatusFunc;          external 'APFAXD' index indexAPFAXCVT + 10;
function LoadFont;                external 'APFAXD' index indexAPFAXCVT + 11;
function LoadHPFont;              external 'APFAXD' index indexAPFAXCVT + 12;
procedure SetPageSize;            external 'APFAXD' index indexAPFAXCVT + 13;
procedure SetResolutionMode;      external 'APFAXD' index indexAPFAXCVT + 14;
procedure SetFaxPath;             external 'APFAXD' index indexAPFAXCVT + 15;
procedure SetResolutionWidth;     external 'APFAXD' index indexAPFAXCVT + 16;
procedure SetStationIDCvt;        external 'APFAXD' index indexAPFAXCVT + 17;
procedure SetMargins;             external 'APFAXD' index indexAPFAXCVT + 18;
procedure GetStatusInfo;          external 'APFAXD' index indexAPFAXCVT + 19;
function GetFileName;             external 'APFAXD' index indexAPFAXCVT + 20;
procedure InitTextConverter;      external 'APFAXD' index indexAPFAXCVT + 21;
procedure DoneTextConverter;      external 'APFAXD' index indexAPFAXCVT + 22;
procedure ConvertFaxText;         external 'APFAXD' index indexAPFAXCVT + 23;
procedure InitPcxConverterData;   external 'APFAXD' index indexAPFAXCVT + 24;
procedure DonePcxConverterData;   external 'APFAXD' index indexAPFAXCVT + 25;
procedure InitPcxConverter;       external 'APFAXD' index indexAPFAXCVT + 26;
procedure DonePcxConverter;       external 'APFAXD' index indexAPFAXCVT + 27;
procedure ConvertFaxPcx;          external 'APFAXD' index indexAPFAXCVT + 28;
procedure InitDcxConverter;       external 'APFAXD' index indexAPFAXCVT + 29;
procedure DoneDcxConverter;       external 'APFAXD' index indexAPFAXCVT + 30;
procedure ConvertFaxDcx;          external 'APFAXD' index indexAPFAXCVT + 31;
procedure InitTiffConverter;      external 'APFAXD' index indexAPFAXCVT + 32;
procedure DoneTiffConverter;      external 'APFAXD' index indexAPFAXCVT + 33;
procedure ConvertFaxTiff;         external 'APFAXD' index indexAPFAXCVT + 34;
procedure InitUnpacker;           external 'APFAXD' index indexAPFAXCVT + 35;
procedure DoneUnpacker;           external 'APFAXD' index indexAPFAXCVT + 36;
procedure ufOptionsOn;            external 'APFAXD' index indexAPFAXCVT + 37;
procedure ufOptionsOff;           external 'APFAXD' index indexAPFAXCVT + 38;
function ufOptionsAreOn;          external 'APFAXD' index indexAPFAXCVT + 39;
procedure GetFaxHeader;           external 'APFAXD' index indexAPFAXCVT + 40;
procedure GetPageHeader;          external 'APFAXD' index indexAPFAXCVT + 41;
procedure SetOutputLineFunc;      external 'APFAXD' index indexAPFAXCVT + 42;
procedure UnpackPage;             external 'APFAXD' index indexAPFAXCVT + 43;
procedure UnpackFile;             external 'APFAXD' index indexAPFAXCVT + 44;
procedure InitPcxUnpackData;      external 'APFAXD' index indexAPFAXCVT + 45;
procedure DoneUnpackPcxData;      external 'APFAXD' index indexAPFAXCVT + 46;
procedure InitUnpackToPcx;        external 'APFAXD' index indexAPFAXCVT + 47;
procedure DoneUnpackToPcx;        external 'APFAXD' index indexAPFAXCVT + 48;
procedure UnpackFileToPcx;        external 'APFAXD' index indexAPFAXCVT + 49;
procedure InitUnpackToDcx;        external 'APFAXD' index indexAPFAXCVT + 50;
procedure DoneUnpackToDcx;        external 'APFAXD' index indexAPFAXCVT + 51;
procedure UnpackFileToDcx;        external 'APFAXD' index indexAPFAXCVT + 52;
function TodayString;             external 'APFAXD' index indexAPFAXCVT + 53;
function NowString;               external 'APFAXD' index indexAPFAXCVT + 54;
procedure Merge;                  external 'APFAXD' index indexAPFAXCVT + 55;
function Trim;                    external 'APFAXD' index indexAPFAXCVT + 56;
function TrimStationID;           external 'APFAXD' index indexAPFAXCVT + 57;
procedure StripPrefix;            external 'APFAXD' index indexAPFAXCVT + 58;
function ForceExtension;          external 'APFAXD' index indexAPFAXCVT + 59;
function GetPackedDateTime;       external 'APFAXD' index indexAPFAXCVT + 60;
function acAddData;               external 'APFAXD' index indexAPFAXCVT + 61;
function acCreateOutputFile;      external 'APFAXD' index indexAPFAXCVT + 62;
function acUpdateMainHeader;      external 'APFAXD' index indexAPFAXCVT + 63;
function acUpdatePageHeader;      external 'APFAXD' index indexAPFAXCVT + 64;
procedure acAddCodePrim;          external 'APFAXD' index indexAPFAXCVT + 65;
procedure acAddCode;              external 'APFAXD' index indexAPFAXCVT + 66;
procedure acCompressRasterLine;   external 'APFAXD' index indexAPFAXCVT + 67;
function pcOpenPcxFile;           external 'APFAXD' index indexAPFAXCVT + 68;
function pcValidatePcxHdr;        external 'APFAXD' index indexAPFAXCVT + 69;
procedure pcReadRasterLine;       external 'APFAXD' index indexAPFAXCVT + 70;
procedure tcReadRasterLine;       external 'APFAXD' index indexAPFAXCVT + 71;
function tcValidTIFF;             external 'APFAXD' index indexAPFAXCVT + 72;
function tcOpenTiffFile;          external 'APFAXD' index indexAPFAXCVT + 73;
function tcSeek;                  external 'APFAXD' index indexAPFAXCVT + 74;
function tcReadTagDir;            external 'APFAXD' index indexAPFAXCVT + 75;
function tcGetLong;               external 'APFAXD' index indexAPFAXCVT + 76;
procedure tcLoadStripInfo;        external 'APFAXD' index indexAPFAXCVT + 77;
function acAddLine;               external 'APFAXD' index indexAPFAXCVT + 78;
function acAddBlankLines;         external 'APFAXD' index indexAPFAXCVT + 79;
procedure InitBmpConverter;       external 'APFAXD' index indexAPFAXCVT + 80;                {!!.03}
procedure DoneBmpConverter;       external 'APFAXD' index indexAPFAXCVT + 81;                {!!.03}
procedure ConvertFaxBmp;          external 'APFAXD' index indexAPFAXCVT + 82;                {!!.03}
function bcOpenBmpFile;           external 'APFAXD' index indexAPFAXCVT + 83;                {!!.03}
procedure bcReadRasterLine;       external 'APFAXD' index indexAPFAXCVT + 84;                {!!.03}


{from APABSFAX}
procedure InitFaxData;            external 'APFAXD' index indexAPABSFAX + 1;
procedure DoneFaxData;            external 'APFAXD' index indexAPABSFAX + 2;
procedure afOptionsOn;            external 'APFAXD' index indexAPABSFAX + 3;
procedure afOptionsOff;           external 'APFAXD' index indexAPABSFAX + 4;
function afOptionsAreOn;          external 'APFAXD' index indexAPABSFAX + 5;
procedure SetFaxStatusProc;       external 'APFAXD' index indexAPABSFAX + 6;
procedure SetTitle;               external 'APFAXD' index indexAPABSFAX + 7;
procedure SetRecipientName;       external 'APFAXD' index indexAPABSFAX + 8;
procedure SetSenderName;          external 'APFAXD' index indexAPABSFAX + 9;
procedure SetDestinationDir;      external 'APFAXD' index indexAPABSFAX + 10;
procedure SetStationID;           external 'APFAXD' index indexAPABSFAX + 11;
procedure SetConnectAttempts;     external 'APFAXD' index indexAPABSFAX + 12;
procedure SetNextFaxFunc;         external 'APFAXD' index indexAPABSFAX + 13;
procedure SetFaxLogProc;          external 'APFAXD' index indexAPABSFAX + 14;
procedure SetFaxNameFunc;         external 'APFAXD' index indexAPABSFAX + 15;
procedure SetAcceptFaxFunc;       external 'APFAXD' index indexAPABSFAX + 16;
procedure FaxStatus;              external 'APFAXD' index indexAPABSFAX + 17;
procedure AddFaxEntry;            external 'APFAXD' index indexAPABSFAX + 18;
procedure ClearFaxEntries;        external 'APFAXD' index indexAPABSFAX + 19;
function GetFaxName;              external 'APFAXD' index indexAPABSFAX + 20;
function GetFaxProgress;          external 'APFAXD' index indexAPABSFAX + 21;
function NextFax;                 external 'APFAXD' index indexAPABSFAX + 22;
procedure LogFax;                 external 'APFAXD' index indexAPABSFAX + 23;
function FaxName;                 external 'APFAXD' index indexAPABSFAX + 24;
function AcceptFax;               external 'APFAXD' index indexAPABSFAX + 25;
function afConvertHeaderString;   external 'APFAXD' index indexAPABSFAX + 26;
function NextFaxList;             external 'APFAXD' index indexAPABSFAX + 27;
function FaxNameMD;               external 'APFAXD' index indexAPABSFAX + 28;
function FaxNameCount;            external 'APFAXD' index indexAPABSFAX + 29;

{from APFAX12}
procedure InitC12AbsData;         external 'APFAXD' index indexAPFAX12 + 1;
procedure DoneC12AbsData;         external 'APFAXD' index indexAPFAX12 + 2;
procedure SetFaxPort;             external 'APFAXD' index indexAPFAX12 + 3;
procedure SetModemInit;           external 'APFAXD' index indexAPFAX12 + 4;
function SetClassType;            external 'APFAXD' index indexAPFAX12 + 5;
procedure SetInitBaudRate;        external 'APFAXD' index indexAPFAX12 + 6; {!!.01}
function GetModemClassSupport;    external 'APFAXD' index indexAPFAX12 + 7;
function GetModemInfo;            external 'APFAXD' index indexAPFAX12 + 8;
procedure GetModemFeatures;       external 'APFAXD' index indexAPFAX12 + 9;
procedure SetModemFeatures;       external 'APFAXD' index indexAPFAX12 + 10;
function GetLastPageStatus;       external 'APFAXD' index indexAPFAX12 + 11;
function GetRemoteID;             external 'APFAXD' index indexAPFAX12 + 12;
procedure GetSessionParams;       external 'APFAXD' index indexAPFAX12 + 13;
function GetHangupResult;         external 'APFAXD' index indexAPFAX12 + 14;
procedure GetPageInfoC12;         external 'APFAXD' index indexAPFAX12 + 15;
procedure InitC12SendFax;         external 'APFAXD' index indexAPFAX12 + 16;
procedure DoneC12SendFax;         external 'APFAXD' index indexAPFAX12 + 17;
procedure SetToneDial;            external 'APFAXD' index indexAPFAX12 + 18;
procedure SetDialPrefix;          external 'APFAXD' index indexAPFAX12 + 19;
procedure SetDialTime;            external 'APFAXD' index indexAPFAX12 + 20;
procedure SetHeaderText;          external 'APFAXD' index indexAPFAX12 + 21;
procedure SetMaxRetries;          external 'APFAXD' index indexAPFAX12 + 22;
function FaxTransmitPartC12;      external 'APFAXD' index indexAPFAX12 + 23;
procedure PrepareFaxTransmitPartC12; external 'APFAXD' index indexAPFAX12 + 24;
procedure FaxTransmitC12;         external 'APFAXD' index indexAPFAX12 + 25;
procedure InitC12ReceiveFax;      external 'APFAXD' index indexAPFAX12 + 26;
procedure DoneC12ReceiveFax;      external 'APFAXD' index indexAPFAX12 + 27;
function InitModemForFaxReceive;  external 'APFAXD' index indexAPFAX12 + 28;
procedure SetAnswerOnRing;        external 'APFAXD' index indexAPFAX12 + 29;
procedure SetFaxAndData;          external 'APFAXD' index indexAPFAX12 + 30;
procedure SetConnectState;        external 'APFAXD' index indexAPFAX12 + 31;
procedure SetOneFax;              external 'APFAXD' index indexAPFAX12 + 32;
procedure PrepareFaxReceivePartC12; external 'APFAXD' index indexAPFAX12 + 33;
function FaxReceivePartC12;       external 'APFAXD' index indexAPFAX12 + 34;
procedure FaxReceiveC12;          external 'APFAXD' index indexAPFAX12 + 35;

{from APFAXCAS}
procedure InitCasFax;             external 'APFAXD' index indexAPFAXCAS + 1;
procedure DoneCasFax;             external 'APFAXD' index indexAPFAXCAS + 2;
procedure SubmitTask;             external 'APFAXD' index indexAPFAXCAS + 3;
procedure AbortCurrentEvent;      external 'APFAXD' index indexAPFAXCAS + 4;
procedure FindFirstCAS;           external 'APFAXD' index indexAPFAXCAS + 5;
procedure FindNextCAS;            external 'APFAXD' index indexAPFAXCAS + 6;
procedure OpenFile;               external 'APFAXD' index indexAPFAXCAS + 7;
procedure CloseFile;              external 'APFAXD' index indexAPFAXCAS + 8;
procedure DeleteFile;             external 'APFAXD' index indexAPFAXCAS + 9;
procedure DeleteAllFiles;         external 'APFAXD' index indexAPFAXCAS + 10;
procedure GetEventDate;           external 'APFAXD' index indexAPFAXCAS + 11;
procedure SetTaskDate;            external 'APFAXD' index indexAPFAXCAS + 12;
procedure GetEventTime;           external 'APFAXD' index indexAPFAXCAS + 13;
procedure SetTaskTime;            external 'APFAXD' index indexAPFAXCAS + 14;
procedure GetExternalDataBlock;   external 'APFAXD' index indexAPFAXCAS + 15;
procedure GetSetAutoReceive;      external 'APFAXD' index indexAPFAXCAS + 16;
procedure GetEventStatus;         external 'APFAXD' index indexAPFAXCAS + 17;
procedure GetQueueStatus;         external 'APFAXD' index indexAPFAXCAS + 18;
procedure GetHardwareStatus;      external 'APFAXD' index indexAPFAXCAS + 19;
procedure RunDiagnostics;         external 'APFAXD' index indexAPFAXCAS + 20;
procedure MoveReceivedFile;       external 'APFAXD' index indexAPFAXCAS + 21;
procedure SubmitSingleFile;       external 'APFAXD' index indexAPFAXCAS + 22;
procedure SetLogoFile;            external 'APFAXD' index indexAPFAXCAS + 23;
procedure GetPageInfoCAS;         external 'APFAXD' index indexAPFAXCAS + 24;
procedure SetCASAbortFunc;        external 'APFAXD' index indexAPFAXCAS + 25;
procedure GetAllStatus;           external 'APFAXD' index indexAPFAXCAS + 26;
procedure SetCASResolution;       external 'APFAXD' index indexAPFAXCAS + 27;
procedure PrepareFaxTransmitPartCas; external 'APFAXD' index indexAPFAXCAS + 28;
function FaxTransmitPartCas;      external 'APFAXD' index indexAPFAXCAS + 29;
procedure FaxTransmitCas;         external 'APFAXD' index indexAPFAXCAS + 30;
procedure PrepareFaxReceivePartCas; external 'APFAXD' index indexAPFAXCAS + 31;
function FaxReceivePartCas;       external 'APFAXD' index indexAPFAXCAS + 32;
procedure FaxReceiveCas;          external 'APFAXD' index indexAPFAXCAS + 33;
function CASInstalled;            external 'APFAXD' index indexAPFAXCAS + 34;

begin
end.
