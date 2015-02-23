{$IFDEF DPMI}
 Duh, real mode stupid!
{$ENDIF}

{$I DEFINES.INC}
{$M 32000,0,655360}
PROGRAM GSMailFrontEnd;


USES Sema,Globals,ApTimer,NList,Info,Misc,BsMulti,ApCom,ApPort,Crt,
     DrawScrn,Comm,FireUp,Keys,BsLog,Session,Banner,Scan,Transfer,
     Faxes,Events,BusyFile,Saver,ApAbsFax,BsExec,SaveScrn,FastW1,
     BsString,BsFile,BsCom,Dos,UnDial;


PROCEDURE KillDial;
BEGIN
     CallingOut := False;
     NewTimerSecs(DialTimer,MailerInfo.RetryDelay);
     _KillBusy;
END;


FUNCTION CallOut: Boolean;
VAR  FoundOne : Boolean;
     Passes   : Byte;
     C        : Char;
BEGIN
     Passes   := 0;
     FoundOne := False;
     REPEAT
           INC(MailQueuePointer);
           IF MailQueuePointer>NumberOfQueues THEN
           BEGIN
                MailQueuePointer := 1;
                INC(Passes);
           END;
           IF ((MailQueue^[MailQueuePointer].MsgStat=YetToGo) OR (MailQueue^[MailQueuePointer].MsgStat=Crash)) THEN
           BEGIN
                IF (GetNodeInfo(MailQueue^[MailQueuePointer].DestAddr)<>'') THEN
                BEGIN
                     IF CanDialThisOne(MailQueue^[MailQueuePointer].DestAddr)
                        THEN FoundOne := True
                        ELSE MailQueue^[MailQueuePointer].MsgStat := Hold;
                END
                ELSE MailQueue^[MailQueuePointer].MsgStat := Hold;
           END;
           IF (Passes>2) THEN
           BEGIN
                TimeSlice;
                CallOut := False;
                Exit;
           END;
     UNTIL FoundOne;
     WriteNodeFile('GSMail','Outbound Call','');
     KillSaver;
     SystemInformation(False);
     DialPhone(MailQueuePointer);
     bsClearInBuffer;
     NewTimerSecs(FailSafe,120);
     Waiting   := True;
     RingCount := 0;
     CallOut   := True;
END;


PROCEDURE SitAndWait;
VAR  OuttaHere : Boolean;
BEGIN
     OuttaHere := False;
     REPEAT
           CheckSaver;
           IF KeyPressed THEN
           BEGIN
                KillSaver;
                Exit;
           END
           ELSE TimeSlice;
           IF CharReady(bsBBSPort) THEN
           BEGIN
                KillSaver;
                Exit;
           END
           ELSE TimeSlice;
           IF NOT(Waiting) THEN
           BEGIN
                IF TimerExpired(InitTimer) THEN
                BEGIN
                     KillSaver;
                     InitializeModem;
                END
                ELSE TimeSlice;
                SystemInformation(False);
                IF NOT(MailerInfo.BBSOnly) THEN
                BEGIN
                     IF ((NumberOfQueues<>0) AND (Mailer2Info.AllowNodeToDial)) THEN
                     BEGIN
                          IF TimerExpired(DialTimer) THEN
                          BEGIN
                               IF CallOut THEN Exit
                                          ELSE TimeSlice;
                          END
                          ELSE TimeSlice;
                     END
                     ELSE TimeSlice;
                END
                ELSE TimeSlice;
           END
           ELSE
           BEGIN
                IF TimerExpired(FailSafe) THEN
                BEGIN
                     KillSaver;
                     KillDial;
                     bsOnHook(NodeInfo.OnHook);
                     StatusWindow('Initializing Modem');
                     InitializeModem;
                     StatusWindow('Waiting for a call or event');
                     WriteNodeFile('GSMail','Waiting For A Caller','');
                     TimerWait := 20;
                     Waiting   := False;
                     RingCount := 0;
                     NewTimerSecs(InitTimer,TimerWait);
                     ResetDialTimer;
                END
                ELSE TimeSlice;
           END;
           TimeSlice;
     UNTIL ((OuttaHere) OR (DoExitEvent) OR (Finished));
     KillSaver;
