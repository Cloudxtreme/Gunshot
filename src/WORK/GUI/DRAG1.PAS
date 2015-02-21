{$I DEFINES.INC}
UNIT Drag1;


INTERFACE


PROCEDURE GetArcDraw;
PROCEDURE GetDragArc;
PROCEDURE GetPolyDraw;
PROCEDURE GetDragPoly;
PROCEDURE GetDragBezier;
PROCEDURE GetBezierDraw;


IMPLEMENTATION


USES Globals,BsGraph,Gr2_Bp,Gx2_Bp,_Keys,Obs,Redraw,_Bezier,Shotgun;


PROCEDURE GetPolyDraw;
VAR  Bootit      : Boolean;
     AnchorX     : Word;
     AnchorY     : Word;
     LineCollect : Array[1..1000,1..4] Of Word;
     CurLine     : Word;
     Loop        : Word;
BEGIN
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := XXX1;
     yyy2 := YYY1;
     AnchorX := xxx1;
     AnchorY := yyy1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt  := False;
     CurLine := 0;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                IF CurLine<>0 THEN GrDrawLine(xxx2,yyy2,AnchorX,AnchorY);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                IF yyy2<=YWindow THEN
                BEGIN
                     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                     IF CurLine<>0 THEN GrDrawLine(xxx2,yyy2,AnchorX,AnchorY);
                END;
           END;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                INC(CurLine);
                LineCollect[CurLine,1] := xxx1;
                LineCollect[CurLine,2] := yyy1;
                LineCollect[CurLine,3] := xxx2;
                LineCollect[CurLine,4] := yyy2;
                REPEAT
                UNTIL GrGetMouseButtons<>GrLButton;
                IF CurLine=1 THEN GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                xxx1 := xxx2;
                yyy1 := yyy2;
           END
           ELSE IF GrGetMouseButtons=GrRButton THEN
           BEGIN
                INC(CurLine);
                LineCollect[CurLine,1] := xxx1;
                LineCollect[CurLine,2] := yyy1;
                LineCollect[CurLine,3] := xxx2;
                LineCollect[CurLine,4] := yyy2;
                IF CurLine=1 THEN GrDrawLine(xxx1,yyy1,xxx2,yyy2);
           END;
     UNTIL ((GrGetMouseButtons=GrRButton) OR (BootIt) OR (yyy2>YWindow));
     IF CurLine=1 THEN BootIt := True;
     IF ((BootIt) OR (yyy2>YWindow)) THEN BEGIN END
     ELSE
     BEGIN
          FOR Loop := 1 TO CurLine DO
          BEGIN
                    IF Loop=1 THEN HoldRaw.Style := 0
               ELSE HoldRaw.Style := 128;
               HoldRaw.x1 := LineCollect[Loop,1];
               HoldRaw.y1 := LineCollect[Loop,2];
               HoldRaw.x2 := LineCollect[Loop,3];
               HoldRaw.y2 := LineCollect[Loop,4];
               WriteFile;
          END;
          HoldRaw.Style := 255;
          HoldRaw.x1 := xxx2;
          HoldRaw.y1 := yyy2;
          HoldRaw.x2 := AnchorX;
          HoldRaw.y2 := AnchorY;
          WriteFile;
     END;
     GrSetOp(GxSet);
     REPEAT
     UNTIL GrGetMouseButtons<>GrRButton;
END;


PROCEDURE GetDragPoly;
VAR  RawFile2 : _Raw_File;
     RawFile3 : _Raw_File;
     EditX    : Word;
     EditY    : Word;
     P1X      : Word;
     P1Y      : Word;
     P2X      : Word;
     P2Y      : Word;
     Bootit   : Boolean;
     Exclude  : Longint;
