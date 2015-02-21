{$I DEFINES.INC}
UNIT ChatFull;


INTERFACE


PROCEDURE FullScreenChat;
PROCEDURE SysopFullChat;


IMPLEMENTATION


USES BsLog,Globals,Screens,ANSIMisc,Crt,QBack,BsMulti,ApPort,Carrier,
     MultNode,Status,KeyInput,ChatMisc,NodeFile,ApTimer,Comm,BsKeys,
     Dos,BsString,BsFile;


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
     WorkLine        : String;
     c               : Char;
     WindowY         : Word;
     UserX           : Word;
     UserY           : Word;
     LeaveChat       : Boolean;
     NodeFile        : String;
     WaitFile        : Text;
     Loop            : Word;
     PrivFile        : String;
     FoundOne        : Boolean;
     CheckFile       : String;
     Code            : Integer;
     DirInfo         : SearchRec;
     FileCheckT      : EventTimer;
LABEL                  NewChannel,JumpIn;
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
     WorkLine                   := '';
     LeaveChat                  := False;
     c                          := CHR(0);
     WindowY                    := 8;
     UserX                      := 19;
     UserY                      := 23;
     PrivateChat                := False;
     NodeFile                   := INTR_Directory+'\CH'+_String(ChatChannel)+'.';
     PrivFile                   := INTR_Directory+'\PV'+_String(ChatChannel)+'.$$$';

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
     NewTimerSecs(FileCheckT,4);
     ASSIGN(FOurMsgRecord,NodeFile+_String(NodeNumber));
     RESET(FOurMsgRecord);
     DisplayGraphicsFile('FULLCHAT',False,False,False,True,False);
     Fore(14);
     GotoXYAnsi(19,23);
     REPEAT
           IF TimerExpired(FileCheckT) THEN
           BEGIN
                IF _FileExists(NODE_Directory+'\PAGE.NOW') THEN
                BEGIN
                     GotoXYAnsi(1,8);
                     CheckIntrNode;
                     DisplayGraphicsFile('FULLCHAT',False,False,False,True,False);
                     FOR Loop := 8 TO 21 DO
                     BEGIN
                          GotoXYAnsi(1,Loop);
                          ClrEolANSI;
                     END;
                     GotoXYAnsi(19,23);
                     Fore(14);
                     WRITEANSI(workline,False,False);
                     GotoXYAnsi(UserX,UserY);
                END;
                NewTimerSecs(FileCheckT,4);
           END;
           {MESSAGES AWAITING!}
           WHILE NOT(EOF(FOurMsgRecord)) DO
           BEGIN
                READ(FOurMsgRecord,MsgRecord2);
                IF MsgRecord2.LastLine='@JOININGCHAT@' THEN
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := True;
                     GotoXYANSI(1,WindowY);
                     Fore(4);
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN WRITEANSI(_PadLeft(MsgRecord2.UserAlias,20)+' has joined in!',False,False)
                             ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+' has joined in!',False,False);
                     END
                     ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+' has joined in!',False,False);
                     INC(WindowY);
                     IF WindowY=22 THEN WindowY := 8;
                     GotoXYANSI(1,WindowY);
                     ClrEOLAnsi;
                     Status_Line;
                END
                ELSE IF MsgRecord2.LastLine='@LEAVINGCHAT@' THEN
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := False;
                     GotoXYANSI(1,WindowY);
                     Fore(4);
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN WRITEANSI(_PadLeft(MsgRecord2.UserAlias,20)+' has left the conversation.',False,False)
                             ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+' has left the conversation.',False,False);
                     END
                     ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+' has left the conversation.',False,False);
                     INC(WindowY);
                     IF WindowY=22 THEN WindowY := 8;
                     GotoXYANSI(1,WindowY);
                     ClrEOLAnsi;
                     Status_Line;
                END
                ELSE
                BEGIN
                     ChattingUsers[MsgRecord2.UserNode] := True;
                     GotoXYANSI(1,WindowY);
                     Fore(8);
                     IF System_Info.Alias_System THEN
                     BEGIN
                          IF MsgRecord2.UserAlias<>''
                             THEN WRITEANSI(_PadLeft(MsgRecord2.UserAlias,20)+': ',False,False)
                             ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+': ',False,False);
                     END
                     ELSE WRITEANSI(_PadLeft(MsgRecord2.UserName,20)+': ',False,False);
                     Fore(7); WRITEANSI(MsgRecord2.LastLine,False,True);
                     INC(WindowY);
                     IF WindowY=22 THEN WindowY := 8;
                     GotoXYANSI(1,WindowY);
                     ClrEOLAnsi;
                     Status_Line;
                END;
           END;
           C := #0;
           IF keypressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     DoSysopPress(C);
                     C := IsTheKeyOk(C,True);
                     IF (C<>#0) THEN GOTO JumpIn;
                END;
           END
           ELSE IF LocalLogon THEN TimeSlice;
           IF NOT(LocalLogon) THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,c);
                     IF ord(c)=0 THEN
                     BEGIN
                          GetChar(BBSPort,c);
                          C := IsTheKeyOk(C,True);
                          IF (C<>#0) THEN GOTO JumpIn;
                     END;
                END
                ELSE CheckForCarrier;
           END;
           IF ORD(c)<>0 THEN
           BEGIN
                Fore(14);
                GotoXYAnsi(UserX,UserY);
                CASE ORD(c) OF
                8:   BEGIN
                          IF LENGTH(workline)=1 THEN
                          BEGIN
                               workline := '';
                               WRITEANSI(#$08+' '+#$08,false,False);
                               DEC(UserX);
                          END
                          ELSE IF LENGTH(workline)>1 THEN
                          BEGIN
                               workline := _Mid(workline,1,LENGTH(workline)-1);
                               WRITEANSI(#$08+' '+#$08,false,False);
                               DEC(UserX);
                          END;
                     END;
                13:  BEGIN
                          IF ((WorkLine='/q') OR (WorkLine='/Q')) THEN
                          BEGIN
                               LeaveChat := True;
                          END
                          ELSE IF ((WorkLine='/p') OR (WorkLine='/P')) THEN
                          BEGIN
                               PageAnotherUser(True);
                               DisplayGraphicsFile('FULLCHAT',False,False,False,True,False);
                               FOR Loop := 8 TO 21 DO
                               BEGIN
                                    GotoXYAnsi(1,Loop);
                                    ClrEolANSI;
                               END;
                               GotoXYAnsi(19,23);
                               Fore(14);
                               WRITEANSI(workline,False,False);
                               GotoXYAnsi(UserX,UserY);
                          END
                          ELSE IF (WorkLine='/!') THEN
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
                               GotoXYANSI(1,WindowY);
                               Fore(3);
                               IF System_Info.Alias_System THEN
                               BEGIN
                                    IF MsgRecord.UserAlias<>''
                                       THEN WRITEANSI(_PadLeft(MsgRecord.UserAlias,20)+': ',False,False)
                                       ELSE WRITEANSI(_PadLeft(MsgRecord.UserName,20)+': ',False,False);
                               END
                               ELSE WRITEANSI(_PadLeft(MsgRecord.UserName,20)+': ',False,False);
                               Fore(11); WRITEANSI(MsgRecord.LastLine,False,True);
                               INC(WindowY);
                               IF WindowY=22 THEN WindowY := 8;
                               GotoXYANSI(1,WindowY);
                               ClrEOLAnsi;
                               Status_Line;
                          END
                          ELSE IF ((WorkLine='/c') OR (WorkLine='/C')) THEN
                          BEGIN
                               bsWriteLog('Changing chat channel',False);
                               GotoXYAnsi(1,UserY);
                               ClrEolANSI;
                               System_Prompt('',125,false,True);
                               Get_Number(3,_String(ChatChannel),False);
                               IF Input_String<>'' THEN
                               BEGIN
                                    VAL(Input_String,Loop,Code);
                                    CheckFile := INTR_Directory+'\PV'+_String(Loop)+'.$$$';
                                    IF _FileExists(CheckFile) THEN
                                    BEGIN
                                         GotoXYAnsi(1,UserY);
                                         ClrEolANSI;
                                         System_Prompt('',164,false,True);
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
                               DisplayGraphicsFile('FULLCHAT',False,False,False,True,False);
                               FOR Loop := 8 TO 21 DO
                               BEGIN
                                    GotoXYAnsi(1,Loop);
                                    ClrEolANSI;
                               END;
                               GotoXYAnsi(19,23);
                               Fore(14);
                               WRITEANSI(workline,False,False);
                               GotoXYAnsi(UserX,UserY);
                          END
                          ELSE IF ((WorkLine='/l') OR (WorkLine='/L')) THEN
                          BEGIN
                               ShowOnlineUsers;
                               DisplayGraphicsFile('FULLCHAT',False,False,False,True,False);
                               FOR Loop := 8 TO 21 DO
                               BEGIN
                                    GotoXYAnsi(1,Loop);
                                    ClrEolANSI;
                               END;
                               GotoXYAnsi(19,23);
                               Fore(14);
                               WRITEANSI(workline,False,False);
                               GotoXYAnsi(UserX,UserY);
                          END
                          ELSE IF WorkLine<>'' THEN
                          BEGIN
                               MsgRecord.LastLine := WorkLine;
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
                               GotoXYANSI(1,WindowY);
                               Fore(3);
                               IF System_Info.Alias_System THEN
                               BEGIN
                                    IF MsgRecord.UserAlias<>''
                                       THEN WRITEANSI(_PadLeft(MsgRecord.UserAlias,20)+': ',False,False)
                                       ELSE WRITEANSI(_PadLeft(MsgRecord.UserName,20)+': ',False,False);
                               END
                               ELSE WRITEANSI(_PadLeft(MsgRecord.UserName,20)+': ',False,False);
                               Fore(11); WRITEANSI(MsgRecord.LastLine,False,True);
                               INC(WindowY);
                               IF WindowY=22 THEN WindowY := 8;
                               GotoXYANSI(1,WindowY);
                               ClrEOLAnsi;
                               Status_Line;
                          END;
                          workline := '';
                          UserX    := 19;
                          UserY    := 23;
                          GotoXYAnsi(UserX,UserY);
                          WRITEANSI('                                                  ',false,False);
                          GotoXYAnsi(UserX,UserY);
                          Fore(14);
                          c := CHR(0);
                     END;
                27:  BEGIN
                          LeaveChat := True;
                     END;
                ELSE BEGIN
                          C := IsTheKeyOk(C,False);
                          IF (C<>#0) THEN
                          BEGIN
                               JumpIn:
                               IF LENGTH(workline)<50 THEN
                               BEGIN
                                    workline := workline+c;
                                    WRITECHAR(c);
                                    INC(UserX);
                               END;
                          END;
                     END;
                END;
                c := Chr(0);
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
END;


PROCEDURE SysopFullChat;
VAR  c           : char;
     prior       : Longint;
     current     : Longint;
     difference  : Longint;
     sysop_key   : char;
     user_key    : char;
     who_last    : byte;
     Loop        : Word;
     SysopX      : Word;
     SysopY      : Word;
     UserX       : Word;
     UserY       : Word;
     OldTime     : Longint;
     OldSysop    : String[30];
     OldAlias    : String[30];
     AllDone     : Boolean;
LABEL              JumpIn1,JumpIn2;

     PROCEDURE NextLineSysop;
     BEGIN
          SendCrLf(1);
          INC(SysopY);
          IF SysopY=12 THEN SysopY := 3;
          SysopX := 1;
          GotoXYANSI(SysopX,SysopY);
          ClrEolANSI;
          IF SysopY=11 THEN
          BEGIN
               GotoXYANSI(1,3);
               ClrEolANSI;
               GotoXYANSI(SysopX,SysopY);
          END
          ELSE
          BEGIN
               GotoXYANSI(1,SysopY+1);
               ClrEolANSI;
               GotoXYANSI(SysopX,SysopY);
          END;
     END;

     PROCEDURE NextLineUser;
     BEGIN
          SendCrLf(1);
          INC(UserY);
          IF UserY=24 THEN UserY := 15;
          UserX := 1;
          GotoXYANSI(UserX,UserY);
          ClrEolANSI;
          IF UserY=23 THEN
          BEGIN
               GotoXYANSI(1,15);
               ClrEolANSI;
               GotoXYANSI(UserX,UserY);
          END
          ELSE
          BEGIN
               GotoXYANSI(1,UserY+1);
               ClrEolANSI;
               GotoXYANSI(UserX,UserY);
          END;
     END;

BEGIN
     bsWriteLog('Chatting with the sysop',False);
     DoNodeActivity(39,'');
     OldTime  := RemainingTimeInSecs(UsersTicker);
     OldSysop := System_Info.Sysop;
     OldAlias := System_Info.Alias;
     GetChatName;
     DisplayGraphicsFile('SYSCHAT',False,False,False,True,False);
     GotoXY(1,3);
     TextColor(7);  WRITE(' Press ');
     TextColor(8);  WRITE('[');
     TextColor(14); WRITE('ESC');
     TextColor(8);  WRITE(']');
     TextColor(7);  WRITE(' To Exit ');
     SysopX := 1;
     SysopY := 4;
     UserX  := 1;
     UserY  := 15;
     Back(0);
     Fore(7);
     GotoXYANSI(SysopX,SysopY);
     who_last := 0;
     AllDone  := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                sysop_key := ReadKey;
                IF ORD(sysop_key)=0 THEN
                BEGIN
                     sysop_key := ReadKey;
                     sysop_key := IsTheKeyOk(sysop_key,True);
                     IF (sysop_key<>#0) THEN
                     BEGIN
                          IF who_last<>2 THEN GotoXYANSI(sysopx,sysopy);
                          who_last := 2;
                          GOTO JumpIn1;
                     END;
                END
                ELSE
                BEGIN
                     IF who_last<>2 THEN GotoXYANSI(sysopx,sysopy);
                     who_last := 2;
                     IF ((sysop_key=' ') AND (SysopX>70)) THEN
                     BEGIN
                          NextLineSysop;
                     END
                     ELSE IF ORD(sysop_key)=13 THEN
                     BEGIN
                          NextLineSysop;
                     END
                     ELSE IF ORD(sysop_key)=27 THEN
                     BEGIN
                          AllDone := True;
                     END
                     ELSE IF ((ORD(sysop_key)=8) AND (SysopX>1)) THEN
                     BEGIN
                          WRITEANSI(#$08+' '+#$08,false,False);
                          DEC(SysopX);
                     END
                     ELSE
                     BEGIN
                          sysop_key := IsTheKeyOk(sysop_key,False);
                          IF (sysop_key<>#0) THEN
                          BEGIN
                               JumpIn1:
                               WRITECHAR(sysop_key);
                               INC(SysopX);
                               IF SysopX=80 THEN NextLineSysop;
                          END;
                     END;
                END;
           END
           ELSE IF LocalLogon THEN TimeSlice;
           IF NOT(LocalLogon) THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,User_Key);
                     IF ord(User_Key)=0 THEN
                     BEGIN
                          GetChar(BBSPort,User_Key);
                          User_Key := IsTheKeyOk(User_Key,True);
                          IF (User_Key<>#0) THEN
                          BEGIN
                               IF who_last<>1 THEN GotoXYANSI(userx,usery);
                               who_last := 1;
                               GOTO JumpIn2;
                          END;
                     END
                     ELSE IF ord(User_Key)=27 THEN
                     BEGIN
                          _Delay(30);
                          ClearInBuffer;
                     END
                     ELSE
                     BEGIN
                          IF who_last<>1 THEN GotoXYANSI(userx,usery);
                          who_last := 1;
                          IF ((user_key=' ') AND (UserX>70)) THEN
                          BEGIN
                               NextLineUser;
                          END
                          ELSE IF ORD(user_key)=13 THEN
                          BEGIN
                               NextLineUser;
                          END
                          ELSE IF ((ORD(user_key)=8) AND (userX>1)) THEN
                          BEGIN
                               WRITEANSI(#$08+' '+#$08,false,False);
                               DEC(userX);
                          END
                          ELSE
                          BEGIN
                               user_key := IsTheKeyOk(user_key,False);
                               IF (user_key<>#0) THEN
                               BEGIN
                                    JumpIn2:
                                    WRITECHAR(user_key);
                                    INC(userX);
                                    IF UserX=80 THEN NextLineUser;
                               END;
                          END;
                     END;
                END
                ELSE CheckForCarrier;
           END;
     UNTIL AllDone;
     NewTimerSecs(UsersTicker,OldTime);
     System_Info.Sysop := OldSysop;
     System_Info.Alias := OldAlias;
END;


END.
