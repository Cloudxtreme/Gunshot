{$I DEFINES.INC}
UNIT Scan;


INTERFACE


PROCEDURE ScanNewMail;
PROCEDURE ScanNewFaxes;
PROCEDURE RescanBase;
PROCEDURE PackNetMail;


IMPLEMENTATION


USES Transfer,DrawScrn,BsLog,FastW1,Queue,SysSound,Emsi,
     Shotgun,Dos,Globals,NetMail,Misc,Crt,BsAkas,Version,
     BsFile,BsString,BsVideo,KeyCheck,SaveScrn,DoProg;


PROCEDURE ScanNewMail;
BEGIN
     ClearOutOutpkts;
     StatusWindow('Scanning message base');
     bsWriteLog('Scanning message base',False);
     FastWrite('   ',Window2+5,55,ShotgunColours.SGMailNewMailLight);
     RescanBase;
END;


PROCEDURE ScanNewFaxes;
VAR  FFaxBase      : File Of _FaxBaseHeader_Record;
     FaxBase       : _FaxBaseHeader_Record;
     DirInfo       : SearchRec;
BEGIN
     ThereAreFaxes := False;
     FindFirst(MailerInfo.NetMail+'*.FAX',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          ASSIGN(FFaxBase,MailerInfo.NetMail+DirInfo.Name);
          RESET(FFaxBase);
          READ(FFaxBase,FaxBase);
          CLOSE(FFaxBase);
          IF NOT(FaxBase.Received) THEN ThereAreFaxes := True;
          FindNext(DirInfo);
     END;
     IF _FileExists(MailerInfo.Semaphores+'FAX.'+_String(SimNode)) THEN ThereAreFaxes := True;
     IF ThereAreFaxes THEN
     BEGIN
          FastWrite('Fax',Window2+5,51,128+ShotgunColours.SGMailNewMailLight);
          DoSound(2);
     END
     ELSE FastWrite('   ',Window2+5,51,ShotgunColours.SGMailNewMailLight);
END;


FUNCTION LastAppropriateFido(LRP: Word): Word;
VAR  Work    : Longint;
     Loop    : Word;
BEGIN
     Work    := 1;
     FOR Loop := 1 TO NumMsgs DO
     BEGIN
          IF Indexes[Loop]<=LRP THEN Work := Loop;
     END;
     LastAppropriateFido := Work;
END;


PROCEDURE LastReadFido;
TYPE Last_Read = RECORD
     LRP       : Word;
     END;
VAR  LastRead  : Last_Read;
     FLastRead : File Of Last_Read;
     UsrNumber : Longint;
BEGIN
     UsrNumber := 0;
     ASSIGN(FLastRead,MailerInfo.NetMail+'LASTREAD');
     {$I-}RESET(FLastRead);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FLastRead,LastRead);
                LastRead.LRP := LastAppropriateFido(LastRead.LRP);
                SEEK(FLastRead,UsrNumber);
                WRITE(FLastRead,LastRead);
                INC(UsrNumber);
          UNTIL EOF(FLastRead);
          CLOSE(FLastRead);
     END;
END;


PROCEDURE PackNetMail;
VAR  Loop : Word;
BEGIN
     ClearTheWindows;
     IndexAreas;
     FOR Loop := 1 TO NumMsgs DO
     BEGIN
          IF (Loop<>Indexes[Loop]) THEN
          BEGIN
               _RenameFile(MailerInfo.NetMail+_String(Indexes[Loop])+'.MSG',
                           MailerInfo.NetMail+_String(Loop)+'.MSG');
          END;
     END;
END;


FUNCTION PktTime: String;
CONST Days   : Array[0..6] Of String[3] = ('Sun','Mon','Tue','Wed','Thr','Fri','Sat');
CONST Months : Array[1..12] Of String[3] = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
     Temp         : String;

     FUNCTION PadIt(InWord: Word): String;
     VAR  Crap : String;
     BEGIN
          Crap := _String(InWord);
          IF LENGTH(Crap)=1 THEN Crap := '0'+Crap;
          PadIt := Crap;
     END;

BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     Temp := Days[dow]+' '+Months[mm]+' '+_String(dd)+' '+_String(yy)+
             ' at '+PadIt(h)+':'+PadIt(m)+' UTC'+SystemInfo.UTCSetting;
     PktTime := Temp;
END;


