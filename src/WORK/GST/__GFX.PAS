{$I DEFINES.INC}
UNIT __Gfx;


INTERFACE


USES BsGraph,Crt,Dos,BsMulti,BsString,BsKeys,BsFile,
     {$IFDEF DPMI}
     Gx2_Bp,Gx2_BpVC,Gr2_Bp,Tx2_Bp;
     {$ELSE}
     GXM,Gx_Tp,Gx_TpVC,Gr_Tp,Tx_Tp;
     {$ENDIF}


CONST FieldBackground : Byte = 1;
      FieldForeground : Byte = 15;
      FieldDisabled   : Byte = 7;
      WindowHeaderC   : Byte = 57;
      WindowHighC     : Byte = 60;
      WindowLowC      : Byte = 54;
      WindowTextC     : Byte = 15;
      WindowTextD     : Byte = 8;
      WindowBack      : Byte = 7;
      WindowHigh      : Byte = 253;
      WindowLow       : Byte = 239;
      ColourRes       : Word = 256;
      XORLine         = 255;
      NumWindows      = 5;
      NumButtons      = 25;
      NumFields       = 20;
TYPE  ButtonInfo      = RECORD
      x1              : Word;
      y1              : Word;
      x2              : Word;
      y2              : Word;
      BType           : Byte;
      FillC           : Byte;
      HBorder         : Byte;
      DBorder         : Byte;
      Holdable        : Boolean;
      Enabled         : Boolean;
      END;
TYPE  FieldInfo       = RECORD
      x1              : Word;
      y1              : Word;
      x2              : Word;
      y2              : Word;
      Text            : String;
      CursorPos       : Byte;
      EntryType       : Byte; {0-Plain String  1-Plain Numeric  2-Proper String}
                              {3-Date          4-Phone Number   5-File Name}
      MaxLength       : Byte;
      Active          : Boolean;
      END;
TYPE  Pick_Info       = RECORD
      Active          : Boolean;
      x1              : Word;
      y1              : Word;
      x2              : Word;
      y2              : Word;
      Top             : Word;
      NumItems        : Word;
      ItemsOnScrn     : Word;
      Current         : Word;
      MaxChars        : Word;
      Locator         : Word;
      Pickable        : Boolean;
      END;
TYPE  Screen_Info     = RECORD
      Index           : Byte;
      OrigX1          : Word;
      OrigY1          : Word;
      OrigX2          : Word;
      OrigY2          : Word;
      XOffset         : Integer;
      YOffSet         : Integer;
      Title           : String;
      HelpTopic       : Word;
      END;
TYPE  Icon30x30       = RECORD
      matrix          : Array[1..30,1..30] Of BYTE;
      END;
TYPE  Icon16x16       = RECORD
      matrix          : Array[1..16,1..16] Of BYTE;
      END;
TYPE  Pick_List       = Array[1..800] Of String[60];
TYPE  Special_Mouse   = RECORD
      Colour          : Word;
      HotX            : Word;
      HotY            : Word;
      MMask           : Array[0..15] Of Word;
      MCursor         : Array[0..15] Of Word;
      END;
VAR   Cutouts         : Array[1..NumWindows,0..1] Of GXHeader;
      CutActive       : Array[1..NumWindows,0..1] Of Boolean;
      CutCoord        : Array[1..NumWindows,0..1,1..4] Of Word;
      Buttons         : Array[1..NumButtons] Of ButtonInfo;
      Fields          : Array[1..NumFields] Of FieldInfo;
      P256            : Array[0..767] Of Byte;
      PickList        : ^Pick_List;
      PickInfo        : Pick_Info;
      Icon30          : Icon30x30;
      Icon16          : Icon16x16;
      {$IFNDEF DPMI}
      UseEMS          : Boolean;
      UseXMS          : Boolean;
      {$ENDIF}
      ScreenInfo      : Screen_Info;
      NFields         : Byte;
      NButtons        : Byte;
      GraphicsLibrary : String[80];
      IconHdr         : GXHeader;
      SvScreen        : GXHeader;
      SvScreen2       : GXHeader;
      SystemFont      : TxHeader;
      HelvFont        : TxHeader;
      RomanFont       : TxHeader;
      BitFont8x8      : TxHeader;
      BitFont8x14     : TxHeader;
      BitFont8x16     : TxHeader;
      GetPut          : GXHeader;
      GetPut2         : GXHeader;
      ClockMouse      : Special_Mouse;
      InsertMouse     : Special_Mouse;
      FieldNum        : Byte;
      LastPressed     : Word;
      CurrentWindow   : Byte;
      CurrentPointer  : Byte;
      HelpFile        : String;
      SelectedFile    : String;

      {Startup}
      PROCEDURE FireUpGfx      (GrafLib,TempDir: String; HorRes: Word);

      {Main Loop Function}
      FUNCTION  MouseHandler   (DoKeys: Boolean): Word;

      {Pick List Functions - In Order Of Function}
      FUNCTION  PickContents   (Index: Word): String;
      PROCEDURE SetPickList    (Index: Word; InString: String);
      PROCEDURE NewPickList    (x,y,OnScreen,MaxChars: Word; Pickable: Boolean);
      PROCEDURE AddToPickList  (InString: String);
      PROCEDURE SetUpPickList;

      {General Drawing}
      FUNCTION  CreateVirtual  (VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
      PROCEDURE SystemField    (x1,y1: Word; EntryType,MaxLength: Byte; Stuff: String);
      FUNCTION  FileSelector   (Path,Spec1,Spec2: String; AllowOpen,AllowNew,IsSave: Boolean): Byte;
      PROCEDURE SystemButton   (x1,y1,x2,y2,Style: Word; Hold,Redraw: Boolean);
      FUNCTION  VerifySave     (InString1,InString2,InString3: String): Boolean;
      PROCEDURE DrawWindow     (x1,y1,x2,y2: word; title: String; HelpTopic: Word);
      PROCEDURE WindowHeader   (title: String; Enabled: Boolean);
      PROCEDURE OutTextXY      (x,y,f,b,size: word; s: String);
      PROCEDURE OutTextXYFR    (x,y,f,b,Size: word; s: String);
      PROCEDURE OutTextXYS     (x,y,f,b: word; s: String);
      PROCEDURE Put            (x,y: Word; Kill: Boolean);
      PROCEDURE Put2           (x,y: Word; Kill: Boolean);
      PROCEDURE Get            (x1,y1,x2,y2: Word);
      PROCEDURE Get2           (x1,y1,x2,y2: Word);
      PROCEDURE InvertedBox    (x1,y1,x2,y2: Word);
      PROCEDURE RaisedBox      (x1,y1,x2,y2: Word);
      PROCEDURE SystemIcon     (x,y,num: Word);
      PROCEDURE SystemIcon16   (x,y,num: Word);
      PROCEDURE ChangeField    (Number: Word);
      PROCEDURE DoHelp         (Topic: Word);
      PROCEDURE DoOkButton     (x,y: Word);
      PROCEDURE DropError      (Num: Word);
      PROCEDURE RedrawField;
      PROCEDURE save_screen2;
      PROCEDURE load_screen2;
      PROCEDURE save_screen;
      PROCEDURE load_screen;
      PROCEDURE KillWindow;

      {Shutdown}
      PROCEDURE ShutdownGfx;


IMPLEMENTATION


PROCEDURE SetDefaultPalette;
VAR  Error    : Integer;
     Ct       : Word;
BEGIN
     Error := gxGetConvertPalette(GxPAL5,@P256);
     Ct    := 0;
     {Basic Palette}
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Purple}
     P256[Ct] := 15; INC(ct);  P256[Ct] := 3;  INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 6;  INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 9;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 37; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 59; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 60; INC(ct);
     {Blues}
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 23; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Dusty Blues}
     P256[Ct] := 7;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 31; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 17; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 27; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 51; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 63; INC(ct);

     P256[Ct] := 15; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 5; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 27; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 37; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 47; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 62; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 9; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 19; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 29; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 39; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 29; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 3; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 6; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 43; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 27; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 1; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 2; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 8; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 47; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 17; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 45; INC(ct);
     {Grays}
     P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);
     P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);
     P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);
     P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     Error := gxSetConvertPalette(GxPAL5,@P256);
     Error := GxSetDisplayPalette(@P256);
END;


