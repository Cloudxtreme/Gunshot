{$I DEFINES.INC}
UNIT DoorFile;


INTERFACE


PROCEDURE CreateCustomDropFile(ScriptFile,DropFile: String);
PROCEDURE make_door_files(NType,BType: Byte);


IMPLEMENTATION


USES Special,ErrorLog,Globals,Time,Dates,BsString,BsTime,BsFile;


PROCEDURE CreateCustomDropFile(ScriptFile,DropFile: String);
VAR  TFile  : Text;
     SFile  : Text;
     Temp   : String;
BEGIN
     ASSIGN(SFile,Process_Special(ScriptFile,False));
     {$I-}RESET(SFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          ASSIGN(TFile,Process_Special(DropFile,False));
          REWRITE(TFile);
          REPEAT
                READLN(SFile,Temp);
                Temp := Process_Special(Temp,False);
                WRITELN(TFile,Temp);
          UNTIL EOF(SFile);
          CLOSE(TFile);
          CLOSE(SFile);
     END
     ELSE DoErrorLog(22,Process_Special(ScriptFile,False));
END;


PROCEDURE make_door_files(NType,BType: Byte);
VAR  door_file   : text;
     Users_name  : String;
     user_first  : string;
     user_last   : string;
     work1       : byte;
     work2       : byte;
     loop        : byte;
     Sysops_Name : String;
     sysop_first : string;
     sysop_last  : string;
     Temp        : string;
     TheScoop    : Byte;
BEGIN
     CASE NType OF
     0:   Users_Name := UserRecord.Name;
     1:   BEGIN
               IF UserRecord.Alias<>''
                  THEN Users_Name := UserRecord.Alias
                  ELSE Users_Name := UserRecord.Name;
          END;
     END;

     {USERS NAME}
     Work1 := Pos(' ',Users_Name);
     IF Work1=0 THEN
     BEGIN
          User_First := Users_Name;
          User_Last  := 'NLN';
          Users_Name := Users_Name+' NLN';
     END
     ELSE
     BEGIN
          Temp := Users_Name;
          User_First := _Mid(Temp,1,Work1-1);
          Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          User_Last  := Temp;
     END;

     {SYSOPS NAME}
     Sysops_Name := system_info.Sysop;
     Work1 := Pos(' ',Sysops_Name);
     IF Work1=0 THEN
     BEGIN
          Sysop_First := Sysops_Name;
          Sysop_Last  := 'NLN';
          Sysops_Name := Sysops_Name+' NLN';
     END
     ELSE
     BEGIN
          Temp := Sysops_Name;
          Sysop_First := _Mid(Temp,1,Work1-1);
          Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Work1 := Pos(' ',Temp); IF Work1<>0 THEN Delete(Temp,1,Work1);
          Sysop_Last  := Temp;
     END;

     {DOORFILE.SR}
     ASSIGN(door_file,NODE_Directory+'\DOORFILE.SR');
     REWRITE(door_file);
     WRITELN(door_file,Users_Name);
     WRITELN(door_file,'1');
     WRITELN(door_file,_String(UserRecord.Ibm));
     WRITELN(door_file,'24');
     CASE BType OF
     0:   WRITELN(door_file,BAUDString);
     1:   WRITELN(door_file,LockedBAUDString);
     END;
     IF LocalLogon THEN WRITELN(door_file,'0')
                   ELSE WRITELN(door_file,COMString);
     WRITELN(door_file,_String(Round(AbsTimeLeft/60)));
     CLOSE(door_file);

     {DOOR.SYS}
     ASSIGN(door_file,NODE_Directory+'\DOOR.SYS');
     REWRITE(door_file);
     IF LocalLogon THEN WRITELN(door_file,'COM0:')
                   ELSE WRITELN(door_file,'COM'+COMString+':');
     CASE BType OF
     0:   WRITELN(door_file,BAUDString);
     1:   WRITELN(door_file,LockedBAUDString);
     END;
     WRITELN(door_file,'8');
     WRITELN(door_file,NodeString);
     CASE BType OF
     0:   WRITELN(door_file,LockedBaudString);
     1:   WRITELN(door_file,BAUDString);
     END;
     WRITELN(door_file,'Y');
     WRITELN(door_file,'Y');
     WRITELN(door_file,'Y');
     WRITELN(door_file,'Y');
     WRITELN(door_file,Users_Name);
     WRITELN(door_file,UserRecord.city+', '+UserRecord.prov);
     WRITELN(door_file,UserRecord.Voice);
     WRITELN(door_file,UserRecord.Data);
     WRITELN(door_file,UserRecord.Password);
     WRITELN(door_file,UserRecord.Security);
     WRITELN(door_file,UserRecord.Total_Calls);
     WRITELN(door_file,TranslateDate1(_UnpackedDate(RealLastCall)));
     WRITELN(door_file,_String(AbsTimeLeft));
     WRITELN(door_file,_String(Round(AbsTimeLeft/60)));
     WRITELN(door_file,'GR');
     WRITELN(door_file,'24');
     WRITELN(door_file,'N');
     WRITELN(door_file,'');
     WRITELN(door_file,'');
     IF (_UnpackedDate(UserRecord.Sub_Expiry)<>'00-00-1980')
        THEN WRITELN(door_file,TranslateDate1(_UnpackedDate(UserRecord.Sub_Expiry)))
        ELSE WRITELN(door_file,'');
     WRITELN(door_file,UserRecord.User_Number);
     WRITELN(door_file,'Z');
     WRITELN(door_file,UserRecord.files_uploaded);
     WRITELN(door_file,UserRecord.files_downloaded);
     WRITELN(door_file,Trunc(UserRecord.DLBytesToday/1024));
     WRITELN(door_file,Trunc(UserAccess.daily_bytes/1024));
     CLOSE(door_file);

     {DORINFOx.DEF}
     Temp := Gunshot_Directory+'\DROPFILE';
     _CreatePath(Temp);
     FOR TheScoop := 0 TO 2 DO
     BEGIN
          CASE TheScoop OF
          0:   ASSIGN(door_file,NODE_Directory+'\DORINFO'+NodeString+'.DEF');
          1:   ASSIGN(door_file,Temp+'\DORINFO'+NodeString+'.DEF');
          2:   ASSIGN(door_file,NODE_Directory+'\DORINFO.DEF');
          END;
          REWRITE(door_file);
          WRITELN(door_file,system_info.bbs_name);
          WRITELN(door_file,sysop_first);
          WRITELN(door_file,sysop_last);
          IF LocalLogon
             THEN WRITELN(door_file,'COM0')
             ELSE WRITELN(door_file,'COM'+COMString);
          CASE BType OF
          0:   WRITELN(door_file,BAUDString+' BAUD,N,8,1');
          1:   WRITELN(door_file,LockedBAUDString+' BAUD,N,8,1');
          END;
          WRITELN(door_file,'0');
          WRITELN(door_file,user_first);
          WRITELN(door_file,user_last);
          WRITELN(door_file,UserRecord.city+', '+UserRecord.prov);
          WRITELN(door_file,'1');
          WRITELN(door_file,UserRecord.Security);
          WRITELN(door_file,_String(Round(AbsTimeLeft/60)));
          IF NodeInfo.ComDevice<>1
             THEN WRITELN(door_file,'-1')
             ELSE WRITELN(door_file,'0');
          CLOSE(door_file);
     END;
END;


END.