BEGIN
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     EditX := RawFile2.x1;
     EditY := RawFile2.y1;
     P1X   := RawFile2.x2;
     P1Y   := RawFile2.y2;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     CASE RawFile2.Style OF
     0:   BEGIN
               Seek(FWorkSg,EndPoly-1);
               Exclude := EndPoly;
          END;
     ELSE BEGIN
               Seek(FWorkSg,ObjectNumber-2);
               Exclude := ObjectNumber-1;
          END;
     END;
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     RedrawScreen(ObjectNumber,Exclude);
     P2X   := RawFile2.x1;
     P2Y   := RawFile2.y1;
     GrSetColor(9);
     GrSetOp(GxXOR);
     GrDrawLine(EditX,EditY,P1X,P1Y);
     GrDrawLine(EditX,EditY,P2X,P2Y);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>EditX) OR (GetMouseYG(Grid)<>EditY)) THEN
           BEGIN
                GrDrawLine(EditX,EditY,P1X,P1Y);
                GrDrawLine(EditX,EditY,P2X,P2Y);
                EditX := GetMouseXG(Grid);
                EditY := GetMouseYG(Grid);
                GrDrawLine(EditX,EditY,P1X,P1Y);
                GrDrawLine(EditX,EditY,P2X,P2Y);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (EditY>YWindow));
     GrDrawLine(EditX,EditY,P1X,P1Y);
     GrDrawLine(EditX,EditY,P2X,P2Y);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF EditY>YWindow THEN Exit;
     IF BootIt THEN Exit;
     {write the first one}
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,RawFile2);
     RawFile2.x1 := EditX;
     RawFile2.y1 := EditY;
     SEEK(FWorkSg,ObjectNumber-1);
     WRITE(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     {write the second one}
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,Exclude-1);
     READ(FWorkSg,RawFile2);
     RawFile2.x2 := EditX;
     RawFile2.y2 := EditY;
     SEEK(FWorkSg,Exclude-1);
     WRITE(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
END;


PROCEDURE GetBezierDraw;
VAR  Bootit      : Boolean;
     AnchorX     : Word;
     AnchorY     : Word;
     LineCollect : Array[1..1000,1..8] Of Integer;
     CurLine     : Word;
     Loop        : Word;
     Continue    : Boolean;
     Wx1,Wy1     : Word;
     Wx2,Wy2     : Word;
     xxxx1,yyyy1 : Word;

     PROCEDURE SetUpAnchorPoints;
     VAR  Cruncher : Word;
     BEGIN
          IF xxx1=xxx2 THEN
          BEGIN
               wx1 := xxx1;
               wx2 := xxx1;
          END
          ELSE IF xxx1>xxx2 THEN
          BEGIN
               Cruncher := Trunc((xxx1-xxx2+1)/3);
               wx1      := xxx1-Cruncher;
               wx2      := xxx2+Cruncher;
          END
          ELSE
          BEGIN
               Cruncher := Trunc((xxx2-xxx1+1)/3);
               wx1      := xxx1+Cruncher;
               wx2      := xxx2-Cruncher;
          END;
          IF yyy1=yyy2 THEN
          BEGIN
               wy1 := yyy1;
               wy2 := yyy1;
          END
          ELSE IF yyy1>yyy2 THEN
          BEGIN
               Cruncher := Trunc((yyy1-yyy2+1)/3);
               wy1      := yyy1-Cruncher;
               wy2      := yyy2+Cruncher;
          END
          ELSE
          BEGIN
               Cruncher := Trunc((yyy2-yyy1+1)/3);
               wy1      := yyy1+Cruncher;
               wy2      := yyy2-Cruncher;
          END;
     END;

     PROCEDURE KillLast;
     BEGIN
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(LineCollect[CurLine,1],LineCollect[CurLine,2],
                     LineCollect[CurLine,5],LineCollect[CurLine,6]);
          GrDrawLine(LineCollect[CurLine,3],LineCollect[CurLine,4],
                     LineCollect[CurLine,7],LineCollect[CurLine,8]);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(LineCollect[CurLine,5]-3,LineCollect[CurLine,6]-3,
                     LineCollect[CurLine,5]+3,LineCollect[CurLine,6]+3,GrFill);
          GrDrawRect(LineCollect[CurLine,7]-3,LineCollect[CurLine,8]-3,
                     LineCollect[CurLine,7]+3,LineCollect[CurLine,8]+3,GrFill);
     END;

     PROCEDURE DrawTheBezier;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(LineCollect[CurLine,1],LineCollect[CurLine,2],
                       LineCollect[CurLine,5],LineCollect[CurLine,6],
                       LineCollect[CurLine,7],LineCollect[CurLine,8],
                       LineCollect[CurLine,3],LineCollect[CurLine,4]);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(LineCollect[CurLine,1],LineCollect[CurLine,2],
                     LineCollect[CurLine,5],LineCollect[CurLine,6]);
          GrDrawLine(LineCollect[CurLine,3],LineCollect[CurLine,4],
                     LineCollect[CurLine,7],LineCollect[CurLine,8]);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(LineCollect[CurLine,5]-3,LineCollect[CurLine,6]-3,
                     LineCollect[CurLine,5]+3,LineCollect[CurLine,6]+3,GrFill);
          GrDrawRect(LineCollect[CurLine,7]-3,LineCollect[CurLine,8]-3,
                     LineCollect[CurLine,7]+3,LineCollect[CurLine,8]+3,GrFill);
     END;

BEGIN
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := XXX1;
     yyy2 := YYY1;
     AnchorX := xxx1;
     AnchorY := yyy1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt  := False;
     CurLine := 0;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                IF CurLine<>0 THEN GrDrawLine(xxx2,yyy2,AnchorX,AnchorY);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                IF yyy2<=YWindow THEN
                BEGIN
                     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                     IF CurLine<>0 THEN GrDrawLine(xxx2,yyy2,AnchorX,AnchorY);
                END;
           END;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                INC(CurLine);
                LineCollect[CurLine,1] := xxx1;
                LineCollect[CurLine,2] := yyy1;
                LineCollect[CurLine,3] := xxx2;
                LineCollect[CurLine,4] := yyy2;
                SetUpAnchorPoints;
                LineCollect[CurLine,5] := wx1;
                LineCollect[CurLine,6] := wy1;
                LineCollect[CurLine,7] := wx2;
                LineCollect[CurLine,8] := wy2;
                REPEAT
                UNTIL GrGetMouseButtons<>GrLButton;
                Continue := False;
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                DrawTheBezier;
                GrDisplayMouse(GrShow);
                REPEAT
                      CheckKeys;
                      IF GetMouseY<=YWindow THEN Position;
                      IF GrGetMouseButtons=GrLButton THEN
                      BEGIN
                           IF ((GetMouseX>=LineCollect[CurLine,5]-3) AND
                              (GetMouseX<=LineCollect[CurLine,5]+3) AND
                              (GetMouseY>=LineCollect[CurLine,6]-3) AND
                              (GetMouseY<=LineCollect[CurLine,6]+3)) THEN
                           BEGIN
                                {anchor one}
                                xxxx1 := GetMouseX;
                                yyyy1 := GetMouseY;
                                REPEAT
                                      CheckKeys;
                                      IF GetMouseY<=YWindow THEN Position;
                                      IF ((GetMouseX<>xxxx1) OR (GetMouseY<>yyyy1)) THEN
                                      BEGIN
                                           GrDisplayMouse(GrHide);
                                           DrawTheBezier;
                                           xxxx1 := GetMouseX;
                                           yyyy1 := GetMouseY;
                                           LineCollect[CurLine,5] := xxxx1;
                                           LineCollect[CurLine,6] := yyyy1;
                                           DrawTheBezier;
                                           GrDisplayMouse(GrShow);
                                      END;
                                UNTIL (GrGetMouseButtons<>GrLButton);
                           END
                           ELSE IF ((GetMouseX>=LineCollect[CurLine,7]-3) AND
                                   (GetMouseX<=LineCollect[CurLine,7]+3) AND
                                   (GetMouseY>=LineCollect[CurLine,8]-3) AND
                                   (GetMouseY<=LineCollect[CurLine,8]+3)) THEN
                           BEGIN
                                {anchor two}
                                xxxx1 := GetMouseX;
                                yyyy1 := GetMouseY;
                                REPEAT
                                      CheckKeys;
                                      IF GetMouseY<=YWindow THEN Position;
                                      IF ((GetMouseX<>xxxx1) OR (GetMouseY<>yyyy1)) THEN
                                      BEGIN
                                           GrDisplayMouse(GrHide);
                                           DrawTheBezier;
                                           xxxx1 := GetMouseX;
                                           yyyy1 := GetMouseY;
                                           LineCollect[CurLine,7] := xxxx1;
                                           LineCollect[CurLine,8] := yyyy1;
                                           DrawTheBezier;
                                           GrDisplayMouse(GrShow);
                                      END;
                                UNTIL (GrGetMouseButtons<>GrLButton);
                           END
                           ELSE Continue := True;
                      END
                      ELSE IF GrGetMouseButtons=GrRButton THEN
                      BEGIN
                           INC(CurLine);
                           LineCollect[CurLine,1] := xxx2;
                           LineCollect[CurLine,2] := yyy2;
                           LineCollect[CurLine,3] := AnchorX;
                           LineCollect[CurLine,4] := AnchorY;
                           xxx1 := AnchorX;
                           yyy1 := AnchorY;
                           SetUpAnchorPoints;
                           LineCollect[CurLine,5] := wx2;
                           LineCollect[CurLine,6] := wy2;
                           LineCollect[CurLine,7] := wx1;
                           LineCollect[CurLine,8] := wy1;
                           BootIt := True;
                           Continue := True;
                      END;
                UNTIL Continue;
                KillLast;
                REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                REPEAT UNTIL (GrGetMouseButtons<>GrRButton);
                GrDisplayMouse(GrHide);
                IF CurLine=1 THEN GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                xxx1 := xxx2;
                yyy1 := yyy2;
           END;
     UNTIL ((BootIt) OR (yyy2>YWindow));
     IF (yyy2>YWindow) THEN BEGIN END
     ELSE
     BEGIN
          FOR Loop := 1 TO CurLine DO
          BEGIN
               IF Loop=1
                    THEN HoldRaw.Style := 0
               ELSE IF Loop=Curline
                    THEN HoldRaw.Style := 255
               ELSE HoldRaw.Style := 128;
               HoldRaw.x1 := LineCollect[Loop,1];
               HoldRaw.y1 := LineCollect[Loop,2];
               HoldRaw.x2 := LineCollect[Loop,3];
               HoldRaw.y2 := LineCollect[Loop,4];
               HoldRaw.Colour3 := LineCollect[Loop,5];
               HoldRaw.Colour4 := LineCollect[Loop,6];
               HoldRaw.Colour5 := LineCollect[Loop,7];
               HoldRaw.Colour6 := LineCollect[Loop,8];
               WriteFile;
          END;
     END;
     GrSetOp(GxSet);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


PROCEDURE GetDragBezier;
VAR  RawFile2 : _Raw_File;
     RawFile3 : _Raw_File;
     Exclude  : Longint;
     EditX    : Word;
     EditY    : Word;
     AllDone  : Boolean;

     PROCEDURE DrawTheBezier;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4,
                       RawFile2.Colour5,RawFile2.Colour6,RawFile2.x2,RawFile2.y2);
          GrDrawBezier(RawFile3.x1,RawFile3.y1,RawFile3.Colour3,RawFile3.Colour4,
                       RawFile3.Colour5,RawFile3.Colour6,RawFile3.x2,RawFile3.y2);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4);
          GrDrawLine(RawFile3.x2,RawFile3.y2,RawFile3.Colour5,RawFile3.Colour6);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(RawFile2.Colour3-3,RawFile2.Colour4-3,RawFile2.Colour3+3,RawFile2.Colour4+3,GrFill);
          GrDrawRect(RawFile3.Colour5-3,RawFile3.Colour6-3,RawFile3.Colour5+3,RawFile3.Colour6+3,GrFill);
          {Draw the pivot point handle}
          GrSetFillStyle(GrFSolid,11,GrOpaque);
          GrDrawRect(RawFile2.x1-3,RawFile2.y1-3,RawFile2.x1+3,RawFile2.y1+3,GrFill);
     END;

     PROCEDURE DrawTheBezier2;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4,
                       RawFile2.Colour5,RawFile2.Colour6,RawFile2.x2,RawFile2.y2);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(RawFile2.Colour3-3,RawFile2.Colour4-3,RawFile2.Colour3+3,RawFile2.Colour4+3,GrFill);
          {Draw the pivot point handle}
          GrSetFillStyle(GrFSolid,11,GrOpaque);
          GrDrawRect(RawFile2.x1-3,RawFile2.y1-3,RawFile2.x1+3,RawFile2.y1+3,GrFill);
     END;

     PROCEDURE DrawTheBezier3;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(RawFile3.x1,RawFile3.y1,RawFile3.Colour3,RawFile3.Colour4,
                       RawFile3.Colour5,RawFile3.Colour6,RawFile3.x2,RawFile3.y2);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(RawFile3.x2,RawFile3.y2,RawFile3.Colour5,RawFile3.Colour6);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(RawFile3.Colour5-3,RawFile3.Colour6-3,RawFile3.Colour5+3,RawFile3.Colour6+3,GrFill);
          {Draw the pivot point handle}
          GrSetFillStyle(GrFSolid,11,GrOpaque);
          GrDrawRect(RawFile2.x1-3,RawFile2.y1-3,RawFile2.x1+3,RawFile2.y1+3,GrFill);
     END;