PROCEDURE WindowHeader(title: String; Enabled: Boolean);
VAR  X1,Y1,X2,Y2 : Word;
BEGIN
     X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset;
     Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset;
     X2 := ScreenInfo.OrigX2+ScreenInfo.XOffset;
     Y2 := ScreenInfo.OrigY2+ScreenInfo.YOffset;
     GrDisplayMouse(GrHide);
     IF Enabled THEN
     BEGIN
          IF ScreenInfo.HelpTopic=0 THEN
          BEGIN
               GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
               GrDrawRect(x1+6,y1+6,x2-6,y1+24,GrFill);
               OutTextXY(x1+20,y1+8,WindowTextC,255,1,title);
               GrSetColor(WindowLowC);
               GrDrawLine(x1+5,y1+25,x2-5,y1+25);
               GrDrawLine(x2-5,y1+5,x2-5,y1+25);
               GrSetColor(WindowHighC);
               GrDrawLine(x1+5,y1+5,x2-5,y1+5);
               GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          END
          ELSE
          BEGIN
               GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
               GrDrawRect(x1+6,y1+6,x2-27,y1+24,GrFill);
               OutTextXY(x1+20,y1+8,WindowTextC,255,1,title);
               GrSetColor(WindowLowC);
               GrDrawLine(x1+5,y1+25,x2-26,y1+25);
               GrDrawLine(x2-26,y1+5,x2-26,y1+25);
               GrSetColor(WindowHighC);
               GrDrawLine(x1+5,y1+5,x2-26,y1+5);
               GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          END;
     END
     ELSE
     BEGIN
          IF ScreenInfo.HelpTopic=0 THEN
          BEGIN
               GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
               GrDrawRect(x1+6,y1+6,x2-6,y1+24,GrFill);
               OutTextXY(x1+20,y1+8,WindowTextD,255,1,title);
               GrSetColor(WindowLow);
               GrDrawLine(x1+5,y1+25,x2-5,y1+25);
               GrDrawLine(x2-5,y1+5,x2-5,y1+25);
               GrSetColor(WindowHigh);
               GrDrawLine(x1+5,y1+5,x2-5,y1+5);
               GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          END
          ELSE
          BEGIN
               GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
               GrDrawRect(x1+6,y1+6,x2-27,y1+24,GrFill);
               OutTextXY(x1+20,y1+8,WindowTextD,255,1,title);
               GrSetColor(WindowLow);
               GrDrawLine(x1+5,y1+25,x2-26,y1+25);
               GrDrawLine(x2-26,y1+5,x2-26,y1+25);
               GrSetColor(WindowHigh);
               GrDrawLine(x1+5,y1+5,x2-26,y1+5);
               GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          END;
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE SaveLastWindow;
VAR  FFile : File;
BEGIN
     WindowHeader(ScreenInfo.Title,False);
     ASSIGN(FFile,'$$SV$$.'+_String(CurrentWindow));
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,Buttons,SizeOf(Buttons));
     BLOCKWRITE(FFile,Fields,SizeOf(Fields));
     BLOCKWRITE(FFile,PickInfo,SizeOf(PickInfo));
     BLOCKWRITE(FFile,ScreenInfo,SizeOf(ScreenInfo));
     BLOCKWRITE(FFile,NFields,SizeOf(NFields));
     BLOCKWRITE(FFile,NButtons,SizeOf(NButtons));
     BLOCKWRITE(FFile,FieldNum,SizeOf(FieldNum));
     IF PickInfo.Active THEN BLOCKWRITE(FFile,PickList^,SizeOf(PickList^));
     CLOSE(FFile);
     NButtons    := 0;
     NFields     := 0;
     FieldNum    := 0;
     LastPressed := 0;
     IF PickInfo.Active THEN DISPOSE(PickList);
     FillChar(ScreenInfo,SizeOf(ScreenInfo),0);
     FillChar(PickInfo,SizeOf(PickInfo),0);
     FillChar(Buttons,SizeOf(Buttons),0);
     FillChar(Fields,SizeOf(Fields),0);
END;


PROCEDURE LoadLastWindow;
VAR  FFile : File;
BEGIN
     FieldNum := 0;
     ASSIGN(FFile,'$$SV$$.'+_String(CurrentWindow));
     RESET(FFile,1);
     BLOCKREAD(FFile,Buttons,SizeOf(Buttons));
     BLOCKREAD(FFile,Fields,SizeOf(Fields));
     BLOCKREAD(FFile,PickInfo,SizeOf(PickInfo));
     BLOCKREAD(FFile,ScreenInfo,SizeOf(ScreenInfo));
     BLOCKREAD(FFile,NFields,SizeOf(NFields));
     BLOCKREAD(FFile,NButtons,SizeOf(NButtons));
     BLOCKREAD(FFile,FieldNum,SizeOf(FieldNum));
     IF PickInfo.Active THEN
     BEGIN
          NEW(PickList);
          BLOCKREAD(FFile,PickList^,SizeOf(PickList^));
     END;
     CLOSE(FFile);
     ERASE(FFile);
     LastPressed := 0;
     WindowHeader(ScreenInfo.Title,True);
END;


PROCEDURE LoadFontFiles;
VAR  Error    : Integer;
     GraphLib : GXLIB;

     {$IFNDEF DPMI}
     FUNCTION FontLoaded(FileName: String; VAR TextHeader: TxHeader): Boolean;
     VAR  AnyGood : Boolean;
     LABEL          AllIsOk;
     BEGIN
          AnyGood := True;
          IF UseEMS THEN
          BEGIN
               Error := txLibFont(gxEMM,GraphLib,FileName,TextHeader);
               IF Error=txSuccess THEN GOTO AllIsOk;
          END;
          IF UseXMS THEN
          BEGIN
               Error := txLibFont(gxXMM,GraphLib,FileName,TextHeader);
               IF Error=txSuccess THEN GOTO AllIsOk;
          END;
          Error := txLibFont(gxDMM,GraphLib,FileName,TextHeader);
          IF Error=txSuccess THEN GOTO AllIsOk;
          AnyGood := False;
          AllIsOk:
          FontLoaded := AnyGood;
     END;
     {$ENDIF}

BEGIN
     gxOpenLib(gxGXL,GraphicsLibrary,GraphLib,Nil,0);
     {$IFDEF DPMI}
     txLibFont(gxCMM,GraphLib,'GUI_____.GFT',SystemFont);
     txLibFont(gxCMM,GraphLib,'HELV____.GFT',HelvFont);
     txLibFont(gxCMM,GraphLib,'ROMAN___.GFT',RomanFont);
     txLibFont(gxCMM,GraphLib,'BIT8X16.GFT',BitFont8x16);
     txLibFont(gxCMM,GraphLib,'BIT8X14.GFT',BitFont8x14);
     txLibFont(gxCMM,GraphLib,'BIT8X8.GFT',BitFont8x8);
     {$ELSE}
     FontLoaded('GUI_____.GFT',SystemFont);
     FontLoaded('HELV____.GFT',HelvFont);
     FontLoaded('ROMAN___.GFT',RomanFont);
     FontLoaded('BIT8X16.GFT',BitFont8x16);
     FontLoaded('BIT8X14.GFT',BitFont8x14);
     FontLoaded('BIT8X8.GFT',BitFont8x8);
     {$ENDIF}
     gxLibBuffer(GraphLib,'CLOCK.MSE',0,SizeOf(ClockMouse),@ClockMouse);
     gxLibBuffer(GraphLib,'INSERT.MSE',0,SizeOf(InsertMouse),@InsertMouse);
     gxCloseLib(GraphLib);
     txSetFont(SystemFont);
END;


PROCEDURE DropError(Num: Word);
VAR  Temp : String;
BEGIN
     CASE Num OF
     1:   Temp := 'Mouse not installed. Please load your mouse driver.';
     2:   Temp := 'SVGA mode not found. Try using a VESA driver.';
     3:   Temp := 'Could not install DMM manager. Free some conventional mem.';
     4:   Temp := 'Buffer allocation error @entry point : #004';
     5:   Temp := 'Buffer allocation error @entry point : #005';
     6:   Temp := 'Buffer allocation error @entry point : #006';
     7:   Temp := 'Buffer allocation error @entry point : #007';
     8:   Temp := 'Buffer allocation error @entry point : #008';
     9:   Temp := 'Buffer allocation error @entry point : #009';
     10:  Temp := 'Font loader error @entry point : #001';
     11:  Temp := 'Font loader error @entry point : #001';
     12:  Temp := 'Couldn''t install XMM driver. Install EMS memory.';
     13:  Temp := 'Buffer allocation error @entry point : #010';
     14:  Temp := 'Graphic library missing';
     END;
     TextMode(co80);
     ClrScr;
     TextBackground(4);
     TextColor(15);
     ClrEol;
     WRITELN('  SERIOUS CRITICAL ERROR!!!');
     TextBackground(0);
     WRITELN;
     WRITELN('     '+Temp);
     WRITELN;
     Halt;
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(WindowHigh);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(WindowLow);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE RaisedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(WindowLow);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(WindowHigh);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
VAR  Error : Integer;
LABEL        Continue;
BEGIN
     {$IFDEF DPMI}
     Error := gxCreateVirtual(gxCMM,VBuffer,CT,W,H);
     {$ELSE}
     IF UseEMS THEN
     BEGIN
          Error := gxCreateVirtual(gxEMM,VBuffer,CT,W,H);
          IF Error=GxSuccess THEN GOTO Continue;
     END;
     IF UseXMS THEN
     BEGIN
          Error := gxCreateVirtual(gxXMM,VBuffer,CT,W,H);
          IF Error=GxSuccess THEN GOTO Continue;
     END;
     Error := gxCreateVirtual(gxDMM,VBuffer,CT,W,H);
     {$ENDIF}
     IF Error=GxSuccess THEN GOTO Continue;
     CreateVirtual := False;
     Exit;
     Continue:
     CreateVirtual := True;
END;


PROCEDURE save_screen;
VAR  Error  : Integer;
LABEL         Continue;
BEGIN
     {$IFDEF DPMI}
     Error := gxCreateVirtual(gxCMM,SvScreen,TheDisplay,GraphMaxX+1,GraphMaxY+1);
     {$ELSE}
     Error := gxCreateVirtual(gxDMM,SvScreen,TheDisplay,GraphMaxX+1,GraphMaxY+1);
     {$ENDIF}
     IF Error=GxSuccess THEN GOTO Continue;
     DropError(5);
     Continue:
     Error := gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen,0,0);
END;


PROCEDURE load_screen;
BEGIN
     gxVirtualDisplay(SvScreen,0,0,0,0,GraphMaxX,GraphMaxY,0);
     gxDestroyVirtual(SvScreen);
END;


PROCEDURE save_screen2;
VAR  Error  : Integer;
LABEL         Continue;
BEGIN
     {$IFDEF DPMI}
     Error := gxCreateVirtual(gxCMM,SvScreen2,TheDisplay,GraphMaxX+1,GraphMaxY+1);
     {$ELSE}
     Error := gxCreateVirtual(gxDMM,SvScreen2,TheDisplay,GraphMaxX+1,GraphMaxY+1);
     {$ENDIF}
     IF Error=GxSuccess THEN GOTO Continue;
     DropError(5);
     Continue:
     Error := gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen2,0,0);
END;


PROCEDURE load_screen2;
BEGIN
     gxVirtualDisplay(SvScreen2,0,0,0,0,GraphMaxX,GraphMaxY,0);
     gxDestroyVirtual(SvScreen2);
END;


