{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                   APMODEM.PAS 2.03                    *}
{*     Copyright (c) TurboPower Software 1991.           *}
{* Portions copyright (c) Information Technology 1989,   *}
{*    and used under license to TurboPower Software      *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$IFDEF UseOOP}
  !! STOP COMPILE - this unit requires UseOOP to be undefined
{$ENDIF}

unit ApModem;
  {-Modem support}

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
  {$IFDEF UsePModeDLL}                                                 {!!.02}
  ApComD;                                                              {!!.02}
  {$ELSE}                                                              {!!.02}
  ApMisc,                                                              {!!.02}
  ApPort,                                                              {!!.02}
  ApTimer,                                                             {!!.02}
  ApCom;                                                               {!!.02}
  {$ENDIF}                                                             {!!.02}

const
  {Compile-time constants}
  MaxWordLen = 30;          {Max length for a modem word response}
  MaxStdSRegs = 12;         {Max standard Sregs}
  MaxSRegs = 40;            {Max ultimate number of Sregs}
  MaxDialStr = 30;          {Max length of dial prefix}

  {Run-time constants}
  DefDialTimeout : Word = 1092; {Default tics for dial timeout (60 secs)}
  DefDelayFactor : Byte = 2;    {Default tics for inter-cmd delay}
  DefSepChar : Char = '/';      {Default separator for modem responses}
  DefTimeout : Word = 182;      {Default tics for cmd timeout (10 secs)}
  DTRDropHold : Word = 8;       {Tics to DTR low during Hangup}
  ModemCharDelay : Word = 10;   {MSec between outgoing cmd chars}

  {Modem ID codes}
  miHayesModem    = 0;
  miNullModem     = 1;
  miCourierModem      = 2;
  miMicroComModem = 3;

type
  {Defines one modem register}
  ModemRegType = record
    Lo  : byte;
    Hi  : byte;
    Def : byte;
  end;

  {Defines one modem set of S-registers}
  SRegSet = array[0..MaxStdSRegs] of ModemRegType;

  {Misc}
  ModemErrorString = String[10];

