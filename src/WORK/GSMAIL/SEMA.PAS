{$I DEFINES.INC}
UNIT Sema;


INTERFACE


PROCEDURE UpdateTo;
PROCEDURE UpdateBBS;
PROCEDURE UpdateBBS2        (GoodCaller: Boolean);
PROCEDURE UpdateFAX;
PROCEDURE UpdateFreqs       (IsInbound: Boolean);
PROCEDURE UpdateMailSession (IsOutbound,MailFail: Boolean);
PROCEDURE UpdateFrom;
PROCEDURE UpdateHistory;
PROCEDURE CheckCallerDate;
PROCEDURE CheckSemaphores;
PROCEDURE DumpCIDSemaphore;
PROCEDURE ClearCIDSemaphore;
PROCEDURE CreateSemaphore   (Number: Word);
PROCEDURE WriteNodeFile     (InString1,InString2,InString3: String);
PROCEDURE CreateBatchFile   (Speed: Longint; PortNum: Word; Evt: String; NNode: Word);


IMPLEMENTATION


USES Globals,DrawScrn,FireUp,Info,Comm,ApTimer,Misc,Saver,Scan,Dos,
     Time,NList,BsMulti,Transfer,Events,Shotgun,BsAkas,BsFile,BsKeys,
     BsString,BsTime,BsLog;


PROCEDURE CreateSemaphore(Number: Word);
VAR  Temp  : String;
     FFile : File;
BEGIN
     CASE Number OF
     1:   Temp := 'CFGSCAN.NOW';
     2:   Temp := 'RESCAN.NOW';
     3:   Temp := 'MAIL.IN';
     END;
     _CreatePath(MailerInfo.Semaphores);
     ASSIGN(FFile,MailerInfo.Semaphores+Temp);
     REWRITE(FFile);
     CLOSE(FFile);
     CASE Number OF
     1:   CfgRescanTime := _FileDate(MailerInfo.Semaphores+'CFGSCAN.NOW');
     2:   MsgRescanTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
     END;
END;


PROCEDURE CheckSemaphores;
BEGIN
     IF (CfgRescanTime<>_FileDate(MailerInfo.Semaphores+'CFGSCAN.NOW')) THEN
     BEGIN
          KillSaver;
          StatusWindow('Configuration change requested');
          CfgRescanTime := _FileDate(MailerInfo.Semaphores+'CFGSCAN.NOW');
          LoadVars;
          DrawAka;
          StatusWindow('Initializing Modem');
          InitializeModem;
          StatusWindow('Waiting for a call or event');
          WriteNodeFile('GSMail','Waiting For A Caller','');
          TimerWait := 20;
          NewTimerSecs(InitTimer,TimerWait);
          ResetDialTimer;
     END
     ELSE TimeSlice;
     IF (MsgRescanTime<>_FileDate(MailerInfo.Semaphores+'RESCAN.NOW')) THEN
     BEGIN
          KillSaver;
          StatusWindow('Rescan requested');
          MsgRescanTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
          _HideCursor;
          ScanNewMail;
          ScanNewFaxes;
          StatusWindow('Initializing Modem');
          _ShowCursor;
          InitializeModem;
          StatusWindow('Waiting for a call or event');
          WriteNodeFile('GSMail','Waiting For A Caller','');
          TimerWait := 20;
          NewTimerSecs(InitTimer,TimerWait);
          ResetDialTimer;
     END
     ELSE TimeSlice;
     IF _FileExists(MailerInfo.Semaphores+'NOCALLS.'+_String(SimNode)) THEN
     BEGIN
          KillSaver;
          StallThisNode(True);
     END
     ELSE TimeSlice;
     IF _FileExists(MailerInfo.Semaphores+'RESET.'+_String(SimNode)) THEN
     BEGIN
          KillSaver;
          StatusWindow('GSMail reset via external process');
          bsWriteLog('GSMail reset via external process',False);
          Finished := True;
          HaltCode := 0;
     END
     ELSE TimeSlice;
END;


PROCEDURE WriteNodeFile(InString1,InString2,InString3: String);
VAR  FNode     : File Of _NodeFile_Record;
     Node      : _NodeFile_Record;
BEGIN
     FillChar(Node,SizeOf(Node),0);
     Node.User     := InString1;
     Node.Activity := InString2;
     Node.Baud     := InString3;
     Node.Node     := SimNode;
     ASSIGN(FNode,Shotgun_Directory+'\INTRNODE\NODE'+_String(SimNode)+'.$$$');
     {$I-}RESET(FNode);{$I+}
     IF IOResult<>0 THEN REWRITE(FNode);
     WRITE(FNode,Node);
     CLOSE(FNode);
END;


PROCEDURE CheckCallerDate;
VAR  Year,Month,Day,DayOfWeek : Word;
     Loop                     : Word;
