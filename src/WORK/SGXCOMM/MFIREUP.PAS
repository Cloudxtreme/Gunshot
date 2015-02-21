{$I DEFINES.INC}
UNIT MFireUp;


INTERFACE


PROCEDURE JamBase_FireUpMessageBase(FullPath: String);


IMPLEMENTATION


USES Dos,Globals,MkOpen,BsString,ErrorLog,FMode;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Check to see if the base is there.                                }
{      - If it ISN'T, then create it.                                      }
{      - Create the MSG indexes.                                           }
{      - Get the total number of messages.                                 }
{      - Get the user's last read pointer.                                 }
{      - Set the user's last read pointer if its wonky.                    }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_FireUpMessageBase(FullPath: String);
VAR  Loop       : Word;
     Loop2      : Word;
     SearchFile : String[80];
     DirInfo    : SearchRec;
     Work       : Word;
     AreaType   : Char;
     Code       : Integer;
     MaxMsgs    : Word;
BEGIN
     CurrentMessageBase := FullPath;
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     IF NOT(OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs)) THEN
     BEGIN
          TotalMessages := 0;
          UserLastReadMSG := 0;
          Exit;
     END;
     UserLastReadMSG := Msg^.GetLastRead(UserRecord.Name,UserRecord.User_Number);
     IF AreaType='F' THEN
     BEGIN
          {GET ALL THE MESSAGE NAMES}
          Loop := 0;
          FindFirst(CurrentMessageBase+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               SearchFile := _UpperCase(DirInfo.Name);
               INC(Loop);
               VAL(_Mid(SearchFile,1,Pos('.',SearchFile)-1),MsgIndex[Loop],Code);
               IF Loop=3000 THEN DoErrorLog(28,CurrentMessageBase);
               FindNext(DirInfo);
          END;
          TotalMessages := Loop;
          IF Loop=0 THEN
          BEGIN
               UserLastReadMSG := 0;
               Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,0);
               CloseMsgArea(Msg);
               EXIT;
          END;
          {CREATE THE SORTED INDEXES}
          FOR Loop := 1 TO TotalMessages DO
          BEGIN
               FOR Loop2 := 1 TO TotalMessages DO
               BEGIN
                    IF MsgIndex[Loop]<MsgIndex[Loop2] THEN
                    BEGIN
                         Work := MsgIndex[Loop];
                         MsgIndex[Loop] := MsgIndex[Loop2];
                         MsgIndex[Loop2] := Work;
                    END;
               END;
          END;
     END
     ELSE
     BEGIN
          Loop := 0;
          Msg^.SeekFirst(1);
          IF NOT(Msg^.SeekFound) THEN Msg^.SeekNext;
          WHILE Msg^.SeekFound DO
          BEGIN
               Msg^.MsgStartUp;
               INC(Loop);
               MsgIndex[Loop] := Msg^.GetMsgNum;
               IF Loop=3000 THEN DoErrorLog(28,CurrentMessageBase);
               Msg^.SeekNext;
          END;
          TotalMessages := Loop;
          IF Loop=0 THEN
          BEGIN
               TotalMessages   := 0;
               UserLastReadMSG := 0;
               Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,0);
               CloseMsgArea(Msg);
               EXIT;
          END;
     END;
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
     FOR Loop2 := 1 TO TotalMessages DO
     BEGIN
          IF MsgIndex[Loop2]>=UserLastReadMSG THEN
          BEGIN
               IF (MsgIndex[Loop2]<>UserLastReadMSG)
                  THEN Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,MsgIndex[Loop2]);
               UserLastReadMSG := Loop2;
               CloseMsgArea(Msg);
               EXIT;
          END;
     END;
     IF TotalMessages=0 THEN
     BEGIN
          UserLastReadMSG := 1;
          Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,1);
     END
     ELSE IF (UserLastReadMSG>=TotalMessages) THEN
     BEGIN
          UserLastReadMSG := TotalMessages;
          IF (UserLastReadMSG<>TotalMessages)
             THEN Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,MsgIndex[TotalMessages]);
     END
     ELSE
     BEGIN
          UserLastReadMSG := 1;
          Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,1);
     END;
     CloseMsgArea(Msg);
END;


END.