{$I DEFINES.INC}
UNIT ViewTFil;


INTERFACE


PROCEDURE view_text_file(work_file,title: string);


IMPLEMENTATION


USES Globals,ANSIMisc,KeyInput,Screens,SBuffer,ErrorLog,Commands,
     BsFile,BsString;


PROCEDURE view_text_file(work_file,title: string);
TYPE working2 = RECORD
     line2    : String[79];
     END;
VAR  work_file2     : file of working2;
     work_line2     : array[1..17] of working2;
     work_file3     : text;
     count_lines    : word;
     pages          : word;
     current_page   : word;
     outtahere      : boolean;
     top            : word;
     loop           : word;
     working_line   : string;
     temp           : string;
     c              : char;
     Work           : Word;
     P1,P2,P3,P4,P5 : Char;
     Default        : Char;
     HaveNextBot    : Boolean;
     HavePrevTop    : Boolean;
BEGIN
     count_lines := 0;
     IF _FileExists(work_file) THEN
     BEGIN
          ASSIGN(work_file2,NODE_Directory+'\READ.$$$');
          REWRITE(work_file2);
          ASSIGN(work_file3,work_file);
          RESET(work_file3);
          REPEAT
                READLN(work_file3,working_line);
                REPEAT
                      Work := Pos(#9,working_line);
                      IF Work<>0 THEN
                      BEGIN
                           Delete(working_line,Work,1);
                           Insert('        ',working_line,Work);
                      END;
                UNTIL Work=0;
                REPEAT
                      Work := Pos(#12,working_line);
                      IF work<>0 THEN working_line[Work] := #32;
                UNTIL work=0;
                work_line2[1].line2 := working_line;
                WRITE(work_file2,work_line2[1]);
                INC(count_lines);
          UNTIL EOF(work_file3);
          CLOSE(work_file3);
          CLOSE(work_file2);
          pages        := (trunc((count_lines-1)/17))+1;
          outtahere    := false;
          current_page := 1;
          top          := 1;
          REPEAT
                ASSIGN(work_file2,NODE_Directory+'\READ.$$$');
                RESET(work_file2);
                SEEK(work_file2,top-1);
                ClearBuffer;
                AddToBuffer('@HEADER',title);
                FOR loop := 1 TO 17 DO
                BEGIN
                     Temp := _String(Loop);
                     IF Length(Temp)=1 THEN Temp := '0'+Temp;
                     IF NOT(EOF(work_file2)) THEN
                     BEGIN
                          READ(work_file2,work_line2[loop]);
                          AddToBuffer('@LINE'+Temp,work_line2[Loop].line2)
                     END
                     ELSE AddToBuffer('@LINE'+Temp,'');
                END;
                CLOSE(work_file2);
                DisplayGraphicsFile('READFILE',True,True,True,True,False);
                P1 := GetCommandKeyPress('READFILE',1);
                P2 := GetCommandKeyPress('READFILE',2);
                P3 := GetCommandKeyPress('READFILE',3);
                P4 := GetCommandKeyPress('READFILE',4);
                P5 := GetCommandKeyPress('READFILE',5);
                HaveNextBot := False;
                HavePrevTop := False;
                IF current_page>1 THEN HavePrevTop := True;
                IF current_page<pages THEN HaveNextBot := True;
                IF HaveNextBot THEN Default := P1
                               ELSE Default := #0;
                IF HaveNextBot THEN Temp := P1+P4
                               ELSE Temp := '';
                IF HavePrevTop THEN Temp := Temp+P2+P3;
                IF HaveNextBot THEN DoCommandString('READFILE',1);
                IF HavePrevTop THEN DoCommandString('READFILE',2);
                IF HavePrevTop THEN DoCommandString('READFILE',3);
                IF HaveNextBot THEN DoCommandString('READFILE',4);
                DoCommandString('READFILE',5);
                system_prompt('',1,false,True);
                c  := Get_Menu_Selection(Temp+P5,Default);
                IF c=P5 THEN
                BEGIN
                     outtahere := true;
                END
                ELSE IF c=P1 THEN
                BEGIN
                     INC(current_page);
                     top := ((current_page-1)*17)+1;
                END
                ELSE IF c=P2 THEN
                BEGIN
                     DEC(current_page);
                     top := ((current_page-1)*17)+1;
                END
                ELSE IF c=P3 THEN
                BEGIN
                     current_page := 1;
                     top := 1;
                END
                ELSE IF c=P4 THEN
                BEGIN
                     current_page := pages;
                     top := ((current_page-1)*17)+1;
                END;
          UNTIL outtahere;
     END
     ELSE DoErrorLog(34,work_file);
END;


END.