PROCEDURE SystemIcon(x,y,num: Word);
VAR  LoopX  : Word;
     LoopY  : Word;
     GLib   : GxLib;
BEGIN
     gxOpenLib(gxGXL,GraphicsLibrary,GLib,Nil,0);
     gxLibBuffer(GLib,_String(Num)+'.ICO',0,900,@Icon30);
     gxCloseLib(GLib);
     gxDisplayVirtual(x,y,x+29,y+29,0,IconHdr,0,0);
     grSetActiveVirtual(IconHdr);
     grSetVirtual(gxTrue);
     WITH Icon30 DO
     BEGIN
      FOR LoopX := 0 TO 29 DO
       FOR loopY := 0 TO 29 DO
        IF Matrix[loopX+1,loopY+1]<>255 THEN
         GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
     END;
     grSetVirtual(gxFalse);
     gxVirtualDisplay(IconHdr,0,0,x,y,x+29,y+29,0);
END;


PROCEDURE SystemIcon16(x,y,num: Word);
VAR  LoopX  : Word;
     LoopY  : Word;
     GLib   : GxLib;
BEGIN
     gxOpenLib(gxGXL,GraphicsLibrary,GLib,Nil,0);
     gxLibBuffer(GLib,_String(Num)+'.ICO',0,256,@Icon16);
     gxCloseLib(GLib);
     gxDisplayVirtual(x,y,x+15,y+15,0,IconHdr,0,0);
     grSetActiveVirtual(IconHdr);
     grSetVirtual(gxTrue);
     WITH Icon16 DO
     BEGIN
      FOR LoopX := 0 TO 15 DO
       FOR loopY := 0 TO 15 DO
        IF Matrix[loopX+1,loopY+1]<>255 THEN
         GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
     END;
     grSetVirtual(gxFalse);
     gxVirtualDisplay(IconHdr,0,0,x,y,x+15,y+15,0);
END;


PROCEDURE SystemButton(x1,y1,x2,y2,Style: Word; Hold,Redraw: Boolean);
BEGIN
     LastPressed := 0;
     IF (NButtons>=NumButtons) THEN Exit;
     INC(NButtons);
     Buttons[NButtons].Holdable := Hold;
     Buttons[NButtons].Enabled  := True;
     CASE Style OF
     1:   BEGIN
               IF Redraw THEN
               BEGIN
                    GrSetColor(0);
                    GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                    GrDrawRect(x1,y1,x2,y2,GrFill+GrOutline);
                    GrSetColor(WindowLow);
                    GrDrawLine(x1+1,y2-1,x2-1,y2-1);
                    GrDrawLine(x2-1,y1+1,x2-1,y2-1);
                    GrSetColor(WindowHigh);
                    GrDrawLine(x1+1,y1+1,x2-1,y1+1);
                    GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               END;
               Buttons[NButtons].x2      := x2;
               Buttons[NButtons].y2      := y2;
          END;
     4:   BEGIN
               IF Redraw THEN SystemIcon(x1,y1,21);
               Buttons[NButtons].x2      := x1+15;
               Buttons[NButtons].y2      := y1+15;
          END;
     END;
     Buttons[NButtons].x1      := x1;
     Buttons[NButtons].y1      := y1;
     Buttons[NButtons].HBorder := WindowHigh;
     Buttons[NButtons].DBorder := WindowLow;
     Buttons[NButtons].BType   := Style;
     Buttons[NButtons].FillC   := WindowBack;
END;


PROCEDURE save_cutout(x1,y1,x2,y2: word; IndexNum,ForeBack: Word);
VAR  Error  : Integer;
LABEL         Continue;
BEGIN
     IF CutActive[IndexNum,ForeBack]=False THEN
     BEGIN
          IF CreateVirtual(Cutouts[IndexNum,ForeBack],x2-x1+1,y2-y1+1,TheDisplay) THEN GOTO Continue;
          DropError(4);
     END;
     Continue:
     Error := gxDisplayVirtual(x1,y1,x2,y2,0,Cutouts[IndexNum,ForeBack],0,0);
     CutCoord[IndexNum,ForeBack,1] := x1;
     CutCoord[IndexNum,ForeBack,2] := y1;
     CutCoord[IndexNum,ForeBack,3] := x2;
     CutCoord[IndexNum,ForeBack,4] := y2;
     IF Error=GxSuccess THEN CutActive[IndexNum,ForeBack] := True
                        ELSE CutActive[IndexNum,ForeBack] := False;
END;


PROCEDURE load_cutout(x,y: Integer; IndexNum,ForeBack: Word);
BEGIN
     IF CutActive[IndexNum,ForeBack]=True THEN
     BEGIN
          gxVirtualDisplay(Cutouts[IndexNum,ForeBack],0,0,CutCoord[IndexNum,ForeBack,1]+x,
                           CutCoord[IndexNum,ForeBack,2]+y,CutCoord[IndexNum,ForeBack,3]+x,
                           CutCoord[IndexNum,ForeBack,4]+y,0);
     END;
END;


PROCEDURE kill_cutout(IndexNum,ForeBack: Word);
BEGIN
     IF CutActive[IndexNum,ForeBack]=True THEN
     BEGIN
          gxDestroyVirtual(Cutouts[IndexNum,ForeBack]);
          CutActive[IndexNum,ForeBack] := False;
     END;
END;


PROCEDURE OutTextXY(x,y,f,b,size: word; s: String);
BEGIN
     CASE Size OF
     1:   txSetFont(SystemFont);
     2:   txSetFont(BitFont8x16);
     3:   txSetFont(BitFont8x14);
     4:   txSetFont(BitFont8x8);
     5:   txSetFont(HelvFont);
     6:   txSetFont(RomanFont);
     END;
     IF b=255 THEN txSetFace(txNormal+txTrans)
              ELSE txSetFace(txNormal);
     txSetColor(f,b);
     txOutTextXy(s,x,y);
     txSetFont(SystemFont);
END;


PROCEDURE OutTextXYFR(x,y,f,b,Size: word; s: String);
VAR  Width : Integer;
BEGIN
     CASE Size OF
     1:   txSetFont(SystemFont);
     5:   txSetFont(HelvFont);
     6:   txSetFont(RomanFont);
     END;
     Width := TxStrWidth(s);
     IF b=255 THEN
     BEGIN
          txSetFace(txNormal+txTrans);
          txSetColor(f,b);
          txOutTextXy(s,x-Width,y);
     END
     ELSE
     BEGIN
          txSetFace(txNormal);
          txSetColor(f,b);
          txOutTextXy(s,x-Width,y);
     END;
     txSetFont(SystemFont);
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: word; title: String; HelpTopic: Word);
BEGIN
     IF (CurrentWindow<>0) THEN SaveLastWindow
     ELSE
     BEGIN
          NButtons    := 0;
          NFields     := 0;
          FieldNum    := 0;
          LastPressed := 0;
     END;
     IF CurrentWindow>=NumWindows THEN Exit;
     INC(CurrentWindow);
     ScreenInfo.OrigX1    := x1;
     ScreenInfo.OrigY1    := y1;
     ScreenInfo.OrigX2    := x2;
     ScreenInfo.OrigY2    := y2;
     ScreenInfo.XOffset   := 0;
     ScreenInfo.YOffSet   := 0;
     ScreenInfo.Index     := CurrentWindow;
     ScreenInfo.Title     := Title;
     ScreenInfo.HelpTopic := HelpTopic;
     Save_Cutout(x1,y1,x2+5,y2+5,CurrentWindow,0);
     {WINDOW}
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrSetColor(0);
     GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrSetColor(WindowLow);
     GrDrawLine(x1+1,y2-1,x2-1,y2-1);
     GrDrawLine(x2-1,y1+1,x2-1,y2-1);
     GrSetColor(WindowHigh);
     GrDrawLine(x1+1,y1+1,x2-1,y1+1);
     GrDrawLine(x1+1,y1+1,x1+1,y2-1);
     {WINDOW HEADER}
     IF HelpTopic=0 THEN
     BEGIN
          GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
          GrDrawRect(x1+6,y1+6,x2-6,y1+24,GrFill);
          GrSetColor(WindowLowC);
          GrDrawLine(x1+5,y1+25,x2-5,y1+25);
          GrDrawLine(x2-5,y1+5,x2-5,y1+25);
          GrSetColor(WindowHighC);
          GrDrawLine(x1+5,y1+5,x2-5,y1+5);
          GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          GrSetColor(WindowLow);
          GrDrawLine(x1+4,y1+4,x2-4,y1+4);
          GrDrawLine(x1+4,y1+4,x1+4,y1+26);
          GrSetColor(WindowHigh);
          GrDrawLine(x1+5,y1+26,x2-4,y1+26);
          GrDrawLine(x2-4,y1+5,x2-4,y1+26);
     END
     ELSE
     BEGIN
          GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
          GrDrawRect(x1+6,y1+6,x2-27,y1+24,GrFill);
          GrSetColor(WindowLowC);
          GrDrawLine(x1+5,y1+25,x2-26,y1+25);
          GrDrawLine(x2-26,y1+5,x2-26,y1+25);
          GrSetColor(WindowHighC);
          GrDrawLine(x1+5,y1+5,x2-26,y1+5);
          GrDrawLine(x1+5,y1+5,x1+5,y1+25);
          GrSetColor(WindowLow);
          GrDrawLine(x1+4,y1+4,x2-25,y1+4);
          GrDrawLine(x1+4,y1+4,x1+4,y1+26);
          GrSetColor(WindowHigh);
          GrDrawLine(x1+5,y1+26,x2-25,y1+26);
          GrDrawLine(x2-25,y1+5,x2-25,y1+26);
          SystemIcon16(x2-22,y1+7,113);
     END;
     {WINDOW SHADOW}
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(x1+5,y2+1,x2+5,y2+5,GrFill);
     GrDrawRect(x2+1,y1+5,x2+5,y2+5,GrFill);
     OutTextXY(x1+20,y1+8,WindowTextC,255,1,title);
