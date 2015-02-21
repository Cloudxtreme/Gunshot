{$I DEFINES.INC}
PROGRAM SGPack;


USES Fido,Squish,Jam,Globals,Startup,Crt,ApTimer,MkFFile,BsLog,
     MkGlobt,BsFile,BsString,BsMulti,FMode,BsVideo,KeyCheck;


VAR  BytesRead : Word;
     C         : Char;


PROCEDURE DoStatus;
VAR  Temp : String;
     Work : Word;
BEGIN
     FastWrite(_String(PCurrentArea)+'/'+_String(PNumAreas),7,13,7);
     IF PNumAreas<>0 THEN
     BEGIN
       Work := Trunc((PCurrentArea/PNumAreas)*40);
       IF Work>40 THEN Work := 40;
       IF (Work>0) THEN
       BEGIN
         Move(Progress[1],Temp[1],Work);
         Temp[0] := Chr(Work);
         FastWrite(Temp,7,35,9);
       END;
     END;
END;


BEGIN
     FileMode := SetFileMode;
     FireUp;
     New(SLastRead);
     WeGiveUp := False;
     TryCount := 31;
     REPEAT
       IF NOT(_FileExists(BaseDirectory+'\SGPACK.$$$')) THEN
       BEGIN
         ASSIGN(FunkyFile,BaseDirectory+'\SGPACK.$$$');
         REWRITE(FunkyFile,1);
         CLOSE(FunkyFile);
         Window(1,9,80,25);
         NewTimerSecs(TheTimer,1440*60);
         IF _FileExists(BaseDirectory+'\DATA\MA000000.DAT') THEN
         BEGIN
           ASSIGN(FMessageAreas2,BaseDirectory+'\DATA\MA000000.DAT');
           RESET(FMessageAreas2);
           PNumAreas := FileSize(FMessageAreas2);
           CLOSE(FMessageAreas2);
           DoStatus;
           FMessageAreas.Init(32768);
           FMessageAreas.OpenFile(BaseDirectory+'\DATA\MA000000.DAT',SetFileMode);
           REPEAT
             FMessageAreas.BlkRead(MessageAreas,SizeOf(MessageAreas),BytesRead);
             IF (BytesRead<>0) THEN
             BEGIN
               CASE MessageAreas.Base_Type OF
               1:   PackJam;
               2:   PackSquish;
               3:   PackFido;
               END;
             END;
             IF KeyPressed THEN
             BEGIN
               C := ReadKey;
               CASE C OF
               #0:  C := ReadKey;
               #27: BytesRead := 0;
               END;
             END;
             INC(PCurrentArea);
             DoStatus;
           UNTIL BytesRead=0;
           FMessageAreas.CloseFile;
           FMessageAreas.Done;
         END;
         ERASE(FunkyFile);
         WeGiveUp := True;
         Window(1,7,80,25);
         TextColor(7);
         ClrScr;
         TextColor(14);
         WRITELN('   Total Messages Kept: '+_String(TotalMsgs));
         WRITELN(' Total Elapsed Seconds: '+_String(ElapsedTimeInSecs(TheTimer)));
         WRITELN('   Bytes Prior To Pack: '+_String(OrigBytes));
         WRITELN('      Bytes After Pack: '+_String(DoneBytes));
         {Log It}
         bsWriteLog('Total Messages Kept....: '+_String(TotalMsgs),False);
         bsWriteLog('Total Elapsed Seconds..: '+_String(ElapsedTimeInSecs(TheTimer)),False);
         bsWriteLog('Bytes Prior To Pack....: '+_String(OrigBytes),False);
         bsWriteLog('Bytes After Pack.......: '+_String(DoneBytes),False);
         bsWriteLog('End Run.',False);
         TextColor(7);
         Window(1,1,80,25);
         GotoXY(1,11);
       END
       ELSE
       BEGIN
         DEC(TryCount);
         _Delay(1000);
         FastWrite('SGPack busy. Timeout: '+_String(TryCount)+' ',7,1,14);
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
     Dispose(SLastRead);
END.
