{$I DEFINES.INC}
UNIT MsgSrch6;


INTERFACE


PROCEDURE Search_String;


IMPLEMENTATION


USES Globals,Screens,BsLog,Toggle,KeyInput,MiscStr,TagArea,
     GotKeys,MiscMsg,JamGet,ReadNew,MsgHeadr,ChangeMA,MFireUp,
     MkGlobT,MkMsgAbs,MkOpen,Shotgun,BsString;


PROCEDURE Search_String;
VAR  before        : word;
     beforesub     : word;
     found         : boolean;
     temp          : string;
     c             : Char;
     FFMessageArea : File Of _MessageArea_Record;
     Selected      : Word;
     LookingFor    : String;
     MsgText       : MessageTextLines;
     DoIt          : Boolean;
     MsgScan       : AbsMsgPtr;
     Counter       : Longint;
     MaxMsgs       : Word;
     AreaType      : Char;
     LABEL           quit_search,SkipIt,Continue;
BEGIN
     DisplayGraphicFile('SEARCHES',false,True,True);
     c := Get_Menu_Selection('CATSQ',#0);
     IF c='Q' THEN Exit;
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     system_prompt('',183);
     Get_Enter;
     IF Fields^[1].Text='' THEN Exit;
     LookingFor := _UpperCase(Fields^[1].Text);
     found      := false;
     bsWriteLog('Searching for mail search string: '+LookingFor,False);
     System_Prompt('',184);
     ASSIGN(FFMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FFMessageArea);
     StartToggle(FileSize(FFMessageArea));
     CurrentMessageArea := 0;
     REPEAT
           DoToggle;
           READ(FFMessageArea,MessageAreas);
           INC(CurrentMessageArea);
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
                     TotalMessages := MsgScan^.NumberOfMsgs;
                     Counter       := 0;
                     MsgScan^.SeekFirst(1);
                     IF NOT(MsgScan^.SeekFound) THEN MsgScan^.SeekNext;
                     WHILE MsgScan^.SeekFound DO
                     BEGIN
                          INC(Counter);
                          MsgScan^.MsgStartUp;
                          MsgScan^.MsgTxtStartUp;
                          DoIt := False;
                          REPEAT
                                MsgText.Line := MsgScan^.GetString(80);
                                IF Pos(LookingFor,_UpperCase(MsgText.Line))<>0 THEN
                                BEGIN
                                     DoIt := True;
                                     GOTO Continue;
                                END;
                          UNTIL MsgScan^.EOM;
                          Continue:
                          IF DoIt THEN
                          BEGIN
                               CurrentMessage     := Counter;
                               MsgIndex^[Counter] := MsgScan^.GetMsgNum;
                               JamBase_GetMessage(Counter);
                               IF CanSee THEN
                               BEGIN
                                    found := True;
                                    EnteredReply := False;
                                    CASE Read_New_Mail(False) OF
                                    0:   BEGIN
                                              CloseMsgArea(MsgScan);
                                              GOTO quit_search;
                                         END;
                                    2:   BEGIN
                                              System_Prompt('',184);
                                              ToggleInfo.Current := CurrentMessageArea;
                                              RedrawToggle;
                                              CloseMsgArea(MsgScan);
                                              GOTO SkipIt;
                                         END;
                                    END;
                                    System_Prompt('',184);
                                    ToggleInfo.Current := CurrentMessageArea;
                                    RedrawToggle;
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
                   ELSE System_Prompt('',185);
     Get_Enter;
     Header2(BeforeSub,Before,True);
END;


END.