const
  {Basic modem commands (Hayes)}
  mcNone              = 0;   {Null command}
  mcAnswer            = 1;   {A     - answer phone immediately}
  mcRepeat            = 2;   {A/    - repeat last command}
  mcSetCarrierTrans   = 3;   {Cn    - carrier transmitter on/off}
  mcDial              = 4;   {Ds    - dial number string}
  mcEcho              = 5;   {En    - set offline echo on/off}
  mcOnlineEcho        = 6;   {Fn    - set online echo on/off}
  mcHook              = 7;   {Hn    - set hook mode on/off/special}
  mcSpeaker           = 8;   {Mn    - set speaker off, ontillCD, always on}
  mcOnline            = 9;   {O     - go online}
  mcQuiet             = 10;  {Q     - set result mode quiet/normal}
  mcSetRegister       = 11;  {Sn=x  - set an S register}
  mcReadRegister      = 12;  {Sn=   - return an S register}
  mcPulse             = 13;  {P     - pulse dialing}
  mcResultCodes       = 14;  {Vn    - set results codes or text}
  mcCodeSet           = 15;  {Xn    - set result code set}
  mcReset             = 16;  {Z     - reset modem}
  mcTone              = 17;  {T     - tone dialing}
  mcVolume            = 18;  {L     - volume control}
  mcDCDControl        = 19;  {&C    - DCD always on/follow conect}
  mcDTRControl        = 20;  {&D    - DTR override/terminate call}
  mcCmdMode           = 21;  {+++   - escape to command mode}
  mcDataCompression   = 22;  {varies with modem}
  mcErrorControlOff   = 23;  {varies with modem}
  mcErrorControlOn    = 24;  {varies with modem}
  mcErrorControlAuto  = 25;  {varies with modem}
  mcLinkLockedOn      = 26;  {varies with modem}
  mcLinkLockedOff     = 27;  {varies with modem}

  {User added commands}
  mcUser0             = 100;
  mcUser1             = 101;
  mcUser2             = 102;
  mcUser3             = 103;
  mcUser4             = 104;
  mcUser5             = 105;
  mcUser6             = 106;
  mcUser7             = 107;
  mcUser8             = 108;
  mcUser9             = 109;

  {For SetCarrierTrans}
  mTransOn           = 1;
  mTransOff          = 0;

  {For SetModemSpeaker}
  mSpeakerOff        = 0;
  mSpeakerOnDial     = 1;
  mSpeakerOn         = 2;
  mSpeakerOnConnect  = 3;

  {For SetModemEcho and SetModemOnlineEcho}
  mEchoOff           = 0;
  mEchoOn            = 1;

  {For HangupModem}
  mHangup            = 0;
  mOnHook            = 0;
  mOffHook           = 1;

  {For SetModemQuiet}
  mNormalResp        = 0;
  mQuietResp         = 1;

  {For SetModemResults}
  mCodeResults       = 0;
  mWordResults       = 1;

  {For SetModemVolume}
  mLow               = 0;
  mMedium            = 1;
  mHigh              = 2;

  {For SetModemCodeSet}
  mExtSet0           = 0;
  mExtSet1           = 1;
  mExtSet2           = 2;
  mExtSet3           = 3;
  mExtSet4           = 4;
  mExtSet5           = 5;
  mExtSet6           = 6;
  mExtSet7           = 7;

  {For SetDCDControl}
  mDCDAlwaysOn       = 0;
  mDCDFollowConnect  = 1;

  {For SetDTRControl}
  mDTRAlwaysOn       = 0;
  mDTRTerminateCall  = 2;

  {For initializing standard S-registers}
  SRegsInit : SRegSet =
    ((Lo:0; Hi:255; Def:0),          {0  Rings to answer}
     (Lo:0; Hi:255; Def:0),          {1  Ring counter}
     (Lo:0; Hi:127; Def:43),         {2  Escape code (ASCII 0-127)}
     (Lo:0; Hi:127; Def:13),         {3  Carriage return (ASCII 0-127)}
     (Lo:0; Hi:127; Def:10),         {4  Line feed (ASCII 0-127)}
     (Lo:0; Hi:32;  Def:8),          {5  Backspace (ASCII 0-33)}
     (Lo:0; Hi:255; Def:2),          {6  Wait period for dialtone}
     (Lo:1; Hi:255; Def:30),         {7  Wait for ring-back/carrier}
     (Lo:0; Hi:255; Def:2),          {8  Comma pause time}
     (Lo:1; Hi:255; Def:6),          {9  Carrier recognize wait}
     (Lo:1; Hi:255; Def:7),          {10 Carrier loss wait}
     (Lo:1; Hi:255; Def:70),         {11 Reserved}
     (Lo:20;Hi:255; Def:50));        {12 Escape code guard time}

  {Modem command options}
  moUsePrefix      = $0001; {Attach CmdPrefix to front of command string}
  moUseSuffix      = $0002; {Append CmdSuffix to end of command string}
  moDialTimeout    = $0004; {Use dial timeout value}

  {Flow control option flags}
  fSWTrans           = $0001;         {Software transmit flow}
  fSWRec             = $0002;         {Software receive flow}
  fHWTrans           = $0004;         {Hardware transmit flow}
  fHWRec             = $0008;         {Hardware receive flow}
  fRmtXoff           = $0010;         {Pass Xoff to remote}

  {Convenient constants for building response strings}
  cA = $41;
  cB = $42;
  cC = $43;
  cD = $44;
  cE = $45;
  cF = $46;
  cG = $47;
  cH = $48;
  cI = $49;
  cJ = $4A;
  cK = $4B;
  cL = $4C;
  cM = $4D;
  cN = $4E;
  cO = $4F;
  cP = $50;
  cQ = $51;
  cR = $52;
  cS = $53;
  cT = $54;
  cU = $55;
  cV = $56;
  cW = $57;
  cX = $58;
  cY = $59;
  cZ = $5A;
  c_ = $20;

  {Modem response codes (internal)}
  mrOk         = 0;
  mrConnect    = 1;
  mrRing       = 2;
  mrNoCarrier  = 3;
  mrError      = 4;
  mrNoDialtone = 6;
  mrBusy       = 7;
  mrNoAnswer   = 8;
  mrVoice      = 9;
  mrNone       = 99;

  {+++ option flags for numeric response connects +++}
  mnErrorControl    = $0001;   {An error correcting connection was made}
  mnOtherBPS        = $0002;   {Other BPS connection}
  mn600BPS          = $0004;   {600 BPS connection}
  mn1200BPS         = $0008;   {1200 BPS connection}
  mn2400BPS         = $0010;   {2400 BPS connection}
  mn4800BPS         = $0020;   {4800 BPS connection}
  mn7200BPS         = $0040;   {7200 BPS connection}
  mn9600BPS         = $0080;   {9600 BPS connection}
  mn12000BPS        = $0100;   {1200 BPS connection}
  mn14400BPS        = $0200;   {11400 BPS connection}

  mnBPSMask         = mnOtherBPS+mn600BPS+mn1200BPS+mn2400BPS+mn4800BPS+
                      mn7200BPS+mn9600BPs+mn12000BPS+mn14400BPS;

  {Basic Hayes command set}
  HayesCommandMax = 110;
  HayesCommandID : String[14] = 'hayes commands';
  HayesCommandSet : array[0..HayesCommandMax] of Byte = (
   {len flags chars             command type         modem command}
    3,  $07,  cA,                mcAnswer,           {Answer phone}
    4,  $00,  cA,Ord('/'),       mcRepeat,           {Rpt cmd}
    3,  $03,  cC,                mcSetCarrierTrans,  {Trans on/off}
    3,  $0F,  cD,                mcDial,             {Dial number string}
    3,  $03,  cE,                mcEcho,             {Set offline echo}
    3,  $03,  cF,                mcOnlineEcho,       {Set online echo}
    3,  $03,  cH,                mcHook,             {Set hook mode}
    3,  $03,  cM,                mcSpeaker,          {Set speaker on/off}
    3,  $03,  cO,                mcOnline,           {Go online}
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
    5,  $00,  Ord('+'),Ord('+'),Ord('+'), mcCmdMode, {Terminal to command mode}

    {-----------pad to end of array----------}
                0, 0, 0, 0, 0, 0,        {90}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,        {100}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);       {110}

  {Modem response set}
  HayesResponseMax = 120;
  HayesResponseID : String[15] = 'hayes responses';
  HayesResponseSet : array[0..HayesResponseMax] of Byte = (
   {len  text fragment                      response code      meaning}
    8,   cC,cO,cN,cN,cE,cC,cT,              mrConnect,         {Connect}
    11,  cN,cO,c_,cC,cA,cR,cR,cI,cE,cR,     mrNoCarrier,       {No carrier}
    6,   cE,cR,cR,cO,cR,                    mrError,           {Error}
    8,   cN,cO,c_,cD,cI,cA,cL,              mrNoDialtone,      {No dial tone}
    8,   cN,cO,c_,cT,cO,cN,cE,              mrNoDialtone,      {No dial tone}
    5,   cB,cU,cS,cY,                       mrBusy,            {Busy}
    10,  cN,cO,c_,cA,cN,cS,cW,cE,cR,        mrNoAnswer,        {No answer}
    6,   cV,cO,cI,cC,cE,                    mrVoice,           {Voice}
    5,   cR,cI,cN,cG,                       mrRing,            {Ring}
    3,   cO,cK,                             mrOk,              {Ok}

                               0,     {80}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     {90}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     {100}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     {110}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);    {120}

  {Modem response code set}
  HayesCodeMax = 60;
  HayesCodeID : String[11] = 'hayes codes';
  HayesCodeSet : array[0..HayesCodeMax] of Byte = (
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
       9,            $00,$00,   mrNone,            {Reserved}
       10,           $00,$10,   mrConnect,         {Connect}
       255, {End-of-table mark}

                0, 0, 0, 0, 0, 0,     {50}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);    {60}

