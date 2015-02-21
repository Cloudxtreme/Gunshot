{$I DEFINES.INC}
UNIT DoFreqs;


INTERFACE


PROCEDURE CheckYourFreqs;


IMPLEMENTATION


USES Globals,Time,KeyInput,Screens,Toggle,GotKeys,DLEst,Shotgun,
     BsFile,BsString,BsTime;


FUNCTION BytesInQueue: Longint;
VAR  Loop : Word;
     Work : Longint;
BEGIN
     Work := 0;
     IF Tagged>0 THEN
     BEGIN
          FOR loop := 1 TO tagged DO work := work+TaggedFiles^[Loop].Size;
     END;
     BytesInQueue := Work;
END;


FUNCTION RatioClear(AddedBytes: Longint): Boolean;
VAR  UsersCalc  : Real;
     SystemCalc : Real;
BEGIN
     IF ((UserAccess.NoFileRatio=1) OR (UserAccess.byte_ratio=0)) THEN
     BEGIN
          RatioClear := True;
          Exit;
     END;
     UsersCalc  := (UserRecord.uploads/(UserRecord.dl_total+AddedBytes));
     SystemCalc := (1/UserAccess.byte_ratio);
     IF (UsersCalc>=SystemCalc) THEN RatioClear := True
                                ELSE RatioClear := False;
     IF (UserRecord.dl_total+AddedBytes<UserAccess.Ratio_Start) THEN RatioClear := True;
END;


PROCEDURE CheckYourFreqs;
VAR  FRequestFile2 : File Of _RequestFile;
     Now           : Longint;
     FoundSome     : Boolean;
     FoundIt       : Boolean;
     ThePath       : String;
     TheFile       : String;
     Loop3         : Word;
LABEL                AddTheFile,SkipTheMark;
BEGIN
     IF _FileExists(Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS') THEN
     BEGIN
       {First, Lets Weed Out The Old Ones}
       Now := _ProperDateNoTime;
       ASSIGN(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
       RENAME(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.OLD');
       ASSIGN(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
       ASSIGN(FRequestFile2,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.OLD');
       REWRITE(FRequestFile);
       RESET(FRequestFile2);
       REPEAT
         READ(FRequestFile2,RequestFile);
         IF DaysBetween(RequestFile.RequestDate,Now)<=Freqs.DaysToKeepRequests
           THEN WRITE(FRequestFile,RequestFile);
       UNTIL EOF(FRequestFile);
       CLOSE(FRequestFile2);
       ERASE(FRequestFile2);
       CLOSE(FRequestFile);
       IF _FileSize(Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS')=0 THEN
       BEGIN
         _EraseFile(Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
         Exit;
       END;
       DisplayGraphicFile('FREQCHK',False,True,True);
       IF Get_Yes_No THEN
       BEGIN
         FoundSome := False;
         DisplayGraphicFile('FREQLOOK',False,True,True);
         {Do The Search}
         ASSIGN(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
         RENAME(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.OLD');
         ASSIGN(FRequestFile2,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.OLD');
         ASSIGN(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
         REWRITE(FRequestFile);
         RESET(FRequestFile2);
         StartToggle(FileSize(FRequestFile2));
         REPEAT
           DoToggle;
           READ(FRequestFile2,RequestFile);
           ThePath := _GetFilePath(RequestFile.FileName);
           TheFile := _NoPath(RequestFile.FileName);
           FoundIt := False;
           ASSIGN(FFileArea,DATA_Directory+'\FA000000.DAT');
           {$I-}RESET(FFileArea);{$I+}
           IF IOResult=0 THEN
           BEGIN
             WHILE NOT(EOF(FFileArea)) DO
             BEGIN
               READ(FFileArea,FileAreas);
               IF ((UserRecord.Security>=FileAreas.View_Access) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
               BEGIN
                 IF (FileAreas.Area_Path=ThePath) THEN
                 BEGIN
                   ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                   {$I-}RESET(FFileDefs);{$I+}
                   IF IOResult = 0 THEN
                   BEGIN
                     REPEAT
                       READ(FFileDefs,FileDefs^);
                       IF (FileDefs^.File_Name=TheFile) THEN
                       BEGIN
                         IF _FileExists(ThePath+TheFile) THEN
                         BEGIN
                           IF (tagged<15) THEN
                           BEGIN
                             {Add It If Its A Free File}
                             IF (FileDefs^.Free=1) THEN GOTO AddTheFile;
                             {Check if the user has enough time left}
                             Time_For_Downloads := 0;
                             IF (tagged<>0) THEN
                             BEGIN
                               FOR loop3 := 1 TO tagged DO
                                 time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles^[loop3].Size);
                               time_for_downloads := time_for_downloads+DL_ESTIMATE2(FileDefs^.File_Size);
                             END
                             ELSE time_for_downloads  := DL_ESTIMATE2(FileDefs^.File_Size);
                             IF (time_for_downloads>AbsTimeLeft) THEN GOTO SkipTheMark;
                             {Check if the user has enough bytes left}
                             IF (BytesInQueue+FileDefs^.File_Size>UserRecord.DLBytesRemaining) THEN GOTO SkipTheMark;
                             {Check the user's ratio}
                             IF (NOT(RatioClear(BytesInQueue+FileDefs^.File_Size))) THEN GOTO SkipTheMark;

                             {Lets add it to the queue}
                             AddTheFile:
                             INC(tagged);
                             TaggedFiles^[tagged].FileName := FileDefs^.File_Name;
                             TaggedFiles^[tagged].FilePath := FileAreas.Area_Path;
                             TaggedFiles^[tagged].Size     := FileDefs^.File_Size;
                             CASE FileDefs^.Free OF
                             0:   TaggedFiles^[tagged].FreeFile := False;
                             1:   TaggedFiles^[tagged].FreeFile := True;
                             END;
                             TaggedFiles^[tagged].FileArea := FilePos(FFileArea);
                             TaggedFiles^[tagged].FileSub  := 0;
                             TaggedFiles^[tagged].Description := 'Offline request';
                             IF (fileareas.cd_rom<>0) THEN TaggedFiles^[Tagged].CDRom := true
                                                      ELSE TaggedFiles^[Tagged].CDRom := false;
                             FoundIt   := True;
                             FoundSome := True;
                             SkipTheMark:
                           END;
                         END;
                       END;
                     UNTIL EOF(FFileDefs);
                     CLOSE(FFileDefs);
                   END;
                 END;
               END;
             END;
             CLOSE(FFileArea);
           END;
           IF NOT(FoundIt) THEN WRITE(FRequestFile,RequestFile);
         UNTIL EOF(FRequestFile2);
         CLOSE(FRequestFile2);
         ERASE(FRequestFile2);
         CLOSE(FRequestFile);
         IF _FileSize(Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS')=0 THEN
            _EraseFile(Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
         EndToggle;
         {Show The Results}
         IF FoundSome THEN DisplayGraphicFile('FREQYES',False,True,True)
                      ELSE DisplayGraphicFile('FREQNO',False,True,True);
         Get_Enter;
       END;
     END;
END;


END.
