{$R-,S-,A+,F-,I-,V-,B-,G+}

{******************************************************}
{*                  FSMISC.PAS  2.03                  *}
{*    Copyright (c) TurboPower Software 1993-94.      *}
{*                All rights reserved.                *}
{******************************************************}

{$I APDEFINE.INC}

unit FsMisc;
  {-Assorted utility routines for fax server}

interface

uses
  Dos,
  Dpmi,
  {$IFDEF UseOpro}
  OpCrt,
  OpDate,
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTpro}
  TpCrt,
  TpDate,
  TpMemChk,
  TpString,
  {$ENDIF}
  {$IFDEF StandAlone}
  Crt,
  {$ENDIF}
  FastW1,
  {$IFDEF UsePModeDLL}                                                 {!!.02}
  ApComD,                                                              {!!.02}
  ApFaxD;                                                              {!!.02}
  {$ELSE}                                                              {!!.02}
  ApTimer,                                                             {!!.02}
  ApMisc;                                                              {!!.02}
  {$ENDIF}                                                             {!!.02}

type
  {General pointer for screen saves - dynamically allocated}
  BufPtr           = ^BufferArray;
  BufferArray      = array[0..MaxInt] of Char;
  TBrowseCharSet   = set of char;

const
  {For Shell-to-DOS option}
  MinSpaceForDos   : Word = 20000;     {Minimum bytes for DOS shell to run}

function ReadKeyTimeOut(Timeout : Word; Default : Char) : Char;
  {-Wait for a keypress no longer than Timeout seconds. Return
    the pressed character or the Default character}
procedure ClearKeyboardBuffer;
  {-Clear pending key presses}
function SaveScreen(XLow, YLow, XHigh, YHigh : Byte) : Pointer;
  {-Save a screen region}
procedure RestoreScreen(P : Pointer; XLow, YLow, XHigh, YHigh : Byte);
  {-Restore a previously saved screen region}
function GetPackedTime : LongInt;
  {-Return a packed time LongInt}
function DateString(DT : DateTime) : string;
  {-Return date in a "MM/DD/YY" format}
function TimeString(DT : DateTime) : string;
  {-Return the time as a "HH:MMpm" string}
function JustName(PathName : string) : string;
  {-Return just the name (no extension, no path) of a pathname}
function Time24String : string;
  {-Return the current time in 24 hour format as a string}
procedure Tone(Freq,Duration : Word);
  {-Generate a tone with "Freq" frequency for "Duration" ms}
procedure Ring;
  {-Make a ring sound}
function Long2Str(L : LongInt) : string;
  {-Convert a byte, integer, word, or longint to a string}
function Pad(S : string; Size : Byte) : string;
  {-Right pad S with spaces to "Size" length}
function ShellToDos : Integer;
  {-Shell out to a dos session}
procedure BuildWindow(XLow, YLow, XHigh, YHigh : Byte;
                      Header : String; Attr : Byte);
  {-Construct the status window}
function AddTime(PDT : LongInt; Secs : LongInt) : LongInt;
  {-Increase/decrease the PDT packed time variable by Secs}
procedure CopyFile(Src, Dest : PathStr; Buf : Pointer; BufSize : Word);
  {-Copy the file specified by SrcPath into DestPath}

implementation


function ReadKeyTimeOut(Timeout : Word; Default : Char) : Char;
  {-Wait for a keypress no longer than Timeout seconds. Return
    the pressed character or the Default character}
var
  ET      : EventTimer;
begin
  NewTimerSecs(ET, Timeout);
  repeat until KeyPressed or TimerExpired(ET);
  if KeyPressed then
    ReadKeyTimeout := ReadKey
  else
    ReadKeyTimeout := Default;  {Default if timer expired}
end;

procedure ClearKeyboardBuffer;
  {-Clear pending key presses}
var
  Ch : Char;
begin
  while KeyPressed do Ch := ReadKey;
end;

function SaveScreen(XLow, YLow, XHigh, YHigh : Byte) : Pointer;
  {-Save a screen region}
var
  CoversP : BufPtr;
  WordsPerRow : Word;
  BufBytes : Word;
  SrcPos : Word;
  DestPos : Word;
  Row : Word;
begin
  SaveScreen := nil;

  {Compute number of words to move per row}
  WordsPerRow := Succ(XHigh-XLow);

  {Compute bytes needed for screen buffer}
  BufBytes := (WordsPerRow*Succ(YHigh-YLow)) shl 1;

  {Make sure enough memory is available}
  if not GetMemCheck(CoversP, BufBytes) then
    Exit;

  {Save current contents to the screen buffer}
  DestPos := 0;
  SrcPos := (Pred(YLow)*ScreenWidth+Pred(XLow)) shl 1;
  for Row := YLow to YHigh do begin
    MoveFromScreen(Mem[VideoSegment:SrcPos], CoversP^[DestPos], WordsPerRow);
    Inc(SrcPos, ScreenWidth shl 1);
    Inc(DestPos, WordsPerRow shl 1);
  end;

  SaveScreen := CoversP;
