{$I DEFINES.INC}
UNIT FileMan;


INTERFACE


PROCEDURE SortFiles;
PROCEDURE DoFileEdit           (FName: String);
PROCEDURE LoadInDirectory      (Path: String);
PROCEDURE CheckTheFiles        (Path: String);
PROCEDURE DoFileDirectory      (Number: Longint);
FUNCTION  RemoveTrailingSpaces (InString: String) : String;
FUNCTION  RemoveFileIdDiz      (FName: String)    : Byte;


IMPLEMENTATION


USES CnfgVars,DOS,IntrFace,FilePick,BsString,BsFile,Dispatch,BsEditor,
     Import,Defaults,CRT,BsMouse,DosShell,BsExec,Shotgun;


FUNCTION RemoveFileIdDiz(FName: String): Byte;
VAR  CommandLine : String;
     Status      : Byte;
     CheckIt     : Word;
LABEL              SkipIt;
BEGIN
     _SaveWindow(WorkDir+'\DIZIMP.SCR');
     _EraseFile('FILE_ID.DIZ');
     _EraseFile('DESC.SDI');
     GotoXY(1,1);
     Status := 0;
     CheckFile('ARCHIVE.DAT');
     CheckFile('ARCUTILS.DAT');
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     RESET(FArcUtils);
     REPEAT
           READ(FArcUtils,ArcUtils);
           IF _GetFileExtension(FName)=ArcUtils.Extension THEN
           BEGIN
                CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+FName+' FILE_ID.DIZ >nul';
                DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,USE_ALL,WorkDir);
                IF _FileExists('FILE_ID.DIZ') THEN
                BEGIN
                     Status := 1;
                     GOTO SkipIt;
                END;
                CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+FName+' DESC.SDI >nul';
                DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,USE_ALL,WorkDir);
                IF _FileExists('DESC.SDI') THEN Status := 2;
                GOTO SkipIt;
           END;
     UNTIL EOF(FArcUtils);
     SkipIt:
     CLOSE(FArcUtils);
     LoadWindow(WorkDir+'\DIZIMP.SCR');
     RemoveFileIdDiz := Status;
END;


FUNCTION KillPotentialDupe(AreaNum: Longint; FName: String): Boolean;
VAR  FFileArea93  : File Of _FileArea_Record;
     FFileDefs93  : File Of _FileDefinitions;
     FileArea93   : _FileArea_Record;
     FileDefs93   : _FileDefinitions;
     FFileDefs100 : File Of _FileDefinitions;
     FFileDefs101 : File Of _FileDefinitions;
     FFileDesc100 : File Of _FileDescriptions;
     FFileDesc101 : File Of _FileDescriptions;
     FileDefs100  : _FileDefinitions;
     FileDesc100  : Array[1..18] Of _FileDescriptions;
     Success      : Boolean;
     Desc_Lines   : Word;
     Loop         : Word;
BEGIN
     FName := _UpperCase(FName);
     ASSIGN(FFileArea93,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea93);
     SEEK(FFileArea93,AreaNum-1);
     READ(FFileArea93,FileArea93);
     CLOSE(FFileArea93);
     ASSIGN(FFileDefs93,FileArea93.Dos_Name+'.FIL');
     {$I-}RESET(FFileDefs93);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FFileDefs93,FileDefs93);
         IF _UpperCase(FileDefs93.File_Name)=FName THEN
         BEGIN
           CLOSE(FFileDefs93);
           IF NOT(Confirmed2(FName)) THEN
           BEGIN
             KillPotentialDupe := False;
             Exit;
           END
           ELSE
           BEGIN
             IF _FileExists(FileArea93.Dos_Name+'.FIL') THEN
             BEGIN
               ASSIGN(FFileDefs101,FileArea93.Dos_Name+'.FIL');
               RENAME(FFileDefs101,FileArea93.Dos_Name+'.FIB');
               ASSIGN(FFileDesc101,FileArea93.Dos_Name+'.TXT');
               RENAME(FFileDesc101,FileArea93.Dos_Name+'.TXB');
               ASSIGN(FFileDefs101,FileArea93.Dos_Name+'.FIB');
               ASSIGN(FFileDesc101,FileArea93.Dos_Name+'.TXB');
               ASSIGN(FFileDefs100,FileArea93.Dos_Name+'.FIL');
               ASSIGN(FFileDesc100,FileArea93.Dos_Name+'.TXT');
               REWRITE(FFileDefs100);
               REWRITE(FFileDesc100);
               RESET(FFileDefs101);
               RESET(FFileDesc101);
               Success := False;
               REPEAT
                 READ(FFileDefs101,FileDefs100);
                 FOR Loop := 1 TO FileDefs100.Desc_Lines DO READ(FFileDesc101,FileDesc100[Loop]);
                 IF FileDefs100.File_Name=FName THEN
                 BEGIN
                   Success    := True;
                   Desc_Lines := FileDefs100.Desc_Lines;
                 END
                 ELSE
                 BEGIN
                   IF Success THEN
                   BEGIN
                     DEC(FileDefs100.First_Desc,Desc_Lines);
                     WRITE(FFileDefs100,FileDefs100);
                     FOR Loop := 1 TO FileDefs100.Desc_Lines DO WRITE(FFileDesc100,FileDesc100[Loop]);
                   END
                   ELSE
                   BEGIN
                     WRITE(FFileDefs100,FileDefs100);
                     FOR Loop := 1 TO FileDefs100.Desc_Lines DO WRITE(FFileDesc100,FileDesc100[Loop]);
                   END;
                 END;
               UNTIL EOF(FFileDefs101);
               CLOSE(FFileDefs100);
               CLOSE(FFileDesc100);
               CLOSE(FFileDefs101);
               CLOSE(FFileDesc101);
               ERASE(FFileDefs101);
               ERASE(FFileDesc101);
               IF _FileSize(FileArea93.Dos_Name+'.FIL')=0 THEN
               BEGIN
                 ERASE(FFileDefs100);
                 ERASE(FFileDesc100);
               END;
             END;
           END;
           KillPotentialDupe := True;
           Exit;
         END;
       UNTIL EOF(FFileDefs93);
       CLOSE(FFileDefs93);
     END;
     KillPotentialDupe := True;
END;


PROCEDURE SortArea(DBaseName: String; SortMethod: Word);
VAR  i,j           : Word;
     Temp          : FFFF;  {Info : String[16]; OrigIndex : Word; InfoNum : Longint}
     NumberOfFiles : Word;
     Counter       : Word;
     Month         : Word;
     Day           : Word;
     Year          : Word;
     RealDate      : Longint;
     Loop          : Word;
     Loop2         : Word;
     TextPos       : Word;
BEGIN
     {No Sort - Just Exit}
     IF SortMethod=1 THEN Exit;

     {LOAD THE SORT INFORMATION REQUIRED}
     CASE SortMethod OF
     2,3: BEGIN
               ASSIGN(FFileDefs,DBaseName+'.FIL');
               RESET(FFileDefs);
               NumberOfFiles := FileSize(FFileDefs);
               Counter       := 0;
               REPEAT
                     READ(FFileDefs,FileDefs);
                     INC(Counter);
                     FileInfo2^[Counter].OrigIndex := Counter;
                     FileInfo2^[Counter].Info      := _UpperCase(RemoveTrailingSpaces(FileDefs.File_Name));
               UNTIL EOF(FFileDefs);
               CLOSE(FFileDefs);
          END;
     4,5: BEGIN
               ASSIGN(FFileDefs,DBaseName+'.FIL');
               RESET(FFileDefs);
               NumberOfFiles := FileSize(FFileDefs);
               Counter       := 0;
               REPEAT
                     READ(FFileDefs,FileDefs);
                     INC(Counter);
                     FileInfo2^[Counter].OrigIndex := Counter;
                     FileInfo2^[Counter].InfoNum   := FileDefs.File_Date;
               UNTIL EOF(FFileDefs);
               CLOSE(FFileDefs);
          END;
     6,7: BEGIN
               ASSIGN(FFileDefs,DBaseName+'.FIL');
               RESET(FFileDefs);
               NumberOfFiles := FileSize(FFileDefs);
               Counter       := 0;
               REPEAT
                     READ(FFileDefs,FileDefs);
                     INC(Counter);
                     FileInfo2^[Counter].OrigIndex := Counter;
                     FileInfo2^[Counter].InfoNum   := FileDefs.File_Size;
               UNTIL EOF(FFileDefs);
               CLOSE(FFileDefs);
          END;
     END;

     {SORT THE INDEXES}
     CASE SortMethod OF
     2:   BEGIN {ALPHABETICAL (A-Z)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].Info<FileInfo2^[j].Info THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     3:   BEGIN {ALPHABETICAL (Z-A)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].Info>FileInfo2^[j].Info THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     4:   BEGIN {DATE (NEW-OLD)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].InfoNum>FileInfo2^[j].InfoNum THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     5:   BEGIN {DATE (OLD-NEW)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].InfoNum<FileInfo2^[j].InfoNum THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     6:   BEGIN {SIZE (LARGE-SMALL)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].InfoNum>FileInfo2^[j].InfoNum THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     7:   BEGIN {SIZE (SMALL-LARGE)}
               FOR i := 1 TO NumberOfFiles DO
               BEGIN
                    FOR j := 1 TO NumberOfFiles DO
                    BEGIN
                         IF FileInfo2^[i].InfoNum<FileInfo2^[j].InfoNum THEN
                         BEGIN
                              Temp := FileInfo2^[i];
                              FileInfo2^[i] := FileInfo2^[j];
                              FileInfo2^[j] := temp;
                         END;
                    END;
               END;
          END;
     END;
     {RENAME THE OLD DBASE FILES TO A TEMPORARY}
     ASSIGN(FFileDefs,DBaseName+'.FIL'); RENAME(FFileDefs,DBaseName+'.FIB');
     ASSIGN(FFileDesc,DBaseName+'.TXT'); RENAME(FFileDesc,DBaseName+'.TXB');
     ASSIGN(FFileDefs2,DBaseName+'.FIB');
     ASSIGN(FFileDesc2,DBaseName+'.TXB');
     ASSIGN(FFileDefs,DBaseName+'.FIL');
     ASSIGN(FFileDesc,DBaseName+'.TXT');
     REWRITE(FFileDesc);
     REWRITE(FFileDefs);
     RESET(FFileDesc2);
     RESET(FFileDefs2);
     TextPos := 1;
     FOR Loop := 1 TO NumberOfFiles DO
     BEGIN
          {READ IN THE RECORDS}
          SEEK(FFileDefs2,FileInfo2^[Loop].OrigIndex-1);
          READ(FFileDefs2,FileDefs);
          SEEK(FFileDesc2,FileDefs.First_Desc-1);
          FOR Loop2 := 1 TO FileDefs.Desc_Lines DO
              READ(FFileDesc2,FileDesc[Loop2]);
          {ADJUST THE TEXT POINTER}
          FileDefs.First_Desc := TextPos;
          INC(TextPos,FileDefs.Desc_Lines);
          {WRITE THE NEW RECORDS}
          WRITE(FFileDefs,FileDefs);
          FOR Loop2 := 1 TO FileDefs.Desc_Lines DO
              WRITE(FFileDesc,FileDesc[Loop2]);
     END;
     CLOSE(FFileDesc);
     CLOSE(FFileDefs);
     CLOSE(FFileDesc2);
     CLOSE(FFileDefs2);
     ERASE(FFileDesc2);
     ERASE(FFileDefs2);
