{$I DEFINES.INC}
UNIT BaseInfo;


INTERFACE


PROCEDURE JamBase_MessageBaseInfo(FullPath: String);


IMPLEMENTATION


USES Globals,MkOpen,Dos,BsString,BsFile;


{==========================================================================}
{                                                                          }
{ THIS PROCEDURE SHOULD DO:                                                }
{                                                                          }
{      - Get only the current Msg number, number of messages and the       }
{        highest message number in the base.                               }
{                                                                          }
{==========================================================================}
PROCEDURE JamBase_MessageBaseInfo(FullPath: String);
TYPE SqBaseHead = Record
     Len        : Word;
     Rsvd1      : Word;
     NumMsg     : LongInt;
     HighMsg    : LongInt;
     SkipMsg    : LongInt;
     HighWater  : LongInt;
     Uid        : LongInt;
     END;
VAR  Loop       : Word;
     Loop2      : Word;
     AreaType   : Char;
     MaxMsgs    : Word;
     DirInfo    : SearchRec;
     Work       : Word;
     FFile      : File;
     Crap       : Longint;
     BytesRead  : Word;
     TmpSquish  : SqBaseHead;
     SLastRead  : Longint;
     FLastRead  : Word;
BEGIN
     CurrentMessageBase := FullPath;
     TotalMessages      := 0;
     HighMSGNumber      := 0;
     UserLastReadMSG    := 0;
     CASE MessageAreas.Base_Type OF
     1:   BEGIN {Jam}
            AreaType := 'J';
            IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                                      ELSE MaxMsgs := MessageAreas.MaxMsgs;
            IF NOT(OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs)) THEN Exit;
            TotalMessages   := Msg^.NumberOfMsgs;
            HighMSGNumber   := Msg^.GetHighMsgNum;
            UserLastReadMSG := Msg^.GetLastRead(UserRecord.Name,UserRecord.User_Number);
            CloseMsgArea(Msg);
            IF (TotalMessages=0) THEN
            BEGIN
              HighMSGNumber   := 0;
              UserLastReadMSG := 0;
            END;
          END;
     2:   BEGIN {Squish}
            ASSIGN(FFile,CurrentMessageBase+'.SQD');
            {$I-}RESET(FFile,1);{$I+}
            IF IOResult=0 THEN
            BEGIN
              BLOCKREAD(FFile,TmpSquish,SizeOf(TmpSquish),BytesRead);
              CLOSE(FFile);
              HighMSGNumber := TmpSquish.Uid-1;
              TotalMessages := TmpSquish.NumMsg;
              IF (TotalMessages<>0) THEN
              BEGIN
                Crap := ((UserRecord.User_Number+1)*4);
                IF (_FileSize(CurrentMessageBase+'.SQL')>=Crap) THEN
                BEGIN
                  ASSIGN(FFile,CurrentMessageBase+'.SQL');
                  {$I-}
                  RESET(FFile,1);
                  SEEK(FFile,Crap-4);
                  BLOCKREAD(FFile,SLastRead,SizeOf(SLastRead),BytesRead);
                  CLOSE(FFile);
                  {$I+}
                  IF IOResult=0 THEN;
                  UserLastReadMSG := SLastRead;
                END;
              END;
            END;
          END;
     3:   BEGIN {Fido *.MSG}
            FindFirst(CurrentMessageBase+'*.MSG',AnyFile,DirInfo);
            WHILE DosError=0 DO
            BEGIN
              Work := _Numeric(_NoExtension(DirInfo.Name));
              IF Work>HighMSGNumber THEN HighMSGNumber := Work;
              INC(TotalMessages);
              FindNext(DirInfo);
            END;
            IF (TotalMessages<>0) THEN
            BEGIN
              Crap := ((UserRecord.User_Number+1)*2);
              IF (_FileSize(CurrentMessageBase+'LASTREAD')>=Crap) THEN
              BEGIN
                ASSIGN(FFile,CurrentMessageBase+'LASTREAD');
                {$I-}
                RESET(FFile,1);
                SEEK(FFile,Crap-2);
                BLOCKREAD(FFile,FLastRead,SizeOf(FLastRead),BytesRead);
                CLOSE(FFile);
                {$I+}
                IF IOResult=0 THEN;
                UserLastReadMSG := FLastRead;
              END;
            END
            ELSE _CreatePath(CurrentMessageBase);
          END;
     END;
END;


END.