{******************************************************}
{*                   TPVIEW.PAS  2.03                 *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}


{$IFDEF DPMI}
{$V-,B-,R-,S-,F-,O-,A+,I-,X+}
{$ELSE}
{$V-,B-,R-,S-,F+,O+,A+,I-,X+}
{$ENDIF}

unit TpfView;

interface

uses
  Dos,
  ApMisc,
  OpInline,
  OpString,
  OpConst,
  OpRoot,
  OpCrt,
  OpMouse,
  OpCmd,
  OoFaxCvt;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

{$I TPFVIEW.ICD}

const
  MaxLines = 4000;

{$IFDEF Ver60}
  SegA000 : Word = $A000;
{$ENDIF}

type

  PLine = ^TLine;
  TLine = array[0..$FFF0] of Byte;

  PNode = ^TNode;
  TNode =
    record
      Data : PLine;
      Len  : Word;
    end;

  PList = ^TList;
  TList =
    record
      Lines     : array[1..MaxLines] of PNode;
      LineCount : Word;
    end;

  PFaxViewer = ^TFaxViewer;
  TFaxViewer =
    object(UnpackFax)
      fvCmdPtr   : CommandProcessorPtr; { pointer to command processor    }
      fvCmd      : Word;                { last command received           }
      fvKey      : Word;                { last keystroke                  }
      fvError    : Word;                { error code for last operation   }
      fvWidth    : Word;                { width of the screen, pixels     }
      fvWidthB   : Word;
      fvHeight   : Word;                { height of the screen, pixels    }
      fvBuffer   : Pointer;             { save buffer for text screen     }
      fvCursor   : Word;                { saved cursor pos of text screen }
      fvCursorT  : Word;                { saved cursor scan lines         }
      fvTMode    : Word;                { mode of saved text screen       }
      fvCurPage  : Word;                { currently displayed fax page    }
      fvMode     : Byte;                { graphics mode number            }
      fvInGraph  : Boolean;             { TRUE if in graphics mode        }
      fvSkip     : Boolean;             { TRUE to skip every other line   }
      fvSkipThis : Boolean;             { TRUE to skip the current line   }
      fvRasters  : TList;               { raster lines of current page    }
      fvFile     : PathStr;             { name of fax file                }
      fvErrorProc: ErrorProc;

      constructor Init(FName : PathStr; Mode : Byte; Width, Height : Word);
      destructor Done; virtual;

      procedure Process; virtual;
      procedure GotError(Code : Word); virtual;
      function GetLastError : Word;
      function PeekLastError : Word;
      procedure GetNextCommand; virtual;
      function GetLastCommand : Word;
      function GetLastKey : Word;
      procedure SetLastCommand(Cmd : Word);
      procedure SetErrorProc(EP : ErrorProc);

      function OutputLine : Boolean; virtual;
      procedure OneMomentPlease;

      {++internal}
      procedure fvGoGraphics;
      procedure fvGoText;
      procedure fvGraphicsClear;
      procedure fvPackBuffer(var Buffer; var Len : Word);
      function  fvInitNode(var T : TNode; var Buffer; L : Word) : Boolean;
      procedure fvClearRasterList;
      procedure fvDoneNode(var P : PNode);
    end;

var
  ViewerCommands : CommandProcessor;

implementation

  procedure FastZero(var Dest; Size : Word); assembler;
  asm
    xor   ax,ax    { store zeros from AX    }
    les   di,Dest  { ES:DI = @Dest          }
    cld            { go forward             }
    mov   cx,Size  { size of data to zero   }
    shr   cx,1     { divide size by two     }
    jnc   @1       { any odd bytes?         }
    stosb          { store odd byte         }
@1:
    jcxz  @2       { if no bytes left, exit }
    rep   stosw    { zero remaining bytes   }