type
  ModemCommandTable = array[0..65534] of Byte;
  ModemCommandPtr = ^ModemCommandTable;

  ModemResponseTable = array[0..65534] of Byte;
  ModemResponsePtr =  ^ModemResponseTable;

  ModemCodeTable = array[0..65534] of Byte;
  ModemCodePtr = ^ModemCodeTable;

  {For dialing numbers}
  NumberStr = String[20];
  PrefixStr = String[MaxDialStr];

  {Describes modem response codes as numbers or words}
  ResponseType = (NumericCodes, WordCodes);

  {Describes error checking options}
  ErrorStates = (eCheckOff, eCheckOn, eCheckAuto);

  {Modem record}
  ModemRecPtr = ^ModemRec;
  ModemRec = record
    PR          : PortRecPtr;           {Active port record}
    Buffer      : String;               {General purpose buffer}
    Responses   : ResponseType;         {Result code type}
    SRegs       : SRegSet;              {S registers settings}
    SRegLow     : Byte;                 {Lowest Sreg supported}
    SRegHigh    : Byte;                 {Highest Sreg supported}
    HandleResponses : Boolean;          {True if procs should get response}
    DelimChar   : Char;                 {Delimit char for modem result codes}
    CRchar      : Char;                 {Current <CR> char}
    LFchar      : Char;                 {Current <LF> char}
    SepChar     : Char;                 {Current seperator char (/)}
    Timeout     : Word;                 {Seconds to wait for modem response}
    DialTimeout : Word;                 {Seconds to wait for dialing numbers}
    DelayFactor : Word;                 {Time to delay before sending cmds}
    DialPrefix  : String[MaxDialStr];   {Dial prefix string}
    CmdPrefix   : String[10];           {Prefix for all "normal" commands}
    CmdSuffix   : Char;                 {Suffix for all "normal" commands}
    CmdFlags    : Word;                 {Option flags for the current command}
    FlowOptions : Word;                 {Flow control option bits}
    LastText    : String;               {Last text response}
    LastCode    : Integer;              {Last code reponse}
    mFlags      : Word;                 {Modem options}
    ECString    : String[10];           {Error correction string}
    ErrorControl: Boolean;              {True if error ctl connection}
    CmdTable    : ModemCommandPtr;      {Modem command table}
    CmdTableMax : Word;                 {Last index in command table}
    RespTable   : ModemResponsePtr;     {Modem response table}
    RespTableMax: Word;                 {Last index in command table}
    CodeTable   : ModemCodePtr;         {Modem code table}
    CodeTableMax: Word;                 {Last index in code table}
    ConnectSpeed: LongInt;              {Actual connect speed}
  end;

  {+++ init / done +++}
  procedure InitModem(var M : ModemRecPtr; P : PortRecPtr);
    {-Allocates and initializes a Modem}

  procedure DoneModem(M : ModemRecPtr);
    {-Dispose of this modem}

  {+++ table handling for modem commands +++}
  procedure AddModemCommand(M : ModemRecPtr; S : String;
                            Cmd : Word; Flags : Word);
    {-Add/change modem command in list}

  procedure RemoveModemCommand(M : ModemRecPtr; Cmd : Word);
    {-Remove modem command from list}

  procedure ExecuteModemCommand(M : ModemRecPtr; Cmd : Word; CmdVal : Integer);
    {-Execute the command registered for Cmd}

  {+++ table handling for modem responses +++}
  procedure AddModemResponse(M : ModemRecPtr; S : String; Code : Word);
    {-Inserts new response in best fit slot (never changes existing resp)}

  procedure RemoveModemResponse(M : ModemRecPtr; S : String);
    {-Remove the modem response S}

  procedure AddModemCode(M : ModemRecPtr; NC, Code : Byte; Options : Word);
    {-Inserts new numeric response NC in best fit slot}

  procedure RemoveModemCode(M : ModemRecPtr; NC : Byte);
    {-Remove the modem numeric response NC}

  {+++ modem command execution and response handling}
  procedure GetModemResponse(M : ModemRecPtr; CurTimeout : Integer);
    {-Wait for the result code from the last modem command}

  procedure PutModemCommand(M : ModemRecPtr; Cmd : String);
    {-Sends Cmd string to the modem and handles the response}

  function GetLastText(M : ModemRecPtr) : String;
    {-Returns text of last modem response}

  function GetLastCode(M : ModemRecPtr) : Integer;
    {-Returns code of last modem response}

  function GetConnectSpeed(M : ModemRecPtr) : LongInt;
    {-Returns the current connect speed of the modem}

  function GetLastErrorMode(M : ModemRecPtr) : Boolean;
    {-Returns True if the last connection was an error correcting one}

  {+++ misc customizations +++}
  procedure SetModemDelay(M : ModemRecPtr; DF : Word);
    {-Time (in tics) to delay before sending a modem command}

  procedure SetHandleResponses(M : ModemRecPtr; State : Boolean);
    {-Turns automatic response handling on/off}

  procedure SetDialPrefix(M : ModemRecPtr; Prefix : PrefixStr);
    {-Sets a dialing prefix (do _not_ include ATD)}

  procedure SetDCDControl(M : ModemRecPtr; Opt : Word);
    {-Sets DCD behavior (mDCDAlwaysOn or mDCDFollowConnect)}

  procedure SetDTRControl(M : ModemRecPtr; Opt : Word);
    {-Sets DTR behavior (mDTRAlwaysOn or mDTRTerminateCall)}

  procedure SetModemTimeouts(M : ModemRecPtr; Normal, Dialing : Integer);
    {-Sets timeout values for normal commands and dialing}

  procedure SetModemPort(M : ModemRecPtr; P : PortRecPtr);
    {Change modem to use port P}

  procedure SetModemErrorString(M : ModemRecPtr; EC : ModemErrorString);
    {-Change modem error string to EC}

  procedure SetModemCmdTable(M : ModemRecPtr; P : Pointer; Max : Word);
    {Change modem to use command table pointed to by P}

  procedure SetModemRespTable(M : ModemRecPtr; P : Pointer; Max : Word);
    {Change modem to use response string table pointed to by P}

  procedure SetModemCodeTable(M : ModemRecPtr; P : Pointer; Max : Word);
    {Change modem to use response code table pointed to by P}

  {+++ standard AT command set +++}
  procedure AnswerModem(M : ModemRecPtr);
    {-Answer modem immediately}

  procedure AutoAnswerModem(M : ModemRecPtr);
    {-Loops waiting to detect a RING when modem in auto answer mode}

  procedure RepeatModemCommand(M : ModemRecPtr);
    {-Repeats last modem command}

  procedure SetCarrierTrans(M : ModemRecPtr; Opt : Word);
    {-Turns carrier transmiter on/off}

  procedure DialModem(M : ModemRecPtr; TelNo : NumberStr);
    {-Dials TelNo (prefixes 'ATD' + DialPrefixStr)}

  procedure SetModemEcho(M : ModemRecPtr; Opt : Word);
    {-Turn modem echoing on/off}

  procedure SetModemOnlineEcho(M : ModemRecPtr; Opt : Word);
    {-Turn modem echoing on/off}

  procedure HangupModem(M : ModemRecPtr; Opt : Word; DropDTR : Boolean);
    {-Send hangup string or drop DTR to hangup modem}

  procedure SetModemSpeaker(M : ModemRecPtr; Opt : Word);
    {-Sets the speaker mode}

  procedure SetModemOnline(M : ModemRecPtr);
    {-Switches modem from command mode to terminal mode}

  procedure SetModemCmdMode(M : ModemRecPtr);
    {-Switches modem from terminal mode to command mode}

  procedure SetDialPulse(M : ModemRecPtr);
    {-Sets dialing to pulse mode}

  procedure SetModemQuiet(M : ModemRecPtr; Opt : Word);
    {-Set modem response mode (quite/normal)}

  procedure SetModemRegister(M : ModemRecPtr; Reg, Value : Integer);
    {-Sets the S register Reg to Value}

  function GetModemRegister(M : ModemRecPtr; Reg : Integer) : Byte;
    {-Returns string result from S-register Reg}

  procedure SetDialTone(M : ModemRecPtr);
    {-Sets dial mode to tone}

  procedure SetModemResults(M : ModemRecPtr; Opt : Word);
    {-Sets results to words or codes}

  procedure SetModemCodeSet(M : ModemRecPtr; Opt : Word);
    {-Sets the modem response code set}

  procedure ResetModem(M : ModemRecPtr);
    {-Issues ATZ command to reset modem to power-on defaults}

  procedure SetModemVolume(M : ModemRecPtr; Opt : Word);
    {-Sets the speaker volume}

implementation

  {$I APMODEM.PA1}      {ApModem's implementation}
end.
