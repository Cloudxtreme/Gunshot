{$I DEFINES.INC}
UNIT JamStore;


INTERFACE


PROCEDURE JamBase_StoreMessage(AddTag: Boolean);


IMPLEMENTATION


USES Globals,BsLog,MiscMsg,MkGlobT,MkOpen,MkMsgAbs,KeyCheck,
     BsAkas,MkString,MkDos,GoodLang,Sema,Version,FMode;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Add origin & tear lines to the message.                           }
{      - Store the message text & header.                                  }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_StoreMessage(AddTag: Boolean);
VAR  MsgText  : MessageTextLines;
     Loop     : Word;
     FoundIt  : Boolean;
     AreaType : Char;
     Temp     : String;
     MaxMsgs  : Word;
BEGIN
     bsWriteLog('Entered ÄÂÄ To: '+FastBaseHdr.MsgTo,False);
     bsWriteLog('message  ÀÄ Re: '+FastBaseHdr.MsgSubject,False);
     {ADD TEAR & ORIGIN LINES FOR ECHO AREAS}
     IF ((MessageAreas.area_type>=10) AND
        (MessageAreas.area_type<=12) AND
        (AddTag=True)) THEN
     BEGIN
          ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
          RESET(FMsgText);
          SEEK(FMsgText,FileSize(FMsgText));
          MsgText.Line := '';
          WRITE(FMsgText,MsgText);
          {TEAR LINE}
          MsgText.Line := '--- '+OurAppName;
          WRITE(FMsgText,MsgText);
          {ORIGIN LINE}
          MsgText.Line := ' * Origin: '+GetNetOrigin(MessageAreas.origin)+' ('+
                          GetNetAddress(MessageAreas.address)+')';
          WRITE(FMsgText,MsgText);
          CLOSE(FMsgText);
     END;
     IF ((MessageAreas.Area_Type>=30) AND (MessageAreas.Area_Type<=32)) THEN
     BEGIN
          OrigAddr := UUCP.YourAddress;
          DestAddr := UUCP.HostAddress;
          CASE MessageAreas.Base_Type OF
          1:  AreaType := 'J';
          2:  AreaType := 'S';
          3:  AreaType := 'F';
          END;
          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
          IF OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs) THEN
          BEGIN
               EnteredEcho := True;
               Msg^.StartNewMsg;
               Msg^.SetMailType(mmtNetMail);
               Msg^.SetEcho(True);
               Msg^.SetOrig(OrigAddr);
               Msg^.SetDest(DestAddr);
               Msg^.SetCrash(Msg_Crash);
               Msg^.SetHold(Msg_Hold);
               IF ((MessageAreas.file_attaches=1) AND
                  (UserRecord.Security>=MessageAreas.file_attaches_sec)) THEN
               BEGIN
                    Msg^.SetFAttach(Msg_File_Attach);
               END
               ELSE Msg^.SetFAttach(False);
               Msg^.SetFileReq(Msg_File_Request);
               Msg^.SetKillSent(True);
               Msg^.SetSubj  (FastBaseHdr.MsgSubject);
               Msg^.SetPriv  (FastBaseHdr.Priv);
               Msg^.SetDate  (DateStr(GetDosDate));
               Msg^.SetTime  (TimeStr(GetDosDate));
               Msg^.SetLocal (True);
               Msg^.SetFrom  (FastBaseHdr.MsgFrom);
               Msg^.SetTo    (UUCP.HostName);
               Temp := 'To: '+FastBaseHdr.MsgTo;
               Msg^.DoStringLn(Temp);
               Temp := '';
               Msg^.DoStringLn(Temp);
               Msg^.DoStringLn(GetMsgId(OrigAddr));
               IF (ReplyDomain<>'') THEN Msg^.DoStringLn(#1+'REPLY: '+ReplyDomain);
               Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
               ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
               RESET(FMsgText);
               REPEAT
                     IF NOT(EOF(FMsgText)) THEN
                     BEGIN
                          READ(FMsgText,MsgText);
                          IF MessageAreas.CleanLanguage=1 THEN MsgText.Line := clean_language(MsgText.Line);
                          Msg^.DoStringLn(MsgText.Line);
                     END;
               UNTIL EOF(FMsgText);
               CLOSE(FMsgText);
               IF Msg^.WriteMsg=0 THEN;
               AddToSemaphores(CurrentMessageBase,Msg^.GetMsgNum);
               CloseMsgArea(Msg);
          END;
     END
     ELSE
     BEGIN
          GetNetAddress(MessageAreas.address);
          OrigAddr := NetworkInfo.Net_Address;
          CASE MessageAreas.Base_Type OF
          1:  AreaType := 'J';
          2:  AreaType := 'S';
          3:  AreaType := 'F';
          END;
          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
          IF OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs) THEN
          BEGIN
               Msg^.StartNewMsg;
               Msg^.SetOrig(OrigAddr);
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
                    FoundIt := False;
                    ASSIGN(FNetworkInfo,DATA_Directory+'\NETWORK.DAT');
                    RESET(FNetworkInfo);
                    REPEAT
                          READ(FNetworkInfo,NetworkInfo);
                          IF DestAddr.Zone=NetworkInfo.Net_Address.Zone THEN
                          BEGIN
                               OrigAddr := NetworkInfo.Net_Address;
                               FoundIt := True;
                          END;
                    UNTIL ((EOF(FNetworkInfo)) OR (FoundIt));
                    CLOSE(FNetworkInfo);
                    IF NOT(FoundIt) THEN
                    BEGIN
                         GetNetAddress(1);
                         OrigAddr := NetworkInfo.Net_Address;
                    END;
                    Msg^.SetOrig(OrigAddr);
                    Msg^.SetDest(DestAddr);
                    Msg^.SetCrash(Msg_Crash);
                    Msg^.SetHold(Msg_Hold);
                    IF ((MessageAreas.file_attaches=1) AND
                       (UserRecord.Security>=MessageAreas.file_attaches_sec)) THEN
                    BEGIN
                         Msg^.SetFAttach(Msg_File_Attach);
                    END
                    ELSE Msg^.SetFAttach(False);
                    Msg^.SetFileReq(Msg_File_Request);
                    Msg^.SetKillSent(True);
                    Msg^.DoStringLn(GetMsgId(OrigAddr));
                    IF (ReplyDomain<>'') THEN Msg^.DoStringLn(#1+'REPLY: '+ReplyDomain);
               END
               ELSE IF ((MessageAreas.Area_Type>=10) AND (MessageAreas.Area_Type<=12)) THEN
               BEGIN
                    Msg^.SetMailType(mmtEchoMail);
                    Msg^.SetEcho(True);
                    Msg^.DoStringLn(GetMsgId(OrigAddr));
                    IF (ReplyDomain<>'') THEN Msg^.DoStringLn(#1+'REPLY: '+ReplyDomain);
                    EnteredEcho := True;
               END;
               Msg^.SetFrom  (FastBaseHdr.MsgFrom);
               Msg^.SetTo    (FastBaseHdr.MsgTo);
               Msg^.SetSubj  (FastBaseHdr.MsgSubject);
               Msg^.SetPriv  (FastBaseHdr.Priv);
               Msg^.SetDate  (DateStr(GetDosDate));
               Msg^.SetTime  (TimeStr(GetDosDate));
               Msg^.SetLocal (True);
               Msg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
               ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
               RESET(FMsgText);
               REPEAT
                     IF NOT(EOF(FMsgText)) THEN
                     BEGIN
                          READ(FMsgText,MsgText);
                          IF MessageAreas.CleanLanguage=1 THEN MsgText.Line := clean_language(MsgText.Line);
                          Msg^.DoStringLn(MsgText.Line);
                     END;
               UNTIL EOF(FMsgText);
               CLOSE(FMsgText);
               IF Msg^.WriteMsg=0 THEN;
               AddToSemaphores(CurrentMessageBase,Msg^.GetMsgNum);
               CloseMsgArea(Msg);
          END;
     END;
     FileMode := SetFileMode;
     IF IOResult=0 THEN;
     EnteredReply := True;
END;


END.
