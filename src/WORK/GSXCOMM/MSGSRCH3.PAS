{$I DEFINES.INC}
UNIT MsgSrch3;


INTERFACE


PROCEDURE All_Mail;


IMPLEMENTATION


USES Globals,Screens,BsLog,Toggle,KeyInput,BsString,MiscStr,TagArea,
     Gunshot,GotKeys,MiscMsg,JamGet,ReadNew,MsgHeadr,ChangeMA,MFireUp,
     LstReads;


PROCEDURE All_Mail;
VAR  before        : word;
     beforesub     : word;
     found         : boolean;
     read_all      : boolean;
     temp          : string;
     nml           : word;
     start_at      : word;
     end_at        : word;
     c             : Char;
     FFMessageArea : File Of _MessageArea_Record;
     Selected      : Word;
     LABEL           quit_search,SkipIt;
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
     found      := false;
     bsWriteLog('Searching for all mail',True);
     ASSIGN(FFMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FFMessageArea);
     CurrentMessageArea := 0;
     REPEAT
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
                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                start_at := 1;
                end_at   := TotalMessages;
                IF ((start_at<end_at) AND (start_at<>0)) THEN
                BEGIN
                     nml := start_at;
                     REPEAT
                           JamBase_GetMessage(nml);
                           JamBase_SetLastRead(nml);
                           IF CanSee THEN
                           BEGIN
                                found := True;
                                EnteredReply := False;
                                CASE Read_New_Mail(False) OF
                                0:   GOTO quit_search;
                                1:   IF EnteredReply THEN INC(end_at);
                                2:   GOTO SkipIt;
                                END;
                           END;
                           INC(nml);
                     UNTIL nml>end_at;
                END;
                IF CommLookAhead=#27 THEN GOTO Quit_Search;
           END;
           SkipIt:
     UNTIL EOF(FFMessageArea);
     quit_search:
     CLOSE(FFMessageArea);
     IF found=True THEN System_Prompt('',66)
                   ELSE System_Prompt('',140);
     Get_Enter;
     Header2(BeforeSub,Before,True);
END;


END.