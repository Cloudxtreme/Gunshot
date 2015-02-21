{$I APDEFINE.INC}

program ZipList; {ZIPLIST.PAS}
uses
  {$IFDEF UseOPro}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  {$ENDIF}
  ApMisc, ApArchiv, ApZip;
var
  FML : FileMaskList;
  ZFL : ZipFileList;
  ZNP : ZipNodePtr;

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: ZIPLIST ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  InitFileMaskList(FML);

  {initialize ZIP file list}
  InitZipFileList(ZFL);

  {open the ZIP file}
  InitZipFile(DefaultExtension(ParamStr(1),'ZIP'));
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  SetShowCommentsProcZip(DefShowCommentsProcZip);

  {construct list of files in archive}
  BuildZipFileList(ZFL, FML);
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {display names and sizes of all files in archive}
  ZNP := ZFL.Head;
  while ZNP <> nil do begin
    with ZNP^, CDH do
      WriteLn(OrigSize:7, ' ', FName);
    ZNP := ZNP^.Next;
  end;

  {close the ZIP file}
  DoneZipFile;

  {dispose of data structures}
  DoneZipFileList(ZFL);
  DoneFileMaskList(FML);
end.
