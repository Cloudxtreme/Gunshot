program ExZip; {EXZIP.PAS}
uses
  Dos, ApMisc, ApArchiv, ApZip;
var
  FML : FileMaskList;

begin
  {Initialize the file mask list and add masks}
  InitFileMaskList(FML);
  if not AppendFileMask('EXZIP.PAS', FML) or
     not AppendFileMask('EXZIP.EXE', FML) then begin
    WriteLn('Insufficient memory');
    Halt;
  end;

  {Create a new ZIP file}
  CreateZipFile('EXZIP.ZIP');
  if ArchiveStatus <> ecOk then begin
    WriteLn('Failed to create archive, error: ', ArchiveStatus);
    Halt;
  end;

  {Set options}
  SetShowMethodProcZip(DefShowMethodProcZip);
  SetShowProgressFuncZip(DefShowProgressFuncZip);
  SetShowCommentsProcZip(DefShowCommentsProcZip);

  {Set compressing-only options}
  SetOkToCompressFuncZip(DefOkToCompressFuncZip);
  SetCompressSuccessFuncZip(DefCompressSuccessFuncZip);

  {Add the files the archive}
  CompressFileMaskListZip(FML);

  {Report errors}
  if ArchiveStatus <> ecOk then
    WriteLn('Failed due to error ', ArchiveStatus mod 10000);

  {Clean up}
  DoneFileMaskList(FML);
  DoneZipFile;
end.
