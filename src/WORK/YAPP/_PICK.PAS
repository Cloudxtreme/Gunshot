{======================================================}
{  This unit is specifically for handling pick lists.  }
{======================================================}
{$I DEFINES.INC}
UNIT _Pick;


INTERFACE


FUNCTION  MoveLocator                                             : Boolean;
FUNCTION  ItemPickable       (Index: Word)                        : Boolean;
PROCEDURE AppendToPickList   (InString: String);
PROCEDURE ReSelectPickList   (Old,New: Word);
PROCEDURE RedrawThePickList;
PROCEDURE NewPickList;
PROCEDURE KillPickList;
PROCEDURE SetUpPickList;
PROCEDURE ScrollPickUp;
PROCEDURE ScrollPickDown;
PROCEDURE ScrollPickPgUp;
PROCEDURE ScrollPickPgDown;
PROCEDURE ScrollPickTop;
PROCEDURE ScrollPickBottom;
PROCEDURE DrawPickListLocator;
PROCEDURE GoGetIt;


IMPLEMENTATION


USES Gx2_Bp,Gx2_BpVc,Gr2_Bp,Tx2_Bp,Startup,_Win,
     Globals,Process,ApCom,ApPort,BsGraph,_Convert;


PROCEDURE GoGetIt;
VAR  c          : Char;
     BBytesSent : Word;
BEGIN
     GetBlockTimeOut(BBSPort,PickList.Pickable,1,BBytesSent,[],YappDelay);
     GetCharTimeout(BBSPort,c,YappDelay);
     PickList.Line[0] := c;
     GetBlockTimeOut(BBSPort,PickList.Line[1],Ord(c),BBytesSent,[],YappDelay);
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


PROCEDURE ScrollPickTop;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          PickInfo.Top := 1;
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


PROCEDURE ScrollPickBottom;
BEGIN
     IF (PickInfo.NumItems>PickInfo.ItemsOnScrn) THEN
     BEGIN
          IF (PickInfo.Top<PickInfo.NumItems-PickInfo.ItemsOnScrn+1) THEN
          BEGIN
               PickInfo.Top := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
               GrDisplayMouse(GrHide);
               DrawPickListLocator;
               SetUpPickList;
               GrDisplayMouse(GrShow);
          END;
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
     IF (OrigT<>PickInfo.Top) THEN MoveLocator := True
     ELSE
     BEGIN
          PickInfo.Locator := OrigY;
          MoveLocator      := False;
     END;
END;


PROCEDURE SetUpPickList;
VAR  BBytesSent : Word;
     Loop       : Word;
     Y          : Word;
     Cnt        : Word;
     Last       : Word;

     PROCEDURE PickListText(x,y,f,b: Word; InString: String; NoColour: Boolean);
     VAR  Error : Integer;
          Face  : Integer;
          Loop2 : Word;
     LABEL        Continue;
     BEGIN
               txSetColor(f,b);
               InString := ConvertColourCodes(InString);
               Loop2    := 1;
               REPEAT
                     IF InString[Loop2]=#1 THEN
                     BEGIN
                          IF NOT(NoColour) THEN txSetColor(ORD(InString[Loop2+1]),b);
                          INC(Loop2);
                     END
                     ELSE
                     BEGIN
                          txOutTextXy(InString[Loop2],x,y);
                          INC(x,7);
                     END;
                     INC(Loop2);
               UNTIL (Loop2>Length(InString));
     END;

