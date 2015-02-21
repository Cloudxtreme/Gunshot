{$I DEFINES.INC}
UNIT PickLst;


INTERFACE


PROCEDURE KillPickList;
PROCEDURE SetUpPickList;
PROCEDURE ScrollPickUp;
PROCEDURE ScrollPickDown;
PROCEDURE ScrollPickPgUp;
PROCEDURE ScrollPickPgDown;
PROCEDURE DrawPickListLocator;
PROCEDURE NewPickList          (x,y,OnScreen,MaxChars: Word);
PROCEDURE AddToPickList        (InString: String);
FUNCTION  GetFromPickList      (Num: Word)                   : String;
FUNCTION  MoveLocator                                        : Boolean;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,BHandler,_Icons,ErrorOut,BsString,_Text,Gx2_Bp,BsGraph;


FUNCTION GetFromPickList(Num: Word): String;
BEGIN
     IF ((Num>PickInfo.NumItems) OR (Num=0)) THEN Exit;
     GetFromPickList := PickList^[Num];
END;


PROCEDURE KillPickList;
BEGIN
     DISPOSE(PickList);
     PickInfo.Active := False;
END;


PROCEDURE DrawPickListLocator;
VAR  Work      : Word;
     Percent   : Real;
     Pixels    : Word;
     YRelative : Word;
BEGIN
     IF PickInfo.NumItems>PickInfo.ItemsOnScrn THEN
     BEGIN
          Work             := PickInfo.NumItems-PickInfo.ItemsOnScrn;
          Percent          := (PickInfo.Top-1)/Work;
          Pixels           := PickInfo.y2-PickInfo.y1-61;
          YRelative        := Round(Pixels*Percent);
          PickInfo.Locator := PickInfo.y1+21+YRelative;
     END
     ELSE PickInfo.Locator := PickInfo.y1+21;
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(PickInfo.x2+2,PickInfo.y1+21,PickInfo.x2+20,PickInfo.y2-21,GrFill);
     GrSetColor(0);
     GrDrawRect(PickInfo.x2+2,PickInfo.Locator,PickInfo.x2+20,PickInfo.Locator+20,GrOutline);
     RaisedBox(PickInfo.x2+3,PickInfo.Locator+1,PickInfo.x2+19,PickInfo.Locator+19);
END;


PROCEDURE NewPickList(x,y,OnScreen,MaxChars: Word);
BEGIN
     NEW(PickList);
     PickInfo.Active      := True;
     PickInfo.x1          := x;
     PickInfo.y1          := y;
     PickInfo.Top         := 1;
     PickInfo.NumItems    := 0;
     PickInfo.ItemsOnScrn := OnScreen;
     PickInfo.Current     := 1;
     PickInfo.MaxChars    := MaxChars;
     PickInfo.x2          := x+20+(MaxChars*8);
     PickInfo.y2          := y+16+(OnScreen*15);
     PickInfo.Locator     := PickInfo.y1+21;
     {Play area}
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(PickInfo.x1,PickInfo.y1,PickInfo.x2,PickInfo.y2,GrFill+GrOutline);
     GrSetLineStyle(GrLSolid,1);
     InvertedBox(PickInfo.x1-1,PickInfo.y1-1,PickInfo.x2+22,PickInfo.y2+1);
     {Scroll Bar}
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrDrawRect(PickInfo.x2+1,PickInfo.y1,PickInfo.x2+21,PickInfo.y2,GrFill+GrOutline);
     {Scroll Bar Buttons}
     SystemButton(PickInfo.x2+1,PickInfo.y1,PickInfo.x2+21,PickInfo.y1+20,1,True,True);
     SystemIcon(PickInfo.x2+5,PickInfo.y1+5,28);
     SystemButton(PickInfo.x2+1,PickInfo.y2-20,PickInfo.x2+21,PickInfo.y2,1,True,True);
     SystemIcon(PickInfo.x2+5,PickInfo.y2-15,29);
     DrawPickListLocator;
END;


