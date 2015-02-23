{$I DEFINES.INC}
PROGRAM GipTosser;
{$M 32000,0,655360}


USES Crt,Dos,BsMulti,FastW1,BsVideo,Version,Gunshot,ApMisc,BsString,BsFile,BsTime,BsCrc;


VAR  FunkyFile     : File;
     BigFatTemp    : String;
     WeGiveUp      : Boolean;
     TryCount      : Word;
     NodeNumber    : Word;
     BaseDirectory : String;
     TheLogFile    : String;
     FMailer       : File Of _Mailer_Record;
     Mailer        : _Mailer_Record;
     DirInfo       : SearchRec;
     GIPHeader     : _GIPHeader;
     GIPDir        : String;


PROCEDURE WriteNodeFile;
VAR  FNode     : File Of _NodeFile_Record;
     Node      : _NodeFile_Record;
BEGIN
     FillChar(Node,SizeOf(Node),0);
     Node.User     := 'GIP';
     Node.Activity := 'Importing GIP Info Packs';
     Node.Node     := NodeNumber;
     ASSIGN(FNode,BaseDirectory+'\INTRNODE\NODE'+_String(NodeNumber)+'.$$$');
     {$I-}RESET(FNode);{$I+}
     IF IOResult<>0 THEN REWRITE(FNode);
     WRITE(FNode,Node);
     CLOSE(FNode);
END;


FUNCTION LoadData: Boolean;
VAR   Status : Boolean;
LABEL ForgetIt,Good;
BEGIN
     Status := True;
     {=======================================================================}
     { MAILER DATA - REQUIRED FOR INBOUND PATH                               }
     {=======================================================================}
     ASSIGN(FMailer,BaseDirectory+'\DATA\MAILER.DAT');
     {$I-}RESET(FMailer);{$I+}
     IF IOResult=0 THEN
     BEGIN
          {$I-}SEEK(FMailer,NodeNumber-1);{$I+}
          IF IOResult=0 THEN READ(FMailer,Mailer)
                        ELSE Status := False;
          CLOSE(FMailer);
     END
     ELSE Status := False;
     LoadData := Status;
END;


FUNCTION Path(Work: String): String;
BEGIN
     IF Work<>'' THEN
     BEGIN
          IF Work[LENGTH(Work)]='\' THEN Work := _Mid(Work,1,LENGTH(Work)-1);
     END;
     Path := Work;
END;


PROCEDURE StartLogFile;
{$IFNDEF MSDOS}
CONST MemAvail: LongInt = 640 * 1024; // Pretend we have 640k
{$ENDIF}    
VAR  TFile : Text;
BEGIN
     ASSIGN(TFile,TheLogFile);
     {$I-}APPEND(TFile);{$I+}
     IF (IOResult<>0) THEN REWRITE(TFile);
     WRITELN(TFile,'GIP '+GunshotVersion+' starting up: '+_GetPrettyTime+
             ', '+_GetPrettyDate+'  mem: '+_String(Trunc(MemAvail/1024))+'kb');
     WRITELN(TFile,'-------------------------------------------------------------------------------');
     CLOSE(TFile);
END;


PROCEDURE WriteLogFile(InString: String);
VAR  TFile : Text;
BEGIN
     ASSIGN(TFile,TheLogFile);
     APPEND(TFile);
     WRITELN(TFile,_GetPrettyTime+'  '+InString);
     CLOSE(TFile);
END;


PROCEDURE EndLogFile;
VAR  TFile : Text;
BEGIN
     ASSIGN(TFile,TheLogFile);
     APPEND(TFile);
     WRITELN(TFile,'');
     CLOSE(TFile);
END;


PROCEDURE DoStatus(InString: String);
BEGIN
     TextColor(7);
     WRITELN(InString);
END;


PROCEDURE ImportGip(FName: String);
VAR  FFile     : File;
     AreaCRC   : String[8];
     TFile     : Text;
     Temp      : String;
     IsItThere : Boolean;
