{$I DEFINES.INC}
UNIT MsgWrite;


INTERFACE


PROCEDURE CreateAttachment(FileName1,FileName2: String);
PROCEDURE CreateMessages;


IMPLEMENTATION


USES BsFido,Globals,BsAkas,Version,Shotgun,MkOpen,MkMsgAbs,
     Dos,MkString,MkDos,BsTime,BsFile,Process,BsString,KeyCheck;


PROCEDURE CreateAttachment(FileName1,FileName2: String);
BEGIN
     {The File}
     wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
     wFidoSetMsgFrom(OurAppName);
     wFidoSetMsgTo(LinksInfo.SysopName);
     wFidoSetMsgSubject(FileName1);
     wFidoSetAkas(NetworkInfo.Net_Address,LinksInfo.NetWorkAddress);
     wFidoSetFileAttached(True);
     CASE LinksInfo.NetMailStatus OF
     2:   wFidoSetHoldForPickup(True);
     3:   wFidoSetCrash(True);
     END;
     wFidoSetDirect(True);
     wFidoWriteHeader(True);
     wFidoEndMessage;
     {The TIC}
     wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
     wFidoSetMsgFrom(OurAppName);
     wFidoSetMsgTo(LinksInfo.SysopName);
     wFidoSetMsgSubject(FileName2);
     wFidoSetAkas(NetworkInfo.Net_Address,LinksInfo.NetWorkAddress);
     wFidoSetFileAttached(True);
     wFidoSetKillFile(True);
     CASE LinksInfo.NetMailStatus OF
     2:   wFidoSetHoldForPickup(True);
     3:   wFidoSetCrash(True);
     END;
     wFidoSetDirect(True);
     wFidoWriteHeader(True);
     wFidoEndMessage;
END;


PROCEDURE CreateMessages;
VAR  FMessageArea : File Of _MessageArea_Record;
     FReports     : File Of _Report_Record;
     MessageArea  : _MessageArea_Record;
     Reports      : _Report_Record;
     GotIt        : Boolean;
     AreaType     : Char;
     MaxMsgs      : Word;
     Msg          : AbsMsgPtr;
     TFile1       : Text;
     TFile2       : Text;
     TFile3       : Text;
     Temp         : String;
     DirInfo      : SearchRec;
     ReportNum    : Longint;
     ByteCount    : Longint;
     FileCount    : Longint;
     LineCounter  : Longint;

     FUNCTION LoadMessageAreaInfo: Boolean;
     VAR  Status : Boolean;
     BEGIN
          Status := False;
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          {$I-}RESET(FMessageArea);{$I+}
          IF IOResult=0 THEN
          BEGIN
            REPEAT
              READ(FMessageArea,MessageArea);
              IF MessageArea.AreaId=Reports.MsgAreaNumber THEN Status := True;
            UNTIL ((Status) OR (EOF(FMessageArea)));
            CLOSE(FMessageArea);
          END
          ELSE Status := False;
          LoadMessageAreaInfo := Status;
     END;

     PROCEDURE StartTheMessage;
     BEGIN
          Msg^.StartNewMsg;
          CASE MessageArea.Area_Type OF
          1..3: Msg^.SetMailType(mmtNormal);
          20..22: BEGIN
                    Msg^.SetMailType(mmtNetMail);
                    Msg^.SetEcho(True);
                  END;
          10..12: BEGIN
                    Msg^.SetMailType(mmtEchoMail);
                    Msg^.SetEcho(True);
                  END;
          END;
          Msg^.SetOrig(NetWorkInfo.net_address);
          Msg^.SetDest(NetWorkInfo.net_address);
          Msg^.SetFrom(Reports.MsgFrom);
          Msg^.SetTo(Reports.MsgTo);
          Msg^.SetSubj(Reports.MsgSubject);
          Msg^.SetDate(DateStr(GetDosDate));
          Msg^.SetTime(TimeStr(GetDosDate));
          Msg^.SetLocal(True);
          CASE MessageArea.Area_Type OF
          2,21,11: Msg^.SetPriv(True);
          ELSE  Msg^.SetPriv(False);
          END;
          Msg^.DoStringLn(GetMsgId(NetWorkInfo.net_address));
          Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
          Msg^.DoStringLn('');
          Msg^.DoStringLn(_GetPrettyDate+'; '+_GetPrettyTime);
          Msg^.DoStringLn('');
          {INSERT THE MESSAGE HEADER}
          IF _FileExists(Reports.Header) THEN
          BEGIN
            ASSIGN(TFile2,Reports.Header);
            RESET(TFile2);
            REPEAT
              READLN(TFile2,Temp);
              Msg^.DoStringLn(Temp);
            UNTIL EOF(TFile2);
            CLOSE(TFile2);
            Msg^.DoStringLn('');
            Msg^.DoStringLn('');
          END;
     END;

     PROCEDURE EndTheMessage;
     BEGIN
          Msg^.DoStringLn('');
          Msg^.DoStringLn('');
          {INSERT THE MESSAGE FOOTER}
          IF _FileExists(Reports.Footer) THEN
          BEGIN
            ASSIGN(TFile2,Reports.Footer);
            RESET(TFile2);
            REPEAT
              READLN(TFile2,Temp);
              Msg^.DoStringLn(Temp);
            UNTIL EOF(TFile2);
            CLOSE(TFile2);
          END;
          Msg^.DoStringLn('');
          Msg^.DoStringLn('--- '+OurAppName);
          Msg^.DoStringLn(' * Origin: '+GetNetOrigin(MessageArea.origin)+
                          ' ('+AddressToString(NetWorkInfo.net_address)+')');
          Msg^.WriteMsg;
     END;