end;

procedure RestoreScreen(P : Pointer; XLow, YLow, XHigh, YHigh : Byte);
  {-Restore a previously saved screen region}
var
  CoversP : BufPtr absolute P;
  WordsPerRow : Word;
  SrcPos : Word;
  DestPos : Word;
  Row : Word;
begin
  {Compute number of words to move per row}
  WordsPerRow := Succ(XHigh-XLow);

  {Restore current contents to the screen buffer}
  DestPos := 0;
  SrcPos := (Pred(YLow)*ScreenWidth+Pred(XLow)) shl 1;
  for Row := YLow to YHigh do begin
    MoveToScreen(CoversP^[DestPos], Mem[VideoSegment:SrcPos], WordsPerRow);
    Inc(SrcPos, ScreenWidth shl 1);
    Inc(DestPos, WordsPerRow shl 1);
  end;

  {Deallocate buffer space}
  FreeMemCheck(CoversP, (WordsPerRow*Succ(YHigh-YLow)) shl 1);
end;

function GetPackedTime : LongInt;
  {-Return a packed time LongInt}
var
  H, M, S, HS : Word;
begin
  GetTime(H, M, S, HS);
  GetPackedTime := H*60*60 + M*60 + S;
end;

function DateString(DT : DateTime) : string;
  {-Return date in a "MM/DD/YY" format}
var
  S, T : String[12];
begin
  with DT do begin
    {convert the month}
    Str(Month:2, S);
    if S[1] = ' ' then
      S[1] := '0';
    T := S + '/';

    {convert the day}
    Str(Day:2, S);
    if S[1] = ' ' then
      S[1] := '0';
    T := T + S;
    T := T + '/';

    {convert the year}
    Year := Year mod 100;  {strip the "19"}
    Str(Year:2, S);
    if S[1] = ' ' then
      S[1] := '0';
    T := T + S;

    DateString := T;
  end;
end;

function TimeString(DT : DateTime) : string;
  {-Return the time as a "HH:MMpm" string}
var
  S, T : String[12];
  PM : Boolean;
begin
  with DT do begin
    {correct for AM/PM}
    PM := ((Hour >= 12) and (Hour < 24));
    if Hour > 12 then
      Dec(Hour, 12);

    {convert the hours}
    Str(Hour, S);
    if Length(S) = 1 then
      S := '0' + S;
    T := S + ':';

    {convert the minutes}
    Str(Min:2, S);
    if S[1] = ' ' then
      S[1] := '0';
    T := T + S;

    {add the AM/PM indicator}
    if PM then
      T := T + 'pm'
    else
      T := T + 'am';

    TimeString := T;
  end;
end;

function JustName(PathName : string) : string;
  {-Return just the name (no extension, no path) of a pathname}
var
  DotPos : Byte;
begin
  PathName := JustFileName(PathName);
  DotPos := Pos('.', PathName);
  if DotPos > 0 then
    PathName := Copy(PathName, 1, DotPos-1);
  JustName := PathName;
end;

function Time24String : string;
  {-Return the current time in 24 hour format as a string}
var
  Hour, Min, Sec, Sec100 : Word;
  H, M : String[12];
begin
  {get the system time}
  GetTime(Hour, Min, Sec, Sec100);

  {convert the hours}
  Str(Hour:2, H);
  if H[1] = ' ' then
    H[1] := '0';

  {convert the minutes}
  Str(Min:2, M);
  if M[1] = ' ' then
    M[1] := '0';

  Time24String := H + ':' + M;
end;

procedure Tone(Freq,Duration : Word);
  {-Generate a tone with "Freq" frequency for "Duration" ms}
begin
  Sound(Freq);
  Delay(Duration);
  NoSound;
end;

procedure Ring;
  {-Make a ring sound}
begin
  Tone(880,50);
  Tone(110,100);
  Tone(440,50);
end;

function Long2Str(L : LongInt) : string;
  {-Convert a byte, integer, word, or longint to a string}
var
  S : string;
begin
  Str(L, S);
  Long2Str := S;
end;

function Pad(S : string; Size : Byte) : string;
  {-Right pad S with spaces to "Size" length}
var
  Len  : Byte absolute S;
begin
  if Len < Size then begin
    FillChar(S[Len+1], Size-Len, ' ');
    S[0] := Char(Size);
  end;
  Pad := S;
end;

