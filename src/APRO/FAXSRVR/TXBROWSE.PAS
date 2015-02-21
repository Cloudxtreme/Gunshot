{=======================================================================
TXBROWSE - a small unit for browsing text files of any size. In a text
file, all lines (except perhaps the last one) must be terminated with
CR/LF.

Runs in DOS real mode and DOS protected mode. Requires TP6 or BP7.
Uses no data space or heap space. Uses about 5000 bytes of code and
about 1500 bytes of stack space. Provides keyboard support but no
mouse support. Scrolling is a little slow, a consequence of the
minimal buffer memory used.

Note that it is the responsibility of the caller to save the
underlying screen, frame the window, etc. if desired.

See the comments below for more information.

BROWSE.PAS is a simple demonstration of the unit.

Written by Kim Kokkonen, TurboPower Software. Released to the public
domain. Contact Kim on CompuServe at 76004,2611.

Version 1.0 - 9/2/94
  initial release
Version 1.1 - 9/12/94
  fix bug for file that starts with a blank line
  optimize PageDown to avoid wasted work at end of file
Version 1.2 - 10/20/94
  fix bug when browsing backwards with lines longer than MaxCols
  prevent crashes in case of other bugs like the previous one
  add ability to display the end of file initially

========================================================================}

{$R-,S-,I-}

{$I APDEFINE.INC}

unit TxBrowse;
  {-Browse a text file in a window}

interface

uses
  Dos;

type
  TBrowseCharSet = set of char;
  ReadKeyFunc = function : char;
  StatusProc = procedure (TopLine, TopOfs, LastOfs : LongInt;
                          LeftOfs : Word; var StatusData);

function BrowseFile(XLow, YLow, XHigh, YHigh, Attr : Byte;
                    var TopLine : LongInt;
                    var LeftOfs : Word;
                    FName : PathStr;
                    ReadKeyF : ReadKeyFunc;
                    ExitChars : TBrowseCharSet;
                    var ExitKey : Char;
                    StatusP : StatusProc;
                    var StatusData) : Word;
  {-Browse text file FName. Assumes each line in the file ends with
    CR/LF. FName is opened in read-only mode and the page starting at
    line TopLine and offset LeftOfs is displayed. Passing -1 for
    TopLine causes the browser to display the end of file. The browser
    reacts to cursor keys until a key in ExitChars is pressed. The
    current values of TopLine and LeftOfs are returned, as is the key
    used to exit. To specify extended keystrokes in ExitChars, set the
    top bit. For example, use #$AD for <AltX>. ReadKey is a
    user-supplied function to get keyboard input. Pass CRT.ReadKey
    here unless you have special needs for background processing, etc.
    StatusP is called just before getting each keystroke with the
    current values of TopLine and LeftOfs. StatusData is any data that
    the application wishes passed on to the status procedure. Pass
    StatusP = nil (BP7 allows this) if you don't want a status
    procedure.

    Returns zero if successful, a non-zero Turbo Pascal error code if
    not.

    Supports the following keystrokes:
        Up, ^E, ^W       scroll up one line
        Down, ^X, ^Z     scroll down one line
        PgUp, ^R         scroll up one window
        PgDn, ^C         scroll down one window
        ^Home, ^PgUp     scroll to top of file
        ^End, ^PgDn      scroll to end of file
        Left, ^S         scroll left one column
        Right, ^D        scroll right one column
        Home             scroll to left edge
        End              scroll to right edge
    }

  {=========================================================================}

implementation

uses
{$IFDEF UseOPRO}
  OpCrt;
{$ELSE}
{$IFDEF UseTPRO}
  TpCrt;
{$ELSE}
  Crt, FastW1;
{$ENDIF}
{$ENDIF}

{$DEFINE UseAsm}   {Define to use Asm statements for better speed}

function BrowseFile(XLow, YLow, XHigh, YHigh, Attr : Byte;
                    var TopLine : LongInt;
                    var LeftOfs : Word;
                    FName : PathStr;
                    ReadKeyF : ReadKeyFunc;
                    ExitChars : TBrowseCharSet;
                    var ExitKey : Char;
                    StatusP : StatusProc;
                    var StatusData) : Word;