END;


PROCEDURE KillWindow;
BEGIN
     IF PickInfo.Active THEN DISPOSE(PickList);
     GrDisplayMouse(GrHide);
     Load_Cutout(0,0,ScreenInfo.Index,0);
     GrDisplayMouse(GrShow);
     Kill_Cutout(ScreenInfo.Index,0);
     Kill_Cutout(ScreenInfo.Index,1);
     ScreenInfo.XOffSet := 0;
     ScreenInfo.YOffSet := 0;
     ScreenInfo.OrigX1  := 999;
     ScreenInfo.OrigX2  := 999;
     ScreenInfo.OrigY1  := 999;
     ScreenInfo.OrigY1  := 999;
     LastPressed        := 0;
     DEC(CurrentWindow);
     IF (CurrentWindow<>0) THEN LoadLastWindow;
END;


PROCEDURE move_frame(x1,y1,x2,y2: word);
VAR  new_x,new_y       : word;
     x_add,y_add       : word;
     start_x1,start_y1 : word;
     old_m_x,old_m_y   : word;
     LastX,LastY       : Word;
     OldX1,OldY1       : Word;
     OldX2,OldY2       : Word;
     X_Move,Y_Move     : Integer;
     Loop              : Word;
     SVX               : Word;
     SVY               : Word;
BEGIN
     SVX      := GetMouseX;
     SVY      := GetMouseY;
     old_m_x  := SVX-x1;
     old_m_y  := SVY-y1;
     start_x1 := x1;
     start_y1 := y1;
     LastX    := SVX;
     LastY    := SVY;
     x_add    := x2-SVX;
     y_add    := y2-SVY;
     GrSetMouseBounds(old_m_x+5,old_m_y+5,GraphMaxX-x_add-5,GraphMaxY-y_add-5);
     GrSetLineStyle(GrLSolid,2);
     GrSetOp(GxXOR);
     GrSetColor(XORLine);
     GrDisplayMouse(GrHide);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrDisplayMouse(GrShow);
     REPEAT
           IF ((GetMouseX<>LastX) OR (GetMouseY<>LastY)) THEN
           BEGIN
                Lastx := GetMouseX;
                Lasty := GetMouseY;
                GrDisplayMouse(GrHide);
                GrDrawRect(x1,y1,x2,y2,GrOutline);
                x1 := LastX-old_m_x;
                y1 := Lasty-old_m_y;
                x2 := Lastx+X_Add;
                y2 := Lasty+y_add;
                GrDrawRect(x1,y1,x2,y2,GrOutline);
                GrDisplayMouse(GrShow);
           END;
     UNTIL GrGetMouseButtons<>GrLButton;
     GrDisplayMouse(GrHide);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrDisplayMouse(GrShow);
     X_Move := 0;
     Y_Move := 0;
     IF (x1>start_x1) THEN X_Move := x1-start_x1
        ELSE IF (x1<start_x1) THEN X_Move := -1*(start_x1-x1);
     IF (y1>start_y1) THEN Y_Move := y1-start_y1
        ELSE IF (y1<start_y1) THEN Y_Move := -1*(start_y1-y1);
     GrSetOp(GxSet);
     GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
     GrSetLineStyle(GrLSolid,1);
     {RECALCULATE BUTTONS, AND WINDOW}
     IF ((X_Move<>0) OR (Y_Move<>0)) THEN
     BEGIN
          GrDisplayMouse(GrHide);
          save_cutout(ScreenInfo.OrigX1+ScreenInfo.XOffSet,ScreenInfo.OrigY1+ScreenInfo.YOffSet,
                      ScreenInfo.OrigX2+ScreenInfo.XOffSet,ScreenInfo.OrigY2+ScreenInfo.YOffSet,ScreenInfo.Index,1);
          load_cutout(0,0,ScreenInfo.Index,0);
          OldX1              := ScreenInfo.OrigX1+ScreenInfo.XOffSet;
          OldY1              := ScreenInfo.OrigY1+ScreenInfo.YOffSet;
          OldX2              := ScreenInfo.OrigX2+ScreenInfo.XOffSet;
          OldY2              := ScreenInfo.OrigY2+ScreenInfo.YOffSet;
          ScreenInfo.XOffSet := ScreenInfo.XOffSet+X_Move;
          ScreenInfo.YOffSet := ScreenInfo.YOffSet+Y_Move;
          save_cutout(ScreenInfo.OrigX1+ScreenInfo.XOffSet,ScreenInfo.OrigY1+ScreenInfo.YOffSet,
                      ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,ScreenInfo.Index,0);
          load_cutout(X_Move,Y_Move,ScreenInfo.Index,1);
          GrSetFillStyle(GrFCloseDot,0,GrTrans);
          GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffSet+5,ScreenInfo.OrigY2+ScreenInfo.YOffSet+1,
                     ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,GrFill);
          GrDrawRect(ScreenInfo.OrigX2+ScreenInfo.XOffSet+1,ScreenInfo.OrigY1+ScreenInfo.YOffSet+5,
                     ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,GrFill);
          GrDisplayMouse(GrShow);
          FOR Loop := 1 TO NButtons DO
          BEGIN
               IF ((Buttons[Loop].x1>=OldX1) AND (Buttons[Loop].x2<=OldX2) AND
                   (Buttons[Loop].y1>=OldY1) AND (Buttons[Loop].y2<=OldY2)) THEN
               BEGIN
                    Buttons[Loop].x1 := Buttons[Loop].x1+X_Move;
                    Buttons[Loop].y1 := Buttons[Loop].y1+Y_Move;
                    Buttons[Loop].x2 := Buttons[Loop].x2+X_Move;
                    Buttons[Loop].y2 := Buttons[Loop].y2+Y_Move;
               END;
          END;
          IF NFields<>0 THEN
          BEGIN
               FOR Loop := 1 TO NFields DO
               BEGIN
                    IF ((Fields[Loop].x1>=OldX1) AND (Fields[Loop].x2<=OldX2) AND
                       (Fields[Loop].y1>=OldY1) AND (Fields[Loop].y2<=OldY2)) THEN
                    BEGIN
                         Fields[Loop].x1 := Fields[Loop].x1+X_Move;
                         Fields[Loop].y1 := Fields[Loop].y1+Y_Move;
                         Fields[Loop].x2 := Fields[Loop].x2+X_Move;
                         Fields[Loop].y2 := Fields[Loop].y2+Y_Move;
                    END;
               END;
          END;
          IF PickInfo.Active THEN
          BEGIN
               PickInfo.x1 := PickInfo.x1+X_Move;
               PickInfo.y1 := PickInfo.y1+Y_Move;
               PickInfo.x2 := PickInfo.x2+X_Move;
               PickInfo.y2 := PickInfo.y2+Y_Move;
               PickInfo.Locator := PickInfo.Locator+Y_Move;
          END;
     END;
END;


PROCEDURE PressButton(Num: Word);
VAR  x1,y1,x2,y2 : Word;
BEGIN
     x1 := Buttons[Num].X1;
     x2 := Buttons[Num].X2;
     y1 := Buttons[Num].Y1;
     y2 := Buttons[Num].Y2;
     GrDisplayMouse(GrHide);
     CASE Buttons[Num].BType OF
     1:   BEGIN
               GrSetColor(Buttons[Num].FillC);
               GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
          END;
     2:   BEGIN
               GrSetColor(Buttons[Num].FillC);
               GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
          END;
     3:   {INVISIBLE ICON};
     4:   SystemIcon(x1,y1,52);
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE ReleaseButton(Num: Word);
VAR  x1,y1,x2,y2 : Word;
BEGIN
     x1 := Buttons[Num].X1;
     x2 := Buttons[Num].X2;
     y1 := Buttons[Num].Y1;
     y2 := Buttons[Num].Y2;
     GrDisplayMouse(GrHide);
     CASE Buttons[Num].BType OF
     1:   BEGIN
               GrSetColor(Buttons[Num].DBorder);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Buttons[Num].HBorder);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
          END;
     2:   BEGIN
               GrSetColor(Buttons[Num].HBorder);
               GrDrawRect(x1+1,y1+1,x2,y2,GrOutline);
               GrSetColor(Buttons[Num].DBorder);
               GrDrawLine(x1,y1,x2,y1);
               GrDrawLine(x1,y1,x1,y2);
               GrDrawLine(x1+2,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+2,x2-1,y2-1);
          END;
     3:   {INVISIBLE ICON};
     4:   SystemIcon(x1,y1,51);
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE OutTextXYS(x,y,f,b: word; s: String);
BEGIN
     txSetFont(BitFont8x16);
     IF (B<>255) THEN txSetFace(txNORMAL)
                 ELSE txSetFace(txTRANS);
     txSetColor(f,b);
     txOutTextXy(s,x,y);
     txSetFont(SystemFont);
END;


PROCEDURE SystemField(x1,y1: Word; EntryType,MaxLength: Byte; Stuff: String);
VAR  x2,y2 : Word;
BEGIN
     IF (NFields>=NumFields) THEN Exit;
     x2 := x1+20+(MaxLength*8);
     y2 := y1+20;
     INC(NFields);
     IF NFields=1 THEN
     BEGIN
          Fields[NFields].Active := True;
          FieldNum               := 1;
     END
     ELSE Fields[NFields].Active := False;
     Fields[NFields].x1         := x1;
     Fields[NFields].y1         := y1;
     Fields[NFields].x2         := x2;
     Fields[NFields].y2         := y2;
     Fields[NFields].Text       := Stuff;
     Fields[NFields].CursorPos  := LENGTH(Stuff)+1;
     Fields[NFields].EntryType  := EntryType;
     Fields[NFields].MaxLength  := MaxLength;
     IF NFields=FieldNum THEN
     BEGIN
          GrSetFillStyle(GrFSolid,FieldBackground,GrOpaque);
          GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill);
          InvertedBox(x1+1,y1+1,x2-1,y2-1);
          OutTextXYS(x1+10,y1+3,FieldForeground,255,Stuff+'_');
     END
     ELSE
     BEGIN
          GrSetFillStyle(GrFSolid,FieldBackground,GrOpaque);
          GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill);
          OutTextXYS(x1+10,y1+3,FieldDisabled,255,Stuff);
     END;
     InvertedBox(x1,y1,x2,y2);
