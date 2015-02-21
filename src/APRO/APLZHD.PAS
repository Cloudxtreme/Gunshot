{$S-,R-,V-,I-}

{$I APDEFINE.INC}

{$IFNDEF DPMI}
  !! STOP COMPILE - this unit is for protected mode only
{$ENDIF}

{$IFNDEF UsePModeDLL}
  !! STOP COMPILE - this import unit requires UsePModeDLL to be defined
{$ENDIF}

{*********************************************************}
{*                   APLZHD.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1993.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApLzhD;

interface

uses
  Dos;

{$UNDEF UsePModeDLL}
{$DEFINE CompilingImport}
{$I APMISC.PA0}
{$I APARCHIV.PA0}
{$I APLZH.PA0}
{$UNDEF CompilingImport}
{$DEFINE UsePModeDLL}

implementation

{from APMISC}
function StatusStr;         external 'APLZHD' index indexAPMISC + 1;
function UpdateChecksum;    external 'APLZHD' index indexAPMISC + 2;
function UpdateCrC;         external 'APLZHD' index indexAPMISC + 3;
function UpdateCrcKermit;   external 'APLZHD' index indexAPMISC + 4;
function GlobalAllocCheck;  external 'APLZHD' index indexAPMISC + 5;
procedure GlobalFreeCheck;  external 'APLZHD' index indexAPMISC + 6;
function GetMemCheck;       external 'APLZHD' index indexAPMISC + 7;
procedure FreeMemCheck;     external 'APLZHD' index indexAPMISC + 8;
function IsLeapYear;        external 'APLZHD' index indexAPMISC + 9;
function DaysInMonth;       external 'APLZHD' index indexAPMISC + 10;
function ValidDate;         external 'APLZHD' index indexAPMISC + 11;
function DMYtoDate;         external 'APLZHD' index indexAPMISC + 12;
procedure DateToDMY;        external 'APLZHD' index indexAPMISC + 13;
procedure DateTimeDiff;     external 'APLZHD' index indexAPMISC + 14;
procedure TimeToHMS;        external 'APLZHD' index indexAPMISC + 15;
function HMStoTime;         external 'APLZHD' index indexAPMISC + 16;
procedure IncDateTime;      external 'APLZHD' index indexAPMISC + 17;
function StUpcase;          external 'APLZHD' index indexAPMISC + 18;
function PadCh;             external 'APLZHD' index indexAPMISC + 19;
function Search;            external 'APLZHD' index indexAPMISC + 20;
function AddBackSlash;      external 'APLZHD' index indexAPMISC + 21;
function JustPathname;      external 'APLZHD' index indexAPMISC + 22;
function DefaultExtension;  external 'APLZHD' index indexAPMISC + 23;
function HexW;              external 'APLZHD' index indexAPMISC + 24;
function HexL;              external 'APLZHD' index indexAPMISC + 25;
function JustFilename;      external 'APLZHD' index indexAPMISC + 26;
function ExistFile;         external 'APLZHD' index indexAPMISC + 27;
function StringToHeap;      external 'APLZHD' index indexAPMISC + 28;
procedure DisposeString;    external 'APLZHD' index indexAPMISC + 29;
function CheckRange;        external 'APLZHD' index indexAPMISC + 30;
function GetAsyncStatus;    external 'APLZHD' index indexAPMISC + 31;
procedure SetAsyncStatus;   external 'APLZHD' index indexAPMISC + 32;
function GetArchiveStatus;  external 'APLZHD' index indexAPMISC + 33;
procedure SetArchiveStatus; external 'APLZHD' index indexAPMISC + 34;
function GetAproFileMode;   external 'APCOMD' index indexAPMISC + 35;  {!!.03}
procedure SetAproFileMode;  external 'APCOMD' index indexAPMISC + 36;  {!!.03}
function ExtractWord;       external 'APCOMD' index indexAPMISC + 37;  {!!.03}
function WordPosition;      external 'APCOMD' index indexAPMISC + 38;  {!!.03}

{from APARCHIV}
procedure InitFileMaskList;   external 'APLZHD' index indexAPARCHIV + 1;
procedure DoneFileMaskList;   external 'APLZHD' index indexAPARCHIV + 2;
function AppendFileMask;      external 'APLZHD' index indexAPARCHIV + 3;
function MatchFileMask;       external 'APLZHD' index indexAPARCHIV + 4;
procedure SortFileMaskList;   external 'APLZHD' index indexAPARCHIV + 5;
procedure ExpandFileMaskList; external 'APLZHD' index indexAPARCHIV + 6;
procedure arOptionsOn;        external 'APLZHD' index indexAPARCHIV + 7;
procedure arOptionsOff;       external 'APLZHD' index indexAPARCHIV + 8;
function arOptionsAreOn;      external 'APLZHD' index indexAPARCHIV + 9;
procedure SetOutputPath;      external 'APLZHD' index indexAPARCHIV + 10;
procedure CreateOutputFile;   external 'APLZHD' index indexAPARCHIV + 11;
function Percentage;          external 'APZIPD' index indexAPARCHIV + 12;{!!.01}

{from APLZH}
procedure InitLzhFile;               external 'APLZHD' index indexAPLZH + 1;
procedure CreateLzhFile;             external 'APLZHD' index indexAPLZH + 2;
procedure DoneLzhFile;               external 'APLZHD' index indexAPLZH + 3;
procedure ExtractLzh;                external 'APLZHD' index indexAPLZH + 4;
procedure ExtractFileMaskListLzh;    external 'APLZHD' index indexAPLZH + 5;
procedure CompressLzh;               external 'APLZHD' index indexAPLZH + 6;
procedure CompressFileMaskListLzh;   external 'APLZHD' index indexAPLZH + 7;
procedure DeleteFilesLzh;            external 'APLZHD' index indexAPLZH + 8;
procedure DeleteFileMaskListLzh;     external 'APLZHD' index indexAPLZH + 9;
procedure FreshenArchiveLzh;         external 'APLZHD' index indexAPLZH + 10;
procedure SetCompressionModeLzh;     external 'APLZHD' index indexAPLZH + 11;
function lhaMemRequired;             external 'APLZHD' index indexAPLZH + 12;
procedure InitLzhFileList;           external 'APLZHD' index indexAPLZH + 13;
procedure BuildLzhFileList;          external 'APLZHD' index indexAPLZH + 14;
procedure DeleteLzhFileListNode;     external 'APLZHD' index indexAPLZH + 15;
procedure ExtractLzhFileList;        external 'APLZHD' index indexAPLZH + 16;
procedure DoneLzhFileList;           external 'APLZHD' index indexAPLZH + 17;
procedure SetOkToWriteFuncLzh;       external 'APLZHD' index indexAPLZH + 18;
procedure SetShowNameProcLzh;        external 'APLZHD' index indexAPLZH + 19;
procedure SetShowMethodProcLzh;      external 'APLZHD' index indexAPLZH + 20;
procedure SetExtractSuccessFuncLzh;  external 'APLZHD' index indexAPLZH + 21;
procedure SetShowProgressFuncLzh;    external 'APLZHD' index indexAPLZH + 22;
procedure SetOkToCompressFuncLzh;    external 'APLZHD' index indexAPLZH + 23;
procedure SetCompressSuccessFuncLzh; external 'APLZHD' index indexAPLZH + 24;
procedure SetProgressWidth;          external 'APLZHD' index indexAPLZH + 25;
procedure DefShowMethodProcLzh;      external 'APLZHD' index indexAPLZH + 26;
function DefExtractSuccessFuncLzh;   external 'APLZHD' index indexAPLZH + 27;
function DefCompressSuccessFuncLzh;  external 'APLZHD' index indexAPLZH + 28;
function DefOkToWriteFuncLzh;        external 'APLZHD' index indexAPLZH + 29;
procedure DefShowNameProcLzh;        external 'APLZHD' index indexAPLZH + 30;
function DefShowProgressFuncLzh;     external 'APLZHD' index indexAPLZH + 31;
function DefOkToCompressFuncLzh;     external 'APLZHD' index indexAPLZH + 32;

end.
