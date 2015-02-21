{******************************************************}
{*                  TPFMAIN.PAS  2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}

{$V-,B-,R-,S-,F+,O-,A+,I-,X+}

unit TpfMain;

interface

uses
  Dos,
  OpInline,
  OpString,
  OpConst,
  OpRoot,
  OpDate,
  OpCrt,
  OpMouse,
  OpCmd,
  OpFrame,
  OpWindow,
  OpDrag,
  OpPick,
  OpDos,
  OpDir,
  ApUart,
  ApMisc,
  ApPort,
  OpCtrl,
  OpDialog,
  DlgStuff,
  ApTimer,
  OoCom,
  OoFaxCvt,
  OoAbsFax,
  TpfError,
  TpfData,
  OpColor,
  TpfColor,
  TpfDia,
  OpMenu,
  TpfMenu,
  TpfView,
  OoFax12,
  OoFaxCas,
  OoFaxPrn,
  OpKey;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

procedure TpFaxMainLoop;
procedure SendFaxQueuePrim;

implementation

var
  SavedMode : Word;
  MainMenu  : MenuPtr;

  procedure InitDragMouse(var DP : DragProcessor);
  begin
    DP.SetMouseCursor(DefaultCursorMask, DefaultCursorMask, DefaultCursorMask);
    DP.SetScreenMask(DefaultScreenMask);
  end;

  procedure DisplayCopyright;
  begin
    WriteLn('TPFAX - Advanced fax send system');
    WriteLn('Copyright (c) 1993 TurboPower Software');
    WriteLn;
  end;

  procedure ParseCommandLine;
  var
    I : Word;
    P : String;

    procedure DisplayParamHelp;
    begin
      WriteLn('Usage: TPFAX [options]');
      WriteLn('  /I <filespec>     Specify the name of the INI file to use');
      WriteLn('  /P <filespec>     Specify the name of the phonebook file to use');
      WriteLn('  /Q <filespec>     Specify the name of the outgoing queue file to use');
      WriteLn('  /S                Start sending the fax queue immediately');
      WriteLn('  /?                Display this help screen');
      WriteLn;
      WriteLn('Note that ''-'' can be used instead of ''/'' in the above');
      WriteLn;
      Halt;
    end;

    procedure GetININame;
    begin
      Inc(I);
      ConfigFile := CleanPathName(StUpCase(ParamStr(I)));
      if not ExistFile(ConfigFile) then
        Abort('Specified .INI file ' + ParamStr(I) + ' not found');
    end;

    procedure GetPBName;
    begin
      Inc(I);
      ConfigData.PhoneFile := CleanPathName(StUpCase(ParamStr(I)));
    end;

    procedure GetOGQName;
    begin
      Inc(I);
      ConfigData.QueueFile := CleanPathName(StUpCase(ParamStr(I)));
    end;

    procedure GetSendImmed;
    begin
      if (Length(P) <> 2) then begin
        WriteLn('Invalid parameter: ', P);
        WriteLn;
        DisplayParamHelp;
      end;
      SendImmediately := True;
    end;

  begin
    ConfigFile            := '';
    ConfigData.PhoneFile  := '';
    ConfigData.QueueFile  := '';
    SendImmediately       := False;

    I := 1;
    while (I <= ParamCount) do begin
      P := StUpCase(ParamStr(I));

      if (P[1] <> '/') and (P[1] <> '-') and (Length(P) <> 2) then begin
        WriteLn('Invalid parameter: ', P);
        WriteLn;
        DisplayParamHelp;
      end;

      case P[2] of
        'I': GetININame;
        'P': GetPBName;
        'Q': GetOGQName;
        'S': GetSendImmed;
        '?',
        'H': DisplayParamHelp;
      else
        WriteLn('Invalid parameter: ', P);
        WriteLn;
        DisplayParamHelp;
      end;

      Inc(I);
    end;

    { use default file names, if necessary }
    if (ConfigFile = '') then begin
      ConfigFile := 'TPFAX.INI';

      { does the default config file exist in the current directory? }
      if not ExistFile(ConfigFile) then

        { does the default config file exist in the load directory? }
{!!.01} if not ExistFile(AddBackslash(JustPathName(ParamStr(0))) + ConfigFile) then begin
          P := FSearch(ConfigFile, GetEnv('PATH'));
          if (P <> '') then
            ConfigFile := P;
        end else
{!!.01}   ConfigFile := AddBackslash(JustPathName(ParamStr(0))) + ConfigFile;
    end;
  end;

  procedure InitSystem;
  var
    Err : Word;

  begin
    LoadConfiguration;
    wStack.Init(100);

    UseEnhancedKbd := True;
    MainMenu := InitMainMenu;

    if (MainMenu = nil) then
      AbortWithMessage('Menu initialization failed.', InitStatus);

    InitDragMouse(MenuCommands);
    InitDragMouse(PickCommands);
    InitDragMouse(DialogCommands);

    DialogCommands.AddCommand(ccComboTrigger, 1, CtrlDown, 0);

    DefArrows      := TriangleArrows;
    DefSliderChar  := #254;
    DefBarChar     := #177;
    DefPickOptions := ((DefPickOptions and not pkMinHeight) and not pkDrawActive) or
                      pkProcessZero or pkAltCurrent;

    { initialize the outgoing queue }
    SendQueue.Init;
    if ExistFile(ConfigData.QueueFile) then begin
      Err := ReadQueue;
      if (Err <> 0) then
        AbortWithMessage('Unable to read outgoing queue data.', Err);
    end else begin
      Err := WriteQueue;
      if (Err <> 0) then
        AbortWithMessage('Unable to create outgoing fax queue file.', Err);
    end;

    { initialize the directory tree manager }
    if not TreeManager.Init(ConfigData.TreeFile) then
      if (InitStatus = 162) then
        Abort('If running TPFAX on a network, each user must have his/her own set of support files')
      else
        AbortWithMessage('Tree manager initialization failed.', InitStatus);

    { initialize history lists }
    if not CvtFNameHistory.Init(20) or
       not PrnFNameHistory.Init(20) or
       not ViewFNameHistory.Init(20) or
       not SendFNameHistory.Init(20) then
      Abort('Insufficient memory to initialize history lists');

    CvtFNameHistory.AddEntry('*.*');
    PrnFNameHistory.AddEntry('*.APF');
    ViewFNameHistory.AddEntry('*.APF');
    SendFNameHistory.AddEntry('*.*');

    SavedMode := LastMode;
    HiddenCursor;

    TextChar := '°';
    TextAttr := ColorMono(BlueOnLtGray, BlackOnLtGray);
    ClrScr;
    ClearStatus;

    MainMenu^.Draw;

    if SendImmediately then
      SendFaxQueuePrim;
  end;

  procedure DoneSystem;
  begin
    MainMenu^.Erase;
    Dispose(MainMenu, Done);
    TreeManager.Done;
    wStack.Done;
    SendQueue.Done;
    CvtFNameHistory.Done;
    PrnFNameHistory.Done;
    ViewFNameHistory.Done;
    SendFNameHistory.Done;
    TextMode(SavedMode);
  end;

