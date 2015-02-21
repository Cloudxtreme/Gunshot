Unit MKWCrt;
{$R Keys.Res}

Interface

{
     MKWCRT - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Uses WinProcs, WinTypes, WinDos;

Const
  Black = 0;
  Blue = 1;
  Green = 2;
  Cyan = 3;
  Red = 4;
  Magenta = 5;
  Brown = 6;
  LightGray = 7;
  DarkGray = 8;
  LightBlue = 9;
  LightGreen = 10;
  LightCyan = 11;
  LightRed = 12;
  LightMagenta = 13;
  Yellow = 14;
  White = 15;
  Blink = 128;


Const
  TextAttr: Byte = $07;
  TextChar: Char = ' ';
  CheckBreak: Boolean = True;
  CheckEOF: Boolean = False;
  CheckSnow: Boolean = False;
  DirectVideo: Boolean = False;
  LastMode: Word = 3;
  WindMin: Word = $0;
  WindMax: Word = $184f;
  ScreenWidth = 80;
  ScreenHeight = 25;
  KeyBufferSize = 20;

Const
  AppName = 'AppName Here';

Procedure AssignWinCrt(Var F: Text);
Procedure Delay(DTime: LongInt);
Procedure TextColor(CL: Byte);
Procedure TextBackground(CL: Byte);
Procedure PutStr(Str: String);
Procedure PutChar(Ch: Char);
Procedure GoToXy(X: Byte; Y: Byte);
Function  WhereX: Byte;
Function  WhereY: Byte;
Procedure Window(X1, Y1, X2, Y2: Byte);
Procedure ClrScr;
Procedure ClrEol;
Function  KeyPressed: Boolean;
Function  ReadKey: Char;
Function  SaveScrnRegion(xl,yl,xh,yh: Byte; Var Pt: Pointer):Boolean;
Procedure RestoreScrnRegion(xl,yl,xh,yh: Byte; Pt: Pointer);
Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
Function  GetScrnWord(SX: Byte; SY: Byte): Word;
Procedure DelCharInLine(Sx: Byte; Sy: Byte);
Procedure InsCharInLine(Sx: Byte; Sy: Byte; Ch: Char);
Procedure InitializeScrnRegion(xl,yl,xh,yh: Byte; Ch: Char);
Function  WindowProc(HWindow: HWnd; Message, WParam: Word;
  LParam: Longint): Longint; export;
Procedure RedrawScrn;


Type ScrnArrayType = Array[0..(ScreenWidth * ScreenHeight)] of Word;

Type WordArray = Array[0..9999] of Word;

Type WordArrayPtr = ^WordArray;


Var
  HWindow: HWnd;
  Accels: THandle;
  Message: TMsg;
  TVert: Word;
  THorz: Word;
  ScrnArray: ^ScrnArrayType;
  KeyBuffer: Array[1..KeyBufferSize] of Char;
  KeyPut: Byte;
  KeySend: Byte;
  ScrnWidth: Byte;
  ScrnHeight: Byte;



Const
  WindowClass: TWndClass = (
    style: 0;
    lpfnWndProc: @WindowProc;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hInstance: 0;
    hIcon: 0;
    hCursor: 0;
    hbrBackground: 0;
    lpszMenuName: AppName;
    lpszClassName: AppName);


Const
  CurrX: Byte = 1;
  CurrY: Byte = 1;

Implementation


Const ColorArray: Array[0..15] of LongInt = (0, 1141120, 43520, 11184640,
  170, 11141290, 43690, 11184810, 5592405, 16733525, 5635925,
  16777045, 5592575, 16733695, 5636095, 16777215);

Procedure Delay(DTime: LongInt);
  Const
    TimerId = 1989;
  Var
    DDone: Boolean;

  Begin
  DDone := False;
  If SetTimer(HWindow,TimerId, DTime, nil) <> 0 Then
    Begin
    While Not DDone Do
      Begin
      WaitMessage;
      If PeekMessage(Message, HWindow, 0, 0, pm_Remove) Then
        Begin
        If Message.Message = wm_Timer Then
          DDone := True
        Else
          If (TranslateAccelerator(HWindow, Accels, Message) = 0) Then
            Begin
            TranslateMessage(Message);
            DispatchMessage(Message);
            End;
        End;
      End;
    KillTimer(HWindow, TimerId);
    End;
  End;

Procedure TextColor(CL: Byte);
  Begin
  TextAttr := TextAttr and $F0;
  TextAttr := TextAttr or (CL and $0F);
  End;


Procedure TextBackground(CL: Byte);
  Begin
  TextAttr := TextAttr and $0F;
  TextAttr := TextAttr or (CL shl 4);
  End;


Procedure GoToXy(X: Byte; Y: Byte);
  Begin
  CurrX := X + (WindMin and $ff);
  CurrY := Y + (WindMin shr 8);
  If (CurrX > ((WindMax and $ff) + 1)) Then
    CurrX := (WindMax and $ff) + 1;
  If (CurrY > ((WindMax shr 8) + 1)) Then
    CurrY := (WindMax shr 8) + 1;
  End;


Procedure Window(X1, Y1, X2, Y2: Byte);
  Begin
  WindMin := (Y1 - 1);
  WindMin := (WindMin Shl 8) + (X1 - 1);
  WindMax := (Y2 - 1);
  WindMax := (WindMax Shl 8) + (X2 - 1);
  End;


Procedure ClrScr;
  Var
    CX, CY: Byte;
    TmpStr: String;
    NumRows, NumCols: Byte;
    DC: HDC;
    Metrics: TTextMetric;

  Begin
  DC := GetDC(HWindow);
  SetTextColor(DC,ColorArray[TextAttr and $0f]);
  SetBkColor(DC, ColorArray[TextAttr shr 4]);
  SelectObject(DC, GetStockObject(OEM_Fixed_Font));
  TmpStr := '';
  Cx := (WindMin and $ff);
  While (Cx <= (WindMax and $ff)) Do
    Begin
    TmpStr := TmpStr + TextChar;
    Inc(Cx);
    End;
  Cy := (WindMin shr 8) + 1;
  While (Cy <= ((WindMax shr 8) + 1)) Do
    Begin
    Cx := WindMin and $ff;
    While Cx <= (WindMax and $ff) Do
      Begin
      ScrnArray^[(Cy - 1) * ScreenWidth + (Cx)] := Ord(TextChar) + (TextAttr shl 8);
      Inc(Cx);
      End;
    TextOut(DC, (WindMin and $ff) * THorz, (CY - 1) * TVert, PChar(@TmpStr[1]),
      Length(TmpStr));
    Inc(Cy);
    End;
  TextChar := ' ';
  ReleaseDC(HWindow,DC);
  GoToXY(1, 1);
  End;


Procedure ClrEol;
  Var
    CX: Byte;
    TmpStr: String;
    DC: HDC;
    Metrics: TTextMetric;

  Begin
  DC := GetDC(HWindow);
  SetTextColor(DC,ColorArray[TextAttr and $0f]);
  SetBkColor(DC, ColorArray[TextAttr shr 4]);
  SelectObject(DC, GetStockObject(OEM_Fixed_Font));
  CX := CurrX;
  TmpStr := '';
  While (CX <= ((WindMax and $ff)+ 1)) Do
    Begin
    TmpStr := TmpStr + TextChar;
    Inc(Cx);
    End;
  TextOut(DC, (CurrX - 1) * THorz, (CurrY - 1) * TVert, PChar(@TmpStr[1]),
    Length(TmpStr));
  ReleaseDC(HWindow,DC);
  End;


Function WhereX: Byte;
  Begin
  WhereX := CurrX - (WindMin and $ff);
  End;


Function WhereY: Byte;
  Begin
  WhereY := CurrY - (WindMin shr 8);
  End;


Function GetKeyChar: Char;
  Begin
  If KeyPut <> KeySend Then
    Begin
    GetKeyChar := KeyBuffer[KeySend];
    Inc(KeySend);
    If KeySend > KeyBufferSize Then
      KeySend := 1;
    End
  Else
    GetKeyChar := #0;
  End;


Procedure PutKeyChar(Ch: Char);
  Var
    Tmp: Byte;

  Begin
  Tmp := KeyPut;
  Inc(KeyPut);
  If KeyPut > KeyBufferSize Then
    KeyPut := 1;
  If KeyPut <> KeySend Then
    KeyBuffer[Tmp] := Ch
  Else
    KeyPut := Tmp;
  End;


Procedure CharMsg(Message: TMsg);
  Var
    Tmp: Byte;

  Begin
  PutKeyChar(Char(Message.wParam));
  End;


Function WindowProc(HWindow: HWnd; Message, WParam: Word;
  LParam: Longint): Longint;
  Var
    PassOn: Boolean;

  Begin
  PassOn := True;
  WindowProc := 0;
  case Message of
    wm_Char:
      Begin
      If (LParam and 256) <> 0 Then
        Begin
        PutKeyChar(#0);
        PutKeyChar(Chr(LParam and 127));
        End
      Else
        PutKeyChar(Chr(WParam));
      PassOn := False;
      End;
    wm_Command:
      Begin
      PutKeyChar(#0);
      PutKeyChar(Chr(Lo(WParam)));
      PassOn := False;
      End;
    wm_Destroy:
      Begin
      PostQuitMessage(0);
      Exit;
      End;
    wm_Paint: RedrawScrn;
    End;
  If PassOn Then
    WindowProc := DefWindowProc(HWindow, Message, WParam, LParam)
  Else
    WindowProc := 1;
  End;


Procedure PutChar(Ch: Char);
  Var
    DC: HDC;

  Begin
  Case Ch of
    #07: ;
    #08: If CurrX > ((WindMin and $ff) + 1) Then
          Dec(CurrX);
    #10: Begin
         Inc(CurrY);
         If CurrY > ((WindMax shr 8) + 1) Then
           Begin
           CurrY := ((WindMax shr 8) + 1);
           ScrollScrnRegionUp(1, 1, ScreenWidth, ScreenHeight,1);
           End;
         End;
    #13: CurrX := 1;
    Else
      Begin
      DC := GetDC(HWindow);
      SetTextColor(DC,ColorArray[TextAttr and $0f]);
      SetBkColor(DC, ColorArray[TextAttr shr 4]);
      SelectObject(DC, GetStockObject(OEM_Fixed_Font));
      ScrnArray^[(CurrX - 1) + (CurrY - 1) * ScreenWidth] := Ord(ch) + (TextAttr shl 8);
      TextOut(DC, (CurrX - 1) * THorz, (CurrY - 1) * TVert, PChar(@Ch), 1);
      ReleaseDC(HWindow,DC);
      Inc(CurrX);
      If CurrX > ((WindMax and $FF) + 1) Then
        Begin
        CurrX := (WindMin and $FF) + 1;
        Inc(CurrY);
         If CurrY >= ((WindMax shr 8) + 1) Then
           Begin
           CurrY := (WindMax shr 8) + 1;
           ScrollScrnRegionUp(1, 1, ScreenWidth, ScreenHeight, 1);
           End;
        End;
      End;
    End;
  End;


Procedure PutStr(Str: String);
  Var
    i: Word;

  Begin
  i := 1;
  While i <= Length(Str) Do
    Begin
    PutChar(Str[i]);
    Inc(i);
    End;
  End;


Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
  Var
    Ty: Byte;
    Tx: Byte;
    Wdth: Byte;
    DC: HDC;
    Rect: TRect;
    TempStr: String;


  Begin
  xl := xl + (WindMin and $ff);
  yl := yl + (WindMin shr 8);
  xh := xh + (WindMin and $ff);
  yh := yh + (WindMin shr 8);
  If yh > ((WindMax shr 8) + 1) Then
    yh := ((WindMax shr 8) + 1);
  If xh > ((WindMax and $ff) + 1) Then
    xh := ((WindMax and $ff) + 1);
  Wdth := Xh + 1 - Xl;
  If Wdth > 0 Then
    Begin
    Ty := yl;
    While Ty < yh Do
      Begin
      Move(ScrnArray^[(Ty * ScreenWidth) + XL - 1],
        ScrnArray^[((Ty - 1) * ScreenWidth) + XL - 1], Wdth);
      Inc(Ty);
      End;
    For Tx := xl to xh Do
      ScrnArray^[(Tx - 1) + (yh - 1) * ScreenWidth] :=  32 + (TextAttr shl 8);
    Rect.Left := (xl - 1) * THorz;
    Rect.Right := (xh) * THorz;
    Rect.Top := (yl - 1) * TVert;
    Rect.Bottom := (yh) * TVert;
    ScrollWindow(HWindow, 0,  -TVert * Count, @Rect, @Rect);
    DC := GetDC(HWindow);
    SetTextColor(DC,ColorArray[TextAttr and $0f]);
    SetBkColor(DC, ColorArray[TextAttr shr 4]);
    SelectObject(DC, GetStockObject(OEM_Fixed_Font));
    TempStr := '';
    For tx := xl to xh Do
      TempStr := TempStr + ' ';
    TextOut(DC, (Xl - 1) * THorz, (Yh - 1) * TVert, PChar(@TempStr[1]),
      Length(TempStr));
    ReleaseDC(HWindow,DC);
    End;
  End;


Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
  Var
    Ty: Byte;
    Tx: Byte;
    Wdth: Byte;
    DC: HDC;
    Rect: TRect;
    TempStr: String;

  Begin
  xl := xl + (WindMin and $ff);
  yl := yl + (WindMin shr 8);
  xh := xh + (WindMin and $ff);
  yh := yh + (WindMin shr 8);
  If yh > ((WindMax shr 8) + 1) Then
    yh := ((WindMax shr 8) + 1);
  If xh > ((WindMax and $ff) + 1) Then
    xh := ((WindMax and $ff) + 1);
  Wdth := Xh + 1 - Xl;
  If Wdth > 0 Then
    Begin
    Ty := yh;
    While Ty > yl Do
      Begin
      Move(ScrnArray^[((Ty - 2) * ScreenWidth) + XL - 1],
        ScrnArray^[((Ty - 1) * ScreenWidth) + XL - 1], Wdth);
      Dec(Ty);
      End;
    For Tx := xl to xh Do
      ScrnArray^[(Tx - 1) + (yl - 1) * ScreenWidth] :=  32 + (TextAttr shl 8);
    Rect.Left := (xl - 1) * THorz;
    Rect.Right := (xh) * THorz;
    Rect.Top := (yl - 1) * TVert;
    Rect.Bottom := (yh) * TVert;
    ScrollWindow(HWindow, 0, Count * TVert, @Rect, @Rect);
    DC := GetDC(HWindow);
    SetTextColor(DC,ColorArray[TextAttr and $0f]);
    SetBkColor(DC, ColorArray[TextAttr shr 4]);
    SelectObject(DC, GetStockObject(OEM_Fixed_Font));
    TempStr := '';
    For tx := xl to xh Do
      TempStr := TempStr + ' ';
    TextOut(DC, (Xl - 1) * THorz, (Yl - 1) * TVert, PChar(@TempStr[1]),
      Length(TempStr));
    ReleaseDC(HWindow,DC);
    End;
  End;


Procedure PutScrnWordDC(SX: Byte; SY: Byte; CA: Word; Var DC: HDC);
  Var
    Attr: Byte;
    Ch: Char;

  Begin
  ScrnArray^[((SY - 1) * ScreenWidth) + SX - 1] := CA;
  Ch := Chr(Lo(CA));
  Attr := CA shr 8;
  SetTextColor(DC,ColorArray[Attr and $0f]);
  SetBkColor(DC, ColorArray[Attr shr 4]);
  SelectObject(DC, GetStockObject(OEM_Fixed_Font));
  TextOut(DC, (SX - 1) * THorz, (SY - 1) * TVert, PChar(@Ch), 1);
  End;


Procedure RedrawScrn;
  Var
    DC: HDC;
    Paint: TPaintStruct;
    Tx, Ty: Word;
    Mx, My: Word;
    Attr: Byte;
    LA: Byte;
    Ch: Char;

  Begin
  If ((THorz > 0) and (TVert > 0)) Then
    Begin
    DC := BeginPaint(HWindow, Paint);
    Tx := Paint.RcPaint.Left div THorz;
    Ty := Paint.RcPaint.Top div TVert;
    If ((Tx < (ScreenWidth - 1)) and (Ty < (ScreenHeight - 1))) Then
      Begin
      Mx := (Paint.RcPaint.Right div Thorz) + 1;
      My := (Paint.RcPaint.Bottom div TVert) + 1;
      If Mx > (ScreenWidth - 1) Then
        Mx := ScreenWidth - 1;
      If My > (ScreenHeight - 1) Then
        My := ScreenHeight - 1;
      Attr := ScrnArray^[Tx + (ScreenWidth * Ty)] Shr  8;
      LA := Attr;
      SetTextColor(DC,ColorArray[Attr and $0f]);
      SetBkColor(DC, ColorArray[Attr shr 4]);
      SelectObject(DC, GetStockObject(OEM_Fixed_Font));
      While Ty <= My Do
        Begin
        Tx := Paint.RcPaint.Left div THorz;
        While Tx <= Mx Do
          Begin
          Attr := ScrnArray^[Tx + (TY * ScreenWidth)] shr 8;
          If Attr <> LA Then
            Begin
            SetTextColor(DC,ColorArray[Attr and $0f]);
            SetBkColor(DC, ColorArray[Attr shr 4]);
            LA := Attr;
            End;
          Ch := Chr(ScrnArray^[Tx + (TY * ScreenWidth)] and $ff);
          TextOut(DC, Tx * THorz, TY * TVert, PChar(@Ch), 1);
          Inc(Tx);
          End;
        Inc(Ty);
        End;
      End;
    EndPaint(HWindow, Paint);
    End;
  End;


Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
  Var
    DC: HDC;

  Begin
  DC := GetDC(HWindow);
  PutScrnWordDC(SX, SY, CA, DC);
  ReleaseDC(HWindow,DC);
  End;


Function  GetScrnWord(SX: Byte; SY: Byte): Word;
  Begin
  GetScrnWord := ScrnArray^[((SY - 1) * ScreenWidth) + SX - 1];
  End;


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


Procedure RestoreScrnRegion(xl,yl,xh,yh: Byte; Pt: Pointer);
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
  Cy := yl;
  While (cy <= yh) Do
    Begin
    Cx := xl;
    While (Cx <= xh) Do
      Begin
      PutScrnWord(Cx, Cy, Ord(ch) + (TextAttr shl 8));
      Inc(Cx);
      End;
    Inc(Cy);
    End;
  End;



Function  KeyPressed: Boolean;
  Begin
  If PeekMessage(Message, HWindow, 0, 0, pm_NoRemove) Then
    Begin
    GetMessage(Message, HWindow, wm_KeyFirst, wm_KeyLast);
    If (TranslateAccelerator(HWindow, Accels, Message) = 0) Then
      Begin
      TranslateMessage(Message);
      DispatchMessage(Message);
      End;
    End;
  KeyPressed := (KeyPut <> KeySend);
  End;


Function  ReadKey: Char;
  Begin
  While KeySend = KeyPut Do
    Begin
    While PeekMessage(Message, HWindow, 0, 0, pm_NoRemove) Do
      Begin
      GetMessage(Message, HWindow, 0, 0);
      If (TranslateAccelerator(HWindow, Accels, Message) = 0) Then
        Begin
        TranslateMessage(Message);
        DispatchMessage(Message);
        End;
      End;
    End;
  ReadKey := GetKeyChar;
  End;


Procedure WinMain;
  Var
    DC: HDC;
    Metrics: TTextMetric;

  Begin
  if HPrevInst = 0 then
    Begin
    WindowClass.hInstance := HInstance;
    WindowClass.hIcon := LoadIcon(0, idi_Application);
    WindowClass.hCursor := LoadCursor(0, idc_Arrow);
    WindowClass.hbrBackground := GetStockObject(white_Brush);
    if not RegisterClass(WindowClass) then Halt(255);
    End;
  HWindow := CreateWindow(
  AppName,
    'MKWCrt Application',
    ws_OverlappedWindow,
    cw_UseDefault,
    cw_UseDefault,
    cw_UseDefault,
    cw_UseDefault,
    0,
    0,
    HInstance,
    nil);
  ShowWindow(HWindow, CmdShow);
  UpdateWindow(HWindow);
  DC := GetDC(HWindow);
  SelectObject(DC, GetStockObject(OEM_Fixed_Font));
  GetTextMetrics(DC, Metrics);
  TVert := Metrics.tmHeight + Metrics.tmInternalLeading +
    Metrics.tmExternalLeading;
  THorz := Metrics.tmAveCharWidth;
  ReleaseDC(HWindow,DC);
  End;


{$F+}
Function WinWrite(Var F: TTextRec): Integer;
  Var
    i: Word;

  Begin
  i := 0;
  While i < F.BufPos Do
    Begin
    PutChar(F.BufPtr^[i]);
    Inc(i);
    End;
  F.BufPos := 0;
  WinWrite := 0;
  End;


{$F+}
Function WinCrtClose(Var F: TTextRec): Integer;
  Begin
  F.Mode := fmClosed;
  WinCrtClose := 0;
  End;


{$F+}
Function WinCrtOpen(Var F: TTextRec): Integer;
  Begin
  If F.Mode = fmOutput Then
    WinCrtOpen := 0
  Else
    WinCrtOpen := 5;
  End;


Procedure AssignWinCrt(Var F: Text);
  Begin
  TTextRec(F).Mode := fmClosed;
  TTextRec(F).BufSize := SizeOf(TTextBuf);
  TTextRec(F).BufPtr := @TTextRec(F).Buffer;
  TTextRec(F).OpenFunc := @WinCrtOpen;
  TTextRec(F).InOutFunc := @WinWrite;
  TTextRec(F).FlushFunc := @WinWrite;
  TTextRec(F).CloseFunc := @WinCrtClose;
  TTextRec(F).Name[0] := #0;
  End;


Begin
New(ScrnArray);
ScrnHeight := ScreenHeight;
ScrnWidth := ScreenWidth;
WinMain;
Accels :=LoadAccelerators(HInstance, 'A_RESOURCE');
If Accels = 0 Then
  MessageBeep(0);
AssignWinCrt(Output);
Rewrite(Output);
KeyPut := 1;
KeySend := 1;
ClrScr;
End.
