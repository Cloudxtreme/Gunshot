{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES Gx2_Bp,Tx2_Bp,Version,Gunshot;


{DRAWING PRIMITIVES    1 - Background          !}
{                      2 - Mouse               !}
{                      3 - Sound               !}
{                      4 - Lines               !}
{                      5 - Boxes               !}
{                      6 - Elipses             !}
{                      7 - Flood Fill          !}
{                      8 - Normal Buttons      !}
{                      9 - Panel Buttons       !}
{                     10 - Pop Buttons         !}
{                     11 - Windows             !}
{                     12 - Icons               !}
{                     13 - Text                !}
{                     14 - Poly Lines          !}
{                     15 - Polygons            !}
{                     16 - Bezier Curves       !}
{                     17 - Bezier Objects      !}
{                     18 - Progress Indicators !}
{                     19 - Input Boxes         !}
{                     20 - Dimension Frames    !}
{                     21 - Pick Lists          !}
{                     22 - Graphics Images     !}
{                     23 - String Pads         !}
{                     24 - Custom Control      !}
{                     25 - Animated Icon       !}
{                     26 - Plain Arc           !}
{                     27 - Clickable Region    !}

CONST MainWindow       = 1;
CONST IconEditWindow   = 2;
CONST AboutWindow      = 3;
CONST LoadIconWindow   = 4;
CONST FileBoxWindow    = 5;
CONST FloatingMenu     = 6;
CONST EditWindow       = 7;
CONST LoadSaveWarning  = 8;
CONST PalSize          = 12;
CONST XORLine          = 255;
CONST FieldBackground  = 15;
CONST FieldForeground  = 0;
CONST FieldDisabled    = 7;
CONST WindowHeaderC    = 57;
CONST WindowHighC      = 60;
CONST WindowLowC       = 54;
CONST WindowTextC      = 15;
CONST WindowTextD      = 8;
CONST WindowBack       = 7;
CONST WindowHigh       = 253;
CONST WindowLow        = 239;
CONST GridSize         = 8;
TYPE  Poly_Points      = Array[0..32000] Of Integer;
TYPE  Pick_List        = Array[1..800] Of String[60];
TYPE  Pick_Info        = RECORD
      Active           : Boolean;
      x1               : Word;
      y1               : Word;
      x2               : Word;
      y2               : Word;
      Top              : Word;
      NumItems         : Word;
      ItemsOnScrn      : Word;
      Current          : Word;
      MaxChars         : Word;
      Locator          : Word;
      END;
TYPE  PalBoxInfo       = RECORD
      Current          : Byte;
      X1               : Word;
      Y1               : Word;
      X2               : Word;
      Y2               : Word;
      Size             : Byte;
      AllowNoColour    : Boolean;
      SelectedX1       : Word;
      SelectedY1       : Word;
      SelectedX2       : Word;
      SelectedY2       : Word;
      DnX1             : Word;
      DnY1             : Word;
      DnX2             : Word;
      DnY2             : Word;
      UpX1             : Word;
      UpY1             : Word;
      UpX2             : Word;
      UpY2             : Word;
      LeftColour       : Word;
      END;
TYPE  Screen_Info      = RECORD
      Index            : Byte;
      OrigX1           : Word;
      OrigY1           : Word;
      OrigX2           : Word;
      OrigY2           : Word;
      XOffset          : Integer;
      YOffSet          : Integer;
      END;
TYPE  ButtonInfo       = RECORD
      x1               : Word;
      y1               : Word;
      x2               : Word;
      y2               : Word;
      BType            : Byte;
      FillC            : Byte;
      HBorder          : Byte;
      DBorder          : Byte;
      Holdable         : Boolean;
      Enabled          : Boolean;
      END;
TYPE  FieldInfo        = RECORD
      x1               : Word;
      y1               : Word;
      x2               : Word;
      y2               : Word;
      Text             : String;
      CursorPos        : Byte;
      EntryType        : Byte;  {0-Plain String}
                                {1-Plain Numeric}
                                {2-Proper String}
                                {3-Date}
                                {4-Phone Number}
      MaxLength        : Byte;
      Active           : Boolean;
      END;
TYPE  LiPoint3D        = RECORD
      X,Y,Z            : LongInt;
      END;
TYPE  SaveInformation  = RECORD
      ScreenInfo       : Screen_Info;
      NButtons         : Byte;
      NFields          : Byte;
      NumPalettes      : Byte;
      END;
VAR   Disabled         : GXHeader;
      GraphLib         : GXLIB;
      Icn              : Array[1..36] OF Byte;
      DrawMode         : Boolean;
      DrawingSomething : Boolean;
      LastPressed      : Word;
      GraphicsLibrary  : String[80];
      P256             : Array[0..767] Of Byte;
      G256             : Array[0..767] Of Byte;
      CtrlPt           : Array [-1..8] Of LiPoint3D;
      Ax,Bx,Cx,Dx      : Real;
      Ay,By,Cy,Dy      : Real;
      FIcon16          : File Of _Icon16x16;
      FIcon30          : File Of _Icon30x30;
      FMouseDef        : File Of _Mouse_Def;
      MouseDef         : _Mouse_Def;
      Icon16           : _Icon16x16;
      Icon30           : _Icon30x30;
      ScreenInfo       : Screen_Info;
      FieldNum         : Byte;
      Fields           : Array[1..30] Of FieldInfo;
      FButtons         : File Of ButtonInfo;
      Buttons          : Array[1..110] Of ButtonInfo;
      NFields          : Byte;
      NButtons         : Byte;
      Saved            : Array[1..6] Of SaveInformation;
      OldX,OldY        : Word;
      IsOn             : Boolean;
      CurX,CurY        : Word;
      YWindow          : Integer;
      ICONDir          : String[50];
      JPEGDir          : String[50];
      FONTDir          : String[50];
      SOUNDDir         : String[50];
      SGDir            : String[50];
      LastBackSty      : Byte;
      LastBackCol      : Byte;
      LastBackPat      : Byte;
      LastBackFil      : String[12];
      Cutouts          : Array[1..10,0..1] Of GXHeader;
      CutActive        : Array[1..10,0..1] Of Boolean;
      CutCoord         : Array[1..10,0..1,1..4] Of Word;
      SvScreen         : GXHeader;
      GetPut           : GXHeader;
      P                : GXHeader;
      BMPFile          : GXHeader;
      IconHdr          : GXHeader;
      Gunshot_Dir      : String;
      WallPaper        : String;
      SystemFont       : TxHeader;
      HelvFont         : TxHeader;
      RomanFont        : TxHeader;
      WorkFont         : TxHeader;
      BitFont8x8       : TxHeader;
      BitFont8x14      : TxHeader;
      BitFont8x16      : TxHeader;
      GrowingWindows   : Boolean;
      Work_Icon30      : _Icon30x30;
      Work_Icon16      : _Icon16x16;
      CurrentIcon      : Word;
      CurrentIFile     : String;
      CurrentDraw      : Word;
      CurrentSize      : Word;
      SmallX           : Word;
      SmallY           : Word;
      CurrentDrawX     : Word;
      CurrentDrawY     : Word;
      DExchange        : Boolean;
      DFill            : Boolean;
      DSucker          : Boolean;
      Palettes         : Array[1..8] Of PalBoxInfo;
      FPalettes        : File Of PalBoxInfo;
      NumPalettes      : Byte;
      ChangedWhich     : Byte;
      PickList         : ^Pick_List;
      PickInfo         : Pick_Info;
      WinX             : Array[1..3] Of Word; {1-Cursor 2-Mask 3-Hotspot}
      WinY             : Array[1..3] Of Word;
      WorkCursor       : Array[1..16,1..16] Of Boolean;
      WorkMask         : Array[1..16,1..16] Of Boolean;
      WorkHotspotX     : Byte;
      WorkHotspotY     : Byte;
      WorkColour       : Word;
      ObjectNumber     : Longint;
      EditNode         : Word;
      StartPoly        : Longint;
      EndPoly          : Longint;
      PolyPoint        : ^Poly_Points;
      WorkWord         : Longint;
      LastFont         : String[12];
      WorkSG           : _Raw_File;
      WorkDir          : String;
      FWorkSG          : File Of _Raw_File;
      HoldRaw          : _Raw_File;
      ScreenMouse      : _Mouse_Def;
      Grid             : Word;
      TrackX           : Word;
      TrackY           : Word;
      MouseOn          : Boolean;
      DoAReDraw        : Boolean;
      LastX,LastY      : Word;
      xxx1,yyy1,
      xxx2,yyy2        : Word;
      KeyBox           : Boolean;
      KeyBoxX          : Word;
      KeyBoxY          : Word;
      CurrentFile      : String;
      LangDir          : String;
      LoadedMouseNumber : Word;
      UseSwapFile      : Boolean;
      SwapFileSize     : Longint;


IMPLEMENTATION


END.