var
  StatusWindow : WindowPtr;

  procedure InitCvtStatusWin;
  begin
    New(StatusWindow, InitCustom( 22, 4, 60, 9,
                                  DialogColors,
                                  wBordered+wClear+wSaveContents ));
    if (StatusWindow <> nil) then
      with StatusWindow^, wFrame, DialogColors do begin
        SetFrameType(DblWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddHeader(' Convert Status ', heTC);
        SetCursor(cuHidden);

        if (RawError <> 0) then begin
          Dispose(StatusWindow, Done);
          StatusWindow := nil;
        end else begin
          StatusWindow^.Draw;
          wFastText('Converting', 2, 3);
          wFastText('Lines converted', 4, 3);
          wFastText('Pages converted', 4, 23);

          wFastFill(15, ' ', 5, 3 , ColorMono(FieldColor, FieldMono));
          wFastFill(15, ' ', 5, 23, ColorMono(FieldColor, FieldMono));
        end;
      end;
  end;

  procedure UpdateCvtStatus(LinesCvt  : LongInt;
                            PagesCvt  : Integer;
                            CvtFile   : String );
  begin
    with StatusWindow^, DialogColors do begin
      wFastText(Pad(Long2Str(LinesCvt), 15), 5, 3);
      wFastText(Pad(Long2Str(PagesCvt), 15), 5, 23);
      wFastText(Pad(CvtFile, 24), 2, 14);
    end;
  end;

  function ConvertStatusFunc( FECP : AbstractFaxConverterPtr;
                              Starting, Ending : Boolean) : Boolean; far;
  var
    Lines       : LongInt;
    Pages       : Integer;
    Action      : String;
    ShouldAbort : Boolean;

  begin
    ShouldAbort := KeyOrButtonPressed;
    if ShouldAbort then begin
      if KeyPressed then
        { eat the keystroke }
        ReadKeyWord
      else
        { eat the mouse click(s) }
        ClearMouseEvents;

      { confirm the abort }
      ShouldAbort := YesNo('Are you sure you want to abort the document conversion?', ' Query ');
    end;

    if ShouldAbort then begin
      ConvertStatusFunc := True;
      Exit;
    end;

    FECP^.GetStatusInfo(Lines, Pages);
    UpdateCvtStatus(Lines, Pages, JustFileName(FECP^.GetFileName));
    ConvertStatusFunc := False;
  end;

  procedure ConvertToFax;
  var
    DB       : PSelectCvtFilesDlg;
    Cmd      : Word;
    Finished : Boolean;

    { loop through the list of selected files and convert them, if possible }
    procedure ConvertSelectedFiles;
    var
      Index  : Word;
      FaxCvt : AbstractFaxConverterPtr;
      FType  : CvtFileType;
      FName  : PathStr;

    label
      EndLoop;

    begin
      InitCvtStatusWin;
      if (StatusWindow = nil) then begin
        ShowError(0, AsyncStatus, emNullError);
        Exit;
      end;

      { put the highlight bar on the first item in the selected list }
      DB^.ClearForStatus;

      Index := 1;
      while (AsyncStatus = ecOK) and (Index <= DB^.cfFiles.GetNumSel) do begin

        AsyncStatus := ecOK;

        { get the information about this selected file }
        DB^.cfFiles.GetSelFileInfo(Index, FName, FType);

        FaxCvt := nil;

        { instantiate a fax converter based on the type of data file }
        case FType of
          ftTEXT: FaxCvt := New(TextFaxConverterPtr, Init);
          ftPCX : FaxCvt := New(PcxFaxConverterPtr , Init);
          ftDCX : FaxCvt := New(DcxFaxConverterPtr , Init);
          ftTIFF: FaxCvt := New(TiffFaxConverterPtr, Init);
          ftBMP : FaxCvt := New(BmpFaxConverterPtr , Init); {!!.03}
        end;

        { success? }
        if (FaxCvt <> nil) then
          with FaxCvt^ do begin
            SetResolutionMode(ConfigData.Resolution);
            SetStatusFunc(ConvertStatusFunc);
            SetFaxPath(JustPathName(FName));

            if (FType = ftText) then begin
              if not LoadFont(StandardFont, ConfigData.Resolution) then begin
                ShowError(0, AsyncStatus, emNullError);
                Dispose(FaxCvt, Done);
                goto EndLoop;
              end;

              SetPageSize(ConfigData.PageLen);
            end;

            { get the raw error number }
            AsyncStatus := AsyncStatus mod 10000;
            ConvertFax(FName);
            if (AsyncStatus <> ecOK) and (AsyncStatus <> ecUserAbort) then
              ShowError(0, AsyncStatus, emNullError);

            Dispose(FaxCvt, Done);
          end;

    EndLoop:
        if (AsyncStatus = ecOK) then
          DB^.cfFiles.UnselectFile(Index)
        else if (AsyncStatus = ecUserAbort) then
          Finished := True
        else begin
          Inc(Index);
          AsyncStatus := ecOK;
        end;

        DB^.UpdateForStatus(Index);
      end;

      Finished := (DB^.cfFiles.GetNumSel = 0);

      StatusWindow^.Erase;
      Dispose(StatusWindow, Done);

      with DB^ do begin
        cfFiles.Refresh;
        cfUnselFiles^.ChangeNumItems(cfFiles.GetNumUnsel);
        cfUnselFiles^.SetInitialChoice(1);
        cfUnselFiles^.UpdateContents;
      end;
    end;

  begin
    New(DB, Init(False, False, False, ' Select Files for Conversion ', @CvtFNameHistory));
    if (DB = nil) then begin
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;

    Finished := False;
    repeat
      Cmd := ProcessDialog(DB);
      if (Cmd = ccSelect) then
        ConvertSelectedFiles
      else
        Finished := (Cmd = ccQuit);
    until Finished;

    DB^.Erase;
    Dispose(DB, Done);
  end;

{-- VARIABLES USED BY THE QUEUE SEND ENGINE --}
var
  OnEntry     : PSendQueueEntry;
  OnFile      : PSendFileNode;
  AbsFax      : AbstractFaxPtr;
  SendPort    : AbstractPortPtr;
  BytesInFile : LongInt;
  LastStatus  : Word;
  LastCode    : Word;
  RejectList  : SingleList;
  LastBytesX  : LongInt;
  LastPageX   : Word;         {!!.01}
  TotalBytesX : LongInt;

  function PortAbortFunc : Boolean; far;
  begin
    PortAbortFunc := (KeyPressed and (ReadKeyWord = Esc)) or
                     (MousePressed and (MouseKeyWord = MouseRt));
  end;

  { return a port object based on configuration options }
  function GetAPort : AbstractPortPtr; far;
  var
    AP : AbstractPortPtr;

  begin
    case ConfigData.DevType of
      dlUart  :
        begin
          AP := New(UartPortPtr, InitCustom(ConfigData.ComPort,
                                            ConfigData.PortRate,
                                            NoParity, 8, 1,
                                            1024, 8192,
                                            DefPortOptions));
          if (AP <> nil) then begin
            RotateIrqPriority(DefIrqNumber[ConfigData.ComPort]);
            if (ClassifyUart(AP^.GetBaseAddr, False) = U16550A) then
              SetFifoBuffering(AP^.GetBaseAddr, True, 4);
          end;
        end;

      dlInt14 : AP := New(Int14PortPtr, InitCustom( ConfigData.ComPort,
                                                    ConfigData.PortRate,
                                                    NoParity, 8, 1,
                                                    1024, 8192,
                                                    DefPortOptions ));
      dlDigi  : AP := New(Digi14PortPtr, InitCustom(ConfigData.ComPort,
                                                    ConfigData.PortRate,
                                                    NoParity, 8, 1,
                                                    1024, 8192,
                                                    DefPortOptions));
      dlFossil: AP := New(FossilPortPtr, InitCustom(ConfigData.ComPort,
                                                    ConfigData.PortRate,
                                                    NoParity, 8, 1,
                                                    1024, 8192,
                                                    DefPortOptions));
    end;

    if (AP = nil) or (AsyncStatus <> ecOK) then begin         {!!.01}
      if (AsyncStatus = ecOK) then                            {!!.01}
        AsyncStatus := epFatal+ecOutOfMemory;                 {!!.01}
      ShowError(0, AsyncStatus, emNullError);                 {!!.01}
      GetAPort := nil;                                        {!!.01}
      Exit;                                                   {!!.01}
    end;                                                      {!!.01}

    with AP^ do begin
      if ConfigData.UseHWFlow then                            {!!.01}
        AP^.HWFlowEnable(952, 50, hfRequireCTS or hfUseRTS);  {!!.01} {!!.02}
      SetAbortFunc(PortAbortFunc)                             {!!.01}
    end;                                                      {!!.01}

    GetAPort := AP;
  end;

  procedure ClearC12FaxStatus;
  var
    C : Byte;
    I : Byte;

  begin
    with StatusWindow^ do begin
      C := ColorMono(DialogColors.FieldColor, DialogColors.FieldMono);
      wFastFill(20, ' ', 3, 3, C);
      wFastFill(20, ' ', 3, 27, C);
      wFastFill(5, ' ', 3, 51, C);
      wFastFill(14, ' ', 6, 3, C);
      wFastFill(14, ' ', 6, 20, C);
      wFastFill(14, ' ', 9, 3, C);
      wFastFill(14, ' ', 9, 20, C);
      wFastFill(53, ' ', 12, 3, C);
      wFastFill(53, ' ', 15, 3, C);

      for I := 6 to 9 do
        wFastFill(19, ' ', I, 37, ColorMono(ClusterColors.ClusterColor,
                                            ClusterColors.ClusterMono));
    end;
  end;

  procedure InitC12FaxStatusWin;
  begin
    New(StatusWindow, InitCustom( 13, 5, 69, 20,
                                  DialogColors,
                                  wBordered+wClear+wSaveContents));
    if (StatusWindow <> nil) then
      with StatusWindow^ do begin
        wFrame.AddHeader(' Fax Send Status ', heTC);
        wFrame.SetFrameType(DblWindowFrame);
        wFrame.AddShadow(shBR, shSeeThru);
        SetCursor(cuHidden);

        Draw;
        wFastText('Sending File(s) to', 2, 3);
        wFastText('Remote Station ID', 2, 27);
        wFastText('BPS', 2, 51);
        wFastText('Pages to send', 5, 3);
        wFastText('Pages Sent', 5, 20);
        wFastText('Bytes to send', 8, 3);
        wFastText('Bytes Sent', 8, 20);
        wFastText('Operation/Status', 11, 3);
        wFastText('% Complete', 14, 3);
        ClearC12FaxStatus;
      end;
  end;

  procedure C12FaxStatus( AP : AbstractFaxPtr;
                          Starting, Ending : Boolean); far;
  var
    NumPages    : Word;
    OnPage      : Word;
    BytesXfered : LongInt;
    PageLen     : LongInt;
    BPS         : LongInt;
    Progress    : Word;
    StatChars   : Byte;
    Resolution  : Boolean;
    Correction  : Boolean;
    StatID      : String;
    Action      : String;
    Size        : Word;

  begin
    Size := SendPort^.OutBuffUsed;
    with StatusWindow^, C12SendFaxPtr(AP)^ do begin
      GetPageInfo(NumPages, OnPage, BytesXfered, PageLen);
      Progress := GetFaxProgress;

      LastStatus := Progress;
      case LastStatus of
        fpSendPage,
        fpSendPageStatus,
        fpPageError,
        fpPageOK:
          begin
            { update the send progress info }               {!!.01}
            if (LastPageX <> OnPage) then                   {!!.01}
              LastBytesX := 0;                              {!!.01}
                                                            {!!.01}
            LastPageX := OnPage;                            {!!.01}
                                                            {!!.01}
            Inc(TotalBytesX, BytesXFered - LastBytesX);     {!!.01}
            LastBytesX := BytesXfered;                      {!!.01}

            wFastText(Long2Str(NumPages), 6, 3);
            wFastText(Long2Str(OnPage), 6, 20);
            wFastText(Long2Str(BytesInFile), 9, 3);
            wFastText(Long2Str(TotalBytesX), 9, 20);

            if (BytesInFile <> 0) then
              StatChars := Round(53 * (TotalBytesX) / BytesInFile)
            else
              StatChars := 0;

            if (StatChars > 53) then
              StatChars := 53;

            wFastFill(StatChars, #219, 15, 3, ColorMono(DialogColors.FieldColor,
                                                        DialogColors.FieldMono));
          end;

        fpSessionParams:
          begin
            GetSessionParams(BPS, Resolution, Correction);
            wFastText(Pad(Long2Str(BPS), 5), 3, 51);
          end;

        fpGotRemoteID:
          wFastText(GetRemoteID, 3, 27);
      end;

      case LastStatus of
        fpInitModem     : Action := 'Initializing faxmodem';
        fpDialing       : Action := 'Dialing remote';
        fpBusyWait      : Action := 'Remote is busy...waiting to send';
        fpSendPage      : Action := 'Sending page data';
        fpSendPageStatus: Action := 'Sending end-of-page';
        fpPageError     : Action := 'Error sending page...page being resent';
        fpPageOK        : Action := 'Remote received page correctly';
        fpSessionParams : Action := 'Getting session parameters';
        fpGotRemoteID   : Action := 'Got remote station ID';
        else
          Action := '';
      end;

      wFastText(Pad(Action, 53), 12, 3);
    end;
  end;

  function GetFileDataBytes(FN : PathStr) : LongInt;
  var
    F  : File;
    FH : FaxHeaderRec;
    FS : LongInt;

  begin
    GetFileDataBytes := 1;
    Assign(F, FN);
    Reset(F, 1);
    if (IoResult <> 0) then
      Exit;

    BlockRead(F, FH, SizeOf(FaxHeaderRec));
    if (IoResult <> 0) then begin
      Close(F);
      Exit;
    end;

    FS := FileSize(F);
    Close(F);
    GetFileDataBytes :=
      FS - (FH.PageCount * SizeOf(PageHeaderRec)) - SizeOf(FaxHeaderRec);
  end;

  procedure UpdateFileNameDisplay;
  begin
    StatusWindow^.wFastText(
      Pad(JustFileName(StringFromHeap(OnFile^.FName)), 12), 6, 38);
  end;

  function ConvertSendFile(var FName : PathStr; FType : CvtFileType) : Boolean;
  var
    AF : AbstractFaxConverterPtr;

  begin
    ConvertSendFile := False;

    case FType of
      ftTEXT : AF := New(TextFaxConverterPtr, Init);
      ftPCX  : AF := New(PcxFaxConverterPtr , Init);
      ftDCX  : AF := New(DcxFaxConverterPtr , Init);
      ftTIFF : AF := New(TiffFaxConverterPtr, Init);
      ftBmp  : AF := New(BmpFaxConverterPtr , Init); {!!.03}
    else
      AF := nil;
    end;

    if (AF = nil) then
      Exit;

    AF^.SetFaxPath(JustPathName(FName));
    AF^.SetResolutionMode(False);

    if (FType = ftTEXT) then begin
      if not AF^.LoadFont(StandardFont, ConfigData.Resolution) then begin
        Dispose(AF, Done);
        Exit;
      end;

      AF^.SetPageSize(ConfigData.PageLen);
    end;

    AF^.ConvertFax(FName);
    Dispose(AF, Done);
    if (AsyncStatus = ecOK) then begin
      FName := ForceExtension(FName, 'APF');
      ConvertSendFile := True;
    end;
  end;

  procedure GetNextSendFile;
  var
    QE : PSendQueueEntry;
    SF : PSendFileNode;

  begin
    if (OnEntry = nil) and (OnFile = nil) then
      SendQueue.GetFirstFile(OnEntry, OnFile)
    else
      SendQueue.GetNextFile(OnEntry, OnFile);
  end;

  procedure AddToRejectList;
  var
    RE  : PRejectFile;
    SV  : PSendFileNode;
    Err : Word;

  begin
    New(RE, Init);
    if (RE = nil) then begin
      Err := epNonFatal+ecOutOfMemory;
      ShowError(0, Err, emNullError);
      Exit;
    end;

    RE^.FName := JustFileName(StringFromHeap(OnFile^.FName));
    if (OnEntry^.SendTo = '') then
      RE^.FDest := OnEntry^.SendNum
    else
      RE^.FDest := OnEntry^.SendTo;
    RE^.FErr := AsyncStatus;

    RejectList.Append(RE);
  end;

  function WaitForFaxTime : Boolean;
  var
    RW : RawWindow;
    C  : Byte;

  label
    DoneWait;

  begin
    WaitForFaxTime := True;

    { exit immediately if no waiting needs to be done }
    if (CurrentTime >= OnEntry^.SendTime) and (Today >= OnEntry^.SendDate) then
      Exit;

    if not RW.InitCustom( 29, 16, 75, 16,
                          ErrorColors,
                          wBordered+wClear ) then
      Exit;

    with RW, wFrame do begin
      AddShadow(shBR, shSeeThru);
      SetFrameType(SglWindowFrame);
      SetCursor(cuHidden);
    end;

    RW.Draw;

    C := ColorMono(ErrorColors.TextColor, ErrorColors.TextMono) + Blink;

    RW.wFastWrite('Next fax to be sent at ' +
                  TimeToTimeString('hh:mm te', OnEntry^.SendTime) + ' on ' +
                  DateToDateString('mm/dd/yyyy', OnEntry^.SendDate), 1, 2, C);


    { wait for our time to come }
    repeat
      if PortAbortFunc then begin
        WaitForFaxTime := False;
        goto DoneWait;
      end;
    until (CurrentTime >= OnEntry^.SendTime) and (Today >= OnEntry^.SendDate);

