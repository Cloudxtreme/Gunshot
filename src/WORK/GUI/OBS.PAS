{$I DEFINES.INC}
UNIT Obs;

INTERFACE


FUNCTION  KillLast                                         : Boolean;
FUNCTION  CheckObject        (x,y: Word)                   : Boolean;
FUNCTION  HighLightObject    (x,y: Word; DoCheck: Boolean) : Boolean;
PROCEDURE HighLightTheObject (Index: Word);
PROCEDURE WriteToFile        (Index: Word);
PROCEDURE MoveToBottom       (Num: Word);
PROCEDURE MoveToTop          (Num: Word);
PROCEDURE DeleteObject       (Num: Word);
PROCEDURE UpdatePoly;
PROCEDURE WriteFile;


IMPLEMENTATION


USES Globals,Redraw,Gr2_Bp,BsGraph,_Text,_Bezier,Shotgun;


FUNCTION CheckObject(x,y: Word): Boolean;
VAR  LoopX       : Word;
     LoopY       : Word;
     Counter     : Longint;
     RawFile2    : _Raw_File;

     FUNCTION Match(xx,yy,ChX,ChY: Integer): Boolean;
     BEGIN
          IF ((xx>=ChX-2) AND (xx<=ChX+2) AND (yy>=ChY-2) AND (yy<=ChY+2))
             THEN Match := True
             ELSE Match := False;
     END;

BEGIN
     CheckObject := False;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     Counter := 0;
     REPEAT
           READ(FWorkSg,RawFile2);
           INC(Counter);
           CASE RawFile2.Number OF
           1:     ; {SCREEN BACKGROUNDS}
           2:     ; {SCREEN MOUSE}
           3:     ; {SCREEN SOUND}
           4,5,8,9,11,18,20,21,22,23,26,27,28:
                  BEGIN
                       IF ((Match(x,y,RawFile2.x1,RawFile2.y1)=True) OR
                          (Match(x,y,RawFile2.x2,RawFile2.y2)=True)) THEN
                       BEGIN
                            IF Match(x,y,RawFile2.x1,RawFile2.y1)
                               THEN EditNode := 1
                               ELSE EditNode := 2;
                            CheckObject := True;
                            ObjectNumber := Counter;
                            CLOSE(FWorkSg);
                            Exit;
                       END;
                  END;
           6,7,10,12,13,14,15,16,17,19,24,25:
                  BEGIN
                       IF (Match(x,y,RawFile2.x1,RawFile2.y1)=True) THEN
                       BEGIN
                            EditNode := 1;
                            CheckObject := True;
                            ObjectNumber := Counter;
                            CLOSE(FWorkSg);
                            Exit;
                       END;
                  END;
           END;
     UNTIL EOF(FWorkSg);
     CLOSE(FWorkSg);
END;


FUNCTION HighLightObject(x,y: Word; DoCheck: Boolean): Boolean;
VAR  LoopX       : Word;
     LoopY       : Word;
     RawFile2    : _Raw_File;
     Work        : Longint;
     GotIt       : Longint;
