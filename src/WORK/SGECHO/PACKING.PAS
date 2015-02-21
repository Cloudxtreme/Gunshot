{$I DEFINES.INC}
UNIT Packing;


INTERFACE


PROCEDURE PackOutbound;


IMPLEMENTATION


USES Dos,BsTime,Globals,FMode,Shotgun,Common,KeyCheck,
     BsFile,BsCrc,BsString,BsAkas,BsLog,BsExec,BsFido;


FUNCTION NeedAttachment(FName: String): Boolean;
VAR  Loop : Word;
     Temp : String;
BEGIN
     rFidoStartUpArea(Mailer.NetMail);
     IF rFidoNumberOfMsgs=0 THEN
     BEGIN
       rFidoCloseArea;
       Exit;
     END;
     FName := _UpperCase(FName);
     FOR Loop := 1 TO rFidoNumberOfMsgs DO
     BEGIN
       IF rFidoOpenMessage(Loop) THEN
       BEGIN
         IF rFidoIsFileAttached THEN
         BEGIN
           Temp := _UpperCase(rFidoGetMsgSubject);
           IF (Pos(FName,Temp)<>0) THEN
           BEGIN
             rFidoCloseMessage;
             rFidoCloseArea;
             NeedAttachment := False;
             Exit;
           END;
         END;
         rFidoCloseMessage;
       END;
     END;
     rFidoCloseArea;
     NeedAttachment := True;
END;


PROCEDURE PackOutbound;
CONST Days : Array[0..6]  Of String[3] = ('SU0','MO0','TU0','WE0','TH0','FR0','SA0');
CONST BNum : Array[1..36] Of Char = ('0','1','2','3','4','5','6','7','8','9',
                                     'A','B','C','D','E','F','G','H','I','J',
                                     'K','L','M','N','O','P','Q','R','S','T',
                                     'U','V','W','X','Y','Z');
VAR  DirInfo      : SearchRec;
     CurrentTime  : Longint;
     ScrapTime    : Longint;
     NewName      : String;
     OldName      : String;
     DidIt        : Boolean;
     CommandLine  : String;
     OutArchive   : String;
     OutSize      : Longint;
     Ext          : String[3];
     yy,mm,dd,dow : Word;
     Work         : Char;
     DT           : DateTime;
     FFile        : File;
     Temp         : String;
     LinkCrc      : String;
     BytesRead    : Word;
     LinksInfo    : _Links_Record;
     FArcUtils    : File Of _Archiver_Utilities;
     ArcUtils     : _Archiver_Utilities;

     FUNCTION GetNextOne(InChar: Char): Char;
     VAR  Loop : Byte;
     BEGIN
          InChar := UpCase(InChar);
          FOR Loop := 1 TO 35 DO
          BEGIN
            IF InChar=BNum[Loop] THEN
            BEGIN
              GetNextOne := BNum[Loop+1];
              Exit;
            END;
          END;
          GetNextOne := '0';
     END;

     PROCEDURE CreateFileAttach(AttachedFile: String);
     BEGIN
          wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
          wFidoSetMsgFrom('ARCmail');
          wFidoSetMsgTo(LinksInfo.SysopName);
          wFidoSetMsgSubject(AttachedFile);
          wFidoSetFileAttached(True);
          wFidoSetTruncFile(True);
          wFidoSetDirect(True);
          CASE LinksInfo.NetMailStatus OF
          2:   wFidoSetHoldForPickup(True);
          3:   wFidoSetCrash(True);
          END;
          wFidoSetAkas(NetWorkInfo.Net_Address,LinksInfo.NetWorkAddress);
          wFidoWriteHeader(True);
          wFidoEndMessage;
     END;

