{$S-,R-,V-,I-,B-,F+,O+,A-}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}

{*********************************************************}
{*                  OOPMAIN.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OopMain;
interface

uses
  dos,                            {DOS/BIOS stuff}
  opinline,                       {inline macros}
  oproot,                         {base objects, error codes, etc.}
  opcmd,                          {command processing}
  opcrt,                          {low-level screen handling}
  {$IFDEF UseMouse}
  opmouse,                        {mouse handling}
  {$ENDIF}
  opstring,                       {string handling}
  opdos,                          {misc. DOS/BIOS routines}
  opframe,                        {frames, shadows, etc.}
  opwindow,                       {window management}
  opbrowse,                       {file browser}
  opmemo,                         {memo editor}
  opeditor,                       {text editor}
  opabsfld,                       {abstract field, picture mask stuff}
  opfield,                        {field definitions}
  opedit,                         {line editor}
  opselect,                       {selectors}
  opentry,                        {entry screens}
  oppick,                         {pick lists}
  opdir,                          {directory lists}
  opmenu,                         {menus}
  ophelp,
  ooui,                           {object oriented user interface}
  ApPort,
  {$IFDEF UseUart}                                                     {!!.01}
  ApUart,
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseFossil}                                                   {!!.01}
  ApFossil,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseDigi14}                                                   {!!.01}
  ApDigi14,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  {$IFDEF UseInt14}                                                    {!!.01}
  ApInt14,                                                             {!!.01}
  {$ENDIF}                                                             {!!.01}
  ApMisc,
  ApTimer,
  OOCom,
  OOModem,
  OOAbsPcl,
  OOAscii,
  OOXModem,
  OOYModem,
  OOZModem,
  OOKermit,
  OOBPlus,
  OOEmu,
  TermWin,                        {APRO terminal windows}
  OopMain0,
  OOPMain1;

