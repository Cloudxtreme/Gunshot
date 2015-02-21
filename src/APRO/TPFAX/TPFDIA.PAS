{******************************************************}
{*                   TPFDIA.PAS  2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}

{$IFDEF DPMI}
{$V-,B-,R-,S-,F-,O-,A+,I-,X+}
{$ELSE}
{$V-,B-,R-,S-,F+,O+,A+,I-,X+}
{$ENDIF}

unit TpfDia;

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
  OpField,
  OpSelect,
  OpFrame,
  OpWindow,
  OpDrag,
  OpPick,
  OpDos,
  OpDir,
  OpXtree,
  ApMisc,
  OpCtrl,
  OpDialog,
  DlgStuff,
  OoAbsFax,
  TpfColor,
  TpfData,
  TpfError;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

const
  ccSendQueue   = ccUser5;

type

  PDirTree      = ^TDirTree;
  PUnselList    = ^TUnselList;
  PSelList      = ^TSelList;
  PDriveList    = ^TDriveList;

  PSelectCvtFilesDlg = ^TSelectCvtFilesDlg;
  TSelectCvtFilesDlg =
    object(AltDialog)
      cfDirTree    : PDirTree;
      cfUnselFiles : PUnselList;
      cfSelFiles   : PSelList;
      cfDrives     : PDriveList;
      cfFileHist   : HistoryListBoxPtr;
      cfFiles      : TSelectFileList;
      cfCasFiles   : Boolean;
      cfAllowAPF   : Boolean;
      cfApfOnly    : Boolean;
      cfFileName   : PathStr;
      cfDriveDisp  : String[7];

      constructor Init( CasFiles, AllowAPF, ApfOnly : Boolean;
                        Header : String; History : HistoryListPtr);
      destructor Done; virtual;

      procedure SetDefaultMask;
      procedure SwitchDrives;
      procedure CheckFileName;
      procedure ChangeDirectory;
      function GetFileType(FName : PathStr; var CT : CvtFileType) : Boolean;
      procedure AddToSelected;
      procedure RemoveFromSelected;
      procedure RefreshTree;
      procedure ClearForStatus;
      procedure UpdateForStatus(Index : Word);

      procedure ProcessSelf; virtual;
      procedure dgPostFocus; virtual;
    end;

  PSelectApfFilesDlg = ^TSelectApfFilesDlg;
  TSelectApfFilesDlg =
    object(AltDialog)
      afDirTree   : PDirTree;
      afDriveList : PDriveList;
      afFileHist  : HistoryListBoxPtr;
      afFileList  : DirListPtr;
      afDriveDisp : String[7];
      afFileName  : PathStr;

      constructor Init(Header : String; History : HistoryListPtr);
      destructor Done; virtual;

      procedure SwitchDrives;
      procedure ChangeDirectory;
      procedure CheckFileName;
      function GetFileName : PathStr;
      procedure RefreshTree;

      procedure ProcessSelf; virtual;
      procedure dgPostFocus; virtual;
    end;

  TDirTree =
    object(XTreePathList)
      constructor Init(X, Y : Byte);

      function  GetDisplayedPath : DirStr;
      procedure SetDirectory(Dir : DirStr);
    end;

  TUnselList =
    object(PickList)
      ListParent : PSelectCvtFilesDlg;

      constructor Init(P : PSelectCvtFilesDlg);
      procedure ItemString(Item : Word; Mode : pkMode; var IType : pkItemType;
                           var IString : String); virtual;
    end;

  TSelList =
    object(PickList)
      ListParent : PSelectCvtFilesDlg;

      constructor Init(P : PSelectCvtFilesDlg);
      procedure ItemString(Item : Word; Mode : pkMode; var IType : pkItemType;
                           var IString : String); virtual;
    end;

  TDriveList =
    object(ComboList)
      (*ListParent : PSelectCvtFilesDlg; *)                      {!!.01}
      NumDrives  : Byte;
      Drives     : array[1..26] of Char;

      (*constructor Init(X, Y : Byte; P : PSelectCvtFilesDlg);*) {!!.01}
      constructor Init(X, Y : Byte);                             {!!.01}
      procedure ItemString(Item : Word; Mode : pkMode; var IType : pkItemType;
                           var IString : String); virtual;
    end;

  PPhonebookMaintDlg = ^TPhonebookMaintDlg;
  TPhonebookMaintDlg =
    object(DialogBox)
      pmPhonebook : TPhonebook;
      pmEntryList : PickListPtr;

      constructor Init;
      destructor Done; virtual;
      procedure ProcessSelf; virtual;

      procedure AddEntry;
      procedure ChangeEntry;
      procedure DeleteEntry;
    end;

  PPBookDropDown = ^TPBookDropDown;

  PQueueEntryDialog = ^TQueueEntryDialog;
  TQueueEntryDialog =
    object(AltDialog)
      qePhoneList : PPBookDropDown;
      qeSendList  : PickListPtr;
      qeEditEntry : PSendQueueEntry;
      qeOldEntry  : PSendQueueEntry;
      qePhonebook : TPhonebook;

      constructor Init(Entry : PSendQueueEntry);
      destructor Done; virtual;

      procedure ProcessSelf; virtual;
      procedure dgPostFocus; virtual;

      procedure InsertFile;
      procedure DeleteFile;
    end;

  TPBookDropDown =
    object(ComboList)
      ListParent : PQueueEntryDialog;

      constructor Init(Parent : PQueueEntryDialog);
      procedure ItemString(     Item    : Word;
                                Mode    : pkMode;
                            var IType   : pkItemType;
                            var IString : String); virtual;
    end;

  PFaxQueueDialog = ^TFaxQueueDialog;
  TFaxQueueDialog =
    object(DialogBox)
      qdQueueList : PickListPtr;

      constructor Init;

      procedure ProcessSelf; virtual;
      procedure InsertEntry;
      procedure ChangeEntry;
      procedure DeleteEntry;
      procedure CopyEntry;
    end;

  PRejectPickList = ^TRejectPickList;
  TRejectPickList =
    object(PickList)
      procedure ItemString(     Item    : Word;
                                Mode    : pkMode;
                            var IType   : pkItemType;
                            var IString : String); virtual;
    end;

  PRejectListDlg = ^TRejectListDlg;
  TRejectListDlg =
    object(DialogBox)
      rlRejects : SingleListPtr;
      rlList    : PRejectPickList;

      constructor Init(var Rejects : SingleList);
    end;

procedure OneMomentPlease;
function  InitAboutBox : DialogBoxPtr;
function  InitYesNoBox(Message, Header : String) : DialogBoxPtr;
function  YesNo(Message, Header : String) : Boolean;
procedure ShowError(UnitCode : Byte; var ErrorCode : Word;
                    ErrorMsg : string);
procedure ShowErrorMessage(Msg : String);
procedure PortShowError(P : Pointer; var StatusCode : Word);

procedure ClearStatus;

implementation