BEGIN
     IF DoCheck THEN
     BEGIN
          IF NOT(CheckObject(x,y)) THEN
          BEGIN
               HighLightObject := False;
               Exit;
          END;
          IF (ObjectNumber<>0) THEN RedrawScreen(0,0);
     END;
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     CASE RawFile2.Number OF
     1:   ; {SCREEN BACKGROUNDS}
     2:   ; {SCREEN MOUSE}
     3:   ; {SCREEN SOUND}
     4:   BEGIN
               GrSetColor(9);
               GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
               HoldRaw := RawFile2;
          END;
     5,11,18,20,22,23:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
               HoldRaw := RawFile2;
          END;
     6:   BEGIN
               GrSetColor(9);
               GrDrawEllipse(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               HoldRaw := RawFile2;
          END;
     7:   BEGIN
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               HoldRaw := RawFile2;
          END;
     8,9,27:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetColor(4);
               GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
               HoldRaw := RawFile2;
          END;
     10:  BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetColor(4);
               GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               HoldRaw := RawFile2;
          END;
     12,24,25:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               HoldRaw := RawFile2;
          END;
     13:  BEGIN
               HoldRaw := RawFile2;
               RawFile2.Colour1 := 9;
               RawFile2.Text    := StripColourCodes(RawFile2.Text);
               DoText(RawFile2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     14:  BEGIN
               HoldRaw   := RawFile2;
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=14) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=ObjectNumber) THEN GotIt := Work
                                                  ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=14) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     15:  BEGIN
               HoldRaw   := RawFile2;
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=15) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=ObjectNumber) THEN GotIt := Work
                                                  ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=15) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     16:  BEGIN
               HoldRaw   := RawFile2;
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=16) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=ObjectNumber) THEN GotIt := Work
                                                  ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=16) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     17:  BEGIN
               HoldRaw   := RawFile2;
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=17) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=ObjectNumber) THEN GotIt := Work
                                                  ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=17) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     19:  BEGIN
               Work := (GetStringWidth(RawFile2.Colour4)*8)+20;
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x1+Work,RawFile2.y1+20,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               HoldRaw := RawFile2;
          END;
     21,
     28:  BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrDrawRect(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
               HoldRaw := RawFile2;
          END;
     26:  BEGIN
               GrSetColor(9);
               GrDrawBezier(RawFile2.x1,RawFile2.y1,
                            RawFile2.Colour3,RawFile2.Colour4,
                            RawFile2.Colour5,RawFile2.Colour6,
                            RawFile2.x2,RawFile2.y2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
               HoldRaw   := RawFile2;
          END;
     END;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
     HighLightObject := True;
END;


PROCEDURE HighLightTheObject(Index: Word);
VAR  LoopX       : Word;
     LoopY       : Word;
     RawFile2    : _Raw_File;
     Work        : Longint;
     GotIt       : Longint;
BEGIN
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,Index-1);
     READ(FWorkSg,RawFile2);
     CLOSE(FWorkSg);
     CASE RawFile2.Number OF
     1:   ; {SCREEN BACKGROUNDS}
     2:   ; {SCREEN MOUSE}
     3:   ; {SCREEN SOUND}
     4:   BEGIN
               GrSetColor(9);
               GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
          END;
     5,11,18,20,22,23:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
          END;
     6:   BEGIN
               GrSetColor(9);
               GrDrawEllipse(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     7:   BEGIN
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     8,9,27:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetColor(4);
               GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
          END;
     10:  BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetColor(4);
               GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     12,24,25:
          BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     13:  BEGIN
               RawFile2.Colour1 := 9;
               RawFile2.Text    := StripColourCodes(RawFile2.Text);
               DoText(RawFile2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     14:  BEGIN
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=14) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=Index) THEN GotIt := Work
                                           ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=14) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     15:  BEGIN
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=15) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=Index) THEN GotIt := Work
                                           ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=15) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     16:  BEGIN
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=16) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=Index) THEN GotIt := Work
                                           ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=16) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     17:  BEGIN
               StartPoly := 999999;
               GotIt     := 0;
               {FIND START OF POLY - STYLE 0}
               Work := 0;
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF ((RawFile2.Number=17) AND (RawFile2.Style=0)) THEN
                     BEGIN
                          IF (Work<=Index) THEN GotIt := Work
                                           ELSE StartPoly := GotIt;
                     END;
               UNTIL ((EOF(FWorkSg)) OR (StartPoly<>999999));
               CLOSE(FWorkSg);
               IF StartPoly=999999 THEN StartPoly := GotIt;
               {DRAW THE POLY}
               ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
               RESET(FWorkSg);
               SEEK(FWorkSg,StartPoly-1);
               Work := StartPoly-1;
               REPEAT
                     READ(FWorkSg,RawFile2);
                     INC(Work);
                     IF (RawFile2.Number=17) THEN
                     BEGIN
                          GrSetColor(9);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,11,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
               UNTIL (RawFile2.Style=255);
               EndPoly := Work;
               CLOSE(FWorkSg);
          END;
     19:  BEGIN
               Work := (GetStringWidth(RawFile2.Colour4)*8)+20;
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x1+Work,RawFile2.y1+20,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
          END;
     21,
     28:  BEGIN
               GrSetColor(9);
               GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
               GrDrawRect(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2,GrOutline);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
          END;
     26:  BEGIN
               GrSetColor(9);
               GrDrawBezier(RawFile2.x1,RawFile2.y1,
                            RawFile2.Colour3,RawFile2.Colour4,
                            RawFile2.Colour5,RawFile2.Colour6,
                            RawFile2.x2,RawFile2.y2);
               GrSetFillStyle(GrFSolid,11,GrOpaque);
               GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
               GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
          END;
     END;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


