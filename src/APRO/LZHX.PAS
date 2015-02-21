{$S-,R-,V-,I-,B-,F-}
{$M 4096,65536,655360}

{Conditional defines that may affect this program}
{$I APDEFINE.INC}

{*********************************************************}
{*                    LZHX.PAS 2.03                      *}
{*     Copyright (c) TurboPower Software 1991, 1993.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

program LzhX;
  {-Lzh file extraction utility}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Dos,
  {$IFDEF UseOpro}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApLzhD;
  {$ELSE}
  ApMisc,
  ApArchiv,
  ApLzh;
  {$ENDIF}

const
  Version = 'LzhX. Copyright (c) 1991 TurboPower Software. Version 2.03';

  CreateDirs : Boolean = False;       {True to create directories stored in LZH}
  OverwriteFiles : Boolean = False;   {True to overwrite existing files}
  OverwriteIfNewer : Boolean = False; {True to overwrite if files are newer}

var
  LzhMask : PathStr;              {mask for directory search}
  LzhName : PathStr;              {name of LZH file}
  FML     : FileMaskList;         {list of files to extract}
  SRec    : SearchRec;            {used for finding LZH files}
  OutPath : PathStr;              {path for output files}
  SaveOF  : Boolean;              {saved value of OverwriteFiles}

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
      Halt;
    WaitForKey := Key;
  end;

  function GetConfirmation(Def : Char) : Boolean;
    {-Confirm a replace/copy operation}
  var
    Key : Word;
    Ch  : Char absolute Key;
  begin
    GetConfirmation := True;
    Write(' (Y/N/A/Q) [', Def, ']'^H^H);
    repeat
      Key := WaitForKey;
      if Ch = ^M then
        Ch := Def;
      Ch := Upcase(Ch);
    until Pos(Ch, 'YNAQ') <> 0;
    Write(Ch);
    case Ch of
      'A' : OverwriteFiles := True;
      'Q' : Halt;
      'N' : GetConfirmation := False;
    end;
  end;

{$F+}

  function OkToWrite(var LH : LzhHeader; var FName : PathStr) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Return True if it is OK to (over)write FName}
  var
    SR : SearchRec;
  begin
    OkToWrite := True;
    if not OverwriteFiles then begin
      FindFirst(FName, $6, SR);
      if DosError <> 0 then
        Exit
      else if OverwriteIfNewer then
        OkToWrite := (MakeLongInt(LH.Date, LH.Time) > SR.Time)
      else begin
        Write('Warning: ', FName, ' exists. Overwrite it?');
        OkToWrite := GetConfirmation('N');
        WriteLn;
      end;
    end;
  end;

{$F-}

  procedure ShowHelp;
    {-Displays help message with LZHX options}
  begin
    WriteLn('Usage: LZHX [Options] Filename[.LZH] [files...]'^M^J);
    WriteLn('Parameters:');
    WriteLn('  /D          create directories stored in LZH file');
    WriteLn('  /N          extract only newer files');
    WriteLn('  /O          overwrite existing files');
    WriteLn('  /P path     path for output files');
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
    LzhMask := '';
    OutPath := '';
    InitFileMaskList(FML);

    I := 1;
    while I <= ParamCount do begin
      Opt := ParamStr(I);
      if (Opt[1] = '/') or (Opt[1] = '-') then
        if Length(Opt) <> 2 then
          InvalidOption
        else
          case UpCase(Opt[2]) of
            'D' : CreateDirs := True;
            'N' : OverwriteIfNewer := True;
            'O' : OverwriteFiles := True;
            'P' : begin
                    Inc(I);
                    OutPath := AddBackslash(ParamStr(I));
                    OutPath := StUpcase(OutPath);
                  end;
            '?' : ShowHelp;
            else InvalidOption;
          end
      else if LzhMask = '' then begin
        LzhMask := DefaultExtension(Opt, 'LZH');
        LzhMask := StUpCase(LzhMask);
      end
      else if not AppendFileMask(Opt, FML) then begin
        WriteLn('Insufficient memory');
        Halt(1);
      end;

      Inc(I);
    end;

    {make sure we have an LZH file mask}
    if LzhMask = '' then
      ShowHelp;
  end;

begin
  {display signon message}
  WriteLn(Version);
  WriteLn;

  {get command line parameters}
  Initialize;

  {get the first matching file}
  FindFirst(LzhMask, $6, SRec);
  if DosError <> 0 then
    WriteLn('No matching file(s) found');

  {save value of OverwriteFiles}
  SaveOF := OverwriteFiles;

  while (DosError = 0) do begin
    {reset OverwriteFiles}
    OverwriteFiles := SaveOF;

    {get name of next LZH file}
    LzhName := AddBackSlash(JustPathName(LzhMask))+SRec.Name;

    {try to open the LZH file}
    InitLzhFile(LzhName);
    if GetArchiveStatus <> 0 then begin
      if GetArchiveStatus = ecNotAnLzhFile  then
        WriteLn(LzhName, ' is not a valid LZH file')
      else
        WriteLn('Unable to open ', LzhName);
      Halt(1);
    end;

    {set options}
    if CreateDirs then
      arOptionsOn(arCreateDirs);
    SetShowMethodProcLzh(DefShowMethodProcLzh);
    SetExtractSuccessFuncLzh(DefExtractSuccessFuncLzh);
    SetShowProgressFuncLzh(DefShowProgressFuncLzh);
    SetShowNameProcLzh(DefShowNameProcLzh);
    SetOkToWriteFuncLzh(OkToWrite);
    SetOutputPath(OutPath);

    {extract all matching files}
    ExtractFileMaskListLzh(FML);

    {report errors}
    case GetArchiveStatus mod 10000 of
      ecOK :
        {ok};
      ecPathNotFound :
        WriteLn('Path not found');
      ecInvalidDrive :
        WriteLn('Invalid drive');
      ecDiskFull :
        WriteLn('Disk full');
      ecDriveNotReady :
        WriteLn('Drive not ready');
      ecOutOfMemory :
        WriteLn('Insufficient memory');
      ecBadFileFormat :
        WriteLn('Bad LZH file format');
      ecNoMatchingFiles :
        WriteLn('No matching file(s) found', ' in ', LzhName);
      ecUserAbort :
        WriteLn('^C');
      else
        WriteLn('I/O error ', GetArchiveStatus);
    end;

    {close the LZH file}
    DoneLzhFile;

    {halt if we failed}
    case GetArchiveStatus mod 10000 of
      ecOK, ecNoMatchingFiles :
        {ok} ;
      ecUserAbort :
        Halt(0);
      else
        Halt(1);
    end;

    {get next file, if any}
    FindNext(SRec);
    if DosError = 0 then
      WriteLn;
  end;
end.
