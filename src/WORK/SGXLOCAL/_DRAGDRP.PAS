{$I DEFINES.INC}
UNIT _DragDrp;


INTERFACE


PROCEDURE DoDragAndDrop(FType: String);


IMPLEMENTATION


USES BsGraph,Globals,Gr2_Bp,_Win,_Mouse,BsMulti;


PROCEDURE DoDragAndDrop(FType: String);
VAR  XX    : Word;
     YY    : Word;
BEGIN
     DidDragDrop := 0;
          IF FType='FILE' THEN ChangeMouse(FileDragMouse)
     ELSE IF FType='MSG'  THEN ChangeMouse(MsgDragMouse);
     REPEAT
           XX := MousePosX;
           YY := MousePosY;
           IF ((XX<9) OR (XX>76) OR (YY<YWindow+9) OR (YY>YWindow+41)) THEN
           BEGIN
                IF (DidDragDrop<>0) THEN
                BEGIN
                     DidDragDrop := 0;
                     HideTheMouse;
                     RaisedBox(9,YWindow+9,41,YWindow+41);
                     RaisedBox(44,YWindow+9,76,YWindow+41);
                     ShowTheMouse;
                END;
           END
           ELSE IF ((XX>9) AND (XX<41)) THEN
           BEGIN
                IF (DidDragDrop<>1) THEN
                BEGIN
                     DidDragDrop := 1;
                     HideTheMouse;
                     InvertedBox(9,YWindow+9,41,YWindow+41);
                     RaisedBox(44,YWindow+9,76,YWindow+41);
                     ShowTheMouse;
                END;
           END
           ELSE IF ((XX>44) AND (XX<76)) THEN
           BEGIN
                IF (DidDragDrop<>2) THEN
                BEGIN
                     DidDragDrop := 2;
                     HideTheMouse;
                     RaisedBox(9,YWindow+9,41,YWindow+41);
                     InvertedBox(44,YWindow+9,76,YWindow+41);
                     ShowTheMouse;
                END;
           END;
           TimeSlice;
     UNTIL NOT(RightButtonPress);
     ChangeMouse(DefaultMouse);
     HideTheMouse;
     RaisedBox(9,YWindow+9,41,YWindow+41);
     RaisedBox(44,YWindow+9,76,YWindow+41);
     ShowTheMouse;
END;


END.
