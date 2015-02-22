{$I DEFINES.INC}
UNIT Freq;


INTERFACE


PROCEDURE RequestIt(FName,AreaName,CDRom: String; CDNum,RFArea,RFGroup: Word);


IMPLEMENTATION


USES Globals,Time,Special,MiscMsg,MkOpen,MkMsgAbs,BsFile,
     BsString,BsLog,MkString,MkDos,Sema,Version,BsTime,KeyCheck;


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


PROCEDURE RequestIt(FName,AreaName,CDRom: String; CDNum,RFArea,RFGroup: Word);
VAR  AreaType : Char;
     MaxMsgs  : Word;
BEGIN
     _CreatePath(Shotgun_Directory+'\FREQ');
     RequestFile.RequestDate := _ProperDateNoTime;
     RequestFile.FileName    := FName;
     RequestFile.FileArea    := RFArea;
     RequestFile.FileGroup   := RFGroup;
     RequestFile.CDRom       := CDNum;
     ASSIGN(FRequestFile,Shotgun_Directory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
     {$I-}RESET(FRequestFile);{$I+}
     IF (IOResult<>0) THEN REWRITE(FRequestFile);
     SEEK(FRequestFile,FileSize(FRequestFile));
     WRITE(FRequestFile,RequestFile);
     CLOSE(FRequestFile);
     IF FoundMessageArea(Freqs.SysopMessageAreaID) THEN
     BEGIN
          FastBaseHdr.MsgFrom    := UserRecord.Name;
          FastBaseHdr.MsgTo      := Process_Special(Freqs.SysopMessageTo,False);
          FastBaseHdr.MsgSubject := 'Offline file request.';
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
               Msg^.DoStringLn('File Name: '+FName);
               Msg^.DoStringLn('File Area: '+AreaName);
               IF (CDRom<>'') THEN
               BEGIN
                    Msg^.DoStringLn('  CD Name: '+CDRom);
                    Msg^.DoStringLn('CD Number: '+_String(CDNum));
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


END.