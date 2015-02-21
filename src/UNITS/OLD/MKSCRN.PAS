Unit MKScrn;
{$I MKB.Def}

Interface

Type ScrnItemType = Record
  Ch: Char;
  Attr: Byte;
  End;


Type ScreenType = Record
  Case Boolean Of
    True:  (ScrnWord: Array[0..10000] of Word);
    False: (ScrnItem: Array[0..10000] of ScrnItemType);
  End;


Var
  AdapterType: Byte;    {0=none 1=mono 2=CGA 4=EGA-C 5=EGA-M}
                        {7=VGA-M 8=VGA-C 10=MCGA-C 11=MCGA-M}
  ScrnWidth: Byte;
  ScrnHeight: Byte;
  ScrnPtr: ^ScreenType;
  FontHeight: Byte;


Function  SaveScrnRegion(xl,yl,xh,yh: Byte; Var Pt: Pointer):Boolean;
Procedure RestoreScrnRegion(xl,yl,xh,yh: Byte; Var Pt: Pointer);
Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
Function  GetScrnWord(SX: Byte; SY: Byte): Word;
Procedure SetCursorPosition(Sx: Byte; Sy: Byte);
Procedure GetCursorPosition(Var Sx: Byte; Var Sy: Byte);
Procedure DelCharInLine(Sx: Byte; Sy: Byte);
Procedure InsCharInLine(Sx: Byte; Sy: Byte; Ch: Char);
Procedure InitializeScrnRegion(xl,yl,xh,yh: Byte; Ch: Char);


Implementation


Uses MKString,
  {$IFDEF WINDOWS}
  WinDos, MKWCrt;
  {$ELSE}
     Dos,
    {$IFDEF OPRO}
    OPCrt;
    {$ELSE}
    Crt;
    {$ENDIF}
  {$ENDIF}

Type WordArray = Array[0..9999] of Word;

Type WordArrayPtr = ^WordArray;


Var Regs: Registers;


Function SaveScrnRegion(xl,yl,xh,yh: Byte; Var Pt: Pointer):Boolean;
  Var
    Tx: Byte;
    Ty: Byte;
    Ctr: Word;

  Begin
  GetMem(Pt, ((xh + 1 - xl) * (yh +1 - yl) * 2));
  If Pt = nil Then
    SaveScrnRegion := False
  Else
    Begin
    SaveScrnRegion := True;
    Ctr := 0;
    For Tx := xl to xh Do
      Begin
      For Ty := yl to yh Do
        Begin
        WordArrayPtr(PT)^[Ctr] := GetScrnWord(Tx, Ty);
        Inc(Ctr);
        End;
      End;
    End;
  End;


Procedure RestoreScrnRegion(xl,yl,xh,yh: Byte; Var Pt: Pointer);
  Var
    Tx: Byte;
    Ty: Byte;
    Ctr: Word;

  Begin
  If Pt <> nil Then
    Begin
    Ctr := 0;
    For Tx := xl to xh Do
      Begin
      For Ty := yl to yh Do
        Begin
        PutScrnWord(Tx, Ty, WordArrayPtr(PT)^[Ctr]);
        Inc(Ctr);
        End;
      End;
    FreeMem(Pt, ((xh + 1 - xl) * (yh +1 - yl) * 2));
    End;
  End;


Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
  Begin
  xl := xl + (WindMin and $ff);
  yl := yl + (WindMin shr 8);
  xh := xh + (WindMin and $ff);
  yh := yh + (WindMin shr 8);
  If yh > ((WindMax shr 8) + 1) Then
    yh := ((WindMax shr 8) + 1);
  If xh > ((WindMax and $ff) + 1) Then
    xh := ((WindMax and $ff) + 1);
  Regs.ah := 6;
  Regs.al := count;
  Regs.ch := yl - 1;
  Regs.cl := xl - 1;
  Regs.dh := yh - 1;
  Regs.dl := xh - 1;
  Regs.bh := TextAttr;
  Intr($10, Regs);
  End;


Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
  Begin
  Regs.ah := 7;
  xl := xl + (WindMin and $ff);
  yl := yl + (WindMin shr 8);
  xh := xh + (WindMin and $ff);
  yh := yh + (WindMin shr 8);
  If yh > ((WindMax shr 8) + 1) Then
    yh := ((WindMax shr 8) + 1);
  If xh > ((WindMax and $ff) + 1) Then
    xh := ((WindMax and $ff) + 1);
  Regs.al := count;
  Regs.ch := yl - 1;
  Regs.cl := xl - 1;
  Regs.dh := yh - 1;
  Regs.dl := xh - 1;
  Regs.bh := TextAttr;
  Intr($10, Regs);
  End;


Procedure SetCursorPosition(Sx: Byte; Sy: Byte);
  Begin
  Regs.ah := 2;
  Regs.dh := sy - 1;
  Regs.dl := sx - 1;
  Regs.bh := 0;
  Intr($10, Regs);
  End;


Procedure GetCursorPosition(Var Sx: Byte; Var Sy: Byte);
  Begin
  Regs.ah := 3;
  Regs.bh := 0;
  Intr($10, Regs);
  Sx := Regs.dl + 1;
  Sy := Regs.dh + 1;
  End;


