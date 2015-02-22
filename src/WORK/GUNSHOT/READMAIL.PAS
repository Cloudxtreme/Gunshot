{$I DEFINES.INC}
UNIT ReadMail;


INTERFACE


PROCEDURE read_message(area,override: word; FireUp: Boolean);
PROCEDURE draw_msg_header;


IMPLEMENTATION


USES SBuffer,Globals,Time,Screens,MiscStr,MFireUp,LstReads,ANSIMisc,
     KeyInput,JamGet,GoodLang,WhatLine,ChangeMA,MsgHeadr,JamStore,
     MiscMsg,BsLog,Special,Download,MsgKill,WriteMsg,Dates,Commands,
     BsAkas,BsString,BsFile;


PROCEDURE draw_msg_header;
VAR  draw_temp : string;
BEGIN
     ClearBuffer;
     IF ((MessageAreas.Area_Type<20) OR (MessageAreas.Area_Type>29)) THEN
     BEGIN
          AddToBuffer('@MESSAGEFROM',FastBaseHdr.MsgFrom);
          AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo);
     END
     ELSE
     BEGIN
          AddToBuffer('@MESSAGEFROM',FastBaseHdr.MsgFrom+' ('+AddressToString(FastBaseHdr.Orig)+')');
          AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo+' ('+AddressToString(FastBaseHdr.Dest)+')');
     END;
     AddToBuffer('@MESSAGESUBJECT',FastBaseHdr.MsgSubject);
     AddToBuffer('@MSG#',_String(CurrentMessage));
     AddToBuffer('@MSGS',_String(TotalMessages));
     AddToBuffer('@TIME',LongToStringTime(FastBaseHdr.MsgTime));
     draw_temp := '';
     IF FastBaseHdr.Delete      THEN draw_temp := draw_temp+'*';
     IF FastBaseHdr.Local       THEN draw_temp := draw_temp+'Loc ';
     IF FastBaseHdr.Recv        THEN draw_temp := draw_temp+'Rcvd ';
     IF FastBaseHdr.Priv        THEN draw_temp := draw_temp+'Priv ';
     IF FastBaseHdr.Crash       THEN draw_temp := draw_temp+'Crash ';
     IF FastBaseHdr.Hold        THEN draw_temp := draw_temp+'Hold ';
     IF FastBaseHdr.FileAttach  THEN draw_temp := draw_temp+'File ';
     IF FastBaseHdr.FileRequest THEN draw_temp := draw_temp+'Freq ';
     IF FastBaseHdr.Local THEN
     BEGIN
          IF FastBaseHdr.Sent     THEN draw_temp := draw_temp+'Sent ';
          IF FastBaseHdr.KillSent THEN draw_temp := draw_temp+'Kill/Sent ';
     END;
     AddToBuffer('@MESSAGEFLAGS',draw_temp);
     draw_temp := TranslateDate1(FastBaseHdr.MessageDate);
     AddToBuffer('@MSGDATE',draw_temp);
     DisplayGraphicsFile('MSGHEADR',true,true,True,True,False);
END;


PROCEDURE read_message(area,override: word; FireUp: Boolean);
VAR  MsgText           : MessageTextLines;
     pages             : word;
     page_count        : word;
     page              : word;
     temp              : string;
     crap              : string;
     scrap             : text;
     outtathis         : boolean;
     outtathis2        : boolean;
     loop3             : word;
     loop4             : word;
     count_lines       : word;
     quote             : boolean;
     tear              : boolean;
     Message_There     : boolean;
     top               : word;
     c                 : char;
     ReadingDirection  : Byte;    {1-Back 2-Stationary 3-Forward}
     DidIt             : Boolean;
     ReadingMessage    : Word;
     MaxLines          : Byte;
     P1,P2,P3,P4,P5,P6 : Char;
     P7,P8,P9,P10,P11  : Char;
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

