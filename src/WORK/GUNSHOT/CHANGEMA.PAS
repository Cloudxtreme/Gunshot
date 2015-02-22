{$I DEFINES.INC}
UNIT ChangeMA;


INTERFACE


FUNCTION ChangeMessageArea: boolean;


IMPLEMENTATION


USES Globals,SBuffer,Screens,MiscStr,GotKeys,BaseInfo,TagArea,ANSIMisc,
     KeyInput,ToggMsg,Commands,BsString;


FUNCTION ChangeMessageArea: boolean;
VAR  selected_area : boolean;
     count         : word;
     exit_here     : byte;
     top           : word;
     bot           : word;
     loop          : word;
     c             : string;
     loop2         : word;
     work          : word;
     pages         : byte;
     current_p     : byte;
     temp          : string;
     Messagefile   : Text;
     working_line  : string;
     working_word  : word;
     File_Count    : word;
     Mark          : Longint;
     NumberAreas   : Byte;
     cfa_tagged    : Array[1..17] Of Boolean;
     cfa_areaid    : Array[1..17] Of Word;
     cfa_area      : Array[1..17] Of String[40];
     cfa_msgs      : Array[1..17] Of Word;
     cfa_new       : Array[1..17] Of Boolean;
     TaggingAll    : Boolean;
     Code          : Integer;
     P1,P2,P3,P4   : Char;
     P5,P6,P7,P8   : Char;
     LABEL           skip_line,re_do_line;