PROCEDURE AddToPickList(InString: String);
BEGIN
     INC(PickInfo.NumItems);
     IF PickInfo.NumItems=800 THEN DropError(9);
     PickList^[PickInfo.NumItems] := _PadRight(InString,PickInfo.MaxChars);
END;


PROCEDURE SetUpPickList;
VAR  Loop : Word;
     Y    : Word;
     Cnt  : Word;
BEGIN
     Cnt := PickInfo.Top;
     Y   := PickInfo.y1+8;
     FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
     BEGIN
          IF Cnt<=PickInfo.NumItems THEN
          BEGIN
               IF Cnt=PickInfo.Current
                  THEN OutTextXY(PickInfo.x1+3,y,15,0,3,' '+PickList^[Cnt]+' ')
                  ELSE OutTextXY(PickInfo.x1+3,y,0,15,3,' '+PickList^[Cnt]+' ');
          END;
          INC(y,15);
          INC(Cnt);
     END;
END;


PROCEDURE ScrollPickUp;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          DEC(PickInfo.Top);
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


PROCEDURE ScrollPickDown;
BEGIN
     IF ((PickInfo.Top+PickInfo.ItemsOnScrn-1)<PickInfo.NumItems) THEN
     BEGIN
          INC(PickInfo.Top);
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


FUNCTION MoveLocator: Boolean;
VAR  LastY : Word;
     OrigY : Word;
     OrigT : Word;

     PROCEDURE CalcTop;
     VAR  Percent   : Real;
          Pixels    : Word;
          YRelative : Word;
          Work      : Word;
     BEGIN
          IF PickInfo.NumItems>PickInfo.ItemsOnScrn THEN
          BEGIN
               Pixels          := (PickInfo.y2-41)-(PickInfo.y1+21);
               YRelative       := PickInfo.Locator-(PickInfo.y1+21);
               Percent         := YRelative/Pixels;
               Work            := PickInfo.NumItems-PickInfo.ItemsOnScrn;
               PickInfo.Top    := Round(Work*Percent)+1;
          END
          ELSE PickInfo.Top := 1;
     END;

BEGIN
     GrDisplayMouse(GrHide);
     GrSetMousePos(PickInfo.x2+1,PickInfo.Locator);
     LastY := PickInfo.Locator;
     OrigY := PickInfo.Locator;
     GrSetMouseBounds(PickInfo.x2+1,PickInfo.y1+21,PickInfo.x2+1,PickInfo.y2-41);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetOp(GxXOR);
     GrSetColor(15);
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     REPEAT
           IF (GetMouseY<>LastY) THEN
           BEGIN
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
                LastY := GetMouseY;
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
           END;
     UNTIL GrGetMouseButtons<>GrLButton;
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     GrSetOp(GxSet);
     GrSetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
     GrSetMousePos(PickInfo.x2+10,LastY+10);
     GrDisplayMouse(GrShow);
     GrSetLineStyle(GrLSolid,1);
     PickInfo.Locator := LastY;
     OrigT            := PickInfo.Top;
     CalcTop;
     IF (OrigT<>PickInfo.Top)
        THEN MoveLocator := True
        ELSE
        BEGIN
             PickInfo.Locator := OrigY;
             MoveLocator      := False;
        END;
END;


PROCEDURE ScrollPickPgUp;
VAR  Temp : Integer;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          Temp := PickInfo.Top-PickInfo.ItemsOnScrn;
          IF Temp<1 THEN Temp := 1;
          PickInfo.Top := Temp;
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


PROCEDURE ScrollPickPgDown;
VAR  Temp : Integer;
BEGIN
     IF ((PickInfo.Top+PickInfo.ItemsOnScrn-1)<PickInfo.NumItems) THEN
     BEGIN
          Temp := PickInfo.Top+PickInfo.ItemsOnScrn;
          IF (Temp>(PickInfo.NumItems-PickInfo.ItemsOnScrn+1))
             THEN Temp := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
          PickInfo.Top := Temp;
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


END.
