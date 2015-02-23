{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES Gx2_Bp,Tx2_Bp,ApPort,ApTimer,Gunshot,MkFFile;


CONST PolySize    = 24000;
CONST NumCutouts  = 10;
CONST YappDelay   = 540;
CONST XORLine     = 255;
CONST DontSend    = #1#2#3;
TYPE  LiPoint3D   = RECORD
      X,Y,Z       : LongInt;
      END;
TYPE File_Info      = RECORD
     FName          : String[12];
     IsDir          : Boolean;
     END;
TYPE ButCoord       = RECORD
     x1             : Word;
     y1             : Word;
     x2             : Word;
     y2             : Word;
     END;
TYPE Toggle_Info = RECORD
     Percent     : Byte;
     Active      : Boolean;
     x1          : Word;
     y1          : Word;
     x2          : Word;
     y2          : Word;
     Colour      : Byte;
     Horizontal  : Boolean;
     END;
{Holds all required info for windows that are one the stack. 1 is current}
TYPE Saved_Cutouts = RECORD
     Cutout       : GXHeader;
     Active       : Boolean;
     Coordinates  : Array[1..4] Of Word;
     KeepWindow   : Boolean;
     FileName     : String[40];
     MoveX        : Integer;
     MoveY        : Integer;
     WindowDef    : _Raw_File;
     END;
TYPE ButtonInfo   = RECORD
     Return       : Char;
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     BType        : Byte;
     FillC        : Byte;
     HBorder      : Byte;
     DBorder      : Byte;
     Holdable     : Boolean;
     END;
TYPE Screen_Info  = RECORD
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     OrigX1       : Word;
     OrigY1       : Word;
     OrigX2       : Word;
     OrigY2       : Word;
     HasWindow    : Boolean;
     MoveX        : Integer;
     MoveY        : Integer;
     END;
TYPE Poly_Points  = Array[0..PolySize] Of Integer;
TYPE FieldInfo    = RECORD
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Text         : String[70];
     CursorPos    : Byte;
     EntryType    : Byte;
     Length       : Byte;
     Active       : Boolean;
     TextBack     : Byte;
     TextEnabled  : Byte;
     TextDisabled : Byte;
     END;
TYPE Custom_Controls = RECORD
     Icon1        : GXHeader;
     Icon2        : GXHeader;
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     END;
TYPE Animated_Controls = RECORD
     Icon         : Array[1..8] Of GXHeader;
     Current      : Byte;
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     END;
TYPE Animated_Record = Array[1..10] Of Animated_Controls;
TYPE Custom_Record = Array[1..20] Of Custom_Controls;
TYPE Button_Record = Array[1..40] Of ButtonInfo;
TYPE Field_Record = Array[1..15] Of FieldInfo;
TYPE Pick_Info    = RECORD
     Active       : Boolean;
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Top          : Word;
     NumItems     : Word;
     ItemsOnScrn  : Word;
     Current      : Word;
     MaxChars     : Word;
     Locator      : Word;
     Pickable     : Boolean;
     END;
TYPE Pick_List    = RECORD
     Line         : String[100];
     Pickable     : Boolean;
     END;
TYPE YappDropFile = RECORD
     Port         : Byte;
     PortAddr     : String[4];
     Irq          : Byte;
     Device       : Byte;
     Baud         : Longint;
     Logon        : String[30];
     Password     : String[20];
     F1           : String[30];
     F2           : String[30];
     F3           : String[30];
     F4           : String[30];
     F5           : String[30];
     F6           : String[30];
     F7           : String[30];
     F8           : String[30];
     F9           : String[30];
     F10          : String[30];
     Sound        : Boolean;
     UlDir        : String[50];
     DlDir        : String[50];
     VideoSize    : Word;
     END;
TYPE MassiveGraphBuffer = Array[1..64000] Of Byte;
TYPE BufferItem              = RECORD
     Token                   : String[80];
     Replacement             : String[100];
     END;
TYPE Work_Buffer        = Array [1..50] Of BufferItem;
VAR  BBSPort              : PortRecPtr;
     YappDef              : YappDropFile;
     PickList             : Pick_List;
     PickInfo             : Pick_Info;
     P256                 : Array[0..767] Of Byte;
     G256                 : Array[0..767] Of Byte;
     GraphLib             : GXLIB;
     SystemFont           : TxHeader;
     HelvFont             : TxHeader;
     RomanFont            : TxHeader;
     BitFont8x8           : TxHeader;
     BitFont8x14          : TxHeader;
     BitFont8x16          : TxHeader;
     YWindow              : Word;
     Colours              : _SysColourSVGA;
     FColours             : File Of _SysColourSVGA;
     ModeSelected         : Word;
     SESSION_Directory    : String[40];
     RESOURCES            : String[40];
     GST_Directory        : String[40];
     GIP_Directory        : String[40];
     InBuffer             : Word;
     MsgEditorKludge      : Boolean;
     MsgOldX              : Word;
     MsgOldY              : Word;
     SavedCutouts         : Array[1..NumCutouts] Of Saved_Cutouts;
     Buttons              : ^Button_Record;
     Fields               : Field_Record;
     Custom               : Custom_Record;
     Animate              : Animated_Record;
     NButtons             : Byte;
     NCustom              : Byte;
     NAnimate             : Byte;
     NFields              : Byte;
     ScreenInfo           : Screen_Info;
     RawFile              : _Raw_File;
     Icon16               : _Icon16x16;
     Icon30               : _Icon30x30;
     FRawFile             : File Of _Raw_File;
     FIcon16              : File Of _Icon16x16;
     FIcon30              : File Of _Icon30x30;
     PolyPoint            : ^Poly_Points;
     GetPut               : GXHeader;
     GetPut2              : GXHeader;
     IconHdr              : GXHeader;
     BMPFile              : GXHeader;
     WorkFont             : TXHeader;
     FMouse               : File Of _Mouse_Def;
     DefaultMouse         : _Mouse_Def;
     InsertMouse          : _Mouse_Def;
     BPressMouse          : _Mouse_Def;
     BusyMouse            : _Mouse_Def;
     MsgDragMouse         : _Mouse_Def;
     FileDragMouse        : _Mouse_Def;
     WinMoveMouse         : _Mouse_Def;
     LastFont             : String[12];
     LastPressed          : Word;
     SvScreen             : GXHeader;
     UsingBuffer          : Boolean;
     FieldNum             : Word;
     ATimer               : EventTimer;
     SavedMouseX          : Word;
     SavedMouseY          : Word;
     PadX1                : Word;
     PadY1                : Word;
     PadX2                : Word;
     PadY2                : Word;
     DidField             : Boolean;
     ScreenBack           : GXHeader;
     WindowBack           : GXHeader;
     OffScreen            : GXHeader;
     CurMouse             : Byte;
     LastMouse            : Byte;
     DidOneYet            : Boolean;
     Disconnected         : Boolean;
     ScreenNumber         : Word;
     FixedLPT             : Byte;
     Sig                  : String[8];
     CarrierTimer         : EventTimer;
     CtrlPt               : Array [-1..8] Of LiPoint3D;
     Ax,Bx,Cx,Dx          : Real;
     Ay,By,Cy,Dy          : Real;
     Toggle               : Toggle_Info;
     WorkWord             : Word;
     GFXBuffer            : ^MassiveGraphBuffer;

     STheDrives     : String[26];
     SCurrentPath   : String[180];
     SCurrentDrive  : Byte;
     NFiles         : Word;
     FFileInfo      : File Of File_Info;
     FileInfo       : File_Info;
     SCurrentFile   : Word;
     SCurrentRem    : Word;
     WindowX1,
     WindowX2,
     WindowY1,
     WindowY2       : Word;
     SelBut         : Array[1..33] Of ButCoord;
     NSelBut        : Word;
     AtTheTop       : Word;

     Doing_Receive      : Boolean;
     FilesInQueue       : Byte;
     CurrentFileNum     : Byte;
     WeAbort            : Boolean;
     AbortedProtocol    : Boolean;
     IsGfx              : Boolean;
     WorkBuffer         : ^Work_Buffer;
     TBufferedFile      : FFileObj;


IMPLEMENTATION


BEGIN
     ModeSelected    := 640;
     MsgOldX         := 0;
     MsgOldY         := 0;
     ScreenInfo.x1   := 32000;
     ScreenInfo.y1   := 32000;
     ScreenInfo.x2   := 32000;
     ScreenInfo.y2   := 32000;
     PadX1           := 32000;
     PadY1           := 32000;
     PadX2           := 32000;
     PadY2           := 32000;
     CurMouse        := 1;
     LastMouse       := 1;
     NewTimerSecs(CarrierTimer,8);
END.
