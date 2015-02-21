{$I DEFINES.INC}
UNIT UserList;


INTERFACE


PROCEDURE ShowUserList;


IMPLEMENTATION


USES Globals,BsLog,ANSIMisc,KeyInput,SBuffer,
     Screens,Commands,Shotgun,BsString,BsFile;


PROCEDURE ShowUserList;
VAR  FUserRecord3   : File Of _UsersBBS_Record;
     FUserRecord4   : File Of _UsersBBS_Record;
     UserRecord3    : _UsersBBS_Record;
     exit_here      : byte;
     top            : word;
     c              : char;
     pages          : byte;
     current_p      : byte;
     working_line   : string;
     working_word   : word;
     count          : Word;
     Loop           : Word;
     Loop2          : Word;
     Loop3          : Word;
     messagefile    : text;
     Temp           : String;
     P1,P2,P3,P4,P5 : Char;
BEGIN
     bsWriteLog('Browsing the user list',False);
     SendCrLf(2);
     System_Prompt('',61,false,true);
     Get_String(30,'',True,False,True,False);
     SendCrLf(1);
     IF Input_String='' THEN
     BEGIN
          ASSIGN(FUserRecord3,DATA_Directory+'\USERS.BBS');
          ASSIGN(FUserRecord4,NODE_Directory+'\USERS.$$$');
          RESET(FUserRecord3);
          REWRITE(FUserRecord4);
          READ(FUserRecord3,UserRecord3);
          REPEAT
                READ(FUserRecord3,UserRecord3);
                IF UserRecord3.Userlist=1 THEN
                   WRITE(FUserRecord4,UserRecord3);
          UNTIL EOF(FUserRecord3);
          CLOSE(FUserRecord3);
          CLOSE(FUserRecord4);
     END
     ELSE
     BEGIN
          ASSIGN(FUserRecord3,DATA_Directory+'\USERS.BBS');
          ASSIGN(FUserRecord4,NODE_Directory+'\USERS.$$$');
          RESET(FUserRecord3);
          REWRITE(FUserRecord4);
          READ(FUserRecord3,UserRecord3);
          REPEAT
                READ(FUserRecord3,UserRecord3);
                IF UserRecord3.Userlist=1 THEN
                BEGIN
                     IF ((Pos(Input_string,_UpperCase(UserRecord3.Name))<>0) OR
                        (Pos(Input_string,_UpperCase(UserRecord3.Alias))<>0)) THEN
                        WRITE(FUserRecord4,UserRecord3);
                END;
          UNTIL EOF(FUserRecord3);
          CLOSE(FUserRecord3);
          CLOSE(FUserRecord4);
     END;
     ASSIGN(FUserRecord3,NODE_Directory+'\USERS.$$$');
     RESET(FUserRecord3);
     count := FileSize(FUserRecord3);
     CLOSE(FUserRecord3);
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           ClearBuffer;
           ASSIGN(FUserRecord3,NODE_Directory+'\USERS.$$$');
           RESET(FUserRecord3);
           SEEK(FUserRecord3,Top-1);
           FOR loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF LENGTH(Temp)=1 THEN Temp := '0'+Temp;
                IF NOT(EOF(FUserRecord3)) THEN
                BEGIN
                     READ(FUserRecord3,UserRecord3);
                     AddToBuffer('@UN'+Temp,_String(UserRecord3.User_Number));
                     CASE Names.UserList OF
                     0:   AddToBuffer('@USERSNAME'+Temp,UserRecord3.Name);
                     1:   IF UserRecord3.Alias=''
                             THEN AddToBuffer('@USERSNAME'+Temp,UserRecord3.Name)
                             ELSE AddToBuffer('@USERSNAME'+Temp,UserRecord3.Alias);
                     END;
                     AddToBuffer('@USERSLOCATION'+Temp,UserRecord3.city+', '+UserRecord3.prov);
                END
                ELSE
                BEGIN
                     AddToBuffer('@UN'+Temp,'');
                     AddToBuffer('@USERSNAME'+Temp,DontSend);
                     AddToBuffer('@USERSLOCATION'+Temp,DontSend);
                END;
           END;
           CLOSE(FUserRecord3);
           DisplayGraphicsFile('USERLIST',True,True,True,True,False);
           DoCommandString('USERLIST',1);
           DoCommandString('USERLIST',2);
           DoCommandString('USERLIST',3);
           DoCommandString('USERLIST',4);
           DoCommandString('USERLIST',5);
           system_prompt('',1,false,true);
           P1 := GetCommandKeyPress('USERLIST',1);
           P2 := GetCommandKeyPress('USERLIST',2);
           P3 := GetCommandKeyPress('USERLIST',3);
           P4 := GetCommandKeyPress('USERLIST',4);
           P5 := GetCommandKeyPress('USERLIST',5);
           c  := Get_Menu_Selection(P1+P2+P3+P4+P5,P1);
           IF c=P5 THEN
           BEGIN
                exit_here := 1;
           END
           ELSE IF ((c=P1) AND (current_p<pages)) THEN
           BEGIN
                INC(current_p);
                top := ((current_p-1)*17)+1;
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
           END;
     UNTIL (exit_here=1);
     _EraseFile(NODE_Directory+'\USERS.$$$');
END;


END.