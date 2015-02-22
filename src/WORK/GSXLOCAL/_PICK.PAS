{======================================================}
{  This unit is specifically for handling pick lists.  }
{======================================================}
{$I DEFINES.INC}
UNIT _Pick;


INTERFACE


FUNCTION  MoveLocator                                             : Boolean;
FUNCTION  ItemPickable       (Index: Word)                        : Boolean;
FUNCTION  TrueIndex          (Index: Word)                        : Word;
PROCEDURE AddToPickList      (InString: String; Index: Word; Pickable: Boolean);
PROCEDURE NewPickList        (Pickable: Boolean);
PROCEDURE AppendToPickList   (InString: String);
PROCEDURE ReSelectPickList   (Old,New: Word);
PROCEDURE BeginPickList;
PROCEDURE KillPickList;
PROCEDURE SetUpPickList;
PROCEDURE ScrollPickUp;
PROCEDURE ScrollPickDown;
PROCEDURE ScrollPickPgUp;
PROCEDURE ScrollPickPgDown;
PROCEDURE ScrollPickTop;
PROCEDURE ScrollPickBottom;
PROCEDURE DrawPickListLocator;


IMPLEMENTATION


USES Globals,Gr2_Bp,Gx2_Bp,_Win,BsGraph,Special,
     _Convert,Tx2_Bp,_Mouse,BsFile,BsString;


PROCEDURE ScrollPickUp;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          DEC(PickInfo.Top);
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
     END;
END;


PROCEDURE ScrollPickDown;
BEGIN
     IF ((PickInfo.Top+PickInfo.ItemsOnScrn-1)<PickInfo.NumItems) THEN
     BEGIN
          INC(PickInfo.Top);
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
     END;
END;


PROCEDURE ScrollPickTop;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          PickInfo.Top := 1;
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
     END;
END;


PROCEDURE ScrollPickBottom;
BEGIN
     IF (PickInfo.NumItems>PickInfo.ItemsOnScrn) THEN
     BEGIN
          IF (PickInfo.Top<PickInfo.NumItems-PickInfo.ItemsOnScrn+1) THEN
          BEGIN
               PickInfo.Top := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
               HideTheMouse;
               DrawPickListLocator;
               SetUpPickList;
               ShowTheMouse;
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
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
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
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
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
     HideTheMouse;
     SetMousePos(PickInfo.x2+1,PickInfo.Locator);
     LastY := PickInfo.Locator;
     OrigY := PickInfo.Locator;
     SetMouseBounds(PickInfo.x2+1,PickInfo.y1+21,PickInfo.x2+1,PickInfo.y2-41);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetOp(GxXOR);
     GrSetColor(15);
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     REPEAT
           IF (MousePosY<>LastY) THEN
           BEGIN
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
                LastY := MousePosY;
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
           END;
     UNTIL NOT(RightButtonPress);
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     GrSetOp(GxSet);
     SetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
     SetMousePos(PickInfo.x2+10,LastY+10);
     ShowTheMouse;
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


PROCEDURE SetUpPickList;
VAR  Loop : Word;
     Y    : Word;
     Cnt  : Word;

     PROCEDURE PickListText(x,y,f,b: Word; InString: String; NoColour: Boolean);
     VAR  Error : Integer;
          Face  : Integer;
          Loop2 : Word;
     LABEL        Continue;
     BEGIN
          InString := Process_Special(InString,False);

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
     Y    := PickInfo.y1+8;
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,Cnt-1);
     END;
     IF PickInfo.Pickable THEN
     BEGIN
       FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
       BEGIN
         IF Cnt<=PickInfo.NumItems THEN
         BEGIN
           IF PickInfo.UsingDisk
              THEN READ(FPickList,PickList)
              ELSE Move(HugePick^[Cnt],PickList,SizeOf(PickList));
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
       FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
       BEGIN
         IF Cnt<=PickInfo.NumItems THEN
         BEGIN
           IF PickInfo.UsingDisk
              THEN READ(FPickList,PickList)
              ELSE Move(HugePick^[Cnt],PickList,SizeOf(PickList));
           PickListText(PickInfo.x1+5,y,Colours.PicklistFore,Colours.PicklistBack,PickList.Line,False);
           INC(y,14);
           INC(Cnt);
         END;
       END;
     END;
     IF PickInfo.UsingDisk THEN CLOSE(FPickList);
     txSetFont(SystemFont);
END;


PROCEDURE ReSelectPickList(Old,New: Word);
VAR  Loop : Word;
     Y    : Word;
     Cnt  : Word;

     PROCEDURE PickListText(x,y,f,b: Word; InString: String; NoColour: Boolean);
     VAR  Error : Integer;
          Face  : Integer;
          Loop2 : Word;
     LABEL        Continue;
     BEGIN
          InString := Process_Special(InString,False);

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
     Y    := PickInfo.y1+8;
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,Cnt-1);
     END;
     FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
     BEGIN
       IF Cnt<=PickInfo.NumItems THEN
       BEGIN
         IF PickInfo.UsingDisk
            THEN READ(FPickList,PickList)
            ELSE Move(HugePick^[Cnt],PickList,SizeOf(PickList));
         IF Cnt=New
            THEN PickListText(PickInfo.x1+5,y,Colours.PickHighlightFore,Colours.PickHighlightBack,PickList.Line,True)
         ELSE IF ((Cnt=Old) AND (Old<>New))
            THEN PickListText(PickInfo.x1+5,y,Colours.PickListFore,Colours.PickListBack,PickList.Line,False);
         INC(y,14);
         INC(Cnt);
       END;
     END;
     IF PickInfo.UsingDisk THEN CLOSE(FPickList);
     txSetFont(SystemFont);
