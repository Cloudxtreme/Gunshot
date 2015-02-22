{$I DEFINES.INC}
UNIT FileBoxs;


INTERFACE


PROCEDURE FileBox(ScrFile: String);


IMPLEMENTATION


USES Dos,Globals,BsLog,MiscStr,SBuffer,Screens,KeyInput,
     ANSIMisc,Download,Commands,BsFile,BsString;


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
     Code     : Integer;
     P1,P2    : Char;
BEGIN
     bsWriteLog('Accessing user FileBox',False);
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
                     UserName := _RemoveLeftSpaces(UserName);
                     UserName := _RemoveRightSpaces(UserName);
                     IF UserName=_UpperCase(UserRecord.Name)
                        THEN FoundIt := True;
                END;
           END;
     UNTIL ((EOF(FFile)) OR (FoundIt));
     CLOSE(FFile);
     IF NOT(FoundIt) THEN
     BEGIN
          SendCrLf(2);
          system_prompt('',181,True,false);
          Get_Enter;
          Exit;
     END;
     IF BoxPath[LENGTH(BoxPath)]='\' THEN Delete(BoxPath,LENGTH(BoxPath),1);
     _CreatePath(BoxPath);
     AllDone := False;
     REPEAT
           ClearBuffer;
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
                          Temp := _String(Count);
                          IF Length(Temp)=1 THEN Temp := '0'+Temp;
                          AddToBuffer('@N'+Temp,_String(Count));
                          AddToBuffer('@DESCRIPTION'+Temp,FDesc);
                          AddToBuffer('@FILENAME'+Temp,_NoPath(FName));
                          AddToBuffer('@SIZE'+Temp,_String(_FileSize(FName)));
                          AddToBuffer('@SENDER'+Temp,FSender);
                     END;
                END;
                FindNext(DirInfo);
           END;
           IF Count<>10 THEN
           BEGIN
                FOR Loop := Count+1 TO 10 DO
                BEGIN
                     Temp := _String(Loop);
                     IF Length(Temp)=1 THEN Temp := '0'+Temp;
                     AddToBuffer('@N'+Temp,DontSend);
                     AddToBuffer('@DESCRIPTION'+Temp,DontSend);
                     AddToBuffer('@FILENAME'+Temp,DontSend);
                     AddToBuffer('@SIZE'+Temp,DontSend);
                     AddToBuffer('@SENDER'+Temp,DontSend);
                END;
           END;
           DisplayGraphicsFile('FILEBOX',True,True,False,True,False);
           DoCommandString('FILEBOX',1);
           DoCommandString('FILEBOX',2);
           system_prompt('',1,false,true);
           P1  := GetCommandKeyPress('FILEBOX',1);
           P2  := GetCommandKeyPress('FILEBOX',2);
           C := Get_Menu_Selection(P1+P2,Chr(0));
           IF C=P1 THEN
           BEGIN
                Fore(15);
                SendCrLf(2);
                system_prompt('',182,False,true);
                Get_Number(2,'',False);
                IF input_string<>'' THEN
                BEGIN
                     VAL(input_string,kill,code);
                     IF ((kill>0) AND (kill<=Count)) THEN
                     BEGIN
                          bsWriteLog('Downloading from user FileBox',False);
                          dl_file(DlFile[Kill]);
                     END;
                END;
           END
           ELSE IF C=P2 THEN AllDone := True;
     UNTIL AllDone;
END;


END.