@2:
  end;

  procedure BltLine(var Buffer; Len, X, Y, WidthBytes : Word); assembler;
  asm
    { BX will contains WidthBytes throughout }
    mov   bx,WidthBytes
    xor   dx,dx
    cld

    { point ES:DI to the proper line on the screen }
    mov   ax,SegA000
    mov   es,ax
    mov   ax,Y
    dec   ax
    mul   bx
    mov   di,ax

    { point DS:SI to the buffer }
    push  ds
    lds   si,Buffer

    { now, figure out the actual number of bytes to be transfered from Buffer }
    mov   ax,X
    mov   cx,Len

    cmp   ax,cx               { is the x offset greater than the length? }
    ja    @3                  { if so, fill the line with zeros }
    add   si,ax
    sub   cx,ax               { CX gets WidthBytes or (Len - X), }
    cmp   cx,bx               {   whichever is smaller }
    jb    @1
    mov   cx,bx

@1:
    mov   dx,cx               { save this length count for later }
    shr   cx,1                { divide length by two for move-by-word }
    jnc   @2
    movsb                     { move the odd byte }

@2:
    jcxz  @3
    rep   movsw               { move the rest of the data }

    { by the time the code gets to @3, dx should contain the number of }
    { bytes that have been written to the screen }

@3:
    sub   bx,dx               { get the number of "padding" bytes }
    mov   cx,bx
    jcxz  @9                  { if no padding, then bail }

    mov   ax,$FFFF
    shr   cx,1                { divide cx by two for move-by-word }
    jnc   @4
    stosb                     { store the odd byte }

@4:
    jcxz  @9
    rep   stosw

@9:
    pop   ds
  end;

  procedure ScrollScreenUp(WidthBytes, Height : Word); assembler;
  asm
    push  ds                  { point DS:SI to the second line of the screen }
    mov   bx,SegA000
    mov   ds,bx
    mov   si,WidthBytes

    mov   es,bx               { point ES:DI to the first line of the screen }
    xor   di,di

    cld                       { go forward }

    mov   cx,Height           { get number of bytes to move in CX }
    dec   cx
    mov   ax,si
    mul   cx
    mov   cx,ax

    shr   cx,1                { divide CX by two for move-by-word }
    jnc   @1
    movsb                     { move the odd byte }

@1:
    jcxz  @2                  { no more data? if so, leave }
    rep   movsw               { move the rest of the data }

