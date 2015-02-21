program ExZipO; {EXZIPO.PAS}
uses
  Dos, ApMisc, OoArchiv, OoZip;
var
  FML : FileMaskList;
  Z : Zip;
  Result : Word;
begin
  {Instantiate the file mask list and add masks}
  FML.Init;
  if not FML.Append('EXZIPO.PAS') or
     not FML.Append('EXZIPO.EXE') then begin
    WriteLn('Insufficient memory');
    Halt(1);
  end;

  {Create ZIP file}
  Z.Create('EXZIPO.ZIP');
  if ArchiveStatus <> ecOk then begin
    WriteLn('Failed to create archive, error: ', ArchiveStatus);
    Halt;
  end;

  {Set standard options}
  Z.SetShowMethodProc(DefShowMethodProc);
  Z.SetShowProgressFunc(DefShowProgressFunc);
  Z.SetShowCommentsProc(DefShowCommentsProc);

  {Set compressing-only options}
  Z.SetOkToCompressFunc(DefOkToCompressFunc);
  Z.SetCompressSuccessFunc(DefCompressSuccessFunc);

  {Add the files to the archive}
  Z.CompressFileMaskList(FML);

  {Report errors}
  Result := Z.GetLastError;
  if Result <> ecOk then
    WriteLn('Failed due to error ', Result);

  {Clean up}
  FML.Done;
  Z.Done;
end.

