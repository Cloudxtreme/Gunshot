{$S-,R-,V-,I-,B-,F-}
{$M 4096, 65536, 655360}

{Conditional defines that may affect this program}
{$I APDEFINE.INC}

{*********************************************************}
{*                    LZH.PAS 2.0                        *}
{*     Copyright (c) TurboPower Software 1993.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

program Lzh;
  {-Lzh file compression utility}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Dos,
  {$IFDEF UseOpro}
  OpCrt,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpCrt,
  TpString,
  {$ENDIF}
  {$IFDEF Standalone}
  Crt,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApLzhD;
  {$ELSE}
  ApMisc,
  ApArchiv,
  ApLzh;
  {$ENDIF}

const
  Version = 'Lzh. Copyright (c) 1991 TurboPower Software. Version 2.03';

  StripPath  : Boolean = False;     {strip pathname}
  NewArchive : Boolean = False;     {true if archive was created}
  HaltSoon   : Boolean = False;     {true to halt as soon as possible}
  AllOk      : Boolean = True;      {true to skip confirmations}
  GotOne     : Boolean = False;     {helps us delete empty files}

  {Default to new LHA method}
  MethodToUse : CompressionMode = cmBestMethod;

type
  ActionType = (lzhAdd, lzhDelete, lzhFreshen, lzhNoAction);

var
  LzhName   : PathStr;              {name of LZH file}
  FML       : FileMaskList;         {list of files to extract}
  Action    : ActionType;           {action to perform this pass}
  F         : File;                 {only needed for deleting bad archives}

  function GetKey : Word;
    {-Get a key}
  var
    Regs : Registers;
  begin
    Regs.AH := 0;
    Intr($16, Regs);
    GetKey := Regs.AX;
  end;

  function WaitForKey : Word;
    {-Wait for a keypress and throw away the result}
  var
    Key : Word;
    Ch  : Char absolute Key;
  begin
    {halt if ^Break or ^C pressed}
    Key := GetKey;
    if (Key = $0000) or (Ch = ^C) then
      HaltSoon := True;
    WaitForKey := Key;
  end;

  function GetConfirmation(NewFile : PathStr; Def : Char) : Boolean;
    {-Confirm a replace/copy operation}
  var
    Key : Word;
    Ch  : Char absolute Key;
  begin
    GetConfirmation := True;
    Write('Compress ', JustFileName(NewFile));
    Write(' (Y/N/A/Q) [', Def, ']'^H^H);
    repeat
      Key := WaitForKey;
      if Ch = ^M then
        Ch := Def;
      Ch := Upcase(Ch);
    until Pos(Ch, 'YNAQ') <> 0;
    Write(Ch);
    case Ch of
      'A' : AllOk := True;
      'Q' : HaltSoon := True;
      'N' : GetConfirmation := False;
    end;
  end;

  {$F+}
  function MyShowProgressFunc(BytesWritten, TotalBytes : LongInt) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Checks for user abort, then calls default function to show progress}
  var
    C : Char;
  begin
    {Handle pending halts}
    if HaltSoon then begin
      MyShowProgressFunc := False;
      Exit;
    end;

    {Check for abort key}
    while KeyPressed do begin
      C := ReadKey;
      if C = #0 then
        C := ReadKey
      else if C = #27 then begin
        MyShowProgressFunc := False;
        Exit;
      end;
    end;

    {Call default function to show progress}
    MyShowProgressFunc := DefShowProgressFuncLzh(BytesWritten, TotalBytes);
  end;
  {$F-}

  {$F+}
  function MyOkToCompressFunc(NewFile : PathStr; LH : LzhHeader) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Call old function to get OK, then request confirmation from user}
  var
    OK : Boolean;
  begin
    {Get OK from default compress function}
    OK := DefOkToCompressFuncLzh(NewFile, LH);

    {If no additional confirmation needed, just set result and exit}
    if AllOk then begin
      MyOkToCompressFunc := OK;
      Exit;
    end;

    {If still OK, go ask user}
    if OK then begin
      OK := GetConfirmation(NewFile, 'Y');
      if OK then
        GotOne := True;
      MyOkToCompressFunc := OK;
      WriteLn;
    end else
      MyOktoCompressFunc := False;
  end;
  {$F-}

  procedure ShowHelp;
    {-Displays help message with LZH options}
  begin
    WriteLn('Usage: LZH [Options] Filename[.LZH] [files...]'^M^J);
    WriteLn('Parameters:');
    WriteLn('  /A          add files to directory');
    WriteLn('  /O          old methods; required for');
    WriteLn('              compatibility with older ver. of LHA.');
    WriteLn('  /D          delete files from directory');
    WriteLn('  /F          freshen files in this archive');
    WriteLn('  /S          strip the path name when adding');
    WriteLn('  /C          request confirmations');
    WriteLn('  Filename    name of LZH file; LZH extension assumed');
    WriteLn('  files...    one or more file masks; may contain wildcards');
    WriteLn('  /?          display this help screen');
    Halt(0);
  end;

  procedure Initialize;
    {-Initialize and check for command line parameters}
  var
    I   : Word;
    Opt : string[127];

    procedure InvalidOption;
      {-displays error message and aborts}
    begin
      WriteLn(Opt, ' is an invalid option');
      ShowHelp;
    end;

  begin
    {initialize global variables}
    Action := lzhNoAction;
    LzhName := '';
    InitFileMaskList(FML);

    I := 1;
    while I <= ParamCount do begin
      Opt := ParamStr(I);
      if (Opt[1] = '/') or (Opt[1] = '-') then
        if Length(Opt) <> 2 then
          InvalidOption
        else
          case UpCase(Opt[2]) of
            'A' : Action := lzhAdd;
            'O' : MethodToUse := cmFrozen1;
            'D' : Action := lzhDelete;
            'F' : Action := lzhFreshen;
            'S' : StripPath := True;
            'C' : AllOk := False;
            '?' : ShowHelp;
            else InvalidOption;
          end
      else if LzhName = '' then begin
        LzhName := DefaultExtension(Opt, 'LZH');
        LzhName := StUpCase(LzhName);
      end else if not AppendFileMask(Opt, FML) then begin
        WriteLn('Insufficient memory');
        Halt(1);
      end;

      Inc(I);
    end;

    {make sure we have an LZH file mask}
    if LzhName = '' then
      ShowHelp;
  end;