BEGIN
     ASSIGN(FFile,Mailer.Inbound+FName);
     RESET(FFile,1);
     BLOCKREAD(FFile,GIPHeader,SizeOf(GIPHeader));
     CLOSE(FFile);
     DoStatus('Importing GIP file: '+FName);
     DoStatus('             Title: '+GIPHeader.Title);
     DoStatus('            Author: '+GIPHeader.Author);
     DoStatus('              Area: '+GIPHeader.Area);
     WriteLogFile('  # Importing GIP file: '+FName);
     WriteLogFile('  ÃÄÄÄÄ TITLE: '+GIPHeader.Title);
     AreaCRC := StringCRC(_UpperCase(GIPHeader.Area));
     IsItThere := False;
     ASSIGN(TFile,GIPDir+'\GIPDIR.CFG');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READLN(TFile,Temp);
                IF _Mid(Temp,1,8)=AreaCRC THEN IsItThere := True;
          UNTIL ((EOF(TFile)) OR (IsItThere));
     END
     ELSE REWRITE(TFile);
     CLOSE(TFile);
     IF NOT(IsItThere) THEN
     BEGIN
          Temp := AreaCRC+' '+GIPHeader.Area;
          APPEND(TFile);
          WRITELN(TFile,Temp);
          CLOSE(TFile);
          WriteLogFile('  ÃÄ NEW AREA: '+GIPHeader.Area);
     END
     ELSE WriteLogFile('  ÃÄÄÄÄÄ AREA: '+GIPHeader.Area);
     WriteLogFile('  ÀÄÄÄ AUTHOR: '+GIPHeader.Author);
     _CreatePath(GIPDir+'\'+AreaCRC);
     IF _MoveFile(FName,Mailer.Inbound,GIPDir+'\'+AreaCRC+'\')
        THEN _EraseFile(Mailer.Inbound+FName);
END;


BEGIN
     FileMode := 66;
     AppHeader('GIP - GIP Graphic File Tosser For Gunshot Professional');
     BigFatTemp := _UpperCase(ParamStr(1));
     IF _Mid(BigFatTemp,1,2)='-N' THEN
     BEGIN
          Delete(BigFatTemp,1,2);
          NodeNumber := _Numeric(BigFatTemp);
     END
     ELSE NodeNumber := 0;
     IF NodeNumber<>0 THEN
     BEGIN
          TextColor(7);
          BaseDirectory := _UpperCase(_GetFilePath(ParamStr(0)));
          BaseDirectory := Path(BaseDirectory);
          GIPDir        := BaseDirectory+'\GIPS';
          _CreatePath(GIPDir);
          ChDir(BaseDirectory);
          WeGiveUp := False;
          TryCount := 31;
          REPEAT
                IF NOT(_FileExists(BaseDirectory+'\GIP.$$$')) THEN
                BEGIN
                     ASSIGN(FunkyFile,BaseDirectory+'\GIP.$$$');
                     REWRITE(FunkyFile,1);
                     CLOSE(FunkyFile);
                     TheLogFile := BaseDirectory+'\LOGS';
                     _CreatePath(BaseDirectory+'\LOGS');
                     TheLogFile := BaseDirectory+'\LOGS\GIP.'+_String(NodeNumber);
                     IF LoadData THEN
                     BEGIN
                          Window(1,7,80,24);
                          FindFirst(Mailer.Inbound+'*.GIP',Anyfile-Directory-VolumeID,DirInfo);
                          IF DosError=0 THEN
                          BEGIN
                               WriteNodeFile;
                               StartLogFile;
                               FindFirst(Mailer.Inbound+'*.GIP',Anyfile-Directory-VolumeID,DirInfo);
                               WHILE DosError=0 DO
                               BEGIN
                                    ImportGip(DirInfo.Name);
                                    FindNext(DirInfo);
                               END;
                               WriteLogFile('End run.');
                               EndLogFile;
                               ChDir(BaseDirectory);
                          END;
                          DoStatus('All done!');
                          Window(1,1,80,25);
                          TextColor(7);
                          GotoXY(1,23);
                     END;
                     ERASE(FunkyFile);
                     WeGiveUp := True;
                END
                ELSE
                BEGIN
                     DEC(TryCount);
                     _Delay(1000);
                     FastWrite('GIP busy. Timeout: '+_String(TryCount)+' ',7,1,14);
                     IF TryCount=0 THEN
                     BEGIN
                          FastWrite('                         ',7,1,14);
                          TextColor(7);
                          GotoXY(1,23);
                          WeGiveUp := True;
                     END
                     ELSE WeGiveUp := False;
                END;
          UNTIL WeGiveUp;
     END
     ELSE
     BEGIN
          WRITELN('      Missing node number! Command line:');
          WRITELN;
          WRITELN('        GIP.EXE -Nxxx');
          WRITELN;
          WRITELN('      where xxx is the node number.');
          WRITELN;
          TextColor(7);
     END;
END.