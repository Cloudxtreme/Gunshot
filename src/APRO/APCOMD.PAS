{$S-,R-,V-,I-}

{$I APDEFINE.INC}

{$IFNDEF DPMI}
  !! STOP COMPILE - this unit is for protected mode only
{$ENDIF}

{$IFNDEF UsePModeDLL}
  !! STOP COMPILE - this import unit requires UsePModeDLL to be defined
{$ENDIF}

{*********************************************************}
{*                   APCOMD.PAS 2.03                     *}
{*     Copyright (c) TurboPower Software 1993.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApComD;

interface

uses
  Dos;

{$UNDEF UsePModeDLL}
{$DEFINE CompilingImport}
{$I APMISC.PA0}
{$I APPORT.PA0}
{$I APTIMER.PA0}
{$IFDEF UseUart}
{$I APUART.PA0}
{$ENDIF}
{$IFDEF UseFossil}
{$I APFOSSIL.PA0}
{$ENDIF}
{$IFDEF UseDigi14}
{$I APDIGI14.PA0}
{$ENDIF}
{$IFDEF UseInt14}
{$I APINT14.PA0}
{$ENDIF}
{$I APCOM.PA0}
{$I APINI.PA0}
{$I APINIDB.PA0}
{$I APMODDB.PA0}
{$I APMODEM2.PA0}
{$UNDEF CompilingImport}
{$DEFINE UsePModeDLL}

{$IFDEF UseUart}
procedure ActivateApUartDLL;
{$ENDIF}
{$IFDEF UseFossil}
procedure ActivateApFossilDLL;
{$ENDIF}
{$IFDEF UseDigi14}
procedure ActivateApDigi14DLL;
{$ENDIF}
{$IFDEF UseInt14}
procedure ActivateApInt14DLL;
{$ENDIF}

implementation

{from APMISC}
function StatusStr;               external 'APCOMD' index indexAPMISC + 1;
function UpdateChecksum;          external 'APCOMD' index indexAPMISC + 2;
function UpdateCrC;               external 'APCOMD' index indexAPMISC + 3;
function UpdateCrcKermit;         external 'APCOMD' index indexAPMISC + 4;
function GlobalAllocCheck;        external 'APCOMD' index indexAPMISC + 5;
procedure GlobalFreeCheck;        external 'APCOMD' index indexAPMISC + 6;
function GetMemCheck;             external 'APCOMD' index indexAPMISC + 7;
procedure FreeMemCheck;           external 'APCOMD' index indexAPMISC + 8;
function IsLeapYear;              external 'APCOMD' index indexAPMISC + 9;
function DaysInMonth;             external 'APCOMD' index indexAPMISC + 10;
function ValidDate;               external 'APCOMD' index indexAPMISC + 11;
function DMYtoDate;               external 'APCOMD' index indexAPMISC + 12;
procedure DateToDMY;              external 'APCOMD' index indexAPMISC + 13;
procedure DateTimeDiff;           external 'APCOMD' index indexAPMISC + 14;
procedure TimeToHMS;              external 'APCOMD' index indexAPMISC + 15;
function HMStoTime;               external 'APCOMD' index indexAPMISC + 16;
procedure IncDateTime;            external 'APCOMD' index indexAPMISC + 17;
function StUpcase;                external 'APCOMD' index indexAPMISC + 18;
function PadCh;                   external 'APCOMD' index indexAPMISC + 19;
function Search;                  external 'APCOMD' index indexAPMISC + 20;
function AddBackSlash;            external 'APCOMD' index indexAPMISC + 21;
function JustPathname;            external 'APCOMD' index indexAPMISC + 22;
function DefaultExtension;        external 'APCOMD' index indexAPMISC + 23;
function HexW;                    external 'APCOMD' index indexAPMISC + 24;
function HexL;                    external 'APCOMD' index indexAPMISC + 25;
function JustFilename;            external 'APCOMD' index indexAPMISC + 26;
function ExistFile;               external 'APCOMD' index indexAPMISC + 27;
function StringToHeap;            external 'APCOMD' index indexAPMISC + 28;
procedure DisposeString;          external 'APCOMD' index indexAPMISC + 29;
function CheckRange;              external 'APCOMD' index indexAPMISC + 30;
function GetAsyncStatus;          external 'APCOMD' index indexAPMISC + 31;
procedure SetAsyncStatus;         external 'APCOMD' index indexAPMISC + 32;
function GetArchiveStatus;        external 'APCOMD' index indexAPMISC + 33;
procedure SetArchiveStatus;       external 'APCOMD' index indexAPMISC + 34;
function GetAproFileMode;         external 'APCOMD' index indexAPMISC + 35; {!!.03}
procedure SetAproFileMode;        external 'APCOMD' index indexAPMISC + 36; {!!.03}
function ExtractWord;             external 'APCOMD' index indexAPMISC + 37; {!!.03}
function WordPosition;            external 'APCOMD' index indexAPMISC + 38; {!!.03}

{from APPORT}
function IsPS2;                   external 'APCOMD' index indexAPPORT + 1;
function ComNameString;           external 'APCOMD' index indexAPPORT + 2;
function CheckForString;          external 'APCOMD' index indexAPPORT + 3;
procedure RotateIrqPriority;      external 'APCOMD' index indexAPPORT + 4;
{$IFDEF Tracing}
procedure ClearTracing;           external 'APCOMD' index indexAPPORT + 5;
procedure AbortTracing;           external 'APCOMD' index indexAPPORT + 6;
procedure InitTracing;            external 'APCOMD' index indexAPPORT + 7;
procedure AddTraceEntry;          external 'APCOMD' index indexAPPORT + 8;
procedure DumpTrace;              external 'APCOMD' index indexAPPORT + 9;
procedure DumpTraceHex;           external 'APCOMD' index indexAPPORT + 10;
procedure StartTracing;           external 'APCOMD' index indexAPPORT + 11;
procedure StopTracing;            external 'APCOMD' index indexAPPORT + 12;
procedure AppendTrace;            external 'APCOMD' index indexAPPORT + 13; {!!.02}
procedure AppendTraceHex;         external 'APCOMD' index indexAPPORT + 14; {!!.02}
{$ENDIF}
function NoAbortFunc;             external 'APCOMD' index indexAPPORT + 15; {!!.03}
procedure NoErrorProc;            external 'APCOMD' index indexAPPORT + 16; {!!.03}
procedure GetProcPointers;        external 'APCOMD' index indexAPPORT + 17; {!!.03}
procedure SetPs2DetectMode;       external 'APCOMD' index indexAPPORT + 18; {!!.03}

{from APTIMER}
function Tics2Secs;               external 'APCOMD' index indexAPTIMER + 1;
function Secs2Tics;               external 'APCOMD' index indexAPTIMER + 2;
procedure NewTimer;               external 'APCOMD' index indexAPTIMER + 3;
procedure NewTimerSecs;           external 'APCOMD' index indexAPTIMER + 4;
function TimerExpired;            external 'APCOMD' index indexAPTIMER + 5;
function ElapsedTime;             external 'APCOMD' index indexAPTIMER + 6;
function ElapsedTimeInSecs;       external 'APCOMD' index indexAPTIMER + 7;
function ElapsedTimeInMSecs;      external 'APCOMD' index indexAPTIMER + 8;
function RemainingTime;           external 'APCOMD' index indexAPTIMER + 9;
function RemainingTimeInSecs;     external 'APCOMD' index indexAPTIMER + 10;
function RemainingTimeInMSecs;    external 'APCOMD' index indexAPTIMER + 11;
procedure DelayTics;              external 'APCOMD' index indexAPTIMER + 12;
procedure Delay;                  external 'APCOMD' index indexAPTIMER + 13;
procedure CalibrateDelay;         external 'APCOMD' index indexAPTIMER + 14;

{$IFDEF UseUart}
{from APUART}
procedure uInitPort;              external 'APCOMD' index indexAPUART + 1;
procedure uInitPortKeep;          external 'APCOMD' index indexAPUART + 2;
procedure uDonePort;              external 'APCOMD' index indexAPUART + 3;
procedure uSetUart;               external 'APCOMD' index indexAPUART + 4;
procedure uSetLine;               external 'APCOMD' index indexAPUART + 5;
procedure uGetLine;               external 'APCOMD' index indexAPUART + 6;
procedure uSetModem;              external 'APCOMD' index indexAPUART + 7;
procedure uGetModem;              external 'APCOMD' index indexAPUART + 8;
procedure uGetChar;               external 'APCOMD' index indexAPUART + 9;
procedure uPeekChar;              external 'APCOMD' index indexAPUART + 10;
procedure uPutChar;               external 'APCOMD' index indexAPUART + 11;
procedure uStartTransmitter;      external 'APCOMD' index indexAPUART + 12;
function uCharReady;              external 'APCOMD' index indexAPUART + 13;
function uTransReady;             external 'APCOMD' index indexAPUART + 14;
procedure uSendBreak;             external 'APCOMD' index indexAPUART + 15;
procedure uActivatePort;          external 'APCOMD' index indexAPUART + 16;
procedure uDeactivatePort;        external 'APCOMD' index indexAPUART + 17;
procedure uSavePort;              external 'APCOMD' index indexAPUART + 18;
procedure uRestorePort;           external 'APCOMD' index indexAPUART + 19;
procedure uGotError;              external 'APCOMD' index indexAPUART + 20;
function uUpdateLineStatus;       external 'APCOMD' index indexAPUART + 21;
function uUpdateModemStatus;      external 'APCOMD' index indexAPUART + 22;
{$IFDEF UseHWFlow}
procedure uHWFlowSet;             external 'APCOMD' index indexAPUART + 23;
function uHWFlowGet;              external 'APCOMD' index indexAPUART + 24;
{$ENDIF}
{$IFDEF UseSWFlow}
procedure uSWFlowSet;             external 'APCOMD' index indexAPUART + 25;
function uSWFlowGet;              external 'APCOMD' index indexAPUART + 26;
procedure uSWFlowCtl;             external 'APCOMD' index indexAPUART + 27;
{$ENDIF}
procedure uBufferStatus;          external 'APCOMD' index indexAPUART + 28;
procedure uBufferFlush;           external 'APCOMD' index indexAPUART + 29;
procedure ActivateApUart;         external 'APCOMD' index indexAPUART + 30;
function UartTest1;               external 'APCOMD' index indexAPUART + 31;
function UartTest2;               external 'APCOMD' index indexAPUART + 32;
function UartTest3;               external 'APCOMD' index indexAPUART + 33;
function ClassifyUart;            external 'APCOMD' index indexAPUART + 34;
procedure SetFifoBuffering;       external 'APCOMD' index indexAPUART + 35;
function FifoStatus;              external 'APCOMD' index indexAPUART + 36;
procedure SaveUartState;          external 'APCOMD' index indexAPUART + 37;
procedure RestoreUartState;       external 'APCOMD' index indexAPUART + 38;
function GetLineStatusDirect;     external 'APCOMD' index indexAPUART + 39;
function CheckTEDirect;           external 'APCOMD' index indexAPUART + 40;
function GetModemStatusDirect;    external 'APCOMD' index indexAPUART + 41;
procedure SendLongBreak;          external 'APCOMD' index indexAPUART + 42;
{$IFDEF EventLogging}
procedure InitEventLogging;       external 'APCOMD' index indexAPUART + 43;
procedure DumpEvents;             external 'APCOMD' index indexAPUART + 44;
{$ENDIF}
{$ENDIF}

{$IFDEF UseFossil}
{from APFOSSIL}
procedure fInitPort;              external 'APCOMD' index indexAPFOSSIL + 1;
procedure fInitPortKeep;          external 'APCOMD' index indexAPFOSSIL + 2;
procedure fDonePort;              external 'APCOMD' index indexAPFOSSIL + 3;
procedure fSetUart;               external 'APCOMD' index indexAPFOSSIL + 4;
procedure fSetLine;               external 'APCOMD' index indexAPFOSSIL + 5;
procedure fGetLine;               external 'APCOMD' index indexAPFOSSIL + 6;
procedure fSetModem;              external 'APCOMD' index indexAPFOSSIL + 7;
procedure fGetModem;              external 'APCOMD' index indexAPFOSSIL + 8;
procedure fGetChar;               external 'APCOMD' index indexAPFOSSIL + 9;
procedure fPeekChar;              external 'APCOMD' index indexAPFOSSIL + 10;
procedure fPutChar;               external 'APCOMD' index indexAPFOSSIL + 11;
procedure fStartTransmitter;      external 'APCOMD' index indexAPFOSSIL + 12;
function fCharReady;              external 'APCOMD' index indexAPFOSSIL + 13;
function fTransReady;             external 'APCOMD' index indexAPFOSSIL + 14;
procedure fSendBreak;             external 'APCOMD' index indexAPFOSSIL + 15;
procedure fActivatePort;          external 'APCOMD' index indexAPFOSSIL + 16;
procedure fDeactivatePort;        external 'APCOMD' index indexAPFOSSIL + 17;
procedure fSavePort;              external 'APCOMD' index indexAPFOSSIL + 18;
procedure fRestorePort;           external 'APCOMD' index indexAPFOSSIL + 19;
procedure fGotError;              external 'APCOMD' index indexAPFOSSIL + 20;
function fUpdateLineStatus;       external 'APCOMD' index indexAPFOSSIL + 21;
function fUpdateModemStatus;      external 'APCOMD' index indexAPFOSSIL + 22;
{$IFDEF UseHWFlow}
procedure fHWFlowSet;             external 'APCOMD' index indexAPFOSSIL + 23;
function fHWFlowGet;              external 'APCOMD' index indexAPFOSSIL + 24;
{$ENDIF}
{$IFDEF UseSWFlow}
procedure fSWFlowSet;             external 'APCOMD' index indexAPFOSSIL + 25;
function fSWFlowGet;              external 'APCOMD' index indexAPFOSSIL + 26;
procedure fSWFlowCtl;             external 'APCOMD' index indexAPFOSSIL + 27;
{$ENDIF}
procedure fBufferStatus;          external 'APCOMD' index indexAPFOSSIL + 28;
procedure fBufferFlush;           external 'APCOMD' index indexAPFOSSIL + 29;
procedure ActivateApFossil;       external 'APCOMD' index indexAPFOSSIL + 30;
procedure FossilIntr;             external 'APCOMD' index indexAPFOSSIL + 31;
{$ENDIF}

{$IFDEF UseDigi14}
{from APDIGI14}
procedure dInitPort;              external 'APCOMD' index indexAPDIGI14 + 1;
procedure dInitPortKeep;          external 'APCOMD' index indexAPDIGI14 + 2;
procedure dDonePort;              external 'APCOMD' index indexAPDIGI14 + 3;
procedure dSetUart;               external 'APCOMD' index indexAPDIGI14 + 4;
procedure dSetLine;               external 'APCOMD' index indexAPDIGI14 + 5;
procedure dGetLine;               external 'APCOMD' index indexAPDIGI14 + 6;
procedure dSetModem;              external 'APCOMD' index indexAPDIGI14 + 7;
procedure dGetModem;              external 'APCOMD' index indexAPDIGI14 + 8;
procedure dGetChar;               external 'APCOMD' index indexAPDIGI14 + 9;
procedure dPeekChar;              external 'APCOMD' index indexAPDIGI14 + 10;
procedure dPutChar;               external 'APCOMD' index indexAPDIGI14 + 11;
procedure dStartTransmitter;      external 'APCOMD' index indexAPDIGI14 + 12;
function dCharReady;              external 'APCOMD' index indexAPDIGI14 + 13;
function dTransReady;             external 'APCOMD' index indexAPDIGI14 + 14;
procedure dSendBreak;             external 'APCOMD' index indexAPDIGI14 + 15;
procedure dActivatePort;          external 'APCOMD' index indexAPDIGI14 + 16;
procedure dDeactivatePort;        external 'APCOMD' index indexAPDIGI14 + 17;
procedure dSavePort;              external 'APCOMD' index indexAPDIGI14 + 18;
procedure dRestorePort;           external 'APCOMD' index indexAPDIGI14 + 19;
procedure dGotError;              external 'APCOMD' index indexAPDIGI14 + 20;
function dUpdateLineStatus;       external 'APCOMD' index indexAPDIGI14 + 21;
function dUpdateModemStatus;      external 'APCOMD' index indexAPDIGI14 + 22;
{$IFDEF UseHWFlow}
procedure dHWFlowSet;             external 'APCOMD' index indexAPDIGI14 + 23;
function dHWFlowGet;              external 'APCOMD' index indexAPDIGI14 + 24;
{$ENDIF}
{$IFDEF UseSWFlow}
procedure dSWFlowSet;             external 'APCOMD' index indexAPDIGI14 + 25;
function dSWFlowGet;              external 'APCOMD' index indexAPDIGI14 + 26;
procedure dSWFlowCtl;             external 'APCOMD' index indexAPDIGI14 + 27;
{$ENDIF}
procedure dBufferStatus;          external 'APCOMD' index indexAPDIGI14 + 28;
procedure dBufferFlush;           external 'APCOMD' index indexAPDIGI14 + 29;
procedure ActivateApDigi14;       external 'APCOMD' index indexAPDIGI14 + 30;
{$ENDIF}

{$IFDEF UseInt14}
{from APINT14}
procedure iInitPort;              external 'APCOMD' index indexAPINT14 + 1;
procedure iInitPortKeep;          external 'APCOMD' index indexAPINT14 + 2;
procedure iDonePort;              external 'APCOMD' index indexAPINT14 + 3;
procedure iSetUart;               external 'APCOMD' index indexAPINT14 + 4;
procedure iSetLine;               external 'APCOMD' index indexAPINT14 + 5;
procedure iGetLine;               external 'APCOMD' index indexAPINT14 + 6;
procedure iSetModem;              external 'APCOMD' index indexAPINT14 + 7;
procedure iGetModem;              external 'APCOMD' index indexAPINT14 + 8;
procedure iGetChar;               external 'APCOMD' index indexAPINT14 + 9;
procedure iPeekChar;              external 'APCOMD' index indexAPINT14 + 10;
procedure iPutChar;               external 'APCOMD' index indexAPINT14 + 11;
procedure iStartTransmitter;      external 'APCOMD' index indexAPINT14 + 12;
function iCharReady;              external 'APCOMD' index indexAPINT14 + 13;
function iTransReady;             external 'APCOMD' index indexAPINT14 + 14;
procedure iSendBreak;             external 'APCOMD' index indexAPINT14 + 15;
procedure iActivatePort;          external 'APCOMD' index indexAPINT14 + 16;
procedure iDeactivatePort;        external 'APCOMD' index indexAPINT14 + 17;
procedure iSavePort;              external 'APCOMD' index indexAPINT14 + 18;
procedure iRestorePort;           external 'APCOMD' index indexAPINT14 + 19;
procedure iGotError;              external 'APCOMD' index indexAPINT14 + 20;
function iUpdateLineStatus;       external 'APCOMD' index indexAPINT14 + 21;
function iUpdateModemStatus;      external 'APCOMD' index indexAPINT14 + 22;
{$IFDEF UseHWFlow}
procedure iHWFlowSet;             external 'APCOMD' index indexAPINT14 + 23;
function iHWFlowGet;              external 'APCOMD' index indexAPINT14 + 24;
{$ENDIF}
{$IFDEF UseSWFlow}
procedure iSWFlowSet;             external 'APCOMD' index indexAPINT14 + 25;
function iSWFlowGet;              external 'APCOMD' index indexAPINT14 + 26;
procedure iSWFlowCtl;             external 'APCOMD' index indexAPINT14 + 27;
{$ENDIF}
procedure iBufferStatus;          external 'APCOMD' index indexAPINT14 + 28;
procedure iBufferFlush;           external 'APCOMD' index indexAPINT14 + 29;
procedure ActivateApInt14;        external 'APCOMD' index indexAPINT14 + 30;
{$ENDIF}

{from APCOM}
procedure InitPortFast;           external 'APCOMD' index indexAPCOM + 1;
procedure ChangeBaud;             external 'APCOMD' index indexAPCOM + 2;
procedure ChangeParity;           external 'APCOMD' index indexAPCOM + 3;
procedure ChangeDataBits;         external 'APCOMD' index indexAPCOM + 4;
procedure ChangeStopBits;         external 'APCOMD' index indexAPCOM + 5;
procedure ChangeBufferSizes;      external 'APCOMD' index indexAPCOM + 6;
procedure ForceBufferLimits;      external 'APCOMD' index indexAPCOM + 7;
function BlockReady;              external 'APCOMD' index indexAPCOM + 8;
function GetDelimLoc;             external 'APCOMD' index indexAPCOM + 9;
procedure GetCharTimeout;         external 'APCOMD' index indexAPCOM + 10;
procedure PeekCharTimeout;        external 'APCOMD' index indexAPCOM + 11;
procedure GetString;              external 'APCOMD' index indexAPCOM + 12;
procedure GetStringTimeout;       external 'APCOMD' index indexAPCOM + 13;
procedure GetBlock;               external 'APCOMD' index indexAPCOM + 14;
procedure GetBlockDirect;         external 'APCOMD' index indexAPCOM + 15;
procedure GetBlockTimeout;        external 'APCOMD' index indexAPCOM + 16;
procedure PutCharTimeout;         external 'APCOMD' index indexAPCOM + 17;
procedure PutString;              external 'APCOMD' index indexAPCOM + 18;
procedure PutStringTimeout;       external 'APCOMD' index indexAPCOM + 19;
procedure PutBlock;               external 'APCOMD' index indexAPCOM + 20;
procedure PutBlockTimeout;        external 'APCOMD' index indexAPCOM + 21;
procedure PutBlockDirect;         external 'APCOMD' index indexAPCOM + 22;
procedure FlushInBuffer;          external 'APCOMD' index indexAPCOM + 23;
procedure FlushOutBuffer;         external 'APCOMD' index indexAPCOM + 24;
function InBuffUsed;              external 'APCOMD' index indexAPCOM + 25;
function OutBuffUsed;             external 'APCOMD' index indexAPCOM + 26;
function InBuffFree;              external 'APCOMD' index indexAPCOM + 27;
function OutBuffFree;             external 'APCOMD' index indexAPCOM + 28;
procedure DrainOutBuffer;         external 'APCOMD' index indexAPCOM + 29;
{$IFDEF StatusBuffering}
procedure EnableStatusBuffer;     external 'APCOMD' index indexAPCOM + 30;
procedure DisableStatusBuffer;    external 'APCOMD' index indexAPCOM + 31;
function StatusBuffering;         external 'APCOMD' index indexAPCOM + 32;
{$ENDIF}
{$IFDEF UseSWFlow}
procedure SWFlowEnable;           external 'APCOMD' index indexAPCOM + 33;
procedure SWFlowEnableOpt;        external 'APCOMD' index indexAPCOM + 34;
procedure SWFlowDisable;          external 'APCOMD' index indexAPCOM + 35;
function SWFlowState;             external 'APCOMD' index indexAPCOM + 36;
procedure SWFlowResume;           external 'APCOMD' index indexAPCOM + 37;
procedure SWFlowSetChars;         external 'APCOMD' index indexAPCOM + 38;
{$ENDIF}
{$IFDEF UseHWFlow}
procedure HWFlowEnable;           external 'APCOMD' index indexAPCOM + 39;
procedure HWFlowDisable;          external 'APCOMD' index indexAPCOM + 40;
function HWFlowState;             external 'APCOMD' index indexAPCOM + 41;
{$ENDIF}
procedure SetDTR;                 external 'APCOMD' index indexAPCOM + 42;
procedure SetRTS;                 external 'APCOMD' index indexAPCOM + 43;
function GetModemControl;         external 'APCOMD' index indexAPCOM + 44;
function GetModemStatusPrim;      external 'APCOMD' index indexAPCOM + 45;
function GetModemStatus;          external 'APCOMD' index indexAPCOM + 46;
function CheckCTS;                external 'APCOMD' index indexAPCOM + 47;
function CheckDSR;                external 'APCOMD' index indexAPCOM + 48;
function CheckRI;                 external 'APCOMD' index indexAPCOM + 49;
function CheckDCD;                external 'APCOMD' index indexAPCOM + 50;
function CheckDeltaCTS;           external 'APCOMD' index indexAPCOM + 51;
function CheckDeltaDSR;           external 'APCOMD' index indexAPCOM + 52;
function CheckDeltaRI;            external 'APCOMD' index indexAPCOM + 53;
function CheckDeltaDCD;           external 'APCOMD' index indexAPCOM + 54;
function GetLineControl;          external 'APCOMD' index indexAPCOM + 55;
function GetLineStatus;           external 'APCOMD' index indexAPCOM + 56;
function CheckDataReady;          external 'APCOMD' index indexAPCOM + 57;
function CheckLineError;          external 'APCOMD' index indexAPCOM + 58;
function GetLineError;            external 'APCOMD' index indexAPCOM + 59;
function CheckLineBreak;          external 'APCOMD' index indexAPCOM + 60;
function CheckTHRE;               external 'APCOMD' index indexAPCOM + 61;
function CheckTE;                 external 'APCOMD' index indexAPCOM + 62;
function CheckFifoError;          external 'APCOMD' index indexAPCOM + 63;
function GetComName;              external 'APCOMD' index indexAPCOM + 64;
function GetBaseAddr;             external 'APCOMD' index indexAPCOM + 65;
procedure SetErrorProc;           external 'APCOMD' index indexAPCOM + 66;
procedure WaitForChar;            external 'APCOMD' index indexAPCOM + 67;
procedure WaitForString;          external 'APCOMD' index indexAPCOM + 68;
procedure WaitForMultiString;     external 'APCOMD' index indexAPCOM + 69;
procedure SetAbortFunc;           external 'APCOMD' index indexAPCOM + 70;
procedure SetWaitCharProc;        external 'APCOMD' index indexAPCOM + 71;
procedure ptOptionsOn;            external 'APCOMD' index indexAPCOM + 72;
procedure ptOptionsOff;           external 'APCOMD' index indexAPCOM + 73;
function ptOptionsAreOn;          external 'APCOMD' index indexAPCOM + 74;
function ProtocolInProgress;      external 'APCOMD' index indexAPCOM + 75;
function FaxInProgress;           external 'APCOMD' index indexAPCOM + 76;
function WaitComplete;            external 'APCOMD' index indexAPCOM + 77;
procedure NoWaitChar;             external 'APCOMD' index indexAPCOM + 78;

{from APINI}
procedure InitIniMgr;             external 'APCOMD' index indexAPINI + 1;
procedure DoneIniMgr;             external 'APCOMD' index indexAPINI + 2;
procedure FlushFile;              external 'APCOMD' index indexAPINI + 3;
procedure SetFlushMode;           external 'APCOMD' index indexAPINI + 4;
procedure ChangeFileName;         external 'APCOMD' index indexAPINI + 5;
function GetFileName;             external 'APCOMD' index indexAPINI + 6;
procedure ForceUpd;               external 'APCOMD' index indexAPINI + 7;
function GetProfileString;        external 'APCOMD' index indexAPINI + 8;
function GetProfileBool;          external 'APCOMD' index indexAPINI + 9;
function GetProfileByte;          external 'APCOMD' index indexAPINI + 10;
function GetProfileInt;           external 'APCOMD' index indexAPINI + 11;
function GetProfileWord;          external 'APCOMD' index indexAPINI + 12;
function GetProfileLong;          external 'APCOMD' index indexAPINI + 13;
procedure SetProfileString;       external 'APCOMD' index indexAPINI + 14;
procedure AddProfileString;       external 'APCOMD' index indexAPINI + 15;
procedure EnumGroups;             external 'APCOMD' index indexAPINI + 16;
procedure EnumGroupItems;         external 'APCOMD' index indexAPINI + 17;
procedure DeleteProfileString;    external 'APCOMD' index indexAPINI + 18;
procedure DeleteProfileGroup;     external 'APCOMD' index indexAPINI + 19;
function Modified;                external 'APCOMD' index indexAPINI + 20;
procedure InitIniLinePtr;         external 'APCOMD' index indexAPINI + 21;
procedure DoneIniLinePtr;         external 'APCOMD' index indexAPINI + 22;

{from APINIDB}
procedure InitIniDataBase;        external 'APCOMD' index indexAPINIDB + 1;
procedure DoneIniDatabase;        external 'APCOMD' index indexAPINIDB + 2;
procedure AddIniDBStringField;    external 'APCOMD' index indexAPINIDB + 3;
procedure AddIniDBIntField;       external 'APCOMD' index indexAPINIDB + 4;
procedure PrepareIniDatabase;     external 'APCOMD' index indexAPINIDB + 5;
procedure ChangeIniDefaults;      external 'APCOMD' index indexAPINIDB + 6;
function KeyExists;               external 'APCOMD' index indexAPINIDB + 7;
procedure AddIniRecord;           external 'APCOMD' index indexAPINIDB + 8;
procedure UpdIniRecord;           external 'APCOMD' index indexAPINIDB + 9;
procedure DelIniRecord;           external 'APCOMD' index indexAPINIDB + 10;
procedure GetIniRecord;           external 'APCOMD' index indexAPINIDB + 11;
function NumIniRecs;              external 'APCOMD' index indexAPINIDB + 12;
procedure WriteToIni;             external 'APCOMD' index indexAPINIDB + 13;
procedure ReadFromIni;            external 'APCOMD' index indexAPINIDB + 14;
procedure FlushIniDBFile;         external 'APCOMD' index indexAPINIDB + 15;
procedure SetIniDBFileName;       external 'APCOMD' index indexAPINIDB + 16;

{from APMODDB}
procedure InitModemDB;            external 'APCOMD' index indexAPMODDB + 1;
procedure DoneModemDB;            external 'APCOMD' index indexAPMODDB + 2;
procedure AddModem;               external 'APCOMD' index indexAPMODDB + 3;
procedure UpdModem;               external 'APCOMD' index indexAPMODDB + 4;
procedure DelModem;               external 'APCOMD' index indexAPMODDB + 5;
procedure RetrieveModem;          external 'APCOMD' index indexAPMODDB + 6;
function NumModems;               external 'APCOMD' index indexAPMODDB + 7;
procedure WriteModemToIni;        external 'APCOMD' index indexAPMODDB + 8;
procedure ReadModemFromIni;       external 'APCOMD' index indexAPMODDB + 9;
procedure FlushModDBFile;         external 'APCOMD' index indexAPMODDB + 10;
procedure SetModDBFileName;       external 'APCOMD' index indexAPMODDB + 11;

{from APMODEM2}
procedure InitModem;              external 'APCOMD' index indexAPMODEM2 + 1;
procedure DoneModem;              external 'APCOMD' index indexAPMODEM2 + 2;
procedure SetDialTimeout;         external 'APCOMD' index indexAPMODEM2 + 3;
procedure SetAnswerTimeout;       external 'APCOMD' index indexAPMODEM2 + 4;
procedure SetDelayFactor;         external 'APCOMD' index indexAPMODEM2 + 5;
procedure SetCmdTimeout;          external 'APCOMD' index indexAPMODEM2 + 6;
procedure SetDTRDropHold;         external 'APCOMD' index indexAPMODEM2 + 7;
procedure SetCharDelay;           external 'APCOMD' index indexAPMODEM2 + 8;
procedure SetTildeDelay;          external 'APCOMD' index indexAPMODEM2 + 9;
procedure SetRingWaitTimeout;     external 'APCOMD' index indexAPMODEM2 + 10;
procedure SetStatusProc;          external 'APCOMD' index indexAPMODEM2 + 11;
procedure PutCommand;             external 'APCOMD' index indexAPMODEM2 + 12;
procedure Initialize;             external 'APCOMD' index indexAPMODEM2 + 13;
function NumConfigStrings;        external 'APCOMD' index indexAPMODEM2 + 14;
function GetConfigString;         external 'APCOMD' index indexAPMODEM2 + 15;
procedure Configure;              external 'APCOMD' index indexAPMODEM2 + 16;
procedure HangUp;                 external 'APCOMD' index indexAPMODEM2 + 17;
procedure Dial;                   external 'APCOMD' index indexAPMODEM2 + 18;
procedure SendCancel;             external 'APCOMD' index indexAPMODEM2 + 19;
function GetConnectSpeed;         external 'APCOMD' index indexAPMODEM2 + 20;
function GetDataCompression;      external 'APCOMD' index indexAPMODEM2 + 21;
function GetErrorCorrection;      external 'APCOMD' index indexAPMODEM2 + 22;
function ModemWorking;            external 'APCOMD' index indexAPMODEM2 + 23;
procedure Answer;                 external 'APCOMD' index indexAPMODEM2 + 24;
procedure AutoAnswer;             external 'APCOMD' index indexAPMODEM2 + 25;
function ProcessCommandResponse;  external 'APCOMD' index indexAPMODEM2 + 26;
procedure ProcessConnectResponse; external 'APCOMD' index indexAPMODEM2 + 27;

  {$IFDEF UseUart}
  procedure ActivateApUartDLL;
  begin
    ActivateApUart;
    GetProcPointers(InitPort,    InitPortKeep,  DonePort,         SetLine,
                    GetLine,     SetModem,      GetModem,         GetChar,
                    PeekChar,    PutChar,       StartTransmitter, CharReady,
                    TransReady,  SendBreak,     ActivatePort,     DeactivatePort,
                    SavePort,    RestorePort,   GotError,         UpdateLineStatus,
                    UpdateModemStatus,          HWFlowSet,        HWFlowGet,
                    SWFlowSet,   SWFlowGet,     SWFlowCtl,        BufferStatus,
                    BufferFlush, SetUart,       AnsiOutput);
  end;
  {$ENDIF}

  {$IFDEF UseFossil}
  procedure ActivateApFossilDLL;
  begin
    ActivateApFossil;
    GetProcPointers(InitPort,    InitPortKeep,  DonePort,         SetLine,
                    GetLine,     SetModem,      GetModem,         GetChar,
                    PeekChar,    PutChar,       StartTransmitter, CharReady,
                    TransReady,  SendBreak,     ActivatePort,     DeactivatePort,
                    SavePort,    RestorePort,   GotError,         UpdateLineStatus,
                    UpdateModemStatus,          HWFlowSet,        HWFlowGet,
                    SWFlowSet,   SWFlowGet,     SWFlowCtl,        BufferStatus,
                    BufferFlush, SetUart,       AnsiOutput);
  end;
  {$ENDIF}

  {$IFDEF UseDigi14}
  procedure ActivateApDigi14DLL;
  begin
    ActivateApDigi14;
    GetProcPointers(InitPort,    InitPortKeep,  DonePort,         SetLine,
                    GetLine,     SetModem,      GetModem,         GetChar,
                    PeekChar,    PutChar,       StartTransmitter, CharReady,
                    TransReady,  SendBreak,     ActivatePort,     DeactivatePort,
                    SavePort,    RestorePort,   GotError,         UpdateLineStatus,
                    UpdateModemStatus,          HWFlowSet,        HWFlowGet,
                    SWFlowSet,   SWFlowGet,     SWFlowCtl,        BufferStatus,
                    BufferFlush, SetUart,       AnsiOutput);
  end;
  {$ENDIF}

  {$IFDEF UseInt14}
  procedure ActivateApInt14DLL;
  begin
    ActivateApInt14;
    GetProcPointers(InitPort,    InitPortKeep,  DonePort,         SetLine,
                    GetLine,     SetModem,      GetModem,         GetChar,
                    PeekChar,    PutChar,       StartTransmitter, CharReady,
                    TransReady,  SendBreak,     ActivatePort,     DeactivatePort,
                    SavePort,    RestorePort,   GotError,         UpdateLineStatus,
                    UpdateModemStatus,          HWFlowSet,        HWFlowGet,
                    SWFlowSet,   SWFlowGet,     SWFlowCtl,        BufferStatus,
                    BufferFlush, SetUart,       AnsiOutput);
  end;
  {$ENDIF}

begin
  {Set CRC32 table address for inline code}
  Crc32TableOfs := Ofs(Crc32Table);

  {Set a device layer}
  {$IFDEF UseInt14}
  ActivateApInt14DLL;
  {$ENDIF}
  {$IFDEF UseDigi14}
  ActivateApDigi14DLL;
  {$ENDIF}
  {$IFDEF UseFossil}
  ActivateApFossilDLL;
  {$ENDIF}
  {$IFDEF UseUart}
  ActivateApUartDLL;
  {$ENDIF}
end.
