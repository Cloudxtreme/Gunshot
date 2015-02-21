{$S-,R-,V-,I-,B-,F+,A-}

{*********************************************************}
{*                 OOPINSTM.PAS 2.03                     *}
{*           Installation program for OOPCOM             *}
{*       Copyright (c) TurboPower Software 1991.         *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}                                                      {!!.01}

unit OopInstM;
  {-main unit of installation program for OOPCOM}
interface

uses
  Dos,
  OpInline,
  OpString,
  OpDos,
  OpRoot,
  {$IFDEF Opro12}
  OpConst,
  {$ENDIF}
  OpClone,
  OpCrt,
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpAbsFld,
  OpCmd,
  OpField,
  OpFrame,
  OpWindow,
  OpSEdit,
  OpSelect,
  OpPick,
  OpEntry,
  OpMenu,
  ApPort,
  {ApUart,}                                                            {!!.01}
  ApMisc,
  OOCom,
  OOAbsPcl,

  MakeMisc,
  OOUI,       {User Interface}
  OopMain0,   {OOPCOM globals}
  OopMain1;   {load/store config code}

procedure DoOopInst;
  {-install program for OopCom}

implementation

type
  BytePtr            = ^Byte;
  ByteArrayPtr = ^ByteArray;
  ByteArray = Array[0..$FFF0] of Byte;