BEGIN
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     EditX := RawFile2.x1;
     EditY := RawFile2.y1;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     CASE RawFile2.Style OF
     0:   BEGIN
               Seek(FWorkSg,EndPoly-1);
               Exclude := EndPoly;
          END;
     ELSE BEGIN
               Seek(FWorkSg,ObjectNumber-2);
               Exclude := ObjectNumber-1;
          END;
     END;
     READ(FWorkSg,RawFile3);
     CLOSE(FWorkSg);
     RedrawScreen(ObjectNumber,Exclude);
     GrSetColor(9);
     GrSetOp(GxXOR);
     DrawTheBezier;
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     AllDone := False;
     GrDisplayMouse(GrShow);
     REPEAT
           CheckKeys;
           EditX := GetMouseX;
           EditY := GetMouseY;
           IF EditY<=YWindow THEN Position;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                IF ((EditX>=RawFile2.x1-3) AND (EditX<=RawFile2.x1+3) AND
                   (EditY>=RawFile2.y1-3) AND (EditY<=RawFile2.y1+3)) THEN
                BEGIN
                     GrSetMousePos(RawFile2.x1,RawFile2.y1);
                     EditX := RawFile2.x1;
                     EditY := RawFile2.y1;
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseXG(Grid)<>EditX) OR (GetMouseYG(Grid)<>EditY)) THEN
                           BEGIN
                                DrawTheBezier;
                                EditX := GetMouseXG(Grid);
                                EditY := GetMouseYG(Grid);
                                RawFile2.x1 := EditX;
                                RawFile2.y1 := EditY;
                                RawFile3.x2 := EditX;
                                RawFile3.y2 := EditY;
                                DrawTheBezier;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrSetMousePos(EditX,EditY);
                     GrDisplayMouse(GrShow);
                END
                ELSE IF ((EditX>=RawFile2.Colour3-3) AND (EditX<=RawFile2.Colour3+3) AND
                        (EditY>=RawFile2.Colour4-3) AND (EditY<=RawFile2.Colour4+3)) THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseX<>EditX) OR (GetMouseY<>EditY)) THEN
                           BEGIN
                                DrawTheBezier2;
                                EditX := GetMouseX;
                                EditY := GetMouseY;
                                RawFile2.Colour3 := EditX;
                                RawFile2.Colour4 := EditY;
                                DrawTheBezier2;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrDisplayMouse(GrShow);
                END
                ELSE IF ((EditX>=RawFile3.Colour5-3) AND (EditX<=RawFile3.Colour5+3) AND
                        (EditY>=RawFile3.Colour6-3) AND (EditY<=RawFile3.Colour6+3)) THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseX<>EditX) OR (GetMouseY<>EditY)) THEN
                           BEGIN
                                DrawTheBezier3;
                                EditX := GetMouseX;
                                EditY := GetMouseY;
                                RawFile3.Colour5 := EditX;
                                RawFile3.Colour6 := EditY;
                                DrawTheBezier3;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrDisplayMouse(GrShow);
                END
                ELSE AllDone := True;
           END;
           IF GrGetMouseButtons=GrRButton THEN AllDone := True;
     UNTIL ((AllDone) OR (EditY>YWindow));
     GrDisplayMouse(GrHide);
     DrawTheBezier;
     REPEAT UNTIL GrGetMouseButtons<>GrRButton;
     REPEAT UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF EditY>YWindow THEN Exit;
     {write the first one}
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     WRITE(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     {write the second one}
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,Exclude-1);
     WRITE(FWorkSg,RawFile3);
     CLOSE(FWorkSg);