@2:
    pop   ds
  end;

  procedure ScrollScreenDown(WidthBytes, Height : Word); assembler;
  asm
    push  ds                  { DS and ES both point to video memory }
    mov   bx,SegA000
    mov   ds,bx
    mov   es,bx

    mov   bx,WidthBytes       { get the number of bytes to move }
    mov   ax,Height
    dec   ax
    mul   bx
    mov   cx,ax

    mov   si,cx               { DS:SI points just beyond the end of the }
                              { 2nd to last line                     }

    mov   di,si               { ES:DI points just beyond the end of the }
    add   di,bx               { last line }

    dec   si                  { point to the actual ends of the 2nd-to-last }
    dec   di                  { and last lines }

    std                       { go backwards }

    shr   cx,1                { divide CX by two for move-by-word }
    jnc   @1                  { if there's no odd byte, go to move-by-word }
    movsb

@1:
    jcxz  @9                  { if there's no data left, get out }
    dec   si
    dec   di
    rep   movsw               { move the remaining data }

@9:
    pop   ds
  end;

  constructor TFaxViewer.Init(FName : PathStr; Mode : Byte; Width, Height : Word);
  begin
    fvFile    := FName;
    fvCmdPtr  := @ViewerCommands;
    fvMode    := Mode;
    fvWidth   := Width;
    fvWidthB  := fvWidth shr 3;
    fvHeight  := Height;
    fvBuffer  := nil;
    fvCursor  := 0;
    fvCursorT := 0;
    fvInGraph := False;
    fvCurPage := 1;
    fvError   := 0;

    FastZero(fvRasters, SizeOf(fvRasters));

    if not UnpackFax.Init then
      Fail;
  end;

  destructor TFaxViewer.Done;
  begin
    fvGoText;
    fvClearRasterList;
    UnpackFax.Done;
  end;

  procedure TFaxViewer.Process;
  var
    Y        : Word;
    X        : Word;
    W        : Word;
    Finished : Boolean;
    NeedUpd  : Boolean;

  label
    ExitPoint;

    procedure UpdateScreen;
    var
      N : Word;
      Z : Word;
      P : PNode;
      B : Byte;
      S : String;

    begin
      NeedUpd := False;
      if (Y > fvRasters.LineCount) then
        Exit;
      B := $FF;
      N := 0;
      Z := Y;
      P := fvRasters.Lines[Z];
      if (P = nil) then
        Exit;

      for N := 1 to fvHeight do begin
        if (P <> nil) then
          BltLine(P^.Data^, P^.Len, X, N, fvWidthB)
        else
          BltLine(B, 1, X, N, fvWidthB);
        if (P <> nil) then begin
          Inc(Z);
          if (Z > fvRasters.LineCount) then
            P := nil
          else
            P := fvRasters.Lines[Z];
        end;
      end;
    end;

    procedure ScrollDown;
    var
      B : Byte;
      P : PNode;

    begin
      if (Y > 1) then begin
        Dec(Y);
        B := $FF;
        ScrollScreenDown(fvWidthB, fvHeight);
        P := fvRasters.Lines[Y];
        if (P <> nil) then
          BltLine(P^.Data^, P^.Len, X, 1, fvWidthB)
        else
          BltLine(B, 1, X, 1, fvWidthB);
      end;
    end;

    procedure ScrollUp;
    var
      P : PNode;
      B : Byte;

    begin
      if (Y < fvRasters.LineCount) then begin
        Inc(Y);
        B := $FF;

        ScrollScreenUp(fvWidthB, fvHeight);
        P := fvRasters.Lines[Y + fvHeight - 1];
        if (P <> nil) then
          BltLine(P^.Data^, P^.Len, X, fvHeight, fvWidthB)
        else
          BltLine(B, 1, X, fvHeight, fvWidthB);
      end;
    end;

    procedure ScrollLeft;
    begin
      Inc(X, 8);
      NeedUpd := True;
    end;

    procedure ScrollRight;
    begin
      if (X >= 8) then begin
        Dec(X, 8);
        NeedUpd := True;
      end;
    end;

    procedure PageUp;
    begin
      Y := MaxLong(1, LongInt(Y) - 72);
      NeedUpd := True;
    end;

    procedure PageDown;
    begin
      Y := MinLong(fvRasters.LineCount, Y + 72);
      NeedUpd := True;
    end;

    procedure HomePage;
    begin
      X := 0;
      Y := 1;
      NeedUpd := True;
    end;

    procedure EndPage;
    begin
      X := 0;
      if (fvRasters.LineCount < fvHeight) then
        Y := 1
      else
        Y := fvRasters.LineCount - fvHeight + 1;
      NeedUpd := True;
    end;

    procedure NewPagePrim;
    begin
      OneMomentPlease;
      fvClearRasterLIst;
      UnpackPage(fvFile, fvCurPage);
      if (AsyncStatus <> 0) and (AsyncStatus <> ecUserAbort) then begin
        GotError(AsyncStatus);
        Exit;
      end;

      X := 0; Y := 1;
      NeedUpd := True;
    end;

    procedure NextPage;
    begin
      if (fvCurPage < FaxHeader.PageCount) then begin
        Inc(fvCurPage);
        NewPagePrim;
      end else
        RingBell;
    end;

    procedure PrevPage;
    begin
      if (fvCurPage > 1) then begin
        Dec(fvCurPage);
        NewPagePrim;
      end else
        RingBell;
    end;

    procedure TopOfFile;
    begin
      if (fvCurPage = 1) and ((Y <> 1) or (X <> 0)) then begin
        Y := 1;
        X := 0;
        NeedUpd := True
      end else if (fvCurPage <> 1) then begin
        fvCurPage := 1;
        NewPagePrim;
      end;
    end;

    procedure EndOfFile;
    begin
      if (fvCurPage = FaxHeader.PageCount) and ((Y <> 1) or (X <> 0)) then begin
        Y := 1;
        X := 0;
        NeedUpd := True;
      end else if (fvCurPage <> FaxHeader.PageCount) then begin
        fvCurPage := FaxHeader.PageCount;
        NewPagePrim;
      end;
    end;

  begin

    fvSkipThis := True;
    GetPageHeader(fvFile, fvCurPage, PageHeader);
    if (AsyncStatus <> 0) then begin
      GotError(AsyncStatus);
      Exit;
    end;

    fvSkip := (PageHeader.ImgFlags and ffHighRes = ffHighRes);

    UnpackPage(fvFile, fvCurPage);
    if (AsyncStatus <> 0) then begin
      GotError(AsyncStatus);
      Exit;
    end;

    fvGoGraphics;
    Y := 1;
    X := 0;

    Finished := False;
    NeedUpd := True;
    repeat
      if NeedUpd then
        UpdateScreen;

      GetNextCommand;

      case fvCmd of
        ccQuit     : Finished := True;
        ccUp       : ScrollDown;
        ccDown     : ScrollUp;
        ccLeft     : ScrollRight;
        ccRight    : ScrollLeft;
        ccPageUp   : PageUp;
        ccPageDn   : PageDown;
        ccHome     : HomePage;
        ccEnd      : EndPage;
        ccNextRec  : NextPage;
        ccPrevRec  : PrevPage;
        ccTopOfFile: TopOfFile;
        ccEndOfFile: EndOfFile;
      end;
    until Finished or (fvCmd = ccError);

    fvGoText;
  end;

  procedure TFaxViewer.GotError(Code : Word);
  begin
    fvGoText;
    fvError := Code;
    SetLastCommand(ccError);
    if (@fvErrorProc <> nil) then
      fvErrorProc(0, fvError, emNullError)
    else
      RingBell;
  end;

  function TFaxViewer.GetLastError : Word;
  begin
    GetLastError := fvError;
    fvError := 0;
  end;

  function TFaxViewer.PeekLastError : Word;
  begin
    PeekLastError := fvError;
  end;

  procedure TFaxViewer.GetNextCommand;
  begin
    if (fvError = 0) then
      fvCmd := fvCmdPtr^.GetCommand(fvKey)
    else
      fvCmd := ccError;
  end;

  function TFaxViewer.GetLastCommand : Word;
  begin
    GetLastCommand := fvCmd;
  end;

  function TFaxViewer.GetLastKey : Word;
  begin
    GetLastKey := fvKey;
  end;

  procedure TFaxViewer.SetLastCommand(Cmd : Word);
  begin
    fvCmd := Cmd;
  end;

  procedure TFaxViewer.SetErrorProc(EP : ErrorProc);
  begin
    fvErrorProc := EP;
  end;

  function TFaxViewer.OutputLine : Boolean;
  var
    P : PNode;
    W : Word;

  begin
    OutputLine := False;

    AsyncStatus := ecOK;

    if fvSkip then begin
      fvSkipThis := not fvSkipThis;
      if fvSkipThis then
        Exit;
    end;

    with fvRasters do begin
      New(P);
      if (P <> nil) then begin
        FastZero(P^, SizeOf(TNode));
        W := LineOfs;
        fvPackBuffer(LineBuffer^, W);
        if fvInitNode(P^, LineBuffer^, W) then begin
          Inc(LineCount);
          if (LineCount > MaxLines) then begin
            AsyncStatus := epFatal+ecOutOfMemory;
            GotError(AsyncStatus);
          end else
            Lines[LineCount] := P;
        end else begin
          AsyncStatus := epFatal+ecOutOfMemory;
          GotError(AsyncStatus);
        end;
      end else begin
        AsyncStatus := epFatal+ecOutOfMemory;
        GotError(AsyncStatus);
      end;
    end;

    OutputLine := (AsyncStatus <> 0);
  end;

  procedure TFaxViewer.OneMomentPlease;
  const
    OMPLen = 24;
    OMP    : String[OMPLen] = 'One moment, please . . .';
  var
    Regs   : Registers;
    I      : Byte;

  begin
    fvGraphicsClear;
    FastZero(Regs, SizeOf(Regs));

    { int 10 position cursor function }
    Regs.AH := 2;
    Regs.DL := ((80 - OMPLen) div 2) + 1;
    Regs.DH := 13;
    Intr($10, Regs);

    for I := 1 to OMPLen do begin
      { int 10 print character in teletype mode function }
      Regs.AH := $0E;
      Regs.AL := Byte(OMP[I]);
      Regs.BX := $00FF;
      Intr($10, Regs);
    end;
  end;

  procedure TFaxViewer.fvGoGraphics;
  var
    Regs : Registers;
    F    : Text;

  begin
    if not fvInGraph then begin
      { save the screen }

      if MouseInstalled then
        HideMouse;

      fvTMode := LastMode;
      if not SaveWindow(1, 1, ScreenWidth, ScreenHeight, True, fvBuffer) then begin
        GotError(epNonFatal+ecOutOfMemory);
        Exit;
      end;

      GetCursorState(fvCursor, fvCursorT);

      Regs.AX := fvMode;
      Intr($10, Regs);
      Regs.AX := $0F00;
      Intr($10, Regs);
      if (Regs.AL <> fvMode) then begin
        fvGoText;
        GotError(epNonFatal+9999);
        Exit;
      end;

      fvInGraph := True;
      fvGraphicsClear;
    end;
  end;

  procedure TFaxViewer.fvGoText;
  begin
    if fvInGraph then begin
      TextMode(fvTMode);
      RestoreWindow(1, 1, ScreenWidth, ScreenHeight, True, fvBuffer);
      RestoreCursorState(fvCursor, fvCursorT);
      fvInGraph := False;
    end;
  end;

  procedure TFaxViewer.fvGraphicsClear;
  begin
    if fvInGraph then
      asm
        les   di,Self
        mov   cx,es:[di].fvWidth

        { get number of bytes per line }
        shr   cx,1
        shr   cx,1
        shr   cx,1

        mov   ax,es:[di].fvHeight
        mul   cx

        mov   cx,ax
        shr   cx,1
        mov   ax,$FFFF

        mov   bx,SegA000
        mov   es,bx
        xor   di,di
        cld

        rep   stosw
      end;
  end;

  procedure TFaxViewer.fvPackBuffer(var Buffer; var Len : Word);
  type
    PW = ^Word;

  var
    TL : TLine absolute Buffer;
    W  : Word;
    X  : Word;
    P  : PW;

  begin
    X := Len shr 1;
    Len := X;
    asm
      mov   cx,X
      jcxz  @2
      push  ds
      les   di,Buffer
      lds   si,Buffer
      cld

@1:   lodsw
      xchg  al,ah
      xor   bl,bl

      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1
      shl   ax,1
      shl   ax,1
      rcl   bl,1

      mov   es:[di],bl
      inc   di
      loop  @1
      pop   ds
@2:
    end;
  end;

  function TFaxViewer.fvInitNode(var T : TNode; var Buffer; L : Word) : Boolean;
  var
    I : Word;

  begin

    T.Data := nil;
    T.Len  := 0;

    if (L = 0) then begin
      fvInitNode := True;
      Exit;
    end;

    fvInitNode := False;

    if not GetMemCheck(T.Data, L) then
      Exit;

    fvInitNode := True;
    MoveFast(Buffer, T.Data^, L);
    T.Len := L;
    asm
      les   di,T
      les   di,TNode(es:[di]).Data
      mov   cx,L
@1:   not   byte ptr es:[di]
      inc   di
      loop  @1
    end;
  end;

  procedure TFaxViewer.fvClearRasterList;
  var
    I : Word;

  begin
    with fvRasters do begin
      I := LineCount;
      while (I > 0) do begin
        fvDoneNode(Lines[I]);
        Dec(I);
      end;
      FastZero(Lines, SizeOf(Lines));    {!!.02}
      LineCount := 0;
    end;
  end;

  procedure TFaxViewer.fvDoneNode(var P : PNode);
  begin
    with P^ do
      FreeMemCheck(Data, Len);
    Dispose(P);
  end;

begin
  ViewerCommands.Init(@ViewerKeySet, ViewerKeyMax);
  ViewerCommands.cpOptionsOn(cpEnableMouse);
end.
