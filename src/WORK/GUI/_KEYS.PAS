{$I DEFINES.INC}
UNIT _Keys;


INTERFACE


FUNCTION  CheckKeys: Byte;
PROCEDURE Position;


IMPLEMENTATION


USES Crt,BsGraph,Globals,Gr2_Bp,BsKeys,Gx2_Bp,_Text,Obs,BsString;


FUNCTION CheckKeys: Byte;
VAR  Press   : Char;
     OldMode : Word;
     OldX    : Integer;
     OldY    : Integer;
     TheOne  : Byte;
     C       : Char;
LABEL          SkipOnIn;
BEGIN
     TheOne := 0;
     IF KeyPressed THEN
     BEGIN
          Press := ReadKey;
          IF ORD(Press)=0 THEN
          BEGIN
               Press := ReadKey;
               CASE ORD(Press) OF
               72:  IF (GetMouseY>Grid-1)         THEN GrSetMousePos(GetMouseX,GetMouseY-Grid);
               80:  IF (GetMouseY<YWindow-Grid+1) THEN GrSetMousePos(GetMouseX,GetMouseY+Grid);
               75:  IF (GetMouseX>Grid-1)         THEN GrSetMousePos(GetMouseX-Grid,GetMouseY);
               77:  IF (GetMouseX<639-Grid+1)     THEN GrSetMousePos(GetMouseX+Grid,GetMouseY);
               73:  TheOne := 1;
               81:  TheOne := 2;
               83:  TheOne := 3;
               ELSE BEGIN
                         IF KeyBox THEN
                         BEGIN
                              Press := IsTheKeyOk(Press,True);
                              IF (Press<>#0) THEN
                              BEGIN
                                   HoldRaw.Return := Press;
                                   GOTO SkipOnIn;
                              END;
                         END;
                    END;
               END;
          END
          ELSE
          BEGIN
               IF KeyBox THEN
               BEGIN
                    HoldRaw.Return := UpCase(Press);
                    C              := IsTheKeyOk(Press,False);
                    IF ((C<>#0) OR (Press=#13) OR (Press=#27)) THEN
                    BEGIN
                         IF (C<>#0) THEN Press := C;
                         SkipOnIn:
                         OldMode := GrGetOp;
                         GrGetCp(OldX,OldY);
                         GrSetOp(GxSet);
                         GrSetMouseProtect(KeyBoxX,KeyBoxY,KeyBoxX+20,KeyBoxY+20);
                         GrProtectMouse(GrProtect);
                         GrSetFillStyle(GrFSolid,15,GrOpaque);
                         GrDrawRect(KeyBoxX+1,KeyBoxY+1,KeyBoxX+19,KeyBoxY+19,GrFill);
                         OutTextXY(KeyBoxX+7,KeyBoxY+3,0,15,3,HoldRaw.Return);
                         GrProtectMouse(GrNoProtect);
                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                         GrSetOp(OldMode);
                         GrMoveTo(OldX,OldY);
                    END;
               END;
          END;
     END;
     CheckKeys := TheOne;
END;


PROCEDURE Position;
VAR  x,y : Word;
BEGIN
     x := GetMouseXG(Grid);
     y := GetMouseYG(Grid);
     IF ((y<>LastY) OR (x<>LastX)) THEN
     BEGIN
          LastX := x;
          LastY := y;
          OutTextXY(526,YWindow+2,0,WindowBack,1,'X: '+_String(x)+'    ');
          OutTextXY(581,YWindow+2,0,WindowBack,1,'Y: '+_String(y)+'    ');
     END;
END;


END.