{$I DEFINES.INC}
UNIT Globals;


INTERFACE


USES  Gunshot,Dos,MkFFile,ApTimer;


CONST edSave             : Byte = 1;
      edAbort            : Byte = 2;
      edForward          : Byte = 3;
      edBackward         : Byte = 4;


TYPE  GetPutRecord       = RECORD
      LineLength         : Byte;
      Line               : Array[1..160] Of Byte;
      END;
TYPE  Get_Put1           = RECORD
      NumLines           : Byte;
      Lines              : Array[1..25] Of GetPutRecord;
      END;
TYPE  Editor_Object      = RECORD
      BodyText           : Array[1..48000] Of Char;
      YStart             : Word;
      XStart             : Word;
      UserX              : Word;
      UserY              : Word;
      TopCharNum         : Word;
      Current            : Word;
      Total              : Word;
      OnScreen           : Array[1..25] Of String[88];
      Locators           : Array[1..3000] Of Word;
      TotalLines         : Word;
      IsOnScreen         : Boolean;
      TopLine            : Word;
      CharsOnScrn        : Word;
      LinesOnScrn        : Byte;
      LastPosX           : Word;
      LastPosY           : Word;
      AltKey             : Boolean;
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
TYPE  SaveScrn_2         = Array[1..4000] Of Byte;
TYPE  SaveScrn_3         = Array[1..4000] Of Byte;
TYPE  BigBuffer          = Array[1..48000] Of Char;
VAR   FMailerInfo        : File Of _Mailer_Record;
      FNetwork           : File Of _Network_Record;
      FPhoneBook         : File Of _PhoneBook_Record;
      FSystemInfo        : File Of _SystemDat_Record;
      MailerInfo         : _Mailer_Record;
      Network            : _Network_Record;
      PhoneBook          : _PhoneBook_Record;
      SystemInfo         : _SystemDat_Record;
      SimNode            : Word;
{$IFDEF MSDOS}
      SaveScreen1        : Array[1..4000] Of Byte;
      SaveScreen2        : ^SaveScrn_2;
      SaveScreen3        : ^SaveScrn_3;
{$ENDIF}
      Gunshot_Directory  : String[80];
      NumMsgs            : Word;
      Indexes            : Array[1..3000] Of Word;
      Current            : Word;
      FastBaseHdr        : Message_Header;
      FidoHeader         : FidoMsgHeader;
      Buffer             : ^BigBuffer;
      IntlKludge         : String[60];
      MsgIDKludge        : String[60];
      FlagsKludge        : String[60];
      FmPtKludge         : String[30];
      ToPtKludge         : String[30];
      NumLines           : Word;
      Top                : Word;
      NewMsg             : Boolean;
      TheHour            : Word;
      TheMinute          : Word;
      TheSecond          : Word;
      TheMonth           : Word;
      TheDay             : Word;
      TheYear            : Word;
      MMDDYYYY           : String[10];
      SystemDate         : string[30];
      SystemTime         : string[20];
      EditorObject       : ^Editor_Object;
      GetPut1            : ^Get_Put1;
      CurrentAka         : Word;
      ReplyDomain        : String[60];
      FNodeIndx          : FFileObj;
      FNodeList          : FFileObj;
      FUserList          : FFileObj;
      RescanDateTime     : Longint;
      RescanTimer        : EventTimer;
      ExternalApps       : _External_Apps;
      FExternalApps      : File Of _External_Apps;
      SwapMethod         : Integer;
      NodeIndx           : _NodeIndx_Sg;
      UserList           : _UserList_Sg;
      NodeListAka        : AddrType;
      NodeListBaud       : Longint;
      NodeListSysop      : String;
      NodeListSystem     : String;
      NodeListPhone      : String;
      NodeListLocation   : String;
      NodeListFlags      : String;


IMPLEMENTATION


BEGIN
     NewTimerSecs(RescanTimer,6);
END.