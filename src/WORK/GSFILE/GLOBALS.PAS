{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES {$IFNDEF MSDOS}VideoUtils,{$ENDIF}Gunshot,ApTimer,MkFFile;


TYPE BiggerBuffer     = Array[1..64000] Of Byte;
TYPE _TIC_File_Info   = RECORD
     FileName         : String[12];
     AreaTag          : String[12];
     Replaces         : String[12];
     AkaFrom          : AddrType;
     Crc              : String[8];
     Password         : String[8];
     OneDescription   : String;
     LDescription     : Array[1..18] Of String[45];
     LNumDesc         : Byte;
     AreaDesc         : String[40];
     Origin           : AddrType;
     END;
TYPE GetPutRecord     = RECORD
     LineLength       : Byte;
     Line             : Array[1..160] Of Byte;
     END;
TYPE Get_Put1         = RECORD
     NumLines         : Byte;
     Lines            : Array[1..50] Of GetPutRecord;
     END;
VAR  NodeNumber       : Word;
     ScanForViruses   : Boolean;
     DoCrcChecking    : Boolean;
     DoConverting     : Boolean;
     BaseDirectory    : String;
     NumberOfTics     : Word;
{$IFDEF MSDOS}
     SavedScreen      : Array[1..4000] Of Byte;
{$ENDIF}     
{$IFNDEF MSDOS}
     SavedScreen      : TScreenBuffer;
{$ENDIF}
     SavedScreenXY    : Word;
     CurrentTicFile   : String[12];
     TossIsGood       : Boolean;
     TicFileName      : Array[1..1000] Of String[12];
     FArcDefs         : File Of _Archiver_Record;
     FArcUtils        : File Of _Archiver_Utilities;
     FMailer          : File Of _Mailer_Record;
     FScanners        : File Of _VirusScanners_Record;
     FSystemInfo      : File Of _SystemDat_Record;
     FLinksInfo       : File Of _Links_Record;
     FLinkGroups      : File Of _Link_Groups_Record;
     FFileArea        : File Of _FileArea_Record;
     FFileSubs        : File Of _FileSub_Record;
     FFileDefs        : File Of _FileDefinitions;
     FFileDesc        : File Of _FileDescriptions;
     FFileDefs2       : File Of _FileDefinitions;
     FFileDesc2       : File Of _FileDescriptions;
     FNetworkInfo     : File Of _Network_Record;
     FMailer2Info     : File Of _Mailer2_Record;
     FNetOrigins      : File Of _Origin_Record;
     NetOrigins       : _Origin_Record;
     Mailer2Info      : _Mailer2_Record;
     NetworkInfo      : _Network_Record;
     FileDesc         : _FileDescriptions;
     FileDefs         : _FileDefinitions;
     FileDefs2        : _FileDefinitions;
     FileSubs         : _FileSub_Record;
     FileArea         : _FileArea_Record;
     FileArea2        : _FileArea_Record;
     LinkGroups       : _Link_Groups_Record;
     LinksInfo        : _Links_Record;
     ArcDefs          : _Archiver_Record;
     ArcUtils         : _Archiver_Utilities;
     Mailer           : _Mailer_Record;
     Scanners         : _VirusScanners_Record;
     SystemInfo       : _SystemDat_Record;
     TicFile          : _TIC_File_Info;
     OriginalArcName  : String[12];
     DidADeArc        : Boolean;
     NewFileCrc       : String[8];
     MainScreenActive : Boolean;
     GetPut1          : Get_Put1;
     RunningInbound   : Longint;
     RunningStored    : Longint;
     RunningInFiles   : Longint;
     RunningOutTics   : Longint;
     RunningAFix      : Longint;
     BigTimer         : EventTimer;
     MassiveBuffer    : ^BiggerBuffer;
     AreaFixMessages  : Boolean;
     StatusFile       : Text;
     BufferedFile     : FFileObj;
     KeepAFix         : Boolean;
     DoNotify         : Boolean;
     SwapMethod       : Integer;
     WrappedDesc      : Array[1..18] Of String[45];
     NumWrappedDesc   : Byte;


IMPLEMENTATION


END.