FUNCTION KillLast: Boolean;
VAR  RawFile2 : _Raw_File;
     FWorkSG2 : File Of _Raw_File;
     Work     : Longint;
     TheOne   : Longint;
     Loop     : Longint;
BEGIN
     IF IOResult=0 THEN;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     {$I-}RESET(FWorkSg);{$I+}
     IF IOResult<>0 THEN
     BEGIN
          KillLast := False;
          Exit;
     END;
     READ(FWorkSg,RawFile2);
     READ(FWorkSg,RawFile2);
     READ(FWorkSg,RawFile2);
     IF EOF(FWorkSg) THEN
     BEGIN
          CLOSE(FWorkSg);
          IF IOResult=0 THEN;
          KillLast := False;
          Exit;
     END;
     Work := 3;
     REPEAT
           READ(FWorkSg,RawFile2);
           INC(Work);
           TheOne := Work;
           CASE RawFile2.Number OF
           14:  BEGIN
                     REPEAT
                           READ(FWorkSg,RawFile2);
                           INC(Work);
                     UNTIL RawFile2.Style=255;
                END;
           15:  BEGIN
                     REPEAT
                           READ(FWorkSg,RawFile2);
                           INC(Work);
                     UNTIL (RawFile2.Style=255);
                END;
           16:  BEGIN
                     REPEAT
                           READ(FWorkSg,RawFile2);
                           INC(Work);
                     UNTIL (RawFile2.Style=255);
                END;
           17:  BEGIN
                     REPEAT
                           READ(FWorkSg,RawFile2);
                           INC(Work);
                     UNTIL (RawFile2.Style=255);
                END;
           END;
     UNTIL EOF(FWorkSg);
     CLOSE(FWorkSg);
     IF IOResult=0 THEN;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSG);
     {$I-}
     SEEK(FWorkSG,TheOne-1);
     TRUNCATE(FWorkSG);
     {$I+}
     CLOSE(FWorkSG);
     IF IOResult=0 THEN;
     KillLast := True;
END;


PROCEDURE MoveToTop(Num: Word); {DRAW THE OBJECT LAST}
VAR  FOldRawFile : File Of _Raw_File;
     FNewRawFile : File Of _Raw_File;
     FTempRaw    : File Of _Raw_File;
     Counter     : Word;
BEGIN
     CASE HoldRaw.Number OF
     14..17:
          BEGIN
               {FIRST DELETE THE OLD ONE}
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               REWRITE(FTempRaw);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF ((Counter<StartPoly) OR (Counter>EndPoly)) THEN
                     BEGIN
                          WRITE(FNewRawFile,HoldRaw);
                     END
                     ELSE WRITE(FTempRaw,HoldRaw);
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FOldRawFile);
               {PLACE THE OBJECT AT THE END}
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               RESET(FNewRawFile);
               RESET(FTempRaw);
               SEEK(FNewRawFile,FileSize(FNewRawFile));
               REPEAT
                     READ(FTempRaw,HoldRaw);
                     WRITE(FNewRawFile,HoldRaw);
               UNTIL EOF(FTempRaw);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FTempRaw);
          END;
     ELSE BEGIN
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               REWRITE(FTempRaw);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF (Counter<>Num)
                        THEN WRITE(FNewRawFile,HoldRaw)
                        ELSE WRITE(FTempRaw,HoldRaw);
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FOldRawFile);
               {PLACE THE OBJECT AT THE END}
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               RESET(FNewRawFile);
               RESET(FTempRaw);
               SEEK(FNewRawFile,FileSize(FNewRawFile));
               REPEAT
                     READ(FTempRaw,HoldRaw);
                     WRITE(FNewRawFile,HoldRaw);
               UNTIL EOF(FTempRaw);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FTempRaw);
          END;
     END;
END;


PROCEDURE MoveToBottom(Num: Word); {DRAW THE OBJECT FIRST}
VAR  FOldRawFile : File Of _Raw_File;
     FNewRawFile : File Of _Raw_File;
     FTempRaw    : File Of _Raw_File;
     Counter     : Word;
