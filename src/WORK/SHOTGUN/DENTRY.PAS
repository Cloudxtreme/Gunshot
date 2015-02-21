{$I DEFINES.INC}
UNIT DEntry;


INTERFACE


PROCEDURE DoDataEntryScreen(ScriptFile: String);


IMPLEMENTATION


USES Globals,ErrorLog,ANSIMisc,Screens,KeyInput,BsLog,Special,BsFile,BsString;


PROCEDURE DoDataEntryScreen(ScriptFile: String);
VAR  TFile        : Text;
     Temp         : String;
     FileExports  : Array[1..20] Of String[80];
     Descriptions : Array[1..20] Of String[80];
     EntryFields  : Array[1..20] Of String[80];
     ExportCount  : Word;
     ScreenFile   : String;
     DataFile     : String;
     Command      : String;
     Work         : Word;
     Work2        : Word;
     OuttaHere    : Boolean;
     C            : Char;
     Loop         : Word;
     Entries      : Word;
BEGIN
     ScriptFile := process_special(ScriptFile,False);
     ScreenFile := '';
     DataFile   := '';
     IF NOT(_FileExists(ScriptFile)) THEN
     BEGIN
          DoErrorLog(22,ScriptFile);
          Exit;
     END;
     ExportCount := 0;
     Entries     := 0;
     ASSIGN(TFile,ScriptFile);
     RESET(TFile);
     REPEAT
           READLN(TFile,Temp);
           IF (Temp[1]<>';') THEN
           BEGIN
                Command := _UpperCase(Temp);
                Work    := Pos('=',Command);
                Command := _Mid(Command,1,Work-1);
                Delete(Temp,1,Work);
                IF Command='SCREENFILE' THEN
                BEGIN
                     Temp := process_special(Temp,False);
                     ScreenFile := Temp;
                END
                ELSE IF Command='DATAFILE' THEN
                BEGIN
                     Temp := process_special(Temp,False);
                     DataFile := Temp;
                END
                ELSE IF _Mid(Command,1,11)='DESCRIPTION' THEN
                BEGIN
                     Delete(Command,1,11);
                     Work := _Numeric(Command);
                     IF (Work>Entries) THEN Entries := Work;
                     Descriptions[Work] := Temp;
                END
                ELSE IF _Mid(Command,1,5)='FIELD' THEN
                BEGIN
                     Delete(Command,1,5);
                     Work := _Numeric(Command);
                     IF (Work>Entries) THEN Entries := Work;
                     EntryFields[Work] := _UpperCase(Temp);
                END
                ELSE IF _Mid(Command,1,12)='EXPORTTOFILE' THEN
                BEGIN
                     Temp := process_special(Temp,False);
                     INC(ExportCount);
                     FileExports[ExportCount] := Temp;
                END;
           END;
     UNTIL EOF(TFile);
     CLOSE(TFile);
     IF ((ScreenFile='') OR (DataFile='')) THEN Exit;
     bsWriteLog('Filling out data entry screen: '+ScreenFile,False);
     IF DisplayGraphicsFile(ScreenFile,True,False,True,True,False) THEN
     BEGIN
          SendCrLf(1);
          FOR Loop := 1 TO Entries DO
          BEGIN
               WRITEANSI(Descriptions[Loop]+' ',False,True);
               IF EntryFields[Loop]='GENERALFILENAME' THEN
               BEGIN
                    Get_String(12,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALDATE' THEN
               BEGIN
                    GetADate('',False);
               END
               ELSE IF EntryFields[Loop]='GENERALNUMERIC' THEN
               BEGIN
                    Get_Number(5,'',False);
               END
               ELSE IF EntryFields[Loop]='GENERALPROPERNAME' THEN
               BEGIN
                    Get_Name(30,'',True,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING10' THEN
               BEGIN
                    Get_String(10,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING20' THEN
               BEGIN
                    Get_String(20,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING30' THEN
               BEGIN
                    Get_String(30,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING40' THEN
               BEGIN
                    Get_String(40,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING50' THEN
               BEGIN
                    Get_String(50,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING60' THEN
               BEGIN
                    Get_String(60,'',True,False,False,False);
               END
               ELSE IF EntryFields[Loop]='GENERALSTRING70' THEN
               BEGIN
                    Get_String(70,'',True,False,False,False);
               END;
               EntryFields[Loop] := Input_String;
               SendCrLf(1);
          END;
          IF (ExportCount<>0) THEN
          BEGIN
               ASSIGN(TFile,DataFile);
               {$I-}APPEND(TFile);{$I+}
               IF (IOResult<>0) THEN REWRITE(TFile);
               FOR Loop := 1 TO ExportCount DO
               BEGIN
                    Work := Pos('{FIELD',FileExports[Loop]);
                    IF (Work<>0) THEN
                    BEGIN
                         Work2 := Pos('}',FileExports[Loop]);
                         Temp := _Mid(FileExports[Loop],Work,Work2);
                         Delete(FileExports[Loop],Work,Work2-Work+1);
                         Delete(Temp,1,6);
                         Delete(Temp,LENGTH(Temp),1);
                         Insert(EntryFields[_Numeric(Temp)],FileExports[Loop],Work);
                    END;
                    WRITELN(TFile,process_special(FileExports[Loop],False));
               END;
               CLOSE(TFile);
          END;
     END;
END;


END.
