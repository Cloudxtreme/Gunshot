{$I DEFINES.INC}
UNIT Events;


INTERFACE


FUNCTION  MinToNext         : String;
PROCEDURE StallThisNode     (IsExternal: Boolean);
PROCEDURE CheckEvents;


IMPLEMENTATION


USES DrawScrn,Globals,BsLog,Sema,Crt,SaveScrn,Comm,FastW1,
     BsMulti,Time,Dos,Transfer,ApTimer,Queue,Saver,BsKeys,
     BsFile,BsString,BsTime,BsCom,BsVideo;


PROCEDURE StallThisNode(IsExternal: Boolean);
VAR  AllDone : Boolean;
     OldXY   : Word;
     TimeNow : Longint;
     C       : Char;
     TopLine : Word;
BEGIN
     TopLine := Window1-3;
     WriteNodeFile('GSMail','Node Temporarily Offline','');
     WhereXYAbs(OldXY);
     _HideCursor;
     SaveScreen(1);
     bsOffHook(NodeInfo.OffHook);
     IF IsExternal THEN DrawWindow(20,TopLine,67,TopLine+4,'BUSY EVENT - EXTERNAL PROCESS',True)
                   ELSE DrawWindow(20,TopLine,67,TopLine+4,'BUSY EVENT',True);
     InvertedBox(22,TopLine+1,65,TopLine+3);
     FastWrite('Press ESC to force an end to this event.',TopLine+2,24,ShotgunColours.GSMailWindowText);
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                CASE C OF
                #0:  C := ReadKey;
                #27: AllDone := True;
                END;
           END
           ELSE TimeSlice;
           IF IsExternal THEN
           BEGIN
                IF NOT(_FileExists(MailerInfo.Semaphores+'NOCALLS.'+_String(SimNode)))
                   THEN AllDone := True
                   ELSE TimeSlice;
           END
           ELSE
           BEGIN
                TimeNow := Getting_Time_No_Secs;
                IF ((TimeNow<DropEvent.StartTime) OR (TimeNow>=DropEvent.EndTime))
                   THEN AllDone := True
                   ELSE TimeSlice;
           END;
           FastWrite(_PadRight(_DayOfWeek+' '+_GetPrettyDate,27),Window2+5,23,ShotgunColours.GSMailTimeDateData);
           FastWrite(_PadRight(_GetPrettyTime,8),Window2+5,9,ShotgunColours.GSMailTimeDateData);
           _Delay(1000);
     UNTIL AllDone;
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     TextColor(7);
     TextBackGround(0);
     bsOnHook(NodeInfo.OnHook);
     _EraseFile(MailerInfo.Semaphores+'NOCALLS.'+_String(SimNode));
END;


PROCEDURE UnpackPollEvents;
VAR  Loop    : Word;
     TimeNow : Longint;
BEGIN
     IF (NumberOfQueues<>0) THEN
     BEGIN
          FOR Loop := 1 TO NumberOfQueues DO
          BEGIN
               IF MailQueue^[Loop].MsgStat=YetToGo THEN MailQueue^[Loop].MsgStat := Hold;
               IF MailQueue^[Loop].IsEvent THEN
               BEGIN
                    IF ((MailQueue^[Loop].MailType=1) AND (MailQueue^[Loop].MsgStat<>Sent)) THEN
                    BEGIN
                         IF _FileExists(Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode)) THEN
                         BEGIN
                              ASSIGN(FPollEvent,Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode));
                              RESET(FPollEvent);
                              SEEK(FPollEvent,MailQueue^[Loop].EventNum-1);
                              READ(FPollEvent,PollEvent);
                              CLOSE(FPollEvent);
                              TimeNow := Getting_Time_No_Secs;
                              IF ((TimeNow<PollEvent.StartTime) OR (TimeNow>=PollEvent.EndTime)) THEN
                              BEGIN
                                   MailQueue^[Loop].MsgStat := Sent;
                              END;
                         END;
                    END;
               END;
          END;
     END;
END;


PROCEDURE CheckEvents;
VAR  yy,mm,dd,dow    : Word;
     hr,min,sec,hund : Word;
     WorkTime        : Longint;
     WorkTime2       : Longint;
     Counter         : Longint;
     Loop            : Word;
     TimeNow         : Longint;
