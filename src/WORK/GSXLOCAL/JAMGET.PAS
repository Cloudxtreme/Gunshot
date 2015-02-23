{$I DEFINES.INC}
UNIT JamGet;


INTERFACE


PROCEDURE JamBase_GetMessage            (Number: Longint);
PROCEDURE JamBase_GetMessageHeader      (Number: Longint);


IMPLEMENTATION


USES Globals,MkOpen,MkMsgAbs,MkGlobT,MiscMsg,MkString,
     Gunshot,FMode,BsString,BsAkas;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Read in the message header.                                       }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_GetMessageHeader(Number: Longint);
VAR  MsgText     : MessageTextLines;
     Loop        : Word;
     AreaType    : Char;
     Temp        : String;
     TestAddress : AddrType;
     MaxMsgs     : Word;
BEGIN
     CanKill := False;
     IsYours := False;
     CanSee  := False;
     CurrentMessage := Number;
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     Msg^.SeekFirst(MsgIndex^[Number]);
     IF Msg^.SeekFound THEN
     BEGIN
          Msg^.MsgStartUp;
          FastBaseHdr.MsgFrom := Msg^.GetFrom;
          FastBaseHdr.MsgTo   := Msg^.GetTo;
          FastBaseHdr.Priv    := Msg^.IsPriv;
          FastBase_Yours;
     END;
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;
{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Read MSG 'number' into a temp file for reading.                   }
{      - Set the message as received if its the user's                     }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_GetMessage(Number: Longint);
VAR  FastBaseTxt  : String;
     MsgText      : MessageTextLines;
     Loop         : Word;
     Loop2        : Word;
     Temp         : String;
     CharCount    : Word;
     Counter      : Word;
     AreaType     : Char;
     MaxMsgs      : Word;
     NewZone      : Word;
     FmPt         : String;
     ToPt         : String;

     FUNCTION NoEsc(InString: String): String;
     VAR  Work : Word;
     BEGIN
          REPEAT
                Work := Pos(#27,InString);
                IF Work<>0 THEN Delete(InString,Work,1);
          UNTIL Work=0;
          NoEsc := InString;
     END;

BEGIN
     CurrentMessage := Number;
     ReplyDomain    := '';
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     Msg^.SeekFirst(MsgIndex^[Number]);
     IF Msg^.SeekFound THEN
     BEGIN
          FmPt := '';
          ToPt := '';
          Msg^.MsgStartUp;
          FastBaseHdr.MsgNumber   := Number;
          FastBaseHdr.MsgFrom     := Msg^.GetFrom;
          FastBaseHdr.MsgTo       := Msg^.GetTo;
          FastBaseHdr.MsgSubject  := Msg^.GetSubj;
          FastBaseHdr.MsgTime     := TimeToLongint(Msg^.GetTime);
          FastBaseHdr.MsgDate     := Msg^.GetDate;
          FastBaseHdr.Local       := Msg^.IsLocal;
          FastBaseHdr.Sent        := Msg^.IsSent;
          FastBaseHdr.Recv        := Msg^.IsRcvd;
          FastBaseHdr.Priv        := Msg^.IsPriv;
          FastBaseHdr.Delete      := Msg^.IsDeleted;
          FastBaseHdr.KillSent    := Msg^.IsKillSent;
          FastBaseHdr.FileAttach  := Msg^.IsFAttach;
          FastBaseHdr.FileRequest := Msg^.IsFileReq;
          FastBaseHdr.Crash       := Msg^.IsCrash;
          FastBaseHdr.Hold        := Msg^.IsHold;
          Msg^.GetOrig(FastBaseHdr.Orig);
          Msg^.GetDest(FastBaseHdr.Dest);
          FastBase_Yours;
          ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
          REWRITE(FMsgText);
          Msg^.MsgTxtStartUp;
          REPEAT
                MsgText.Line[1] := #32;
                MsgText.Line := NoEsc(Msg^.GetString(80));
                IF (MsgText.Line[1]=#1) THEN
                BEGIN
                     IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN
                     BEGIN
                          ReplyDomain := MsgText.Line;
                          Delete(ReplyDomain,1,8);
                     END;
                     IF ((System_Info.MessageDebug=1) AND (UserRecord.Security>=System_Info.MessageInfo))
                        THEN WRITE(FMsgText,MsgText);
                     IF _Mid(MsgText.Line,2,6)='INTL ' THEN
                     BEGIN
                          Delete(MsgText.Line,1,6);
                          Loop := Pos(' ',MsgText.Line);
                          StringToAddress(_Mid(MsgText.Line,1,Loop-1),FastBaseHdr.Dest);
                          StringToAddress(_Mid(MsgText.Line,Loop+1,LENGTH(MsgText.Line)),FastBaseHdr.Orig);
                     END
                     ELSE IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN
                     BEGIN
                          Delete(MsgText.Line,1,8);
                          IF FastBaseHdr.Orig.Zone=FastBaseHdr.Dest.Zone THEN
                          BEGIN
                               Loop    := Pos(':',MsgText.Line);
                               NewZone := _Numeric(_Mid(MsgText.Line,1,Loop-1));
                               FastBaseHdr.Dest.Zone := NewZone;
                               FastBaseHdr.Orig.Zone := NewZone;
                          END;
                     END
                     ELSE IF _Mid(MsgText.Line,2,6)='FMPT ' THEN
                     BEGIN
                          Delete(MsgText.Line,1,6);
                          FmPt := MsgText.Line;
                     END
                     ELSE IF _Mid(MsgText.Line,2,6)='TOPT ' THEN
                     BEGIN
                          Delete(MsgText.Line,1,6);
                          ToPt := MsgText.Line;
                     END;
                END
                ELSE
                BEGIN
                     IF Pos('SEEN-BY: ',MsgText.Line)=1 THEN
                     BEGIN
                          IF ((System_Info.MessageDebug=1) AND (UserRecord.Security>=System_Info.MessageInfo))
                             THEN WRITE(FMsgText,MsgText);
                     END
                     ELSE WRITE(FMsgText,MsgText);
                END;
          UNTIL Msg^.EOM;
          CLOSE(FMsgText);
          IF (FmPt<>'') THEN FastBaseHdr.Orig.Point := _Numeric(FmPt);
          IF (ToPt<>'') THEN FastBaseHdr.Dest.Point := _Numeric(ToPt);
          IF IsYours THEN
          BEGIN
               Msg^.SetRcvd(True);
               Msg^.ReWriteHdr;
          END;
     END;
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


END.
