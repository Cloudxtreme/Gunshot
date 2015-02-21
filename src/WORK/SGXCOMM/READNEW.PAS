{$I DEFINES.INC}
UNIT ReadNew;


INTERFACE


FUNCTION read_new_mail(Hack: Boolean): Byte;


IMPLEMENTATION


USES Globals,ReadMail,GoodLang,WhatLine,Screens,KeyInput,BsLog,
     Time,Special,Download,WriteMsg,MFireUp,JamGet,Gfx,ApCom,
     ApPort,BsComp,Yapp,Commands,BsString;


{Returns 0 - Quit Search}
{        1 - Next message}
{        2 - Skip Area}
FUNCTION read_new_mail(Hack: Boolean): Byte;
VAR  MsgText              : MessageTextLines;
     MessageNumber        : Word;
     temp                 : string;
     scrap                : text;
     outtathis            : boolean;
     outtathis2           : boolean;
     c                    : char;
     WhatToDo             : Byte;
     P3,P4,P5,P6,P7       : Char;
     LABEL               another_message;

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

     PROCEDURE RedrawMessage;
     BEGIN
          draw_msg_header;
          DisplayGraphicFile('MSGREAD2',True,True,True);
          SetScreenNumber(2);
          NewPickList(False);
          PickInfo.Current := 0;
          ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
          {$I-}
          RESET(FMsgText);
          {$I+}
          IF IOResult=0 THEN;
          REPEAT
                IF NOT(EOF(FMsgText)) THEN
                BEGIN
                     READ(FMsgText,MsgText);
                     Temp := MsgText.Line;
                     IF MessageAreas.CleanLanguage=1 THEN Temp := Clean_Language(Temp);
                     IF Is_Tear(Temp) THEN
                     BEGIN
                          IF Temp[1]=#1 THEN Delete(Temp,1,1);
                          Temp := '{'+_String(Colours.ReadMSGTearColour)+'}'+Temp
                     END
                     ELSE IF Is_Quote(Temp) THEN Temp := '{'+_String(Colours.ReadMsgQuote)+'}'+Temp
                     ELSE Temp := '{'+_String(Colours.ReadMsgBody)+'}'+Temp;
                     AddToPickList(Temp,0,False);
                END;
          UNTIL EOF(FMsgText);
          CLOSE(FMsgText);
          BeginPickList;
     END;