function ShellToDos : Integer;
  {-ShellToDos return codes are as follows:
         0 : Success
        -1 : Insufficient memory to store free list
        -2 : DOS setblock error before EXEC call
        -3 : DOS setblock error after EXEC call  -- critical error!
        -4 : Insufficient memory to run DOS command
      else   a DOS error code
  }
type
  OS = record
     O, S : Word;
  end;
var
  {Variables for saving and restoring state of system}
  OurInt23 : Pointer;
  OurInt24 : Pointer;
  SaveDta  : Pointer;

  {Variables for managing the heap compression}
  ParasWeHave : Word;
  ParasForDos : Word;
  ParasToKeep : Word;
  OldHeapEnd  : Pointer;
  Regs        : Registers;

  function SetBlock(var Paragraphs : Word) : Boolean;
    {-Change size of DOS memory block allocated to this program}
  begin
    with Regs do begin
      AH := $4A;
      ES := PrefixSeg;
      BX := Paragraphs;
      MsDos(Regs);
      Paragraphs := BX;
      SetBlock := not Odd(Flags);
    end;
  end;

  procedure GetDta(var DTAptr : Pointer);
    {-Return the DOS DTA pointer}
  begin
    with Regs do begin
      AH := $2F;
      MsDos(Regs);
      DTAptr := Ptr(ES, BX);
    end;
  end;

  procedure SetDta(DTAptr : Pointer);
    {-Set the DOS DTA to point to DTA}
  {$IFDEF DPMI}
  var
    Regs : DpmiRegisters;
  begin
    FillChar(Regs, SizeOf(DpmiRegisters), 0);
    with Regs do begin
      AX := $1A00;
      DS := OS(DTAptr).S;
      DX := OS(DTAptr).O;
      if SimulateRealModeInt($21, Regs) <> 0 then ;
    end;
  end;
  {$ELSE}
  begin
    with Regs do begin
      AH := $1A;
      DS := OS(DTAptr).S;
      DX := OS(DTAptr).O;
      MsDos(Regs);
    end;
  end;
  {$ENDIF}

  function PtrDiff(H, L : Pointer) : LongInt;
    {-Return the number of bytes between H^ and L^. H is the higher address}
  var
    High : OS absolute H;
    Low  : OS absolute L;
  begin
    PtrDiff := (LongInt(High.S) shl 4+High.O)-(LongInt(Low.S) shl 4+Low.O);
  end;