END;


PROCEDURE GetArcDraw;
VAR  LineCollect : Array[1..8] Of Integer;
     Wx1,Wy1     : Word;
     Wx2,Wy2     : Word;
     xxxx1,yyyy1 : Word;
     Good        : Boolean;

     PROCEDURE SetUpAnchorPoints;
     VAR  Cruncher : Word;
     BEGIN
          IF xxx1=xxx2 THEN
          BEGIN
               wx1 := xxx1;
               wx2 := xxx1;
          END
          ELSE IF xxx1>xxx2 THEN
          BEGIN
               Cruncher := Trunc((xxx1-xxx2+1)/3);
               wx1      := xxx1-Cruncher;
               wx2      := xxx2+Cruncher;
          END
          ELSE
          BEGIN
               Cruncher := Trunc((xxx2-xxx1+1)/3);
               wx1      := xxx1+Cruncher;
               wx2      := xxx2-Cruncher;
          END;
          IF yyy1=yyy2 THEN
          BEGIN
               wy1 := yyy1;
               wy2 := yyy1;
          END
          ELSE IF yyy1>yyy2 THEN
          BEGIN
               Cruncher := Trunc((yyy1-yyy2+1)/3);
               wy1      := yyy1-Cruncher;
               wy2      := yyy2+Cruncher;
          END
          ELSE
          BEGIN
               Cruncher := Trunc((yyy2-yyy1+1)/3);
               wy1      := yyy1+Cruncher;
               wy2      := yyy2-Cruncher;
          END;
     END;

     PROCEDURE KillLast;
     BEGIN
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(LineCollect[1],LineCollect[2],LineCollect[5],LineCollect[6]);
          GrDrawLine(LineCollect[3],LineCollect[4],LineCollect[7],LineCollect[8]);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(LineCollect[5]-3,LineCollect[6]-3,LineCollect[5]+3,LineCollect[6]+3,GrFill);
          GrDrawRect(LineCollect[7]-3,LineCollect[8]-3,LineCollect[7]+3,LineCollect[8]+3,GrFill);
     END;

     PROCEDURE DrawTheBezier;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(LineCollect[1],LineCollect[2],LineCollect[5],LineCollect[6],
                       LineCollect[7],LineCollect[8],LineCollect[3],LineCollect[4]);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(LineCollect[1],LineCollect[2],LineCollect[5],LineCollect[6]);
          GrDrawLine(LineCollect[3],LineCollect[4],LineCollect[7],LineCollect[8]);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(LineCollect[5]-3,LineCollect[6]-3,LineCollect[5]+3,LineCollect[6]+3,GrFill);
          GrDrawRect(LineCollect[7]-3,LineCollect[8]-3,LineCollect[7]+3,LineCollect[8]+3,GrFill);
     END;

