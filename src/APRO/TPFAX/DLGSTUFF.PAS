{******************************************************}
{*                 DLGSTUFF.PAS  2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}

{$V-,B-,R-,S-,F-,O-,A+,I-,X+}

{$IFNDEF UseDrag}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseMouse}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseScrollBars}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseHotSpots}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

{$IFNDEF UseShadows}
  !! ERROR - The settings in OPDEFINE.INC are incompatible with this unit
{$ENDIF}

unit DlgStuff;

interface

uses
  OpAbsFld,
  {$IFDEF UseBCD}
  OpBCD,
  {$ENDIF}
  OpCmd,
  OpConst,
  OpCrt,
  OpCtrl,
  {$IFDEF UseDates}
  OpDate,
  {$ENDIF}
  OpDialog,
  OpDrag,
  OpFEdit,
  OpSelect,  {!!.02}
  OpField,
  OpFrame,
  OpInline,
  OpMouse,
  OpPick,
  OpRoot,
  OpString,
  OpWindow;

const
  ccComboTrigger  = ccUser54;

  DialogCloseSpot = $FF;

  OKButton        = 'O&k';
  CancelButton    = 'Cancel';
  YesButton       = '&Yes';
  NoButton        = '&No';

type

  ComboBoxPtr  = ^ComboBox;
  AltDialogPtr = ^AltDialog;

  ComboUserProc = procedure(CB : ComboBoxPtr; DBP : AltDialogPtr);

  ComboBox =
    object(Control)
      cbEColor   : Byte;
      cbEMono    : Byte;
      cbColor    : Byte;
      cbMono     : Byte;
      cbPickBox  : PickListPtr;
      cbRelX     : Integer;
      cbRelY     : Integer;
      cbPreEdit  : ComboUserProc;
      cbPostEdit : ComboUserProc;

      constructor Init(     ID         : Word;
                        var Prompt     : String;
                            pRow, pCol : Word;
                        var Picture    : String;
                            fRow, fCol : Word;
                            fWidth     : Byte;
                            HlpNdx     : Word;
                            DataSize   : Word;
                        var EditVar    : String;
                            PickBox    : PickListPtr;
                            PadChar    : Char;
                            prOptions  : LongInt;
                            seOptions  : LongInt;
                            dcOptions  : LongInt;
                        var Colors     : ColorSet;
                        var dColors    : DialogColorSet;
                            Dialog     : AltDialogPtr;
                            PreEdit    : ComboUserProc;
                            PostEdit   : ComboUserProc );
      destructor Done; virtual;
      procedure Draw(var St : string; Row, Col : Word; FA, CA, POffset : Byte;
                     PasswordChar : Char; var Flags : PictureFlags); virtual;
      function ClickedOnTrigger(DBP : AltDialogPtr; Y, X : Byte) : Boolean;
      procedure Trigger(DBP : AltDialogPtr);
    end;

  AltDialog =
    object(DialogBox)
      adComboBox : ComboBoxPtr;

      procedure ProcessSelf; virtual;
      function  asProcessMouseCommand(     Cmd          : Word;
                                       var ScrollByPage : Boolean) : Byte; virtual;

      procedure AddComboBox(Prompt : String;  pRow, pCol : Word;
                            Picture : String; cRow, cCol : Word;
                            cWidth : Byte;    HelpIndex : Word;
                            var EditSt : String; PL : PickListPtr;
                            PreEditProc  : ComboUserProc;
                            PostEditProc : ComboUserProc);

      { routines for adding edit controls other than strings }

      procedure AddCharControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; CharLo, CharHi : Char;
                                var EditChar : Char);

      procedure AddRealControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; RealLo, RealHi : Real;
                                Places : Byte; var EditReal : Real );

      procedure AddByteControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; ByteLo, ByteHi : Byte;
                                var EditByte : Byte );

      procedure AddIntegerControl(Prompt  : String; pRow, pCol : Word;
                                  Picture : String; fRow, fCol : Word;
                                  cWidth  : Byte;
                                  HelpIndex : Word; IntLo, IntHi : Integer;
                                  var EditInt : Integer );

      procedure AddWordControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                Helpindex : Word; WordLo, WordHi : Word;
                                var EditWord : Word );

      procedure AddLongControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                Helpindex : Word; LongLo, LongHi : LongInt;
                                var EditLong : LongInt);

      procedure AddYesNoControl(Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; var EditYesNo : Boolean );

      procedure AddBooleanControl(Prompt  : String; pRow, pCol : Word;
                                  Picture : String; fRow, fCol : Word;
                                  cWidth  : Byte;
                                  HelpIndex : Word; var EditBoolean : Boolean );

      {$IFDEF UseDates}
      procedure AddDateControl(Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; DateLo, DateHi : Date;
                                var EditDate : Date);

      procedure AddTimeControl( Prompt  : String; pRow, pCol : Word;
                                Picture : String; fRow, fCol : Word;
                                cWidth  : Byte;
                                HelpIndex : Word; TimeLo, TimeHi : Time;
                                var EditTime : Time );
      {$ENDIF}

      {$IFDEF UseBCD}
      procedure AddBCDControl(Prompt  : String; pRow, pCol : Word;
                              Picture : String; fRow, fCol : Word;
                              cWidth  : Byte;
                              HelpIndex : Word; BCDLo, BCDHi : BCD;
                              var EditBCD : BCD);
      {$ENDIF}
    end;

  ComboListPtr = ^ComboList;
  ComboList    =
    object(PickList)
      procedure ProcessSelf; virtual;
    end;

  HistoryArrayPtr = ^HistoryArray;
  HistoryArray    = array[1..16380] of StringPtr;

  HistoryListPtr = ^HistoryList;
  HistoryList =
    object(Root)
      hlNumEntries : Word;
      hlMaxEntries : Word;
      hlHistory    : HistoryArrayPtr;
      hlError      : Word;

      constructor Init(MaxEntries : Word);
      destructor Done; virtual;

      function GetLastError : Word;
      function PeekLastError : Word;
      procedure GotError(Code : Word);

      procedure AddEntry(S : String);
    end;

  HistoryListBoxPtr = ^HistoryListBox;
  HistoryListBox    =
    object(ComboList)
      hlList : HistoryListPtr;

      procedure SetHistory(HL : HistoryListPtr);
      procedure ItemString(     Item    : Word;
                                Mode    : pkMode;
                            var IType   : pkItemType;
                            var IString : String); virtual;
      procedure AddEntry(S : String);
    end;

