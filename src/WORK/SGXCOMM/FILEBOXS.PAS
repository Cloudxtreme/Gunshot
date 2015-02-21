{$I DEFINES.INC}
UNIT FileBoxs;


INTERFACE


PROCEDURE FileBox(ScrFile: String);


IMPLEMENTATION


USES Dos,Globals,BsLog,BsFile,BsString,MiscStr,SBuffer,
     Screens,KeyInput,Gfx,Download,Commands;


PROCEDURE FileBox(ScrFile: String);
VAR  FFile    : Text;
     Temp     : String;
     UserName : String;
     BoxPath  : String;
     FoundIt  : Boolean;
     Work     : Word;
     DirInfo  : SearchRec;
     Count    : Word;
     Loop     : Word;
     FName    : String;
     FDesc    : String;
     FSender  : String;
     DlFile   : Array[1..10] Of String;
     AllDone  : Boolean;
     Kill     : Longint;
     C        : Char;
     P1,P2    : Char;
BEGIN
     bsWriteLog('Accessing user FileBox',True);
     IF NOT(_FileExists(ScrFile)) THEN Exit;
     FoundIt := False;
     ASSIGN(FFile,ScrFile);
     RESET(FFile);
     REPEAT
           READLN(FFile,Temp);
           IF ((Temp<>'') AND (Temp[1]<>';')) THEN
           BEGIN
                Work := Pos('@',Temp);
                IF Work<>0 THEN
                BEGIN
                     UserName := _UpperCase(_Mid(Temp,1,Work-1));
                     BoxPath  := _UpperCase(_Mid(Temp,Work+1,LENGTH(Temp)));
                     StripLeadingSpaces(UserName);
                     StripTrailingSpaces(UserName);
                     IF UserName=_UpperCase(UserRecord.Name)
                        THEN FoundIt := True;
                END;
           END;
     UNTIL ((EOF(FFile)) OR (FoundIt));
     CLOSE(FFile);
     IF NOT(FoundIt) THEN
     BEGIN
          system_prompt('',181);
          Get_Enter;
          Exit;
     END;
     IF BoxPath[LENGTH(BoxPath)]='\' THEN Delete(BoxPath,LENGTH(BoxPath),1);
     _CreatePath(BoxPath);
     AllDone := False;
     REPEAT
           IF DisplayGraphicFile('FILEBOX',False,True,True) THEN
           BEGIN
                NewPickList(True);
                PickInfo.Current := 0;
                Count := 0;
                FindFirst(BoxPath+'\*.DIZ',Anyfile-Directory-VolumeID,DirInfo);
                WHILE DosError = 0 DO
                BEGIN
                     ASSIGN(FFile,BoxPath+'\'+DirInfo.Name);
                     RESET(FFile);
                     READLN(FFile,FName);
                     READLN(FFile,FDesc);
                     READLN(FFile,FSender);
                     CLOSE(FFile);
                     IF (Count<10) THEN
                     BEGIN
                          IF _FileExists(FName) THEN
                          BEGIN
                               INC(Count);
                               DlFile[Count] := FName;
                               Temp := ' '+_PadRight(_NoPath(FName),14)+
                                       _PadRight(_String(_FileSize(FName)),9)+
                                       _PadRight(FDesc,31)+_PadRight(FSender,21);
                               AddToPickList(Temp,Count,True);
                          END;
                     END;
                     FindNext(DirInfo);
                END;
                BeginPickList;
                P1  := GetCommandKeyPress('FILEBOX',1);
                P2  := GetCommandKeyPress('FILEBOX',2);
                c := Get_Menu_Selection(P1+P2+#27,Chr(0));
                IF ((C=P2) OR (C=#27)) THEN
                BEGIN
                     AllDone := True;
                END
                ELSE IF C=P1 THEN
                BEGIN
                     KillPickList;
                     IF (PickInfo.Current<>0) THEN
                     BEGIN
                          bsWriteLog('Downloading from user FileBox',True);
                          dl_file(DlFile[PickInfo.Current],False);
                     END;
                END;
                KillPickList;
           END
           ELSE AllDone := True;
     UNTIL AllDone;
END;


END.
