{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES Dos,ApTimer,ApAbsFax,ApPort,ApAbsPcl,Shotgun,MkFFile;


CONST YetToGo            = 1;
      Crash              = 2;
      Hold               = 3;
      Sent               = 4;
      MaxMailQueues      = 250;
      FaxClass           : ClassType = ctClass2;
      ACK                = #$06;
      NAK                = #$15;
      ENQ                = #$05;
      YOOHOO             = #$F1;
      TSYNC              = #$AE;
      EMSI_INQ           : String[14] = '**EMSI_INQC816';
      EMSI_REQ           : String[14] = '**EMSI_REQA77E';
      EMSI_ACK           : String[14] = '**EMSI_ACKA490';
      EMSI_NAK           : String[14] = '**EMSI_NAKEEC3';
      EMSI_CLI           : String[14] = '**EMSI_CLIFA8C';
      EMSI_ICI           : String[14] = '**EMSI_ICI2D73';
      EMSI_HBT           : String[14] = '**EMSI_HBTEAEE';
      EMSI_IRQ           : String[14] = '**EMSI_IRQ8E08';
      SessionType        : String[16] = 'EMSI';
      QueueWindowTop     = 9;
      FBuffSize          = 16384;
TYPE  TransferModeType   = (Transmit, Receive);
TYPE  Hello_Packet       = RECORD
      Signal             : Word;
      Hello_Version      : Word;
      Product            : Word;
      Product_Major      : Word;
      Product_Minor      : Word;
      BBSName            : Array[1..60] Of Char;
      Sysop              : Array[1..20] Of Char;
      Zone               : Word;
      Net                : Word;
      Node               : Word;
      Point              : Word;
      Password           : Array[1..8] Of Char;
      Reserved2          : Array[1..8] Of Byte;
      Capabilities       : Word;
      Reserved3          : Array[1..12] Of Byte;
      END;
TYPE  GetPutRecord       = RECORD
      LineLength         : Byte;
      Line               : Array[1..160] Of Byte;
      END;
TYPE  Get_Put1           = RECORD
      NumLines           : Byte;
      Lines              : Array[1..50] Of GetPutRecord;
      END;
TYPE  Message_Header     = RECORD
      MsgNumber          : Longint;
      FirstText          : Longint;
      NumberText         : Longint;
      MsgFrom            : String[79];
      MsgTo              : String[79];
      MsgSubject         : String[79];
      MsgDateTime        : DateTime;
      SeeAlso            : Longint;
      Reply              : Longint;
      Local              : Boolean;
      Echo               : Boolean;
      Sent               : Boolean;
      KillSent           : Boolean;
      TruncSent          : Boolean;
      KillFileSent       : Boolean;
      Recv               : Boolean;
      Priv               : Boolean;
      Crash              : Boolean;
      FileAttach         : Boolean;
      FileRequest        : Boolean;
      Hold               : Boolean;
      Orphan             : Boolean;
      Delete             : Boolean;
      InTransit          : Boolean;
      Immediate          : Boolean;
      Direct             : Boolean;
      Exclusive          : Boolean;
      Dest               : AddrType;
      Orig               : AddrType;
      END;
TYPE  FidoMsgHeader      = RECORD
      MsgFrom            : Array[1..36] Of Char;
      MsgTo              : Array[1..36] Of Char;
      MsgSubject         : Array[1..72] Of Char;
      DateTime           : Array[1..20] Of Char; {eg: "01 Jan 86  02:34:56"+#0}
      TimesRead          : Word;
      DestNode           : Word;
      OrigNode           : Word;
      Cost               : Word;
      OrigNet            : Word;
      DestNet            : Word;
      Fill               : Array[1..8] Of Char;
      ReplyTo            : Word;
      Attribute          : Word;
      NextReply          : Word;
      END;
{                                                                          }
{    Attribute   bit       meaning                                         }
{                ---       --------------------                            }
{                  0  +    Private                                         }
{                  1  + s  Crash                                           }
{                  2       Recd                                            }
{                  3       Sent                                            }
{                  4  +    FileAttached                                    }
{                  5       InTransit                                       }
{                  6       Orphan                                          }
{                  7       KillSent                                        }
{                  8       Local                                           }
{                  9    s  HoldForPickup                                   }
{                 10  +    unused                                          }
{                 11    s  FileRequest                                     }
{                 12  + s  ReturnReceiptRequest                            }
{                 13  + s  IsReturnReceipt                                 }
{                 14  + s  AuditRequest                                    }
{                 15    s  FileUpdateReq                                   }
{                                                                          }
{                       s - this bit is supported by SEAdog only           }
{                       + - this bit is not zeroed before packeting        }
{                                                                          }
TYPE  Type2PHeader       = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      Year               : Integer;
      Month              : Integer;
      Day                : Integer;
      Hour               : Integer;
      Min                : Integer;
      Sec                : Integer;
      Baud               : Integer;
      PktVer             : Integer;
      OrigNet            : Word;
      DestNet            : Word;
      PrdCodL            : Byte;
      PVMajor            : Byte;
      Password           : Array[1..8] Of Char;
      QOrigZone          : Word;
      QDestZone          : Word;
      Filler             : Word;
      CapValid           : Word;
      PrdCodH            : Byte;
      PVMinor            : Byte;
      CapWord            : Word;
      OrigZone           : Word;
      DestZone           : Word;
      OrigPoint          : Word;
      DestPoint          : Word;
      ProdData           : Longint;
      END;
TYPE  Type2Header        = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      Year               : Word;
      Month              : Word;
      Day                : Word;
      Hour               : Word;
      Minute             : Word;
      Second             : Word;
      Baud               : Word;
      PacketType         : Byte;
      Scrap              : Byte;
      OrigNet            : Word;
      DestNet            : Word;
      ProductCode        : Byte;
      SerialNumber       : Byte;
      Password           : Array[1..8] Of Char;
      OrigZone           : Word;
      DestZone           : Word;
      Fill               : Array[1..20] Of Byte;
      END;
TYPE  Type22Header       = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      OrigPoint          : Word;
      DestPoint          : Word;
      Reserved           : Array[1..8] Of Byte;
      PktMinVer          : Word; {2}
      PktMajVer          : Word; {2}
      OrigNet            : Word;
      DestNet            : Word;
      ProductCode        : Byte;
      ProductVer         : Byte;
      Password           : Array[1..8] Of Char;
      OrigZone           : Word;
      DestZone           : Word;
      OrigDomain         : Array[1..8] Of Char;
      DestDomain         : Array[1..8] Of Char;
      Filler             : Array[1..4] Of Byte;
      END;
TYPE  BigBuffer          = Array[1..48000] Of Char;
TYPE  PakdMessageHeader  = RECORD
      Signature          : Byte; {Always #2}
      Fill               : Byte;
      OrigNode           : Word;
      DestNode           : Word;
      OrigNet            : Word;
      DestNet            : Word;
      Attribute          : Word;
      Cost               : Word;
      DateTime           : Array[1..20] Of Char;
      END;
TYPE  Mail_Queue         = RECORD
      DestAddr           : AddrType;   {The address you are calling}
      MailType           : Byte;       {1-Poll 2-ReqFiles 3-Transmit Files}
      FileName           : String[50]; {For attached files}
      MsgStat            : Byte;       {1-YetToGo 2-Crash 3-Hold 4-Sent}
      FidoMsg            : Word;
      Kill               : Boolean;
      FileKill           : Byte;       {0-None 1-Trunc 2-Kill}
      IsEvent            : Boolean;
      StartTime          : Longint;
      EndTime            : Longint;
      EventNum           : Word;
      Exclusive          : Boolean;
      Freq               : Boolean;
      END;
TYPE  MMailQueue         = Array[1..MaxMailQueues] Of Mail_Queue;
TYPE  FileListing        = RECORD
      FName              : String[60];
      IsFreq             : Boolean;
      END;
TYPE  LinkedInformation  = RECORD
      Address            : AddrType;
      Sysop              : String[60];
      PhoneNumber        : String[60];
      Location           : String[60];
      BBSName            : String[60];
      SessionPassword    : String[60];
      LinkCodes          : String[60];
      MailerProductCode  : String[60];
      MailerName         : String[60];
      MailerVersion      : String[60];
      MailerSerialNumber : String[60];
      CompatabilityCodes : String[60];
      NodeListFlags      : String[60];
      BaudRate           : String[60];
      CallAddress        : AddrType;
      END;
TYPE  LinkedInformation2 = RECORD
      Akas               : Array[1..100] Of AddrType;
      NumberOfAkas       : Byte;
      Sysop              : String[60];
      PhoneNumber        : String[60];
      Location           : String[60];
      BBSName            : String[60];
      SessionPassword    : String[60];
      LinkCodes          : String[60];
      MailerProductCode  : String[60];
      MailerName         : String[60];
      MailerVersion      : String[60];
      MailerSerialNumber : String[60];
      CompatabilityCodes : String[60];
      NodeListFlags      : String[60];
      BaudRate           : String[60];
      CallAddress        : AddrType;
      END;
VAR   ListFile           : FileListing;
      FListFile          : File Of FileListing;
      FListFile2         : File Of FileListing;
      FilesToSend        : Word;
      CurrentFileNum     : Word;
      YourSystem         : LinkedInformation;
      RemoteSystem       : LinkedInformation2;
      FLastUserOnline    : File Of _LastHuman_Record;
      LastUserOnline     : _LastHuman_Record;
      ConnectRate        : Longint;
      KeepXY             : Word;
      SystemInfo         : _SystemDat_Record;
      Network            : _Network_Record;
      NodeInfo           : _Node_Record;
      SessionPW          : _SessionPW_Record;
      ErrLevel           : _ErrLevel_Record;
      MailerInfo         : _Mailer_Record;
      ExitEvent          : _Exit_Event;
      DropEvent          : _Drop_Event;
      PollEvent          : _Poll_Event;
      SendEvent          : _Send_Event;
      MailEvent          : _Mail_Event;
      FreqEvent          : _Freq_Event;
      PhoneBook          : _PhoneBook_Record;
      CallRouting        : _CallRouting_Record;
      ConfigSetup        : _SGConfig_Record;
      LCallers           : _LastSGMailCalls_Record;
      ExtCodes           : _ExtCodesM_Record;
      Mailer2Info        : _Mailer2_Record;
      FaxCodes           : _FaxCodes_Record;
      ShotgunColours     : _Shotgun_Colours;
      MailHistory        : _Mail_History;
      FunctionKeys       : _Function_Keys;
      FFunctionKeys      : File Of _Function_Keys;
      FMailHistory       : File Of _Mail_History;
      FShotgunColours    : File Of _Shotgun_Colours;
      FFaxCodes          : File Of _FaxCodes_Record;
      FMailer2Info       : File Of _Mailer2_Record;
      FExtCodes          : File Of _ExtCodesM_Record;
      FLCallers          : File Of _LastSGMailCalls_Record;
      FConfigSetup       : File Of _SGConfig_Record;
      FCallRouting       : File Of _CallRouting_Record;
      FPhoneBook         : File Of _PhoneBook_Record;
      FMailEvent         : File Of _Mail_Event;
      FFreqEvent         : File Of _Freq_Event;
      FPollEvent         : File Of _Poll_Event;
      FSendEvent         : File Of _Send_Event;
      FDropEvent         : File Of _Drop_Event;
      FExitEvent         : File Of _Exit_Event;
      FSystemInfo        : File Of _SystemDat_Record;
      FNetwork           : File Of _Network_Record;
      FNodeInfo          : File Of _Node_Record;
      FSessionPW         : File Of _SessionPW_Record;
      FErrLevel          : File Of _ErrLevel_Record;
      FMailerInfo        : File Of _Mailer_Record;
      Shotgun_Directory  : String[80];
      ExitBaud           : String;
      BufferPointer      : Word;
      SimNode            : Word;
      Finished           : Boolean;
      ModemResult        : String;
      MainScreen         : Text;
      Packet             : String;
      HaltCode           : Byte;
      Check_It           : Boolean;
      CallingOut         : Boolean;
      DataChanged        : Boolean;
      MailQueue          : ^MMailQueue;
      MailQueuePointer   : Word;
      NumberOfQueues     : Word;
      TTInput            : AddrType;
      DeviceName         : String;
      DialSave           : Word;
      DialWindowActive   : Boolean;
      ReceivedMail       : Boolean;
      DialTimer          : EventTimer;
      FoundYes           : Boolean;
      InitTimer          : EventTimer;
      InfoTimer          : EventTimer;
      TimerWait          : Word;
      CurrentAka         : Word;
      TheHour            : Word;
      TheMinute          : Word;
      TheSecond          : Word;
      TheMonth           : Word;
      TheDay             : Word;
      TheYear            : Word;
      CfgRescanTime      : Longint;
      MsgRescanTime      : Longint;
      StationId          : String;
      HumanCaller        : Boolean; {If incoming call is a human caller}
      RescanRequired     : Boolean;
      Empty              : Boolean;
      NumMsgs            : Word;
      Current            : Word;
      FidoHeader         : FidoMsgHeader;
      Indexes            : Array[1..3000] Of Word;
      FastBaseHdr        : Message_Header;
      Type2PPacket       : Type2PHeader;
      Type22Packet       : Type22Header;
      Type2Packet        : Type2Header;
      PackMsgHeader      : PakdMessageHeader;
      PKTMsgTo           : Array[1..36] Of Char;
      PKTMsgFrom         : Array[1..36] Of Char;
      PKTMsgSubject      : Array[1..72] Of Char;
      IntlKludge         : String[60];
      MsgIDKludge        : String[60];
      FlagsKludge        : String[60];
      FmPtKludge         : String[30];
      ToPtKludge         : String[30];
      PktName            : String;
      IsItNew            : Boolean;
      SendStatus         : Byte;
      Buffer             : ^BigBuffer;
      LastTime           : String[20];
      DoExitEvent        : Boolean;
      MailOnly           : Boolean;
      FreqsOk            : Boolean;
      ThereAreMsgs       : Boolean;
      ThereAreFaxes      : Boolean;
      GetPut1            : Get_Put1;
      EMSI_DAT           : Array[1..1024] Of Char;
      Their_EMSI_DAT     : Array[1..1024] Of Char;
      Length_EMSI_DAT    : String[4];
      CRC                : String[4];
      ELength            : Word;
      TELength           : Word;
      OurPacket          : Hello_Packet;
      TheirPacket        : Hello_Packet;
      Waiting            : Boolean;
      ActualBaud         : longint;
      ModemBuffer        : Array[1..8192] Of Char;
      InBuffer           : Word;
      LastCursorX        : Byte;
      LastCursorY        : Byte;
      DoingZAP           : Boolean;
      SrcFileName        : String;
      Protocol           : Byte;
      PROTO              : ProtocolRecPtr;
      TransferMode       : TransferModeType;
      Success            : Boolean;
      LastCPS            : Longint;
      LastPercent        : String[60];
      BytesInBuffer      : Word;
      RingCount          : Word;
      FTSCType           : Byte;
      Doing_Receive      : Boolean;
      WeAbort            : Boolean;
      AbortedProtocol    : Boolean;
      EMSIPresentAllAkas : Boolean;
      DoEmsi             : Boolean;
      DoYooHoo           : Boolean;
      DoZap              : Boolean;
      Progress           : String[40];
      FilesActuallySent  : Longint;
      BytesActuallySent  : Longint;
      SessionTimer       : EventTimer;


TYPE  BigFileQueue       = Array[1..15] Of String[100];
TYPE  InfoRec            = RECORD
      Protocol           : Array[1..2] Of Word;
      FileName           : Array[1..2] Of Word;
      Size               : Array[1..2] Of Word;
      Sent               : Array[1..2] Of Word;
      Speed              : Array[1..2] Of Word;
      Time               : Array[1..2] Of Word;
      Left               : Array[1..2] Of Word;
      CPS                : Array[1..2] Of Word;
      END;
VAR   FileQueue          : ^BigFileQueue;
      FilesInQueue       : Byte;
      SaveXYPos          : Word;
      SaveAttr           : Word;
      Offline            : Boolean;
      Timer              : EventTimer;
      OnlineTime         : String[7];
      IsOnline           : Boolean;
      TProtocol          : Byte;
      Info               : InfoRec;
      NumLines           : Word;
      OldLines           : Word;
      Window1            : Byte;
      Window2            : Byte;
      ScreenBytes        : Word;
      ResultType         : Byte;
      FailSafe           : EventTimer;
      SecureSession      : Boolean;
      BGFaxXY            : Word;
      CIDSemaphore       : _CID_Data;
      FCIDSemaphore      : File Of _CID_Data;
      SessionFailure     : Boolean;
      ShesAFreak         : Boolean;
      ViaKludge          : String;
      ExternalApps       : _External_Apps;
      FExternalApps      : File Of _External_Apps;
      HiddenDial         : _Hidden_Dial;
      FHiddenDial        : File Of _Hidden_Dial;
      LastFaxStatus      : Word;
      SwapMethod         : Integer;
      NeedQueueRedraw    : Boolean;
      FNodeIndx          : FFileObj;
      FNodeList          : FFileObj;
      FUserList          : FFileObj;
      NodeListAka        : AddrType;
      NodeListBaud       : Longint;
      NodeListSysop      : String;
      NodeListSystem     : String;
      NodeListPhone      : String;
      NodeListLocation   : String;
      NodeListFlags      : String;
      BytesToSend        : Longint;
      pScan              : Longint;
      pCurrent           : Longint;
      pTotal             : Longint;



IMPLEMENTATION


BEGIN
     NewTimerSecs(InfoTimer,1);
     NewTimerSecs(FailSafe,1);
END.