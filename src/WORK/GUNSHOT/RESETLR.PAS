{$I DEFINES.INC}
UNIT ResetLR;


INTERFACE


PROCEDURE ResetLastReadPointers(EndOfBase: Boolean);
PROCEDURE ResetLRPsLastXXXMsgs;
PROCEDURE ResetLRPsSkipXXXMsgs;


IMPLEMENTATION


USES ANSIMisc,Screens,KeyInput,Globals,Toggle,ChangeMA,
     MiscStr,GotKeys,LstReads,MsgHeadr,BsLog,TagArea,
     MFireUp;


PROCEDURE ResetLastReadPointers(EndOfBase: Boolean);
VAR  before        : word;
     beforesub     : word;
     C             : Char;
     Selected      : Word;
LABEL                SkipIt;
BEGIN
     SendCrLf(1);
     DisplayGraphicsFile('SEARCHES',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,true);
     c := Get_Menu_Selection('CATSQ',#0);
     SendCrLf(1);
     IF c='Q' THEN Exit;
     bsWriteLog('Resetting last read pointers',False);
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     SendCrLf(1);
     System_Prompt('',168,false,true);
     FORE(Colours.SpinCursor);
     StartToggle(0);
     CurrentMessageArea := 0;
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FMessageArea);
     REPEAT
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
                DoToggle;
                IF EndOfBase
                   THEN JamBase_ResetLastRead(MessageAreas.Dos_Name)
                   ELSE JamBase_ZeroLastRead(MessageAreas.Dos_Name);
           END;
           SkipIt:
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     EndToggle;
     SendCrLf(1);
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
     SendCrLf(1);
     DisplayGraphicsFile('SEARCHES',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,true);
     c := Get_Menu_Selection('CATSQ',#0);
     SendCrLf(1);
     IF c='Q' THEN Exit;
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     SendCrLf(1);
     System_Prompt('',188,false,true);
     Get_Number(5,'',False);
     IF input_string<>'' THEN
     BEGIN
          VAL(input_string,tttt,code);
          bsWriteLog('Setting last read pointers at last '+input_string+' msgs',False);
          SendCrLf(2);
          System_Prompt('',168,false,true);
          FORE(Colours.SpinCursor);
          StartToggle(0);
          CurrentMessageArea := 0;
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          REPEAT
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
                     DoToggle;
                     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                     IF tttt>TotalMessages
                        THEN JamBase_SetLastRead(0)
                        ELSE JamBase_SetLastRead(TotalMessages-tttt);
                END;
                SkipIt:
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          EndToggle;
     END;
     SendCrLf(1);
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
     SendCrLf(1);
     DisplayGraphicsFile('SEARCHES',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,true);
     c := Get_Menu_Selection('CATSQ',#0);
     SendCrLf(1);
     IF c='Q' THEN Exit;
     before     := CurrentMessageArea;
     beforesub  := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     SendCrLf(1);
     System_Prompt('',189,false,true);
     Get_Number(5,'',False);
     IF input_string<>'' THEN
     BEGIN
          VAL(input_string,tttt,code);
          bsWriteLog('Setting last read pointers at first '+input_string+' msgs',False);
          SendCrLf(2);
          System_Prompt('',168,false,true);
          FORE(Colours.SpinCursor);
          StartToggle(0);
          CurrentMessageArea := 0;
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          REPEAT
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
                     DoToggle;
                     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                     IF tttt>TotalMessages
                        THEN JamBase_SetLastRead(TotalMessages)
                        ELSE JamBase_SetLastRead(tttt);
                END;
                SkipIt:
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          EndToggle;
     END;
     SendCrLf(1);
     Header2(BeforeSub,Before,True);
END;


END.