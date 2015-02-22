{$I DEFINES.INC}
UNIT Globals;


INTERFACE


{$IFDEF DPMI}
USES Gx2_Bp,ApPort,ApTimer,ApAbsPcl,Shotgun;
{$ELSE}
USES Gx_Tp,ApPort,ApTimer,ApAbsPcl,Shotgun;
{$ENDIF}


TYPE Comm_Def         = RECORD
     Device           : Byte;  {1-UART 2-FOSSIL 3-DIGIBOARD}
     Port             : Byte;
     PortAddr         : String[4];
     Irq              : Byte;
     Baud             : Byte;
     DataInit         : String[50];
     FaxInit          : String[50];
     DPrefix          : String[20];
     Hangup           : String[20];
     UlDir            : String[50];
     DlDir            : String[50];
     VideoMode        : Byte; {0-640x480 1-800x600 2-1024x768}
     DialTimeout      : Word;
     CommandDelay     : Word;
     DataInit2        : String[50];
     DataInit3        : String[50];
     YappToUse        : Byte;
     END;
TYPE Fax_Dir          = RECORD
     SendFile         : String[40];
     InPath           : String[40];
     CoverPage        : String[40];
     Title            : String[40];
     YourName         : String[30];
     Recipient        : String[30];
     StationID        : String[20];
     DialPhone        : String[20];
     END;
TYPE Dial_Dir         = RECORD
     Name             : String[30];
     Phone            : String[20];
     Logon            : String[30];
     Password         : String[20];
     F1               : String[30];
     F2               : String[30];
     F3               : String[30];
     F4               : String[30];
     F5               : String[30];
     F6               : String[30];
     F7               : String[30];
     F8               : String[30];
     F9               : String[30];
     F10              : String[30];
     DoESCs           : Boolean;
     Sound            : Boolean;
     END;
TYPE Yapp_DropFile    = RECORD
     Port             : Byte;
     PortAddr         : String[4];
     Irq              : Byte;
     Device           : Byte;
     Baud             : Longint;
     Logon            : String[30];
     Password         : String[20];
     F1               : String[30];
     F2               : String[30];
     F3               : String[30];
     F4               : String[30];
     F5               : String[30];
     F6               : String[30];
     F7               : String[30];
     F8               : String[30];
     F9               : String[30];
     F10              : String[30];
     Sound            : Boolean;
     UlDir            : String[50];
     DlDir            : String[50];
     VideoSize        : Word;
     END;
TYPE InfoRec          = RECORD
     Protocol         : Array[1..2] Of Word;
     FileName         : Array[1..2] Of Word;
     Size             : Array[1..2] Of Word;
     Sent             : Array[1..2] Of Word;
     Speed            : Array[1..2] Of Word;
     Time             : Array[1..2] Of Word;
     Left             : Array[1..2] Of Word;
     CPS              : Array[1..2] Of Word;
     END;
TYPE TransferModeType = (Transmit, Receive);
VAR  BBSPort          : PortRecPtr;
     FDialDir         : File Of Dial_Dir;
     FFaxDir          : File Of Fax_Dir;
     SaveScr          : Array[1..4000] Of Byte;
     CallQueue        : Array[1..1000] Of Word;
     NumInQueue       : Word;
     SavedXX,
     SavedYY          : Word;
     CommDef          : Comm_Def;
     DialDir          : Dial_Dir;
     FaxDir           : Fax_Dir;
     ActualBaud       : Longint;
     BaseDir          : String;
     YappDropFile     : Yapp_DropFile;
     FYappDropFile    : File Of Yapp_DropFile;
     Escape,
     Saved_X,
     Saved_Y          : Byte;
     Control_Code     : String;
     CurX,CurY        : Word;
     OldX,OldY        : Word;
     P                : GxHeader;
     SaveXPos         : Word;
     SaveYPos         : Word;
     SaveAttr         : Word;
     OnlineTime       : String[20];
     FileQueue        : Array[1..13] Of String;
     WeAbort          : Boolean;
     CurrentFileNum   : Word;
     FilesInQueue     : Word;
     doing_receive    : Boolean;
     Info             : InfoRec;
     Timer            : EventTimer;
     TProtocol        : Byte;
     PROTO            : ProtocolRecPtr;
     TransferMode     : TransferModeType;
     SrcFileName      : String;
     AbortedProtocol  : Boolean;
     Offline          : Boolean;
     IsOnline         : Boolean;
     Modems           : _Modems_Record;
     FModems          : File Of _Modems_Record;


IMPLEMENTATION


END.
