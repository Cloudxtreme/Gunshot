{$I DEFINES.INC}
UNIT Gip;


INTERFACE


PROCEDURE DoGipDirectory(BaseDir: String);


IMPLEMENTATION


USES Globals,Gr2_Bp,_Pick,MiscStr,Screens,SBuffer,BsString,
     GotKeys,_Mouse,KeyInput,BsLog,Dos,Shotgun;


PROCEDURE ViewGipTopics(Category,TheDir: String);
TYPE FileNamesRecord = RECORD
     FName           : String[12];
     END;
VAR  count           : word;
     OuttaHere       : Boolean;
     C               : Char;
     DirInfo         : SearchRec;
     GIPHeader       : _GIPHeader;
     FGIPHeader      : File Of _GIPHeader;
     FNames          : FileNamesRecord;
     FFNames         : File Of FileNamesRecord;
LABEL                  OverAgain;
BEGIN
     bsWriteLog('Viewing GIP category: '+Category,False);
     OverAgain:
     ClearBuffer;
     AddToBuffer('@GIPCATEGORY',Category);
     IF DisplayGraphicFile('GIPCAT',True,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(FFNames,NODE_Directory+'\GIPS.$$$');
          REWRITE(FFNames);
          FindFirst(TheDir+'*.GIP',Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               INC(Count);
               ASSIGN(FGIPHeader,TheDir+DirInfo.Name);
               RESET(FGIPHeader);
               READ(FGIPHeader,GIPHeader);
               CLOSE(FGIPHeader);
               FNames.FName := DirInfo.Name;
               WRITE(FFNames,FNames);
               AddToPickList(_PadRight(GIPHeader.Title,31)+GIPHeader.Author,Count,True);
               FindNext(DirInfo);
          END;
          CLOSE(FFNames);
          IF Count=0 THEN ERASE(FFNames);
          ChangeMouse(DefaultMouse);
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13:  BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                               KillPickList;
                               ASSIGN(FFNames,NODE_Directory+'\GIPS.$$$');
                               RESET(FFNames);
                               SEEK(FFNames,PickInfo.Current-1);
                               READ(FFNames,FNames);
                               CLOSE(FFNames);
                               ASSIGN(FGIPHeader,TheDir+FNames.FName);
                               RESET(FGIPHeader);
                               READ(FGIPHeader,GIPHeader);
                               CLOSE(FGIPHeader);
                               bsWriteLog('Viewing GIP file: '+GIPHeader.Title,False);
                               IF DisplayGIPFile(TheDir+FNames.FName) THEN Get_Enter;
                               GOTO OverAgain;
                          END;
                     END;
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
END;


PROCEDURE DoGipDirectory(BaseDir: String);
VAR  count     : word;
     OuttaHere : Boolean;
     TFile     : Text;
     Temp      : String;
     Temp2     : String;
     C         : Char;
     Loop      : Word;
LABEL            OverAgain;
BEGIN
     bsWriteLog('Viewing GIP directory: '+BaseDir,False);
     OverAgain:
     IF DisplayGraphicFile('GIPDIRS',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(TFile,BaseDir+'GIPDIR.CFG');
          {$I-}RESET(TFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     READLN(TFile,Temp);
                     Delete(Temp,1,9);
                     INC(Count);
                     AddToPickList(Temp,Count,True);
               UNTIL EOF(TFile);
               CLOSE(TFile);
          END;
          ChangeMouse(DefaultMouse);
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13:  BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                               ASSIGN(TFile,BaseDir+'GIPDIR.CFG');
                               {$I-}RESET(TFile);{$I+}
                               IF IOResult=0 THEN
                               BEGIN
                                    FOR Loop := 1 TO PickInfo.Current DO READLN(TFile,Temp);
                                    Temp2 := Temp; Delete(Temp2,1,9);
                                    Temp := _Mid(Temp,1,8);
                                    CLOSE(TFile);
                                    KillPickList;
                                    ViewGipTopics(Temp2,BaseDir+Temp+'\');
                                    GOTO OverAgain;
                               END;
                          END;
                     END;
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
END;


END.