{$I DEFINES.INC}
UNIT ChatFull;


INTERFACE


PROCEDURE FullScreenChat;


IMPLEMENTATION


USES BsLog,Globals,Screens,Crt,QBack,BsMulti,MultNode,_Pick,
     Status,KeyInput,NodeFile,ApTimer,AllGone,Time,_Save,Gr2_Bp,
     _BHandle,_Fields,_Mouse,Dos,BsFile,BsString,BsKeys;


FUNCTION GoodKey(InChar: Char): Boolean;
VAR  AnyGood : Boolean;
BEGIN
     AnyGood := False;
     IF ((Ord(InChar)>31) AND (Ord(InChar)<128)) THEN AnyGood := True;
     GoodKey := AnyGood;
END;


PROCEDURE FullScreenChat;
TYPE MessageRecord = RECORD
     UserName      : String[20];
     UserAlias     : String[20];
     UserNode      : Word;
     LastLine      : String[50];
     END;
VAR  MsgRecord       : MessageRecord;
     MsgRecord2      : MessageRecord;
     FMsgRecord      : File Of MessageRecord;
     FOurMsgRecord   : File Of MessageRecord;
     c               : Char;
     LeaveChat       : Boolean;
     NodeFile        : String;
     WaitFile        : Text;
     Loop            : Word;
     PrivFile        : String;
     FoundOne        : Boolean;
     CheckFile       : String;
     Temp            : String;
     TimerInfo       : EventTimer;
     Code            : Integer;
     DirInfo         : SearchRec;
LABEL                  NewChannel,ChangeTheChannel;

     PROCEDURE ReturnToNormal;
     BEGIN
          LoadCurrentWindow('CHAT');
          DisplayGraphicFile('FULLCHAT',True,True,True);
          PickInfo.Active := True;
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
     END;

     PROCEDURE DoPrivate;
     VAR  Loop2 : Word;
     BEGIN
          IF _FileExists(PrivFile) THEN
          BEGIN
               _EraseFile(PrivFile);
               PrivateChat := False;
               MsgRecord.LastLine := 'This chat is no longer private.';
          END
          ELSE
          BEGIN
               ASSIGN(FMsgRecord,PrivFile);
               REWRITE(FMsgRecord);
               WRITE(FMsgRecord,MsgRecord);
               CLOSE(FMsgRecord);
               PrivateChat := True;
               MsgRecord.LastLine := 'This chat is now private.';
          END;
          FOR Loop2 := 1 TO 255 DO
          BEGIN
               IF ((Loop2<>NodeNumber) AND (ChattingUsers[Loop2]=True)) THEN
               BEGIN
                    IF _FileExists(NodeFile+_String(Loop2)) THEN
                    BEGIN
                         ASSIGN(FMsgRecord,NodeFile+_String(Loop2));
                         RESET(FMsgRecord);
                         SEEK(FMsgRecord,FileSize(FMsgRecord));
                         WRITE(FMsgRecord,MsgRecord);
                         CLOSE(FMsgRecord);
                    END
                    ELSE ChattingUsers[Loop2] := False;
               END;
          END;
          Temp := '{9}';
          IF System_Info.Alias_System THEN
          BEGIN
               IF MsgRecord.UserAlias<>''
                  THEN Temp := Temp+_PadLeft(MsgRecord.UserAlias,20)+': '
                  ELSE Temp := Temp+_PadLeft(MsgRecord.UserName,20)+': ';
          END
          ELSE Temp := Temp+_PadLeft(MsgRecord.UserName,20)+': ';
          Temp := Temp+'{1}'+MsgRecord.LastLine;
          AppendToPickList(Temp);
     END;

     PROCEDURE InsertChatCommands;
     VAR  TFile : Text;
     BEGIN
          ASSIGN(TFile,SGDirectory+'\FULLCHAT.TXT');
          RESET(TFile);
          REPEAT
                READLN(TFile,Temp);
                AddToPickList(Temp,0,False);
          UNTIL EOF(TFile);
          CLOSE(TFile);
     END;

     FUNCTION GetAKeyPress: Char;
     VAR  cc : char;
     BEGIN
          cc := chr(0);
          IF TimerExpired(TimerInfo) THEN
          BEGIN
               IF NOT(NodeInfo^.NoTimeout) THEN dispatch(4);
          END;
          TimeLimit;
          cc := ButtonHandler;
          IF keypressed THEN
          BEGIN
               NewTimerSecs(TimerInfo,system_info.Sys_Idle);
               cc := ReadKey;
               IF ORD(cc)=0 THEN
               BEGIN
                    cc := ReadKey;
                    DoSysopPress(cc);
                    IF HandleKeys(cc,True)
                       THEN cc := Chr(0)
                       ELSE cc := _AltToNormal(cc);
               END
               ELSE IF HandleKeys(cc,False) THEN cc := Chr(0);
          END
          ELSE TimeSlice;
          GetAKeyPress := cc;
     END;