BEGIN
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := XXX1;
     yyy2 := YYY1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     {====================================================================}
     { DRAW THE TWO STARTING POINTS                                       }
     {====================================================================}
     Good := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                IF yyy2<=YWindow THEN GrDrawLine(xxx1,yyy1,xxx2,yyy2);
           END;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                LineCollect[1] := xxx1;
                LineCollect[2] := yyy1;
                LineCollect[3] := xxx2;
                LineCollect[4] := yyy2;
                SetUpAnchorPoints;
                LineCollect[5] := wx1;
                LineCollect[6] := wy1;
                LineCollect[7] := wx2;
                LineCollect[8] := wy2;
                REPEAT
                UNTIL GrGetMouseButtons<>GrLButton;
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                DrawTheBezier;
                Good := True;
           END
           ELSE IF ((GrGetMouseButtons=GrRButton) OR (GetMouseY>YWindow)) THEN
           BEGIN
                REPEAT UNTIL GrGetMouseButtons<>GrRButton;
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                GrSetOp(GxSet);
                GrSetLineStyle(GrLSolid,1);
                GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
                GrSetClipping(GrClip);
                Exit;
           END;
     UNTIL Good;
     {====================================================================}
     { DRAW THE ARC                                                       }
     {====================================================================}
     GrDisplayMouse(GrShow);
     Good := False;
     REPEAT
           CheckKeys;
           IF GetMouseY<=YWindow THEN Position;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                IF ((GetMouseX>=LineCollect[5]-3) AND
                   (GetMouseX<=LineCollect[5]+3) AND
                   (GetMouseY>=LineCollect[6]-3) AND
                   (GetMouseY<=LineCollect[6]+3)) THEN
                BEGIN
                     {anchor one}
                     xxxx1 := GetMouseX;
                     yyyy1 := GetMouseY;
                     REPEAT
                           CheckKeys;
                           IF GetMouseY<=YWindow THEN Position;
                           IF ((GetMouseX<>xxxx1) OR (GetMouseY<>yyyy1)) THEN
                           BEGIN
                                GrDisplayMouse(GrHide);
                                DrawTheBezier;
                                xxxx1 := GetMouseX;
                                yyyy1 := GetMouseY;
                                LineCollect[5] := xxxx1;
                                LineCollect[6] := yyyy1;
                                DrawTheBezier;
                                GrDisplayMouse(GrShow);
                           END;
                     UNTIL (GrGetMouseButtons<>GrLButton);
                END
                ELSE IF ((GetMouseX>=LineCollect[7]-3) AND
                        (GetMouseX<=LineCollect[7]+3) AND
                        (GetMouseY>=LineCollect[8]-3) AND
                        (GetMouseY<=LineCollect[8]+3)) THEN
                BEGIN
                     {anchor two}
                     xxxx1 := GetMouseX;
                     yyyy1 := GetMouseY;
                     REPEAT
                           CheckKeys;
                           IF GetMouseY<=YWindow THEN Position;
                           IF ((GetMouseX<>xxxx1) OR (GetMouseY<>yyyy1)) THEN
                           BEGIN
                                GrDisplayMouse(GrHide);
                                DrawTheBezier;
                                xxxx1 := GetMouseX;
                                yyyy1 := GetMouseY;
                                LineCollect[7] := xxxx1;
                                LineCollect[8] := yyyy1;
                                DrawTheBezier;
                                GrDisplayMouse(GrShow);
                           END;
                     UNTIL (GrGetMouseButtons<>GrLButton);
                END
                ELSE Good := True;
           END
           ELSE IF ((GrGetMouseButtons=GrRButton) OR (GetMouseY>YWindow)) THEN
           BEGIN
                REPEAT UNTIL GrGetMouseButtons<>GrRButton;
                GrDisplayMouse(GrHide);
                KillLast;
                GrSetOp(GxSet);
                GrSetLineStyle(GrLSolid,1);
                GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
                GrSetClipping(GrClip);
                Exit;
           END;
     UNTIL Good;
     HoldRaw.x1      := LineCollect[1];
     HoldRaw.y1      := LineCollect[2];
     HoldRaw.x2      := LineCollect[3];
     HoldRaw.y2      := LineCollect[4];
     HoldRaw.Colour3 := LineCollect[5];
     HoldRaw.Colour4 := LineCollect[6];
     HoldRaw.Colour5 := LineCollect[7];
     HoldRaw.Colour6 := LineCollect[8];
     WriteFile;
     REPEAT UNTIL GrGetMouseButtons<>GrRButton;
     REPEAT UNTIL GrGetMouseButtons<>GrLButton;
     GrDisplayMouse(GrHide);
     KillLast;
     GrSetOp(GxSet);
     GrSetLineStyle(GrLSolid,1);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


