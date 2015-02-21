{$I DEFINES.INC}
UNIT KillOld;


INTERFACE


PROCEDURE kill_old_mail;


IMPLEMENTATION


USES BsLog,Screens,ANSIMisc,Toggle,GotKeys,MFireUp,
     Globals,MsgKill,MiscStr,KeyInput,MsgHeadr;


PROCEDURE kill_old_mail;
VAR  killed_any  : boolean;
     killed_some : boolean;
     temp        : string;
LABEL              Quit_Search;
BEGIN
     bsWriteLog('Deleting old personal mail',False);
     killed_some := false;
     SendCrLf(2);
     System_Prompt('',68,false,true);
     FORE(Colours.SpinCursor);
     StartToggle(0);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     reset(FMessageArea);
     REPEAT
           read(FMessageArea,MessageAreas);
           IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
              (UserRecord.Security>=system_info.MessageKill)) THEN
           BEGIN
                DoToggle;
                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                Killed_Any  := JamBase_KillOld;
                IF killed_any THEN killed_some := true;
                IF CommLookAhead=#27 THEN GOTO Quit_Search;
           END;
     UNTIL EOF(FMessageArea);
     Quit_Search:
     close(FMessageArea);
     EndToggle;
     SendCrLf(2);
     IF killed_some=true THEN System_Prompt('',69,true,false)
                         ELSE System_Prompt('',70,true,false);
     Get_Enter;
     ASSIGN(FMessageArea,DATA_Directory+'\MA000000.DAT');
     reset(FMessageArea);
     Seek(FMessageArea,(CurrentMessageArea-1));
     read(FMessageArea,MessageAreas);
     close(FMessageArea);
     Header2(CurrentMessageSub,CurrentMessageArea,True);
END;


END.