BEGIN
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL);
     Cnt  := PickInfo.Top;
     Last := PickInfo.Top+PickInfo.ItemsOnScrn-1;
     IF Last>PickInfo.NumItems THEN Last := PickInfo.NumItems;
     Y    := PickInfo.y1+8;
     IF PickInfo.Pickable THEN
     BEGIN
       PutChar(BBSPort,#255);
       PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
       PutBlockDirect(BBSPort,Last,2,BBytesSent);
       FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
       BEGIN
         IF Cnt<=PickInfo.NumItems THEN
         BEGIN
           GoGetIt;
           IF Cnt=PickInfo.Current
              THEN PickListText(PickInfo.x1+5,y,Colours.PickHighlightFore,Colours.PickHighlightBack,PickList.Line,True)
              ELSE PickListText(PickInfo.x1+5,y,Colours.PickListFore,Colours.PickListBack,PickList.Line,False);
           INC(y,14);
           INC(Cnt);
         END;
       END;
     END
     ELSE
     BEGIN
       PutChar(BBSPort,#255);
       PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
       PutBlockDirect(BBSPort,Last,2,BBytesSent);
       FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
       BEGIN
         IF Cnt<=PickInfo.NumItems THEN
         BEGIN
           GoGetIt;
           PickListText(PickInfo.x1+5,y,Colours.PicklistFore,Colours.PicklistBack,PickList.Line,False);
           INC(y,14);
           INC(Cnt);
         END;
       END;
     END;
     PutChar(BBSPort,#252);
     txSetFont(SystemFont);
END;


PROCEDURE ReSelectPickList(Old,New: Word);
VAR  Loop       : Word;
     Y          : Word;
     Cnt        : Word;
     BBytesSent : Word;

     PROCEDURE PickListText(x,y,f,b: Word; InString: String; NoColour: Boolean);
     VAR  Error : Integer;
          Face  : Integer;
          Loop2 : Word;
     LABEL        Continue;
     BEGIN
               txSetColor(f,b);
               InString := ConvertColourCodes(InString);
               Loop2    := 1;
               REPEAT
                     IF InString[Loop2]=#1 THEN
                     BEGIN
                          IF NOT(NoColour) THEN txSetColor(ORD(InString[Loop2+1]),b);
                          INC(Loop2);
                     END
                     ELSE
                     BEGIN
                          txOutTextXy(InString[Loop2],x,y);
                          INC(x,7);
                     END;
                     INC(Loop2);
               UNTIL (Loop2>Length(InString));
     END;

BEGIN
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL);
     IF (Old<>New) THEN
     BEGIN
       Cnt  := PickInfo.Top;
       Y    := PickInfo.y1+8;
       FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
       BEGIN
         IF Cnt<=PickInfo.NumItems THEN
         BEGIN
           IF Cnt=Old THEN
           BEGIN
             PutChar(BBSPort,#255);
             PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
             PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
             GoGetIt;
             PutChar(BBSPort,#252);
             PickListText(PickInfo.x1+5,y,Colours.PickListFore,Colours.PickListBack,PickList.Line,False);
           END;
           INC(y,14);
           INC(Cnt);
         END;
       END;
     END;
     Cnt  := PickInfo.Top;
     Y    := PickInfo.y1+8;
     FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
     BEGIN
       IF Cnt<=PickInfo.NumItems THEN
       BEGIN
         IF Cnt=New THEN
         BEGIN
              PutChar(BBSPort,#255);
              PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
              PutBlockDirect(BBSPort,Cnt,2,BBytesSent);
              GoGetIt;
              PutChar(BBSPort,#252);
              PickListText(PickInfo.x1+5,y,Colours.PickHighlightFore,Colours.PickHighlightBack,PickList.Line,True);
         END;
         INC(y,14);
         INC(Cnt);
       END;
     END;
     txSetFont(SystemFont);
END;


FUNCTION ItemPickable(Index: Word): Boolean;
VAR  BBytesSent : Word;
BEGIN
     PutChar(BBSPort,#253);
     PutBlockDirect(BBSPort,Index,2,BBytesSent);
     GetBlockTimeOut(BBSPort,PickList.Pickable,1,BBytesSent,[],YappDelay);
     ItemPickable := PickList.Pickable;
END;


PROCEDURE KillPickList;
BEGIN
     PickInfo.Active := False;
END;


PROCEDURE AppendToPickList(InString: String);
VAR  NumPads    : Word;
     TotSize    : Word;
BEGIN
     INC(PickInfo.NumItems);
     IF (PickInfo.NumItems>PickInfo.ItemsOnScrn) THEN
     BEGIN
          IF (PickInfo.Top<PickInfo.NumItems-PickInfo.ItemsOnScrn+1)
             THEN PickInfo.Top := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
     END;
     GrDisplayMouse(GrHide);
     DrawPickListLocator;
     SetUpPickList;
     GrDisplayMouse(GrShow);
END;


PROCEDURE NewPickList;
BEGIN
     DrawPickListLocator;
END;


PROCEDURE RedrawThePickList;
BEGIN
     PickInfo.Active := True;
     GrDisplayMouse(GrHide);
     DrawPickListLocator;
     SetUpPickList;
     GrDisplayMouse(GrShow);
END;


END.