{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES MkMsgAbs,ApTimer,Gunshot,MkFFile;


TYPE Squish_Last_Read  = Array[1..10000] Of Longint;
TYPE Big_Buffer        = Array[1..64000] Of Char;
CONST Progress         : String[40] = 'лллллллллллллллллллллллллллллллллллллллл';
VAR  MessageAreas      : _MessageArea_Record;
     FMessageAreas     : FFileObj;
     FMessageAreas2    : File Of _MessageArea_Record;
     Indexes           : Array[1..10000] Of Word;
     Temp              : String;
     NumMsgs           : Word;
     NewBase           : Word;
     BaseDirectory     : String;
     WeGiveUp          : Boolean;
     TryCount          : Word;
     FunkyFile         : File;
     SourceBase        : AbsMsgPtr;
     DestBase          : AbsMsgPtr;
     BasePath          : String;
     TotalMsgs         : Longint;
     TheTimer          : EventTimer;
     CleanAllReceived  : Boolean;
     CleanPrivReceived : Boolean;
     SLastRead         : ^Squish_Last_Read;
     StripKludges      : Boolean;
     PNumAreas         : Longint;
     PCurrentArea      : Longint;
     OverLimit         : Boolean;
     OrigBytes         : Longint;
     DoneBytes         : Longint;
     PurgeDays         : Word;
     TodaysDate        : Longint;
     BeforeDate        : Longint;
     NodeNumber        : Word;


IMPLEMENTATION


END.