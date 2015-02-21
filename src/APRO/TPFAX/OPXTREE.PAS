{$R-,S-,I-,V-,B-,F+,O+,A-}

{An extension to the PathList in OPDIR from Object Professional.
 Sorts the directory alphabetically at each level.

 Written 2/2/91, Kim Kokkonen, TurboPower Software.
}

unit OpXTree;
  {-PathList object sorted XTree style}

interface

uses
  OpInline, OpString, OpCrt, OpPick, OpDir;

type
  XTreePathListPtr = ^XTreePathList;
  XTreePathList =
    object(PathList)
      procedure paFindAllPaths; virtual;
      procedure xtSort(L, R : Word; Level : Byte);
    end;

  {====================================================================}

implementation

var
  Min : Word;
  S : Word;
  D : Word;
  C : Word;
  F : Word;
  Rec1 : PathRec;
  Rec2 : PathRec;
  Fini : Boolean;

  procedure XTreePathList.xtSort(L, R : Word; Level : Byte);
  var
    B, E : Word;

    function Dest(S : Word) : Word;
    begin
      if S >= Min then
        Dest := S+B-Min
      else
        Dest := S+E-Min+1;
    end;

  begin
    {sort nested levels}
    B := L;
    while B <= R do begin
      if paDPtr^[B].PLevel > Level then begin
        E := B+1;
        while (E <= R) and (paDPtr^[E].PLevel > Level) do
          inc(E);
        xtSort(B, E-1, Level+1);
        B := E;
      end else
        inc(B);
    end;

    {sort this level}
    B := L;
    while B <= R do begin
      {find start of minimum sequence}
      Rec1.PName := #255;
      Min := 0;
      for S := B to R do
        if paDPtr^[S].PLevel = Level then
          if paDPtr^[S].PName < Rec1.PName then begin
            Rec1 := paDPtr^[S];
            Min := S;
          end;

      {find end of minimum sequence}
      E := Min+1;
      while (E <= R) and (paDPtr^[E].PLevel > Level) do
        inc(E);
      dec(E);

      if Min > B then begin
        {move minimum sequence down}
        C := 1;
        F := E;
        Fini := False;
        repeat
          S := F;
          D := Dest(S);
          Rec2 := paDPtr^[S];
          repeat
            if C > E-B then
              Fini := True;
            inc(C);
            Rec1 := PaDPtr^[D];
            PaDPtr^[D] := Rec2;
            S := D;
            D := Dest(S);
            Rec2 := Rec1;
          until Fini or (S = F);
          dec(F);
        until Fini;
      end;

      {continue just beyond the minimum sequence}
      inc(B, E-Min+1);
    end;
  end;

  procedure XTreePathList.paFindAllPaths;
  begin
    PathList.paFindAllPaths;
    if paCurFiles > 1 then
      xtSort(2, paCurFiles, 1);
  end;

end.
