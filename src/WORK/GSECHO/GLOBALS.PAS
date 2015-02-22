{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES Shotgun,MkFFile,ApTimer,BsPkt,MkMsgAbs;


TYPE TwoDimensionAddr  = RECORD
     Net               : Word;
     Node              : Word;
     END;
TYPE FFileRecord       = RECORD
     FName             : String[12];
     FDate             : Longint;
     END;
TYPE BigFileNames      = ARRAY[1..2000] Of FFileRecord;
TYPE Dupe_Records_Abs  = RECORD
     MsgId             : Longint;
     AreaID            : Word;
     END;
TYPE Dupe_Records      = Array[0..5000] Of Dupe_Records_Abs;
TYPE BigBuffer         = Array[1..64000] Of Char;
VAR  BaseDirectory     : String;
     TempUnpack        : String;
     TempOutbound      : String;
     Toss              : Boolean;
     UseEchoToss       : Boolean;
     StripControlLines : Boolean;
     CheckDupes        : Boolean;
     Thereisanareafix  : Boolean;
     DoNotify          : Boolean;
     KeepAFix          : Boolean;
     NodeNumber        : Word;
     SwapMethod        : Integer;
     FLinkGroups       : FFileObj;
     FLinksInfo        : FFileObj;
     BufferedFile      : FFileObj;
     FileNames         : BigFileNames;
     NumBundles        : Longint;
     NumPackets        : Longint;
     NumMsgs           : Longint;
     NumBytes          : Longint;
     NumNetmails       : Longint;
     NumEchomails      : Longint;
     NumExported       : Longint;
     NumDupes          : Longint;
     RunningAFix       : Longint;
     StatusFile        : Text;
     Type2PPacket      : Type2PHeader;
     Type22Packet      : Type22Header;
     Type2Packet       : Type2Header;
     Dupes             : ^Dupe_Records;
     ArcDefs           : _Archiver_Record;
     Mailer            : _Mailer_Record;
     SystemInfo        : _SystemDat_Record;
     NetWorkInfo       : _Network_Record;
     DownLink          : _Links_Record;
     DownLinkGroups    : _Link_Groups_Record;
     UpLink            : _Links_Record;
     UpLinkGroups      : _Link_Groups_Record;
     MessageSubs       : _MessageSub_Record;
     TossTimer         : EventTimer;
     Elapsed           : Longint;
     MsgsPerSecond     : Longint;
     Paths             : Array[1..1024] Of TwoDimensionAddr;
     SeenBys           : Array[1..1024] Of TwoDimensionAddr;
     NumPaths          : Word;
     NumSeenBys        : Word;
     MsgTextBuffer     : ^BigBuffer;
     InBuffer          : Word;
     TossMessageArea   : _MessageArea_Record;
     FTossMessageArea  : File Of _MessageArea_Record;
     ScanMessageArea   : _MessageArea_Record;
     FScanMessageArea  : File Of _MessageArea_Record;
     TossMsg           : AbsMsgPtr;
     ScanMsg           : AbsMsgPtr;


IMPLEMENTATION


END.