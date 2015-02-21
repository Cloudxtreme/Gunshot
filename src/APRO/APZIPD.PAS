{$S-,R-,V-,I-}

{$I APDEFINE.INC}

{$IFNDEF DPMI}
  !! STOP COMPILE - this unit is for protected mode only
{$ENDIF}

{$IFNDEF UsePModeDLL}
  !! STOP COMPILE - this import unit requires UsePModeDLL to be defined
{$ENDIF}

{*********************************************************}
{*                   APZIPD.PAS 2.03                     *}
{*          Copyright (c) TurboPower Software.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApZipD;

interface

uses
  Dos;

{$UNDEF UsePModeDLL}
{$DEFINE CompilingImport}
{$I APMISC.PA0}
{$I APARCHIV.PA0}
{$I APZIP.PA0}
{$UNDEF CompilingImport}
{$DEFINE UsePModeDLL}

implementation

{from APMISC}
function StatusStr;         external 'APZIPD' index indexAPMISC + 1;
function UpdateChecksum;    external 'APZIPD' index indexAPMISC + 2;
function UpdateCrC;         external 'APZIPD' index indexAPMISC + 3;
function UpdateCrcKermit;   external 'APZIPD' index indexAPMISC + 4;
function GlobalAllocCheck;  external 'APZIPD' index indexAPMISC + 5;
procedure GlobalFreeCheck;  external 'APZIPD' index indexAPMISC + 6;
function GetMemCheck;       external 'APZIPD' index indexAPMISC + 7;
procedure FreeMemCheck;     external 'APZIPD' index indexAPMISC + 8;
function IsLeapYear;        external 'APZIPD' index indexAPMISC + 9;
function DaysInMonth;       external 'APZIPD' index indexAPMISC + 10;
function ValidDate;         external 'APZIPD' index indexAPMISC + 11;
function DMYtoDate;         external 'APZIPD' index indexAPMISC + 12;
procedure DateToDMY;        external 'APZIPD' index indexAPMISC + 13;
procedure DateTimeDiff;     external 'APZIPD' index indexAPMISC + 14;
procedure TimeToHMS;        external 'APZIPD' index indexAPMISC + 15;
function HMStoTime;         external 'APZIPD' index indexAPMISC + 16;
procedure IncDateTime;      external 'APZIPD' index indexAPMISC + 17;
function StUpcase;          external 'APZIPD' index indexAPMISC + 18;
function PadCh;             external 'APZIPD' index indexAPMISC + 19;
function Search;            external 'APZIPD' index indexAPMISC + 20;
function AddBackSlash;      external 'APZIPD' index indexAPMISC + 21;
function JustPathname;      external 'APZIPD' index indexAPMISC + 22;
function DefaultExtension;  external 'APZIPD' index indexAPMISC + 23;
function HexW;              external 'APZIPD' index indexAPMISC + 24;
function HexL;              external 'APZIPD' index indexAPMISC + 25;
function JustFilename;      external 'APZIPD' index indexAPMISC + 26;
function ExistFile;         external 'APZIPD' index indexAPMISC + 27;
function StringToHeap;      external 'APZIPD' index indexAPMISC + 28;
procedure DisposeString;    external 'APZIPD' index indexAPMISC + 29;
function CheckRange;        external 'APZIPD' index indexAPMISC + 30;
function GetAsyncStatus;    external 'APZIPD' index indexAPMISC + 31;
procedure SetAsyncStatus;   external 'APZIPD' index indexAPMISC + 32;
function GetArchiveStatus;  external 'APZIPD' index indexAPMISC + 33;
procedure SetArchiveStatus; external 'APZIPD' index indexAPMISC + 34;
function GetAproFileMode;   external 'APCOMD' index indexAPMISC + 35;  {!!.03}
procedure SetAproFileMode;  external 'APCOMD' index indexAPMISC + 36;  {!!.03}
function ExtractWord;       external 'APCOMD' index indexAPMISC + 37;  {!!.03}
function WordPosition;      external 'APCOMD' index indexAPMISC + 38;  {!!.03}

{from APARCHIV}
procedure InitFileMaskList;   external 'APZIPD' index indexAPARCHIV + 1;
procedure DoneFileMaskList;   external 'APZIPD' index indexAPARCHIV + 2;
function AppendFileMask;      external 'APZIPD' index indexAPARCHIV + 3;
function MatchFileMask;       external 'APZIPD' index indexAPARCHIV + 4;
procedure SortFileMaskList;   external 'APZIPD' index indexAPARCHIV + 5;
procedure ExpandFileMaskList; external 'APZIPD' index indexAPARCHIV + 6;
procedure arOptionsOn;        external 'APZIPD' index indexAPARCHIV + 7;
procedure arOptionsOff;       external 'APZIPD' index indexAPARCHIV + 8;
function arOptionsAreOn;      external 'APZIPD' index indexAPARCHIV + 9;
procedure SetOutputPath;      external 'APZIPD' index indexAPARCHIV + 10;
procedure CreateOutputFile;   external 'APZIPD' index indexAPARCHIV + 11;
function Percentage;          external 'APZIPD' index indexAPARCHIV + 12;{!!.01}

{from APZIP}
procedure InitZipFile;            external 'APZIPD' index indexAPZIP + 1;
procedure CreateZipFile;          external 'APZIPD' index indexAPZIP + 2;
procedure DoneZipFile;            external 'APZIPD' index indexAPZIP + 3;
procedure ExtractFileMaskListZip; external 'APZIPD' index indexAPZIP + 4;
procedure ExtractZip;             external 'APZIPD' index indexAPZIP + 5;
procedure CompressFileMaskListZip;external 'APZIPD' index indexAPZIP + 6;
procedure CompressZip;            external 'APZIPD' index indexAPZIP + 7;
procedure FreshenArchiveZip;      external 'APZIPD' index indexAPZIP + 8;
procedure DeleteFileMaskListZip;  external 'APZIPD' index indexAPZIP + 9;
procedure DeleteFilesZip;         external 'APZIPD' index indexAPZIP + 10;
procedure SetZipComment;          external 'APZIPD' index indexAPZIP + 11;
procedure UpdateCommentsFileMaskList; external 'APZIPD' index indexAPZIP + 12;
procedure InitZipFileList;        external 'APZIPD' index indexAPZIP + 13;
procedure BuildZipFileList;       external 'APZIPD' index indexAPZIP + 14;
procedure DeleteZipFileListNode;  external 'APZIPD' index indexAPZIP + 15;
procedure ExtractZipFileList;     external 'APZIPD' index indexAPZIP + 16;
procedure DoneZipFileList;        external 'APZIPD' index indexAPZIP + 17;
procedure SetOkToWriteFuncZip;    external 'APZIPD' index indexAPZIP + 18;
procedure SetShowCommentsProcZip; external 'APZIPD' index indexAPZIP + 19;
procedure SetShowMethodProcZip;   external 'APZIPD' index indexAPZIP + 20;
procedure SetExtractSuccessFuncZip;external 'APZIPD' index indexAPZIP + 21;
procedure SetShowProgressFuncZip; external 'APZIPD' index indexAPZIP + 22;
procedure SetOkToCompressFuncZip; external 'APZIPD' index indexAPZIP + 23;
procedure SetCompressSuccessFuncZip;external 'APZIPD' index indexAPZIP + 24;
procedure SetFileCommentFuncZip;  external 'APZIPD' index indexAPZIP + 25;
procedure SetCompressionModeZip;  external 'APZIPD' index indexAPZIP + 26;
procedure SetImplodeFactors;      external 'APZIPD' index indexAPZIP + 27;
procedure DefShowMethodProcZip;   external 'APZIPD' index indexAPZIP + 28;
function DefExtractSuccessFuncZip;external 'APZIPD' index indexAPZIP + 29;
function DefOkToWriteFuncZip;     external 'APZIPD' index indexAPZIP + 30;
procedure DefShowCommentsProcZip; external 'APZIPD' index indexAPZIP + 31;
function DefShowProgressFuncZip;  external 'APZIPD' index indexAPZIP + 32;
function DefCompressSuccessFuncZip;external 'APZIPD' index indexAPZIP + 33;
function DefOkToCompressFuncZip;  external 'APZIPD' index indexAPZIP + 34;
function DefFileCommentFuncZip;   external 'APZIPD' index indexAPZIP + 35;
procedure ImplodeFile;            external 'APZIPD' index indexAPZIP + 36;
procedure DeflateFile;            external 'APZIPD' index indexAPZIP + 37;{!!.01}
procedure InflateFile;            external 'APZIPD' index indexAPZIP + 38;{!!.01}
procedure SetDeflateLevel;        external 'APZIPD' index indexAPZIP + 39;{!!.01}

end.