END;


FUNCTION TrueIndex(Index: Word): Word;
BEGIN
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,Index-1);
          READ(FPickList,PickList);
          CLOSE(FPickList);
     END
     ELSE Move(HugePick^[Index],PickList,SizeOf(PickList));
     TrueIndex := PickList.TrueIndex;
END;


FUNCTION ItemPickable(Index: Word): Boolean;
BEGIN
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,Index-1);
          READ(FPickList,PickList);
          CLOSE(FPickList);
     END
     ELSE Move(HugePick^[Index],PickList,SizeOf(PickList));
     ItemPickable := PickList.Pickable;
END;


PROCEDURE BeginPickList;
BEGIN
     IF PickInfo.UsingDisk THEN CLOSE(FPickList);
END;


PROCEDURE KillPickList;
BEGIN
     IF PickInfo.UsingDisk THEN _EraseFile(NODE_Directory+'\PICK.LST');
     PickInfo.Active := False;
END;


PROCEDURE AppendToPickList(InString: String);
VAR  NumPads    : Word;
     TotSize    : Word;
     FFile      : File;
BEGIN
     INC(PickInfo.NumItems);
     IF PickInfo.NumItems=MaxPick+1 THEN
     BEGIN
          {Commit to disk}
          ASSIGN(FFile,NODE_Directory+'\PICK.LST');
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,HugePick^,SizeOf(HugePick^));
          CLOSE(FFile);
          PickInfo.UsingDisk := True;
     END;
     TotSize := LENGTH(Process_Special(InString,True));
     IF TotSize=PickInfo.MaxChars THEN
     BEGIN
          PickList.Line := InString;
     END
     ELSE IF TotSize<PickInfo.MaxChars THEN
     BEGIN
          NumPads       := PickInfo.MaxChars-TotSize;
          PickList.Line := InString+_PadRight('',NumPads);
     END
     ELSE
     BEGIN
          NumPads       := TotSize-PickInfo.MaxChars;
          PickList.Line := _Mid(InString,1,LENGTH(InString)-NumPads);
     END;
     PickList.Pickable  := False;
     PickList.TrueIndex := 0;
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,FileSize(FPickList));
          WRITE(FPickList,PickList);
          CLOSE(FPickList);
          IF IOResult=0 THEN;
     END
     ELSE Move(PickList,HugePick^[PickInfo.NumItems],SizeOf(PickList));
     IF (PickInfo.NumItems>PickInfo.ItemsOnScrn) THEN
     BEGIN
          IF (PickInfo.Top<PickInfo.NumItems-PickInfo.ItemsOnScrn+1)
             THEN PickInfo.Top := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
     END;
     HideTheMouse;
     DrawPickListLocator;
     SetUpPickList;
     ShowTheMouse;
END;


PROCEDURE AddToPickList(InString: String; Index: Word; Pickable: Boolean);
VAR  NumPads    : Word;
     TotSize    : Word;
     FFile      : File;
BEGIN
     INC(PickInfo.NumItems);
     IF PickInfo.NumItems=MaxPick+1 THEN
     BEGIN
          {Commit to disk}
          ASSIGN(FFile,NODE_Directory+'\PICK.LST');
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,HugePick^,SizeOf(HugePick^));
          CLOSE(FFile);
          {Open the file}
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RESET(FPickList);
          SEEK(FPickList,FileSize(FPickList));
          PickInfo.UsingDisk := True;
     END;
     TotSize := LENGTH(Process_Special(InString,True));
     IF TotSize=PickInfo.MaxChars THEN
     BEGIN
          PickList.Line := InString;
     END
     ELSE IF TotSize<PickInfo.MaxChars THEN
     BEGIN
          NumPads       := PickInfo.MaxChars-TotSize;
          PickList.Line := InString+_PadRight('',NumPads);
     END
     ELSE
     BEGIN
          NumPads       := TotSize-PickInfo.MaxChars;
          PickList.Line := _Mid(InString,1,LENGTH(InString)-NumPads);
     END;
     PickList.Pickable  := Pickable;
     PickList.TrueIndex := Index;
     IF PickInfo.UsingDisk THEN
     BEGIN
          WRITE(FPickList,PickList);
          IF IOResult=0 THEN;
     END
     ELSE Move(PickList,HugePick^[PickInfo.NumItems],SizeOf(PickList));
END;


PROCEDURE NewPickList(Pickable: Boolean);
BEGIN
     PickInfo.ItemsOnScrn := Trunc((PickInfo.y2-PickInfo.y1-10)/14);
     PickInfo.MaxChars    := Trunc((PickInfo.x2-PickInfo.x1-10)/7);
     PickInfo.UsingDisk   := False;
     PickInfo.Active      := True;
     PickInfo.Top         := 1;
     PickInfo.NumItems    := 0;
     PickInfo.Current     := 1;
     PickInfo.Locator     := PickInfo.y1+21;
     PickInfo.Pickable    := Pickable;
     DrawPickListLocator;
END;


END.