PROCEDURE GetDragArc;
VAR  RawFile2 : _Raw_File;
     EditX    : Word;
     EditY    : Word;
     AllDone  : Boolean;

     PROCEDURE DrawTheBezier;
     BEGIN
          {Draw The Bezier}
          GrDrawBezier(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4,
                       RawFile2.Colour5,RawFile2.Colour6,RawFile2.x2,RawFile2.y2);
          {Draw the editing wires}
          GrSetLineStyle(GrLCloseDot,1);
          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.Colour3,RawFile2.Colour4);
          GrDrawLine(RawFile2.x2,RawFile2.y2,RawFile2.Colour5,RawFile2.Colour6);
          GrSetLineStyle(GrLSolid,1);
          {Draw the editing point handles}
          GrSetFillStyle(GrFSolid,14,GrOpaque);
          GrDrawRect(RawFile2.Colour3-3,RawFile2.Colour4-3,RawFile2.Colour3+3,RawFile2.Colour4+3,GrFill);
          GrDrawRect(RawFile2.Colour5-3,RawFile2.Colour6-3,RawFile2.Colour5+3,RawFile2.Colour6+3,GrFill);
          {Draw the pivot point handles}
          GrSetFillStyle(GrFSolid,11,GrOpaque);
          GrDrawRect(RawFile2.x1-3,RawFile2.y1-3,RawFile2.x1+3,RawFile2.y1+3,GrFill);
          GrDrawRect(RawFile2.x2-3,RawFile2.y2-3,RawFile2.x2+3,RawFile2.y2+3,GrFill);
     END;

