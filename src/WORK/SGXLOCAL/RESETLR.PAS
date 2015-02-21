{$I DEFINES.INC}
UNIT ResetLR;


INTERFACE


PROCEDURE ResetLastReadPointers(EndOfBase: Boolean);
PROCEDURE ResetLRPsLastXXXMsgs;
PROCEDURE ResetLRPsSkipXXXMsgs;


IMPLEMENTATION


USES Screens,KeyInput,Globals,Toggle,ChangeMA,MiscStr,
     GotKeys,LstReads,MsgHeadr,BsLog,TagArea,MFireUp;


PROCEDURE ResetLastReadPointers(EndOfBase: Boolean);
VAR  before        : word;
     beforesub     : word;
     C             : Char;
     Selected      : Word;
LABEL                SkipIt;
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
     bsWriteLog('Resetting last read pointers',False);
     System_Prompt('',168);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FMessageArea);
     CurrentMessageArea := 0;
     StartToggle(FileSize(FMessageArea));
     REPEAT
           DoToggle;
           READ(FMessageArea,MessageAreas);
           INC(CurrentMessageArea);
           CASE c OF
           'C': IF CurrentMessageArea<>Before THEN GOTO SkipIt;
           'T': IF NOT(IsMsgTagged(MessageAreas.AreaID)) THEN GOTO SkipIt;
           'S': IF CurrentMessageArea<>Selected THEN GOTO SkipIt;
           END;
           IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
              (UserRecord.Security>=MessageAreas.Read_Access)) THEN
           BEGIN
                IF EndOfBase
                   THEN JamBase_ResetLastRead(MessageAreas.Dos_Name)
                   ELSE JamBase_ZeroLastRead(MessageAreas.Dos_Name);
                CommLookAhead;
           END;
           SkipIt:
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     EndToggle;
     Header2(BeforeSub,Before,True);
END;


PROCEDURE ResetLRPsLastXXXMsgs;
VAR  before        : word;
     beforesub     : word;
     C             : Char;
     Selected      : Word;
     tttt          : Word;
     Code          : Integer;
LABEL                SkipIt;
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
     System_Prompt('',188);
     Get_Enter;
     IF Fields^[1].Text<>'' THEN
     BEGIN
          VAL(Fields^[1].Text,tttt,code);
          bsWriteLog('Setting last read pointers at last '+Fields^[1].Text+' msgs',False);
          System_Prompt('',168);
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          CurrentMessageArea := 0;
          StartToggle(FileSize(FMessageArea));
          REPEAT
                DoToggle;
                READ(FMessageArea,MessageAreas);
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
                     IF tttt>TotalMessages
                        THEN JamBase_SetLastRead(0)
                        ELSE JamBase_SetLastRead(TotalMessages-tttt);
                     CommLookAhead;
                END;
                SkipIt:
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          EndToggle;
     END;
     Header2(BeforeSub,Before,True);
END;


PROCEDURE ResetLRPsSkipXXXMsgs;
VAR  before        : word;
     beforesub     : word;
     C             : Char;
     Selected      : Word;
     tttt          : Word;
     Code          : Integer;
LABEL                SkipIt;
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
     System_Prompt('',189);
     Get_Enter;
     IF Fields^[1].Text<>'' THEN
     BEGIN
          VAL(Fields^[1].Text,tttt,code);
          bsWriteLog('Setting last read pointers at first '+Fields^[1].Text+' msgs',False);
          System_Prompt('',168);
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          CurrentMessageArea := 0;
          StartToggle(FileSize(FMessageArea));
          REPEAT
                DoToggle;
                READ(FMessageArea,MessageAreas);
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
                     IF tttt>TotalMessages
                        THEN JamBase_SetLastRead(TotalMessages)
                        ELSE JamBase_SetLastRead(tttt);
                     CommLookAhead;
                END;
                SkipIt:
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          EndToggle;
     END;
     Header2(BeforeSub,Before,True);
END;


END.