BEGIN
     NeedQueueRedraw := False;
     {Get Rid Of Old Events}
     UnpackPollEvents;
     {Check ErrorLevel Exits}
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSE.'+_String(SimNode)) THEN
     BEGIN
          Counter := 0;
          ASSIGN(FExitEvent,Shotgun_Directory+'\DATA\EVENTSE.'+_String(SimNode));
          RESET(FExitEvent);
          REPEAT
                INC(Counter);
                READ(FExitEvent,ExitEvent);
                IF ExitEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF ExitEvent.Days[dow+1] THEN
                     BEGIN
                          IF ((yy<>ExitEvent.LastYear) OR (mm<>ExitEvent.LastMonth) OR (dd<>ExitEvent.LastDay)) THEN
                          BEGIN
                               IF Getting_Time_No_Secs>=ExitEvent.Time THEN
                               BEGIN
                                    ExitEvent.LastYear  := yy;
                                    ExitEvent.LastMonth := mm;
                                    ExitEvent.LastDay   := dd;
                                    DoExitEvent := True;
                                    SEEK(FExitEvent,Counter-1);
                                    WRITE(FExitEvent,ExitEvent);
                                    CLOSE(FExitEvent);
                                    Exit;
                               END;
                          END;
                     END;
                END;
          UNTIL EOF(FExitEvent);
          CLOSE(FExitEvent);
     END;
     {Check Drop Calls Event}
     IF _FileExists(MailerInfo.Semaphores+'NOCALLS.'+_String(SimNode)) THEN
     BEGIN
          KillSaver;
          StallThisNode(True);
     END;
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSB.'+_String(SimNode)) THEN
     BEGIN
          ASSIGN(FDropEvent,Shotgun_Directory+'\DATA\EVENTSB.'+_String(SimNode));
          RESET(FDropEvent);
          REPEAT
                READ(FDropEvent,DropEvent);
                IF DropEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF DropEvent.Days[dow+1] THEN
                     BEGIN
                          TimeNow := Getting_Time_No_Secs;
                          IF ((TimeNow>=DropEvent.StartTime) AND (TimeNow<DropEvent.EndTime)) THEN
                          BEGIN
                               KillSaver;
                               StallThisNode(False);
                          END;
                     END;
                END;
          UNTIL EOF(FDropEvent);
          CLOSE(FDropEvent);
     END;
     {Check Poll Calls Event}
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode)) THEN
     BEGIN
          Counter := 0;
          ASSIGN(FPollEvent,Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode));
          RESET(FPollEvent);
          REPEAT
                INC(Counter);
                READ(FPollEvent,PollEvent);
                IF PollEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF PollEvent.Days[dow+1] THEN
                     BEGIN
                          IF ((yy<>PollEvent.LastYear) OR (mm<>PollEvent.LastMonth) OR (dd<>PollEvent.LastDay)) THEN
                          BEGIN
                               TimeNow := Getting_Time_No_Secs;
                               IF ((TimeNow>=PollEvent.StartTime) AND (TimeNow<PollEvent.EndTime)) THEN
                               BEGIN
                                    AddToQueue('POLL',PollEvent.CallAddress,'',0,False,0,YetToGo,True,
                                               PollEvent.StartTime,PollEvent.EndTime,Counter,False,False,False);
                               END;
                          END;
                     END;
                END;
          UNTIL EOF(FPollEvent);
          CLOSE(FPollEvent);
     END;
     {Check Send Calls Event}
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSS.'+_String(SimNode)) THEN
     BEGIN
          Counter := 0;
          ASSIGN(FSendEvent,Shotgun_Directory+'\DATA\EVENTSS.'+_String(SimNode));
          RESET(FSendEvent);
          REPEAT
                INC(Counter);
                READ(FSendEvent,SendEvent);
                IF SendEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF SendEvent.Days[dow+1] THEN
                     BEGIN
                          TimeNow := Getting_Time_No_Secs;
                          IF ((TimeNow>=SendEvent.StartTime) AND (TimeNow<SendEvent.EndTime)) THEN
                          BEGIN
                               AddToQueue('UNHOLD',SendEvent.CallAddress,'',0,False,
                                          0,YetToGo,False,0,0,0,False,False,False);
                          END;
                     END;
                END;
          UNTIL EOF(FSendEvent);
          CLOSE(FSendEvent);
     END;
     {Check Mail Only Events}
     MailerInfo.MailOnly := False;
     IF MailOnly THEN MailerInfo.MailOnly := True;
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode)) THEN
     BEGIN
          ASSIGN(FMailEvent,Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode));
          RESET(FMailEvent);
          REPEAT
                READ(FMailEvent,MailEvent);
                IF MailEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF MailEvent.Days[dow+1] THEN
                     BEGIN
                          TimeNow := Getting_Time_No_Secs;
                          IF ((TimeNow>=MailEvent.StartTime) AND (TimeNow<MailEvent.EndTime))
                             THEN MailerInfo.MailOnly := True;
                     END;
                END;
          UNTIL EOF(FMailEvent);
          CLOSE(FMailEvent);
     END;
     {Check No File Requests Events}
     MailerInfo.AllowFreqs := True;
     IF NOT(FreqsOk) THEN MailerInfo.AllowFreqs := False;
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSF.'+_String(SimNode)) THEN
     BEGIN
          ASSIGN(FFreqEvent,Shotgun_Directory+'\DATA\EVENTSF.'+_String(SimNode));
          RESET(FFreqEvent);
          REPEAT
                READ(FFreqEvent,FreqEvent);
                IF FreqEvent.Active THEN
                BEGIN
                     GetDate(yy,mm,dd,dow);
                     IF FreqEvent.Days[dow+1] THEN
                     BEGIN
                          TimeNow := Getting_Time_No_Secs;
                          IF ((TimeNow>=FreqEvent.StartTime) AND (TimeNow<FreqEvent.EndTime))
                             THEN MailerInfo.AllowFreqs := False;
                     END;
                END;
          UNTIL EOF(FFreqEvent);
          CLOSE(FFreqEvent);
     END;
     IF NeedQueueRedraw THEN RescanQueue;