END;


FUNCTION RemoveTrailingSpaces(InString: String): String;
VAR  EndsAt     : Word;
     Loop       : Word;
BEGIN
     IF InString<>'' THEN
     BEGIN
          IF InString[LENGTH(InString)]=' ' THEN
          BEGIN
               EndsAt := 0;
               FOR Loop := LENGTH(InString) DOWNTO 1 DO
               BEGIN
                    IF ((InString[Loop]<>' ') AND (EndsAt=0)) THEN
                    BEGIN
                         EndsAt := Loop;
                    END;
               END;
               IF (EndsAt<>0) THEN RemoveTrailingSpaces := _Mid(InString,1,EndsAt)
                              ELSE RemoveTrailingSpaces := '';
          END
          ELSE RemoveTrailingSpaces := InString;
     END
     ELSE RemoveTrailingSpaces := '';
END;


PROCEDURE LoadInDirectory(Path: String);
VAR  DirInfo           : SearchRec;
     WorkFile          : String;
BEGIN
     HasFilesBBS := False;
     FileCounter := 0;
     IF Path[Length(Path)]='\' THEN Path := _Mid(Path,1,LENGTH(Path)-1);
     FindFirst(Path+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          WorkFile := _UpperCase(DirInfo.Name);
          IF ((WorkFile<>'FILES.BBS') AND
             (Path+'\'+WorkFile<>FileArea.Dos_Name+'.FIL') AND
             (Path+'\'+WorkFile<>FileArea.Dos_Name+'.TXT')) THEN
          BEGIN
               INC(FileCounter);
               FileInfo^[FileCounter].FileType := 2;
               FileInfo^[FileCounter].Name     := _RemoveSpaces(WorkFile);
               FileInfo^[FileCounter].FileSize := DirInfo.Size;
               FileInfo^[FileCounter].FileDesc := '';
          END;
          FindNext(DirInfo);
     END;
     IF _FileExists(Path+'\FILES.BBS') THEN HasFilesBBS := True;
END;


PROCEDURE CheckTheFiles(Path: String);
VAR  Loop       : Word;
LABEL             NextOne;
BEGIN
     IF ((_FileSize(Path+'.FIL')=0) OR (_FileSize(Path+'.TXT')=0)) THEN
     BEGIN
          _EraseFile(Path+'.FIL');
          _EraseFile(Path+'.TXT');
     END;
     {CHECK FOR COMPLETE FILES}
     ASSIGN(FFileDefs,Path+'.FIL');
     {$I-}RESET(FFileDefs);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FFileDefs,FileDefs);
                FileDefs.File_Name := _UpperCase(_RemoveSpaces(FileDefs.File_Name));
                FOR Loop := 1 TO FileCounter DO
                BEGIN
                     IF FileDefs.File_Name=FileInfo^[Loop].Name THEN
                     BEGIN
                          FileInfo^[Loop].FileType := 1;
                          ASSIGN(FFileDesc,Path+'.TXT');
                          {$I-}RESET(FFileDesc);{$I+}
                          IF IOResult=0 THEN
                          BEGIN
                               SEEK(FFileDesc,FileDefs.First_Desc-1);
                               READ(FFileDesc,FileDesc[1]);
                               CLOSE(FFileDesc);
                               FileInfo^[Loop].FileDesc := FileDesc[1].Desc;
                          END
                          ELSE FileInfo^[Loop].FileDesc := '';
                          GOTO NextOne;
                     END;
                END;
                INC(FileCounter);
                FileInfo^[FileCounter].FileType := 3;
                FileInfo^[FileCounter].Name     := FileDefs.File_Name;
                FileInfo^[FileCounter].FileSize := FileDefs.File_Size;
                FileInfo^[FileCounter].FileDesc := '';
                NextOne:
          UNTIL EOF(FFileDefs);
          CLOSE(FFileDefs);
     END;
END;


PROCEDURE SortFiles;
VAR  Loop       : Word;
     I,J        : Word;
     Temp       : FFF;
BEGIN
     FOR Loop := 1 TO FileCounter DO
         FileInfo^[Loop].Name := _UpperCase(FileInfo^[Loop].Name);
     FOR i := 1 TO FileCounter DO
     BEGIN
          FOR j := 1 TO FileCounter DO
          BEGIN
               IF FileInfo^[i].Name<FileInfo^[j].Name THEN
               BEGIN
                    Temp := FileInfo^[i];
                    FileInfo^[i] := FileInfo^[j];
                    FileInfo^[j] := temp;
               END;
          END;
     END;
END;


PROCEDURE LoadUpDescription(NumLines: Word);
VAR  Loop2 : Word;
     Loop  : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Total := 1;
          FOR Loop2 := 1 TO NumLines DO
          BEGIN
               IF FileDesc[Loop2].Desc='' THEN
               BEGIN
                    BodyText[Total] := #13;
                    INC(Total);
               END
               ELSE
               BEGIN
                    FOR Loop := 1 TO LENGTH(FileDesc[Loop2].Desc) DO
                    BEGIN
                         BodyText[Total] := FileDesc[Loop2].Desc[Loop];
                         INC(Total);
                    END;
                    BodyText[Total] := #13;
                    INC(Total);
               END;
          END;
          Dec(Total);
          BodyText[Total+1] := #255;
     END;
END;


PROCEDURE GetBackDescription;
VAR  AllDone     : Boolean;
     Loop2       : Word;
     Good        : Boolean;
     LastSpace   : Word;
     Start       : Word;
     Temp        : String;
     Loop        : Word;
     Msg_Text    : String;
     CurrentDesc : Word;
BEGIN
     FOR Loop := 1 TO 18 DO FillChar(FileDesc[Loop].Desc,SizeOf(FileDesc[Loop].Desc),0);
     WITH EditorObject^ DO
     BEGIN
          Loop        := 0;
          AllDone     := False;
          Msg_Text    := '';
          CurrentDesc := 1;
          REPEAT
                INC(Loop);
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     IF CurrentDesc<=18 THEN
                     BEGIN
                          FileDesc[CurrentDesc].Desc := Msg_Text;
                     END;
                     AllDone := True;
                END
                ELSE IF BodyText[Loop]=#13 THEN
                BEGIN
                     IF CurrentDesc<=18 THEN
                     BEGIN
                          FileDesc[CurrentDesc].Desc := Msg_Text;
                          INC(CurrentDesc);
                     END;
                END
                ELSE
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     Temp      := '';
                     REPEAT
                           Temp := Temp+BodyText[Loop2];
                           IF LENGTH(Temp)<=CharsOnScrn THEN
                           BEGIN
                                IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                           END;
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     Delete(Temp,Length(Temp),1);
                                     Msg_Text := Temp;
                                     IF CurrentDesc<=18 THEN
                                     BEGIN
                                          FileDesc[CurrentDesc].Desc := Msg_Text;
                                          INC(CurrentDesc);
                                     END;
                                     Msg_Text := '';
                                     Good     := True;
                                     Loop     := Loop2;
                                END;
                           255: BEGIN
                                     Delete(Temp,Length(Temp),1);
                                     Msg_Text := Temp;
                                     IF CurrentDesc<=18 THEN
                                     BEGIN
                                          FileDesc[CurrentDesc].Desc := Msg_Text;
                                          INC(CurrentDesc);
                                     END;
                                     Msg_Text := '';
                                     AllDone  := True;
                                     Good     := True;
                                     Loop     := Loop2;
                                END;
                           ELSE BEGIN
                                     IF LENGTH(Temp)>CharsOnScrn THEN
                                     BEGIN
                                          Temp := '';
                                          FOR Loop2 := Start TO LastSpace DO Temp := Temp+BodyText[Loop2];
                                          Loop := LastSpace;
                                          Good := True;
                                          Msg_Text := Temp;
                                          IF CurrentDesc<=18 THEN
                                          BEGIN
                                               FileDesc[CurrentDesc].Desc := Msg_Text;
                                               INC(CurrentDesc);
                                          END;
                                          Msg_Text := '';
                                     END;
                                END;
                           END;
                           INC(Loop2);
                     UNTIL Good;
                END;
          UNTIL AllDone;
     END;
END;


PROCEDURE DoFileEdit(FName: String);
VAR  Work      : Word;
     WeGotOne  : Boolean;
     FileIdDiz : Text;
     Temp      : String;
     Loop      : Word;
     Pooper    : Longint;

     PROCEDURE DoARedraw(NumLines: Word);
     BEGIN
          _HideMouse;
          LoadUpDescription(NumLines);
          EditorRedraw(False,True);
          _ShowMouse;
     END;

BEGIN
     Pooper := _FileSize(FName);
     IF (Pooper<>0) THEN FileDefs.File_Size := Pooper;
     Pooper := _FileDate(FName);
     IF (Pooper<>0) THEN FileDefs.File_Date := Pooper;
     _EraseFile('FILE_ID.DIZ');
     _EraseFile('DESC.SDI');
     Work := RemoveFileIdDiz(FName);
     IF ((Work=1) OR (Work=2)) THEN WeGotOne := True
                               ELSE WeGotOne := False;
     New(EditorObject);
     _SaveWindow(WorkDir+'\FILEEDIT.SCR');
     DrawWindow(1,1,80,24,'EDIT FILE DEFINITION',False);
     _HideMouse;
     InitEditor(32,3,77,20);
     LoadUpDescription(FileDefs.Desc_Lines);
     EditorRedraw(False,True);
     _ShowMouse;
     AddObject(16,3,1,12,FileDefs.File_Name,True);
     AddObject(16,4,2,9,_String(FileDefs.File_Size),True);
     AddObject(16,5,4,6,UnpackedDate(FileDefs.File_Date),True);
     AddObject(16,6,4,6,UnpackedDate(FileDefs.Added_Date),True);
     AddObject(16,8,2,9,_String(FileDefs.DLed),True);
     AddObject(16,9,6,3,_String(FileDefs.Free),True);
     AddObject(16,22,1,30,FileDefs.Uploader,True);
     IF WeGotOne THEN
     BEGIN
          AddButton(54,22,' QUIT ',True,1,16);
          AddButton(62,22,' FILE_ID.DIZ ',True,1,33);
     END
     ELSE AddButton(71,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(2,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(2,20); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(4,3);   WRITE(' File Name');
     GotoXY(4,4);   WRITE(' File Size');
     GotoXY(4,5);   WRITE(' File Date');
     GotoXY(4,6);   WRITE('Added Date');
     GotoXY(4,8);   WRITE('Times DLed');
     GotoXY(4,9);   WRITE(' Free File');
     GotoXY(3,22);  WRITE('Uploaded By');
     _ShowMouse;
     EditorActive := True;
     REPEAT
           Work := DoObjects;
           IF ((Work=2) AND (WeGotOne)) THEN
           BEGIN
                IF _FileExists('FILE_ID.DIZ') THEN
                BEGIN
                     Loop := 0;
                     ASSIGN(FileIdDiz,'FILE_ID.DIZ');
                     RESET(FileIdDiz);
                     REPEAT
                           READLN(FileIdDiz,Temp);
                           INC(Loop);
                           IF (Loop<=18) THEN FileDesc[Loop].Desc := Temp;
                     UNTIL EOF(FileIdDiz);
                     CLOSE(FileIdDiz);
                     IF Loop>18 THEN Loop := 18;
                     DoARedraw(Loop);
                END
                ELSE IF _FileExists('DESC.SDI') THEN
                BEGIN
                     Loop := 0;
                     ASSIGN(FileIdDiz,'DESC.SDI');
                     RESET(FileIdDiz);
                     REPEAT
                           READLN(FileIdDiz,Temp);
                           INC(Loop);
                           IF (Loop<=18) THEN FileDesc[Loop].Desc := Temp;
                     UNTIL EOF(FileIdDiz);
                     CLOSE(FileIdDiz);
                     IF Loop>18 THEN Loop := 18;
                     DoARedraw(Loop);
                END;
           END;
     UNTIL (Work=1);
     EditorActive := False;
     ClearObjects;
     ClearButtons;
     FileDefs.File_Name  := _UpperCase(_RemoveSpaces(Objects^[1].Stuff));
     FileDefs.File_Size  := Numeric(Objects^[2].Stuff,LongInteger);
     FileDefs.File_Date  := PackedDate(Objects^[3].Stuff);
     FileDefs.Added_Date := PackedDate(Objects^[4].Stuff);
     FileDefs.DLed       := Numeric(Objects^[5].Stuff,LongInteger);
     FileDefs.Free       := Numeric(Objects^[6].Stuff,ByteInteger);
     IF (FileDefs.Uploader<>Objects^[7].Stuff)
        THEN FileDefs.Uploader := _ProperCase(Objects^[7].Stuff)
        ELSE FileDefs.Uploader := Objects^[7].Stuff;
     GetBackDescription;
     LoadWindow(WorkDir+'\FILEEDIT.SCR');
     Dispose(EditorObject);
     _EraseFile('FILE_ID.DIZ');
     _EraseFile('DESC.SDI');
END;


PROCEDURE DeleteFromDataBase(Temp: String);
VAR  Success      : Boolean;
     Desc_Lines   : Word;
     Loop         : Word;
BEGIN
     IF NOT(_FileExists(FileArea.Dos_Name+'.FIL')) THEN Exit;
     {REMOVE FROM THE FILE AREAS DATABASE}
     ASSIGN(FFileDefs2,FileArea.Dos_Name+'.FIL');
     RENAME(FFileDefs2,FileArea.Dos_Name+'.FIB');
     ASSIGN(FFileDesc2,FileArea.Dos_Name+'.TXT');
     RENAME(FFileDesc2,FileArea.Dos_Name+'.TXB');
     ASSIGN(FFileDefs2,FileArea.Dos_Name+'.FIB');
     ASSIGN(FFileDesc2,FileArea.Dos_Name+'.TXB');
     ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
     ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
     REWRITE(FFileDefs);
     REWRITE(FFileDesc);
     RESET(FFileDefs2);
     RESET(FFileDesc2);
     Success := False;
     REPEAT
           READ(FFileDefs2,FileDefs2);
           FOR Loop := 1 TO FileDefs2.Desc_Lines DO
               READ(FFileDesc2,FileDesc[Loop]);
           IF FileDefs2.File_Name=Temp THEN
           BEGIN
                Success    := True;
                Desc_Lines := FileDefs2.Desc_Lines;
           END
           ELSE
           BEGIN
                IF Success THEN
                BEGIN
                     DEC(FileDefs2.First_Desc,Desc_Lines);
                     WRITE(FFileDefs,FileDefs2);
                     FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc[Loop]);
                END
                ELSE
                BEGIN
                     WRITE(FFileDefs,FileDefs2);
                     FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc[Loop]);
                END;
           END;
     UNTIL EOF(FFileDefs2);
     CLOSE(FFileDefs);
     CLOSE(FFileDesc);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     ERASE(FFileDefs2);
     ERASE(FFileDesc2);
     IF _FileSize(FileArea.Dos_Name+'.FIL')=0 THEN
     BEGIN
          ERASE(FFileDefs);
          ERASE(FFileDesc);
     END;
END;


PROCEDURE WriteOutPickList;
VAR  Loop        : Word;
BEGIN
     PickingListItems2 := FileCounter;
     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
     REWRITE(FPickingListFile2);
     FOR Loop := 1 TO FileCounter DO
     BEGIN
          CASE FileInfo^[Loop].FileType OF
          1:   BEGIN
                    PickingListFile2.A := ' '+_PadRight(FileInfo^[Loop].Name,13);
                    PickingListFile2.A := PickingListFile2.A+_PadLeft(_String(FileInfo^[Loop].FileSize),8);
                    PickingListFile2.A := PickingListFile2.A+'  '+FileInfo^[Loop].FileDesc;
               END;
          2:   BEGIN
                    PickingListFile2.A := ' '+_PadRight(FileInfo^[Loop].Name,13);
                    PickingListFile2.A := PickingListFile2.A+'  Orphan';
                    PickingListFile2.A := PickingListFile2.A+'  '+FileInfo^[Loop].FileDesc;
               END;
          3:   BEGIN
                    PickingListFile2.A := ' '+_PadRight(FileInfo^[Loop].Name,13);
                    PickingListFile2.A := PickingListFile2.A+' Missing';
                    PickingListFile2.A := PickingListFile2.A+'  '+FileInfo^[Loop].FileDesc;
               END;
          END;
          WRITE(FPickingListFile2,PickingListFile2);
     END;
     CLOSE(FPickingListFile2);
END;


FUNCTION GetCDRomName(WhichOne: Word): String;
VAR  Temp : String;
BEGIN
     Temp := '';
     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FCDRoms,CDRoms);
                IF CDRoms.CDNumber=WhichOne THEN Temp := CDRoms.CDName;
          UNTIL ((EOF(FCDRoms)) OR (Temp<>''));
          CLOSE(FCDRoms);
     END;
     GetCDRomName := Temp;
END;


FUNCTION GotSomeTagged: Boolean;
BEGIN
     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile2);
     REPEAT
           READ(FPickingListFile2,PickingListFile2);
           IF PickingListFile2.A[1]='þ' THEN
           BEGIN
                CLOSE(FPickingListFile2);
                GotSomeTagged := True;
                Exit;
           END;
     UNTIL EOF(FPickingListFile2);
     CLOSE(FPickingListFile2);
     GotSomeTagged := False;
END;


FUNCTION SetDestinationArea: Longint;
VAR  OuttaHere  : Boolean;
     Action     : Word;
     SaveItem1  : Word;
     SaveItem2  : Word;
     SaveItem3  : Word;
     SaveItem4  : Word;
     SaveItem5  : Word;
     SaveItem6  : Word;
     SaveItem7  : Boolean;
     SaveItem8  : Boolean;
     SaveItem9  : Boolean;
     SaveItem10 : Boolean;
     SaveItem11 : Boolean;
     SaveItem12 : Boolean;
     SaveItem13 : Boolean;
     SaveItem14 : String;
     SaveItem15 : String;
BEGIN
     _HideMouse;
     _RenameFile(WorkDir+'\PICK.LST',WorkDir+'\PICK.LS$');
     _SaveWindow(WorkDir+'\DESTAREA.SCR');
     SaveItem1  := PickListPerPage;
     SaveItem2  := PickItem;
     SaveItem3  := PickTop;
     SaveItem4  := PickListItems;
     SaveItem5  := PickListX;
     SaveItem6  := PickListY;
     SaveItem7  := UseTwoColumn;
     SaveItem8  := UseEditButton;
     SaveItem9  := UseDeleteButton;
     SaveItem10 := UseInsertButton;
     SaveItem11 := UseAddButton;
     SaveItem12 := UseFileButton;
     SaveItem13 := UseSelectButton;
     SaveItem14 := PickList_A_Title;
     SaveItem15 := PickList_B_Title;
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 0;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := False;
     UseInsertButton  := False;
     UseAddButton     := False;
     UseFileButton    := False;
     UseSelectButton  := True;
     PickList_A_Title := _PadRight(' File Area Description',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     REWRITE(FPickListFile);
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea3);
           INC(PickListItems);
           PickListFile.A := FileArea3.Area_Name;
           PickListFile.B := '';
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FFileArea);
     CLOSE(FPickListFile);
     CLOSE(FFileArea);
     SetUpPickList('SELECT DESTINATION AREA');
     _ShowMouse;
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   BEGIN
                     OuttaHere := True; {NORMAL QUIT}
                     SetDestinationArea := 0;
                END;
           6:   IF (PickItem<>0) THEN
                BEGIN
                     SetDestinationArea := PickItem;
                     OuttaHere := True;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere          := True;
                     ProgramFinished    := True;
                     SetDestinationArea := 0;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     _HideMouse;
     LoadWindow(WorkDir+'\DESTAREA.SCR');
     _RenameFile(WorkDir+'\PICK.LS$',WorkDir+'\PICK.LST');
     _ShowMouse;
     PickListPerPage  := SaveItem1;
     PickItem         := SaveItem2;
     PickTop          := SaveItem3;
     PickListItems    := SaveItem4;
     PickListX        := SaveItem5;
     PickListY        := SaveItem6;
     UseTwoColumn     := SaveItem7;
     UseEditButton    := SaveItem8;
     UseDeleteButton  := SaveItem9;
     UseInsertButton  := SaveItem10;
     UseAddButton     := SaveItem11;
     UseFileButton    := SaveItem12;
     UseSelectButton  := SaveItem13;
     PickList_A_Title := SaveItem14;
     PickList_B_Title := SaveItem15;