Function GetScrnWord(SX: Byte; SY: Byte): Word;
  Var
    Cx: Byte;
    Cy: Byte;

  Begin
  If (DirectVideo  And (Not CheckSnow)) Then
    GetScrnWord := ScrnPtr^.ScrnWord[((SY - 1) * ScrnWidth) + (SX - 1)]
  Else
    Begin
    GetCursorPosition(Cx,Cy);
    SetCursorPosition(Sx,Sy);
    Regs.Ah := 8;
    Regs.Bh := 0;
    Intr($10, Regs);
    GetScrnWord := Regs.Ax;
    SetCursorPosition(Cx,Cy);
    End;
  End;


Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
  Var
    Cx: Byte;
    Cy: Byte;

  Begin
  If (DirectVideo And (Not CheckSnow)) Then
    ScrnPtr^.ScrnWord[((SY - 1) * ScrnWidth) + (SX - 1)] := CA
  Else
    Begin
    GetCursorPosition(Cx, Cy);
    SetCursorPosition(Sx, Sy);
    Regs.Ah := 9;
    Regs.Bh := 0;
    Regs.Al := Lo(Ca);
    Regs.Bl := Hi(Ca);
    Regs.Cx := 1;
    Intr($10, Regs);
    SetCursorPosition(Cx, Cy);
    End;
  End;

Procedure SetScreenParams;
  Var
    Regs: Registers;

  Begin
  Regs.Ah := $1a;
  Regs.AL := $00;
  Intr($10, Regs);
  If Regs.AL = $1a Then
    Begin
    AdapterType := Regs.Bl;
    If AdapterType = 12 Then
      AdapterType := 10;
    If AdapterType > 11 Then
      AdapterType := 2;
    End
  Else
    Begin
    Regs.Ah := $12;
    Regs.Bx := $10;
    Intr($10, Regs);
    If Regs.BX <> $10 Then
      Begin
      Regs.Ah := $12;
      Regs.BL := $10;
      Intr($10, Regs);
      If (Regs.Bh = 0) Then
        AdapterType := 4
      Else
        AdapterType := 5
      End
    Else
      Begin
      Intr($11, Regs);
      If (((Regs.Al and $30) shr 4) = 3) Then
         AdapterType := 1
      Else
        AdapterType := 2;
      End
    End;
  Case AdapterType of
    0: Begin
       ScrnHeight := 25;
       FontHeight := 8;
       End;
    1: Begin
       ScrnHeight := 25;
       FontHeight := 14;
       End;
    2: Begin
       ScrnHeight := 25;
       FontHeight := 8;
       End;
    10..11: Begin
       ScrnHeight := 25;
       FontHeight := 16;
       End;
    Else
       Begin
       Regs.Ah := $11;
       Regs.Al := $30;
       Regs.Bl := $00;
       Intr($10, Regs);
       FontHeight := Regs.Cx;
       Case AdapterType of
         4..5: ScrnHeight := 350 Div FontHeight;
         7..8: ScrnHeight := 400 Div FontHeight;
         Else
           ScrnHeight := 25;
         End;
       End;
    End;
  If ScrnHeight = 44 Then
    ScrnHeight := 43;
  Regs.Ah := $0f;
  Intr($10, Regs);
  ScrnWidth := Regs.Ah;
  Case AdapterType of
    1,5,7,11: ScrnPtr := Ptr($B000, 0);
    Else
      ScrnPtr := Ptr($B800, 0);
    End;
  ScrnHeight := Mem[$0040:$0084] + 1;
  If ScrnHeight < 8 Then
    ScrnHeight := 25;
  If ScrnWidth < 40 Then
    ScrnWidth := 80;
  If ScrnWidth > 132 Then
    ScrnWidth := 80;
  If ScrnHeight > 66 Then
    ScrnHeight := 25;
  End;


Procedure DelCharInLine(Sx: Byte; Sy: Byte);
  Var
    Ex: Byte;
    Cx: Byte;

  Begin
  Ex := Lo(WindMax) + 1;
  Cx := Sx;
  While (Cx < Ex) Do
    Begin
    PutScrnWord(Cx, Sy, GetScrnWord(Cx + 1, Sy));
    Inc(Cx);
    End;
  PutScrnWord(Ex, Sy, 32 + (TextAttr shl 8));
  End;


Procedure InsCharInLine(Sx: Byte; Sy: Byte; Ch: Char);
  Var
    Ex: Byte;
    Cx: Byte;

  Begin
  Ex := Lo(WindMax) + 1;
  Cx := Ex;
  While (Cx > Sx) Do
    Begin
    PutScrnWord(Cx, Sy, GetScrnWord(Cx - 1, Sy));
    Dec(Cx);
    End;
  PutScrnWord(Sx, Sy, Ord(Ch) + (TextAttr shl 8));
  End;


Procedure InitializeScrnRegion(xl,yl,xh,yh: Byte; Ch: Char);
  Var
    Cx, Cy: Byte;

  Begin
  xl := xl + (WindMin and $ff);
  yl := yl + (WindMin shr 8);
  xh := xh + (WindMin and $ff);
  yh := yh + (WindMin shr 8);
  If yh > ((WindMax shr 8) + 1) Then
    yh := ((WindMax shr 8) + 1);
  If xh > ((WindMax and $ff) + 1) Then
    xh := ((WindMax and $ff) + 1);
  Cx := xl;
  Cy := yl;
  While (cy <= yh) Do
    Begin
    While (Cx <= xh) Do
      Begin
      PutScrnWord(Cx, Cy, Ord(ch) + (TextAttr shl 8));
      Inc(Cx);
      End;
    Inc(Cy);
    End;
  End;


Begin
SetScreenParams;
End.