BEGIN
     IF FireUp THEN
     BEGIN
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          reset(FMessageArea);
          Seek(FMessageArea,(area-1));
          read(FMessageArea,MessageAreas);
          close(FMessageArea);
          JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
     END;
     outtathis := false;
     IF UserLastReadMSG=0 THEN
     BEGIN
          JamBase_SetLastRead(1);
     END;
     ReadingMessage := UserLastReadMSG;

     ReadingDirection := 3;
     IF Override<>0 THEN
     BEGIN
          JamBase_SetLastRead(override);
          ReadingDirection := 2;
          ReadingMessage   := Override;
     END;
     REPEAT
           another_message:
           temp := '';

           {NO MESSAGES}
           IF TotalMessages=0 THEN
           BEGIN
                SendCrLf(2);
                System_Prompt('',77,true,false);
                Get_enter;
                EXIT;
           END;

           JamBase_GetMessage(ReadingMessage);
           IF CanSee=True THEN
           BEGIN
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
                      {$I-}
                      RESET(FMsgText);
                      SEEK(FMsgText,top-1);
                      {$I+}
                      IF IOResult=0 THEN;
                      REPEAT
                            IF NOT(EOF(FMsgText)) THEN
                            BEGIN
                                 READ(FMsgText,MsgText);
                                 IF MessageAreas.CleanLanguage=1 THEN
                                    MsgText.Line := Clean_Language(MsgText.Line);
                                 INC(count_lines);
                                 quote  := Is_Quote(MsgText.Line);
                                 tear   := Is_Tear(MsgText.Line);
                                 IF tear THEN FORE(Colours.ReadMSGTearColour)
                                    ELSE IF Quote THEN FORE(Colours.ReadMSGQuoteColour)
                                    ELSE FORE(Colours.ReadMSGBodyColour);
                                 WRITEANSI(MsgText.Line,true,true);
                            END;
                      UNTIL ((count_lines=MaxLines) OR (EOF(FMsgText)));
                      CLOSE(FMsgText);
                      SendCrLf(1);
                      DoCommandString('READMAIL',1);
                      DoCommandString('READMAIL',2);
                      DoCommandString('READMAIL',3);
                      DoCommandString('READMAIL',4);
                      IF (UserRecord.Security>=MessageAreas.Write_Access) THEN DoCommandString('READMAIL',5);
                      DoCommandString('READMAIL',6);
                      IF CanKill THEN DoCommandString('READMAIL',7);
                      IF UserRecord.Security>=system_info.MessageCopy THEN DoCommandString('READMAIL',8);
                      IF UserRecord.Security>=system_info.MessageMove THEN DoCommandString('READMAIL',9);
                      IF UserRecord.Security>=system_info.MessageForward THEN DoCommandString('READMAIL',10);
                      DoCommandString('READMAIL',11);
                      SendCrLf(1);
                      system_prompt('',1,false,true);
                      P1  := GetCommandKeyPress('READMAIL',1);
                      P2  := GetCommandKeyPress('READMAIL',2);
                      P3  := GetCommandKeyPress('READMAIL',3);
                      P4  := GetCommandKeyPress('READMAIL',4);
                      P5  := GetCommandKeyPress('READMAIL',5);
                      P6  := GetCommandKeyPress('READMAIL',6);
                      P7  := GetCommandKeyPress('READMAIL',7);
                      P8  := GetCommandKeyPress('READMAIL',8);
                      P9  := GetCommandKeyPress('READMAIL',9);
                      P10 := GetCommandKeyPress('READMAIL',10);
                      P11 := GetCommandKeyPress('READMAIL',11);
                      Temp := P1+P2+P3+P4+P6+P11;
                      IF CanKill THEN Temp := Temp+P7;
                      IF (UserRecord.Security>=MessageAreas.Write_Access) THEN Temp := Temp+P5;
                      IF UserRecord.Security>=system_info.MessageCopy THEN Temp := Temp+P8;
                      IF UserRecord.Security>=system_info.MessageMove THEN Temp := Temp+P9;
                      IF UserRecord.Security>=system_info.MessageForward THEN Temp := Temp+P10;
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
                                ReadingDirection := 3;
                                IF ReadingMessage<TotalMessages THEN
                                BEGIN
                                     INC(ReadingMessage);
                                     JamBase_SetLastRead(ReadingMessage+1);
                                     GOTO another_message;
                                END
                                ELSE
                                BEGIN
                                     SendCrLf(2);
                                     System_Prompt('',66,true,false);
                                     Get_Enter;
                                     EXIT;
                                END;
                           END;
                      END
                      ELSE IF C=P3 THEN
                      BEGIN
                           ReadingDirection := 3;
                           IF ReadingMessage<TotalMessages THEN
                           BEGIN
                                INC(ReadingMessage);
                                JamBase_SetLastRead(ReadingMessage);
                                GOTO another_message;
                           END
                           ELSE
                           BEGIN
                                SendCrLf(2);
                                System_Prompt('',66,true,false);
                                Get_Enter;
                                EXIT;
                           END;
                      END
                      ELSE IF C=P4 THEN
                      BEGIN
                           ReadingDirection := 1;
                           IF ReadingMessage>1 THEN
                           BEGIN
                                DEC(ReadingMessage);
                                JamBase_SetLastRead(ReadingMessage);
                                GOTO another_message;
                           END;
                      END
                      ELSE IF C=P5 THEN
                      BEGIN
                           loop3 := MsgIndex[ReadingMessage];
                           WriteMessage(CurrentMessageSub,CurrentMessageArea,True,FastBaseHdr.MsgFrom);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           ReadingMessage := GetFromOld(Loop3);
                           JamBase_GetMessage(ReadingMessage);
                      END
                      ELSE IF C=P6 THEN
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
                      ELSE IF C=P7 THEN
                      BEGIN
                           JamBase_DeleteMessage(ReadingMessage);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           ReadingMessage:=UserLastReadMsg;
                           GOTO another_message;
                      END
                      ELSE IF C=P8 THEN
                      BEGIN
                           Loop3 := CurrentMessageArea;
                           Loop4 := CurrentMessageSub;
                           CurrentMessageSub := 0;
                           IF ChangeMessageArea=True THEN
                           BEGIN
                                _EraseFile(NODE_Directory+'\WRITE.$$$');
                                ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                                RENAME(FMsgText,NODE_Directory+'\WRITE.$$$');
                                Header2(CurrentMessageSub,CurrentMessageArea,True);
                                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                                JamBase_StoreMessage(False);
                           END;
                           Header2(Loop4,Loop3,True);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           JamBase_GetMessage(ReadingMessage);
                      END
                      ELSE IF C=P9 THEN
                      BEGIN
                           Loop3 := CurrentMessageArea;
                           Loop4 := CurrentMessageSub;
                           DidIt := False;
                           CurrentMessageSub := 0;
                           IF ChangeMessageArea=True THEN
                           BEGIN
                                _EraseFile(NODE_Directory+'\WRITE.$$$');
                                ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                                RENAME(FMsgText,NODE_Directory+'\WRITE.$$$');
                                Header2(CurrentMessageSub,CurrentMessageArea,True);
                                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                                JamBase_StoreMessage(False);
                                DidIt := True;
                           END;
                           Header2(Loop4,Loop3,True);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           JamBase_GetMessage(ReadingMessage);
                           IF DidIt=True THEN
                           BEGIN
                                JamBase_DeleteMessage(ReadingMessage);
                                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                                ReadingMessage:=UserLastReadMsg;
                                GOTO another_message;
                           END;
                      END
                      ELSE IF C=P10 THEN
                      BEGIN
                           SendCrLf(2);
                           System_Prompt('',138,true,false);
                           Get_Name(30,'',True,False);
                           SendCrLf(1);
                           IF Input_String<>'' THEN
                           BEGIN
                                Loop3 := CurrentMessageArea;
                                Loop4 := CurrentMessageSub;
                                Temp  := CurrentMessageBase;
                                FastBaseHdr.MsgTo := Input_String;
                                CurrentMessageSub := 0;
                                IF ChangeMessageArea=True THEN
                                BEGIN
                                     _EraseFile(NODE_Directory+'\WRITE.$$$');
                                     ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                                     RENAME(FMsgText,NODE_Directory+'\WRITE.$$$');
                                     Header2(CurrentMessageSub,CurrentMessageArea,True);
                                     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                                     JamBase_StoreMessage(False);
                                END;
                                CurrentMessageBase := Temp;
                                Header2(Loop4,Loop3,True);
                                JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                                JamBase_GetMessage(ReadingMessage);
                           END;
                      END
                      ELSE IF C=P11 THEN
                      BEGIN
                           outtathis  := true;
                           outtathis2 := true;
                      END;
                UNTIL outtathis2;
           END
           ELSE
           BEGIN {MESSAGE IS PRIVATE!!}
                IF ReadingDirection=1 THEN
                BEGIN
                     IF ReadingMessage>1 THEN
                     BEGIN
                          JamBase_SetLastRead(ReadingMessage-1);
                          DEC(ReadingMessage);
                     END
                     ELSE
                     BEGIN
                          SendCrLf(2);
                          System_Prompt('',78,true,false);
                          Get_enter;
                          EXIT;
                     END;
                END
                ELSE IF ReadingDirection=2 THEN
                BEGIN
                     SendCrLf(2);
                     System_Prompt('',116,true,false);
                     Get_enter;
                     EXIT;
                END
                ELSE IF ReadingDirection=3 THEN
                BEGIN
                     IF ReadingMessage<TotalMessages THEN
                     BEGIN
                          JamBase_SetLastRead(ReadingMessage+1);
                          INC(ReadingMessage);
                     END
                     ELSE
                     BEGIN
                          SendCrLf(2);
                          System_Prompt('',78,true,false);
                          Get_enter;
                          EXIT;
                     END;
                END;
           END;
     UNTIL (outtathis);
END;


END.