DoneWait:
    RW.Erase;
    RW.Done;
  end;

  function GetNextQueueFile(     AP     : AbstractFaxPtr;
                             var Number : String;
                             var FName  : PathStr;
                             var Cover  : PathStr ) : Boolean; far;
  var
    OutStr : String;
    FaxLog : Text;

  label
    Start;

  begin

Start:

    if PortAbortFunc then begin
      GetNextQueueFile := False;
      Exit;
    end;

    { if there are no more entries, then exit }
    if (OnEntry = nil) or (OnFile = nil) then begin
      GetNextQueueFile := False;
      Exit;
    end;

    Number := OnEntry^.SendNum;
    FName := StringFromHeap(OnFile^.FName);

    Cover := ConfigData.CoverPage;

    { if the file isn't an APF file, try to convert it }
    if (OnFile^.FType <> ftAPF) then begin
      StatusWindow^.wFastText(Pad('Converting document', 54), 12, 3);
      if not ConvertSendFile(FName, OnFile^.FType) then begin
        Assign(FaxLog, 'TPFAX.LOG');
        Append(FaxLog);
        if (IoResult = 2) then
          Rewrite(FaxLog);
        WriteLn(FaxLog, 'Unable to convert ', FName, ' error #', AsyncStatus);
        WriteLn(FaxLog);
        Close(FaxLog);

        AddToRejectList;
        GetNextSendFile;

        goto Start;
      end;
    end;

    BytesInFile := GetFileDataBytes(FName);
    ClearC12FaxStatus;

    { update the "who am I sending to" portion of the screen }
    if (OnEntry^.SendTo = '') then
      OutStr := OnEntry^.SendNum
    else
      OutStr := OnEntry^.SendTo;
    StatusWindow^.wFastText(OutStr, 3, 3);
    UpdateFilenameDisplay;

    { do we need to wait for a date/time? }
    if not OnEntry^.Immediate then
      if not WaitForFaxTime then begin
        GetNextQueueFile := False;
        Exit;
      end;

    GetNextQueueFile := True;
  end;

  procedure SomeoneElsesLogFaxProc( AP     : AbstractFaxPtr;
                                    Number : String;
                                    FName  : PathStr;
                                    Log    : TLogFaxCode ); far;
  var
    FLog      : Text;
    F         : File;
    SaveFType : CvtFileType;
    Err       : Word;

  begin
    with AP^ do begin
      Assign(FLog, 'TPFAX.LOG');
      Append(FLog);
      if (IoResult = 2) then
        Rewrite(FLog);

      case Log of
        lFaxTransmitStart:
          begin
            TotalBytesX := 0;
            LastBytesX  := 0;
            LastPageX   := 0;
            WriteLn(FLog, OpDate.TodayString('mm/dd/yy'), ' ',
                          OpDate.CurrentTimeString('hh:mm te'),
                          ' -- start fax transmit: ', FName, ' to ', Number);
          end;

        lFaxTransmitOk :
          begin
            OnFile^.FSize := $FFFF;
            WriteLn(FLog, OpDate.TodayString('mm/dd/yy'), ' ',
                          OpDate.CurrentTimeString('hh:mm te'),
                          ' -- end fax transmit: ', FName);
            WriteLn(FLog);
          end;

        lFaxTransmitFail :
          begin
            WriteLn(FLog, OpDate.TodayString('mm/dd/yy'), ' ',
                          OpDate.CurrentTimeString('hh:mm te'),
                          ' -- fail fax transmit (', AsyncStatus, '): ', FName);
            WriteLn(FLog);
          end;
      end;

      LastCode := AsyncStatus;

      if (Log <> lFaxTransmitStart) then begin
        SaveFType := OnFile^.FType;

        if (Log <> lFaxTransmitOk) and (AsyncStatus <> ecUserAbort) then
          AddToRejectList;

        if (AsyncStatus <> ecUserAbort) then
          GetNextSendFile;

        { erase the temporary send file, if necessary }
        if (SaveFType <> ftAPF) then begin
          Assign(F, FName);
          Erase(F); if (IoResult = 0) then ;
        end;
      end;

      Close(FLog); if (IoResult = 0) then ;
    end;
  end;

const
  CorrectionChars : array[False..True] of Char = ('0', '1');

  { return a fax object based on configuration options }
  function GetAFax(APort : AbstractPortPtr) : AbstractFaxPtr;
  var
    AF    : AbstractFaxPtr;
    Class : Char;
    Model : String;
    Chip  : String;
    Rev   : String;

  label
    Error;

  begin
    GetAFax := nil;

    if ConfigData.FaxClass in [ctClass1, ctClass2, ctDetect] then begin
      AF := New(C12SendFaxPtr, Init(ConfigData.StationID, APort));
      if (AF = nil) then begin
        ShowError(0, AsyncStatus, emNullError);
        Exit;
      end;

      with C12SendFaxPtr(AF)^ do begin
        SetToneDial(ConfigData.ToneDial);
        SetDialPrefix(ConfigData.DialPrefix);
        SetDialTime(Secs2Tics(ConfigData.DialTime));
        SetMaxRetries(ConfigData.MaxRetries);
        SetModemInit(ConfigData.ModemInit);
        SetClassType(ConfigData.FaxClass);
        SetSenderName(ConfigData.SenderName);
        SetHeaderText(ConfigData.Header);
        if (AsyncStatus <> ecOK) then
          goto Error;

        SetModemFeatures( ConfigData.XmitBPS,
                          CorrectionChars[ConfigData.ErrorCorrection]);
        if (AsyncStatus <> ecOK) then
          goto Error;

        if (ConfigData.FaxClass <> ctCas) then
          SetFaxStatusProc(C12FaxStatus);
        SetNextFaxFunc(GetNextQueueFile);
        SetFaxLogProc(SomeoneElsesLogFaxProc);

        OkDelay := 55;
        if not GetModemInfo(Class, Model, Chip, Rev, True) or (AsyncStatus <> ecOK) then
          goto Error;
      end;
    end else
      AF := nil;

    GetAFax := AF;
    Exit;

Error:
    Dispose(AF, Done);
  end;

  procedure SendFaxQueue;
  var
    SaveStatus : Word;
    SF         : PSendFileNode;
    SE         : PSendQueueEntry;

  begin

    if (SendQueue.TotalFiles = 0) then begin
      ShowErrorMessage('No files in outgoing queue.');
      Exit;
    end;

    { get a port for sending }
    SendPort := GetAPort;
    if (SendPort = nil) then begin
      ShowError(0, AsyncStatus, emNullError);
      Exit;
    end;

    { initialize a fax }
    AbsFax := GetAFax(SendPort);
    if (AbsFax = nil) then begin
      SaveStatus := AsyncStatus;
      if (ConfigData.DevType = dlUart) then
        RotateIrqPriority(0);
      Dispose(SendPort, Done);
      if (SaveStatus <> ecOK) and (SaveStatus <> ecUserAbort) then
        ShowError(0, SaveStatus, emNullError);
      Exit;
    end;

    if (ConfigData.FaxClass <> ctCas) then
      InitC12FaxStatusWin
    else
      StatusWindow := nil; { nothing yet }

    if (StatusWindow = nil) then begin
      Dispose(AbsFax, Done);
      if (ConfigData.DevType = dlUart) then
        RotateIrqPriority(0);
      Dispose(SendPort, Done);
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;

    ClearStatus;
    FastText(' Press <Esc> to abort sending', ScreenHeight, 2);

    OnEntry := nil;
    OnFile  := nil;
    GetNextSendFile;

    if (OnEntry <> nil) and (OnFile <> nil) then begin
      LastStatus := 0;
      AbsFax^.FaxTransmit;
    end;

    Dispose(AbsFax, Done);
    if (ConfigData.DevType = dlUart) then
      RotateIrqPriority(0);
    Dispose(SendPort, Done);
    StatusWIndow^.Erase;
    Dispose(StatusWindow, Done);

    { go through the send queue and remove files that were successfully sent }
    SendQueue.GetFirstFile(OnEntry, OnFile);
    while (OnEntry <> nil) and (OnFile <> nil) do begin

      SF := PSendFileNode(OnFile^.slNext);

      if (OnFile^.FSize = $FFFF) then
        OnEntry^.FileList.Delete(OnFile);

      OnFile := SF;

      if (OnFile = nil) then begin
        SE := OnEntry;
        SendQueue.GetNextFile(OnEntry, OnFile);

        if (SE^.FileList.Size = 0) then
          SendQueue.KillKillKill(SE);
      end;
    end;

    AsyncStatus := WriteQueue;
    if (AsyncStatus <> ecOK) then
      ShowError(0, AsyncStatus, emNullError);
  end;

  procedure ViewRejectList;
  var
    DB : PRejectListDlg;

  begin
    { if there are no rejects, just exit }
    if (RejectList.Size = 0) then
      Exit;

    New(DB, Init(RejectList));
    if (DB = nil) then
      Exit;

    ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);
  end;

  procedure SendCasQueue;
  var
    CF     : CasFax;
    D      : Integer;
    M      : Integer;
    Y      : Integer;
    H      : Byte;
    S      : Byte;
    Min    : Byte;
    DT     : DateTime;
    PT     : LongInt;
    Handle : Word;
    SE     : PSendQueueEntry;
    SF     : PSendFileNode;

  label
    Error;

  begin

    if not CasInstalled then begin
      ShowErrorMessage('No CAS manager is installed');
      Exit;
    end;

    if not CF.Init(ConfigData.StationID) then begin
      ShowError(0, AsyncStatus, emNullError);
      Exit;
    end;

    if (ConfigData.LogoFile <> '') and ExistFile(ConfigData.LogoFile) then
      CF.SetLogoFile(ConfigData.LogoFile);

    { loop through all files in the queue, submitting them to CAS }
    SendQueue.GetFirstFile(OnEntry, OnFile);
    while (OnEntry <> nil) and (OnFile <> nil) do begin

      if OnEntry^.Immediate then
        PT := 0
      else begin

        { convert OPRO's date and time into CAS's format }
        DateToDMY(OnEntry^.SendDate, D, M, Y);
        DT.Day   := D;
        DT.Month := M;
        DT.Year  := Y;

        TimeToHMS(OnEntry^.SendTime, H, Min, S);
        DT.Hour := H;
        DT.Min  := Min;
        DT.Sec  := S;

        PackTime(DT, PT);

      end;

      CF.SubmitSingleFile(Ord(not (ConfigData.Resolution)), 0, Lo(PT), Hi(PT),
                          '', StringFromHeap(OnFile^.FName),
                          OnEntry^.SendNum, ConfigData.CoverPage, Handle);

      if (AsyncStatus <> ecOK) then begin
        ShowError(0, AsyncStatus, emNullError);
        goto Error;
      end;

      SE := OnEntry;
      SF := OnFile;

      SendQueue.GetNextFile(OnEntry, OnFile);

      SE^.FileList.Delete(SF);
      if (SE^.FileList.Size = 0) then
        SendQueue.KillKillKill(SE);
    end;