BEGIN
     {====================================================================}
     { CREATE NEW AREAS ANNOUNCEMENTS                                     }
     {====================================================================}
     IF _FileExists(BaseDirectory+'\!21\AUTOADD.TXT') THEN
     BEGIN
       ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
       {$I-}RESET(FReports);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FReports,Reports);
           IF Reports.ReportType=5 THEN
           BEGIN
             GotIt := False;
             ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
             {$I-}RESET(FMessageArea);{$I+}
             IF IOResult=0 THEN
             BEGIN
               REPEAT
                 READ(FMessageArea,MessageArea);
                 IF MessageArea.AreaId=Reports.MsgAreaNumber THEN GotIt := True;
               UNTIL ((GotIt) OR (EOF(FMessageArea)));
               CLOSE(FMessageArea);
               IF GotIt THEN
               BEGIN
                 GetNetAddress(MessageArea.address);
                 CASE MessageArea.Base_Type OF
                 1:  AreaType := 'J';
                 2:  AreaType := 'S';
                 3:  AreaType := 'F';
                 END;
                 IF MessageArea.MaxMsgs=0 THEN MaxMsgs := 1000
                                          ELSE MaxMsgs := MessageArea.MaxMsgs;
                 IF OpenOrCreateMsgArea(Msg,AreaType+MessageArea.Dos_Name,MaxMsgs) THEN
                 BEGIN
                   Msg^.StartNewMsg;
                   CASE MessageArea.Area_Type OF
                   1..3:   Msg^.SetMailType(mmtNormal);
                   20..22: BEGIN
                                Msg^.SetMailType(mmtNetMail);
                                Msg^.SetEcho(True);
                           END;
                   10..12: BEGIN
                                Msg^.SetMailType(mmtEchoMail);
                                Msg^.SetEcho(True);
                           END;
                   END;
                   Msg^.SetOrig(NetWorkInfo.net_address);
                   Msg^.SetDest(NetWorkInfo.net_address);
                   Msg^.SetFrom(Reports.MsgFrom);
                   Msg^.SetTo(Reports.MsgTo);
                   Msg^.SetSubj(Reports.MsgSubject);
                   Msg^.SetDate(DateStr(GetDosDate));
                   Msg^.SetTime(TimeStr(GetDosDate));
                   Msg^.SetLocal(True);
                   CASE MessageArea.Area_Type OF
                   2,21,11: Msg^.SetPriv(True);
                   ELSE  Msg^.SetPriv(False);
                   END;
                   Msg^.DoStringLn(GetMsgId(NetWorkInfo.net_address));
                   Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
                   Msg^.DoStringLn('');
                   Msg^.DoStringLn(_GetPrettyDate+'; '+_GetPrettyTime);
                   Msg^.DoStringLn('');
                   Msg^.DoStringLn('The following areas were auto-created by GSFile:');
                   Msg^.DoStringLn(_Replicate('Ä',75));
                   ASSIGN(TFile1,BaseDirectory+'\!21\AUTOADD.TXT');
                   RESET(TFile1);
                   REPEAT
                     READLN(TFile1,Temp);
                     Msg^.DoStringLn(Temp);
                   UNTIL EOF(TFile1);
                   CLOSE(TFile1);
                   Msg^.DoStringLn('');
                   Msg^.DoStringLn('--- '+OurAppName);
                   Msg^.DoStringLn(' * Origin: '+GetNetOrigin(MessageArea.origin)+
                                   ' ('+AddressToString(NetWorkInfo.net_address)+')');
                   Msg^.WriteMsg;
                   CloseMsgArea(Msg);
                 END;
               END;
             END;
           END;
         UNTIL EOF(FReports);
         CLOSE(FReports);
       END;
       _EraseFile(BaseDirectory+'\!21\AUTOADD.TXT');
     END;
     {====================================================================}
     { CREATE NEW FILE ANNOUNCEMENTS                                      }
     {====================================================================}
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF ((FileArea.Area_Tag<>'') AND (FileArea.TicReportNumber<>0)) THEN
       BEGIN
         IF _FileExists(BaseDirectory+'\!21\'+_String(FileArea.AreaId)+'.RPT') THEN
         BEGIN
           ByteCount := 0;
           FileCount := 0;
           ASSIGN(TFile1,BaseDirectory+'\!21\'+_String(FileArea.AreaId)+'.RPT');
           ASSIGN(TFile2,BaseDirectory+'\!21\'+_String(FileArea.TicReportNumber)+'.R');
           RESET(TFile1);
           {$I-}APPEND(TFile2);{$I+}
           IF IOResult=0 THEN
           BEGIN
             WRITELN(TFile2,'');
             WRITELN(TFile2,'');
           END
           ELSE REWRITE(TFile2);
           WRITELN(TFile2,' Area Tag : '+FileArea.Area_Tag);
           WRITELN(TFile2,'Area Name : '+FileArea.Area_Name);
           WRITELN(TFile2,_Replicate('Ä',75));
           REPEAT
             READLN(TFile1,Temp);
             IF ((Temp<>'') AND (Temp[1]=#1)) THEN
             BEGIN
               INC(FileCount);
               Delete(Temp,1,1);
               INC(ByteCount,_Numeric(Temp));
             END
             ELSE WRITELN(TFile2,Temp);
           UNTIL EOF(TFile1);
            WRITELN(TFile2,_Replicate('Ä',75));
           WRITELN(TFile2,'  Totals '+_String(ByteCount)+' bytes in '+_String(FileCount)+' files.');
           CLOSE(TFile2);
           CLOSE(TFile1);
           ERASE(TFile1);
         END;
       END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     FindFirst(BaseDirectory+'\!21\*.R',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
       ReportNum := _Numeric(_NoExtension(DirInfo.Name));
       GotIt     := False;
       ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
       {$I-}RESET(FReports);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FReports,Reports);
           IF ReportNum=Reports.ReportNumber THEN
           BEGIN
             IF Reports.ReportType=1 THEN
             BEGIN
               GotIt := True;
             END;
           END;
         UNTIL ((GotIt) OR (EOF(FReports)));
         CLOSE(FReports);
         IF GotIt THEN
         BEGIN
           IF LoadMessageAreaInfo THEN
           BEGIN
             GetNetAddress(MessageArea.Address);
             CASE MessageArea.Base_Type OF
             1:  AreaType := 'J';
             2:  AreaType := 'S';
             3:  AreaType := 'F';
             END;
             IF MessageArea.MaxMsgs=0 THEN MaxMsgs := 1000
                                      ELSE MaxMsgs := MessageArea.MaxMsgs;
             IF OpenOrCreateMsgArea(Msg,AreaType+MessageArea.Dos_Name,MaxMsgs) THEN
             BEGIN
               LineCounter := 0;
               StartTheMessage;
               ASSIGN(TFile3,BaseDirectory+'\!21\'+DirInfo.Name);
               RESET(TFile3);
               REPEAT
                 READLN(TFile3,Temp);
                 Msg^.DoStringLn(Temp);
                 INC(LineCounter);
                 IF ((Temp='') AND (LineCounter>=400)) THEN
                 BEGIN
                   IF NOT(EOF(TFile3)) THEN
                   BEGIN
                     EndTheMessage;
                     LineCounter := 0;
                     StartTheMessage;
                   END;
                 END;
               UNTIL EOF(TFile3);
               CLOSE(TFile3);
               EndTheMessage;
               CloseMsgArea(Msg);
             END;
           END;
         END;
       END;
       _EraseFile(BaseDirectory+'\!21\'+DirInfo.Name);
       FindNext(DirInfo);
     END;
END;


END.