END;


PROCEDURE UnTagAll;
VAR  Counter : Longint;
BEGIN
     Counter := 0;
     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile2);
     REPEAT
           READ(FPickingListFile2,PickingListFile2);
           IF PickingListFile2.A[1]='þ' THEN
           BEGIN
                PickingListFile2.A[1] := ' ';
                SEEK(FPickingListFile2,Counter);
                WRITE(FPickingListFile2,PickingListFile2);
           END;
           INC(Counter);
     UNTIL EOF(FPickingListFile2);
     CLOSE(FPickingListFile2);
END;


PROCEDURE DoFileDirectory(Number: Longint);
VAR  OuttaHere   : Boolean;
     Action      : Word;
     AllIsOk     : Boolean;
     Temp        : String;
     C           : Char;
     FoundIt     : Boolean;
     Counting    : Longint;
     DidIt       : Boolean;
     TheFile     : String;
     Work        : Byte;
     Reference   : Longint;
     OldLines    : Byte;
     FilesBBS    : Text;
     TBytes      : Longint;
     TFiles      : Longint;
     FileIdDiz   : Text;
     Crapper     : Byte;
     Loop        : Word;
     FileNumber  : Word;
     ToArea      : Longint;
LABEL              OneMoreTime;

     PROCEDURE ReloadArea;
     BEGIN
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          SEEK(FFileArea,Number-1);
          READ(FFileArea,FileArea);
          CLOSE(FFileArea);
     END;

