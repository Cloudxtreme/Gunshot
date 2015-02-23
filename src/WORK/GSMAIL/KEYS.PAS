{$I DEFINES.INC}
UNIT Keys;


INTERFACE


USES Gunshot;


PROCEDURE ChangeCurrentAKA;
PROCEDURE EditSessionQueue;
PROCEDURE SelectedAName   (InString: String; VAR TheAka: AddrType);
PROCEDURE SelectedANode   (InAddress: AddrType; VAR TheAka : AddrType);
PROCEDURE GetAnAddress    (Title,Stuff: String; VAR TheAka: AddrType);
FUNCTION  GetFileRequests (Title: String; NodeAddr: AddrType; IsTransmit: Boolean) : Boolean;
FUNCTION  InTheBook       (TheName: String)                                        : Boolean;
FUNCTION  HandleLocalKeyPresses                                                    : Char;
FUNCTION  GetAQuicky                                                               : Boolean;


IMPLEMENTATION


USES Globals,FastW1,BsMulti,Crt,SaveScrn,DrawScrn,Comm,Scan,Sema,
     Editor,ApTimer,Transfer,BsLog,FaxEdit,BsExec,FireUp,Info,ApPort,
     NList,Terminal,Misc,ApCom,Saver,BusyFile,MHistory,MkFFile,FMode,
     BsAkas,BsString,BsFile,BsKeys,BsCom,Dos,BsVideo,UnDial,Queue;


FUNCTION InTheBook(TheName: String): Boolean;
BEGIN
     TheName := _UpperCase(TheName);
     IF _FileExists(Gunshot_Directory+'\DATA\PBOOK.DAT') THEN
     BEGIN
          ASSIGN(FPhoneBook,Gunshot_Directory+'\DATA\PBOOK.DAT');
          RESET(FPhoneBook);
          REPEAT
                READ(FPhoneBook,PhoneBook);
                IF _UpperCase(PhoneBook.UserName)=TheName THEN
                BEGIN
                     CLOSE(FPhoneBook);
                     InTheBook := True;
                     Exit;
                END;
          UNTIL EOF(FPhoneBook);
          CLOSE(FPhoneBook);
     END;
     InTheBook := False;
END;


PROCEDURE DisplayTheNode(TheAka: AddrType);
CONST Flags : Array[0..7] Of String[48] = (
      'None/Unknown',
      'Bark and WaZOO file/update requests',
      'Bark file/update requests, WaZOO file requests',
      'Bark file requests, WaZOO file file/update',
      'Bark file/update requests',
      'Bark and WaZOO file requests',
      'WaZOO file requests',
      'WaZOO file/update requests');
VAR   Temp      : String;
      C         : Char;
      ReqMethod : Byte;

      PROCEDURE LoadItUp;
      VAR  BytesRead : Word;
           NodeIndx  : _NodeIndx_Sg;
      BEGIN
           IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
           BEGIN
             REPEAT
               FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
               IF (BytesRead<>0) THEN
               BEGIN
                 IF AkasMatch(NodeIndx.Aka,TheAka) THEN
                 BEGIN
                   FNodeIndx.CloseFile;
                   LoadFromNodeList(NodeIndx.ByteOffSet);
                   Exit;
                 END;
               END;
             UNTIL BytesRead=0;
             FNodeIndx.CloseFile;
           END;
      END;