type
  PhonePickList =
    object(PickList)
      constructor Init(X1, Y1, X2, Y2 : Byte;
                       ItemWidth : Byte;
                       NumItems : Word;
                       StringProc : pkStringProc;
                       Orientation : pkGenlProc;
                       CommandHandler : pkGenlProc);
        {-Initialize a phone pick list}
      procedure UpdateContents; virtual;
    end;
  TransferModeType = (Transmit, Receive);
  OCTWindowPtr = ^OopComTerminalWindow;
  ProtocolWindowPtr = ^ProtocolWindow;
  ProtocolWindow =
    object(CommandWindow)
      pwOptions         : Word;
      pwPromptAttr      : Byte;
      pwFieldAttr       : Byte;
      pwKind            : Byte;
      pwTransferMode    : TransferModeType;
      pwFileMask        : PathStr;
      pwProtocol        : AbstractProtocolPtr;
      pwTerminal        : OCTWindowPtr;
      constructor Init(X1, Y1, X2, Y2 : Byte;
                       TransferMode : TransferModeType;
                       KindOfProtocol : Byte;
                       FileMask : PathStr;
                       TermP : OCTWindowPtr; Options : Word);
      destructor Done; Virtual;
      procedure ProcessSelf; Virtual;
      procedure Upload;
      procedure Download;
      procedure UploadBPlus;
      procedure DownloadBPlus;
      procedure InstantiateProtocol;
      procedure DisposeProto;
    end;
  OopComTerminalWindow =
    object(CaptureTerminalWindow)
      UsingFile    : Boolean;
      FileName     : String;
      InFile       : File;
      octwBuffer   : String;
      octwBreak    : Byte;
      octwHWHState : Word;
      octwSWFState : Boolean;
      octwBGState  : Boolean;
      octwProtocol : ProtocolWindowPtr;
      octwLocalMenu: Menu;
      octwModem    : AbstractModemPtr;
      octwBPlusStarted : Boolean;
      constructor Init(X1, Y1, X2, Y2 : Byte;
                       ScrollBackRows : Word;
                       ComPort : ComNameType;
                       Baud : LongInt;
                       TerminalOptions : LongInt;
                       DefCaptureFileName : String;
                       CaptureBufferSize : Word;
                       BackgroundBufBreak : Byte);
        {-Create a TerminalWindow}
      constructor InitCustom(X1, Y1, X2, Y2 : Byte;
                             ScrollBackRows : Word;
                             var Colors : ColorSet;
                             Port : AbstractPortPtr;
                             Emu   : TerminalEmulatorPtr;
                             WindowOptions : LongInt;
                             TerminalOptions : LongInt;
                             DefCaptureFileName : String;
                             CaptureBufferSize : Word;
                             BackgroundBufBreak : Byte);
        {-Create a TerminalWindow window with custom options}
      destructor Done; virtual;                                        {!!.01}
      procedure BackgroundLogic;
        {-handle incoming characters while TerminalWindow is not current,
          or inactive}
      function ProcessBuffer : Boolean;
      function GetIncomingChar(var Key : Char) : Boolean; Virtual;
      procedure GetNextCommand; virtual;
      procedure SetHardwareFlowControl(Options : Word);
      procedure SetSoftwareFlowControl(On : Boolean);
      procedure GetPortBufferSizes(var InS, OutS : Word);
      procedure RegisterProtocol(PW : ProtocolWindowPtr);
      procedure DeregisterProtocol;
      function ProtocolActive : Boolean;
      procedure LaunchProtocol(UpOrDown : TransferModeType);
      function GetProtocolInfo(Mode : TransferModeType;
                               var Kind : Byte;
                               var Mask : PathStr;
                               var Options : Word) : Boolean;
      procedure EnableOptions(var PhoneRecord : PhonePickRec);
      function ChangePorts(ComName : ComNameType) : Boolean;
      function GetBaud : LongInt;
      procedure SetBackgroundState(On : Boolean);
      procedure UseFile(Name : String); {*************}
      function StartBPlus(DrawIt : Boolean) : Boolean;
    end;

  ComStatusWindow =
    object(CommandWindow)
      cswTW : octwindowPtr;
      cswPromptAttr : Byte;
      cswFieldAttr  : Byte;
      constructor Init(X1, Y1, X2, Y2 : Byte;
                       Msg : String;
                       TW : octwindowPtr);
      procedure ProcessSelf; Virtual;
      procedure UpdateContents; Virtual;
      procedure cswUpdateContents;
    end;
  OopComDeskTop =
    object(DeskTop)
      ocdtWinId   : Byte;
      ocdtCmd     : Word;
      ocdtHelpWin : CommandWindowPtr;
      procedure DoHelp(CmdWinPtr : CommandWindowPtr); Virtual;
      function ActivateWindow(Which : Byte; Msg : string) : Boolean; Virtual;
    end;

  {this type switches a port to 8 data bits, no parity, 1 stop bit for
   file transfers}
  SwitchToBinary =
    object
      Port     : AbstractPortPtr;
      Parity   : ParityType;
      DataBits : DataBitType;
      StopBits : StopBitType;
      Baud     : LongInt;
      constructor Init(AP : AbstractPortPtr);
        {-Save current settings and switch to 81N}
      destructor Done;
        {-Restore original settings}
    end;
var
  Desk            : OopComDeskTop;   {desktop window manager}
  PhoneWin        : PhonePickList;   {phonebook}
  TermiWin        : OopComTerminalWindow; {terminal window}
  ProtocolWin     : ProtocolWindow;
  ComStatusWin    : ComStatusWindow;

procedure DoOopCom;
  {-Run program}

function InitBrowse(X1, Y1, X2, Y2 : Byte; Msg : string) : Boolean;
  {-Initialize the file browser window}

procedure ProcessBrowse(var Cmd : Word);
  {-Process the commands for the file browser window}

procedure CloseBrowse(EraseFirst : Boolean);
  {-Close the file browser window}

function OkToCloseBrowse : Boolean;
  {-Return True if OK to close the file browser window}

function InitEditor(X1, Y1, X2, Y2 : Byte; Msg : string) : Boolean;
  {-Initialize the text editor window}
function OkToCloseEditor : Boolean;
  {-Return True if OK to close the text editor window}

procedure ProcessEditor(var Cmd : Word);
  {-Process the commands for the text editor window}

procedure CloseEditor(EraseFirst : Boolean);
  {-Close the text editor window}

function InitPhone(X1, Y1, X2, Y2 : Byte; Msg : string) : Boolean;
  {-Initialize the phone book window}

procedure ProcessPhone(var Cmd : Word);
  {-Process the commands for the phone book window}

procedure ClosePhone(EraseFirst : Boolean);
  {-Close the phone book window}

function OkToClosePhone : Boolean;
  {-Return True if OK to close the phone book window}

