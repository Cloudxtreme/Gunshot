{$I DEFINES.INC}
UNIT Report;


INTERFACE


PROCEDURE DoFilesUploadedReport;
PROCEDURE DoPrivateUploadReport;
PROCEDURE DoNewUserReport;


IMPLEMENTATION


USES Globals,MiscMsg,MkOpen,MkMsgAbs,MkString,KeyCheck,
     MkDos,Special,BsLog,Sema,Version,BsFile;


FUNCTION FoundMessageArea(AreaNumber: Word): Boolean;
VAR  FoundIt : Boolean;
BEGIN
     FoundIt := False;
     ASSIGN(FMessageArea,DATA_Directory+'\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
           READ(FMessageArea,MessageAreas);
           IF ((MessageAreas.AreaID=AreaNumber) AND (MessageAreas.Area_Type<30)) THEN FoundIt := True;
     UNTIL ((EOF(FMessageArea)) OR (FoundIt));
     CLOSE(FMessageArea);
     FoundMessageArea := FoundIt;
END;


PROCEDURE DoFilesUploadedReport;
VAR  AreaType : Char;
     MaxMsgs  : Word;
     TFile    : Text;
     Temp     : String;
BEGIN
     ASSIGN(FReports,DATA_Directory+'\REPORTS.DAT');
     {$I-}
     RESET(FReports);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FReports,Reports);
                IF Reports.ReportType=2 THEN
                BEGIN
                     IF FoundMessageArea(Reports.MsgAreaNumber) THEN
                     BEGIN
                          FastBaseHdr.MsgFrom    := Process_Special(Reports.MsgFrom,False);
                          FastBaseHdr.MsgTo      := Process_Special(Reports.MsgTo,False);
                          FastBaseHdr.MsgSubject := Process_Special(Reports.MsgSubject,False);
                          GetNetAddress(MessageAreas.address);
                          OrigAddr := NetworkInfo.Net_Address;
                          CASE MessageAreas.Base_Type OF
                          1:  AreaType := 'J';
                          2:  AreaType := 'S';
                          3:  AreaType := 'F';
                          END;
                          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
                          IF OpenOrCreateMsgArea(Msg,AreaType+MessageAreas.Dos_Name,MaxMsgs) THEN
                          BEGIN
                               bsWriteLog('Entered ÄÂÄ To: '+FastBaseHdr.MsgTo,False);
                               bsWriteLog('message  ÀÄ Re: '+FastBaseHdr.MsgSubject,False);
                               Msg^.StartNewMsg;
                               Msg^.SetOrig(OrigAddr);
                               Msg^.SetDest(OrigAddr);
                               IF ((MessageAreas.area_type>=1) AND (MessageAreas.area_type<=3)) THEN
                               BEGIN
                                    EnteredLocal := True;
                                    Msg^.SetMailType(mmtNormal);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=20) AND (MessageAreas.Area_Type<=22)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtNetMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                                    Msg^.SetOrig(OrigAddr);
                                    Msg^.SetDest(OrigAddr);
                                    Msg^.SetCrash(False);
                                    Msg^.SetFAttach(False);
                                    Msg^.SetFileReq(False);
                                    Msg^.SetKillSent(True);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=10) AND (MessageAreas.Area_Type<=12)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtEchoMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                               END;
                               Msg^.SetFrom(FastBaseHdr.MsgFrom);
                               Msg^.SetTo(FastBaseHdr.MsgTo);
                               Msg^.SetSubj(FastBaseHdr.MsgSubject);
                               Msg^.SetDate(DateStr(GetDosDate));
                               Msg^.SetTime(TimeStr(GetDosDate));
                               Msg^.SetLocal(True);
                               CASE MessageAreas.area_type OF
                               1,10,20,30 : FastBaseHdr.Priv := false;
                               2,11,21,31 : FastBaseHdr.Priv := True;
                               3,12,22,32 : FastBaseHdr.Priv := false;
                               END;
                               Msg^.SetPriv(FastBaseHdr.Priv);
                               Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
                               IF _FileExists(Reports.Header) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Header);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               IF _FileExists(NODE_Directory+'\NEWFILES.$$$') THEN
                               BEGIN
                                    ASSIGN(TFile,NODE_Directory+'\NEWFILES.$$$');
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               IF _FileExists(Reports.Footer) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Footer);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               {ADD THE TEAR LINE}
                               IF ((MessageAreas.area_type>=10) AND (MessageAreas.area_type<=12)) THEN
                               BEGIN
                                    Msg^.DoStringLn('');
                                    Msg^.DoStringLn('--- '+OurAppName);
                                    Msg^.DoStringLn(' * Origin: '+GetNetOrigin(MessageAreas.origin)+' ('+
                                                    GetNetAddress(MessageAreas.address)+')');
                               END;
                               IF Msg^.WriteMsg=0 THEN;
                               AddToSemaphores(MessageAreas.Dos_Name,Msg^.GetMsgNum);
                               CloseMsgArea(Msg);
                          END;
                     END;
                END;
          UNTIL EOF(FReports);
          CLOSE(FReports);
     END;