BEGIN
     SaveScreen(2);
     LoadItUp;
     DrawWindow(10,6,70,18,AddressToString(NodeListAka),True);
     FastWrite('         System:',8,13,GunshotColours.GSMailWindowText);
     FastWrite('          Sysop:',9,13,GunshotColours.GSMailWindowText);
     FastWrite('       Location:',10,13,GunshotColours.GSMailWindowText);
     FastWrite('          Phone:',11,13,GunshotColours.GSMailWindowText);
     FastWrite('           Baud:',12,13,GunshotColours.GSMailWindowText);
     FastWrite('          Flags:',13,13,GunshotColours.GSMailWindowText);
     FastWrite('Continuous Mail:',14,13,GunshotColours.GSMailWindowText);
     FastWrite('      Mail Only:',15,13,GunshotColours.GSMailWindowText);
     FastWrite('  File Requests:',16,13,GunshotColours.GSMailWindowText);
     FastWrite(NodeListSystem,8,31,GunshotColours.GSMailWindowHighlight);
     FastWrite(NodeListSysop,9,31,GunshotColours.GSMailWindowHighlight);
     FastWrite(NodeListLocation,10,31,GunshotColours.GSMailWindowHighlight);
     FastWrite(NodeListPhone,11,31,GunshotColours.GSMailWindowHighlight);
     FastWrite(_String(NodeListBaud),12,31,GunshotColours.GSMailWindowHighlight);
     FastWrite(NodeListFlags,13,31,GunshotColours.GSMailWindowHighlight);
     IF (Pos('CM',NodeListFlags)<>0) THEN Temp := 'Yes' ELSE Temp := 'No';
     FastWrite(Temp,14,31,GunshotColours.GSMailWindowHighlight);
     IF (Pos('MO',NodeListFlags)<>0) THEN Temp := 'Yes' ELSE Temp := 'No';
     FastWrite(Temp,15,31,GunshotColours.GSMailWindowHighlight);
     ReqMethod := 0;
     IF (Pos('XA',NodeListFlags)<>0) THEN ReqMethod := 1;
     IF (Pos('XB',NodeListFlags)<>0) THEN ReqMethod := 2;
     IF (Pos('XC',NodeListFlags)<>0) THEN ReqMethod := 3;
     IF (Pos('XP',NodeListFlags)<>0) THEN ReqMethod := 4;
     IF (Pos('XR',NodeListFlags)<>0) THEN ReqMethod := 5;
     IF (Pos('XW',NodeListFlags)<>0) THEN ReqMethod := 6;
     IF (Pos('XX',NodeListFlags)<>0) THEN ReqMethod := 7;
     FastWrite(Flags[ReqMethod],16,31,GunshotColours.GSMailWindowHighlight);
     C := #0;
     REPEAT
       IF KeyPressed THEN
       BEGIN
         C := ReadKey;
         CASE C OF
         #27,#32,#13,#9: ;
         #0:  BEGIN
                C := ReadKey;
                IF (C<>#15) THEN C := #0;
              END;
         ELSE C := #0;
         END;
       END;
     UNTIL (C<>#0);
     RestoreScreen(2);
END;


PROCEDURE SelectedAName(InString: String; VAR TheAka: AddrType);
TYPE Pick_List  = RECORD
     Text       : String[75];
     END;
VAR  TempIndex  : Longint;
     Temp       : String;
     NodeRec    : AddrType;
     FNodeRec   : File Of AddrType;
     Code       : Integer;
     OldXY      : Word;
     PickList   : Pick_List;
     FPickList  : File Of Pick_List;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Work1      : Integer;
     BytesRead  : Word;
     UserList   : _UserList_Sg;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  Loop : Word;
          ToDo : Word;
     BEGIN
          TheOne  := Top-1;
          SEEK(FPickList,Top-1);
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR Loop := (YYPos+1) TO ToDo DO
          BEGIN
               IF NOT(EOF(FPickList)) THEN
               BEGIN
                    READ(FPickList,PickList);
                    INC(TheOne);
                    IF TheOne=Current THEN FastWrite(PickList.Text,Loop,3,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(PickList.Text,Loop,3,GunshotColours.GSMailWindowText);
               END;
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     InString := _UpperCase(InString);
     NumItems := 0;
     ASSIGN(FPickList,MailerInfo.OutPkts+'PICKLIST.$$$');
     ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
     REWRITE(FNodeRec);
     REWRITE(FPickList);
     IF FUserList.OpenFile(MailerInfo.NodeList+'USERLIST.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FUserList.BlkRead(UserList,SizeOf(UserList),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF (Pos(InString,UserList.SysopName)<>0) THEN
           BEGIN
             LoadFromNodeList(UserList.ByteOffSet);
             PickList.Text := ' '+_PadRight(NodeListSysop,24)+
                              _PadRight(AddressToString(NodelistAka),20)+
                              _PadRight(NodeListSystem,30);
             NodeRec := NodeListAka;
             INC(NumItems);
             WRITE(FPickList,PickList);
             WRITE(FNodeRec,NodeRec);
           END;
         END;
       UNTIL BytesRead=0;
       FUserList.CloseFile;
     END;
     CLOSE(FNodeRec);
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Tab or "?" for information',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Tab or "?" for information',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF ((C='?') OR (C=#9)) THEN
                BEGIN
                     IF _FileExists(MailerInfo.NodeList+'USERLIST.SG') THEN
                     BEGIN
                          ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
                          RESET(FNodeRec);
                          SEEK(FNodeRec,Current-1);
                          READ(FNodeRec,NodeRec);
                          CLOSE(FNodeRec);
                          DisplayTheNode(NodeRec);
                     END;
                END
                ELSE IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C=#13) OR (C=#27));
     CLOSE(FPickList);
     ERASE(FPickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     IF C=#13 THEN
     BEGIN
          ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
          RESET(FNodeRec);
          SEEK(FNodeRec,Current-1);
          READ(FNodeRec,NodeRec);
          CLOSE(FNodeRec);
          ERASE(FNodeRec);
          TheAka := NodeRec;
     END
     ELSE FillChar(TheAka,SizeOf(TheAka),0);
END;


PROCEDURE SelectedANode(InAddress: AddrType; VAR TheAka : AddrType);
TYPE Pick_List  = RECORD
     Text       : String[75];
     END;
VAR  Temp       : String;
     NodeRec    : AddrType;
     FNodeRec   : File Of AddrType;
     Code       : Integer;
     OldXY      : Word;
     PickList   : Pick_List;
     FPickList  : File Of Pick_List;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Work1      : Integer;
     BytesRead  : Word;
     NodeIndx   : _NodeIndx_Sg;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  Loop : Word;
          ToDo : Word;
     BEGIN
          TheOne  := Top-1;
          SEEK(FPickList,Top-1);
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR Loop := (YYPos+1) TO ToDo DO
          BEGIN
               IF NOT(EOF(FPickList)) THEN
               BEGIN
                    READ(FPickList,PickList);
                    INC(TheOne);
                    IF TheOne=Current THEN FastWrite(PickList.Text,Loop,3,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(PickList.Text,Loop,3,GunshotColours.GSMailWindowText);
               END;
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     NumItems := 0;
     ASSIGN(FPickList,MailerInfo.OutPkts+'PICKLIST.$$$');
     ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
     REWRITE(FNodeRec);
     REWRITE(FPickList);
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF ((NodeIndx.Aka.Net=InAddress.Net) AND (NodeIndx.Aka.Zone=InAddress.Zone)) THEN
           BEGIN
             LoadFromNodeList(NodeIndx.ByteOffSet);
             PickList.Text := ' '+_PadRight(NodeListSysop,24)+
                              _PadRight(AddressToString(NodeListAka),20)+
                              _PadRight(NodeListSystem,30);
             NodeRec := NodelistAka;
             INC(NumItems);
             WRITE(FPickList,PickList);
             WRITE(FNodeRec,NodeRec);
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
     CLOSE(FNodeRec);
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Tab or "?" for information',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Tab or "?" for information',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF ((C='?') OR (C=#9)) THEN
                BEGIN
                     IF _FileExists(MailerInfo.NodeList+'USERLIST.SG') THEN
                     BEGIN
                          ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
                          RESET(FNodeRec);
                          SEEK(FNodeRec,Current-1);
                          READ(FNodeRec,NodeRec);
                          CLOSE(FNodeRec);
                          DisplayTheNode(NodeRec);
                     END;
                END
                ELSE IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C=#13) OR (C=#27));
     CLOSE(FPickList);
     ERASE(FPickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     IF C=#13 THEN
     BEGIN
          ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
          RESET(FNodeRec);
          SEEK(FNodeRec,Current-1);
          READ(FNodeRec,NodeRec);
          CLOSE(FNodeRec);
          ERASE(FNodeRec);
          TheAka := NodeRec;
     END
     ELSE FillChar(TheAka,SizeOf(TheAka),0);
END;


FUNCTION HandleLocalKeyPresses: Char;
VAR  C         : Char;
     Ch        : Char;
     Current   : Byte;
     TheMenu   : Array[1..19] Of String[25];
     Loop      : Byte;
     TheAttr   : Word;
     OldXY     : Word;
     Crap      : Char;
     TopLine   : Word;
     TheOne    : Char;
     Temp      : String;
     Blubber   : Boolean;
LABEL            AltA,AltB,AltC,AltE,AltF,AltG,AltH,AltI,AltJ,AltL,AltP,AltX,AltR,AltS,AltT,AltU,AltV,Question;
LABEL            ToTheMenu,ToTheShell;

     PROCEDURE DrawTheMenu;
     VAR  Loop2 : Word;
     BEGIN
          FOR Loop2 := 1 TO 19 DO
          BEGIN
               IF Loop2=Current THEN TheAttr := GunshotColours.GSMailMenuSelected
                                ELSE TheAttr := GunshotColours.GSMailWindowText;
               FastWrite(' '+TheMenu[Loop2]+' ',TopLine+1+Loop2,12,TheAttr);
          END;
     END;

     PROCEDURE DoRescan;
     BEGIN
          ClearTheWindows;
          ScanNewMail;
          ScanNewFaxes;
          bsOnHook(NodeInfo.OnHook);
          StatusWindow('Initializing Modem');
          _ShowCursor;
          InitializeModem;
          StatusWindow('Waiting for a call or event');
          WriteNodeFile('GSMail','Waiting For A Caller','');
          TimerWait := 20;
          NewTimerSecs(InitTimer,TimerWait);
          LastTime := '';
          NewTimerSecs(InfoTimer,6);
          ResetDialTimer;
     END;

     PROCEDURE ClearTheDeadWood;
     BEGIN
          RemoveDialWindow;
          CallingOut := False;
          _KillBusy;
     END;

BEGIN
     Blubber := False;
     TheOne := #0;
     TheMenu[1]  := 'Change AKA          Alt+A';
     TheMenu[2]  := 'PhoneBook Quicky    Alt+B';
     TheMenu[3]  := 'Configuration       Alt+C';
     TheMenu[4]  := 'Netmail Editor      Alt+E';
     TheMenu[5]  := 'Force Poll A Node   Alt+F';
     TheMenu[6]  := 'Request Files       Alt+G';
     TheMenu[7]  := 'Hang Up Modem       Alt+H';
     TheMenu[8]  := 'Initialize Modem    Alt+I';
     TheMenu[9]  := 'Jump To Terminal    Alt+J';
     TheMenu[10] := 'Local Logon         Alt+L';
     TheMenu[11] := 'Pack Netmail Area   Alt+P';
     TheMenu[12] := 'Restart Event       Alt+R';
     TheMenu[13] := 'Session Editor      Alt+S';
     TheMenu[14] := 'Transmit Files      Alt+T';
     TheMenu[15] := 'Undialable Systems  Alt+U';
     TheMenu[16] := 'View Fax Base       Alt+V';
     TheMenu[17] := 'Quit GSMail         Alt+X';
     TheMenu[18] := 'Shell To DOS        F2   ';
     TheMenu[19] := 'Mail History        ?    ';
     TopLine := Window1-11;
     IF KeyPressed THEN
     BEGIN
       C := UpCase(ReadKey);
       IF ORD(C)=0 THEN
       BEGIN
         C := ReadKey;
         ClearTheDeadWood;
         CASE Ord(C) OF
         59..68: {F1-F10  Programmable Function Keys}
              BEGIN
                CASE Ord(C) OF
                59:  Temp := FunctionKeys.GSMail_F1;
                60:  Temp := FunctionKeys.GSMail_F2;
                61:  Temp := FunctionKeys.GSMail_F3;
                62:  Temp := FunctionKeys.GSMail_F4;
                63:  Temp := FunctionKeys.GSMail_F5;
                64:  Temp := FunctionKeys.GSMail_F6;
                65:  Temp := FunctionKeys.GSMail_F7;
                66:  Temp := FunctionKeys.GSMail_F8;
                67:  Temp := FunctionKeys.GSMail_F9;
                68:  Temp := FunctionKeys.GSMail_F10;
                END;
                IF _UpperCase(Temp)='%MENU' THEN GOTO ToTheMenu;
                IF _UpperCase(Temp)='%SHELL' THEN GOTO ToTheShell;
                IF (Temp<>'') THEN
                BEGIN
                  IF Temp[1]='?' THEN
                  BEGIN
                    Delete(Temp,1,1);
                    HaltCode := _Numeric(Temp);
                    StatusWindow('User break, exiting errorlevel: '+_String(HaltCode));
                    bsWriteLog('User break, exiting errorlevel: '+_String(HaltCode),False);
                    bsOnHook(NodeInfo.OnHook);
                    Finished := True;
                  END
                  ELSE
                  BEGIN
                    WhereXYAbs(OldXY);
                    SaveScreen(1);
                    SetOrigVideoMode;
                    bsOffHook(NodeInfo.OffHook);
                    WHILE KeyPressed DO Crap := ReadKey;
                    DoExec(GetEnv('COMSPEC'),' /C '+Temp,SwapMethod,
                           Gunshot_Directory+'\NODE'+_String(SimNode));
                    SetOurVideoMode;
                    ChDir(Gunshot_Directory);
                    _HideCursor;
                    RestoreScreen(1);
                    GotoXYAbs(OldXY);
                    _ShowCursor;
                    DoRescan;
                  END;
                END;
                ResetDialTimer;
              END;
         36:  BEGIN {ALT-J  Terminal}
                AltJ:
                IF MailerInfo.HandleFaxes THEN
                BEGIN
                  PutString(bsBBSPort,'AT+FCLASS=0'+#13);
                  bsClearInBuffer;
                END;
                DoTerminal;
                DoRescan;
                ResetDialTimer;
              END;
         22:  BEGIN {ALT-U  Undialable Systems}
                AltU:
                UndialableSystems;
                ResetDialTimer;
              END;
         18:  BEGIN {ALT-E  Netmail Editor}
                AltE:
                WhereXYAbs(OldXY);
                SaveScreen(1);
                SetOrigVideoMode;
                bsOffHook(NodeInfo.OffHook);
                WHILE KeyPressed DO Crap := ReadKey;
                DoExec(Gunshot_Directory+'\BIN\GSEDIT.EXE','-N'+_String(SimNode),
                       SwapMethod,Gunshot_Directory+'\NODE'+_String(SimNode));
                SetOurVideoMode;
                ChDir(Gunshot_Directory);
                _HideCursor;
                RestoreScreen(1);
                GotoXYAbs(OldXY);
                _ShowCursor;
                bsOnHook(NodeInfo.OnHook);
                ResetDialTimer;
              END;
         48:  BEGIN {ALT-B  PhoneBook Quicky}
                AltB:
                IF _FileExists(Gunshot_Directory+'\DATA\PBOOK.DAT') THEN
                BEGIN
                  IF GetAQuicky THEN AddToQueue('POLL',PhoneBook.NetAddress,'',0,False,0,Crash,False,0,0,0,False,True,True);
                END;
                ResetDialTimer;
              END;
         31:  BEGIN {ALT-S  Session Editor}
                AltS:
                IF (NumberOfQueues<>0) THEN
                BEGIN
                  EditSessionQueue;
                  RescanQueue;
                  StatusWindow('Initializing Modem');
                  InitializeModem;
                  StatusWindow('Waiting for a call or event');
                  WriteNodeFile('GSMail','Waiting For A Caller','');
                  TimerWait := 20;
                  NewTimerSecs(InitTimer,TimerWait);
                END;
                ResetDialTimer;
              END;
         38:  BEGIN {ALT-L Local Logon}
                AltL:
                StatusWindow('Local logon, exiting errorlevel: 10');
                bsWriteLog('Local logon, exiting errorlevel: 10',False);
                bsOnHook(NodeInfo.OnHook);
                Finished := True;
                HaltCode := 10;
              END;
         45:  BEGIN {ALT-X  Quit}
                AltX:
                StatusWindow('User break, exiting errorlevel: 5');
                bsWriteLog('User break, exiting errorlevel: 5',False);
                bsOnHook(NodeInfo.OnHook);
                Finished := True;
                HaltCode := 5;
              END;
         47:  BEGIN {ALT-V  View Fax Base}
                AltV:
                bsOffHook(NodeInfo.OffHook);
                FaxEditor;
                ScanNewFaxes;
                CreateSemaphore(2);
                bsOnHook(NodeInfo.OnHook);
                StatusWindow('Initializing Modem');
                InitializeModem;
                StatusWindow('Waiting for a call or event');
                WriteNodeFile('GSMail','Waiting For A Caller','');
                TimerWait := 20;
                NewTimerSecs(InitTimer,TimerWait);
                ResetDialTimer;
              END;
         25:  BEGIN {ALT-P  Pack Netmail}
                AltP:
                _HideCursor;
                PackNetMail;
                DoRescan;
                CreateSemaphore(2);
                ResetDialTimer;
              END;
         19:  BEGIN {ALT-R  Restart Event}
                AltR:
                _HideCursor;
                DoRescan;
                ResetDialTimer;
              END;
         34:  BEGIN {ALT-G  Request Files}
                AltG:
                GetAnAddress('Request Files','',TTInput);
                IF (TTInput.Zone<>0) THEN
                BEGIN
                  IF GetFileRequests('Request Files From '+AddressToString(TTInput),TTInput,false) THEN
                  BEGIN
                    AddToQueue('FREQ',TTInput,'',0,False,2,Crash,False,0,0,0,False,True,True);
                  END;
                END;
                ResetDialTimer;
              END;
         20:  BEGIN {ALT-T  Transmit Files}
                AltT:
                GetAnAddress('Transmit Files','',TTInput);
                IF (TTInput.Zone<>0) THEN GetFileRequests('Transmit Files To '+AddressToString(TTInput),TTInput,true);
                ResetDialTimer;
              END;
         23:  BEGIN {ALT-I  Initialize Modem}
                AltI:
                StatusWindow('Initializing Modem');
                InitializeModem;
                StatusWindow('Waiting for a call or event');
                WriteNodeFile('GSMail','Waiting For A Caller','');
                TimerWait := 20;
                NewTimerSecs(InitTimer,TimerWait);
                ResetDialTimer;
              END;
         46:  BEGIN {ALT-C  Config}
                AltC:
                SaveScreen(1);
                SetOrigVideoMode;
                bsOffHook(NodeInfo.OffHook);
                WHILE KeyPressed DO Crap := ReadKey;
                DoExec('GSCONFIG.EXE','-N'+_String(SimNode),SwapMethod,
                       Gunshot_Directory+'\NODE'+_String(SimNode));
                SetOurVideoMode;
                ChDir(Gunshot_Directory);
                _HideCursor;
                CreateSemaphore(1);
                RestoreScreen(1);
                LoadVars;
                DrawAka;
                DoRescan;
                ResetDialTimer;
              END;
         33:  BEGIN {ALT-F  Forced Poll}
                AltF:
                GetAnAddress('Forced Poll','',TTInput);
                IF (TTInput.Zone<>0) THEN
                BEGIN
                  AddToQueue('POLL',TTInput,'',0,False,0,Crash,False,0,0,0,False,True,True);
                END;
                ResetDialTimer;
              END;
         30:  BEGIN {ALT-A  Change AKA}
                AltA:
                ChangeCurrentAka;
                LoadVars;
                DrawAka;
                ResetDialTimer;
              END;
         35:  BEGIN {ALT-H  Hangup}
                AltH:
                StatusWindow('Hanging Up Modem');
                bsOnHook(NodeInfo.OnHook);
                StatusWindow('Waiting for a call or event');
                WriteNodeFile('GSMail','Waiting For A Caller','');
                TimerWait := 20;
                NewTimerSecs(InitTimer,TimerWait);
                ResetDialTimer;
              END;
         END;
         IF Blubber THEN
         BEGIN
           ToTheMenu:
           SaveScreen(1);
           _HideCursor;
           DrawWindow(9,TopLine,41,TopLine+22,'GSMAIL MENU',True);
           InvertedBox(11,TopLine+1,39,TopLine+21);
           Current := 1;
           DrawTheMenu;
           Ch := #0;
           REPEAT
             IF KeyPressed THEN
             BEGIN
               Ch := ReadKey;
               IF Ord(Ch)=0 THEN
               BEGIN
                 Ch := ReadKey;
                 CASE Ord(Ch) OF
                 72:  IF Current>1 THEN
                      BEGIN
                        DEC(Current);
                        DrawTheMenu;
                      END
                      ELSE
                      BEGIN
                        Current := 19;
                        DrawTheMenu;
                      END;
                 80:  IF Current<19 THEN
                      BEGIN
                        INC(Current);
                        DrawTheMenu;
                      END
                      ELSE
                      BEGIN
                        Current := 1;
                        DrawTheMenu;
                      END;
                 END;
                 Ch := #0;
               END;
             END
             ELSE TimeSlice;
           UNTIL ((Ch=#27) OR (Ch=#13));
           RestoreScreen(1);
           _ShowCursor;
           IF (Ch=#13) THEN
           BEGIN
             CASE Current OF
             1:   GOTO AltA;
             2:   GOTO AltB;
             3:   GOTO AltC;
             4:   GOTO AltE;
             5:   GOTO AltF;
             6:   GOTO AltG;
             7:   GOTO AltH;
             8:   GOTO AltI;
             9:   GOTO AltJ;
             10:  GOTO AltL;
             11:  GOTO AltP;
             12:  GOTO AltR;
             13:  GOTO AltS;
             14:  GOTO AltT;
             15:  GOTO AltU;
             16:  GOTO AltV;
             17:  GOTO AltX;
             18:  GOTO ToTheShell;
             19:  GOTO Question;
             END;
           END;
         END;
         IF Blubber THEN
         BEGIN
           ToTheShell:
           StatusWindow('User invoking DOS shell');
           bsWriteLog('User invoking DOS shell',False);
           SaveScreen(1);
           SetOrigVideoMode;
           bsOffHook(NodeInfo.OffHook);
           WHILE KeyPressed DO Crap := ReadKey;
           PutEnviro('PROMPT=Enter EXIT to return to GSMail!!$_$p$g');
           DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),SwapMethod,
                  Gunshot_Directory+'\NODE'+_String(SimNode));
           SetOurVideoMode;
           ChDir(Gunshot_Directory);
           _HideCursor;
           RestoreScreen(1);
           DoRescan;
           ResetDialTimer;
         END;
       END
       ELSE
       BEGIN
         CASE C OF
         #27: BEGIN
                bsOnHook(NodeInfo.OnHook);
                TheOne := #27;
                ResetDialTimer;
              END;
         #32: IF NOT(Waiting) THEN
              BEGIN
                IF (NumberOfQueues<>0) THEN NewTimer(DialTimer,1);
              END;
         '?': BEGIN
                Question:
                ShowMailHistory;
                ResetDialTimer;
              END;
         END;
       END;
       WHILE KeyPressed DO C := ReadKey;
       NewTimerSecs(SaverAdvance,5);
       NewTimerSecs(SaverTimer,Mailer2Info.BlankerTimeout);
     END
     ELSE TimeSlice;
     HandleLocalKeyPresses := TheOne;
END;
{==========================================================================}
{                                                                          }
{ Grabs your file requests for a destination node                          }
{                                                                          }
{==========================================================================}
FUNCTION GetFileRequests(Title: String; NodeAddr: AddrType; IsTransmit: Boolean) : Boolean;
VAR  Work    : String;
     OldXY   : Word;
     Entered : Byte;
     ReqFile : Text;
     CurYPos : Word;
     TFile   : Text;

     PROCEDURE DrawIt;
     BEGIN
          FastWrite(_PadRight(Work,50),CurYPos,16,GunshotColours.GSMailWindowText);
          IF CurYPos=15 THEN
          BEGIN
            Get(16,12,67,15);
            Put(16,11);
            FastWrite('File(s):',CurYPos,7,GunshotColours.GSMailWindowText);
          END
          ELSE
          BEGIN
            INC(CurYPos);
            FastWrite('File(s):',CurYPos,7,GunshotColours.GSMailWindowText);
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     DrawWindow(3,9,70,17,Title,True);
     InvertedBox(5,10,68,16);
     FastWrite('File(s):',11,7,GunshotColours.GSMailWindowText);
     Entered := 0;
     IF Not(IsTransmit) THEN
     BEGIN
          ASSIGN(ReqFile,MailerInfo.OutPkts+HexSystem16(NodeAddr)+'.REQ');
          {$I-}APPEND(ReqFile);{$I+}
          IF (IOResult<>0) THEN REWRITE(ReqFile);
     END;
     CurYPos := 11;
     REPEAT
       Work := _UpperCase(aGetInput(16,CurYPos,50,GunshotColours.GSMailDataEntry,'',True,True));
       IF ((Work<>'') AND (Work<>#27)) THEN
       BEGIN
         IF Work[1]='@' THEN
         BEGIN
           IF IsTransmit THEN
           BEGIN
             {FUCK}
           END
           ELSE
           BEGIN
             Delete(Work,1,1);
             Work := _RemoveSpaces(Work);
             IF _FileExists(Work) THEN
             BEGIN
               ASSIGN(TFile,Work);
               RESET(TFile);
               REPEAT
                 READLN(TFile,Work);
                 Work := _UpperCase(_RemoveSpaces(Work));
                 INC(Entered);
                 WRITELN(ReqFile,Work);
                 DrawIt;
               UNTIL EOF(TFile);
               CLOSE(TFile);
             END;
           END;
         END
         ELSE
         BEGIN
           INC(Entered);
           IF Not(IsTransmit)
              THEN WRITELN(ReqFile,Work)
              ELSE AddToQueue('TRANS',TTInput,work,0,False,0,Crash,False,0,0,0,False,False,False);
           DrawIt;
         END;
       END;
     UNTIL ((Work='') OR (Work=#27));
     IF NOT(IsTransmit) THEN CLOSE(ReqFile);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     IF NOT(IsTransmit) THEN
     BEGIN
          IF _FileSize(MailerInfo.OutPkts+HexSystem16(NodeAddr)+'.REQ')=0 THEN
          BEGIN
               _EraseFile(MailerInfo.OutPkts+HexSystem16(NodeAddr)+'.REQ');
               Entered := 0;
          END;
     END;
     IF Entered=0 THEN GetFileRequests := False
                  ELSE GetFileRequests := True;
END;


PROCEDURE EditSessionQueue;
TYPE Pick_List  = RECORD
     Text       : String[75];
     QueueNum   : Word;
     END;
TYPE BigPick    = Array[1..800] Of Pick_List;
VAR  OldXY      : Word;
     PickList   : ^BigPick;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Loop       : Word;
     Loop2      : Word;
     IsItThere  : Boolean;
     Temp       : String;
     Temp2      : String;
     Work1      : Integer;
LABEL             Skip1,Skip2,PassOn;

     PROCEDURE DoRedraw;
     VAR  LLoop : Word;
          ToDo  : Word;
          TTemp : String;
     BEGIN
          TheOne  := Top;
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR LLoop := (YYPos+1) TO ToDo DO
          BEGIN
               IF (TheOne<=NumItems) THEN
               BEGIN
                    TTemp := PickList^[TheOne].Text;
                    IF TheOne=Current THEN FastWrite(TTemp,LLoop,3,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(TTemp,LLoop,3,GunshotColours.GSMailWindowText);
               END;
               INC(TheOne);
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     New(PickList);
     FillChar(PickList^,SizeOf(PickList^),0);
     NumItems := 0;

     FOR Loop := 1 TO NumberOfQueues DO
     BEGIN
          IF Loop<>1 THEN
          BEGIN
               IsItThere := False;
               FOR Loop2 := 1 TO Loop-1 DO
               BEGIN
                    IF (Pos(AddressToString(MailQueue^[Loop].DestAddr),PickList^[Loop2].Text)=7) THEN
                    BEGIN
                         IsItThere := True;
                         GOTO PassOn;
                    END;
               END;
               PassOn:
               IF NOT(IsItThere) THEN
               BEGIN
                    Temp2 := GetBBSName(MailQueue^[Loop].DestAddr);
                    IF (Temp2<>'-Unlisted-') THEN
                    BEGIN
                         Temp := _PadLeft(_String(Loop),3)+']  '+_PadRight(AddressToString(MailQueue^[Loop].DestAddr),25);
                         Temp := Temp+_PadRight(Temp2,34);
                         CASE MailQueue^[Loop].MsgStat OF
                         1:   Temp := Temp+'Immediate ';
                         2:   Temp := Temp+'Immediate ';
                         3:   Temp := Temp+'Hold      ';
                         4:   Temp := Temp+'Sent      ';
                         END;
                         INC(NumItems);
                         PickList^[NumItems].Text := Temp;
                         PickList^[NumItems].QueueNum := Loop;
                    END;
               END;
          END
          ELSE
          BEGIN
               Temp2 := GetBBSName(MailQueue^[Loop].DestAddr);
               IF (Temp2<>'-Unlisted-') THEN
               BEGIN
                    Temp := _PadLeft(_String(Loop),3)+']  '+_PadRight(AddressToString(MailQueue^[Loop].DestAddr),25);
                    Temp := Temp+_PadRight(Temp2,34);
                    CASE MailQueue^[Loop].MsgStat OF
                    1:   Temp := Temp+'Immediate ';
                    2:   Temp := Temp+'Immediate ';
                    3:   Temp := Temp+'Hold      ';
                    4:   Temp := Temp+'Sent      ';
                    END;
                    INC(NumItems);
                    PickList^[NumItems].Text := Temp;
                    PickList^[NumItems].QueueNum := Loop;
               END;
          END;
     END;

     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Mail Session Queue',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Mail Session Queue',True);
     END;
     FastWrite(_PadRight('  [  ] Immediate  [  ]       [  ]',80),Window2+7,1,GunshotColours.GSMailWindowText);
     FastWrite('F1',Window2+7,4,GunshotColours.GSMailWindowHighlight);
     FastWrite('F2',Window2+7,20,GunshotColours.GSMailWindowHighlight);
     FastWrite('F3',Window2+7,31,GunshotColours.GSMailWindowHighlight);
     FastWrite('Immediate',Window2+7,8,GunshotColours.GSMailWindowText);
     FastWrite('Hold',Window2+7,24,GunshotColours.GSMailWindowText);
     FastWrite('Mark As Sent',Window2+7,35,GunshotColours.GSMailWindowText);
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     59:  IF (MailQueue^[PickList^[Current].QueueNum].MsgStat<>Sent) THEN
                          BEGIN
                               MailQueue^[PickList^[Current].QueueNum].MsgStat := Crash;
                               Temp := _PadLeft(_String(PickList^[Current].QueueNum),3)+']  '+
                                       _PadRight(AddressToString(MailQueue^[PickList^[Current].QueueNum].DestAddr),25);
                               Temp := Temp+_PadRight(GetBBSName(MailQueue^[PickList^[Current].QueueNum].DestAddr),34);
                               CASE MailQueue^[PickList^[Current].QueueNum].MsgStat OF
                               1:   Temp := Temp+'Immediate ';
                               2:   Temp := Temp+'Immediate ';
                               3:   Temp := Temp+'Hold      ';
                               4:   Temp := Temp+'Sent      ';
                               END;
                               PickList^[Current].Text := Temp;
                               DoRedraw;
                          END;
                     60:  IF (MailQueue^[PickList^[Current].QueueNum].MsgStat<>Sent) THEN
                          BEGIN
                               MailQueue^[PickList^[Current].QueueNum].MsgStat := Hold;
                               Temp := _PadLeft(_String(PickList^[Current].QueueNum),3)+']  '+
                                       _PadRight(AddressToString(MailQueue^[PickList^[Current].QueueNum].DestAddr),25);
                               Temp := Temp+_PadRight(GetBBSName(MailQueue^[PickList^[Current].QueueNum].DestAddr),34);
                               CASE MailQueue^[PickList^[Current].QueueNum].MsgStat OF
                               1:   Temp := Temp+'Immediate ';
                               2:   Temp := Temp+'Immediate ';
                               3:   Temp := Temp+'Hold      ';
                               4:   Temp := Temp+'Sent      ';
                               END;
                               PickList^[Current].Text := Temp;
                               DoRedraw;
                          END;
                     61:  IF (MailQueue^[PickList^[Current].QueueNum].MsgStat<>Sent) THEN
                          BEGIN
                               MailQueue^[PickList^[Current].QueueNum].MsgStat := Sent;
                               Temp := _PadLeft(_String(PickList^[Current].QueueNum),3)+']  '+
                                       _PadRight(AddressToString(MailQueue^[PickList^[Current].QueueNum].DestAddr),25);
                               Temp := Temp+_PadRight(GetBBSName(MailQueue^[PickList^[Current].QueueNum].DestAddr),34);
                               CASE MailQueue^[PickList^[Current].QueueNum].MsgStat OF
                               1:   Temp := Temp+'Immediate ';
                               2:   Temp := Temp+'Immediate ';
                               3:   Temp := Temp+'Hold      ';
                               4:   Temp := Temp+'Sent      ';
                               END;
                               PickList^[Current].Text := Temp;
                               DoRedraw;
                          END;
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C=#13) OR (C=#27));
     Dispose(PickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
END;


FUNCTION GetAQuicky: Boolean;
TYPE Pick_List  = RECORD
     Text       : String[75];
     QueueNum   : Word;
     END;
TYPE BigPick    = Array[1..800] Of Pick_List;
VAR  OldXY      : Word;
     PickList   : ^BigPick;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Loop       : Word;
     Loop2      : Word;
     Temp       : String;
     Temp2      : String;
     Work1      : Integer;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  LLoop : Word;
          ToDo  : Word;
          TTemp : String;
     BEGIN
          TheOne  := Top;
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR LLoop := (YYPos+1) TO ToDo DO
          BEGIN
               IF (TheOne<=NumItems) THEN
               BEGIN
                    TTemp := PickList^[TheOne].Text;
                    IF TheOne=Current THEN FastWrite(TTemp,LLoop,3,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(TTemp,LLoop,3,GunshotColours.GSMailWindowText);
               END;
               INC(TheOne);
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     New(PickList);
     NumItems := 0;

     ASSIGN(FPhoneBook,Gunshot_Directory+'\DATA\PBOOK.DAT');
     RESET(FPhoneBook);
     REPEAT
           READ(FPhoneBook,PhoneBook);
           WITH PhoneBook DO
           BEGIN
                Temp := ' '+_PadRight(UserName,25)+
                        _PadRight(Description,33)+
                        _PadLeft(AddressToString(NetAddress),15)+' ';
           END;
           INC(NumItems);
           PickList^[NumItems].Text := Temp;
           PickList^[NumItems].QueueNum := NumItems;
     UNTIL EOF(FPhoneBook);
     CLOSE(FPhoneBook);
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Quick PhoneBook Call',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Quick PhoneBook Call',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END
                ELSE IF ((C=#13) OR (C=#32)) THEN
                BEGIN
                     ASSIGN(FPhoneBook,Gunshot_Directory+'\DATA\PBOOK.DAT');
                     RESET(FPhoneBook);
                     SEEK(FPhoneBook,Current-1);
                     READ(FPhoneBook,PhoneBook);
                     CLOSE(FPhoneBook);
                     Dispose(PickList);
                     RestoreScreen(1);
                     GotoXYAbs(OldXY);
                     _ShowCursor;
                     GetAQuicky := True;
                     Exit;
                END;
           END
           ELSE TimeSlice;
     UNTIL C=#27;
     Dispose(PickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     GetAQuicky := False;
END;


PROCEDURE ChangeCurrentAKA;
TYPE Pick_List  = RECORD
     Text       : String[25];
     QueueNum   : Word;
     END;
TYPE BigPick    = Array[1..800] Of Pick_List;
VAR  OldXY      : Word;
     PickList   : ^BigPick;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Loop       : Word;
     Loop2      : Word;
     Temp       : String;
     Temp2      : String;
     Work1      : Integer;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  LLoop : Word;
          ToDo  : Word;
          TTemp : String;
     BEGIN
          TheOne  := Top;
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR LLoop := (YYPos+1) TO ToDo DO
          BEGIN
               IF (TheOne<=NumItems) THEN
               BEGIN
                    TTemp := PickList^[TheOne].Text;
                    IF TheOne=Current THEN FastWrite(TTemp,LLoop,5,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(TTemp,LLoop,5,GunshotColours.GSMailWindowText);
               END;
               INC(TheOne);
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     New(PickList);
     NumItems := 0;

     ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     REPEAT
           READ(FNetwork,Network);
           Temp := _PadRight(' '+AddressToString(Network.Net_Address),25);
           INC(NumItems);
           PickList^[NumItems].Text := Temp;
           PickList^[NumItems].QueueNum := NumItems;
     UNTIL EOF(FNetwork);
     CLOSE(FNetwork);
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(4,YYPos,30,YYPos+NumItems+1,'CHANGE CURRENT AKA',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(4,2,30,24,'CHANGE CURRENT AKA',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END
                ELSE IF ((C=#13) OR (C=#32)) THEN
                BEGIN
                     IF (Current<>0) THEN
                     BEGIN
                          CurrentAka := Current;
                          Dispose(PickList);
                          RestoreScreen(1);
                          GotoXYAbs(OldXY);
                          _ShowCursor;
                          Exit;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL C=#27;
     Dispose(PickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
END;


PROCEDURE GetAnAddress(Title,Stuff: String; VAR TheAka: AddrType);
VAR  Work   : String;
     OldXY  : Word;
     TmpAka : AddrType;
LABEL       OverAgain;

     FUNCTION IsAName(InString: String): Boolean;
     VAR  Loop : Word;
     BEGIN
          InString := _UpperCase(InString);
          FOR Loop := 65 TO 90 DO
          BEGIN
               IF Pos(Chr(Loop),InString)<>0 THEN
               BEGIN
                    IsAName := True;
                    Exit;
               END;
          END;
          IF Pos(' ',InString)<>0 THEN
          BEGIN
               IsAName := True;
               Exit;
          END;
          IsAName := False;
     END;

BEGIN
     OverAgain:
     WhereXYAbs(OldXY);
     SaveScreen(1);
     DrawWindow(5,9,68,16,Title,True);
     InvertedBox(7,10,66,14);
     FastWrite('Address:',12,11,GunshotColours.GSMailWindowText);
     FastWrite('Enter the full zone:net/node number or user searchstring',15,9,GunshotColours.GSMailWindowText);
     Work := _UpperCase(aGetInput(22,12,40,GunshotColours.GSMailDataEntry,Stuff,True,True));
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     IF Work=#27 THEN
     BEGIN
          FillChar(TheAka,SizeOf(TheAka),0);
          Exit;
     END;
     IF (Work='') THEN
     BEGIN
          ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          SEEK(FNetwork,CurrentAka-1);
          READ(FNetwork,Network);
          CLOSE(FNetwork);
          IF (GetNetInfo(NetWork.Net_Address)<>'') THEN
          BEGIN
               SelectedANode(NetWork.Net_Address,TmpAka);
               IF TmpAka.Zone=0 THEN GOTO OverAgain;
               TheAka := TmpAka;
          END
          ELSE GOTO OverAgain;
     END
     ELSE IF InTheBook(Work) THEN
     BEGIN
          IF (GetNodeInfo(PhoneBook.NetAddress)<>'')
             THEN TheAka := PhoneBook.NetAddress
             ELSE FillChar(TheAka,SizeOf(TheAka),0);
     END
     ELSE IF IsAName(Work) THEN
     BEGIN
          FindNameInfo(Work,TmpAka);
          IF (TmpAka.Zone<>0) THEN
          BEGIN
               SelectedAName(Work,TmpAka);
               IF TmpAka.Zone=0 THEN GOTO OverAgain;
               TheAka := TmpAka;
          END
          ELSE GOTO OverAgain;
     END
     ELSE
     BEGIN
          StringToAddress(Work,TmpAka);
          IF (GetNodeInfo(TmpAka)<>'')
             THEN TheAka := TmpAka
             ELSE FillChar(TheAka,SizeOf(TheAka),0);
     END;
END;


END.
