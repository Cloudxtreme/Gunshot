{$I DEFINES.INC}
UNIT MsgKill;


INTERFACE


FUNCTION  JamBase_KillOld: Boolean;
PROCEDURE JamBase_DeleteMessage(Number: Longint);


IMPLEMENTATION


USES Globals,MkOpen,MkMsgAbs,MiscMsg,FMode,BsFile,BsString;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Erase the message from the header and text files.                 }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_DeleteMessage(Number: Longint);
VAR  AreaType : Char;
     MaxMsgs  : Word;
BEGIN
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF AreaType='F' THEN
     BEGIN
          _EraseFile(CurrentMessageBase+_String(MsgIndex[Number])+'.MSG');
     END
     ELSE
     BEGIN
          IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                    ELSE MaxMsgs := MessageAreas.MaxMsgs;
          OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
          Msg^.SeekFirst(MsgIndex[Number]);
          IF Msg^.SeekFound THEN
          BEGIN
               Msg^.MsgStartUp;
               Msg^.DeleteMsg;
          END;
          CloseMsgArea(Msg);
     END;
END;


FUNCTION JamBase_KillOld: Boolean;
VAR  DidAny   : Boolean;
     AreaType : Char;
     MaxMsgs  : Word;
BEGIN
     DidAny := False;
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     Msg^.SeekFirst(1);
     WHILE Msg^.SeekFound DO
     BEGIN
          Msg^.MsgStartUp;
          FastBaseHdr.MsgFrom     := Msg^.GetFrom;
          FastBaseHdr.MsgTo       := Msg^.GetTo;
          FastBaseHdr.Recv        := Msg^.IsRcvd;
          FastBase_Yours;
          IF ((IsYours) AND (FastBaseHdr.Recv)) THEN
          BEGIN
               Msg^.DeleteMsg;
               DidAny := True;
          END;
          Msg^.SeekNext;
     END;
     CloseMsgArea(Msg);
     JamBase_KillOld := DidAny;
END;


END.