procedure SetDialogOptions(DB : DialogBoxPtr);
  {- Set all the options on a dialog box }

procedure SetPickOptions( PL : PickListPtr; ScrollBarPos : FrameEdgeType;
                          var Colors : ColorSet; var dColors : DialogColorSet );
  {- Set all the options on an embedded pick list }

procedure SetComboListOptions(CL : ComboListPtr; var Colors : ColorSet);
  {- Set all the options on a combo list }

procedure ChangeToBurst(CW : CommandWindowPtr);
  {- Change the close box on a window to a starburst }

procedure ChangeToBlock(CW : CommandWindowPtr);
  {- Change the close box on a window to a normal block }

function InitMessageBox(Message, Header, Button : String;
                        var Colors : ColorSet; 
                        var dColors : DialogColorSet) : DialogBoxPtr;
  {- Initialize a message dialog with a single button }

function InitChoiceBox( Message, Header, Choice1, Choice2 : String;
                        var Colors : ColorSet; 
                        var dColors : DialogColorSet) : DialogBoxPtr;
  {- Initialize a message dialog with two buttons }

procedure SetChildErrorProc(CW : CommandWindowPtr; EP : ErrorProc);
  {- Sets the error proc for CW and all children }

function ProcessDialogPrim(DB : DialogBoxPtr; IgnoreUser : Boolean) : Word;
  {- Process a dialog box, returning the last command, optionally ignoring
     ccUser commands }

function ProcessDialog(DB : DialogBoxPtr) : Word;
  {- Process a dialog box, returning the last command }