BEGIN
     TaggingAll := True;
     count      := 0;
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     ASSIGN(FMessageArea2,NODE_Directory+'\MMMMMMMM.MMM');
     REWRITE(FMessageArea2);
     {$I-}RESET(FMessageArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          WHILE NOT(EOF(FMessageArea)) DO
          BEGIN
               READ(FMessageArea,MessageAreas);
               IF ((UserRecord.Security>=MessageAreas.Read_Access) AND
                  GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) THEN
               BEGIN
                    INC(Count);
                    WRITE(FMessageArea2,MessageAreas);
               END;
          END;
          CLOSE(FMessageArea);
          CLOSE(FMessageArea2);
     END
     ELSE
     BEGIN
          CLOSE(FMessageArea2);
          ERASE(FMessageArea2);
          ChangeMessageArea := False;
          EXIT;
     END;
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
           reset(FMessageArea);
           Seek(FMessageArea,(top-1));
           bot := top-1;
           NumberAreas := 0;
           FOR loop := top TO top+16 DO
           BEGIN
                IF NOT(EOF(FMessageArea)) THEN
                BEGIN
                     read(FMessageArea,MessageAreas);
                     Work := Loop-Top+1;
                     JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
                     cfa_msgs[Work]   := TotalMessages;
                     IF HighMsgNumber>UserLastReadMSG
                        THEN cfa_new[Work] := True
                        ELSE cfa_new[Work] := False;
                     cfa_area[Work]   := MessageAreas.area_name;
                     cfa_tagged[Work] := IsMsgTagged(MessageAreas.AreaID);
                     cfa_areaid[Work] := MessageAreas.AreaID;
                     INC(bot);
                     INC(NumberAreas);
                END;
           END;
           CLOSE(FMessageArea);
           ClearBuffer;
           FOR Loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF Loop<=NumberAreas THEN
                BEGIN
                     AddToBuffer('@MESSAGEAREANAME'+Temp,CFA_Area[Loop]);
                     AddToBuffer('@AN'+Temp,_String(top+Loop-1));
                     AddToBuffer('@AM'+Temp,_PadLeft(_String(cfa_msgs[Loop]),6));
                     IF Cfa_Tagged[Loop]=True
                        THEN AddToBuffer('@T'+Temp,#1+'*')
                        ELSE AddToBuffer('@T'+Temp,#1+' ');
                     IF Cfa_New[Loop]=True
                        THEN AddToBuffer('@N'+Temp,#1+'*')
                        ELSE AddToBuffer('@N'+Temp,#1+' ');
                END
                ELSE
                BEGIN
                     AddToBuffer('@MESSAGEAREANAME'+Temp,DontSend);
                     AddToBuffer('@AN'+Temp,DontSend);
                     AddToBuffer('@AM'+Temp,DontSend);
                     AddToBuffer('@N'+Temp,DontSend);
                     AddToBuffer('@T'+Temp,DontSend);
                END;
           END;
           DisplayGraphicsFile('MAREAS',True,True,True,True,False);
           DoCommandString('MAREAS',1);
           DoCommandString('MAREAS',2);
           DoCommandString('MAREAS',3);
           DoCommandString('MAREAS',4);
           DoCommandString('MAREAS',5);
           DoCommandString('MAREAS',6);
           DoCommandString('MAREAS',7);
           DoCommandString('MAREAS',8);
           system_prompt('',1,false,true);
           P1 := GetCommandKeyPress('MAREAS',1);
           P2 := GetCommandKeyPress('MAREAS',2);
           P3 := GetCommandKeyPress('MAREAS',3);
           P4 := GetCommandKeyPress('MAREAS',4);
           P5 := GetCommandKeyPress('MAREAS',5);
           P6 := GetCommandKeyPress('MAREAS',6);
           P7 := GetCommandKeyPress('MAREAS',7);
           P8 := GetCommandKeyPress('MAREAS',8);
           c  := GETKEYORNUMBER(P1+P2+P3+P4+P5+P6+P7+P8,P1);
           IF NOT(numeric) THEN
           BEGIN
                IF c=P8 THEN
                BEGIN
                     selected_area     := false;
                     ChangeMessageArea := false;
                     exit_here         := 1;
                END
                ELSE IF c=P1 THEN
                BEGIN
                     IF current_p<pages THEN
                     BEGIN
                          INC(current_p);
                          top := ((current_p-1)*17)+1;
                     END
                     ELSE
                     BEGIN
                          SendCrLf(1);
                          system_prompt('',119,True,False);
                          Get_Enter;
                     END;
                END
                ELSE IF ((c=P2) AND (current_p>1)) THEN
                BEGIN
                     DEC(current_p);
                     top       := ((current_p-1)*17)+1;
                END
                ELSE IF c=P3 THEN
                BEGIN
                     current_p := 1;
                     top       := 1;
                END
                ELSE IF c=P4 THEN
                BEGIN
                     current_p := pages;
                     top       := ((current_p-1)*17)+1;
                END
                ELSE IF c=P7 THEN
                BEGIN
                     ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
                     RESET(FMessageArea);
                     REPEAT
                           READ(FMessageArea,MessageAreas);
                           ToggleMsgArea(MessageAreas.AreaID,TaggingAll);
                     UNTIL EOF(FMessageArea);
                     CLOSE(FMessageArea);
                     IF TaggingAll THEN TaggingAll := False
                                   ELSE TaggingAll := True;
                END
                ELSE IF c=P5 THEN
                BEGIN
                     SendCrLf(1);
                     System_Prompt('',34,false,false);
                     REPEAT
                           SendCrLf(1);
                           System_Prompt('',169,false,true);
                           Get_Number(5,'',False);
                           IF input_string<>'' THEN
                           BEGIN
                                VAL(input_string,mark,code);
                                IF ((mark<Top) OR (mark>Bot)) THEN
                                BEGIN
                                     SendCrLf(1);
                                     System_Prompt('',171,false,false);
                                END
                                ELSE IF ((mark>=Top) AND (mark<=Bot)) THEN
                                BEGIN
                                     ToggleMsgArea(cfa_areaid[Mark-Top+1],True);
                                     FOR loop2 := LENGTH(input_string) TO 4 DO
                                     WRITECHAR(' ');
                                     System_Prompt('',172,false,false);
                                END;
                           END;
                     UNTIL input_string='';
                END
                ELSE IF c=P6 THEN
                BEGIN
                     SendCrLf(1);
                     System_Prompt('',34,false,false);
                     REPEAT
                           SendCrLf(1);
                           System_Prompt('',170,false,true);
                           Get_Number(5,'',False);
                           IF input_string<>'' THEN
                           BEGIN
                                VAL(input_string,mark,code);
                                IF ((mark<Top) OR (mark>Bot)) THEN
                                BEGIN
                                     SendCrLf(1);
                                     System_Prompt('',171,false,false);
                                END
                                ELSE IF ((mark>=Top) AND (mark<=Bot)) THEN
                                BEGIN
                                     ToggleMsgArea(cfa_areaid[Mark-Top+1],False);
                                     FOR loop2 := LENGTH(input_string) TO 4 DO
                                     WRITECHAR(' ');
                                     System_Prompt('',173,false,false);
                                END;
                           END;
                     UNTIL input_string='';
                END;
           END
           ELSE
           BEGIN
                VAL(c,work,code);
                IF ((work>0) AND (work<count+1)) THEN
                BEGIN
                     CurrentMessageArea := work;
                     exit_here          := 1;
                     ChangeMessageArea  := true;
                     selected_area      := true;
                END;
           END;
     UNTIL (exit_here=1);
     IF Selected_Area THEN
     BEGIN
          ASSIGN(FMessageArea2,NODE_Directory+'\MMMMMMMM.MMM');
          RESET(FMessageArea2);
          SEEK(FMessageArea2,CurrentMessageArea-1);
          READ(FMessageArea2,MessageAreas2);
          CLOSE(FMessageArea2);
          Count := 0;
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          REPEAT
                READ(FMessageArea,MessageAreas);
                INC(Count);
          UNTIL (MessageAreas2.AreaID=MessageAreas.AreaID);
          CLOSE(FMessageArea);
          CurrentMessageArea := Count;
     END;
     ChangeMessageArea := selected_area;
END;


END.
