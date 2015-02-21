{$I APDEFINE.INC}

program ZipExtO; {ZIPEXTO.PAS}
uses
  {$IFDEF UseOPro}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  {$ENDIF}
  ApMisc, OoArchiv, OoZip;
var
  UZ :  UnZip;
  FML : FileMaskList;
  Error : Word;

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: ZIPEXTO ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  FML.Init;

  {open the ZIP file}
  if not UZ.Init(DefaultExtension(ParamStr(1), 'ZIP')) then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  UZ.SetShowCommentsProc(DefShowCommentsProc);
  UZ.SetShowMethodProc(DefShowMethodProc);
  UZ.SetExtractSuccessFunc(DefExtractSuccessFunc);
  UZ.SetShowProgressFunc(DefShowProgressFunc);

  {extract all files in archive}
  UZ.ExtractFileMaskList(FML);
  Error := UZ.GetLastError;
  if Error <> ecOk then begin
    Writeln('Error: ', StatusStr(Error));
    Halt;
  end;

  {close the ZIP file}
  UZ.Done;

  {dispose of data structures}
  FML.Done;
end.