BEGIN
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     EditX := RawFile2.x1;
     EditY := RawFile2.y1;
     RedrawScreen(ObjectNumber,ObjectNumber);
     GrSetColor(9);
     GrSetOp(GxXOR);
     DrawTheBezier;
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     AllDone := False;
     GrDisplayMouse(GrShow);
     REPEAT
           CheckKeys;
           EditX := GetMouseX;
           EditY := GetMouseY;
           IF EditY<=YWindow THEN Position;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                IF ((EditX>=RawFile2.x1-3) AND (EditX<=RawFile2.x1+3) AND
                   (EditY>=RawFile2.y1-3) AND (EditY<=RawFile2.y1+3)) THEN
                BEGIN
                     GrSetMousePos(RawFile2.x1,RawFile2.y1);
                     EditX := RawFile2.x1;
                     EditY := RawFile2.y1;
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseXG(Grid)<>EditX) OR (GetMouseYG(Grid)<>EditY)) THEN
                           BEGIN
                                DrawTheBezier;
                                EditX := GetMouseXG(Grid);
                                EditY := GetMouseYG(Grid);
                                RawFile2.x1 := EditX;
                                RawFile2.y1 := EditY;
                                DrawTheBezier;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrSetMousePos(EditX,EditY);
                     GrDisplayMouse(GrShow);
                END
                ELSE IF ((EditX>=RawFile2.x2-3) AND (EditX<=RawFile2.x2+3) AND
                        (EditY>=RawFile2.y2-3) AND (EditY<=RawFile2.y2+3)) THEN
                BEGIN
                     GrSetMousePos(RawFile2.x2,RawFile2.y2);
                     EditX := RawFile2.x2;
                     EditY := RawFile2.y2;
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseXG(Grid)<>EditX) OR (GetMouseYG(Grid)<>EditY)) THEN
                           BEGIN
                                DrawTheBezier;
                                EditX := GetMouseXG(Grid);
                                EditY := GetMouseYG(Grid);
                                RawFile2.x2 := EditX;
                                RawFile2.y2 := EditY;
                                DrawTheBezier;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrSetMousePos(EditX,EditY);
                     GrDisplayMouse(GrShow);
                END
                ELSE IF ((EditX>=RawFile2.Colour3-3) AND (EditX<=RawFile2.Colour3+3) AND
                        (EditY>=RawFile2.Colour4-3) AND (EditY<=RawFile2.Colour4+3)) THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseX<>EditX) OR (GetMouseY<>EditY)) THEN
                           BEGIN
                                DrawTheBezier;
                                EditX := GetMouseX;
                                EditY := GetMouseY;
                                RawFile2.Colour3 := EditX;
                                RawFile2.Colour4 := EditY;
                                DrawTheBezier;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrDisplayMouse(GrShow);
                END
                ELSE IF ((EditX>=RawFile2.Colour5-3) AND (EditX<=RawFile2.Colour5+3) AND
                        (EditY>=RawFile2.Colour6-3) AND (EditY<=RawFile2.Colour6+3)) THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     REPEAT
                           CheckKeys;
                           IF EditY<=YWindow THEN Position;
                           IF ((GetMouseX<>EditX) OR (GetMouseY<>EditY)) THEN
                           BEGIN
                                DrawTheBezier;
                                EditX := GetMouseX;
                                EditY := GetMouseY;
                                RawFile2.Colour5 := EditX;
                                RawFile2.Colour6 := EditY;
                                DrawTheBezier;
                           END;
                     UNTIL ((GrGetMouseButtons<>GrLButton) OR (EditY>YWindow));
                     GrDisplayMouse(GrShow);
                END
                ELSE AllDone := True;
           END;
           IF GrGetMouseButtons=GrRButton THEN AllDone := True;
     UNTIL ((AllDone) OR (EditY>YWindow));
     GrDisplayMouse(GrHide);
     DrawTheBezier;
     REPEAT UNTIL GrGetMouseButtons<>GrRButton;
     REPEAT UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF EditY>YWindow THEN Exit;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     WRITE(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
END;


END.
