{$I DEFINES.INC}
UNIT ReadMail;


INTERFACE


PROCEDURE read_message(area,override: word; FireUp: Boolean);
PROCEDURE draw_msg_header;


IMPLEMENTATION


USES SBuffer,Globals,Screens,Time,_Pick,GoodLang,WhatLine,Gr2_Bp,
     MiscStr,MFireUp,LstReads,KeyInput,JamGet,ChangeMa,MsgHeadr,
     JamStore,BsLog,Special,BsPrint,Download,MsgKill,WriteMsg,
     _Mouse,Dates,Commands,MiscMsg,BsAkas,BsString,BsFile;


PROCEDURE draw_msg_header;
VAR  draw_temp           : string;
BEGIN
     ClearBuffer;
     AddToBuffer('@HEADER','AREA:  '+MessageAreas.Area_Name);
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
     draw_temp := TranslateDate1(_Mid(FastBaseHdr.MsgDate,1,2)+'-'+
                  _Mid(FastBaseHdr.MsgDate,3,4)+'-'+
                  _Mid(FastBaseHdr.MsgDate,5,6));
     AddToBuffer('@MSGDATE',draw_temp);
END;


PROCEDURE read_message(area,override: word; FireUp: Boolean);
VAR  MsgText           : ARRAY[1..1] Of MessageTextLines;
     temp              : string;
     crap              : string;
     scrap             : text;
     outtathis         : boolean;
     outtathis2        : boolean;
     loop3             : word;
     loop4             : word;
     Message_There     : boolean;
     c                 : char;
     ReadingDirection  : Byte;    {1-Back 2-Stationary 3-Forward}
     DidIt             : Boolean;
     ReadingMessage    : Word;
     P1,P2,P3,P4,P5,P6 : Char;
     P7,P8,P9,P10,P11  : Char;
     LABEL               another_message;

     FUNCTION GetFromOld(TheOne : Word): Word;
     VAR  Work : Word;
          Loop : Word;
     BEGIN
          FOR Loop := 1 TO TotalMessages DO
          BEGIN
               IF MsgIndex^[Loop]=TheOne THEN Work := Loop;
          END;
          GetFromOld := Work;
     END;

     PROCEDURE RedrawMessage;
     BEGIN
          draw_msg_header;
          DisplayGraphicFile('MSGREADR',True,True,True);
          ScreenNumber := 2;
          NewPickList(False);
          PickInfo.Current := 0;
          ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
          {$I-}RESET(FMsgText);{$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     IF NOT(EOF(FMsgText)) THEN
                     BEGIN
                          READ(FMsgText,MsgText[1]);
                          Temp := MsgText[1].Line;
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
          END;
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
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
     IF UserLastReadMSG=0 THEN JamBase_SetLastRead(1);
     ReadingMessage   := UserLastReadMSG;
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
                System_Prompt('',77);
                Get_enter;
                EXIT;
           END;
           JamBase_GetMessage(ReadingMessage);
           IF CanSee=True THEN
           BEGIN
                draw_msg_header;
                DisplayGraphicFile('MSGREADR',True,True,True);
                ScreenNumber := 2;
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
                           READ(FMsgText,MsgText[1]);
                           Temp := MsgText[1].Line;
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
                HideTheMouse;
                BeginPickList;
                SetUpPickList;
                ShowTheMouse;
                outtathis2 := false;
                REPEAT
                      {Set Up Valid Presses}
                      P3  := GetCommandKeyPress('READMAIL',3);
                      P4  := GetCommandKeyPress('READMAIL',4);
                      P5  := GetCommandKeyPress('READMAIL',5);
                      P6  := GetCommandKeyPress('READMAIL',6);
                      P7  := GetCommandKeyPress('READMAIL',7);
                      P8  := GetCommandKeyPress('READMAIL',8);
                      P9  := GetCommandKeyPress('READMAIL',9);
                      P10 := GetCommandKeyPress('READMAIL',10);
                      P11 := GetCommandKeyPress('READMAIL',11);
                      Temp := P3+P4+P6+P11+#27;
                      IF CanKill THEN Temp := Temp+P7;
                      IF (UserRecord.Security>=MessageAreas.Write_Access) THEN Temp := Temp+P5;
                      IF UserRecord.Security>=system_info.MessageCopy THEN Temp := Temp+P8;
                      IF UserRecord.Security>=system_info.MessageMove THEN Temp := Temp+P9;
                      IF UserRecord.Security>=system_info.MessageForward THEN Temp := Temp+P10;
                      c := Get_Menu_Selection(Temp,Chr(0));
                      IF C=P3 THEN
                      BEGIN
                           KillPickList;
                           ReadingDirection := 3;
                           IF ReadingMessage<TotalMessages THEN
                           BEGIN
                                INC(ReadingMessage);
                                JamBase_SetLastRead(ReadingMessage);
                                GOTO another_message;
                           END
                           ELSE
                           BEGIN
                                outtathis  := true;
                                outtathis2 := true;
                                System_Prompt('',66);
                                Get_Enter;
                           END;
                      END
                      ELSE IF C=P4 THEN
                      BEGIN
                           ReadingDirection := 1;
                           IF ReadingMessage>1 THEN
                           BEGIN
                                KillPickList;
                                DEC(ReadingMessage);
                                JamBase_SetLastRead(ReadingMessage);
                                GOTO another_message;
                           END;
                      END
                      ELSE IF C=P5 THEN
                      BEGIN
                           KillPickList;
                           Loop3 := MsgIndex^[ReadingMessage];
                           WriteMessage(CurrentMessageSub,CurrentMessageArea,True,FastBaseHdr.MsgFrom);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           ReadingMessage := GetFromOld(Loop3);
                           JamBase_GetMessage(ReadingMessage);
                           RedrawMessage;
                      END
                      ELSE IF ((C=P6) OR (C=#1)) THEN
                      BEGIN
                           bsWriteLog('Downloading a message as a text file',False);
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
                                 READ(FMsgText,MsgText[1]);
                                 WRITELN(Scrap,Remove_Special(MsgText[1].Line));
                           UNTIL EOF(FMsgText);
                           CLOSE(Scrap);
                           CLOSE(FMsgText);
                           dl_file(CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                           ERASE(Scrap);
                           INC(RunningMessageDL);
                           RedrawMessage;
                      END
                      ELSE IF C=P7 THEN
                      BEGIN
                           KillPickList;
                           JamBase_DeleteMessage(ReadingMessage);
                           JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                           ReadingMessage := UserLastReadMsg;
                           GOTO another_message;
                      END
                      ELSE IF C=P8 THEN
                      BEGIN
                           KillPickList;
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
                           RedrawMessage;
                      END
                      ELSE IF C=P9 THEN
                      BEGIN
                           KillPickList;
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
                           RedrawMessage;
                      END
                      ELSE IF C=P10 THEN
                      BEGIN
                           KillPickList;
                           System_Prompt('',138);
                           Get_Enter;
                           IF Fields^[1].Text<>'' THEN
                           BEGIN
                                Loop3 := CurrentMessageArea;
                                Loop4 := CurrentMessageSub;
                                Temp  := CurrentMessageBase;
                                FastBaseHdr.MsgTo := Fields^[1].Text;
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
                           RedrawMessage;
                      END
                      ELSE IF ((C=P11) OR (C=#27)) THEN
                      BEGIN
                           KillPickList;
                           outtathis  := true;
                           outtathis2 := true;
                      END
                      ELSE IF C=#2 THEN
                      BEGIN
                           bsWriteLog('Printing a message to the printer',False);
                           KillPickList;
                           ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                           ASSIGN(Scrap,CD_Directory+'\PRNMSG.$$$');
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
                                 READ(FMsgText,MsgText[1]);
                                 WRITELN(Scrap,Remove_Special(MsgText[1].Line));
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
                                PrintStart(FixedLPT);
                                ASSIGN(Scrap,CD_Directory+'\PRNMSG.$$$');
                                RESET(Scrap);
                                REPEAT
                                      READLN(Scrap,Temp);
                                      PrintLine('  '+Temp);
                                UNTIL EOF(Scrap);
                                CLOSE(Scrap);
                                PrintEnd;
                           END;
                           ERASE(Scrap);
                           RedrawMessage;
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
                          System_Prompt('',78);
                          Get_enter;
                          OuttaThis := True;
                     END;
                END
                ELSE IF ReadingDirection=2 THEN
                BEGIN
                     System_Prompt('',116);
                     Get_enter;
                     OuttaThis := True;
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
                          System_Prompt('',78);
                          Get_enter;
                          OuttaThis := True;
                     END;
                END;
           END;
     UNTIL (outtathis);
END;


END.