const
  ProgName         : string[41] = 'OOPINST 2.0 - OOPCOM Installation Program';
  ExeName          : PathStr = 'OOPCOM.EXE';
  MainFrame        : FrameArray = 'ÕÔ¸¾ÍÍ³³';
  BackdropChar     = '±';
  BackdropAttr     = $07;
  {$IFDEF UseMouse}
  MouseChar        : Char = #04;
  {$ENDIF}

  miBrowser      = 9;
  miDialer       = 12;
  miEditor       = 10;
  miHelp         = 13;
  miModem        = 14;
  miProtocols    = 15;
  miTerminal     = 16;
  miColors       = 18;
  miMisc         = 19;

  miLoad          = 0;
  miCustomize     = 1;
  miSave          = 2;
  miQuit          = 3;

  {TerminalES field IDs}
  idDefTermWinX1         = 0;
  idDefTermWinY1         = idDefTermWinX1 + 1;
  idDefTermWinX2         = idDefTermWinY1 + 1;
  idDefTermWinY2         = idDefTermWinX2 + 1;
  idScrollBackRows       = idDefTermWinY2 + 1;
  idDefComPort           = idScrollBackRows + 1;
  idDefCaptureName       = idDefComPort + 1;
  idCaptureBufferSize    = idDefCaptureName + 1;
  idBackgroundBufferBrea = idCaptureBufferSize + 1;
  idDefUseAnsi           = idBackgroundBufferBrea + 1;
  idDefDuplexType        = idDefUseAnsi + 1;
  idDefBaud              = idDefDuplexType + 1;
  idDefParity            = idDefBaud + 1;
  idDefDataBits          = idDefParity + 1;
  idDefStopBits          = idDefDataBits + 1;
  idSoftwareFlow         = idDefStopBits + 1;
  idUseDTR               = idSoftwareFlow + 1;
  idUseRTS               = idUseDTR + 1;
  idRequireDSR           = idUseRTS + 1;
  idRequireCTS           = idRequireDSR + 1;

  idHangupDropDTR        = 0;
  idDefWordCodes         = idHangupDropDTR + 1;
  idDefDialTimeout       = idDefWordCodes + 1;
  idDefTimeout           = idDefDialTimeout + 1;
  idDefDelayFactor       = idDefTimeout + 1;
  idDefDialPrefix        = idDefDelayFactor + 1;
  idDefTonePulse         = idDefDialPrefix + 1;
  idModemPickList        = idDefTonePulse + 1;

  idBrowsePages          = 0;
  idBrowserExpandTabs    = idBrowsePages + 1;
  idBrowseStripHigh      = idBrowserExpandTabs + 1;
  idBrowseHexMode        = idBrowseStripHigh + 1;
  idBrowseDefExt         = idBrowseHexMode + 1;

  idEditBufferSize       = 0;
  idEditAutoIndent       = idEditBufferSize + 1;
  idEditWordWrap         = idEditAutoIndent + 1;
  idEditDeleteJoins      = idEditWordWrap + 1;
  idEditIndentIsPara     = idEditDeleteJoins + 1;
  idEditReadPartial      = idEditIndentIsPara + 1;
  idEditMakeBackups      = idEditReadPartial + 1;
  idEditSmartTabs        = idEditMakeBackups + 1;
  idEditWrapAtLeft       = idEditSmartTabs + 1;
  idEditTabDelta         = idEditWrapAtLeft + 1;
  idEditDefExt           = idEditTabDelta + 1;

  idPhoneBookName        = 0;
  idDefPhoneExt          = idPhoneBookName + 1;

  idHelpX1               = 0;
  idHelpY1               = idHelpX1 + 1;
  idHelpX2               = idHelpY1 + 1;
  idHelpY2               = idHelpX2 + 1;
  idHelpFileName         = idHelpY2 + 1;

  idDefProtocol          = 0;
  idIncludeDirs          = idDefProtocol + 1;
  idHonorDir             = idIncludeDirs + 1;
  idOverwriteMode        = idHonorDir + 1;
  idAsciiCharDelay       = idOverwriteMode + 1;
  idAsciiLineDelay       = idAsciiCharDelay + 1;
  idZMOverride           = idAsciiLineDelay + 1;
  idZMSkipNoFile         = idZMOverride + 1;
  idMaxPacketLen         = idZMSkipNoFile + 1;
  idMaxTimeout           = idMaxPacketLen + 1;
  idPadChar              = idMaxTimeout + 1;
  idPadCount             = idPadChar + 1;
  idTerminator           = idPadCount + 1;
  idCtrlPrefix           = idTerminator + 1;
  idHiBitPrefix          = idCtrlPrefix + 1;
  idChecksumType         = idHiBitPrefix + 1;
  idRepeatPrefix         = idChecksumType + 1;

  idUseEmsForOverlays    = 0;
  idDefMouseSupport      = idUseEmsForOverlays + 1;
  idUseSoftMouseCursor   = idDefMouseSupport + 1;
  idDefColorMap          = idUseSoftMouseCursor + 1;

  {Color selector field constants}
  idWindowTextColor      = 0;
  idWindowTextMono       = 1;
  idWindowFrameColor     = 2;
  idWindowFrameMono      = 3;
  idHeaderActiveColor    = 4;
  idHeaderActiveMono     = 5;
  idHeaderInactiveColor  = 6;
  idHeaderInactiveMono   = 7;
  idShadowColor          = 8;
  idShadowMono           = 9;
  idScrollBarColor       = 10;
  idScrollBarMono        = 11;
  idSliderColor          = 12;
  idSliderMono           = 13;
  idHotSpotColor         = 14;
  idHotSpotMono          = 15;
  idMouseColor           = 16;
  idMouseMono            = 17;
  idStatusTextColor      = 18;
  idStatusTextMono       = 19;
  idStatusPromptColor    = 20;
  idStatusPromptMono     = 21;
  idStatusFieldColor     = 22;
  idStatusFieldMono      = 23;
  idMenuFrameColor       = 24;
  idMenuFrameMono        = 25;
  idMenuItemColor        = 26;
  idMenuItemMono         = 27;
  idMenuHighlightColor   = 28;
  idMenuHighlightMono    = 29;
  idMenuSelItemColor     = 30;
  idMenuSelItemMono      = 31;
  idMenuProItemColor     = 32;
  idMenuProItemMono      = 33;
  idPickSelItemColor     = 34;
  idPickSelItemMono      = 35;
  idPickProItemColor     = 36;
  idPickProItemMono      = 37;
  idDirItemColor         = 38;
  idDirItemMono          = 39;
  idDirAltItemColor      = 40;
  idDirAltItemMono       = 41;
  idDirAltSelItemColor   = 42;
  idDirAltSelItemMono    = 43;
  idBrowseTextColor      = 44;
  idBrowseTextMono       = 45;
  idBlockColor           = 46;
  idBlockMono            = 47;
  idMarkerColor          = 48;
  idMarkerMono           = 49;
  idEditTextColor        = 50;
  idEditTextMono         = 51;
  idEditCtrlColor        = 52;
  idEditCtrlMono         = 53;
  idEditHighlightColor   = 54;
  idEditHighlightMono    = 55;
  idPhoneItemColor       = 56;
  idPhoneItemMono        = 57;
  idPhoneSelItemColor    = 58;
  idPhoneSelItemMono     = 59;
  idPhonePromptColor     = 60;
  idPhonePromptMono      = 61;
  idPhoneSelPromptColor  = 62;
  idPhoneSelPromptMono   = 63;
  idPhoneSelFieldColor   = 64;
  idPhoneSelFieldMono    = 65;
  idPhoneCtrlColor       = 66;
  idPhoneCtrlMono        = 67;
  idTermTextColor        = 68;
  idTermTextMono         = 69;
  idFlexAHelpColor       = 70;
  idFlexAHelpMono        = 71;
  idFlexBHelpColor       = 72;
  idFlexBHelpMono        = 73;
  idFlexCHelpColor       = 74;
  idFlexCHelpMono        = 75;
  idUnselXRefColor       = 76;
  idUnselXRefMono        = 77;
  idSelXRefColor         = 78;
  idSelXRefMono          = 79;

  Frame1 = 'ÕÔ¸¾ÍÍ³³';
  ESWinOptions = wBordered+wClear+wUserContents;

  TerminalMsgs : Array[idDefTermWinX1..idRequireCTS] of String[80] =
    (
    'Enter the column number of the left side of the terminal window (2..74)',
    'Enter the row number of the top of the terminal window (3..20)',
    'Enter the column number of the right side of the terminal window (6..79)',
    'Enter the row number of the bottom of the terminal window (6..23)',
    'Enter the number of rows in terminal window''s scroll back buffer (25..400)',
    'Enter the communications port to use ',
    'Enter the default name for the capture file',
    'Enter the size of the capture buffer (64..9999)',
    'Enter number of characters (16..255) to buffer when window is not current',
    'Y to enable ANSI emulation, N to disable',
    'Use <Space bar> to select between half and full duplex',
    'Use <Space bar> to toggle baud rate (300..115K baud)',
    'Use <Space bar> to toggle parity (none, even, odd, mark)',
    'Use <Space bar> to toggle data bits (5..8)',
    'Use <Space bar> to toggle stop bits (1 or 2)',
    'Y to enable software flow control, N to disable',
    'Y to enable DTR hardware flow control option, N to disable',
    'Y to enable RTS hardware flow control option, N to disable',
    'Y to require DSR (a hardware flow control option), N to disable',
    'Y to require CTS (a hardware flow control option), N to disable'
    );

  BrowserMsgs : Array[idBrowsePages..idBrowseDefExt] of String[80] =
    (
    'Enter number of pages for browser to cache in ram (1..20)',
    'Y to enable tab expansion, N to disable',
    'Y to enable stripping of high bits, N to disable',
    'Y to enable Hex mode display by default, N for ASCII mode',
    'Enter the default file extension for the browser'
    );

  ModemMsgs : Array[idHangupDropDTR..idModemPickList] of String[80] =
    (
    'Y to drop DTR line to hangup modem',
    'Use <Space bar> to toggle between modem word or code responses',
    'Enter the dial timeout in ticks (approx. 18.2 ticks per second)',
    'Enter the modem command timeout in ticks (approx. 18.2 ticks per second)',
    'Enter the modem delay factor in ticks (approx. 18.2 ticks per second)',
    'Enter the prefix string to be used when dialing modem (usually blank)',
    'Use <Space bar> to toggle between tone or pulse dialing',
    'Use arrow keys to select modem type, <Enter> to select a modem, <ESC> to exit'
    );

  EditorMsgs : Array[idEditBufferSize..idEditDefExt] of String[80] =
    (
    'Enter the size of the biggest allowable file in bytes (1024..65535)',
    'Y to enable autoindent, N to disable',
    'Y to enable word wrap, N to disable',
    'Y to enable delete to join lines, N to disable',
    'Y to enable indent starts paragraph, N to disable',
    'Y to allow reading of partial files, N to disallow',
    'Y to enable making of backup files, N to disable',
    'Y to enable smart tabs, N to disable',
    'Y to enable wrap at left margin, N to disable',
    'Enter the tab delta size',
    'Enter the extension to be used by default for editor files'
    );

  HelpMsgs : Array[idHelpX1..idHelpFileName] of String[80] =
    (
    'Enter the column number of the left side of the help window (2..70)',
    'Enter the row number of the top of the terminal window (3..22)',
    'Enter the column number of the right side of the terminal window (10..79)',
    'Enter the row number of the bottom of the terminal window (6..23)',
    'Enter the name of the help file to use'
    );

  DialerMsgs : Array[idPhoneBookName..idDefPhoneExt] of String[80] =
  (
  'Enter the name of the default phone book file',
  'Enter the default extension to use with phone book files'
  );

  ProtocolMsgs : Array[idDefProtocol..idRepeatPrefix] of String[80] =
  (
    'Use <Space bar> to select the default protocol type',
    'Y to include subdirectories in file transfers',
    'Y to honor directory names in file transfers',
    'Use <Space bar> to select behavior when receiving files that already exist',
    'Delay between characters for ASCII protocol',
    'Delay between lines for ASCII protocol',
    'Y to enable receiver override of sender''s options for ZMODEM protocol',
    'Y to enable the "skip if no file" option of the ZMODEM protocol',
    'Enter the maximum packet length for KERMIT protocol (0..94)',
    'Enter the maximum timeout for KERMIT protocol in seconds (0..50)',
    'Enter the ASCII code of pad character for KERMIT protocol (0..127)',
    'Enter the pad count for KERMIT protocol (0..50)',
    'Enter the ASCII code of the terminator character for KERMIT protocol (0..127)',
    'Enter the character to be used as the control prefix for KERMIT protocol',
    'Enter the high bit prefix code for KERMIT protocol',
    'Use <Space bar> to select checksum type',
    'Enter character to use as repeat prefix for KERMIT protocol'
  );

  MiscMsgs : Array[idUseEmsForOverlays..idDefColorMap] of String[80] =
  (
    'Y to use EMS if available for overlay file',
    'Y to use the mouse within OOPCOM if a mouse is present',
    'Y to use a software mouse cursor',
    '<Space bar> to select how video attributes are chosen'
  );

  EntryColors : ColorSet = (
    TextColor       : $1E; TextMono       : $0F;
    CtrlColor       : $1C; CtrlMono       : $07;
    FrameColor      : $13; FrameMono      : $07;
    HeaderColor     : $3F; HeaderMono     : $70;
    ShadowColor     : $08; ShadowMono     : $70;
    HighlightColor  : $4F; HighlightMono  : $70;
    PromptColor     : $30; PromptMono     : $07;
    SelPromptColor  : $30; SelPromptMono  : $07;
    ProPromptColor  : $30; ProPromptMono  : $07;
    FieldColor      : $31; FieldMono      : $0F;
    SelFieldColor   : $31; SelFieldMono   : $0F;
    ProFieldColor   : $17; ProFieldMono   : $07;
    ScrollBarColor  : $13; ScrollBarMono  : $07;
    SliderColor     : $13; SliderMono     : $0F;
    HotSpotColor    : $30; HotSpotMono    : $70;
    BlockColor      : $3E; BlockMono      : $0F;
    MarkerColor     : $5F; MarkerMono     : $70;
    DelimColor      : $31; DelimMono      : $0F;
    SelDelimColor   : $31; SelDelimMono   : $0F;
    ProDelimColor   : $31; ProDelimMono   : $0F;
    SelItemColor    : $3E; SelItemMono    : $70;
    ProItemColor    : $17; ProItemMono    : $07;
    HighItemColor   : $1F; HighItemMono   : $0F;
    AltItemColor    : $1F; AltItemMono    : $0F;
    AltSelItemColor : $3F; AltSelItemMono : $70;
    FlexAHelpColor  : $1F; FlexAHelpMono  : $0F;
    FlexBHelpColor  : $1F; FlexBHelpMono  : $0F;
    FlexCHelpColor  : $1B; FlexCHelpMono  : $70;
    UnselXrefColor  : $1E; UnselXrefMono  : $09;
    SelXrefColor    : $5F; SelXrefMono    : $70;
    MouseColor      : $4F; MouseMono      : $70
  );
  MenuColors : ColorSet = (
    TextColor       : $30; TextMono       : $07;
    CtrlColor       : $30; CtrlMono       : $07;
    FrameColor      : $30; FrameMono      : $07;
    HeaderColor     : $3F; HeaderMono     : $70;
    ShadowColor     : $08; ShadowMono     : $70;
    HighlightColor  : $3F; HighlightMono  : $0F;
    PromptColor     : $30; PromptMono     : $07;
    SelPromptColor  : $30; SelPromptMono  : $07;
    ProPromptColor  : $30; ProPromptMono  : $07;
    FieldColor      : $1E; FieldMono      : $07;
    SelFieldColor   : $31; SelFieldMono   : $0F;
    ProFieldColor   : $17; ProFieldMono   : $07;
    ScrollBarColor  : $13; ScrollBarMono  : $07;
    SliderColor     : $13; SliderMono     : $0F;
    HotSpotColor    : $30; HotSpotMono    : $70;
    BlockColor      : $3E; BlockMono      : $0F;
    MarkerColor     : $2F; MarkerMono     : $70;
    DelimColor      : $31; DelimMono      : $0F;
    SelDelimColor   : $31; SelDelimMono   : $0F;
    ProDelimColor   : $31; ProDelimMono   : $0F;
    SelItemColor    : $1F; SelItemMono    : $70;
    ProItemColor    : $37; ProItemMono    : $07;
    HighItemColor   : $3F; HighItemMono   : $0F;
    AltItemColor    : $1F; AltItemMono    : $70;
    AltSelItemColor : $3F; AltSelItemMono : $0F;
    FlexAHelpColor  : $1F; FlexAHelpMono  : $0F;
    FlexBHelpColor  : $1B; FlexBHelpMono  : $0F;
    FlexCHelpColor  : $1C; FlexCHelpMono  : $70;
    UnselXrefColor  : $1E; UnselXrefMono  : $09;
    SelXrefColor    : $5F; SelXrefMono    : $70;
    MouseColor      : $4F; MouseMono      : $70
  );
  oiColors : ColorSet = (
    TextColor       : $1F; TextMono        : $0F;
    CtrlColor       : $1E; CtrlMono        : $0F;
    FrameColor      : $1A; FrameMono       : $07;
    HeaderColor     : $2F; HeaderMono      : $70;
    ShadowColor     : $08; ShadowMono      : $0F;
    HighlightColor  : $4F; HighlightMono   : $09;
    PromptColor     : $1A; PromptMono      : $07;
    SelPromptColor  : $1A; SelPromptMono   : $07;
    ProPromptColor  : $17; ProPromptMono   : $07;
    FieldColor      : $1F; FieldMono       : $0F;
    SelFieldColor   : $2F; SelFieldMono    : $70;
    ProFieldColor   : $17; ProFieldMono    : $07;
    ScrollBarColor  : $13; ScrollBarMono   : $07;
    SliderColor     : $13; SliderMono      : $0F;
    HotSpotColor    : $30; HotSpotMono     : $70;
    BlockColor      : $1F; BlockMono       : $70;
    MarkerColor     : $3F; MarkerMono      : $70;
    DelimColor      : $31; DelimMono       : $0F;
    SelDelimColor   : $31; SelDelimMono    : $0F;
    ProDelimColor   : $31; ProDelimMono    : $0F;
    SelItemColor    : $2F; SelItemMono     : $70;
    ProItemColor    : $17; ProItemMono     : $07;
    HighItemColor   : $1F; HighItemMono    : $0F;
    AltItemColor    : $1F; AltItemMono     : $0F;
    AltSelItemColor : $3F; AltSelItemMono  : $70;
    FlexAHelpColor  : $1F; FlexAHelpMono   : $0F;
    FlexBHelpColor  : $1F; FlexBHelpMono   : $0F;
    FlexCHelpColor  : $1B; FlexCHelpMono   : $70;
    UnselXrefColor  : $1E; UnselXrefMono   : $09;
    SelXrefColor    : $3F; SelXrefMono     : $70;
    MouseColor      : $4F; MouseMono       : $70
  );

  Clone : ByteArrayPtr = Nil;
  Modified : Boolean = False;
  MainMenuHlp =
    'Use arrow keys to move highlight bar, <Enter> to select, <ESC> to exit';
  LoadHlp =
    'Load OOPCOM configuration from a disk file';

