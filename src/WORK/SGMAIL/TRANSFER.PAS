{$I DEFINES.INC}
UNIT Transfer;


INTERFACE


USES Globals,Shotgun;


PROCEDURE ClearFileQueue;
PROCEDURE ClearOutOutpkts;
PROCEDURE ClearInboundFreqs;
PROCEDURE UnpackInboundPkts;
PROCEDURE SetUpOutgoingTransfer;
FUNCTION  HexSystem(InAddress: AddrType): String;
FUNCTION  HexSystem16(InAddress: AddrType): String;
PROCEDURE AddToQueue(EventType: String; DestinationAddr: AddrType; File_Name: String;
                     FidoMsg: Word; Kill: Boolean; FileKill,MsgStatus: Byte;
                     IsEvent: Boolean; StartTime,EndTime,EventNum: Longint;
                     Exclusive,RedrawQueue,AdjustQueue: Boolean);


IMPLEMENTATION


USES Dos,BsLog,NetMail,EMSI,Misc,ApMisc,Queue,Sema,
     MkFFile,FMode,BsAkas,BsString,BsFile,BsCrc;


{==========================================================================}
{                                                                          }
{ This is the grunt worker. This sets up an outgoing transfer, handling    }
{ any outgoing mail and files.                                             }
{                                                                          }
{==========================================================================}
PROCEDURE SetUpOutgoingTransfer;
VAR  Loop          : Word;
     Loop2         : Word;
     DirInfo       : SearchRec;
     FreqInfo      : SearchRec;
     TFile         : Text;
     TFile2        : Text;
     Temp          : String;
     MagicName     : String;
     UserPassword  : String;
     UserRequest   : String;
     FileSpec      : String;
     RequiredPass  : String;
     GotOne        : Boolean;
     GotExc        : Boolean;
     Before        : Longint;
     Crap          : Word;
     FFile         : FFileObj;
     InboundPath   : String;
     InboundLoop   : Byte;
     TBuf          : Array[1..2048] Of Char;
     AlreadyGotOne : Boolean;
