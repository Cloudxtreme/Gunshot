{$I DEFINES.INC}
UNIT Import;


INTERFACE


PROCEDURE ImportCD       (Script: String; CdDrive: String; BBSType: Byte);
PROCEDURE ImportFilesBBS;


IMPLEMENTATION


USES DOS,CRT,BsString,BsFile,CnfgVars,IntrFace,FastW1,MkString,BsVideo;


FUNCTION CheckTab(InString: String): String;
VAR  Work : Word;
BEGIN
     REPEAT
           Work := Pos(#9,InString);
           IF Work<>0 THEN
           BEGIN
                Delete(InString,Work,1);
                Insert('        ',InString,Work);
           END;
     UNTIL Work=0;
     CheckTab := InString;
END;


FUNCTION RemoveLeftSpaces(InString: String): String;
VAR  Poop       : Word;
     Locator    : Word;
     AllDone    : Boolean;
BEGIN
     IF InString='' THEN
     BEGIN
          RemoveLeftSpaces := '';
          Exit;
     END;
     Locator := 0;
     AllDone := False;
     REPEAT
           INC(Locator);
           IF InString[Locator]<>' ' THEN AllDone := True;
     UNTIL AllDone;
     DEC(Locator);
     Delete(InString,1,Locator);
          IF _Mid(InString,1,2)='| ' THEN Delete(InString,1,2)
     ELSE IF _Mid(InString,1,1)='|'  THEN Delete(InString,1,1);
     RemoveLeftSpaces := InString;
END;


FUNCTION RemoveCounters(InString: String): String;
VAR
     Poop       : Word;
     WhichOne   : Char;
     From       : Word;
     Temp       : String;
BEGIN
     IF InString[1]='[' THEN WhichOne := ']';
     IF InString[1]='}' THEN WhichOne := '}';
     Poop := 1;
     From := 0;
     REPEAT
           IF InString[Poop]=WhichOne THEN From := Poop;
           INC(Poop);
     UNTIL (From<>0);
     Temp := _Mid(InString,From+1,LENGTH(InString));
     Temp := RemoveLeftSpaces(Temp);
     RemoveCounters := Temp;
END;


PROCEDURE ImportCD(Script: String; CdDrive: String; BBSType: Byte);
TYPE New_Files_BBS = RECORD
     Line        : String[80];
     END;
TYPE ImportRef = RECORD
     Name      : String[12];
     END;
VAR  ImportFile    : ImportRef;
     FImportFile   : File Of ImportRef;
     NewFilesBBS   : New_Files_BBS;
     FNewFilesBBS  : File Of New_Files_BBS;
     InfoFile      : Text;
     FilesBBS      : Text;
     FileLoc       : Array[1..800] Of Word;
     ScrapLine     : String;
     TotalLines    : Word;
     TotalFiles    : Word;
     Loop          : Word;
     Loop2         : Word;
     FileName      : String[80];
     DestDir       : String[80];
     Horse         : String;
     AreaCount     : Word;
     Terd          : Word;
     CD_Path       : String[80];
     ByteCounter   : Longint;
     DescLoop      : Word;
     DescCount     : Word;
     FDescCounter  : Longint;
     Garbage       : String;
     CommandLine   : String;
     GotFirstFile  : Boolean;
     DDirInfo      : SearchRec;
     Proceed       : Boolean;
     TryAgain      : Boolean;
LABEL                NoFilesBBS,ReDoIt;


PROCEDURE WakeUpCd;
VAR  DirInfo   : SearchRec;
     TimeCount : Word;
BEGIN
     IF IOResult=0 THEN;
     TimeCount := 0;
     REPEAT
           INC(TimeCount);
           FindFirst(CD_PATH+'*.*',AnyFile,DirInfo);
           IF DosError=0 THEN TimeCount := 0
                         ELSE Delay(100);
     UNTIL ((TimeCount=0) OR (TimeCount=300));
     IF IOResult=0 THEN;
END;


FUNCTION RemoveFileName(InString: String): String;
VAR  Poop       : Word;
     GotIt      : Word;
     WWork      : String;
     GotPCB     : Boolean;
BEGIN
     GotPCB := False;
     WWork := _Mid(InString,24,31);
     IF ((WWork[3]='-') AND (WWork[6]='-')) THEN
     BEGIN
          Delete(WWork,6,1);
          Delete(WWork,3,1);
          IF IsNumeric(WWork) THEN GotPCB := True;
     END;
     IF GotPCB THEN
     BEGIN
          Delete(InString,1,33);
          RemoveFileName := InString;
     END
     ELSE
     BEGIN
          Poop  := 1;
          GotIt := 0;
          REPEAT
                IF InString[Poop]=CHR(32) THEN GotIt := Poop;
                INC(Poop);
          UNTIL (Gotit<>0);
          Delete(InString,1,Poop-1);
          InString := RemoveLeftSpaces(InString);
          IF ((InString[1]='[') OR (InString[1]='{')) THEN InString := RemoveCounters(InString);
          RemoveFileName := InString;
     END;
END;


PROCEDURE LongToMulti(FileName: String);
VAR  Ln        : Array[1..900] Of Char;
     Wk        : Text;
     Temp      : String;
     Count     : Word;
     c         : Char;
     Wrote     : Word;
     Runner    : Word;
     Pooper    : Word;
     Pooper2   : Word;
     Written   : Boolean;
     TheFile   : String;
     LastSpace : Word;
     LastGone  : Word;
     Buf       : Array[1..8192] Of Char;
BEGIN
     FillChar(Ln,SizeOf(Ln),0);
     ASSIGN(FNewFilesBBS,WorkDir+'\FILESBBS.NEW');
     ASSIGN(Wk,FileName);
     SetTextBuf(Wk,Buf);
     REWRITE(FNewFilesBBS);
     RESET(Wk);
     REPEAT
           Wrote := 0;
           Temp  := '';
           Count := 0;
           REPEAT
                 IF NOT(EoLn(Wk)) THEN
                 BEGIN
                      READ(Wk,C);
                      INC(Count);
                      Ln[Count] := C;
                 END;
           UNTIL EoLn(Wk);
           READLN(Wk,Temp);
           IF ((Ln[1]<>' ') AND (Count>5)) THEN
           BEGIN
                {GET THE FILENAME}
                TheFile := '';
                FOR Pooper := 1 TO 12 DO
                BEGIN
                     IF Ln[Pooper]<>' ' THEN TheFile := TheFile+Ln[Pooper];
                END;

                {SEEK THE START OF THE DESCRIPTION}
                runner := 0;
                FOR Pooper := LENGTH(TheFile)+1 TO Count DO
                BEGIN
                     IF Runner=0 THEN
                     BEGIN
                          IF Ln[Pooper]<>' ' THEN Runner := Pooper;
                     END;
                END;

                Written   := False;
                Pooper    := Runner;
                LastGone  := 0;
                LastSpace := Runner;
                REPEAT
                      IF (Pooper-Runner+1)>46 THEN
                      BEGIN
                           Temp := '';
                           FOR Pooper2 := Runner TO LastSpace DO Temp := Temp+Ln[Pooper2];
                           IF Written THEN NewFilesBBS.Line := _PadRight('',15)+Temp
                                      ELSE NewFilesBBS.Line := _PadRight(TheFile,15)+Temp;
                           WRITE(FNewFilesBBS,NewFilesBBS);
                           LastGone := LastSpace;
                           Runner   := LastSpace+1;
                           Pooper   := Runner-1;
                           Written  := True;
                      END
                      ELSE
                      BEGIN
                           IF ((Ln[Pooper]=' ') OR (Ln[Pooper]='-') OR (Ln[Pooper]='/') OR (Ln[Pooper]='\'))
                              THEN LastSpace := Pooper;
                      END;
                      INC(Pooper);
                      IF Pooper=Count THEN
                      BEGIN
                           IF LastGone<>Count THEN
                           BEGIN
                                Temp := '';
                                FOR Pooper2 := Runner TO Count DO Temp := Temp+Ln[Pooper2];
                                IF Written THEN NewFilesBBS.Line := _PadRight('',15)+Temp
                                           ELSE NewFilesBBS.Line := _PadRight(TheFile,15)+Temp;
                                WRITE(FNewFilesBBS,NewFilesBBS);
                                LastGone := Count;
                                Written  := True;
                           END;
                      END;
                UNTIL LastGone=Count;
           END;
     UNTIL EOF(Wk);
     CLOSE(FNewFilesBBS);
     CLOSE(Wk);
     IF IOResult=0 THEN;
END;


PROCEDURE ZapIt(FileName: String);
VAR  Wk   : Text;
     Temp : String;
     Buf  : Array[1..8192] Of Char;
BEGIN
     ASSIGN(FNewFilesBBS,WorkDir+'\FILESBBS.NEW');
     ASSIGN(Wk,FileName);
     SetTextBuf(Wk,Buf);
     REWRITE(FNewFilesBBS);
     RESET(Wk);
     REPEAT
           READLN(Wk,Temp);
           NewFilesBBS.Line := Temp;
           WRITE(FNewFilesBBS,NewFilesBBS);
     UNTIL EOF(Wk);
     CLOSE(FNewFilesBBS);
     CLOSE(Wk);
END;


BEGIN
     _SaveWindow(WorkDir+'\IMPORTCD.VID');
     AreaCount := 0;
     DrawWindow(10,5,60,18,'IMPORT CD ROM',True);
     ASSIGN(InfoFile,Script);
     {$I-}RESET(InfoFile);{$I+}
     IF IOResult<>0 THEN
     BEGIN
          Window(1,1,80,25);
          LoadWindow(WorkDir+'\IMPORTCD.VID');
          Exit;
     END;
     NEW(FileInfo3);
     DestDir := FileArea.DOS_Name;
     REPEAT
           READLN(InfoFile,FileArea.Area_Name);
           READLN(InfoFile,ScrapLine);
           FastWrite(_PadRight('AREA: '+FileArea.Area_Name,48),6,12,27);
           FastWrite(_PadRight('',12),7,12,27);
           FastWrite(_PadRight('',46),8,12,27);
           FastWrite(_PadRight('',46),9,12,27);
           FastWrite(_PadRight('',46),10,12,27);
           FastWrite(_PadRight('',46),11,12,27);
           FastWrite(_PadRight('',46),12,12,27);
           FastWrite(_PadRight('',46),13,12,27);
           FastWrite(_PadRight('',46),14,12,27);
           FastWrite(_PadRight('',46),15,12,27);
           FastWrite(_PadRight('',46),16,12,27);
           FastWrite(_PadRight('',46),17,12,27);
           ScrapLine := CDDrive+':'+ScrapLine;
           {COUNT LINES & FILES}
           ByteCounter  := 0;
           TotalLines   := 0;
           TotalFiles   := 0;
           FDescCounter := 1;
           INC(AreaCount);
           CD_Path := ScrapLine;
           _EraseFile(WorkDir+'\FILESBBS.NEW');
           _EraseFile(WorkDir+'\FILES.BBS');

           Garbage := '';
           IF Pos(';',CD_Path)<>0 THEN
           BEGIN
                Garbage := CD_Path;
                Loop := Pos(';',CD_Path);
                CD_Path := _Mid(Garbage,1,Loop-1);
                Delete(Garbage,1,Loop);
           END;

           IF CD_PATH[LENGTH(CD_PATH)]<>'\' THEN CD_PATH := CD_PATH+'\';
           CD_PATH := _UpperCase(CD_PATH);

           {Check if the area already exists}
           ASSIGN(FFileArea2,'DATA\FA000000.DAT');
           RESET(FFileArea2);
           REPEAT
                 READ(FFileArea2,FileArea2);
                 IF FileArea2.cd_rom=FileArea.Cd_Rom THEN
                 BEGIN
                      IF _UpperCase(FileArea2.Area_Name)=_UpperCase(FileArea.Area_Name) THEN
                      BEGIN
                           IF _UpperCase(FileArea2.Area_Path)=_UpperCase(CD_PATH) THEN
                           BEGIN
                                CLOSE(FFileArea2);
                                GOTO NoFilesBBS;
                           END;
                      END;
                 END;
           UNTIL EOF(FFileArea2);
           CLOSE(FFileArea2);

           WakeUpCd;
           IF Garbage='' THEN
           BEGIN
                IF NOT(_FileExists(CD_PATH+'FILES.BBS')) THEN GOTO NoFilesBBS;
                IF NOT(_CopyFile('FILES.BBS',CD_PATH,WorkDir)) THEN GOTO NoFilesBBS;
           END;

           {IF ITS LONGLINE, THEN CONVERT IT TO MULTILINE}
           CASE BBSType OF
           1:   BEGIN
                     IF Garbage='' THEN ZapIt(WorkDir+'\FILES.BBS')
                                   ELSE ZapIt(Garbage);
                END;
           2:   BEGIN
                     IF Garbage='' THEN LongToMulti(WorkDir+'\FILES.BBS')
                                   ELSE LongToMulti(Garbage);
                END;
           END;


           {ASSIGN THE FILES BBS TO THE CORRECT TEXT FILE - THEY ARE ALL MULTILINE!}
           ASSIGN(FNewFilesBBS,WorkDir+'\FILESBBS.NEW');
           RESET(FNewFilesBBS);

           {Load In The Directory}
           FileCounter := 0;
           FindFirst(CD_Path+'*.*',Anyfile-Directory-VolumeID,DDirInfo);
           WHILE DosError = 0 DO
           BEGIN
                IF (DDirInfo.Name<>'FILES.BBS') THEN
                BEGIN
                     INC(FileCounter);
                     FileInfo3^[FileCounter].Name := DDirInfo.Name;
                     FileInfo3^[FileCounter].Size := DDirInfo.Size;
                     FileInfo3^[FileCounter].Time := DDirInfo.Time;
                END;
                FindNext(DDirInfo);
           END;
           IF FileCounter=0 THEN GOTO NoFilesBBS;
           FileDefs.class       := 0;
           FileDefs.free        := 0;
           FileDefs.dled        := 0;
           FileDefs.uploader    := 'Gunshot CD Rom Importer';
           FileDefs.added_date  := proper_date;
           ASSIGN(FFileDefs,DestDir+_String(AreaCount)+'.FIL');
           ASSIGN(FFileDesc,DestDir+_String(AreaCount)+'.TXT');
           REWRITE(FFileDefs);
           REWRITE(FFileDesc);
           FOR Loop := 1 TO FileCounter DO
           BEGIN
                FileDefs.File_Name   := FileInfo3^[Loop].Name;
                FileDefs.File_Size   := FileInfo3^[Loop].Size;
                FileDefs.File_Date   := FileInfo3^[Loop].Time;
                Proceed := False;
                TryAgain := False;
                ReDoIt:
                REPEAT
                      IF NOT(EOF(FNewFilesBBS)) THEN
                      BEGIN
                           READ(FNewFilesBBS,NewFilesBBS);
                           IF _UpperCase(_RemoveSpaces(_Mid(NewFilesBBS.Line,1,12)))=FileDefs.File_Name
                              THEN Proceed := True;
                      END;
                UNTIL ((EOF(FNewFilesBBS)) OR (Proceed));
                IF ((NOT(Proceed)) AND (NOT(TryAgain))) THEN
                BEGIN
                     TryAgain := True;
                     RESET(FNewFilesBBS);
                     GOTO ReDoIt;
                END;
                IF Proceed THEN
                BEGIN
                     {Do the first line}
                     ScrapLine := CheckTab(RemoveFileName(NewFilesBBS.Line));
                     DescCount := 1;
                     FillChar(FileDesc,SizeOf(FileDesc),0);
                     FileDesc[1].Desc := ScrapLine;
                     {Do the rest}
                     Proceed := False;
                     REPEAT
                           IF NOT(EOF(FNewFilesBBS)) THEN
                           BEGIN
                                READ(FNewFilesBBS,NewFilesBBS);
                                ScrapLine := CheckTab(NewFilesBBS.Line);
                                IF (ScrapLine[1]<>#32) THEN Proceed := True
                                ELSE
                                BEGIN
                                     IF (DescCount<18) THEN
                                     BEGIN
                                          INC(DescCount);
                                          FileDesc[DescCount].Desc := RemoveLeftSpaces(ScrapLine);
                                     END;
                                END;
                           END;
                     UNTIL ((EOF(FNewFilesBBS)) OR (Proceed));
                     {$I-}SEEK(FNewFilesBBS,FilePos(FNewFilesBBS)-2);{$I+}
                     IF IOResult<>0 THEN
                     BEGIN
                          {$I-}SEEK(FNewFilesBBS,FilePos(FNewFilesBBS)-1);{$I+}
                          IF IOResult=0 THEN;
                     END;
                     FileDefs.Desc_Lines  := DescCount;
                     FileDefs.First_Desc  := FDescCounter;
                     ByteCounter          := ByteCounter+FileDefs.File_Size;
                     FDescCounter         := FDescCounter+DescCount;
                     INC(TotalFiles);
                     WRITE(FFileDefs,FileDefs);
                     FOR DescLoop := 1 TO DescCount DO
                         WRITE(FFileDesc,FileDesc[DescLoop]);
                     {Display}
                     FastWrite(_PadRight(FileDefs.File_Name,12),7,12,27);
                     FastWrite(_PadRight(FileDesc[1].Desc,46),8,12,27);
                     FastWrite(_PadRight(FileDesc[2].Desc,46),9,12,27);
                     FastWrite(_PadRight(FileDesc[3].Desc,46),10,12,27);
                     FastWrite(_PadRight(FileDesc[4].Desc,46),11,12,27);
                     FastWrite(_PadRight(FileDesc[5].Desc,46),12,12,27);
                     FastWrite(_PadRight(FileDesc[6].Desc,46),13,12,27);
                     FastWrite(_PadRight(FileDesc[7].Desc,46),14,12,27);
                     FastWrite(_PadRight(FileDesc[8].Desc,46),15,12,27);
                     FastWrite(_PadRight(FileDesc[9].Desc,46),16,12,27);
                     FastWrite(_PadRight(FileDesc[10].Desc,46),17,12,27);
                END;
           END;
           CLOSE(FFileDefs);
           CLOSE(FFileDesc);
           CLOSE(FNewFilesBBS);

           {Update The Areas}
           FileArea.Area_Path  := CD_Path;
           FileArea.Dos_Name   := DestDir+_String(AreaCount);
           FileArea.Num_Files  := TotalFiles;
           FileArea.Num_Bytes  := ByteCounter;
           IF TotalFiles<>0 THEN
           BEGIN
                ASSIGN(FFileArea,'DATA\FA000000.DAT');
                RESET(FFileArea);
                SEEK(FFileArea,FileSize(FFileArea));
                WRITE(FFileArea,FileArea);
                CLOSE(FFileArea);
                INC(FileArea.AreaID);
           END;
           NoFilesBBS:
     UNTIL (EOF(InfoFile) OR KeyPressed);
     CLOSE(InfoFile);
     DISPOSE(FileInfo3);
     Window(1,1,80,25);
     LoadWindow(WorkDir+'\IMPORTCD.VID');
     _EraseFile(WorkDir+'\FILESBBS.NEW');
     _EraseFile(WorkDir+'\FILES.NEW');
END;


PROCEDURE ImportFilesBBS;
TYPE New_Files_BBS = RECORD
     Line        : String[80];
     END;
TYPE ImportRef = RECORD
     Name      : String[12];
     END;
VAR  IsItThere     : Boolean;
     ImportFile    : ImportRef;
     FImportFile   : File Of ImportRef;
     InfoFile      : Text;
     NewFilesBBS   : New_Files_BBS;
     FNewFilesBBS  : File Of New_Files_BBS;
     FilesBBS      : Text;
     FileLoc       : Array[1..800] Of Word;
     TotalLines    : Word;
     TotalFiles    : Word;
     Loop          : Word;
     Loop2         : Word;
     FileName      : String[80];
     DestDir       : String[80];
     Horse         : String;
     AreaCount     : Word;
     Terd          : Word;
     ByteCounter   : Longint;
     DescLoop      : Word;
     DescCount     : Word;
     ListType      : String[80];
     FDescCounter  : Longint;
     Garbage       : String;
     ScrapLine     : String;
     GotFirstFile  : Boolean;


PROCEDURE RemoveFileName;
VAR  Poop       : Word;
     GotIt      : Word;
BEGIN
     Poop  := 1;
     GotIt := 0;
     REPEAT
           IF NewFilesBBS.Line[Poop]=CHR(32) THEN GotIt := Poop;
           INC(Poop);
     UNTIL (Gotit<>0);
     FileName         := _Mid(NewFilesBBS.Line,1,Poop-2);
     NewFilesBBS.Line := _Mid(NewFilesBBS.Line,Poop,LENGTH(NewFilesBBS.Line));
     NewFilesBBS.Line := RemoveLeftSpaces(NewFilesBBS.Line);
     IF ((NewFilesBBS.Line[1]='[') OR (NewFIlesBBS.Line[1]='{')) THEN
        NewFilesBBS.Line := RemoveCounters(NewFilesBBS.Line);
END;


PROCEDURE LongToMulti(FileName: String);
VAR  Ln        : Array[1..900] Of Char;
     Wk        : Text;
     Fbbs      : Text;
     Temp      : String;
     Count     : Word;
     c         : Char;
     Wrote     : Word;
     Runner    : Word;
     Pooper    : Word;
     Pooper2   : Word;
     Written   : Boolean;
     TheFile   : String;
     LastSpace : Word;
     LastGone  : Word;
     Buf       : Array[1..8192] Of Char;
BEGIN
     FillChar(Ln,SizeOf(Ln),0);
     ASSIGN(Fbbs,WorkDir+'\FILESBBS.NEW');
     ASSIGN(Wk,FileName);
     SetTextBuf(Wk,Buf);
     REWRITE(Fbbs);
     RESET(Wk);
     REPEAT
           Wrote := 0;
           Temp  := '';
           Count := 0;
           REPEAT
                 IF NOT(EoLn(Wk)) THEN
                 BEGIN
                      READ(Wk,C);
                      INC(Count);
                      Ln[Count] := C;
                 END;
           UNTIL EoLn(Wk);
           READLN(Wk,Temp);
           IF ((Ln[1]<>' ') AND (Count>5)) THEN
           BEGIN
                {GET THE FILENAME}
                TheFile := '';
                FOR Pooper := 1 TO 12 DO
                BEGIN
                     IF Ln[Pooper]<>' ' THEN TheFile := TheFile+Ln[Pooper];
                END;

                IF _FileExists(FileArea.Area_Path+TheFile) THEN
                BEGIN
                     WRITE(Fbbs,_PadRight(TheFile,15));

                     {SEEK THE START OF THE DESCRIPTION}
                     runner := 0;
                     FOR Pooper := LENGTH(TheFile)+1 TO Count DO
                     BEGIN
                          IF Runner=0 THEN
                          BEGIN
                               IF Ln[Pooper]<>' ' THEN Runner := Pooper;
                          END;
                     END;

                     Written   := False;
                     Pooper    := Runner;
                     LastGone  := 0;
                     LastSpace := Runner;
                     REPEAT
                           IF (Pooper-Runner+1)>46 THEN
                           BEGIN
                                Temp := '';
                                FOR Pooper2 := Runner TO LastSpace DO Temp := Temp+Ln[Pooper2];
                                IF Written THEN WRITE(FBBS,_PadRight('',15));
                                WRITELN(FBBS,Temp);
                                LastGone := LastSpace;
                                Runner   := LastSpace+1;
                                Pooper   := Runner-1;
                                Written  := True;
                           END
                           ELSE
                           BEGIN
                                IF ((Ln[Pooper]=' ') OR (Ln[Pooper]='-') OR (Ln[Pooper]='/') OR (Ln[Pooper]='\'))
                                   THEN LastSpace := Pooper;
                           END;
                           INC(Pooper);
                           IF Pooper=Count THEN
                           BEGIN
                                IF LastGone<>Count THEN
                                BEGIN
                                     Temp := '';
                                     FOR Pooper2 := Runner TO Count DO Temp := Temp+Ln[Pooper2];
                                     IF Written THEN WRITE(FBBS,_PadRight('',15));
                                     WRITELN(FBBS,Temp);
                                     LastGone := Count;
                                     Written  := True;
                                END;
                           END;
                     UNTIL LastGone=Count;
                END;
           END;
     UNTIL EOF(Wk);
     CLOSE(Wk);
     CLOSE(Fbbs);
     IF IOResult=0 THEN;
END;


FUNCTION ValidFile(InString: String): Boolean;
VAR  DirInfo : SearchRec;
     Loop    : Word;
BEGIN
     InString := _Mid(InString,1,12);
     InString := _RemoveSpaces(InString);
     IF InString='' THEN
     BEGIN
          ValidFile := False;
          Exit;
     END;
     FOR Loop := 1 TO Length(InString) DO
     BEGIN
          IF ((Ord(InString[Loop])>127) OR (Ord(InString[Loop])<33)) THEN
          BEGIN
               ValidFile := False;
               Exit;
          END;
     END;
     IF IOResult=0 THEN;
     FindFirst(FileArea.Area_Path+InString,AnyFile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN ValidFile := True
                   ELSE ValidFile := False;
     IF IOResult=0 THEN;
END;


PROCEDURE _FileSizeDate(FName: String; VAR Size,Date: Longint);
VAR  DirInfo : SearchRec;
BEGIN
     IF IOResult=0 THEN;
     FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN
     BEGIN
          Size := DirInfo.Size;
          Date := DirInfo.Time;
     END
     ELSE
     BEGIN
          Size := 0;
          Date := 0;
     END;
     IF IOResult=0 THEN;
END;


BEGIN
     IF NOT(_FileExists(FileArea.Area_Path+'FILES.BBS')) THEN Exit;
     _SaveWindow(WorkDir+'\IMPORTCD.VID');
     AreaCount := 0;

     DrawWindow(10,5,60,18,'IMPORT FILES.BBS',True);
     Window(12,7,59,17);
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);

     {TEST IF ITS A LONG OR MULTI LINE}
     ListType := 'MULTILINE';
     ASSIGN(FilesBBS,FileArea.Area_Path+'FILES.BBS');
     RESET(FilesBBS);
     REPEAT
           READLN(FilesBBS,Horse);
           IF LENGTH(Horse)>80 THEN ListType := 'LONGLINE';
     UNTIL ((EOF(FilesBBS)) OR (ListType='LONGLINE'));
     CLOSE(FilesBBS);

     TotalFiles   := 0;
     TotalLines   := 0;
     ByteCounter  := 0;
     TotalLines   := 0;
     TotalFiles   := 0;
     FDescCounter := 1;

     IF _UpperCase(ListType)='LONGLINE' THEN
        LongToMulti(FileArea.Area_Path+'FILES.BBS');

     ASSIGN(FFileDefs,BaseDirectory+'\TEMP.FIL');
     ASSIGN(FFileDesc,BaseDirectory+'\TEMP.TXT');
     ASSIGN(FNewFilesBBS,WorkDir+'\FILES.NEW');
     IF _UpperCase(ListType)='LONGLINE'
        THEN ASSIGN(FilesBBS,WorkDir+'\FILESBBS.NEW')
        ELSE ASSIGN(FilesBBS,FileArea.Area_Path+'FILES.BBS');
     REWRITE(FFileDefs);
     REWRITE(FFileDesc);
     REWRITE(FNewFilesBBS);
     RESET(FilesBBS);
     GotFirstFile := False;
     REPEAT
           IF NOT(EOF(FilesBBS)) THEN
           BEGIN
                READLN(FilesBBS,ScrapLine);
                ScrapLine := CheckTab(ScrapLine);
                IF NOT(GotFirstFile) THEN
                BEGIN
                     IF (Length(ScrapLine)>2) THEN
                     BEGIN
                          IF ValidFile(ScrapLine) THEN
                          BEGIN
                               GotFirstFile := True;
                               NewFilesBBS.Line := ScrapLine;
                               WRITE(FNewFilesBBS,NewFilesBBS);
                               INC(TotalLines);
                               IF LENGTH(ScrapLine)<>0 THEN
                               BEGIN
                                    IF ScrapLine[1]<>Chr(32) THEN
                                    BEGIN
                                         INC(TotalFiles);
                                         FileLoc[TotalFiles] := TotalLines;
                                    END;
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     NewFilesBBS.Line := ScrapLine;
                     WRITE(FNewFilesBBS,NewFilesBBS);
                     INC(TotalLines);
                     IF LENGTH(ScrapLine)<>0 THEN
                     BEGIN
                          IF ScrapLine[1]<>Chr(32) THEN
                          BEGIN
                               INC(TotalFiles);
                               FileLoc[TotalFiles] := TotalLines;
                          END;
                     END;
                END;
           END;
     UNTIL EOF(FilesBBS);
     CLOSE(FilesBBS);
     CLOSE(FNewFilesBBS);

     FOR Loop := 1 TO TotalFiles DO
     BEGIN
          FOR Terd := 1 TO 18 DO
          BEGIN
               FillChar(FileDesc[Terd].Desc,SizeOf(FileDesc[Terd].Desc),CHR(0));
               FileDesc[Terd].Desc[0] := #00;
               FileDesc[Terd].Desc := '';
          END;
          IF Loop=TotalFiles THEN
          BEGIN
               Terd := 0;
               Window(12,6,59,17);
               WRITELN(_PadRight('AREA: '+FileArea.Area_Name,48));
               Window(12,7,59,17);
               ClrScr;
               ASSIGN(FNewFilesBBS,WorkDir+'\FILES.NEW');
               RESET(FNewFilesBBS);
               SEEK(FNewFilesBBS,FileLoc[Loop]-1);
               FOR Loop2 := 1 TO 40 DO
               BEGIN
                    IF NOT(EOF(FNewFilesBBS)) THEN
                    BEGIN
                         READ(FNewFilesBBS,NewFilesBBS);
                         IF Loop2=1 THEN
                         BEGIN
                              RemoveFileName;
                              WRITELN(FileName);
                         END
                         ELSE NewFilesBBS.Line := RemoveLeftSpaces(NewFilesBBS.Line);
                         WRITELN(NewFilesBBS.Line);
                         INC(Terd);
                         IF Terd<19 THEN FileDesc[Terd].Desc := _Mid(NewFilesBBS.Line,1,46);
                    END;
               END;
               CLOSE(FNewFilesBBS);
          END
          ELSE
          BEGIN
               Terd := 0;
               Window(12,6,59,17);
               WRITELN(_PadRight('AREA: '+FileArea.Area_Name,48));
               Window(12,7,59,17);
               ClrScr;
               ASSIGN(FNewFilesBBS,WorkDir+'\FILES.NEW');
               RESET(FNewFilesBBS);
               SEEK(FNewFilesBBS,FileLoc[Loop]-1);
               FOR Loop2 := FileLoc[Loop] TO (FileLoc[Loop+1]-1) DO
               BEGIN
                    READ(FNewFilesBBS,NewFilesBBS);
                    IF Loop2=FileLoc[Loop] THEN
                    BEGIN
                         RemoveFileName;
                         WRITELN(FileName);
                    END
                    ELSE NewFilesBBS.Line :=  RemoveLeftSpaces(NewFilesBBS.Line);
                    WRITELN(NewFilesBBS.Line);
                    INC(Terd);
                    IF Terd<19 THEN FileDesc[Terd].Desc := _Mid(NewFilesBBS.Line,1,46);
               END;
               CLOSE(FNewFilesBBS);
          END;

          FileDefs.File_Name   := FileName;
          _FileSizeDate(FileArea.Area_Path+FileName,FileDefs.File_Size,FileDefs.file_date);
          FileDefs.class       := 0;
          FileDefs.free        := 0;
          FileDefs.dled        := 0;
          FileDefs.uploader    := System_Info.Sysop;
          FileDefs.added_date  := proper_date;
          DescLoop  := 18;
          DescCount := 0;
          REPEAT
                IF FileDesc[DescLoop].Desc<>'' THEN DescCount := DescLoop;
                DEC(DescLoop);
          UNTIL ((DescLoop=0) OR (DescCount<>0));
          FOR DescLoop := 1 TO DescCount DO
          BEGIN
               WRITE(FFileDesc,FileDesc[DescLoop]);
          END;
          FileDefs.Desc_Lines  := DescCount;
          FileDefs.First_Desc  := FDescCounter;
          FDescCounter := FDescCounter+DescCount;
          WRITE(FFileDefs,FileDefs);
          ByteCounter := ByteCounter+FileDefs.File_Size;
     END;
     CLOSE(FFileDefs);
     CLOSE(FFileDesc);
     Window(1,1,80,25);
     LoadWindow(WorkDir+'\IMPORTCD.VID');
     IF _UpperCase(ListType)='LONGLINE' THEN
     BEGIN
          ASSIGN(FilesBBS,WorkDir+'\FILESBBS.NEW');
          ERASE(FilesBBS);
     END;
     ASSIGN(FNewFilesBBS,WorkDir+'\FILES.NEW');
     ERASE(FNewFilesBBS);

     ASSIGN(FFileDefs2,BaseDirectory+'\TEMP.FIL');
     ASSIGN(FFileDesc2,BaseDirectory+'\TEMP.TXT');
     RESET(FFileDefs2);
     RESET(FFileDesc2);
     REPEAT
           READ(FFileDefs2,FileDefs);
           SEEK(FFileDesc2,FileDefs.First_Desc-1);
           FOR Loop := 1 TO FileDefs.Desc_Lines DO
               READ(FFileDesc2,FileDesc[Loop]);
           {CHECK TO SEE IF WE ALREADY HAVE IT}
           IsItThere    := False;
           IF _FileExists(FileArea.DOS_Name+'.FIL') THEN
           BEGIN
                ASSIGN(FFileDefs,FileArea.DOS_Name+'.FIL');
                RESET(FFileDefs);
                REPEAT
                      READ(FFileDefs,FileDefs2);
                      IF _UpperCase(_RemoveSpaces(FileDefs2.File_Name))=
                         _UpperCase(_RemoveSpaces(FileDefs.File_Name))
                         THEN IsItThere := True;
                UNTIL ((EOF(FFileDefs)) OR (IsItThere));
                CLOSE(FFileDefs);
           END;
           IF NOT(IsItThere) THEN
           BEGIN
                IF _FileExists(FileArea.DOS_Name+'.TXT') THEN
                BEGIN
                     ASSIGN(FFileDesc,FileArea.DOS_Name+'.TXT');
                     RESET(FFileDesc);
                     FileDefs.First_Desc := FileSize(FFileDesc)+1;
                     CLOSE(FFileDesc);
                END
                ELSE FileDefs.First_Desc := 1;
                IF _FileExists(FileArea.DOS_Name+'.FIL') THEN
                BEGIN
                     ASSIGN(FFileDefs,FileArea.DOS_Name+'.FIL');
                     RESET(FFileDefs);
                     SEEK(FFileDefs,FileSize(FFileDefs));
                     WRITE(FFileDefs,FileDefs);
                     CLOSE(FFileDefs);
                     ASSIGN(FFileDesc,FileArea.DOS_Name+'.TXT');
                     RESET(FFileDesc);
                     SEEK(FFileDesc,FileSize(FFileDesc));
                     FOR Loop2 := 1 TO FileDefs.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc[Loop2]);
                     CLOSE(FFileDesc);
                END
                ELSE
                BEGIN
                     ASSIGN(FFileDefs,FileArea.DOS_Name+'.FIL');
                     REWRITE(FFileDefs);
                     WRITE(FFileDefs,FileDefs);
                     CLOSE(FFileDefs);
                     ASSIGN(FFileDesc,FileArea.DOS_Name+'.TXT');
                     REWRITE(FFileDesc);
                     FOR Loop2 := 1 TO FileDefs.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc[Loop2]);
                     CLOSE(FFileDesc);
                END;
           END;
     UNTIL EOF(FFileDefs2);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     ERASE(FFileDefs2);
     ERASE(FFileDesc2);
END;


END.
