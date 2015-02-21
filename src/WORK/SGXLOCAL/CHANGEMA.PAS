{$I DEFINES.INC}
UNIT ChangeMa;


INTERFACE


FUNCTION ChangeMessageArea: boolean;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Pick,MiscStr,Screens,GotKeys,
     _Mouse,TagArea,KeyInput,ToggMsg,Commands;


FUNCTION ChangeMessageArea: boolean;
TYPE Area_Id       = Word;
VAR  FAreaId       : File Of Area_Id;
     AreaId        : Area_Id;
     count         : word;
     Temp          : String;
     Loop          : Word;
     OuttaHere     : Boolean;
     Selected_Area : Boolean;
     C             : Char;
     TaggingAll    : Boolean;
LABEL                SkipIt;

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
                  THEN PickList.Line[1] := #32
                  ELSE PickList.Line[1] := Chr(254);
               SEEK(FFPickList,PickInfo.Current-1);
               WRITE(FFPickList,PickList);
               CLOSE(FFPickList);
          END
          ELSE
          BEGIN
               IF HugePick^[PickInfo.Current].Line[1]=Chr(254)
                  THEN HugePick^[PickInfo.Current].Line[1] := #32
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
                                   ELSE PickList.Line[1] := #32;
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
                       ELSE HugePick^[LLoop].Line[1] := #32;
               END;
          END;
          HideTheMouse;
          SetUpPickList;
          ShowTheMouse;
     END;

BEGIN
     TaggingAll := True;
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     ASSIGN(FMessageArea2,NODE_Directory+'\MMMMMMMM.MMM');
     REWRITE(FMessageArea2);
     {$I-}RESET(FMessageArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          WHILE NOT(EOF(FMessageArea)) DO
          BEGIN
               READ(FMessageArea,MessageAreas);
               IF ((UserRecord.Security>=MessageAreas.Read_Access) AND
                  GotTheKeys(UserRecord.Tags,MessageAreas.Tags))
                  THEN WRITE(FMessageArea2,MessageAreas);
          END;
          CLOSE(FMessageArea);
          CLOSE(FMessageArea2);
     END
     ELSE
     BEGIN
          CLOSE(FMessageArea2);
          ERASE(FMessageArea2);
          ChangeMessageArea := False;
          EXIT;
     END;
     Selected_Area := False;
     IF DisplayGraphicFile('MAREAS',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count            := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
          RESET(FMessageArea);
          REPEAT
                READ(FMessageArea,MessageAreas);
                INC(Count);
                IF IsMsgTagged(MessageAreas.AreaID)
                   THEN Temp := Chr(254)+MessageAreas.Area_Name
                   ELSE Temp := #32+MessageAreas.Area_Name;
                AddToPickList(Temp,Count,True);
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
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
                               CurrentMessageArea := PickInfo.Current;
                               Selected_Area      := True;
                               OuttaHere          := True;
                          END
                          ELSE OuttaHere := True;
                     END;
                27:  OuttaHere := True;
                ELSE BEGIN
                          IF ((c=GetCommandKeyPress('MAREAS',5)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
                               RESET(FMessageArea);
                               SEEK(FMessageArea,PickInfo.Current-1);
                               READ(FMessageArea,MessageAreas);
                               CLOSE(FMessageArea);
                               IF NOT(IsMsgTagged(MessageAreas.AreaID)) THEN
                               BEGIN
                                    ToggleMsgArea(MessageAreas.AreaID,True);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF ((c=GetCommandKeyPress('MAREAS',6)) AND (PickInfo.Current<>0)) THEN
                          BEGIN
                               ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
                               RESET(FMessageArea);
                               SEEK(FMessageArea,PickInfo.Current-1);
                               READ(FMessageArea,MessageAreas);
                               CLOSE(FMessageArea);
                               IF IsMsgTagged(MessageAreas.AreaID) THEN
                               BEGIN
                                    ToggleMsgArea(MessageAreas.AreaID,False);
                                    ReloadTag;
                               END;
                          END
                          ELSE IF c=GetCommandKeyPress('MAREAS',7) THEN
                          BEGIN
                               ASSIGN(FMessageArea,NODE_Directory+'\MMMMMMMM.MMM');
                               RESET(FMessageArea);
                               REPEAT
                                     READ(FMessageArea,MessageAreas);
                                     ToggleMsgArea(MessageAreas.AreaID,TaggingAll);
                               UNTIL EOF(FMessageArea);
                               CLOSE(FMessageArea);
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
          ASSIGN(FMessageArea2,NODE_Directory+'\MMMMMMMM.MMM');
          RESET(FMessageArea2);
          SEEK(FMessageArea2,CurrentMessageArea-1);
          READ(FMessageArea2,MessageAreas2);
          CLOSE(FMessageArea2);
          Count := 0;
          ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
          RESET(FMessageArea);
          REPEAT
                READ(FMessageArea,MessageAreas);
                INC(Count);
          UNTIL (MessageAreas2.AreaID=MessageAreas.AreaID);
          CLOSE(FMessageArea);
          CurrentMessageArea := Count;
     END;
     ChangeMessageArea := selected_area;
END;


END.