BEGIN
     FillChar(ArcUtils,SizeOf(ArcUtils),0);
     CurrentTime := _ProperDate;
     FLinksInfo.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);
     REPEAT
       FLinksInfo.BlkRead(LinksInfo,SizeOf(LinksInfo),BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
         LinkCrc := System_Crc(LinksInfo.NetworkAddress);
         OldName := TempOutbound+'\'+LinkCrc+'.OUT';
         IF _FileExists(OldName) THEN
         BEGIN
           GetNetAddress(LinksInfo.AkaToUse);
           NewName := TempOutbound+'\'+Long2Hex(CurrentTime)+'.PKT';
           INC(CurrentTime);
           _RenameFile(OldName,NewName);
           IF (ArcUtils.Extension<>LinksInfo.Archiver) THEN
           BEGIN
             DidIt := False;
             ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
             RESET(FArcUtils);
             REPEAT
               READ(FArcUtils,ArcUtils);
               IF ArcUtils.Extension=LinksInfo.Archiver THEN DidIt := True;
             UNTIL ((EOF(FArcUtils)) OR (DidIt));
             CLOSE(FArcUtils);
           END
           ELSE DidIt := True;
           IF ((DidIt) AND (NOT(LinksInfo.Paused))) THEN
           BEGIN
             {Check For Existing Bundle}
             OutArchive := Bundle_Crc(NetworkInfo.Net_Address,LinksInfo.NetworkAddress);
             FindFirst(Mailer.Outbound+OutArchive+'.*',Anyfile-Directory-VolumeID,DirInfo);
             IF (DosError<>0) THEN
             BEGIN
               GetDate(yy,mm,dd,dow);
               OutArchive := OutArchive+'.'+Days[dow];
               OutSize    := 0;
             END
             ELSE
             BEGIN
               {Find The Newest One}
               ScrapTime := 0;
               FindFirst(Mailer.Outbound+OutArchive+'.*',Anyfile-Directory-VolumeID,DirInfo);
               WHILE DosError=0 DO
               BEGIN
                 IF DirInfo.Time>=ScrapTime THEN
                 BEGIN
                   OutArchive := DirInfo.Name;
                   ScrapTime  := DirInfo.Time;
                   OutSize    := DirInfo.Size;
                   IF DirInfo.Size=0 THEN _EraseFile(Mailer.Outbound+OutArchive);
                 END;
                 FindNext(DirInfo);
               END;
               IF OutSize=0 THEN
               BEGIN
                 GetDate(yy,mm,dd,dow);
                 Temp := _GetFileExtension(OutArchive);
                 IF (_Mid(Days[dow],1,2)=_Mid(Temp,1,2)) THEN
                 BEGIN
                   Work := OutArchive[LENGTH(OutArchive)];
                   Work := GetNextOne(Work);
                   Ext := _GetFileExtension(OutArchive);
                   Ext := _Mid(Ext,1,2)+Work;
                   OutArchive := _NoExtension(OutArchive)+'.'+Ext;
                 END
                 ELSE
                 BEGIN
                   OutArchive := _NoExtension(OutArchive)+'.'+Days[dow];
                   OutSize    := 0;
                 END;
               END;
             END;
             OutArchive := Mailer.Outbound+OutArchive;
             {Don't Let Bundles Get Larger Than 1024k!}
             IF OutSize>=1024000 THEN
             BEGIN
               Work := OutArchive[LENGTH(OutArchive)];
               Work := GetNextOne(Work);
               Ext := _GetFileExtension(OutArchive);
               Ext := _Mid(Ext,1,2)+Work;
               OutArchive := _NoExtension(OutArchive)+'.'+Ext;
               OutSize    := 0;
             END;
             {Log It}
             WRITE('Adding outbound mail for: '+AddressToString(LinksInfo.NetworkAddress)+
                   ' ('+_String(_FileSize(NewName))+')');
             bsWriteLog('Adding outbound mail for: '+AddressToString(LinksInfo.NetworkAddress)+
                        ' ('+_String(_FileSize(NewName))+')',False);
             {Add The Packet}
             CommandLine := ArcDefs.ArcPath+ArcUtils.CopyArc+' '+OutArchive+' '+NewName+' >NUL';
             {Add The Packets}
             DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwapMethod,TempOutbound);
             IF (OutSize<>0) THEN
             BEGIN
               {Set Original Date}
               ASSIGN(FFile,OutArchive);
               RESET(FFile,1);
               SetFTime(FFile,ScrapTime);
               CLOSE(FFile);
             END;
             {Create Attachment If Needed}
             IF NeedAttachment(OutArchive) THEN
             BEGIN
               WRITELN;
               WRITELN('À[Creating a file attach for: '+AddressToString(LinksInfo.NetworkAddress));
               bsWriteLog('À[Creating a file attach for: '+AddressToString(LinksInfo.NetworkAddress),False);
               CreateFileAttach(OutArchive);
             END
             ELSE WRITELN;
           END;
           _EraseFile(NewName);
         END;
       END;
     UNTIL BytesRead=0;
     FLinksInfo.CloseFile;
END;


END.