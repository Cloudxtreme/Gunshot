{$I DEFINES.INC}
UNIT UserList;


INTERFACE


PROCEDURE ShowUserList;


IMPLEMENTATION


USES Globals,BsLog,KeyInput,SBuffer,Screens,Gfx,Shotgun,BsString,BsFile;


PROCEDURE ShowUserList;
VAR  FUserRecord3 : File Of _UsersBBS_Record;
     FUserRecord4 : File Of _UsersBBS_Record;
     UserRecord3  : _UsersBBS_Record;
     OuttaHere    : Boolean;
     Temp         : String;
     Crap         : String;
     C            : Char;
     WroteAny     : Boolean;
BEGIN
     bsWriteLog('Browsing the user list',True);
     WroteAny := False;
     System_Prompt('',61);
     Get_Enter;
     Fields[1].Text := _UpperCase(Fields[1].Text);
     IF Fields[1].Text='' THEN
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
                     WroteAny := True;
                     WRITE(FUserRecord4,UserRecord3);
                END;
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
                     IF ((Pos(Fields[1].Text,_UpperCase(UserRecord3.Name))<>0) OR
                        (Pos(Fields[1].Text,_UpperCase(UserRecord3.Alias))<>0)) THEN
                     BEGIN
                          WroteAny := True;
                          WRITE(FUserRecord4,UserRecord3);
                     END;
                END;
          UNTIL EOF(FUserRecord3);
          CLOSE(FUserRecord3);
          CLOSE(FUserRecord4);
     END;
     IF NOT(WroteAny) THEN Exit;
     IF DisplayGraphicFile('USERLIST',False,True,True) THEN
     BEGIN
          NewPickList(False);
          PickInfo.Current := 0;
          ASSIGN(FUserRecord3,NODE_Directory+'\USERS.$$$');
          RESET(FUserRecord3);
          REPEAT
                READ(FUserRecord3,UserRecord3);
                CASE Names.UserList OF
                0:   Crap := _PadRight(UserRecord3.Name,30);
                1:   IF UserRecord3.Alias=''
                        THEN Crap := _PadRight(UserRecord3.Name,30)
                        ELSE Crap := _PadRight(UserRecord3.Alias,30);
                END;
                Temp := '  '+_PadRight(_String(UserRecord3.User_Number),8)+
                        Crap+_PadRight(UserRecord3.city+', '+UserRecord3.prov,30);
                AddToPickList(Temp,0,False);
          UNTIL EOF(FUserRecord3);
          CLOSE(FUserRecord3);
          BeginPickList;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13,
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
     _EraseFile(NODE_Directory+'\USERS.$$$');
END;


END.