BEGIN
     outtathis := false;
     REPEAT
           temp := '';
           draw_msg_header;
           DisplayGraphicFile('MSGREAD2',True,True,True);
           SetScreenNumber(2);
           NewPickList(False);
           PickInfo.Current := 0;
           ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
           {$I-}
           RESET(FMsgText);
           {$I+}
           IF IOResult=0 THEN;
           REPEAT
                 IF NOT(EOF(FMsgText)) THEN
                 BEGIN
                      READ(FMsgText,MsgText);
                      Temp := MsgText.Line;
                      IF MessageAreas.CleanLanguage=1 THEN Temp := Clean_Language(Temp);
                      IF Is_Tear(Temp) THEN
                      BEGIN
                           IF Temp[1]=#1 THEN Delete(Temp,1,1);
                           Temp := '{'+_String(Colours.ReadMSGTearColour)+'}'+Temp
                      END
                      ELSE IF Is_Quote(Temp) THEN Temp := '{'+_String(Colours.ReadMsgQuote)+'}'+Temp
                      ELSE Temp := '{'+_String(Colours.ReadMsgBody)+'}'+Temp;
                      AddToPickList(Temp,0,False);
                 END;
           UNTIL EOF(FMsgText);
           CLOSE(FMsgText);
           BeginPickList;
           outtathis2 := false;
           REPEAT
                 {Set Up Valid Presses}
                 P3 := GetCommandKeyPress('READNEW',3);
                 P4 := GetCommandKeyPress('READNEW',4);
                 P5 := GetCommandKeyPress('READNEW',5);
                 P6 := GetCommandKeyPress('READNEW',6);
                 P7 := GetCommandKeyPress('READNEW',7);
                 Temp := P3+P5+P6+P7+#27;
                 IF (UserRecord.Security>=MessageAreas.Write_Access) THEN Temp := Temp+P4;
                 c := Get_Menu_Selection(Temp,Chr(0));
                 IF C=#2 THEN
                 BEGIN {PRINT MESSAGE}
                      bsWriteLog('Printing a message to the printer',True);
                      KillPickList;
                      ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                      ASSIGN(Scrap,CD_Directory+'\PRNFILE.$$$');
                      RESET(FMsgText);
                      REWRITE(Scrap);
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      WRITELN(Scrap,' *   Original By:  '+FastBaseHdr.MsgFrom);
                      WRITELN(Scrap,' *   Original To:  '+FastBaseHdr.MsgTo);
                      WRITELN(Scrap,' * Original Area:  '+MessageAreas.Area_Name);
                      WRITELN(Scrap,' * Original Date:  '+ProperDateToFancyDate(FastBaseHdr.MsgDate)+'   '+
                                    LongToStringTime(FastBaseHdr.MsgTime));
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      REPEAT
                            READ(FMsgText,MsgText);
                            WRITELN(Scrap,Remove_Special(MsgText.Line));
                      UNTIL EOF(FMsgText);
                      CLOSE(Scrap);
                      CLOSE(FMsgText);
                      IF FixedLPT=0 THEN
                      BEGIN
                           DisplayGraphicFile('PRNSEL',True,True,True);
                           c := UpCase(Get_Menu_Selection('123Q'+#27,#27));
                           CASE c OF
                           '1': FixedLPT := 1;
                           '2': FixedLPT := 2;
                           '3': FixedLPT := 3;
                           END;
                      END;
                      IF (FixedLPT<>0) THEN
                      BEGIN
                           PutStringTimeout(BBSPort,#255#133+_String(FixedLPT)+#13,YappDelay);
                           pCompressFile(CD_Directory+'\PRNFILE.$$$',CD_Directory+'\PRNFILE.CMP');
                           SendSystemFile(CD_Directory+'\PRNFILE.CMP');
                      END;
                      ERASE(Scrap);
                      RedrawMessage;
                 END
                 ELSE IF ((C=#1) OR (C=P5)) THEN
                 BEGIN {DOWNLOAD MESSAGE}
                      bsWriteLog('Downloading a message as a text file',True);
                      KillPickList;
                      ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                      ASSIGN(Scrap,CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                      RESET(FMsgText);
                      REWRITE(Scrap);
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      WRITELN(Scrap,' *   Original By:  '+FastBaseHdr.MsgFrom);
                      WRITELN(Scrap,' *   Original To:  '+FastBaseHdr.MsgTo);
                      WRITELN(Scrap,' * Original Area:  '+MessageAreas.Area_Name);
                      WRITELN(Scrap,' * Original Date:  '+ProperDateToFancyDate(FastBaseHdr.MsgDate)+'   '+
                                    LongToStringTime(FastBaseHdr.MsgTime));
                      WRITELN(Scrap,'--------------------------------------------------------------------------');
                      REPEAT
                            READ(FMsgText,MsgText);
                            WRITELN(Scrap,Remove_Special(MsgText.Line));
                      UNTIL EOF(FMsgText);
                      CLOSE(Scrap);
                      CLOSE(FMsgText);
                      dl_file(CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT',False);
                      ERASE(Scrap);
                      INC(RunningMessageDL);
                      RedrawMessage;
                 END
                 ELSE IF ((C=P7) OR (C=#27)) THEN
                 BEGIN
                      KillPickList;
                      outtathis  := true;
                      outtathis2 := true;
                      WhatToDo   := 0;
                 END
                 ELSE IF C=P3 THEN
                 BEGIN
                      KillPickList;
                      outtathis  := True;
                      Outtathis2 := True;
                      WhatToDo   := 1;
                 END
                 ELSE IF C=P4 THEN
                 BEGIN
                      KillPickList;
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
                      RedrawMessage;
                 END
                 ELSE IF C=P6 THEN
                 BEGIN
                      KillPickList;
                      outtathis  := True;
                      Outtathis2 := True;
                      WhatToDo   := 2;
                 END;
           UNTIL outtathis2;
     UNTIL (outtathis);
     Read_New_Mail := WhatToDo;
END;


END.