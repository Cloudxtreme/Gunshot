{$S-,R-,V-,I-,B-,F-,A-}
{$M 16384, 0, 655360}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{$IFNDEF UseUart}                                                      {!!.02}
  STOP COMPILE - This program requires UseUart                         {!!.02}
{$ENDIF}                                                               {!!.02}

{.$DEFINE Test8KZmodem}       {Define this to test 8K zmodem}           {!!.01}

{*********************************************************}
{*                     FX.PAS 2.03                       *}
{*     Copyright (c) TurboPower Software 1991.           *}
{*                 All rights reserved.                  *}
{*********************************************************}

program FX;
  {-File transfer demonstration}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Crt,
  Dos,
  FastW1,
  {$IFDEF UseOPro}
  OpRoot,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpMemChk,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApProtD;
  {$ELSE}
  ApMisc,
  ApTimer,
  ApPort,
  ApUart,
  ApCom,
  ApAbsPcl,
  ApXmodem,
  ApYmodem,
  ApZmodem,
  ApKermit,
  ApAscii,
  ApBPlus;
  {$ENDIF}

const
  Version = 'FX Copyright(c) TurboPower Software. Version 2.03';

  {Number of entries to keep in the trace queue}
  TraceEntries = 10000;

  {Determines whether port is opened normal or with "keep"}
  BaudSpecified : Boolean = False;

  {Determines if background process is demonstrated}
  BackgroundDemo : Boolean = False;

  WAttr : Byte = $1B;          {Window attribute}
  FAttr : Byte = $1E;          {Frame attribute}
  DAttr : Byte = $1F;          {Data attribute}

type
  BufPtr = ^BufferArray;
  BufferArray = array[0..MaxInt] of Char;
  TransferModeType = (Transmit, Receive);

