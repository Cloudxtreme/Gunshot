{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                   APCOUR.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit ApCour;
  {-Unit for controlling US Robotics Courier 9600 BPS modems}

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
  {Courier command set}
  CourierCommandMax = 140;
  CourierCommandID : String[16] = 'Courier commands';
  CourierCommandSet : array[0..CourierCommandMax-1] of Byte = (
   {len flags chars             command type         modem command}
    3,  $07,  Ord('A'),          mcAnswer,           {Answer phone}
    4,  $00,  Ord('A'),Ord('/'), mcRepeat,           {Rpt cmd}
    3,  $03,  Ord('C'),          mcSetCarrierTrans,  {Trans on/off}
    3,  $0F,  Ord('D'),          mcDial,             {Dial number string}
    3,  $03,  Ord('E'),          mcEcho,             {Set offline echo}
    3,  $03,  Ord('F'),          mcOnlineEcho,       {Set online echo}
    3,  $03,  Ord('H'),          mcHook,             {Set hook mode}
    3,  $03,  Ord('M'),          mcSpeaker,          {Set speaker on/off}
    3,  $03,  Ord('O'),          mcOnline,           {Command to Terminal Mode}
    3,  $03,  Ord('Q'),          mcQuiet,            {Set quite mode}
    3,  $03,  Ord('S'),          mcSetRegister,      {Set an S register}
    3,  $03,  Ord('S'),          mcReadRegister,     {Return S register}
    3,  $03,  Ord('P'),          mcPulse,            {Pulse dialing}
    3,  $03,  Ord('V'),          mcResultCodes,      {Set results mode}
    3,  $03,  Ord('X'),          mcCodeSet,          {Set result code set}
    3,  $03,  Ord('Z'),          mcReset,            {Reset modem}
    3,  $03,  Ord('T'),          mcTone,             {Tone dialing}
    4,  $03,  Ord('&'), cC,      mcDCDControl,       {DCD behavior}
    4,  $03,  Ord('&'), cD,      mcDTRControl,       {DTR behavior}
    5,  $00,  Ord('+'),Ord('+'),Ord('+'), mcCmdMode, {Terminal to Command Mode}
    4,  $03,  Ord('&'),Ord('K'),          mcDataCompression, {Compress on/off}
    5,  $03,  Ord('&'),Ord('M'),Ord('0'), mcErrorControlOff, {Error ctl off}
    5,  $03,  Ord('&'),Ord('M'),Ord('5'), mcErrorControlOn,  {Error ctl on}
    5,  $03,  Ord('&'),Ord('M'),Ord('4'), mcErrorControlAuto,{Error ctl auto}
    5,  $03,  Ord('&'),Ord('B'),Ord('1'), mcLinkLockedOn,    {Lock DTE/DCE}
    5,  $03,  Ord('&'),Ord('B'),Ord('0'), mcLinkLockedOff,   {Unlock DTE/DCE}

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

procedure InitModemCourier(var M : ModemRecPtr; P : PortRecPtr);
  {-Allocates and initializes a Modem}

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

  procedure InitModemCourier(var M : ModemRecPtr; P : PortRecPtr);
    {-Allocates and initializes a Modem}
  begin
    InitModem(M, P);
    if GetAsyncStatus <> ecOk then                                     {!!.02}
      Exit;

    with M^ do begin
      {Use Courier tables}
      CmdTable := @CourierCommandSet;
      CmdTableMax := CourierCommandMax;
      CodeTable := @CourierCodeSet;
      CodeTableMax := CourierCodeMax;

    end;
  end;

  procedure SetFlowControl(M : ModemRecPtr; FlowOpts : Word);
    {-Set flow control options}
  var
    Hval : Byte;
    Ival : Byte;
    Rval : Byte;
  begin
    with M^ do begin
      {Save FlowOpts}
      FlowOptions := FlowOpts;

      {Set the "n" values}
      Hval := 0;
      Ival := 0;
      Rval := 1;
      if FlagIsSet(FlowOpts, fSWTrans) then
        Inc(Hval);
      if FlagIsSet(FlowOpts, fHWTrans) then
        Inc(Hval);
      if FlagIsSet(FlowOpts, fSWRec) then
        Ival := 2;
      if FlagIsSet(FlowOpts, fHWRec) then
        Rval := 2;

      {Build the command string}
      Buffer := CmdPrefix + '&H' + Long2Str(Hval) +
                            '&I' + Long2Str(Ival) +
                            '&R' + Long2Str(Rval) + ^M;

      {Execute the command and handle the response}
      PutModemCommand(M, Buffer);
    end;
  end;

  procedure SetErrorControl(M : ModemRecPtr; ErrorOpt : ErrorStates);
    {-Turn error control on/off}
  var
    Cmd : Word;
  begin
    with M^ do begin
      case ErrorOpt of
        eCheckOff  : Cmd := mcErrorControlOff;
        eCheckOn   : Cmd := mcErrorControlOn;
        eCheckAuto : Cmd := mcErrorControlAuto;
      end;
      ExecuteModemCommand(M, Cmd, -1);
    end;
  end;

  procedure SetLinkLocked(M : ModemRecPtr; Locked : Boolean);
    {-Lock the link rate or follow connection?}
  var
    Cmd : Word;
  begin
    with M^ do begin
      if Locked then
        Cmd := mcLinkLockedOn
      else
        Cmd := mcLinkLockedOff;
      ExecuteModemCommand(M, Cmd, -1);
    end;
  end;

  procedure SetModemSpeed(M : ModemRecPtr; Baud : LongInt);
    {-Set the DTE/DCE data rate}
  begin
    with M^ do
      {For Courier's let the modem decide what baud rate to use}
      PutModemCommand(M, CmdPrefix+'&N0'+^M);
  end;

  procedure SetSpeedMatching(M : ModemRecPtr);
    {-Answering DCE matches speed with originating DCE}
  begin
    with M^ do
      PutModemCommand(M, CmdPrefix+'&N0'+CmdSuffix);
  end;

  procedure SetDataCompression(M : ModemRecPtr; State : Boolean);
    {-Turn data compression on/off}
  begin
    with M^ do
      ExecuteModemCommand(M, mcDataCompression, Ord(State));
  end;

end.
