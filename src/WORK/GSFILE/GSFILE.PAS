{$IFDEF DPMI}
Hello there???
{$ENDIF}
{$I DEFINES.INC}
PROGRAM SgFile;
{$M 32000,0,655360}


USES FMode,StartUp,Process,BsFile,Globals,ApTimer,AreaFix,Status,LogFile,MsgWrite;


VAR  Loop : Word;


BEGIN
     FileMode := SetFileMode;
     GetCommandLineOptions;
     NewTimerSecs(BigTimer,1440*60);
     IF LoadDataFiles THEN
     BEGIN
       IF SomethingToDo THEN
       BEGIN
         SetTheVideoMode;
         DrawOpeningScreen;
         IF WeAreReadyToGo THEN
         BEGIN
           MakeUsBusy;
           WriteNodeFile;
           KillNullTics;
           _CreatePath(BaseDirectory+'\!21');
           _CreatePath(SystemInfo.BadFiles);
           IF ((AreaFixMessages) OR (DoNotify)) THEN
           BEGIN
             DrawAreaFixProcessingScreen;
             ProcessAreaFix;
           END;
           IF LoadTheTics THEN
           BEGIN
             New(MassiveBuffer);
             DrawMainProcessingScreen;
             DrawStartingStatus;
             FOR Loop := 1 TO NumberOfTics DO
             BEGIN
               CurrentTicFile := TicFileName[Loop];
               TossIsGood     := True;
               IF LoadTheTic THEN
               BEGIN
                 IF LoadTheLink(TicFile.AkaFrom,True) THEN
                 BEGIN
                   IF LoadTheArea THEN
                   BEGIN
                     IF PurgeThisArea(TicFile.AreaTag) THEN
                     BEGIN
                       WriteLogFile('  ! SGFile auto-purge for this area: '+TicFile.AreaTag);
                       WriteLogFile('   Ã Erasing file..: '+OriginalArcName);
                       WriteLogFile('   À Erasing TIC...: '+CurrentTicFile);
                       _EraseFile(Mailer.Inbound+OriginalArcName);
                       _EraseFile(Mailer.Inbound+CurrentTicFile);
                     END
                     ELSE
                     BEGIN
                       DrawTicStatus;
                       IF _FileExists(Mailer.Inbound+TicFile.FileName) THEN
                       BEGIN
                         UpdateScreenInfo(Loop-1);
                         CopyToWork;
                         UpdateScreenInfo(Loop-1);
                         IF TossIsGood THEN DearcArchive;
                         UpdateScreenInfo(Loop-1);
                         IF TossIsGood THEN VirusCheck;
                         UpdateScreenInfo(Loop-1);
                         IF TossIsGood THEN ExtFILE_IDDIZ;
                         UpdateScreenInfo(Loop-1);
                         IF TossIsGood THEN RearcArchive;
                         UpdateScreenInfo(Loop-1);
                         IF TossIsGood THEN AddToDatabase;
                         CleanUp;
                         IF TossIsGood THEN
                         BEGIN
                           _EraseFile(Mailer.Inbound+OriginalArcName);
                           _EraseFile(Mailer.Inbound+CurrentTicFile);
                         END;
                       END
                       ELSE WriteLogFile('  ! Attached file for '+CurrentTicFile+' ('+
                                         TicFile.FileName+') not found in inbound!');
                       ClearTicStatus;
                     END;
                   END;
                 END;
               END;
               UpdateScreenInfo(Loop);
             END;
             Dispose(MassiveBuffer);
           END;
           WriteLogFile('Creating reports/announcements.');
           CreateMessages;
           ForceMailerRescan;
           _NukeDir(BaseDirectory+'\!21',False);
           KillOurBusy;
         END;
         FinishLogFile;
       END;
     END;
     DrawShutdownScreen;
END.