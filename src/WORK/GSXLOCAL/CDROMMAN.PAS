{$I DEFINES.INC}
UNIT CDRomMan;


INTERFACE


PROCEDURE CDRomManager;


IMPLEMENTATION


USES Globals,MiscStr,SBuffer,Screens,KeyInput,CDS,FilHeadr,GotKeys,
     TagArea,ToggCD,Gr2_Bp,_Pick,_Mouse,Commands,Gunshot,BsString,
     BsFile;


PROCEDURE CDRomManager;
VAR  count             : word;
     Temp              : String;
     Loop              : Word;
     OuttaHere         : Boolean;
     Selected_Area     : Boolean;
     C                 : Char;
     TaggingAll        : Boolean;
     FCDRoms2          : File Of _CDRom_Record;
     CDRoms2           : _CDRom_Record;
     Str1              : String[20];
     Str2              : String[20];

     PROCEDURE ReloadTag;
     VAR  FFPickList : File Of Pick_List;
     BEGIN
          IF PickInfo.UsingDisk THEN
          BEGIN
               ASSIGN(FFPickList,NODE_Directory+'\PICK.LST');
               RESET(FFPickList);
               SEEK(FFPickList,PickInfo.Current-1);
               READ(FFPickList,PickList);
               IF PickList.Line[1]=Chr(254)
                  THEN PickList.Line[1] := ' '
                  ELSE PickList.Line[1] := Chr(254);
               SEEK(FFPickList,PickInfo.Current-1);
               WRITE(FFPickList,PickList);
               CLOSE(FFPickList);
          END
          ELSE
          BEGIN
               IF HugePick^[PickInfo.Current].Line[1]=Chr(254)
                  THEN HugePick^[PickInfo.Current].Line[1] := ' '
                  ELSE HugePick^[PickInfo.Current].Line[1] := Chr(254);
          END;
          HideTheMouse;
          SetUpPickList;
          ShowTheMouse;
     END;

     PROCEDURE ReloadAll;
     VAR  FPickList2 : File Of Pick_List;
          FFPickList : File Of Pick_List;
          LLoop      : Word;
     BEGIN
          IF PickInfo.UsingDisk THEN
          BEGIN
               ASSIGN(FFPickList,NODE_Directory+'\PICK.LST');
               RENAME(FFPickList,NODE_Directory+'\PICK.LS$');
               ASSIGN(FPickList2,NODE_Directory+'\PICK.LS$');
               ASSIGN(FFPickList,NODE_Directory+'\PICK.LST');
               REWRITE(FFPickList);
               RESET(FPickList2);
               REPEAT
                     READ(FPickList2,PickList);
                     IF TaggingAll THEN PickList.Line[1] := Chr(254)
                                   ELSE PickList.Line[1] := ' ';
                     WRITE(FFPickList,PickList);
               UNTIL EOF(FPickList2);
               CLOSE(FPickList2);
               CLOSE(FFPickList);
               ERASE(FPickList2);
          END
          ELSE
          BEGIN
               FOR LLoop := 1 TO PickInfo.NumItems DO
               BEGIN
                    IF TaggingAll
                       THEN HugePick^[LLoop].Line[1] := Chr(254)
                       ELSE HugePick^[LLoop].Line[1] := ' ';
               END;
          END;
          HideTheMouse;
          SetUpPickList;
          ShowTheMouse;
     END;

BEGIN
     Str1 := GetCommandString('MISC',1);
     Str2 := GetCommandString('MISC',2);
     TaggingAll := True;
     IF NOT(_FileExists(DATA_Directory+'\CDROMS.DAT')) THEN Exit;
     IF DisplayGraphicFile('CDROMMAN',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
          RESET(FCDRoms2);
          REPEAT
                READ(FCDRoms2,CDRoms2);
                INC(Count);
                IF IsCDOnline(CDRoms2.CDNumber)
                   THEN Temp := _PadRight(CDRoms2.CDName,37)+Str1
                   ELSE Temp := _PadRight(CDRoms2.CDName,37)+Str2;
                IF IsCDToggled(CDRoms2.CDNumber)
                   THEN AddToPickList(Chr(254)+Temp,Count,True)
                   ELSE AddToPickList(' '+Temp,Count,True);
          UNTIL EOF(FCDRoms2);
          CLOSE(FCDRoms2);
          ChangeMouse(DefaultMouse);
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13:  OuttaHere := True;
                27:  OuttaHere := True;
                ELSE BEGIN
                          IF ((c=GetCommandKeyPress('CDROMMAN',5)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                               RESET(FCDRoms2);
                               SEEK(FCDRoms2,PickInfo.Current-1);
                               READ(FCDRoms2,CDRoms2);
                               CLOSE(FCDRoms2);
                               IF NOT(IsCDToggled(CDRoms2.CDNumber)) THEN
                               BEGIN
                                    ToggleCDRom(CDRoms2.CDNumber,True);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF ((c=GetCommandKeyPress('CDROMMAN',6)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                               RESET(FCDRoms2);
                               SEEK(FCDRoms2,PickInfo.Current-1);
                               READ(FCDRoms2,CDRoms2);
                               CLOSE(FCDRoms2);
                               IF IsCDToggled(CDRoms2.CDNumber) THEN
                               BEGIN
                                    ToggleCDRom(CDRoms2.CDNumber,False);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF c=GetCommandKeyPress('CDROMMAN',7) THEN
                          BEGIN
                               ASSIGN(FCDRoms2,DATA_Directory+'\CDROMS.DAT');
                               RESET(FCDRoms2);
                               REPEAT
                                     READ(FCDRoms2,CDRoms2);
                                     ToggleCDRom(CDRoms2.CDNumber,TaggingAll);
                               UNTIL EOF(FCDRoms2);
                               CLOSE(FCDRoms2);
                               ReloadAll;
                               IF TaggingAll THEN TaggingAll := False
                                             ELSE TaggingAll := True;
                          END;
                     END;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
     Header(CurrentFileSub,CurrentFileArea,True);
END;


END.