END;


PROCEDURE DoPrivateUploadReport;
VAR  AreaType : Char;
     MaxMsgs  : Word;
     TFile    : Text;
     Temp     : String;
BEGIN
     ASSIGN(FReports,DATA_Directory+'\REPORTS.DAT');
     {$I-}
     RESET(FReports);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FReports,Reports);
                IF Reports.ReportType=3 THEN
                BEGIN
                     IF FoundMessageArea(Reports.MsgAreaNumber) THEN
                     BEGIN
                          FastBaseHdr.MsgFrom    := Process_Special(Reports.MsgFrom,False);
                          FastBaseHdr.MsgTo      := Process_Special(Reports.MsgTo,False);
                          FastBaseHdr.MsgSubject := Process_Special(Reports.MsgSubject,False);
                          GetNetAddress(MessageAreas.address);
                          OrigAddr := NetworkInfo.Net_Address;
                          CASE MessageAreas.Base_Type OF
                          1:  AreaType := 'J';
                          2:  AreaType := 'S';
                          3:  AreaType := 'F';
                          END;
                          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
                          IF OpenOrCreateMsgArea(Msg,AreaType+MessageAreas.Dos_Name,MaxMsgs) THEN
                          BEGIN
                               bsWriteLog('Entered ÄÂÄ To: '+FastBaseHdr.MsgTo,False);
                               bsWriteLog('message  ÀÄ Re: '+FastBaseHdr.MsgSubject,False);
                               Msg^.StartNewMsg;
                               Msg^.SetOrig(OrigAddr);
                               Msg^.SetDest(OrigAddr);
                               IF ((MessageAreas.area_type>=1) AND (MessageAreas.area_type<=3)) THEN
                               BEGIN
                                    EnteredLocal := True;
                                    Msg^.SetMailType(mmtNormal);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=20) AND (MessageAreas.Area_Type<=22)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtNetMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                                    Msg^.SetOrig(OrigAddr);
                                    Msg^.SetDest(OrigAddr);
                                    Msg^.SetCrash(False);
                                    Msg^.SetFAttach(False);
                                    Msg^.SetFileReq(False);
                                    Msg^.SetKillSent(True);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=10) AND (MessageAreas.Area_Type<=12)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtEchoMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                               END;
                               Msg^.SetFrom(FastBaseHdr.MsgFrom);
                               Msg^.SetTo(FastBaseHdr.MsgTo);
                               Msg^.SetSubj(FastBaseHdr.MsgSubject);
                               Msg^.SetDate(DateStr(GetDosDate));
                               Msg^.SetTime(TimeStr(GetDosDate));
                               Msg^.SetLocal(True);
                               CASE MessageAreas.area_type OF
                               1,10,20,30 : FastBaseHdr.Priv := false;
                               2,11,21,31 : FastBaseHdr.Priv := True;
                               3,12,22,32 : FastBaseHdr.Priv := false;
                               END;
                               Msg^.SetPriv(FastBaseHdr.Priv);
                               Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
                               IF _FileExists(Reports.Header) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Header);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               IF _FileExists(NODE_Directory+'\NEWFILES.$$$') THEN
                               BEGIN
                                    ASSIGN(TFile,NODE_Directory+'\NEWFILES.$$$');
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               IF _FileExists(Reports.Footer) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Footer);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               {ADD THE TEAR LINE}
                               IF ((MessageAreas.area_type>=10) AND (MessageAreas.area_type<=12)) THEN
                               BEGIN
                                    Msg^.DoStringLn('');
                                    Msg^.DoStringLn('--- '+OurAppName);
                                    Msg^.DoStringLn(' * Origin: '+GetNetOrigin(MessageAreas.origin)+' ('+
                                                    GetNetAddress(MessageAreas.address)+')');
                               END;
                               IF Msg^.WriteMsg=0 THEN;
                               AddToSemaphores(MessageAreas.Dos_Name,Msg^.GetMsgNum);
                               CloseMsgArea(Msg);
                          END;
                     END;
                END;
          UNTIL EOF(FReports);
          CLOSE(FReports);
     END;