END;


BEGIN
     StartUp;
     DialWindowActive := False;
     TimerWait        := 20;
     Waiting          := False;
     RingCount        := 0;
     NewTimerSecs(InitTimer,TimerWait);
     ResetDialTimer;
     WriteNodeFile('GSMail','Waiting For A Caller','');
     SystemInformation(False);
     REPEAT
       SitAndWait;
       IF NOT(DoExitEvent) THEN
       BEGIN
         IF NOT(CharReady(bsBBSPort)) THEN
         BEGIN
           IF HandleLocalKeyPresses=#27 THEN
           BEGIN
             RemoveDialWindow;
             Waiting := False;
             RingCount := 0;
             KillDial;
             bsOnHook(NodeInfo.OnHook);
             StatusWindow('Initializing Modem');
             InitializeModem;
             StatusWindow('Waiting for a call or event');
             WriteNodeFile('GSMail','Waiting For A Caller','');
             TimerWait := 20;
             NewTimerSecs(InitTimer,TimerWait);
             NewTimerSecs(DialTimer,MailerInfo.RetryDelay);
           END;
         END
         ELSE
         BEGIN
           ProcessIncoming;
           IF (ModemResult<>'') THEN
           BEGIN
             ModemResult := _UpperCase(ModemResult);
             CASE ResultType OF
             1:      BEGIN {CONNECT}
                       SetModem(bsBBSPort,True,True);
                       RemoveDialWindow;
                       Waiting := False;
                       RingCount := 0;
                       ModemStatusWindow(ModemResult);
                       IF bsCarrierDetected THEN StatusWindow('Carrier detected');
                       bsWriteLog(ModemResult,False);
                       RemoveARQ(ModemResult);
                       FoundYes := False;
                       ASSIGN(FErrLevel,Gunshot_Directory+'\DATA\ERRLEVEL.'+_String(SimNode));
                       RESET(FErrLevel);
                       REPEAT
                         READ(FErrLevel,ErrLevel);
                         IF (ErrLevel.ConnectMessage<>'') THEN
                         BEGIN
                           IF _UpperCase(ErrLevel.ConnectMessage)=_UpperCase(ModemResult) THEN
                           BEGIN
                             FoundYes := True;
                           END;
                         END;
                       UNTIL ((EOF(FErrLevel)) OR (FoundYes));
                       CLOSE(FErrLevel);
                       IF FoundYes THEN
                       BEGIN
                         RescanRequired := False;
                         ConnectRate := ErrLevel.ConnectSpeed;
                         IF CallingOut THEN WriteNodeFile('GSMail','Outbound Connect',_String(ConnectRate))
                                       ELSE WriteNodeFile('GSMail','Incoming Call',_String(ConnectRate));
                         IF ErrLevel.Immediate THEN
                         BEGIN
                           StatusWindow('Immediate Exit ErrorLevel: '+_String(ErrLevel.ErrorLevel));
                           bsWriteLog('Immediate Exit ErrorLevel: '+_String(ErrLevel.ErrorLevel),False);
                           HaltCode := ErrLevel.ErrorLevel;
                           Finished := True;
                         END
                         ELSE
                         BEGIN
                           DoMailSession;
                           KillDial;
                           IF HumanCaller THEN
                           BEGIN
                             IF MailerInfo.MailOnly THEN
                             BEGIN
                               StatusWindow('Rejecting human caller');
                               bsWriteLog('Rejecting human caller',False);
                               DrainOutBuffer(bsBBSPort,Secs2Tics(60));
                               UpdateBBS2(False);
                             END
                             ELSE IF ErrLevel.AllowHumans THEN
                             BEGIN
                               StatusWindow('Incoming human caller');
                               bsWriteLog('Incoming human caller',False);
                               SendBanner;
                               HaltCode := ErrLevel.ErrorLevel;
                               Finished := True;
                               CreateBatchFile(ErrLevel.ConnectSpeed,NodeInfo.ComPort,MinToNext,SimNode);
                               UpdateBBS2(True);
                             END
                             ELSE
                             BEGIN
                               StatusWindow('Rejecting human caller at speed '+_String(ErrLevel.ConnectSpeed));
                               bsWriteLog('Rejecting human caller at speed '+_String(ErrLevel.ConnectSpeed),False);
                               PutString(bsBBSPort,_String(ErrLevel.ConnectSpeed)+
                                         ' BPS connections are not supported on this system.'+#$0A#$0D);
                               StatusWindow('Displaying \GUNSHOT\GSMAIL\TOOSLOW.TXT');
                               bsWriteLog('Displaying \GUNSHOT\GSMAIL\TOOSLOW.TXT',False);
                               SendTooSlowBanner;
                               DrainOutBuffer(bsBBSPort,Secs2Tics(60));
                               UpdateBBS2(False);
                             END;
                             UpdateBBS;
                           END
                           ELSE
                           BEGIN
                             _Delay(1000);
                             DrainOutBuffer(bsBBSPort,Secs2Tics(60));
                             bsOnHook(NodeInfo.OnHook);
                             UnpackInboundPkts;
                             IF ReceivedMail THEN
                             BEGIN
                               IF (MailerInfo.MailExit<>0) THEN
                               BEGIN
                                 StatusWindow('Exiting due to mail received. ErrorLevel: '+_String(MailerInfo.MailExit));
                                 bsWriteLog('Exiting due to mail received. ErrorLevel: '+_String(MailerInfo.MailExit),False);
                                 HaltCode := MailerInfo.MailExit;
                                 WriteNodeFile('GSMail','Processing Network Mail','');
                                 Finished := True;
                               END;
                               CreateSemaphore(3);
                             END;
                             IF RescanRequired THEN CreateSemaphore(2);
                             _Delay(1000);
                           END;
                         END;
                         IF NOT(Finished) THEN
                         BEGIN
                           bsOnHook(NodeInfo.OnHook);
                           StatusWindow('Initializing Modem');
                           InitializeModem;
                           StatusWindow('Waiting for a call or event');
                           WriteNodeFile('GSMail','Waiting For A Caller','');
                         END;
                         TimerWait := 20;
                         NewTimerSecs(InitTimer,TimerWait);
                         NewTimerSecs(DialTimer,MailerInfo.RetryDelay);
                       END;
                       UpdateHistory;
                     END;
             3:      BEGIN {ERROR}
                       ModemStatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                     END;
             4:      BEGIN {FAX}
                       ModemStatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                       KillDial;
                       StatusWindow('Incoming FAX call');
                       bsWriteLog('Incoming FAX call',False);
                       IF NOT(RunExternalFax) THEN
                       BEGIN
                         IF MailerInfo.HandleFaxes THEN
                         BEGIN
                           GoGetTheFax;
                           ScanNewMail;
                           ScanNewFaxes;
                           StatusWindow('Initializing Modem');
                           InitializeModem;
                           StatusWindow('Waiting for a call or event');
                           WriteNodeFile('GSMail','Waiting For A Caller','');
                           TimerWait := 20;
                           NewTimerSecs(InitTimer,TimerWait);
                           NewTimerSecs(DialTimer,MailerInfo.RetryDelay);
                         END
                         ELSE
                         BEGIN
                           StatusWindow('Immediate Exit ErrorLevel 15');
                           bsWriteLog('Immediate Exit ErrorLevel 15',False);
                           HaltCode := 15;
                           Finished := True;
                           UpdateFAX;
                           UpdateHistory;
                         END;
                       END
                       ELSE
                       BEGIN
                         UpdateFAX;
                         UpdateHistory;
                       END;
                     END;
             2,5,6,11:
                     BEGIN {BUSY/NO ANSWER/NO CARRIER/VOICE}
                       IF ResultType IN [5,6,11] THEN
                       BEGIN
                         IF ((Waiting) AND (CallingOut)) THEN AddUndialable(MailQueue^[MailQueuePointer].DestAddr);
                       END;
                       RemoveDialWindow;
                       Waiting := False;
                       RingCount := 0;
                       ModemStatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                       _Delay(NodeInfo.CommandDelay);
                       bsClearInBuffer;
                       InitializeModem;
                       KillDial;
                     END;
             7:      BEGIN {NO DIAL TONE}
                       NewTimerSecs(FailSafe,60);
                       RemoveDialWindow;
                       Waiting := True;
                       RingCount := 0;
                       ModemStatusWindow(ModemResult);
                       _Delay(NodeInfo.CommandDelay);
                       PutString(bsBBSPort,NodeInfo.Answer+#13);
                       KillDial;
                     END;
             8:      BEGIN {OK}
                       ModemStatusWindow(ModemResult);
                     END;
             9:      BEGIN {RING}
                       NewTimerSecs(FailSafe,60);
                       RemoveDialWindow;
                       INC(RingCount);
                       Waiting := True;
                       ModemStatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                       IF RingCount=1 THEN ClearCIDSemaphore;
                       IF (RingCount>=MailerInfo.AnswerOnRing) THEN
                       BEGIN
                         bsSendCommandString(NodeInfo.Answer,NodeInfo.CommandDelay);
                         DumpCIDSemaphore;
                       END;
                       KillDial;
                     END;
             10:     BEGIN {RINGING}
                       bsWriteLog(ModemResult,False);
                     END;
             12..15: BEGIN {CID DATE/TIME/NAME/NUMBER}
                       StatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                       CASE ResultType OF
                       14:  BEGIN {NAME}
                              Delete(ModemResult,1,LENGTH(ExtCodes.CIDName));
                              CIDSemaphore.Name := ModemResult;
                            END;
                       15:  BEGIN {NUMBER}
                              Delete(ModemResult,1,LENGTH(ExtCodes.CIDNumber));
                              CIDSemaphore.Number := ModemResult;
                            END;
                       END;
                     END;
             16..25: BEGIN {USER DEFs}
                       ModemStatusWindow(ModemResult);
                       bsWriteLog(ModemResult,False);
                       IF ModemResult='DATA' THEN
                       BEGIN
                         _Delay(NodeInfo.CommandDelay);
                         PutString(bsBBSPort,'ATO'+#13);
                       END;
                     END;
             END;
             NewTimerSecs(SaverAdvance,5);
             NewTimerSecs(SaverTimer,Mailer2Info.BlankerTimeout);
           END;
         END;
       END;
     UNTIL ((Finished) OR (DoExitEvent));
     IF NOT(HumanCaller) THEN ClearCIDSemaphore;
     IF DoExitEvent THEN
     BEGIN
       StatusWindow('Exit Event: '+ExitEvent.Description);
       StatusWindow('ErrorLevel: '+_String(ExitEvent.Errorlevel));
       bsWriteLog('Exit Event: '+ExitEvent.Description,False);
       bsWriteLog('ErrorLevel: '+_String(ExitEvent.Errorlevel),False);
       WriteNodeFile('GSMail','Running External Event','');
       bsClearInBuffer;
       bsOffHook(NodeInfo.OffHook);
       HaltCode := ExitEvent.ErrorLevel;
     END
     ELSE
     BEGIN
       IF (HaltCode=MailerInfo.MailExit) THEN
       BEGIN
         bsClearInBuffer;
         bsOffHook(NodeInfo.OffHook);
       END
       ELSE IF ((HaltCode=5) OR (HaltCode=10)) THEN
       BEGIN
         WriteNodeFile('GSMail','Node Temporarily Offline','');
         bsClearInBuffer;
         bsOffHook(NodeInfo.OffHook);
       END;
     END;
     ShutDown;
     ClearOutOutpkts;
     Halt(HaltCode);
END.
