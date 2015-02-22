{$I DEFINES.INC}
UNIT ChangeFa;


INTERFACE


FUNCTION change_farea: boolean;


IMPLEMENTATION


USES Globals,MiscStr,SBuffer,Screens,KeyInput,CDS,GotKeys,
     TagArea,ToggFile,Gr2_Bp,_Pick,_Mouse,Commands;


FUNCTION change_farea: boolean;
TYPE Area_Id           = Word;
VAR  FAreaId           : File Of Area_Id;
     AreaId            : Area_Id;
     count             : word;
     Temp              : String;
     Loop              : Word;
     OuttaHere         : Boolean;
     Selected_Area     : Boolean;
     C                 : Char;
     TaggingAll        : Boolean;

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
     TaggingAll := True;
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     ASSIGN(FFileArea2,NODE_Directory+'\FFFFFFFF.FFF');
     REWRITE(FFileArea2);
     {$I-}RESET(FFileArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          WHILE NOT(EOF(FFileArea)) DO
          BEGIN
               READ(FFileArea,FileAreas);
               IF ((UserRecord.Security>=FileAreas.View_Access) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
               BEGIN
                    IF NOT(FileAreas.PassThrough) THEN
                    BEGIN
                         IF (FileAreas.CD_Rom<>0) THEN
                         BEGIN
                              IF IsCDToggled(FileAreas.CD_Rom) THEN
                              BEGIN
                                   INC(Count);
                                   WRITE(FFileArea2,FileAreas);
                              END;
                         END
                         ELSE
                         BEGIN
                              INC(Count);
                              WRITE(FFileArea2,FileAreas);
                         END;
                    END;
               END;
          END;
          CLOSE(FFileArea);
          CLOSE(FFileArea2);
     END
     ELSE
     BEGIN
          CLOSE(FFileArea2);
          ERASE(FFileArea2);
          Change_Farea := False;
          EXIT;
     END;
     Selected_Area := False;
     IF DisplayGraphicFile('FAREAS',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count            := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileAreas);
                INC(Count);
                IF IsFileTagged(FileAreas.AreaID)
                   THEN AddToPickList(Chr(254)+FileAreas.Area_Name,Count,True)
                   ELSE AddToPickList(' '+FileAreas.Area_Name,Count,True);
          UNTIL EOF(FFileArea);
          CLOSE(FFileArea);
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
                               CurrentFileArea := PickInfo.Current;
                               Selected_Area   := True;
                               OuttaHere       := True;
                          END
                          ELSE OuttaHere := True;
                     END;
                27:  OuttaHere := True;
                ELSE BEGIN
                          IF ((c=GetCommandKeyPress('FAREAS',5)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
                               RESET(FFileArea);
                               SEEK(FFileArea,PickInfo.Current-1);
                               READ(FFileArea,FileAreas);
                               CLOSE(FFileArea);
                               IF NOT(IsFileTagged(FileAreas.AreaID)) THEN
                               BEGIN
                                    ToggleFileArea(FileAreas.AreaID,True);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF ((c=GetCommandKeyPress('FAREAS',6)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
                               RESET(FFileArea);
                               SEEK(FFileArea,PickInfo.Current-1);
                               READ(FFileArea,FileAreas);
                               CLOSE(FFileArea);
                               IF IsFileTagged(FileAreas.AreaID) THEN
                               BEGIN
                                    ToggleFileArea(FileAreas.AreaID,False);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF c=GetCommandKeyPress('FAREAS',7) THEN
                          BEGIN
                               ASSIGN(FFileArea,NODE_Directory+'\FFFFFFFF.FFF');
                               RESET(FFileArea);
                               REPEAT
                                     READ(FFileArea,FileAreas);
                                     ToggleFileArea(FileAreas.AreaID,TaggingAll);
                               UNTIL EOF(FFileArea);
                               CLOSE(FFileArea);
                               ReloadAll;
                               IF TaggingAll THEN TaggingAll := False
                                             ELSE TaggingAll := True;
                          END;
                     END;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
     IF Selected_Area THEN
     BEGIN
          ASSIGN(FFileArea2,NODE_Directory+'\FFFFFFFF.FFF');
          RESET(FFileArea2);
          SEEK(FFileArea2,CurrentFileArea-1);
          READ(FFileArea2,FileAreas2);
          CLOSE(FFileArea2);
          Count := 0;
          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileAreas);
                INC(Count);
          UNTIL (FileAreas2.AreaID=FileAreas.AreaID);
          CLOSE(FFileArea);
          CurrentFileArea := Count;
     END;
     change_farea := selected_area;
END;


END.
