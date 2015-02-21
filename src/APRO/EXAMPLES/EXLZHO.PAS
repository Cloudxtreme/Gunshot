program ExLzhO; {EXLZHO.PAS}
uses
  Dos, ApMisc, OoArchiv, OoLzh;
var
  FML : FileMaskList;
  L : Lzh;
  Result : Word;
begin
  FML.Init;
  if not FML.Append('EXLZHO.PAS') or
     not FML.Append('EXLZHO.EXE') then begin
    WriteLn('Insufficient memory');
    Halt(1);
  end;

  {Create LZH file}
  L.Create('EXLZHO.LZH');
  if ArchiveStatus <> ecOk then begin
    WriteLn('Failed to create archive, error: ', ArchiveStatus);
    Halt;
  end;

  {set standard options}
  L.SetShowMethodProc(DefShowMethodProc);
  L.SetShowProgressFunc(DefShowProgressFunc);
  L.SetShowNameProc(DefShowNameProc);

  {set compressing-only options}
  L.SetOkToCompressFunc(DefOkToCompressFunc);
  L.SetCompressSuccessFunc(DefCompressSuccessFunc);

  L.CompressFileMaskList(FML);

  {report errors}
  Result := L.GetLastError;
  if Result <> ecOk then
    WriteLn('Failed due to error ', Result);

  {clean up}
  FML.Done;
  L.Done;
end.
