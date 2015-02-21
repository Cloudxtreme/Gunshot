{$I DEFINES.INC}
UNIT DEntry;


INTERFACE


PROCEDURE DoDataEntryScreen(ScriptFile: String);


IMPLEMENTATION


USES BsString,BsFile,Globals,ErrorLog,Gfx,Screens,KeyInput,BsLog,Special;


PROCEDURE DoDataEntryScreen(ScriptFile: String);
VAR  TFile       : Text;
     Temp        : String;
     FileExports : Array[1..20] Of String[80];
     ExportCount : Word;
     ScreenFile  : String;
     DataFile    : String;
     Command     : String;
     Work        : Word;
     Work2       : Word;
     OuttaHere   : Boolean;
     C           : Char;
     Loop        : Word;
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
                     {NOT NEEDED}
                END
                ELSE IF _Mid(Command,1,5)='FIELD' THEN
                BEGIN
                     {NOT NEEDED}
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
     bsWriteLog('Filling out data entry screen: '+ScreenFile,True);
     IF DisplayGraphicFile(ScreenFile,False,True,True) THEN
     BEGIN
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13,
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          IF ((Ord(C)=13) AND (ExportCount<>0)) THEN
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
                         Insert(Fields[_Numeric(Temp)].Text,FileExports[Loop],Work);
                    END;
                    WRITELN(TFile,process_special(FileExports[Loop],False));
               END;
               CLOSE(TFile);
          END;
     END;
END;


END.