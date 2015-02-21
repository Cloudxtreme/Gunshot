{$I APDEFINE.INC}
program LzhExtO; {LZHEXTO.PAS}
uses
  {$IFDEF UseOPro}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpString,
  {$ENDIF}
  ApMisc, OoArchiv, OoLzh;
var
  UL :  UnLzh;
  FML : FileMaskList;
  Error : Word;

begin
  {Display signon message}
  WriteLn(Version);
  WriteLn;
  if ParamCount = 0 then begin
    Writeln('Syntax: LZHEXTO ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  FML.Init;

  {open the LZH file}
  if not UL.Init(DefaultExtension(ParamStr(1), 'LZH')) then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  UL.SetShowNameProc(DefShowNameProc);
  UL.SetShowMethodProc(DefShowMethodProc);
  UL.SetExtractSuccessFunc(DefExtractSuccessFunc);
  UL.SetShowProgressFunc(DefShowProgressFunc);
  UL.SetOkToWriteFunc(DefOkToWriteFunc);

  {extract all files in archive}
  UL.ExtractFileMaskList(FML);
  Error := UL.GetLastError;
  if Error <> ecOk then begin
    Writeln('Error: ', StatusStr(Error));
    Halt;
  end;

  {close the LZH file}
  UL.Done;

  {dispose of data structures}
  FML.Done;
end.