END;


FUNCTION MinToNext: String; {Max Of 1440 Minutes To Next Mail Only Event}
VAR  YY,MM,DD,DOW   : Word;
     NextOne        : Longint;
     Work           : Longint;
     TimeNow        : Longint;
     SecsToMidnight : Longint;
BEGIN
     NextOne := 1440*60;
     TimeNow := Getting_Time_No_Secs;
     GetDate(yy,mm,dd,dow);
     INC(Dow);
     {======================================================================}
     { DO EVENTS FOR TODAY FIRST                                            }
     {======================================================================}
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode)) THEN
     BEGIN
          ASSIGN(FMailEvent,Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode));
          RESET(FMailEvent);
          REPEAT
                READ(FMailEvent,MailEvent);
                IF MailEvent.Active THEN
                BEGIN
                     IF MailEvent.Days[dow] THEN
                     BEGIN
                          IF (MailEvent.StartTime>=TimeNow) THEN
                          BEGIN
                               IF (MailEvent.StartTime-TimeNow<NextOne)
                                  THEN NextOne := MailEvent.StartTime-TimeNow;
                          END;
                     END;
                END;
          UNTIL EOF(FMailEvent);
          CLOSE(FMailEvent);
     END;
     IF (NextOne<>(1440*60)) THEN
     BEGIN
          NextOne := Round(NextOne/60);
          StatusWindow('Next event in '+_String(NextOne)+' minutes (today)');
          bsWriteLog('Next event in '+_String(NextOne)+' minutes (today)',False);
          MinToNext := _String(NextOne);
          Exit;
     END;
     SecsToMidnight := (1440*60)-TimeNow;
     IF Dow=7 THEN Dow := 1
              ELSE INC(Dow);
     {======================================================================}
     { DO EVENTS FOR TOMORROW                                               }
     {======================================================================}
     IF _FileExists(Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode)) THEN
     BEGIN
          ASSIGN(FMailEvent,Shotgun_Directory+'\DATA\EVENTSM.'+_String(SimNode));
          RESET(FMailEvent);
          REPEAT
                READ(FMailEvent,MailEvent);
                IF MailEvent.Active THEN
                BEGIN
                     IF MailEvent.Days[dow] THEN
                     BEGIN
                          IF (SecsToMidnight+MailEvent.StartTime<NextOne)
                             THEN NextOne := SecsToMidnight+MailEvent.StartTime;
                     END;
                END;
          UNTIL EOF(FMailEvent);
          CLOSE(FMailEvent);
     END;
     IF (NextOne>(1440*60)) THEN NextOne := (1440*60);
     NextOne := Round(NextOne/60);
     StatusWindow('Next event in '+_String(NextOne)+' minutes');
     bsWriteLog('Next event in '+_String(NextOne)+' minutes',False);
     MinToNext := _String(NextOne);
END;


END.
