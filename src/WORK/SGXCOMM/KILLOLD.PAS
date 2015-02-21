{$I DEFINES.INC}
UNIT KillOld;


INTERFACE


PROCEDURE kill_old_mail;


IMPLEMENTATION


USES BsLog,Screens,Toggle,GotKeys,MFireUp,
     Globals,MsgKill,MiscStr,KeyInput,MsgHeadr;


PROCEDURE kill_old_mail;
VAR  killed_any  : boolean;
     killed_some : boolean;
     temp        : string;
LABEL              Quit_Search;
BEGIN
     bsWriteLog('Deleting old personal mail',True);
     killed_some := false;
     System_Prompt('',68);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     reset(FMessageArea);
     StartToggle(FileSize(FMessageArea));
     REPEAT
           DoToggle;
           read(FMessageArea,MessageAreas);
           IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
              (UserRecord.Security>=system_info.MessageKill)) THEN
           BEGIN
                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                Killed_Any  := JamBase_KillOld;
                IF killed_any THEN killed_some := true;
           END;
           IF CommLookAhead=#27 THEN GOTO Quit_Search;
     UNTIL EOF(FMessageArea);
     Quit_Search:
     close(FMessageArea);
     EndToggle;
     IF killed_some=true THEN System_Prompt('',69)
                         ELSE System_Prompt('',70);
     Get_Enter;
     ASSIGN(FMessageArea,DATA_Directory+'\MA000000.DAT');
     reset(FMessageArea);
     Seek(FMessageArea,(CurrentMessageArea-1));
     read(FMessageArea,MessageAreas);
     close(FMessageArea);
     Header2(CurrentMessageSub,CurrentMessageArea,True);
END;


END.