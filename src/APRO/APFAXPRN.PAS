
(******************************************************************************
APFAXPRN.PAS - This unit provides fax printing support for APRO format
fax files using either Epson or HP compatible printers. There is basically
only one data structure that you need to create: A FaxPrinterRec. The basic
steps to print a fax are shown below:

 var
   Printer : FaxPrinterPtr;    {Fax printing object}
  ...
  {Init data}
  InitFaxPrinter(Printer);

  {Set options}
  SetPcl5Mode(Printer, True);           {Uses PCL5 commands to compress}
  SetScaling(Printer, True);                         {Scale page output}
  SetHeader(Printer, True);                {Print a header on each page}
  SetBlankLineSuppression(Printer, True);            {Strip blank areas}

  {Print the fax - to an Epson, HP150, or HP300}
  PrintFaxDocument(Printer, HP300, 'LPT1', 'FAX.APF');

  {Dispose of data}
  DoneFaxPrinter(Printer);

******************************************************************************)

{$R-,S-,A+,F+,I-,V-,B-,O+}

{******************************************************}
{*                 APFAXPRN.PAS 2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I APDEFINE.INC}

unit ApFaxPrn;
  {-Print a fax file}

interface

uses
  Dos,
  {$IFDEF UseOpro}
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTpro}
  TpMemChk,
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApFaxD;
  {$ELSE}
  ApMisc,
  ApFaxCvt;
  {$ENDIF}

const
  {Fax printing options}
  fpScale               = $0001;  {Scale page output}
  fpHeader              = $0002;  {Print a page header}
  fpPcl5Mode            = $0004;  {Use PCL5 commands (HP only)}
  fpSuppressBlanks      = $0008;  {Suppress printing of large blank areas}

  {Setup default options}
  DefPrinterOptions     : Word = fpScale;  {Scale page by default}

  {Setup bad options}
  BadPrinterOptions     : Word = 0;

  BLSSize               : Word = 60;                                   {!!.01}
                            {Blank line suppression size, 60 = 2/10ths inch}
                            {Shrink blank areas to this minimum height}

type
  {Allowable printer types}
  PrinterType           = (Epson, Epson24, HP150, HP300);

  {Types for print and pack buffer allocations}
  ByteArray             = array[0..$FFF0] of Byte;
  PByteArray            = ^ByteArray;

  {User hook function types - return True to abort}
  LineNotifyType        = function(Lines, LineSize : Word) : Boolean;
  WriteNotifyType       = function(BytesWritten : Word) : Boolean;
  PageNotifyType        = function(ThisPage, TotalPages : Word) : Boolean;

  {Printer record}
  FaxPrinterPtr         = ^FaxPrinter;
  FaxPrinter            = record
    PrnF                : file;        {Printer file/device}
    PrnDest             : PathStr;     {Print destination}
    PrintBufCount       : Word;        {Characters in the print buffer}
    PrintedLineCount    : Word;        {Number of raster lines printed}
    MaxLinesPerPage     : Word;        {Max raster lines per page}
    CurrentPage         : Word;        {Page that is printing}
    TotalPages          : Word;        {Number of pages for this document}
    RasterCount         : Word;        {Number of raster lines unpacked}
    FaxName             : PathStr;     {Name of file being printed}
    MinBlankSpace       : Word;        {For blank line compression}
    fpOptions           : Word;        {Print options}

    {Pack and print buffers - dynamically allocated}
    PackBuf             : PByteArray;  {Pack buffer}
    PrintBuf            : PByteArray;  {Print buffer}

    {Notification hooks}
    LineNotify          : LineNotifyType;
    WriteNotify         : WriteNotifyType;
    PageNotify          : PageNotifyType;

    {Scale buffer for HP printing - dynamically allocated}
    ScaleBuf            : PByteArray;  {Scaling buffer}
    BlankLinesToPrint   : Word;        {Pending blank lines to send}

    {For Epson printing}
    RasterCountDown     : Byte;        {For Epson, counts lines in pack buffer}
    CombineCount        : Byte;        {For Epson, counts rasters to combine}
  end;

  procedure InitFaxPrinter(var AFP : FaxPrinterPtr);
    {-Allocates and initializes the fax printer data}
  procedure DoneFaxPrinter(var AFP : FaxPrinterPtr);
    {-Disposes of the fax printer data}

  {Option management}
  procedure fpOptionsOn(var AFP : FaxPrinterPtr;
                        OptionFlags : Word);
    {-Activate multiple options}
  procedure fpOptionsOff(var AFP : FaxPrinterPtr;
                         OptionFlags : Word);
    {-Deactivate multiple options}
  function fpOptionsAreOn(var AFP : FaxPrinterPtr;
                          OptionFlags : Word) : Boolean;
    {-Return True if all specified options are on}

  {User control}
  procedure SetLineNotifyFunc(var AFP : FaxPrinterPtr;
                              LNF : LineNotifyType);
    {-Set the procedure that is called for each raster line processed}
  procedure SetWriteNotifyFunc(var AFP : FaxPrinterPtr;
                               WNF : WriteNotifyType);
    {-Set the procedure that is called for each data write}
  procedure SetPageNotifyFunc(var AFP : FaxPrinterPtr;
                              PNF : PageNotifyType);
    {-Set the procedure that is called before each fax page is printed}

  procedure SetScaling(var AFP : FaxPrinterPtr; On : Boolean);
    {-Enable/disable scaling - default is on}
  procedure SetHeader(var AFP : FaxPrinterPtr; On : Boolean);
    {-Enable/disable page headers - default is off}
  procedure SetPCL5Mode(var AFP : FaxPrinterPtr; On : Boolean);
    {-Enable/disable use of PCL5 commands - default is off}
  procedure SetBlankLineSuppression(var AFP : FaxPrinterPtr; On : Boolean);
    {-Enable/disable blank line suppression - default is off}

  procedure PrintFaxDocument(AFP      : FaxPrinterPtr;
                             APrinter : PrinterType;
                             ADest    : PathStr;
                             AFaxName : PathStr);
    {-Prints a fax file}

implementation

var
  fpPrinter             : FaxPrinterPtr;
  UF                    : UnpackFaxPtr;
  WhichPrinter          : PrinterType;

