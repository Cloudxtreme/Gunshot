{$I DEFINES.INC}
UNIT AreaFix;


INTERFACE


PROCEDURE ProcessAreaFix;


IMPLEMENTATION


USES LogFile,Globals,BsFile,BsString,Gunshot,MsgWrite,KeyCheck,
     BsAkas,FMode,TicName,BsCrc,Version,Process,BsFido;


PROCEDURE LogAndStat(InString: String);
BEGIN
     WriteLogFile('  @ '+InString);
     WriteLn(StatusFile,' '+InString);
END;


PROCEDURE WriteThisNode;
VAR  LinksInfo2 : _Links_Record;
     Counter    : Longint;
BEGIN
     Counter := 0;
     ASSIGN(FLinksInfo,BaseDirectory+'\DATA\LINKS.DAT');
     RESET(FLinksInfo);
     REPEAT
       READ(FLinksInfo,LinksInfo2);
       INC(Counter);
       IF AkasMatch(LinksInfo2.NetworkAddress,LinksInfo.NetworkAddress) THEN
       BEGIN
         SEEK(FLinksInfo,Counter-1);
         WRITE(FLinksInfo,LinksInfo);
         CLOSE(FLinksInfo);
         Exit;
       END;
     UNTIL EOF(FLinksInfo);
     CLOSE(FLinksInfo);
END;


FUNCTION CanDo(TheSub: Word): Boolean;
VAR  Loop : Word;
BEGIN
     FOR Loop := 1 TO 200 DO
     BEGIN
       IF (LinkGroups.FileGroups[Loop]<>0) THEN
       BEGIN
         IF LinkGroups.FileGroups[Loop]=TheSub THEN
         BEGIN
           CanDo := True;
           Exit;
         END;
       END;
     END;
     CanDo := False;
END;


FUNCTION YouAreConnected(AreaId: Word): Boolean;
VAR  EchoTag   : _GSFileDat_Record;
     BytesRead : Word;
BEGIN
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT') THEN
     BEGIN
       IF BufferedFile.OpenFile(BaseDirectory+'\DATA\GSFILE.DAT',SetFileMode) THEN
       BEGIN
         REPEAT
           BufferedFile.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
           IF (BytesRead<>0) THEN
           BEGIN
             IF (EchoTag.AreaID=AreaId) THEN
             BEGIN
               IF AkasMatch(EchoTag.Aka,LinksInfo.NetworkAddress) THEN
               BEGIN
                 BufferedFile.CloseFile;
                 YouAreConnected := True;
                 Exit;
               END;
             END;
           END;
         UNTIl BytesRead=0;
         BufferedFile.CloseFile;
       END;
     END;
     YouAreConnected := False;
END;


PROCEDURE LinkAllAreas;
VAR  EchoTag  : _GSFileDat_Record;
     FEchoTag : File Of _GSFileDat_Record;
BEGIN
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF ((FileArea.Area_Tag<>'') AND (CanDo(FileArea.Sub))) THEN
       BEGIN
         IF (LinksInfo.AccessLevel>=FileArea.View_Access) THEN
         BEGIN
           IF NOT(YouAreConnected(FileArea.AreaId)) THEN
           BEGIN
             EchoTag.AreaId := FileArea.AreaId;
             EchoTag.Aka    := LinksInfo.NetworkAddress;
             ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
             {$I-}RESET(FEchoTag);{$I+}
             IF (IOResult<>0) THEN REWRITE(FEchoTag);
             SEEK(FEchoTag,FileSize(FEchoTag));
             WRITE(FEchoTag,EchoTag);
             CLOSE(FEchoTag);
           END;
         END;
       END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
END;


PROCEDURE UnlinkAllAreas;
VAR  EchoTag   : _GSFileDat_Record;
     FEchoTag  : File Of _GSFileDat_Record;
     FEchoTag2 : File Of _GSFileDat_Record;