function InitTerm(X1, Y1, X2, Y2 : Byte; Msg : String) : Boolean;
  {-Initialize the terminal window}

procedure ProcessTerm(var Cmd : Word);
  {-Process the commands for the terminal window}

procedure CloseTerm(EraseFirst : Boolean);
  {-Close the terminal window}

function OkToCloseTerm : Boolean;
  {-Return True if OK to close the terminal window}

function InitOptions(X1, Y1, X2, Y2 : Byte; Msg : String) : Boolean;
  {-Initialize the Options window}

procedure ProcessOptions(var Cmd : Word);
  {-Process the commands for the options window}

procedure CloseOptions(EraseFirst : Boolean);
  {-Close the options window}

function InitComStatus(X1, Y1, X2, Y2 : Byte; Msg : String) : Boolean;
  {-Initialize the ComStatus window}

procedure ProcessComStatus(var Cmd : Word);
  {-Process the commands for the ComStatus window}

procedure CloseComStatus(EraseFirst : Boolean);
  {-Close the ComStatus window}

function OkToCloseComStatus : Boolean;

procedure TermBackgroundHook;

function TermGetKeyWord : Word;

procedure DrawMainMenuStatusMsg;
  {-Draw the main menu's status line}

function KeyboardAbort : Boolean;
  {-Used by protocol upload/downloads to allow user to abort with
    ^C, ESC or right mouse button}

procedure UartErrorProc(P : Pointer; var StatusCode : Word);

function OopComErrorMessage(ErrorCode : Word) : String;

implementation

uses OopMain2;

  procedure ClearEntireWindow;
  var
    SaveAOC : Boolean;
  begin
    with TermiWin, twVScreen^ do begin
      {clear entire vscreen and home the cursor}
      Clear(svsTextAttr, svsTextChar);
      svsHome;
      SetView(1, 1);
    end;
  end;

  procedure FeederFile;
  const
    FeederFile : String = '';
  begin
    with TermiWin do begin
      UsingFile := False;
      Close(InFile);
      if IoResult <> 0 then ;
      if not GetFile(0, 'File: ', True, True, False, True,
                     60, '', FeederFile) then
        Exit;
      ClearEntireWindow;
      UseFile(FeederFile);
    end;
  end;


  {$I OOPMAIN.PA1}
  {$I OOPMAIN.PA2}
  {$I OOPMAIN.PA3}

  function KeyboardAbort : Boolean;
    {-Used by protocol upload/downloads to allow user to abort with
      ^C or ESC}
  var
    KW : Word;
  begin
    KeyboardAbort := False;
    if OldKeyPressed then begin
      KW := OldGetKeyProc;
      {$IFDEF UseMouse}
      if KW = MouseRt then
        KeyboardAbort := True
      else
      {$ENDIF}
        case Char(KW) of
          ^[, ^C : KeyboardAbort := True;
        end;
    end;
  end;

  function OopComErrorMessage(ErrorCode : Word) : String;
  begin
    OopComErrorMessage := 'Async Error: '+ StatusStr(ErrorCode);
  end;

  procedure UartErrorProc(P : Pointer; var StatusCode : Word);
  const
    InErrorProc : Boolean = False;
  begin
    if InErrorProc then
      Exit;

    {Ignore ecNotSupported errors}                                     {!!.01}
    if AsyncStatus mod 10000 = ecNotSupported then begin               {!!.01}
      AsyncStatus := ecOk;                                             {!!.01}
      Exit;                                                            {!!.01}
    end;                                                               {!!.01}

    InErrorProc := True;
    TermiWin.SetBackgroundState(False);
    with AbstractPortPtr(P)^ do begin
      {Do nothing if a protocol is in progress}
      if ProtocolInProgress then begin
        InErrorProc := False;
        TermiWin.SetBackgroundState(True);
        Exit;
      end;
      StatusCode := StatusCode mod 10000;
      if StatusCode <> 0 then begin
        {Build an error message}
        ErrorMessage(OopComErrorMessage(StatusCode), True);
        StatusCode := 0;
      end;
    end;
    InErrorProc := False;
    TermiWin.SetBackgroundState(True);
  end;

  {--------- routines for file browser -----------}
const
  BrowseMenuChoice   : Word = 1;
  ValidBrowseOptions : CharSet = [brBackward, brNoCase, brGlobal];

  procedure BrowseMenuCustom(var Name : String; Key : LongInt;
                             Selected, Highlighted : Boolean;
                             WPtr : RawWindowPtr);
    {-String customization routine for BrowseMenu}
  const
    HexAsciiSt : array[Boolean] of array[1..5] of Char = ('Ascii', 'Hex  ');
    ShowStripSt : array[Boolean] of array[1..5] of Char = ('Show ', 'Strip');

    procedure MergeYesNo(YN : Boolean; Col : Byte);
    begin
      Move(YesNoSt[YN], Name[Col], 3);
    end;

  begin
    with BrowseWin do
      case Word(Key) of
        hidBLHidden  : MergeYesNo(not brBlockOn, 09);
        hidBLExpand  : MergeYesNo(brOptionsAreOn(brTabExpand), 14);
        hidBLHighBits: Move(ShowStripSt[brOptionsAreOn(brStripHigh)], Name[14], 5);
        hidBLMode    : Move(HexAsciiSt[brOptionsAreOn(brHexMode)], Name[14], 5);
        hidBLAgain   : MergeSearchSt(brSearchSt, Name, 10, 10);
        hidBLFindOpts: MergeOptionsSt(brOptionSt, ValidBrowseOptions, Name, 10);
        hidBLGlobal  : MergeYesNo(SearchOptionIsSet(brOptionSt, brGlobal), 14);
        hidBLIgnore  : MergeYesNo(SearchOptionIsSet(brOptionSt, brNoCase), 14);
        hidBLReverse : MergeYesNo(SearchOptionIsSet(brOptionSt, brBackward), 14);
      end;
  end;

  function InitBrowseMenu : Boolean;
    {-Initialize the directory window's local menu}
  begin
    InitBrowseMenu := False;

    with BrowseMenu do begin
      {initialize the menu}
      if not InitCustom(2, 2, 15, 10, TpUiMenuColors, DefWindowOptions, Vertical) then
        Exit;
      AddShadow(shBR, shSeeThru);

      {add menu items}
      AddItem('Close',            01, 1, hidLocalClose);
      AddItem('Move',             02, 1, hidLocalMove);
      AddItem('Resize',           03, 1, hidLocalResize);
      AddItem('Zoom',             04, 1, hidLocalZoom);
      AddSeparator('Ã', 'Ä', '´', 05);
      AddItem('Block',            06, 1, hidBLBlock);
        AddFramedSubMenu(4, 9, 16, 13, Vertical, DefWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddItem('Begin block',    01, 1, hidBLBlockBegin);
        AddItem('End block',      02, 1, hidBLBlockEnd);
        AddItem('Hidden Yes',     03, 1, hidBLHidden);
        AddItem('Print',          04, 1, hidBLPrint);
        AddItem('Write',          05, 1, hidBLWrite);
        ItemsDone;
      AddItem('Options',          07, 1, hidBLOptions);
        AddFramedSubMenu(4, 10, 22, 12, Vertical, DefWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddItem('Expand tabs Yes',   01, 1, hidBLExpand);
        AddItem('High bits   Strip', 02, 1, hidBLHighBits);
        AddItem('Mode        Ascii', 03, 1, hidBLMode);
        ItemsDone;
      AddItem('Search',           08, 1, hidBLSearch);
        AddFramedSubMenu(4, 11, 19, 13, Vertical, DefWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddItem('Again   [1234567...]', 01, 1, hidBLAgain);
        AddItem('Find',                 02, 1, hidBLFind);
        AddItem('Options [UBG]',        03, 1, hidBLFindOpts);
          AddFramedSubMenu(14, 14, 30, 16, Vertical, DefWindowFrame);
          AddShadow(shBR, shSeeThru);
          AddItem('Global      Yes',    01, 1, hidBLGlobal);
          AddItem('Ignore case Yes',    02, 1, hidBLIgnore);
          AddItem('Reverse     Yes',    03, 1, hidBLReverse);
          ItemsDone;
        ItemsDone;
      AddItem('Text markers',     09, 1, hidBLMarkers);
        AddFramedSubMenu(4, 12, 9, 13, Vertical, DefWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddItem('Jump',           01, 1, hidBLJump);
        AddItem('Set',            02, 1, hidBLSet);
        ItemsDone;
      ItemsDone;
      mnOptionsOn(mnUseItemForTopic);

      {install error handler}
      SetErrorProc(TpUiErrorProc);

      {install string customization routine}
      SetCustomStringProc(BrowseMenuCustom);

      {move the window}
      MoveWindow(BrowseWin.wFrame.frXL, BrowseWin.wFrame.frYL);

      {check for errors}
      if ClassifyError(GetLastError) = etFatal then begin
        Done;
        Exit;
      end;

      {display the menu}
      DefaultPath(BrowseMenuChoice);
      Draw;

      {check for errors}
      if ClassifyError(GetLastError) = etFatal then
        Done
      else
        InitBrowseMenu := True;
    end;
  end;


  function GetBrowseMenuCmd : Byte;
    {-Get next menu choice; initialize and draw menu if necessary}
  begin
    {is the menu on the screen?}
    if (wStack.TopWindow <> @BrowseMenu) then
      {initialize and display it}
      if not InitBrowseMenu then begin
        InsufficientMemory;
        GetBrowseMenuCmd := ccError;
        Exit;
      end;

    with BrowseMenu do begin
      {get the next menu command}
      Process;
      BrowseMenuChoice := MenuChoice;
      GetBrowseMenuCmd := GetLastCommand;
    end;
  end;

  procedure EraseBrowseMenu;
    {-Erase BrowseMenu}
  begin
    BrowseMenu.Erase;
    BrowseMenu.Done;
  end;

  procedure BrowseWinStatusProc(BP : BrowserPtr);
    {-Display the status line for the file browser window}
  const
    StatusMsg =
      ' <F3> New file  <F9> Menu  <AltH> Hex/Ascii  <Esc> Close  ³ ';
  begin
    with BrowseWin do begin
      if brOptionsAreOn(brNewFile) then begin
        {modify the frame header that shows the filename}
        ChangeTitle(BrowseWin, BrowseTitle+JustFilename(CurrentFileName));

        {clear the new file flag}
        brOptionsOff(brNewFile);
      end;

      ShowStatusString(StatusMsg, 1, Length(StatusMsg));
      if brWorkingFlag <> 0 then
        ShowStatusString('Working...', 61, 20)
      else begin
        ShowStatusString('Line ', 61, 5);
        ShowStatusNumber(brCurLine, 66, 6);
        ShowStatusString('Col ', 72, 4);
        ShowStatusNumber(brColOfs+1, 76, 5);
      end;
    end;
  end;

  function InitBrowse(X1, Y1, X2, Y2 : Byte; Msg : string) : Boolean;
    {-Initialize the file browser window}
  const
    MaxLen = SizeOf(PathStr)-1;
    TitleSize = Length(BrowseTitle)+12;
  var
    FName : PathStr;
  begin
    InitBrowse := False;

    {get the name of the file to browse}
    if Msg <> '' then
      FName := Msg
    else begin
      FName := '';
      if not GetFile(0, 'File to browse: ', True, True, False, True,
                     MaxLen, BrowseDefExt, FName) then
        Exit;
    end;

    with BrowseWin do begin
      {initialize the browser}
      if not Init(X1, Y1, X2, Y2, LongInt(BrowsePages) * OnePage) then begin
        InsufficientMemory;
        Exit;
      end;

      {install default error handler}
      SetErrorProc(TpUiErrorProc);

      {try to open it}
      OpenFile(FName);
      if ClassifyError(GetLastError) = etFatal then begin
        Done;
        Exit;
      end;

      {initialize procedure pointers}
      SetEditProc(EditProc);
      SetGetFileProc(GetFile);
      SetStatusProc(BrowseWinStatusProc);

      {add headers, hot spots, etc.}
      CustomizeWindow(BrowseWin, BrowseTitle+JustFileName(FName), TitleSize);

      {customize colors}
      SetTextAttr(BrowseTextColor, BrowseTextMono);

      if ClassifyError(GetLastError) = etFatal then
        Done
      else
        InitBrowse := True;
    end;

  end;

  procedure ProcessBrowse(var Cmd : Word);
    {-Process the commands for the file browser window}
  label
    Reevaluate;
  var
    AllDone : Boolean;

    procedure DoBrowseCommand(Cmd : Word; OffScreen : Boolean);
      {-Execute the specified browser command. If OffScreen is True, switch to
        a virtual screen first.}
    var
      CmdList : array[1..2] of Byte;
    begin
      if OffScreen then begin
        BrowseWin.SetCursor(cuHidden);
        BrowseWin.ActivateWrite;
      end
      else
        EraseBrowseMenu;

      CmdList[1] := Cmd;
      CmdList[2] := ccUser55;
      BrowseWin.ProcessAutoPilot(CmdList, 2);

      StatusLocalMenu;
      if OffScreen then
        BrowseWin.DeactivateWrite;
    end;

    function ProcessLocalMenu(var Cmd : Word) : Boolean;
      {-Process local menu commands}
    var
      Stop : Boolean;
      MN : Byte;
      Ch : Char;
      P : Pointer;

      procedure UpdateMenu;
      begin
        BrowseMenu.Redraw;
      end;

    begin
      StatusLocalMenu;

      ProcessLocalMenu := True;
      Stop := False;
      with BrowseWin do
        repeat
          case GetBrowseMenuCmd of
            ccSelect :
              case BrowseMenuChoice of
                hidLocalClose..hidLocalZoom :
                  begin
                    case BrowseMenuChoice of
                      hidLocalClose  : Cmd := ccQuit;
                      hidLocalMove   : Cmd := MoveWindowCmd;
                      hidLocalResize : Cmd := ResizeWindowCmd;
                      hidLocalZoom   : Cmd := ZoomWindowCmd;
                    end;
                    ProcessLocalMenu := False;
                    Stop := True;
                  end;
                hidBLBlockBegin : DoBrowseCommand(ccBlkBegin, True);
                hidBLBlockEnd : DoBrowseCommand(ccBlkEnd, True);
                hidBLHidden   : DoBrowseCommand(ccBlkToggle, True);
                hidBLPrint    : DoBrowseCommand(ccBlkPrint, True);
                hidBLWrite    : DoBrowseCommand(ccBlkWrite, False);
                hidBLExpand   : DoBrowseCommand(ccTabExpand, True);
                hidBLHighBits : DoBrowseCommand(ccStripHigh, True);
                hidBLMode     : DoBrowseCommand(ccHexMode, True);
                hidBLFind     : DoBrowseCommand(ccSearch, False);
                hidBLAgain    : if Length(brSearchSt) <> 0 then
                       DoBrowseCommand(ccReSearch, False);
                hidBLSearch   : DoBrowseCommand(ccSearch, False);
                hidBLGlobal..hidBLReverse :
                  begin
                    case BrowseMenuChoice of
                      hidBLGlobal  : Ch := brGlobal;
                      hidBLIgnore  : Ch := brNoCase;
                      hidBLReverse : Ch := brBackward;
                    end;
                    ToggleSearchOption(brOptionSt, Ch,  ValidBrowseOptions);
                    UpdateMenu;
                  end;
                hidBLJump     : if GetMarkerNumber(True, MN) then
                       DoBrowseCommand(ccJmpMark0+MN, True);
                hidBLSet      : if GetMarkerNumber(False, MN) then
                       DoBrowseCommand(ccSetMark0+MN, True);
              end;
            {$IFDEF UseMouse}
            ccMouseSel :
              begin
                P := Desk.WindowClickedOn;
                if P = @BrowseWin then
                  Stop := True
                else if P <> nil then begin
                  Cmd := ccMouseSel;
                  ProcessLocalMenu := False;
                  Stop := True;
                end;
              end;
            {$ENDIF}
            MainMenuCmd :
              begin
                Cmd := MainMenuCmd;
                ProcessLocalMenu := False;
                Stop := True;
              end;
            LocalMenuCmd,
            ccQuit,
            ccError :
              Stop := True;
          end;
        until Stop or (cwGetLastError <> 0);
      EraseBrowseMenu;
    end;

  begin
    AllDone := False;
    repeat
      with BrowseWin do begin
        SetHelpIndex(BrowseWinID);
        {browse}
        Process;
        {get the command}
        Cmd := GetLastCommand;
      end;
Reevaluate:
      {process exit commands}
      if not Desk.ProcessExitCommands(Cmd) then begin
        {process any exit commands that TPUI can't handle for us}
        case Cmd of
          LocalMenuCmd :
            if not ProcessLocalMenu(Cmd) then
              goto Reevaluate;
          NextWindowCmd..SelectWindow8,
          ExitProgramCmd,
          UnloadTsrCmd,
          MainMenuCmd,
          ccError,
          ccQuit :
            AllDone := True;
        end;
      end;
    until AllDone;
  end;

  procedure CloseBrowse(EraseFirst : Boolean);
    {-Close the file browser window}
  begin
    if EraseFirst then
      BrowseWin.Erase;
    BrowseWin.Done;
  end;

  function OkToCloseBrowse : Boolean;
    {-Return True if OK to close the file browser window}
  begin
    OkToCloseBrowse := True;
  end;

  {-------- main menu ------}
  function OkToCloseMain : Boolean;
  var
    Esc : Boolean;
  begin
    OkToCloseMain := YesNo('Do you really want to quit?', 'Y', Esc);
  end;

  procedure DrawMainMenuStatusMsg;
    {-Draw the main menu's status line}
  const
    StatusMsg =
      '<F5> Zoom  <F6> Next  <^F6> Prev  <AltM> Move  <AltR> Resize  <AltX> Exit';
  begin
    Message(StatusMsg, True);
  end;

  procedure DoOopCom;
  var
    Item        : LongInt;         {main menu item selection}
    NextWin     : Byte;            {next window to go to}

  begin
    OopComInit;
    {$IFDEF Tracing}
    InitTracing(5000);
    {$ENDIF}
    NextWin := 0;
    Desk.ocdtCmd := MainMenuCmd;
    repeat
      with MainMenu do
        if Desk.ocdtCmd <> MainMenuCmd then begin
          Select;
          Desk.ProcessCommands(Desk.ocdtCmd);
          case Desk.ocdtCmd of
            {$IFDEF UseMouse}
            SelectWindowCmd :
              begin
                Select;
                if SelectItemByPos(MouseKeyWordX+MouseXLo, MouseKeyWordY+MouseYLo) then {};
                Desk.ocdtCmd := MainMenuCmd;
              end;
            {$ENDIF}
            ccQuit, ExitProgramCmd :
              if OKToCloseMain then
                Desk.ocdtCmd := ExitProgramCmd
              else
                Desk.ocdtCmd := ProcessWindowCmd;
          end;
          EraseAllSubMenus(False, True);
        end
        else begin
          Select;
          DrawMainMenuStatusMsg;

          Process;
          EraseAllSubMenus(False, True);
          Item := MenuChoice;
          Desk.ocdtCmd := GetLastCommand;

          if (Desk.ocdtCmd = ccSelect) then
            case Item of
              DialerWinId..StatusWinID:
                begin
                  NextWin := Item;
                  Desk.ocdtCmd := ProcessWindowCmd;
                end;
              DosShellID :
                DoDosShell;
              QuitID :
                Desk.ocdtCmd := ExitProgramCmd;
              AboutID : About;
              HelpIndexID : OurHelpProc(0, Nil, 0);
              PreviousTopicID :
                OurHelpProc(0, Nil, HelpWin.CurrentTopic);
              HelpOnHelpID :
                OurHelpProc(0, Nil, hidHelpOnHelp);
          end;

          case Desk.ocdtCmd of
            ShowMemoryCmd :
              ShowAvailableMemory;
            ProcessWindowCmd :
              if NextWin <> 0 then
                if Desk.ActivateWindow(NextWin, '') then
                  NextWin := 0
                else
                  Desk.ocdtCmd := MainMenuCmd;
            SelectWindow1..SelectWindow8 :
              if Desk.ProcessExitCommands(Desk.ocdtCmd) then
                Desk.ocdtCmd := MainMenuCmd;
            PrevWindowCmd,
            NextWindowCmd :
              if Desk.dtActive <= 1 then
                Desk.ocdtCmd := MainMenuCmd;

            UnloadTsrCmd : FeederFile;
            ExitProgramCmd,
            ccQuit :
              if OKToCloseMain then
                Desk.ocdtCmd := ExitProgramCmd
              else
                Desk.ocdtCmd := ProcessWindowCmd;
            {$IFDEF UseMouse}
            ccMouseSel :
              begin
                Desk.SelectWindow(Desk.ocdtCmd);
                if Desk.ocdtCmd = ccNone then
                  Desk.ocdtCmd := MainMenuCmd;
              end;
            {$ENDIF}
            else
              Desk.ocdtCmd := MainMenuCmd;
          end;
        end;
    until (Desk.ocdtCmd = ExitProgramCmd) or (Desk.ocdtCmd = ccError);
    OopComDone;
    {$IFDEF Tracing}
    DumpTrace('OOPCOM.TRC');
    {$ENDIF}
  end;
end.