END;


PROCEDURE ChangeField(Number: Word);
VAR  x2,y2 : Word;
BEGIN
     IF NFields<=1 THEN Exit;
     {First, kill the last one}
     Fields[FieldNum].Active := False;
     GrSetColor(FieldBackground);
     GrDrawRect(Fields[FieldNum].x1+1,Fields[FieldNum].y1+1,
                Fields[FieldNum].x2-1,Fields[FieldNum].y2-1,GrOutline);
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldDisabled,
                FieldBackground,_PadRight(Fields[FieldNum].Text,Fields[FieldNum].MaxLength+1));
     {Set the new one active}
     FieldNum := Number;
     Fields[FieldNum].Active := True;
     Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
     {Draw it out}
     InvertedBox(Fields[FieldNum].x1+1,Fields[FieldNum].y1+1,
                 Fields[FieldNum].x2-1,Fields[FieldNum].y2-1);
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldForeground,255,
                _PadRight(Fields[FieldNum].Text+'_',Fields[FieldNum].MaxLength+1));
END;


PROCEDURE RedrawField;
BEGIN
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldForeground,FieldBackground,
                _PadRight(Fields[FieldNum].Text,Fields[FieldNum].MaxLength+1));
     OutTextXYS(Fields[FieldNum].x1+10+((Fields[FieldNum].CursorPos-1)*8),
                Fields[FieldNum].y1+3,FieldForeground,255,'_');
END;


PROCEDURE ProcessButton(xx,yy: Word);
VAR  Loop  : Word;
BEGIN
     IF NFields<>0 THEN
     BEGIN
          FOR Loop := 1 TO NFields DO
          BEGIN
               IF ((xx>Fields[Loop].x1) AND (xx<Fields[Loop].x2) AND
                  (yy>Fields[Loop].y1) AND (yy<Fields[Loop].y2)) THEN
               BEGIN
                    IF Loop<>FieldNum THEN
                    BEGIN
                         GrDisplayMouse(GrHide);
                         ChangeField(Loop);
                         GrDisplayMouse(GrShow);
                         Exit;
                    END;
               END;
          END;
     END;
     IF ((LastPressed=0) AND (NButtons<>0)) THEN
     BEGIN
          FOR Loop := 1 TO NButtons DO
          BEGIN
               IF ((xx>=Buttons[Loop].x1) AND (xx<=Buttons[Loop].x2)) THEN
               BEGIN
                    IF ((yy>=Buttons[Loop].y1) AND (yy<=Buttons[Loop].y2)) THEN
                    BEGIN
                         IF Buttons[Loop].Enabled THEN
                         BEGIN
                              LastPressed := Loop;
                              PressButton(LastPressed);
                              Exit;
                         END;
                    END;
               END;
          END;
     END
     ELSE IF (LastPressed<>0) THEN
     BEGIN
          {CHECK TO SEE IF THE USER MOVED OFF OF THE BUTTON}
          IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
              (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2)) THEN
          BEGIN
               ReleaseButton(LastPressed);
               LastPressed := 0;
          END;
     END;
END;


PROCEDURE HandleKeys;
VAR  c      : Char;
     ThePos : Word;