BEGIN
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT') THEN
     BEGIN
       _EraseFile(BaseDirectory+'\DATA\GSFILE.BAK');
       _RenameFile(BaseDirectory+'\DATA\GSFILE.DAT',BaseDirectory+'\DATA\GSFILE.BAK');
       ASSIGN(FEchoTag2,BaseDirectory+'\DATA\GSFILE.BAK');
       ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
       REWRITE(FEchoTag);
       RESET(FEchoTag2);
       REPEAT
         READ(FEchoTag2,EchoTag);
         IF NOT(AkasMatch(EchoTag.Aka,LinksInfo.NetworkAddress)) THEN WRITE(FEchoTag,EchoTag);
       UNTIL EOF(FEchoTag2);
       CLOSE(FEchoTag2);
       ERASE(FEchoTag2);
       CLOSE(FEchoTag);
       IF _FileSize(BaseDirectory+'\DATA\GSFILE.DAT')=0 THEN ERASE(FEchoTag);
     END;
END;


FUNCTION ConnectArea(TheArea: String): Boolean;
VAR  EchoTag  : _GSFileDat_Record;
     FEchoTag : File Of _GSFileDat_Record;
BEGIN
     ConnectArea := True;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF TheArea=FileArea.Area_Tag THEN
       BEGIN
         IF ((FileArea.Area_Tag<>'') AND (CanDo(FileArea.Sub))) THEN
         BEGIN
           IF (LinksInfo.AccessLevel>=FileArea.View_Access) THEN
           BEGIN
             IF YouAreConnected(FileArea.AreaId) THEN
             BEGIN
               LogAndStat(FileArea.Area_Tag+'  is already connected');
               CLOSE(FFileArea);
               Exit;
             END
             ELSE
             BEGIN
               LogAndStat(FileArea.Area_Tag+'  is now connected');
               CLOSE(FFileArea);
               EchoTag.AreaId := FileArea.AreaId;
               EchoTag.Aka    := LinksInfo.NetworkAddress;
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
               {$I-}RESET(FEchoTag);{$I+}
               IF IOResult<>0 THEN REWRITE(FEchoTag);
               SEEK(FEchoTag,FileSize(FEchoTag));
               WRITE(FEchoTag,EchoTag);
               CLOSE(FEchoTag);
               Exit;
             END;
           END;
         END;
         {User Can't See It}
         CLOSE(FFileArea);
         Exit;
       END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     {Area Wasn't Found}
     ConnectArea := False;
END;


PROCEDURE DisconnectArea(TheArea: String);
VAR  EchoTag   : _GSFileDat_Record;
     FEchoTag  : File Of _GSFileDat_Record;
     FEchoTag2 : File Of _GSFileDat_Record;
BEGIN
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF TheArea=FileArea.Area_Tag THEN
       BEGIN
         IF ((FileArea.Area_Tag<>'') AND (CanDo(FileArea.Sub))) THEN
         BEGIN
           IF (LinksInfo.AccessLevel>=FileArea.View_Access) THEN
           BEGIN
             IF YouAreConnected(FileArea.AreaId) THEN
             BEGIN
               CLOSE(FFileArea);
               _EraseFile(BaseDirectory+'\DATA\GSFILE.BAK');
               _RenameFile(BaseDirectory+'\DATA\GSFILE.DAT',BaseDirectory+'\DATA\GSFILE.BAK');
               ASSIGN(FEchoTag2,BaseDirectory+'\DATA\GSFILE.BAK');
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
               REWRITE(FEchoTag);
               RESET(FEchoTag2);
               REPEAT
                 READ(FEchoTag2,EchoTag);
                 IF AkasMatch(EchoTag.Aka,LinksInfo.NetworkAddress) AND (EchoTag.AreaID=FileArea.AreaId)
                    THEN LogAndStat(FileArea.Area_Tag+'  is now disconnected')
                    ELSE WRITE(FEchoTag,EchoTag);
               UNTIL EOF(FEchoTag2);
               CLOSE(FEchoTag2);
               ERASE(FEchoTag2);
               CLOSE(FEchoTag);
               IF _FileSize(BaseDirectory+'\DATA\GSFILE.DAT')=0 THEN ERASE(FEchoTag);
               Exit;
             END
             ELSE
             BEGIN
               LogAndStat(FileArea.Area_Tag+'  is already disconnected');
               CLOSE(FFileArea);
               Exit;
             END;
           END;
         END;
         {User Can't See It}
         CLOSE(FFileArea);
         Exit;
       END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
END;


PROCEDURE Rescan(AreaName: String);
VAR  OutTic : String;
     TFile  : Text;
     Loop   : Word;
BEGIN
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF ((AreaName=FileArea.Area_Tag) OR (AreaName='*')) THEN
       BEGIN
         IF ((NOT FileArea.PassThrough) AND (FileArea.Area_Tag<>'') AND (YouAreConnected(FileArea.AreaId))) THEN
         BEGIN
           ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
           {$I-}RESET(FFileDefs);{$I+}
           IF IOResult=0 THEN
           BEGIN
             ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
             RESET(FFileDesc);
             REPEAT
               READ(FFileDefs,FileDefs);
               OutTic := GetNextFileName;
               ASSIGN(TFile,OutTic);
               REWRITE(TFile);
               WRITELN(TFile,'Area '+FileArea.Area_Tag);
               WRITELN(TFile,'Areadesc '+FileArea.Area_Name);
               WRITELN(TFile,'Origin '+AddressToString(NetworkInfo.Net_Address));
               WRITELN(TFile,'From '+AddressToString(NetworkInfo.Net_Address));
               WRITELN(TFile,'File '+FileDefs.File_Name);
               READ(FFileDesc,FileDesc);
               WRITELN(TFile,'Desc '+FileDesc.Desc);
               IF (FileDefs.Desc_Lines>1) THEN
               BEGIN
                 WRITELN(TFile,'Ldesc '+FileDesc.Desc);
                 FOR Loop := 2 TO FileDefs.Desc_Lines DO
                 BEGIN
                   READ(FFileDesc,FileDesc);
                   WRITELN(TFile,'Ldesc '+FileDesc.Desc);
                 END;
               END;
               WRITELN(TFile,'Crc '+FileCrc32(FileArea.Area_Path+FileDefs.File_Name));
               WRITELN(TFile,'Created by '+OurAppName+' '+GunshotCopyright);
               WRITELN(TFile,'Path '+AddressToString(NetworkInfo.Net_Address)+PathTime);
               WRITELN(TFile,'Seenby '+AddressToString(NetworkInfo.Net_Address));
               WRITELN(TFile,'Seenby '+AddressToString(LinksInfo.NetworkAddress));
               WRITELN(TFile,'Pw '+LinksInfo.GSFileTIC);
               CLOSE(TFile);
               CreateAttachment(FileArea.Area_Path+FileDefs.File_Name,OutTic);
               WriteLogFile('  > Added TIC for node '+AddressToString(LinksInfo.NetworkAddress)+
                            '  File: '+FileArea.Area_Path+FileDefs.File_Name);
               INC(RunningOutTics);
             UNTIL EOF(FFileDefs);
             CLOSE(FFileDefs);
             CLOSE(FFileDesc);
           END;
         END;
       END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
END;


PROCEDURE ProcessAreaFix;
VAR  Loop       : Word;
     Temp       : String;
     Orig       : AddrType;
     Dest       : AddrType;
     More       : Boolean;
     DidIt      : Boolean;
     FidoMsgNum : Word;

     PROCEDURE StartMessage(Subject: String);
     BEGIN
          wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
          wFidoSetMsgFrom(OurAppName);
          wFidoSetMsgTo(LinksInfo.SysopName);
          wFidoSetMsgSubject(Subject);
          wFidoSetAkas(Dest,Orig);
          CASE LinksInfo.NetMailStatus OF
          2:   wFidoSetHoldForPickup(True);
          3:   wFidoSetCrash(True);
          END;
          IF KeepAFix THEN wFidoSetKillSent(False);
          wFidoSetDirect(True);
          wFidoWriteHeader(True);
          wFidoWriteString('');
     END;

     PROCEDURE EndMessage;
     BEGIN
          wFidoWriteString('');
          wFidoWriteString('--- '+OurAppName);
          wFidoEndMessage;
     END;

     PROCEDURE SendHelp;
     VAR  TFile : Text;
          Crap  : String;
     BEGIN
          IF _FileExists(BaseDirectory+'\HELP\GSFILE.HLP') THEN
          BEGIN
            StartMessage('GSFile help');
            ASSIGN(TFile,BaseDirectory+'\HELP\GSFILE.HLP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
            UNTIL EOF(TFile);
            CLOSE(TFile);
            EndMessage;
          END
          ELSE WriteLogFile('  ! Areafix help file \GUNSHOT\HELP\GSFILE.HLP not found.');
     END;

     PROCEDURE SendStatusMsg;
     VAR  TFile  : Text;
          Crap   : String;
          LCount : Longint;
          MCount : Longint;
     BEGIN
          LCount := 0;
          MCount := 1;
          StartMessage('Return receipt ['+_String(MCount)+']');
          ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.$$$');
          RESET(TFile);
          REPEAT
            READLN(TFile,Crap);
            wFidoWriteString(Crap);
            INC(LCount);
            IF ((LCount=400) AND (NOT(EOF(TFile)))) THEN
            BEGIN
              EndMessage;
              LCount := 0;
              INC(MCount);
              StartMessage('Return receipt ['+_String(MCount)+']');
            END;
          UNTIL EOF(TFile);
          CLOSE(TFile);
          EndMessage;
     END;

     PROCEDURE ListAllAreas;
     VAR  Counter  : Longint;
          MCounter : Longint;
          Crap     : String;
          TFile    : Text;
     BEGIN
          ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          REPEAT
            READ(FFileArea,FileArea);
            IF ((FileArea.Area_Tag<>'') AND (CanDo(FileArea.Sub))) THEN
            BEGIN
              IF (LinksInfo.AccessLevel>=FileArea.View_Access) THEN
              BEGIN
                IF YouAreConnected(FileArea.AreaId)
                   THEN Crap := '+ '+_PadRight(FileArea.Area_Tag,15)+FileArea.Area_Name
                   ELSE Crap := '  '+_PadRight(FileArea.Area_Tag,15)+FileArea.Area_Name;
                WRITELN(TFile,_Mid(Crap,1,78));
              END;
            END;
          UNTIL EOF(FFileArea);
          CLOSE(FFileArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All file echoes available on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all available file echoes:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(BaseDirectory+'\!21\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString('   + You are connected (linked) to that file echo');
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('File echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All file echoes available on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all available file echoes:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString('   + You are connected (linked) to that file echo');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('File echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(BaseDirectory+'\!21\AREAFIX.TMP');
     END;

     PROCEDURE ListAllLinkedAreas;
     VAR  Counter  : Longint;
          MCounter : Longint;
          Crap     : String;
          TFile    : Text;
     BEGIN
          ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          REPEAT
            READ(FFileArea,FileArea);
            IF (FileArea.Area_Tag<>'') THEN
            BEGIN
              IF YouAreConnected(FileArea.AreaId) THEN
              BEGIN
                Crap := ' '+_PadRight(FileArea.Area_Tag,15)+FileArea.Area_Name;
                WRITELN(TFile,_Mid(Crap,1,78));
              END;
            END;
          UNTIL EOF(FFileArea);
          CLOSE(FFileArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All file echoes linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all your connected file echoes:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(BaseDirectory+'\!21\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('File echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All file echoes linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all your connected file echoes:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('File echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(BaseDirectory+'\!21\AREAFIX.TMP');
     END;

     PROCEDURE ListAllUnlinkedAreas;
     VAR  Counter  : Longint;
          MCounter : Longint;
          Crap     : String;
          TFile    : Text;
     BEGIN
          ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          REPEAT
            READ(FFileArea,FileArea);
            IF ((FileArea.Area_Tag<>'') AND (CanDo(FileArea.Sub))) THEN
            BEGIN
              IF (LinksInfo.AccessLevel>=FileArea.View_Access) THEN
              BEGIN
                IF NOT(YouAreConnected(FileArea.AreaId)) THEN
                BEGIN
                  Crap := ' '+_PadRight(FileArea.Area_Tag,15)+FileArea.Area_Name;
                  WRITELN(TFile,_Mid(Crap,1,78));
                END;
              END;
            END;
          UNTIL EOF(FFileArea);
          CLOSE(FFileArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All file echoes unlinked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all your unlinked file echoes:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(BaseDirectory+'\!21\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,BaseDirectory+'\!21\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('File echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All file echoes unlinked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all your unlinked file echoes:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('File echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(BaseDirectory+'\!21\AREAFIX.TMP');
     END;

BEGIN
     IF DoNotify THEN
     BEGIN
       WriteLogFile('Processing -NOTIFY');
       BufferedFile.Init(32768);
       ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
       ASSIGN(FLinksInfo,BaseDirectory+'\DATA\LINKS.DAT');
       RESET(FLinkGroups);
       RESET(FLinksInfo);
       REPEAT
         READ(FLinksInfo,LinksInfo);
         READ(FLinkGroups,LinkGroups);
         IF LinksInfo.SendNotify THEN
         BEGIN
           GetNetAddress(LinksInfo.AkaToUse);
           Orig := LinksInfo.NetworkAddress;
           Dest := NetworkInfo.Net_Address;
           WriteLogFile('  ? Sending basic setup information to '+AddressToString(LinksInfo.NetworkAddress));
           StartMessage('Current GSFile setup.');
           wFidoWriteString('Please check your setup to make sure these settings are correct:');
           wFidoWriteString('');
           wFidoWriteString('  Sysop Name.........:  '+LinksInfo.SysopName);
           wFidoWriteString('  Network Address....:  '+AddressToString(LinksInfo.NetworkAddress));
           wFidoWriteString('  TIC File Password..:  '+LinksInfo.GSFileTIC);
           wFidoWriteString('  Areafix Password...:  '+LinksInfo.GSFileAreaFix);
           CASE LinksInfo.NetmailStatus OF
           1:   wFidoWriteString('  Netmail Status.....:  None');
           2:   wFidoWriteString('  Netmail Status.....:  Hold');
           3:   wFidoWriteString('  Netmail Status.....:  Crash');
           END;
           IF LinksInfo.AreaCreate
              THEN wFidoWriteString('  Auto Area Create...:  Yes')
              ELSE wFidoWriteString('  Auto Area Create...:  No');
           IF LinksInfo.Paused
              THEN wFidoWriteString('  System Paused......:  Yes')
              ELSE wFidoWriteString('  System Paused......:  No');
           EndMessage;
           WriteLogFile('  ? %QUERY - Sending list of all linked areas to '+AddressToString(LinksInfo.NetworkAddress));
           ListAllLinkedAreas;
           WriteLogFile('  ? %HELP - Sending GSFILE.HLP to '+AddressToString(LinksInfo.NetworkAddress));
           SendHelp;
         END;
       UNTIL EOF(FLinksInfo);
       CLOSE(FLinkGroups);
       CLOSE(FLinksInfo);
       BufferedFile.Done;
     END;
     rFidoStartUpArea(Mailer.NetMail);
     IF rFidoNumberOfMsgs=0 THEN
     BEGIN
       rFidoCloseArea;
       Exit;
     END;
     BufferedFile.Init(32768);
     FOR Loop := 1 TO rFidoNumberOfMsgs DO
     BEGIN
       IF rFidoOpenMessage(Loop) THEN
       BEGIN
         FidoMsgNum := rFidoGetMsgNumber;
         DidIt      := False;
         Temp       := _UpperCase(rFidoGetMsgTo);
         IF ((Temp='GSFILE') OR (Temp='RAID')) THEN
         BEGIN
           IF ((NOT rFidoIsReceived) AND (NOT rFidoIsLocal)) THEN
           BEGIN
             rFidoGetAkas(Orig,Dest);
             IF ((IsOurNode(Dest)) AND (LoadTheLink(Orig,False))) THEN
             BEGIN
               GetNetAddress(LinksInfo.AkaToUse);
               Dest := NetworkInfo.Net_Address;
               INC(RunningAFix);
               ASSIGN(StatusFile,BaseDirectory+'\!21\AREAFIX.$$$');
               REWRITE(StatusFile);
               WriteLogFile('Areafix message.: #'+_String(FidoMsgNum)+' from '+AddressToString(LinksInfo.NetworkAddress));
               Temp := _RemoveSpaces(_UpperCase(rFidoGetMsgSubject));
               IF Temp=LinksInfo.GSFileAreaFix THEN
               BEGIN
                 REPEAT
                   More := rFidoGetString(Temp);
                   IF More THEN
                   BEGIN
                     Temp := _RemoveSpaces(_UpperCase(Temp));
                     IF (Temp<>'') THEN
                     BEGIN
                       IF Temp='%PAUSE' THEN
                       BEGIN
                         IF LinksInfo.AllowPause THEN
                         BEGIN
                           LogAndStat('%PAUSE - '+AddressToString(Orig)+' packing paused.');
                           LinksInfo.Paused := True;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%PAUSE - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%RESUME' THEN
                       BEGIN
                         IF LinksInfo.AllowResume THEN
                         BEGIN
                           LogAndStat('%RESUME - '+AddressToString(Orig)+' packing resumed.');
                           LinksInfo.Paused := False;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%RESUME - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF _Mid(Temp,1,9)='%PASSWORD' THEN
                       BEGIN
                         Delete(Temp,1,9);
                         IF LinksInfo.AllowPassword THEN
                         BEGIN
                           LogAndStat('%PASSWORD - '+AddressToString(Orig)+' password changed to "'+Temp+'".');
                           LinksInfo.GSFileTic     := Temp;
                           LinksInfo.GSFileAreaFix := Temp;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%PASSWORD - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%HELP' THEN
                       BEGIN
                         IF LinksInfo.AllowHelp THEN
                         BEGIN
                           LogAndStat('%HELP - Sending GSFILE.HLP to '+AddressToString(Orig));
                           SendHelp;
                         END
                         ELSE LogAndStat('%HELP - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%LIST' THEN
                       BEGIN
                         IF LinksInfo.AllowList THEN
                         BEGIN
                           LogAndStat('%LIST - Sending list of all available areas to '+AddressToString(Orig));
                           ListAllAreas;
                         END
                         ELSE LogAndStat('%LIST - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%QUERY' THEN
                       BEGIN
                         IF LinksInfo.AllowQuery THEN
                         BEGIN
                           LogAndStat('%QUERY - Sending list of all linked areas to '+AddressToString(Orig));
                           ListAllLinkedAreas;
                         END
                         ELSE LogAndStat('%QUERY - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%UNLINKED' THEN
                       BEGIN
                         IF LinksInfo.AllowUnlinked THEN
                         BEGIN
                           LogAndStat('%UNLINKED - Sending list of all unlinked areas to '+AddressToString(Orig));
                           ListAllUnlinkedAreas;
                         END
                         ELSE LogAndStat('%UNLINKED - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='+*' THEN
                       BEGIN
                         LogAndStat('+* - Connecting all areas for '+AddressToString(Orig));
                         LinkAllAreas;
                       END
                       ELSE IF Temp='-*' THEN
                       BEGIN
                         LogAndStat('-* - Disconnecting all areas for '+AddressToString(Orig));
                         UnlinkAllAreas;
                       END
                       ELSE IF Temp[1]='+' THEN
                       BEGIN
                         Delete(Temp,1,1);
                         IF NOT(ConnectArea(Temp)) THEN
                         BEGIN
                           IF LoadSub(LinkGroups.CreateFileGroup) THEN
                           BEGIN
                             IF FileSubs.AutoRequests THEN
                             BEGIN
                               IF LoadTheLink(FileSubs.Uplink,False) THEN
                               BEGIN
                                 GetNetAddress(LinksInfo.AkaToUse);
                                 LogAndStat('Area: '+Temp+' has been requested from upstream host.');
                                 wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
                                 wFidoSetMsgFrom(OurAppName);
                                 wFidoSetMsgTo(FileSubs.AreaManager);
                                 wFidoSetMsgSubject(_UpperCase(FileSubs.YourPassword));
                                 wFidoSetAkas(NetworkInfo.Net_Address,LinksInfo.NetworkAddress);
                                 CASE LinksInfo.NetMailStatus OF
                                 2:   wFidoSetHoldForPickup(True);
                                 3:   wFidoSetCrash(True);
                                 END;
                                 IF KeepAFix THEN wFidoSetKillSent(False);
                                 wFidoSetDirect(True);
                                 wFidoWriteHeader(True);
                                 wFidoWriteString('+'+Temp);
                                 wFidoEndMessage;
                               END;
                               LoadTheLink(Orig,False);
                               GetNetAddress(LinksInfo.AkaToUse);
                             END;
                           END;
                         END;
                       END
                       ELSE IF Temp[1]='-' THEN
                       BEGIN
                         Delete(Temp,1,1);
                         DisconnectArea(Temp);
                       END
                       ELSE IF _Mid(Temp,1,7)='%RESCAN' THEN
                       BEGIN
                         Delete(Temp,1,7);
                         IF LinksInfo.AllowRescan THEN
                         BEGIN
                           IF (Temp<>'') THEN
                           BEGIN
                             LogAndStat('%RESCAN - Rescanning '+Temp+' for '+AddressToString(Orig));
                             Rescan(Temp);
                           END
                           ELSE LogAndStat('%RESCAN - Missing parameter!');
                         END
                         ELSE LogAndStat('%RESCAN - Not allowed by '+AddressToString(Orig));
                       END;
                     END;
                   END;
                 UNTIL NOT(More);
               END
               ELSE
               BEGIN
                 LogAndStat('Areafix password from '+AddressToString(Orig)+' is incorrect.');
                 WriteLogFile('  ! Areafix password from '+AddressToString(Orig)+' is incorrect.');
                 WriteLogFile('  ! Expected: "'+LinksInfo.GSFileAreaFix+'"  Received: "'+Temp+'".');
               END;
               CLOSE(StatusFile);
               IF (_FileSize(BaseDirectory+'\!21\AREAFIX.$$$')<>0) THEN SendStatusMsg;
               ERASE(StatusFile);
               DidIt := True;
             END
             ELSE
             BEGIN
               IF IsOurNode(Dest)
                 THEN WriteLogFile('! Areafix from unknown system - '+AddressToString(Orig)+'.')
                 ELSE WriteLogFile('! Areafix not for our system - '+AddressToString(Dest)+'.');
             END;
           END;
         END;
         rFidoCloseMessage;
         IF DidIt THEN
         BEGIN
           IF eFidoStartUpMessage(Mailer.NetMail,FidoMsgNum) THEN
           BEGIN
             IF KeepAFix THEN
             BEGIN
               eFidoSetReceived(True);
               eFidoCloseMessage;
             END
             ELSE eFidoKillMessage;
           END;
         END;
       END;
     END;
     rFidoCloseArea;
     BufferedFile.Done;
END;


END.
