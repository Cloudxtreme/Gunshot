{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O+,P-,Q-,R-,S-,T-,V+,X+,Y-}
Unit RipLink;


{$DEFINE MOUSE}          { is to be used or not.  DEBUGIT and DEBUGPAUSE  }

{Absolute coords - RipMouse.AddRegion}

interface

uses
  Dos, Graph, RipLink1,Crt;

const
  The79               = 80;
  The42               = 42;
  TheEndOfScreen      = 18;
  AnsiMaxParams       = 5;  {maximum parameters for our ansi interpreter}
  eNone               = 0;  {no command, ignore this char}
  eChar               = 1;  {no command, process the char}
  eGotoXY             = 2;  {absolute goto cursor position call}
  eUp                 = 3;  {cursor up}
  eDown               = 4;  {cursor down}
  eRight              = 5;  {cursor right}
  eLeft               = 6;  {cursor left}
  eClearBelow         = 7;  {clear screen below cursor}
  eClearAbove         = 8;  {clear screen above cursor}
  eClearScreen        = 9;  {clear entire screen}
  eClearEndofLine     = 10; {clear from cursor to end of line}
  eClearStartOfLine   = 11; {clear from cursor to the start of line}
  eClearLine          = 12; {clear entire line that cursor is on}
  eSetMode            = 13; {set video mode}
  eSetBackground      = 14; {set background attribute}
  eSetForeground      = 15; {set foreground attribute}
  eSetAttribute       = 16; {set video attribute (foreground and background)}
  eSaveCursorPos      = 17; {save cursor position}
  eRestoreCursorPos   = 18; {restore cursor position}
  eDeviceStatusReport = 19; {report device status or cursor position}
  eError              = 255;{indicates a parser error}
  Escape              = #27;
  LeftBracket         = #91;
  Semicolon           = #59;
  FormFeed            = #12;
  iQueueSize          = 32;

  TextOffsetX : array[0..4] of Byte = ( 8, 7, 8, 7,16);
  TextOffsetY : array[0..4] of Byte = ( 8, 8,14,14,14);
  TextMaxX    : array[0..4] of Byte = (The79,90,The79,90,39);
  TextMaxY    : array[0..4] of Byte = (The42,The42,24,24,24);