LABEL         DnArrow,SkipIn;
BEGIN
     GrDisplayMouse(GrHide);
     C := ReadKey;
     IF NFields=0 THEN
     BEGIN
          IF ORD(c)=0 THEN c := ReadKey;
          GrDisplayMouse(GrShow);
          Exit;
     END;
     CASE ORD(c) OF
     13:  GOTO DnArrow;
     0:   BEGIN
               C := ReadKey;
               CASE ORD(c) OF
               15,72: BEGIN {SHIFT TAB & UpArrow}
                           IF FieldNum=1 THEN ChangeField(NFields)
                                         ELSE ChangeField(FieldNum-1);
                      END;
               80:    BEGIN {DownArrow}
                           DnArrow:
                           IF FieldNum=NFields THEN ChangeField(1)
                                               ELSE ChangeField(FieldNum+1);
                      END;
               71:    BEGIN {HOME}
                           IF (Fields[FieldNum].CursorPos<>1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := 1;
                                RedrawField;
                           END;
                      END;
               79:    BEGIN {END}
                           IF (Fields[FieldNum].CursorPos<>LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
                                RedrawField;
                           END;
                      END;
               75:    BEGIN {Left}
                           IF (Fields[FieldNum].CursorPos>1) THEN
                           BEGIN
                                DEC(Fields[FieldNum].CursorPos);
                                RedrawField;
                           END;
                      END;
               77:    BEGIN {Right}
                           IF (Fields[FieldNum].CursorPos<LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                                RedrawField;
                           END;
                      END;
               83:    BEGIN {DELETE}
                           ThePos := Fields[FieldNum].CursorPos;
                           IF (ThePos<=LENGTH(Fields[FieldNum].Text)) THEN
                           BEGIN
                                Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                      _Mid(Fields[FieldNum].Text,ThePos+1,LENGTH(Fields[FieldNum].Text));
                                RedrawField;
                           END;
                      END;
               ELSE   BEGIN
                           C := IsTheKeyOk(C,True);
                           IF (C<>#0) THEN GOTO SkipIn;
                      END;
               END;
          END;
     8:   BEGIN {BACKSPACE}
               ThePos := Fields[FieldNum].CursorPos;
               IF ThePos>1 THEN
               BEGIN
                    Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-2)+
                          _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                    DEC(Fields[FieldNum].CursorPos);
                    RedrawField;
               END;
          END;
     9:   BEGIN {TAB}
               IF FieldNum=NFields THEN ChangeField(1)
                                   ELSE ChangeField(FieldNum+1);
          END;
     127: BEGIN {Ctrl-Backspace}
               Fields[FieldNum].Text := '';
               Fields[FieldNum].CursorPos := 1;
               RedrawField;
          END;
     ELSE
       BEGIN
         C := IsTheKeyOk(C,False);
         IF (C<>#0) THEN
         BEGIN
              SkipIn:
              IF (LENGTH(Fields[FieldNum].Text)<Fields[FieldNum].MaxLength) THEN
              BEGIN
                   CASE Fields[FieldNum].EntryType OF
                   0:   BEGIN {0-Plain String}
                             ThePos := Fields[FieldNum].CursorPos;
                             Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                             INC(Fields[FieldNum].CursorPos);
                        END;
                   1:   BEGIN {1-Plain Numeric}
                             IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                             BEGIN
                                  ThePos := Fields[FieldNum].CursorPos;
                                  Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                                  INC(Fields[FieldNum].CursorPos);
                             END;
                        END;
                   2:   BEGIN {2-Proper String}
                             ThePos := Fields[FieldNum].CursorPos;
                             IF ThePos=1 THEN C := UpCase(C)
                             ELSE
                             BEGIN
                                  IF (ThePos<>2) THEN
                                  BEGIN
                                       IF Fields[FieldNum].Text[ThePos-1]=' ' THEN C := UpCase(C);
                                  END;
                             END;
                             Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                             INC(Fields[FieldNum].CursorPos);
                        END;
                   3:   BEGIN {3-Date}
                        END;
                   4:   BEGIN {4-Phone Number}
                             IF (((ORD(c)>47) AND (ORD(c)<58)) OR (c='-') OR
                                (c=' ') OR (c='(') OR (c=')') OR (c='*')) THEN
                             BEGIN
                                  ThePos := Fields[FieldNum].CursorPos;
                                  Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                                  INC(Fields[FieldNum].CursorPos);
                             END;
                        END;
                   5:   BEGIN {5-Filename}
                             C := UpCase(C);
                             IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR (c=':') OR
                                (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_') OR
                                (c='\') OR (c='!')) THEN
                             BEGIN
                                  ThePos := Fields[FieldNum].CursorPos;
                                  Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                                  INC(Fields[FieldNum].CursorPos);
                             END;
                        END;
                   END;
                   RedrawField;
              END;
         END;
       END;
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE DrawPickListLocator;
VAR  Work      : Word;
     Percent   : Real;
     Pixels    : Word;
     YRelative : Word;
BEGIN
     IF PickInfo.NumItems>PickInfo.ItemsOnScrn THEN
     BEGIN
          Work             := PickInfo.NumItems-PickInfo.ItemsOnScrn;
          Percent          := (PickInfo.Top-1)/Work;
          Pixels           := PickInfo.y2-PickInfo.y1-61;
          YRelative        := Round(Pixels*Percent);
          PickInfo.Locator := PickInfo.y1+21+YRelative;
     END
     ELSE PickInfo.Locator := PickInfo.y1+21;
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(PickInfo.x2+2,PickInfo.y1+21,PickInfo.x2+20,PickInfo.y2-21,GrFill);
     GrSetColor(0);
     GrDrawRect(PickInfo.x2+2,PickInfo.Locator,PickInfo.x2+20,PickInfo.Locator+20,GrOutline);
     RaisedBox(PickInfo.x2+3,PickInfo.Locator+1,PickInfo.x2+19,PickInfo.Locator+19);
END;


PROCEDURE NewPickList(x,y,OnScreen,MaxChars: Word; Pickable: Boolean);
BEGIN
     NEW(PickList);
     PickInfo.Active      := True;
     PickInfo.x1          := x;
     PickInfo.y1          := y;
     PickInfo.Top         := 1;
     PickInfo.NumItems    := 0;
     PickInfo.ItemsOnScrn := OnScreen;
     PickInfo.Current     := 1;
     PickInfo.MaxChars    := MaxChars;
     PickInfo.x2          := x+20+(MaxChars*8);
     PickInfo.y2          := y+16+(OnScreen*14);
     PickInfo.Locator     := PickInfo.y1+21;
     PickInfo.Pickable    := Pickable;
     {Play area}
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(PickInfo.x1,PickInfo.y1,PickInfo.x2,PickInfo.y2,GrFill+GrOutline);
     GrSetLineStyle(GrLSolid,1);
     InvertedBox(PickInfo.x1-1,PickInfo.y1-1,PickInfo.x2+22,PickInfo.y2+1);
     {Scroll Bar}
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrDrawRect(PickInfo.x2+1,PickInfo.y1,PickInfo.x2+21,PickInfo.y2,GrFill+GrOutline);
     {Scroll Bar Buttons}
     SystemButton(PickInfo.x2+1,PickInfo.y1,PickInfo.x2+21,PickInfo.y1+20,1,True,True);
     SystemIcon(PickInfo.x2+5,PickInfo.y1+5,28);
     SystemButton(PickInfo.x2+1,PickInfo.y2-20,PickInfo.x2+21,PickInfo.y2,1,True,True);
     SystemIcon(PickInfo.x2+5,PickInfo.y2-15,29);
     DrawPickListLocator;
END;


PROCEDURE AddToPickList(InString: String);
BEGIN
     INC(PickInfo.NumItems);
     IF PickInfo.NumItems=800 THEN DropError(9);
     PickList^[PickInfo.NumItems] := _PadRight(InString,PickInfo.MaxChars);
END;


FUNCTION PickContents(Index: Word): String;
BEGIN
     PickContents := PickList^[Index];
END;


PROCEDURE SetPickList(Index: Word; InString: String);
BEGIN
     PickList^[Index] := InString;
END;


PROCEDURE SetUpPickList;
VAR  Loop : Word;
     Y    : Word;
     Cnt  : Word;
BEGIN
     Cnt := PickInfo.Top;
     Y   := PickInfo.y1+8;
     FOR Loop := 1 TO PickInfo.ItemsOnScrn DO
     BEGIN
          IF Cnt<=PickInfo.NumItems THEN
          BEGIN
               IF PickInfo.Pickable THEN
               BEGIN
                    IF Cnt=PickInfo.Current
                       THEN OutTextXY(PickInfo.x1+3,y,0,250,3,' '+PickList^[Cnt]+' ')
                       ELSE OutTextXY(PickInfo.x1+3,y,0,15,3,' '+PickList^[Cnt]+' ');
               END
               ELSE OutTextXY(PickInfo.x1+3,y,0,15,3,' '+PickList^[Cnt]+' ');
          END
          ELSE OutTextXY(PickInfo.x1+3,y,0,15,3,_PadRight('',PickInfo.MaxChars+2));
          INC(y,14);
          INC(Cnt);
     END;
END;


PROCEDURE ScrollPickUp;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          DEC(PickInfo.Top);
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


PROCEDURE ScrollPickDown;
BEGIN
     IF ((PickInfo.Top+PickInfo.ItemsOnScrn-1)<PickInfo.NumItems) THEN
     BEGIN
          INC(PickInfo.Top);
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


FUNCTION MoveLocator: Boolean;
VAR  LastY : Word;
     OrigY : Word;
     OrigT : Word;

     PROCEDURE CalcTop;
     VAR  Percent   : Real;
          Pixels    : Word;
          YRelative : Word;
          Work      : Word;
     BEGIN
          IF PickInfo.NumItems>PickInfo.ItemsOnScrn THEN
          BEGIN
               Pixels          := (PickInfo.y2-41)-(PickInfo.y1+21);
               YRelative       := PickInfo.Locator-(PickInfo.y1+21);
               Percent         := YRelative/Pixels;
               Work            := PickInfo.NumItems-PickInfo.ItemsOnScrn;
               PickInfo.Top    := Round(Work*Percent)+1;
          END
          ELSE PickInfo.Top := 1;
     END;

BEGIN
     GrDisplayMouse(GrHide);
     GrSetMousePos(PickInfo.x2+1,PickInfo.Locator);
     LastY := PickInfo.Locator;
     OrigY := PickInfo.Locator;
     GrSetMouseBounds(PickInfo.x2+1,PickInfo.y1+21,PickInfo.x2+1,PickInfo.y2-41);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetOp(GxXOR);
     GrSetColor(15);
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     REPEAT
           IF (GetMouseY<>LastY) THEN
           BEGIN
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
                LastY := GetMouseY;
                GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
           END;
     UNTIL GrGetMouseButtons<>GrLButton;
     GrDrawRect(PickInfo.x2+1,LastY,PickInfo.x2+21,LastY+20,GrOutline);
     GrSetOp(GxSet);
     GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
     GrSetMousePos(PickInfo.x2+10,LastY+10);
     GrDisplayMouse(GrShow);
     GrSetLineStyle(GrLSolid,1);
     PickInfo.Locator := LastY;
     OrigT            := PickInfo.Top;
     CalcTop;
     IF (OrigT=PickInfo.Top) THEN
     BEGIN
          PickInfo.Locator := OrigY;
          MoveLocator      := False;
     END
     ELSE MoveLocator := True;
END;


PROCEDURE ScrollPickPgUp;
VAR  Temp : Integer;
BEGIN
     IF (PickInfo.Top>1) THEN
     BEGIN
          Temp := PickInfo.Top-PickInfo.ItemsOnScrn;
          IF Temp<1 THEN Temp := 1;
          PickInfo.Top := Temp;
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


PROCEDURE ScrollPickPgDown;
VAR  Temp : Integer;
BEGIN
     IF ((PickInfo.Top+PickInfo.ItemsOnScrn-1)<PickInfo.NumItems) THEN
     BEGIN
          Temp := PickInfo.Top+PickInfo.ItemsOnScrn;
          IF (Temp>(PickInfo.NumItems-PickInfo.ItemsOnScrn+1))
             THEN Temp := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
          PickInfo.Top := Temp;
          GrDisplayMouse(GrHide);
          DrawPickListLocator;
          SetUpPickList;
          GrDisplayMouse(GrShow);
     END;
END;


FUNCTION MouseHandler(DoKeys: Boolean): Word;
VAR  w        : Word;
     xx       : Word;
     yy       : Word;
     C        : Char;
     TheOne   : Word;
     CurMouse : Byte;
     Looper   : Word;
BEGIN
     IF ((KeyPressed) AND (DoKeys)) THEN HandleKeys;
     w  := 0;
     xx := GetMouseX;
     yy := GetMouseY;
     {=====================================================================}
     {  CHANGING OF THE MOUSE ROUTINE!                                     }
     {=====================================================================}
     CurMouse := 1;
     IF (NFields<>0) THEN
     BEGIN
          FOR Looper := 1 TO NFields DO
          BEGIN
               IF ((xx>=Fields[Looper].x1) AND (xx<=Fields[Looper].x2) AND
                  (yy>=Fields[Looper].y1) AND (yy<=Fields[Looper].y2)) THEN
               BEGIN
                    CurMouse := 4;
               END;
          END;
     END;
     IF PickInfo.Active THEN
     BEGIN
          IF ((xx>=PickInfo.x1) AND (xx<=PickInfo.x2) AND
             (yy>=PickInfo.y1) AND (yy<=PickInfo.y2)) THEN
          BEGIN
               CurMouse := 2;
          END;
     END;
     IF (NButtons<>0) THEN
     BEGIN
          FOR Looper := 1 TO NButtons DO
          BEGIN
               IF ((xx>=Buttons[Looper].x1) AND (xx<=Buttons[Looper].x2) AND
                  (yy>=Buttons[Looper].y1) AND (yy<=Buttons[Looper].y2)) THEN
               BEGIN
                    CurMouse := 2;
               END;
          END;
     END;
     IF ScreenInfo.HelpTopic=0 THEN
     BEGIN
          IF ((xx>ScreenInfo.OrigX1+ScreenInfo.XOffset) AND
             (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset) AND
             (yy>ScreenInfo.OrigY1+ScreenInfo.YOffset) AND
             (yy<ScreenInfo.OrigY1+ScreenInfo.YOffset+24)) THEN
          BEGIN
               CurMouse := 3;
          END;
     END
     ELSE
     BEGIN
          IF ((xx>ScreenInfo.OrigX1+ScreenInfo.XOffset) AND
             (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset-25) AND
             (yy>ScreenInfo.OrigY1+ScreenInfo.YOffset) AND
             (yy<ScreenInfo.OrigY1+ScreenInfo.YOffset+24)) THEN
          BEGIN
               CurMouse := 3;
          END;
          IF ((xx>ScreenInfo.OrigX2+ScreenInfo.XOffset-25) AND
             (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset) AND
             (yy>ScreenInfo.OrigY1+ScreenInfo.YOffset) AND
             (yy<ScreenInfo.OrigY1+ScreenInfo.YOffset+24)) THEN
          BEGIN
               CurMouse := 2;
          END;
     END;
     IF (CurMouse<>CurrentPointer) THEN
     BEGIN
          CASE CurMouse OF
          1:   GrSetMouseStyle(0,15); {Pointer}
          2:   GrSetMouseStyle(5,15); {Finger}
          3:   GrSetMouseStyle(6,15); {Open Hand}
          4:   BEGIN {Insert Cursor}
                    GrSetMouseMask(grCUSER,InsertMouse.HotX,InsertMouse.HotY,
                                   @InsertMouse.MCursor,@InsertMouse.MMask);
                    GrSetMouseStyle(GrCUSER,InsertMouse.Colour);
               END;
          END;
     END;
     CurrentPointer := CurMouse;
     IF GrGetMouseButtons=GrLButton THEN
     BEGIN
          IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
             (xx<PickInfo.x2+21) AND (yy>PickInfo.Locator) AND
             (yy<PickInfo.Locator+20)) THEN
          BEGIN
               IF MoveLocator THEN
               BEGIN
                    GrDisplayMouse(GrHide);
                    DrawPickListLocator;
                    SetUpPickList;
                    GrDisplayMouse(GrShow);
               END;
          END
          ELSE IF ((xx>ScreenInfo.OrigX1+ScreenInfo.XOffset) AND
                  (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset) AND
                  (yy>ScreenInfo.OrigY1+ScreenInfo.YOffset) AND
                  (yy<ScreenInfo.OrigY1+ScreenInfo.YOffset+24)) THEN
          BEGIN
               IF ScreenInfo.HelpTopic=0 THEN
               BEGIN
                    move_frame(ScreenInfo.OrigX1+ScreenInfo.XOffset,ScreenInfo.OrigY1+ScreenInfo.YOffset,
                               ScreenInfo.OrigX2+ScreenInfo.XOffset,ScreenInfo.OrigY2+ScreenInfo.YOffset);
               END
               ELSE
               BEGIN
                    IF ((xx>ScreenInfo.OrigX2+ScreenInfo.XOffset-25) AND
                       (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset)) THEN
                    BEGIN
                         DoHelp(ScreenInfo.HelpTopic);
                    END
                    ELSE
                    BEGIN
                         move_frame(ScreenInfo.OrigX1+ScreenInfo.XOffset,ScreenInfo.OrigY1+ScreenInfo.YOffset,
                                    ScreenInfo.OrigX2+ScreenInfo.XOffset,ScreenInfo.OrigY2+ScreenInfo.YOffset);
                    END;
               END;
          END
          ELSE IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
                  (xx<PickInfo.x2+21) AND (yy>PickInfo.y1+21) AND
                  (yy<PickInfo.Locator)) THEN
          BEGIN
               ScrollPickPgUp;
               REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
          END
          ELSE IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
                  (xx<PickInfo.x2+21) AND (yy>PickInfo.Locator+20) AND
                  (yy<PickInfo.y2-21)) THEN
          BEGIN
               ScrollPickPgDown;
               REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
          END
          ELSE
          BEGIN
               IF ((LastPressed<>0) AND (Buttons[LastPressed].Holdable)) THEN
               BEGIN
                    IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
                       (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2)) THEN
                    BEGIN
                         ReleaseButton(LastPressed);
                         LastPressed := 0;
                    END
                    ELSE
                    BEGIN
                         {BUTTON IS STILL PRESSED}
                         IF PickInfo.Active THEN
                         BEGIN
                              w := LastPressed;
                              IF ((xx>PickInfo.x2+1) AND (xx<PickInfo.x2+21) AND
                                 (yy>PickInfo.y1) AND (yy<PickInfo.y1+21)) THEN
                              BEGIN
                                   ScrollPickUp;
                              END
                              ELSE IF ((xx>PickInfo.x2+1) AND (xx<PickInfo.x2+21) AND
                                      (yy>PickInfo.y2-20) AND (yy<PickInfo.y2)) THEN
                              BEGIN
                                   ScrollPickDown;
                              END;
                         END;
                    END;
               END
               ELSE
               BEGIN
                    ProcessButton(xx,yy);
                    IF ((PickInfo.Active) AND (PickInfo.Pickable)) THEN
                    BEGIN
                         IF ((xx>PickInfo.x1) AND (xx<PickInfo.x2) AND
                            (yy>PickInfo.y1+8) AND (yy<PickInfo.y2-8)) THEN
                         BEGIN
                              TheOne := PickInfo.Top+Trunc((yy-PickInfo.y1+8)/14)-1;
                              IF TheOne<>PickInfo.Current THEN
                              BEGIN
                                   IF ((TheOne>=PickInfo.Top) AND (TheOne<=(PickInfo.Top+PickInfo.ItemsOnScrn-1))) THEN
                                   BEGIN
                                        IF TheOne<=PickInfo.NumItems THEN
                                        BEGIN
                                             PickInfo.Current := TheOne;
                                             GrDisplayMouse(GrHide);
                                             SetUpPickList;
                                             GrDisplayMouse(GrShow);
                                        END;
                                   END;
                              END;
                         END;
                    END;
               END;
          END;
     END
     ELSE
     BEGIN
          IF LastPressed<>0 THEN
          BEGIN
               xx := GetMouseX;
               yy := GetMouseY;
               ReleaseButton(LastPressed);
               IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
                  (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2))
                  THEN w := 0
                  ELSE w := LastPressed;
               LastPressed := 0;
          END;
     END;
     MouseHandler := w;
END;


FUNCTION FileSelector(Path,Spec1,Spec2: String; AllowOpen,AllowNew,IsSave: Boolean): Byte;
TYPE File_List   = RECORD
     FileName    : String[8];
     FileExt     : String[3];
     FileDate    : String[10];
     END;
TYPE BigList     = Array[1..700] Of File_List;
VAR  FileList    : ^BigList;
     TempList    : File_List;
     NumFiles    : Word;
     DirInfo     : SearchRec;
     Temp        : String;
     Loop        : Word;
     Work        : Word;
     Top         : Word;
     Bot         : Word;
     AllDone     : Boolean;
     DoJob       : Word;
     TypeWindowX : Word;
     TypeWindowY : Word;
     C           : Char;
     DT          : DateTime;
     FileTime    : Longint;
     YY,MM,DD    : String;
     EditPos     : Word;
     x,y         : Word;
     I,J         : Word;
     Current     : Word;
LABEL              SkipHandler;
BEGIN
     IF (MemAvail<(SizeOf(BigList)+16384)) THEN Exit;
     New(FileList);
     SelectedFile := _RemoveSpaces(SelectedFile);
     IF Path[Length(Path)]='\' THEN Delete(Path,Length(Path),1);
     NumFiles := 0;
     {CHECK THE FIRST SPEC}
     FindFirst(Path+'\'+Spec1,Anyfile-Directory-VolumeID-Hidden-SysFile,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          Temp := _UpperCase(DirInfo.Name);
          INC(NumFiles);
          FileTime := DirInfo.Time;
          UnpackTime(FileTime,dt);
          WITH dt DO
          BEGIN
            YY := _String(Year);
            MM := _String(Month); IF Length(MM)=1 THEN MM := '0'+MM;
            DD := _String(Day);   IF Length(DD)=1 THEN DD := '0'+DD;
            FileList^[NumFiles].FileDate := MM+'-'+DD+'-'+YY;
          END;
          FileList^[NumFiles].FileName := _NoExtension(Temp);
          FileList^[NumFiles].FileExt  := _GetFileExtension(Temp);
          FindNext(DirInfo);
     END;
     {CHECK THE SECOND SPEC}
     IF Spec2<>'' THEN
     BEGIN
          FindFirst(Path+'\'+Spec2,Anyfile-Directory-VolumeID-Hidden-SysFile,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               Temp := _UpperCase(DirInfo.Name);
               INC(NumFiles);
               FileTime := DirInfo.Time;
               UnpackTime(FileTime,dt);
               WITH dt DO
               BEGIN
                    YY := _String(Year);
                    MM := _String(Month); IF Length(MM)=1 THEN MM := '0'+MM;
                    DD := _String(Day);   IF Length(DD)=1 THEN DD := '0'+DD;
                    FileList^[NumFiles].FileDate := MM+'-'+DD+'-'+YY;
               END;
               FileList^[NumFiles].FileName := _NoExtension(Temp);
               FileList^[NumFiles].FileExt  := _GetFileExtension(Temp);
               FindNext(DirInfo);
          END;
     END;
     {Alpha}
     FOR i := 1 TO NumFiles DO
     BEGIN
          FOR j := 1 TO NumFiles DO
          BEGIN
               IF ((FileList^[i].FileName+'.'+FileList^[i].FileExt)<(FileList^[j].FileName+'.'+FileList^[j].FileExt)) THEN
               BEGIN
                    TempList     := FileList^[i];
                    FileList^[i] := FileList^[j];
                    FileList^[j] := TempList;
               END;
          END;
     END;
     IF NumFiles=0 THEN
     BEGIN
       Dispose(FileList);
       FileSelector := 3;
       Exit;
     END;
     GrDisplayMouse(GrHide);
     DrawWindow(150,50,405,365,'FILE SELECTOR',0);
     {Space definitions}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+53;
     {Window Text}
     OutTextXY(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+35,1,255,1,'Filename:');
     OutTextXY(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+80,1,255,1,'Files:');
     {Window Areas}
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+50,ScreenInfo.OrigX1+229,ScreenInfo.OrigY1+70,GrFill+GrOutline);
     GrSetLineStyle(GrLSolid,1);
     InvertedBox(ScreenInfo.OrigX1+9,ScreenInfo.OrigY1+49,ScreenInfo.OrigX1+230,ScreenInfo.OrigY1+71);
     {Buttons}
     SystemButton(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+275,ScreenInfo.OrigX1+75,ScreenInfo.OrigY1+305,1,False,True);
     IF NOT(AllowOpen) THEN DEC(NButtons);
     SystemButton(ScreenInfo.OrigX1+80,ScreenInfo.OrigY1+275,ScreenInfo.OrigX1+145,ScreenInfo.OrigY1+305,1,False,True);
     IF NOT(AllowNew)  THEN DEC(NButtons);
     SystemButton(ScreenInfo.OrigX1+150,ScreenInfo.OrigY1+275,ScreenInfo.OrigX1+215,ScreenInfo.OrigY1+305,1,False,True);
     IF NOT(AllowOpen) THEN OutTextXY(ScreenInfo.OrigX1+30,ScreenInfo.OrigY1+282,8,255,1,'Load')
                       ELSE OutTextXY(ScreenInfo.OrigX1+30,ScreenInfo.OrigY1+282,0,255,1,'Load');
     IF IsSave THEN
     BEGIN
          IF NOT(AllowNew) THEN OutTextXY(ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+282,8,255,1,'Save')
                           ELSE OutTextXY(ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+282,0,255,1,'Save');
     END
     ELSE
     BEGIN
          IF NOT(AllowNew) THEN OutTextXY(ScreenInfo.OrigX1+95,ScreenInfo.OrigY1+282,8,255,1,'Create')
                           ELSE OutTextXY(ScreenInfo.OrigX1+95,ScreenInfo.OrigY1+282,0,255,1,'Create');
     END;
     OutTextXY(ScreenInfo.OrigX1+165,ScreenInfo.OrigY1+282,0,255,1,'Cancel');
     {Stuffed Filename}
     OutTextXY(ScreenInfo.OrigX1+15,ScreenInfo.OrigY1+53,0,15,2,SelectedFile);
     OutTextXY(ScreenInfo.OrigX1+15+(Length(SelectedFile)*8),ScreenInfo.OrigY1+54,0,15,2,'_');

     NewPickList(ScreenInfo.OrigX1+ScreenInfo.XOffset+11,
                 ScreenInfo.OrigY1+ScreenInfo.YOffset+96,11,24,True);
     FOR i := 1 TO NumFiles DO
     BEGIN
          Temp := _PadRight(FileList^[i].FileName+'.'+FileList^[i].FileExt,14)+FileList^[i].FileDate;
          AddToPickList(Temp);
     END;
     Current := 0;
     SetUpPickList;
     GrDisplayMouse(GrShow);
     AllDone := False;
     EditPos := Length(SelectedFile)+1;
     REPEAT
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+53;
           IF KeyPressed THEN
           BEGIN
                C := UpCase(ReadKey);
                IF Ord(C)=0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                               GOTO SkipHandler;
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(SelectedFile)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                               GOTO SkipHandler;
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(SelectedFile)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(SelectedFile,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,SelectedFile+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(SelectedFile)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(c) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(SelectedFile,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,SelectedFile+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     ELSE BEGIN
                               IF LENGTH(SelectedFile)<12 THEN
                               BEGIN
                                    IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR
                                       (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_')) THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         SelectedFile := _Mid(SelectedFile,1,EditPos-1)+C+
                                                         _Mid(SelectedFile,EditPos,LENGTH(SelectedFile));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,SelectedFile);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                         GOTO SkipHandler;
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           DoJob := MouseHandler(False);
           IF (PickInfo.Current<>Current) THEN
           BEGIN
                Current := PickInfo.Current;
                Temp := FileList^[Current].FileName+'.'+FileList^[Current].FileExt;
                IF SelectedFile<>Temp THEN
                BEGIN
                     SelectedFile := Temp;
                     GrDisplayMouse(GrHide);
                     OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,_PadRight(SelectedFile,13));
                     EditPos := LENGTH(SelectedFile)+1;
                     OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                     GrDisplayMouse(GrShow);
                END;
           END;
           IF (AllowOpen AND AllowNew) THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {LOAD}
                          IF _FileExists(Path+'\'+SelectedFile) THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 1;
                          END;
                     END;
                2:   BEGIN {SAVE}
                          IF SelectedFile<>'' THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 2;
                          END;
                     END;
                3:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE IF AllowOpen THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {LOAD}
                          IF _FileExists(Path+'\'+SelectedFile) THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 1;
                          END;
                     END;
                2:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE IF AllowNew THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {SAVE}
                          IF SelectedFile<>'' THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 2;
                          END;
                     END;
                2:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE
           BEGIN
                CASE DoJob OF
                1:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END;
           SkipHandler:
     UNTIL AllDone;
     KillWindow;
     Dispose(FileList);
END;


FUNCTION VerifySave(InString1,InString2,InString3: String): Boolean;
VAR  C : Word;
BEGIN
     GrDisplayMouse(GrHide);
     DrawWindow(170,120,469,260,'WARNING!!!',0);
     SystemButton(180,210,315,250,1,False,True);
     SystemButton(325,210,459,250,1,False,True);
     SystemIcon(190,215,65);
     SystemIcon(335,215,64);
     SystemIcon(180,160,62);
     OutTextXY(245,225,0,255,1,'Yes');
     OutTextXY(390,225,0,255,1,'No');
     OutTextXY(215,154,0,255,1,InString1);
     OutTextXY(215,170,0,255,1,InString2);
     OutTextXY(215,186,0,255,1,InString3);
     GrDisplayMouse(GrShow);
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           1:   VerifySave := True;
           2:   VerifySave := False;
           END;
     UNTIL (C<>0);
     KillWindow;
END;


PROCEDURE FireUpGfx(GrafLib,TempDir: String; HorRes: Word);
VAR  Error     : Integer;
BEGIN
     FileMode := 66;
     {$IFNDEF DPMI}
     gxSetUserMalloc(@MyFarMalloc,@MyFarFree,@MyFarCoreLeft);
     {$ENDIF}
     IF NOT(_FileExists(GrafLib)) THEN DropError(14);
     GraphicsLibrary := GrafLib;
     GraphicsMode_BS(ColourRes,HorRes,True,True);
     IF NOT(GraphicsInitialized) THEN DropError(2);
     {$IFNDEF DPMI}
     Error   := gxInstallDMM(TempDir,gxNULL);
     UseEMS  := False;
     UseXMS  := False;
     IF gxXMSInstalled=gxSuccess THEN UseXMS := True;
     IF gxEMSInstalled=gxSuccess THEN UseEMS := True;
     IF UseXMS THEN
     BEGIN
          IF NOT(UseEMS) THEN
          BEGIN
               Error := gxInstallXMM(gxNULL);
               IF (Error<>gxSuccess) THEN UseXMS := False;
          END
          ELSE UseXMS := False;
     END;
     {$ENDIF}
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY); GrSetClipping(GrClip);
     TxSetClipRegion(0,0,GraphMaxX,GraphMaxY); TxSetClipping(TxClip);
     SetDefaultPalette;
     Fade_Off;
     LoadFontFiles;
     gxCreateVirtual(gxCMM,IconHdr,TheDisplay,30,30);
     GrSetMouseMode(gxGRAPHICS);
     Error := GrInitMouse;
     IF Error<>GxSuccess THEN DropError(1);
     GrSetMouseMode(gxGRAPHICS);
     GrTrackMouse(GrTrack);
     GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
     SetPixeltoMickey(3,5);
     GrSetMouseStyle(0,15);
     CurrentPointer := 0;
END;


PROCEDURE ShutdownGfx;
BEGIN
     Fade_Out;
     txFreeFont(SystemFont);
     txFreeFont(HelvFont);
     txFreeFont(RomanFont);
     txFreeFont(BitFont8x16);
     txFreeFont(BitFont8x14);
     txFreeFont(BitFont8x8);
     gxDestroyVirtual(IconHdr);
     GrStopMouse;
     {$IFNDEF DPMI}
     IF UseXMS THEN gxRemoveXMM;
     gxRemoveDMM;
     {$ENDIF}
     Delay(512);
     gxSetMode(GxText);
     gxDone;
     TEXTCOLOR(7);
     TEXTBACKGROUND(0);
     ClrScr;
     {$IFNDEF DPMI}
     gxSetUserMalloc(pointer(0),pointer(0),pointer(0));
     {$ENDIF}
END;


PROCEDURE DoOkButton(x,y: Word);
BEGIN
     SystemButton(x,y,x+80,y+40,1,False,True);
     SystemIcon(x+10,y+5,65);
     OutTextXY(x+45,y+13,0,255,1,'Ok');
END;


PROCEDURE Get(x1,y1,x2,y2: Word);
LABEL Continue;
BEGIN
     IF CreateVirtual(GetPut,x2-x1+1,y2-y1+1,TheDisplay) THEN GOTO Continue;
     DropError(6);
     Continue:
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut,0,0);
END;


PROCEDURE Put(x,y: Word; Kill: Boolean);
BEGIN
     gxVirtualDisplay(GetPut,0,0,x,y,GraphMaxX,GraphMaxY,0);
     IF Kill THEN gxDestroyVirtual(GetPut);
END;


PROCEDURE Get2(x1,y1,x2,y2: Word);
LABEL Continue;
BEGIN
     IF CreateVirtual(GetPut2,x2-x1+1,y2-y1+1,TheDisplay) THEN GOTO Continue;
     DropError(6);
     Continue:
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut2,0,0);
END;


PROCEDURE Put2(x,y: Word; Kill: Boolean);
BEGIN
     gxVirtualDisplay(GetPut2,0,0,x,y,GraphMaxX,GraphMaxY,0);
     IF Kill THEN gxDestroyVirtual(GetPut2);
END;


PROCEDURE DoHelp(Topic: Word);
TYPE Lines   = RECORD
     Line    : String[60];
     END;
VAR  C       : Word;
     BFile   : Lines;
     FBFile  : File Of Lines;
     Counter : Longint;
BEGIN
     IF HelpFile='' THEN Exit;
     IF NOT(_FileExists(HelpFile)) THEN Exit;
     Counter := 0;
     ASSIGN(FBFile,HelpFile);
     RESET(FBFile);
     REPEAT
           READ(FBFile,BFile);
           IF BFile.Line='<TOPIC>' THEN INC(Counter);
     UNTIL ((Counter=Topic) OR (EOF(FBFile)));
     IF (Counter<>Topic) THEN
     BEGIN
          CLOSE(FBFile);
          Exit;
     END;
     grDisplayMouse(GrHide);
     DrawWindow(50,27,589,427,'Online Help',0);
     NewPickList(60,60,21,60,False);
     REPEAT
           READ(FBFile,BFile);
           IF (BFile.Line<>'<TOPIC>') THEN AddToPickList(BFile.Line);
     UNTIL ((EOF(FBFile)) OR (BFile.Line='<TOPIC>'));
     CLOSE(FBFile);
     SetUpPickList;
     DoOkButton(502,380);
     grDisplayMouse(GrShow);
     REPEAT
           c := MouseHandler(False);
           IF c=0 THEN TimeSlice;
     UNTIL C=NButtons;
     KillWindow;
END;


END.