const
  PackBufSize      = 9216;                     {Pack buffer size}
  {Note: worst case PackBufSize is for Epson 24-pin scaled output.
   For this case, PackBufSize must be at least
     2048*(3/2)*3 = 9216 bytes
   2048 is the maximum number of pixels in the fax raster line.
   3/2 is the horizontal scaling ratio.
   3 is the number of bytes in the pack buffer for each pixel column.}

  PrintBufSize     = 2048;                     {Print buffer size}
  ScaleBufSize     = 2048;                     {Scaling buffer size}

  {PCL printer command strings}
  PclInit          : string[2] = #27'E';       {Init command}
  Pcl300DPI        : string[7] = #27'*t300R';  {Enable 300 dpi mode}
  Pcl150DPI        : string[7] = #27'*t150R';  {Enable 150 dpi mode}
  PclStartGraph    : string[5] = #27'*r0A';    {Start raster graphics}
  PclEndGraph      : string[4] = #27'*rB';     {End raster graphics}
  PclXferS         : string[3] = #27'*b';      {Start data block command}
  PclXferE         : string[1] = 'W';          {End data block command}
  PclTiffMode      : string[5] = #27'*b2M';    {Enable TIFF compression}
  PclDeltaMode     : string[5] = #27'*b3M';    {Enable delta compression}
  PclRepLine       : string[5] = #27'*b0W';    {Repeat previous line}
  PclBlankS        : string[3]  = #27'*b';     {Start blank line command}
  PclBlankE        : string[1]  = 'Y';         {End blank line command}
  PclSetMargin     : string[5] = #27'&l1E';    {Set margin to first raster}

  {TIFF encoded command strings to draw a horizontal line}
  PclLine300       : string[11] = #27'*b6W'#129#255#129#255#213#255;
  PclLine150       : string[9]  = #27'*b4W'#129#255#235#255;

  LinesPerPageLimit= 3135;  {Maximum raster lines per page at 300 dpi}

  Pcl4LineAdj      = 100;   {Heigth of about two text lines for adjusting}
                            {the lines per page for older PCL printers}

  AfterTextSpace   = 14;    {Down 14 raster lines after header}
  ProbationArea    = 60;    {Raster lines above the page bottom to start}
                            {looking for a good place for a page break}

  {Epson printer command strings}
  EpsInit          : string[5]  = #27'@';  {Reset}
  EpsShutdown      : string[3]  = ^L;      {Form feed}

  {Never more than 1920 bytes = 1920 pixels wide = 8.00"}
  EpsMaxWidth      = 1920;


  {---------- General-purpose routines ----------}

  procedure FastZero(var Dest; Size : Word); assembler;
    {-Zero fill dest}
  asm
    xor   ax,ax     { store zeros from ax   }
    les   di,Dest   { es:di = @Dest         }
    cld             { go forward            }
    mov   cx,Size   { size of data to zero  }
    shr   cx,1      { divide size by two    }
    rep   stosw     { zero words            }
    adc   cx,cx     { get odd byte (cf)     }
    rep   stosb     { store odd byte if any }
  end;

  procedure FastMove(var Src; var Dest; Size : Word); assembler;
    {-Move that assumes no Src and Dest overlap}
  asm
    push ds         { save ds               }
    mov  cx,Size    { cx = bytes to move    }
    lds  si,Src     { ds:si = @Src          }
    les  di,Dest    { es:di = @Dest         }
    cld             { forward               }
    shr  cx,1       { adjust for words      }
    rep  movsw      { copy cx words         }
    adc  cx,cx      { get odd byte (cf)     }
    rep  movsb      { move last byte if any }
    pop  ds         { restore ds            }
  end;

  function NonZeroLen(var Src; Len : Word) : Word; assembler;
    {-Return number of leading non-zero bytes in Src}
  asm
    mov   cx,Len
    jcxz  @2           {get out for zero length}
    les   di,Src       {ES:DI = buffer}
    add   di,cx
    dec   di           {di -> last valid byte}
    std                {backwards}
    xor   al,al
    repe  scasb
    cld                {in case someone else counts on cld}
    jnz   @1           {jump if any non-zeros found}
    mov   cx,-1        {force return of zero}
@1: inc   cx
@2: mov   ax,cx
  end;

  procedure SetRawMode(var F : file; On : Boolean); assembler;
    {-Set "raw" mode on or off for the specified file (must be a device)}
  asm
    les   di,F
    mov   bx,es:[di]   { bx = file handle    }
    mov   ax,$4400     { get device info     }
    int   $21
    jc    @9           { jump if error       }
    xor   ax,ax        { clear error code    }
    test  dl,$80       { is a device?        }
    jz    @9           { jump if not         }
    and   dx,$00AF     { clear unwanted bits }
    or    dl,$20       { assume raw mode     }
    cmp   On,0         { is On non-zero?     }
    jne   @1           { jump if On = True   }
    and   dl,$DF
@1: mov   ax,$4401     { set device info     }
    int   $21
    jc    @9           { jump if error       }
    xor   ax,ax        { clear error code    }
@9: mov   DosError,ax
  end;

  function Long2Str(L : LongInt) : string;
  var
    S : string;
  begin
    Str(L, S);
    Long2Str := S;
  end;

  { NOTE: This routine assumes that InLen is an even multiple of 3
    and that it is not less than 3 }
  procedure Scale200to300(var InBuf ;     InLen  : Word;
                          var OutBuf; var OutLen : Word); assembler;
  const
    ScaleBufDiv4 = ScaleBufSize div 4;

  asm
    push  ds
    lds   si,InBuf      { DS:SI->InBuf }
    mov   ax,InLen
    les   di,OutBuf     { ES:DI->OutBuf }
    push  di            { Save for later calculation }
    cld                 { go forward }

    xor   dx,dx
    mov   cx,3          { divide length of buffer by three }
    div   cx
    mov   cx,ax

    cmp   cx, ScaleBufDiv4  { test for OutBuf limits }
    jbe   @1
    mov   cx, ScaleBufDiv4  { reduce to upper limit }

    { BX and DX are output registers }

@1: push  cx            { save loop counter }

    lodsw               { get first two bytes of input }
    xchg  al,ah         { reverse the bytes so they're ordered properly }

    mov  bx,ax          {copy into bx}

    {use 12 bits of input from ax}
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  cx,1           {skip output bit}

    {use 12 bits of input from bx}
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1

    {have two bytes of output, having used 12 bits of input}
    or   cx,dx         {merge output words}
    xchg cl,ch
    mov  es:[di],cx
    inc  di
    inc  di

    {use last 4 bits of ax}
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  ax,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  ax,1
    rcl  cx,1

    {use last 4 bits of bx}
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  bx,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bx,1
    rcl  dx,1

    lodsb               {another byte of input}
    mov  bl,al          {copy into bl}

    {use 8 bits of al}
    shl  al,1
    rcl  cx,1
    shl  al,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  al,1
    rcl  cx,1
    shl  al,1
    rcl  cx,1
    shl  al,1
    rcl  cx,1
    shl  cx,1           {skip output bit}
    shl  al,1
    rcl  cx,1
    shl  al,1
    rcl  cx,1
    shl  al,1
    rcl  cx,1
    shl  cx,1           {skip output bit}

    {use 8 bits of bl}
    shl  bl,1
    rcl  dx,1
    shl  bl,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bl,1
    rcl  dx,1
    shl  bl,1
    rcl  dx,1
    shl  bl,1
    rcl  dx,1
    shl  dx,1           {skip output bit}
    shl  bl,1
    rcl  dx,1
    shl  bl,1
    rcl  dx,1
    shl  bl,1
    rcl  dx,1

    {have another 2 bytes of output}
    or   cx,dx          {merge output words}
    xchg cl,ch
    mov  es:[di],cx
    inc  di
    inc  di

    pop  cx
    dec  cx             {more groups?}
    jcxz @2             {jump if not}
    jmp  @1             {do it again}

@2: pop  bx             { get initial DI in BX }

    sub   di,bx         { calculate and store length of output }
    mov   bx,di
    les   di,OutLen
    mov   es:[di],bx

    pop   ds            { restore ds }
  end;

  procedure InitFaxPrinter(var AFP : FaxPrinterPtr);
  label
    ErrorExit;
  begin
    SetAsyncStatus(ecOk);                                              {!!.01}

    if not GetMemCheck(AFP, SizeOf(FaxPrinter)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;
    FastZero(AFP^, SizeOf(FaxPrinter));

    with AFP^ do begin
      {Set defaults}
      PrnDest := 'PRN';
      fpOptions := DefPrinterOptions;

      {Allocate the print buffer}
      if not GetMemCheck(PrintBuf, PrintBufSize) then
        goto ErrorExit;
      FastZero(PrintBuf^, PrintBufSize);

      {Allocate the pack buffer}
      if not GetMemCheck(PackBuf, PackBufSize) then
        goto ErrorExit;
      FastZero(PackBuf^, PackBufSize);

      {Allocate the scale buffer}
      if not GetMemCheck(ScaleBuf, ScaleBufSize) then
        goto ErrorExit;
      FastZero(ScaleBuf^, ScaleBufSize);

      {Init notification hook pointers}
      @LineNotify  := nil;
      @WriteNotify := nil;
      @PageNotify  := nil;
    end;

    Exit;

ErrorExit:

    SetAsyncStatus(ecOutOfMemory);
    with AFP^ do begin
      FreeMemCheck(ScaleBuf, ScaleBufSize);
      FreeMemCheck(PackBuf, PackBufSize);
      FreeMemCheck(PrintBuf, PrintBufSize);
    end;
    FreeMemCheck(AFP, SizeOf(FaxPrinter));
  end;

  procedure DoneFaxPrinter(var AFP : FaxPrinterPtr);
  begin
    with AFP^ do begin
      FreeMemCheck(ScaleBuf, ScaleBufSize);
      FreeMemCheck(PackBuf, PackBufSize);
      FreeMemCheck(PrintBuf, PrintBufSize);
    end;
    FreeMemCheck(AFP, SizeOf(FaxPrinter));
  end;

  procedure fpOptionsOn(var AFP : FaxPrinterPtr;
                        OptionFlags : Word);
  begin
    with AFP^ do
      fpOptions := fpOptions or (OptionFlags and not BadPrinterOptions);
  end;

  procedure fpOptionsOff(var AFP : FaxPrinterPtr;
                         OptionFlags : Word);
  begin
    with AFP^ do
      fpOptions := fpOptions and not (OptionFlags and not BadPrinterOptions);
  end;

  function fpOptionsAreOn(var AFP : FaxPrinterPtr;
                          OptionFlags : Word) : Boolean;
  begin
    with AFP^ do
      fpOptionsAreOn := (fpOptions and OptionFlags = OptionFlags);
  end;

  procedure SetLineNotifyFunc(var AFP : FaxPrinterPtr;
                              LNF : LineNotifyType);
  begin
    AFP^.LineNotify := LNF;
  end;

  procedure SetWriteNotifyFunc(var AFP : FaxPrinterPtr;
                               WNF : WriteNotifyType);
  begin
    AFP^.WriteNotify := WNF;
  end;

  procedure SetPageNotifyFunc(var AFP : FaxPrinterPtr;
                              PNF : PageNotifyType);
  begin
    AFP^.PageNotify := PNF;
  end;

  function CallWriteNotify(BytesWritten : Word) : Boolean;
  begin
    with fpPrinter^ do begin
      if @WriteNotify <> nil then
        CallWriteNotify := WriteNotify(BytesWritten)
      else
        CallWriteNotify := False;  {Don't abort}
    end;
    SetAsyncStatus(ecOk);  {Clear status}
  end;

  function CallLineNotify(Lines, LineSize : Word) : Boolean;
  begin
    with fpPrinter^ do begin
      if @LineNotify <> nil then
        CallLineNotify := LineNotify(Lines, LineSize)
      else
        CallLineNotify := False;  {Don't abort}
    end;
    SetAsyncStatus(ecOk);  {Clear status}
  end;

  function CallPageNotify(ThisPage, PageCount : Word) : Boolean;
  begin
    with fpPrinter^ do begin
      if @PageNotify <> nil then
        CallPageNotify := PageNotify(ThisPage, PageCount)
      else
        CallPageNotify := False;  {Don't abort}
    end;
    SetAsyncStatus(ecOk);  {Clear status}
  end;

  procedure SetScaling(var AFP : FaxPrinterPtr; On : Boolean);
  begin
    if On then
      fpOptionsOn(AFP, fpScale)
    else
      fpOptionsOff(AFP, fpScale);
  end;

  procedure SetHeader(var AFP : FaxPrinterPtr; On : Boolean);
  begin
    if On then
      fpOptionsOn(AFP, fpHeader)
    else
      fpOptionsOff(AFP, fpHeader);
  end;

  procedure SetPCL5Mode(var AFP : FaxPrinterPtr; On : Boolean);
  begin
    if On then
      fpOptionsOn(AFP, fpPCL5Mode)
    else
      fpOptionsOff(AFP, fpPCL5Mode);
  end;

  procedure SetBlankLineSuppression(var AFP : FaxPrinterPtr; On : Boolean);
  begin
    if On then
      fpOptionsOn(AFP, fpSuppressBlanks)
    else
      fpOptionsOff(AFP, fpSuppressBlanks);
  end;


  {Abstract print routines}
  procedure AbstractPrintOpen;
  begin
    with fpPrinter^ do begin
      Assign(PrnF, PrnDest);
      ReWrite(PrnF, 1);
      SetAsyncStatus(IoResult);
      if GetAsyncStatus <> ecOk then
        Exit;
      SetRawMode(PrnF, True);
      {Init to show an empty print buffer}
      PrintBufCount := 0;
    end;
  end;

  procedure AbstractFlushPrintBuf;
  begin
    if GetAsyncStatus <> ecOk then Exit;                               {!!.02}
    with fpPrinter^ do begin
      {Send current buffer contents}
      BlockWrite(PrnF, PrintBuf^[0], PrintBufCount);
      SetAsyncStatus(IoResult);
      if GetAsyncStatus <> ecOk then Exit;                             {!!.02}

      {Clear buffer contents counter}
      PrintBufCount := 0;

      {Call user hook}
      if CallWriteNotify(PrintBufCount) then
        SetAsyncStatus(ecUserAbort);
    end;
  end;

  procedure AbstractPrintClose;
  begin
    with fpPrinter^ do begin
      {Flush remaining data in buffer}
      if PrintBufCount > 0 then
        AbstractFlushPrintBuf;
      {Close the device/file}
      Close(PrnF);
      if IoResult <> 0 then {};
    end;
  end;

  procedure AbstractPrintData(var Data; Size : Word);
  var
    BytesToPrint : Word;
    ByteOfs : Word;
  begin
    with fpPrinter^ do begin
      ByteOfs := 0;
      repeat
        {Limit block to PrintBufSize}
        if Size > PrintBufSize then
          BytesToPrint := PrintBufSize
        else
          BytesToPrint := Size;

        {Dump buffer to output if the block won't fit}
        if PrintBufCount+BytesToPrint > PrintBufSize then
          AbstractFlushPrintBuf;
        if GetAsyncStatus <> ecOK then                                 {!!.03}
          Exit;                                                        {!!.03}

        {Move this data into the print buffer}
        FastMove(ByteArray(Data)[ByteOfs], PrintBuf^[PrintBufCount], BytesToPrint);

        inc(PrintBufCount, BytesToPrint);
        inc(ByteOfs, BytesToPrint);
        dec(Size, BytesToPrint);
      until Size = 0;
    end;
  end;

  {---------- Epson printer routines ----------}

  procedure EpsonPrintStr(S : string);
  begin
    AbstractPrintData(S[1], Length(S));
  end;

  function EpsonMakeHeader : string;
  var
    S : string[100];
  begin
    with fpPrinter^ do
      S := 'Filename: ' + StUpCase(JustFileName(FaxName)) +
           ' Printed: ' + NowString + '  ' + TodayString +
           '                     Page ' + Long2Str(CurrentPage);
    EpsonMakeHeader := ^M^J + S;
  end;

  procedure EpsonPrintGraphics(var Buffer;
                               ByteLen : Word; AdvanceLen : Byte);
  var
    N1 : Byte;
    N2 : Byte;
  begin
    {Never more than 1920 bytes = 1920 pixels wide = 8.00"}
    if ByteLen > EpsMaxWidth then
      ByteLen := EpsMaxWidth;

    {Trim trailing zeros}
    ByteLen := NonZeroLen(Buffer, ByteLen);

    {Print what's left}
    if ByteLen > 0 then begin
      N1 := ByteLen and $FF;
      N2 := ByteLen shr 8;
      EpsonPrintStr(#27'Z'+Char(N1)+Char(N2));
      AbstractPrintData(Buffer, ByteLen);
      FastZero(Buffer, EpsMaxWidth);
    end;

    {Vertical advance}
    EpsonPrintStr(#27'J'+Char(AdvanceLen)+^M);
  end;

  procedure EpsonStartNewPage;
  begin
    with fpPrinter^ do begin
      {Print last set of raster lines}
      if RasterCountDown < 7 then
        EpsonPrintGraphics(PackBuf^, EpsMaxwidth, 24);

      EpsonPrintStr(EpsInit);
      Inc(CurrentPage);

      {Print a page header}
      if fpOptionsAreOn(fpPrinter, fpHeader) then begin
        EpsonPrintStr(EpsonMakeHeader);
        EpsonPrintStr(^M^J);
        FillChar(PackBuf^, EpsMaxWidth, $80);
        EpsonPrintGraphics(PackBuf^, EpsMaxWidth, 8);
      end;

      {Init for next page}
      RasterCountDown  := 7;
      CombineCount := 0;
      PrintedLineCount := 0;
    end;
  end;

  procedure EpsonPrintOpen;
  begin
    AbstractPrintOpen;
    EpsonStartNewPage;
  end;

  procedure EpsonPrintClose;
  begin
    with fpPrinter^ do begin
      {Print last set of raster lines}
      if RasterCountDown < 7 then
        EpsonPrintGraphics(PackBuf^, EpsMaxwidth, 24);

      EpsonPrintStr(EpsShutdown);
      AbstractPrintClose;
    end;
  end;

  function EpsonPrintRasterLine(UFP      : UnpackFaxPtr;
                                Buffer   : PByteBuffer;
                                InputLen : Word;
                                PH       : PageHeaderRec) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ELSE} far; {$ENDIF}
  const                 {HighRes, Scaling}
    CombineLimit : array[Boolean, Boolean] of Byte =
      ((0, 1),     {HighRes = False}
       (1, 3));    {HighRes = True}
  var
    Scaling : Boolean;
  begin
    SetAsyncStatus(ecOk);  {Clear status}

    if InputLen = 0 then begin
      EpsonPrintRasterLine := False;
      Exit;
    end;
    if InputLen > EpsMaxWidth shr 3 then
      InputLen := EpsMaxWidth shr 3;

    {Update row RasterCountDown of PackBuf}
    asm
      push ds
      les  di,fpPrinter
      mov  ch,es:[di].FaxPrinter.RasterCountDown
      les  di,es:[di].FaxPrinter.PackBuf
      lds  si,Buffer
      mov  dx,si
      add  dx,InputLen       {dx = input offset terminator}
      jmp  @9
@1:   mov  ah,[si]           {ah = current input byte}
@2:   mov  al,ah
      shr  al,cl
      and  al,1
      xchg ch,cl
      shl  al,cl             {al = ((Input shr BitShift) and $01) shl RasterCountDown}
      xchg ch,cl
      or   es:[di],al        {or result into PackBuf}
      inc  di                {next output byte}
      or   cl,cl             {bit shift = 0?}
      jz   @3                {jump if so}
      dec  cl                {decrement bit shift}
      jmp  @2                {do it again}
@3:   inc  si                {next byte of input}
@9:   mov  cl,7              {reset bit shift}
      cmp  si,dx             {all input used?}
      jb   @1                {jump if not}
      pop  ds
    end;

    with fpPrinter^ do begin
      Scaling := fpOptionsAreOn(fpPrinter, fpScale);
      {Dump PackBuf when 8 raster lines are combined and filled in}
      if CombineCount >=
         CombineLimit[(PH.ImgFlags and ffHighRes <> 0), Scaling] then begin
        CombineCount := 0;
        if RasterCountDown = 0 then begin
          RasterCountDown := 7;
          EpsonPrintGraphics(PackBuf^, EpsMaxWidth, 24);
          if GetAsyncStatus <> ecOk then begin
            EpsonPrintRasterLine := True;
            Exit;
          end;
        end else
          Dec(RasterCountDown);
      end else
        inc(CombineCount);

      {Call LineNotify routine}
      Inc(PrintedLineCount);
      if CallLineNotify(PrintedLineCount, InputLen) then begin
        EpsonPrintRasterLine := True;
        Exit;
      end;

      {No abort if we get here}
      EpsonPrintRasterLine := False;
    end;
  end;

  {---------- Epson24 printer routines ----------}

  procedure Epson24PrintGraphics(var Buffer;
                               ByteLen : Word; AdvanceLen : Byte);
  var
    N1 : Byte;
    N2 : Byte;
    Cols : Word;
  begin
    {Trim trailing zeros}
    ByteLen := NonZeroLen(Buffer, ByteLen);
    Cols := ByteLen mod 3;
    if Cols <> 0 then
      inc(ByteLen, 3-Cols);

    {Print what's left}
    if ByteLen > 0 then begin
      Cols := ByteLen div 3;
      N1 := Cols and $FF;
      N2 := Cols shr 8;
      EpsonPrintStr(#27'*'#40+Char(N1)+Char(N2));
      AbstractPrintData(Buffer, ByteLen);
      FastZero(Buffer, PackBufSize);
    end;

    {Vertical advance}
    EpsonPrintStr(#27'J'+Char(AdvanceLen)+^M);
  end;

  procedure Epson24StartNewPage;
  var
    I : Word;
  begin
    with fpPrinter^ do begin
      {Print last set of raster lines}
      if RasterCountDown < 23 then
        Epson24PrintGraphics(PackBuf^, PackBufSize, 24);

      EpsonPrintStr(EpsInit);
      Inc(CurrentPage);

      {Print a page header}
      if fpOptionsAreOn(fpPrinter, fpHeader) then begin
        EpsonPrintStr(EpsonMakeHeader);
        EpsonPrintStr(^M^J);
        FastZero(PackBuf^, PackBufSize);
        for I := 0 to (PackBufSize div 3)-1 do
          PackBuf^[3*I] := $80;
        Epson24PrintGraphics(PackBuf^, PackBufSize, 8);
      end;

      {Init for next page}
      RasterCountDown  := 23;
      PrintedLineCount := 0;
      RasterCount := 0;
    end;
  end;

  procedure Epson24PrintOpen;
  begin
    AbstractPrintOpen;
    Epson24StartNewPage;
  end;

  procedure Epson24PrintClose;
  begin
    with fpPrinter^ do begin
      {Print last set of raster lines}
      if RasterCountDown < 23 then
        Epson24PrintGraphics(PackBuf^, PackBufSize, 24);

      EpsonPrintStr(EpsShutdown);
      AbstractPrintClose;
    end;
  end;

  function Epson24PrintRasterLine(UFP      : UnpackFaxPtr;
                                Buffer   : PByteBuffer;
                                InputLen : Word;
                                PH       : PageHeaderRec) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ELSE} far; {$ENDIF}
  var
    OutLen : Word;
    Count : Word;
    ICount : Word;
    Scaling : Boolean;
    HighRes : Boolean;
  begin
    SetAsyncStatus(ecOk);  {Clear status}

    if InputLen = 0 then begin
      Epson24PrintRasterLine := False;
      Exit;
    end;

    Scaling := fpOptionsAreOn(fpPrinter, fpScale);
    HighRes := (PH.ImgFlags and ffHighRes <> 0);
    inc(fpPrinter^.RasterCount);

    {Perform horizontal scaling if enabled}
    if Scaling and (InputLen >= 3) then
      Scale200to300(Buffer^, InputLen, fpPrinter^.ScaleBuf^, OutLen)
    else begin
      FastMove(Buffer^, fpPrinter^.ScaleBuf^, InputLen);
      OutLen := InputLen;
    end;

    {Perform vertical scaling if appropriate}
    if Scaling and not(HighRes) and Odd(fpPrinter^.RasterCount) then
      Count := 2
    else
      Count := 1;

    {Prevent pack buffer overflow}
    if OutLen > (PackBufSize shr 3) div 3 then
      OutLen := (PackBufSize shr 3) div 3;

    for ICount := 1 to Count do begin
      {Update row RasterCountDown of PackBuf}
      asm
        push ds
        les  di,fpPrinter
        mov  ch,es:[di].FaxPrinter.RasterCountdown
        lds  si,es:[di].FaxPrinter.ScaleBuf
        les  di,es:[di].FaxPrinter.PackBuf

        mov  al,ch
        and  ch,7              {ch = shift count into output byte}
        neg  al
        add  al,23             {al = 23-RasterCountdown}
        xor  ah,ah
        shr  ax,1
        shr  ax,1
        shr  ax,1              {get the byte offset into the output buffer}
        add  di,ax

        mov  dx,si
        add  dx,OutLen         {dx = input offset terminator}
        jmp  @9

@1:     mov  ah,[si]           {ah = current input byte}
@2:     mov  al,ah
        shr  al,cl
        and  al,1
        xchg ch,cl
        shl  al,cl             {al = ((Input shr BitShift) and $01) shl RasterCountDown}
        xchg ch,cl
        or   es:[di],al        {or result into PackBuf}
        add  di,3              {next output byte}
        or   cl,cl             {bit shift = 0?}
        jz   @3                {jump if so}
        dec  cl                {decrement bit shift}
        jmp  @2                {do it again}
@3:     inc  si                {next byte of input}
@9:     mov  cl,7              {reset bit shift}
        cmp  si,dx             {all input used?}
        jb   @1                {jump if not}
        pop  ds
      end;

      {Dump PackBuf when 24 raster lines are combined and filled in}
      with fpPrinter^ do
        if HighRes and ((RasterCount and 3) = 0) then
          {Next raster line will combine with this one}
        else if RasterCountDown = 0 then begin
          RasterCountDown := 23;
          Epson24PrintGraphics(PackBuf^, PackBufSize, 24);
          if GetAsyncStatus <> ecOk then begin
            Epson24PrintRasterLine := True;
            Exit;
          end;
        end else
          Dec(RasterCountDown);
    end;

    {Call LineNotify routine}
    with fpPrinter^ do begin
      Inc(PrintedLineCount);
      if CallLineNotify(PrintedLineCount, InputLen) then begin
        Epson24PrintRasterLine := True;
        Exit;
      end;
    end;

    {No abort if we get here}
    Epson24PrintRasterLine := False;
  end;

  {---------- LaserJet-specific routines ----------}

  procedure TiffEncode( var InBuf ;     InLen  : Word;
                        var OutBuf; var OutLen : Word ); assembler;
  asm
    push ds

    mov  ax,InLen                 {get input length}
    or   ax,ax                    {is it zero?}
    jnz  @I1                      {jump if not}
    xor  di,di                    {return zero output length}
    jmp  @A

@I1:les  di,OutBuf                {di = current output offset}
    mov  dx,di                    {dx = saved starting output offset}
    mov  bx,di                    {bx = control byte offset}
    mov  byte ptr es:[bx],0       {reset initial control byte}

    lds  si,InBuf                 {si = current input offset}

    cmp  ax,1                     {is input length 1?}
    ja   @I2                      {jump if not}

    mov  al,[si]                  {get first input byte}
    mov  es:[bx+1],al             {store it past control byte}
    mov  di,2                     {output length is two}
    jmp  @A                       {exit}

@I2:cld                           {forward}
    mov  cx,si
    add  cx,ax                    {cx = offset just beyond end of input}

    mov  ax,[si]                  {does data start with a run?}
    cmp  ah,al
    je   @I3                      {jump if so}

    inc  di                       {prepare to store first input byte}
    mov  es:[di],al               {store it}
    inc  di                       {prepare to store next input byte}
    inc  si                       {we've used first input byte}

@I3:dec  si                       {first time in, adjust for next inc si}

@1: inc  si                       {next input byte}
    cmp  si,cx
    jae  @9                       {jump out if done}

    mov  ax,[si]                  {get next two bytes}
    cmp  ah,al                    {the same?}
    jne  @5                       {jump if not a run}
    mov  bx,di                    {save OutPos offset}
    mov  byte ptr es:[bx],0       {reset control byte}
    mov  es:[bx+1],al             {store run byte}

@2: inc  si                       {next input byte}
    cmp  si,cx                    {end of input?}
    jae  @3                       {jump if so}
    cmp  [si],al                  {still a run?}
    jne  @3                       {jump if not}
    cmp  byte ptr es:[bx],$81     {max run length?}
    je   @3                       {jump if so}
    dec  byte ptr es:[bx]         {decrement control byte}
    jmp  @2                       {loop}

@3: dec  si                       {back up one input character}
    inc  di                       {step past control and run bytes}
    inc  di
    jmp  @1                       {loop}

@5: cmp  byte ptr es:[bx],$7f     {run already in progress?}
    jb  @6                        {jump if not}
    mov  bx,di                    {start a new control sequence}
    mov  byte ptr es:[bx],0       {reset control byte}
    inc  di                       {next output position}
    jmp  @7
@6: inc  byte ptr es:[bx]         {increase non-run length}
@7: stosb                         {copy input byte to output}
    jmp  @1

@9: pop  ds
    sub  di,dx
@A: les  si,OutLen
    mov  es:[si],di
  end;

  { NOTE: This routine assumes that InLen is an even multiple of 2 }
  procedure NoScale200to150(var InBuf ;     InLen  : Word;
                            var OutBuf; var OutLen : Word); assembler;
  asm
    push  ds
    lds   si,InBuf
    les   di,OutBuf
    mov   cx,InLen
    shr   cx,1

    cmp   cx, ScaleBufSize  { test for OutBuf limits }
    jbe   @0
    mov   cx, ScaleBufSize  { reduce to upper limit }

@0: push  cx
    cld

@1: lodsw
    xchg  al,ah

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    shr   ax,1
    rcr   bx,1
    shr   ax,1
    rcr   dx,1

    or    bx,dx
    mov   es:[di],bh
    inc   di

    loop  @1

    pop   cx
    les   di,OutLen
    mov   es:[di],cx

    pop   ds
  end;

  { NOTE: This routine assumes that InLen is an integer multiple of 3 }
  procedure Scale200to150(var InBuf ;     InLen  : Word;
                          var OutBuf; var OutLen : Word); assembler;
  const
    ScaleBufDiv2 = ScaleBufSize div 2;

  asm
    push  ds

    lds   si,InBuf      { DS:SI->InBuf               }
    les   di,OutBuf     { ES:DI->OutBuf              }
    push  di            { save for later length calculation }
    cld                 { forward }
    mov   ax,InLen
    xor   dx,dx
    mov   cx,3
    div   cx
    mov   cx,ax         { cx = times through loop below }

    cmp   cx,ScaleBufDiv2  { test for OutBuf limits }
    jbe   @0
    mov   cx,ScaleBufDiv2  { reduce to upper limit }

@0: or    cx,cx         { can't use JCXZ...too much to jump over }
    jnz   @1
    jmp   @9

@1: lodsb
    shl   al,1      {i0..i2 -> o0..o1}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i3..i5 -> o2..o3}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i6..i8 -> o4..o5}
    rcl   bx,1
    shl   al,1
    rcl   dl,1

    lodsb

    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i9..i11 -> o6..o7}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i12..i14 -> o8..o9}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i15..i17 -> o10..o11}
    rcl   bx,1

    lodsb

    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i18..i20 -> o12..o13}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    shl   al,1      {i21..i23 -> o14..o15}
    rcl   bx,1
    shl   al,1
    rcl   dl,1
    shl   al,1
    rcl   dh,1
    or    dl,dh
    shr   dl,1
    rcl   bx,1

    mov   ax,bx
    xchg  ah,al
    stosw

    dec   cx
    jcxz  @9
    jmp   @1            { process next block of 3 input bytes }

@9: pop   bx
    sub   di,bx         { di = OutLen }
    les   si,OutLen
    mov   es:[si],di    { return in var parameter }

    pop   ds
  end;


  {---------- HP150Printer object ----------}

  procedure HP150PrintData(var Data; Size : Word);
  var
    S              : string[21];
    i              : Integer;
  begin
    with fpPrinter^ do begin
      {Any pending blank lines are printed first}
      if (BlankLinesToPrint > 0) then begin
        if fpOptionsAreOn(fpPrinter, fpSuppressBlanks) then begin
          if BlankLinesToPrint > MinBlankSpace then begin

            {Reduce the running line count by this amount}
            Dec(PrintedLineCount, BlankLinesToPrint - MinBlankSpace);
            BlankLinesToPrint := MinBlankSpace;
          end;
        end;

        if fpOptionsAreOn(fpPrinter, fpPCL5Mode) then begin
          S := PclBlankS + Long2Str(BlankLinesToPrint) + PclBlankE;
          AbstractPrintData(S[1], Length(S));
        end else begin
          S := PclXferS + '0' + PclXferE;
          for i := 1 to BlankLinesToPrint do
            AbstractPrintData(S[1], Length(S));
        end;

        {Clear blank line count}
        BlankLinesToPrint := 0;
      end;

      {Call ancestor to do the rest}
      AbstractPrintData(Data, Size);
    end;
  end;

  procedure HP150PrintStr(S : string);
  begin
    HP150PrintData(S[1], Length(S));
  end;

  function HP150MakeHeader : string;
  var
    S : string[100];
  begin
    with fpPrinter^ do
      S := 'Filename: ' + StUpCase(JustFileName(FaxName)) +
           ' Printed: ' + NowString + '  ' + TodayString +
           '                     Page ' + Long2Str(CurrentPage);

    {Start printing on second line if not using PCL5 mode}
    if not fpOptionsAreOn(fpPrinter, fpPCL5Mode) then
      S := ^M^J + S;
    HP150MakeHeader := S;
  end;

  procedure HP150StartNewPage;
  begin
    with fpPrinter^ do begin
      {No sense printing just blank lines if we're starting a new page}
      BlankLinesToPrint := 0;

      HP150PrintStr(PclInit);
      HP150PrintStr(PclSetMargin + Pcl150DPI);
      Inc(CurrentPage);

      {Print the page header}
      if fpOptionsAreOn(fpPrinter, fpHeader) then begin
        HP150PrintStr(HP150MakeHeader);

        {Start graphics mode}
        HP150PrintStr(PclStartGraph);

        {Push number of blank lines after header area}
        Inc(BlankLinesToPrint, AfterTextSpace div 2);
      end else
        {Start graphics mode}
        HP150PrintStr(PclStartGraph);

      if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then begin
        HP150PrintStr(PclTiffMode);
        {Print a line under the text}
        if fpOptionsAreOn(fpPrinter, fpHeader) then
          HP150PrintStr(PclLine150);
      end else begin
        {Print a line under the text}
        if fpOptionsAreOn(fpPrinter, fpHeader) then begin
          FillChar(PackBuf^, 150, $FF);
          HP150PrintStr(#27'*b150W');    {print divider line}
          HP150PrintData(PackBuf^, 150);
        end;
      end;

      RasterCount := 0;
      PrintedLineCount := 0;
    end;
  end;

  procedure HP150PrintOpen;
  begin
    AbstractPrintOpen;
    HP150StartNewPage;
  end;

  procedure HP150PrintClose;
  begin
    HP150PrintStr(PclEndGraph + PclInit);
    AbstractPrintClose;
  end;

  function HP150PrintRasterLine(UFP      : UnpackFaxPtr;
                                Buffer   : PByteBuffer;
                                InputLen : Word;
                                PH       : PageHeaderRec) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ELSE} far; {$ENDIF}
  var
    NewI      : Word;
    Limit     : Word;
    PackI     : Word;
    Bytes     : string[25];
    RLP       : LongInt;     {Real lines printed}                      {!!.01}

  begin
    SetAsyncStatus(ecOk);  {Clear status}
    HP150PrintRasterLine := False;

    {Check buffer to make sure it has at least 3 bytes}
    while InputLen < 3 do begin
      Buffer^[InputLen] := 0;
      Inc(InputLen);
    end;

    with fpPrinter^ do begin
      {Check if the page is full}
      if (PrintedLineCount >= MaxLinesPerPage - (ProbationArea div 2)) then begin
        {In the probation area}
        RLP := LongInt(PrintedLineCount) - BlankLinesToPrint;          {!!.01}
        if RLP >= MaxLinesPerPage then begin                           {!!.01}
          {Time to force a new page if this isn't a blank line}
          if NonZeroLen(Buffer^, InputLen) > 0 then begin
            HP150StartNewPage;
            if CallPageNotify(CurrentPage, TotalPages) then begin
              HP150PrintRasterLine := True;
              Exit;
            end;
          end;
        end;
      end;

      Limit := 0;
      Inc(RasterCount);
      if PH.ImgFlags and ffHighRes <> 0 then begin
        if RasterCount and 3 = 0 then
          Exit;
      end else if Odd(RasterCount) then
        Inc(Limit);

      {Handle special case for zero filled lines}
      if NonZeroLen(Buffer^, InputLen) = 0 then begin
        Inc(BlankLinesToPrint, Succ(Limit));
        Inc(PrintedLineCount, Succ(Limit));
        Exit;
      end;

      {Scale down fax raster line to PCL raster line, 200 -> 150}
      if fpOptionsAreOn(fpPrinter, fpScale) then
        Scale200to150(Buffer^, InputLen, ScaleBuf^, NewI)
      else
        NoScale200to150(Buffer^, InputLen, ScaleBuf^, NewI);

      {Use TIFF compression in PCL5 mode}
      if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then
        TiffEncode(ScaleBuf^, NewI, PackBuf^, PackI)
      else begin
        FastMove(ScaleBuf^, PackBuf^, NewI);
        PackI := NewI;
      end;

      {Send the raster data}
      HP150PrintStr(PclXferS);
      Bytes := Long2Str(PackI) + PclXferE;
      HP150PrintStr(Bytes);
      HP150PrintData(PackBuf^, PackI);
      Inc(PrintedLineCount);

      {Print every other raster line twice in standard resolution}
      if Limit > 0 then begin
        if fpOptionsAreOn(fpPrinter, fpPCL5Mode) then begin
          HP150PrintStr(PclDeltaMode);
          HP150PrintStr(PclRepLine);
        end else begin
          HP150PrintStr(PclXferS);
          HP150PrintStr(Bytes);
          HP150PrintData(PackBuf^, PackI);
        end;
        Inc(PrintedLineCount);

        {Switch back to proper mode}
        if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then
          HP150PrintStr(PclTiffMode);
      end;

      if GetAsyncStatus <> ecOk then
        HP150PrintRasterLine := True;

      if CallLineNotify(PrintedLineCount, InputLen) then
        HP150PrintRasterLine := True;
    end;
  end;

  {---------- HP300Printer object ----------}

  procedure HP300StartNewPage;
  begin
    with fpPrinter^ do begin
      {No sense printing just blank lines if we're starting a new page}
      BlankLinesToPrint := 0;

      HP150PrintStr(PclInit);
      HP150PrintStr(PclSetMargin + Pcl300DPI);

      Inc(CurrentPage);

      {Print the page header}
      if fpOptionsAreOn(fpPrinter, fpHeader) then begin
        HP150PrintStr(HP150MakeHeader);

        {Start graphics mode}
        HP150PrintStr(PclStartGraph);
        Inc(BlankLinesToPrint, AfterTextSpace);
      end else
        {Start graphics mode}
        HP150PrintStr(PclStartGraph);

      if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then begin
        HP150PrintStr(PclTiffMode);
        {Print a line under the text}
        if fpOptionsAreOn(fpPrinter, fpHeader) then
          HP150PrintStr(PclLine300)
      end else begin
        {Print a line under the text}
        if fpOptionsAreOn(fpPrinter, fpHeader) then begin
          FillChar(PackBuf^, 300, $FF);
          HP150PrintStr(#27'*b300W');    {print divider line}
          HP150PrintData(PackBuf^, 300);
        end;
      end;

      RasterCount := 0;
      PrintedLineCount := 0;
      BlankLinesToPrint := 0;
    end;
  end;

  procedure HP300PrintOpen;
  begin
    AbstractPrintOpen;
    HP300StartNewPage;
  end;

  procedure HP300PrintClose;
  begin
    HP150PrintClose;
  end;

  function HP300PrintRasterLine(UFP      : UnpackFaxPtr;
                                Buffer   : PByteBuffer;
                                InputLen : Word;
                                PH       : PageHeaderRec) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ELSE} far; {$ENDIF}
  var
    NewI      : Word;
    I         : Word;
    Limit     : Word;
    PackI     : Word;
    Bytes     : string[25];
    RLP       : LongInt;     {Real lines printed}                      {!!.01}

  begin
    SetAsyncStatus(ecOk);  {Clear status}
    HP300PrintRasterLine := False;

    {Check buffer to make sure it has at least 3 bytes}
    while InputLen < 3 do begin
      Buffer^[InputLen] := 0;
      Inc(InputLen);
    end;

    with fpPrinter^ do begin
      {Check if the page is full}
      if (PrintedLineCount >= MaxLinesPerPage - ProbationArea) then begin
        {In the probation area}
        RLP := LongInt(PrintedLineCount) - BlankLinesToPrint;          {!!.01}
        if RLP >= MaxLinesPerPage then begin                           {!!.01}
          {Time to force a new page if this isn't a blank line}
          if NonZeroLen(Buffer^, InputLen) > 0 then begin
            HP300StartNewPage;
            if CallPageNotify(CurrentPage, TotalPages) then begin
              HP300PrintRasterLine := True;
              Exit;
            end;
          end;
        end;
      end;

      {Compute number of times to print this raster line}
      Inc(RasterCount);
      if PH.ImgFlags and ffHighRes <> 0 then
        {Print every other raster line twice}
        if Odd(RasterCount) then
          Limit := 0
        else
          Limit := 1
      else
        {Print each raster line three times}
        Limit := 2;

      {Handle special case for zero lines}
      if NonZeroLen(Buffer^, InputLen) = 0 then begin
        Inc(BlankLinesToPrint, Succ(Limit));
        Inc(PrintedLineCount, Succ(Limit));
        Exit;
      end;

      {Scale up fax raster line to PCL raster line, 200 -> 300}
      if fpOptionsAreOn(fpPrinter, fpScale) then
        Scale200to300(Buffer^, InputLen, ScaleBuf^, NewI)
      else begin
        FastMove(Buffer^, ScaleBuf^, InputLen);
        NewI := InputLen;
      end;

      {Use TIFF compression in PCL5 mode}
      if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then
        TiffEncode(ScaleBuf^, NewI, PackBuf^, PackI)
      else begin
        FastMove(ScaleBuf^, PackBuf^, NewI);
        PackI := NewI;
      end;

      {Send raster data}
      HP150PrintStr(PclXferS);
      Bytes := Long2Str(PackI) + PclXferE;
      HP150PrintStr(Bytes);
      HP150PrintData(PackBuf^, PackI);
      Inc(PrintedLineCount);

      {Repeat raster line as necessary}
      if Limit > 0 then begin
        if fpOptionsAreOn(fpPrinter, fpPCL5Mode) then begin
          HP150PrintStr(PclDeltaMode);
          for I := 1 to Limit do begin
            HP150PrintStr(PclRepLine);
            Inc(PrintedLineCount);
          end;
        end else begin
          for I := 1 to Limit do begin
            HP150PrintStr(PclXferS);
            HP150PrintStr(Bytes);
            HP150PrintData(PackBuf^, PackI);
            Inc(PrintedLineCount);
          end;
        end;

        {Switch back to proper mode}
        if fpOptionsAreOn(fpPrinter, fpPcl5Mode) then
          HP150PrintStr(PclTiffMode);
      end;

      if GetAsyncStatus <> ecOk then
        HP300PrintRasterLine := True;

      if CallLineNotify(PrintedLineCount, InputLen) then
        HP300PrintRasterLine := True;
    end;
  end;


  { +++ Fax printing +++ }

  procedure PrintFaxDocument(AFP      : FaxPrinterPtr;
                             APrinter : PrinterType;
                             ADest    : PathStr;
                             AFaxName : PathStr);
  var
    I   : Word;
    FH  : FaxHeaderRec;
  begin
    fpPrinter := AFP;

    {Allocate unpack fax record}
    InitUnpacker(UF);
    if GetAsyncStatus <> ecOk then
      Exit;

    {Initialize fax printing variables}
    WhichPrinter := APrinter;
    with fpPrinter^ do begin
      PrnDest := ADest;
      FaxName := AFaxName;
      CurrentPage := 0;

      case WhichPrinter of
        Epson, Epson24 :
          begin
            {Set maximum raster lines per page}
            MaxLinesPerPage := $FFFF;
          end;
        HP150 :
          begin
            {Set maximum raster lines per page}
            MaxLinesPerPage := LinesPerPageLimit div 2;
            {Reduce raster lines per page for older PCL printers}
            if not fpOptionsAreOn(fpPrinter, fpPCL5Mode) then
              Dec(MaxLinesPerPage, Pcl4LineAdj div 2);
            MinBlankSpace := BLSSize div 2;
          end;
        HP300 :
          begin
            {Set maximum raster lines per page}
            MaxLinesPerPage := LinesPerPageLimit;
            {Reduce raster lines per page for older PCL printers}
            if not fpOptionsAreOn(fpPrinter, fpPCL5Mode) then
              Dec(MaxLinesPerPage, Pcl4LineAdj);
            MinBlankSpace := BLSSize;
          end;
      end;
    end;


    GetFaxHeader(UF, AFaxName, FH);
    if GetAsyncStatus = ecOk then begin
      {Tell the unpacker which output line function to call}
      case WhichPrinter of
        Epson : SetOutputLineFunc(UF, EpsonPrintRasterLine);
        Epson24 : SetOutputLineFunc(UF, Epson24PrintRasterLine);
        HP150 : SetOutputLineFunc(UF, HP150PrintRasterLine);
        HP300 : SetOutputLineFunc(UF, HP300PrintRasterLine);
      end;

      I := 1;
      fpPrinter^.TotalPages := FH.PageCount;
      repeat
        case WhichPrinter of
          Epson : EpsonPrintOpen;
          Epson24 : Epson24PrintOpen;
          HP150 : HP150PrintOpen;
          HP300 : HP300PrintOpen;
        end;
        if GetAsyncStatus = ecOk then begin
          with fpPrinter^ do
            if CallPageNotify(CurrentPage, TotalPages) then
              SetAsyncStatus(ecUserAbort);
          {Call unpacker to unpack the page}
          if GetAsyncStatus = ecOk then                                {!!.02}
            UnpackPage(UF, AFaxName, I);                               {!!.02}
          {Next page}
          Inc(I);
          case WhichPrinter of
            Epson : EpsonPrintClose;
            Epson24 : Epson24PrintClose;
            HP150 : HP150PrintClose;
            HP300 : HP300PrintClose;
          end;
        end;
      until (I > fpPrinter^.TotalPages) or (GetAsyncStatus <> ecOk);
    end;

    DoneUnpacker(UF);
  end;

end.
