{$I APDEFINE.INC}

program ZipListO; {ZIPLISTO.PAS}
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
  ZFL : ZipFileList;
  ZNP : ZipNodePtr;
  Error : Word;

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: ZIPLISTO ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  FML.Init;

  {initialize ZIP file list}
  ZFL.Init;

  {open the ZIP file}
  if not UZ.Init(DefaultExtension(ParamStr(1), 'ZIP')) then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  UZ.SetShowCommentsProc(DefShowCommentsProc);

  {construct list of files in archive}
  UZ.BuildZipFileList(ZFL, FML);
  Error := UZ.GetLastError;
  if Error <> 0 then begin
    Writeln('Error: ', StatusStr(Error));
    Halt;
  end;

  {display names and sizes of all files in archive}
  ZNP := ZFL.zfHead;
  while ZNP <> nil do begin
    with ZNP^, znCDH do
      WriteLn(OrigSize:7, ' ', znFName);
    ZNP := ZNP^.znNext;
  end;

  {close the ZIP file}
  UZ.Done;

  {dispose of data structures}
  ZFL.Done;
  FML.Done;
end.