type
  Str2          = string[2];
  Str4          = string[4];
  Str12         = string[12];
  Str50         = string[50];

  fpt           = array[1..8] of byte;

  ParseStatus   = (None,Got_Excl,Got_Pipe,Got_Level,Got_SubLevel,Got_Command);
  CharStatus    = (cNone,Pending,ContLine,Escaped);
  LastCharStatus= (lNone,lChar,lCR,lLF,lPipe,lBackSlash,lExcl);

  MouseRegionRecord = record
    x0,y0,x1,y1     : word;
    invert,reset    : boolean;
    thetext         : str50;
  end; {61}

  QueueType = Array[1..255] of Char;
  QueuePtr  = ^QueueType;

  AnsiParserType = (GotNone,GotEscape,GotBracket,GotSemiColon,GotParam,GotCommand);

  CommandRecord = record
    Ch   : Char;
    Cmd  : Byte;
    X, Y : Byte;
  end;

  RootPtr = ^Root;
  Root = object
    constructor Init;
    destructor Done; virtual;
  end;

  RipPtr = ^RipObj;
  RipObj = object(Root)
    {general}
    TMaxX0, TMaxY0, TMaxX1, TMaxY1 : word;
    DefColor      : word;
    CurFont       : byte;
    CurSize       : byte;
    Metric        : MetricRec;
    ClipB         : Pointer;
    ClipSize      : word;
    IconDir       : DirStr;
    charfile      : file;
    FontPtr       : Pointer;
    FontSize      : word;
    DriverPtr     : Pointer;
    {button info}
    ButPlainWidth, ButPlainHeight, ButOrientation, ButFlags,
    ButBevelSize, ButLabelFore, ButLabelDropShadow, ButPlainHilite,
    ButPlainShadow, ButPlainSurface, ButGroupNum, ButFlags2,
    ButLabelUnderline, ButCorner : word;
    {mouse}
    {$IFDEF MOUSE}
    MouseExist    : boolean;
    LastStatus,           {used for CheckMouse}
    LastX,                { " }
    LastY         : word; { " }
    RegionArray   : Array[1..128] of MouseRegionRecord;
    LastButton    : Byte; {how many regions are there?}
    Inverted      : byte; {which region is currently inverted}
    CurRegion     : Byte; {temp var for CheckMouse}
    CurButton     : Byte; {which button are we working with?}
    KeyBuf        : Array[1..250] of Char; {Input Buffer}
    KeyBufHead    : Byte;                  {Head of Input Buffer}
    KeyBufTail    : Byte;                  {Tail of Input Buffer}
    {$ENDIF}
    {ansi parser}
    QueueSize     : Byte;      {size of our queue}
    aTextAttr     : Byte;      {set to Crt's TextAttr on Init}
    QueueIndex    : Byte;      {current index into queue}
    Queue         : QueuePtr;  {ptr to our queue}
    Params        : Array[1..AnsiMaxParams] of String[5]; {parameter strings}
    ParamInt      : Array[1..AnsiMaxParams] of Integer;   {params as ints}
    ParamIndex    : Byte;           {last param's index}
    Inverse       : Boolean;
    Intense       : Boolean;
    Blink         : Boolean;
    Invis         : Boolean;
    ParserState   : AnsiParserType;
    {rip parser}
    Level,SubLevel: byte;
    command       : char;
    firstcmd,
    nextcommand,
    commanddone,
    didrip        : boolean;
    pstat         : parsestatus;
    cstat         : charstatus;
    lstat         : lastcharstatus;
    lastc         : char;
    rBuffer       : Array[1..1024] of char;
    bufcount      : word;
    {text window}                     {char/color}
    VirtualWindow : Array[0..90,0..42,0..1] of Byte;
    TextX0        : byte;
    TextY0        : byte;
    TextX1        : byte;
    TextY1        : byte;
    TextSize      : byte; {8x8/7x8/8x14/7x14/16x14}
    TextWrap      : boolean;
    TextActive    : boolean;
    TextClr       : byte; {color}
    CursorX       : word;
    CursorY       : word;
    CursorSaveX   : word;
    CursorSaveY   : word;
    CursorOn      : boolean;
    CmdRec        : CommandRecord; {for ansi parser}
    TextFontFile  : File of CharMapRecord;
    TextChar      : CharMapRecord;
    {other}

    constructor Init(userip : boolean;fontname:string);
    procedure   RipTextWindow(x0,y0,x1,y1 : byte; wrap : boolean; size : byte);
    procedure   RipViewPort(x0,y0,x1,y1 : word);
    procedure   RipResetWindows;
    procedure   RipEraseWindow;
    procedure   RipEraseView;
    procedure   RipGotoXY(x0,y0 : byte);
    procedure   RipHome;
    procedure   RipEraseEOL;
    procedure   RipColor(clr : byte);
    procedure   RipSetPalette(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16 : word);
    procedure   RipOnePalette(color,value : word);
    procedure   RipWriteMode(mode : byte);
    procedure   RipMove(x0,y0 : word);
    procedure   RipText(instr : string);
    procedure   RipTextXY(x0,y0 : word; instr : string);
    procedure   RipFontStyle(font, direct, size : byte);
    procedure   RipPixel(x0,y0 : word);
    procedure   RipLine(x0,y0,x1,y1 : word);
    procedure   RipRectangle(x0,y0,x1,y1 : word);
    procedure   RipBar(x0,y0,x1,y1 : word);
    procedure   RipCircle(x0,y0,radius : word);
    procedure   RipOval(x0,y0,stangle,endangle,xrad,yrad : word);
    procedure   RipFilledOval(x0,y0,xrad,yrad : word);
    procedure   RipArc(x0,y0,stangle,endangle,rad : word);
    procedure   RipOvalArc(x0,y0,stangle,endangle,xrad,yrad : word);
    procedure   RipPieSlice(x0,y0,stangle,endangle,rad : word);
    procedure   RipOvalPieSlice(x0,y0,stangle,endangle,radx,rady : word);
    procedure   RipBezier(x0,y0,x1,y1,x2,y2,x3,y3,count : word);
    procedure   RipPolygon(numpoints : word; var polypoints);
    procedure   RipFillPoly(numpoints : word; var polypoints);
    procedure   RipPolyLine(NumPoints : word; var polypoints);
    procedure   RipFill(x0,y0,border : word);
    procedure   RipLineStyle(style,pattern,thick : word);
    procedure   RipFillStyle(style,color : word);
    procedure   RipFillPattern(pattern : fpt; color : word);
    procedure   RipMouse(x0,y0,x1,y1 : word; click, clear : boolean; instr : string);
    procedure   RipKillMouseFields;
    procedure   RipGetImage(x0,y0,x1,y1 : word);
    procedure   RipPutImage(x0,y0,mode : word);
    procedure   RipWriteIcon(fname : str12);
    procedure   RipLoadIcon(x0,y0,mode : word; clipbrd : boolean; fname : str12);
    procedure   RipButtonStyle(wid,hgt,orient,flags,bevsize,dfore,dback,bright,dark,
                               surface,grp_no,flags2,uline_col,corner_col : word);
    procedure   RipButton(x0,y0,x1,y1,hotkey : word; flags : byte; icon : str12; sLabel : string; Cmd : string);
    procedure   StatLine;
    destructor  Done; virtual;
    Procedure   ResetParser;
    Procedure   ResetParser2(c:char);
    Procedure   DumpBuffer;
    Procedure   DumpBuffer2;
    Procedure   ParseRipStr(s:string;sendchar:boolean);
    Procedure   ParseRip(c : char; sendchar : boolean);
    Procedure   DoTextStr(s:string);
    Procedure   DoTextChar(c:char);
    {$IFDEF MOUSE}
    Procedure   MouseInit;
    Procedure   MouseOn;
    Procedure   MouseOff;
    Procedure   GetPosition(var ButtonStatus,xPos,yPos:Integer);
    Procedure   SetMousePos(x,y:Integer);
    Procedure   IsButtonDown(Button:Integer; var Status,DnCount,xPos,yPos:Integer);
    Procedure   IsButtonUp(Button:Integer; var Status,UpCount,xPos,yPos:Integer);
    Procedure   CheckMouse;
    Function    InRegion(x,y:word):byte;
    Procedure   DoInvert(region:byte;InvertIt:boolean);
    Procedure   AddRegion(x0,y0,x1,y1:word;invert,reset:boolean;thetext:str50);
    Function    CharInBuffer: boolean;
    Function    GetNextChar:char;
    Procedure   AddString(st:string);
    Procedure   KillRegions;
    Procedure   KillBuffer;
    {$ENDIF}
    private
    Procedure rTextWindow(x0,y0,x1,y1:byte; wrap:boolean; size:byte);
    Procedure rViewPort(x0,y0,x1,y1:word);
    Procedure rResetWindows;
    Procedure rEraseWindow;
    Procedure rEraseView;
    Procedure rGotoXY(x0,y0:byte);
    Procedure rHome;
    Procedure rEraseEOL;
    Procedure rColor(clr:byte);
    Procedure rSetPalette(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16:word);
    Procedure rOnePalette(color,value:word);
    Procedure rWriteMode(mode:byte);
    Procedure rMove(x0,y0:word);
    Procedure rText(instr:string);
    Procedure rTextXY(x0,y0:word; instr:string);
    Procedure rFontStyle(font,direct,size:byte);
    Procedure rPixel(x0,y0:word);
    Procedure rLine(x0,y0,x1,y1:word);
    Procedure rRectangle(x0,y0,x1,y1:word);
    Procedure rBar(x0,y0,x1,y1:word);
    Procedure rCircle(x0,y0,radius:word);
    Procedure rOval(x0,y0,stangle,endangle,xrad,yrad:word);
    Procedure rFilledOval(x0,y0,xrad,yrad:word);
    Procedure rArc(x0,y0,stangle,endangle,rad:word);
    Procedure rPieSlice(x0,y0,stangle,endangle,rad:word);
    Procedure rOvalPieSlice(x0,y0,stangle,endangle,radx,rady:word);
    Procedure rBezier(x0,y0,x1,y1,x2,y2,x3,y3,count:word);
    Procedure rPolygon(numpoints:word; var PolyPoints; Complete:boolean);
    Procedure rFillPoly(numpoints:word; var polypoints);
    Procedure rFill(x0,y0,border:word);
    Procedure rLineStyle(style,pattern,thick:word);
    Procedure rFillStyle(style,color:word);
    Procedure rFillPattern(pattern:fpt; color:word);
    Procedure rMouse(x0,y0,x1,y1:word; inv,reset:boolean; instr:string);
    Procedure rKillMouse;
    Procedure rGetImage(x0,y0,x1,y1:word);
    Procedure rPutImage(x0,y0,mode:word);
    Procedure rWriteIcon(fname:str12);
    Procedure rLoadIcon(x0,y0,mode:word; clipbrd:boolean; fname:str12);
    Procedure rButtonStyle(wid,hgt,orient,flags,bevsize,dfore,dback,bright,dark,
                           surface,grp_no,flags2,uline_col,corner_col:word);
    Procedure rButton(tx0,ty0,tx1,ty1,hotkey:word; flags:byte; icon:str12; sLabel,Cmd:string);

    Function  MegaBuf(tpos,a,b:byte):word;
    Function  UnEscapeString(bStart,bEnd:word):string;
    Function  DoRipChar(c : char): boolean;

    procedure ProcessChar(C : Char; var pCommand : CommandRecord);
    procedure PutQueue(C : Char);
    procedure InitParser;
    procedure BuildParam(C : Char);
    procedure ConvertParams(C : Char);
    procedure MakeCommand(C : Char; var pCommand : CommandRecord);

    Procedure DispChar(c:char);
  end;

var
  RIPScriptFont        : word;
  RIPSimplexFont       : word;
  RIPTriplexScriptFont : word;
  RIPComplexFont       : word;
  RIPEuropeanFont      : word;
  RIPBoldFont          : word;
  RIPMouseOverride     : Boolean;
  RIPStat1             : String[40];
  RIPStat2             : String[5];
  RIPStat3             : String[4];
  RIPStat4             : String[6];
  RIPStat5             : String[6];
  oRIPStat1            : String[40];
  oRIPStat2            : String[5];
  oRIPStat3            : String[4];
  oRIPStat4            : String[6];
  oRIPStat5            : String[6];

Implementation


Uses FMode,BsString;


Var
  Regs           : registers;


Constructor Root.Init;
begin
end;

Destructor Root.Done;
begin
end;

Procedure RipObj.rTextWindow(x0,y0,x1,y1:byte; wrap:boolean; size:byte);
begin
    textx0 := x0;     texty0 := y0;
    textx1 := x1;     texty1 := y1;
    textsize := size; textwrap := wrap;
    if (x0=0) and (y0=0) and (x1=0) and (y1=0) then
      textactive := false
    else
    begin
      textactive := true;
      textclr := 15;
      fillchar(virtualwindow,7826,#0);
      rHome;
    end;
    statline;
end;

Procedure RipObj.rViewPort(x0,y0,x1,y1:word);
begin
    IF (y1>GetMaxY-TheEndOfScreen) THEN y1 := GetMaxY-TheEndOfScreen;
    setviewport(x0,y0,x1,y1,true);
    statline;
end;

Procedure RipObj.rResetWindows;
begin
    {$IFDEF MOUSE}
    KillRegions;
    {$ENDIF}
    textx0 := 0;  texty0 := 0;
    textx1 := The79; texty1 := The42;
    textsize := 0;
    textwrap := true;
    textactive := true;
    textclr := 15;
    cursorx := 0; cursory := 0;
    cursoron := false;
    fillchar(virtualwindow,7826,#0);
    graphdefaults;
    SetViewPort(0,0,GetMaxX,GetMaxY-TheEndOfScreen,True);
    ClearViewPort;
    settextjustify(lefttext,toptext);
    DefColor := GetColor;
    CurFont := 0;
    CurSize := 1;
    Metric := MetricArray[CurFont,CurSize];
    if clipb <> nil then
    begin
      FreeMem(ClipB,ClipSize);
      ClipSize := 0;
      ClipB := nil;
    end;
    statline;
end;

Procedure RipObj.rEraseWindow;
var
  fst : fillsettingstype;
begin
    getfillsettings(fst);
    setfillstyle(0,fst.color);
    fillchar(virtualwindow,7826,#0);
    Bar(TextOffsetX[textsize]*textx0,TextOffsetY[textsize]*texty0,
        TextOffsetX[textsize]*(textx1+1)-1,TextOffsetY[textsize]*(texty1+1)-1);
    setfillstyle(fst.pattern,fst.color);
    rHome;
    statline;
end;

Procedure RipObj.rEraseView;
begin
    ClearViewPort;
    statline;
end;

Procedure RipObj.rGotoXY(x0,y0:byte);
begin
    cursorx := {textx0+}x0;
    cursory := {texty0+}y0;
end;

Procedure RipObj.rHome;
begin
    cursorx := textx0;
    cursory := texty0;
end;

Procedure RipObj.rEraseEOL;
var
  fst : fillsettingstype;
  ctr : byte;
begin
  if TextActive then
  begin
    getfillsettings(fst);
    setfillstyle(0,fst.color);
    {fillchar(virtualwindow,7826,#0);}
    Bar(TextOffsetX[textsize]*cursorx,TextOffsetY[textsize]*cursory,
        TextOffsetX[textsize]*(textx1+1)-1,TextOffsetY[textsize]*(cursory+1)-1);
    setfillstyle(fst.pattern,fst.color);
    for ctr := cursorx to TextMaxX[textsize] do
      virtualwindow[ctr,cursory,0] := 0;
    rHome;
    statline;
  end;
end;

Procedure RipObj.rColor(clr:byte);
begin
    SetColor(clr);
    DefColor := clr;
end;

Procedure RipObj.rSetPalette(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16:word);
var
  palette       : palettetype;
begin
  with palette do
  begin
    size := 16;
    colors[0]  := c1;
    colors[1]  := c2;
    colors[2]  := c3;
    colors[3]  := c4;
    colors[4]  := c5;
    colors[5]  := c6;
    colors[6]  := c7;
    colors[7]  := c8;
    colors[8]  := c9;
    colors[9]  := c10;
    colors[10] := c11;
    colors[11] := c12;
    colors[12] := c13;
    colors[13] := c14;
    colors[14] := c15;
    colors[15] := c16;
  end;
  SetAllPalette(Palette);
end;

Procedure RipObj.rOnePalette(color,value:word);
begin
  SetPalette(color,value);
end;

Procedure RipObj.rWriteMode(mode:byte);
begin
  SetWriteMode(mode);
end;

Procedure RipObj.rMove(x0,y0:word);
begin
  MoveTo(x0,y0);
end;

Procedure RipObj.rText(instr:string);
begin
    settextjustify(lefttext,toptext);
    OutText(instr);
end;

Procedure RipObj.rTextXY(x0,y0:word; instr:string);
begin
  settextjustify(lefttext,toptext);
  outtextxy(x0,y0,instr);
end;

Procedure RipObj.rFontStyle(font,direct,size:byte);
begin
    IF ((CurFont<>font) OR (CurSize<>Size)) THEN
    BEGIN
      if fontptr <> nil then
      begin
        freemem(fontptr,fontsize);
        fontptr := nil;
      end;
      case font of
        1  : begin fontsize := 16677; seek(charfile,  5527); end;
        2  : begin fontsize :=  5131; seek(charfile, 22204); end;
        3  : begin fontsize := 13596; seek(charfile, 27335); end;
        4  : begin fontsize := 18063; seek(charfile, 40931); end;
        5  : begin fontsize := 10987; seek(charfile, 58994); end;
        6  : begin fontsize :=  8437; seek(charfile, 69981); end;
        7  : begin fontsize := 17355; seek(charfile, 78418); end;
        8  : begin fontsize := 12083; seek(charfile, 95773); end;
        9  : begin fontsize :=  8439; seek(charfile,107856); end;
        10 : begin fontsize := 14670; seek(charfile,116295); end;
      end;
      if font <> 0 then
      begin
        getmem(fontptr,fontsize);
        blockread(charfile,fontptr^,fontsize);
        if registerbgifont(fontptr) < 0 then ;
      end;
    END;
    SetTextStyle(font,direct,size);
    CurFont := font;
    CurSize := size;
    Metric := MetricArray[CurFont,CurSize];
end;

Procedure RipObj.rPixel(x0,y0:word);
begin
    PutPixel(x0,y0,defcolor);
end;

Procedure RipObj.rLine(x0,y0,x1,y1:word);
begin
    Line(x0,y0,x1,y1);
end;

Procedure RipObj.rRectangle(x0,y0,x1,y1:word);
begin
    Rectangle(x0,y0,x1,y1);
end;

Procedure RipObj.rBar(x0,y0,x1,y1:word);
begin
    Bar(x0,y0,x1,y1);
end;

Procedure RipObj.rCircle(x0,y0,radius:word);
begin
    Circle(x0,y0,radius);
end;

Procedure RipObj.rOval(x0,y0,stangle,endangle,xrad,yrad:word);
begin
    Ellipse(x0,y0,stangle,endangle,xrad,yrad);
end;

Procedure RipObj.rFilledOval(x0,y0,xrad,yrad:word);
begin
    FillEllipse(x0,y0,xrad,yrad);
end;

Procedure RipObj.rArc(x0,y0,stangle,endangle,rad:word);
begin
    Arc(x0,y0,stangle,endangle,rad);
end;

Procedure RipObj.rPieSlice(x0,y0,stangle,endangle,rad:word);
begin
    PieSlice(x0,y0,stangle,endangle,rad);
end;

Procedure RipObj.rOvalPieSlice(x0,y0,stangle,endangle,radx,rady:word);
begin
    Sector(x0,y0,stangle,endangle,radx,rady);
end;

Procedure RipObj.rBezier(x0,y0,x1,y1,x2,y2,x3,y3,count:word);
type
  coord = record
    x,y : integer;
  end;

  CurveDataRec = array[0..65521 div sizeof(coord)] of coord;

var
  bezarray                  : array [0..3] of coord;

  procedure drawBezier(var d0:coord;nPoints,nSteps:word; colr : byte);
  {Formula:            3            2       2           3
         Q(t) = (1 - t) P1 + 3t(1-t) P2 + 3t (1-t)P3 + t P4
  }
  const
    nsa = 1/6;
    nsb = 2/3;
  var
    i,i2,i3,xx,yy                             : integer;
    t,tm3,t2,t2m3,t3,t3m3,nc1,nc2,nc3,nc4,step: real;
    d                                         : curveDataRec absolute d0;
    oldx, oldy                                : integer;
  begin
    step := 1/nSteps;
    oldx := d[0].x;
    oldy := d[0].y;
    setcolor(colr);
    for i2 := 0 to pred(nPoints) div 4 do
    begin
      i := i2*4;
      t := 0.0;
      for i3 := pred(nSteps) downto 0 do
      begin
        t    := t+step;
{        t2   := (1-t);
        xx := round(t2*t2*t2*d[i].x + 3.0*t*t2*t2*d[i+1].x +
                    3.0*t*t*t2*d[i+2].x +   t*t*t*d[i+3].x);
        yy := round(t2*t2*(1-t)*d[i].y + 3.0*t*t2*t2*d[i+1].y +
                    3.0*t*t*t2*d[i+2].y +   t*t*t*d[i+3].y);
}
        tm3  := t*3.0;
        t2   := t*t;
        t2m3 := t2*3.0;
        t3   := t2*t;
        t3m3 := t3*3.0;
        nc1  := 1-tm3+t2m3-t3;
        nc2  := t3m3-2.0*t2m3+tm3;
        nc3  := t2m3-t3m3;
        nc4  := t3;
        xx := trunc(nc1*d[i].x+nc2*d[succ(i)].x+nc3*d[i+2].x+nc4*d[i+3].x);
        yy := trunc(nc1*d[i].y+nc2*d[succ(i)].y+nc3*d[i+2].y+nc4*d[i+3].y);
        if (oldx = 0) and (oldy = 0) then
        begin
          putpixel(xx,yy, colr);
          oldx := xx;
          oldy := yy;
        end
        else
        begin
          line(oldx, oldy, xx, yy);
          oldx := xx;
          oldy := yy;
        end;
      end;
    end;
  end;

begin
  bezarray[0].X := x0;
  bezarray[0].Y := y0;
  bezarray[1].X := x1;
  bezarray[1].Y := y1;
  bezarray[2].X := x2;
  bezarray[2].Y := y2;
  bezarray[3].X := x3;
  bezarray[3].Y := y3;
  drawBezier(bezarray[0],4,count,defcolor);
end;

Procedure RipObj.rPolygon(numpoints:word; var PolyPoints; complete:boolean);
type
  PointRec = record
    X : word;
    Y : word;
  end;

  TempType = Array[1..512] of PointRec;
var
  polytemp : temptype;
begin
    polytemp := temptype(polypoints);
    if complete then
    begin
      polytemp[numpoints+1].X := polytemp[1].X;
      polytemp[numpoints+1].Y := polytemp[1].Y;
      drawpoly(numpoints+1,polytemp);
    end
    else
      drawpoly(numpoints,polytemp);
end;

Procedure RipObj.rFillPoly(numpoints:word; var polypoints);
begin
    fillpoly(numpoints,polypoints);
end;

Procedure RipObj.rFill(x0,y0,border:word);
begin
    FloodFill(x0,y0,border);
end;

Procedure RipObj.rLineStyle(style,pattern,thick:word);
begin
  SetLineStyle(style,pattern,thick);
end;

Procedure RipObj.rFillStyle(style,color:word);
begin
  SetFillStyle(style,color);
end;

Procedure RipObj.rFillPattern(pattern:fpt; color:word);
begin
  SetFillStyle(UserFill,color);
  SetFillPattern(fillpatterntype(pattern),color);
end;

Procedure RipObj.rMouse(x0,y0,x1,y1:word; inv,reset:boolean; instr:string);
begin
  {$IFDEF MOUSE}
  AddRegion(x0,y0,x1,y1,inv,reset,instr);
  {$ENDIF}
end;

Procedure RipObj.rKillMouse;
begin
  {$IFDEF MOUSE}
  KillRegions;
  {$ENDIF}
end;

Procedure RipObj.rGetImage(x0,y0,x1,y1:word);
begin
    if ClipB <> nil then
    begin
      FreeMem(ClipB,ClipSize);
      ClipSize := 0;
      ClipB := nil;
    end;
    ClipSize := ImageSize(x0,y0,x1,y1);
    GetMem(ClipB,ClipSize);
    GetImage(x0,y0,x1,y1,ClipB^);
end;

Procedure RipObj.rPutImage(x0,y0,mode:word);
begin
    if ClipB = nil then
      Exit;
    PutImage(x0,y0,ClipB^,mode);
end;

Procedure RipObj.rWriteIcon(fname:str12);
var
  IcnFile       : File;
  tname         : string;
begin
    if ClipB = nil then
      Exit;
    filemode := SetFileMode;
    tname := backslash(icondir)+fname;
    if pos('.',tname) = 0 then
      tname := tname + '.ICN';
    assign(IcnFile,tname);
    {$I-}
    rewrite(IcnFile,1);
    {$I+}
    if IOresult <> 0 then
    begin
      exit;
    end;
    blockwrite(IcnFile,ClipB^,ClipSize);
    close(icnfile);
end;

Procedure RipObj.rLoadIcon(x0,y0,mode:word; clipbrd:boolean; fname:str12);
var
  cb            : pointer;
  cb2           : pointer;
  cbsize        : word;
  IcnFile       : file;
  thewid,thehgt : word;
begin
    filemode := SetFileMode;
    assign(icnfile,backslash(IconDir)+fname);
    {$I-}
    reset(icnfile,1);
    if IOresult <> 0 then
      exit;
    {$I+}
    seek(IcnFile,0);
    blockread(IcnFile,thewid,2);
    blockread(IcnFile,thehgt,2);
    cbsize := ImageSize(0,0,thewid,thehgt);
    getmem(cb,cbsize);
    seek(IcnFile,0);
    blockread(IcnFile,cb^,cbsize);
    close(icnfile);
    PutImage(x0,y0,cb^,mode);
    if clipbrd then
    begin
      if clipb <> nil then
      begin
        FreeMem(ClipB,ClipSize);
        ClipSize := 0;
        ClipB := nil;
      end;
      clipsize := cbsize;
      GetMem(ClipB,ClipSize);
      Move(cb^,clipb^,clipsize);
    end;
    freemem(cb,cbsize);
end;

Procedure RipObj.rButtonStyle(wid,hgt,orient,flags,bevsize,dfore,dback,bright,dark,
                              surface,grp_no,flags2,uline_col,corner_col:word);
begin
  ButPlainWidth       := wid;
  ButPlainHeight      := hgt;
  ButOrientation      := orient;
  ButFlags            := flags;
  ButBevelSize        := bevsize;
  ButLabelFore        := dfore;
  ButLabelDropShadow  := dback;
  ButPlainHilite      := bright;
  ButPlainShadow      := dark;
  ButPlainSurface     := surface;
  ButGroupNum         := grp_no;
  ButFlags2           := flags2;
  ButLabelUnderline   := uline_col;
  ButCorner           := corner_col;
end;

Procedure RipObj.rButton(tx0,ty0,tx1,ty1,hotkey:word; flags:byte; icon:str12; sLabel,Cmd:string);
type
  IconHdr = record
    tWid,
    tHgt : word;
  end;

var
  Trapezoid : array[1..4] of PointType;

  BClip, BInvertable, BReset, BChisel, BRecess, BDropShadow, BImage2Clip,
  BIconBut, BPlainBut, BBevel, BMouse, BUline, BHotIcons, BAdjustVert,
  BRadio, BSunken, BCheckbox, BHilite, BExplode, BLeftJust, BRightJust   : Boolean;

  X0,Y0,X1,Y1                   : integer;
  bWid,bHgt,tWid,tHgt,tX,tY     : integer;
  TempX0,TempY0,TempX1,TempY1   : integer;
  RecessTemp                    : Word;
  T2                            : Word;
  tst                           : TextSettingsType;
  lst                           : LineSettingsType;
  col                           : word; {color}
  DoneHilite                    : boolean;
  XChisel, YChisel              : Byte;

  cb            : pointer;
  cb2           : pointer;
  cbsize        : word;
  IcnFile       : file;
  thewid,thehgt : word;

  Function FlagOn(Flags : Word; FlagMask : Word) : Boolean;
  begin
    FlagOn := (Flags and FlagMask) <> 0;
  end;

  procedure SetFlagOn(var Flags : Word; FlagMask : Word);
  begin
    Flags := Flags or FlagMask;
  end;

  procedure SetFlagOff(var Flags : Word; FlagMask : Word);
  begin
    Flags := Flags and not FlagMask;
  end;

  Procedure PutItXY(x,y : word; thelabel : string);
  var
    thecounter : byte;
  begin
    MoveTo(x,y);
    for thecounter := 1 to length(thelabel) do
    begin
      if (not donehilite) and (upcase(thelabel[thecounter]) = char(hotkey)) then
      begin
        setcolor(ButLabelUnderline);
        OutText(thelabel[thecounter]);
        setcolor(ButLabelFore);
        donehilite := true;
      end
      else
        OutText(thelabel[thecounter]);
    end;
  end;

  Function Real_TextHeight: word;
  begin
    Real_TextHeight := Metric.Base - Metric.Top + 1;
  end;

  Function Contains_DropDown(st:string): boolean;
  var
    ct : byte;
  begin
    contains_dropdown := true;
    for ct := 1 to length(st) do
    begin
      if low_char[ord(st[ct])] = 1 then
        exit;
    end;
    contains_dropdown := false;
  end;

begin
    GetTextSettings(tst);
    GetLineSettings(lst);
    Col := GetColor;
    SetColor(0);
    {SetTextStyle(defaultfont,horizdir,1);}
    SetLineStyle(SolidLn,0,NormWidth);

{+} BClip := FlagOn(ButFlags,1);
{+} BInvertable := FlagOn(ButFlags,2);
{+} BReset := FlagOn(ButFlags,4);
{+} BChisel := FlagOn(ButFlags,8);
{+} BRecess := FlagOn(ButFlags,16);
{+} BDropShadow := FlagOn(ButFlags,32);
{+} BImage2Clip := FlagOn(ButFlags,64);
{+} BIconBut := FlagOn(ButFlags,128);
{+} BPlainBut := FlagOn(ButFlags,256);
{+} BBevel := FlagOn(ButFlags,512);
{+} BMouse := FlagOn(ButFlags,1024);
{-} BUline := FlagOn(ButFlags,2048);
{-} BHotIcons := FlagOn(ButFlags,4096);
{+} BAdjustVert := FlagOn(ButFlags,8192);
{-} BRadio := FlagOn(ButFlags,16384);
{+} BSunken := FlagOn(ButFlags,32768);
{-} BCheckbox := FlagOn(ButFlags2,1);
{+} BHilite := FlagOn(ButFlags2,2);
{-} BExplode := FlagOn(ButFlags2,4);
{+} BLeftJust := FlagOn(ButFlags2,8);
{+} BRightJust := FlagOn(ButFlags2,16);
    if not BMouse then
    begin
      BUline := false;
      BInvertable := false;
      BReset := false;
      BHotIcons := false;
      BRadio := false;
      BCheckbox := false;
      BHilite := false;
      BExplode := false;
    end;
    if not BIconBut then
    begin
      BHotIcons := false;
    end;
    if BHilite then
      DoneHilite := false
    else
      DoneHilite := true;

    {x/y adjustments based on button type go here}
    x0 := tx0;
    y0 := ty0;
    x1 := tx1;
    y1 := ty1;
    if BPlainBut and ((tx1 = 0) and (ty1 = 0)) then
    begin
      x1 := tx0+ButPlainWidth;
      y1 := ty0+ButPlainHeight;
    end;
    if BIconBut then
    begin
      filemode := SetFileMode;
      assign(icnfile,backslash(IconDir)+icon);
      {$I-}
      reset(icnfile,1);
      {$I+}
      if IOresult <> 0 then
      begin
        exit;
      end;
      seek(IcnFile,0);
      blockread(IcnFile,thewid,2);
      blockread(IcnFile,thehgt,2);
      cbsize := ImageSize(0,0,thewid,thehgt);
      x1 := tx0+thewid;
      y1 := ty0+thehgt;
      getmem(cb,cbsize);
      seek(IcnFile,0);
      blockread(IcnFile,cb^,cbsize);
      close(icnfile);
    end;
    if BClip then
    begin
      if clipb <> nil then
      begin
        thewid := iconhdr(clipb^).tWid;
        thehgt := iconhdr(clipb^).tHgt;
        x1 := tx0+thewid;
        y1 := ty0+thehgt;
      end;
    end;

    SetColor(ButPlainSurface);
    SetFillStyle(SolidFill,ButPlainSurface);
    Bar(x0,y0,x1,y1);
    if BSunken then
    begin
      SetColor(ButPlainShadow);
      Line(x0,y0,x1,y0);
      Line(x0,y0,x0,y1);
      SetColor(ButPlainHiLite);
      Line(x0,y1,x1,y1);
      Line(x1,y0,x1,y1);
      SetColor(ButCorner);
      PutPixel(x0,y0,ButCorner);
      PutPixel(x1,y0,ButCorner);
      PutPixel(x0,y1,ButCorner);
      PutPixel(x1,y1,ButCorner);
    end;
    if BRecess then
    begin
      if BBevel then
        RecessTemp := ButBevelSize+2
      else
        RecessTemp := 2;
      SetColor(0);
      Rectangle(x0-recesstemp+1,y0-recesstemp+1,x1+recesstemp-1,y1+recesstemp-1);

      SetColor(ButPlainShadow);
      Line(x0-RecessTemp,y0-RecessTemp,x1+RecessTemp,y0-RecessTemp);
      Line(x0-RecessTemp,y0-RecessTemp,x0-RecessTemp,y1+RecessTemp);
      SetColor(ButPlainHiLite);
      Line(x1+RecessTemp,y0-RecessTemp,x1+RecessTemp,y1+RecessTemp);
      Line(x0-RecessTemp,y1+RecessTemp,x1+RecessTemp,y1+RecessTemp);
      SetColor(ButCorner);
      PutPixel(x0-RecessTemp,y0-RecessTemp,ButCorner);
      PutPixel(x1+RecessTemp,y0-RecessTemp,ButCorner);
      PutPixel(x0-RecessTemp,y1+RecessTemp,ButCorner);
      PutPixel(x1+RecessTemp,y1+RecessTemp,ButCorner);
    end;
    if BBevel then
    begin
      SetLineStyle(SolidLn,0,1);
      SetFillStyle(SolidFill,ButPlainHiLite);
      SetColor(ButPlainHiLite);
      Trapezoid[1].X := x0-ButBevelSize;  Trapezoid[1].Y := y0-ButBevelSize;
      Trapezoid[2].X := x0-1;             Trapezoid[2].Y := y0-1;
      Trapezoid[4].X := x1+ButBevelSize;  Trapezoid[4].Y := y0-ButBevelSize;
      Trapezoid[3].X := x1+1;             Trapezoid[3].Y := y0-1;
      FillPoly(4,Trapezoid);
      Trapezoid[4].X := x0-ButBevelSize;  Trapezoid[4].Y := y1+ButBevelSize;
      Trapezoid[3].X := x0-1;             Trapezoid[3].Y := y1+1;
      FillPoly(4,Trapezoid);
      SetFillStyle(SolidFill,ButPlainShadow);
      SetColor(ButPlainShadow);
      Trapezoid[1].X := x1+ButBevelSize;  Trapezoid[1].Y := y1+ButBevelSize;
      Trapezoid[2].X := x1+1;             Trapezoid[2].Y := y1+1;
      FillPoly(4,Trapezoid);
      Trapezoid[4].X := x1+ButBevelSize;  Trapezoid[4].Y := y0-ButBevelSize;
      Trapezoid[3].X := x1+1;             Trapezoid[3].Y := y0-1;
      FillPoly(4,Trapezoid);
      SetColor(ButCorner);
      Line(x0-ButBevelSize,y0-ButBevelSize,x0-1,y0-1);
      Line(x0-ButBevelSize,y1+ButBevelSize,x0-1,y1+1);
      Line(x1+1,y0-1,x1+ButBevelSize,y0-ButBevelSize);
      Line(x1+1,y1+1,x1+ButBevelSize,y1+ButBevelSize);
    end;
    if BChisel then
    begin
      case (y1-y0) of
        0..11    : begin  xchisel := 1;   ychisel := 1;  end;
        12..24   : begin  xchisel := 3;   ychisel := 2;  end;
        25..39   : begin  xchisel := 4;   ychisel := 3;  end;
        40..74   : begin  xchisel := 6;   ychisel := 5;  end;
        75..149  : begin  xchisel := 7;   ychisel := 5;  end;
        150..199 : begin  xchisel := 8;   ychisel := 6;  end;
        200..249 : begin  xchisel := 10;  ychisel := 7;  end;
        250..299 : begin  xchisel := 11;  ychisel := 8;  end;
        300..999 : begin  xchisel := 13;  ychisel := 9;  end;
      end;
      setcolor(ButPlainHiLite);
      rectangle(x0+xchisel+1,y0+ychisel+1,x1-xchisel,y1-ychisel);
      setcolor(ButPlainShadow);
      rectangle(x0+xchisel,y0+ychisel,x1-(xchisel+1),y1-(ychisel+1));
      putpixel(x0+xchisel,y1-ychisel,ButPlainShadow);
      putpixel(x1-xchisel,y0+ychisel,ButPlainShadow);
    end;

    if BIconBut then
    begin
      PutImage(tx0,ty0,cb^,0);
      freemem(cb,cbsize);
    end;
    if BClip then
    begin
      if clipb <> nil then
        PutImage(tx0,ty0,clipb^,0);
    end;
    if BImage2Clip or BMouse then
    begin
      tempx0 := x0;  tempx1 := x1;
      tempy0 := y0;  tempy1 := y1;
      if BBevel then
      begin
        dec(tempx0,butbevelsize);
        dec(tempy0,butbevelsize);
        inc(tempx1,butbevelsize);
        inc(tempy1,butbevelsize);
      end;
    end;
    if BImage2Clip then
    begin
      if clipb <> nil then
      begin
        FreeMem(ClipB,ClipSize);
        ClipSize := 0;
        ClipB := nil;
      end;
      clipsize := ImageSize(tempx0,tempy0,tempx1,tempy1);
      GetMem(ClipB,ClipSize);
      GetImage(tempx0,tempy0,tempx1,tempy1,clipb^);
    end;
    if BMouse then
    begin
      {$IFDEF MOUSE}
      AddRegion(tempx0,tempy0,tempx1,tempy1,BInvertable,BReset,cmd);
      {$ENDIF}
    end;

    if sLabel <> '' then
    begin
      bwid := x1-x0;
      bhgt := y1-y0;
      if BBevel then
      begin
        inc(bwid,2*butbevelsize);
        inc(bhgt,2*butbevelsize);
        dec(x0,butbevelsize);
        dec(y0,butbevelsize);
        inc(x1,butbevelsize);
        inc(y1,butbevelsize);
      end;
      twid := textwidth(slabel);
      thgt := real_textheight;
      if brecess then
      begin
        dec(x0,2);
        dec(y0,2);
        inc(x1,2);
        inc(y1,2);
      end;

      case ButOrientation of
  {top} 0 : begin
              if bleftjust then
              begin
                if bchisel then
                  tx := x0+20
                else
                  tx := x0+10;
              end
              else
                if brightjust then
                begin
                  if bchisel then
                    tx := x0+bwid-twid-20
                  else
                    tx := x0+bwid-twid-10;
                end
                else
                  tx := x0+((bwid-twid) div 2);
              ty := y0-5-thgt;
              if contains_dropdown(slabel) and badjustvert then
                dec(ty,(metric.drop-metric.base));
            end;
 {left} 1 : begin
              if contains_dropdown(slabel) and badjustvert then
                inc(thgt,(metric.drop-metric.base));
              tx := x0-twid-8;
              ty := y0+((bhgt-thgt) div 2)+2;
              if buline then
                dec(ty,1);
              if contains_dropdown(slabel) then
                inc(ty,(metric.drop-metric.base) div 2);
            end;
{center}2 : begin
              if contains_dropdown(slabel) and badjustvert then
                inc(thgt,(metric.drop-metric.base));
              if bleftjust then
              begin
                if bchisel then
                  tx := x0+20
                else
                  tx := x0+10;
              end
              else
                if brightjust then
                begin
                  if bchisel then
                    tx := x0+bwid-twid-20
                  else
                    tx := x0+bwid-twid-10;
                end
                else
                  tx := x0+((bwid-twid) div 2);
              ty := y0 + ((bhgt-thgt) div 2)+1;
            end;
{right} 3 : begin
              if contains_dropdown(slabel) and badjustvert then
                inc(thgt,(metric.drop-metric.base));
              tx := x1+8;
              ty := y0+((bhgt-thgt) div 2)+2;
              if buline then
                dec(ty,1);
              if contains_dropdown(slabel) then
                inc(ty,(metric.drop-metric.base) div 2);
            end;
{bottom}4 : begin
              if bleftjust then
              begin
                if bchisel then
                  tx := x0+20
                else
                  tx := x0+10;
              end
              else
                if brightjust then
                begin
                  if bchisel then
                    tx := x0+bwid-twid-20
                  else
                    tx := x0+bwid-twid-10;
                end
                else
                  tx := x0+((bwid-twid) div 2);
              ty := y1+3;
            end;
      end; {case}
      if brecess then
      begin
        inc(ty,2);
        inc(tx,2);
      end;
      if bclip then
      begin
        if not contains_dropdown(slabel) then
          dec(ty,1);
      end
      else
        if (biconbut or bplainbut) then
          dec(ty,1);

      {display label finally}
      if bdropshadow then
      begin
        setcolor(butlabeldropshadow);
        outtextxy(tx+1,ty+1-metric.top,slabel);
      end;
      setcolor(butlabelfore);
      putitxy(tx,ty-metric.top,slabel);
    end; {if slabel...}
    if BImage2Clip then
    begin
      SetFlagOn(ButFlags,1);
      SetFlagOff(ButFlags,128);
      SetFlagOff(ButFlags,256);
      SetFlagOff(ButFlags,8);
      SetFlagOff(ButFlags,512);
      SetFlagOff(ButFlags,64);
      SetFlagOff(ButFlags,32768);
    end;

    SetColor(col);
    with tst do
      SetTextStyle(font,direction,charsize);
    with lst do
      SetLineStyle(LineStyle,Pattern,Thickness);
end;

Constructor RipObj.Init(userip : boolean;fontname : string);
var
  GrDriver      : integer;
  GrMode        : Integer;
  success       : boolean;
  tres          : integer;
  rnd1          : word;
  rnd2          : word;
  c             : byte;
begin
  if not Root.Init then
    fail;

  success := true;
  TMaxX0 := Lo(WindMin)+1;
  TMaxY0 := Hi(WindMin)+1;
  TMaxX1 := Lo(WindMax)+1;
  TMaxY1 := Hi(WindMax)-1;

  level := 0;
  sublevel := 0;
  command := #0;
  firstcmd := true;
  nextcommand := false;
  commanddone := false;
  didrip      := false;
  pstat := none;
  cstat := cnone;
  lastc := #0;
  fillchar(rbuffer,1024,#0);
  bufcount := 0;

  DefColor := 0;
    RIPScriptFont        := InstallUserFont('SCRI');
    if GraphResult <> grOk then success := false;
    RIPSimplexFont       := InstallUserFont('SIMP');
    if GraphResult <> grOk then success := false;
    RIPTriplexScriptFont := InstallUserFont('TSCR');
    if GraphResult <> grOk then success := false;
    RIPComplexFont       := InstallUserFont('LCOM');
    if GraphResult <> grOk then success := false;
    RIPEuropeanFont      := InstallUserFont('EURO');
    if GraphResult <> grOk then success := false;
    RIPBoldFont          := InstallUserFont('BOLD');
    if GraphResult <> grOk then success := false;

    assign(charfile,fontname+'.1');
    {$I-}
    reset(charfile,1);
    {$I+}
    if ioresult <> 0 then
      success := false;
    GetMem(driverptr,5527);
    blockread(charfile,driverptr^,5527);
    if RegisterBGIdriver(driverptr) < 0 then
      success := false;
    FontPtr       := nil;
    FontSize      := 0;

    if not success then
    begin
      Root.Done;
      Fail;
    end;

    GrDriver := Graph.EGA64;
    GrMode   := Graph.EGA64Hi;
    SetGraphBufSize(4096);
    InitGraph(GrDriver, GrMode,'');
    tres := graphresult;
    if tres <> grOk then
      success := false;
    SetTextJustify(LeftText,TopText);
    {ansi parser}
    if (MaxAvail < iQueueSize) or (iQueueSize = 0) then
      Fail;
    GetMem(Queue,iQueueSize);
    QueueSize := iQueueSize;
    QueueIndex := 0;
    aTextAttr := TextAttr;
    Intense := False;
    Inverse := False;
    Blink := False;
    Invis := False;
    InitParser;
    {text window}
    textx0 := 0;  texty0 := 0;
    textx1 := The79; texty1 := The42;
    textsize := 0;
    textwrap := true;
    textclr := 15;
    textactive := true;
    cursorx := 0; cursory := 0;
    cursoron := false;
    fillchar(virtualwindow,7826,#0);
    filemode := SetFileMode;
    assign(textfontfile,fontname+'.2');
    {$I-}
    reset(textfontfile);
    {$I+}
    if IOresult <> 0 then
      success := false;
  if not success then
  begin
    Root.Done;
    Fail;
  end;
  ClipB := nil;
  ClipSize := 0;
  {$IFDEF MOUSE}
  mouseexist := false;
  MouseInit;
  MouseOn;
  {$ENDIF}
  CurFont   := 0;
  CurSize   := 1;
  Metric    := MetricArray[CurFont,CurSize];
  IconDir := '.\';
end;

Destructor RipObj.Done;
begin
    close(textfontfile);
    FreeMem(Queue,QueueSize);
    {$IFDEF MOUSE}
    regs.ax := $0000;
    intr($33,regs);
    mouseexist := (regs.ax = $ffff);
    {$ENDIF}
    if ClipB <> nil then
    begin
      FreeMem(ClipB,ClipSize);
      ClipB := nil;
      ClipSize := 0;
    end;
    CloseGraph;
    FreeMem(driverptr,5527);
    if fontptr <> nil then
      freemem(fontptr,fontsize);
    close(charfile);
  Root.Done;
end;

Procedure RipObj.RipTextWindow(x0, y0, x1, y1: byte; wrap : boolean; size : byte);
begin
  rTextWindow(x0,y0,x1,y1,wrap,size);
end;

Procedure RipObj.RipViewPort(x0,y0,x1,y1 : word);
begin
  rViewPort(x0,y0,x1,y1);
end;

Procedure RipObj.RipResetWindows;
begin
  rResetWindows;
end;

Procedure RipObj.RipEraseWindow;
begin
  rEraseWindow;
end;

Procedure RipObj.RipEraseView;
begin
  rEraseView;
end;

Procedure RipObj.RipGotoXY(x0,y0 : byte);
begin
  rGotoXY(x0,y0);
end;

Procedure RipObj.RipHome;
begin
  rHome;
end;

Procedure RipObj.RipEraseEOL;
begin
  rEraseEOL;
end;

Procedure RipObj.RipColor(clr : byte);
begin
  rColor(clr);
end;

Procedure RipObj.RipSetPalette(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16 : word);
begin
  rSetPalette(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16);
end;

Procedure RipObj.RipOnePalette(color,value : word);
begin
  rOnePalette(color,value);
end;

Procedure RipObj.RipWriteMode(Mode : Byte);
begin
  rWriteMode(mode);
end;

Procedure RipObj.RipMove(x0,y0 : word);
begin
  rMove(x0,y0);
end;

Procedure RipObj.RipText(instr : string);
begin
  rText(instr);
end;

Procedure RipObj.RipTextXY(x0,y0 : word; instr : string);
begin
  rTextXY(x0,y0,instr);
end;

Procedure RipObj.RipFontStyle(font,direct,size : byte);
begin
  rFontStyle(font,direct,size);
end;

Procedure RipObj.RipPixel(x0,y0 : word);
begin
  rPixel(x0,y0);
end;

Procedure RipObj.RipLine(x0,y0,x1,y1 : word);
begin
  rLine(x0,y0,x1,y1);
end;

Procedure RipObj.RipRectangle(x0,y0,x1,y1 : word);
begin
  rRectangle(x0,y0,x1,y1);
end;

Procedure RipObj.RipBar(x0,y0,x1,y1 : word);
begin
  rBar(x0,y0,x1,y1);
end;

Procedure RipObj.RipCircle(x0,y0,radius : word);
begin
  rCircle(x0,y0,radius);
end;

Procedure RipObj.RipOval(x0,y0,StAngle,EndAngle,xrad,yrad : word);
begin
  rOval(x0,y0,stangle,endangle,xrad,yrad);
end;

Procedure RipObj.RipFilledOval(x0,y0,xrad,yrad : word);
begin
  rFilledOval(x0,y0,xrad,yrad);
end;

Procedure RipObj.RipArc(x0,y0,StAngle,EndAngle,Rad : word);
begin
  rArc(x0,y0,stangle,endangle,rad);
end;

Procedure RipObj.RipOvalArc(x0,y0,StAngle,EndAngle,xrad,yrad : word);
begin
  rOval(x0,y0,stangle,endangle,xrad,yrad);
end;

Procedure RipObj.RipPieSlice(x0,y0,StAngle,EndAngle,Rad : word);
begin
  rPieSlice(x0,y0,stangle,endangle,rad);
end;

Procedure RipObj.RipOvalPieSlice(x0,y0,StAngle,EndAngle,radx,rady : word);
begin
  rOvalPieSlice(x0,y0,stangle,endangle,radx,rady);
end;

Procedure RipObj.RipBezier(x0,y0,x1,y1,x2,y2,x3,y3,count : word);
begin
  rBezier(x0,y0,x1,y1,x2,y2,x3,y3,count);
end;

Procedure RipObj.RipPolygon(NumPoints : word; var PolyPoints);
begin
  rPolygon(numpoints,polypoints,true);
end;

Procedure RipObj.RipFillPoly(NumPoints : word; var polypoints);
begin
  rFillPoly(numpoints,polypoints);
end;

Procedure RipObj.RipPolyLine(NumPoints : word; var polypoints);
begin
  rPolygon(numpoints,polypoints,false);
end;

Procedure RipObj.RipFill(x0,y0,border : word);
begin
  rFill(x0,y0,border);
end;

Procedure RipObj.RipLineStyle(style, pattern, thick : word);
begin
  rLineStyle(style,pattern,thick);
end;

Procedure RipObj.RipFillStyle(style, color : word);
begin
  rFillStyle(style,color);
end;

Procedure RipObj.RipFillPattern(Pattern : fpt; color : word);
begin
  rFillPattern(pattern,color);
end;

Procedure RipObj.RipMouse(x0,y0,x1,y1 : word; click, clear : boolean; instr : string);
var
  ch1, ch2 : char;
begin
  if click then
    ch1 := '1'
  else
    ch1 := '0';
  if clear then
    ch2 := '1'
  else
    ch2 := '0';
  rMouse(x0,y0,x1,y1,click,clear,instr);
end;

Procedure RipObj.RipKillMouseFields;
begin
  rKillMouse;
end;

Procedure RipObj.RipGetImage(x0,y0,x1,y1 : word);
begin
  rGetImage(x0,y0,x1,y1);
end;

Procedure RipObj.RipPutImage(x0,y0,mode : word);
begin
  rPutImage(x0,y0,mode);
end;

Procedure RipObj.RipWriteIcon(fname : str12);
begin
  rWriteIcon(fname);
end;

Procedure RipObj.RipLoadIcon(x0,y0,mode : word; clipbrd : boolean; fname : str12);
begin
  rLoadIcon(x0,y0,mode,clipbrd,fname);
end;

Procedure RipObj.RipButtonStyle(wid,hgt,orient,flags,bevsize,dfore,dback,bright,dark,
                                surface,grp_no,flags2,uline_col,corner_col : word);
begin
  rButtonStyle(wid,hgt,orient,flags,bevsize,dfore,dback,bright,dark,surface,grp_no,flags2,uline_col,corner_col);
end;

Procedure RipObj.RipButton(x0,y0,x1,y1,hotkey : word; flags : byte; icon : str12; sLabel : string; Cmd : string);
begin
  rButton(x0,y0,x1,y1,hotkey,flags,icon,slabel,cmd);
end;

Procedure RipObj.ResetParser;
begin
  fillchar(rbuffer,1024,#0);
  bufcount := 0;
  level := 0;
  sublevel := 0;
  command := #0;
  {lastc := #0;}
  firstcmd := false;
  if nextcommand then
    pstat := got_pipe
  else
    pstat := none;
  lstat := lNone;
  nextcommand := false;
  commanddone := false;
  cstat := cnone;
end;

Procedure RipObj.ResetParser2(c:char);
begin
  ResetParser;
  inc(bufcount);
  rbuffer[bufcount] := c;
  if c = #13 then
  begin
    firstcmd := true;
    dec(bufcount);
  end;
end;

Procedure RipObj.DumpBuffer;
var
  ctr : word;
begin
  for ctr := 1 to bufcount do
    DoTextChar(rbuffer[ctr]);
  resetparser;
end;

Procedure RipObj.DumpBuffer2;
var
  stor:boolean;
begin
  stor := firstcmd;
  ResetParser;
  firstcmd := stor;
end;

Procedure RipObj.ParseRipStr(s:string;sendchar:boolean);
var
  ctr : byte;
begin
  for ctr := 1 to length(s) do
    ParseRip(s[ctr],sendchar);
end;

Procedure RipObj.ParseRip(c : char;sendchar : boolean);
Var
  b : boolean;
begin
  b := DoRipChar(c);
end;

Function RipObj.MegaBuf(tpos,a,b:byte):word;
begin
  megabuf := megatoword(rbuffer[tpos+a]+rbuffer[tpos+b]);
end;

Function RipObj.UnEscapeString(bStart,bEnd:word):string;
var
  s : string;
  ctr : byte;
begin
  s := '';
  ctr := bStart-1;
  while ctr < bEnd-1 do
  begin
    inc(ctr);
    if rbuffer[ctr] = '\' then
    begin
      inc(ctr);
      if rbuffer[ctr] in ['\','|','!'] then
        s := s + rbuffer[ctr]
      else
        while rbuffer[ctr+1] in [#13,#10] do
          inc(ctr);
    end
    else
      s := s + rbuffer[ctr];
  end;
  unescapestring := s;
end;

Function RipObj.DoRipChar(c : char): boolean;
type
  PointRec = record
    X : word;
    Y : word;
  end;

  TempType = Array[1..512] of PointRec;
var
  doexit : boolean;
  st5    : string[7];
  tPos   : byte;
  st2    : string[2];
  w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16         : word;
  b1,b2,b3,b4,b5                                                 : byte;
  o1,o2                                                          : boolean;
  s1,s2,s3,s4                                                    : string;
  sCtr                                                           : byte;
  TempPoly : TempType;
  TempFPT  : fpt;

  Function MegaB(ch:char) :Boolean;
  begin
    if ch = '1' then
      megab := true
    else
      megab := false;
  end;

  Procedure DoTheButton;
  var
    sctr        : byte;
  begin
    s1 := ''; s2 := ''; s3 := ''; s4 := '';
    s1 := unescapestring(tpos+13,bufcount);
    case pos('<>',s1) of
      0 : begin
            if s1 <> '' then
            begin
              s2 := s1;
              s1 := '';
            end;
          end;
      1 : delete(s1,1{index},2{count});
      else
      begin
        s2 := copy(s1,1,pos('<>',s1)-1);
        delete(s1,1,pos('<>',s1)+1);
      end;
    end;
    case pos('<>',s1) of
      0 : begin
            if s1 <> '' then
            begin
              s3 := s1;
              s1 := '';
            end;
          end;
      1 : delete(s1,1{index},2{count});
      else
      begin
        s3 := copy(s1,1,pos('<>',s1)-1);
        delete(s1,1,pos('<>',s1)+1);
      end;
    end;
    case pos('<>',s1) of
      0 : begin
            if s1 <> '' then
            begin
              s4 := s1;
              s1 := '';
            end;
          end;
      1 : delete(s1,1{index},2{count});
      else
      begin
        s4 := copy(s1,1,pos('<>',s1)-1);
        delete(s1,1,pos('<>',s1)+1);
      end;
    end;

    w1 := megabuf(tpos,1,2);
    w2 := megabuf(tpos,3,4);
    w3 := megabuf(tpos,5,6);
    w4 := megabuf(tpos,7,8);
    w5 := megabuf(tpos,9,10);
    b1 := megatoword('0'+rbuffer[tpos+11]);
    rButton(w1,w2,w3,w4,w5,b1,s2,s3,s4);
  end;

  Procedure DoTheButtonStyle;
  begin
    w1 := megabuf(tpos,1,2);
    w2 := megabuf(tpos,3,4);
    w3 := megabuf(tpos,5,6);
    w4 := word(mega4tolong(rbuffer[tpos+7]+rbuffer[tpos+8]+rbuffer[tpos+9]+rbuffer[tpos+10]));
    w5 := megabuf(tpos,11,12);
    w6 := megabuf(tpos,13,14);
    w7 := megabuf(tpos,15,16);
    w8 := megabuf(tpos,17,18);
    w9 := megabuf(tpos,19,20);
    w10 := megabuf(tpos,21,22);
    w11 := megabuf(tpos,23,24);
    w12 := megabuf(tpos,25,26);
    w13 := megabuf(tpos,27,28);
    w14 := megabuf(tpos,29,30);
    rButtonStyle(w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14);
  end;

  Procedure DoSetPalette;
  begin
    w1  := megabuf(tpos,1 ,2 );
    w2  := megabuf(tpos,3 ,4 );
    w3  := megabuf(tpos,5 ,6 );
    w4  := megabuf(tpos,7 ,8 );
    w5  := megabuf(tpos,9 ,10);
    w6  := megabuf(tpos,11,12);
    w7  := megabuf(tpos,13,14);
    w8  := megabuf(tpos,15,16);
    w9  := megabuf(tpos,17,18);
    w10 := megabuf(tpos,19,20);
    w11 := megabuf(tpos,21,22);
    w12 := megabuf(tpos,23,24);
    w13 := megabuf(tpos,25,26);
    w14 := megabuf(tpos,27,28);
    w15 := megabuf(tpos,29,30);
    w16 := megabuf(tpos,31,32);
    rSetPalette(w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16);
  end;

  Procedure DoFillPattern;
  begin
    tempfpt[1] := megabuf(tpos,1,2);
    tempfpt[2] := megabuf(tpos,3,4);
    tempfpt[3] := megabuf(tpos,5,6);
    tempfpt[4] := megabuf(tpos,7,8);
    tempfpt[5] := megabuf(tpos,9,10);
    tempfpt[6] := megabuf(tpos,11,12);
    tempfpt[7] := megabuf(tpos,13,14);
    tempfpt[8] := megabuf(tpos,15,16);
    w1 := megabuf(tpos,17,18);
    rFillpattern(tempfpt,w1);
  end;

begin
  doripchar := false;

  inc(bufcount);
  rbuffer[bufcount] := c;

  doexit := false;

  if c in [#13,#10,'!'] then
  begin
    if (c = #13) and (lstat <> lBackSlash) then
    begin
      firstcmd := true;
    end;
    if (not didrip) and (c = '!') and (lastc = #10) then
      firstcmd := true;
  end
  else
    firstcmd := false;

  lastc := c;

  case pstat of
    None          : begin
      if firstcmd then
      begin
        if c = '!' then
          pstat := got_excl
        else
        begin
          if not (c in [#13,#10]) then
            dumpbuffer
          else
            if didrip then
            begin
              dec(bufcount);
              if c = #10 then
                didrip := false;
            end
            else
              dumpbuffer;
          exit;
        end;
      end
      else
        if c in [#1,#2] then
          pstat := got_excl
        else
          if c = '|' then
            pstat := got_pipe
          else
          begin
            dumpbuffer;
            exit;
          end;
    end;
    Got_Excl      : begin
      didrip := true;
      if c = '|' then
        pstat := got_pipe
      else
      begin
        dumpbuffer;
        exit;
      end;
    end;
    Got_Pipe      : begin
      didrip := true;
      case c of
        '1'..'9' : begin
                     level := _Numeric(c);
                     pstat := got_level;
                   end;
        #27,'#','*','=','>','@','A'..'Z','a'..'z' :
                   begin
                     level := 0;
                     command := c;
                     pstat := got_command;
                   end;
        else
        begin
          dumpbuffer;
          exit;
        end;
      end;
    end;
    Got_Level     : begin
      case c of
        '1'..'9' : begin
                     sublevel := _Numeric(c);
                     pstat := got_sublevel;
                   end;
        #27,'#','*','=','>','@','A'..'Z','a'..'z' :
                   begin
                     command := c;
                     pstat := got_command;
                   end;
        else
        begin
          dumpbuffer;
          exit;
        end;
      end;
    end;
    Got_SubLevel  : begin
      if c in [#27,'#','*','=','>','@','A'..'Z','a'..'z'] then
      begin
        command := c;
        pstat := got_command;
      end
      else
      begin
        dumpbuffer;
        exit;
      end;
    end;
    Got_Command   : begin
      if (c = '|') and not (lstat = lBackSlash) then
        nextcommand := true;

      case c of
        #13 : lstat := lCR;
        #10 : lstat := lLF;
        '|' : lstat := lPipe;
        '\' : lstat := lBackSlash;
        '!' : lstat := lExcl;
        else
          lstat := lChar;
      end;

      if firstcmd {and (cstat <> contline) and (cstat <> pending)} then
        doexit := true;
{     case cstat of
        pending  : begin
                     if c = #13 then
                       cstat := contline
                     else
                       cstat := escaped;
                   end;
        contline : cstat := cnone;
      end;}
      st5 := rbuffer[1]+rbuffer[2]+rbuffer[3]+rbuffer[4]+rbuffer[5]+rbuffer[6]+rbuffer[7];
      tpos := pos(command,st5);
      case level of
        0  : begin
          case command of
            'w' : begin {text window}
                    if bufcount = (tpos+10) then
                    begin
                      b1 := megabuf(tpos,1,2);
                      b2 := megabuf(tpos,3,4);
                      b3 := megabuf(tpos,5,6);
                      b4 := megabuf(tpos,7,8);
                      b5 := megatoword('0'+rbuffer[tpos+10]);
                      o1 := megab(rbuffer[tpos+9]);
                      rTextWindow(b1,b2,b3,b4,o1,b5);
                      resetparser;
                      exit;
                    end;
                  end;
            'v' : begin {view port}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rViewPort(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            '*' : begin {reset windows}
                    rResetWindows;
                    resetparser2(c);
                    exit;
                  end;
            'e' : begin {erase window}
                    rEraseWindow;
                    resetparser2(c);
                    exit;
                  end;
            'E' : begin {erase view}
                    rEraseView;
                    resetparser2(c);
                    exit;
                  end;
            'g' : begin {gotoxy}
                    if bufcount = (tpos+ 4) then
                    begin
                      b1 := megabuf(tpos,1,2);
                      b2 := megabuf(tpos,3,4);
                      rGotoXY(b1,b2);
                      resetparser;
                      exit;
                    end;
                  end;
            'H' : begin {home}
                    rHome;
                    resetparser2(c);
                    exit;
                  end;
            '>' : begin {erase eol}
                    rEraseEOL;
                    resetparser2(c);
                    exit;
                  end;
            'c' : begin {color}
                    if bufcount = (tpos+ 2) then
                    begin
                      b1 := megabuf(tpos,1,2);
                      rColor(b1);
                      resetparser;
                      exit;
                    end;
                  end;
            'Q' : begin {set palette}
                    if bufcount = (tpos+ 32) then
                    begin
                      DoSetPalette;
                      resetparser;
                      exit;
                    end;
                  end;
            'a' : begin {one palette}
                    if bufcount = (tpos+ 4) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      rOnePalette(w1,w2);
                      resetparser;
                      exit;
                    end;
                  end;
            'W' : begin {write mode}
                    if bufcount = (tpos+ 2) then
                    begin
                      b1  := megabuf(tpos,1,2);
                      rWriteMode(b1);
                      resetparser;
                      exit;
                    end;
                  end;
            'm' : begin {move}
                    if bufcount = (tpos+ 4) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      rMove(w1,w2);
                      resetparser;
                      exit;
                    end;
                  end;
            'T' : begin {text}
                    if doexit or nextcommand then
                    begin
                      s1 := unescapestring(tpos+1,bufcount);
                      rText(s1);
                      resetparser2(c);
                      exit;
                    end;
                  end;
            '@' : begin {textxy}
                    if doexit or nextcommand then
                    begin
                      s1 := unescapestring(tpos+5,bufcount);
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      rTextXY(w1,w2,s1);
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'Y' : begin {font style}
                    if bufcount = (tpos+ 8) then
                    begin
                      b1 := megabuf(tpos,1,2);
                      b2 := megabuf(tpos,3,4);
                      b3 := megabuf(tpos,5,6);
                      rFontStyle(b1,b2,b3);
                      resetparser;
                      exit;
                    end;
                  end;
            'X' : begin {pixel}
                    if bufcount = (tpos+ 4) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      rPixel(w1,w2);
                      resetparser;
                      exit;
                    end;
                  end;
            'L' : begin {line}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rLine(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            'R' : begin {rectangle}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rRectangle(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            'B' : begin {bar}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rBar(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            'C' : begin {circle}
                    if bufcount = (tpos+ 6) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      rCircle(w1,w2,w3);
                      resetparser;
                      exit;
                    end;
                  end;
            'O' : begin {oval}
                    if bufcount = (tpos+ 12) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      w6 := megabuf(tpos,11,12);
                      rOval(w1,w2,w3,w4,w5,w6);
                      resetparser;
                      exit;
                    end;
                  end;
            'o' : begin {filled oval}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rFilledOval(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            'A' : begin {arc}
                    if bufcount = (tpos+ 10) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      rArc(w1,w2,w3,w4,w5);
                      resetparser;
                      exit;
                    end;
                  end;
            'V' : begin {oval arc}
                    if bufcount = (tpos+ 12) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      w6 := megabuf(tpos,11,12);
                      rOval(w1,w2,w3,w4,w5,w6);
                      resetparser;
                      exit;
                    end;
                  end;
            'I' : begin {pie slice}
                    if bufcount = (tpos+ 10) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      rPieSlice(w1,w2,w3,w4,w5);
                      resetparser;
                      exit;
                    end;
                  end;
            'i' : begin {oval pie slice}
                    if bufcount = (tpos+ 12) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      w6 := megabuf(tpos,11,12);
                      rOvalPieSlice(w1,w2,w3,w4,w5,w6);
                      resetparser;
                      exit;
                    end;
                  end;
            'Z' : begin {bezier}
                    if bufcount = (tpos+ 18) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      w5 := megabuf(tpos,9,10);
                      w6 := megabuf(tpos,11,12);
                      w7 := megabuf(tpos,13,14);
                      w8 := megabuf(tpos,15,16);
                      w9 := megabuf(tpos,17,18);
                      rBezier(w1,w2,w3,w4,w5,w6,w7,w8,w9);
                      resetparser;
                      exit;
                    end;
                  end;
            'P' : begin {polygon}
                    if bufcount >= (tpos+ 2) then
                    begin
                      st2 := rbuffer[tpos+1]+rbuffer[tpos+2];
                      if bufcount = (tpos+2+ (4* megatoword(st2))) then
                      begin
                        fillchar(temppoly,2048,#0);
                        w1 := megatoword(st2);
                        for sctr := 1 to w1 do
                        begin
                          temppoly[sctr].X := megabuf(tpos,3+((sctr-1)*4),4+((sctr-1)*4));
                          temppoly[sctr].Y := megabuf(tpos,5+((sctr-1)*4),6+((sctr-1)*4));
                        end;
                        rPolygon(w1,temppoly,true);
                        resetparser;
                        exit;
                      end;
                    end;
                  end;
            'p' : begin {fill polygon}
                    if bufcount >= (tpos+ 2) then
                    begin
                      st2 := rbuffer[tpos+1]+rbuffer[tpos+2];
                      if bufcount = (tpos+2+ (4* megatoword(st2))) then
                      begin
                        fillchar(temppoly,2048,#0);
                        w1 := megatoword(st2);
                        for sctr := 1 to w1 do
                        begin
                          temppoly[sctr].X := megabuf(tpos,3+((sctr-1)*4),4+((sctr-1)*4));
                          temppoly[sctr].Y := megabuf(tpos,5+((sctr-1)*4),6+((sctr-1)*4));
                        end;
                        rFillPoly(w1,temppoly);
                        resetparser;
                        exit;
                      end;
                    end;
                  end;
            'l' : begin {polyline}
                    if bufcount >= (tpos+ 2) then
                    begin
                      st2 := rbuffer[tpos+1]+rbuffer[tpos+2];
                      if bufcount = (tpos+2+ (4* megatoword(st2))) then
                      begin
                        fillchar(temppoly,2048,#0);
                        w1 := megatoword(st2);
                        for sctr := 1 to w1 do
                        begin
                          temppoly[sctr].X := megabuf(tpos,3+((sctr-1)*4),4+((sctr-1)*4));
                          temppoly[sctr].Y := megabuf(tpos,5+((sctr-1)*4),6+((sctr-1)*4));
                        end;
                        rPolygon(w1,temppoly,false);
                        resetparser;
                        exit;
                      end;
                    end;
                  end;
            'F' : begin {fill}
                    if bufcount = (tpos+ 6) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      rFill(w1,w2,w3);
                      resetparser;
                      exit;
                    end;
                  end;
            '=' : begin {line style}
                    if bufcount = (tpos+ 8) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := word(mega4tolong(rbuffer[tpos+3]+rbuffer[tpos+4]
                                            +rbuffer[tpos+5]+rbuffer[tpos+6]));
                      w3 := megabuf(tpos,7,8);
                      rLineStyle(w1,w2,w3);
                      resetparser;
                      exit;
                    end;
                  end;
            'S' : begin {fill style}
                    if bufcount = (tpos+ 4) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      rFillStyle(w1,w2);
                      resetparser;
                      exit;
                    end;
                  end;
            's' : begin {fill pattern}
                    if bufcount = (tpos+ 18) then
                    begin
                      DoFillPattern;
                      resetparser;
                      exit;
                    end;
                  end;
            '#' : begin {no more}
                    resetparser2(c);
                    exit;
                  end;
            else
            begin
              dumpbuffer;
              exit;
            end;
          end;
        end;
        1  : begin
          case command of
            'M' : begin {mouse}
                    if doexit or nextcommand then
                    begin
                      s1 := unescapestring(tpos+18,bufcount);
                      w1 := megabuf(tpos,3,4);
                      w2 := megabuf(tpos,5,6);
                      w3 := megabuf(tpos,7,8);
                      w4 := megabuf(tpos,9,10);
                      o1 := megab(rbuffer[tpos+11]);
                      o2 := megab(rbuffer[tpos+12]);
                      rMouse(w1,w2,w3,w4,o1,o2,s1);
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'K' : begin {kill mouse fields}
                    rKillMouse;
                    resetparser2(c);
                    exit;
                  end;
            'T' : begin {begin text}
                    if bufcount = (tpos+ 10) then
                    begin
                      resetparser;
                      exit;
                    end;
                  end;
            't' : begin {region text}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'E' : begin {end text}
                    resetparser2(c);
                    exit;
                  end;
            'C' : begin {get image}
                    if bufcount = (tpos+ 9) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      w4 := megabuf(tpos,7,8);
                      rGetImage(w1,w2,w3,w4);
                      resetparser;
                      exit;
                    end;
                  end;
            'P' : begin {put image}
                    if bufcount = (tpos+ 7) then
                    begin
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      rPutImage(w1,w2,w3);
                      resetparser;
                      exit;
                    end;
                  end;
            'W' : begin {write icon}
                    if doexit or nextcommand then
                    begin
                      s1 := unescapestring(tpos+2,bufcount);
                      rWriteIcon(s1);
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'I' : begin {load icon}
                    if doexit or nextcommand then
                    begin
                      s1 := unescapestring(tpos+10,bufcount);
                      w1 := megabuf(tpos,1,2);
                      w2 := megabuf(tpos,3,4);
                      w3 := megabuf(tpos,5,6);
                      o1 := megab(rbuffer[tpos+7]);
                      rLoadIcon(w1,w2,w3,o1,s1);
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'B' : begin {button style}
                    if bufcount = (tpos+ 36) then
                    begin
                      DoTheButtonStyle;
                      resetparser;
                      exit;
                    end;
                  end;
            'U' : begin {button}
                    if doexit or nextcommand then
                    begin
                      DoTheButton;
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'D' : begin {define}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            #27 : begin {query}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'G' : begin {copy region}
                    if bufcount = (tpos+ 12) then
                    begin
                      resetparser;
                      exit;
                    end;
                  end;
            'R' : begin {read scene}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            'F' : begin {file query}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            else
            begin
              dumpbuffer;
              exit;
            end;
          end;
        end;
        9  : begin
          case command of
            #27 : begin {enter block mode}
                    if doexit or nextcommand then
                    begin
                      resetparser2(c);
                      exit;
                    end;
                  end;
            else
            begin
              dumpbuffer;
              exit;
            end;
          end;
        end;
        else {case}
        begin
          dumpbuffer;
          exit;
        end;
      end; {case level of}
      if doexit then
        exit;
    end; {got_command}
  end;
  doripchar := true;
end;

{$IFDEF MOUSE}
Procedure RipObj.MouseInit;
begin
  regs.ax := $0000;
  intr($33,regs);
  mouseexist := (regs.ax = $ffff);
  fillchar(regionarray,sizeof(mouseregionrecord)*128,#0);
  lastbutton := 0;
  inverted := 0;
  fillchar(keybuf,250,#0);
  keybufhead := 1;
  keybuftail := 1;
  LastStatus := 0;
  LastX := 0;
  LastY := 0;
end;

Procedure RipObj.MouseOn;
begin
  if not mouseexist then
    exit;
  if RIPMouseOverride then
    exit;
  regs.ax := $01;
  intr($33,regs);
end;

Procedure RipObj.MouseOff;
begin
  if not mouseexist then
    exit;
  if RIPMouseOverride then
    exit;
  regs.ax := $02;
  intr($33,regs);
end;

Procedure RipObj.GetPosition(var ButtonStatus,xPos,yPos:Integer);
{absolute coords}
{ButtonStatus : Bit 0 - Left Button is down
                Bit 1 - Right Button is down
                Bit 2 - Middle Button is down }
begin
  if not mouseexist then
    exit;
  regs.ax := $03;
  intr($33,regs);
  buttonstatus := regs.bx;
  xpos := regs.cx;
  ypos := regs.dx;
end;

Procedure RipObj.SetMousePos(x,y:Integer);
{absolute coords}
begin
  if not mouseexist then
    exit;
  regs.ax := $04;
  regs.cx := x;
  regs.dx := y;
  intr($33,regs);
end;

Procedure RipObj.IsButtonDown(Button:Integer; var Status,DnCount,xPos,yPos:Integer);
begin
  if not mouseexist then
    exit;
  regs.ax := $05;
  regs.bx := button;
  intr($33,regs);
  status := regs.ax;
  dncount := regs.bx;
  xpos := regs.cx;
  ypos := regs.dx;
end;

Procedure RipObj.IsButtonUp(Button:Integer; var Status,UpCount,xPos,yPos:Integer);
begin
  if not mouseexist then
    exit;
  regs.ax := $06;
  regs.bx := button;
  intr($33,regs);
  status := regs.ax;
  upcount := regs.bx;
  xpos := regs.cx;
  ypos := regs.dx;
end;

Function FlagOn(Flags : word; FlagMask : word) : Boolean;
begin
  FlagOn := (Flags and FlagMask) <> 0;
end;

Procedure RipObj.CheckMouse;
{ ax : intrmask (see below)
  bx : button status
  cx : current x position
  dx : current y position}
var
  bx,cx,dx : integer;
begin
  if not mouseexist then
    exit;
  GetPosition(bx,cx,dx);
  if flagon(bx,$1) and (not flagon(laststatus,$1)) then {if leftbutton just pushed}
  begin
    curregion := inregion(cx,dx);
    if curregion <> 0 then
    begin
      if regionarray[curregion].invert then
      begin
        inverted := curregion;
        doinvert(curregion,true);
      end;
      curbutton := curregion;
    end
    else
      curbutton := 0;
  end;

  if flagon(bx,$1) and flagon(laststatus,$1) then {if leftbutton down and not just pushed}
  begin
    CurRegion := InRegion(cx,dx);
    if curregion = curbutton then
    begin
      if (inverted <> curbutton) and regionarray[curregion].invert then
      begin
        doinvert(curregion,true);
        inverted := curregion;
      end;
    end
    else
    begin
      if inverted <> 0 then
      begin
        doinvert(curbutton,false);
        inverted := 0;
      end;
    end;
  end;

  if (not flagon(bx,$1)) and flagon(laststatus,$1) and (curbutton <> 0) then
  {if leftbutton just released then}
  begin
    curregion := inregion(cx,dx);
    if curregion = curbutton then
    begin
      if regionarray[curregion].invert then
        doinvert(curbutton,false);
      if regionarray[curbutton].reset then
      begin
        {do |!*}
      end;
      addstring(regionarray[curbutton].thetext);
    end;
    inverted := 0;
    curbutton := 0;
  end;
  laststatus := bx;
  lastx := cx;
  lasty := dx;
end;

Function RipObj.InRegion(x,y:word):byte;
var
  c : byte;
begin
  if not mouseexist then
    exit;
  for c := lastbutton downto 1 do
  begin
    inregion := c;
    with regionarray[c] do
    begin
      if (x >= x0) and (x <= x1) and (y >= y0) and (y <= y1) then
        exit;
    end;
  end;
  inregion := 0;
end;

Procedure RipObj.DoInvert(region:byte;InvertIt:boolean);
var
  cb : pointer;
  cbsize : word;
  wason : boolean;
begin
  if not mouseexist then
    exit;
  with regionarray[region] do
  begin
    MouseOff;
    cbsize := imagesize(x0,y0,x1,y1);
    getmem(cb,cbsize);
    getimage(x0,y0,x1,y1,cb^);
    putimage(x0,y0,cb^,4{NOT});
    freemem(cb,cbsize);
    MouseOn;
  end;
end;

Procedure RipObj.AddRegion(x0,y0,x1,y1:word;invert,reset:boolean;thetext:str50);
begin
  if not mouseexist then
    exit;
  inc(lastbutton);
  regionarray[lastbutton].x0      := x0;
  regionarray[lastbutton].y0      := y0;
  regionarray[lastbutton].x1      := x1;
  regionarray[lastbutton].y1      := y1;
  regionarray[lastbutton].invert  := invert;
  regionarray[lastbutton].reset   := reset;
  regionarray[lastbutton].thetext := thetext;
end;

Function RipObj.CharInBuffer: boolean;
begin
  if not mouseexist then
  begin
    charinbuffer := false;
    exit;
  end;
  CharInBuffer := KeyBufHead <> KeyBufTail;
end;

Function RipObj.GetNextChar:char;
begin
  getnextchar := #0;
  if not mouseexist then
    exit;
  if KeyBufHead <> KeyBufTail then
  begin
    getnextchar := keybuf[keybufhead];
    inc(keybufhead);
    if keybufhead > 250 then
      keybufhead := 1;
  end;
end;

Procedure RipObj.AddString(st:string);
var
  s : string;
  c : byte;
begin
  if not mouseexist then
    exit;
  c := 0;
  s := '';
  while c < length(st) do
  begin
    inc(c);
    if st[c] = '^' then
    begin
      inc(c);
      if upcase(st[c]) in ['A'..'Z'] then
      begin
        s := s + char(byte(upcase(st[c]))-64);
      end
      else
      begin
        s := s + '^' + st[c];
      end;
    end
    else
    begin
      s := s + st[c];
    end;
  end;
  for c := 1 to length(s) do
  begin
    KeyBuf[KeyBufTail] := s[c];
    inc(keybuftail);
    if keybuftail > 250 then
      keybuftail := 1;
  end;
end;

Procedure RipObj.KillRegions;
begin
  if not mouseexist then
    exit;
  fillchar(regionarray,sizeof(mouseregionrecord)*128,#0);
  lastbutton := 0;
end;

Procedure RipObj.KillBuffer;
begin
  if not mouseexist then
    exit;
  fillchar(keybuf,250,#0);
  keybufhead := 1;
  keybuftail := 1;
end;
{$ENDIF}

{*** Ansi Emulator***}

procedure RipObj.PutQueue(C : Char);
begin
  if QueueIndex < QueueSize then
  begin
    Inc(QueueIndex);
    Queue^[QueueIndex] := C;
  end;
end;

procedure RipObj.ProcessChar(C : Char; var pCommand : CommandRecord);

  procedure ErrorCondition;
  begin
    pCommand.Cmd := eError;
    InitParser;
  end;

begin
  PutQueue(C);         {put char in queue in case of subsequent error}
  with pCommand do
  begin
    Ch := C;
    Cmd := eNone;
  end;
  case ParserState of
    GotNone :
      if C = Escape then
        ParserState := GotEscape
      else
        if C = FormFeed then
          pCommand.Cmd := eClearScreen
        else
          pCommand.Cmd := eChar;
    GotEscape :
      if C = LeftBracket then
        ParserState := GotBracket
      else
        ErrorCondition;
    GotParam,
    GotBracket,
    GotSemicolon :       {need a parameter char, semicolon or command}
      if (C >= #48) and (C <= #57) then
      begin
        BuildParam(C);
        ParserState := GotParam;
      end
      else
      begin
        if C = Semicolon then
        begin
          if ParserState = GotSemicolon then
            ErrorCondition
          else
          begin
            ParserState := GotSemicolon;
            Inc(ParamIndex);
            if ParamIndex > AnsiMaxParams then
              ErrorCondition;
          end;
        end
        else
        begin
          MakeCommand(C, pCommand);
          InitParser;
        end;
      end;
  end;
end;

procedure RipObj.InitParser;
begin
  ParamIndex := 1;
  FillChar(Params,SizeOf(Params),0);
  ParserState := GotNone;
  QueueIndex := 0;
end;

procedure RipObj.BuildParam(C : Char);
begin
  Params[ParamIndex] := Params[ParamIndex] + C;
end;

procedure RipObj.ConvertParams(C : Char);
var
  I, Code : Integer;
begin
  if C='K' then
  begin
    for I := 1 to AnsiMaxParams do
    begin
      Val(Params[I], ParamInt[I], Code);
      if Code <> 0 then ParamInt[I] := 1;
    end;
    if (Length(Params[1]) = 0) then ParamInt[1] := 0;
  end
  else
  begin
    for I := 1 to AnsiMaxParams do
    begin
      Val(Params[I], ParamInt[I], Code);
      if Code <> 0 then ParamInt[I] := 1;
    end;
    if (Length(Params[1]) = 0) and (C='J') then ParamInt[1] := 2;
  end;
end;

procedure RipObj.MakeCommand(C : Char; var pCommand : CommandRecord);
var
  I, TextFg, TextBk : Byte;
begin
  ConvertParams(C);
  with pCommand do
  begin
    Ch := C;
    case C of
      'f', 'H' : begin
        Cmd := eGotoXY;
        X   := ParamInt[2];
        Y   := ParamInt[1];
      end;
      'A' : begin
        Cmd := eUp;
        Y   := ParamInt[1];
      end;
      'B' : begin
        Cmd := eDown;
        Y   := ParamInt[1];
      end;
      'C' : begin
        Cmd := eRight;
        X   := ParamInt[1];
      end;
      'D' : begin
        cmd := eLeft;
        X   := ParamInt[1];
      end;
      'J' : begin
        case ParamInt[1] of
          0 : Cmd := eClearBelow;
          1 : Cmd := eClearAbove;
          2 : Cmd := eClearScreen;
          else
            Cmd := eChar;
        end;
      end;
      'K' : begin
        case ParamInt[1] of
          0 : Cmd := eClearEndOfLine;
          1 : Cmd := eClearStartOfLine;
          2 : Cmd := eClearLine;
          else
            Cmd := eChar;
        end;
      end;
      'h' : begin
        Cmd := eSetMode;
        X   := ParamInt[1];
      end;
      'm' : begin
        Cmd := eSetAttribute;
        X   := aTextAttr;
        for I := 1 to ParamIndex do
        begin
          if Inverse then
          begin
            Blink := X and $80 = $80;
            Intense := X and $08 = $08;
            X := X and $77;

            X := Byte((Word(X) shl 4) or (Word(X) shr 4));
          end;

          TextFg := X and $0F;
          TextBk := X and $F0;

          case ParamInt[I] of
            0  : begin
                   X := $07;            {White on black}
                   Inverse := False;
                   Intense := False;
                   Blink := False;
                   Invis := False;
                 end;
            1  : Intense  := True;      {Set intense bit later}
            4  : Intense  := True;      {Subst intense for underline}
            5  : Blink := True;         {set blinking on}
            7  : Inverse  := True;      {Invert TextAttr later}
            8  : Invis := True;         {Invisible}
            27 : Inverse  := False;     {Stop inverting TextAttr}
            30 : X := TextBk or $00;    {Black foreground}
            31 : X := TextBk or $04;    {Red foreground}
            32 : X := TextBk or $02;    {Green foreground}
            33 : X := TextBk or $06;    {Yellow forground}
            34 : X := TextBk or $01;    {Blue foreground}
            35 : X := TextBk or $05;    {Magenta foreground}
            36 : X := TextBk or $03;    {Cyan foreground}
            37 : X := TextBk or $07;    {White foreground}
            40 : X := TextFg;
            41 : X := TextFg or $40;    {Red background}
            42 : X := TextFg or $20;    {Green background}
            43 : X := TextFg or $60;    {Yellow background}
            44 : X := TextFg or $10;    {Blue background}
            45 : X := TextFg or $50;    {Magenta background}
            46 : X := TextFg or $30;    {Cyan background}
            47 : X := TextFg or $70;    {White background}
          end;
        end;

        if Inverse then
          X := Byte((Word(X) shl 4) or (Word(X) shr 4));
        if Inverse then
          X := X and $7F;
        if Invis then
          X := $00;
        if Intense then
          X := X or $08;
        if Blink then
          X := X or $80;
        aTextAttr := X;
      end;
      's' : Cmd := eSaveCursorPos;
      'u' : Cmd := eRestoreCursorPos;
      'n' : cmd := eDeviceStatusReport;
      else
        Cmd := eError;
    end;
  end;
end;

{*** Text Window Methods ***}

Procedure RipObj.DoTextStr(s:string);
var
  ctr : byte;
begin
  for ctr := 1 to length(s) do
    DoTextChar(s[ctr]);
end;

Procedure RipObj.DoTextChar(c:char);
{General processing procedure for text window}
var
  fst : fillsettingstype;
  ctr : byte;
  wrk : integer;
begin
  ProcessChar(c,CmdRec);
  case CmdRec.Cmd of
    eNone               : ;
    eChar               : if textactive then DispChar(CmdRec.Ch);
    eGotoXY             : rGotoXY(CmdRec.X-1,CmdRec.Y-1);
    eUp                 : begin {cursor up}
      if cursory-CmdRec.x >= texty0 then
        rGotoXY(cursorx,cursory-CmdRec.y);
    end;
    eDown               : begin {cursor down}
      if cursory+CmdRec.x <= texty1 then
        rGotoXY(cursorx,cursory+CmdRec.y);
    end;
    eRight              : begin {cursor right}
      wrk := cursorx+CmdRec.x;
      if  wrk <= textx1 then rGotoXY(wrk,cursory)
                        else rGotoXY(textx1,cursory);
    end;
    eLeft               : begin {cursor left}
      wrk := cursorx-CmdRec.x;
      if  wrk >= textx0 then rGotoXY(wrk,cursory)
                        else rGotoXY(textx0,cursory);
    end;
    eClearBelow         : ; {clear screen below cursor}
    eClearAbove         : ; {clear screen above cursor}
    eClearScreen        : begin {clear entire screen}
      if TextActive then
      begin
        getfillsettings(fst);
        setfillstyle(0,textclr and $F0);
        fillchar(virtualwindow,7826,#0);
        Bar(TextOffsetX[textsize]*textx0,TextOffsetY[textsize]*texty0,
            TextOffsetX[textsize]*(textx1+1)-1,TextOffsetY[textsize]*(texty1+1)-1);
        setfillstyle(fst.pattern,fst.color);
        rHome;
      end;
    end;
    eClearEndofLine     : begin {clear from cursor to end of line}
      if TextActive then
      begin
        getfillsettings(fst);
        setfillstyle(0,textclr and $F0);
        Bar(TextOffsetX[textsize]*cursorx,TextOffsetY[textsize]*cursory,
            TextOffsetX[textsize]*(textx1+1)-1,TextOffsetY[textsize]*(cursory+1)-1);
        for ctr := cursorx to TextMaxX[textsize] do
          virtualwindow[ctr,cursory,0] := 0;
        setfillstyle(fst.pattern,fst.color);
      end;
    end;
    eClearStartOfLine   : ; {clear from cursor to the start of line}
    eClearLine          : begin {clear entire line that cursor is on}
      if TextActive then
      begin
        getfillsettings(fst);
        setfillstyle(0,textclr and $F0);
        Bar(TextOffsetX[textsize]*textx0,TextOffsetY[textsize]*cursory,
            TextOffsetX[textsize]*(textx1+1)-1,TextOffsetY[textsize]*(cursory+1)-1);
        for ctr := 0 to TextMaxX[textsize] do
          virtualwindow[ctr,cursory,0] := 0;
        setfillstyle(fst.pattern,fst.color);
        rHome;
      end;
    end;
    eSetAttribute       : textclr := CmdRec.X;
    eSaveCursorPos      : begin
      cursorsavex := cursorx;
      cursorsavey := cursory;
    end;
    eRestoreCursorPos   : begin
      cursorx := cursorsavex;
      cursory := cursorsavey;
    end;
  end;
end;

Procedure RipObj.DispChar(c:char);
begin
  if (cursorx = TextX1) and textwrap then
  begin
    if (cursory <> TextY1) then
    begin
      cursorx := TextX0;
      inc(cursory);
    end;
  end;
  seek(textfontfile,byte(c));              {scrolling on y!}
  read(textfontfile,textchar);
  if c in [#0,#7,#8,#10,#12,#13,#255] then
  begin
    if c = #13 then
    begin
      cursorx := textx0;
{      if cursory < texty1 then
        inc(cursory);}
    end;
    if c = #10 then
      if cursory < texty1 then
        inc(cursory);
    if c = #8 then
    begin
      if cursorx > textx0 then
        dec(cursorx);
    end;
  end
  else
  begin
    DisplayChar(TextOffsetX[textsize]*cursorx,TextOffsetY[textsize]*cursory,textclr and $0F,(textclr and $F0) shr 4,
                textchar,textsize);
  end;
  virtualwindow[cursorx,cursory,0] := byte(c);
  virtualwindow[cursorx,cursory,1] := textclr;
  if (cursorx <> textx1) and not (c in [#0,#7,#8,#10,#12,#13,#255]) then
    inc(cursorx);
end;

Procedure RipObj.StatLine;
const num1 = 320;
      num2 = 400;
      num3 = 480;
      num4 = 560;
var
  vpt   : ViewPortType;
  tst   : TextSettingsType;
  lst   : LineSettingsType;
  col   : word; {color}

  procedure frameline(x: Word);
  begin
    SetColor(15);
    Line(x,1,x,TheEndOfScreen-2);
    SetColor(8);
    Line(x+1,1,x+1,TheEndOfScreen-2);
  end;

begin
     IF ((oRIPStat1<>RIPStat1) OR (oRIPStat2<>RIPStat2) OR (oRIPStat3<>RIPStat3) OR
        (oRIPStat4<>RIPStat4) OR (oRIPStat5<>RIPStat5)) THEN
     BEGIN
       oRIPStat1 := RIPStat1;
       oRIPStat2 := RIPStat2;
       oRIPStat3 := RIPStat3;
       oRIPStat4 := RIPStat4;
       oRIPStat5 := RIPStat5;
       GetViewSettings(vpt);
       GetTextSettings(tst);
       GetLineSettings(lst);
       Col := GetColor;
       SetColor(0);
       SetViewPort(0,GetMaxY-TheEndOfScreen+1,GetMaxX,GetMaxY,true);
       SetTextStyle(defaultfont,horizdir,1);
       SetLineStyle(SolidLn,0,NormWidth);
       SetTextJustify(LeftText,TopText);
       {MAKE CHANGES HERE}
       SetFillStyle(SolidFill,7);
       Bar(0,0,GetMaxX,TheEndOfScreen-2);
       SetColor(8);
       Line(0,0,GetMaxX,0);
       SetColor(15);
       Line(0,TheEndOfScreen-1,GetMaxX,TheEndOfScreen-1);
       frameline(num1);
       frameline(num2);
       frameline(num3);
       frameline(num4);
       SetColor(0);
       OutTextXY(10,6,'USR:');
       OutTextXY(num1+7,6,'S:');
       OutTextXY(num2+7,6,'T:');
       OutTextXY(num3+7,6,'B:');
       OutTextXY(num4+7,6,'M:');
       SetColor(14);
       OutTextXY(9,5,'USR:');
       OutTextXY(num1+6,5,'S:');
       OutTextXY(num2+6,5,'T:');
       OutTextXY(num3+6,5,'B:');
       OutTextXY(num4+6,5,'M:');
       SetColor(0);
       OutTextXY(44,6,RIPStat1);
       OutTextXY(num1+25,6,RIPStat2);
       OutTextXY(num2+25,6,RIPStat3);
       OutTextXY(num3+25,6,RIPStat4);
       OutTextXY(num4+25,6,RIPStat5);
       SetColor(15);
       OutTextXY(43,5,RIPStat1);
       OutTextXY(num1+24,5,RIPStat2);
       OutTextXY(num2+24,5,RIPStat3);
       OutTextXY(num3+24,5,RIPStat4);
       OutTextXY(num4+24,5,RIPStat5);
       SetColor(col);
       SetViewPort(0,0,GetMaxX,GetMaxY-TheEndOfScreen,true);
       with tst do
       begin
         SetTextStyle(font,direction,charsize);
         SetTextJustify(Horiz,Vert);
       end;
       with lst do
         SetLineStyle(LineStyle,Pattern,Thickness);
     END;
end;

End.