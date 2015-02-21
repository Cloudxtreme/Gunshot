{$I DEFINES.INC}
UNIT _Bezier;


INTERFACE


PROCEDURE GrDrawBezier       (x1,y1,x2,y2,x3,y3,x4,y4: Integer);
PROCEDURE AddToBezier        (x1,y1,x2,y2,x3,y3,x4,y4: Integer);


IMPLEMENTATION


USES Gr2_Bp,Globals;


{==========================================================================}
{                                                                          }
{         DRAWS A BEZIER CURVE - THE FIRST TWO AND LAST TWO ARGUMENTS      }
{                                ARE FOR THE END POINTS. THE OTHER 4       }
{                                ARE FOR THE ANCHOR POINTS.                }
{                                                                          }
{==========================================================================}
FUNCTION CalcX(T: Real): Real;
BEGIN
     CalcX := ((Ax*T*T*T)+(Bx*T*T)+(Cx*T)+Dx)/6;
END;


FUNCTION CalcY(T: Real): Real;
BEGIN
     CalcY := ((Ay*T*T*T)+(By*T*T)+(Cy*T)+Dy)/6;
END;


PROCEDURE ComputeCoeffs(N: Integer);
BEGIN
     Ax := -CtrlPt[N-1].X+3*CtrlPt[N].X-3*CtrlPt[N+1].X+CtrlPt[N+2].X;
     Bx := 3*CtrlPt[N-1].X-6*CtrlPt[N].X+3*CtrlPt[N+1].X;
     Cx := -3*CtrlPt[N-1].X+3*CtrlPt[N+1].X;
     Dx := CtrlPt[N-1].X+4*CtrlPt[N].X+CtrlPt[N+1].X;
     Ay := -CtrlPt[N-1].Y+3*CtrlPt[N].Y-3*CtrlPt[N+1].Y+CtrlPt[N+2].Y;
     By := 3*CtrlPt[N-1].Y-6*CtrlPt[N].Y+3*CtrlPt[N+1].Y;
     Cy := -3*CtrlPt[N-1].Y+3*CtrlPt[N+1].Y;
     Dy := CtrlPt[N-1].Y+4*CtrlPt[N].Y+CtrlPt[N+1].Y;
END;


PROCEDURE GrDrawBezier(x1,y1,x2,y2,x3,y3,x4,y4: Integer);
CONST Res = 10;
VAR  I,J        : Integer;
     X,Y,Lx,Ly  : Real;
     PolyPoints : Array[0..400] Of Integer;
     Counter    : Word;
BEGIN
     CtrlPt[1].X  := x1;
     CtrlPt[1].Y  := y1;
     CtrlPt[2].X  := x2;
     CtrlPt[2].Y  := y2;
     CtrlPt[3].X  := x3;
     CtrlPt[3].Y  := y3;
     CtrlPt[4].X  := x4;
     CtrlPt[4].Y  := y4;
     CtrlPt[-1]   := CtrlPt[1];
     CtrlPt[0]    := CtrlPt[1];
     CtrlPt[5]    := CtrlPt[4];
     CtrlPt[6]    := CtrlPt[4];
     Counter := 0;
     For I := 0 To 4 Do
     Begin
          ComputeCoeffs(I);
          Lx := CalcX(0);
          Ly := CalcY(0);
          For J := 1 To Res Do
          Begin
               X := CalcX(J/Res);
               Y := CalcY(J/Res);
               PolyPoints[Counter] := Round(Lx); INC(Counter);
               PolyPoints[Counter] := Round(Ly); INC(Counter);
               IF ((Round(Lx)<>Round(X)) OR (Round(Ly)<>Round(Y))) THEN
               BEGIN
                    PolyPoints[Counter] := Round(X); INC(Counter);
                    PolyPoints[Counter] := Round(Y); INC(Counter);
               END;
               Lx := X; Ly := Y;
          End;
     End;
     GrDrawPoly(@PolyPoints,Trunc((Counter+1)/2),GrOutline);
END;
{==========================================================================}
{                                                                          }
{         ADDS TO A BEZIER CURVE - THE FIRST TWO AND LAST TWO ARGUMENTS    }
{                                  ARE FOR THE END POINTS. THE OTHER 4     }
{                                  ARE FOR THE ANCHOR POINTS.              }
{                                                                          }
{==========================================================================}
PROCEDURE AddToBezier(x1,y1,x2,y2,x3,y3,x4,y4: Integer);
CONST Res = 10;
VAR  I,J        : Integer;
     X,Y,Lx,Ly  : Real;
BEGIN
     CtrlPt[1].X  := x1;
     CtrlPt[1].Y  := y1;
     CtrlPt[2].X  := x2;
     CtrlPt[2].Y  := y2;
     CtrlPt[3].X  := x3;
     CtrlPt[3].Y  := y3;
     CtrlPt[4].X  := x4;
     CtrlPt[4].Y  := y4;
     CtrlPt[-1]   := CtrlPt[1];
     CtrlPt[0]    := CtrlPt[1];
     CtrlPt[5]    := CtrlPt[4];
     CtrlPt[6]    := CtrlPt[4];
     For I := 0 To 4 Do
     Begin
          ComputeCoeffs(I);
          Lx := CalcX(0);
          Ly := CalcY(0);
          For J := 1 To Res Do
          Begin
               X := CalcX(J/Res);
               Y := CalcY(J/Res);
               PolyPoint^[WorkWord] := Round(Lx); INC(WorkWord);
               PolyPoint^[WorkWord] := Round(Ly); INC(WorkWord);
               IF ((Round(Lx)<>Round(X)) OR (Round(Ly)<>Round(Y))) THEN
               BEGIN
                    PolyPoint^[WorkWord] := Round(X); INC(WorkWord);
                    PolyPoint^[WorkWord] := Round(Y); INC(WorkWord);
               END;
               Lx := X; Ly := Y;
          End;
     End;
END;


END.
