{$I APDEFINE.INC}
program LzhExt; {LZHEXT.PAS}
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
begin
  if ParamCount = 0 then begin
    Writeln('Syntax: LZHEXT ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  InitFileMaskList(FML);

  {open the LZH file}
  InitLzhFile(DefaultExtension(ParamStr(1), 'LZH'));
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  SetShowNameProcLzh(DefShowNameProcLzh);
  SetShowMethodProcLzh(DefShowMethodProcLzh);
  SetExtractSuccessFuncLzh(DefExtractSuccessFuncLzh);
  SetShowProgressFuncLzh(DefShowProgressFuncLzh);

  {extract all files in archive}
  ExtractFileMaskListLzh(FML);
  if ArchiveStatus <> 0 then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {close the LZH file}
  DoneLzhFile;

  {dispose of data structures}
  DoneFileMaskList(FML);
end.