LABEL               GotIt,SorryBud1,SorryBud2;

     FUNCTION NotThere(FName: String): Boolean;
     VAR  BytesRead : Word;
     BEGIN
       IF (FilesToSend<>0) THEN
       BEGIN
         FFile.OpenFile(Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode),SetFileMode);
         REPEAT
           FFile.BlkRead(ListFile,SizeOf(ListFile),BytesRead);
           IF (BytesRead<>0) THEN
           BEGIN
             IF _NoPath(ListFile.FName)=FName THEN
             BEGIN
               FFile.CloseFile;
               NotThere := False;
               Exit;
             END;
           END;
         UNTIL BytesRead=0;
         FFile.CloseFile;
       END;
       NotThere := True;
     END;

     PROCEDURE AddFileToTransfer(FName: String; IsFreq: Boolean);
     BEGIN
       ListFile.FName := FName;
       ListFile.IsFreq := IsFreq;
       ASSIGN(FListFile,Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
       {$I-}RESET(FListFile);{$I+}
       IF IOResult=0 THEN SEEK(FListFile,FileSize(FListFile))
                     ELSE REWRITE(FListFile);
       WRITE(FListFile,ListFile);
       CLOSE(FListFile);
       INC(FilesToSend);
     END;

BEGIN
     FFile.Init(FBuffSize);
     {====================================================}
     { CHECK FOR EXLUSIVE ONLY SENDING                    }
     {====================================================}
     GotExc := False;
     IF CallingOut THEN
     BEGIN
       FOR Loop := 1 TO NumberOfQueues DO
       BEGIN
         IF MailQueue^[Loop].Exclusive THEN
         BEGIN
           FOR Loop2 := 1 TO RemoteSystem.NumberOfAkas DO
           BEGIN
             IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.Akas[Loop2]) THEN
             BEGIN
               GotExc := True;
             END;
           END;
           IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.CallAddress) THEN
           BEGIN
             GotExc := True;
           END;
         END;
       END;
     END;
     FilesToSend    := 0;
     BytesToSend    := 0;
     _EraseFile(Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
     CurrentFileNum := 0;
     {====================================================}
     { DO INBOUND FILE REQUESTS                           }
     {====================================================}
     IF CallingOut THEN
     BEGIN
       ClearInboundFreqs;
     END
     ELSE
     BEGIN
       FOR InboundLoop := 1 TO 2 DO
       BEGIN
         CASE InboundLoop OF
         1:   InboundPath := MailerInfo.Inbound;
         2:   InboundPath := Mailer2Info.InSecureInbound;
         END;
         IF _FileExists(InboundPath+'*.REQ') THEN
         BEGIN
           UpdateFreqs(True);
           bsWriteLog('Processing file request list',False);
           IF ConnectRate<MailerInfo.FreqBaud THEN
           BEGIN
             bsWriteLog('  Baud Rate: '+_String(ConnectRate)+' too slow',False);
             FailedFileRequest(YourSystem.Address,RemoteSystem.Akas[1],_String(ConnectRate),4);
           END
           ELSE IF NOT(MailerInfo.AllowFreqs) THEN
           BEGIN
             bsWriteLog('  File requests not allowed on this system',False);
             IF FreqsOk THEN FailedFileRequest(YourSystem.Address,RemoteSystem.Akas[1],'',2)
                        ELSE FailedFileRequest(YourSystem.Address,RemoteSystem.Akas[1],'',1);
           END
           ELSE
           BEGIN
             FindFirst(InboundPath+'*.REQ',AnyFile-Directory-VolumeID,DirInfo);
             WHILE DosError = 0 DO
             BEGIN
               ASSIGN(TFile,InboundPath+DirInfo.Name);
               RESET(TFile);
               REPEAT
                 READLN(TFile,Temp);
                 GotOne        := False;
                 Temp          := _UpperCase(Temp);
                 UserRequest   := '';
                 UserPassword  := '';
                 AlreadyGotOne := False;
                 Crap := Pos(' !',Temp);
                 IF (Crap<>0) THEN
                 BEGIN
                   UserRequest := _Mid(Temp,1,Crap-1);
                   Delete(Temp,1,Crap+1);
                   UserPassword := Temp;
                 END
                 ELSE UserRequest := Temp;
                 IF (UserPassword='')
                    THEN bsWriteLog('  Request: "'+UserRequest+'"',False)
                    ELSE bsWriteLog('  Request: "'+UserRequest+'"  Password: "'+UserPassword+'"',False);
                 IF (Pos('.',UserRequest)=0) THEN
                 BEGIN
                   {Check Magic Names}
                   ASSIGN(TFile2,MailerInfo.AliasList);
                   SetTextBuf(TFile2,TBuf);
                   {$I-}RESET(TFile2);{$I+}
                   IF IOResult=0 THEN
                   BEGIN
                     REPEAT
                       READLN(TFile2,Temp);
                       Temp := _UpperCase(Temp);
                       IF Pos(';',Temp)=0 THEN
                       BEGIN
                         Crap := Pos(' ',Temp);
                         MagicName    := _Mid(Temp,1,Crap-1);
                         Delete(Temp,1,Crap);
                         Temp := _RemoveLeftSpaces(Temp);
                         RequiredPass := '';
                         Crap := Pos(' ',Temp);
                         IF (Crap<>0) THEN
                         BEGIN
                           FileSpec := _Mid(Temp,1,Crap-1);
                           Delete(Temp,1,Crap);
                           Temp := _RemoveLeftSpaces(Temp);
                           Crap := Pos('!',Temp);
                           IF (Crap=1) THEN Delete(Temp,1,1);
                           RequiredPass := Temp;
                         END
                         ELSE FileSpec := Temp;
                         IF MagicName=UserRequest THEN
                         BEGIN
                           IF (RequiredPass<>'') THEN
                           BEGIN
                             IF (RequiredPass<>UserPassword) THEN
                             BEGIN
                               bsWriteLog('  User password rejected. Expected: "'+
                                          RequiredPass+'"  Got: "'+UserPassword+'"',False);
                               GOTO SorryBud1;
                             END;
                           END;
                           FindFirst(FileSpec,AnyFile-Directory-VolumeID,FreqInfo);
                           WHILE DosError=0 DO
                           BEGIN
                             IF NotThere(FreqInfo.Name) THEN
                             BEGIN
                               INC(BytesToSend,FreqInfo.Size);
                               AddFileToTransfer(_GetFilePath(FileSpec)+FreqInfo.Name,True);
                               bsWriteLog('  Found match: '+_GetFilePath(FileSpec)+FreqInfo.Name,False);
                               GotOne := True;
                             END
                             ELSE AlreadyGotOne := True;
                             FindNext(FreqInfo);
                           END;
                         END;
                       END;
                       SorryBud1:
                     UNTIL EOF(TFile2);
                     CLOSE(TFile2);
                   END;
                 END
                 ELSE
                 BEGIN
                   {Check Dir List}
                   IF NOT(GotOne) THEN
                   BEGIN
                     ASSIGN(TFile2,MailerInfo.DirList);
                     SetTextBuf(TFile2,TBuf);
                     {$I-}RESET(TFile2);{$I+}
                     IF IOResult=0 THEN
                     BEGIN
                       REPEAT
                         READLN(TFile2,Temp);
                         Temp := _UpperCase(Temp);
                         IF Pos(';',Temp)=0 THEN
                         BEGIN
                           RequiredPass := '';
                           Crap := Pos(' ',Temp);
                           IF (Crap<>0) THEN
                           BEGIN
                             FileSpec := _Path(_Mid(Temp,1,Crap-1));
                             Delete(Temp,1,Crap);
                             Temp := _RemoveSpaces(Temp);
                             Crap := Pos('!',Temp);
                             IF (Crap=1) THEN Delete(Temp,1,1);
                             RequiredPass := Temp;
                           END
                           ELSE FileSpec := _Path(Temp);
                           IF (RequiredPass<>'') THEN
                           BEGIN
                             IF (RequiredPass<>UserPassword) THEN
                             BEGIN
                               bsWriteLog('  User password rejected. Expected: "'+
                                          RequiredPass+'"  Got: "'+UserPassword+'"',False);
                               GOTO SorryBud2;
                             END;
                           END;
                           FindFirst(FileSpec+UserRequest,AnyFile-Directory-VolumeID,FreqInfo);
                           WHILE DosError=0 DO
                           BEGIN
                             IF NotThere(FreqInfo.Name) THEN
                             BEGIN
                               INC(BytesToSend,FreqInfo.Size);
                               AddFileToTransfer(FileSpec+FreqInfo.Name,True);
                               bsWriteLog('  Found match: '+FileSpec+FreqInfo.Name,False);
                               GotOne := True;
                             END
                             ELSE AlreadyGotOne := True;
                             FindNext(FreqInfo);
                           END;
                         END;
                         SorryBud2:
                       UNTIL EOF(TFile2);
                       CLOSE(TFile2);
                     END;
                   END;
                 END;
                 {Failed Request}
                 IF NOT(GotOne) THEN
                 BEGIN
                   IF NOT(AlreadyGotOne) THEN
                   BEGIN
                     bsWriteLog('  No matches found',False);
                     FailedFileRequest(YourSystem.Address,RemoteSystem.Akas[1],UserRequest,3);
                   END;
                 END;
               UNTIL EOF(TFile);
               CLOSE(TFile);
               ERASE(TFile);
               FindNext(DirInfo);
             END;
           END;
         END;
         {Kill The Inbound REQ Files}
         FindFirst(InboundPath+'*.REQ',AnyFile-Directory-VolumeID,DirInfo);
         WHILE DosError=0 DO
         BEGIN
           _EraseFile(InboundPath+DirInfo.Name);
           FindNext(DirInfo);
         END;
       END;
     END;
     {Create The Rest Of The File Queue}
     FOR Loop := 1 TO NumberOfQueues DO
     BEGIN
       {If We Are Doing Exc only, skip if not exc}
       IF GotExc THEN
       BEGIN
         IF NOT(MailQueue^[Loop].Exclusive) THEN GOTO GotIt;
       END;
       {Check and make sure it isn't already sent}
       IF MailQueue^[Loop].MsgStat<>Sent THEN
       BEGIN
         FOR Loop2 := 1 TO RemoteSystem.NumberOfAkas DO
         BEGIN
           IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.Akas[Loop2]) THEN
           BEGIN
             {==================================================}
             { FOR REMOTE'S MAIN AKA                            }
             {==================================================}
             CASE MailQueue^[Loop].MailType OF
             1:   ; {Poll - Send NULL File Attach??}
             2:   BEGIN {Request Files}
                    MailQueue^[Loop].FileName := _UpperCase(MailQueue^[Loop].FileName);
                    IF NotThere(_NoPath(MailQueue^[Loop].FileName)) THEN
                    BEGIN
                      INC(BytesToSend,_FileSize(MailQueue^[Loop].FileName));
                      AddFileToTransfer(MailQueue^[Loop].FileName,False);
                    END;
                  END;
             3:   BEGIN {Transmit Files}
                    Before := FilesToSend;
                    MailQueue^[Loop].FileName := _UpperCase(MailQueue^[Loop].FileName);
                    FindFirst(MailQueue^[Loop].FileName,AnyFile-Directory-VolumeID,DirInfo);
                    WHILE DosError = 0 DO
                    BEGIN
                      DirInfo.Name := _UpperCase(DirInfo.Name);
                      IF NotThere(DirInfo.Name) THEN
                      BEGIN
                        INC(BytesToSend,DirInfo.Size);
                        AddFileToTransfer(_GetFilePath(MailQueue^[Loop].FileName)+DirInfo.Name,False);
                      END;
                      FindNext(DirInfo);
                    END;
                    IF Before=FilesToSend THEN bsWriteLog('!!! Missing send file: "'+MailQueue^[Loop].FileName+'"',False);
                  END;
             4:   ; {Null mail attach - for truncating}
             END;
             GOTO GotIt;
           END;
         END;
         IF CallingOut THEN
         BEGIN
           IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.CallAddress) THEN
           BEGIN
             {==================================================}
             { FOR REMOTE'S MAIN AKA                            }
             {==================================================}
             CASE MailQueue^[Loop].MailType OF
             1:   ; {Poll - Send NULL File Attach??}
             2:   BEGIN {Request Files}
                    MailQueue^[Loop].FileName := _UpperCase(MailQueue^[Loop].FileName);
                    IF NotThere(_NoPath(MailQueue^[Loop].FileName)) THEN
                    BEGIN
                      INC(BytesToSend,_FileSize(MailQueue^[Loop].FileName));
                      AddFileToTransfer(MailQueue^[Loop].FileName,False);
                    END;
                  END;
             3:   BEGIN {Transmit Files}
                    Before := FilesToSend;
                    MailQueue^[Loop].FileName := _UpperCase(MailQueue^[Loop].FileName);
                    FindFirst(MailQueue^[Loop].FileName,AnyFile-Directory-VolumeID,DirInfo);
                    WHILE DosError = 0 DO
                    BEGIN
                      DirInfo.Name := _UpperCase(DirInfo.Name);
                      IF NotThere(DirInfo.Name) THEN
                      BEGIN
                        INC(BytesToSend,DirInfo.Size);
                        AddFileToTransfer(_GetFilePath(MailQueue^[Loop].FileName)+DirInfo.Name,False);
                      END;
                      FindNext(DirInfo);
                    END;
                    IF Before=FilesToSend THEN bsWriteLog('!!! Missing send file: "'+MailQueue^[Loop].FileName+'"',False);
                  END;
             4:   ; {Null mail attach - for truncating}
             END;
           END;
         END;
       END;
       GotIt:
     END;
     FFile.Done;
     {Sort PKTs To The Front}
     IF (FilesToSend<>0) THEN
     BEGIN
       _EraseFile(Shotgun_Directory+'\INTRNODE\TMP$$$$.'+_String(SimNode));

       ASSIGN(FListFile,Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
       RENAME(FListFile,Shotgun_Directory+'\INTRNODE\TMP$$$$.'+_String(SimNode));

       ASSIGN(FListFile,Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
       REWRITE(FListFile);
       {Do PKTs}
       ASSIGN(FListFile2,Shotgun_Directory+'\INTRNODE\TMP$$$$.'+_String(SimNode));
       RESET(FListFile2);
       REPEAT
         READ(FListFile2,ListFile);
         IF _UpperCase(_GetFileExtension(ListFile.FName))='PKT' THEN WRITE(FListFile,ListFile);
       UNTIL EOF(FListFile2);
       {Do The Rest}
       RESET(FListFile2);
       REPEAT
         READ(FListFile2,ListFile);
         IF _UpperCase(_GetFileExtension(ListFile.FName))<>'PKT' THEN WRITE(FListFile,ListFile);
       UNTIL EOF(FListFile2);
       CLOSE(FListFile2);
       CLOSE(FListFile);
       ERASE(FListFile2);
     END;
END;
{==========================================================================}
{                                                                          }
{ Clears out the file queue after a session was successful                 }
{                                                                          }
{==========================================================================}
PROCEDURE ClearFileQueue;
VAR  Loop         : Word;
     Loop2        : Word;
     WorkBytes    : Array[1..2] Of Byte;
     FFile        : File;
     BytesRead    : Word;
     yy,mm,dd,dow : Word;
     GotExc       : Boolean;
LABEL               NextOne;
BEGIN
     GotExc := False;
     IF CallingOut THEN
     BEGIN
          FOR Loop := 1 TO NumberOfQueues DO
          BEGIN
               IF MailQueue^[Loop].Exclusive THEN
               BEGIN
                    FOR Loop2 := 1 TO RemoteSystem.NumberOfAkas DO
                    BEGIN
                         IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.Akas[Loop2]) THEN
                         BEGIN
                              GotExc := True;
                         END;
                    END;
                    IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.CallAddress) THEN
                    BEGIN
                         GotExc := True;
                    END;
               END;
          END;
     END;
     FOR Loop := 1 TO NumberOfQueues DO
     BEGIN
          {If We Are Doing Exc only, skip if not exc}
          IF GotExc THEN
          BEGIN
               IF NOT(MailQueue^[Loop].Exclusive) THEN GOTO NextOne;
          END;
          IF (MailQueue^[Loop].MsgStat<>Sent) THEN
          BEGIN
               FOR Loop2 := 1 TO RemoteSystem.NumberOfAkas DO
               BEGIN
                    IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.Akas[Loop2]) THEN
                    BEGIN
                         MailQueue^[Loop].MsgStat := Sent;
                         {Set Date If An Event Poll}
                         IF MailQueue^[Loop].IsEvent THEN
                         BEGIN
                              ASSIGN(FPollEvent,Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode));
                              RESET(FPollEvent);
                              SEEK(FPollEvent,MailQueue^[Loop].EventNum-1);
                              READ(FPollEvent,PollEvent);
                              GetDate(yy,mm,dd,dow);
                              PollEvent.LastYear  := yy;
                              PollEvent.LastMonth := mm;
                              PollEvent.LastDay   := dd;
                              SEEK(FPollEvent,MailQueue^[Loop].EventNum-1);
                              WRITE(FPollEvent,PollEvent);
                              CLOSE(FPollEvent);
                         END;
                         {Trunc/Sent}
                         CASE MailQueue^[Loop].FileKill OF
                         1:   BEGIN {Trunc}
                                   IF (MailQueue^[Loop].MailType<>4) THEN
                                   BEGIN
                                        IF _FileExists(MailQueue^[Loop].FileName) THEN
                                        BEGIN
                                             RescanRequired := True;
                                             bsWriteLog('Truncating sent file: '+MailQueue^[Loop].FileName,False);
                                             _TruncateFile(MailQueue^[Loop].FileName);
                                        END;
                                   END;
                              END;
                         2:   BEGIN {Kill}
                                   IF (MailQueue^[Loop].MailType<>4) THEN
                                   BEGIN
                                        IF _FileExists(MailQueue^[Loop].FileName) THEN
                                        BEGIN
                                             RescanRequired := True;
                                             bsWriteLog('Deleting sent file: '+MailQueue^[Loop].FileName,False);
                                             _EraseFile(MailQueue^[Loop].FileName);
                                        END;
                                   END;
                              END;
                         END;
                         {Sent Flag}
                         IF (MailQueue^[Loop].FidoMsg<>0) THEN
                         BEGIN
                              IF _FileExists(MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG') THEN
                              BEGIN
                                   RescanRequired := True;
                                   {Kill/Msg}
                                   IF MailQueue^[Loop].Kill THEN
                                   BEGIN
                                        _EraseFile(MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG');
                                        bsWriteLog('Killed msg #'+_String(MailQueue^[Loop].FidoMsg),False);
                                   END
                                   ELSE
                                   BEGIN
                                        ASSIGN(FFile,MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG');
                                        RESET(FFile,1);
                                        BLOCKREAD(FFile,FidoHeader,SizeOf(FidoHeader),BytesRead);
                                        Move(FidoHeader.Attribute,WorkBytes[1],2);
                                        WorkBytes[1] := (WorkBytes[1] OR 8);
                                        Move(WorkBytes[1],FidoHeader.Attribute,2);
                                        SEEK(FFile,0);
                                        BLOCKWRITE(FFile,FidoHeader,SizeOf(FidoHeader));
                                        CLOSE(FFile);
                                   END;
                              END;
                         END;
                         GOTO NextOne;
                    END;
               END;
               IF CallingOut THEN
               BEGIN
                    IF AkasMatch(MailQueue^[Loop].DestAddr,RemoteSystem.CallAddress) THEN
                    BEGIN
                         MailQueue^[Loop].MsgStat := Sent;
                         {Set Date If An Event Poll}
                         IF MailQueue^[Loop].IsEvent THEN
                         BEGIN
                              ASSIGN(FPollEvent,Shotgun_Directory+'\DATA\EVENTSP.'+_String(SimNode));
                              RESET(FPollEvent);
                              SEEK(FPollEvent,MailQueue^[Loop].EventNum-1);
                              READ(FPollEvent,PollEvent);
                              GetDate(yy,mm,dd,dow);
                              PollEvent.LastYear  := yy;
                              PollEvent.LastMonth := mm;
                              PollEvent.LastDay   := dd;
                              SEEK(FPollEvent,MailQueue^[Loop].EventNum-1);
                              WRITE(FPollEvent,PollEvent);
                              CLOSE(FPollEvent);
                         END;
                         CASE MailQueue^[Loop].FileKill OF
                         1:   BEGIN {Trunc}
                                   IF _FileExists(MailQueue^[Loop].FileName) THEN
                                   BEGIN
                                        IF (MailQueue^[Loop].MailType<>4) THEN
                                        BEGIN
                                             RescanRequired := True;
                                             bsWriteLog('Truncating sent file: '+MailQueue^[Loop].FileName,False);
                                             _TruncateFile(MailQueue^[Loop].FileName);
                                        END;
                                   END;
                              END;
                         2:   BEGIN {Kill}
                                   IF _FileExists(MailQueue^[Loop].FileName) THEN
                                   BEGIN
                                        IF (MailQueue^[Loop].MailType<>4) THEN
                                        BEGIN
                                             RescanRequired := True;
                                             bsWriteLog('Deleting sent file: '+MailQueue^[Loop].FileName,False);
                                             _EraseFile(MailQueue^[Loop].FileName);
                                        END;
                                   END;
                              END;
                         END;
                         {Sent Flag}
                         IF (MailQueue^[Loop].FidoMsg<>0) THEN
                         BEGIN
                              IF _FileExists(MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG') THEN
                              BEGIN
                                   RescanRequired := True;
                                   {Kill/Msg}
                                   IF MailQueue^[Loop].Kill THEN
                                   BEGIN
                                        _EraseFile(MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG');
                                        bsWriteLog('Killed msg #'+_String(MailQueue^[Loop].FidoMsg),False);
                                   END
                                   ELSE
                                   BEGIN
                                        ASSIGN(FFile,MailerInfo.NetMail+_String(MailQueue^[Loop].FidoMsg)+'.MSG');
                                        RESET(FFile,1);
                                        BLOCKREAD(FFile,FidoHeader,SizeOf(FidoHeader),BytesRead);
                                        Move(FidoHeader.Attribute,WorkBytes[1],2);
                                        WorkBytes[1] := (WorkBytes[1] OR 8);
                                        Move(WorkBytes[1],FidoHeader.Attribute,2);
                                        SEEK(FFile,0);
                                        BLOCKWRITE(FFile,FidoHeader,SizeOf(FidoHeader));
                                        CLOSE(FFile);
                                   END;
                              END;
                         END;
                    END;
               END;
          END;
          NextOne:
     END;
     FilesToSend    := 0;
     CurrentFileNum := 0;
     RescanQueue;
END;
{==========================================================================}
{                                                                          }
{ Makes a hex string representation of a systems address                   }
{                                                                          }
{==========================================================================}
FUNCTION HexSystem(InAddress: AddrType): String;
BEGIN
     HexSystem := StringCrc(AddressToString(InAddress));
END;


FUNCTION HexSystem16(InAddress: AddrType): String;
BEGIN
     HexSystem16 := Word2Hex(InAddress.Net)+Word2Hex(InAddress.Node);
END;
{==========================================================================}
{                                                                          }
{ Adds a mail,poll or freq event to the list.                              }
{                                                                          }
{==========================================================================}
PROCEDURE AddToQueue(EventType: String; DestinationAddr: AddrType; File_Name: String;
                     FidoMsg: Word; Kill: Boolean; FileKill,MsgStatus: Byte;
                     IsEvent: Boolean; StartTime,EndTime,EventNum: Longint;
                     Exclusive,RedrawQueue,AdjustQueue: Boolean);
VAR  Loop : Word;
BEGIN
     IF NumberOfQueues=MaxMailQueues THEN
     BEGIN
          bsWriteLog('SGMail transfer queue full.',False);
          Exit;
     END;
     IF EventType='MAIL' THEN
     BEGIN
          INC(NumberOfQueues);
          IF AdjustQueue THEN MailQueuePointer := NumberOfQueues-1;
          MailQueue^[NumberOfQueues].MailType   := 3;
          MailQueue^[NumberOfQueues].DestAddr   := DestinationAddr;
          MailQueue^[NumberOfQueues].FileName   := File_Name;
          MailQueue^[NumberOfQueues].MsgStat    := MsgStatus;
          MailQueue^[NumberOfQueues].FidoMsg    := FidoMsg;
          MailQueue^[NumberOfQueues].Kill       := Kill;
          MailQueue^[NumberOfQueues].FileKill   := FileKill;
          MailQueue^[NumberOfQueues].IsEvent    := IsEvent;
          MailQueue^[NumberOfQueues].StartTime  := StartTime;
          MailQueue^[NumberOfQueues].EndTime    := EndTime;
          MailQueue^[NumberOfQueues].EventNum   := EventNum;
          MailQueue^[NumberOfQueues].Exclusive  := Exclusive;
          IF RedrawQueue THEN RescanQueue
                         ELSE NeedQueueRedraw := True;
          Exit;
     END
     ELSE IF EventType='NULLMAIL' THEN
     BEGIN
          INC(NumberOfQueues);
          IF AdjustQueue THEN MailQueuePointer := NumberOfQueues-1;
          MailQueue^[NumberOfQueues].MailType   := 4;
          MailQueue^[NumberOfQueues].DestAddr   := DestinationAddr;
          MailQueue^[NumberOfQueues].FileName   := File_Name;
          MailQueue^[NumberOfQueues].MsgStat    := MsgStatus;
          MailQueue^[NumberOfQueues].FidoMsg    := FidoMsg;
          MailQueue^[NumberOfQueues].Kill       := Kill;
          MailQueue^[NumberOfQueues].FileKill   := FileKill;
          MailQueue^[NumberOfQueues].IsEvent    := IsEvent;
          MailQueue^[NumberOfQueues].StartTime  := StartTime;
          MailQueue^[NumberOfQueues].EndTime    := EndTime;
          MailQueue^[NumberOfQueues].EventNum   := EventNum;
          MailQueue^[NumberOfQueues].Exclusive  := Exclusive;
          IF RedrawQueue THEN RescanQueue
                         ELSE NeedQueueRedraw := True;
          Exit;
     END
     ELSE IF EventType='TRANS' THEN
     BEGIN
          INC(NumberOfQueues);
          IF AdjustQueue THEN MailQueuePointer := NumberOfQueues-1;
          MailQueue^[NumberOfQueues].MailType   := 3;
          MailQueue^[NumberOfQueues].DestAddr   := DestinationAddr;
          MailQueue^[NumberOfQueues].FileName   := File_Name;
          MailQueue^[NumberOfQueues].MsgStat    := MsgStatus;
          MailQueue^[NumberOfQueues].FidoMsg    := FidoMsg;
          MailQueue^[NumberOfQueues].Kill       := Kill;
          MailQueue^[NumberOfQueues].FileKill   := FileKill;
          MailQueue^[NumberOfQueues].IsEvent    := IsEvent;
          MailQueue^[NumberOfQueues].StartTime  := StartTime;
          MailQueue^[NumberOfQueues].EndTime    := EndTime;
          MailQueue^[NumberOfQueues].EventNum   := EventNum;
          MailQueue^[NumberOfQueues].Exclusive  := Exclusive;
          IF RedrawQueue THEN RescanQueue
                         ELSE NeedQueueRedraw := True;
          Exit;
     END
     ELSE IF EventType='UNHOLD' THEN
     BEGIN
          FOR Loop := 1 TO NumberOfQueues DO
          BEGIN
               IF MailQueue^[Loop].MsgStat=Hold THEN
               BEGIN
                    IF AkasMatch(MailQueue^[Loop].DestAddr,DestinationAddr) THEN
                    BEGIN
                         MailQueue^[Loop].MsgStat := YetToGo;
                         IF AdjustQueue THEN MailQueuePointer := Loop-1;
                         IF RedrawQueue THEN RescanQueue
                                        ELSE NeedQueueRedraw := True;
                         Exit;
                    END;
               END;
          END;
          Exit;
     END
     ELSE IF EventType='POLL' THEN
     BEGIN
          { SEEK TO MAKE SURE WE DON'T ALREADY HAVE A POLL FOR }
          { THIS SYSTEM - IF WE DO, THEN JUST MAKE THAT QUEUE  }
          { THE CURRENT QUEUE.                                 }
          FOR Loop := 1 TO NumberOfQueues DO
          BEGIN
               IF MailQueue^[Loop].MailType=1 THEN
               BEGIN
                    IF AkasMatch(MailQueue^[Loop].DestAddr,DestinationAddr) THEN
                    BEGIN
                         MailQueue^[Loop].MsgStat := YetToGo;
                         IF AdjustQueue THEN MailQueuePointer := Loop-1;
                         IF RedrawQueue THEN RescanQueue
                                        ELSE NeedQueueRedraw := True;
                         Exit;
                    END;
               END;
          END;
          INC(NumberOfQueues);
          IF AdjustQueue THEN MailQueuePointer := NumberOfQueues-1;
          MailQueue^[NumberOfQueues].MailType   := 1;
          MailQueue^[NumberOfQueues].DestAddr   := DestinationAddr;
          MailQueue^[NumberOfQueues].FileName   := '';
          MailQueue^[NumberOfQueues].MsgStat    := MsgStatus;
          MailQueue^[NumberOfQueues].FidoMsg    := 0;
          MailQueue^[NumberOfQueues].Kill       := False;
          MailQueue^[NumberOfQueues].FileKill   := 0;
          MailQueue^[NumberOfQueues].IsEvent    := IsEvent;
          MailQueue^[NumberOfQueues].StartTime  := StartTime;
          MailQueue^[NumberOfQueues].EndTime    := EndTime;
          MailQueue^[NumberOfQueues].EventNum   := EventNum;
          MailQueue^[NumberOfQueues].Exclusive  := Exclusive;
          IF RedrawQueue THEN RescanQueue
                         ELSE NeedQueueRedraw := True;
          Exit;
     END
     ELSE IF EventType='FREQ' THEN
     BEGIN
          INC(NumberOfQueues);
          IF AdjustQueue THEN MailQueuePointer := NumberOfQueues-1;
          MailQueue^[NumberOfQueues].MailType   := 2;
          MailQueue^[NumberOfQueues].DestAddr   := DestinationAddr;
          MailQueue^[NumberOfQueues].FileName   := MailerInfo.OutPkts+HexSystem16(DestinationAddr)+'.REQ';
          MailQueue^[NumberOfQueues].MsgStat    := MsgStatus;
          MailQueue^[NumberOfQueues].FidoMsg    := FidoMsg;
          MailQueue^[NumberOfQueues].Kill       := Kill;
          MailQueue^[NumberOfQueues].FileKill   := FileKill;
          MailQueue^[NumberOfQueues].IsEvent    := IsEvent;
          MailQueue^[NumberOfQueues].StartTime  := StartTime;
          MailQueue^[NumberOfQueues].EndTime    := EndTime;
          MailQueue^[NumberOfQueues].EventNum   := EventNum;
          MailQueue^[NumberOfQueues].Exclusive  := Exclusive;
          IF RedrawQueue THEN RescanQueue
                         ELSE NeedQueueRedraw := True;
          Exit;
     END;
END;


PROCEDURE UnpackInboundPkts;
VAR  DirInfo   : SearchRec;
BEGIN
     IF Mailer2Info.UnpackPackets THEN
     BEGIN
          FindFirst(MailerInfo.Inbound+'*.PKT',AnyFile-Directory-VolumeID,DirInfo);
          WHILE DosError=0 DO
          BEGIN
               PktToMSG(MailerInfo.InBound+DirInfo.Name);
               RescanRequired := True;
               FindNext(DirInfo);
          END;
     END;
     IF Mailer2Info.UnpackInSecurePkts THEN
     BEGIN
          FindFirst(Mailer2Info.InSecureInbound+'*.PKT',AnyFile-Directory-VolumeID,DirInfo);
          WHILE DosError=0 DO
          BEGIN
               PktToMSG(Mailer2Info.InSecureInBound+DirInfo.Name);
               RescanRequired := True;
               FindNext(DirInfo);
          END;
     END;
END;


PROCEDURE ClearOutOutpkts;
VAR  DirInfo : SearchRec;
BEGIN
     _CreatePath(MailerInfo.Outpkts);
     _CreatePath(MailerInfo.Outpkts+'EXC\');
     FindFirst(MailerInfo.Outpkts+'*.*',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          _EraseFile(MailerInfo.Outpkts+DirInfo.Name);
          FindNext(DirInfo);
     END;
     FindFirst(MailerInfo.Outpkts+'EXC\*.*',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          _EraseFile(MailerInfo.Outpkts+'EXC\'+DirInfo.Name);
          FindNext(DirInfo);
     END;
END;


PROCEDURE ClearInboundFreqs;
VAR  InboundLoop : Word;
     InboundPath : String;
     DirInfo     : SearchRec;
BEGIN
     FOR InboundLoop := 1 TO 2 DO
     BEGIN
       CASE InboundLoop OF
       1:   InboundPath := MailerInfo.Inbound;
       2:   InboundPath := Mailer2Info.InSecureInbound;
       END;
       FindFirst(InboundPath+'*.REQ',AnyFile-Directory-VolumeID,DirInfo);
       WHILE DosError=0 DO
       BEGIN
         _EraseFile(InboundPath+DirInfo.Name);
         bsWriteLog('Ignoring inbound request list',False);
         UpdateFreqs(True);
         FindNext(DirInfo);
       END;
     END;
END;


END.