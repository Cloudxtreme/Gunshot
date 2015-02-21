{$I DEFINES.INC}
UNIT ReadNew;


INTERFACE


FUNCTION read_new_mail(Hack: Boolean): Byte;


IMPLEMENTATION


USES Globals,ReadMail,GoodLang,WhatLine,ANSIMisc,Screens,KeyInput,BsLog,
     Time,Special,Download,WriteMsg,MFireUp,JamGet,Commands,BsString;


{Returns 0 - Quit Search}
{        1 - Next message}
{        2 - Skip Area}
FUNCTION read_new_mail(Hack: Boolean): Byte;
VAR  MsgText              : MessageTextLines;
     pages                : word;
     page_count           : word;
     page                 : word;
     crap                 : string;
     outtathis            : boolean;
     outtathis2           : boolean;
     loop3                : word;
     count_lines          : word;
     quote                : boolean;
     tear                 : boolean;
     Message_There        : boolean;
     top                  : word;
     c                    : char;
     Message_File         : string;
     MessageNumber        : Word;
     Temp                 : String;
     Scrap                : Text;
     MaxLines             : Byte;
     WhatToDo             : Byte;
     P1,P2,P3,P4,P5,P6,P7 : Char;

     FUNCTION GetFromOld(TheOne : Word): Word;
     VAR  Work : Word;
          Loop : Word;
     BEGIN
          FOR Loop := 1 TO TotalMessages DO
          BEGIN
               IF MsgIndex[Loop]=TheOne THEN Work := Loop;
          END;
          GetFromOld := Work;
     END;

BEGIN
     outtathis := false;
     REPEAT
           page_count := 0;
           ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
           RESET(FMsgText);
           Page_Count := FileSize(FMsgText);
           CLOSE(FMsgText);
           IF IsRip THEN MaxLines := 25
                    ELSE MaxLines := 14;
           pages := (trunc((page_count-1)/MaxLines))+1;
           page  := 1;
           top   := 1;
           outtathis2 := false;
           REPEAT
                 draw_msg_header;
                 count_lines := 0;
                 ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                 RESET(FMsgText);
                 SEEK(FMsgText,top-1);
                 REPEAT
                       IF NOT(EOF(FMsgText)) THEN
                       BEGIN
                            READ(FMsgText,MsgText);
                            IF MessageAreas.CleanLanguage=1 THEN
                               MsgText.Line := Clean_Language(MsgText.Line);
                            INC(count_lines);
                            quote  := false;
                            tear   := false;
                            quote  := Is_Quote(MsgText.Line);
                            tear   := Is_Tear(MsgText.Line);
                            IF tear THEN FORE(Colours.ReadMSGTearColour)
                               ELSE IF Quote THEN FORE(Colours.ReadMSGQuoteColour)
                               ELSE FORE(Colours.ReadMSGBodyColour);
                            WRITEANSI(MsgText.Line,true,true);
                            BACK(0);
                       END;
                 UNTIL ((count_lines=MaxLines) OR (EOF(FMsgText)));
                 CLOSE(FMsgText);
                 SendCrLf(1);
                 DoCommandString('READNEW',1);
                 DoCommandString('READNEW',2);
                 DoCommandString('READNEW',3);
                 IF (UserRecord.Security>=MessageAreas.Write_Access) THEN DoCommandString('READNEW',4);
                 DoCommandString('READNEW',5);
                 DoCommandString('READNEW',6);
                 DoCommandString('READNEW',7);
                 system_prompt('',1,false,true);
                 P1 := GetCommandKeyPress('READNEW',1);
                 P2 := GetCommandKeyPress('READNEW',2);
                 P3 := GetCommandKeyPress('READNEW',3);
                 P4 := GetCommandKeyPress('READNEW',4);
                 P5 := GetCommandKeyPress('READNEW',5);
                 P6 := GetCommandKeyPress('READNEW',6);
                 P7 := GetCommandKeyPress('READNEW',7);
                 Temp := P1+P2+P3+P5+P6+P7;
                 IF (UserRecord.Security>=MessageAreas.Write_Access) THEN Temp := Temp+P4;
                 c := Get_Menu_Selection(Temp,P2);
                 IF C=P1 THEN
                 BEGIN
                      IF page>1 THEN
                      BEGIN
                           DEC(page);
                           top := ((page-1)*MaxLines)+1;
                      END;
                 END
                 ELSE IF C=P2 THEN
                 BEGIN
                      IF page<pages THEN
                      BEGIN
                           INC(page);
                           top := ((page-1)*MaxLines)+1;
                      END
                      ELSE
                      BEGIN
                           outtathis  := True;
                           Outtathis2 := True;
                           WhatToDo   := 1;
                      END;
                 END
                 ELSE IF C=P3 THEN
                 BEGIN
                      outtathis  := True;
                      Outtathis2 := True;
                      WhatToDo   := 1;
                 END
                 ELSE IF C=P4 THEN
                 BEGIN
                      IF Hack THEN
                      BEGIN
                           MessageNumber := MsgIndex[CurrentMessage];
                           WriteMessage(CurrentMessageSub,CurrentMessageArea,True,FastBaseHdr.MsgFrom);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           MsgIndex[1] := MessageNumber;
                           TotalMessages := 1;
                           JamBase_GetMessage(1);
                      END
                      ELSE
                      BEGIN
                           MessageNumber := MsgIndex[CurrentMessage];
                           WriteMessage(CurrentMessageSub,CurrentMessageArea,True,FastBaseHdr.MsgFrom);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           MessageNumber := GetFromOld(MessageNumber);
                           JamBase_GetMessage(MessageNumber);
                      END;
                      Outtathis2 := True;
                 END
                 ELSE IF C=P5 THEN
                 BEGIN
                      bsWriteLog('Downloading a message as a text file',False);
                      ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                      ASSIGN(Scrap,CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                      RESET(FMsgText);
                      REWRITE(Scrap);
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      WRITELN(Scrap,' *   Original By:  '+FastBaseHdr.MsgFrom);
                      WRITELN(Scrap,' *   Original To:  '+FastBaseHdr.MsgTo);
                      WRITELN(Scrap,' * Original Area:  '+MessageAreas.Area_Name);
                      WRITELN(Scrap,' * Original Date:  '+ProperDateToFancyDate(FastBaseHdr.MessageDate)+'   '+
                                    LongToStringTime(FastBaseHdr.MsgTime));
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      REPEAT
                            READ(FMsgText,MsgText);
                            WRITELN(Scrap,Remove_Special(MsgText.Line));
                      UNTIL EOF(FMsgText);
                      CLOSE(Scrap);
                      CLOSE(FMsgText);
                      dl_file(CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                      ERASE(Scrap);
                      INC(RunningMessageDL);
                 END
                 ELSE IF C=P6 THEN
                 BEGIN
                      outtathis  := True;
                      Outtathis2 := True;
                      WhatToDo   := 2;
                 END
                 ELSE IF C=P7 THEN
                 BEGIN
                      outtathis  := true;
                      outtathis2 := true;
                      WhatToDo   := 0;
                 END;
           UNTIL outtathis2;
     UNTIL (outtathis);
     read_new_mail := WhatToDo;
END;


END.