const
  ccSelectFile  = ccUser1;
  ccRemoveFile  = ccUser2;
  ccChangeDir   = ccUser3;

  ccInsertEntry = ccUser1;
  ccChangeEntry = ccUser2;
  ccDeleteEntry = ccUser3;

  ccCopyEntry   = ccUser4;

  ccRefreshTree = ccUser10;

  { control IDs for the multi-selection dialog }
  cfDirTreeID    = 0;
  cfDriveListID  = 1;
  cfFileNameID   = 2;
  cfUnselFilesID = 3;
  cfdSelFilesID  = 8;

  { control IDs for the select APF dialog }
  afDirTreeID   = 0;
  afDriveListID = 1;
  afFileNameID  = 2;
  afFileListID  = 3;

  { control IDs for the fax queue entry dialog }
  fqeName    = 0;
  fqeNumber  = 1;
  fqeOptions = 2;
  fqeDate    = 3;
  fqeTime    = 4;
  fqeFiles   = 5;

  procedure OneMomentPlease;
  begin
    ClearStatus;
    FastText('One moment please . . .', ScreenHeight, 2);
  end;

  function ContainsWildCards(FName : PathStr) : Boolean;
  begin
    ContainsWildCards := (Pos('?', FName) <> 0) or (Pos('*', FName) <> 0);
  end;

  procedure PreFocus(DBP : DialogBoxPtr); far;
  var
    S : String;

  begin
    S := StringFromHeap(EntryFieldPtr(DBP^.asCurrent)^.sfFieldName);
    FastText(Pad(Copy(S, 1, 78), 78), ScreenHeight, 2);
  end;

  procedure SetHelpString(DB : DialogBoxPtr; S : String);
  begin
    SelectFieldPtr(DB^.asFields.Tail)^.sfFieldName := StringToHeap(S);
  end;

  function InitFileTypeDialog(var FT : Byte; FName : TFileNameStr;
                              CasFiles, AllowAPF : Boolean) : DialogBoxPtr;
  var
    DB : DialogBoxPtr;

  begin
    InitFileTypeDialog := nil;

    New(DB, InitCustom( 22, 7, 59, 18,
                        DialogColors,
                        wBordered+wClear+wUserContents,
                        ClusterColors ));
    if (DB = nil) then
      Exit;
    SetDialogOptions(DB);


    with DB^ do begin
      SetPreFocusProc(PreFocus);
      wFrame.AddHeader(' File Type ', heTC);

      AddTextField('What type of file is ' + FName + '?', 2, 3);

      {!!.03 - Made larger}
      AddRadioButtons('', 1, 1, 4, 3, 34, 6 + Ord(AllowAPF), 34, 0, FT);
      SetHelpString(DB, 'Select the format that the input file is in');

        AddRadioButton('DOS &text file', ftTEXT);
        AddRadioButton('&PCX graphics file', ftPCX);
        AddRadioButton('&DCX graphics file', ftDCX);

        if not CasFiles then
          AddRadioButton('TI&FF image file', ftTIFF);

        if not CasFiles then                            {!!.03}
          AddRadioButton('Windows &BMP', ftBMP);        {!!.03}

        if not CasFiles and AllowAPF then
          AddRadioButton('APF APRO fax format', ftAPF);

      AddPushButton(OkButton, 10, 17, 8, 0, ccSelect, True);
      SetHelpString(DB, 'Click or select this button to choose the file type');

      AddPushButton(CancelButton, 10, 29, 8, 0, ccQuit, False);
      SetHelpString(DB, 'Click or select this button to cancel the selection of this file');

      SetChildErrorProc(DB, ShowError);

      InitStatus := RawError;
    end;

    if (InitStatus = 0) then
      InitFileTypeDialog := DB;
  end;

  function InitAboutBox : DialogBoxPtr;
  var
    DB : DialogBoxPtr;

  begin
    InitAboutBox := nil;

    New(DB, InitCustom( 18, 5, 62, 19,
                        DialogColors,
                        wBordered+wClear+wUserContents,
                        ClusterColors ));
    if (DB = nil) then
      Exit;
    SetDialogOptions(DB);

    with DB^ do begin
      SetPreFocusProc(PreFocus);
      wFrame.AddHeader(' About TPFAX ', heTC);
      AddTextField('TPFAX v2.03: OOP Fax Send Program', 2, 7);
      AddTextField('Created with Object Professional', 3, 7);
      AddTextField('and Async Professional', 4, 12);

      AddTextField('Copyright (c) 1993 by TurboPower Software', 6, 3);
      AddTextField('P.O. BOX 49009', 8, 16);
      AddTextField('Colorado Springs, CO  80949-9009', 9, 7);

      AddTextField('Technical support: (719) 260-6641', 11, 7);
      AddTextField('Order line       : (800) 333-4160', 12, 7);

      AddPushButton(OkButton, 14, 19, 8, 0, ccSelect, True);
      SetHelpString(DB, 'Click on or select ''Ok'' to return to the main menu');

      InitStatus := RawError;
    end;

    if (InitStatus = 0) then
      InitAboutBox := DB;
  end;

  function InitYesNoBox(Message, Header : String) : DialogBoxPtr;
  begin
    InitYesNoBox := InitChoiceBox(Message, Header, YesButton, DlgStuff.NoButton,
                                  DialogColors, ClusterColors);
  end;

  function YesNo(Message, Header : String) : Boolean;
  var
    DB : DialogBoxPtr;
    Ch : Char;

  begin
    DB := InitYesNoBox(Message, Header);
    if (DB = nil) then begin
      ClearStatus;
      FastText(Message + ' [Y/N] ', ScreenHeight, 2);
      repeat
        Ch := UpCase(ReadKey);
      until (Ch = 'N') or (Ch = 'Y');
      YesNo := (Ch = 'Y');
    end else begin
      YesNo := ProcessDialog(DB) = ccSelect;
      DB^.Erase;
      Dispose(DB, Done);
    end;
  end;

  { find an error message string in a table }
  procedure GetErrorMessage(Code : Word; Table : Pointer; var Dest : String); assembler;
  asm
    push    ds
    lds     si,Table    { DS:SI points to error table        }
    les     di,Dest     { ES:DI points to destination string }
    cld                 { go forward }
    mov     bx,Code     { BX = error code, for faster cmps   }

@1: lodsw               { load the first error code in table }
    or      ax,ax       { end of the table reached?          }
    jz      @2          { yes, return a null string          }
    cmp     ax,bx       { is this the error code we want?    }
    je      @4          { if so, do something with it        }
    xor     ax,ax       { if not, skip to the next code...   }
    lodsb               { ...by loading this length byte...  }
    add     si,ax       { ...and skipping the string         }
    jmp     @1

@4: xor     cx,cx
    lodsb               { load the length byte               }
    mov     cl,al       { store it in CL                     }
    stosb               { store it in the dest string        }
    jcxz    @3          { if the string is empty, exit       }
    rep     movsb       { store the error string             }

    jmp     @3          { get the heck out of here           }

@2: xor     ax,ax       { store a null string                }
    stosb

