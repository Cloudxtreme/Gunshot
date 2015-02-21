{$R-,S-,I-,V-,B-,F+,O+,A-}

{*********************************************************}
{*                    OOUI.PAS 2.03                      *}
{*        Copyright (c) TurboPower Software 1989.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I OPDEFINE.INC}

{***************************************************************************
 This unit requires that OPDEFINE.INC activate the following defines:
   UseDates, UseScrollBars, UseHotSpots, UseAdjustableWindows,
   UseShadows
 This unit will use features activated with the following defines:
   UseMouse
 ***************************************************************************}

{$IFNDEF UseDates}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

{$IFNDEF UseScrollBars}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

{$IFNDEF UseHotSpots}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

{$IFNDEF UseAdjustableWindows}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

{$IFNDEF UseShadows}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

{$IFDEF UseDrag}
  !! STOP COMPILE - settings in OPDEFINE.INC are not compatible with this unit.
{$ENDIF}

unit OOUI;
  {-TurboPower User Interface routines}

interface

uses
  Dos,
  OpInline,
  OpString,
  OpRoot,
  {$IFDEF Opro12}
  OpConst,
  {$ENDIF}
  OpCrt,
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpCmd,
  OpDos,
  OpFrame,
  OpWindow,
  OpEdit,
  OpPick,
  OpDir;

{$I OOUI.PCD}      {configuration data}

const
  {frame stuff}
  SliderChar       = '²';
  ScrollBarChar    = '°';
  BackdropChar     = '±';
  BackdropAttr     = $07;
  TpUiFrame        = 'ÕÔ¸¾ÍÍ³³';
  Step             = 1;

  {status line}
  StatusRow        : Byte = 25;
  DirHelpIndex     : Word = 0;
  MaxCommands      = $FFF1 div SizeOf(Word);

