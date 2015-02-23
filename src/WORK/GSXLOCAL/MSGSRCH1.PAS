{$I DEFINES.INC}
UNIT MsgSrch1;


INTERFACE


PROCEDURE new_mail;


IMPLEMENTATION


USES Globals,Screens,BsLog,Toggle,KeyInput,MiscStr,TagArea,GotKeys,
     MiscMsg,JamGet,ReadNew,MsgHeadr,ChangeMA,MkGlobT,MkOpen,MkMsgAbs,
     Gunshot,BsString;


PROCEDURE new_mail;
VAR  before        : word;
     beforesub     : word;
     found         : boolean;
     temp          : string;
     AliasName     : String;
     RealName      : String;
     c             : Char;
     FFMessageArea : File Of _MessageArea_Record;
     Selected      : Word;
     AreaType      : Char;
     MsgScan       : AbsMsgPtr;
     Counter       : Longint;
     MaxMsgs       : Word;
LABEL                quit_search,SkipIt;
BEGIN
     DisplayGraphicFile('SEARCHES',false,True,True);
     c := Get_Menu_Selection('CATSQ',#0);
     IF c='Q' THEN Exit;
     AliasName  := _UpperCase(UserRecord.Alias);
     RealName   := _UpperCase(UserRecord.Name);
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     found      := false;
     bsWriteLog('Searching for new personal mail',False);
     System_Prompt('',65);
     ASSIGN(FFMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FFMessageArea);
     CurrentMessageArea := 0;
     StartToggle(FileSize(FFMessageArea));
     REPEAT
           READ(FFMessageArea,MessageAreas);
           INC(CurrentMessageArea);
           DoToggle;
           CASE c OF
           'C': IF CurrentMessageArea<>Before THEN GOTO SkipIt;
           'T': IF NOT(IsMsgTagged(MessageAreas.AreaID)) THEN GOTO SkipIt;
           'S': IF CurrentMessageArea<>Selected THEN GOTO SkipIt;
           END;
           IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
              (UserRecord.Security>=MessageAreas.Read_Access)) THEN
           BEGIN
                CASE MessageAreas.Base_Type OF
                1:  AreaType := 'J';
                2:  AreaType := 'S';
                3:  AreaType := 'F';
                END;
                IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                          ELSE MaxMsgs := MessageAreas.MaxMsgs;
                CurrentMessageBase := MessageAreas.Dos_Name;
                IF OpenOrCreateMsgArea(MsgScan,AreaType+CurrentMessageBase,MaxMsgs) THEN
                BEGIN
                     TotalMessages := 1;
                     MsgScan^.SeekFirst(MsgScan^.GetLastRead(UserRecord.Name,UserRecord.User_Number));
                     IF NOT(MsgScan^.SeekFound) THEN MsgScan^.SeekNext;
                     WHILE MsgScan^.SeekFound DO
                     BEGIN
                          MsgScan^.MsgStartUp;
                          IF ItsYours(MsgScan^.GetTo,RealName,AliasName) THEN
                          BEGIN
                               IF NOT(MsgScan^.IsRcvd) THEN
                               BEGIN
                                    MsgIndex^[1] := MsgScan^.GetMsgNum;
                                    JamBase_GetMessage(1);
                                    IF CanSee THEN
                                    BEGIN
                                         found := True;
                                         CASE Read_New_Mail(True) OF
                                         0:   BEGIN
                                                   CloseMsgArea(MsgScan);
                                                   GOTO quit_search;
                                              END;
                                         2:   BEGIN
                                                   System_Prompt('',65);
                                                   ToggleInfo.Current := CurrentMessageArea;
                                                   RedrawToggle;
                                                   CloseMsgArea(MsgScan);
                                                   GOTO SkipIt;
                                              END;
                                         END;
                                         System_Prompt('',65);
                                         ToggleInfo.Current := CurrentMessageArea;
                                         RedrawToggle;
                                    END;
                               END;
                          END;
                          MsgScan^.SeekNext;
                     END;
                     CloseMsgArea(MsgScan);
                END;
                IF CommLookAhead=#27 THEN GOTO Quit_Search;
           END;
           SkipIt:
     UNTIL EOF(FFMessageArea);
     quit_search:
     CLOSE(FFMessageArea);
     EndToggle;
     IF found=True THEN System_Prompt('',66)
                   ELSE System_Prompt('',67);
     Get_Enter;
     Header2(BeforeSub,Before,True);
END;


END.
