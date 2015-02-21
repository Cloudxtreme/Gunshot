{$I DEFINES.INC}
UNIT ImgDefs;


INTERFACE


FUNCTION  GetChangeImage: Boolean;
PROCEDURE GetChangeEffect(VAR InEffect: Integer);


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,BHandler,_Text,PickLst;


FUNCTION GetChangeImage: Boolean;
VAR  C          : Word;
     AllDone    : Boolean;
     XX,YY      : Word;
     AnyChanges : Boolean;

     PROCEDURE UpdateDither(NewDither: Word);
     BEGIN
          XX := ScreenInfo.OrigX1+ScreenInfo.XOffset;
          YY := ScreenInfo.OrigY1+ScreenInfo.YOffset;
          {Clear Last Dither}
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          CASE HoldRaw.Colour2 OF
          1:   GrDrawRect(XX+34,YY+74,XX+39,YY+79,GrFill);
          2:   GrDrawRect(XX+34,YY+94,XX+39,YY+99,GrFill);
          3:   GrDrawRect(XX+34,YY+114,XX+39,YY+119,GrFill);
          4:   GrDrawRect(XX+34,YY+134,XX+39,YY+139,GrFill);
          END;
          {Draw New Dither}
          HoldRaw.Colour2 := NewDither;
          GrSetFillStyle(GrFSolid,4,GrOpaque);
          CASE HoldRaw.Colour2 OF
          1:   GrDrawRect(XX+34,YY+74,XX+39,YY+79,GrFill);
          2:   GrDrawRect(XX+34,YY+94,XX+39,YY+99,GrFill);
          3:   GrDrawRect(XX+34,YY+114,XX+39,YY+119,GrFill);
          4:   GrDrawRect(XX+34,YY+134,XX+39,YY+139,GrFill);
          END;
     END;

     PROCEDURE UpdateTakeOver;
     BEGIN
          XX := ScreenInfo.OrigX1+ScreenInfo.XOffset;
          YY := ScreenInfo.OrigY1+ScreenInfo.YOffset;
          {Gray scale}
          CASE HoldRaw.Colour1 OF
          0:   GrSetFillStyle(GrFSolid,7,GrOpaque);
          1:   GrSetFillStyle(GrFSolid,4,GrOpaque);
          END;
          GrDrawRect(XX+34,YY+199,XX+39,YY+204,GrFill);
     END;

BEGIN
     AnyChanges := False;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     SaveWindow(3);
     NButtons := 0;
     DrawWindow(130,110,555,340,'GRAPHIC IMAGE OPTIONS',FloatingMenu);
     InvertedBox(140,170,345,260);
     InvertedBox(140,290,345,330);
     XX := ScreenInfo.OrigX1+ScreenInfo.XOffset;
     YY := ScreenInfo.OrigY1+ScreenInfo.YOffset;
     SystemButton(XX+30,YY+70,0,0,4,False,True);   {Magic Square}
     SystemButton(XX+30,YY+90,0,0,4,False,True);   {Dispersed Dot}
     SystemButton(XX+30,YY+110,0,0,4,False,True);  {Clustered Dot}
     SystemButton(XX+30,YY+130,0,0,4,False,True);  {Best Match}
     SystemButton(XX+30,YY+195,0,0,4,False,True);  {Gray Scale}
     SystemButton(480,300,545,330,1,False,True);   {Done Button}
     OutTextXY(XX+60,YY+70,0,255,1,'Magic Square');
     OutTextXY(XX+60,YY+90,0,255,1,'Dispersed Dot');
     OutTextXY(XX+60,YY+110,0,255,1,'Clustered Dot');
     OutTextXY(XX+60,YY+130,0,255,1,'No Dithering');
     OutTextXY(XX+60,YY+195,0,255,1,'Gray Scale Image');
     OutTextXY(140,154,1,255,1,'Image Dithering:');
     OutTextXY(140,274,1,255,1,'Palette Behaviour:');
     OutTextXY(355,154,1,255,1,'Drawing Effect:');
     OutTextXY(500,307,0,255,1,'Done');

     NewPickList(356,171,7,19);
     AddToPickList('No Effect');
     AddToPickList('Blind - Horiz');
     AddToPickList('Blind - Verti');
     AddToPickList('Crush - Horiz');
     AddToPickList('Crush - Verti');
     AddToPickList('Diagonal - Up/Right');
     AddToPickList('Diagonal - Dn/Right');
     AddToPickList('Diagonal - Up/Left');
     AddToPickList('Diagonal - Dn/Left');
     AddToPickList('Drip - Up');
     AddToPickList('Drip - Down');
     AddToPickList('Explode - In');
     AddToPickList('Explode - Out');
     AddToPickList('Interleave - Horiz');
     AddToPickList('Interleave - Verti');
     AddToPickList('Random');
     AddToPickList('Sand - Up');
     AddToPickList('Sand - Down');
     AddToPickList('Slide - Up');
     AddToPickList('Slide - Down');
     AddToPickList('Slide - Left');
     AddToPickList('Slide - Right');
     AddToPickList('Slide Blind - Horiz');
     AddToPickList('Slide Blind - Verti');
     AddToPickList('Slide Weave - Horiz');
     AddToPickList('Slide Weave - Verti');
     AddToPickList('Spiral - In');
     AddToPickList('Spiral - Out');
     AddToPickList('Split - Horiz');
     AddToPickList('Split - Verti');
     AddToPickList('Weave - Horiz');
     AddToPickList('Weave - Verti');
     AddToPickList('Wipe - Up');
     AddToPickList('Wipe - Down');
     AddToPickList('Wipe - Left');
     AddToPickList('Wipe - Right');
     IF (HoldRaw.Colour3+1>PickInfo.NumItems) THEN HoldRaw.Colour3 := 0;
     PickInfo.Current := HoldRaw.Colour3+1;
     SetUpPickList;
     UpdateDither(HoldRaw.Colour2);
     UpdateTakeOver;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     AllDone := False;
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           1:   BEGIN
                     GrDisplayMouse(GrHide);
                     UpdateDither(1);
                     GrDisplayMouse(GrShow);
                     AnyChanges := True;
                END;
           2:   BEGIN
                     GrDisplayMouse(GrHide);
                     UpdateDither(2);
                     GrDisplayMouse(GrShow);
                     AnyChanges := True;
                END;
           3:   BEGIN
                     GrDisplayMouse(GrHide);
                     UpdateDither(3);
                     GrDisplayMouse(GrShow);
                     AnyChanges := True;
                END;
           4:   BEGIN
                     GrDisplayMouse(GrHide);
                     UpdateDither(4);
                     GrDisplayMouse(GrShow);
                     AnyChanges := True;
                END;
           5:   BEGIN
                     IF HoldRaw.Colour1=0 THEN HoldRaw.Colour1 := 1
                                          ELSE HoldRaw.Colour1 := 0;
                     GrDisplayMouse(GrHide);
                     UpdateTakeOver;
                     GrDisplayMouse(GrShow);
                     AnyChanges := True;
                END;
           6:   AllDone := True;
           END;
     UNTIL AllDone;
     IF (PickInfo.Current<>HoldRaw.Colour3+1) THEN
     BEGIN
          HoldRaw.Colour3 := PickInfo.Current-1;
          AnyChanges := True;
     END;
     KillWindow;
     ReloadWindow(3);
     KillPickList;
     GetChangeImage := AnyChanges;
