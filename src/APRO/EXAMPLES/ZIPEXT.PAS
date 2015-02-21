{$I APDEFINE.INC}
program ZipExt; {ZIPEXT.PAS}
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

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: ZIPEXT ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  InitFileMaskList(FML);

  {open the ZIP file}
  InitZipFile(DefaultExtension(ParamStr(1), 'ZIP'));
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  SetShowCommentsProcZip(DefShowCommentsProcZip);
  SetShowMethodProcZip(DefShowMethodProcZip);
  SetExtractSuccessFuncZip(DefExtractSuccessFuncZip);
  SetShowProgressFuncZip(DefShowProgressFuncZip);

  {extract all files in archive}
  ExtractFileMaskListZip(FML);
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {close the ZIP file}
  DoneZipFile;

  {dispose of data structures}
  DoneFileMaskList(FML);
end.