BEGIN
     _SaveWindow(WorkDir+'\FILEDIRS.SCR');
     ReloadArea;
     _CreatePath(Filearea.area_path);
     OneMoreTime:
     AllIsOk := False;
     REPEAT
           InfoBox('PLEASE WAIT...','Getting The Directory Listing','','');
           LoadInDirectory(FileArea.Area_Path);
           InfoBox('PLEASE WAIT...','Sorting The File Area','','');
           CheckTheFiles(FileArea.Dos_Name);
           IF FileArea.CD_Rom<>0 THEN
           BEGIN
                FOR Loop := 1 TO FileCounter DO
                BEGIN
                     IF FileInfo^[Loop].FileType=1 THEN AllIsOk := True;
                END;
           END
           ELSE AllIsOk := True;
           IF ((NOT(AllIsOK)) AND (FileArea.CD_Rom<>0)) THEN
           BEGIN
                Temp := GetCDRomName(FileArea.CD_Rom);
                IF Temp<>'' THEN InfoBox('WRONG CD!!','Insert '+Temp,
                                         ' into drive '+FileArea.Area_Path[1]+': and press a key.',
                                         ' [ESC] To Abort')
                            ELSE InfoBox('WRONG CD!!','Insert the correct CD ',
                                         ' into drive '+FileArea.Area_Path[1]+': and press a key.',
                                         ' [ESC] To Abort');
                C := ReadKey;
                IF ORD(C)=0 THEN
                BEGIN
                     C := ReadKey;
                     CASE Ord(C) OF
                     45:  ShutDown;
                     60:  ShellToDos;
                     68 : DumpTheScreen;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(UpCase(C)) OF
                     27:  BEGIN
                               LoadWindow(WorkDir+'\FILEDIRS.SCR');
                               EXIT;
                          END;
                     END;
                END;
           END;
     UNTIL AllIsOk;
     SortFiles;
     PickingListPerPage2 := 18;
     PickingItem2        := 1;
     PickingTop2         := 1;
     OuttaHere           := False;
     PickingListTitle2   := _PadRight(' File            Bytes  Description',78);
     PickingList2X       := 6;
     PickingList2Y       := 0;
     WriteOutPickList;
     SetUpPickingList2('FILE DIRECTORY EDITOR - '+FileArea.Area_Name);
     REPEAT
           Action := DoPickingList2;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           3:   IF PickingListItems2<>0 THEN
                BEGIN {ORPHAN}
                     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                     RESET(FPickingListFile2);
                     Seek(FPickingListFile2,PickingItem2-1);
                     READ(FPickingListFile2,PickingListFile2);
                     CLOSE(FPickingListFile2);
                     Temp := _UpperCase(_RemoveSpaces(_Mid(PickingListFile2.A,2,13)));
                     DeleteFromDataBase(Temp);
                     FOR Loop := 1 TO FileCounter DO
                     BEGIN
                          IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=Temp THEN
                          BEGIN
                               FileInfo^[Loop].FileType := 2;
                               FileInfo^[Loop].FileDesc := '';
                          END;
                     END;
                     WriteOutPickList;
                     UpdatePickingList2;
                END;
           5:   IF PickingListItems2<>0 THEN
                BEGIN {ADD}
                     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                     RESET(FPickingListFile2);
                     Seek(FPickingListFile2,PickingItem2-1);
                     READ(FPickingListFile2,PickingListFile2);
                     CLOSE(FPickingListFile2);
                     Temp    := _Mid(PickingListFile2.A,2,13);
                     TheFile := _UpperCase(_RemoveSpaces(Temp));
                     FoundIt := False;
                     FOR loop := 1 TO FileCounter DO
                     BEGIN
                          IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                          BEGIN
                               IF FileInfo^[Loop].FileType=2 THEN
                               BEGIN
                                    FoundIt    := True;
                                    FileNumber := Loop;
                               END;
                          END;
                     END;
                     IF FoundIt THEN
                     BEGIN
                          FileDefs.File_Name  := TheFile;
                          FileDefs.File_Size  := _FileSize(FileArea.Area_Path+TheFile);
                          FileDefs.DLed       := 0;
                          FileDefs.Desc_Lines := 0;
                          FileDefs.Class      := 0;
                          FileDefs.Free       := 0;
                          FileDefs.Uploader   := System_Info.Sysop;
                          FileDefs.Added_Date := proper_date;
                          FileDefs.File_Date  := _FileDate(FileArea.Area_Path+TheFile);
                          ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                          {$I-}RESET(FFileDesc);{$I+}
                          IF IOResult=0 THEN
                          BEGIN
                               FileDefs.First_Desc := FileSize(FFileDesc)+1;
                               CLOSE(FFileDesc);
                          END
                          ELSE FileDefs.First_Desc := 1;
                          FOR Loop := 1 TO 18 DO FileDesc[Loop].Desc := '';
                          Crapper := RemoveFileIdDiz(FileArea.Area_Path+TheFile);
                          CASE Crapper OF
                          1:   BEGIN
                                    ASSIGN(FileIdDiz,'FILE_ID.DIZ');
                                    {$I-}RESET(FileIdDiz);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         Loop := 0;
                                         REPEAT
                                               READLN(FileIdDiz,Temp);
                                               INC(Loop);
                                               IF (Loop<=18) THEN FileDesc[Loop].Desc := Temp;
                                         UNTIL EOF(FileIdDiz);
                                         CLOSE(FileIdDiz);
                                         IF (Loop<=18) THEN FileDefs.Desc_Lines := Loop
                                                       ELSE FileDefs.Desc_Lines := 18;
                                    END;
                               END;
                          2:   BEGIN
                                    ASSIGN(FileIdDiz,'DESC.SDI');
                                    {$I-}RESET(FileIdDiz);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         Loop := 0;
                                         REPEAT
                                               READLN(FileIdDiz,Temp);
                                               INC(Loop);
                                               IF (Loop<=18) THEN FileDesc[Loop].Desc := Temp;
                                         UNTIL EOF(FileIdDiz);
                                         CLOSE(FileIdDiz);
                                         IF (Loop<=18) THEN FileDefs.Desc_Lines := Loop
                                                       ELSE FileDefs.Desc_Lines := 18;
                                    END;
                               END;
                          END;
                          _EraseFile('FILE_ID.DIZ');
                          _EraseFile('DESC.SDI');
                          DoFileEdit(FileArea.Area_Path+TheFile);
                               IF (FileDesc[18].Desc<>'') THEN Work := 18
                          ELSE IF (FileDesc[17].Desc<>'') THEN Work := 17
                          ELSE IF (FileDesc[16].Desc<>'') THEN Work := 16
                          ELSE IF (FileDesc[15].Desc<>'') THEN Work := 15
                          ELSE IF (FileDesc[14].Desc<>'') THEN Work := 14
                          ELSE IF (FileDesc[13].Desc<>'') THEN Work := 13
                          ELSE IF (FileDesc[12].Desc<>'') THEN Work := 12
                          ELSE IF (FileDesc[11].Desc<>'') THEN Work := 11
                          ELSE IF (FileDesc[10].Desc<>'') THEN Work := 10
                          ELSE IF (FileDesc[9].Desc<>'') THEN Work := 9
                          ELSE IF (FileDesc[8].Desc<>'') THEN Work := 8
                          ELSE IF (FileDesc[7].Desc<>'') THEN Work := 7
                          ELSE IF (FileDesc[6].Desc<>'') THEN Work := 6
                          ELSE IF (FileDesc[5].Desc<>'') THEN Work := 5
                          ELSE IF (FileDesc[4].Desc<>'') THEN Work := 4
                          ELSE IF (FileDesc[3].Desc<>'') THEN Work := 3
                          ELSE IF (FileDesc[2].Desc<>'') THEN Work := 2
                          ELSE IF (FileDesc[1].Desc<>'') THEN Work := 1
                          ELSE
                          BEGIN
                               FileDesc[1].Desc := 'No Description';
                               Work             := 1;
                          END;
                          FileDefs.Desc_Lines := Work;
                          {DO THE TEXT THING}
                          ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                          {$I-}RESET(FFileDesc);{$I+}
                          IF IOResult=0 THEN
                          BEGIN
                               SEEK(FFileDesc,FileSize(FFileDesc));
                               FOR Loop := 1 TO Work DO WRITE(FFileDesc,FileDesc[Loop]);
                               CLOSE(FFileDesc);
                          END
                          ELSE
                          BEGIN
                               REWRITE(FFileDesc);
                               FOR Loop := 1 TO Work DO WRITE(FFileDesc,FileDesc[Loop]);
                               CLOSE(FFileDesc);
                          END;
                          {DO THE FILE THING}
                          ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                          {$I-}RESET(FFileDefs);{$I+}
                          IF IOResult=0 THEN
                          BEGIN
                               SEEK(FFileDefs,FileSize(FFileDefs));
                               WRITE(FFileDefs,FileDefs);
                               CLOSE(FFileDefs);
                          END
                          ELSE
                          BEGIN
                               REWRITE(FFileDefs);
                               WRITE(FFileDefs,FileDefs);
                               CLOSE(FFileDefs);
                          END;
                          FileInfo^[FileNumber].FileType := 1;
                          FileInfo^[FileNumber].FileDesc := FileDesc[1].Desc;
                          ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                          RESET(FPickingListFile2);
                          SEEK(FPickingListFile2,PickingItem2-1);
                          PickingListFile2.A := ' '+_PadRight(FileInfo^[FileNumber].Name,13);
                          PickingListFile2.A := PickingListFile2.A+
                                                _PadLeft(_String(FileInfo^[FileNumber].FileSize),8);
                          PickingListFile2.A := PickingListFile2.A+'  '+FileInfo^[FileNumber].FileDesc;
                          WRITE(FPickingListFile2,PickingListFile2);
                          CLOSE(FPickingListFile2);
                          UpdatePickingList2;
                     END;
                END;
           6:   IF PickingListItems2<>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                          RESET(FPickingListFile2);
                          Seek(FPickingListFile2,PickingItem2-1);
                          READ(FPickingListFile2,PickingListFile2);
                          CLOSE(FPickingListFile2);
                          Temp := _UpperCase(_RemoveSpaces(_Mid(PickingListFile2.A,2,13)));
                          DeleteFromDataBase(Temp);
                          _EraseFile(FileArea.Area_Path+Temp);
                          New(FileInfoTmp);
                          Counting := 0;
                          FOR Loop := 1 TO FileCounter DO
                          BEGIN
                               IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))<>Temp THEN
                               BEGIN
                                    INC(Counting);
                                    FileInfoTmp^[Counting] := FileInfo^[Loop];
                               END;
                          END;
                          FileCounter := Counting;
                          FOR Loop := 1 TO FileCounter DO FileInfo^[Loop] := FileInfoTmp^[Loop];
                          Dispose(FileInfoTmp);
                          WriteOutPickList;
                          {Rescan the cursor position}
                          IF PickingItem2>PickingListItems2 THEN DEC(PickingItem2);
                          IF PickingItem2<PickingTop2 THEN DEC(PickingTop2);
                          {Redraw the picklist}
                          UpdatePickingList2;
                     END;
                END;
           7:   IF PickingListItems2<>0 THEN
                BEGIN {EDIT}
                     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                     RESET(FPickingListFile2);
                     Seek(FPickingListFile2,PickingItem2-1);
                     READ(FPickingListFile2,PickingListFile2);
                     CLOSE(FPickingListFile2);
                     Temp    := _Mid(PickingListFile2.A,2,13);
                     TheFile := _UpperCase(_RemoveSpaces(Temp));
                     FoundIt := False;
                     FOR loop := 1 TO FileCounter DO
                     BEGIN
                          IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                          BEGIN
                               IF FileInfo^[Loop].FileType=1 THEN
                               BEGIN
                                    FoundIt    := True;
                                    FileNumber := Loop;
                               END;
                          END;
                     END;
                     IF FoundIt THEN
                     BEGIN
                          FOR Loop := 1 TO 18 DO FileDesc[Loop].Desc := '';
                          DidIt := False;
                          Reference := 0;
                          ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                          {$I-}RESET(FFileDefs);{$I+}
                          IF IOResult=0 THEN
                          BEGIN
                               REPEAT
                                     READ(FFileDefs,FileDefs);
                                     INC(Reference);
                                     IF _UpperCase(_RemoveSpaces(FileDefs.File_Name))=TheFile THEN
                                     BEGIN
                                          DidIt := True;
                                          ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                          RESET(FFileDesc);
                                          SEEK(FFileDesc,FileDefs.First_Desc-1);
                                          FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                              READ(FFileDesc,FileDesc[Loop]);
                                          CLOSE(FFileDesc);
                                     END;
                               UNTIL (EOF(FFileDefs) OR DidIt);
                               CLOSE(FFileDefs);
                          END;
                          IF DidIt THEN
                          BEGIN
                               DoFileEdit(FileArea.Area_Path+TheFile);
                                    IF (FileDesc[18].Desc<>'') THEN Work := 18
                               ELSE IF (FileDesc[17].Desc<>'') THEN Work := 17
                               ELSE IF (FileDesc[16].Desc<>'') THEN Work := 16
                               ELSE IF (FileDesc[15].Desc<>'') THEN Work := 15
                               ELSE IF (FileDesc[14].Desc<>'') THEN Work := 14
                               ELSE IF (FileDesc[13].Desc<>'') THEN Work := 13
                               ELSE IF (FileDesc[12].Desc<>'') THEN Work := 12
                               ELSE IF (FileDesc[11].Desc<>'') THEN Work := 11
                               ELSE IF (FileDesc[10].Desc<>'') THEN Work := 10
                               ELSE IF (FileDesc[9].Desc<>'') THEN Work := 9
                               ELSE IF (FileDesc[8].Desc<>'') THEN Work := 8
                               ELSE IF (FileDesc[7].Desc<>'') THEN Work := 7
                               ELSE IF (FileDesc[6].Desc<>'') THEN Work := 6
                               ELSE IF (FileDesc[5].Desc<>'') THEN Work := 5
                               ELSE IF (FileDesc[4].Desc<>'') THEN Work := 4
                               ELSE IF (FileDesc[3].Desc<>'') THEN Work := 3
                               ELSE IF (FileDesc[2].Desc<>'') THEN Work := 2
                               ELSE IF (FileDesc[1].Desc<>'') THEN Work := 1
                               ELSE
                               BEGIN
                                    FileDesc[1].Desc := 'No Description';
                                    Work             := 1;
                               END;
                               OldLines := FileDefs.Desc_Lines;
                               IF Work=OldLines THEN
                               BEGIN
                                    FileDefs.Desc_Lines := Work;
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    RESET(FFileDefs);
                                    SEEK(FFileDefs,Reference-1);
                                    WRITE(FFileDefs,FileDefs);
                                    CLOSE(FFileDefs);
                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                    RESET(FFileDesc);
                                    SEEK(FFileDesc,FileDefs.First_Desc-1);
                                    FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                        WRITE(FFileDesc,FileDesc[Loop]);
                                    CLOSE(FFileDesc);
                               END
                               ELSE IF Work>OldLines THEN
                               BEGIN
                                    FileDefs.Desc_Lines := Work;
                                    Counting  := 0;
                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                    RENAME(FFileDesc,FileArea.Dos_Name+'.TXB');
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    RENAME(FFileDefs,FileArea.Dos_Name+'.FIB');
                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                    ASSIGN(FFileDesc2,FileArea.Dos_Name+'.TXB');
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    ASSIGN(FFileDefs2,FileArea.Dos_Name+'.FIB');
                                    RESET(FFileDesc2);
                                    REWRITE(FFileDesc);
                                    RESET(FFileDefs2);
                                    REWRITE(FFileDefs);
                                    REPEAT
                                          READ(FFileDefs2,FileDefs2);
                                          INC(Counting);
                                          FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                              READ(FFileDesc2,FileDesc2[Loop]);
                                          IF (Counting<Reference) THEN
                                          BEGIN
                                               WRITE(FFileDefs,FileDefs2);
                                               FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc2[Loop]);
                                          END
                                          ELSE IF Counting>Reference THEN
                                          BEGIN
                                               INC(FileDefs2.First_Desc,(Work-OldLines));
                                               WRITE(FFileDefs,FileDefs2);
                                               FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc2[Loop]);
                                          END
                                          ELSE
                                          BEGIN
                                               WRITE(FFileDefs,FileDefs);
                                               FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc[Loop]);
                                          END;
                                    UNTIL EOF(FFileDefs2);
                                    CLOSE(FFileDesc);
                                    CLOSE(FFileDesc2);
                                    CLOSE(FFileDefs);
                                    CLOSE(FFileDefs2);
                                    ERASE(FFileDesc2);
                                    ERASE(FFileDefs2);
                               END
                               ELSE IF Work<OldLines THEN
                               BEGIN
                                    FileDefs.Desc_Lines := Work;
                                    Counting  := 0;
                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                    RENAME(FFileDesc,FileArea.Dos_Name+'.TXB');
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    RENAME(FFileDefs,FileArea.Dos_Name+'.FIB');
                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                    ASSIGN(FFileDesc2,FileArea.Dos_Name+'.TXB');
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    ASSIGN(FFileDefs2,FileArea.Dos_Name+'.FIB');
                                    RESET(FFileDesc2);
                                    REWRITE(FFileDesc);
                                    RESET(FFileDefs2);
                                    REWRITE(FFileDefs);
                                    REPEAT
                                          READ(FFileDefs2,FileDefs2);
                                          INC(Counting);
                                          FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                              READ(FFileDesc2,FileDesc2[Loop]);
                                          IF (Counting<Reference) THEN
                                          BEGIN
                                               WRITE(FFileDefs,FileDefs2);
                                               FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc2[Loop]);
                                          END
                                          ELSE IF Counting>Reference THEN
                                          BEGIN
                                               DEC(FileDefs2.First_Desc,(OldLines-Work));
                                               WRITE(FFileDefs,FileDefs2);
                                               FOR Loop := 1 TO FileDefs2.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc2[Loop]);
                                          END
                                          ELSE
                                          BEGIN
                                               WRITE(FFileDefs,FileDefs);
                                               FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                   WRITE(FFileDesc,FileDesc[Loop]);
                                          END;
                                    UNTIL EOF(FFileDefs2);
                                    CLOSE(FFileDesc);
                                    CLOSE(FFileDesc2);
                                    CLOSE(FFileDefs);
                                    CLOSE(FFileDefs2);
                                    ERASE(FFileDesc2);
                                    ERASE(FFileDefs2);
                               END;
                               FileInfo^[FileNumber].FileDesc := FileDesc[1].Desc;
                               ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                               RESET(FPickingListFile2);
                               SEEK(FPickingListFile2,PickingItem2-1);
                               PickingListFile2.A := ' '+_PadRight(FileInfo^[FileNumber].Name,13);
                               PickingListFile2.A := PickingListFile2.A+
                                                     _PadLeft(_String(FileInfo^[FileNumber].FileSize),8);
                               PickingListFile2.A := PickingListFile2.A+'  '+FileInfo^[FileNumber].FileDesc;
                               WRITE(FPickingListFile2,PickingListFile2);
                               CLOSE(FPickingListFile2);
                               UpdatePickingList2;
                          END;
                     END;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           4:   IF HasFilesBBS THEN
                BEGIN {IMPORT}
                     IF _FileExists(FileArea.Area_Path+'FILES.BBS') THEN
                     BEGIN
                          _HideMouse;
                          ImportFilesBBS;
                          _ShowMouse;
                          GOTO OneMoreTime;
                     END;
                END;
           8:   IF PickingListItems2<>0 THEN
                BEGIN {COPY}
                     ToArea := SetDestinationArea;
                     IF ((ToArea<>0) AND (ToArea<>Number)) THEN
                     BEGIN
                          _SaveWindow(WorkDir+'\COPYTMP.SCR');
                          IF GotSomeTagged THEN
                          BEGIN
                               ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                               RESET(FPickingListFile2);
                               REPEAT
                                     READ(FPickingListFile2,PickingListFile2);
                                     IF PickingListFile2.A[1]='þ' THEN
                                     BEGIN
                                          DidIt   := False;
                                          Temp    := _Mid(PickingListFile2.A,2,13);
                                          TheFile := _UpperCase(_RemoveSpaces(Temp));
                                          InfoBox('COPYING FILE...',TheFile,'','');
                                          FoundIt := False;
                                          FOR loop := 1 TO FileCounter DO
                                          BEGIN
                                               IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                                               BEGIN
                                                    IF FileInfo^[Loop].FileType=1 THEN
                                                    BEGIN
                                                         FoundIt    := True;
                                                         FileNumber := Loop;
                                                    END;
                                               END;
                                          END;
                                          IF ((FoundIt) AND (KillPotentialDupe(ToArea,TheFile))) THEN
                                          BEGIN
                                               FillChar(FileDesc,SizeOf(FileDesc),0);
                                               ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                               {$I-}RESET(FFileDefs);{$I+}
                                               IF IOResult=0 THEN
                                               BEGIN
                                                    REPEAT
                                                          READ(FFileDefs,FileDefs);
                                                          IF _UpperCase(_RemoveSpaces(FileDefs.File_Name))=TheFile THEN
                                                          BEGIN
                                                               DidIt := True;
                                                               ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                                               RESET(FFileDesc);
                                                               SEEK(FFileDesc,FileDefs.First_Desc-1);
                                                               FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                                   READ(FFileDesc,FileDesc[Loop]);
                                                               CLOSE(FFileDesc);
                                                          END;
                                                    UNTIL (EOF(FFileDefs) OR DidIt);
                                                    CLOSE(FFileDefs);
                                               END;
                                          END;
                                          IF DidIt THEN
                                          BEGIN
                                               ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                               RESET(FFileArea);
                                               SEEK(FFileArea,ToArea-1);
                                               READ(FFileArea,FileArea3);
                                               CLOSE(FFileArea);
                                               IF _CopyFile(TheFile,FileArea.Area_Path,FileArea3.Area_Path) THEN
                                               BEGIN
                                                    {DO THE TEXT THING}
                                                    ASSIGN(FFileDesc,FileArea3.Dos_Name+'.TXT');
                                                    {$I-}RESET(FFileDesc);{$I+}
                                                    IF IOResult=0 THEN
                                                    BEGIN
                                                         FileDefs.First_Desc := FileSize(FFileDesc)+1;
                                                         SEEK(FFileDesc,FileSize(FFileDesc));
                                                         FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                             WRITE(FFileDesc,FileDesc[Loop]);
                                                         CLOSE(FFileDesc);
                                                    END
                                                    ELSE
                                                    BEGIN
                                                         FileDefs.First_Desc := 1;
                                                         REWRITE(FFileDesc);
                                                         FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                             WRITE(FFileDesc,FileDesc[Loop]);
                                                         CLOSE(FFileDesc);
                                                    END;
                                                    {DO THE FILE THING}
                                                    ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                                    {$I-}RESET(FFileDefs);{$I+}
                                                    IF IOResult=0 THEN
                                                    BEGIN
                                                         SEEK(FFileDefs,FileSize(FFileDefs));
                                                         WRITE(FFileDefs,FileDefs);
                                                         CLOSE(FFileDefs);
                                                    END
                                                    ELSE
                                                    BEGIN
                                                         REWRITE(FFileDefs);
                                                         WRITE(FFileDefs,FileDefs);
                                                         CLOSE(FFileDefs);
                                                    END;
                                                    {MAKE CALCULATIONS}
                                                    TBytes := 0;
                                                    TFiles := 0;
                                                    ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                                    RESET(FFileDefs);
                                                    REPEAT
                                                          READ(FFileDefs,FileDefs);
                                                          INC(TBytes,FileDefs.File_Size);
                                                          INC(TFiles);
                                                    UNTIL EOF(FFileDefs);
                                                    CLOSE(FFileDefs);
                                                    {FIX THE AREA FILE}
                                                    ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                                    RESET(FFileArea);
                                                    SEEK(FFileArea,ToArea-1);
                                                    READ(FFileArea,FileArea3);
                                                    FileArea3.Num_Files := TFiles;
                                                    FileArea3.Num_Bytes := TBytes;
                                                    SEEK(FFileArea,ToArea-1);
                                                    WRITE(FFileArea,FileArea3);
                                                    CLOSE(FFileArea);
                                                    SortArea(FileArea3.Dos_Name,FileArea3.Sort);
                                               END;
                                          END;
                                     END;
                                     ReloadArea;
                               UNTIL EOF(FPickingListFile2);
                               CLOSE(FPickingListFile2);
                               UnTagAll;
                          END
                          ELSE
                          BEGIN
                               DidIt := False;
                               ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                               RESET(FPickingListFile2);
                               Seek(FPickingListFile2,PickingItem2-1);
                               READ(FPickingListFile2,PickingListFile2);
                               CLOSE(FPickingListFile2);
                               Temp    := _Mid(PickingListFile2.A,2,13);
                               TheFile := _UpperCase(_RemoveSpaces(Temp));
                               InfoBox('COPYING FILE...',TheFile,'','');
                               FoundIt := False;
                               FOR loop := 1 TO FileCounter DO
                               BEGIN
                                    IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                                    BEGIN
                                         IF FileInfo^[Loop].FileType=1 THEN
                                         BEGIN
                                              FoundIt    := True;
                                              FileNumber := Loop;
                                         END;
                                    END;
                               END;
                               IF ((FoundIt) AND (KillPotentialDupe(ToArea,TheFile))) THEN
                               BEGIN
                                    FillChar(FileDesc,SizeOf(FileDesc),0);
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    {$I-}RESET(FFileDefs);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         REPEAT
                                               READ(FFileDefs,FileDefs);
                                               IF _UpperCase(_RemoveSpaces(FileDefs.File_Name))=TheFile THEN
                                               BEGIN
                                                    DidIt := True;
                                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                                    RESET(FFileDesc);
                                                    SEEK(FFileDesc,FileDefs.First_Desc-1);
                                                    FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                        READ(FFileDesc,FileDesc[Loop]);
                                                    CLOSE(FFileDesc);
                                               END;
                                         UNTIL (EOF(FFileDefs) OR DidIt);
                                         CLOSE(FFileDefs);
                                    END;
                               END;
                               IF DidIt THEN
                               BEGIN
                                    ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                    RESET(FFileArea);
                                    SEEK(FFileArea,ToArea-1);
                                    READ(FFileArea,FileArea3);
                                    CLOSE(FFileArea);
                                    IF _CopyFile(TheFile,FileArea.Area_Path,FileArea3.Area_Path) THEN
                                    BEGIN
                                         {DO THE TEXT THING}
                                         ASSIGN(FFileDesc,FileArea3.Dos_Name+'.TXT');
                                         {$I-}RESET(FFileDesc);{$I+}
                                         IF IOResult=0 THEN
                                         BEGIN
                                              FileDefs.First_Desc := FileSize(FFileDesc)+1;
                                              SEEK(FFileDesc,FileSize(FFileDesc));
                                              FOR Loop := 1 TO FileDefs.Desc_Lines DO WRITE(FFileDesc,FileDesc[Loop]);
                                              CLOSE(FFileDesc);
                                         END
                                         ELSE
                                         BEGIN
                                              FileDefs.First_Desc := 1;
                                              REWRITE(FFileDesc);
                                              FOR Loop := 1 TO FileDefs.Desc_Lines DO WRITE(FFileDesc,FileDesc[Loop]);
                                              CLOSE(FFileDesc);
                                         END;
                                         {DO THE FILE THING}
                                         ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                         {$I-}RESET(FFileDefs);{$I+}
                                         IF IOResult=0 THEN
                                         BEGIN
                                              SEEK(FFileDefs,FileSize(FFileDefs));
                                              WRITE(FFileDefs,FileDefs);
                                              CLOSE(FFileDefs);
                                         END
                                         ELSE
                                         BEGIN
                                              REWRITE(FFileDefs);
                                              WRITE(FFileDefs,FileDefs);
                                              CLOSE(FFileDefs);
                                         END;
                                         {MAKE CALCULATIONS}
                                         TBytes := 0;
                                         TFiles := 0;
                                         ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                         RESET(FFileDefs);
                                         REPEAT
                                               READ(FFileDefs,FileDefs);
                                               INC(TBytes,FileDefs.File_Size);
                                               INC(TFiles);
                                         UNTIL EOF(FFileDefs);
                                         CLOSE(FFileDefs);
                                         {FIX THE AREA FILE}
                                         ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                         RESET(FFileArea);
                                         SEEK(FFileArea,ToArea-1);
                                         READ(FFileArea,FileArea3);
                                         FileArea3.Num_Files := TFiles;
                                         FileArea3.Num_Bytes := TBytes;
                                         SEEK(FFileArea,ToArea-1);
                                         WRITE(FFileArea,FileArea3);
                                         CLOSE(FFileArea);
                                         SortArea(FileArea3.Dos_Name,FileArea3.Sort);
                                    END;
                               END;
                               ReloadArea;
                          END;
                          LoadWindow(WorkDir+'\COPYTMP.SCR');
                          UpdatePickingList2;
                     END;
                END;
           9:   IF PickingListItems2<>0 THEN
                BEGIN {MOVE}
                     ToArea := SetDestinationArea;
                     IF ((ToArea<>0) AND (ToArea<>Number)) THEN
                     BEGIN
                          _SaveWindow(WorkDir+'\COPYTMP.SCR');
                          IF GotSomeTagged THEN
                          BEGIN
                               ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                               RESET(FPickingListFile2);
                               REPEAT
                                     READ(FPickingListFile2,PickingListFile2);
                                     IF PickingListFile2.A[1]='þ' THEN
                                     BEGIN
                                          DidIt   := False;
                                          Temp    := _Mid(PickingListFile2.A,2,13);
                                          TheFile := _UpperCase(_RemoveSpaces(Temp));
                                          InfoBox('MOVING FILE...',TheFile,'','');
                                          FoundIt := False;
                                          FOR loop := 1 TO FileCounter DO
                                          BEGIN
                                               IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                                               BEGIN
                                                    IF FileInfo^[Loop].FileType=1 THEN
                                                    BEGIN
                                                         FoundIt    := True;
                                                         FileNumber := Loop;
                                                    END;
                                               END;
                                          END;
                                          IF ((FoundIt) AND (KillPotentialDupe(ToArea,TheFile))) THEN
                                          BEGIN
                                               FillChar(FileDesc,SizeOf(FileDesc),0);
                                               ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                               {$I-}RESET(FFileDefs);{$I+}
                                               IF IOResult=0 THEN
                                               BEGIN
                                                    REPEAT
                                                          READ(FFileDefs,FileDefs);
                                                          IF _UpperCase(_RemoveSpaces(FileDefs.File_Name))=TheFile THEN
                                                          BEGIN
                                                               DidIt := True;
                                                               ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                                               RESET(FFileDesc);
                                                               SEEK(FFileDesc,FileDefs.First_Desc-1);
                                                               FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                                   READ(FFileDesc,FileDesc[Loop]);
                                                               CLOSE(FFileDesc);
                                                          END;
                                                    UNTIL (EOF(FFileDefs) OR DidIt);
                                                    CLOSE(FFileDefs);
                                               END;
                                          END;
                                          IF DidIt THEN
                                          BEGIN
                                               ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                               RESET(FFileArea);
                                               SEEK(FFileArea,ToArea-1);
                                               READ(FFileArea,FileArea3);
                                               CLOSE(FFileArea);
                                               IF _CopyFile(TheFile,FileArea.Area_Path,FileArea3.Area_Path) THEN
                                               BEGIN
                                                    {DO THE TEXT THING}
                                                    ASSIGN(FFileDesc,FileArea3.Dos_Name+'.TXT');
                                                    {$I-}RESET(FFileDesc);{$I+}
                                                    IF IOResult=0 THEN
                                                    BEGIN
                                                         FileDefs.First_Desc := FileSize(FFileDesc)+1;
                                                         SEEK(FFileDesc,FileSize(FFileDesc));
                                                         FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                             WRITE(FFileDesc,FileDesc[Loop]);
                                                         CLOSE(FFileDesc);
                                                    END
                                                    ELSE
                                                    BEGIN
                                                         FileDefs.First_Desc := 1;
                                                         REWRITE(FFileDesc);
                                                         FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                             WRITE(FFileDesc,FileDesc[Loop]);
                                                         CLOSE(FFileDesc);
                                                    END;
                                                    {DO THE FILE THING}
                                                    ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                                    {$I-}RESET(FFileDefs);{$I+}
                                                    IF IOResult=0 THEN
                                                    BEGIN
                                                         SEEK(FFileDefs,FileSize(FFileDefs));
                                                         WRITE(FFileDefs,FileDefs);
                                                         CLOSE(FFileDefs);
                                                    END
                                                    ELSE
                                                    BEGIN
                                                         REWRITE(FFileDefs);
                                                         WRITE(FFileDefs,FileDefs);
                                                         CLOSE(FFileDefs);
                                                    END;
                                                    {MAKE CALCULATIONS}
                                                    TBytes := 0;
                                                    TFiles := 0;
                                                    ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                                    RESET(FFileDefs);
                                                    REPEAT
                                                          READ(FFileDefs,FileDefs);
                                                          INC(TBytes,FileDefs.File_Size);
                                                          INC(TFiles);
                                                    UNTIL EOF(FFileDefs);
                                                    CLOSE(FFileDefs);
                                                    {FIX THE AREA FILE}
                                                    ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                                    RESET(FFileArea);
                                                    SEEK(FFileArea,ToArea-1);
                                                    READ(FFileArea,FileArea3);
                                                    FileArea3.Num_Files := TFiles;
                                                    FileArea3.Num_Bytes := TBytes;
                                                    SEEK(FFileArea,ToArea-1);
                                                    WRITE(FFileArea,FileArea3);
                                                    CLOSE(FFileArea);
                                                    SortArea(FileArea3.Dos_Name,FileArea3.Sort);
                                                    DeleteFromDataBase(TheFile);
                                                    _EraseFile(FileArea.Area_Path+TheFile);
                                               END;
                                          END;
                                     END;
                                     ReloadArea;
                               UNTIL EOF(FPickingListFile2);
                               CLOSE(FPickingListFile2);
                               UnTagAll;
                          END
                          ELSE
                          BEGIN
                               DidIt := False;
                               ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                               RESET(FPickingListFile2);
                               Seek(FPickingListFile2,PickingItem2-1);
                               READ(FPickingListFile2,PickingListFile2);
                               CLOSE(FPickingListFile2);
                               Temp    := _Mid(PickingListFile2.A,2,13);
                               TheFile := _UpperCase(_RemoveSpaces(Temp));
                               InfoBox('MOVING FILE...',TheFile,'','');
                               FoundIt := False;
                               FOR loop := 1 TO FileCounter DO
                               BEGIN
                                    IF _UpperCase(_RemoveSpaces(FileInfo^[Loop].Name))=TheFile THEN
                                    BEGIN
                                         IF FileInfo^[Loop].FileType=1 THEN
                                         BEGIN
                                              FoundIt    := True;
                                              FileNumber := Loop;
                                         END;
                                    END;
                               END;
                               IF ((FoundIt) AND (KillPotentialDupe(ToArea,TheFile))) THEN
                               BEGIN
                                    FillChar(FileDesc,SizeOf(FileDesc),0);
                                    ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
                                    {$I-}RESET(FFileDefs);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         REPEAT
                                               READ(FFileDefs,FileDefs);
                                               IF _UpperCase(_RemoveSpaces(FileDefs.File_Name))=TheFile THEN
                                               BEGIN
                                                    DidIt := True;
                                                    ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
                                                    RESET(FFileDesc);
                                                    SEEK(FFileDesc,FileDefs.First_Desc-1);
                                                    FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                                        READ(FFileDesc,FileDesc[Loop]);
                                                    CLOSE(FFileDesc);
                                               END;
                                         UNTIL (EOF(FFileDefs) OR DidIt);
                                         CLOSE(FFileDefs);
                                    END;
                               END;
                               IF DidIt THEN
                               BEGIN
                                    ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                    RESET(FFileArea);
                                    SEEK(FFileArea,ToArea-1);
                                    READ(FFileArea,FileArea3);
                                    CLOSE(FFileArea);
                                    IF _CopyFile(TheFile,FileArea.Area_Path,FileArea3.Area_Path) THEN
                                    BEGIN
                                         {DO THE TEXT THING}
                                         ASSIGN(FFileDesc,FileArea3.Dos_Name+'.TXT');
                                         {$I-}RESET(FFileDesc);{$I+}
                                         IF IOResult=0 THEN
                                         BEGIN
                                              FileDefs.First_Desc := FileSize(FFileDesc)+1;
                                              SEEK(FFileDesc,FileSize(FFileDesc));
                                              FOR Loop := 1 TO FileDefs.Desc_Lines DO WRITE(FFileDesc,FileDesc[Loop]);
                                              CLOSE(FFileDesc);
                                         END
                                         ELSE
                                         BEGIN
                                              FileDefs.First_Desc := 1;
                                              REWRITE(FFileDesc);
                                              FOR Loop := 1 TO FileDefs.Desc_Lines DO WRITE(FFileDesc,FileDesc[Loop]);
                                              CLOSE(FFileDesc);
                                         END;
                                         {DO THE FILE THING}
                                         ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                         {$I-}RESET(FFileDefs);{$I+}
                                         IF IOResult=0 THEN
                                         BEGIN
                                              SEEK(FFileDefs,FileSize(FFileDefs));
                                              WRITE(FFileDefs,FileDefs);
                                              CLOSE(FFileDefs);
                                         END
                                         ELSE
                                         BEGIN
                                              REWRITE(FFileDefs);
                                              WRITE(FFileDefs,FileDefs);
                                              CLOSE(FFileDefs);
                                         END;
                                         {MAKE CALCULATIONS}
                                         TBytes := 0;
                                         TFiles := 0;
                                         ASSIGN(FFileDefs,FileArea3.Dos_Name+'.FIL');
                                         RESET(FFileDefs);
                                         REPEAT
                                               READ(FFileDefs,FileDefs);
                                               INC(TBytes,FileDefs.File_Size);
                                               INC(TFiles);
                                         UNTIL EOF(FFileDefs);
                                         CLOSE(FFileDefs);
                                         {FIX THE AREA FILE}
                                         ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                                         RESET(FFileArea);
                                         SEEK(FFileArea,ToArea-1);
                                         READ(FFileArea,FileArea3);
                                         FileArea3.Num_Files := TFiles;
                                         FileArea3.Num_Bytes := TBytes;
                                         SEEK(FFileArea,ToArea-1);
                                         WRITE(FFileArea,FileArea3);
                                         CLOSE(FFileArea);
                                         SortArea(FileArea3.Dos_Name,FileArea3.Sort);
                                         DeleteFromDataBase(TheFile);
                                         _EraseFile(FileArea.Area_Path+TheFile);
                                    END;
                               END;
                               ReloadArea;
                          END;
                          LoadWindow(WorkDir+'\COPYTMP.SCR');
                          GOTO OneMoreTime;
                     END;
                END;
           10:  IF PickingListItems2<>0 THEN {TAG/DETAG}
                BEGIN
                     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
                     RESET(FPickingListFile2);
                     SEEK(FPickingListFile2,PickingItem2-1);
                     READ(FPickingListFile2,PickingListFile2);
                     IF PickingListFile2.A[1]=#32
                        THEN PickingListFile2.A[1] := 'þ'
                        ELSE PickingListFile2.A[1] := ' ';
                     SEEK(FPickingListFile2,PickingItem2-1);
                     WRITE(FPickingListFile2,PickingListFile2);
                     CLOSE(FPickingListFile2);
                     UpdatePickingList2;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickingListFile2);
     LoadWindow(WorkDir+'\FILEDIRS.SCR');
     ReloadArea;
     {MAKE CALCULATIONS}
     TBytes := 0;
     TFiles := 0;
     IF _FileExists(FileArea.Dos_Name+'.FIL') THEN
     BEGIN
          ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
          RESET(FFileDefs);
          REPEAT
                READ(FFileDefs,FileDefs);
                INC(TBytes,FileDefs.File_Size);
                INC(TFiles);
          UNTIL EOF(FFileDefs);
          CLOSE(FFileDefs);
     END;
     {FIX THE AREA FILE}
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,Number-1);
     READ(FFileArea,FileArea);
     FileArea.Num_Files := TFiles;
     FileArea.Num_Bytes := TBytes;
     SEEK(FFileArea,Number-1);
     WRITE(FFileArea,FileArea);
     CLOSE(FFileArea);
     {SORT THE AREA}
     IF _FileExists(FileArea.Dos_Name+'.FIL') THEN
        SortArea(FileArea.Dos_Name,FileArea.Sort);
END;


END.
