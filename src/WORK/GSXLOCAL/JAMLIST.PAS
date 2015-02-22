{$I DEFINES.INC}
UNIT JamList;


INTERFACE


FUNCTION  JamBase_ListMessages2: Boolean;
PROCEDURE JamBase_ListMessages;


IMPLEMENTATION


USES Globals,MkOpen,MkMsgAbs,BsString,MiscMsg,FMode;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Read all the messages in a base and make a list file of           }
{        various message attributes. Contains a starting point.            }
{                                                                          }
{==========================================================================}
FUNCTION JamBase_ListMessages2: Boolean;
VAR  AreaType    : Char;
     Loop        : Word;
     MaxMsgs     : Word;
     AreThere    : Boolean;
BEGIN
     AreThere := False;
     ASSIGN(FMsgList,NODE_Directory+'\MSGLIST.$$$');
     REWRITE(FMsgList);
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+MessageAreas.Dos_Name,MaxMsgs);
     Msg^.SeekFirst(1);
     IF NOT(Msg^.SeekFound) THEN Msg^.SeekNext;
     Loop := 1;
     WHILE Msg^.SeekFound DO
     BEGIN
          Msg^.MsgStartUp;
          FastBaseHdr.MsgFrom := _Mid(Msg^.GetFrom,1,30);
          FastBaseHdr.MsgTo   := _Mid(Msg^.GetTo,1,30);
          FastBase_Yours;
          IF IsYours THEN
          BEGIN
               MsgList.MsgFrom     := FastBaseHdr.MsgFrom;
               MsgList.MsgTo       := FastBaseHdr.MsgTo;
               MsgList.MsgSubject  := _Mid(Msg^.GetSubj,1,30);
               MsgList.MsgPrivate  := Msg^.IsPriv;
               MsgList.MsgRecv     := Msg^.IsRcvd;
               MsgList.MsgNum      := Loop;
               FastBaseHdr.Priv    := MsgList.MsgPrivate;
               MsgIndex^[Loop]     := Msg^.GetMsgNum;
               IF CanSee THEN
               BEGIN
                    WRITE(FMsgList,MsgList);
                    AreThere := True;
               END;
          END;
          Msg^.SeekNext;
          INC(Loop);
     END;
     CloseMsgArea(Msg);
     CLOSE(FMsgList);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
     CurrentMessageBase := MessageAreas.Dos_Name;
     TotalMessages      := Loop-1;
     JamBase_ListMessages2 := AreThere;
END;
{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Read all the messages in a base and make a list file of           }
{        various message attributes.                                       }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_ListMessages;
VAR  AreaType    : Char;
     Loop        : Word;
     MaxMsgs     : Word;
BEGIN
     ASSIGN(FMsgList,NODE_Directory+'\MSGLIST.$$$');
     REWRITE(FMsgList);
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     Msg^.SeekFirst(1);
     Loop := 1;
     WHILE Msg^.SeekFound DO
     BEGIN
          Msg^.MsgStartUp;
          MsgList.MsgFrom     := _Mid(Msg^.GetFrom,1,30);
          MsgList.MsgTo       := _Mid(Msg^.GetTo,1,30);
          MsgList.MsgSubject  := _Mid(Msg^.GetSubj,1,30);
          MsgList.MsgPrivate  := Msg^.IsPriv;
          MsgList.MsgRecv     := Msg^.IsRcvd;
          MsgList.MsgNum      := Loop;
          FastBaseHdr.MsgFrom := MsgList.MsgFrom;
          FastBaseHdr.MsgTo   := MsgList.MsgTo;
          FastBaseHdr.Priv    := MsgList.MsgPrivate;
          FastBase_Yours;
          IF CanSee THEN WRITE(FMsgList,MsgList);
          Msg^.SeekNext;
          INC(Loop);
     END;
     CloseMsgArea(Msg);
     CLOSE(FMsgList);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


END.