BEGIN
     bsWriteLog('Entering multinode chat',False);
     ChatChannel := 1;
     FoundOne    := False;
     REPEAT
           PrivFile := INTR_Directory+'\PV'+_String(ChatChannel)+'.$$$';
           IF _FileExists(PrivFile) THEN INC(ChatChannel)
                                    ELSE FoundOne := True;
     UNTIL FoundOne;
     NewChannel:
     MsgRecord.UserName         := _Mid(UserRecord.Name,1,20);
     MsgRecord.UserAlias        := _Mid(UserRecord.Alias,1,20);
     MsgRecord.LastLine         := '';
     MsgRecord.UserNode         := NodeNumber;
     LeaveChat                  := False;
     c                          := CHR(0);
     PrivateChat                := False;
     NodeFile                   := INTR_Directory+'\CH'+_String(ChatChannel)+'.';
     PrivFile                   := INTR_Directory+'\PV'+_String(ChatChannel)+'.$$$';
     Fields^[1].Text            := '';

     {START OUR MESSAGE FILE}
     ASSIGN(FOurMsgRecord,NodeFile+_String(NodeNumber));
     REWRITE(FOurMsgRecord);
     CLOSE(FOurMsgRecord);

     {FIND OTHER GUYS IN THE CHAT AND LET THEM KNOW YOU ARE HERE!}
     FillChar(ChattingUsers,SizeOf(ChattingUsers),0);
     ChattingUsers[NodeNumber] := True;
     FindFirst(NodeFile+'*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          Loop := _Numeric(_GetFileExtension(DirInfo.Name));
          IF (Loop<>NodeNumber) THEN
          BEGIN
               IF ((Loop>0) AND (Loop<256)) THEN
               BEGIN
                    ChattingUsers[Loop] := True;
                    MsgRecord.LastLine  := '@JOININGCHAT@';
                    ASSIGN(FMsgRecord,NodeFile+_String(Loop));
                    RESET(FMsgRecord);
                    SEEK(FMsgRecord,FileSize(FMsgRecord));
                    WRITE(FMsgRecord,MsgRecord);
                    CLOSE(FMsgRecord);
               END;
          END;
          FindNext(DirInfo);
     END;
     ASSIGN(FOurMsgRecord,NodeFile+_String(NodeNumber));
     RESET(FOurMsgRecord);
     DisplayGraphicFile('FULLCHAT',False,True,True);
     NewPickList(False);
     PickInfo.Current := 0;
     IF _FileExists(SGDirectory+'\FULLCHAT.TXT') THEN InsertChatCommands;
     HideTheMouse;
     BeginPickList;
     SetUpPickList;
     ShowTheMouse;
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     REPEAT
           C := GetAKeyPress;
           IF ORD(c)<>0 THEN
           BEGIN
                CASE ORD(c) OF
                13:  BEGIN
                          IF _UpperCase(Fields^[1].Text)='/Q' THEN
                          BEGIN
                               LeaveChat := True;
                          END
                          ELSE IF _UpperCase(Fields^[1].Text)='/P' THEN
                          BEGIN
                               SaveCurrentWindow('CHAT');
                               PageAnotherUser;
                               ReturnToNormal;
                          END
                          ELSE IF Fields^[1].Text='/!' THEN
                          BEGIN
                               DoPrivate;
                          END
                          ELSE IF _UpperCase(Fields^[1].Text)='/C' THEN
                          BEGIN
                               ChangeTheChannel:
                               bsWriteLog('Changing chat channel',False);
                               SaveCurrentWindow('CHAT');
                               System_Prompt('',125);
                               FieldText(1,_String(ChatChannel));
                               HideTheMouse;
                               DrawFields;
                               ShowTheMouse;
                               Get_Enter;
                               IF Fields^[1].Text<>'' THEN
                               BEGIN
                                    VAL(Fields^[1].Text,Loop,Code);
                                    CheckFile := INTR_Directory+'\PV'+_String(Loop)+'.$$$';
                                    IF _FileExists(CheckFile) THEN
                                    BEGIN
                                         System_Prompt('',164);
                                         Get_Enter;
                                    END
                                    ELSE IF Loop<>ChatChannel THEN
                                    BEGIN
                                         CLOSE(FOurMsgRecord);
                                         _EraseFile(NodeFile+_String(NodeNumber));
                                         ChatChannel := Loop;
                                         FOR Loop := 1 TO 255 DO
                                         BEGIN
                                              IF ((Loop<>NodeNumber) AND (ChattingUsers[Loop]=True)) THEN
                                              BEGIN
                                                   MsgRecord.LastLine  := '@LEAVINGCHAT@';
                                                   ASSIGN(FMsgRecord,NodeFile+_String(Loop));
                                                   RESET(FMsgRecord);
                                                   SEEK(FMsgRecord,FileSize(FMsgRecord));
                                                   WRITE(FMsgRecord,MsgRecord);
                                                   CLOSE(FMsgRecord);
                                              END;
                                         END;
                                         PrivateChat := False;
                                         IF _FileExists(PrivFile) THEN
                                         BEGIN
                                              FOR Loop := 1 TO 255 DO
                                              BEGIN
                                                   IF _FileExists(NodeFile+_String(Loop))
                                                      THEN PrivateChat := True;
                                              END;
                                              IF Not(PrivateChat) THEN _EraseFile(PrivFile);
                                         END;
                                         PrivateChat := False;
                                         GOTO NewChannel;
                                    END;
                               END;
                               ReturnToNormal;
                          END
                          ELSE IF _UpperCase(Fields^[1].Text)='/L' THEN
                          BEGIN
                               SaveCurrentWindow('CHAT');
                               ShowOnlineUsers;
                               ReturnToNormal;
                          END
                          ELSE IF Fields^[1].Text<>'' THEN
                          BEGIN
                               MsgRecord.LastLine := Fields^[1].Text;
                               FOR Loop := 1 TO 255 DO
                               BEGIN
                                    IF ((Loop<>NodeNumber) AND (ChattingUsers[Loop]=True)) THEN
                                    BEGIN
                                         IF _FileExists(NodeFile+_String(Loop)) THEN
                                         BEGIN
                                              ASSIGN(FMsgRecord,NodeFile+_String(Loop));
                                              RESET(FMsgRecord);
                                              SEEK(FMsgRecord,FileSize(FMsgRecord));
                                              WRITE(FMsgRecord,MsgRecord);
                                              CLOSE(FMsgRecord);
                                         END
                                         ELSE ChattingUsers[Loop] := False;
                                    END;
                               END;
                               Temp := '{9}';
                               IF System_Info.Alias_System THEN
                               BEGIN
                                    IF MsgRecord.UserAlias<>''
                                       THEN Temp := Temp+_PadLeft(MsgRecord.UserAlias,20)+': '
                                       ELSE Temp := Temp+_PadLeft(MsgRecord.UserName,20)+': ';
                               END
                               ELSE Temp := Temp+_PadLeft(MsgRecord.UserName,20)+': ';
                               Temp := Temp+'{1}'+MsgRecord.LastLine;
                               AppendToPickList(Temp);
                          END;
                          FieldText(1,'');
                          HideTheMouse;
                          DrawFields;
                          ShowTheMouse;
                     END;
                49:  DoPrivate;
                67:  GOTO ChangeTheChannel;
                76:  BEGIN
                          SaveCurrentWindow('CHAT');
                          ShowOnlineUsers;
                          ReturnToNormal;
                     END;
                80:  BEGIN
                          SaveCurrentWindow('CHAT');
                          PageAnotherUser;
                          ReturnToNormal;
                     END;
                27,
                81:  LeaveChat := True;
                END;
           END;
           IF _FileExists(NODE_Directory+'\PAGE.NOW') THEN
           BEGIN
                SaveCurrentWindow('CHAT');
                CheckIntrNode;
                ReturnToNormal;
           END;
           {MESSAGES AWAITING!}
           WHILE NOT(EOF(FOurMsgRecord)) DO
           BEGIN
                READ(FOurMsgRecord,MsgRecord2);
                IF MsgRecord2.LastLine='@JOININGCHAT@' THEN
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := True;
                     Temp := '{4}';
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN Temp := Temp+_PadLeft(MsgRecord2.UserAlias,20)+' has joined in!'
                             ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+' has joined in!';
                     END
                     ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+' has joined in!';
                     AppendToPickList(Temp);
                END
                ELSE IF MsgRecord2.LastLine='@LEAVINGCHAT@' THEN
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := False;
                     Temp := '{4}';
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN Temp := Temp+_PadLeft(MsgRecord2.UserAlias,20)+' has left the conversation.'
                             ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+' has left the conversation.';
                     END
                     ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+' has left the conversation.';
                     AppendToPickList(Temp);
                END
                ELSE
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := True;
                     Temp := '{8}';
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN Temp := Temp+_PadLeft(MsgRecord2.UserAlias,20)+': '
                             ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+': ';
                     END
                     ELSE Temp := Temp+_PadLeft(MsgRecord2.UserName,20)+': ';
                     Temp := Temp+'{0}'+MsgRecord2.LastLine;
                     AppendToPickList(Temp);
                END;
           END;
     UNTIL LeaveChat;
     CLOSE(FOurMsgRecord);
     _EraseFile(NodeFile+_String(NodeNumber));
     PrivateChat := False;
     IF _FileExists(PrivFile) THEN
     BEGIN
          FOR Loop := 1 TO 255 DO
          BEGIN
               IF _FileExists(NodeFile+_String(Loop)) THEN PrivateChat := True;
          END;
          IF Not(PrivateChat) THEN _EraseFile(PrivFile);
     END;
     FOR Loop := 1 TO 255 DO
     BEGIN
          IF ((Loop<>NodeNumber) AND (ChattingUsers[Loop]=True)) THEN
          BEGIN
               MsgRecord.LastLine  := '@LEAVINGCHAT@';
               ASSIGN(FMsgRecord,NodeFile+_String(Loop));
               {$I-}RESET(FMsgRecord);{$I+}
               IF IOResult=0 THEN
               BEGIN
                    SEEK(FMsgRecord,FileSize(FMsgRecord));
                    WRITE(FMsgRecord,MsgRecord);
                    CLOSE(FMsgRecord);
               END;
          END;
     END;
     KillPickList;
END;


END.