Error:
    CF.Done;
    AsyncStatus := WriteQueue;
    if (AsyncStatus <> ecOK) then
      ShowError(0, AsyncStatus, emNullError);
  end;

  procedure SendFaxQueuePrim; {!!.01 - Code moved from SendFaxes }
  begin
    if (SendQueue.TotalFiles = 0) then begin
      ShowErrorMessage('No files in outgoing queue.');
      Exit;
    end;

    if (ConfigData.FaxClass <> ctCas) then begin
      RejectList.Init;
      SendFaxQueue;
      ViewRejectList;
      RejectList.Done;
    end else
      SendCasQueue;
  end;

  procedure SendFaxes;
  var
    DB  : PFaxQueueDialog;
    LC  : Word;
    Err : Word;

  label
    StartAgain;

  begin

StartAgain:

    New(DB, Init);
    if (DB = nil) then begin
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;

    LC := ProcessDialogPrim(DB, False);
    DB^.Erase;
    Dispose(DB, Done);

    case LC of
      ccQuit:
        { if the user aborted, re-read the fax queue from disk }
        if (LC = ccQuit) then begin
          SendQueue.Clear;
          if ExistFile(ConfigData.QueueFile) then begin
            Err := ReadQueue;
            if (Err <> 0) then begin
              ShowError(0, Err, emNullError);
              Exit;
            end;
          end;
        end;
      ccSelect,
      ccSendQueue:
        begin
          Err := WriteQueue;
          if (Err <> 0) then begin
            ShowError(0, Err, emNullError);
            Exit;
          end;
        end;
    end;

    if (LC = ccSendQueue) then begin {!!.01}
      SendFaxQueuePrim;              {!!.01}
      goto StartAgain;               {!!.01}
    end;                             {!!.01}
  end;

  procedure ViewFax;
  var
    DB       : PSelectApfFilesDlg;
    Cmd      : Word;
    FName    : PathStr;
    TV       : PFaxViewer;
    LC       : Word;
    LastPath : DirStr;
    LastMask : TFileNameStr;

  begin
    repeat
      New(DB, Init(' Select File for Viewing ', @ViewFNameHistory));
      if (DB = nil) then begin
        ShowError(0, InitStatus, emNullError);
        Exit;
      end;

      LC := ProcessDialog(DB);

      if (LC = ccSelect) then begin
        FName := DB^.GetFileName;
        DB^.Erase;
        Dispose(DB, Done);

        New(TV, Init(FName, $12, 640, 480));
        if (TV = nil) then begin
          ShowError(0, InitStatus, emNullError);
          Exit;
        end else begin
          TV^.SetErrorProc(ShowError);
          OneMomentPlease;
          TV^.Process;
          Dispose(TV, Done);
        end;
      end else begin
        DB^.Erase;
        Dispose(DB, Done);
      end;
    until (LC = ccQuit);
  end;

  procedure InitPrnStatusWin;
  begin
    New(StatusWindow, InitCustom( 22, 10, 60, 15,
                                  DialogColors,
                                  wBordered+wClear+wSaveContents ));
    if (StatusWindow <> nil) then
      with StatusWindow^, wFrame, DialogColors do begin
        SetFrameType(DblWindowFrame);
        AddShadow(shBR, shSeeThru);
        AddHeader(' Print Status ', heTC);
        SetCursor(cuHidden);

        if (RawError <> 0) then begin
          Dispose(StatusWindow, Done);
          StatusWindow := nil;
        end else begin
          StatusWindow^.Draw;
          wFastText('Printing', 2, 3);
          wFastText('Lines printed', 4, 3);
          wFastText('Pages printed', 4, 23);
          wFastFill(15, ' ', 5, 3 , ColorMono(FieldColor, FieldMono));
          wFastFill(15, ' ', 5, 23, ColorMono(FieldColor, FieldMono));
        end;
      end;
  end;