implementation

  constructor ComboBox.Init(    ID         : Word;
                            var Prompt     : String;
                                pRow, pCol : Word;
                            var Picture    : String;
                                fRow, fCol : Word;
                                fWidth     : Byte;
                                HlpNdx     : Word;
                                DataSize   : Word;
                            var EditVar    : String;
                                PickBox    : PickListPtr;
                                PadChar    : Char;
                                prOptions  : LongInt;
                                seOptions  : LongInt;
                                dcOptions  : LongInt;
                            var Colors     : ColorSet;
                            var dColors    : DialogColorSet;
                                Dialog     : AltDialogPtr;
                                PreEdit    : ComboUserProc;
                                PostEdit   : ComboUserProc );
  begin
    if not Control.Init(ID, Prompt, pRow, pCol, Picture, fRow, fCol,
                        fWidth, 1, HlpNdx, BlankRange, BlankRange,
                        DataSize, 0, NullValidation, StringConversion,
                        DrawString, StringEditor, EditVar, PadChar,
                        prOptions, seOptions, dcOptions, Colors, dColors) then
      Fail;
    with Colors, dColors do begin
      cbEColor := (TextColor and $F0) or ((ButtonColor and $F0) shr 4);
      cbEMono := (TextMono and $F0) or ((ButtonColor and $F0) shr 4);
      cbColor := ButtonColor;
      cbMono := ButtonMono;
    end;

    cbPickBox := PickBox;
    cbRelX    := cbPickBox^.wXL - Dialog^.wXL;
    cbRelY    := cbPickBox^.wYL - Dialog^.wYL;

    cbPreEdit  := PreEdit;
    cbPostEdit := PostEdit;
  end;

  destructor ComboBox.Done;
  begin
    Dispose(cbPickBox, Done);
    Control.Done;
  end;

  procedure ComboBox.Draw(var St              : string;
                              Row, Col        : Word;
                              FA, CA, POffset : Byte;
                              PasswordChar    : Char;
                          var Flags           : PictureFlags);

  var
    SaveMouse : Boolean;
    Attr      : Byte;

  begin
    if (VirtualSegment = VideoSegment) then
      HideMousePrim(SaveMouse);
    Control.Draw(St, Row, Col, FA, CA, POffset, PasswordChar, Flags);
    if not LongFlagIsSet(sfOptions, sfHidden) then
      begin
        FastWrite(#222, Row, Col + sfFWidth    , ColorMono(cbEColor, cbEMono));
        FastWrite(#31 , Row, Col + sfFWidth + 1, ColorMono(cbColor , cbMono ));
        FastWrite(#221, Row, Col + sfFwidth + 2, ColorMono(cbEColor, cbEMono));
      end;
    ShowMousePrim(SaveMouse);
  end;

  function ComboBox.ClickedOnTrigger(DBP : AltDialogPtr; Y, X : Byte) : Boolean;
  var
    AbsY : Byte;
    AbsX : Byte;

  begin
    AbsY := (sfFRow + DBP^.wYL - 1);
    AbsX := (sfFCol + DBP^.wXL + sfFWidth - 1);
    ClickedOnTrigger := (Y = AbsY) and ((X = AbsX) or (X = AbsX + 1) or (X = AbsX + 2));
  end;

  procedure ComboBox.Trigger(DBP : AltDialogPtr);
  var
    XDiff : Integer;
    YDiff : Integer;
    NewX  : Byte;
    NewY  : Byte;
    I     : Word;
    S     : StringPtr;
    IType : pkItemType;
    Match : Boolean;
    Temp  : String;

  begin
    with cbPickBox^ do begin
      XDiff := wXH - wXL;
      YDiff := wYH - wYL;
      NewX  := DBP^.wXL + cbRelX;
      NewY  := DBP^.wYL + cbRelY;
      AdjustWindow(NewX, NewY, NewX + XDiff, NewY + YDiff);

      S := StringPtr(efVarPtr);
      if (S^ = '') then
        pkChoice := 1
      else if not FlagIsSet(pkSecFlags, pkFakingOneItem) then begin
        IType := pkNormal;
        Temp  := '';
        I := 1;
        repeat
          Temp := '';
          ItemString(I, pkDisplay, IType, Temp);
          Match := (StUpCase(Trim(Temp)) = StUpCase(Trim(S^)));
          Inc(I);
        until (I > pkItems) or Match;
        if Match then
          pkChoice := Pred(I);
      end else
        pkChoice := 1;

      { pre edit routine }
      if (@cbPreEdit <> nil) then
        cbPreEdit(@Self, DBP);

      if (DBP^.cwKey = MouseLftDown) then begin
        Draw;
        WaitForButtonUp;
      end;

      repeat
        Process;
      until (cwCmd = ccError) or (cwCmd = ccQuit) or (cwCmd = ccSelect);

      if (cwCmd = ccSelect) and
          not FlagIsSet(pkSecFlags, pkFakingOneItem) then
        ItemString(pkChoice, pkDisplay, IType, S^);
      Erase;

      DBP^.DrawField(sfID);

      if (@cbPostEdit <> nil) then
        cbPostEdit(@Self, DBP);
    end;
  end;

  procedure AltDialog.ProcessSelf;
  var
    TCP : ComboBoxPtr;

  begin
    adComboBox := nil;
    repeat
      DialogBox.ProcessSelf;
      if (cwCmd = ccComboTrigger) then begin
        if (cwKey = MouseLftDown) then
          TCP := adComboBox
        else if (TypeOf(asCurrent^) = TypeOf(ComboBox)) then
          TCP := ComboBoxPtr(asCurrent)
        else begin
          SetLastCommand(ccNone);
          TCP := nil;
        end;
        if (TCP <> nil) then begin
          TCP^.Trigger(@Self);
          if (TCP^.cbPickBox^.cwCmd = ccSelect) then
            DrawField(asCurID);

          wRes             := 0;
          wFramePtr^.frRes := 0;
        end;
      end;
    until (cwCmd <> ccComboTrigger);
  end;

  function AltDialog.asProcessMouseCommand(     Cmd          : Word;
                                            var ScrollByPage : Boolean) : Byte;
  var
    Result   : Byte;
    FramePos : FramePosType;
    L        : LongInt;
    HotCode  : Byte;
    AbsY     : Integer;
    AbsX     : Integer;
    TCP      : EntryFieldPtr;  {!!.01}

    function BadCombo : Boolean;                       {!!.01}
    begin                                              {!!.01}
      BadCombo := TCP^.efOptionsAreOn(efProtected) or  {!!.01}
                  TCP^.efOptionsAreOn(efHidden) or     {!!.01}
                  TCP^.efOptionsAreOn(efInvisible);    {!!.01}
    end;                                               {!!.01}

  begin
    Result := DialogBox.asProcessMouseCommand(Cmd, ScrollByPage);
    if (Result <> 0) or (Cmd = ccMouseSel) or (Cmd = ccMouseAuto) then begin
      asProcessMouseCommand := Result;
      Exit;
    end;

    asProcessMouseCommand := 0;
    L := cwMouseResults(Cmd, FramePos, HotCode);
    if (HotCode <> hsNone) or (FramePos <> frInsideActive) then
      Exit;

    AbsY := MouseKeyWordY + MouseXLo;
    AbsX := MouseKeyWordX + MouseXLo;

    TCP := EntryFieldPtr(asFields.Head);        {!!.01}
    while (TCP <> nil) do begin
      if (TypeOf(TCP^) = TypeOf(ComboBox)) and not BadCombo then {!!.01}
        if ComboBoxPtr(TCP)^.ClickedOnTrigger(@Self, AbsY, AbsX) then begin
          asProcessMouseCommand := 1;
          cwCmd := ccComboTrigger;
          adComboBox := ComboBoxPtr(TCP);
          SetNextField(TCP^.sfID);
          Exit;
        end;
      TCP := EntryFieldPtr(asFields.Next(TCP)); {!!.01}
    end;
  end;

  procedure AltDialog.AddComboBox(Prompt : String;  pRow, pCol : Word;
                                  Picture : String; cRow, cCol : Word;
                                  cWidth : Byte;    HelpIndex : Word;
                                  var EditSt : String; PL : PickListPtr;
                                  PreEditProc : ComboUserProc;
                                  PostEditProc : ComboUserProc);
  begin
    if (Picture = '') then
      Picture := CharStr(AnyChar, cWidth);
    if dgParamsOK(Prompt, pRow, pCol, Picture, cRow, cCol, cWidth, 1) then
      dgAppendControl(
        New(ComboBoxPtr,
          Init( asCount, Prompt, pRow, pCol, Picture, cRow, cCol, cWidth,
                HelpIndex, Length(Picture) + 1, EditSt, PL, dgPadChar,
                asFieldOptions, dgFieldFlags, dgControlFlags, asColors,
                dgColors, @Self, PreEditProc, PostEditProc ) ) );
  end;

  procedure AltDialog.AddCharControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; CharLo, CharHi : Char;
                                      var EditChar : Char);
  var
    LoRange, HiRange : RangeType;
    fWidth           : Byte;
    VF               : ValidationFunc;

  begin
    if (Length(Picture) = 0) then begin 
      Picture := AnyChar;
      fWidth := 1;
    end else
      fWidth := Length(Picture);

    if (CharLo = CharHi) then begin
      VF      := NullValidation;
      LoRange := BlankRange;
      HiRange := BlankRange;
    end else begin
      VF             := ValidateChar;
      LoRange.rtChar := CharLo;
      HiRange.rtChar := CharHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Char), 0, VF, CharConversion,
                        DrawString, CharEditor, EditChar);
  end;
    

  procedure AltDialog.AddRealControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; RealLo, RealHi : Real;
                                      Places : Byte; var EditReal : Real );
  var
    LoRange, HiRange : RangeType;

  begin
    if (RealLo = RealHi) then begin
      LoRange.rtReal := -1.5e+38;
      HiRange.rtReal := +1.5e+38;
    end else begin
      LoRange.rtReal := RealLo;
      HiRange.rtReal := RealHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Real), Places, ValidateReal,
                        RealConversion, DrawString, StringEditor, EditReal);
  end;


  procedure AltDialog.AddByteControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; ByteLo, ByteHi : Byte;
                                      var EditByte : Byte );
  var
    LoRange, HiRange : RangeType;

  begin
    if (ByteLo = ByteHi) then begin
      LoRange.rtLong := 0;
      HiRange.rtLong := 255;
    end else begin
      LoRange.rtLong := ByteLo;
      HiRange.rtLong := ByteHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Byte), 0, ValidateLong,
                        ByteConversion, DrawString, StringEditor, EditByte);
  end;

  procedure AltDialog.AddIntegerControl(Prompt  : String; pRow, pCol : Word;
                                        Picture : String; fRow, fCol : Word;
                                        cWidth  : Byte;
                                        HelpIndex : Word; IntLo, IntHi : Integer;
                                        var EditInt : Integer );
  var
    LoRange, HiRange : RangeType;

  begin
    if (IntLo = IntHi) then begin
      LoRange.rtLong := -37286;
      HiRange.rtLong := MaxInt;
    end else begin
      LoRange.rtLong := IntLo;
      HiRange.rtLong := IntHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Integer), 0, ValidateLong,
                        IntConversion, DrawString, StringEditor, EditInt);
  end;

  procedure AltDialog.AddWordControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      Helpindex : Word; WordLo, WordHi : Word;
                                      var EditWord : Word );
  var
    LoRange, HiRange : RangeType;

  begin
    if (WordLo = WordHi) then begin
      LoRange.rtLong := 0;
      HiRange.rtLong := $FFFF;
    end else begin
      LoRange.rtLong := WordLo;
      HiRange.rtLong := WordHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Word), 0, ValidateLong,
                        WordConversion, DrawString, StringEditor, EditWord);
  end;


  procedure AltDialog.AddLongControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      Helpindex : Word; LongLo, LongHi : LongInt;
                                      var EditLong : LongInt);
  var
    LoRange, HiRange : RangeType;

  begin
    if (LongLo = LongHi) then begin
      LoRange.rtLong := $80000000;
      HiRange.rtLong := $7FFFFFFF;
    end else begin
      LoRange.rtLong := LongLo;
      HiRange.rtLong := LongHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(LongInt), 0, ValidateLong,
                        LongConversion, DrawString, StringEditor, EditLong);
  end;


  procedure AltDialog.AddYesNoControl(Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; var EditYesNo : Boolean);
  begin
    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol, 
                        1, HelpIndex, BlankRange, BlankRange,
                        SizeOf(Boolean), 0, NullValidation,
                        YesNoConversion, DrawString, CharEditor, EditYesNo);
  end;

  procedure AltDialog.AddBooleanControl(Prompt  : String; pRow, pCol : Word;
                                        Picture : String; fRow, fCol : Word;
                                        cWidth  : Byte;
                                        HelpIndex : Word; var EditBoolean : Boolean );
  begin
    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        1, Helpindex, BlankRange, BlankRange,
                        SizeOf(Boolean), 0, NullValidation,
                        BooleanConversion, DrawString, CharEditor, EditBoolean);
  end;

  {$IFDEF UseDates}

  {$IFOPT F-}
    {$DEFINE TO}
    {$F+}
  {$ENDIF}

  procedure DialogDateConversion(EFP : EntryFieldPtr; PostEdit : Boolean);
  var
    D : Date;

  begin
    with EFP^ do begin
      if PostEdit then
        Date(efVarPtr^) := DateStringToDate(efPicture^, efEditSt^)
      else
        efEditSt^ := DateToDateString(efPicture^, Date(efVarPtr^));
      efSetSemiHidden(Date(efVarPtr^) = BadDate);
    end;
  end;

  function DialogDateValidate(EFP : EntryFieldPtr; var Code : Word;
                              var SP : StringPtr) : Boolean;
  var
    D     : Date;
    Day   : Integer;
    Month : Integer;
    Year  : Integer;

  begin
    with EFP^ do begin
      DialogDateValidate := False;
      if (efRangeHi.rtDate = MinDate) then
        if DateStringIsBlank(efPicture^, efEditSt^) then begin
          DialogDateValidate := True;
          Exit;
        end;

      D := DateStringToDate(efPicture^, efEditSt^);

      if (D = BadDate) then begin
        Code := ecBadFormat;
        SP := @emInvalidDate;
      end else if (D < efRangeLo.rtDate) or (D > efRangeHi.rtDate) then begin
        DialogDateValidate := (efRangeHi.rtDate = MinDate);
        Code := ecOutOfRange;
        SP := @emOutOfRange;
      end else
        DialogDateValidate := True;
    end;
  end;

  {$IFDEF TO}
    {$F-}
  {$ENDIF}

  procedure AltDialog.AddDateControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; DateLo, DateHi : Date;
                                      var EditDate : Date);
  var
    LoRange, HiRange : RangeType;

  begin
    if (DateLo = DateHi) then begin
      LoRange.rtDate := MinDate;
      HiRange.rtDate := MaxDate;
    end else begin
      LoRange.rtDate := DateLo;
      HiRange.rtDate := DateHi;
    end;
  
    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(Date), 0, DialogDateValidate,
                        DialogDateConversion, DrawString, StringEditor, EditDate);
  end;

  {$IFOPT F-}
    {$DEFINE TO}
    {$F+}
  {$ENDIF}

  procedure DialogTimeConversion(EFP : EntryFieldPtr; PostEdit : Boolean);
  begin
    with EFP^ do begin
      if PostEdit then
        Time(efVarPtr^) := TimeStringToTime(efPicture^, efEditSt^)
      else
        efEditSt^ := TimeToTimeString(efPicture^, Time(efVarPtr^));
      efSetSemiHidden(Time(efVarPtr^) = BadTime);
    end;
  end;

  function DialogTimeValidate(EFP : EntryFieldPtr;
                              var Code : Word; var SP : StringPtr) : Boolean;
  var
    T : Time;
    H : Integer;
    M : Integer;
    S : Integer;

  begin
    with EFP^ do begin
      DialogTimeValidate := True;

      if (efRangeHi.rtTime = MinTime) then
        if not TimeStringToHMS(efPicture^, efEditSt^, H, M, S) then
          if (H = -1) and (M = -1) and ((S = -1) or (S = 0)) then begin
            DialogTimeValidate := True;
            Exit;
          end;

      T := TimeStringToTime(efPicture^, efEditSt^);
      if (T = BadTime) then begin
        DialogTimeValidate := False;
        Code := ecBadFormat;
        SP := @emInvalidTime;
      end else if (efRangeLo.rtTime <> efRangeHi.rtTime) then
        if (T < efRangeLo.rtTime) or (T > efRangeHi.rtTime) then begin
          DialogTimeValidate := False;
          Code := ecOutOfRange;
          SP := @emOutOfRange;
        end;
    end;
  end;

  {$IFDEF TO}
    {$F-}
  {$ENDIF}

  procedure AltDialog.AddTimeControl( Prompt  : String; pRow, pCol : Word;
                                      Picture : String; fRow, fCol : Word;
                                      cWidth  : Byte;
                                      HelpIndex : Word; TimeLo, TimeHi : Time;
                                      var EditTime : Time );
  var
    LoRange, HiRange : RangeType;

  begin
    if (TimeLo = TimeHi) then begin
      LoRange.rtTime := MinTime;
      HiRange.rtTime := MaxTime;
    end else begin
      LoRange.rtTime := TimeLo;
      HiRange.rtTime := TimeHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, Helpindex, LoRange, HiRange,
                        SizeOf(Time), 0, DialogTimeValidate,
                        DialogTimeConversion, DrawString, StringEditor, EditTime);
  end;

  {$ENDIF}

  {$IFDEF UseBCD}
  procedure AltDialog.AddBCDControl(Prompt  : String; pRow, pCol : Word;
                                    Picture : String; fRow, fCol : Word;
                                    cWidth  : Byte;
                                    HelpIndex : Word; BCDLo, BCDHi : BCD;
                                    var EditBCD : BCD);
  var
    LoRange, HiRange : RangeType;

  begin
    if EqualBCD(BCDLo, BCDHi) then begin
      LoRange.rtBCD := ZeroBCD;
      HiRange.rtBCD := MaxBCD;
    end else begin
      LoRange.rtBCD := BCDLo;
      HiRange.rtBCD := BCDHi;
    end;

    AddUserEditControl( Prompt, pRow, pCol, Picture, fRow, fCol,
                        cWidth, HelpIndex, LoRange, HiRange,
                        SizeOf(BCD), 0, ValidateBCD,
                        BCDConversion, DrawString, StringEditor, EditBCD);
  end;
  {$ENDIF}

  constructor HistoryList.Init(MaxEntries : Word);
  begin
    if not Root.Init then
      Fail;

    hlMaxEntries := MaxEntries;
    hlNumEntries := 0;

    if not GetMemCheck(hlHistory, SizeOf(StringPtr) * hlMaxEntries) then begin
      InitStatus := epFatal+ecOutOfMemory;
      Fail;
    end;

    hlError := 0;
  end;

  destructor HistoryList.Done;
  var
    I : Word;

  begin
    for I := 1 to hlNumEntries do
      DisposeString(hlHistory^[I]);
    FreeMemCheck(hlHistory, SizeOf(StringPtr) * hlMaxEntries);
    Root.Done;
  end;

  function HistoryList.GetLastError : Word;
  begin
    GetLastError := hlError;
    hlError := 0;
  end;

  function HistoryList.PeekLastError : Word;
  begin
    PeekLastError := hlError;
  end;

  procedure HistoryList.GotError(Code : Word);
  begin
    hlError := Code;
  end;

  procedure HistoryList.AddEntry(S : String);
  var
    EntPos : Word;

    procedure AppendEntry;
    begin
      Inc(hlNumEntries);
      hlHistory^[hlNumEntries] := StringToHeap(S);
      if (hlHistory^[hlNumEntries] = nil) then begin
        Dec(hlNumEntries);
        GotError(epNonFatal+ecOutOfMemory);
      end;
    end;

    function EntryExists : Boolean;
    var
      I : Word;

    begin
      I := 1;
      while (I <= hlNumEntries) and (StringFromHeap(hlHistory^[I]) <> S) do
        Inc(I);
      EntryExists := (I <= hlNumEntries);
      EntPos := I;
    end;

    procedure MoveToTop;
    var
      T : StringPtr;

    begin
      if (hlNumEntries > 1) and (StringFromHeap(hlHistory^[hlNumEntries]) <> S) then begin
        T := hlHistory^[hlNumEntries];
        hlHistory^[hlNumEntries] := hlHistory^[EntPos];
        if (hlNumEntries <> 2) then
          MoveFast(hlHistory^[Succ(EntPos)], hlHistory^[EntPos],
            SizeOf(StringPtr) * (hlNumEntries - EntPos));
        hlHistory^[hlNumEntries - 1] := T;
      end;
    end;

    procedure FreeSlot;
    begin
      DisposeString(hlHistory^[1]);
      MoveFast(hlHistory^[2], hlHistory^[1], SizeOf(StringPtr) * Pred(hlMaxEntries));
      Dec(hlNumEntries);
    end;

  begin
    if (S = '') then
      Exit;
    if EntryExists then
      MoveToTop
    else begin
      if (hlNumEntries = hlMaxEntries) then
        FreeSlot;
      AppendEntry;
    end;
  end;

  procedure HistoryListBox.SetHistory(HL : HistoryListPtr);
  begin
    hlList := HL;
  end;

  procedure HistoryListBox.ItemString(    Item    : Word;
                                          Mode    : pkMode;
                                      var IType   : pkItemType;
                                      var IString : String);
  begin
    if (Mode <> pkGetType) then
      IString := StringFromHeap(hlList^.hlHistory^[pkItems - Item + 1]);
  end;

  procedure HistoryListBox.AddEntry(S : String);
  var
    LE : Word;

  begin
    hlList^.AddEntry(S);
    LE := hlList^.GetLastError;
    if (LE <> 0) then
      GotError(LE, emNullError)
    else
      ChangeNumItems(hlList^.hlNumEntries);
  end;

  procedure ComboList.ProcessSelf;
  var
    H : Byte;

  begin
    PickList.ProcessSelf;
    if (cwCmd = ccMouseDown) or (cwCmd = ccMouseAuto) or (cwCmd = ccMouseSel) then begin
      H := HandleMousePress(Self);
      if (H = DialogCloseSpot) then begin
        ChangeToBurst(@Self);
        ShowMouse;
        WaitForButtonUp;
        HideMouse;
        ChangeToBlock(@Self);
        SetLastCommand(ccQuit);
      end;
    end;
  end;

  procedure SetDialogOptions(DB : DialogBoxPtr);
  begin
    with DB^, wFrame do begin
      SetFrameType(DblWindowFrame);
      AddShadow(shBR, shSeeThru);
      AddCustomHeader('[ ]', frTL, 2, 0, frFrameColor, frFrameMono);
      AddCustomHeader( 'þ' , frTL, 3, 0, (frFrameColor and $F0) + $0A,
                                         (frFrameMono  and $F0) + $0F);
      wUserData := GetLastHeaderIndex;
      AddHotRegion(frTL, DialogCloseSpot, 2, 0, 3, 1);
      AddHotBar(frTT, MoveHotCode);
      SetPosLimits(1, 2, ScreenWidth, Pred(ScreenHeight));

      dgFieldOptionsOn(   efInsertPushes +
                          efTrimBlanks   +
                          efClearFirstChar );

      dgFieldOptionsOff(  efProtected    +
                          efHidden       +
                          efMapCtrls     +
                          efInvisible    +
                          efAutoAdvance  +
                          efRightJustify +
                          efPasswordMode +
                          efClickExit    +
                          efBeepOnError  +
                          efAutoNumlock  +
                          efCursorToEnd  +
                          efRequired     +
                          efReadOnly );
    end;
  end;

  procedure SetPickOptions( PL : PickListPtr; ScrollBarPos : FrameEdgeType;
                            var Colors : ColorSet; var dColors : DialogColorSet);
  begin
    with PL^, wFrame, dColors do begin
      SetTextAttr(ClusterColor, ClusterMono);
      SetPickAttr(pkNormal, False, ClusterColor, ClusterMono);
      SetFrameAttr(ClusterColor, ClusterMono);
      AdjustFrameCoords(frXL - Ord(ScrollBarPos = frLL),
                        frYL - Ord(ScrollBarPos = frTT),
                        frXH + Ord(ScrollBarPos = frRR),
                        frYH + Ord(ScrollBarPos = frBB));
      AddCustomScrollBar( ScrollBarPos, 0, MaxLongInt, 0, 0,
                          DefSliderChar, DefBarChar, Colors );
      SetSearchMode(PickAltStringSearch);
    end;
  end;

  procedure SetComboListOptions(CL : ComboListPtr; var Colors : ColorSet);
  begin
    with CL^, wFrame do begin
      SetFrameType(DblWindowFrame);
      AddShadow(shBR, shSeeThru);
      AddCustomHeader('[ ]', frTL, 2, 0, frFrameColor, frFrameMono);
      AddCustomHeader( 'þ' , frTL, 3, 0, (frFrameColor and $F0) + $0A,
                                         (frFrameMono  and $F0) + $0F);
      wUserData := GetLastHeaderIndex;
      AddHotRegion(frTL, DialogCloseSpot, 2, 0, 3, 1);
      SetPosLimits(1, 2, Pred(ScreenWidth), Pred(ScreenHeight));
      AddScrollBar(frRR, 0, MaxLongInt, Colors);

      SetPadSize(1, 1);
      SetSearchMode(PickAltStringSearch);
    end;
  end;

  procedure ChangeToBurst(CW : CommandWindowPtr);
  begin
    with CW^ do
      ChangeHeader(wUserData, #15);
  end;

  procedure ChangeToBlock(CW : CommandWindowPtr);
  begin
    with CW^ do
      ChangeHeader(wUserData, #254);
  end;

  {************* message box stuff ******************}
  function InitMessageBoxPrim(Message, Header : String;
                              var Colors  : ColorSet;
                              var dColors : DialogColorSet) : DialogBoxPtr;
  var
    DB       : DialogBoxPtr;
    MaxWidth : Byte;
    I        : Byte;
    NumLines : Byte;
    X1       : Byte;
    Y1       : Byte;
    X2       : Byte;
    Y2       : Byte;
    Lines    : array[1..4] of String[63];

  begin
    InitMessageBoxPrim := nil;

    { build the text lines of the dialog }
    Message  := Copy(Message, 1, 252);  { 252 char maximum message }
    NumLines := 0;
    MaxWidth := 0;

    { do word wrap until we've come up with a displayable block of text }
    repeat
      Inc(NumLines);
      if (Length(Message) <= 63) then begin
        Lines[NumLines] := Message;
        Message := '';
      end else
        WordWrap(Message, Lines[NumLines], Message, 63, False);
      MaxWidth := MaxWord(MaxWidth, Length(Lines[NumLines]));
    until (NumLines = 4) or (Message = '');

    { find the coordinates of the dialog.  We should try to center it
      on the screen.  The WIDTH of the dialog will be MaxWidth + 4
      (leaving room for two blank characters on each side), and the
      HEIGHT of the dialog will be NumLines + 4 (leaving room for
      one blank at the top, one blank at the bottom, and the
      push buttons. }

    MaxWidth := MaxWord(MaxWidth + 4, 34);

    X1 := Succ((ScreenWidth - MaxWidth) shr 1);
    X2 := X1 + MaxWidth - 1;

    Y1 := Succ((ScreenHeight - (NumLines + 4)) shr 1);
    Y2 := Y1 + NumLines + 3;

    New(DB, InitCustom( X1, Y1, X2, Y2,
                        Colors,
                        wBordered+wClear+wUserContents,
                        dColors ));
    if (DB = nil) then
      Exit;

    SetDialogOptions(DB);

    with DB^ do begin
      wFrame.AddHeader(Header, heTC);
      if (NumLines = 1) then
        AddCenteredTextField(Lines[1], 2)
      else for I := 1 to NumLines do
        AddTextField(Lines[I], Succ(I), 3);
      InitStatus := RawError;
    end;

    if (InitStatus = 0) then
      InitMessageBoxPrim := DB;
  end;

  function InitMessageBox(Message, Header, Button : String;
                          var Colors : ColorSet; 
                          var dColors : DialogColorSet) : DialogBoxPtr;
  var 
    DB : DialogBoxPtr;

  begin
    InitMessageBox := nil;
    DB := InitMessageBoxPrim(Message, Header, Colors, dColors);
    if (DB = nil) then
      Exit;

    with DB^ do begin
      AddPushButton(  Button,
                      Height - 1,
                      Succ((Succ(wXH - wXL) - 9) shr 1),
                      8, 0, ccSelect, True);
      InitStatus := RawError;
    end;

    if (InitStatus = 0) then
      InitMessageBox := DB;
  end;

  function InitChoiceBox( Message, Header, Choice1, Choice2 : String;
                          var Colors : ColorSet; 
                          var dColors : DialogColorSet) : DialogBoxPtr;
  var
    DB : DialogBoxPtr;
    PP : Byte;

  begin
    InitChoiceBox := nil;

    DB := InitMessageBoxPrim(Message, Header, Colors, dColors);
    if (DB = nil) then
      Exit;

    with DB^ do begin
      PP := Succ((Succ(wXH - wXL) - 20) shr 1);
      AddPushButton(Choice1, Height - 1, PP, 8, 0, ccSelect, True);
      AddPushButton(Choice2, Height - 1, PP + 12, 8, 0, ccQuit, False);
      InitStatus := RawError;
    end;

    if (InitStatus = 0) then
      InitChoiceBox := DB;
  end;

  procedure SetChildErrorProc(CW : CommandWindowPtr; EP : ErrorProc);
  var
    Child : CommandWindowPtr;
    I     : Word;

  begin
    CW^.SetErrorProc(EP);
    Child := CommandWindowPtr(CW^.ChildPtr(1));
    I := 1;
    while (Child <> nil) do begin
      Child^.SetErrorProc(EP);
      Inc(I);
      Child := CommandWindowPtr(CW^.ChildPtr(I));
    end;
  end;

  function ProcessDialogPrim(DB : DialogBoxPtr; IgnoreUser : Boolean) : Word;
  var
    LastCmd : Word;
    HotCode : Byte;

  begin
    with DB^ do begin
      Draw;
      repeat
        Process;
        LastCmd := GetLastCommand;

        { if this is a mouse command, handle it directly }
        if (LastCmd = ccMouseDown) or (LastCmd = ccMouseAuto) then begin
          HotCode := HandleMousePress(DB^);
          if (HotCode = DialogCloseSpot) then begin
            ChangeToBurst(DB);
            ShowMouse;
            WaitForButtonUp;
            HideMouse;
            LastCmd := ccQuit;
          end;
        end;
      until (LastCmd = ccError) or (LastCmd = ccQuit) or (LastCmd = ccSelect) or
            (not IgnoreUser and (LastCmd >= ccUser0));
      ProcessDialogPrim := LastCmd;
    end;
  end;

  function ProcessDialog(DB : DialogBoxPtr) : Word;
  begin
    ProcessDialog := ProcessDialogPrim(DB, True);
  end;

end.