var
  SrcFile : File;
  SrcFileName : String;
  ComX : ComNameType;
  Baud : LongInt;
  ComPort : PortRecPtr;
  Finished : Boolean;
  Protocol : Byte;
  AP, XM, YM, ZM, KM, BP : ProtocolRecPtr;
  TransferMode : TransferModeType;
  ResumeFile : Boolean;
  ClobberFile : Boolean;
  NewerLonger : Boolean;
  SaveExit : Pointer;
  OpenStatus : Word;
  BW : Pointer;
  ForceAbort : Boolean;
  SkipNoFile : Boolean;

  {$F+}
  procedure FxExitProc;
  begin
    ExitProc := SaveExit;

    {$IFDEF Tracing}
    {Save the trace to FX.TRC}
    DumpTrace('FX.TRC');
    {$ENDIF}
  end;
  {$F-}

  procedure Abort(Msg : String; Code : Word);
  begin
    if ComPort <> Nil then
      DonePort(ComPort);
    Write(Msg);
    if Code <> 0 then
      WriteLn(Code)
    else
      WriteLn;
    Halt(Code);
  end;

  function Pad(S : string; Len : Byte) : string;
    {-Return a string right-padded to length len with ch}
  var
    o : string;
    SLen : Byte absolute S;
  begin
    if Length(S) >= Len then
      Pad := S
    else begin
      o[0] := Chr(Len);
      Move(S[1], o[1], SLen);
      if SLen < 255 then
        FillChar(o[Succ(SLen)], Len-SLen, ' ');
      Pad := o;
    end;
  end;

  function StUpcase(S : String) : String;
  var
    I : Byte;
  begin
    for I := 1 to Length(S) do
      S[I] := Upcase(S[I]);
    StUpcase := S;
  end;

  function CharStr(Ch : Char; Len : Byte) : string;
    {-Return a string of length len filled with ch}
  var
    S : string;
  begin
    if Len = 0 then
      CharStr[0] := #0
    else begin
      S[0] := Chr(Len);
      FillChar(S[1], Len, Ch);
      CharStr := S;
    end;
  end;

  function Long2Str(L : LongInt) : string;
    {-Convert a long/word/integer/byte/shortint to a string}
  var
    S : string;
  begin
    Str(L, S);
    Long2Str := S;
  end;

  function Long2StrBlank(L : LongInt) : string;
    {-Convert a long/word/integer/byte/shortint to a string}
  begin
    if L = 0 then
      Long2StrBlank := ''
    else
      Long2StrBlank := Long2Str(L);
  end;

  function Real2Str(R : Real; Width : Byte; Places : ShortInt) : string;
    {-Convert a real to a string}
  var
    S : string;
  begin
    Str(R:Width:Places, S);
    Real2Str := S;
  end;

  function LeftPad(S : string; Len : Byte) : string;
    {-Return a string left-padded to length len}
  var
    o : string;
    SLen : Byte absolute S;
  begin
    if Length(S) >= Len then
      LeftPad := S
    else if SLen < 255 then begin
      o[0] := Chr(Len);
      Move(S[1], o[Succ(Word(Len))-SLen], SLen);
      FillChar(o[1], Len-SLen, ' ');
      LeftPad := o;
    end;
  end;

  procedure WriteHelp;
    {-Write help and halt}
  begin
    WriteLn('Usage: FX [options] SrcFilename');
    WriteLn('  /B BaudRate  Baudrate');
    WriteLn('  /C #         Comport name  [default = 1]');
    WriteLn('  /T           Transmit mode [default]');
    WriteLn('  /R           Receive mode');
    WriteLn('  /S           ASCII transfer');
    WriteLn('  /X           Xmodem/XmodemCRC [default]');
    WriteLn('  /K           Xmodem1K');
    WriteLn('  /L           Xmodem1KG');
    WriteLn('  /Y           Ymodem');
    WriteLn('  /G           YmodemG');
    WriteLn('  /Z           Zmodem');
    WriteLn('  /F           Kermit');
    WriteLn('  /P           BPlus');
    WriteLn('  /A           Zmodem option - resume interrupted transfer');
    WriteLn('  /O           Zmodem option - always overwrite files');
    WriteLn('  /N           Zmodem option - only overwrite if newer');
    WriteLn('  /D           Demonstration of background process');
    Halt;
  end;

  procedure ParseCommandLine;
    {-Gets command line options and sets various parameters.}
  var
    Code : Word;
    Param : String;
    Cnt : Word;
    ComNum : Word;

  begin
    {Set defaults}
    ComX := Com1;
    Baud := 1200;
    TransferMode := Transmit;
    Protocol := Xmodem;
    SrcFilename := '';
    ResumeFile := False;
    ClobberFile := False;
    NewerLonger := False;
    SkipNoFile := False;

    {Scan command line}
    if ParamCount = 0 then
      WriteHelp;
    Param := ParamStr(1);
    Cnt := 2;

    while True do begin
      case Param[1] of
        '/', '-' :
          if Length(Param) <> 2 then
            Abort('Invalid parameter: '+Param, 1)
          else
            case Upcase(Param[2]) of

              'B' : {Set baud rate}
                begin
                  BaudSpecified := True;
                  Param := ParamStr(Cnt);
                  Inc(Cnt);
                  Val(Param, Baud, Code);
                  if Code <> 0 then
                    Abort('Invalid baud rate: '+Param, 1);
                end;

              'C' : {Set Com port}
                begin
                  Param := ParamStr(Cnt);
                  Inc(Cnt);
                  Val(Param, ComNum, Code);
                  if Code <> 0 then
                    Abort('Invalid com port: '+Param, 1);
                  ComX := ComNameType(ComNum-1);
                end;

              'T' : TransferMode := Transmit;
              'R' : TransferMode := Receive;

              'S' : Protocol := Ascii;
              'X' : Protocol := Xmodem;
              'K' : Protocol := Xmodem1K;
              'L' : Protocol := Xmodem1KG;
              'Y' : Protocol := Ymodem;
              'G' : Protocol := YmodemG;
              'Z' : Protocol := Zmodem;
              'F' : Protocol := Kermit;
              'P' : Protocol := BPlus;

              'A' : ResumeFile := True;
              'O' : ClobberFile := True;
              'N' : NewerLonger := True;
              'I' : SkipNoFile := True;

              'D' : BackgroundDemo := True;

              '?' : {Request for help}
                WriteHelp;

            else
              Abort('Invalid parameter: '+Param, 1);
            end;
      else
        SrcFileName := Param;
      end;

      {Get next parameter}
      if Cnt > ParamCount then begin
        if (SrcFilename = '') and
           not ((TransferMode = Receive) and
                ((Protocol = Ymodem) or
                (Protocol = YmodemG) or
                (Protocol = Kermit) or
                (Protocol = Zmodem) or
                (Protocol = BPlus))) then
          WriteHelp;
        Exit;
      end;
      Param := ParamStr(Cnt);
      Inc(Cnt);
    end;
  end;

  function BuildWindow(XLow, YLow, XHigh, YHigh : Byte; Header : String) : Pointer;
    {-Saves the underlying screen, frames and clears a window}
  type
    FrameCharType = (ULeft, LLeft, URight, LRight, Horiz, Vert);
    FrameArray = array[FrameCharType] of Char;
  const
    FrameChars : FrameArray = '略맘固';
  var
    CoversP : BufPtr;
    WordsPerRow : Word;
    BufBytes : Word;
    SrcPos : Word;
    DestPos : Word;
    Row : Word;
    HeaderLen : Byte absolute Header;
    Width, HeaderPos : Byte;
    Span : string[132];
    SpanLen : Byte absolute Span;

  begin
    BuildWindow := nil;

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

    {Calculate width of window and position of header}
    SpanLen := Succ(XHigh - XLow);
    Width := SpanLen-2;

    {construct the upper border and draw it}
    FillChar(Span[2], Width, FrameChars[Horiz]);
    Span[1] := FrameChars[ULeft];
    Span[SpanLen] := FrameChars[URight];
    FastWrite(Span, YLow, XLow, FAttr);

    {Draw the vertical bars}
    for Row := Succ(YLow) to Pred(YHigh) do begin
      FastWrite(FrameChars[Vert], Row, XLow, FAttr);
      FastWrite(FrameChars[Vert], Row, XHigh, FAttr);
    end;

    {Draw the bottom border}
    Span[1] := FrameChars[LLeft];
    Span[SpanLen] := FrameChars[LRight];
    FastWrite(Span, YHigh, XLow, FAttr);

    {Draw the header}
    if HeaderLen > 0 then begin
      if HeaderLen > Width then
        HeaderLen := Width;
      HeaderPos := (SpanLen-HeaderLen) shr 1;
      FastWrite(Header, YLow, XLow + HeaderPos, FAttr);
    end;

    {Fill in the window}
    for Row := Ylow+1 to YHigh-1 do
      FastWrite(CharStr(' ', Pred(XHigh-XLow)), Row, XLow+1, FAttr);

    BuildWindow := CoversP;
  end;

  procedure RemoveWindow(P : Pointer; XLow, YLow, XHigh, YHigh : Byte);
    {-Restore screen contents and deallocate buffer space if requested}
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

  function FormatMinSec(TotalSecs : LongInt) : String;
    {-Format TotalSecs as minutes:seconds}
  var
    Min, Sec : LongInt;
    S : String;
  begin
    Min := TotalSecs div 60;
    Sec := TotalSecs mod 60;
    Str(Sec:2, S);
    if S[1] = ' ' then
      S[1] := '0';
    FormatMinSec := LeftPad(Long2Str(Min) + ':' + S, 6);               {!!.01}
  end;

  procedure UpdateProgressBar(Row, Col, Len : Byte; Percent : Real);
    {-Fills in a progress bar with Percent complete}
  const
    CompleteChar = '�';
  var
    CharPercent : Real;
    CharCount : Byte;
    BarStr : String;
  begin
    {Calculate "percent value" of each character space}
    CharPercent := 100.0 / Len;

    {Calculate how many chars we need to approach (but not exceed) Percent}
    CharCount := Trunc((Percent * 100) / CharPercent);

    {Make sure we don't go past Len}
    if CharCount > Len then
      CharCount := Len;

    {Write out the complete bar}
    FillChar(BarStr[1], CharCount, CompleteChar);
    BarStr[0] := Char(CharCount);
    if CharCount <> 0 then
      FastWrite(BarStr, Row, Col, DAttr);
  end;

  procedure UpdateStatusMsg(Row, Col, Len : Byte);
    {-Translate the current AsyncStatus into a status message}
  const
    LastStatus : Word = 65535;
    MaxMsgLen = 40;
  var
    Msg : String;
  begin
    if GetAsyncStatus <> LastStatus then begin
      FillChar(Msg[1], MaxMsgLen, ' ');
      Msg[0] := Char(MaxMsgLen);
      FastWrite(Msg, Row, Col, DAttr);
      Msg := StatusStr(GetAsyncStatus mod 10000);
      FastWrite(Msg, Row, Col, DAttr);
    end;
  end;

  {$F+}
  procedure BackgroundDemoWindow(P : ProtocolRecPtr);
    {-Demonstration of background hook}
  var
    Cnt : Word;
    C : Char;
  begin
    Cnt := 0;
    while KeyPressed and (Cnt < 10) do begin
      C := ReadKey;
      if C = #27 then
        {User requested protocol abort...}
        ForceAbort := True
      else
        {Just display this character}
        Write(C);
    end;
  end;
  {$F-}

  {$F+}
  procedure WindowStatus(P : ProtocolRecPtr;
                         Starting, Ending : Boolean);
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Windowed show status procedure}
  const
    XLow = 10;
    YLow = 3;
    XHigh = 69;
    YHigh = 21;
    W : Pointer = nil;
    DividerBar = '쳐컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴캑';
    NewProgBar = '같같같같같같같같같같같같같같같같같같같같';
    HeaderStr : array[TransferModeType] of String[19] =
      (' Protocol Upload ', ' Protocol Download ');
    ModeStr : array[TransferModeType] of String[9] =
      ('sent:', 'received:');
    OnOffStr : array[Boolean] of String[3] = ('Off', 'On ');
    LastBytesTransferred : LongInt = 0;
  var
    Blocks : Integer;
    Efficiency, MaxCPS, ActualCPS, R : Real;
    CurBlockSize : Word;
    CurFileSize : LongInt;
    CurBytesRemaining : LongInt;
    CurBytesTransferred : LongInt;
    CurProtocol : Byte;
    CurElapsedTics : LongInt;
    CurBlock : Word;
    S : String;
    I : Word;
    B : Boolean;
    Size : Byte;
  begin
    if Starting then begin
      {Build and frame the window}
      W := BuildWindow(XLow, YLow, XHigh, YHigh, HeaderStr[TransferMode]);
      if W = nil then
        Abort('Insufficient memory ', 1);

      {Write out the fixed text strings}
      FastWrite('Protocol:', YLow+1, XLow+2, WAttr);
      FastWrite('Block check:', YLow+2, XLow+2, WAttr);
      FastWrite('File name:', YLow+3, XLow+2, WAttr);
      FastWrite('File size:', YLow+4, XLow+2, WAttr);
      FastWrite('Block size:', YLow+5, XLow+2, WAttr);
      FastWrite('Total blocks:', YLow+6, XLow+2, WAttr);

      FastWrite('Est. time:', YLow+8, XLow+2, WAttr);
      FastWrite('Elapsed time:', YLow+9, XLow+2, WAttr);
      FastWrite('Remaining time:', YLow+10, XLow+2, WAttr);

      FastWrite('Bytes '+ModeStr[TransferMode], YLow+1, XLow+33, WAttr);
      FastWrite('Bytes remaining:', YLow+2, XLow+33, WAttr);
      FastWrite('Blocks '+ModeStr[TransferMode], YLow+3, XLow+33, WAttr);
      FastWrite('Blocks remaining:', YLow+4, XLow+33, WAttr);
      FastWrite('Block errors:', YLow+5, XLow+33, WAttr);
      FastWrite('Total errors:', YLow+6, XLow+33, WAttr);

      FastWrite('Throughput:', YLow+8, XLow+33, WAttr);
      FastWrite('Efficiency:', YLow+9, XLow+33, WAttr);

      {If Kermit then show sliding window status}
      if GetProtocol(P) = Kermit then
        FastWrite('Windows Max/Used:', YLow+10, XLow+33, WAttr);

      FastWrite('Progress:', YLow+12, XLow+2, WAttr);
      FastWrite('Status:', YLow+13, XLow+2, WAttr);

      FastWrite(DividerBar, YLow+14, XLow, FAttr);
      FastWrite('Baud:', YLow+15, XLow+2, WAttr);
      FastWrite('DataBits:', YLow+16, XLow+2, WAttr);
      FastWrite('Sfw Flow:', YLow+17, XLow+2, WAttr);

      FastWrite('StopBits:', YLow+15, XLow+33, WAttr);
      FastWrite('Parity:', YLow+16, XLow+33, WAttr);
      FastWrite('Hdw Flow:', YLow+17, XLow+33, WAttr);

      {Only update the port status on startup}
      with P^.PData^.PR^ do begin
        FastWrite(LeftPad(Long2Str(CurBaud), 8), YLow+15, XLow+18, DAttr);
        FastWrite(LeftPad(Long2Str(CurDataBits), 8), YLow+16, XLow+18, DAttr);
        {$IFDEF UseSWFlow}
        B := SWFlowState(P^.PData^.PR) <> fsOff;
        {$ELSE}
        B := False;
        {$ENDIF}
        FastWrite(OnOffStr[B], YLow+17, XLow+23, DAttr);
        FastWrite(LeftPad(Long2Str(CurStopBits), 8), YLow+15, XLow+50, DAttr);
        FastWrite(LeftPad(ParityString[CurParity], 8), YLow+16, XLow+50, DAttr);
        {$IFDEF UseHWFlow}
        B := HWFlowState(P^.PData^.PR) <> fsOff;
        {$ELSE}
        B := False;
        {$ENDIF}
        FastWrite(OnOffStr[B], YLow+17, XLow+56, DAttr);
      end;
    end;

    {Update the data areas}
    with P^.PData^ do begin
      {Store common status info in local variables}
      CurBlockSize := GetBlockSize(P);
      CurFileSize := GetFileSize(P);
      CurBytesRemaining := GetBytesRemaining(P);
      CurBytesTransferred := GetBytesTransferred(P);
      CurProtocol := GetProtocol(P);
      CurElapsedTics := GetElapsedTics(P);
      CurBlock := GetBlockNum(P);

      {Protocol and file name}
      FastWrite(ProtocolTypeString[CurProtocol], YLow+1, XLow+18, DAttr);
      case GetCheckType(P) of
        bcNone      : S := bcsNone;
        bcChecksum1 : S := bcsChecksum1;
        bcChecksum2 : S := bcsChecksum2;
        bcCrc16     : S := bcsCrc16;
        bcCrc32     : S := bcsCrc32;
        bcCrcK      : S := bcsCrcK;
      end;
      FastWrite(S, YLow+2, XLow+18, DAttr);
      FastWrite(Pad(StUpcase(GetFileName(P)), 12), YLow+3, XLow+18, DAttr);

      {File size, block size, block check and total blocks}
      FastWrite(LeftPad(Long2StrBlank(CurFileSize),8), YLow+4, XLow+18, DAttr);
      FastWrite(LeftPad(Long2Str(CurBlockSize),8), YLow+5, XLow+18, DAttr);
      if CurFileSize = 0 then
        I := 0
      else
        I := Succ(CurFileSize div CurBlockSize);
      FastWrite(LeftPad(Long2StrBlank(I),8), YLow+6, XLow+18, DAttr);

      {Estimated time, elapsed time and time remaining}
      FastWrite(FormatMinSec(EstimateTransferSecs(P, CurFileSize)),
                YLow+8, XLow+18, DAttr);
      FastWrite(FormatMinSec(Tics2Secs(CurElapsedTics)), YLow+9, XLow+18, DAttr);
      FastWrite(FormatMinSec(EstimateTransferSecs(P, CurBytesRemaining)),
                YLow+10, XLow+18, DAttr);

      {Bytes transferred and bytes remaining}
      FastWrite(LeftPad(Long2Str(CurBytesTransferred),8), YLow+1, XLow+50, DAttr);
      FastWrite(LeftPad(Long2StrBlank(CurBytesRemaining),8), YLow+2, XLow+50, DAttr);

      {Blocks transferred and blocks remaining}
      FastWrite(LeftPad(Long2Str(CurBlock),8), YLow+3, XLow+50, DAttr);
      Blocks := (CurBytesRemaining+Pred(CurBlockSize)) div CurBlockSize;
      FastWrite(LeftPad(Long2StrBlank(Blocks),8), YLow+4, XLow+50, DAttr);

      {Error counts}
      FastWrite(LeftPad(Long2Str(GetBlockErrors(P)),8),
                        YLow+5, XLow+50, DAttr);
      FastWrite(LeftPad(Long2Str(GetTotalErrors(P)),8),
                        YLow+6, XLow+50, DAttr);

      {Display an empty progress bar on startup and retransmissions}
      if (CurBytesTransferred = 0) or
         (CurBytesTransferred < LastBytesTransferred) then
        FastWrite(NewProgBar, YLow+12, XLow+18, DAttr);
      LastBytesTransferred := CurBytesTransferred;

      {Update the progress bar (if the file size is known}
      if CurFileSize <> 0 then begin
        R := CurBytesRemaining;
        R := R / CurFileSize;
      end else
        R := 1;
      UpdateProgressBar(YLow+12, XLow+18, Length(NewProgBar), 1.0 - R);

      {Update status message}
      UpdateStatusMsg(YLow+13, XLow+18, 35);

      {Calculate and display throughput}
      if CurElapsedTics > 0 then begin
        R := CurBytesTransferred - GetInitialFilePos(P);
        ActualCPS := R / (CurElapsedTics / 18.2);
      end else
        ActualCPS := 0.0;
      FastWrite(LeftPad(Long2Str(Trunc(ActualCPS))+' CPS',9),
                YLow+8, XLow+49, DAttr);

      {Calculate and display efficiency}
      MaxCPS := PR^.CurBaud div 10;
      if MaxCPS > 0 then
        Efficiency := (ActualCPS / MaxCPS) * 100.0
      else
        Efficiency := 0.0;
      FastWrite(Real2Str(Efficiency, 7, 0)+'%', YLow+9, XLow+50, DAttr);

      {If protocol is Kermit then show sliding window status}
      if CurProtocol = Kermit then begin
        Size := GetSwcSize(P);
        if Size = 0 then
          S := '0/0'
        else
          S := Long2Str(Size) + '/' + Long2Str(WindowsUsed(P));
        FastWrite(LeftPad(S, 5), YLow+10, XLow+53, DAttr);
      end;
    end;

    {Remove the window on the last status call}
    if Ending then
      RemoveWindow(W, XLow, YLow, XHigh, YHigh);
  end;

  function KbdAbort : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Default abort function}
  const
    Escape = #$1B;
  var
    Ch : Char;
  begin
    if BackgroundDemo and (BW <> nil) then
      {Let background process control abort}
      KbdAbort := ForceAbort
    else begin
      {Check for abort at keyboard}
      KbdAbort := False;
      if KeyPressed then begin
        Ch := ReadKey;
        if Ch = #0 then
          Ch := ReadKey;
        if Ch = Escape then
          KbdAbort := True;
      end;
    end;
  end;

  procedure LogFileActivity(P : ProtocolRecPtr; LogFileStatus : LogFileType);
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
    {-Maintains a history of all file transmits and receives}
  var
    FLog : Text;
    F : File;
    FName : PathStr;
    Prot : Byte;
  begin
    Assign(FLog, 'FX.HIS');
    Append(FLog);
    if IOResult = 2 then
      ReWrite(FLog);
    if IOResult <> 0 then
      Exit;
    FName := GetPathName(P);
    Prot := GetProtocol(P);
    case LogFileStatus of
      lfReceiveStart :
        {do nothing} ;
      lfReceiveOk :
        WriteLn(FLog, ProtocolTypeString[Prot], ' receive ', FName);
      lfReceiveFail :
        begin
          WriteLn(FLog, ProtocolTypeString[Prot], ' receive aborted ', FName);
          if (GetProtocol(P) <> Zmodem) and
             (GetProtocol(P) <> BPlus) then begin
            Assign(F, FName);
            Erase(F);
            if IOResult <> 0 then ;
          end;
        end;
      lfReceiveSkip :
        WriteLn(FLog, ProtocolTypeString[Prot], ' receive skipped ', FName);
      lfTransmitStart :
        {do nothing} ;
      lfTransmitOk :
        WriteLn(FLog, ProtocolTypeString[Prot], ' transmit ', FName);
      lfTransmitFail :
        WriteLn(FLog, ProtocolTypeString[Prot], ' transmit aborted ', FName);
      lfTransmitSkip :
        WriteLn(FLog, ProtocolTypeString[Prot], ' transmit skipped ', FName);
    end;
    Close(FLog);
    if IOResult <> 0 then ;
  end;

  function FxAcceptFile(P : ProtocolRecPtr) : Boolean;
    {-Test of file renaming with AcceptFile function}
  var
    FName : String[12];
  begin
    FName := GetFilename(P);
    FName[1] := '$';
    SetReceiveFileName(P, FName);
    FxAcceptFile := True;
  end;

  procedure FxErrorProc(P : Pointer; var StatusCode : Word);
  var
    PR : PortRecPtr absolute P;
    C : Char;
    S : String;
    W : Pointer;
  const
    BlankStr : String[78] =
  '                                                                              ';
  begin
    {Do nothing if a protocol is in progress}
    if ProtocolInProgress(P) then
      Exit;
    if StatusCode mod 10000 <> 0 then begin
      {Build an error message}
      W := BuildWindow(1, 23, 80, 25, ' Press any key to continue ');
      if W = nil then begin
        {Not enough memory to show error -- just beep and exit}
        {Beep;}
        Exit;
      end;
      FastWrite(BlankStr, 24, 2, DAttr);
      Str(GetAsyncStatus, S);
      FastWrite(
        'Error during processing ('+S+'): '+StatusStr(GetAsyncStatus),
         24, 2, DAttr);
      C := ReadKey;
      FastWrite(BlankStr, 24, 2, DAttr);
      RemoveWindow(W, 1, 23, 80, 25);
    end;
  end;
  {$F-}

  procedure SetupDemo(P : ProtocolRecPtr);
    {-Setup for background demo window}
  begin
    {Setup for background hook demo}
    BW := BuildWindow(10, 22, 69, 25, ' Background Window ');
    if BW <> nil then begin
      SetBackgroundProc(P, BackgroundDemoWindow);
      Window(11, 23, 68, 24);
      GotoXY(11, 23);
      TextAttr := DAttr;
      ForceAbort := False;
    end;
  end;

  procedure TransferFiles;
  var
    ET : EventTimer;
    Start : Boolean;
    Upload : Boolean;
    C : Char;
  begin
    case Protocol of

      Ascii :
        begin
          InitAscii(AP, ComPort);
          if GetAsyncStatus = ecOk then begin
            SetShowStatusProc(AP, WindowStatus);
            SetOverwriteOption(AP, WriteRename);
            SetLogFileProc(AP, LogFileActivity);
            if BackgroundDemo then
              SetupDemo(AP);
            case TransferMode of
              Transmit :
                begin
                  SetDelays(AP, 0, 100);
                  SetFileMask(AP, SrcFileName);
                  ProtocolTransmitAS(AP);
                end;
              Receive  :
                begin
                  SetReceiveFileName(AP, SrcFileName);
                  ProtocolReceiveAS(AP);
                end;
            end;
            DoneAscii(AP);
            if GetAsyncStatus = ecOk then
              Write(^M^J'Transfer complete'^M^J)
            else
              Write(^M^J'Transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed initializing AsciiProtocol', GetAsyncStatus,^M^J);
        end;

      Xmodem, Xmodem1K, Xmodem1KG :
        begin
          InitXmodem(XM, ComPort, (Protocol = Xmodem1K), Protocol=Xmodem1KG);
          if GetAsyncStatus = ecOk then begin
            SetBlockWait(XM, RelaxedBlockWait);
            SetHandshakeWait(XM, Secs2Tics(10), 5);
            SetShowStatusProc(XM, WindowStatus);
            SetOverwriteOption(XM, WriteRename);
            SetLogFileProc(XM, LogFileActivity);
            if BackgroundDemo then
              SetupDemo(XM);

            case TransferMode of
              Transmit :
                begin
                  SetFileMask(XM, SrcFileName);
                  ProtocolTransmitXM(XM);
                end;
              Receive  :
                begin
                  SetReceiveFileName(XM, SrcFileName);
                  ProtocolReceiveXM(XM);
                end;
            end;
            DoneXmodem(XM);
            if GetAsyncStatus = ecOk then
              Write(^M^J'Transfer complete'^M^J)
            else
              Write(^M^J'Transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed initializing Xmodem ', GetAsyncStatus,^M^J);
        end;

      Ymodem, YmodemG :
        begin
          InitYmodem(YM, ComPort, True, (Protocol = YmodemG));
          if GetAsyncStatus = ecOk then begin
            SetShowStatusProc(YM, WindowStatus);
            SetBlockWait(YM, RelaxedBlockWait);
            SetHandshakeWait(YM, Secs2Tics(10), 5);
            SetOverwriteOption(YM, WriteRename);
            SetLogFileProc(YM, LogFileActivity);
            if BackgroundDemo then
              SetupDemo(YM);
            case TransferMode of
              Transmit :
                begin
                  SetFileMask(YM, SrcFileName);
                  ProtocolTransmitYM(YM);
                end;
              Receive  :
                  ProtocolReceiveYM(YM);
            end;
            DoneYmodem(YM);
            if GetAsyncStatus = ecOk then
              Write(^M^J'Ymodem transfer complete'^M^J)
            else
              Write(^M^J'Ymodem transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed to init Ymodem ', GetAsyncStatus,^M^J);
        end;

      Zmodem :
        begin
          {$IFDEF Test8KZmodem}
          DefProtocolOptions := DefProtocolOptions or apZmodem8K;
          {$ENDIF}
          InitZmodem(ZM, ComPort);
          if GetAsyncStatus = ecOk then begin
            SetShowStatusProc(ZM, WindowStatus);
            SetHandshakeWait(ZM, Secs2Tics(10), 5);
            SetLogFileProc(ZM, LogFileActivity);
            if ClobberFile then
              SetFileMgmtOptions(ZM, True, SkipNoFile, WriteClobber);
            if NewerLonger then
              SetFileMgmtOptions(ZM, True, SkipNoFile, WriteNewerLonger);
            if ResumeFile then
              SetRecoverOption(ZM, True);
            if BackgroundDemo then
              SetupDemo(ZM);
            {$IFDEF Test8KZmodem}                                    {!!.01}
            SetBigSubPacketOption(ZM, True);                         {!!.01}
            {$ENDIF}                                                 {!!.01}

            (* Example of AcceptFile function
            SetAcceptFileFunc(ZM, FxAcceptFile);
            *)

            case TransferMode of
              Transmit :
                begin
                  SetFileMask(ZM, SrcFileName);
                  ProtocolTransmitZM(ZM);
                end;
              Receive  :
                  ProtocolReceiveZM(ZM);
            end;
            DoneZmodem(ZM);
            if GetAsyncStatus = ecOk then
              Write(^M^J'Zmodem transfer complete'^M^J)
            else
              Write(^M^J'Zmodem transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed to init Zmodem ', GetAsyncStatus,^M^J);
        end;

      Kermit :
        begin
          InitKermit(KM, ComPort);
          if GetAsyncStatus = ecOk then begin
            SetShowStatusProc(KM, WindowStatus);
            SetOverwriteOption(KM, WriteRename);
            SetLogFileProc(KM, LogFileActivity);
            if BackgroundDemo then
              SetupDemo(KM);

            (* Uncomment the following to test sliding windows support
            SetMaxWindows(KM, 15);
            SetMaxLongPacketLen(KM, 1024);
            *)

            SetLogFileProc(KM, LogFileActivity);
            case TransferMode of
              Transmit :
                begin
                  SetFileMask(KM, SrcFileName);
                  ProtocolTransmitKM(KM);
                end;
              Receive  :
                  ProtocolReceiveKM(KM);
            end;
            DoneKermit(KM);
            if GetAsyncStatus = ecOk then
              Write(^M^J'Kermit transfer complete'^M^J)
            else
              Write(^M^J'Kermit transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed to init Kermit ', GetAsyncStatus,^M^J);
        end;

      BPlus :
        begin
          InitBPlus(BP, ComPort);
          if GetAsyncStatus = ecOk then begin
            SetShowStatusProc(BP, WindowStatus);
            SetOverwriteOption(BP, WriteRename);
            SetLogFileProc(BP, LogFileActivity);
            if BackgroundDemo then
              SetupDemo(BP);

            NewTimerSecs(ET, 10);
            Start := False;

            {Assume ENQ already arrived...}
            ProcessENQ(BP);

            {Process expected DLEs}
            repeat
              if CharReady(ComPort) then begin
                GetChar(ComPort, C);
                if C = cDLE then
                  ProcessDLE(BP, Start, Upload);
              end;
            until Start or TimerExpired(ET) or KbdAbort;               {!!.01}

            {Exit if we couldn't start the protocol}
            if not Start then begin                                    {!!.01}
              DoneBPlus(BP);                                           {!!.01}
              Abort('Failed to pick up B+ protocol in progress', 0);   {!!.01}
            end;                                                       {!!.01}

            if Upload then
              TransferMode := Transmit
            else
              TransferMode := Receive;

            case TransferMode of
              Transmit : ProtocolTransmitBP(BP);
              Receive  : ProtocolReceiveBP(BP);
            end;
            DoneBPlus(BP);
            if GetAsyncStatus = ecOk then
              Write(^M^J'BPlus transfer complete'^M^J)
            else
              Write(^M^J'BPlus transfer failed ', GetAsyncStatus,^M^J);
          end else
            Write(^M^J'Failed to init BPlus ', GetAsyncStatus,^M^J);
        end;
    end;
  end;

begin
  {Set ComPort to nil so abort can see if it needs to be disposed}
  ComPort := nil;

  {Use standard out for error messages}
  Assign(Output, '');
  Rewrite(Output);

  {Display version}
  WriteLn(Version);

  {Get command line parameters}
  ParseCommandLine;

  {Use CRT unit again}
  AssignCrt(Output);
  Rewrite(Output);

  {Open a port}
  if BaudSpecified then begin
    InitPort(ComPort, ComX,
             Baud, NoParity, 8, 1,
             {$IFDEF Test8KZmodem}                                     {!!.01}
             16384, 16384+30,                                          {!!.01}
             {$ELSE}                                                   {!!.01}
             4096, 4096,
             {$ENDIF}                                                  {!!.01}
             DefPortOptions);
    OpenStatus := GetAsyncStatus;
  end else begin
    {$IFDEF Test8KZmodem}                                              {!!.01}
    InitPortKeep(ComPort, ComX, 16384, 16384+30);                      {!!.01}
    {$ELSE}
    InitPortKeep(ComPort, ComX, 4096, 4096);                           {!!.01}
    {$ENDIF}
    OpenStatus := GetAsyncStatus;
    ptOptionsOff(ComPort, ptRestoreOnClose or ptDropModemOnClose);
    SetDTR(ComPort, True);
    SetRTS(ComPort, True);
  end;

  if OpenStatus <> ecOk then
    Abort('Failed to open port: ', OpenStatus);

  {Set the port-level user abort function}
  SetAbortFunc(ComPort, KbdAbort);

  {Set the port-level user error handler}
  SetErrorProc(ComPort, FxErrorProc);

  {$IFDEF Tracing}
  {Start a trace}
  InitTracing(TraceEntries);
  {$ENDIF}

  {$IFDEF UseHWFlow}
  {Turn on hardware flow control (CTS only)}
  HWFlowEnable(ComPort, 2000, 200, hfUseRTS or hfRequireCTS);
  {$ENDIF}

  SaveExit := ExitProc;                                                {!!.01}
  ExitProc := @FxExitProc;                                             {!!.01}

  {Do the protocol transfer}
  TransferFiles;

  {Remove background demo window}
  if BackgroundDemo and (BW <> nil) then
    RemoveWindow(BW, 10, 22, 69, 25);

  {$IFDEF Tracing}
  {Write the trace to disk}
  DumpTrace('FX.TRC');
  {$ENDIF}

  {Clean up}
  DonePort(ComPort);
end.