type
  udMap =
    record
      udmTitle : Byte;
      udmTitleHotSpot : Byte;
      udmWinNum : Byte;
      udmUnused : Byte;
    end;

  InitFunc = function(X1, Y1, X2, Y2 : Byte; Msg : string) : Boolean;
  ProcessProc = procedure (var Cmd : Word);
  CloseProc = procedure (EraseFirst : Boolean);
  OkToCloseFunc = function : Boolean;
  StatusProc = procedure;
  ErrorMsgFunc = function (ErrorCode : Word) : String;

  CommandList =
    Array[1..MaxCommands] of Word;

  DesktopWindow =
    record
      dwActive  : Boolean;
      dwNext    : Byte;
      dwPrev    : Byte;
      dwInit    : InitFunc;
      dwProcess : ProcessProc;
      dwClose   : CloseProc;
      dwOK      : OkToCloseFunc;
      dwWindow  : CommandWindowPtr;
    end;

  DesktopArray = array[1..255] of DesktopWindow;
  Desktop =
    object
      dtMax      : Byte;          {maximum number of windows to manage}
      dtCount    : Byte;          {actual number of windows to manage}
      dtActive   : Byte;          {number of windows that are active}
      dtCurrent  : Byte;          {current window}
      dtNew      : Byte;          {new window to switch to}
      dtFirst    : Byte;          {number of first active window}
      dtX1, dtY1 : Byte;          {window coordinates for the desktop}
      dtX2, dtY2 : Byte;
      dtCmdIndex : Word;
      dtCmds     : ^CommandList;
      dtWindows  : ^DesktopArray; {windows to be managed}
      {...}
      constructor Init(X1, Y1, X2, Y2 : Byte; Max : Byte);
        {-Initialize desktop window manager}
      function AddWindow(var CW     : CommandWindow;
                         IFunc      : InitFunc;
                         PProc      : ProcessProc;
                         CProc      : CloseProc;
                         OkFunc     : OkToCloseFunc;
                         var CP     : CommandProcessor
                        ) : Boolean;
        {-Add a window to the window manager's list}
      function ActivateWindow(Which : Byte; Msg : string) : Boolean; Virtual;
        {-Activate the specified window}
      procedure DeactivateWindow(Which : Byte; EraseFirst : Boolean);
        {-Deactivate the specified window}
      function WindowIsActive(Which : Byte) : Boolean;
        {-Return True if the specified window is active}
      procedure ProcessCommands(var Cmd : Word);
        {-Process the commands for the current window}
      function ProcessExitCommands(var Cmd : Word) : Boolean;
        {-Process standard exit commands for the current window}
      function ProcessExitCommandsPrim(CWP : CommandWindowPtr;
                                       var Cmd : Word) : Boolean;
        {-Process standard exit commands for the current window}
      function OkToCloseWindow(Which : Byte) : Boolean;
        {-OK to close specified window?}
      function OkToQuit : Boolean;
        {-Return True if OK to quit the program}
      {$IFDEF UseMouse}
      function WindowClickedOn : Pointer;
        {-Returns pointer to window that mouse was on when button was clicked}
      {$ENDIF}
      procedure SetCommandList(var Cmds);
      function GetFromCommandList(var Cmd : Word) : Boolean;
      procedure DoHelp(CmdWinPtr : CommandWindowPtr); Virtual;
      {++++ used internally ++++}
      procedure CalcCoordinates(WNum : Byte; var X1, Y1, X2, Y2 : Byte); Virtual;
      {$IFDEF UseMouse}
      procedure SelectWindow(var Cmd : Word);
      {$ENDIF}
      procedure ChangeHeaderColors(Which : Byte; Activating : Boolean;
                                   UpdateScreen : Boolean);
    end;
  {.F+}

var
  BackgroundHook : procedure;
  uiErrorMessage : ErrorMsgFunc;

procedure FlushKeyboard;
  {-Flush the keyboard buffer}

function GetKey : Word;
  {-Return a key or mouse button}

procedure ClearStatusLine;
  {-Clear the status line}

procedure Message(Msg : string; Centered : Boolean);
  {-Display a message on the status line}

procedure TempMessage(Msg : String; MsToWait : Word);
  {-Displays a centered message and waits MsToWait milliseconds}

procedure ErrorMessage(Msg : string; RingIt : Boolean);
  {-Display an error message on the status line}

procedure InsufficientMemory;
  {-Display an "insufficient memory" error message}

procedure ShowAvailableMemory;
  {-Show available memory}

function ToggleZoom(var CW : CommandWindow) : Boolean;
  {-Toggle zoom status of a window. Returns False if there's insufficient
    memory.}

function KeyboardMove(var CW : CommandWindow) : Boolean;
  {-Move a window using the keyboard. Returns False if there's insufficient
    memory.}

function KeyboardResize(var CW : CommandWindow) : Boolean;
  {-Resize a window using the keyboard. Returns False if there's insufficient
    memory.}

procedure ClearWholeScreen;
  {-Clear the screen before drawing any windows}

{$IFDEF UseMouse}

procedure ReinitMouse;
  {-Reinitialize mouse}

function HandleMouseSelection(var CW : CommandWindow; var Cmd : Word) : Boolean;
  {-Process a mouse selection within a stacked window}

{$ENDIF}

procedure InitCommandProcessor(var CP : CommandProcessor);
  {-Initialize a command processor (add hot keys, enable mouse support)}

procedure ChangeTitle(var CW : CommandWindow; Title : string);
  {-Change the title for the specified window}

procedure CustomizeWindow(var CW : CommandWindow; Title : string; TWidth : Byte);
  {-Customize a window (add title, scroll bars, etc.). TWidth is maximum
    width of title header.}

procedure CustomizeWindowWithColors(var CW : CommandWindow;
                                    Title : string; TWidth : Byte;
                                    var Colors : ColorSet);
  {-Customize a window (add title, scroll bars, etc.). TWidth is maximum
    width of title header.}

procedure CustomizeWindowSimple(var CW : CommandWindow; Title : string; TWidth : Byte);
  {-Customize a window (add title, scroll bars, etc.). TWidth is maximum
    width of title header.}

procedure TpUiErrorProc(UnitCode : Byte; var ErrCode : Word; Msg : string);
  {-Our error handler}

function EditProc(MsgCode : Word; Prompt : string;
                  ForceUp, TrimBlanks : Boolean;
                  MaxLen : Byte; var S : string) : Boolean;
  {-Our line editing routine}

function YesNoQuit(MsgCode : Word; Prompt : string;
                   Default : Byte; QuitAndAll : Boolean) : Byte;
  {-Get a response to a yes-no question. Allow Quit or All if requested.}

function YesNo(Prompt : string; Default : Char;
               var Escaped : Boolean) : Boolean;
  {-Get a response to a yes-no question}

function ConfirmCreateFile : Boolean;
  {-Confirm that user wants to create a file}

function GetFile(MsgCode : Word; Prompt : string;
                 ForceUp, TrimBlanks, Writing, MustExist : Boolean;
                 MaxLen : Byte; DefExt : ExtStr;
                 var S : string) : Boolean;
  {-Get a filename from the user; assume DefExt as extension}

function SaveStatusLine(var P : Pointer; var CursorXY, CursorSL : Word) : Boolean;
  {-Save the section of the screen beneath the status line}

procedure RestoreStatusLine(var P : Pointer; CursorXY, CursorSL : Word);
  {-Restore the section of the screen beneath the status line}

  {========================================================================}

implementation

  procedure FlushKeyboard;
    {-Flush the keyboard buffer}
  var
    I : Word;
  begin
    {$IFDEF UseMouse}
    while KeyOrButtonPressed do
      I := ReadKeyOrButton;
    {$ELSE}
    while KeyPressed do
      I := ReadKeyWord;
    {$ENDIF}
  end;

  function GetKey : Word;
    {-Return a key or mouse button}
  begin
    {$IFDEF UseMouse}
      GetKey := ReadKeyOrButton;
    {$ELSE}
      GetKey := ReadKeyWord;
    {$ENDIF}
  end;

  procedure ClearStatusLine;
    {-Clear the status line}
  {$IFDEF UseMouse}
  var
    SaveMouse : Boolean;
  {$ENDIF}
  begin
    {$IFDEF UseMouse}
    HideMousePrim(SaveMouse);
    {$ENDIF}

    FastFill(ScreenWidth, ' ', StatusRow, 1, ColorMono(StatusColor, StatusMono));

    {$IFDEF UseMouse}
    ShowMousePrim(SaveMouse);
    {$ENDIF}
  end;

  procedure Message(Msg : string; Centered : Boolean);
    {-Display a message on the status line}
  {$IFDEF UseMouse}
  var
    SaveMouse : Boolean;
  {$ENDIF}
  begin
    if Centered then
      Msg := Center(Msg, ScreenWidth)
    else
      Msg := Pad(Msg, ScreenWidth);

    {$IFDEF UseMouse}
    HideMousePrim(SaveMouse);
    {$ENDIF}

    FastWrite(Msg, StatusRow, 1, ColorMono(StatusColor, StatusMono));

    {$IFDEF UseMouse}
    ShowMousePrim(SaveMouse);
    {$ENDIF}
  end;

  function SaveStatusLine(var P : Pointer; var CursorXY, CursorSL : Word) : Boolean;
    {-Save the section of the screen beneath the status line}
  begin
    P := nil;
    GetCursorState(CursorXY, CursorSL);
    SaveStatusLine := SaveWindow(1, StatusRow, ScreenWidth, StatusRow, True, P);
  end;

  procedure RestoreStatusLine(var P : Pointer; CursorXY, CursorSL : Word);
    {-Restore the section of the screen beneath the status line}
  begin
    {Restore cursor position and shape}
    RestoreCursorState(CursorXY, CursorSL);

    {restore status line}
    if P <> nil then
      RestoreWindow(1, StatusRow, ScreenWidth, StatusRow, True, P);
  end;

  procedure TempMessage(Msg : String; MsToWait : Word);
  var
    P : Pointer;
    XY, SL : Word;
  begin
    if not SaveStatusLine(P, XY, SL) then Exit;
    Message(Msg, True);
    Delay(MsToWait);
    RestoreStatusLine(P, XY, SL);
  end;

  procedure ErrorMessage(Msg : string; RingIt : Boolean);
    {-Display an error message on the status line}
  const
    PressKeyMsg = '. Press any key...';
  var
    I, CursorXY, CursorSL : Word;
    P : Pointer;
  begin
    {try to save the status line}
    if not SaveStatusLine(P, CursorXY, CursorSL) then begin
      RingBell;
      Exit;
    end;

    {add to default message, if possible}
    if Length(Msg) <= ScreenWidth-(Length(PressKeyMsg)+2) then
      Msg := ' '+Msg+PressKeyMsg
    else if Length(Msg) >= ScreenWidth then
      Msg[0] := Char(ScreenWidth-1);

    {Position cursor and make sure it's visible}
    GotoXYabs(Length(Msg)+1, StatusRow);
    NormalCursor;

    {display error message and ring bell}
    Message(Msg, False);
    if RingIt then
      RingBell;

    {flush keyboard buffer}
    FlushKeyboard;

    {wait for keypress}
    I := EditCommands.cpGetKey;

    {restore status line}
    RestoreStatusLine(P, CursorXY, CursorSL);
  end;


{$IFNDEF DPMI}

  function FreeListUsage : Word;
    {-Returns amount of free list space in use}
{$IFDEF Heap6}
  type
    PFreeRec = ^TFreeRec;
    TFreeRec = record
                 Next : PFreeRec;
                 Size : Pointer;
               end;
  var
    PF : PFreeRec;
    Size : LongInt;
{$ENDIF}
  begin
{$IFDEF Heap6}
    Size := 0;
    PF := FreeList;
    while PF <> HeapPtr do begin
      inc(Size, 8);
      PF := PF^.Next;
    end;
    FreeListUsage := Size;
{$ELSE}
    with OS(FreePtr) do
       if O = 0 then
         FreeListUsage := 0
       else
         FreeListUsage := $10000-O;
{$ENDIF}
  end;

  procedure ShowAvailableMemory;
    {-Show available memory}
  var
    S : string[80];
  begin
    S := 'MemAvail = '+Long2Str(MemAvail);
    S := S+', MaxAvail = '+Long2Str(MaxAvail);
    S := S+', FreeList = '+Long2Str(FreeListUsage);
    ErrorMessage(S, False);
  end;
{$ELSE}
  procedure ShowAvailableMemory;
    {-Show available memory}
  var
    S : string[80];
  begin
    S := 'MemAvail = '+Long2Str(MemAvail);
    S := S+', MaxAvail = '+Long2Str(MaxAvail);
    ErrorMessage(S, False);
  end;
{$ENDIF}

  procedure InsufficientMemory;
    {-Display an "insufficient memory" error message}
  begin
    ErrorMessage(emInsufficientMemory, True);
  end;

  function oouiErrorMessage(ErrorCode : Word) : String;
  begin
    oouiErrorMessage := 'internal error ' + Long2Str(ErrorCode);
  end;

  procedure TpUiErrorProc(UnitCode : Byte; var ErrCode : Word; Msg : string);
    {-Our error handler}
  var
    SaveSeg, SaveWidth : Word;
  begin
    {make sure we're writing to the physical screen. Note that this is
     necessary only because DESKPOP sometimes executes editor and browser
     commands while a virtual screen is active.}
    SaveSeg := VirtualSegment;
    SaveWidth := VirtualWidth;
    VirtualSegment := VideoSegment;
    VirtualWidth := ScreenWidth;

    {make sure there's a message}
    if Msg = '' then
      if ErrCode = ecOutOfMemory then
        Msg := emInsufficientMemory
      else
        Msg := uiErrorMessage(ErrCode);

    {display the error message}
    ErrorMessage(Msg, True);

    {switch back to virtual screen if appropriate}
    VirtualSegment := SaveSeg;
    VirtualWidth := SaveWidth;
  end;

  function EditProc(MsgCode : Word; Prompt : string;
                    ForceUp : Boolean;
                    TrimBlanks : Boolean;
                    MaxLen : Byte;
                    var S : string) : Boolean;
    {-Our line editing routine}
  var
    LE : LineEditor;
    Width : Byte;
    CursorXY, CursorSL : Word;
    P : Pointer;
  begin
    {try to save the status line}
    if not SaveStatusLine(P, CursorXY, CursorSL) then begin
      RingBell;
      EditProc := False;
      Exit;
    end;

    with LE do begin
      ClearStatusLine;
      Init(TpUiColors);
      if ForceUp then
        leEditOptionsOn(leForceUpper)
      else
        leEditOptionsOff(leForceUpper);
      if TrimBlanks then
        leEditOptionsOn(leTrimBlanks)
      else
        leEditOptionsOff(leTrimBlanks);
      Prompt := ' '+Prompt;
      if Length(Prompt)+MaxLen > ScreenWidth then
        Width := ScreenWidth-Length(Prompt)-1
      else
        Width := MaxLen;
      ReadString(Prompt, StatusRow, 1, MaxLen, Width, S);
      EditProc := (GetLastCommand <> ccQuit);
    end;

    {restore status line}
    RestoreStatusLine(P, CursorXY, CursorSL);
  end;

  function YesNoQuit(MsgCode : Word; Prompt : string; Default : Byte; QuitAndAll : Boolean) : Byte;
    {-Get a response to a yes-no question. Allow Quit or All if requested.}
  var
    LE : LineEditor;
    CursorXY, CursorSL : Word;
    P : Pointer;
    Ch : Char;
    CharsToTake : CharSet;
  begin
    if not SaveStatusLine(P, CursorXY, CursorSL) then begin
      YesNoQuit := Default;
      Exit;
    end;

    with LE do begin
      ClearStatusLine;
      Init(TpUiColors);
      leEditOptionsOn(leAllowEscape+leDefaultAccepted+leForceUpper);
      if Default = 1 {teYes} then
        Ch := 'Y'
      else
        Ch := 'N';
      Prompt := ' '+Prompt;
      if QuitAndAll then begin
        CharsToTake := ['Y', 'N', 'A', 'Q'];
        Prompt := Prompt+' (Y/N/A/Q)'
      end
      else
        CharsToTake := ['Y', 'N'];
      ReadChar(Prompt, StatusRow, 1, CharsToTake, Ch);
      if GetLastCommand = ccQuit then
        YesNoQuit := 2 {teQuit}
      else case Ch of
        'N' : YesNoQuit := 0 {teNo} ;
        'Y' : YesNoQuit := 1 {teYes} ;
        'Q' : YesNoQuit := 2 {teQuit} ;
        'A' : YesNoQuit := 3 {teAll} ;
      end;
    end;

    {restore status line}
    RestoreStatusLine(P, CursorXY, CursorSL);
  end;

  function YesNo(Prompt : string; Default : Char; var Escaped : Boolean) : Boolean;
    {-Get a response to a yes-no question}
  var
    B : Byte;
  begin
    B := YesNoQuit(0, Prompt, Ord(Default = 'Y'), False);
    YesNo := (B = 1);
    Escaped := (B = 2);
  end;

  function ConfirmCreateFile : Boolean;
    {-Confirm that user wants to create a file}
  var
    Esc : Boolean;
  begin
    ConfirmCreateFile := YesNo('File does not exist. Create it?', 'Y', Esc);
  end;

  function GetFileByList(var S : String) : Byte;
    {-Let the user choose a filename from a list}
  var
    DL : DirList;
    Status, O : Word;
  begin
    GetFileByList := 0;

    with DL do begin
      {initialize the directory list}
      O := DefWindowOptions and not wAllMouseEvents;
      if not InitCustom(
        15, 5, 66, 20, TpUiColors, O, 16 * 1024, PickSnaking, SingleFile) then
          Exit;
      SetHelpIndex(DirHelpIndex);
      {add headers, hot spots, etc.}
      CustomizeWindow(DL, '', 0);

      {set basic options}
      SetCursor(cuHidden);
      diOptionsOn(diOptimizeSize+diExitIfOne);
      pkOptionsOn(pkDrawActive+pkMousePage);

      {set display options}
      SetPadSize(1, 1);

      {set format, sort, search options}
      SetNameFormat;
      SetSortOrder(SortDirName);
      SetSearchMode(PickCharSearch);

      {add header}
      AddMaskHeader(True, 1, 40, heTC);

      {customize colors}
      SetPickAttr(pkNormal, False, DirItemColor, DirItemMono);

      {$IFDEF UseMouse}
      if (MouseInstalled) and (not cwCmdPtr^.cpOptionsAreOn(cpEnableMouse)) then
        cwCmdPtr^.cpOptionsOn(cpEnableMouse);
      {$ENDIF}

      {get a filename}
      Status := GetFileName(S, Directory, S);
      case Status mod 10000 of
        0 : GetFileByList := 1;
        ecFileNotFound : GetFileByList := 2;
        ecNoPickSelection : ; {No selection made}
        ecOutOfMemory : InsufficientMemory;
        ecNoMoreFiles : ErrorMessage(emNoMoreFiles, True);
        ecPathNotFound : ErrorMessage(emPathNotFound, True);
        else ErrorMessage('Error '+Long2Str(Status)+' getting filename', True);
      end;

      {deallocate}
      Done;
    end;
  end;

  function GetFile(MsgCode : Word; Prompt : string;
                   ForceUp, TrimBlanks, Writing, MustExist : Boolean;
                   MaxLen : Byte; DefExt : ExtStr;
                   var S : string) : Boolean;
    {-Get a filename from the user; assume DefExt as extension}
  var
    Escaped : Boolean;
    St : String;
    CPos : Byte;
  begin
    GetFile := False;

    {add default extension to prompt, if any}
    CPos := Pos(':', Prompt);
    if (CPos <> 0) and (DefExt <> '') then
      Insert(' [.'+DefExt+']', Prompt, CPos);

    if S <> '' then
      St := S
    else if DefExt = '' then
      St := '*.*'
    else
      St := '*.'+DefExt;

    if not EditProc(MsgCode, Prompt, ForceUp, TrimBlanks, MaxLen, St) then
      Exit;

    if St <> '' then
      St := DefaultExtension(St, DefExt);
    case GetFileByList(St) of
      0 : Exit;
      1 : if Writing then
            if not YesNo('File exists. Overwrite it?', 'N', Escaped) then
              Exit;
      2 : if MustExist then begin
            ErrorMessage(emFileNotFound, True);
            Exit;
          end;
    end;
    S := St;
    GetFile := True;
  end;

  function ToggleZoom(var CW : CommandWindow) : Boolean;
    {-Toggle zoom status of a window. Returns False if there's insufficient
      memory.}
  begin
    with CW do begin
      if IsZoomed then
        Unzoom
      else
        Zoom;

      if ClassifyError(GetLastError) = etFatal then begin
        {InsufficientMemory;}
        ToggleZoom := False;
      end
      else
        ToggleZoom := True;
    end;
  end;

  function KeyboardMove(var CW : CommandWindow) : Boolean;
    {-Move a window using the keyboard. Returns False if there's insufficient
      memory.}
  var
    AllDone : Boolean;
  begin
    KeyboardMove := True;
    Message(' Use cursor keys to move, <Enter> to accept', True);
    AllDone := False;
    with CW do
      repeat
        case cwCmdPtr^.cpGetKey of
          $4700 : MoveWindow(-Step, -Step); {Home}
          $4800 : MoveWindow(0, -Step);     {Up arrow}
          $4900 : MoveWindow(Step, -Step);  {PgUp}
          $4B00 : MoveWindow(-Step, 0);     {Left Arrow}
          $4D00 : MoveWindow(Step, 0);      {Right Arrow}
          $4F00 : MoveWindow(-Step, Step);  {End}
          $5000 : MoveWindow(0, Step);      {Down arrow}
          $5100 : MoveWindow(Step, Step);   {PgDn}
          $1C0D : AllDone := True;          {Enter}
        end;

        if ClassifyError(GetLastError) = etFatal then begin
          {InsufficientMemory;}
          KeyboardMove := False;
          AllDone := True;
        end;
        ClearErrors;
      until AllDone;
    ClearStatusLine;
  end;

  function KeyboardResize(var CW : CommandWindow) : Boolean;
    {-Resize a window using the keyboard. Returns False if there's insufficient
      memory.}
  var
    AllDone : Boolean;
  begin
    KeyboardResize := True;
    Message(' Use cursor keys to resize, <Enter> to accept', True);
    AllDone := False;
    with CW do
      repeat
        case cwCmdPtr^.cpGetKey of
          $4700 : ResizeWindow(-Step, -Step); {Home}
          $4800 : ResizeWindow(0, -Step);     {Up}
          $4900 : ResizeWindow(Step, -Step);  {PgUp}
          $4B00 : ResizeWindow(-Step, 0);     {Left}
          $4D00 : ResizeWindow(Step, 0);      {Right}
          $4F00 : ResizeWindow(-Step, Step);  {End}
          $5000 : ResizeWindow(0, Step);      {Down}
          $5100 : ResizeWindow(Step, Step);   {PgDn}
          $1C0D : AllDone := True;            {Enter}
        end;

        if ClassifyError(GetLastError) = etFatal then begin
          {InsufficientMemory;}
          KeyboardResize := False;
          AllDone := True;
        end;
        ClearErrors;
      until AllDone;
    ClearStatusLine;
  end;

  function Delta(I : Integer) : Integer;
    {-Force I to the range -1..1}
  begin
    if I < -4 then
      Delta := -1
    else if I > 4 then
      Delta := 1
    else
      Delta := 0;
  end;

  procedure ClearWholeScreen;
    {-Clear the screen before drawing any windows}
  begin
    {$IFDEF UseMouse}
    HideMouse;
    {$ENDIF}

    {clear the entire screen}
    ClearWindow(1, 1, VirtualWidth, ScreenHeight, BackdropChar, BackdropAttr);

    {$IFDEF UseMouse}
    ShowMouse;
    {$ENDIF}

    {clear the status line too}
    ClearStatusLine;
  end;

  {$IFDEF UseMouse}

  procedure ReinitMouse;
    {-Initialize mouse}
  begin
    if MouseInstalled then begin
      InitializeMouse;
      FullMouseWindow;
      with TpUiColors do
        SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+$04);
    end;
  end;

  function HandleMouseSelection(var CW : CommandWindow; var Cmd : Word) : Boolean;
    {-Process a mouse selection within a stacked window}
  const
    DragMsg   = 'Drag window to new location, then click left mouse button';
    ResizeMsg = 'Move mouse to resize window, then click left mouse button';
  var
    Clicked : Boolean;
    FP : FramePosType;
    HC : Byte;
    BP : LongInt;
    XAbs : Byte;
    YAbs : Byte;
    MicH : Integer;
    MicV : Integer;
  begin
    Cmd := ccNone;
    HandleMouseSelection := True;
    with CW do begin
      {get absolute mouse coordinates}
      XAbs := MouseKeyWordX+MouseXLo;
      YAbs := MouseKeyWordY+MouseYLo;

      {evaluate mouse position}
      EvaluatePos(XAbs, YAbs);
      BP := PosResults(FP, HC);

      case FP of
        frInsideFrame,       {inside window frame but not in window boundaries}
        frOutsideFrame :     {outside window frame}
          Cmd := SelectWindowCmd;
        else
          case HC of
            hsRegion0 : {Move}
              if not IsZoomed then begin
                Message(DragMsg, True);
                HideMouse;
                Dec(XAbs, wFrame.frXL);
                Dec(YAbs, wFrame.frYL);
                GetMickeyCount(MicH, MicV);
                repeat
                  if @BackgroundHook <> Nil then
                    BackgroundHook;
                  GetMickeyCount(MicH, MicV);
                  MoveWindow(Delta(MicH), Delta(MicV));
                  if ClassifyError(GetLastError) = etFatal then begin
                    InsufficientMemory;
                    HandleMouseSelection := False;
                  end;
                  if MousePressed then
                    Clicked := (MouseKeyWord = MouseLft)
                  else
                    Clicked := False;
                until Clicked;
                Inc(XAbs, wFrame.frXL);
                Inc(YAbs, wFrame.frYL);
                MouseGoToXY(XAbs, YAbs);
                ClearStatusLine;
                ShowMouse;
              end;

            hsRegion1 : {Local menu}
              Cmd := LocalMenuCmd;

            hsRegion2 : {Zoom}
              if wOptionsAreOn(wResizeable) then
                HandleMouseSelection := ToggleZoom(CW);

            hsRegion3 : {Resize}
              if wOptionsAreOn(wResizeable) and not IsZoomed then begin
                Message(ResizeMsg, True);
                HideMouse;
                GetMickeyCount(MicH, MicV);
                repeat
                  if @BackgroundHook <> Nil then
                    BackgroundHook;
                  GetMickeyCount(MicH, MicV);
                  ResizeWindow(Delta(MicH), Delta(MicV));
                  if ClassifyError(GetLastError) = etFatal then begin
                    InsufficientMemory;
                    HandleMouseSelection := False;
                  end;
                  if MousePressed then
                    Clicked := (MouseKeyWord = MouseLft)
                  else
                    Clicked := False;
                until Clicked;
                MouseGoToXY(wFrame.frXH, wFrame.frYH);
                ClearStatusLine;
                ShowMouse;
              end;
          end;
      end;
    end;
  end;

  {$ENDIF}

  procedure InitCommandProcessor(var CP : CommandProcessor);
    {-Initialize a command processor (add hot keys, enable mouse support)}
  begin
    {install exit commands}
    CP.SetSecondaryKeyPtr(@TpUiKeySet, TpUiKeyMax);

    {$IFDEF UseMouse}
    {enable mouse support}
    if MouseInstalled and (not CP.cpOptionsAreOn(cpEnableMouse)) then
      CP.cpOptionsOn(cpEnableMouse);
    {$ENDIF}
  end;

  procedure ChangeTitle(var CW : CommandWindow; Title : string);
    {-Change the title for the specified window}
  begin
    with CW, wFrame, udMap(wUserData) do begin
      Title := ' '+Title+' ';

      {low word of wUserData has the # of the title header}
      ChangeHeader(udmTitle, Title);
      ChangeHotHeader(udmTitleHotSpot, Length(Title));
    end;
  end;

  procedure TpUiStackProc(WP : WindowPtr);
    {-Called each time the window stack is altered}
  var
    S1 : string[1];
    Redraw : Boolean;
  begin
    with WP^, wFrame, udMap(wUserData) do begin
      {convert window number to a string}
      S1[0] := #1;
      S1[1] := Char(Ord(wNumber)+Ord('0'));

      {high word of wUserData has the # of the window number header}
      ChangeHeaderString(udmWinNum, S1, Redraw);
    end;
  end;

  procedure CustomizeWindow(var CW : CommandWindow; Title : string; TWidth : Byte);
    {-Customize a window (add title, scroll bars, etc.)}
  var
    MW : Word;
  begin
    with CW, wFrame, TpUiColors, udMap(wUserData) do begin
      if wOptionsAreOn(wUserContents) then
        wOptionsOff(wSaveContents);

      {set limits for window coordinates}
      SetPosLimits(1, 2, ScreenWidth, ScreenHeight-1);

      if wOptionsAreOn(wResizeable) then begin
        {set resizing limits, accounting for hot spots}
        MW := MaxWord(wMinW, MinWord(TWidth+12, Width));
        SetSizeLimits(MW, wMinH, wMaxW, wMaxH);
      end;

      {specify shadow type}
      AddShadow(shBR, shSeeThru);

      if wOptionsAreOn(wResizeable) then begin
        {add scroll bars}
        AddCustomScrollBar(
          frBB, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, TpUiColors);
        AddCustomScrollBar(
          frRR, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, TpUiColors);
      end;

      {install default error handler}
      SetErrorProc(TpUiErrorProc);

      if TWidth = 0 then
        Exit;

      {make the window explode}
      EnableExplosions(8);

      {install stack proc}
      SetStackProc(TpUiStackProc);

      {add title header and save the number}
      if Title <> '' then begin
        Title := ' '+Title+' ';
        AddHeader(Title, heTC);
        udmTitle := GetLastHeaderIndex;
        AddHotHeader(heTC, hsRegion0, Length(Title));                  {Move}
        udmTitleHotSpot := GetLastHotIndex;
      end;

      {add window number/local menu button}
      if TWidth <> 0 then begin
        AddCustomHeader('¸',  frTL,   +2, +0, FrameColor, FrameMono);
        AddCustomHeader('#',  frTL,   +3, +0, HotSpotColor, HotSpotMono);
        udmWinNum := GetLastHeaderIndex;
        AddCustomHeader('Õ',  frTL,   +4, +0, FrameColor, FrameMono);
        AddHotRegion(frTL, hsRegion1, +3, +0, 1, 1);               {Local menu}
      end;

      if wOptionsAreOn(wResizeable) then begin
        {add zoom button}
        AddCustomHeader('¸',  frTR,   -4, +0, FrameColor, FrameMono);
        AddCustomHeader(^R,   frTR,   -3, +0, HotSpotColor, HotSpotMono);
        AddCustomHeader('Õ',  frTR,   -2, +0, FrameColor, FrameMono);
        AddHotRegion(frTR, hsRegion2, -3, +0, 1, 1);                   {Zoom}

        {add resize button}
        AddCustomHeader('+',  frBR,   +0, +0, FrameColor, FrameMono);
        AddHotRegion(frBR, hsRegion3, +0, +0, 1, 1);                 {Resize}
      end;
    end;
  end;

procedure CustomizeWindowSimple(var CW : CommandWindow; Title : string; TWidth : Byte);
    {-Customize a window (add title, scroll bars, etc.)}
  var
    MW : Word;
  begin
    with CW, wFrame, TpUiColors, udMap(wUserData) do begin
      {set limits for window coordinates}
      SetPosLimits(1, 2, ScreenWidth, ScreenHeight-1);

      if wOptionsAreOn(wResizeable) then begin
        {set resizing limits, accounting for hot spots}
        MW := MaxWord(wMinW, MinWord(TWidth+12, Width));
        SetSizeLimits(MW, wMinH, wMaxW, wMaxH);
      end;

      {specify shadow type}
      AddShadow(shBR, shSeeThru);

      if wOptionsAreOn(wResizeable) then begin
        {add scroll bars}
        AddCustomScrollBar(
          frBB, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, TpUiColors);
        AddCustomScrollBar(
          frRR, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, TpUiColors);
      end;

      {install default error handler}
      SetErrorProc(TpUiErrorProc);

      if TWidth = 0 then
        Exit;

      {make the window explode}
      EnableExplosions(8);

      {add title header and save the number}
      if Title <> '' then begin
        Title := ' '+Title+' ';
        AddHeader(Title, heTC);
        udmTitle := GetLastHeaderIndex;
        AddHotHeader(heTC, hsRegion0, Length(Title));                  {Move}
        udmTitleHotSpot := GetLastHotIndex;
      end;

      {add window number/local menu button}
      if TWidth <> 0 then begin
        AddCustomHeader('¸',  frTL,   +2, +0, FrameColor, FrameMono);
        AddCustomHeader('#',  frTL,   +3, +0, HotSpotColor, HotSpotMono);
        udmWinNum := GetLastHeaderIndex;
        AddCustomHeader('Õ',  frTL,   +4, +0, FrameColor, FrameMono);
        AddHotRegion(frTL, hsRegion1, +3, +0, 1, 1);               {Local menu}
      end;

      if wOptionsAreOn(wResizeable) then begin
        {add zoom button}
        AddCustomHeader('¸',  frTR,   -4, +0, FrameColor, FrameMono);
        AddCustomHeader(^R,   frTR,   -3, +0, HotSpotColor, HotSpotMono);
        AddCustomHeader('Õ',  frTR,   -2, +0, FrameColor, FrameMono);
        AddHotRegion(frTR, hsRegion2, -3, +0, 1, 1);                   {Zoom}

        {add resize button}
        AddCustomHeader('+',  frBR,   +0, +0, FrameColor, FrameMono);
        AddHotRegion(frBR, hsRegion3, +0, +0, 1, 1);                 {Resize}
      end;
    end;
  end;

procedure CustomizeWindowWithColors(var CW : CommandWindow;
                                    Title : string; TWidth : Byte;
                                    var Colors : ColorSet);
    {-Customize a window (add title, scroll bars, etc.)}
  var
    MW : Word;
  begin
    with CW, wFrame, Colors, udMap(wUserData) do begin
      if wOptionsAreOn(wUserContents) then
        wOptionsOff(wSaveContents);

      {set limits for window coordinates}
      SetPosLimits(1, 2, ScreenWidth, ScreenHeight-1);

      if wOptionsAreOn(wResizeable) then begin
        {set resizing limits, accounting for hot spots}
        MW := MaxWord(wMinW, MinWord(TWidth+12, Width));
        SetSizeLimits(MW, wMinH, wMaxW, wMaxH);
      end;

      {specify shadow type}
      AddShadow(shBR, shSeeThru);

      if wOptionsAreOn(wResizeable) then begin
        {add scroll bars}
        AddCustomScrollBar(
          frBB, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, Colors);
        AddCustomScrollBar(
          frRR, 0, MaxLongInt, 1, 1, SliderChar, ScrollBarChar, Colors);
      end;

      {install default error handler}
      SetErrorProc(TpUiErrorProc);

      if TWidth = 0 then
        Exit;

      {make the window explode}
      EnableExplosions(8);

      {install stack proc}
      SetStackProc(TpUiStackProc);

      {add title header and save the number}
      if Title <> '' then begin
        Title := ' '+Title+' ';
        AddHeader(Title, heTC);
        udmTitle := GetLastHeaderIndex;
        AddHotHeader(heTC, hsRegion0, Length(Title));                  {Move}
        udmTitleHotSpot := GetLastHotIndex;
      end;

      {add window number/local menu button}
      if TWidth <> 0 then begin
        AddCustomHeader('¸',  frTL,   +2, +0, FrameColor, FrameMono);
        AddCustomHeader('#',  frTL,   +3, +0, HotSpotColor, HotSpotMono);
        udmWinNum := GetLastHeaderIndex;
        AddCustomHeader('Õ',  frTL,   +4, +0, FrameColor, FrameMono);
        AddHotRegion(frTL, hsRegion1, +3, +0, 1, 1);               {Local menu}
      end;

      if wOptionsAreOn(wResizeable) then begin
        {add zoom button}
        AddCustomHeader('¸',  frTR,   -4, +0, FrameColor, FrameMono);
        AddCustomHeader(^R,   frTR,   -3, +0, HotSpotColor, HotSpotMono);
        AddCustomHeader('Õ',  frTR,   -2, +0, FrameColor, FrameMono);
        AddHotRegion(frTR, hsRegion2, -3, +0, 1, 1);                   {Zoom}

        {add resize button}
        AddCustomHeader('+',  frBR,   +0, +0, FrameColor, FrameMono);
        AddHotRegion(frBR, hsRegion3, +0, +0, 1, 1);                 {Resize}
      end;
    end;
  end;

  constructor Desktop.Init(X1, Y1, X2, Y2 : Byte; Max : Byte);
    {-Initialize the desktop window manager}
  var
    I : Word;
  begin
    {sufficient memory?}
    I := Max*SizeOf(DesktopWindow);
    if (Max = 0) or not GetMemCheck(dtWindows, I) then
      Fail;

    {initialize window array}
    FillChar(dtWindows^, I, 0);

    {initialize remaining fields}
    dtMax := Max;
    dtCount := 0;
    dtActive := 0;
    dtCurrent := 0;
    dtNew := 0;
    dtFirst := 0;
    dtX1 := X1;
    dtY1 := Y1;
    dtX2 := X2;
    dtY2 := Y2;
    dtCmdIndex := 0;
    dtCmds := Nil;
  end;

  function Desktop.AddWindow(var CW     : CommandWindow;
                             IFunc      : InitFunc;
                             PProc      : ProcessProc;
                             CProc      : CloseProc;
                             OkFunc     : OkToCloseFunc;
                             var CP     : CommandProcessor
                            ) : Boolean;
    {-Add a window to the manager's list}
  begin
    {array already full?}
    if dtCount = dtMax then begin
      AddWindow := False;
      Exit;
    end;

    {increment counter}
    Inc(dtCount);

    with dtWindows^[dtCount] do begin
      {initialize fields}
      dwNext    := 0;
      dwPrev    := 0;
      dwInit    := IFunc;
      dwProcess := PProc;
      dwClose   := CProc;
      dwOK      := OkFunc;
      dwWindow  := @CW;
    end;

    {customize the command processor}
    InitCommandProcessor(CP);

    AddWindow := True;
  end;

  procedure Desktop.CalcCoordinates(WNum : Byte; var X1, Y1, X2, Y2 : Byte);
    {-Calculate the coordinates for the specified window}
  var
    X1Delta, Y1Delta, X2Delta, Y2Delta : ShortInt;
  begin
    Y1Delta := Pred(WNum);
    X1Delta := Y1Delta*2;
    Y2Delta := -Pred(dtCount-WNum);
    X2Delta := Y2Delta*2;

    X1 := dtX1+X1Delta;
    Y1 := dtY1+Y1Delta;
    X2 := dtX2+X2Delta;
    Y2 := dtY2+Y2Delta;
  end;

  procedure Desktop.ChangeHeaderColors(Which : Byte;
                                       Activating : Boolean;
                                       UpdateScreen : Boolean);
    {-Change the color of the header for the specified window}
  var
    Color, Mono : Byte;
  begin
    if (Which = 0) or (Which > dtCount) then
      Exit;

    if Activating then begin
      Color := TpUiColors.HeaderColor;
      Mono := TpUiColors.HeaderMono;
    end
    else begin
      Color := InactiveColor;
      Mono := InactiveMono;
    end;

    with dtWindows^[Which] do
      if dwActive then
        with dwWindow^, udMap(wUserData) do begin
          wFrame.ChangeHeaderAttr(udmTitle, Color, Mono);
          if UpdateScreen then
            wFrame.DrawHeader(udmTitle);
        end;
  end;

  function Desktop.ActivateWindow(Which : Byte; Msg : string) : Boolean;
    {-Activate the specified window, returning True if successful}
  var
    X1, Y1, X2, Y2 : Byte;
  begin
    ActivateWindow := True;
    if (Which = 0) or (Which > dtCount) then
      ActivateWindow := False
    else with dtWindows^[Which], dwWindow^ do
      if dwActive then begin
        if dtWindows^[dtCurrent].dwActive then begin
          ChangeHeaderColors(dtCurrent, False, False);
          ChangeHeaderColors(Which, True, False);
        end
        else
          ChangeHeaderColors(Which, True, True);

        {move it to the top of the stack}
        Select;

        if ClassifyError(GetLastError) = etFatal then begin
          InsufficientMemory;
          dwClose(True);
          ChangeHeaderColors(dtCurrent, True, True);
          ActivateWindow := False;
        end
        else
          dtCurrent := Which
      end
      else begin
        {calculate maximum coordinates for the window}
        CalcCoordinates(wStack.wsFreeNumber, X1, Y1, X2, Y2);

        {try to initialize the window}
        if dwInit(X1, Y1, X2, Y2, Msg) then begin
          ChangeHeaderColors(dtCurrent, False, True);

          {display the window}
          Draw;

          {check for error}
          if ClassifyError(cwGetLastError) = etFatal then begin
            InsufficientMemory;
            dwClose(True);
            ChangeHeaderColors(dtCurrent, True, True);
            ActivateWindow := False;
            Exit;
          end;

          if dtActive = 0 then begin
            dtFirst := Which;
            dwNext := Which;
            dwPrev := Which;
          end
          else begin
            dwPrev := dtCurrent;
            dwNext := dtWindows^[dtCurrent].dwNext;
            dtWindows^[dtCurrent].dwNext := Which;
            dtWindows^[dwNext].dwPrev := Which;
          end;

          dwActive := True;
          Inc(dtActive);
          dtCurrent := Which;
        end
        else
          ActivateWindow := False;
      end;
  end;

  function Desktop.WindowIsActive(Which : Byte) : Boolean;
    {-Return True if the specified window is active}
  begin
    WindowIsActive := dtWindows^[Which].dwActive;
  end;

  procedure Desktop.DeactivateWindow(Which : Byte; EraseFirst : Boolean);
    {-Deactivate the specified window}
  begin
    with dtWindows^[Which] do begin
      {close the window}
      dwClose(EraseFirst);

      dwActive := False;
      Dec(dtActive);
      if dtActive = 0 then begin
        {last window}
        dtFirst := 0;
        dtCurrent := 0;
      end
      else begin
        {switch windows}
        if dtFirst = Which then
          dtFirst := dwNext;

        {remove window from the circular list}
        dtWindows^[dwPrev].dwNext := dwNext;
        dtWindows^[dwNext].dwPrev := dwPrev;
      end;
    end;
  end;

  {$IFDEF UseMouse}

  function Desktop.WindowClickedOn : Pointer;
    {-Returns pointer to window that mouse was on when button was clicked}
  var
    XAbs, YAbs : Integer;
  begin
    {get absolute mouse coordinates}
    XAbs := MouseKeyWordX+MouseXLo;
    YAbs := MouseKeyWordY+MouseYLo;

    {evaluate the position}
    WindowClickedOn := wStack.EvaluateStackPos(XAbs, YAbs);
  end;

  procedure Desktop.SelectWindow(var Cmd : Word);
    {-Select an active window using the mouse}
  var
    WP : Pointer;
    I : Byte;
  begin
    WP := WindowClickedOn;
    if WP = nil then begin
      Cmd := ccNone;
      Exit;
    end;

    {look at all the windows}
    for I := 1 to dtCount do
      with dtWindows^[I] do
        if dwActive and (dwWindow = WP) then
          if ActivateWindow(I, '') then begin
            Cmd := ProcessWindowCmd;
            Exit;
          end;
  end;

  {$ENDIF}

  procedure Desktop.SetCommandList(var Cmds);
  begin
    dtCmds := @Cmds;
    dtCmdIndex := 1;
  end;

  procedure Desktop.DoHelp(CmdWinPtr : CommandWindowPtr);
  begin
  end;

  function Desktop.ProcessExitCommands(var Cmd : Word) : Boolean;
    {-Process standard exit commands}
  begin
    ProcessExitCommands :=
      ProcessExitCommandsPrim(dtWindows^[dtCurrent].dwWindow, Cmd);
  end;

  function Desktop.ProcessExitCommandsPrim(CWP : CommandWindowPtr;
                                           var Cmd : Word) : Boolean;
    {-Process standard exit commands}
  var
    SaveCmd : Word;
    W : Byte;
    I : Word;
  begin
    ProcessExitCommandsPrim := True;
    case Cmd of
      ShowMemoryCmd :
        ShowAvailableMemory;

      MoveWindowCmd :
        if not CWP^.IsZoomed then
          if not KeyboardMove(CWP^) then begin
            Cmd := ccQuit;
            ProcessExitCommandsPrim := False;
          end;
      ResizeWindowCmd :
        if CWP^.wOptionsAreOn(wResizeable) and not CWP^.IsZoomed then
          if not KeyboardResize(CWP^) then begin
            Cmd := ccQuit;
            ProcessExitCommandsPrim := False;
          end;
      ZoomWindowCmd :
        if CWP^.wOptionsAreOn(wResizeable) then
          if not ToggleZoom(CWP^) then begin
            Cmd := ccQuit;
            ProcessExitCommandsPrim := False;
          end;
      SelectWindow1..SelectWindow8 :
        begin
          {calculate the on-screen window number}
          W := Succ(Cmd-SelectWindow1);

          {scan list of windows looking for a match}
          for I := 1 to dtCount do
            with dtWindows^[I] do
              if dwActive and (dwWindow^.wNumber = W) then begin
                {is it already the current window?}
                if (dwWindow = CommandWindowPtr(CurrentWindow)) then
                  {if so, do nothing}
                  Cmd := ccNone
                else begin
                  {save number of window to switch to}
                  dtNew := I;
                  ProcessExitCommandsPrim := False;
                end;
                Exit;
              end;

            {window is not active}
            Cmd := ccNone;
        end;
      {$IFDEF UseMouse}
      ccMouseSel :
        begin
          SaveCmd := Cmd;
          if not HandleMouseSelection(CWP^, Cmd) then begin
            Cmd := ccQuit;
            ProcessExitCommandsPrim := False;
          end
          else
            ProcessExitCommandsPrim := (SaveCmd = Cmd);
        end;
      {$ENDIF}
      else
        ProcessExitCommandsPrim := False;
    end;
  end;

  function Desktop.GetFromCommandList(var Cmd : Word) : Boolean;
  var
    Command : Word;
  begin
    GetFromCommandList := False;
    if dtCmds <> Nil then begin
      Command := dtCmds^[dtCmdIndex];
      if Command = ccNone then begin
        dtCmds := Nil;
        dtCmdIndex := 0;
      end
      else begin
        Inc(dtCmdIndex);
        Cmd := Command;
        GetFromCommandList := True;
      end;
    end;
  end;

  procedure Desktop.ProcessCommands(var Cmd : Word);
    {-Process the commands for the current window}
  label
    ProcessCmd, Autopilot;
  var
    AllDone, GotCommand : Boolean;
    FakeCmd : Word;
  begin
    AllDone := False;
    GotCommand := GetFromCommandList(Cmd);

AutoPilot:
    {default to main menu if no windows open}
    if (dtActive = 0) and (not GotCommand) then
      Cmd := MainMenuCmd;

    if Cmd <> ProcessWindowCmd then
      goto ProcessCmd;

    repeat

      with dtWindows^[dtCurrent] do begin
        {move the current window to the top of the stack}
        dwWindow^.Select;

        {process the current window}
        dwProcess(Cmd);
      end;

ProcessCmd:
      if GotCommand then
        GotCommand := False
      else
        if GetFromCommandList(Cmd) then begin
          GotCommand := True;
          goto AutoPilot;
        end;

      with dtWindows^[dtCurrent] do
        case Cmd of
          ccError,
          ccQuit :                {current window is now closed}
            begin
              {deactivate the window}
              DeactivateWindow(dtCurrent, True);
              GotCommand := GetFromCommandList(Cmd);
              if not GotCommand then begin
                if dtActive = 0 then begin
                  {no windows open--go to main menu}
                  Cmd := MainMenuCmd;
                  AllDone := True;
                end
                {try to switch to previous window}
                else if not ActivateWindow(dwPrev, '') then begin
                  {shouldn't happen--close the previous window too}
                  dtCurrent := dwPrev;
                  goto ProcessCmd;
                end;
              end
              else
                goto ProcessCmd;
            end;

          {$IFDEF UseMouse}
          SelectWindowCmd :
            begin
              {select a window the user clicked on}
              SelectWindow(Cmd);
              AllDone := (Cmd <> ccNone);
            end;
          {$ENDIF}
          SelectWindow1..SelectWindow8 :
            {try to switch windows}
            if not ActivateWindow(dtNew, '') then begin
              {shouldn't happen--close window and try again}
              DeactivateWindow(dtNew, True);
              goto ProcessCmd;
            end;

          NextWindowCmd :      {switch to next window}
            begin
              if (dtActive = 0) then begin
                {no windows open--stay in main menu}
                Cmd := MainMenuCmd;
                AllDone := True;
              end
              {try to switch windows}
              else if not ActivateWindow(dwNext, '') then begin
                {shouldn't happen--close next window and try again}
                DeactivateWindow(dwNext, True);
                goto ProcessCmd;
              end;
            end;
          PrevWindowCmd :      {switch to previous window}
            if dtActive = 0 then begin
              {no windows open--stay in main menu}
              Cmd := MainMenuCmd;
              AllDone := True;
            end
            {try to switch windows}
            else if not ActivateWindow(dwPrev, '') then begin
              {shouldn't happen--close next window and try again}
              DeactivateWindow(dwPrev, True);
              goto ProcessCmd;
            end;

          ExitProgramCmd,
          MainMenuCmd :
            AllDone := True;
          SelectSpecial :
            begin
              FakeCmd := dtCmds^[dtCmdIndex];
              Inc(dtCmdIndex);
              if ActivateWindow(Byte(FakeCmd), '') then
                Cmd := ProcessWindowCmd
              else
                Cmd := MainMenuCmd;

            end;
        end;
    until AllDone;
  end;

  function Desktop.OkToCloseWindow(Which : Byte) : Boolean;
    {-OK to close specified window?}
  begin
    with dtWindows^[Which] do
      OkToCloseWindow := dwActive and dwOK;
  end;

  function Desktop.OkToQuit : Boolean;
    {-Return True if OK to quit the program}
  var
    I : Byte;
  begin
    OkToQuit := False;

    {check all open windows}
    for I := 1 to dtCount do
      with dtWindows^[I] do
        if dwActive then
          if not dwOK then
            Exit;

    OkToQuit := True;
  end;

begin
  {smooth scrolling on CGA's}
  BiosScroll := False;

  {break checking off}
  CheckBreak := False;

  {make sure our windows are framed properly}
  DefWindowOptions := wClear+wResizeable+wStoreContents+wBordered+wAllMouseEvents;
  DefWindowFrame   := TpUiFrame;
  DefaultColorSet  := TpUiColors;
  UiErrorMessage   := oouiErrorMessage;
  StatusRow        := ScreenHeight;
  @BackgroundHook  := Nil;
{$IFNDEF Heap6}
  {make sure there's always some room for the free list}
  FreeMin := 128;
{$ENDIF}
end.