begin
  {display signon message}
  WriteLn(Version);
  WriteLn;

  {allow output redirection}
  Assign(Output, '');
  Rewrite(Output);

  {get command line parameters}
  Initialize;

  {Open/create LZH file}
  InitLzhFile(LzhName);
  if GetArchiveStatus <> ecOk then
    if Action = lzhFreshen then begin
      WriteLn('Can''t find archive (', LzhName, ') to freshen');
      Halt(1);
    end else begin
      CreateLzhFile(LzhName);
      NewArchive := True;
    end;
  if GetArchiveStatus <> ecOk then begin
    WriteLn('Failed to open ', LzhName, ', error was ', GetArchiveStatus);
    Halt(1);
  end;

  {set options}
  SetShowMethodProcLzh(DefShowMethodProcLzh);
  SetShowProgressFuncLzh(MyShowProgressFunc);
  SetShowNameProcLzh(DefShowNameProcLzh);

  {set compressing-only options}
  SetOkToCompressFuncLzh(MyOkToCompressFunc);
  SetCompressSuccessFuncLzh(DefCompressSuccessFuncLzh);
  SetCompressionModeLzh(MethodToUse);

  if StripPath then
    arOptionsOn(arStripPath);
  GotOne := AllOk;

  {Perform requested action}
  case Action of
    lzhAdd :
      CompressFileMaskListLzh(FML);
    lzhDelete :
      DeleteFileMaskListLzh(FML);
    lzhFreshen :
      FreshenArchiveLzh;
    lzhNoAction :
      if NewArchive then begin
        Assign(F, LzhName);
        Erase(F);
        if IOResult <> 0 then ;
        ShowHelp;
      end;
  end;

  {report errors}
  case GetArchiveStatus mod 10000 of
    ecOk : ;
    ecEmptyFileMaskList :
      WriteLn(^M^J'No files to compress');
    ecDiskFull :
      WriteLn(^M^J'Failed due to insufficient disk space');
    ecFileNotFound :
      WriteLn(^M^J'Failed because a file in the list wasn''t found');
    ecPathNotFound :
      Writeln(^M^J'Failed because a file in the list had a bad path name');
    ecAccessDenied :
      WriteLn(^M^J'Failed because a file in the list couldn''t be read (access denied)');
    ecInvalidDrive :
      WriteLn(^M^J'Failed because a file in the list specified an invalid drive');
    ecUserAbort :
      WriteLn(^M^J'Canceled on request, old archive was restored');
    else
      WriteLn(^M^J'Failed due to error ', GetArchiveStatus mod 10000);
  end;

  {Delete archive if errors occurred and this was a new file}
  if NewArchive and ((GetArchiveStatus <> ecOk) or not GotOne) then begin
    Assign(F, LzhName);
    Erase(F);
    if IOResult <> 0 then ;
  end;

  {close the LZH file}
  DoneLzhFile;
  DoneFileMaskList(FML);
end.
