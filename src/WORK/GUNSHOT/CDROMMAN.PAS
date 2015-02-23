{$I DEFINES.INC}
UNIT CDRomMan;


INTERFACE


PROCEDURE CDRomManager;


IMPLEMENTATION


USES Globals,MiscStr,SBuffer,Screens,KeyInput,GotKeys,
     ANSIMisc,ToggCD,CDS,Commands,Gunshot,FilHeadr,BsString;


PROCEDURE CDRomManager;
VAR  count             : word;
     exit_here         : byte;
     top               : word;
     loop              : word;
     c                 : Char;
     loop2             : word;
     pages             : byte;
     current_p         : byte;
     CDRomNums         : Array[1..17] Of Word;
     Mark              : Longint;
     Bot               : Word;
     temp              : string;
     TaggingAll        : Boolean;
     FCDRoms2          : File Of _CDRom_Record;
     CDRoms2           : _CDRom_Record;
     FoundIt           : Boolean;
     NeedNext          : Boolean;
     NeedPrev          : Boolean;
     P1,P2,P3,P4       : Char;
     P5,P6,P7,P8       : Char;
BEGIN
     TaggingAll := True;
     count      := 0;
     ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
     {$I-}RESET(FCDRoms2);{$I+}
     IF IOResult=0 THEN
     BEGIN
          Count := FileSize(FCDRoms2);
          CLOSE(FCDRoms2);
     END
     ELSE Exit;
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
           RESET(FCDRoms2);
           SEEK(FCDRoms2,top-1);
           bot := top-1;
           ClearBuffer;
           FOR loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF NOT(EOF(FCDRoms2)) THEN
                BEGIN
                     READ(FCDRoms2,CDRoms2);
                     CDRomNums[Loop] := CDRoms2.CDNumber;
                     INC(Bot);
                     IF IsCDToggled(CDRoms2.CDNumber)
                        THEN AddToBuffer('@T'+Temp,#1+'*')
                        ELSE AddToBuffer('@T'+Temp,#1+' ');
                     AddToBuffer('@CD'+Temp,_String(top+Loop-1));
                     AddToBuffer('@CDROMNAME'+Temp,CDRoms2.CDName);
                     IF IsCDOnline(CDRoms2.CDNumber)
                        THEN AddToBuffer('@CDO'+Temp,GetCommandString('MISC',1))
                        ELSE AddToBuffer('@CDO'+Temp,GetCommandString('MISC',2));
                END
                ELSE
                BEGIN
                     AddToBuffer('@T'+Temp,DontSend);
                     AddToBuffer('@CD'+Temp,DontSend);
                     AddToBuffer('@CDROMNAME',DontSend);
                     AddToBuffer('@CDO'+Temp,DontSend);
                END;
           END;
           CLOSE(FCDRoms2);
           DisplayGraphicsFile('CDROMMAN',True,True,True,True,False);
           IF current_p<pages THEN NeedNext := True
                              ELSE NeedNext := False;
           IF current_p>1 THEN NeedPrev := True
                          ELSE NeedPrev := False;
           IF NeedNext THEN DoCommandString('CDROMMAN',1);
           IF NeedPrev THEN DoCommandString('CDROMMAN',2);
           IF NeedPrev THEN DoCommandString('CDROMMAN',3);
           IF NeedNext THEN DoCommandString('CDROMMAN',4);
           DoCommandString('CDROMMAN',5);
           DoCommandString('CDROMMAN',6);
           DoCommandString('CDROMMAN',7);
           DoCommandString('CDROMMAN',8);
           system_prompt('',1,false,True);
           P1 := GetCommandKeyPress('CDROMMAN',1);
           P2 := GetCommandKeyPress('CDROMMAN',2);
           P3 := GetCommandKeyPress('CDROMMAN',3);
           P4 := GetCommandKeyPress('CDROMMAN',4);
           P5 := GetCommandKeyPress('CDROMMAN',5);
           P6 := GetCommandKeyPress('CDROMMAN',6);
           P7 := GetCommandKeyPress('CDROMMAN',7);
           P8 := GetCommandKeyPress('CDROMMAN',8);
           Temp := P5+P6+P7+P8;
           IF NeedNext THEN Temp := Temp+P1+P4;
           IF NeedPrev THEN Temp := Temp+P2+P3;
           IF NeedNext THEN c  := Get_Menu_Selection(Temp,P1)
                       ELSE c  := Get_Menu_Selection(Temp,#0);
           IF c=P8 THEN
           BEGIN
                exit_here := 1;
           END
           ELSE IF c=P1 THEN
           BEGIN
                IF current_p<pages THEN
                BEGIN
                     INC(current_p);
                     top := ((current_p-1)*17)+1;
                END;
           END
           ELSE IF ((c=P2) AND (current_p>1)) THEN
           BEGIN
                DEC(current_p);
                top := ((current_p-1)*17)+1;
           END
           ELSE IF c=P3 THEN
           BEGIN
                current_p := 1;
                top := 1;
           END
           ELSE IF c=P4 THEN
           BEGIN
                current_p := pages;
                top := ((current_p-1)*17)+1;
           END
           ELSE IF c=P7 THEN
           BEGIN
                ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                RESET(FCDRoms2);
                REPEAT
                      READ(FCDRoms2,CDRoms2);
                      ToggleCDRom(CDRoms2.CDNumber,TaggingAll);
                UNTIL EOF(FCDRoms2);
                CLOSE(FCDRoms2);
                IF TaggingAll THEN TaggingAll := False
                              ELSE TaggingAll := True;
           END
           ELSE IF c=P5 THEN
           BEGIN
                SendCrLf(2);
                System_Prompt('',34,false,False);
                REPEAT
                      SendCrLf(1);
                      System_Prompt('',190,false,True);
                      Get_Number(5,'',False);
                      IF input_string<>'' THEN
                      BEGIN
                           Mark := _Numeric(input_string);
                           FoundIt := False;
                           ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                           RESET(FCDRoms2);
                           REPEAT
                                 READ(FCDRoms2,CDRoms2);
                                 IF CDRoms2.CDNumber=Mark THEN FoundIt := True;
                           UNTIL ((FoundIt) OR (EOF(FCDRoms2)));
                           CLOSE(FCDRoms2);
                           IF FoundIt THEN
                           BEGIN
                                ToggleCDRom(CDRoms2.CDNumber,True);
                                FOR loop2 := LENGTH(input_string) TO 4 DO
                                WRITECHAR(' ');
                                System_Prompt('',192,false,False);
                           END
                           ELSE
                           BEGIN
                                SendCrLf(1);
                                System_Prompt('',191,false,False);
                           END;
                      END;
                UNTIL input_string='';
           END
           ELSE IF c=P6 THEN
           BEGIN
                SendCrLf(2);
                System_Prompt('',34,false,False);
                REPEAT
                      SendCrLf(1);
                      System_Prompt('',193,false,True);
                      Get_Number(5,'',False);
                      IF input_string<>'' THEN
                      BEGIN
                           Mark := _Numeric(input_string);
                           FoundIt := False;
                           ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                           RESET(FCDRoms2);
                           REPEAT
                                 READ(FCDRoms2,CDRoms2);
                                 IF CDRoms2.CDNumber=Mark THEN FoundIt := True;
                           UNTIL ((FoundIt) OR (EOF(FCDRoms2)));
                           CLOSE(FCDRoms2);
                           IF FoundIt THEN
                           BEGIN
                                ToggleCDRom(CDRoms2.CDNumber,False);
                                FOR loop2 := LENGTH(input_string) TO 4 DO
                                WRITECHAR(' ');
                                System_Prompt('',194,false,False);
                           END
                           ELSE
                           BEGIN
                                SendCrLf(1);
                                System_Prompt('',191,false,False);
                           END;
                      END;
                UNTIL input_string='';
           END;
     UNTIL (exit_here=1);
     Header(CurrentFileSub,CurrentFileArea,True);
END;


END.
