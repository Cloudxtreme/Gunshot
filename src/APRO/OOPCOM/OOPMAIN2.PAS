{$S-,R-,V-,I-,B-,F+,O+,A-}
{*********************************************************}
{*                 OOPMAIN2.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}

unit OopMain2;
interface

uses
  dos,                            {DOS/BIOS stuff}
  opinline,                       {inline macros}
  oproot,                         {base objects, error codes, etc.}
  {$IFDEF Opro12}
  opconst,                        {const split out in OPRO 1.2}
  {$ENDIF}
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
  ApUart,                                                              {!!.01}
  {$ENDIF}
  ApMisc,
  ApTimer,
  OOAbsPcl,
  OOXModem,
  OOYModem,
  OOZModem,
  OOKermit,
  OOCom,
  OOModem,
  OOEmu,
  termwin,                        {APRO terminal windows}
  OopMain0,
  OopMain1;

procedure InitProtocolCommands;

procedure InitStatusCommands;

procedure DoDosShell;

procedure LoadConfig;

procedure ParseCommandLine;

procedure OopComInit;

procedure OopComDone;

procedure LoadConfigFile;

procedure StoreConfigFile;

procedure Terminate(S : String);
  {-Terminate the program with an error message. To be used while desktop is
    active.}

procedure OurHelpProc(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);
  {-our context sensitive help procedure}

procedure Abort(Msg : string);
  {-Display Msg and abort}

procedure About;
  {-Display program name, copyright info}

implementation

uses OopMain;

  procedure Abort(Msg : string);
    {-Display Msg and abort}
  begin
    WriteLn(Msg);
    Halt(1);
  end;


  procedure InitStatusCommands;
  begin
    if not StatusCommands.Init(@ProtoKeySet, ProtoKeyMax) then
        Abort(emInsufficientMemory);
    InitCommandProcessor(StatusCommands);
  end;

  procedure InitProtocolCommands;
  begin
    if not ProtocolCommands.Init(@ProtoKeySet, ProtoKeyMax) then
        Abort(emInsufficientMemory);
  end;

  procedure InitPhoneCommands;
    {-Initialize our command processor}
  begin
    if not PhoneCommands.Init(@PhoneKeySet, PhoneKeyMax) then
        Abort(emInsufficientMemory);
  end;


  procedure InitMenu;
    {-Initialize the main menu}
  const
    {Frame constants}
    Frame1 : FrameArray = 'ÚÀ¿ÙÄÄ³³';
  begin
    with MainMenu do begin
      {initialize the menu}
      if not InitCustom(1, 1, 80, 1, TpUiMenuColors,
                        wClear+wUserContents+wCoversOnDemand,
                        Horizontal) then
        Abort(emInsufficientMemory);
      mnOptionsOn(mnAlphaMatch+mnSelectOnMatch+mnAllowPending+mnArrowSelect+
                  mnAllHotSpots+mnUseItemForTopic);
      mnOptionsOff(mnPopOnSelect+mnSelectOnClick+mnAltMatch);
      AddItem(' ð ' ,         02, 0, AboutId);
      AddItem(' Files ', 9, 2, FilesID);
        AddFramedSubMenu(8, 3, 19, 6, Vertical, Frame1);
        AddShadow(shBR, shSeeThru);
        AddItem(' Browser ', 1, 2, BrowseWinID);
        AddItem(' Editor ', 2, 2, EditWinID);
        AddItem(' Dos Shell ', 3, 2, DosShellID);
        AddItem(' Quit ', 4, 2, QuitID);
        ItemsDone;
      AddItem(' Dialer ', 23, 2, DialerWinID);
      AddItem(' Terminal ', 38, 2, TermWinID);
      AddItem(' Status ', 56, 2, StatusWinID);
      AddItem(' Help ', 71, 2, HelpID);
        AddFramedSubMenu(61, 3, 79, 5, Vertical, Frame1);
        AddShadow(shBR, shSeeThru);
        AddItem(' Index of Topics ', 1, 2, HelpIndexID);
        AddItem(' Previous Topic ', 2, 2, PreviousTopicID);
        AddItem(' Help On Help ', 3, 2, HelpOnHelpID);
        ItemsDone;
      ItemsDone;
      {install error handler}
      SetErrorProc(TpUiErrorProc);
    end;

    {add special user exit commands}
    MenuCommands.SetSecondaryKeyPtr(@TpUiKeySet, TpUiKeyMax);
  end;

  {-------------- general ----------------}

  function InstantiateTermWin : Boolean;
  var
    Emu : AnsiEmulatorPtr;
    TerminalOptions : LongInt;
    P : AbstractPortPtr;
  begin
    InstantiateTermWin := False;
    TerminalOptions := DefTerminalWinOptions or twShowOutgoing or twMapMono;
    if DefDuplexType = dupHalf then
      SetLongFlag(TerminalOptions, twShowOutgoing)
    else
      ClearLongFlag(TerminalOptions, twShowOutgoing);
    with TermiWin do begin
      if not Init(DefTermWinX1, DefTermWinY1, DefTermWinX2, DefTermWinY2,
                  ScrollBackRows, DefComPort, DefBaud,
                  TerminalOptions, DefCaptureName,
                  CaptureBufferSize, BackgroundBufferBreak) then
        Exit;

      (* !!.01 removed *)
      if DefUseAnsi then begin
        SetLongFlag(twOptions, twUsingAnsi);
