{$I DEFINES.INC}
UNIT ListMsgs;


INTERFACE


PROCEDURE list_messages;


IMPLEMENTATION


USES Globals,MsgHeadr,JamList,MFireUp,SBuffer,Screens,ANSIMisc,KeyInput,
     GotoMsg,Commands,BsString;


PROCEDURE list_messages;
VAR  MsgList2          : Array[1..16] Of ListRecord;
     count_lines       : longint;
     pages             : word;
     outtahere         : boolean;
     current_page      : word;
     top               : word;
     c                 : string;
     loop              : word;
     temp              : string;
     working_line      : string;
     working_word      : word;
     loop2             : word;
     read_lines        : word;
     ansi_file         : text;
     TheLine           : String;
     Code              : Integer;
     P1,P2,P3,P4,P5,P6 : Char;
     HaveNextBot       : Boolean;
     HavePrevTop       : Boolean;
     Default           : Char;
     LABEL               OverAgain;
BEGIN
     SavePage := 0;
     OverAgain:
     Header2(CurrentMessageSub,CurrentMessageArea,True);
     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
     JamBase_ListMessages;
     ASSIGN(FMsgList,NODE_Directory+'\MSGLIST.$$$');
     {$I-}RESET(FMsgList);{$I+}
     IF IOResult=0 THEN
     BEGIN
          count_lines := FileSize(FMsgList);
          CLOSE(FMsgList);
     END
     ELSE count_lines := 0;
     pages        := (trunc((count_lines-1)/16))+1;
     outtahere    := false;
     current_page := 1;
     top          := 1;
     IF (SavePage<>0) THEN
     BEGIN
          IF (SavePage<=Pages) THEN
          BEGIN
               Current_Page := SavePage;
               Top          := ((SavePage-1)*16)+1;
          END;
     END;
     REPEAT
           read_lines := 0;
           ASSIGN(FMsgList,NODE_Directory+'\MSGLIST.$$$');
           RESET(FMsgList);
           SEEK(FMsgList,Top-1);
           FOR loop := 1 TO 16 DO
           BEGIN
                IF NOT(EOF(FMsgList)) THEN
                BEGIN
                     READ(FMsgList,MsgList2[Loop]);
                     INC(read_lines);
                END;
           END;
           CLOSE(FMsgList);
           ClearBuffer;
           FOR Loop := 1 TO 16 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF Loop<=Read_Lines THEN
                BEGIN
                     AddToBuffer('@MESSAGEFROM'+Temp,MsgList2[Loop].MsgFrom);
                     AddToBuffer('@MESSAGETO'+Temp,MsgList2[Loop].MsgTo);
                     AddToBuffer('@MESSAGESUBJECT'+Temp,MsgList2[Loop].MsgSubject);
                     AddToBuffer('@N'+Temp,_String(MsgList2[Loop].MsgNum));
                     IF MsgList2[Loop].MsgPrivate=True
                        THEN AddToBuffer('@P'+Temp,GetCommandString('MISC',1))
                        ELSE AddToBuffer('@P'+Temp,GetCommandString('MISC',2));
                END
                ELSE
                BEGIN
                     AddToBuffer('@MESSAGEFROM'+Temp,DontSend);
                     AddToBuffer('@MESSAGETO'+Temp,DontSend);
                     AddToBuffer('@MESSAGESUBJECT'+Temp,DontSend);
                     AddToBuffer('@N'+Temp,DontSend);
                     AddToBuffer('@P'+Temp,DontSend);
                END;
           END;
           DisplayGraphicsFile('LISTMSGS',True,True,True,True,False);
           P1 := GetCommandKeyPress('LISTMSGS',1);
           P2 := GetCommandKeyPress('LISTMSGS',2);
           P3 := GetCommandKeyPress('LISTMSGS',3);
           P4 := GetCommandKeyPress('LISTMSGS',4);
           P5 := GetCommandKeyPress('LISTMSGS',5);
           P6 := GetCommandKeyPress('LISTMSGS',6);
           HaveNextBot := False;
           HavePrevTop := False;
           IF current_page>1 THEN HavePrevTop := True;
           IF current_page<pages THEN HaveNextBot := True;
           IF HaveNextBot THEN Default := P1
                          ELSE Default := #0;
           IF HaveNextBot THEN Temp := P1+P4
                          ELSE Temp := '';
           IF HavePrevTop THEN Temp := Temp+P2+P3;
           IF HaveNextBot THEN DoCommandString('LISTMSGS',1);
           IF HavePrevTop THEN DoCommandString('LISTMSGS',2);
           IF HavePrevTop THEN DoCommandString('LISTMSGS',3);
           IF HaveNextBot THEN DoCommandString('LISTMSGS',4);
           DoCommandString('LISTMSGS',5);
           DoCommandString('LISTMSGS',6);
           system_prompt('',1,false,true);
           c  := GETKEYORNUMBER(Temp+P5+P6,Default);
           IF NOT(numeric) THEN
           BEGIN
                IF c=P5 THEN
                BEGIN
                     outtahere := true;
                END
                ELSE IF ((c=P1) AND (current_page<pages)) THEN
                BEGIN
                     INC(current_page);
                     top := ((current_page-1)*16)+1;
                END
                ELSE IF ((c=P2) AND (current_page>1)) THEN
                BEGIN
                     DEC(current_page);
                     top := ((current_page-1)*16)+1;
                END
                ELSE IF c=P3 THEN
                BEGIN
                     current_page := 1;
                     top := 1;
                END
                ELSE IF c=P6 THEN
                BEGIN
                     SavePage := Current_Page;
                     goto_message(0);
                     GOTO OverAgain;
                END
                ELSE IF c=P4 THEN
                BEGIN
                     current_page := pages;
                     top := ((current_page-1)*16)+1;
                END;
           END
           ELSE
           BEGIN
                SavePage := Current_Page;
                VAL(c,loop,code);
                goto_message(loop);
                GOTO OverAgain;
           END;
     UNTIL outtahere;
     SavePage := 0;
END;


END.