{$IFDEF DPMI}
Hello there???
{$ENDIF}

{$I DEFINES.INC}

{$M 32768,0,655360}
PROGRAM GSEcho;


USES StartUp,BsFile,Globals,BsLog,BsMulti,BsVideo,Scanning,
     BsString,Crt,KeyCheck,AreaFix,Tossing,Packing;


VAR  WeGiveUp  : Boolean;
     TryCount  : Word;
     FunkyFile : File;


BEGIN
     ProgramStartup;
     WeGiveUp := False;
     TryCount := 31;
     REPEAT
       IF NOT(_FileExists(BaseDirectory+'\GSECHO.$$$')) THEN
       BEGIN
         ASSIGN(FunkyFile,BaseDirectory+'\GSECHO.$$$');
         REWRITE(FunkyFile,1);
         CLOSE(FunkyFile);
         CreateTemporaryDirs;
         CheckRegistered(TempUnpack,'GSEcho');
         IF Toss THEN bsSetLog(OurAppName,'[TOSS]',NodeNumber)
                 ELSE bsSetLog(OurAppName,'[SCAN]',NodeNumber);
         WriteNodeFile;
         IF Toss THEN
         BEGIN
           IF ThereIsSomethingToDo THEN
           BEGIN
             StartNodesOff;
             IF ThereIsAnAreaFix THEN ProcessAreaFix;
             TossInbound;
             KillZeroNodes;
             PackOutbound;
             ProcessAddedAreas;
             ShowLastTossStats;
             ForceMailerRescan;
             bsWriteLog('End Run.',False);
           END
           ELSE
           BEGIN
             ClrScr;
             WRITELN('All done!');
             Window(1,1,80,25);
             GOTOXY(1,8);
           END;
         END
         ELSE
         BEGIN
           StartNodesOff;
           DoScan;
           KillZeroNodes;
           PackOutbound;
           ClrScr;
           WRITELN('All done!');
           Window(1,1,80,25);
           GOTOXY(1,8);
           ForceMailerRescan;
           bsWriteLog('End Run.',False);
         END;
         KillTemporaryDirs;
         ERASE(FunkyFile);
         WeGiveUp := True;
       END
       ELSE
       BEGIN
         DEC(TryCount);
         _Delay(1000);
         FastWrite('GSEcho busy. Timeout: '+_String(TryCount)+' ',7,1,14);
         IF TryCount=0 THEN
         BEGIN
           FastWrite('                         ',7,1,7);
           Window(1,1,80,25);
           TextColor(7);
           GotoXY(1,6);
           WeGiveUp := True;
         END
         ELSE WeGiveUp := False;
       END;
     UNTIL WeGiveUp;
     ProgramShutDown;
END.