BEGIN
     CASE HoldRaw.Number OF
     14..17:
          BEGIN
               {FIRST DELETE THE OLD ONE}
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               REWRITE(FTempRaw);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF ((Counter<StartPoly) OR (Counter>EndPoly)) THEN
                     BEGIN
                          WRITE(FNewRawFile,HoldRaw);
                     END
                     ELSE WRITE(FTempRaw,HoldRaw);
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FOldRawFile);
               {PLACE THE OBJECT AT THE START}
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               RESET(FOldRawFile);
               RESET(FTempRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               REPEAT
                     READ(FTempRaw,HoldRaw);
                     WRITE(FNewRawFile,HoldRaw);
               UNTIL EOF(FTempRaw);
               REPEAT
                     IF NOT(EOF(FOldRawFile)) THEN
                     BEGIN
                          READ(FOldRawFile,HoldRaw);
                          WRITE(FNewRawFile,HoldRaw);
                     END;
               UNTIL EOF(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FTempRaw);
               ERASE(FTempRaw);
               ERASE(FOldRawFile);
          END;
     ELSE BEGIN
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               REWRITE(FTempRaw);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF (Counter<>Num)
                        THEN WRITE(FNewRawFile,HoldRaw)
                        ELSE WRITE(FTempRaw,HoldRaw);
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FTempRaw);
               ERASE(FOldRawFile);
               {PLACE THE OBJECT AT THE START}
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               ASSIGN(FTempRaw,WorkDir+'TEMPWORK.TMP');
               REWRITE(FNewRawFile);
               RESET(FOldRawFile);
               RESET(FTempRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               READ(FOldRawFile,HoldRaw); WRITE(FNewRawFile,HoldRaw);
               REPEAT
                     READ(FTempRaw,HoldRaw);
                     WRITE(FNewRawFile,HoldRaw);
               UNTIL EOF(FTempRaw);
               REPEAT
                     IF NOT(EOF(FOldRawFile)) THEN
                     BEGIN
                          READ(FOldRawFile,HoldRaw);
                          WRITE(FNewRawFile,HoldRaw);
                     END;
               UNTIL EOF(FOldRawFile);
               CLOSE(FNewRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FTempRaw);
               ERASE(FTempRaw);
               ERASE(FOldRawFile);
          END;
     END;
END;


PROCEDURE DeleteObject(Num: Word);
VAR  FOldRawFile : File Of _Raw_File;
     FNewRawFile : File Of _Raw_File;
     Counter     : Word;
BEGIN
     CASE HoldRaw.Number OF
     14..17:
          BEGIN
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               REWRITE(FNewRawFile);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF ((Counter<StartPoly) OR (Counter>EndPoly)) THEN
                     BEGIN
                          WRITE(FNewRawFile,HoldRaw);
                     END;
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               ERASE(FOldRawFile);
          END;
     ELSE BEGIN
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.$$$');
               RENAME(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FOldRawFile,WorkDir+'TEMPWORK.OLD');
               ASSIGN(FNewRawFile,WorkDir+'TEMPWORK.$$$');
               REWRITE(FNewRawFile);
               RESET(FOldRawFile);
               Counter := 0;
               REPEAT
                     READ(FOldRawFile,HoldRaw);
                     INC(Counter);
                     IF Counter<>Num THEN
                     BEGIN
                          WRITE(FNewRawFile,HoldRaw);
                     END;
               UNTIL EOF(FOldRawFile);
               CLOSE(FOldRawFile);
               CLOSE(FNewRawFile);
               ERASE(FOldRawFile);
          END;
     END;
END;


PROCEDURE UpdatePoly;
VAR  OldNumber  : Word;
     OldColour1 : Word;
     OldColour2 : Word;
BEGIN
     OldNumber  := HoldRaw.number;
     OldColour1 := HoldRaw.colour1;
     OldColour2 := HoldRaw.colour2;
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,StartPoly-1);
     REPEAT
           READ(FWorkSg,HoldRaw);
           SEEK(FWorkSg,FilePos(FWorkSg)-1);
           HoldRaw.Colour1 := OldColour1;
           HoldRaw.Colour2 := OldColour2;
           WRITE(FWorkSg,HoldRaw);
     UNTIL (HoldRaw.Style=255);
     CLOSE(FWorkSg);
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,ObjectNumber-1);
     READ(FWorkSg,HoldRaw);
     CLOSE(FWorkSg);
END;


PROCEDURE WriteFile;
BEGIN
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,FileSize(FWorkSg));
     WRITE(FWorkSg,HoldRaw);
     CLOSE(FWorkSg);
END;


PROCEDURE WriteToFile(Index: Word);
BEGIN
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,Index-1);
     WRITE(FWorkSG,HoldRaw);
     CLOSE(FWorkSg);
END;


END.
