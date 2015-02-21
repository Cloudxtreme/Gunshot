{$I OPDEFINE.INC}
program ExDialer; {EXDIALER.PAS}

uses
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpCmd,
  OpWindow,
  OpFrame,
  OpDialog,
  OoCom,
  OoModDB,
  OoModem2,
  ApMisc,
  ApPort,
  OpCrt,
  OpDialer,
  OpCtrl;

const
  Colors : ColorSet = (
    TextColor       : $70; TextMono        : $70;
    CtrlColor       : $3A; CtrlMono        : $08;
    FrameColor      : $7F; FrameMono       : $70;
    HeaderColor     : $7F; HeaderMono      : $70;
    ShadowColor     : $08; ShadowMono      : $00;
    HighlightColor  : $4F; HighlightMono   : $70;
    PromptColor     : $70; PromptMono      : $70;
    SelPromptColor  : $7F; SelPromptMono   : $70;
    ProPromptColor  : $70; ProPromptMono   : $07;
    FieldColor      : $1E; FieldMono       : $07;
    SelFieldColor   : $1F; SelFieldMono    : $0F;
    ProFieldColor   : $70; ProFieldMono    : $07;
    ScrollBarColor  : $17; ScrollBarMono   : $07;
    SliderColor     : $17; SliderMono      : $0F;
    HotSpotColor    : $17; HotSpotMono     : $0F;
    BlockColor      : $1E; BlockMono       : $0F;
    MarkerColor     : $1F; MarkerMono      : $70;
    DelimColor      : $7E; DelimMono       : $0F;
    SelDelimColor   : $11; SelDelimMono    : $0F;
    ProDelimColor   : $7E; ProDelimMono    : $0F;
    SelItemColor    : $2F; SelItemMono     : $70;
    ProItemColor    : $77; ProItemMono     : $07;
    HighItemColor   : $7F; HighItemMono    : $0F;
    AltItemColor    : $3E; AltItemMono     : $0F;
    AltSelItemColor : $2F; AltSelItemMono  : $70;
    FlexAHelpColor  : $7F; FlexAHelpMono   : $0F;
    FlexBHelpColor  : $7F; FlexBHelpMono   : $0F;
    FlexCHelpColor  : $7B; FlexCHelpMono   : $70;
    UnselXrefColor  : $7E; UnselXrefMono   : $09;
    SelXrefColor    : $9F; SelXrefMono     : $70;
    MouseColor      : $4F; MouseMono       : $70);

  dColors : DialogColorSet = (
    HiPromptColor   : $7E; HiPromptMono    : $0F;
    ButtonColor     : $20; ButtonMono      : $07;
    DefButtonColor  : $2B; DefButtonMono   : $07;
    HiButtonColor   : $2E; HiButtonMono    : $0F;
    SelButtonColor  : $2F; SelButtonMono   : $0F;
    ProButtonColor  : $70; ProButtonMono   : $70;
    BtnShadowColor  : $70; BtnShadowMono   : $70;
    ClusterColor    : $30; ClusterMono     : $07;
    ProClusterColor : $70; ProClusterMono  : $07;
    HiClusterColor  : $3E; HiClusterMono   : $0F;
    SelClusterColor : $3F; SelClusterMono  : $0F);

var
  ThePort     : UartPortPtr;
  MyModem     : ModemPtr;
  DialDB      : DialerDialogPtr;
  TheCommands : ModemData;
  Ch          : Char;

{allows operation to be aborted by pressing ESC}
function AbortIt : Boolean; far;
var
  Ch : Char;
begin
  AbortIt := False;
  if KeyPressed then
    Ch := ReadKey;
    if (Ch = #0) then
      Ch := ReadKey
    else
      AbortIt := (Ch = #27);
end;

begin
  ClrScr;

  {initialize default command record}
  with TheCommands.Data do begin
    InitCmd       := 'ATZ^M';
    DialCmd       := 'ATDT';
    DialCancel    := '^M';
    DialTerm      := '^M';
    HangupCmd     := 'DTR';
    OkMsg         := 'OK';
    ConnectMsg    := 'CONNECT';
    BusyMsg       := 'BUSY';
    NoCarrierMsg  := 'NO CARRIER';
    NoDialToneMsg := 'NO DIALTONE';
    ErrorMsg      := 'ERROR';
  end;

  {instantiate objects}
  New(ThePort, InitFast(Com1, 19200));
  if ThePort = nil then begin
    Writeln('Error initializing port object.');
    Halt;
  end;
  ThePort^.SetAbortFunc(AbortIt);

  New(MyModem, Init(ThePort, TheCommands));
  if MyModem = nil then begin
    Writeln('Error initializing modem interface object.');
    Dispose(ThePort, Done);
    Halt;
  end;

  Writeln('Sending initialization command to the modem . . . ');
  MyModem^.Initialize(True);
  if AsyncStatus <> ecOK then begin
    Writeln('Error sending intialization command to modem: ',
            StatusStr(AsyncStatus));
    Dispose(MyModem, Done);
    Dispose(ThePort, Done);
    Halt;
  end;

  New(DialDB, Init( 20, 6, Colors, dColors, MyModem, '260-9726',
                    10, 10, DefExitOptions));
  if DialDB = nil then begin
    Writeln('Error creating dialog box.');
    Dispose(MyModem, Done);
    Dispose(ThePort, Done);
    Halt;
  end;

  with DialDB^, wFrame do begin
    SetFrameType(DblWindowFrame);
    AddHeader(' Dialer Demo ', heTC);

    {$IFDEF UseShadows}
    AddShadow(shBR, shSeeThru);
    {$ENDIF}
  end;

  {execute dialog box}
  {$IFDEF UseMouse}
  with Colors do
    SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+$04);
  ShowMouse;
  {$IFNDEF UseDrag}
  DialogCommands.cpOptionsOn(cpEnableMouse);
  {$ENDIF}
  {$ENDIF}
  DialDB^.Process;
  DialDB^.Erase;

  WriteLn('Dial result: ', AsyncStatus);

  {dispose of objects}
  Dispose(DialDB, Done);
  Dispose(MyModem, Done);
  Dispose(ThePort, Done);
  HideMouse;
end.