{ for fax print status }
var
  psPageCount : Word;
  psLineCount : Word;
  psPrnFile   : TFileNameStr;

  function PrnAbort : Boolean;
  begin
    if KeyPressed then begin
      ReadKeyWord;
      PrnAbort := YesNo('Are you sure you want to abort the printing of this fax?', ' Confirm ');
    end else
      PrnAbort := False;
  end;

  procedure PrnStatus;
  begin
    with StatusWindow^ do begin
      wFastText(Pad(psPrnFile, 24), 2, 14);
      wFastText(Pad(Long2Str(psLineCount), 15), 5, 3);
      wFastText(Pad(Long2Str(psPageCount), 15), 5, 23);
    end;
  end;

  function PrnLineNotify(Lines, LineSize : Word) : Boolean; far;
  begin
    psLineCount := Lines;
    PrnStatus;
    PrnLineNotify := PrnAbort;
  end;

  function PrnWriteNotify(BytesWritten : Word) : Boolean; far;
  begin
    PrnWriteNotify := PrnAbort;
  end;

  function PrnPageNotify(ThisPage, TotalPages : Word) : Boolean; far;
  begin
    psPageCount := ThisPage;
    PrnStatus;
    PrnPageNotify := PrnAbort;
  end;

  procedure PrintFaxes;
  var
    DB       : PSelectCvtFilesDlg;
    Cmd      : Word;
    Finished : Boolean;

    { loop through the list of selected files and print them, if possible }
    procedure PrintSelectedFiles;
    var
      Index    : Word;
      APrinter : AbstractPrinterPtr;
      FaxPrn   : FaxPrinterPtr;
      FType    : CvtFileType;
      FName    : PathStr;

      procedure SetPrnFlag(Mask : Byte; On : Boolean);
      begin
        if On then
          APrinter^.fpOptionsOn(Mask)
        else
          APrinter^.fpOptionsOff(Mask);
      end;

    begin
      InitPrnStatusWin;
      if (StatusWindow = nil) then begin
        ShowError(0, AsyncStatus, emNullError);
        Exit;
      end;

      { put the highlight bar on the first item in the selected list }
      DB^.ClearForStatus;

      if (ConfigData.WhatPrn = psPCL5) or (ConfigData.WhatPrn = psPCL4) then
        if ConfigData.Use300DPI then
          APrinter := New(HP300PrinterPtr, Init)
        else
          APrinter := New(HP150PrinterPtr, Init)
      else if (ConfigData.WhatPrn = psEpsonFX) then
        APrinter := New(EpsonPrinterPtr, Init)
      else
        APrinter := New(Epson24PinPrinterPtr, Init);

      if (APrinter = nil) then begin
        StatusWindow^.Erase;
        Dispose(StatusWindow, Done);

        ShowErrorMessage('Printer initialization failed');
        Exit;
      end;

      SetPrnFlag(fpPcl5Mode, (ConfigData.WhatPrn = psPCL5));
      SetPrnFlag(fpScale, ConfigData.UseScaling);
      SetPrnFlag(fpHeader, ConfigData.PrintFaxHeader);
      SetPrnFlag(fpSuppressBlanks, False);

      Index := 1;
      while (AsyncStatus = ecOK) and (Index <= DB^.cfFiles.GetNumSel) do begin
        AsyncStatus := ecOK;

        { get the information about this selected file }
        DB^.cfFiles.GetSelFileInfo(Index, FName, FType);

        FaxPrn := nil;

        New(FaxPrn, Init(APrinter));

        { success? }
        if (FaxPrn <> nil) then
          with FaxPrn^ do begin
            SetLineNotifyFunc(PrnLineNotify);
            SetWriteNotifyFunc(PrnWriteNotify);
            SetPageNotifyFunc(PrnPageNotify);

            psPrnFile := JustFileName(FName);
            FaxPrn^.PrintFax(ConfigData.PrnName, FName);
            if (AsyncStatus <> 0) then
              ShowError(0, AsyncStatus, emNullError);

            Dispose(FaxPrn, Done);
          end;

        if (AsyncStatus = ecOK) then
          DB^.cfFiles.UnselectFile(Index)
        else if ((AsyncStatus mod 10000) = ecUserAbort) then
          Finished := True
        else begin
          Inc(Index);
          AsyncStatus := ecOK;
        end;

        DB^.UpdateForStatus(Index);
      end;

      Finished := DB^.cfFiles.GetNumSel = 0;

      StatusWindow^.Erase;
      Dispose(StatusWindow, Done);
    end;

  begin
    New(DB, Init(False, True, True, ' Select files for Printing ', @PrnFNameHistory));
    if (DB = nil) then begin
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;

    Finished := False;
    repeat
      Cmd := ProcessDialog(DB);
      if (Cmd = ccSelect) then
        PrintSelectedFiles
      else
        Finished := (Cmd = ccQuit);
    until Finished;

    DB^.Erase;
    Dispose(DB, Done);
  end;

  procedure OpenPhonebook;
  var
    DB : PPhonebookMaintDlg;

  begin
    New(DB, Init);
    if (DB = nil) then begin
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;
    ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);
  end;

  procedure DisplayAboutBox;
  var
    DB : DialogBoxPtr;

  begin
    DB := InitAboutBox;
    if (DB = nil) then begin
      ShowError(0, InitStatus, emNullError);
      Exit;
    end;

    ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);
  end;

  procedure ExecuteChoice(Choice : Word);
  begin
    MainMenu^.EraseAllSubMenus(False, False);

    case Choice of
      mmAbout    : DisplayAboutBox;
      mmConvert  : ConvertToFax;
      mmSend     : SendFaxes;
      mmView     : ViewFax;
      mmPrint    : PrintFaxes;
      mmPhonebook: OpenPhonebook;
    end;
  end;

  procedure TpFaxMainLoop;
  var
    Choice : Word;

  begin
    DisplayCopyright;
    ParseCommandLine;
    InitSystem;

    with MainMenu^ do
      repeat
        Process;
        Choice := MenuChoice;
        if (GetLastCommand <> ccQuit) and (Choice <> mmExit) then
          ExecuteChoice(Choice);
      until (Choice = mmExit);

    DoneSystem;
  end;

end.
