{$I APDEFINE.INC}
program LzhListO; {LZHLISTO.PAS}
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
  LFL : LzhFileList;
  LNP : LzhNodePtr;
  Error : Word;

begin
  if ParamCount = 0 then begin
    Writeln('Syntax: LZHLISTO ArchiveName');
    Halt;
  end;

  {create an empty file mask list}
  FML.Init;

  {initialize LZH file list}
  LFL.Init;

  {open the LZH file}
  if not UL.Init(DefaultExtension(ParamStr(1), 'LZH')) then begin
    Writeln('Error: ', StatusStr(ArchiveStatus));
    Halt;
  end;

  {enable user hooks}
  UL.SetShowNameProc(DefShowNameProc);

  {construct list of files in archive}
  UL.BuildLzhFileList(LFL, FML);
  Error := UL.GetLastError;
  if Error <> ecOk then begin
    Writeln('Error: ', StatusStr(Error));
    Halt;
  end;

  {display names and sizes of all files in archive}
  LNP := LFL.lfHead;
  while LNP <> nil do begin
    with LNP^.lnLH do
      WriteLn(OrigSize:7, ' ', FName);
    LNP := LNP^.lnNext;
  end;

  {close the LZH file}
  UL.Done;

  {dispose of data structures}
  LFL.Done;
  FML.Done;
end.
