{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                    APFOSSIL.PAS 2.03                  *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApFossil;
  {-Provides serial I/O using FOSSIL services}

interface

uses
  Dos,
  {$IFDEF DPMI}
  Dpmi,
  WinApi,
  {$ENDIF}
  {$IFDEF UseOpro}
  OpInline,
  OpRoot,
  {$ENDIF}
  {$IFDEF UseTpro}
  TpInline,
  TpMemChk,
  {$ENDIF}
  ApMisc,
  ApPort;

{$I APFOSSIL.PA0}

  {=====================================================================}

implementation

{!!.02 moved up}
{$IFDEF DPMI}
type
  DosMemRec = record
    Sele, Segm : Word;
  end;
{$ENDIF}

type
  OS = record
    Ofs,
    Seg : Word;
  end;

var
  Regs : Registers;

procedure FossilIntr(var Regs : Registers);
  {-Normal int in rmode, virtualized int in pmode}
{$IFDEF DPMI}
var
  DRegs : DPMIRegisters;
{$ENDIF}
begin
  {$IFDEF DPMI}
  FillChar(DRegs, SizeOf(DRegs), 0);
  with DRegs do begin
    AX := Regs.AX;
    BX := Regs.BX;
    CX := Regs.CX;
    DX := Regs.DX;
    ES := Regs.ES;
    DI := Regs.DI;
    if SimulateRealModeInt(FossilInt, DRegs) = 0 then ;
    Regs.AX := AX;
  end;
  {$ELSE}
  Intr(FossilInt, Regs);
  {$ENDIF}
end;

procedure fUpdateLineAndModemStatus(P : PortRecPtr);
  {-Update LineStatus and ModemStatus fields from Fossil}
begin
  with P^, Regs do begin
    AH := $03;
    DX := Ord(PortName);
    FossilIntr(Regs);

    {Refresh status values}
    ModemStatus := AL and ValidModemStatus;
    LineStatus := AH and ValidLineStatus;
  end;
end;

procedure fUpdateDriverInfo(P : PortRecPtr; var Info : DriverInfo);
  {-Return current driver information from the fossil driver}
{$IFDEF DPMI}
var
  Status : Word;
  M : DosMemRec;
{$ENDIF}

begin
  FillChar(Info, SizeOf(Info), $FF);

  {$IFDEF DPMI}
  FillChar(Info, SizeOf(Info), 0);
  LongInt(M) := GlobalDosAlloc(SizeOf(Info));
  if LongInt(M) = 0 then
    Exit;
  Regs.ES := M.Segm;
  Regs.DI := 0;
  {$ELSE}
  Regs.ES := Seg(Info);
  Regs.DI := Ofs(Info);
  {$ENDIF}

  with Regs do begin
    AH := $1B;
    CX := SizeOf(Info);
    DX := Ord(P^.PortName);
    FossilIntr(Regs);
    {$IFDEF DPMI}
    Move(Mem[M.Sele:0], Info, SizeOf(Info));
    Status := GlobalDosFree(M.Sele);
    {$ENDIF}
  end;
end;

procedure fInitPortKeep(var P : PortRecPtr; ComName : ComNameType;
                        InSize, OutSize : Word);
  {-Fossil open port procedure}
var
  Found : Boolean;
  I : Byte;
begin
  AsyncStatus := ecOk;

  {!!.01 removed
  {For Fossil, ComName must be in Com1..Com4}
  {if ComName > Com4 then begin
    AsyncStatus := ecBadPortNumber;
    Exit;
  end;}

  {Init Fossil}
  with Regs do begin
    Regs.AH :=$04;
    Regs.BX := 0;
    Regs.DX := Ord(ComName);
    FossilIntr(Regs);
    if Regs.AX <> FossilSignature then begin
      AsyncStatus := ecNoFossil;
      Exit;
    end;
  end;

  {Allocate Port record}
  if not GetMemCheck(P, SizeOf(PortRec)) then begin
    AsyncStatus := ecOutOfMemory;
    Exit;
  end;

  with P^ do begin
    {Check for an available port slot}
    Found := False;
    I := 9;                                                     {!!.01}{!!.02}
    while not Found and (I <= MaxActivePort) do
      if ActiveComPort[I] = nil then begin
        CurrentPort := I;
        ActiveComPort[I] := P;
        Found := True;
      end else
        Inc(I);

    {Can't open port if no slots available}
    if not Found then begin
      FreeMemCheck(P, SizeOf(PortRec));
      AsyncStatus := ecNoMorePorts;
      Exit;
    end;

    {Store the port name}
    PortName := ComName;

    {No control over the modem, set to zero for now}
    ModemControl := 0;

    {No flow control}
    SWFState := 0;
    SWFGotXoff := False;
    SWFSentXoff := False;
    SWFOnChar := DefaultXonChar;
    SWFOffChar := DefaultXoffChar;
    HWFTransHonor := 0;
    HWFRecHonor := 0;
    HWFRemoteOff := False;
    LastXmitError := 0;

    {Misc other inits}
    Flags := DefPortOptions or DefFossilOptions;                       {!!.02}
    Buffered := False;
    BreakReceived := False;
    TxReady := True;
    TxInts := False;
    LineStatus := 0;
    DoneProc := fDonePort;
    ErrorProc := NoErrorProc;
    ErrorData := nil;
    UserAbort := NoAbortFunc;
    ProtocolActive := False;
    FaxActive := False;

    {Zero out buffer stuff (prevents errors if buffer routines are called)}
    InBuff := nil;
    InHead := nil;
    InBuffEnd := nil;
    InBuffLen := 65535;
    InBuffCount := 0;
    OutBuff := nil;
    OutHead := nil;
    OutBuffEnd := nil;
    OutBuffLen := 65535;
    OutBuffCount := 0;
    UseStatusBuffer := False;
    StatBuff := nil;
    StatHead := nil;
    StatTail := nil;

    {!!.02 new}
    {Use input buffer for GetChar buffering}
    if FlagIsSet(Flags, ptBufferGetChar) then begin
      {$IFDEF DPMI}
      {StatBuff holds selector/segment values}
      LongInt(StatBuff) := GlobalDosAlloc(BufferMax);
      if LongInt(StatBuff) = 0 then begin
        fDonePort(P);
        AsyncStatus := ecOutOfMemory;
        Exit;
      end;
      InBuff := Ptr(DosMemRec(StatBuff).Sele, 0);
      {$ELSE}
      if not GetMemCheck(InBuff, BufferMax) then begin
        AsyncStatus := ecOutOfMemory;
        fDonePort(P);
        Exit;
      end;
      {$ENDIF}
      InHead := InBuff;
      InTail := InBuff;
      InBuffEnd := InBuff;
      Inc(OS(InBuffEnd).Ofs, BufferMax);
    end;
    {!!.02 new end}

    {Get what line info we can from the FOSSIL driver}
    fGetLine(P, CurBaud, CurParity, CurDataBits, CurStopBits, True);
  end;
end;

procedure fInitPort(var P : PortRecPtr; ComName : ComNameType;
                    Baud : LongInt;
                    Parity : ParityType; DataBits : DataBitType;
                    StopBits : StopBitType;
                    InSize, OutSize : Word;
                    Options : Word);
  {-Fossil open port procedure}
begin
  AsyncStatus := ecOk;

  {Allocate the port record and do inits}
  fInitPortKeep(P, ComName, InSize, OutSize);
  if AsyncStatus <> ecOk then
    Exit;

  with P^ do begin
    {Set the line parameters}
    fSetLine(P, Baud, Parity, DataBits, StopBits);
    if AsyncStatus <> ecOk then begin
      {Failed, release memory and free slot}
      FreeMemCheck(P, SizeOf(PortRec));
      ActiveComPort[CurrentPort] := nil;
    end;

    {Save the desired options, but keep ptBufferGetChar set if necessary}
    if FlagIsSet(Flags, ptBufferGetChar) then                          {!!.02}
      Flags := Options or ptBufferGetChar                              {!!.02}
    else                                                               {!!.02}
      Flags := Options;                                                {!!.02}
  end;
end;

procedure fDonePort(var P : PortRecPtr);
  {-Closes ComName}
var
  I : Word;
begin
  AsyncStatus := ecOk;

  if P = nil then
    Exit;

  I := P^.CurrentPort;

  {Deinit the fossil}
  Regs.AH := $05;
  Regs.DX := Ord(P^.PortName);
  FossilIntr(Regs);

  {Release getchar buffer}                                             {!!.02}
  with P^ do                                                           {!!.02}
    if FlagIsSet(Flags, ptBufferGetChar) then                          {!!.02}
      {$IFDEF DPMI}                                                    {!!.02}
      if GlobalDosFree(LongInt(StatBuff)) = 0 then ;                   {!!.02}
      {$ELSE}                                                          {!!.02}
      FreeMemCheck(InBuff, BufferMax);                                 {!!.02}
      {$ENDIF}

  {Release the heap space}
  FreeMemCheck(P, SizeOf(PortRec));
  P := nil;

  {Show port slot as now available}
  ActiveComPort[I] := nil;
end;

procedure fSetUart(ComName : ComNameType; NewBase : Word;
                   NewIrq, NewVector : Byte);
  {-Dummy routine required by high-level routines}
begin
  AsyncStatus := epNonFatal+ecNotSupported;
end;

function BaudMask(Baud : LongInt; var Mask : Byte) : Boolean;
  {-Convert Baud to Mask, return False if invalid Baud}
begin
  BaudMask := True;
  {!!.01 added 38400}
  case (Baud div 10 )of
    30   : Mask := $02;
    60   : Mask := $03;
    120  : Mask := $04;
    240  : Mask := $05;
    480  : Mask := $06;
    960  : Mask := $07;
    1920 : Mask := $00;
    3840 : Mask := $01;
    else begin
      Mask := 0;
      BaudMask := False;
    end;
  end;
end;

procedure fSetLine(P : PortRecPtr; Baud : LongInt; Parity : ParityType;
                  DataBits : DataBitType; StopBits : StopBitType);
  {-sets the port record with the new values}
var
  BaudCode,
  ParityCode,
  DataCode,
  StopCode : Byte;
  SaveAX : Word;
begin
  AsyncStatus := ecOk;

  with Regs do begin
    AH := $00;
    if Baud = 0 then
      {Set mask with known baud}
      if BaudMask(P^.CurBaud, BaudCode) then else
    else
      if not BaudMask(Baud, BaudCode) then begin
        fGotError(P, epFatal+ecInvalidBaudRate);
        Exit;
      end;

    {Set Parity code}
    case Parity of
      NoParity : ParityCode := 0;
      OddParity : ParityCode := 1;
      EvenParity : ParityCode := 3;
      else begin
        fGotError(P, epFatal+ecInvalidParity);
        Exit;
      end;
    end;

    {Set databit and stopbit codes}
    StopCode := StopBits - 1;
    DataCode := DataBits - 5;

    {Assemble the option byte and try to set the options}
    AL := (BaudCode shl 5) + (ParityCode shl 3) +
          (StopCode shl 2) + DataCode;
    DX := Ord(P^.PortName) and $07;
    SaveAX := AX;
    FossilIntr(Regs);

    {If AH is unchanged then the port doesn't exist}
    if SaveAX = AX then begin
      fGotError(P, epFatal+ecBadPortNumber);
      Exit;
    end;

    {Save line parameters in CurXxx}
    with P^ do begin
      if Baud <> 0 then
        CurBaud := Baud;
      CurParity := Parity;
      CurDataBits := DataBits;
      CurStopBits := StopBits;
    end;
  end;
end;

procedure fGetLine(P : PortRecPtr; var Baud : LongInt;
                   var Parity : ParityType;
                   var DataBits : DataBitType;
                   var StopBits : StopBitType;
                   FromHardware : Boolean);
  {-Get line parameters from internal record}
var
  Info : DriverInfo;
begin
  with P^ do
    if not FromHardware then begin
      {Return current field values}
      Baud := CurBaud;
      Parity := CurParity;
      DataBits := CurDataBits;
      StopBits := CurStopBits;
    end else begin
      {Get what info we can from the FOSSIL driver}
      fUpdateDriverInfo(P, Info);
      with Info do
        case (diBaudMask shr 5) of
          $02  : Baud := 300;
          $03  : Baud := 600;
          $04  : Baud := 1200;
          $05  : Baud := 2400;
          $06  : Baud := 4800;
          $07  : Baud := 9600;
          $00  : Baud := 19200;
          $01  : Baud := 38400;                                        {!!.01}
        end;
      Parity := NoParity;
      DataBits := 8;
      StopBits := 1;
    end;
end;

procedure fSetModem(P : PortRecPtr; DTR, RTS : Boolean);
  {-Can only set DTR}
begin
  with P^, Regs do begin
    AH := $06;
    AL := Ord(DTR);
    DX := Ord(PortName);
    FossilIntr(Regs);
    if DTR then
      ModemControl := ModemControl or DTRMask
    else
      ModemControl := ModemControl and not DTRMask;
    if RTS then
      ModemControl := ModemControl or RTSMask
    else
      ModemControl := ModemControl and not RTSMask;
  end;
end;

procedure fGetModem(P : PortRecPtr; var DTR, RTS : Boolean);
  {-Does nothing (can't get modem params from FOSSIL)}
begin
  fGotError(P, epNonFatal+ecNotSupported);
  DTR := True;                                                         {!!.02}
  RTS := True;                                                         {!!.02}
end;

{!!.02 new}
function fCharReadyPhys(P : PortRecPtr) : Boolean;
  {-Returns True if FOSSIL status call has DataReady set}
begin
  with P^, Regs do begin
    AH := $03;
    DX := Ord(PortName);
    FossilIntr(Regs);

    {Refresh status values, set function result}
    ModemStatus := AL and ValidModemStatus;
    LineStatus := AH and ValidLineStatus;
    fCharReadyPhys := Odd(AH);
  end;
end;

{!!.02 new}
procedure fFillBuffer(P : PortRecPtr);
  {-Try to refill buffer}
var
  Count : Integer;

  procedure ReadData;
  begin
    with P^, Regs do begin
      AH := $18;
      {$IFDEF DPMI}
      ES := DosMemRec(StatBuff).Segm;
      {$ELSE}
      ES := OS(InHead).Seg;
      {$ENDIF}
      DI := OS(InHead).Ofs;
      CX := Count;
      DX := Ord(PortName);
      FossilIntr(Regs);
      Inc(InBuffCount, AX);
      Inc(OS(InHead).Ofs, AX);
      if InHead = InBuffEnd then
        InHead := InBuff;
    end;
  end;

begin
  with P^ do begin
    if OS(InHead).Ofs >= OS(InTail).Ofs then begin
      {Normal buffer, fill free space at end...}
      if fCharReadyPhys(P) then begin
        Count := (OS(InBuffEnd).Ofs - OS(InHead).Ofs);
        ReadData;
      end;

      {...and at beginning of buffer}
      if fCharReadyPhys(P) and (InBuff = InHead) then begin
        Count := OS(InTail).Ofs - OS(InBuff).Ofs;
        if Count > 0 then
          ReadData;
      end;
    end else begin
      {Wrapped buffer, fill free space in the middle}
      if fCharReadyPhys(P) then begin
        Count := OS(InTail).Ofs - OS(InHead).Ofs;
        if Count > 0 then
          ReadData;
      end;
    end;
  end;
end;

{!!.02 new}
procedure fGetCharPhys(P : PortRecPtr; var C : Char);
  {-Calls FOSSIL to check for and return C}
begin
  with P^, Regs do begin
    {Call status to see if char is ready}
    if fCharReady(P) then begin
      AH := $02;
      DX := Ord(PortName);
      FossilIntr(Regs);
      if (AH and $07) = $07 then begin
        {Timeout waiting for char, report error}
        C := #$FF;
        fGotError(P, epNonFatal+ecTimeout);
      end else begin
        {Get char and error bits}
        Byte(C) := AL;
        LineStatus := AH and ValidLineStatus;

        {$IFDEF Tracing}
        if TracingOn then
          AddTraceEntry('R', C);
        {$ENDIF}
      end;
    end else
      fGotError(P, epNonFatal+ecBufferIsEmpty);
  end;
end;

{!!.02 new}
procedure fGetCharBuf(P : PortRecPtr; var C : Char);
  {-Get character from buffer}
begin
  with P^ do begin
    if (InHead = InTail) and fCharReadyPhys(P) then
      {Buffer empty but data is ready, refill the buffer}
      fFillBuffer(P);

    if InBuffCount > 0 then begin
      {Get next char from buffer}
      C := Char(InTail^);
      Inc(OS(InTail).Ofs);
      if InTail = InBuffEnd then
        InTail := InBuff;
      Dec(InBuffCount);

      {$IFDEF Tracing}
      if TracingOn then
        AddTraceEntry('R', C);
      {$ENDIF}
    end else
      fGotError(P, epNonFatal+ecBufferIsEmpty);
  end;
end;

{!!.02 rewritten}
procedure fGetChar(P : PortRecPtr; var C : Char);
  {-Calls FOSSIL to check for and return C}
begin
  AsyncStatus := ecOk;
  if FlagIsSet(P^.Flags, ptBufferGetChar) then
    fGetCharBuf(P, C)
  else
    fGetCharPhys(P, C);
end;

{!!.02 new}
procedure fPeekCharPhys(P : PortRecPtr; var C : Char; PeekAhead : Word);
  {-Can't do physical peekaheads}
begin
  if PeekAhead <> 1 then begin
    C := #$FF;
    fGotError(P, epNonFatal+ecInvalidArgument);
  end else with P^, Regs do begin
    AH := $0C;
    DX := Ord(PortName);
    FossilIntr(Regs);
    if AH = $FF then
      fGotError(P, epNonFatal+ecBufferIsEmpty)
    else begin
      AsyncStatus := ecOk;
      LineStatus := AH and ValidLineStatus;
      C := Char(AL);
    end;
  end;
end;

{!!.02 new}
procedure fPeekCharBuf(P : PortRecPtr; var C : Char; PeekAhead : Word);
var
  TrcP : BPtr;
  Count : Word;
begin
  AsyncStatus := ecOk;
  with P^ do begin
    if PeekAhead > InBuffCount then begin
      {Peeking too far, try to refill buffer}
      fFillBuffer(P);
      if PeekAhead > InBuffCount then begin
        {Still too far, give up}
        C := #$FF;
        fGotError(P, epNonFatal+ecInvalidArgument);
        Exit;
      end;
    end;

    {!!.03 rewritten}
    {Return the requested char}
    Count := (OS(InTail).Ofs + PeekAhead)-1;
    if Count >= OS(InBuffEnd).Ofs then
      Dec(Count, BufferMax);
    TrcP := InBuff;
    Inc(OS(TrcP).Ofs, Count);
    C := Char(TrcP^);
  end;
end;

{!!.02 rewritten}
procedure fPeekChar(P : PortRecPtr; var C : Char; PeekAhead : Word);
begin
  AsyncStatus := ecOk;
  if FlagIsSet(P^.Flags, ptBufferGetChar) then
    fPeekCharBuf(P, C, PeekAhead)
  else
    fPeekCharPhys(P, C, PeekAhead);
end;

procedure fPutChar(P : PortRecPtr; C : Char);
  {-Puts a char to FOSSIL}
begin
  AsyncStatus := ecOk;

  {Call Fossil to send a char}
  with P^, Regs do begin
    AL := Byte(C);

    {Specify wait or nowait as requested}
    if FlagIsSet(Flags, ptPutCharWait) then
      AH := $01
    else
      AH := $0B;

    {Call the FOSSIL}
    DX := Ord(PortName);
    FossilIntr(Regs);

    if not FlagIsSet(Flags, ptPutCharWait) then begin
      {Check for buffer full error}
      if AX = 0 then begin
        fGotError(P, epNonFatal+ecBufferIsFull);
        Exit;
      end;
    end;

    ModemStatus := AL and ValidModemStatus;
    LineStatus := AH and ValidLineStatus;

    {$IFDEF Tracing}
    if TracingOn then
      AddTraceEntry('T', C);
    {$ENDIF}
  end;
end;

procedure fStartTransmitter(P : PortRecPtr);
  {-Dummy procedure required by high-level routines}
begin
  {nothing to do}
end;

{!!.02}
function fCharReady(P : PortRecPtr) : Boolean;
  {-Returns True if FOSSIL status call has DataReady set}
begin
  with P^ do begin
    {Always call CharReadyPhys to get updated line/modem values}
    fCharReady := fCharReadyPhys(P);

    {Force a true return if we've data buffered}
    if FlagIsSet(Flags, ptBufferGetChar) then
      if InHead <> InTail then
        fCharReady := True;
  end;
end;

function fTransReady(P : PortRecPtr) : Boolean;
  {-Returns True if fossil has room for another character }
begin
  with P^, Regs do begin
    AH := $03;
    DX := Ord(PortName);
    FossilIntr(Regs);

    {Refresh status values, set function result}
    ModemStatus := AL and ValidModemStatus;
    LineStatus := AH and ValidLineStatus;
    fTransReady := (AH and $20) = $20
  end;
end;

procedure fSendBreak(P : PortRecPtr);
  {-Not implemented}
begin
  fGotError(P, epNonFatal+ecNotSupported);
end;

procedure fActivatePort(P : PortRecPtr; Restore : Boolean);
  {-Does nothing -- FOSSIL uses polled I/O}
begin
  {nothing to do}
end;

procedure fDeactivatePort(P : PortRecPtr; Restore : Boolean);
  {-Does nothing -- FOSSIL uses polled I/O}
begin
  {nothing to do}
end;

procedure fSavePort(P : PortRecPtr; var PSR);
  {-Does nothing -- FOSSIL uses polled I/O}
begin
  {nothing to do}
end;

procedure fRestorePort(P : PortRecPtr; var PSR);
  {-Does nothing -- FOSSIL uses polled I/O}
begin
  {nothing to do}
end;

procedure fGotError(P : PortRecPtr; StatusCode : Word);
  {-Called when an error occurs (GotError calls the optional ErrorHandler)}
begin
  AsyncStatus := StatusCode;
  with P^ do
    if @ErrorProc <> @NoErrorProc then begin
      ErrorProc(ErrorData, StatusCode);
      if ProtocolActive then
        {Remove error class on protocol errors}
        AsyncStatus := AsyncStatus mod 10000;
    end;
end;

function fUpdateLineStatus(P : PortRecPtr) : Byte;
  {-Returns line status register value}
begin
  fUpdateLineAndModemStatus(P);
  fUpdateLineStatus := P^.LineStatus;
end;

function fUpdateModemStatus(P : PortRecPtr) : Byte;
  {-Returns modem status register value}
begin
  fUpdateLineAndModemStatus(P);
  fUpdateModemStatus := P^.ModemStatus;
end;

{$IFDEF UseHWFlow}
procedure fHWFlowSet(P : PortRecPtr; Enable : Boolean;
                     BufferFull, BufferResume : Word;
                     Options : Word);
  {-Enables/disables hardware flow control}

  {!!.01 new}
  procedure CheckSWFlow(var B : Byte);
    {-Or swflow bits into B, if necessary}
  begin
    with P^ do begin
      {Or in software flow bits, if software flow is already on}
      if FlagIsSet(SWFState, sfTransmitFlow) then
        B := B or $01;
      if FlagIsSet(SWFState, sfReceiveFlow) then
        B := B or $08;
    end;
  end;

begin
  AsyncStatus := ecOk;

  with P^, Regs do begin
    if Enable then begin
      {Turning flow control on...}
      if (Options and (hfUseRTS+hfRequireCTS)) <> (hfUseRTS+hfRequireCTS) then begin
        fGotError(P, ecInvalidArgument);
        Exit;
      end;

      AH := $0F;
      AL := $02;
      CheckSWFlow(AL);                                                 {!!.01}
      DX := Ord(PortName);
      FossilIntr(Regs);

      {Say it's on}
      HWFRecHonor := 1;

    end else begin
      {Turning flow control off...}
      AH := $0F;
      AL := $00;
      CheckSWFlow(AL);                                                 {!!.01}
      DX := Ord(PortName);
      FossilIntr(Regs);

      {Say it's off}
      HWFRecHonor := 0;
    end;
  end;
end;

function fHWFlowGet(P : PortRecPtr) : FlowState;
  {-Returns hardware flow control state, on or off only}
begin
  with P^ do begin
    if HWFRecHonor = 1 then
      fHWFlowGet := fsClear
    else
      fHWFlowGet := fsOff;
  end;
end;
{$ENDIF}

{$IFDEF UseSWFlow}
procedure fSWFlowSet(P : PortRecPtr; Enable : Boolean;
                     BufferFull, BufferResume : Word;
                     Options : Word);
  {-Enables/disables software flow control}
begin
  AsyncStatus := ecOk;

  with P^, Regs do begin
    if Enable then begin
      if FlagIsSet(Options, sfTransmitFlow) then
        AL := $01
      else
        AL := $00;
      if FlagIsSet(Options, sfReceiveFlow) then
        AL := AL or $08;
      AH := $0F;
      DX := Ord(PortName);

      {Or in hardware flow, if hardware flow is already on}            {!!.01}
      if HWFRecHonor = 1 then                                          {!!.01}
        AL := AL or $02;                                               {!!.01}

      FossilIntr(Regs);

      {Say it's on }
      SWFState := Options;
    end else begin
      AH := $0F;
      AL := $00;
      if HWFRecHonor = 1 then                                          {!!.01}
        AL := AL or $02;                                               {!!.01}
      DX := Ord(PortName);
      FossilIntr(Regs);

      {Say it's off}
      SWFState := 0;
    end;
  end;
end;

function fSWFlowGet(P : PortRecPtr) : FlowState;
  {-Returns software flow control state}
begin
  with P^ do begin
    if SWFState <> 0 then
      fSWFlowGet := fsClear
    else
      fSWFlowGet := fsOff;
  end;
end;

procedure fSWFlowCtl(P : PortRecPtr; OnChar, OffChar : Char;
                     Resume : Boolean);
  {-Sets software flow control characters and/or resumes transmits}
begin
  fGotError(P, epNonFatal+ecNotSupported);
end;
{$ENDIF}

procedure fBufferStatus(P : PortRecPtr;
                        var InFree, OutFree, InUsed, OutUsed : Word);
  {-Returns various buffer values}
var
  Info : DriverInfo;
  Used : Word;
  Free : Word;
  PercentUsed : Word;
  PercentFree : Word;
begin
  fUpdateDriverInfo(P, Info);
  with P^, Info do begin
    InFree := diInFree;
    if (Flags and ptTrueOutBuffFree) = ptTrueOutBuffFree then begin
      {Return actual value}
      Free := diOutFree;
      if FlagIsSet(Flags, ptHandleFossilBug) and (Free = diOutSize-1) then
        Free := diOutSize;
      OutFree := Free;
    end else begin
      {Make a guess about whether to return 0 or 65535}
      OutFree := 0;                                                    {!!.01}
      if diOutSize <> 0 then begin                                     {!!.01}
        PercentFree := (diOutFree * LongInt(100)) div diOutSize;       {!!.01}
        if PercentFree > 90 then                                       {!!.01}
          OutFree := 65535                                             {!!.01}
      end;                                                             {!!.01}
    end;

    InUsed := diInSize - diInFree;
    Used := diOutSize - diOutFree;
    if FlagIsSet(Flags, ptHandleFossilBug) and (Used = 1) then
      Used := 0;
    OutUsed := Used;
  end;
end;

procedure fBufferFlush(P : PortRecPtr; FlushIn, FlushOut: Boolean);
  {-Flushes input/output buffers}
begin
  with P^, Regs do begin

    if FlushIn then begin
      {Flush the input buffer}
      AH := $0A;
      DX := Ord(PortName);
      FossilIntr(Regs);

      {If buffering input, get rid of any buffered data as well}       {!!.03}
      if FlagIsSet(P^.Flags, ptBufferGetChar) then begin               {!!.03}
        InHead := InBuff;                                              {!!.03}
        InTail := InBuff;                                              {!!.03}
      end;                                                             {!!.03}
    end;

    if FlushOut then begin
      {Flush the output buffer}
      AH := $09;
      DX := Ord(PortName);
      FossilIntr(Regs);
    end;
  end;
end;

procedure ActivateApFossil;
  {-Registers this unit as the active "device layer"}
begin
  {$IFNDEF UseOOP}
  InitPort := fInitPort;
  InitPortKeep := fInitPortKeep;
  DonePort := fDonePort;
  SetLine := fSetLine;
  GetLine := fGetLine;
  SetModem := fSetModem;
  GetModem := fGetModem;
  GetChar := fGetChar;
  PeekChar := fPeekChar;                                               {!!.03}
  PutChar := fPutChar;
  CharReady := fCharReady;
  TransReady := fTransReady;
  SendBreak := fSendBreak;
  ActivatePort := fActivatePort;
  DeactivatePort := fDeactivatePort;
  SavePort := fSavePort;
  RestorePort := fRestorePort;
  GotError := fGotError;

  UpdateLineStatus := fUpdateLineStatus;
  UpdateModemStatus := fUpdateModemStatus;
  {$IFDEF UseHWFlow}
  HWFlowSet := fHWFlowSet;
  HWFlowGet := fHWFlowGet;
  {$ENDIF}
  {$IFDEF UseSWFlow}
  SWFlowSet := fSWFlowSet;
  SWFlowGet := fSWFlowGet;
  SWFlowCtl := fSWFlowCtl;
  {$ENDIF}
  BufferStatus := fBufferStatus;
  BufferFlush := fBufferFlush;

  {$ENDIF}
  SetUart := fSetUart;
end;

begin
  {$IFDEF AutoDeviceInit}
  ActivateApFossil;
  {$ENDIF}

  {Set ANSI output hook to use this device layer}
  AnsiOutput := fPutChar;
end.
