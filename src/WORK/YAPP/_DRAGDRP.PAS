{$I DEFINES.INC}
UNIT _DragDrp;


INTERFACE


PROCEDURE DoDragAndDrop(FType: String);


IMPLEMENTATION


USES _Mouse,Gr2_Bp,_Win,ApCom,Globals,BsGraph,BsString;


PROCEDURE DoDragAndDrop(FType: String);
VAR  XX          : Word;
     YY          : Word;
     DidDragDrop : Word;
BEGIN
     DidDragDrop := 0;
          IF FType='FILE' THEN ChangeMouse(FileDragMouse)
     ELSE IF FType='MSG'  THEN ChangeMouse(MsgDragMouse);
     REPEAT
           XX := GetMouseX;
           YY := GetMouseY;
           IF ((XX<9) OR (XX>76) OR (YY<YWindow+9) OR (YY>YWindow+41)) THEN
           BEGIN
                IF (DidDragDrop<>0) THEN
                BEGIN
                     DidDragDrop := 0;
                     GrDisplayMouse(GrHide);
                     RaisedBox(9,YWindow+9,41,YWindow+41);
                     RaisedBox(44,YWindow+9,76,YWindow+41);
                     GrDisplayMouse(GrShow);
                END;
           END
           ELSE IF ((XX>9) AND (XX<41)) THEN
           BEGIN
                IF (DidDragDrop<>1) THEN
                BEGIN
                     DidDragDrop := 1;
                     GrDisplayMouse(GrHide);
                     InvertedBox(9,YWindow+9,41,YWindow+41);
                     RaisedBox(44,YWindow+9,76,YWindow+41);
                     GrDisplayMouse(GrShow);
                END;
           END
           ELSE IF ((XX>44) AND (XX<76)) THEN
           BEGIN
                IF (DidDragDrop<>2) THEN
                BEGIN
                     DidDragDrop := 2;
                     GrDisplayMouse(GrHide);
                     RaisedBox(9,YWindow+9,41,YWindow+41);
                     InvertedBox(44,YWindow+9,76,YWindow+41);
                     GrDisplayMouse(GrShow);
                END;
           END;
     UNTIL (GrGetMouseButtons<>GrRButton);
     ChangeMouse(DefaultMouse);
     GrDisplayMouse(GrHide);
     RaisedBox(9,YWindow+9,41,YWindow+41);
     RaisedBox(44,YWindow+9,76,YWindow+41);
     GrDisplayMouse(GrShow);
     IF (DidDragDrop<>0) THEN PutStringTimeout(BBSPort,#251+_String(DidDragDrop),YappDelay);
END;


END.