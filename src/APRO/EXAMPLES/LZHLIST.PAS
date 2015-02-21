{$I APDEFINE.INC}
program LzhList; {LZHLIST.PAS}
uses
  {$IFDEF UseOPro}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  {$ENDIF}
  ApMisc, ApArchiv, ApLzh;
var
  FML : FileMaskList;
  LFL : LzhFileList;
  LNP : LzhNodePtr;

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: LZHLIST ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  InitFileMaskList(FML);

  {initialize LZH file list}
  InitLzhFileList(LFL);

  {open the LZH file}
  InitLzhFile(DefaultExtension(ParamStr(1), 'LZH'));
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  SetShowNameProcLzh(DefShowNameProcLzh);

  {construct list of files in archive}
  BuildLzhFileList(LFL, FML);
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {display names and sizes of all files in archive}
  LNP := LFL.Head;
  while LNP <> nil do begin
    with LNP^.LH do
      WriteLn(OrigSize:7, ' ', FName);
    LNP := LNP^.Next;
  end;

  {close the LZH file}
  DoneLzhFile;

  {dispose of data structures}
  DoneLzhFileList(LFL);
  DoneFileMaskList(FML);
end.
