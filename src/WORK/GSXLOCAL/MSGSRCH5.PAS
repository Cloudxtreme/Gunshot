{$I DEFINES.INC}
UNIT MsgSrch5;


INTERFACE


PROCEDURE all_new_mail;


IMPLEMENTATION


USES Globals,Screens,BsLog,Toggle,KeyInput,MiscStr,TagArea,Gunshot,
     GotKeys,MiscMsg,JamGet,ReadNew,MsgHeadr,ChangeMA,MFireUp,LstReads;


PROCEDURE all_new_mail;
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
     bsWriteLog('Searching for all new mail',False);
     System_Prompt('',65);
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
                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                start_at := UserLastReadMsg;
                end_at   := TotalMessages;
                IF ((start_at<end_at) AND (start_at<>0)) THEN
                BEGIN
                     nml := start_at+1;
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
                                2:   BEGIN
                                          ToggleInfo.Current := CurrentMessageArea;
                                          System_Prompt('',65);
                                          ToggleInfo.Current := CurrentMessageArea;
                                          RedrawToggle;
                                          GOTO SkipIt;
                                     END;
                                END;
                                ToggleInfo.Current := CurrentMessageArea;
                                IF nml=end_at THEN
                                BEGIN
                                     System_Prompt('',65);
                                     ToggleInfo.Current := CurrentMessageArea;
                                     RedrawToggle;
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
     EndToggle;
     IF found=True THEN System_Prompt('',66)
                   ELSE System_Prompt('',67);
     Get_Enter;
     Header2(BeforeSub,Before,True);
END;


END.
