{$I DEFINES.INC}
UNIT LstReads;


INTERFACE


PROCEDURE JamBase_SetLastRead           (Number: Longint);
PROCEDURE JamBase_ResetLastRead         (FullPath: String);
PROCEDURE JamBase_ZeroLastRead          (FullPath: String);


IMPLEMENTATION


USES Globals,MkOpen,MkMsgAbs,FMode;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Blindly set the last read pointer for the user at 'number'.       }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_SetLastRead(Number: Longint);
VAR  AreaType : Char;
     MaxMsgs  : Word;
BEGIN
     IF Number>TotalMessages THEN Number := TotalMessages;
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     IF Number<>0 THEN Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,MsgIndex[Number])
                  ELSE Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,0);
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;
{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Set the last read to the last message.                            }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_ResetLastRead(FullPath: String);
VAR  AreaType    : Char;
     MaxMsgs     : Word;
BEGIN
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+FullPath,MaxMsgs);
     Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,Msg^.GetHighMsgNum);
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;
{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Set the last read to the first message.                           }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_ZeroLastRead(FullPath: String);
VAR  AreaType    : Char;
     HighMessage : Word;
     MaxMsgs     : Word;
BEGIN
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+FullPath,MaxMsgs);
     Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,0);
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


END.