var
  ConfigSize : Word;
  OptMenu : Menu;
  TerminalES : EntryScreen;
  ModemES    : EntryScreen;
  DialerES   : EntryScreen;
  EditorES   : EntryScreen;
  HelpES     : EntryScreen;
  ProtoES    : EntryScreen;
  BrowserES  : EntryScreen;
  MiscES     : EntryScreen;
  ModemPL    : PickListPtr;
  UseDTR     : Boolean;
  UseRTS     : Boolean;
  RequireDSR : Boolean;
  RequireCTS : Boolean;
  SS         : ScrollingSelector;
  CS         : ColorSelector;
  AboutWin   : CommandWindow;

{$I OOPINSTM.PA1}

  procedure ErrorHandler(UnitCode : Byte; var ErrCode : Word; Msg : string);
    {-Report errors}
  begin
    if Msg = '' then
      Msg := 'Internal error '+Long2Str(ErrCode);
    ErrorMessage(Msg, True);
  end;

  {----------------color selection code ------------------}
  function InitColorSelector : Word;
    {-Initialize the color selector}
  begin
    if not CS.InitCustom(5, 4, OiColors, DefWindowOptions, False) then
      InitColorSelector := epFatal+ecOutOfMemory
    else with CS do begin
      wFrame.AddShadow(shBR, shSeeThru);
      SetBoxAttr($1F, $0F);
      SetColor(0);
      SetErrorProc(ErrorHandler);
      Draw;
      InitColorSelector := GetLastError;
    end;
  end;

  procedure EditAttr(var B : Byte);
    {-"Edit" the specified color attribute}
  begin
    with CS do begin
      Select;

      Message('Press <Enter> to select, <Esc> to cancel', True);

      SetColor(B);
      Process;
      if (GetLastCommand <> ccQuit) and (GetLastCommand <> ccError) then
        if GetColor <> B then begin
          B := GetColor;
          Modified := True;
        end;

      SS.Select;
    end;
  end;

  function GetColorPtr(ID : Word) : BytePtr;
    {-Point to the attribute pair corresponding to the field}
  var
    O : Word;
  begin
    case ID of
      idWindowTextColor     : O := Ofs(OOPMAIN0.TpUiColors.TextColor);
      idWindowTextMono      : O := Ofs(OOPMAIN0.TpUiColors.TextMono);
      idWindowFrameColor    : O := Ofs(OOPMAIN0.TpUiColors.FrameColor);
      idWindowFrameMono     : O := Ofs(OOPMAIN0.TpUiColors.FrameMono);
      idHeaderActiveColor   : O := Ofs(OOPMAIN0.TpUiColors.HeaderColor);
      idHeaderActiveMono    : O := Ofs(OOPMAIN0.TpUiColors.HeaderMono);
      idHeaderInactiveColor : O := Ofs(OOPMAIN0.InactiveColor);
      idHeaderInactiveMono  : O := Ofs(OOPMAIN0.InactiveMono);
      idShadowColor         : O := Ofs(OOPMAIN0.TpUiColors.ShadowColor);
      idShadowMono          : O := Ofs(OOPMAIN0.TpUiColors.ShadowMono);
      idScrollBarColor      : O := Ofs(OOPMAIN0.TpUiColors.ScrollBarColor);
      idScrollBarMono       : O := Ofs(OOPMAIN0.TpUiColors.ScrollBarMono);
      idSliderColor         : O := Ofs(OOPMAIN0.TpUiColors.SliderColor);
      idSliderMono          : O := Ofs(OOPMAIN0.TpUiColors.SliderMono);
      idHotSpotColor        : O := Ofs(OOPMAIN0.TpUiColors.HotSpotColor);
      idHotSpotMono         : O := Ofs(OOPMAIN0.TpUiColors.HotSpotMono);
      idMouseColor          : O := Ofs(OOPMAIN0.TpUiColors.MouseColor);
      idMouseMono           : O := Ofs(OOPMAIN0.TpUiColors.MouseMono);
      idStatusTextColor     : O := Ofs(OOPMAIN0.StatusColor);
      idStatusTextMono      : O := Ofs(OOPMAIN0.StatusMono);
      idStatusPromptColor   : O := Ofs(OOPMAIN0.TpUiColors.SelPromptColor);
      idStatusPromptMono    : O := Ofs(OOPMAIN0.TpUiColors.SelPromptMono);
      idStatusFieldColor    : O := Ofs(OOPMAIN0.TpUiColors.SelFieldColor);
      idStatusFieldMono     : O := Ofs(OOPMAIN0.TpUiColors.SelFieldMono);
      idMenuFrameColor      : O := Ofs(OOPMAIN0.TpUiMenuColors.FrameColor);
      idMenuFrameMono       : O := Ofs(OOPMAIN0.TpUiMenuColors.FrameMono);
      idMenuItemColor       : O := Ofs(OOPMAIN0.TpUiMenuColors.TextColor);
      idMenuItemMono        : O := Ofs(OOPMAIN0.TpUiMenuColors.TextMono);
      idMenuHighlightColor  : O := Ofs(OOPMAIN0.TpUiMenuColors.HighItemColor);
      idMenuHighlightMono   : O := Ofs(OOPMAIN0.TpUiMenuColors.HighItemMono);
      idMenuSelItemColor    : O := Ofs(OOPMAIN0.TpUiMenuColors.SelItemColor);
      idMenuSelItemMono     : O := Ofs(OOPMAIN0.TpUiMenuColors.SelItemMono);
      idMenuProItemColor    : O := Ofs(OOPMAIN0.TpUiMenuColors.ProItemColor);
      idMenuProItemMono     : O := Ofs(OOPMAIN0.TpUiMenuColors.ProItemMono);
      idPickSelItemColor    : O := Ofs(OOPMAIN0.TpUiColors.SelItemColor);
      idPickSelItemMono     : O := Ofs(OOPMAIN0.TpUiColors.SelItemMono);
      idPickProItemColor    : O := Ofs(OOPMAIN0.TpUiColors.ProItemColor);
      idPickProItemMono     : O := Ofs(OOPMAIN0.TpUiColors.ProItemMono);
      idDirItemColor        : O := Ofs(OOPMAIN0.DirItemColor);
      idDirItemMono         : O := Ofs(OOPMAIN0.DirItemMono);
      idDirAltItemColor     : O := Ofs(OOPMAIN0.TpUiColors.AltItemColor);
      idDirAltItemMono      : O := Ofs(OOPMAIN0.TpUiColors.AltItemMono);
      idDirAltSelItemColor  : O := Ofs(OOPMAIN0.TpUiColors.AltSelItemColor);
      idDirAltSelItemMono   : O := Ofs(OOPMAIN0.TpUiColors.AltSelItemMono);
      idBrowseTextColor     : O := Ofs(OOPMAIN0.BrowseTextColor);
      idBrowseTextMono      : O := Ofs(OOPMAIN0.BrowseTextMono);
      idBlockColor          : O := Ofs(OOPMAIN0.TpUiColors.BlockColor);
      idBlockMono           : O := Ofs(OOPMAIN0.TpUiColors.BlockMono);
      idMarkerColor         : O := Ofs(OOPMAIN0.TpUiColors.MarkerColor);
      idMarkerMono          : O := Ofs(OOPMAIN0.TpUiColors.MarkerMono);
      idEditTextColor       : O := Ofs(OOPMAIN0.EditTextColor);
      idEditTextMono        : O := Ofs(OOPMAIN0.EditTextMono);
      idEditCtrlColor       : O := Ofs(OOPMAIN0.TpUiColors.CtrlColor);
      idEditCtrlMono        : O := Ofs(OOPMAIN0.TpUiColors.CtrlMono);
      idEditHighlightColor  : O := Ofs(OOPMAIN0.TpUiColors.HighlightColor);
      idEditHighlightMono   : O := Ofs(OOPMAIN0.TpUiColors.HighlightMono);
      idPhoneItemColor      : O := Ofs(OOPMAIN0.PhoneItemColor);
      idPhoneItemMono       : O := Ofs(OOPMAIN0.PhoneItemMono);
      idPhoneSelItemColor   : O := Ofs(OOPMAIN0.PhoneSelItemColor);
      idPhoneSelItemMono    : O := Ofs(OOPMAIN0.PhoneSelItemMono);
      idPhonePromptColor    : O := Ofs(OOPMAIN0.PhonePromptColor);
      idPhonePromptMono     : O := Ofs(OOPMAIN0.PhonePromptMono);
      idPhoneSelPromptColor : O := Ofs(OOPMAIN0.PhoneSelPromptColor);
      idPhoneSelPromptMono  : O := Ofs(OOPMAIN0.PhoneSelPromptMono);
      idPhoneSelFieldColor  : O := Ofs(OOPMAIN0.PhoneSelFieldColor);
      idPhoneSelFieldMono   : O := Ofs(OOPMAIN0.PhoneSelFieldMono);
      idPhoneCtrlColor      : O := Ofs(OOPMAIN0.PhoneCtrlColor);
      idPhoneCtrlMono       : O := Ofs(OOPMAIN0.PhoneCtrlMono);
      idTermTextColor       : O := Ofs(OOPMAIN0.TermWinTextColor);
      idTermTextMono        : O := Ofs(OOPMAIN0.TermWinTextMono);
      idFlexAHelpColor      : O := Ofs(OOPMAIN0.TpUiColors.FlexAHelpColor);
      idFlexAHelpMono       : O := Ofs(OOPMAIN0.TpUiColors.FlexAHelpMono);
      idFlexBHelpColor      : O := Ofs(OOPMAIN0.TpUiColors.FlexBHelpColor);
      idFlexBHelpMono       : O := Ofs(OOPMAIN0.TpUiColors.FlexBHelpMono);
      idFlexCHelpColor      : O := Ofs(OOPMAIN0.TpUiColors.FlexCHelpColor);
      idFlexCHelpMono       : O := Ofs(OOPMAIN0.TpUiColors.FlexCHelpMono);
      idUnselXRefColor      : O := Ofs(OOPMAIN0.TpUiColors.UnselXRefColor);
      idUnselXRefMono       : O := Ofs(OOPMAIN0.TpUiColors.UnselXRefMono);
      idSelXRefColor        : O := Ofs(OOPMAIN0.TpUiColors.SelXRefColor);
      idSelXRefMono         : O := Ofs(OOPMAIN0.TpUiColors.SelXRefMono);
    end;
    GetColorPtr := Ptr(DSeg, O);
  end;

  {$F+}

  procedure PreSelect(SP : SelectorPtr; ID : Word);
    {-Our pre-select routine}
  begin
    Message(
      'Press <Enter> to select, <Esc> to return to main menu', True);
  end;

  procedure GetAction(SP : SelectorPtr; ID : Word);
    {-Our action routine}
  begin
    EditAttr(GetColorPtr(ID)^);
    PreSelect(SP, ID);
  end;

  procedure GetField(ID : Word; NeedPrompt : Boolean; var S : string);
    {-Our GetField routine}
  var
    B : Byte;
  begin
    if NeedPrompt then
      case ID of
        idWindowTextColor     : S := 'Text';
        idWindowFrameColor    : S := 'Frame';
        idHeaderActiveColor   : S := 'Header, active window';
        idHeaderInactiveColor : S := 'Header, inactive window';
        idShadowColor         : S := 'Shadow';
        idScrollBarColor      : S := 'Scroll bar';
        idSliderColor         : S := 'Scroll bar slider';
        idHotSpotColor        : S := 'Hot spots, scroll bar arrows';
        idMouseColor          : S := 'Mouse cursor';
        idStatusTextColor     : S := 'Text';
        idStatusPromptColor   : S := 'Edit prompt';
        idStatusFieldColor    : S := 'Edit field';
        idMenuFrameColor      : S := 'Frame';
        idMenuItemColor       : S := 'Unselected item';
        idMenuHighlightColor  : S := 'Highlighted char';
        idMenuSelItemColor    : S := 'Selected item';
        idMenuProItemColor    : S := 'Unselected item';
        idPickSelItemColor    : S := 'Selected item';
        idPickProItemColor    : S := 'Protected item';
        idDirItemColor        : S := 'Filename, unselected';
        idDirAltItemColor     : S := 'Directory name, unselected';
        idDirAltSelItemColor  : S := 'Directory name, selected';
        idBrowseTextColor     : S := 'Text';
        idBlockColor          : S := 'Marked block (Editor also)';
        idMarkerColor         : S := 'Text marker (Editor also)';
        idEditTextColor       : S := 'Text';
        idEditCtrlColor       : S := 'Control characters';
        idEditHighlightColor  : S := 'Found text';
        idPhoneItemColor      : S := 'Unselected entry';
        idPhoneSelItemColor   : S := 'Selected entry';
        idPhonePromptColor    : S := 'Prompt, unselected';
        idPhoneSelPromptColor : S := 'Prompt, selected';
        idPhoneSelFieldColor  : S := 'Field, selected';
        idPhoneCtrlColor      : S := 'Control characters';
        idTermTextColor       : S := 'Text';
        idFlexAHelpColor      : S := 'Help attribute A';
        idFlexBHelpColor      : S := 'Help attribute B';
        idFlexCHelpColor      : S := 'Help attribute C';
        idUnselXRefColor      : S := 'Unselected xref';
        idSelXRefColor        : S := 'Selected xref';
        else                    S := '';
      end
    else
      {return the attribute's value in hex}
      S := HexB(GetColorPtr(ID)^);
  end;

  {$F-}

  function InitSelector : Word;
    {-Initialize the selector}
  const
    WinOptions = wBordered+wClear+wUserContents+wFullMouseWindow;
  begin
    with SS do begin
      if not InitCustom(38, 4, 76, ScreenHeight-4, OiColors, WinOptions) then begin
        InitSelector := InitStatus;
        Exit;
      end;

      wFrame.SetFrameType(MainFrame);
      wFrame.AddShadow(shBR, shSeeThru);
      wFrame.AddHeader(' Colors ', heTC);
      wFrame.AddHeaderColor(' Color Mono ', heTR, $1F, $0F);
      wFrame.AddCustomScrollBar(frRR, 1, MaxLongInt, 1, 1, '²', '°', OiColors);
      SetWrapMode(StopAtEdges);

      SetActionProc(GetAction);
      SetGetFieldProc(GetField);
      SetErrorProc(ErrorHandler);
      SetPreSelectProc(PreSelect);

      AddTextField('Windows, General', 1, 2);
      AddTextField('Status line', 12, 2);
      AddTextField('Menus', 17, 2);
      AddTextField('Pick list', 24, 2);
      AddTextField('Directory list', 28, 2);
      AddTextField('Browser', 33, 2);
      AddTextField('Editor', 38, 2);
      AddTextField('Phone book (list)', 43, 2);
      AddTextField('Phone book (editor)', 47, 2);
      AddTextField('Terminal window', 53, 2);
      AddTextField('Help', 56, 2);

    {idWindowTextColor:}
      AddField(02, 02, 04, 02, 32, 02, 01);

    {idWindowTextMono:}
      AddField(02, 35, 00, 02, 35, 02, 02);

    {idWindowFrameColor:}
      AddField(03, 02, 05, 03, 32, 02, 03);

    {idWindowFrameMono:}
      AddField(03, 35, 00, 03, 35, 02, 04);

    {idHeaderActiveColor:}
      AddField(04, 02, 21, 04, 32, 02, 05);

    {idHeaderActiveMono:}
      AddField(04, 35, 00, 04, 35, 02, 06);

    {idHeaderInactiveColor:}
      AddField(05, 02, 23, 05, 32, 02, 07);

    {idHeaderInactiveMono:}
      AddField(05, 35, 00, 05, 35, 02, 08);

    {idShadowColor:}
      AddField(06, 02, 06, 06, 32, 02, 09);

    {idShadowMono:}
      AddField(06, 35, 00, 06, 35, 02, 10);

    {idScrollBarColor:}
      AddField(07, 02, 10, 07, 32, 02, 11);

    {idScrollBarMono:}
      AddField(07, 35, 00, 07, 35, 02, 12);

    {idSliderColor:}
      AddField(08, 02, 17, 08, 32, 02, 13);

    {idSliderMono:}
      AddField(08, 35, 00, 08, 35, 02, 14);

    {idHotSpotColor:}
      AddField(09, 02, 28, 09, 32, 02, 15);

    {idHotSpotMono:}
      AddField(09, 35, 00, 09, 35, 02, 16);

    {idMouseColor:}
      AddField(10, 02, 12, 10, 32, 02, 17);

    {idMouseMono:}
      AddField(10, 35, 00, 10, 35, 02, 18);

    {idStatusTextColor:}
      AddField(13, 02, 04, 13, 32, 02, 19);

    {idStatusTextMono:}
      AddField(13, 35, 00, 13, 35, 02, 20);

    {idStatusPromptColor:}
      AddField(14, 02, 11, 14, 32, 02, 21);

    {idStatusPromptMono:}
      AddField(14, 35, 00, 14, 35, 02, 22);

    {idStatusFieldColor:}
      AddField(15, 02, 10, 15, 32, 02, 23);

    {idStatusFieldMono:}
      AddField(15, 35, 00, 15, 35, 02, 24);

    {idMenuFrameColor:}
      AddField(18, 02, 05, 18, 32, 02, 25);

    {idMenuFrameMono:}
      AddField(18, 35, 00, 18, 35, 02, 26);

    {idMenuItemColor:}
      AddField(19, 02, 15, 19, 32, 02, 27);

    {idMenuItemMono:}
      AddField(19, 35, 00, 19, 35, 02, 28);

    {idMenuHighlightColor:}
      AddField(20, 02, 16, 20, 32, 02, 29);

    {idMenuHighlightMono:}
      AddField(20, 35, 00, 20, 35, 02, 30);

    {idMenuSelItemColor:}
      AddField(21, 02, 13, 21, 32, 02, 31);

    {idMenuSelItemMono:}
      AddField(21, 35, 00, 21, 35, 02, 32);

    {idMenuProItemColor:}
      AddField(22, 02, 15, 22, 32, 02, 33);

    {idMenuProItemMono:}
      AddField(22, 35, 00, 22, 35, 02, 34);

    {idPickSelItemColor:}
      AddField(25, 02, 13, 25, 32, 02, 35);

    {idPickSelItemMono:}
      AddField(25, 35, 00, 25, 35, 02, 36);

    {idPickProItemColor:}
      AddField(26, 02, 14, 26, 32, 02, 37);

    {idPickProItemMono:}
      AddField(26, 35, 00, 26, 35, 02, 38);

    {idDirItemColor:}
      AddField(29, 02, 20, 29, 32, 02, 39);

    {idDirItemMono:}
      AddField(29, 35, 00, 29, 35, 02, 40);

    {idDirAltItemColor:}
      AddField(30, 02, 26, 30, 32, 02, 41);

    {idDirAltItemMono:}
      AddField(30, 35, 00, 30, 35, 02, 42);

    {idDirAltSelItemColor:}
      AddField(31, 02, 24, 31, 32, 02, 43);

    {idDirAltSelItemMono:}
      AddField(31, 35, 00, 31, 35, 02, 44);

    {idBrowseTextColor:}
      AddField(34, 02, 04, 34, 32, 02, 45);

    {idBrowseTextMono:}
      AddField(34, 35, 00, 34, 35, 02, 46);

    {idBlockColor:}
      AddField(35, 02, 26, 35, 32, 02, 47);

    {idBlockMono:}
      AddField(35, 35, 00, 35, 35, 02, 48);

    {idMarkerColor:}
      AddField(36, 02, 25, 36, 32, 02, 49);

    {idMarkerMono:}
      AddField(36, 35, 00, 36, 35, 02, 50);

    {idEditTextColor:}
      AddField(39, 02, 04, 39, 32, 02, 57);

    {idEditTextMono:}
      AddField(39, 35, 00, 39, 35, 02, 58);

    {idEditCtrlColor:}
      AddField(40, 02, 18, 40, 32, 02, 59);

    {idEditCtrlMono:}
      AddField(40, 35, 00, 40, 35, 02, 60);

    {idEditHighlightColor:}
      AddField(41, 02, 10, 41, 32, 02, 61);

    {idEditHighlightMono:}
      AddField(41, 35, 00, 41, 35, 02, 62);

    {idPhoneItemColor:}
      AddField(44, 02, 16, 44, 32, 02, 63);

    {idPhoneItemMono:}
      AddField(44, 35, 00, 44, 35, 02, 64);

    {idPhoneSelItemColor:}
      AddField(45, 02, 14, 45, 32, 02, 65);

    {idPhoneSelItemMono:}
      AddField(45, 35, 00, 45, 35, 02, 66);

    {idPhonePromptColor:}
      AddField(48, 02, 18, 48, 32, 02, 67);

    {idPhonePromptMono:}
      AddField(48, 35, 00, 48, 35, 02, 68);

    {idPhoneSelPromptColor:}
      AddField(49, 02, 16, 49, 32, 02, 69);

    {idPhoneSelPromptMono:}
      AddField(49, 35, 00, 49, 35, 02, 70);

    {idPhoneSelFieldColor:}
      AddField(50, 02, 15, 50, 32, 02, 71);

    {idPhoneSelFieldMono:}
      AddField(50, 35, 00, 50, 35, 02, 72);

    {idPhoneCtrlColor:}
      AddField(51, 02, 18, 51, 32, 02, 73);

    {idPhoneCtrlMono:}
      AddField(51, 35, 00, 51, 35, 02, 74);

    {idTermTextColor:}
      AddField(54, 02, 18, 54, 32, 02, 75);

    {idTermTextMono:}
      AddField(54, 35, 00, 54, 35, 02, 76);

    {idFlexAHelpColor:}
      AddField(57, 02, 18, 57, 32, 02, 77);

    {idFlexAHelpMono:}
      AddField(57, 35, 00, 57, 35, 02, 78);

    {idFlexBHelpColor:}
      AddField(58, 02, 18, 58, 32, 02, 79);

    {idFlexBHelpMono:}
      AddField(58, 35, 00, 58, 35, 02, 80);

    {idFlexCHelpColor:}
      AddField(59, 02, 18, 59, 32, 02, 81);

    {idFlexCHelpMono:}
      AddField(59, 35, 00, 59, 35, 02, 82);

    {idUnselXRefColor:}
      AddField(60, 02, 18, 60, 32, 02, 83);

    {idUnselXRefMono:}
      AddField(60, 35, 00, 60, 35, 02, 83);

    {idSelXRefColor:}
      AddField(61, 02, 18, 61, 32, 02, 84);

    {idSelXRefMono:}
      AddField(61, 35, 00, 61, 35, 02, 85);

      AllocateScreen;

      InitSelector := GetLastError;
    end;
  end;

  procedure EditColors;
    {-Edit colors}
  var
    Status : Word;
    Cmd    : Word;
  begin
    {initialize selector}
    Status := InitSelector;
    if Status <> 0 then begin
      InsufficientMemory;
      Exit;
    end;
    Status := InitColorSelector;
    if Status <> 0 then begin
      InsufficientMemory;
      Exit;
    end;

    repeat
      SS.Process;
      Cmd := SS.GetLastCommand;
    until (Cmd = ccQuit) or (Cmd = ccError) or (Cmd = ccDone);

    {get rid of selector and color selector}
    SS.Erase;
    CS.Erase;
    SS.Done;
    CS.Done;
  end;

  {------------------------------------------------------}

  function OffsetOf(var D) : Word;
    {-Return the byte offset of the passed var relative to our config data}
  type
    SO  =
      record
        O, S : Word;
      end;
  var
    P : Pointer;
  begin
    P := @D;
    OffsetOf := SO(P).O - Ofs(OopComID);
  end;

  {The following RestoreXXX procedures are used to copy data back from the
   clone data area into the actual data area.}

  procedure RestoreBrowser;
  begin
    Move(Clone^[OffsetOf(BrowsePages)], BrowsePages,
         (Ofs(BrowseDefExt) + SizeOf(BrowseDefExt)) - Ofs(BrowsePages));
  end;

  procedure RestoreDialer;
  begin
    Move(Clone^[OffsetOf(DefPhoneExt)], DefPhoneExt,
         (Ofs(PhoneBookName) + SizeOf(PhoneBookName)) - Ofs(DefPhoneExt));
  end;

  procedure RestoreEditor;
  begin
    Move(Clone^[OffsetOf(EditBufferSize)], EditBufferSize,
         (Ofs(EditDefExt) + SizeOf(EditDefExt)) - Ofs(EditBufferSize));
  end;

  procedure RestoreHelp;
  begin
    Move(Clone^[OffsetOf(HelpFileName)], HelpFileName,
         (Ofs(HelpY2) + SizeOf(HelpY2)) - Ofs(HelpFileName));
  end;

  procedure RestoreModem;
  begin
    Move(Clone^[OffsetOf(HangupDropDTR)], HangupDropDTR,
         Ofs(ModemLibName) - Ofs(HangupDropDTR));
  end;

  procedure RestoreProtocol;
  begin
    Move(Clone^[OffsetOf(DefProtocol)], DefProtocol,
         (Ofs(RepeatPrefix) + SizeOf(RepeatPrefix)) - Ofs(DefProtocol));
  end;

  procedure RestoreTerminal;
  begin
    Move(Clone^[OffsetOf(DefTermWinX1)], DefTermWinX1,
         (Ofs(DefSWFlow) + SizeOf(DefSWFlow)) - Ofs(DefTermWinX1));
  end;

  procedure RestoreMisc;
  begin
    Move(Clone^[OffsetOf(UseEmsForOverlays)], UseEmsForOverlays,
         (Ofs(UseSoftMouseCursor) + SizeOf(UseSoftMouseCursor)) -
         Ofs(UseEmsForOverlays));
  end;

  function DoEdit(var ES : EntryScreen) : Boolean;
  begin
    with ES do begin
      Process;
      Erase;
      DoEdit := GetLastCommand = ccDone;
    end;
  end;

  procedure SaveConfiguration;
  var
    Msg : String;
    FName : PathStr;
    ErrorCode : Word;
    Esc : Boolean;
  begin
    FName := ConfigFileName;
    if not GetFile(0, 'Enter file name to save: ', True, True,
                   True, False, SizeOf(FName) - 1, 'CFG', FName) then
      Exit;
    if Length(FName) = 0 then
      Exit;
    ErrorCode := StoreConfiguration(FName, @OopComID, ConfigSize);
    case ErrorCode of
      0 :
        begin
          Msg := 'Configuration stored to ' + FName;
          Modified := False;
        end;
      1 :
        Msg := 'Disk full';
      else
        Msg := 'Unknown error writing file: ' + Long2Str(ErrorCode);
    end;
    if ErrorCode = 0 then
      TempMessage(Msg, TempMessageDelay)
    else
      ErrorMessage(Msg, True);
  end;

procedure DoOopInst;
  {-install program for OopCom}
var
  Cmd : Word;
  MC : LongInt;
  ConfigFName : PathStr;
  S : String[12];
  Esc : Boolean;

begin
  ConfigSize := SizeOfConfig;
  SystemIsPs2 := IsPs2;
  {$IFDEF LargeComNameSet}                                             {!!.01}
  S := '(COM1..COM36)';                                                {!!.01}
  {$ELSE}                                                              {!!.01}
  {$IFDEF UseDigi14}                                                   {!!.01}
  S := '(COM1..COM8)';                                                 {!!.01}
  {$ELSE}                                                              {!!.01}
  if SystemIsPs2 then
    S := '(COM1..COM8)'
  else
    S := '(COM1..COM4)';
  {$ENDIF}                                                             {!!.01}
  {$ENDIF}                                                             {!!.01}

  TerminalMsgs[idDefComPort] := TerminalMsgs[idDefComPort] + S;
  {initialize menus}
  if not InitMainMenu then begin
    WriteLn(emInsufficientMemory);
    Halt(1);
  end;

  {initialize mouse, screen stuff}
  InitScreen;
  About;
  with MainMenu do begin
    Select;
    Draw;
  end;
  if ParamCount = 1 then
    ConfigFName := ParamStr(1)
  else
    ConfigFName := ConfigFileName;

  if ExistFile(ConfigFName) then begin
    Message('Reading configuration from ' + ConfigFName, True);
    LoadConfig(ConfigFName);
  end
  else begin
    Message(ConfigFName + ' not found, using defaults...', True);
    Delay(1500);
  end;

  CloneData(True);
  InitModemList;
  with MainMenu do begin
    repeat
      Message(MainMenuHlp, True);
      {get a menu selection}
      Process;

      Cmd := GetLastCommand;
      if Cmd = ccSelect then begin
        MC := MenuChoice;
        case Byte(MC) of
          miLoad : LoadDefaults;
          miBrowser :
            begin
              InitBrowser;
              if DoEdit(BrowserES) then
                CloneData(False)
              else
                RestoreBrowser;
              BrowserES.Done;
            end;
          miDialer  :
            begin
              InitDialer;
              if DoEdit(DialerES) then
                CloneData(False)
              else
                RestoreDialer;
              DialerES.Done;
            end;
          miEditor :
            begin
              InitEditor;
              if DoEdit(EditorES) then
                CloneData(False)
              else
                RestoreEditor;
              EditorES.Done;
            end;
          miHelp :
            begin
              InitHelp;
              if DoEdit(HelpES) then
                CloneData(False)
              else
                RestoreHelp;
              HelpES.Done;
            end;
          miModem :
            begin
              InitModem;
              if DoEdit(ModemES) then
                CloneData(False)
              else
                RestoreModem;
              ModemES.Done;
            end;
          miProtocols :
            begin
              InitProtocol;
              if DoEdit(ProtoES) then
                CloneData(False)
              else
                RestoreProtocol;
              ProtoES.Done;
            end;
          miTerminal :
            begin
              InitTerminal;
              UnpackHWFlow;
              if DoEdit(TerminalES) then begin
                PackHWFlow;
                CloneData(False)
              end
              else
                RestoreTerminal;
              TerminalES.DOne;
            end;
          miColors :
            EditColors;
          miMisc :
            begin
              InitMisc;
              if DoEdit(MiscES) then
                CloneData(False)
              else
                RestoreMisc;
              MiscES.Done;
            end;
          miSave : SaveConfiguration;
          miQuit :
            if Modified then begin
              if YesNo('Ignore changes and quit', 'N', Esc) then
                Cmd := ccQuit
              else
                Cmd := ccNone;
            end
            else
              Cmd := ccQuit;
        end;
      end
      else
        if Modified then
          if YesNo('Ignore changes and quit', 'N', Esc) then
            Cmd := ccQuit
          else
            Cmd := ccNone;
    until Cmd in [ccError, ccQuit];
    {$IFDEF UseMouse}
    HideMouse;
    {$ENDIF}
  end;
  NormalScreen;
end;

end.

