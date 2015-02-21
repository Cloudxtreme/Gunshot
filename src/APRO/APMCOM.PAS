{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                   APMCOM.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApMCom;
  {-Unit for controlling Microcom hispeed modems}

interface

uses
  {$IFDEF UseOPro}
  OpInline,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpInline,
  {$ENDIF}
  {$IFDEF UsePModeDLL}                                                 {!!.02}
  ApComD,                                                              {!!.02}
  {$ELSE}                                                              {!!.02}
  ApMisc,                                                              {!!.02}
  ApPort,                                                              {!!.02}
  {$ENDIF}                                                             {!!.02}
  ApModem;

const
  {MicroCom command set}
  MicroComCommandMax = 140;
  MicroComCommandID : String[17] = 'microcom commands';
  MicroComCommandSet : array[0..MicroComCommandMax] of Byte = (
   {len flags chars             command type         modem command}
    3,  $07,  cA,                mcAnswer,           {Answer phone}
    4,  $00,  cA,Ord('/'),       mcRepeat,           {Rpt cmd}
    3,  $03,  cC,                mcSetCarrierTrans,  {Trans on/off}
    3,  $07,  cD,                mcDial,             {Dial number string}
    3,  $03,  cE,                mcEcho,             {Set offline echo}
    4,  $03,  Ord('\'),cE,       mcOnlineEcho,       {Set online echo}
    3,  $03,  cH,                mcHook,             {Set hook mode}
    3,  $03,  cM,                mcSpeaker,          {Set speaker on/off}
    3,  $03,  cO,                mcOnline,           {Command to Terminal Mode}
    3,  $03,  cQ,                mcQuiet,            {Set quite mode}
    3,  $03,  cS,                mcSetRegister,      {Set an S register}
    3,  $03,  cS,                mcReadRegister,     {Return S register}
    3,  $03,  cP,                mcPulse,            {Pulse dialing}
    3,  $03,  cV,                mcResultCodes,      {Set results mode}
    3,  $03,  cX,                mcCodeSet,          {Set result code set}
    3,  $03,  cZ,                mcReset,            {Reset modem}
    3,  $03,  cT,                mcTone,             {Tone dialing}
    4,  $03,  Ord('&'), cC,      mcDCDControl,       {DCD behavior}
    4,  $03,  Ord('&'), cD,      mcDTRControl,       {DTR behavior}
    5,  $00,  Ord('+'),Ord('+'),Ord('+'), mcCmdMode, {Terminal to Command Mode}
    4,  $03,  Ord('%'),cC,       mcDataCompression, {Compress on/off}
    5,  $03,  Ord('\'),cN,Ord('0'), mcErrorControlOff, {Error ctl off}
    5,  $03,  Ord('\'),cN,Ord('2'), mcErrorControlOn,  {Error ctl on}
    5,  $03,  Ord('\'),cN,Ord('3'), mcErrorControlAuto,{Error ctl auto}
    5,  $03,  Ord('\'),cJ,Ord('0'), mcLinkLockedOn,    {Lock DTE/DCE}
    5,  $03,  Ord('\'),cJ,Ord('1'), mcLinkLockedOff,   {Unlock DTE/DCE}

    {-----------pad to end of array----------}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,        {130}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);       {140}

  {Modem response code set}
  CourierCodeMax = 200;
  CourierCodeID : String[13] = 'Courier codes';
  CourierCodeSet : array[0..CourierCodeMax] of Byte = (
   {modem response  options   response code      meaning}
       0,            $00,$00,   mrOk,              {Ok}
       1,            $00,$02,   mrConnect,         {Connect}
       2,            $00,$00,   mrRing,            {Ring}
       3,            $00,$00,   mrNoCarrier,       {No carrier}
       4,            $00,$00,   mrError,           {Error}
       5,            $00,$04,   mrConnect,         {Connect}
       6,            $00,$00,   mrNoDialtone,      {No dialtone}
       7,            $00,$00,   mrBusy,            {Busy}
       8,            $00,$00,   mrNoAnswer,        {No answer}
       9,            $00,$00,   mrNone,            {Reserved}
       10,           $00,$10,   mrConnect,         {Connect}
       11,           $00,$00,   mrRing,            {Ringing}
       12,           $00,$00,   mrVoice,           {Voice}
       13,           $00,$80,   mrConnect,         {Connect 9600}
       14,           $00,$81,   mrConnect,         {Connect/arq}
       15,           $00,$09,   mrConnect,         {Connect 1200/arq}
       16,           $00,$11,   mrConnect,         {Connect 2400/arq}
       17,           $00,$81,   mrConnect,         {Connect 9600/arq}
       18,           $00,$20,   mrConnect,         {Connect 4800}
       19,           $00,$21,   mrConnect,         {Connect 4800/arq}
       20,           $00,$40,   mrConnect,         {Connect 7200}
       21,           $01,$00,   mrConnect,         {Connect 12000}
       22,           $01,$01,   mrConnect,         {Connect 12000/arq}
       23,           $00,$80,   mrConnect,         {Connect 9600/hst}
       24,           $00,$41,   mrConnect,         {Connect 7200/arq}
       25,           $02,$00,   mrConnect,         {Connect 14400}
       26,           $02,$01,   mrConnect,         {Connect 14400/arq}
       27,           $00,$81,   mrConnect,         {Connect 9600/arq/hst}
       28,           $00,$20,   mrConnect,         {Connect 4800/hst}
       29,           $00,$21,   mrConnect,         {Connect 4800/arq/hst}
       30,           $00,$40,   mrConnect,         {Connect 7200/hst}
       31,           $01,$00,   mrConnect,         {Connect 12000/hst}
       32,           $01,$01,   mrConnect,         {Connect 12000/arq/hst}
       33,           $00,$80,   mrConnect,         {Connect 9600/v32}
       34,           $00,$41,   mrConnect,         {Connect 7200/arq/hst}
       35,           $02,$00,   mrConnect,         {Connect 14400/hst}
       36,           $02,$01,   mrConnect,         {Connect 14400/arq/hst}
       37,           $00,$81,   mrConnect,         {Connect 9600/arq/v32}
       38,           $00,$20,   mrConnect,         {Connect 4800/v32}
       39,           $00,$21,   mrConnect,         {Connect 4800/arq/v32}
       40,           $00,$40,   mrConnect,         {Connect 7200/v32}
       41,           $01,$00,   mrConnect,         {Connect 12000/v32}
       42,           $01,$01,   mrConnect,         {Connect 12000/arq/v32}
       44,           $00,$41,   mrConnect,         {Connect 7200/arq/v32}
       45,           $02,$00,   mrConnect,         {Connect 14400/v32}
       46,           $02,$01,   mrConnect,         {Connect 14400/arq/v32}
       255, {End-of-table mark}

                0, 0, 0, 0, 0, 0,     {150}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);    {160}

const
  {Modem response code set}
  MicroComCodeMax = 100;
  MicroComCodeID : String[11] = 'micro codes';
  MicroComCodeSet : array[0..MicroComCodeMax] of Byte = (
   {modem response  options   response code      meaning}
       0,            $00,$00,   mrOk,              {Ok}
       1,            $00,$02,   mrConnect,         {Connect}
       2,            $00,$00,   mrRing,            {Ring}
       3,            $00,$00,   mrNoCarrier,       {No carrier}
       4,            $00,$00,   mrError,           {Error}
       5,            $00,$08,   mrConnect,         {Connect}
       6,            $00,$00,   mrNoDialtone,      {No dialtone}
       7,            $00,$00,   mrBusy,            {Busy}
       8,            $00,$00,   mrNoAnswer,        {No answer}
       9,            $00,$04,   mrConnect,         {Connect 600}
       10,           $00,$10,   mrConnect,         {Connect 2400}
       20,           $00,$03,   mrConnect,         {Connect 103/REL}
       21,           $00,$05,   mrConnect,         {Connect 600/REL}
       22,           $00,$09,   mrConnect,         {Connect 1200/REL}
       23,           $00,$11,   mrConnect,         {Connect 2400/REL}
       30,           $00,$20,   mrConnect,         {Connect 4800}
       32,           $00,$80,   mrConnect,         {Connect 9600}
       33,           $00,$81,   mrConnect,         {Connect 9600/REL}
       40,           $00,$00,   mrConnect,         {REMOTE ACCESS FAILED}
       255, {End-of-table mark}

                      0, 0, 0, 0,     {80}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     {90}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);    {100}

procedure InitModemMcom(var M : ModemRecPtr; P : PortRecPtr);
  {-Allocates and initializes a Microcom modem}

procedure SetFlowControl(M : ModemRecPtr; FlowOpts : Word);
  {-Set flow control options}

procedure SetErrorControl(M : ModemRecPtr; ErrorOpt : ErrorStates);
  {-Turn error control on/off}

procedure SetLinkLocked(M : ModemRecPtr; Locked : Boolean);
  {-Lock the link rate or follow connection?}

procedure SetModemSpeed(M : ModemRecPtr; Baud : LongInt);
  {-Set the DTE/DCE data rate}

procedure SetSpeedMatching(M : ModemRecPtr);
  {-Answering DCE matches speed with originating DCE}

procedure SetDataCompression(M : ModemRecPtr; State : Boolean);
  {-Turn data compression on/off}

implementation

  function Long2Str(L : LongInt) : string;
    {-Convert a long/word/integer/byte/shortint to a string}
  var
    S : string;
  begin
    Str(L, S);
    Long2Str := S;
  end;

  procedure InitModemMcom(var M : ModemRecPtr; P : PortRecPtr);
    {-Allocates and initializes a Microcom modem}
  begin
    InitModem(M, P);
    if GetAsyncStatus <> ecOk then                                     {!!.02}
      Exit;

    with M^ do begin
      {Use Courier tables}
      CmdTable := @MicrocomCommandSet;
      CmdTableMax := MicrocomCommandMax;
      CodeTable := @MicrocomCodeSet;
      CodeTableMax := MicrocomCodeMax;
    end;
  end;

  procedure SetFlowControl(M : ModemRecPtr; FlowOpts : Word);
    {-Set flow control options}
  var
    Qval : Byte;
  label
    ErrorExit;
  begin
    with M^ do begin
      {Save FlowOpts}
      FlowOptions := FlowOpts;

      {Check for unsupported requests}
      if (FlagIsSet(FlowOpts, fSWTrans) or FlagIsSet(FlowOpts, fSWRec)) and
         (FlagIsSet(FlowOpts, fHWTrans) or FlagIsSet(FlowOpts, fHWRec)) then
        {Error - can't have both hw and sw flow control}
        goto ErrorExit;

      if FlagIsSet(FlowOpts, fHWRec) and not FlagIsSet(FlowOpts, fHWTrans) then
        {Error - can't have only hardware receive}
        goto ErrorExit;

      if FlagIsSet(FlowOpts, fSWTrans) and not FlagIsSet(FlowOpts, fSWRec) then
        {Error - can't have only software transmit}
        goto ErrorExit;

      {If we get here we have a valid request, set Q accordingly}
      Qval := 0;
      if FlagIsSet(FlowOpts, fSWTrans) and FlagIsSet(FlowOpts, fSWRec) then
        QVal := 1;
      if FlagIsSet(FlowOpts, fHWTrans) and not FlagIsSet(FlowOpts, fHWRec) then
        QVal := 2;
      if FlagIsSet(FlowOpts, fHWTrans) and FlagIsSet(FlowOpts, fHWRec) then
        QVal := 3;
      if not FlagIsSet(FlowOpts, fSWTrans) and FlagIsSet(FlowOpts, fSWRec) then
        QVal := 4;

      {Build the command string}
      Buffer := CmdPrefix + '\Q' + Long2Str(Qval) + ^M;

      {Execute the command and handle the response}
      PutModemCommand(M, Buffer);
      Exit;

  ErrorExit:
      GotError(PR, epNonFatal+ecNullCommand);
    end;
  end;

  procedure SetErrorControl(M : ModemRecPtr; ErrorOpt : ErrorStates);
    {-Turn error control on/off}
  begin
    with M^ do begin
      case ErrorOpt of
        eCheckOff  : Buffer := '\N0';
        eCheckOn   : Buffer := '\N2';
        eCheckAuto : Buffer := '\N3';
      end;
      PutModemCommand(M, CmdPrefix+Buffer+^M);
    end;
  end;

  procedure SetLinkLocked(M : ModemRecPtr; Locked : Boolean);
    {-Lock the link rate or follow connection?}
  begin
    with M^ do begin
      if Locked then
        Buffer := '%G1'
      else
        Buffer := '%G0';
      PutModemCommand(M, CmdPrefix+Buffer+^M);
    end;
  end;

  procedure SetModemSpeed(M : ModemRecPtr; Baud : LongInt);
    {-Set the DTE/DCE data rate}
  begin
    with M^ do
      PutModemCommand(M, CmdPrefix+'%B'+Long2Str(Baud)+^M);
  end;

  procedure SetSpeedMatching(M : ModemRecPtr);
    {-Answering DCE matches speed with originating DCE}
  begin
    with M^ do
      PutModemCommand(M, CmdPrefix+'%L1'+CmdSuffix);
  end;

  procedure SetDataCompression(M : ModemRecPtr; State : Boolean);
    {-Turn data compression on/off}
  begin
    with M^ do begin
      if State then
        Buffer := '%C1'
      else
        Buffer := '%C0';
      PutModemCommand(M, CmdPrefix+Buffer+^M);
    end;
  end;

end.