END;


PROCEDURE DoNewUserReport;
VAR  AreaType : Char;
     MaxMsgs  : Word;
     TFile    : Text;
     Temp     : String;
BEGIN
     ASSIGN(FReports,DATA_Directory+'\REPORTS.DAT');
     {$I-}
     RESET(FReports);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FReports,Reports);
                IF Reports.ReportType=4 THEN
                BEGIN
                     IF FoundMessageArea(Reports.MsgAreaNumber) THEN
                     BEGIN
                          FastBaseHdr.MsgFrom    := Process_Special(Reports.MsgFrom,False);
                          FastBaseHdr.MsgTo      := Process_Special(Reports.MsgTo,False);
                          FastBaseHdr.MsgSubject := Process_Special(Reports.MsgSubject,False);
                          GetNetAddress(MessageAreas.address);
                          OrigAddr := NetworkInfo.Net_Address;
                          CASE MessageAreas.Base_Type OF
                          1:  AreaType := 'J';
                          2:  AreaType := 'S';
                          3:  AreaType := 'F';
                          END;
                          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
                          IF OpenOrCreateMsgArea(Msg,AreaType+MessageAreas.Dos_Name,MaxMsgs) THEN
                          BEGIN
                               bsWriteLog('Entered ÄÂÄ To: '+FastBaseHdr.MsgTo,False);
                               bsWriteLog('message  ÀÄ Re: '+FastBaseHdr.MsgSubject,False);
                               Msg^.StartNewMsg;
                               Msg^.SetOrig(OrigAddr);
                               Msg^.SetDest(OrigAddr);
                               IF ((MessageAreas.area_type>=1) AND (MessageAreas.area_type<=3)) THEN
                               BEGIN
                                    EnteredLocal := True;
                                    Msg^.SetMailType(mmtNormal);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=20) AND (MessageAreas.Area_Type<=22)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtNetMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                                    Msg^.SetOrig(OrigAddr);
                                    Msg^.SetDest(OrigAddr);
                                    Msg^.SetCrash(False);
                                    Msg^.SetFAttach(False);
                                    Msg^.SetFileReq(False);
                                    Msg^.SetKillSent(True);
                               END
                               ELSE IF ((MessageAreas.Area_Type>=10) AND (MessageAreas.Area_Type<=12)) THEN
                               BEGIN
                                    Msg^.SetMailType(mmtEchoMail);
                                    Msg^.SetEcho(True);
                                    EnteredEcho := True;
                               END;
                               Msg^.SetFrom(FastBaseHdr.MsgFrom);
                               Msg^.SetTo(FastBaseHdr.MsgTo);
                               Msg^.SetSubj(FastBaseHdr.MsgSubject);
                               Msg^.SetDate(DateStr(GetDosDate));
                               Msg^.SetTime(TimeStr(GetDosDate));
                               Msg^.SetLocal(True);
                               CASE MessageAreas.area_type OF
                               1,10,20,30 : FastBaseHdr.Priv := false;
                               2,11,21,31 : FastBaseHdr.Priv := True;
                               3,12,22,32 : FastBaseHdr.Priv := false;
                               END;
                               Msg^.SetPriv(FastBaseHdr.Priv);
                               Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
                               IF _FileExists(Reports.Header) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Header);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIL EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               IF _FileExists(Reports.Footer) THEN
                               BEGIN
                                    ASSIGN(TFile,Reports.Footer);
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          Temp := Process_Special(Temp,False);
                                          Msg^.DoStringLn(Temp);
                                    UNTIl EOF(TFile);
                                    CLOSE(TFile);
                               END;
                               {ADD THE TEAR LINE}
                               IF ((MessageAreas.area_type>=10) AND (MessageAreas.area_type<=12)) THEN
                               BEGIN
                                    Msg^.DoStringLn('');
                                    Msg^.DoStringLn('--- '+OurAppName);
                                    Msg^.DoStringLn(' * Origin: '+GetNetOrigin(MessageAreas.origin)+' ('+
                                                    GetNetAddress(MessageAreas.address)+')');
                               END;
                               IF Msg^.WriteMsg=0 THEN;
                               AddToSemaphores(MessageAreas.Dos_Name,Msg^.GetMsgNum);
                               CloseMsgArea(Msg);
                          END;
                     END;
                END;
          UNTIL EOF(FReports);
          CLOSE(FReports);
     END;
END;


END.