begin
  {Current DOS memory allocation read from memory control block}
{$IFNDEF DPMI}  {no heap compression needed in protected mode}
  ParasWeHave := MemW[Pred(PrefixSeg):3];

  {Calculate amount of memory to give up}
  ParasForDos := Pred(PtrDiff(HeapEnd, HeapPtr) shr 4);

  {Calculate amount of memory to keep while in shell}
  ParasToKeep := ParasWeHave-ParasForDos;

  {See if enough memory to run DOS}
  if (ParasForDos > 0) and (ParasForDos < (MinSpaceForDos shr 4)) then begin
    ShellToDos := -4;
    Exit;
  end;

  {Deallocate memory for DOS}
  if not SetBlock(ParasToKeep) then begin
    ShellToDos := -2;
    Exit;
  end;

  {Save old end of heap and set new one}
  OldHeapEnd := HeapEnd;
  HeapEnd := HeapPtr;
{$ENDIF}

  {Get current DTA}
  GetDta(SaveDta);

  {Switch vectors}
  SwapVectors;

  {Call Turbo's EXEC function}
  Exec(GetEnv('COMSPEC'), '');
{$IFDEF DPMI}

  {accomodate known problem with RTM using 386^Max as DPMI server}
  if DosError = $4B00 then
    DosError := 0;
{$ENDIF}

  {Restore vectors}
  SwapVectors;

  {Restore DTA}
  SetDta(SaveDta);

{$IFNDEF DPMI}
  {Reallocate memory from DOS}
  if not SetBlock(ParasWeHave) then begin
    ShellToDos := -3;
    Exit;
  end;

  {Put heap end back where it was}
  HeapEnd := OldHeapEnd;
{$ENDIF}

  {If we get to here, our function result is in DosError}
  ShellToDos := DosError;
end;

procedure BuildWindow(XLow, YLow, XHigh, YHigh : Byte;
                      Header : String; Attr : Byte);
  {-Construct the status window}
type
  FrameCharType = (ULeft, LLeft, URight, LRight, Horiz, Vert);
  FrameArray = array[FrameCharType] of Char;
const
  FrameChars : FrameArray = 'ÕÔ¸¾Í³';
var
  Row : Word;
  HeaderLen : Byte absolute Header;
  Width, HeaderPos : Byte;
  Span : string[132];
  SpanLen : Byte absolute Span;

begin
  {Calculate width of window and position of header}
  SpanLen := Succ(XHigh - XLow);
  Width := SpanLen-2;

  {construct the upper border and draw it}
  FillChar(Span[2], Width, FrameChars[Horiz]);
  Span[1] := FrameChars[ULeft];
  Span[SpanLen] := FrameChars[URight];
  FastWrite(Span, YLow, XLow, Attr);

  {Draw the vertical bars}
  for Row := Succ(YLow) to Pred(YHigh) do begin
    FastWrite(FrameChars[Vert], Row, XLow, Attr);
    FastWrite(FrameChars[Vert], Row, XHigh, Attr);
  end;

  {Draw the bottom border}
  Span[1] := FrameChars[LLeft];
  Span[SpanLen] := FrameChars[LRight];
  FastWrite(Span, YHigh, XLow, Attr);

  {Draw the header}
  if HeaderLen > 0 then begin
    if HeaderLen > Width then
      HeaderLen := Width;
    HeaderPos := (SpanLen-HeaderLen) shr 1;
    FastWrite(Header, YLow, XLow + HeaderPos, Attr);
  end;

  {Clear the window}
  FillChar(Span[1], Pred(XHigh-XLow), ' ');
  Span[0] := Char(Pred(XHigh-XLow));
  for Row := Ylow+1 to YHigh-1 do
    FastWrite(Span, Row, XLow+1, Attr);
end;

function AddTime(PDT : LongInt; Secs : LongInt) : LongInt;
  {-Increase/decrease the PDT packed time variable by Secs}
var
  I    : LongInt;
  DT   : DateTime;
  DTR  : DateTimeRec;
  D    : Date;
  T    : Time;
  Ho, Mi, Se : Byte;
  Da, Mo, Ye : Integer;
begin
  UnpackTime(PDT, DT);
  D := DMYToDate(DT.Day, DT.Month, DT.Year);
  T := HMSToTime(DT.Hour, DT.Min, DT.Sec);
  DTR.D := D;
  DTR.T := T;
  IncDateTime(DTR, DTR, 0, Secs);
  DateToDMY(DTR.D, Da, Mo, Ye);
  TimeToHMS(DTR.T, Ho, Mi, Se);
  DT.Day := Da; DT.Month := Mo; DT.Year := Ye;
  DT.Hour := Ho; DT.Min := Mi; DT.Sec := Se;
  PackTime(DT, I);
  AddTime := I;
end;

procedure CopyFile(Src, Dest : PathStr; Buf : Pointer; BufSize : Word);
  {-Copy the file specified by Src into Dest}
var
  ErrorCode,
  BytesRead,
  BytesWritten : Word;
  FSrc,
  FDest        : File;
  SaveFileMode : Word;

  procedure UnDo(DeleteDest : Boolean);
  begin
    Close(FSrc);
    if IoResult <> 0 then ;
    if DeleteDest then begin
      Close(FDest);
      if IoResult <> 0 then ;
      Erase(FDest);
      if IoResult <> 0 then ;
    end;
  end;

begin
  {clear any pending IO error}
  if IoResult <> 0 then {};
  SaveFileMode := FileMode;
  Assign(FSrc,Src);
  FileMode := FileMode and $F0;
  Reset(FSrc,1);
  FileMode := SaveFileMode;
  SetAsyncStatus(IoResult);                                            {!!.02}
  if GetAsyncStatus <> ecOk then Exit;                                 {!!.02}
  Assign(FDest,Dest);
  Rewrite(FDest,1);
  SetAsyncStatus(IoResult);                                            {!!.02}
  if GetAsyncStatus <> ecOk then begin                                 {!!.02}
    Undo(False);
    Exit;
  end;
  while not EOF(FSrc) do begin
    BlockRead(FSrc, Buf^, BufSize, BytesRead);
    SetAsyncStatus(IoResult);                                          {!!.02}
    if GetAsyncStatus <> ecOk then begin                               {!!.02}
      UnDo(True);
      Exit;
    end;
    BlockWrite(FDest,Buf^,BytesRead,BytesWritten);
    SetAsyncStatus(IoResult);                                          {!!.02}
    if (GetAsyncStatus <> ecOk) or (BytesWritten <> BytesRead) then begin {!!.02}
      if GetAsyncStatus = ecOk then                                    {!!.02}
        SetAsyncStatus(ecDiskRead);                                    {!!.02}
      UnDo(True);
      Exit;
    end;
  end;
  Close(FDest);
  SetAsyncStatus(IoResult);                                            {!!.02}
  Close(FSrc);
  if GetAsyncStatus = ecOk then                                        {!!.02}
    SetAsyncStatus(IoResult);                                          {!!.02}
end;

end.
