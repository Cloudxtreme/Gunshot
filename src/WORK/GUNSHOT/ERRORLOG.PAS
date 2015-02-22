{$I DEFINES.INC}
UNIT ErrorLog;


INTERFACE


PROCEDURE DoErrorLog(Num: Word; InString: String);


IMPLEMENTATION


USES Time,Globals,BsTime,BsString;


PROCEDURE DoErrorLog(Num: Word; InString: String);
VAR  log_file : File;
     Line     : String;
     Temp     : String;
BEGIN
     Line := _MMDDYYYY+' '+_PadLeft(_GetPrettyTime,7)+' :SYS';
     CASE Num OF
     1:   Line := Line+'0001: Port Speed Error'+#13#10;
     2:   Line := Line+'0002: Com Device Error'+#13#10;
     3:   Line := Line+'0003: Invalid Port Error'+#13#10;
     4:   Line := Line+'0004: Flow Control Error'+#13#10;
     5:   Line := Line+'0005: Internal Buffer Overflow Error'+#13#10;
     6:   Line := Line+'0006: Arc Dump Missing Error: '+InString+#13#10;
     7:   Line := Line+'0007: CBV Error'+#13#10;
     8:   Line := Line+'0008: CBV Error'+#13#10;
     9:   Line := Line+'0009: CBV Error'+#13#10;
     10:  Line := Line+'0010: CBV Error'+#13#10;
     11:  Line := Line+'0011: CBV Error'+#13#10;
     12:  Line := Line+'0012: Missing Menu: '+InString+#13#10;
     13:  Line := Line+'0013: Missing Screen: '+InString+#13#10;
     14:  Line := Line+'0014: Port Opening Error: COM'+InString+#13#10;
     15:  Line := Line+'0015: Missing External: '+InString+#13#10;
     16:  Line := Line+'0016: Missing Nodelist: '+InString+#13#10;
     17:  Line := Line+'0017: File Sub Doesn''t Exist: '+InString+#13#10;
     18:  Line := Line+'0018: File Area Doesn''t Exist: '+InString+#13#10;
     19:  Line := Line+'0019: File Doesn''t Exist: '+InString+#13#10;
     20:  Line := Line+'0020: UL Directory Not Found: '+InString+#13#10;
     21:  Line := Line+'0021: UL Directory Not Found: '+InString+#13#10;
     22:  Line := Line+'0022: File Doesn''t Exist: '+InString+#13#10;
     23:  Line := Line+'0023: Access Level Not Defined Error: '+InString+#13#10;
     24:  Line := Line+'0024: Access Level Not Defined Error: '+InString+#13#10;
     25:  Line := Line+'0025: Access Level Not Defined Error: '+InString+#13#10;
     26:  Line := Line+'0026: Editor Text Buffer Error'+#13#10;
     27:  Line := Line+'0027: Editor Line Buffer Error'+#13#10;
     28:  Line := Line+'0028: MSG Base Limit Error: '+InString+#13#10;
     29:  Line := Line+'0029: QWK Buffer Overflow Error'+#13#10;
     30:  Line := Line+'0030: Message Sub Doesn''t Exist: '+InString+#13#10;
     31:  Line := Line+'0031: Message Area Doesn''t Exist: '+InString+#13#10;
     32:  Line := Line+'0032: "0" MSG Area ID Error'+#13#10;
     33:  Line := Line+'0033: "0" File Area ID Error'+#13#10;
     34:  Line := Line+'0034: Text File Missing: '+InString+#13#10;
     35:  Line := Line+'0035: Memory Critical! Free: '+InString+#13#10;
     36:  Line := Line+'0036: DOS Door Missing: '+InString+#13#10;
     37:  Line := Line+'0037: System File Missing: '+InString+#13#10;
     38:  Line := Line+'0038: No Node Number Selected Error'+#13#10;
     39:  Line := Line+'0039: Invalid Command Line Option: '+InString+#13#10;
     40:  Line := Line+'0040: Node Number Invalid: '+InString+#13#10;
     41:  Line := Line+'0041: Intro File Missing: '+InString+#13#10;
     101: Line := Line+'0101: GUI Memory Error'+#13#10;
     102: Line := Line+'0102: GUI Memory Error'+#13#10;
     103: Line := Line+'0103: GUI Memory Error'+#13#10;
     104: Line := Line+'0104: Mouse Not Found Error'+#13#10;
     105: Line := Line+'0105: Buffer Creation Error'+#13#10;
     106: Line := Line+'0106: Buffer Creation Error'+#13#10;
     END;
     ASSIGN(log_file,Shotgun_Directory+'\LOGS\ERRORLOG.'+NodeString);
     {$I-}RESET(log_file,1);{$I+}
     IF IOResult<>0 THEN
     BEGIN
          REWRITE(log_file,1);
          Temp := ';'+#13#10;
          BLOCKWRITE(log_file,Temp[1],Length(Temp));
          Temp := '; ERROR LOG - Log Of System Errors'+#13#10;
          BLOCKWRITE(log_file,Temp[1],Length(Temp));
          Temp := '; Please see the manual for solutions to these problems.'+#13#10;
          BLOCKWRITE(log_file,Temp[1],Length(Temp));
          Temp := ';'+#13#10;
          BLOCKWRITE(log_file,Temp[1],Length(Temp));
     END;
     SEEK(log_file,FileSize(log_file));
     BLOCKWRITE(log_file,Line[1],Length(Line));
     CLOSE(log_file);
END;


END.