PROCEDURE RescanBase;
VAR  Loop     : Word;
     Work     : Word;
     Temp     : String;
     GoingTo  : AddrType;
     Sysop    : String;
     SysAlias : String;
     TFile    : Text;
     TFile2   : Text;
     MTo      : String;
     WByteLo  : Byte;
     WByteHi  : Byte;
     KFSStat  : Byte;

     FUNCTION IsItEmpty: Boolean;
     VAR  LLoop     : Word;
          IsAllDone : Boolean;
     BEGIN
          LLoop     := 1;
          IsAllDone := False;
          REPEAT
                CASE Buffer^[LLoop] OF
                #0:  BEGIN
                          IsItEmpty := True;
                          Exit;
                     END;
                #1:  BEGIN
                          REPEAT
                                INC(LLoop);
                          UNTIL Buffer^[LLoop]=#13;
                          IF Buffer^[LLoop+1]=#10 THEN INC(LLoop);
                     END;
                #13: BEGIN
                          IF Buffer^[LLoop+1]=#10 THEN INC(LLoop);
                     END;
                #10: BEGIN
                          IF Buffer^[LLoop+1]=#13 THEN INC(LLoop);
                     END;
                ELSE BEGIN
                          IF ((Ord(Buffer^[LLoop])>31) AND (Ord(Buffer^[LLoop])<128)) THEN
                          BEGIN
                               IsItEmpty := False;
                               Exit;
                          END;
                     END;
                END;
                INC(LLoop);
          UNTIL IsAllDone;
     END;