const
  MaxRows = 50;  {max rows in window, max rows whose offset is buffered}
  MaxCols = 128; {max cols in window, max amount of horizontal scrolling,
                  must always be less than 256}
  Unknown = -1;  {used to indicate unknown line or offset. don't change}
type
  OfsArray = array[1..MaxRows] of LongInt;
var
  Status : Word;
  TopLineInFOfs : LongInt;
  FirstKnownOfs : LongInt;
  FirstKnownLine : LongInt;
  LastKnownOfs : LongInt;
  LastKnownLine : LongInt;
  LastTopLine : LongInt;
  LastOfs : LongInt;
  Ch : Char;
  SaveMode : Byte;
  Done : Boolean;
  SaveCheck : Boolean;
  FOfs : OfsArray;
  F : File;

  procedure FindKnownOfs;
    {-Find first and last known offsets}
  var
    Row : Word;
  begin
    FirstKnownOfs := Unknown;
    FirstKnownLine := Unknown;
    LastKnownOfs := Unknown;
    LastKnownLine := Unknown;
    for Row := 1 to MaxRows do
      if FOfs[Row] <> Unknown then begin
        if FirstKnownOfs = Unknown then begin
          FirstKnownOfs := FOfs[Row];
          FirstKnownLine := TopLineInFOfs+Row-1;
        end;
        LastKnownOfs := FOfs[Row];
        LastKnownLine := TopLineInFOfs+Row-1;
      end;
  end;

  function MinLong(A, B : LongInt) : LongInt;
{$IFDEF UseAsm}
  assembler;
  asm
    mov ax,word ptr A
    mov dx,word ptr A+2
    mov bx,word ptr B
    mov cx,word ptr B+2
    cmp dx,cx
    jb @2
    ja @1
    cmp ax,bx
    jbe @2
@1: xchg ax,bx
    xchg dx,cx
@2:
  end;
{$ELSE}
  begin
    if A <= B then
      MinLong := A
    else
      MinLong := B;
  end;
{$ENDIF}

  function MinWord(A, B : Word) : Word;
{$IFDEF UseAsm}
  assembler;
  asm
    mov ax,A
    mov bx,B
    cmp ax,bx
    jbe @1
    xchg ax,bx
@1:
  end;
{$ELSE}
  begin
    if A <= B then
      MinWord := A
    else
      MinWord := B;
  end;
{$ENDIF}

  procedure UpdateOffsets(Top : LongInt);
  var
    Temp : LongInt;
  begin
    if Top < TopLineInFOfs then begin
      {asking for a line prior to what's in the current offset array}
      Temp := MinLong(TopLineInFOfs-Top, MaxRows);
{$IFOPT R+}
      if Temp < MaxRows then
{$ENDIF}
        move(FOfs[1], FOfs[Temp+1], SizeOf(LongInt)*(MaxRows-Temp));
      fillchar(FOfs[1], SizeOf(LongInt)*Temp, Byte(Unknown));
      TopLineInFOfs := Top;
      FindKnownOfs;
    end else if Top+YHigh-YLow > TopLineInFOfs+MaxRows-1 then begin
      {asking for a line after what's in the current offset array}
      Temp := MinLong(Top+YHigh-YLow-(TopLineInFOfs+MaxRows-1), MaxRows);
{$IFOPT R+}
      if Temp < MaxRows then
{$ENDIF}
        move(FOfs[Temp+1], FOfs[1], SizeOf(LongInt)*(MaxRows-Temp));
      fillchar(FOfs[MaxRows-Temp+1], SizeOf(LongInt)*Temp, Byte(Unknown));
      TopLineInFOfs := Top+YHigh-YLow-MaxRows+1;
      FindKnownOfs;
    end;

    TopLine := Top;
  end;

  procedure DisplayLine(Row : Word; Line : LongInt);
  var
    LenLine : Word;
    LenToRead : Word;
    LenRead : Word;
    Ofs : LongInt;
    OfsNext : LongInt;
    FOfsIndex : Word;
    S : String[MaxCols];
  begin
    FOfsIndex := Line-TopLineInFOfs+1;
    LenLine := 0;
    Ofs := FOfs[FOfsIndex];
    if Ofs <> Unknown then begin
      Seek(F, Ofs);
      if FOfsIndex < MaxRows then begin
        OfsNext := FOfs[FOfsIndex+1];
        if OfsNext <> Unknown then
          LenToRead := MinWord(OfsNext-Ofs, MaxCols)
        else
          LenToRead := MaxCols;
      end else
        LenToRead := MaxCols;
      BlockRead(F, S[1], LenToRead, LenRead);
      if IoResult = 0 then begin
{$IFDEF UseAsm}
        asm
          mov cx,LenRead
          cld
          mov al,13
          lea di,S
          mov si,ss
          mov es,si
          inc di
          mov si,di
          repne scasb
          jne @1           {!!.1 changed rest of asm block}
          dec di
@1:       sub di,si
          mov LenLine,di
        end;
{$ELSE}
        while (LenLine < LenRead) and (S[LenLine+1] <> #13) do
          inc(LenLine);
{$ENDIF}
      end;
    end;

    S[0] := Char(XHigh-XLow+1);
    if LeftOfs >= LenLine then
      LenLine := 0
    else if LeftOfs <> 0 then begin
      move(S[LeftOfs+1], S[1], LenLine-LeftOfs);
      dec(LenLine, LeftOfs);
    end;
    if LenLine < Byte(S[0]) then
      FillChar(S[LenLine+1], Byte(S[0])-LenLine, ' ');
    FastWrite(S, Row, XLow, Attr);
  end;

  procedure FindNextLineOfs(var Ofs : LongInt);
  var
    LenLine : Word;
    LenRead : Word;
    S : String[MaxCols];
  begin
    repeat
      Seek(F, Ofs);
      BlockRead(F, S[1], MaxCols, LenRead);
      if (IoResult <> 0) or (LenRead = 0) then begin
        Ofs := Unknown;
        exit;
      end;
{$IFDEF UseAsm}
      asm
        mov cx,LenRead
        cld
        mov al,13
        lea di,S
        mov si,ss
        mov es,si
        inc di
        mov si,di
        repne scasb
        jne @1           {!!.1 changed rest of asm block}
        dec di
@1:     sub di,si
        mov LenLine,di
      end;
{$ELSE}
      S[0] := Char(LenRead);
      LenLine := 0;
      while (LenLine < LenRead) and (S[LenLine+1] <> #13) do
        inc(LenLine);
{$ENDIF}
      if LenLine = LenRead then
        {didn't find CR yet}
        inc(Ofs, LenLine)
      else begin
        {skip CR and assumed LF}
        inc(Ofs, LenLine+2);
        exit;
      end;
    until False;
  end;

  procedure FindPrevLineOfs(var Ofs : LongInt; var UntermLine : Boolean);
  var
    SPos : Word;
    LenToRead : Word;
    LenRead : Word;
    ContinuedLine : Boolean; {!!.2}
    S : String[MaxCols];
  begin
    UntermLine := False;
    ContinuedLine := False;
    repeat
      if Ofs >= MaxCols then begin
        LenToRead := MaxCols;
        dec(Ofs, MaxCols);
      end else begin
        LenToRead := Ofs;
        Ofs := 0;
      end;
      Seek(F, Ofs);
      BlockRead(F, S[1], LenToRead, LenRead);
      if (IoResult <> 0) or (LenRead = 0) then begin
        Ofs := Unknown;
        exit;
      end;
      S[0] := Char(LenRead);
      SPos := LenRead;

      if SPos < 2 then
        {beginning of file}
        exit;

      {find end of previous line}
      if not ContinuedLine then {!!.2}
        if S[SPos-1] <> #13 then
          UntermLine := True
        else
          dec(SPos, 2);

      {find end of line before that}
{$IFDEF UseAsm}
      asm
        mov cx,SPos
        std
        mov al,13
        lea di,S
        mov si,di
        mov bx,ss
        mov es,bx
        add di,cx
        repne scasb
        jne @1           {!!.1 changed remainder of asm block}
        inc di
@1:     sub di,si
        mov SPos,di
      end;
{$ELSE}
      while (SPos > 0) and (S[SPos] <> #13) do
        dec(SPos);
{$ENDIF}

      if SPos > 0 then begin
        inc(Ofs, SPos+1);
        exit;
      end else if Ofs = 0 then
        {beginning of file}
        exit
      else                              {!!.2}
        {didn't find previous line yet} {!!.2}
        ContinuedLine := True;          {!!.2}

    until False;
  end;

  procedure SeekForward(Line : LongInt; var TempLine, TempOfs : LongInt);
  begin
    while (TempLine < Line) and (TempOfs <> Unknown) do begin
      FindNextLineOfs(TempOfs);
      inc(TempLine);
    end;
  end;

  procedure FindLineOfs(Line : LongInt);
  var
    TempLine : LongInt;
    TempOfs : LongInt;
    FOfsIndex : Word;
    UntermLine : Boolean;
  begin
    FOfsIndex := Line-TopLineInFOfs+1;
    if FOfs[FOfsIndex] = Unknown then
      {need to fill in a file offset}
      if FirstKnownLine = Unknown then begin
        {don't know any offsets yet}
        FirstKnownLine := 1;
        FirstKnownOfs := 0;
        TempLine := 1;
        TempOfs := 0;
        SeekForward(Line, TempLine, TempOfs);
        FOfs[FofsIndex] := TempOfs;
        if TempOfs <> Unknown then begin
          FirstKnownLine := TempLine;
          FirstKnownOfs := TempOfs;
        end;
        LastKnownLine := FirstKnownLine;
        LastKnownOfs := FirstKnownOfs;

      end else if Line < FirstKnownLine then begin
        {seek backwards from first known}
        while (FirstKnownLine > Line) and (FirstKnownOfs <> Unknown) do begin {!!.2}
          FindPrevLineOfs(FirstKnownOfs, UntermLine);
          dec(FirstKnownLine);
        end;
        if FirstKnownOfs <> Unknown then  {!!.2}
          FOfs[FofsIndex] := FirstKnownOfs;

      end else if Line > LastKnownLine then begin
        {seek forwards from last known}
        TempLine := LastKnownLine;
        TempOfs := LastKnownOfs;
        SeekForward(Line, TempLine, TempOfs);
        FOfs[FofsIndex] := TempOfs;
        if TempOfs <> Unknown then begin
          LastKnownLine := TempLine;
          LastKnownOfs := TempOfs;
        end;

      end else begin
        {seek forwards from first known}
        TempLine := FirstKnownLine;
        TempOfs := FirstKnownOfs;
        SeekForward(Line, TempLine, TempOfs);
        FOfs[FofsIndex] := TempOfs;
      end;
  end;

  procedure FindAndDisplayRow(Row : Word; Line : LongInt);
  begin
    FindLineOfs(Line);
    DisplayLine(Row, Line);
  end;

  procedure DisplayPage(Top : LongInt);
  var
    Row : Word;
  begin
    UpdateOffsets(Top);
    for Row := YLow to YHigh do
      FindAndDisplayRow(Row, Top+Row-YLow);
  end;

  procedure DisplayPageDown(Top : LongInt);
  var
    Row : Word;
  begin
    UpdateOffsets(Top);
    for Row := YHigh downto YLow do
      FindAndDisplayRow(Row, Top+Row-YLow);
  end;

{$IFDEF UseOPRO}
  {$DEFINE UsePRO}
{$ENDIF}
{$IFDEF UseTPRO}
  {$DEFINE UsePRO}
{$ENDIF}

  procedure ScrollUp;
  var
    Row : Word;
    Width : Word;
{$IFNDEF UsePRO}
    Buf : array[1..MaxCols] of word;
{$ENDIF}
  begin
    Width := XHigh-XLow+1;

    {scoot existing contents down}
{$IFDEF UsePRO}
    for Row := YHigh-1 downto YLow do
      MoveScreen(mem[VideoSegment:2*((Row-1)*ScreenWidth+XLow-1)],
                 mem[VideoSegment:2*((Row)*ScreenWidth+XLow-1)],
                 Width);
{$ELSE}
    for Row := YHigh-1 downto YLow do begin
      MoveFromScreen(mem[VideoSegment:2*((Row-1)*ScreenWidth+XLow-1)],
                     Buf, Width);
      MoveToScreen(Buf, mem[VideoSegment:2*((Row)*ScreenWidth+XLow-1)],
                   Width);
    end;
{$ENDIF}

    UpdateOffsets(TopLine-1);
    FindAndDisplayRow(YLow, TopLine);
  end;

  procedure ScrollDown;
  var
    Row : Word;
    Width : Word;
{$IFNDEF UsePRO}
    Buf : array[1..MaxCols] of word;
{$ENDIF}
  begin
    {try to go a row down}
    inc(TopLine);
    UpdateOffsets(TopLine);
    FindLineOfs(TopLine+YHigh-YLow);
    if FOfs[TopLine+YHigh-YLow-TopLineInFOfs+1] = Unknown then begin
      {no more lines}
      dec(TopLine);
      exit;
    end;

    {scoot existing contents up}
    Width := XHigh-XLow+1;
{$IFDEF UsePRO}
    for Row := YLow+1 to YHigh do
      MoveScreen(mem[VideoSegment:2*((Row-1)*ScreenWidth+XLow-1)],
                 mem[VideoSegment:2*((Row-2)*ScreenWidth+XLow-1)],
                 Width);
{$ELSE}
    for Row := YLow+1 to YHigh do begin
      MoveFromScreen(mem[VideoSegment:2*((Row-1)*ScreenWidth+XLow-1)],
                     Buf, Width);
      MoveToScreen(Buf, mem[VideoSegment:2*((Row-2)*ScreenWidth+XLow-1)],
                   Width);
    end;
{$ENDIF}

    FindAndDisplayRow(YHigh, TopLine+YHigh-YLow);
  end;

  procedure PageDown;
  var
    Row : Word;
    SaveTopLine : LongInt; {!!.1}
  begin
    SaveTopLine := TopLine; {!!.1}

    {try to go a full window down}
    inc(TopLine, YHigh-YLow);
    UpdateOffsets(TopLine);
    for Row := YLow to YHigh do
      FindLineOfs(TopLine+Row-YLow);

    {back up until full screen display}
    Row := TopLine-TopLineInFOfs+1+YHigh-YLow;
    while Row > MaxRows do begin
      dec(Row);
      if (TopLine > 1) then
        dec(TopLine);
    end;
    while (Row > 1) and (FOfs[Row] = Unknown) do begin
      dec(Row);
      if (TopLine > 1) then
        dec(TopLine);
    end;

    if TopLine <> SaveTopLine then   {!!.1}
      DisplayPage(TopLine);
  end;

  procedure ClearFOfs;
  begin
    FillChar(FOfs, SizeOf(OfsArray), Byte(Unknown));
  end;

  procedure EndOfFile;
  var
    Line : LongInt;
    LenLine : Word;
    LenRead : Word;
    UntermLine : Boolean;
    S : String[MaxCols];
  begin
    if LastTopLine = Unknown then begin
      {scan file to end}
      Line := LastKnownLine;
      Seek(F, LastKnownOfs);
      repeat
        BlockRead(F, S[1], MaxCols, LenRead);
        if IoResult <> 0 then
          exit;
        if LenRead <> 0 then begin
{$IFDEF UseAsm}
          asm
            mov cx,LenRead
            cld
            mov al,13
            mov si,ss
            mov es,si
            lea di,S
            inc di
@1:         repne scasb
            jne @2
            add word ptr Line, 1
            adc word ptr Line+2, 0
            jcxz @2
            jmp @1
@2:
          end;
{$ELSE}
          S[0] := Char(LenRead);
          LenLine := 0;
          repeat
            while (LenLine < LenRead) and (S[LenLine+1] <> #13) do
              inc(LenLine);
            if LenLine <> LenRead then begin
              inc(Line);
              inc(LenLine); {skip CR}
            end;
          until LenLine = LenRead;
{$ENDIF}
        end;
      until LenRead = 0;

      LastTopLine := Line-(YHigh-YLow);
      if LastTopLine < 1 then
        LastTopLine := 1;
    end;

    if TopLine <> LastTopLine then begin
      LastKnownLine := LastTopLine+(YHigh-YLow);
      LastKnownOfs := LastOfs;
      FindPrevLineOfs(LastKnownOfs, UntermLine);
      if not UntermLine then
        dec(LastKnownLine);
      ClearFOfs;
      TopLineInFOfs := LastKnownLine;
      FOfs[1] := LastKnownOfs;
      DisplayPageDown(LastTopLine);
      FindKnownOfs;
    end;
  end;

begin
  {validate coordinates}
  if (YHigh < YLow) or (XHigh < XLow) or
  (YHigh-YLow > MaxRows-1) or (XHigh-XLow > MaxCols-1) then begin
    BrowseFile := 106;
    exit;
  end;

  {open file read-only}
  SaveMode := FileMode;
  FileMode := 0;
  Assign(F, FName);
  Reset(F, 1);
  FileMode := SaveMode;
  Status := IoResult;
  if Status <> 0 then begin
    BrowseFile := Status;
    exit;
  end;
  LastOfs := FileSize(F);
  Status := IoResult;
  if Status <> 0 then begin
    BrowseFile := Status;
    Close(F);
    Status := IoResult;
    exit;
  end;

  {turn off break checking}
  SaveCheck := CheckBreak;
  CheckBreak := False;

  {initialize and display first page}
  ClearFOfs;
  TopLineInFOfs := 1;
  LastTopLine := Unknown;
  FirstKnownLine := 1;              {!!.2}
  FirstKnownOfs := 0;               {!!.2}
  LastKnownLine := 1;               {!!.2}
  LastKnownOfs := 0;                {!!.2}
  if TopLine = -1 then              {!!.2}
    {display end of file initially} {!!.2}
    EndOfFile                       {!!.2}
  else                              {!!.2}
    DisplayPage(TopLine);

  {react to keystrokes}
  Done := False;
  repeat
    if @StatusP <> nil then
      StatusP(TopLine, FOfs[TopLine-TopLineInFOfs+1], LastOfs,
              LeftOfs, StatusData);

    Ch := ReadKeyF;
    if Ch > #$80 then
      {avoid conflicts with international keys}
      Ch := #0
    else if Ch = #0 then
      Ch := Char(Byte(ReadKeyF) or $80);

    if Ch in ExitChars then begin
      Done := True;
      ExitKey := Ch;

    end else
      case Byte(Ch) of
        $C8, $05, $17 : {Up, ^E, ^W}
          if TopLine > 1 then
            ScrollUp;

        $D0, $18, $1A : {Down, ^X, ^Z}
          ScrollDown;

        $C9, $12 : {PgUp, ^R}
          if TopLine > YHigh-YLow then
            DisplayPageDown(TopLine-YHigh+YLow)
          else
            DisplayPageDown(1);

        $D1, $03 : {PgDn, ^C}
          PageDown;

        $F7, $84 :  {^Home, ^PgUp}
          if TopLine > 1 then
            DisplayPage(1);

        $F5, $F6 :  {^End, ^PgDn}
          EndOfFile;

        $CB, $13 : {Left, ^S}
          if LeftOfs > 0 then begin
            dec(LeftOfs);
            DisplayPage(TopLine);
          end;

        $CD, $04 : {Right, ^D}
          if LeftOfs < MaxCols-(XHigh-XLow) then begin
            inc(LeftOfs);
            DisplayPage(TopLine);
          end;

        $C7 : {Home}
          if LeftOfs <> 0 then begin
            LeftOfs := 0;
            DisplayPage(TopLine);
          end;

        $CF : {End}
          if LeftOfs <> MaxCols-(XHigh-XLow) then begin
            LeftOfs := MaxCols-(XHigh-XLow);
            DisplayPage(TopLine);
          end;
      end;
  until Done;

  CheckBreak := SaveCheck;

  Close(F);
  Status := IoResult;
  BrowseFile := 0;
end;

end.