@3: pop     ds
  end;

  procedure ShowErrorMessage(Msg : String);
  var
    DB : DialogBoxPtr;

  begin
    DB := InitMessageBox(Msg, ' Error! ', OkButton, ErrorColors, eColors);
    if (DB = nil) then begin
      ClearStatus;
      FastText(Copy(' ' + Msg + ' [ Any Key ]', 1, 78), ScreenHeight, 1);
      RingBell;
      ReadKeyWord;
    end else begin
      ProcessDialog(DB);
      DB^.Erase;
      Dispose(DB, Done);
    end;
  end;

  procedure ShowError(UnitCode : Byte; var ErrorCode : Word;
                      ErrorMsg : string);
  begin
    GetErrorMessage(ErrorCode mod 10000, @Error_Table, ErrorMsg);
    if (ErrorMsg = '') then
      ErrorMsg := 'Unrecognized error code #' + Long2Str(ErrorCode);

    ShowErrorMessage(ErrorMsg);
  end;

  procedure PortShowError(P : Pointer; var StatusCode : Word);
  var
    Raw : Word;
    F   : Text;

  begin
    Assign(F, 'BLAH.ERR');
    if not ExistFile('BLAH.ERR') then
      Rewrite(F)
    else
      Append(F);
    WriteLn(F, StatusCode mod 10000);
    Close(F);
  end;

  procedure cfDriveListPostEdit(CB : ComboBoxPtr; DBP : AltDialogPtr); far;
  begin
    with PSelectCvtFilesDlg(DBP)^ do
      if (cfDriveDisp[2] <> cfFiles.sfCurDir[1]) then
        SwitchDrives;
  end;

  procedure BlankPrePostCombo(CB : ComboBoxPtr; DBP : AltDialogPtr); far;
  begin
  end;

  procedure afDriveListPostEdit(CB : ComboBoxPtr; DBP : AltDialogPtr); far;
  begin
    with PSelectApfFilesDlg(DBP)^ do
      if (afDriveDisp[2] <> afFileList^.diMask[1]) then
        SwitchDrives;
  end;

  procedure FileHistoryPostEdit(CB : ComboBoxPtr; DBP : AltDialogPtr); far;
  var
    S  : String;
    IT : pkItemType;

  begin
    with CB^, cbPickBox^ do
      if (GetLastCommand = ccSelect) then begin
        ItemString(pkChoice, pkDisplay, IT, S);
        HistoryListBoxPtr(cbPickBox)^.AddEntry(S);
      end;
  end;

  procedure ApfSelMoveProc(P : PickListPtr); far;
  begin
    if not FlagIsSet(P^.pkSecFlags, pkFakingOneItem) then
      with PSelectApfFilesDlg(P^.wParentPtr)^ do begin
        afFileName := DirListPtr(P)^.GetLastChoiceString;
        DrawField(afFileNameID);
      end;
  end;

  constructor TSelectCvtFilesDlg.Init(CasFiles, AllowAPF, ApfOnly : Boolean;
                                      Header : String; History : HistoryListPtr);
  var
    S : String;
    A : Boolean;

    procedure CleanUp;
    begin
      if A then
        cfFiles.Done;
      if (cfDirTree <> nil) then
        Dispose(cfDirTree, Done);
      if (cfUnselFiles <> nil) then
        Dispose(cfDirTree, Done);
      if (cfSelFiles <> nil) then
        Dispose(cfSelFiles, Done);
      if (cfDrives <> nil) then
        Dispose(cfDrives, Done);
      if (cfFileHist <> nil) then
        Dispose(cfFileHist, Done);
      AltDialog.Done;
    end;

    procedure InitPointers;
    begin
      A            := False;
      cfDirTree    := nil;
      cfUnselFiles := nil;
      cfSelFiles   := nil;
      cfDrives     := nil;
      cfFileHist   := nil;
    end;

  begin
    OneMomentPlease;
    InitPointers;
    cfCasFiles := CasFiles;
    cfAllowAPF := AllowAPF;
    cfApfOnly  := ApfOnly;

    if not AltDialog.InitCustom(8, 3, 73, 23,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then
      Fail;
    SetDialogOptions(@Self);
    SetPreFocusProc(PreFocus);

    wFrame.AddHeader(Header, heTC);

    if not cfFiles.Init then begin
      CleanUp;
      Fail;
    end;
    A := True;

    New(cfDirTree, Init(10, 5));
    if (cfDirTree = nil) then begin
      CleanUp;
      Fail;
    end;

    New(cfUnselFiles, Init(@Self));
    if (cfUnselFiles = nil) then begin
      CleanUp;
      Fail;
    end;

    New(cfSelFiles, Init(@Self));
    if (cfSelFiles = nil) then begin
      CleanUp;
      Fail;
    end;

    New(cfDrives, Init(62, 5));
    if (cfDrives = nil) then begin
      CleanUp;
      Fail;
    end;

    New(cfFileHist, InitAbstract( 20, 11, 70, 15,
                                  DropBoxColors,
                                  wBordered+wClear+wUserContents,
                                  51, History^.hlNumEntries, PickVertical, SingleChoice ));
    if (cfFileHist = nil) then begin
      CleanUp;
      Fail;
    end;
    SetComboListOptions(cfFileHist, DropBoxColors);
    with cfFileHist^ do begin
      InitStatus := GetLastError;
      if (InitStatus <> 0) then begin
        CleanUp;
        Fail;
      end;
      SetHistory(History);
    end;

    GetDir(0, S);
    cfDriveDisp := ' ' + Copy(S, 1, 2);

    cfFiles.AssembleUnselected(AddBackslash(S) + '*.*');
    InitStatus := cfFiles.GetLastError;
    if (InitStatus <> 0) then begin
      CleanUp;
      Fail;
    end;

    cfUnselFiles^.ChangeNumItems(cfFiles.GetNumUnsel);

    cfFileName := '';

    {idDirTree:}
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Directories', 2, 3,
      3, 3, 0, ccChangeDir, cfDirTree^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Select a new directory on your disk');

    {idDriveList:}
    dgFieldOptionsOn(efReadOnly);
    AddComboBox(
      'Dri&ves', 2, 56,
      'XXXXXXX', 3, 56, 7, 0,
      cfDriveDisp, cfDrives,
      BlankPrePostCombo, cfDriveListPostEdit);
    dgFieldOptionsOff(efReadOnly);
    SetHelpString(@Self, 'Change to a different drive');

    {idFileName:}
    AddComboBox(
      '&File name:', 9, 3,
      CharStr('!', 49), 9, 14, 49, 0,
      cfFileName, cfFileHist, BlankPrePostCombo, FileHistoryPostEdit);
    SetHelpString(@Self, 'Enter the name of the file you want to select or a new file mask');

    {idUnselFiles:}
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Available files', 11, 3,
      12, 3, 0, ccSelectFile, cfUnselFiles^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Files available for processing in the displayed directory');

    AddPushButton('¯¯ Se&lect ¯¯', 13, 24, 14, 0, ccSelectFile, False);
    SetHelpString(@Self, 'Select all tagged files in the ''Available files'' list');

    AddPushButton('®® &Remove ®®', 15, 24, 14, 0, ccRemoveFile, False);
    SetHelpString(@Self, 'Remove all tagged files from the ''Selected files'' list');

    AddPushButton(OkButton, 17, 24, 14, 0, ccSelect, True);
    SetHelpString(@Self, 'Click or select this button to begin processing');

    AddPushButton(CancelButton, 19, 24, 14, 0, ccQuit, False);
    SetHelpString(@Self, 'Click or select this button to cancel the operation');

    {idSelFiles:}
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Selected files', 11, 44,
      12, 44, 0, ccRemoveFile, cfSelFiles^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Files you have selected');

    AddPushButton('Refres&h', 6, 56, 9, 0, ccRefreshTree, False);
    SetHelpString(@Self, 'Refresh the directory tree from the disk');

    SetChildErrorProc(@Self, ShowError);

    InitStatus := RawError;
    if (InitStatus <> 0) then begin
      CleanUp;
      Fail;
    end;
  end;

  destructor TSelectCvtFilesDlg.Done;
  begin
    cfFiles.Done;
    AltDialog.Done;
  end;

  procedure TSelectCvtFilesDlg.SetDefaultMask;
  begin
    cfFileName := JustFileName(cfFileName);
    if not ContainsWildCards(cfFileName) then
      cfFileName := '*.*';
  end;

  procedure TSelectCvtFilesDlg.SwitchDrives;
  begin
    OneMomentPlease;
    with cfDirTree^ do begin
      { load the new directory tree }
      SetDrive(cfDriveDisp[2]);
      TreeManager.ReadTree(cfDirTree);
      cwError := TreeManager.GetLastError;
      if (cwError <> 0) then
        Exit;
    end;

    SetDefaultMask;

    with cfFiles do begin
      AssembleUnselected(
        AddBackslash(cfDirTree^.GetDisplayedPath) + cfFileName);
      cwError := GetLastError;
      if (cwError <> 0) then begin
        GotError(cwError, emNullError);
        Exit;
      end;
    end;

    with cfUnselFiles^ do begin
      ChangeNumItems(cfFiles.GetNumUnsel);
      SetInitialChoice(1);
    end;

    cfFileName := '';
    cfDirTree^.UpdateContents;
    DrawField(cfDriveListID);
    DrawField(cfFileNameID);
    cfUnselFiles^.UpdateContents;
  end;

  procedure TSelectCvtFilesDlg.CheckFileName;
  var
    P  : DirStr;
    F  : TFileNameStr;
    CT : CvtFileType;

  begin
    if (asCurID <> cfFileNameID) or (cfFileName = '') then
      Exit;

    if ContainsWildCards(cfFileName) then begin
      OneMomentPlease;
      { find out if a valid path/file name has been entered }
      P := JustPathName(cfFileName);
      F := JustFileName(cfFileName);

      if (P <> '') and (Length(P) > 2) then
        if (P[2] <> ':') then
          P := cfDriveDisp[2] + ':' + P;

      if not IsDirectory(P) then begin
        GotError(epNonFatal+ecPathNotFound, emNullError);
        Exit;
      end;

      { see if the DRIVE has changed }
      if (Length(cfFileName) > 2) and (cfFileName[2] = ':') and
         (cfFileName[1] <> cfDriveDisp[2]) then begin
        cfDriveDisp := ' ' + Copy(cfFileName, 1, 2);
        cfDirTree^.SetDrive(cfDriveDisp[2]);

        TreeManager.ReadTree(cfDirTree);
        (* cfDirTree^.PreloadPathList; *)

        cwError := TreeManager.GetLastError;
        if (cwError <> 0) then
          Exit;
      end;

      if (P <> cfDirTree^.GetDisplayedPath) then
        cfDirTree^.SetDirectory(P);

      { now, assemble a new unselected list }
      cfFiles.AssembleUnselected(AddBackslash(P) + F);
      cwError := (cfFiles.GetLastError);
      if (cwError <> 0) then begin
        GotError(cwError, emNullError);
        Exit;
      end;

      cfFileName := '';

      { update the screen }
      cfDirTree^.UpdateContents;
      DrawField(cfDriveListID);
      DrawField(cfFileNameID);
      cfUnselFiles^.ChangeNumItems(cfFiles.GetNumUnsel);
      cfUnselFiles^.UpdateContents;
      SetLastCommand(ccNone);

    end else begin

      if (JustPathName(cfFileName) = '') then
        cfFileName := AddBackslash(cfFiles.sfCurDir) + cfFileName;

      if not ExistFile(cfFileName) then begin
        GotError(epNonFatal+ecFileNotFound, emNullError);
        Exit;
      end;

      cfFileName := FullPathName(cfFileName);

      { see if the file is in the selected list }
      if cfFiles.sfIsSel(cfFileName) then
        cfFiles.RemoveFromSelected(cfFileName)
      else begin
        if not GetFileType(cfFileName, CT) then begin
          SetLastCommand(ccNone);
          Exit;
        end;
        cfFiles.AddToSelected(cfFileName, CT);
      end;

      cwError := cfFiles.GetLastError;
      if (cwError <> 0) then begin
        GotError(cwError, emNullError);
        Exit;
      end;

      { update the selected and unselected list displays }

      with cfUnselFiles^ do begin
        ChangeNumItems(cfFiles.GetNumUnsel);
        SetInitialChoice(1);
        UpdateContents;
      end;

      with cfSelFiles^ do begin
        ChangeNumItems(cfFiles.GetNumSel);
        SetInitialChoice(1);
        UpdateContents;
      end;

      cfFileName := '';

      DrawField(cfFileNameID);
      cfUnselFiles^.UpdateContents;
      cfSelFiles^.UpdateContents;

      SetLastCommand(ccNone);
    end;
  end;

  procedure TSelectCvtFilesDlg.ChangeDirectory;
  begin
    OneMomentPlease;
    SetDefaultMask;

    cfFiles.AssembleUnselected(
      AddBackslash(cfDirTree^.GetDisplayedPath) + cfFileName);

    cwError := cfFiles.GetLastError;
    if (cwError <> 0) then begin
      GotError(cwError, emNullError);
      Exit;
    end;

    cfFileName := '';

    with cfUnselFiles^ do begin
      ClearSelected;
      SetInitialChoice(1);
      ChangeNumItems(cfFiles.GetNumUnsel);
      UpdateContents;
    end;
    DrawField(cfFileNameID);
  end;

  function IsAnAPFFile(FName : PathStr) : Boolean;
  var
    F   : File;
    Sig : array[0..5] of Char;

  begin

    { open the file }
    IsAnAPFFile := False;
    Assign(F, FName);
    Reset(F, 1);
    if (IoResult <> 0) then
      Exit;

    { read in what ought to be a signature }
    BlockRead(F, Sig, SizeOf(Sig));
    if (IoResult <> 0) then begin
      Close(F);
      Exit;
    end;
    Close(F); if (IoResult = 0) then ;

    IsAnAPFFile := (CompStruct(DefSig, Sig, SizeOf(Sig)) = Equal);
  end;

  function TSelectCvtFilesDlg.GetFileType(FName : PathStr; var CT : CvtFileType) : Boolean;
  var
    Ext    : ExtStr;
    DB     : DialogBoxPtr;
    FType  : CvtFileType;
    Top    : CvtFileType;
    Result : Boolean;

    function CheckApf : Boolean;
    begin
      CheckAPF := True;
      if not IsAnAPFFile(FName) then begin
        ShowErrorMessage(JustFileName(FName) + ' is not a valid Async Professional fax file');
        CheckAPF := False;
      end;
    end;

  begin
    GetFileType := True;
    if cfApfOnly then begin
      if not CheckAPF then begin
        GetFileType := False;
        Exit;
      end else
        CT := ftAPF
    end else begin
      Ext := JustExtension(FName);
      if cfAllowAPF then
        Top := ftAPF
      else
        Top := ftBMP;

      for FType := ftTEXT to Top do
        if (Ext = FileTypeExtensions[FType]) then begin
          CT := FType;
          Exit;
        end;

      CT := ftTEXT;
      DB := InitFileTypeDialog( Byte(CT), JustFileName(FName),
                                cfCasFiles, not cfCasFiles and cfAllowAPF);
      if (DB = nil) then begin
        GetFileType := False;
        Exit;
      end;

      Result := (ProcessDialog(DB) = ccSelect);
      DB^.Erase;
      Dispose(DB, Done);
      if Result and cfAllowApf and (CT = ftAPF) then
        Result := CheckApf;
      GetFileType := Result;
    end;
  end;

  procedure TSelectCvtFilesDlg.AddToSelected;
  var
    I      : Word;
    NumSel : Word;
    CT     : CvtFileType;

  begin
    with cfUnselFiles^ do begin
      if FlagIsSet(pkSecFlags, pkFakingOneItem) then
        Exit;

      if (GetSelectedCount = 0) then begin
        { add only the currently highlighted file }
        if GetFileType(cfFiles.GetQualUnselFile(GetLastChoice), CT) then begin
          cfFiles.SelectFile(GetLastChoice, CT);
          ChangeNumItems(cfFiles.GetNumUnsel);
          UpdateContents;
        end;
      end else begin
        NumSel := 0;
        InitSequence(I);
        while HaveSelected(I) do begin
          if GetFileType(cfFiles.GetQualUnselFile(I - NumSel), CT) then begin
            cfFiles.SelectFile(I - NumSel, CT);
            Inc(NumSel);
          end;
          NextSelected(I);
        end;
        ChangeNumItems(cfFiles.GetNumUnsel);
      end;

      ClearSelected;
    end;

    with cfSelFiles^ do begin
      ChangeNumItems(cfFiles.GetNumSel);
      UpdateContents;
      pkChoice := 1;
    end;
  end;

  procedure TSelectCvtFilesDlg.RemoveFromSelected;
  var
    I      : Word;
    NumSel : Word;

  begin
    with cfSelFiles^ do begin
      if FlagIsSet(pkSecFlags, pkFakingOneItem) then
        Exit;

      if (GetSelectedCount = 0) then begin
        { unselect only the currently highlighted file }
        cfFiles.UnselectFile(GetLastChoice);
        ChangeNumItems(cfFiles.GetNumSel);
        UpdateContents;
      end else begin
        NumSel := 0;
        InitSequence(I);
        while HaveSelected(I) do begin
          cfFiles.UnselectFile(I - NumSel);
          NextSelected(I);
          Inc(NumSel);
        end;
        ChangeNumItems(cfFiles.GetNumSel);
      end;

      ClearSelected;
    end;

    with cfUnselFiles^ do begin
      ChangeNumItems(cfFiles.GetNumUnsel);
      UpdateContents;
      pkChoice := 1;
    end;
  end;

  procedure TSelectCvtFilesDlg.RefreshTree;
  begin
    OneMomentPlease;
    TreeManager.Refresh(cfDirTree);
    cfDirTree^.paSetChoiceCurDir;
    cfDirTree^.UpdateContents;
    SetLastCommand(ccNone);
  end;

  procedure TSelectCvtFilesDlg.ClearForStatus;
  begin
    ActivateWrite;
    with cfSelFiles^ do begin
      SetInitialChoice(1);
      if pkOptionsAreOn(pkBitSetAlloc) then
        pkSelectSet.ClearAll;
      UpdateContents;
    end;

    with cfUnselFiles^ do begin
      SetInitialChoice(1);
      if pkOptionsAreOn(pkBitSetAlloc) then
        pkSelectSet.ClearAll;
      UpdateContents;
    end;
    DeactivateWrite;
  end;

  procedure TSelectCvtFilesDlg.UpdateForStatus(Index : Word);
  begin
    ActivateWrite;
    with cfSelFiles^ do begin
      ChangeNumItems(cfFiles.GetNumSel);
      SetInitialChoice(MinWord(Index, GetNumItems));
      UpdateContents;
    end;
    DeactivateWrite;
  end;

  procedure TSelectCvtFilesDlg.dgPostFocus;
  begin
    if (asCurID = cfFileNameID) then
      if (cwCmd <> ccComboTrigger) then
        cfFileHist^.AddEntry(cfFileName);
  end;

  procedure TSelectCvtFilesDlg.ProcessSelf;
  var
    Err : Word;

  begin
    AltDialog.ProcessSelf;
    case cwCmd of
      ccSelect     : CheckFileName;
      ccChangeDir  : ChangeDirectory;
      ccSelectFile : AddToSelected;
      ccRemoveFile : RemoveFromSelected;
      ccRefreshTree: RefreshTree;
    end;

    Err := RawError;
    if (Err <> 0) and ((Err div 10000) = etFatal) then
      SetLastCommand(ccError)
    else if (Err <> 0) then
      SetLastCommand(ccNone);
  end;

  constructor TSelectApfFilesDlg.Init(Header : String; History : HistoryListPtr);
  var
    S : String;

    procedure CleanUp;
    begin
      if (afDirTree <> nil) then
        Dispose(afDirTree, Done);
      if (afDriveList <> nil) then
        Dispose(afDriveList, Done);
      if (afFileHist <> nil) then
        Dispose(afFileHist, Done);
      if (afFileList <> nil) then
        Dispose(afFileList, Done);
      Done;
    end;

    procedure InitPointers;
    begin
      afDirTree   := nil;
      afDriveList := nil;
      afFileHist  := nil;
      afFileList  := nil;
    end;

  begin
    OneMomentPlease;
    InitPointers;

    if not AltDialog.InitCustom(7, 4, 73, 22,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then
      Fail;
    SetDialogOptions(@Self);
    SetPreFocusProc(PreFocus);

    New(afDirTree, Init(9, 5));
    if (afDirTree = nil) then begin
      CleanUp;
      Fail;
    end;

    New(afDriveList, Init(62, 5));   {!!.01}
    if (afDriveList = nil) then begin
      CleanUp;
      Fail;
    end;

    New(afFileHist, InitAbstract( 19, 11, 69, 15,
                                  DropBoxColors,
                                  wBordered+wClear+wUserContents,
                                  51, History^.hlNumEntries, PickVertical, SingleChoice ));
    if (afFileHist = nil) then begin
      CleanUp;
      Fail;
    end;

    SetComboListOptions(afFileHist, DropBoxColors);
    with afFileHist^ do begin
      initStatus := GetLastError;
      if (InitStatus <> 0) then begin
        CleanUp;
        Fail;
      end;
      SetHistory(History);
    end;

    GetDir(0, S);
    afDriveDisp := ' ' + Copy(S, 1, 2);

    New(afFileList, InitCustom( 10, 14, 73, 18,
                                DialogColors,
                                wClear+wUserContents+wNoCoversBuffer+wResizeable,
                                8000, PickSnaking, SingleFile));
    if (afFileList = nil) then begin
      CleanUp;
      Fail;
    end;
    with afFileList^ do begin
      ResizeWindow(-1, 0);
      SetPickOptions(afFileList, frBB, DialogColors, ClusterColors);
      EnableDividers(NoFrameChar, '³', NoFrameChar);
      SetPadSize(1, 2);
      diOptionsOn(diFilesUpcase);
      SetMask(AddBackslash(S) + '*.AP?', AnyFile - Directory);
      SetMoveProc(ApfSelMoveProc);
      PreloadDirList;
    end;

    wFrame.AddHeader(Header, heTC);

    {afDirTreeID:}
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Directories', 1, 3,
      2, 3, 0, ccChangeDir, afDirTree^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Select a new directory on your disk');

    {afDriveListID:}
    dgFieldOptionsOn(efReadOnly);
    AddComboBox(
      'Dri&ves', 1, 57,
      CharStr('!', 7), 2, 57, 7, 0,
      afDriveDisp, afDriveList, BlankPrePostCombo, afDriveListPostEdit);
    dgfieldOptionsOff(efReadOnly);
    SetHelpString(@Self, 'Change to a different drive');

    afFileName := '*.AP?';

    {afFileNameID:}
    AddComboBox(
      '&File name:', 8, 3,
      CharStr('!', 49), 8, 14, 49, 0,
      afFileName, afFileHist, BlankPrePostCombo, BlankPrePostCombo);
    SetHelpString(@Self, 'Enter the name of the file you want or a new file mask');

    {afFileListID:}
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Available files', 10, 3, 11, 3, 0, ccSelect, afFileList^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Available APF files in the selected directory');

    AddPushButton(OkButton, 18, 45, 8, 0, ccSelect, True);
    SetHelpString(@Self, 'Click or select this button to select the specified file');

    AddPushButton(CancelButton, 18, 57, 8, 0, ccQuit, False);
    SetHelpString(@Self, 'Click or select this button to cancel the operation');

    AddPushButton('Refres&h', 5, 57, 9, 0, ccRefreshTree, False);
    SetHelpString(@Self, 'Refresh the directory tree from the disk');

    SetChildErrorProc(@Self, ShowError);

    InitStatus := RawError;

    if (InitStatus <> 0) then begin
      CleanUp;
      Fail;
    end;
  end;

  destructor TSelectApfFilesDlg.Done;
  begin
    AltDialog.Done;
  end;

  procedure TSelectApfFilesDlg.SwitchDrives;
  begin
    OneMomentPlease;
    with afDirTree^ do begin
      { load the new directory tree }
      SetDrive(afDriveDisp[2]);

      TreeManager.ReadTree(afDirTree);
      (* PreloadPathList; *)
      cwError := TreeManager.GetLastError;
      if (cwError <> 0) then
        Exit;
    end;

    afFileName := '*.AP?';

    with afFileList^ do begin
      SetMask(AddBackslash(afDirTree^.GetDisplayedPath) + afFileName,
                AnyFile - Directory);
      PreloadDirList;
      cwError := GetLastError;
      if (cwError <> 0) then
        Exit;
    end;

    afDirTree^.UpdateContents;
    DrawField(afFileNameID);
    afFileList^.UpdateContents;
  end;

  procedure TSelectApfFilesDlg.ChangeDirectory;
  var
    Temp : PathStr;

  begin
    with afFileList^ do begin
      Temp := AddBackslash(afDirTree^.GetDisplayedPath);
      if ContainsWildCards(afFileName) then
        Temp := Temp + JustFileName(afFileName)
      else
        Temp := Temp + '*.AP?';

      SetMask(Temp, AnyFile - Directory);

      PreloadDirList;
      cwError := GetLastError;
      if (cwError <> 0) then
        Exit;

      afFileName := JustFileName(Temp);
    end;

    DrawField(afFileNameID);
    afFileList^.UpdateContents;
  end;

  procedure TSelectApfFilesDlg.CheckFileName;
  var
    P : DirStr;
    F : TFileNameStr;

  begin
    if (afFileName = '') then
      Exit;

    if IsDirectory(afFileName) then
      afFileName := AddBackslash(afFileName) + '*.AP?';

    if ContainsWildCards(afFileName) then begin
      OneMomentPlease;

      { find out if a valid path/file name has been entered }
      P := JustPathName(afFileName);
      F := JustFileName(afFileName);

      if (P <> '') and (Length(P) > 2) then
        if (P[2] <> ':') then
          P := afDriveDisp[2] + ':' + P;

      if not IsDirectory(P) then begin
        GotError(epNonFatal+ecPathNotFound, emNullError);
        Exit;
      end;

      { see if the DRIVE has changed }
      if (Length(afFileName) > 2) and (afFileName[2] = ':') and
         (afFileName[1] <> afDriveDisp[2]) then begin
        afDriveDisp := ' ' + Copy(afFileName, 1, 2);
        afDirTree^.SetDrive(afDriveDisp[2]);

        TreeManager.ReadTree(afDirTree);
        (* afDirTree^.PreloadPathList; *)
        cwError := TreeManager.GetLastError;
        if (cwError <> 0) then
          Exit;
      end;

      if (P = '') then
        P := afDirTree^.GetDisplayedPath;

      if (P <> afDirTree^.GetDisplayedPath) then
        afDirTree^.SetDirectory(P);

      { assemble a new list of files }
      afFileList^.SetMask(AddBackslash(P) + F, AnyFile - Directory);
      afFileList^.PreloadDirList;
      cwError := afFileList^.GetLastError;
      if (cwError <> 0) then
        Exit;

      afFileName := F;

      { update the screen }
      afDirTree^.UpdateContents;
      DrawField(afDriveListID);
      DrawField(afFileNameID);
      afFileLIst^.UpdateContents;
      SetLastCommand(ccNone);

    end else begin

      if (JustPathName(afFileName) = '') then
        afFileName := AddBackslash(JustPathName(afFileList^.diMask)) + afFileName;

      if not ExistFile(afFileName) then begin
        GotError(epNonFatal+ecFileNotFound, emNullError);
        Exit;
      end;

      if not IsAnAPFFile(afFileName) then begin
        SetLastCommand(ccNone);
        ShowErrorMessage(afFileName + ' is not a valid Async Professional fax file');
        Exit;
      end;

      afFileName := FullPathName(afFileName);

    end;
  end;

  function TSelectApfFilesDlg.GetFileName : PathStr;
  begin
    GetFileName := afFileName;
  end;

  procedure TSelectApfFilesDlg.RefreshTree;
  begin
    OneMomentPlease;
    TreeManager.Refresh(afDirTree);
    afDirTree^.UpdateContents;
    afDirTree^.paSetChoiceCurDir;
    SetLastCommand(ccNone);
  end;

  procedure TSelectApfFilesDlg.ProcessSelf;
  var
    Err : Word;

  begin
    AltDialog.ProcessSelf;

    case cwCmd of
      ccChangeDir   : ChangeDirectory;
      ccSelect      : CheckFileName;
      ccRefreshTree : RefreshTree;
    end;

    Err := RawError;
    if (Err <> 0) and ((Err div 10000) = etFatal) then
      SetLastCommand(ccError)
    else if (Err <> 0) then
      SetLastCommand(ccNone);
  end;

  procedure TSelectApfFilesDlg.dgPostFocus;
  begin
    if (asCurID = afFileNameID) and (cwCmd <> ccComboTrigger) then
      afFileHist^.AddEntry(afFileName);
  end;

  constructor TDirTree.Init(X, Y : Byte);
  begin
    if not XTreePathList.InitCustom(X, Y, X + 49, Y + 4,
                                    DialogColors,
                                    wClear+wUserContents+wNoCoversBuffer,
                                    SizeOf(PathRec) * 800,
                                    PickVertical, SinglePath) then
      Fail;
    paOptionsOff(paOptimizeSize);
    paOptionsOn(paUpCase);
    SetPickOptions(@Self, frRR, DialogColors, ClusterColors);

    TreeManager.ReadTree(@Self);
    (* PreloadPathList; *)
    InitStatus := TreeManager.GetLastError;
    if (InitStatus <> 0) then
      Fail;
  end;

  function TDirTree.GetDisplayedPath : DirStr;
  begin
    GetDisplayedPath := GetMultiPath(pkChoice);
  end;

  procedure TDirTree.SetDirectory(Dir : DirStr);
  var
    I : Word;

  begin
    for I := 1 to paMaxFiles do
      if (GetMultiPath(I) = Dir) then begin
        SetInitialChoice(I);
        if FlagIsSet(paFlags, paAltCurDir) then
          paDPtr^[I].PCat := pkAlternate;
        Exit;
      end;
  end;

  constructor TUnselList.Init(P : PSelectCvtFilesDlg);
  begin
    ListParent := P;

    if not PickList.InitAbstract( 10, 14, 23, 23,
                                  DialogColors,
                                  wClear+wUserContents+wNoCoversBuffer,
                                  14, ListParent^.cfFiles.GetNumUnsel,
                                  PickVertical, MultipleChoice ) then
      Fail;
    SetPickOptions(@Self, frRR, DialogColors, ClusterColors);
    SetSelectMarker('*', #0);
  end;

  procedure TUnselList.ItemString(    Item    : Word;
                                      Mode    : pkMode;
                                  var IType   : pkItemType;
                                  var IString : String);
  begin
    if (Mode <> pkGetType) then
      IString := ListParent^.cfFiles.GetUnselFile(Item);
  end;

  constructor TSelList.Init(P : PSelectCvtFilesDlg);
  begin
    ListParent := P;

    if not PickList.InitAbstract( 51, 14, 70, 23,
                                  DialogColors,
                                  wClear+wUserContents+wNoCoversBuffer,
                                  20, 0,
                                  PickVertical, MultipleChoice ) then
      Fail;
    SetPickOptions(@Self, frRR, DialogColors, ClusterColors);
    SetSelectMarker('*', #0);
  end;

  procedure TSelList.ItemString(    Item    : Word;
                                    Mode    : pkMode;
                                var IType   : pkItemType;
                                var IString : String);
  begin
    if (Mode = pkDisplay) then
      IString := ListParent^.cfFiles.GetSelFile(Item)
    else if (Mode = pkSearch) then
      IString := Copy(ListParent^.cfFiles.GetSelFile(Item), 1, 12);
  end;

  (*constructor TDriveList.Init(X, Y : Byte; P : PSelectCvtFilesDlg);*) {!!.01}
  constructor TDriveList.Init(X, Y : Byte);                             {!!.01}
  var
    D : Char;

  begin
    (*ListParent := P;*)                                                {!!.01}
    FillChar(Drives, SizeOf(Drives), 0);
    NumDrives := 0;

    { assemble drive list }
    for D := 'A' to 'Z' do
      if ValidDrive(D) then begin
        Inc(NumDrives);
        Drives[NumDrives] := D;
      end;

    if not ComboList.InitAbstractDeluxe(X, Y, X + 8, Y + 9,
                                        DropBoxColors,
                                        wBordered+wClear+wUserContents,
                                        9, NumDrives,
                                        PickVertical, SingleChoice,
                                        DefPickOptions or pkMinHeight) then
      Fail;

    SetComboListOptions(@Self, DropBoxColors);
    SetSearchMode(PickCharSearch);
  end;

  procedure TDriveList.ItemString(    Item    : Word;
                                      Mode    : pkMode;
                                  var IType   : pkItemType;
                                  var IString : String);
  begin
    if (Mode = pkDisplay) then
      IString := ' ' + Drives[Item] + ':'
    else if (Mode = pkSearch) then
      IString := Drives[Item];
  end;

  function InitPBEntryDialog(var Name, Num : TEntryString) : DialogBoxPtr;
  var
    DB : DialogBoxPtr;

  begin
    InitPBEntryDialog := nil;

    New(DB, InitCustom( 25, 10, 72, 15,
                        DialogColors,
                        wBordered+wClear+wUserContents,
                        ClusterColors ));
    if (DB = nil) then
      Exit;
    SetDialogOptions(DB);

    with DB^ do begin
      SetPreFocusProc(PreFocus);
      wFrame.AddHeader(' Phonebook Entry ', heTC);

      AddEditControl('&Name', 2, 3, CharStr('X', 20), 3, 3, 20, 0, Name);
      SetHelpString(DB, 'Enter the name of the person or company for this entry');

      AddEditControl('&Phone number', 2, 27, CharStr('X', 20), 3, 27, 20, 0, Num);
      SetHelpString(DB, 'Enter the fax number for this entry');

      AddPushButton(OkButton, 5, 27, 8, 0, ccSelect, True);
      SetHelpString(DB, 'Save the entry and return to the phonebook maintenance dialog');

      AddPushButton(CancelButton, 5, 38, 8, 0, ccQuit, False);
      SetHelpString(DB, 'Cancel changes and return to the phonebook maintenance dialog');

      InitStatus := RawError;
      if (InitStatus = 0) then
        InitPBEntryDialog := DB;
    end;
  end;

  procedure PBItemString(     Item    : Word;
                              Mode    : pkMode;
                          var IType   : pkItemType;
                          var IString : String;
                              PickPtr : PickListPtr); far;
  var
    P : PPhonebookEntry;

  begin
    if (Mode <> pkGetType) then
      with PPhonebookMaintDlg(PickPtr^.wParentPtr)^ do begin
        P := PPhonebookEntry(pmPhonebook.Nth(Item));
        if (P = nil) then
          IString := ''
        else
          IString := Pad(P^.Name, 20) + '   ' + P^.Number;
      end;
  end;

  constructor TPhonebookMaintDlg.Init;
  begin
    if not pmPhonebook.Init then
      Fail;

    if not DialogBox.InitCustom(17, 7, 64, 19,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then begin           {!!.01}
      pmPhonebook.Done;                                             {!!.01}
      Fail;                                                         {!!.01}
    end;                                                            {!!.01}

    SetDialogOptions(@Self);
    SetPreFocusProc(PreFocus);

    New(pmEntryList, InitCustom(18, 7, 62, 16,
                                DialogColors,
                                wClear+wUserContents+wNoCoversBuffer,
                                45, pmPhonebook.Size, PBItemString,
                                PickVertical, SingleChoice));
    if (pmEntryList = nil) then begin
      pmPhonebook.Done;
      Fail;
    end;

    SetPickOptions(pmEntryList, frRR, DialogColors, ClusterColors);
    pmEntryList^.SetPadSize(1, 1);

    wFrame.AddHeader(' Phonebook ', heTC);
    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl('', 1, 1, 1, 2, 0, ccChangeEntry, pmEntryList^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Entries in your phonebook file');

    AddPushButton('&Insert', 12, 3 , 8, 0, ccInsertEntry, False);
    SetHelpString(@Self, 'Add a new entry to the phonebook');

    AddPushButton('&Change', 12, 15, 8, 0, ccChangeEntry, False);
    SetHelpString(@Self, 'Change the highlighted phonebook entry');

    AddPushButton('&Delete', 12, 27, 8, 0, ccDeleteEntry, False);
    SetHelpString(@Self, 'Deleted the highlighted phonebook entry');

    AddPushButton(OkButton , 12, 39, 8, 0, ccSelect, True);
    SetHelpString(@Self, 'Save all phonebook entries to disk and continue');

    SetChildErrorProc(@Self, ShowError);

    InitStatus := RawError;
    if (InitStatus <> 0) then begin
      Done;
      pmPhonebook.Done;
      Fail;                      {!!.01}
    end;
  end;

  destructor TPhonebookMaintDlg.Done;
  begin
    pmPhonebook.Done;
    DialogBox.Done;
  end;

  procedure TPhonebookMaintDlg.AddEntry;
  var
    DB   : DialogBoxPtr;
    Name : TEntryString;
    Num  : TEntryString;
    Cmd  : Word;

  begin
    Name := '';
    Num  := '';

    DB := InitPBEntryDialog(Name, Num);
    if (DB = nil) then begin
      GotError(InitStatus, emNullError);
      Exit;
    end;

    Cmd := ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);

    if (Cmd = ccSelect) then begin
      pmPhonebook.AddEntry(Name, Num);
      if (pmPhonebook.GetLastError = 0) then
        with pmEntryList^ do begin
          ChangeNumItems(pmPhonebook.Size);
          SetInitialChoice(GetNumItems);
          UpdateContents;
        end;
    end;

    { return to the picklist }
    SetLastCommand(ccNone);
    SetNextField(0);
  end;

  procedure TPhonebookMaintDlg.ChangeEntry;
  var
    DB   : DialogBoxPtr;
    P    : PPhonebookEntry;
    Name : TEntryString;
    Num  : TEntryString;
    Cmd  : Word;

  begin
    P := PPhonebookEntry(pmPhonebook.Nth(pmEntryList^.GetLastChoice));
    if (P = nil) then
      Exit;

    Name := P^.Name;
    Num  := P^.Number;

    DB := InitPBEntryDialog(Name, Num);
    if (DB = nil) then begin
      GotError(InitStatus, emNullError);
      Exit;
    end;

    Cmd := ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);

    if (Cmd = ccSelect) then begin
      P^.Name   := Name;
      P^.Number := Num;
      pmEntryList^.UpdateContents;
    end;

    { return to the picklist }
    SetLastCommand(ccNone);
    SetNextField(0);
  end;

  procedure TPhonebookMaintDlg.DeleteEntry;
  var
    P : PPhonebookEntry;

  begin
    P := PPhonebookEntry(pmPhonebook.Nth(pmEntryList^.GetLastChoice));
    if (P = nil) then
      Exit;

    if YesNo('Are you sure you want to delete this entry?', ' Confirm ') then begin
      pmPhonebook.Delete(P);
      with pmEntryList^ do begin
        ChangeNumItems(GetNumItems - 1);
        UpdateContents;
      end;
    end;

    { return to the picklist }
    SetLastCommand(ccNone);
    SetNextField(0);
  end;

  procedure TPhonebookMaintDlg.ProcessSelf;
  var
    Err : Word;

  begin
    DialogBox.ProcessSelf;
    case GetLastCommand of
      ccSelect     : pmPhonebook.Flush;
      ccInsertEntry: AddEntry;
      ccChangeEntry: ChangeEntry;
      ccDeleteEntry: DeleteEntry;
    end;

    Err := RawError;
    if (Err <> 0) and ((Err div 10000) = etFatal) then
      SetLastCommand(ccError)
    else if (Err <> 0) then
      SetLastCommand(ccNone);
  end;

  procedure QueueItemString(    Item    : Word;
                                Mode    : pkMode;
                            var IType   : pkItemType;
                            var IString : String;
                                PickPtr : PickListPtr); far;
  var
    QE : PSendQueueEntry;
    SF : PSendFileNode;
    L  : Byte absolute IString;

  begin
    if (Mode <> pkGetType) then
      with PFaxQueueDialog(PickPtr^.wParentPtr)^ do begin
        IString := '';
        SendQueue.GetNthEntry(QE, Item);
        if (QE = nil) then
          Exit;

        SF := PSendFileNode(QE^.FileList.Head);
        while (SF <> nil) and (L < 28) do begin
          IString := IString + JustFileName(StringFromHeap(SF^.FName));
          SF := PSendFileNode(QE^.FileList.Next(SF));
          if (SF <> nil) and ((L + 1) < 28) then
            IString := IString + ',';
        end;

        if (SF <> nil) or (L > 28) then
          IString := Copy(IString, 1, 25) + '...';

        if (QE^.SendTo <> '') then
          IString :=  Pad(QE^.SendTo, 22) +
                      Pad(IString, 30)
        else
          IString :=  Pad(QE^.SendNum, 22) +
                      Pad(IString, 30);

        if QE^.Immediate then
          IString := IString + 'Immediately'
        else
          IString := IString +  DateToDateString('mm/dd/yy', QE^.SendDate) +
                     ' '     +  TimeToTimeString('hh:mm te', QE^.SendTime);
      end;
  end;

  procedure SendEntryItemString(    Item    : Word;
                                    Mode    : pkMode;
                                var IType   : pkItemType;
                                var IString : String;
                                    PickPtr : PickListPtr); far;
  var
    SF : PSendFileNode;

  begin
    if (Mode <> pkGetType) then
      with PQueueEntryDialog(PickPtr^.wParentPtr)^ do begin
        SF := PSendFileNode(qeEditEntry^.FileList.Nth(Item));
        if (SF = nil) then
          IString := ''
        else
          IString := Pad(Copy(SF^.FName^, 1, 32), 34) +
                     LongIntForm('#####', SF^.FSize) + ' KB';
      end;
  end;

  procedure PBookDropDownPostEdit(CB : ComboBoxPtr; DBP : AltDialogPtr); far;
  var
    PE : PPhonebookEntry;

  begin
    with PPBookDropDown(CB^.cbPickBox)^ do
      if (GetLastCommand = ccSelect) then begin
        PE := PPhonebookEntry(ListParent^.qePhonebook.Nth(GetLastChoice));
        if (PE <> nil) then begin
          ListParent^.qeEditEntry^.SendNum := PE^.Number;
          DBP^.DrawField(fqeNumber);
        end;
      end;
  end;

  constructor TQueueEntryDialog.Init(Entry : PSendQueueEntry);
  var
    PhoneListInit : Boolean;
    SendListInit  : Boolean;
    EditEntryInit : Boolean;
    PhonebookInit : Boolean;
    DlgInit       : Boolean;

    procedure InitFlags;
    begin
      PhoneListInit := False;
      SendListInit := False;
      EditEntryInit := False;
      PhonebookInit := False;
      DlgInit := False;
    end;

    procedure CleanUp;
    begin
      if PhoneListInit then
        Dispose(qePhoneList, Done);
      if SendListInit then
        Dispose(qeSendList, Done);
      if EditEntryInit then
        Dispose(qeOldEntry, Done);
      if PhonebookInit then
        qePhonebook.Done;
      if DlgInit then
        AltDialog.Done;
    end;

  begin
    InitFlags;

    if not qePhonebook.Init then
      Fail;
    PhonebookInit := True;

    New(qePhoneList, Init(@Self));
    if (qePhoneList = nil) then begin
      Cleanup;
      Fail;
    end;
    SetComboListOptions(qePhoneList, DropBoxColors);
    PhoneListInit := True;

    qeOldEntry := Entry;

    New(qeEditEntry, Copy(qeOldEntry));
    if (qeEditEntry = nil) then begin
      InitStatus := epFatal+ecOutOfMemory;
      Cleanup;
      Fail;
    end;

    EditEntryInit := True;

    New(qeSendList, InitCustom( 26, 15, 69, 19,
                                Dialogcolors,
                                wClear+wUserContents+wNoCoversBuffer,
                                44, qeEditEntry^.FileList.Size,
                                SendEntryItemString,
                                PickVertical, SingleChoice));
    if (qeSendList = nil) then begin
      CleanUp;
      Fail;
    end;
    SetPickOptions(qeSendList, frRR, DialogColors, ClusterColors);
    qeSendList^.SetPadSize(1, 1);
    SendListInit := True;

    if not AltDialog.InitCustom(24, 6, 72, 22,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then begin
      Cleanup;
      Fail;
    end;
    SetDialogOptions(@Self);
    SetPreFocusProc(PreFocus);
    DlgInit := True;

    wFrame.AddHeader(' Fax Queue Entry ', heTC);

    AddComboBox(
      '&Send files to', 2, 3,
      CharStr('X', 20), 3, 3, 20, 0, qeEditEntry^.SendTo,
      qePhoneList, BlankPrePostCombo, PBookDropDownPostEdit);
    SetHelpString(@Self, 'Enter the name of the party to whom you are sending this fax');

    dgFieldOptionsOn(efRequired);
    AddEditControl(
      'Fax &number', 2, 28,
      CharStr('X', 20), 3, 28, 20, 0, qeEditEntry^.SendNum);
    dgFieldOptionsOff(efRequired);
    SetHelpString(@Self, 'Enter the fax number of the party to whom you are sending this fax');

    dgControlOptionsOn(dcItemChangeExit);
    AddRadioButtons('Send &when', 5, 3, 6, 3, 23, 2, 23, 0, qeEditEntry^.Immediate);
      AddRadioButton('Immediately', Ord(True));
      AddRadioButton('Specify date/time', Ord(False));
    dgControlOptionsOff(dcItemChangeExit);
    SetHelpString(@Self, 'Choose a send mode for this fax');

    if qeEditEntry^.Immediate then
      dgFieldOptionsOn(efProtected);
    AddDateControl(
      '&Date', 5, 28,
      'mm/dd/yyyy', 6, 28, 10, 0, Today, MaxDate, qeEditEntry^.SendDate);
    SetHelpString(@Self, 'Enter the date on which you want this fax to be sent');

    AddTimeControl(
      '&Time', 5, 40,
      'hh:mm te', 6, 40, 8, 0, 0, 0, qeEditEntry^.SendTime);
    if qeEditEntry^.Immediate then
      dgFieldOptionsOff(efProtected);
    SetHelpString(@Self, 'Enter the time at which you want this fax to be sent');

    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Files to send', 9, 3,
      10, 3, 0, ccDeleteEntry, qeSendList^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Files queued for sending to the specified number');

    AddPushButton('&Insert', 16, 3, 8, 0, ccInsertEntry, False);
    SetHelpString(@Self, 'Queue another file for sending to the specified number');

    AddPushButton('&Delete', 16, 15, 8, 0, ccDeleteEntry, False);
    SetHelpString(@Self, 'Delete the currently highlighted file');

    AddPushButton(OkButton, 16, 27, 8, 0, ccSelect, True);
    SetHelpString(@Self, 'Save this queue entry and continue');

    AddPushButton(CancelButton, 16, 39, 8, 0, ccQuit, False);
    SetHelpString(@Self, 'Cancel changes to this queue entry and continue');

    InitStatus := RawError;
    if (InitStatus <> 0) then begin
      Cleanup;
      Fail;
    end;
    SetChildErrorProc(@Self, ShowError);
  end;

  destructor TQueueEntryDialog.Done;
  begin
    qePhonebook.Done;
    AltDialog.Done;
  end;

  procedure TQueueEntryDialog.ProcessSelf;

    procedure CopyEditEntry;
    begin
      if not qeEditEntry^.Immediate and (qeEditEntry^.SendDate = BadDate) then begin
        ShowErrorMessage('Invalid send date specified');
        SetNextField(fqeDate);
        SetLastCommand(ccNone);
        Exit;
      end;

      if not qeEditEntry^.Immediate and (qeEditEntry^.SendTime = BadTime) then begin
        ShowErrorMessage('Invalid send time specified');
        SetNextField(fqeTime);
        SetLastCommand(ccNone);
        Exit;
      end;

      if (qeEditEntry^.FileList.Size = 0) then begin
        GotError(epNonFatal+9998, emNullError);
        SetLastCommand(ccNone);
        Exit;
      end;

      { make a copy of the edit entry into the original node }
      with qeOldEntry^ do begin
        FileList.Clear;
        SendTo := qeEditEntry^.SendTo;
        SendNum := qeEditEntry^.SendNum;
        Immediate := qeEditEntry^.Immediate;
        SendDate := qeEditEntry^.SendDate;
        SendTime := qeEditEntry^.SendTime;
        FileList.slHead := qeEditEntry^.FileList.slHead;
        FileList.slTail := qeEditEntry^.FileList.slTail;
        FileList.slSize := qeEditEntry^.FileList.slSize;
      end;

      { "dispose of" the list in qeEditEntry }
      with qeEditEntry^.FileList do begin
        slHead := nil;
        slTail := nil;
        slSize := 0;
      end;
      Dispose(qeEditEntry, Done);
    end;

  begin
    AltDialog.ProcessSelf;

    case cwCmd of
      ccInsertEntry: InsertFile;
      ccDeleteEntry: DeleteFile;
      ccSelect     : CopyEditEntry;
      ccQuit       : Dispose(qeEditEntry, Done);
    end;
  end;

  procedure TQueueEntryDialog.dgPostFocus;
  begin
    if (cwCmd = ccItemChange) and (asCurID = fqeOptions) then
      with qeEditEntry^ do begin
        ChangeProtection(fqeDate, Immediate);
        ChangeProtection(fqeTime, Immediate);

        if Immediate then begin
          SendDate := BadDate;
          SendTime := BadTime;
        end;

        DrawField(fqeDate);
        DrawField(fqeTime);
      end;
  end;

  procedure TQueueEntryDialog.InsertFile;
  var
    DB : PSelectCvtFilesDlg;
    LC : Word;
    FN : PathStr;
    FT : CvtFileType;
    SF : PSendFileNode;
    I  : Word;

  begin
    if (ConfigData.FaxClass = ctCas) then
      New(DB, Init(True, False, False, ' Select Files to Send ', @SendFNameHistory))
    else
      New(DB, Init(False, True, False, ' Select Files to Send ', @SendFNameHistory));

    if (DB = nil) then begin
      GotError(InitStatus, emNullError);
      Exit;
    end;

    LC := ProcessDialog(DB);
    DB^.Erase;

    if (LC = ccSelect) and (DB^.cfFiles.GetNumSel <> 0) then
      with DB^ do begin
        for I := 1 to cfFiles.GetNumSel do begin
          New(SF, Init);
          if (SF = nil) then begin
            GotError(epNonFatal+ecOutOfMemory, emInsufficientMemory);
            Dispose(DB, Done);
            Exit;
          end;

          cfFiles.GetSelFileInfo(I, FN, FT);
          SF^.FName := StringToHeap(FN);
          SF^.FType := FT;
          SF^.FSize := GetFileSize(FN);
          qeEditEntry^.FileList.Append(SF);
        end;

        qeSendList^.ChangeNumItems(qeEditEntry^.FileList.Size);
        qeSendList^.SetInitialChoice(qeEditEntry^.FileList.Size);
        qeSendList^.UpdateContents;
      end;

    Dispose(DB, Done);
  end;

  procedure TQueueEntryDialog.DeleteFile;
  var
    SF : PSendFileNode;
  begin
    { get outta here if there're no files in the list }
    if (qeEditEntry^.FileList.Size = 0) then
      Exit;

    { confirm the deletion }
    if YesNo( 'Are you sure you want to delete this file from the outgoing queue?',
              ' Confirm ') then begin
      SF := PSendFileNode(qeEditEntry^.FileList.Nth(qeSendList^.GetLastChoice));

      { this should never happen, but... }
      if (SF = nil) then
        Exit;

      qeEditEntry^.FileList.Delete(SF);
      qeSendList^.ChangeNumItems(qeEditEntry^.FileList.Size);
      qeSendList^.UpdateContents;
    end;
  end;

  constructor TPBookDropDown.Init(Parent : PQueueEntryDialog);
  begin
    ListParent := Parent;

    if not ComboList.InitAbstract(25, 8, 46, 17,
                                  DropBoxColors,
                                  wBordered+wClear+wUserContents,
                                  22, ListParent^.qePhonebook.Size,
                                  PickVertical, SingleChoice) then
      Fail;
  end;

  procedure TPBookDropDown.ItemString(    Item    : Word;
                                          Mode    : pkMode;
                                      var IType   : pkItemType;
                                      var IString : String);
  var
    PE : PPhonebookEntry;

  begin
    if (Mode <> pkGetType) then
      with ListParent^ do begin
        PE := PPhonebookEntry(qePhonebook.Nth(Item));
        if (PE = nil) then
          IString := ''
        else
          IString := PE^.Name;
      end;
  end;

  constructor TFaxQueueDialog.Init;
  var
    LQE : PSendQueueEntry;
    QE  : PSendQueueEntry;
    LSF : PSendFileNode;
    SF  : PSendFileNode;

  begin
    if not DialogBox.InitCustom(4, 5, 77, 21,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then
      Fail;
    SetDialogOptions(@Self);
    SetPreFocusProc(PreFocus);

    wFrame.AddHeader(' Outgoing Faxes ', heTC);

    New(qdQueueList, InitCustom(6, 7, 74, 16,
                                DialogColors,
                                wClear+wUserContents+wNoCoversBuffer,
                                69, SendQueue.TotalEntries,
                                QueueItemString, PickVertical, SingleChoice));
    if (qdQueueList = nil) then begin
      Done;
      Fail;
    end;
    SetPickOptions(qdQueueList, frRR, DialogColors, ClusterColors);

    dgSecFieldOptionsOn(sefSwitchCommands);
    AddWindowControl(
      '&Recipient             Files                         Date/Time', 2, 3,
      3, 3, 0, ccChangeEntry, qdQueueList^);
    dgSecFieldOptionsOff(sefSwitchCommands);
    SetHelpString(@Self, 'Outgoing faxes');

    AddPushButton('&Add to Queue', 14, 23, 14, 0, ccInsertEntry, False);
    SetHelpString(@Self, 'Add a set of files to the outgoing fax queue');

    AddPushButton('&Change Entry', 14, 41, 14, 0, ccChangeEntry, False);
    SetHelpString(@Self, 'Change the currently highlighted queue entry');

    AddPushButton('&Delete Entry', 14, 59, 14, 0, ccDeleteEntry, False);
    SetHelpString(@Self, 'Delete the currently highlighted queue entry');

    AddPushButton('Cop&y', 16, 23, 8, 0, ccCopyEntry, False);
    SetHelpString(@Self, 'Make a copy of the currently highlighted queue entry');

    AddPushButton('&Send', 16, 37, 8, 0, ccSendQueue, False);
    SetHelpString(@Self, 'Begin sending all queued faxes');

    AddPushButton(OkButton, 16, 51, 8, 0, ccSelect, True);
    SetHelpString(@Self, 'Save the outgoing queue to disk and return to the main menu');

    AddPushButton(CancelButton, 16, 65, 8, 0, ccQuit, False);
    SetHelpString(@Self, 'Cancel the changes to the outgoing queue and return to the main menu');

    SetChildErrorProc(@Self, ShowError);
  end;

  procedure TFaxQueueDialog.ProcessSelf;
  begin
    DialogBox.ProcessSelf;

    case cwCmd of
      ccInsertEntry: InsertEntry;
      ccChangeEntry: ChangeEntry;
      ccDeleteEntry: DeleteEntry;
      ccCopyEntry  : CopyEntry;
    end;
  end;

  procedure TFaxQueueDialog.InsertEntry;
  var
    NewEntry : PSendQueueEntry;
    DB       : PQueueEntryDialog;
    LC       : Word;
    NewPosn  : Word;

  begin
    SetLastCommand(ccNone);

    New(NewEntry, Init);
    if (NewEntry = nil) then begin
      GotError(epNonFatal+ecOutOfMemory, emInsufficientMemory);
      Exit;
    end;

    with NewEntry^ do begin
      SendTo    := '';
      SendNum   := '';
      Immediate := True;
      SendDate  := BadDate;
      SendTime  := BadTime;
    end;

    New(DB, Init(NewEntry));
    if (DB = nil) then begin
      Dispose(NewEntry, Done);
      GotError(InitStatus, emNullError);
      Exit;
    end;

    LC := ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);

    if (LC = ccSelect) then begin
      SendQueue.AddToQueue(NewEntry, NewPosn);

      with qdQueueList^ do begin
        ChangeNumItems(SendQueue.TotalEntries);
        SetInitialChoice(NewPosn);
        UpdateContents;
      end;
    end else
      Dispose(NewEntry, Done);
  end;

  procedure TFaxQueueDialog.ChangeEntry;
  var
    EntryToChange : PSendQueueEntry;
    DB            : PQueueEntryDialog;
    LC            : Word;

  begin
    SetLastCommand(ccNone);

    SendQueue.GetNthEntry(EntryToChange, qdQueueList^.GetLastChoice);
    if (EntryToChange = nil) then
      Exit;

    New(DB, Init(EntryToChange));
    if (DB = nil) then begin
      GotError(InitStatus, emNullError);
      Exit;
    end;

    LC := ProcessDialog(DB);
    DB^.Erase;
    Dispose(DB, Done);

    if (LC = ccSelect) then
      qdQueueList^.UpdateContents;
  end;

  procedure TFaxQueueDialog.DeleteEntry;
  var
    EntryToKill : PSendQueueEntry;

  begin
    SetLastCommand(ccNone);

    SendQueue.GetNthEntry(EntryToKill, qdQueueList^.GetLastChoice);
    if (EntryToKill = nil) then
      Exit;

    { confirm the deletion }
    if not YesNo( 'Are you sure you want to delete this entry and all files attached to it?',
                  ' Confirm ') then
      Exit;

    SendQueue.KillKillKill(EntryToKill);
    with qdQueueList^ do begin
      ChangeNumItems(SendQueue.TotalEntries);
      UpdateContents;
    end;
  end;

  procedure TFaxQueueDialog.CopyEntry;
  var
    OldEntry : PSendQueueEntry;
    NewEntry : PSendQueueEntry;
    NewPosn  : Word;

  begin
    SetLastCommand(ccNone);

    SendQueue.GetNthEntry(OldEntry, qdQueueList^.GetLastChoice);
    if (OldEntry = nil) then
      Exit;

    New(NewEntry, Copy(OldEntry));
    if (NewEntry = nil) then begin
      GotError(epNonFatal+ecOutOfMemory, emInsufficientMemory);
      Exit;
    end;

    SendQueue.AddToQueue(NewEntry, NewPosn);
    with qdQueueList^ do begin
      ChangeNumItems(SendQueue.TotalEntries);
      SetInitialChoice(NewPosn);
      UpdateContents;
    end;
  end;

  procedure TRejectPickList.ItemString(     Item    : Word;
                                            Mode    : pkMode;
                                        var IType   : pkItemType;
                                        var IString : String);
  var
    RE : PRejectFile;
    S  : String;

  begin
    with PRejectListDlg(wParentPtr)^ do begin
      RE := PRejectFile(rlRejects^.Nth(Item));
      if (RE = nil) then
        IString := ''
      else begin
        IString := ' ' + Pad(RE^.FName, 14) +
                         Pad(RE^.FDest, 22);
        GetErrorMessage(RE^.FErr, @Error_Table, S);
        IString := IString + S;
      end;
    end;
  end;

  constructor TRejectListDlg.Init(var Rejects : SingleList);
  begin
    rlRejects := @Rejects;


    New(rlList, InitAbstract( 11, 9, 69, 18,
                              DialogColors,
                              wClear+wUserContents+wNoCoversBuffer,
                              59, rlRejects^.Size,
                              PickVertical, SingleChoice ));
    if (rlList = nil) then
      Fail;
    SetPickOptions(rlList, frRR, DialogColors, ClusterColors);

    if not DialogBox.InitCustom(9, 4, 72, 21,
                                DialogColors,
                                wBordered+wClear+wUserContents,
                                ClusterColors) then begin         {!!.01}
      Dispose(rlList, Done);                                      {!!.01}
      Fail;                                                       {!!.01}
    end;                                                          {!!.01}

    SetDialogOptions(@Self);

    AddTextField('Errors occurred while sending some of the faxes in the', 2, 3);
    AddTextField('queue.  Here is the list of files that weren''t sent and the', 3, 3);
    AddTextField('reasons why.', 4, 3);

    AddWindowControl('', 1, 1, 6, 3, 0, ccSelect, rlList^);

    AddPushButton('&Click Here When Finished', 17, 3, 60, 0, ccSelect, True);

  end;

  procedure ClearStatus;
  begin
    FastFill( ScreenWidth, ' ', ScreenHeight, 1,
              ColorMono(DialogColors.TextColor, DialogColors.TextMono));
  end;

end.
