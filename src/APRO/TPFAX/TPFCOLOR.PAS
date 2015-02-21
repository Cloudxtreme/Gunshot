{******************************************************}
{*                 TPCOLOR.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$V-,B-,R-,S-,F-,O-,A+,I-,X+}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}


unit TpfColor;


interface

uses
  OpCrt,
  OpCtrl,
  OpColor;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

const

  MenuColors : ColorSet = (
    TextColor       : BlackOnLtGray;      TextMono        : BlackOnLtGray;
    CtrlColor       : YellowOnBlue;       CtrlMono        : WhiteOnBlack;
    FrameColor      : BlackOnLtGray;      FrameMono       : BlackOnLtGray;
    HeaderColor     : BlackOnLtGray;      HeaderMono      : BlackOnLtGray;
    ShadowColor     : DkGrayOnBlack;      ShadowMono      : WhiteOnBlack;
    HighlightColor  : WhiteOnRed;         HighlightMono   : BlackOnLtGray;
    PromptColor     : BlackOnCyan;        PromptMono      : LtGrayOnBlack;
    SelPromptColor  : BlackOnCyan;        SelPromptMono   : LtGrayOnBlack;
    ProPromptColor  : BlackOnCyan;        ProPromptMono   : LtGrayOnBlack;
    FieldColor      : YellowOnBlue;       FieldMono       : LtGrayOnBlack;
    SelFieldColor   : BlueOnCyan;         SelFieldMono    : WhiteOnBlack;
    ProFieldColor   : LtGrayOnBlue;       ProFieldMono    : LtGrayOnBlack;
    ScrollBarColor  : CyanOnBlue;         ScrollBarMono   : LtGrayOnBlack;
    SliderColor     : CyanOnBlue;         SliderMono      : WhiteOnBlack;
    HotSpotColor    : BlackOnCyan;        HotSpotMono     : BlackOnLtGray;
    BlockColor      : YellowOnCyan;       BlockMono       : WhiteOnBlack;
    MarkerColor     : WhiteOnMagenta;     MarkerMono      : BlackOnLtGray;
    DelimColor      : BlueOnCyan;         DelimMono       : WhiteOnBlack;
    SelDelimColor   : BlueOnCyan;         SelDelimMono    : WhiteOnBlack;
    ProDelimColor   : BlueOnCyan;         ProDelimMono    : WhiteOnBlack;
    SelItemColor    : BlackOnGreen;       SelItemMono     : LtGrayOnBlack;
    ProItemColor    : DkGrayOnLtGray;     ProItemMono     : DkGrayOnLtGray;
    HighItemColor   : RedOnLtGray;        HighItemMono    : WhiteOnLtGray;
    AltItemColor    : WhiteOnBlue;        AltItemMono     : WhiteOnBlack;
    AltSelItemColor : WhiteOnCyan;        AltSelItemMono  : BlackOnLtGray;
    FlexAHelpColor  : WhiteOnBlue;        FlexAHelpMono   : WhiteOnBlack;
    FlexBHelpColor  : WhiteOnBlue;        FlexBHelpMono   : WhiteOnBlack;
    FlexCHelpColor  : LtCyanOnBlue;       FlexCHelpMono   : BlackOnLtGray;
    UnselXrefColor  : YellowOnBlue;       UnselXrefMono   : LtBlueOnBlack;
    SelXrefColor    : WhiteOnMagenta;     SelXrefMono     : BlackOnLtGray;
    MouseColor      : WhiteOnRed;         MouseMono       : BlackOnLtGray);

  ClusterColors : DialogColorSet = (
    HiPromptColor   : YellowOnLtGray;  HiPromptMono    : WhiteOnLtGray;
    ButtonColor     : BlackOnGreen;    ButtonMono      : LtGrayOnBlack;
    DefButtonColor  : LtCyanOnGreen;   DefButtonMono   : LtGrayOnBlack;
    HiButtonColor   : YellowOnGreen;   HiButtonMono    : LtGrayOnBlack;
    SelButtonColor  : WhiteOnGreen;    SelButtonMono   : WhiteOnBlack;
    ProButtonColor  : BlackOnLtGray;   ProButtonMono   : BlackOnLtGray;
    BtnShadowColor  : BlackOnLtGray;   BtnShadowMono   : BlackOnLtGray;
    ClusterColor    : BlackOnCyan;     ClusterMono     : LtGrayOnBlack;
    ProClusterColor : LtGrayOnCyan;    ProClusterMono  : DkGrayOnBlack;
    HiClusterColor  : YellowOnCyan;    HiClusterMono   : WhiteOnBlack;
    SelClusterColor : WhiteOnCyan;     SelClusterMono  : WhiteOnBlack);

  DialogColors      : ColorSet = (
    TextColor       : BlackOnLtGray;  TextMono        : BlackOnLtGray;
    CtrlColor       : LtGreenOnCyan;  CtrlMono        : DkGrayOnBlack;
    FrameColor      : WhiteOnLtGray;  FrameMono       : BlackOnLtGray;
    HeaderColor     : WhiteOnLtGray;  HeaderMono      : BlackOnLtGray;
    ShadowColor     : DkGrayOnBlack;  ShadowMono      : BlackOnBlack;
    HighlightColor  : WhiteOnRed;     HighlightMono   : BlackOnLtGray;
    PromptColor     : BlackOnLtGray;  PromptMono      : BlackOnLtGray;
    SelPromptColor  : WhiteOnLtGray;  SelPromptMono   : BlackOnLtGray;
    ProPromptColor  : BlackOnLtGray;  ProPromptMono   : LtGrayOnBlack;
    FieldColor      : YellowOnBlue;   FieldMono       : LtGrayOnBlack;
    SelFieldColor   : WhiteOnBlue;    SelFieldMono    : WhiteOnBlack;
    ProFieldColor   : BlackOnLtGray;  ProFieldMono    : LtGrayOnBlack;
    ScrollBarColor  : LtGrayOnBlue;   ScrollBarMono   : LtGrayOnBlack;
    SliderColor     : LtGrayOnBlue;   SliderMono      : WhiteOnBlack;
    HotSpotColor    : LtGrayOnBlue;   HotSpotMono     : WhiteOnBlack;
    BlockColor      : YellowOnBlue;   BlockMono       : WhiteOnBlack;
    MarkerColor     : WhiteOnBlue;    MarkerMono      : BlackOnLtGray;
    DelimColor      : YellowOnLtGray; DelimMono       : WhiteOnBlack;
    SelDelimColor   : BlueOnBlue;     SelDelimMono    : WhiteOnBlack;
    ProDelimColor   : YellowOnLtGray; ProDelimMono    : WhiteOnBlack;
    SelItemColor    : WhiteOnGreen;   SelItemMono     : BlackOnLtGray;
    ProItemColor    : LtGrayOnLtGray; ProItemMono     : LtGrayOnBlack;
    HighItemColor   : WhiteOnLtGray;  HighItemMono    : WhiteOnBlack;
    AltItemColor    : YellowOnCyan;   AltItemMono     : WhiteOnBlack;
    AltSelItemColor : WhiteOnGreen;   AltSelItemMono  : BlackOnLtGray;
    FlexAHelpColor  : WhiteOnLtGray;  FlexAHelpMono   : WhiteOnBlack;
    FlexBHelpColor  : WhiteOnLtGray;  FlexBHelpMono   : WhiteOnBlack;
    FlexCHelpColor  : LtCyanOnLtGray; FlexCHelpMono   : BlackOnLtGray;
    UnselXrefColor  : YellowOnLtGray; UnselXrefMono   : LtBlueOnBlack;
    SelXrefColor    : YellowOnLtGray; SelXrefMono     : BlackOnLtGray;
    MouseColor      : WhiteOnRed;     MouseMono       : BlackOnLtGray);

  DropBoxColors : ColorSet = (
    TextColor       : WhiteOnBlue;    TextMono        : WhiteOnBlack;
    CtrlColor       : LtGreenOnCyan;  CtrlMono        : DkGrayOnBlack;
    FrameColor      : WhiteOnBlue;    FrameMono       : LtGrayOnBlack;
    HeaderColor     : WhiteOnBlue;    HeaderMono      : LtGrayOnBlack;
    ShadowColor     : DkGrayOnBlack;  ShadowMono      : BlackOnBlack;
    HighlightColor  : WhiteOnRed;     HighlightMono   : BlackOnLtGray;
    PromptColor     : BlackOnLtGray;  PromptMono      : BlackOnLtGray;
    SelPromptColor  : WhiteOnLtGray;  SelPromptMono   : BlackOnLtGray;
    ProPromptColor  : BlackOnLtGray;  ProPromptMono   : LtGrayOnBlack;
    FieldColor      : YellowOnBlue;   FieldMono       : LtGrayOnBlack;
    SelFieldColor   : WhiteOnBlue;    SelFieldMono    : WhiteOnBlack;
    ProFieldColor   : BlackOnLtGray;  ProFieldMono    : LtGrayOnBlack;
    ScrollBarColor  : BlueOnCyan;     ScrollBarMono   : LtGrayOnBlack;
    SliderColor     : BlueOnCyan;     SliderMono      : WhiteOnBlack;
    HotSpotColor    : BlueOnCyan;     HotSpotMono     : WhiteOnBlack;
    BlockColor      : YellowOnBlue;   BlockMono       : WhiteOnBlack;
    MarkerColor     : WhiteOnBlue;    MarkerMono      : BlackOnLtGray;
    DelimColor      : YellowOnLtGray; DelimMono       : WhiteOnBlack;
    SelDelimColor   : BlueOnBlue;     SelDelimMono    : WhiteOnBlack;
    ProDelimColor   : YellowOnLtGray; ProDelimMono    : WhiteOnBlack;
    SelItemColor    : WhiteOnGreen;   SelItemMono     : BlackOnLtGray;
    ProItemColor    : LtGrayOnLtGray; ProItemMono     : LtGrayOnBlack;
    HighItemColor   : WhiteOnLtGray;  HighItemMono    : WhiteOnBlack;
    AltItemColor    : WhiteOnGreen;   AltItemMono     : WhiteOnBlack;
    AltSelItemColor : WhiteOnGreen;   AltSelItemMono  : BlackOnLtGray;
    FlexAHelpColor  : WhiteOnLtGray;  FlexAHelpMono   : WhiteOnBlack;
    FlexBHelpColor  : WhiteOnLtGray;  FlexBHelpMono   : WhiteOnBlack;
    FlexCHelpColor  : LtCyanOnLtGray; FlexCHelpMono   : BlackOnLtGray;
    UnselXrefColor  : YellowOnLtGray; UnselXrefMono   : LtBlueOnBlack;
    SelXrefColor    : YellowOnLtGray; SelXrefMono     : BlackOnLtGray;
    MouseColor      : WhiteOnRed;     MouseMono       : BlackOnLtGray);

  ErrorColors : ColorSet = (
    TextColor       : YellowOnRed;    TextMono       : LtGrayOnBlack;
    CtrlColor       : BlackOnRed;     CtrlMono       : WhiteOnBlack;
    FrameColor      : YellowOnRed;    FrameMono      : LtGrayOnBlack;
    HeaderColor     : WhiteOnRed;     HeaderMono     : BlackOnLtGray;
    ShadowColor     : DkGrayOnBlack;  ShadowMono     : LtGrayOnBlack;
    HighlightColor  : LtGreenOnRed;   HighlightMono  : BlackOnLtGray;
    PromptColor     : LtGreenOnRed;   PromptMono     : WhiteOnBlack;
    SelPromptColor  : YellowOnRed;    SelPromptMono  : WhiteOnBlack;
    ProPromptColor  : DkGrayOnRed;    ProPromptMono  : LtGrayOnBlack;
    FieldColor      : YellowOnRed;    FieldMono      : LtGrayOnBlack;
    SelFieldColor   : WhiteOnRed;     SelFieldMono   : LtGrayOnBlack;
    ProFieldColor   : DkGrayOnRed;    ProFieldMono   : LtGrayOnBlack;
    ScrollBarColor  : LtGrayOnBlack;  ScrollBarMono  : LtGrayOnBlack;
    SliderColor     : BlackOnLtGray;  SliderMono     : LtGrayOnBlack;
    HotSpotColor    : BlackOnLtGray;  HotSpotMono    : LtGrayOnBlack;
    BlockColor      : YellowOnCyan;   BlockMono      : WhiteOnBlack;
    MarkerColor     : WhiteOnRed;     MarkerMono     : BlackOnLtGray;
    DelimColor      : WhiteOnBlack;   DelimMono      : WhiteOnBlack;
    SelDelimColor   : BlackOnLtGray;  SelDelimMono   : BlackOnLtGray;
    ProDelimColor   : LtGrayOnBlack;  ProDelimMono   : LtGrayOnBlack;
    SelItemColor    : WhiteOnGreen;   SelItemMono    : BlackOnLtGray;
    ProItemColor    : LtGrayOnBlue;   ProItemMono    : LtGrayOnBlack;
    HighItemColor   : WhiteOnBlue;    HighItemMono   : WhiteOnBlack;
    AltItemColor    : WhiteOnBlue;    AltItemMono    : WhiteOnBlack;
    AltSelItemColor : WhiteOnGreen;   AltSelItemMono : BlackOnLtGray;
    FlexAHelpColor  : WhiteOnBlue;    FlexAHelpMono  : WhiteOnBlack;
    FlexBHelpColor  : WhiteOnBlue;    FlexBHelpMono  : WhiteOnBlack;
    FlexCHelpColor  : LtCyanOnBlue;   FlexCHelpMono  : BlackOnLtGray;
    UnselXrefColor  : YellowOnBlue;   UnselXrefMono  : LtBlueOnBlack;
    SelXrefColor    : WhiteOnMagenta; SelXrefMono    : BlackOnLtGray;
    MouseColor      : LtGreenOnRed;   MouseMono      : BlackOnLtGray
  );

const
  eColors : DialogColorSet = (
    HiPromptColor   : WhiteOnRed;    HiPromptMono    : WhiteOnBlack;
    ButtonColor     : BlackOnGreen;  ButtonMono      : LtGrayOnBlack;
    DefButtonColor  : YellowOnGreen; DefButtonMono   : LtGrayOnBlack;
    HiButtonColor   : WhiteOnGreen;  HiButtonMono    : WhiteOnBlack;
    SelButtonColor  : YellowOnGreen; SelButtonMono   : WhiteOnBlack;
    ProButtonColor  : LtGrayOnBlack; ProButtonMono   : BlackOnLtGray;
    BtnShadowColor  : DkGrayOnRed;   BtnShadowMono   : BlackOnLtGray;
    ClusterColor    : BlackOnRed;    ClusterMono     : LtGrayOnBlack;
    ProClusterColor : RedOnRed;      ProClusterMono  : LtGrayOnBlack;
    HiClusterColor  : YellowOnRed;   HiClusterMono   : WhiteOnBlack;
    SelClusterColor : WhiteOnRed;    SelClusterMono  : LtGrayOnBlack);

implementation
end.
