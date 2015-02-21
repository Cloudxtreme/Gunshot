{$I DEFINES.INC}
UNIT MsgSrch2;


INTERFACE


PROCEDURE new_mail_logon;


IMPLEMENTATION


USES Globals,Screens,BsLog,Toggle,ANSIMisc,KeyInput,MiscStr,TagArea,
     GotKeys,MiscMsg,JamGet,ReadNew,MsgHeadr,MkGlobT,MkOpen,MkMsgAbs,
     Shotgun,BsString;


PROCEDURE new_mail_logon;
VAR  before        : word;
     beforesub     : word;
     found         : boolean;
     temp          : string;
     AliasName     : String;
     RealName      : String;
     c             : Char;
     FFMessageArea : File Of _MessageArea_Record;
     AreaType      : Char;
     MsgScan       : AbsMsgPtr;
     Counter       : Longint;
     MaxMsgs       : Word;
     GotIt         : Boolean;
     ScanGroups    : Array[1..2048] Of Word;
     NumGroups     : Word;
     Loop          : Word;
LABEL                quit_search,SkipIt;
BEGIN
     DisplayGraphicsFile('SEARCH2',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,true);
     c := Get_Menu_Selection('ATQ',#0);
     SendCrLf(1);
     IF c='Q' THEN Exit;
     AliasName  := _UpperCase(UserRecord.Alias);
     RealName   := _UpperCase(UserRecord.Name);
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     found      := false;
     bsWriteLog('Searching for new personal mail',False);
     SendCrLf(1);
     System_Prompt('',65,false,true);
     NumGroups  := 0;
     ASSIGN(FMessageSubs,DATA_Directory+'\MSGAREA.SUB');
     RESET(FMessageSubs);
     REPEAT
       READ(FMessageSubs,MessageSubs);
       IF MessageSubs.ScanAtLogon THEN
       BEGIN
         INC(NumGroups);
         ScanGroups[NumGroups] := MessageSubs.Sub_Num;
       END;
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);

     ASSIGN(FFMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FFMessageArea);
     CurrentMessageArea := 0;
     FORE(Colours.SpinCursor);
     StartToggle(0);
     REPEAT
       READ(FFMessageArea,MessageAreas);
       INC(CurrentMessageArea);
       CASE c OF
       'T': IF NOT(IsMsgTagged(MessageAreas.AreaID)) THEN GOTO SkipIt;
       ELSE BEGIN
              GotIt := False;
              FOR Loop := 1 TO NumGroups DO
              BEGIN
                IF ScanGroups[Loop]=MessageAreas.Sub THEN GotIt := True;
              END;
              IF NOT(GotIt) THEN GOTO SkipIt;
            END;
       END;
       IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
          (UserRecord.Security>=MessageAreas.Read_Access)) THEN
       BEGIN
         DoToggle;
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
                 MsgIndex[1] := MsgScan^.GetMsgNum;
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
                          ClrPortScr;
                          System_Prompt('',65,false,true);
                          FORE(Colours.SpinCursor);
                          ToggleCount := 1;
                          CloseMsgArea(MsgScan);
                          GOTO SkipIt;
                        END;
                   END;
                   ClrPortScr;
                   System_Prompt('',65,false,true);
                   FORE(Colours.SpinCursor);
                   ToggleCount := 1;
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
     SendCrLf(2);
     IF found=True THEN System_Prompt('',66,true,false)
                   ELSE System_Prompt('',67,true,false);
     Get_Enter;
     Header2(BeforeSub,Before,True);
END;


END.
