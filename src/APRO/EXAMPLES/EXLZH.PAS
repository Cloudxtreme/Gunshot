program ExLzh; {EXLZH.PAS}
uses
  Dos, ApMisc, ApArchiv, ApLzh;
var
  FML : FileMaskList;

begin
  InitFileMaskList(FML);
  if not AppendFileMask('EXLZH.PAS', FML) or
     not AppendFileMask('EXLZH.EXE', FML) then begin
    WriteLn('Insufficient memory');
    Halt;
  end;

  {Create a new LZH file}
  CreateLzhFile('EXLZH.LZH');
  if ArchiveStatus <> ecOk then begin
    WriteLn('Failed to create archive, error: ', ArchiveStatus);
    Halt;
  end;

  {set options}
  SetShowMethodProcLzh(DefShowMethodProcLzh);
  SetShowProgressFuncLzh(DefShowProgressFuncLzh);
  SetShowNameProcLzh(DefShowNameProcLzh);

  {set compressing-only options}
  SetOkToCompressFuncLzh(DefOkToCompressFuncLzh);
  SetCompressSuccessFuncLzh(DefCompressSuccessFuncLzh);

  CompressFileMaskListLzh(FML);

  {report errors}
  if ArchiveStatus <> ecOk then
    WriteLn('Failed due to error ', ArchiveStatus mod 10000);

  {clean up}
  DoneFileMaskList(FML);
  DoneLzhFile;
end.