(*
        Emu := New(AnsiEmulatorPtr, Init(DefEmuQueue));
        if Emu <> Nil then
          SetTerminalWinEmulator(Emu);
*)
      end
      else
        ClearLongFlag(twOptions, twUsingAnsi);
 (*     *)

      {set line parameters}
      P := GetTerminalWinPort;
      with P^ do begin
        SetLine(DefBaud, DefParity,
                DefDataBits, DefStopBits);
        SetAbortFunc(KeyboardAbort);
        SetErrorProc(UartErrorProc);
        {$IFDEF UseUart}
        if ClassifyUart(GetBaseAddr, False) = U16550A then
          SetFifoBuffering(GetBaseAddr, True, 4);
        {$ENDIF}
      end;
      {set hardware flow control options}
      SetHardwareFlowControl(DefHWHOptions);

      octwModem^.SetDialPrefix(DefDialPrefix);

      {set virtual screen's page height to 23}
      SetPageSize(25);                                                 {!!.02}
      {add headers, hot spots, etc.}
      CustomizeWindowWithColors(TermiWin, ' Terminal ', 12, TpUiColors);
      if ClassifyError(GetLastError) = etFatal then begin
        Done;
        Exit;
      end;
      if FeedFromFile then
        UseFile(FeederFileName);
    end;
    InstantiateTermWin := True;
  end;

  procedure DoneTermWin;
  begin
    with TermiWin do begin
      if IsActive and (not IsCurrent) then
        EraseHidden;
      Done;
    end;
  end;

  procedure InitTerminalCommands;

  begin
    with TerminalCommands do begin
      {customize the TerminalCommands command processor to our tastes}
      AddCommand(DialerCommand, 1, $3D00, 0);  {F3}
      AddCommand(CaptureCommand, 1, $3E00, 0); {F4}
      AddCommand(HangupCommand, 1, $4100, 0);  {F7}
      AddCommand(ccNone, 1, Ord(^[), 0);
      cpOptionsOn(cpCtrlsAreChars);
    end;
  end;

  procedure InitializeHelp;
  var
    FullName : String;

  begin
    if not ExistOnPath(HelpFileName, FullName) then
      FullName := HelpFileName;
    {instantiate help window}
    if not HelpWin.Init(HelpX1, HelpY1, HelpX2, HelpY2,
                        FullName, PickHorizontal) then begin
      if InitStatus = ecFileNotFound then
        TempMessage('Help file: ' + HelpFileName + ' not found', 3000)
      else
        InsufficientMemory;
      Exit;
    end;
    InitCommandProcessor(HelpCommands);
    with HelpWin do begin
      SetPosLimits(1, 2, ScreenWidth, ScreenHeight - 1);
      {install default error handler}

      {make the window explode}
      EnableExplosions(8);
      AddTopicHeader(1, 60, heTC);
      wFrame.AddHeader(' Help Topic Index ', heTC);
      wFrame.AddScrollBar(frRR, 0, MaxLongInt, TpUiColors);
      wFrame.AddShadow(shBR, shSeeThru);
      hwFrame.AddScrollBar(frRR, 0, MaxLongInt, TpUiColors);
      hwFrame.AddScrollBar(frBB, 0, MaxLongInt, TpUiColors);
      hwFrame.AddShadow(shBR, shSeeThru);

      if ClassifyError(GetLastError) = etFatal then begin
        InsufficientMemory;
        Done;
      end
      else
        HelpOK := True;
    end;
  end;

  procedure FixupHelpIndex(P : Pointer; var ID : Word);
  begin
    if P = @MainMenu then
      case ID of
        AboutID : ID := hidAbout;
        DosShellID : ID := hidDosShell;
        QuitID : ID := hidQuit;
        HelpID : ID := hidHelp;
        HelpIndexID : ID := hidIndex;
        PreviousTopicID : ID := hidPrevious;
        HelpOnHelpID : ID := hidHelponHelp;
      end;
  end;

  {.$DEFINE HelpDebug}

  procedure OurHelpProc(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);

  const
    HelpMsg = '<Tab> next xref   <AltF1> previous topic   <F1> topic index   <ESC> exit help';
    IndexMsg = '<Enter> select topic     <ESC> exit help';

  var
    Finished, Failed, ShowIndex : Boolean;
    Cmd, XY, SL : Word;
    P : Pointer;
    {$IFDEF HelpDebug}
    W : StackWindow;
    {$ENDIF}

  begin
    {$IFDEF HelpDebug}
    if not W.Init(HelpX1, HelpY1, HelpX2, HelpY2) then
      Exit;
    with W do begin
      Draw;
      wFastText('Unitcode = ' + Long2Str(UnitCode) +
                  '  IdPtr = ' + HexPtr(IdPtr) +
                  '  HelpIndex = ' + Long2Str(HelpIndex), 1, 1);
      if ReadKey = #0 then if ReadKey = #0 then ;
      Done;
    end;
    {$ELSE}
    if not HelpOK then begin
      TempMessage('Help file not found', 1000);
      Exit;
    end;
    if not SaveStatusLine(P, XY, SL) then
      Exit;
    FixupHelpIndex(IdPtr, HelpIndex);
    Failed := False;
    Finished := False;
    ShowIndex := HelpIndex = 0;
    with HelpWin do begin
      repeat
        if ShowIndex then begin
          SetTopic(0);
          Message(IndexMsg, True);
        end
        else begin
          SetTopic(HelpIndex);
          Message(HelpMsg, True);
        end;
        Process;
        Cmd := GetLastCommand;
        if (cwGetLastError = 0) then begin
          case Cmd of
            ccSelect :
              begin
                if not InHelpMode then begin
                  HelpIndex := GetTopicChoice;
                  ShowIndex := False;
                end;
              end;
            MoveWindowCmd,
            ResizeWindowCmd,
            ZoomWindowCmd :
              begin
                case Cmd of
                  MoveWindowCmd :
                    if not IsZoomed then
                      if not KeyboardMove(HelpWin) then ;
                  ResizeWindowCmd :
                    if not IsZoomed then
                      if not KeyboardResize(HelpWin) then ;
                  ZoomWindowCmd :
                    if not ToggleZoom(HelpWin) then ;
                end;
                HelpIndex := CurrentTopic;
                ShowIndex := HelpIndex = 0;
              end;
            ExitProgramCmd,
            ccQuit :
              Finished := True;
          end;
        end
        else
          Failed := True;
      until Finished or Failed;
      Erase;
    end;
    RestoreStatusLine(P, XY, SL);
    {$ENDIF}
  end;

  function InitHelp(X1, Y1, X2, Y2 : Byte; Msg : String) : Boolean;
    {-Initialize the help window}
  begin
    InitHelp := True;
  end;

  procedure About;
    {-Display program name, copyright info}
  const                                                                {!!.01}
    AboutWinOpts = wClear+wSaveContents+wBordered+wAllMouseEvents;     {!!.01}
  var
    W : CommandWindow;
    I : Word;

  begin
    if not W.InitCustom(18, 5, 62, 19,                                 {!!.01}
                        DefaultColorSet,                               {!!.01}
                        AboutWinOpts,                                  {!!.01}
                        BrowseCommands, 0) then begin                  {!!.01}
      InsufficientMemory;
      Exit;
    end;
    {W.wOptionsOff(wResizeable);}                                      {!!.01}
    CustomizeWindowSimple(W, '', 0);
    W.SetCursor(cuHidden);
    W.wFrame.AddHeader(' About ', heTC);
    W.Draw;
    W.wFastCenter(ProgName, 2, TextAttr);
    W.wFastCenter('Created with Object Professional', 3, TextAttr);
    W.wFastCenter('and Async Professional', 4, TextAttr);
    W.wFastCenter(Copyright, 5, TextAttr);

    W.wFastCenter('P.O. Box 49009', 7, TextAttr);
    W.wFastCenter('Colorado Springs, Co. 80949-9009', 8, TextAttr);
    W.wFastCenter('Tech support: 719-260-6641', 10, TextAttr);

    W.wFastCenter('Order line: 800-333-4160', 11, TextAttr);
    W.wFastCenter('Press any key...', 14, TextAttr);
    repeat
      I := BrowseCommands.cpGetKey;
      if I = $3B00 then
        OurHelpProc(0, @MainMenu, hidAbout);
    until I <> $3B00;
    W.Done;
  end;

  procedure InitializeDesktop;
    {-Initialize the desktop window manager}
  begin
    with Desk do begin
      Init(3, 4, ScreenWidth-3, ScreenHeight-3, 7);

      {Window 1: Phone book}
      InitPhoneCommands;
      if not AddWindow(PhoneWin, InitPhone, ProcessPhone, ClosePhone,
                       OkToClosePhone, PhoneCommands) then
        Abort(emInsufficientMemory);
      {Window 2: Terminal Window}
      InitTerminalCommands;
      if not InstantiateTermWin then begin
        WriteLn;
        case InitStatus  of
          ecBadPortNumber :
            WriteLn(ComNameString(DefComPort),
                    ' does not exist on this machine.');
          ecOutOfMemory :
            WriteLn(emInsufficientMemory);
          else
            WriteLn('Failed to initialize Terminal window. InitStatus = ',
                    InitStatus);
        end;
        Halt;
      end;
      if not AddWindow(TermiWin, InitTerm, ProcessTerm, CloseTerm,
                       OKToCloseTerm, TerminalCommands) then
        Abort(emInsufficientMemory);

      {Window 3: File Browser}
      if not AddWindow(BrowseWin, InitBrowse, ProcessBrowse, CloseBrowse,
                       OkToCloseBrowse, BrowseCommands) then
        Abort(emInsufficientMemory);

      {Window 4: Editor}
      if not AddWindow(EditWin, InitEditor, ProcessEditor, CloseEditor,
                       OkToCloseEditor, EditorCommands) then
        Abort(emInsufficientMemory);

      InitProtocolCommands;

      {Window 5: Status Window}
      InitStatusCommands;
      if not AddWindow(ComStatusWin, InitComStatus, ProcessComStatus,
                       CloseComStatus,
                       OkToCloseComStatus, StatusCommands) then
        Abort(emInsufficientMemory);

      BackgroundHook := TermBackgroundHook;

      {$IFDEF UseMouse}
      if MouseInstalled and DefMouseSupport then begin
        EditCommands.cpOptionsOn(cpEnableMouse);
        TerminalCommands.cpOptionsOn(cpEnableMouse);
        PickCommands.cpOptionsOn(cpEnableMouse);
        MenuCommands.cpOptionsOn(cpEnableMouse);
        BrowseCommands.cpOptionsOn(cpEnableMouse);
        EditorCommands.cpOptionsOn(cpEnableMouse);
        EntryCommands.cpOptionsOn(cpEnableMouse);
        HelpCommands.cpOptioNsOn(cpEnableMouse);
        ProtocolCommands.cpOptionsOn(cpEnableMouse);
        PhoneCommands.cpOptionsOn(cpEnableMouse);
        StatusCommands.cpOptionsOn(cpEnableMouse);
      end;
      {$ENDIF}

      {save original GetKeyProc and KeyPressedProc}
      OldGetKeyProc := TerminalCommands.cpGetKeyProc;
      OldKeyPressed := TerminalCommands.cpKeyPressedProc;

      {install GetKey routine for all command processors}
      TerminalCommands.SetGetKeyProc(TermGetKeyWord);
      PickCommands.SetGetKeyProc(TermGetKeyWord);
      MenuCommands.SetGetKeyProc(TermGetKeyWord);
      BrowseCommands.SetGetKeyProc(TermGetKeyWord);
      EditorCommands.SetGetKeyProc(TermGetKeyWord);
      EditCommands.SetGetKeyProc(TermGetKeyWord);
      PhoneCommands.SetGetKeyProc(TermGetKeyWord);
      EntryCommands.SetGetKeyProc(TermGetKeyWord);
      HelpCommands.SetGetKeyProc(TermGetKeyWord);
      ProtocolCommands.SetGetKeyProc(TermGetKeyWord);
      PhoneCommands.SetGetKeyProc(TermGetKeyWord);
      StatusCommands.SetGetKeyProc(TermGetKeyWord);

      {install help routine for all command processors}

      MenuCommands.SetHelpProc(OurHelpProc);
      BrowseCommands.SetHelpProc(OurHelpProc);
      PickCommands.SetHelpProc(OurHelpProc);
      EditCommands.SetHelpProc(OurHelpProc);
      EditorCommands.SetHelpProc(OurHelpProc);
      PhoneCommands.SetHelpProc(OurHelpProc);
      TerminalCommands.SetHelpProc(OurHelpProc);
      EntryCommands.SetHelpProc(OurHelpProc);
      ProtocolCommands.SetHelpProc(OurHelpProc);
      StatusCommands.SetHelpProc(OurHelpProc);
    end;
  end;

  procedure Initialize;
  var
    LibFound : Boolean;
  begin
    uiErrorMessage := oopComErrorMessage;
    SystemIsPs2 := IsPs2;

    {initialize the main menu}
    InitMenu;

    {initialize the help system}
    InitializeHelp;

    {initialize pick list array of modems - must be done before
     InstatiateTermWin is called}
    if InitializeModems(LibFound) then begin
      if not LibFound then begin
        {display error message}
        WriteLn(ModemLibName, ' not found.');
        WriteLn('Press Esc to abort, or any other key to continue with defaults');
        if ReadKey = ^[ then
          Halt(1);
      end;
    end
    else
      Abort('Unable to create list of modems');

    {initialize the desktop}
    InitializeDesktop;
  end;

  procedure DoDosShell;
  var
    P : Pointer;
    MSP : MouseStatePtr;
    WC : WindowCoordinates;
    ErrorCode : Integer;
    XY, SL : Word;
    SaveTextAttr : Byte;
  begin
    SaveMouseState(MSP, True);
    HideMouse;
    InitializeMouse;

    if not SaveWindow(1, 1, ScreenWidth, ScreenHeight, True, P) then begin
      InsufficientMemory;
      Exit;
    end;
    GetCursorState(XY, SL);
    {$IFDEF UseDrag}
    RemoveISRs;
    {$ENDIF}
    StoreWindowCoordinates(WC);
    Window(1, 1, ScreenWidth, ScreenHeight);
    SaveTextAttr := TextAttr;
    TextAttr := $07;
    ClrScr;
    NormalCursor;
    ErrorCode := ExecDos('', True, NoExecDosProc);

    InitializeMouse;
    EnableEventHandling;
    {$IFDEF UseDrag}
    InstallISRs;
    {$ENDIF}
    RestoreWindow(1, 1, ScreenWidth, ScreenHeight, True, P);
    RestoreMouseState(MSP, True);
    RestoreCursorState(XY, SL);
    RestoreWindowCoordinates(WC);
    TextAttr := SaveTextAttr;
    if ErrorCode <> 0 then
      TempMessage('Error ' + Long2Str(ErrorCode) +
                  'Unable to shell to DOS', 2000);
  end;

  procedure CloneColors(ToOOUI : Boolean);
  var
    Size : Word;

  begin
    Size := Ofs(OOUI.TpUiCfgEnd) - Ofs(OOUI.TpUiColors);
    if ToOOUI then
      Move(OOPMAIN0.TpUiColors, OOUI.TpUiColors, Size)
    else
      Move(OOUI.TpUiColors, OOPMAIN0.TpUiColors, Size);
  end;

  procedure LoadConfig;
    procedure PromptUser;
    begin
      WriteLn('To create a configuration file, run install program ',
              InstallProgName);
      WriteLn('Press Esc to abort, or any other key to continue with defaults');
      if ReadKey = ^[ then
        Halt(1);
    end;

  var
    ErrorCode : Word;
    FullName : String;
  begin
    WriteLn('Loading OOPCOM configuration file...');
    if not ExistOnPath(ConfigFileName, FullName) then
      FullName := ConfigFileName;
    ErrorCode := LoadConfiguration(FullName, OopComID,
                                   @OopComID, SizeOfConfig);
    if ErrorCode = 0 then
      CloneColors(True)
    else begin
      WriteLn('Error reading: ', FullName);
      case ErrorCode of
        1, $FFFF : WriteLn('File incorrect format');
        2 : WriteLn('Configuration file not found');
        else begin
          WriteLn('Error reading file');
          Halt(1);
        end;
      end;
      PromptUser;
    end;
  end;

  procedure ParseCommandLine;
  var
    I : Byte;
    Param : String;
  begin
    for I := 1 to ParamCount do begin
      Param := ParamStr(I);
      if Param[1] in ['/', '-'] then
        case UpCase(Param[2]) of
          'F' :
            begin
              FeedFromFile := True;
              FeederFileName := Copy(Param, 3, 255);
            end;
          'M' : OpMouse.MouseInstalled := False;
          'C' : ConfigFileName := Copy(Param, 3, 255);
        end;
    end;
  end;

  var
    SaveXY : Word;
    SaveSL : Word;

  procedure OopComInit;
  begin
    ParseCommandLine;
    LoadConfig;
    DefColorChoice := DefColorMap;
    DefaultColorSet := TpUiColors;
    DirHelpIndex := hidDirList;
    with TpUiColors do
      TextAttr := ColorMono(TextColor, TextMono);
    Initialize;
    {$IFDEF UseMouse}
    EnableEventHandling;
    {$ENDIF}
    GetCursorState(SaveXY, SaveSL);
    ClearWholeScreen;
    {$IFDEF UseMouse}
    if UseSoftMouseCursor then
      with TpUiColors do
        SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+$04);
    ShowMouse;
    {$ENDIF}
    MainMenu.Draw;
    MainMenu.wNumber := 200;
    wStack.OptimizeTiled(True);
  end;

  procedure OopComDone;
  begin
    DoneTermWin;
    HelpWin.Done;

    {$IFDEF UseMouse}
    HideMouse;
    {$ENDIF}
    RestoreCursorState(SaveXY, SaveSL);
    TextAttr := 7;
    TextChar := ' ';
    Window(1, 1, ScreenWidth, ScreenHeight);
    ClrScr;
  end;

  procedure Terminate(S : String);
  begin
    OopComDone;
    WriteLn(S);
    Halt(1);
  end;

  procedure LoadConfigFile;
  var
    ErrorCode : Word;
    FileName, Msg : String;
  begin
    FileName := '';
    if not GetFile(0, 'Config file name: ', True, True, False, False,
                   65, 'CFG', FileName) then
      Exit;
    ErrorCode := LoadConfiguration(FileName, OopComID,
                                   @OopComID, SizeOfConfig);
    case ErrorCode of
      0 :
        begin
          Msg := 'Configuation loaded from ' + FileName;
          CloneColors(False);
        end;
      1, $FFFF :
        Msg := 'File is incorrect format';
      2 :
        Msg := FileName + ' not found';
      else
        Msg := 'Unknown error reading file: ' + Long2Str(ErrorCode);
    end;
    if ErrorCode = 0 then begin
      if TermiWin.IsActive then begin
        TermiWin.Select;
        TermiWin.Erase;
      end;
      TermiWin.Done;
      if InstantiateTermWin then
        TempMessage(Msg, TempMessageDelay)
      else begin
        ErrorMessage('Fatal error attempting to instantiate TerminalWindow',
                     True);
        Halt;
      end;
    end
    else
      ErrorMessage(Msg, True);
  end;

  procedure StoreConfigFile;
  var
    ErrorCode : Word;
    FileName, Msg : String;
  begin
    FileName := '';
    if not GetFile(0, 'Config file name: ', True, True, True, False,
                   65, 'CFG', FileName) then
      Exit;
    ErrorCode := StoreConfiguration(FileName, @OopComId, SizeOfConfig);
    case ErrorCode of
      0 :
        Msg := 'Configuration stored to ' + FileName;
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

end.
