{$I DEFINES.INC}
UNIT ChangeFA;


INTERFACE


FUNCTION change_farea: boolean;


IMPLEMENTATION


USES Globals,MiscStr,SBuffer,Screens,KeyInput,GotKeys,
     TagArea,ANSIMisc,ToggFile,CDS,Commands,BsString;


FUNCTION change_farea: boolean;
VAR  count             : word;
     exit_here         : byte;
     top               : word;
     loop              : word;
     c                 : string;
     loop2             : word;
     loop3             : word;
     worker            : word;
     pages             : byte;
     current_p         : byte;
     selected_area     : boolean;
     cfa_areaid        : array[1..17] Of Word;
     Mark              : Longint;
     Bot               : Word;
     temp              : string;
     TaggingAll        : Boolean;
     Code              : Integer;
     P1,P2,P3,P4       : Char;
     P5,P6,P7,P8       : Char;
BEGIN
     TaggingAll  := True;
     count   := 0;
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     ASSIGN(FFileArea2,NODE_Directory+'\FFFFFFFF.FFF');
     REWRITE(FFileArea2);
     {$I-}RESET(FFileArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          WHILE NOT(EOF(FFileArea)) DO
          BEGIN
               READ(FFileArea,FileAreas);
               IF ((UserRecord.Security>=FileAreas.View_Access) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
               BEGIN
                    IF NOT(FileAreas.PassThrough) THEN
                    BEGIN
                         IF (FileAreas.CD_Rom<>0) THEN
                         BEGIN
                              IF IsCDToggled(FileAreas.CD_Rom) THEN
                              BEGIN
                                   INC(Count);
                                   WRITE(FFileArea2,FileAreas);
                              END;
                         END
                         ELSE
                         BEGIN
                              INC(Count);
                              WRITE(FFileArea2,FileAreas);
                         END;
                    END;
               END;
          END;
          CLOSE(FFileArea);
          CLOSE(FFileArea2);
     END
     ELSE
     BEGIN
          CLOSE(FFileArea2);
          ERASE(FFileArea2);
          Change_Farea := False;
          EXIT;
     END;
     pages         := (trunc((count-1)/17))+1;
     current_p     := 1;
     top           := 1;
     exit_here     := 0;
     selected_area := true;
     REPEAT
           ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
           RESET(FFileArea);
           SEEK(FFileArea,top-1);
           bot := top-1;
           ClearBuffer;
           FOR loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF NOT(EOF(FFileArea)) THEN
                BEGIN
                     READ(FFileArea,FileAreas);
                     INC(Bot);
                     cfa_areaid[Loop] := FileAreas.AreaID;
                     IF IsFileTagged(FileAreas.AreaID)
                        THEN AddToBuffer('@T'+Temp,#1+'*')
                        ELSE AddToBuffer('@T'+Temp,#1+' ');
                     AddToBuffer('@FILEAREANAME'+Temp,FileAreas.Area_Name);
                     AddToBuffer('@AN'+Temp,_String(top+Loop-1));
                     AddToBuffer('@AF'+Temp,_PadLeft(_String(FileAreas.Num_Files),6));
                     AddToBuffer('@BYTES'+Temp,_PadLeft(_String(FileAreas.Num_Bytes),9));
                END
                ELSE
                BEGIN
                     AddToBuffer('@FILEAREANAME',DontSend);
                     AddToBuffer('@AN'+Temp,DontSend);
                     AddToBuffer('@T'+Temp,DontSend);
                     AddToBuffer('@AF'+Temp,DontSend);
                     AddToBuffer('@BYTES'+Temp,DontSend);
                END;
           END;
           CLOSE(FFileArea);
           DisplayGraphicsFile('FAREAS',True,True,True,True,False);
           DoCommandString('FAREAS',1);
           DoCommandString('FAREAS',2);
           DoCommandString('FAREAS',3);
           DoCommandString('FAREAS',4);
           DoCommandString('FAREAS',5);
           DoCommandString('FAREAS',6);
           DoCommandString('FAREAS',7);
           DoCommandString('FAREAS',8);
           system_prompt('',1,false,True);
           P1 := GetCommandKeyPress('FAREAS',1);
           P2 := GetCommandKeyPress('FAREAS',2);
           P3 := GetCommandKeyPress('FAREAS',3);
           P4 := GetCommandKeyPress('FAREAS',4);
           P5 := GetCommandKeyPress('FAREAS',5);
           P6 := GetCommandKeyPress('FAREAS',6);
           P7 := GetCommandKeyPress('FAREAS',7);
           P8 := GetCommandKeyPress('FAREAS',8);
           c  := GETKEYORNUMBER(P1+P2+P3+P4+P5+P6+P7+P8,P1);
           IF NOT(numeric) THEN
           BEGIN
                IF c=P8 THEN
                BEGIN
                     selected_area := false;
                     exit_here     := 1;
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
                          system_prompt('',20,True,False);
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
                     ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
                     RESET(FFileArea);
                     REPEAT
                           READ(FFileArea,FileAreas);
                           ToggleFileArea(FileAreas.AreaID,TaggingAll);
                     UNTIL EOF(FFileArea);
                     CLOSE(FFileArea);
                     IF TaggingAll THEN TaggingAll := False
                                   ELSE TaggingAll := True;
                END
                ELSE IF c=P5 THEN
                BEGIN
                     SendCrLf(1);
                     System_Prompt('',34,false,False);
                     REPEAT
                           SendCrLf(1);
                           System_Prompt('',169,false,True);
                           Get_Number(5,'',False);
                           IF input_string<>'' THEN
                           BEGIN
                                VAL(input_string,mark,code);
                                IF ((mark<Top) OR (mark>Bot)) THEN
                                BEGIN
                                     SendCrLf(1);
                                     System_Prompt('',171,false,False);
                                END
                                ELSE IF ((mark>=Top) AND (mark<=Bot)) THEN
                                BEGIN
                                     ToggleFileArea(cfa_areaid[Mark-Top+1],True);
                                     FOR loop2 := LENGTH(input_string) TO 4 DO
                                     WRITECHAR(' ');
                                     System_Prompt('',172,false,False);
                                END;
                           END;
                     UNTIL input_string='';
                END
                ELSE IF c=P6 THEN
                BEGIN
                     SendCrLf(1);
                     System_Prompt('',34,false,False);
                     REPEAT
                           SendCrLf(1);
                           System_Prompt('',170,false,True);
                           Get_Number(5,'',False);
                           IF input_string<>'' THEN
                           BEGIN
                                VAL(input_string,mark,code);
                                IF ((mark<Top) OR (mark>Bot)) THEN
                                BEGIN
                                     SendCrLf(1);
                                     System_Prompt('',171,false,False);
                                END
                                ELSE IF ((mark>=Top) AND (mark<=Bot)) THEN
                                BEGIN
                                     ToggleFileArea(cfa_areaid[Mark-Top+1],False);
                                     FOR loop2 := LENGTH(input_string) TO 4 DO
                                     WRITECHAR(' ');
                                     System_Prompt('',173,false,False);
                                END;
                           END;
                     UNTIL input_string='';
                END;
           END
           ELSE
           BEGIN
                VAL(c,worker,code);
                IF ((worker>0) AND (worker<count+1)) THEN
                BEGIN
                     CurrentFileArea := worker;
                     exit_here := 1;
                END;
           END;
     UNTIL (exit_here=1);
     IF Selected_Area THEN
     BEGIN
          ASSIGN(FFileArea2,NODE_Directory+'\FFFFFFFF.FFF');
          RESET(FFileArea2);
          SEEK(FFileArea2,CurrentFileArea-1);
          READ(FFileArea2,FileAreas2);
          CLOSE(FFileArea2);
          Count := 0;
          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileAreas);
                INC(Count);
          UNTIL (FileAreas2.AreaID=FileAreas.AreaID);
          CLOSE(FFileArea);
          CurrentFileArea := Count;
     END;
     change_farea := selected_area;
END;


END.