END;


PROCEDURE GetChangeEffect(VAR InEffect: Integer);
VAR  C          : Word;
     AllDone    : Boolean;
     XX,YY      : Word;
BEGIN
     IF MouseOn THEN GrDisplayMouse(GrHide);
     SaveWindow(3);
     NButtons := 0;
     DrawWindow(350,110,555,340,'IMAGE EFFECT',FloatingMenu);
     XX := ScreenInfo.OrigX1+ScreenInfo.XOffset;
     YY := ScreenInfo.OrigY1+ScreenInfo.YOffset;
     SystemButton(480,300,545,330,1,False,True);   {Done Button}
     OutTextXY(355,154,1,255,1,'Drawing Effect:');
     OutTextXY(500,307,0,255,1,'Done');
     NewPickList(356,171,7,19);
     AddToPickList('No Effect');
     AddToPickList('Blind - Horiz');
     AddToPickList('Blind - Verti');
     AddToPickList('Crush - Horiz');
     AddToPickList('Crush - Verti');
     AddToPickList('Diagonal - Up/Right');
     AddToPickList('Diagonal - Dn/Right');
     AddToPickList('Diagonal - Up/Left');
     AddToPickList('Diagonal - Dn/Left');
     AddToPickList('Drip - Up');
     AddToPickList('Drip - Down');
     AddToPickList('Explode - In');
     AddToPickList('Explode - Out');
     AddToPickList('Interleave - Horiz');
     AddToPickList('Interleave - Verti');
     AddToPickList('Random');
     AddToPickList('Sand - Up');
     AddToPickList('Sand - Down');
     AddToPickList('Slide - Up');
     AddToPickList('Slide - Down');
     AddToPickList('Slide - Left');
     AddToPickList('Slide - Right');
     AddToPickList('Slide Blind - Horiz');
     AddToPickList('Slide Blind - Verti');
     AddToPickList('Slide Weave - Horiz');
     AddToPickList('Slide Weave - Verti');
     AddToPickList('Spiral - In');
     AddToPickList('Spiral - Out');
     AddToPickList('Split - Horiz');
     AddToPickList('Split - Verti');
     AddToPickList('Weave - Horiz');
     AddToPickList('Weave - Verti');
     AddToPickList('Wipe - Up');
     AddToPickList('Wipe - Down');
     AddToPickList('Wipe - Left');
     AddToPickList('Wipe - Right');
     IF (InEffect+1>PickInfo.NumItems) THEN InEffect := 0;
     PickInfo.Current := InEffect+1;
     SetUpPickList;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     AllDone := False;
     REPEAT
           C := MouseHandler(False);
           IF C=1 THEN AllDone := True;
     UNTIL AllDone;
     InEffect := PickInfo.Current-1;
     KillWindow;
     ReloadWindow(3);
     KillPickList;
END;


END.