BEGIN
     Sysop    := _UpperCase(SystemInfo.Sysop);
     SysAlias := _UpperCase(SystemInfo.Alias);
     ThereAreMsgs := False;
     New(Buffer);
     MailQueuePointer := 0;
     NumberOfQueues   := 0;
     pScan            := 0;
     StatusWindow('Preparing outbound mail');
     bsWriteLog('Preparing outbound mail',False);
     IndexAreas;
     IF (NumMsgs<>0) THEN
     BEGIN
       SaveScreen(1);
       DrawWindow(45,Window1-4,78,Window1,'OUTBOUND MAIL SCAN',True);
       FastWrite('같같같같같같같같같같같같같같같',Window1-2,47,ShotgunColours.SGMailProgressBarBack);
       FOR Loop := 1 TO NumMsgs DO
       BEGIN
         GetTheMessage(Loop);
         IF NOT(FastBaseHdr.Sent) THEN
         BEGIN
           IF IsOurNode(FastBaseHdr.Dest) THEN
           BEGIN
             MTo := _UpperCase(FastBaseHdr.MsgTo);
             IF ((MTo=Sysop) OR (MTo=SysAlias)) THEN
             BEGIN
               IF NOT(FastBaseHdr.Recv) THEN ThereAreMsgs := True;
             END;
           END
           ELSE
           BEGIN
             LoadAkaToMatch(FastBaseHdr.Dest);
             ViaKludge := 'Via '+OurAppName+' '+AddressToString(NetWork.Net_Address)+'@'+NetWork.Net_Domain+', '+PktTime+#13;
             SendStatus := Hold;
             {Get The Routing Info For Main Packet Address}
             TargetNode(FastBaseHdr.Dest,GoingTo);
             IF FastBaseHdr.Direct THEN GoingTo := FastBaseHdr.Dest;
             IF FastBaseHdr.FileAttach THEN GoingTo := FastBaseHdr.Dest;
             IF FastBaseHdr.FileRequest THEN GoingTo := FastBaseHdr.Dest;
             IF FastBaseHdr.Crash THEN
             BEGIN
               SendStatus := Crash;
               GoingTo := FastBaseHdr.Dest;
             END;
                  IF FastBaseHdr.KillFileSent THEN KFSStat := 2
             ELSE IF FastBaseHdr.TruncSent THEN KFSStat := 1
             ELSE KFSStat := 0;
             IF NOT(IsItEmpty) THEN
             BEGIN
               {Strip Everything We Don't Want Set}
               WByteLo := Lo(FidoHeader.Attribute);
               WByteHi := Hi(FidoHeader.Attribute);
               WByteLo := (WByteLo AND (NOT 4));   {Received}
               WByteLo := (WByteLo AND (NOT 8));   {Sent}
               WByteLo := (WByteLo AND (NOT 32));  {InTransit}
               WByteLo := (WByteLo AND (NOT 64));  {Orphan}
               WByteLo := (WByteLo AND (NOT 128)); {KillSent}
               WByteHi := (WByteHi AND (NOT 1));   {Local}
               WByteHi := (WByteHi AND (NOT 2));   {Hold}
               WByteHi := (WByteHi AND (NOT 8));   {Freq}
               WByteHi := (WByteHi AND (NOT 128)); {FileUpdateReq}
               FidoHeader.Attribute := (WByteHi*256)+WByteLo;
               {Create The Packet}
               MakeTheMainPacketHeader(GoingTo);
               AddThePacket;
               IF IsItNew THEN
               BEGIN
                 IF FastBaseHdr.Exclusive THEN
                 BEGIN
                   AddToQueue('MAIL',GoingTo,MailerInfo.Outpkts+'EXC\'+PktName,
                             Indexes[Loop],FastBaseHdr.KillSent,KFSStat,
                             SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
                 END
                 ELSE
                 BEGIN
                   AddToQueue('MAIL',GoingTo,MailerInfo.Outpkts+PktName,
                             Indexes[Loop],FastBaseHdr.KillSent,KFSStat,
                             SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
                 END;
               END
               ELSE AddToQueue('NULLMAIL',GoingTo,MailerInfo.Outpkts+PktName,
                              Indexes[Loop],FastBaseHdr.KillSent,KFSStat,
                              SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
             END
             ELSE
             BEGIN
               AddToQueue('NULLMAIL',GoingTo,'',Indexes[Loop],FastBaseHdr.KillSent,
                         KFSStat,SendStatus,False,0,0,0,FastBaseHdr.Exclusive,
                         False,True);
             END;
             IF FastBaseHdr.FileRequest THEN
             BEGIN
               IF Pos('@',FastBaseHdr.MsgSubject)=1 THEN
               BEGIN
                 Delete(FastBaseHdr.MsgSubject,1,1);
                 IF _FileExists(FastBaseHdr.MsgSubject) THEN
                 BEGIN
                   ASSIGN(TFile2,FastBaseHdr.MsgSubject);
                   RESET(TFile2);
                   REPEAT
                     READLN(TFile2,Temp);
                     Temp := _UpperCase(_RemoveSpaces(Temp));
                     ASSIGN(TFile,MailerInfo.OutPkts+HexSystem16(GoingTo)+'.REQ');
                     {$I-}APPEND(TFile);{$I+}
                     IF (IOResult<>0) THEN REWRITE(TFile);
                     WRITELN(TFile,Temp);
                     CLOSE(TFile);
                   UNTIL EOF(TFile2);
                   CLOSE(TFile2);
                   AddToQueue('FREQ',GoingTo,'',0,False,2,SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
                 END;
               END
               ELSE
               BEGIN
                 REPEAT
                   Work := Pos(' ',FastBaseHdr.MsgSubject);
                   IF Work=0 THEN Work := Pos(',',FastBaseHdr.MsgSubject);
                   IF (Work<>0) THEN
                   BEGIN
                     Temp := _Mid(FastBaseHdr.MsgSubject,1,Work-1);
                     ASSIGN(TFile,MailerInfo.OutPkts+HexSystem16(GoingTo)+'.REQ');
                     {$I-}APPEND(TFile);{$I+}
                     IF (IOResult<>0) THEN REWRITE(TFile);
                     WRITELN(TFile,Temp);
                     CLOSE(TFile);
                     Delete(FastBaseHdr.MsgSubject,1,Work);
                   END
                   ELSE
                   BEGIN
                     ASSIGN(TFile,MailerInfo.OutPkts+HexSystem16(GoingTo)+'.REQ');
                     {$I-}APPEND(TFile);{$I+}
                     IF (IOResult<>0) THEN REWRITE(TFile);
                     WRITELN(TFile,FastBaseHdr.MsgSubject);
                     CLOSE(TFile);
                   END;
                 UNTIL Work=0;
                 AddToQueue('FREQ',GoingTo,'',0,False,2,SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
               END;
             END
             ELSE IF FastBaseHdr.FileAttach THEN
             BEGIN
               IF Pos('@',FastBaseHdr.MsgSubject)=1 THEN
               BEGIN
                 {FUCK}
               END
               ELSE
               BEGIN
                 REPEAT
                   Work := Pos(' ',FastBaseHdr.MsgSubject);
                   IF Work=0 THEN Work := Pos(',',FastBaseHdr.MsgSubject);
                   IF (Work<>0) THEN
                   BEGIN
                     Temp := _Mid(FastBaseHdr.MsgSubject,1,Work-1);
                     AddToQueue('TRANS',GoingTo,Temp,0,False,KFSStat,SendStatus,
                                False,0,0,0,FastBaseHdr.Exclusive,False,True);
                     Delete(FastBaseHdr.MsgSubject,1,Work);
                   END
                   ELSE AddToQueue('TRANS',GoingTo,FastBaseHdr.MsgSubject,0,False,KFSStat,
                                   SendStatus,False,0,0,0,FastBaseHdr.Exclusive,False,True);
                 UNTIL Work=0;
               END;
             END;
           END;
         END;
         DoProgressBar(Loop,NumMsgs,30,pScan,47,Window1-2,False);
       END;
       RestoreScreen(1);
       IF ThereAreMsgs THEN
       BEGIN
         FastWrite('New',Window2+5,55,128+ShotgunColours.SGMailNewMailLight);
         DoSound(1);
       END;
     END;
     IF NumberOfQueues=0 THEN
     BEGIN
       StatusWindow('No mail present in outbound');
       bsWriteLog('No mail present in outbound',False);
     END
     ELSE RescanQueue;
     Dispose(Buffer);
END;


END.