BEGIN
     GetDate(Year,Month,Day,DayOfWeek);
     IF ((Month<>LCallers.CallMonth) OR (Day<>LCallers.CallDay)) THEN
     BEGIN
          DataChanged := True;
          LCallers.CallMonth := Month;
          LCallers.CallDay   := Day;
          LCallers.BBSCalls  := 0;
          LCallers.MailCalls := 0;
          LCallers.FaxCalls  := 0;
          ASSIGN(FLCallers,Shotgun_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
          REWRITE(FLCallers);
          WRITE(FLCallers,LCallers);
          CLOSE(FLCallers);
          ASSIGN(FMailHistory,Shotgun_Directory+'\DATA\MAILHIST.'+_String(SimNode));
          RESET(FMailHistory);
          FOR Loop := 1 TO 6 DO
          BEGIN
               SEEK(FMailHistory,Loop);
               READ(FMailHistory,MailHistory);
               SEEK(FMailHistory,Loop-1);
               WRITE(FMailHistory,MailHistory);
          END;
          FillChar(MailHistory,SizeOf(MailHistory),0);
          SEEK(FMailHistory,6);
          WRITE(FMailHistory,MailHistory);
          CLOSE(FMailHistory);
     END;
END;


PROCEDURE UpdateTo;
BEGIN
     DataChanged := True;
     LCallers.ToSystem   := RemoteSystem.BBSName;
     LCallers.ToLocation := RemoteSystem.Location;
     LCallers.ToAddress  := AddressToString(RemoteSystem.Akas[1]);
     LCallers.ToCallDate := _MMDDYYYY;
     LCallers.ToCallTime := _GetPrettyTime;
     ASSIGN(FLCallers,Shotgun_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
     REWRITE(FLCallers);
     WRITE(FLCallers,LCallers);
     CLOSE(FLCallers);
END;


PROCEDURE UpdateFrom;
BEGIN
     DataChanged := True;
     LCallers.FrmSystem   := RemoteSystem.BBSName;
     LCallers.FrmLocation := RemoteSystem.Location;
     LCallers.FrmAddress  := AddressToString(RemoteSystem.Akas[1]);
     LCallers.FrmCallDate := _MMDDYYYY;
     LCallers.FrmCallTime := _GetPrettyTime;
     INC(LCallers.MailCalls);
     ASSIGN(FLCallers,Shotgun_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
     REWRITE(FLCallers);
     WRITE(FLCallers,LCallers);
     CLOSE(FLCallers);
END;


PROCEDURE UpdateBBS;
BEGIN
     DataChanged := True;
     INC(LCallers.BBSCalls);
     ASSIGN(FLCallers,Shotgun_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
     REWRITE(FLCallers);
     WRITE(FLCallers,LCallers);
     CLOSE(FLCallers);
     INC(MailHistory.HumanCallers);
END;


PROCEDURE UpdateBBS2(GoodCaller: Boolean);
BEGIN
     IF GoodCaller THEN INC(MailHistory.AllowedHumanCallers)
                   ELSE INC(MailHistory.RejectedHumanCallers);
END;


PROCEDURE UpdateFAX;
BEGIN
     DataChanged := True;
     INC(LCallers.FAXCalls);
     ASSIGN(FLCallers,Shotgun_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
     REWRITE(FLCallers);
     WRITE(FLCallers,LCallers);
     CLOSE(FLCallers);
     INC(MailHistory.InboundFaxCalls);
END;


PROCEDURE CreateBatchFile(Speed: Longint; PortNum: Word; Evt: String; NNode: Word);
VAR  Temp  : String;
     TFile : Text;
BEGIN
     Temp := 'EXEBBS '+_String(Speed)+' '+_String(PortNum)+' '+Evt+' '+_String(NNode);
     ASSIGN(TFile,'BBS'+_String(NNode)+'.BAT');
     REWRITE(TFile);
     WRITELN(TFile,Temp);
     CLOSE(TFile);
END;


PROCEDURE ClearCIDSemaphore;
BEGIN
     _EraseFile(Shotgun_Directory+'\INTRNODE\CIDDATA.'+_String(SimNode));
     FillChar(CIDSemaphore,SizeOf(CIDSemaphore),0);
END;


PROCEDURE DumpCIDSemaphore;
BEGIN
     IF ((CIDSemaphore.Name<>'') OR (CIDSemaphore.Number<>'')) THEN
     BEGIN
          ASSIGN(FCIDSemaphore,Shotgun_Directory+'\INTRNODE\CIDDATA.'+_String(SimNode));
          REWRITE(FCIDSemaphore);
          WRITE(FCIDSemaphore,CIDSemaphore);
          CLOSE(FCIDSemaphore);
          FillChar(CIDSemaphore,SizeOf(CIDSemaphore),0);
     END;
END;


PROCEDURE UpdateFreqs(IsInbound: Boolean);
BEGIN
     IF IsInbound THEN INC(MailHistory.InboundFileRequests)
                  ELSE INC(MailHistory.OutboundFileRequests);
END;


PROCEDURE UpdateHistory;
BEGIN
     ASSIGN(FMailHistory,Shotgun_Directory+'\DATA\MAILHIST.'+_String(SimNode));
     RESET(FMailHistory);
     SEEK(FMailHistory,6);
     WRITE(FMailHistory,MailHistory);
     CLOSE(FMailHistory);
END;


PROCEDURE UpdateMailSession(IsOutbound,MailFail: Boolean);
BEGIN
     IF NOT(MailFail) THEN
     BEGIN
          IF IsOutbound THEN INC(MailHistory.CompleteOutSessions)
                        ELSE INC(MailHistory.CompleteInSessions);
     END
     ELSE
     BEGIN
          IF IsOutbound THEN INC(MailHistory.FailedOutSessions)
                        ELSE INC(MailHistory.FailedInSessions);
     END;
     IF IsOutbound THEN INC(MailHistory.OutboundMailCalls)
                   ELSE INC(MailHistory.InboundMailCalls);
END;


END.