{$I DEFINES.INC}
UNIT AreaFix;


INTERFACE


PROCEDURE ProcessAreaFix;


IMPLEMENTATION


USES MkFFile,Shotgun,Globals,BsLog,Common,BsFido,
     BsString,BsAkas,KeyCheck,BsFile,FMode,_EchoTag;


PROCEDURE LogAndStat(InString: String);
BEGIN
     WriteLogFile(InString);
     WriteLn(StatusFile,' '+InString);
END;


PROCEDURE WriteThisNode;
VAR  LinksInfo2  : _Links_Record;
     FLinksInfo2 : File Of _Links_Record;
     Counter     : Longint;
BEGIN
     Counter := 0;
     ASSIGN(FLinksInfo2,BaseDirectory+'\DATA\LINKS.DAT');
     RESET(FLinksInfo2);
     REPEAT
       READ(FLinksInfo2,LinksInfo2);
       INC(Counter);
       IF AkasMatch(LinksInfo2.NetworkAddress,DownLink.NetworkAddress) THEN
       BEGIN
         SEEK(FLinksInfo2,Counter-1);
         WRITE(FLinksInfo2,DownLink);
         CLOSE(FLinksInfo2);
         Exit;
       END;
     UNTIL EOF(FLinksInfo2);
     CLOSE(FLinksInfo2);
END;


FUNCTION YouAreConnected(InAddress: AddrType; AreaId: Word): Boolean;
VAR  EchoTag   : _SGEchoDat_Record;
     BytesRead : Word;
BEGIN
     OpenSGEchoDat;
     IF IsEchoTagFileOpen THEN
     BEGIN
       REPEAT
         FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF (EchoTag.AreaID=AreaId) THEN
           BEGIN
             IF AkasMatch(EchoTag.Aka,InAddress) THEN
             BEGIN
               YouAreConnected := True;
               Exit;
             END;
           END;
         END;
       UNTIL BytesRead=0;
     END;
     YouAreConnected := False;
END;


FUNCTION CanDo(TheSub: Word): Boolean;
VAR  Loop : Word;
BEGIN
     FOR Loop := 1 TO 200 DO
     BEGIN
       IF DownLinkGroups.MessageGroups[Loop]<>0 THEN
       BEGIN
         IF DownLinkGroups.MessageGroups[Loop]=TheSub THEN
         BEGIN
           CanDo := True;
           Exit;
         END;
       END;
     END;
     CanDo := False;
END;


FUNCTION ConnectArea(TheArea: String): Boolean;
VAR  EchoTag      : _SGEchoDat_Record;
     FFEchoTag    : File Of _SGEchoDat_Record;
     MessageArea  : _MessageArea_Record;
     FMessageArea : File Of _MessageArea_Record;
BEGIN
     ConnectArea := True;
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
       READ(FMessageArea,MessageArea);
       IF TheArea=MessageArea.Area_Tag THEN
       BEGIN
         IF ((DownLink.AccessLevel>=MessageArea.Read_Access) AND (CanDo(MessageArea.Sub))) THEN
         BEGIN
           IF YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId) THEN
           BEGIN
             LogAndStat(MessageArea.Area_Tag+'  is already connected');
             CLOSE(FMessageArea);
             Exit;
           END
           ELSE
           BEGIN
             LogAndStat(MessageArea.Area_Tag+'  is now connected');
             CLOSE(FMessageArea);
             EchoTag.AreaId := MessageArea.AreaId;
             EchoTag.Aka    := DownLink.NetworkAddress;
             CloseSGEchoDat;
             ASSIGN(FFEchoTag,BaseDirectory+'\DATA\SGECHO.DAT');
             {$I-}RESET(FFEchoTag);{$I+}
             IF (IOResult<>0) THEN REWRITE(FFEchoTag);
             SEEK(FFEchoTag,FileSize(FFEchoTag));
             WRITE(FFEchoTag,EchoTag);
             CLOSE(FFEchoTag);
             OpenSGEchoDat;
             Exit;
           END;
         END;
         {User Can't See It}
         CLOSE(FMessageArea);
         Exit;
       END;
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     {Area Wasn't Found}
     ConnectArea := False;
END;


PROCEDURE DisconnectArea(TheArea: String);
VAR  EchoTag      : _SGEchoDat_Record;
     FFEchoTag    : File Of _SGEchoDat_Record;
     FFEchoTag2   : File Of _SGEchoDat_Record;
     MessageArea  : _MessageArea_Record;
     FMessageArea : File Of _MessageArea_Record;
BEGIN
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
       READ(FMessageArea,MessageArea);
       IF TheArea=MessageArea.Area_Tag THEN
       BEGIN
         IF ((DownLink.AccessLevel>=MessageArea.Read_Access) AND (CanDo(MessageArea.Sub))) THEN
         BEGIN
           IF YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId) THEN
           BEGIN
             CLOSE(FMessageArea);
             CloseSGEchoDat;
             _EraseFile(BaseDirectory+'\DATA\SGECHO.BAK');
             _RenameFile(BaseDirectory+'\DATA\SGECHO.DAT',BaseDirectory+'\DATA\SGECHO.BAK');
             ASSIGN(FFEchoTag2,BaseDirectory+'\DATA\SGECHO.BAK');
             ASSIGN(FFEchoTag,BaseDirectory+'\DATA\SGECHO.DAT');
             REWRITE(FFEchoTag);
             RESET(FFEchoTag2);
             REPEAT
               READ(FFEchoTag2,EchoTag);
               IF AkasMatch(EchoTag.Aka,DownLink.NetworkAddress) AND (EchoTag.AreaID=MessageArea.AreaId)
                  THEN LogAndStat(MessageArea.Area_Tag+'  is now disconnected')
                  ELSE WRITE(FFEchoTag,EchoTag);
             UNTIL EOF(FFEchoTag2);
             CLOSE(FFEchoTag2);
             ERASE(FFEchoTag2);
             CLOSE(FFEchoTag);
             IF _FileSize(BaseDirectory+'\DATA\SGECHO.DAT')=0 THEN ERASE(FFEchoTag);
             OpenSGEchoDat;
             Exit;
           END
           ELSE
           BEGIN
             LogAndStat(MessageArea.Area_Tag+'  is already disconnected');
             CLOSE(FMessageArea);
             Exit;
           END;
         END;
         {User Can't See It}
         CLOSE(FMessageArea);
         Exit;
       END;
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
END;


PROCEDURE ProcessAreaFix;
VAR  Loop         : Word;
     Temp         : String;
     Orig         : AddrType;
     Dest         : AddrType;
     More         : Boolean;
     DidIt        : Boolean;
     FidoMsgNum   : Word;
     BytesRead    : Word;

     PROCEDURE StartMessage(Subject: String);
     BEGIN
          wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
          wFidoSetMsgFrom(OurAppName);
          wFidoSetMsgTo(DownLink.SysopName);
          wFidoSetMsgSubject(Subject);
          wFidoSetAkas(Dest,Orig);
          CASE DownLink.NetMailStatus OF
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

     PROCEDURE SendStatusMsg;
     VAR  TFile  : Text;
          Crap   : String;
          LCount : Longint;
          MCount : Longint;
     BEGIN
          LCount := 0;
          MCount := 1;
          StartMessage('Return receipt ['+_String(MCount)+']');
          ASSIGN(TFile,TempOutbound+'\AREAFIX.$$$');
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

     PROCEDURE SendHelp;
     VAR  TFile : Text;
          Crap  : String;
     BEGIN
          IF _FileExists(BaseDirectory+'\HELP\SGECHO.HLP') THEN
          BEGIN
            StartMessage('SGEcho help');
            ASSIGN(TFile,BaseDirectory+'\HELP\SGECHO.HLP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
            UNTIL EOF(TFile);
            CLOSE(TFile);
            EndMessage;
          END
          ELSE WriteLogFile('! Areafix help file \SHOTGUN\HELP\SGECHO.HLP not found.');
     END;

     PROCEDURE ChangeCompress(NewComp: String);
     VAR  WeGotIt   : Boolean;
          Crap      : Longint;
          ArcUtils  : _Archiver_Utilities;
          FArcUtils : File Of _Archiver_Utilities;
     BEGIN
          NewComp := _UpperCase(NewComp);
          WeGotIt := False;
          ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
          RESET(FArcUtils);
          REPEAT
            READ(FArcUtils,ArcUtils);
            IF ArcUtils.Extension=NewComp THEN WeGotIt := True;
          UNTIL ((EOF(FArcUtils)) OR (WeGotIt));
          CLOSE(FArcUtils);
          IF WeGotIt THEN
          BEGIN
            DownLink.Archiver := NewComp;
            WriteThisNode;
            LogAndStat('Node '+AddressToString(Orig)+' compressor changed to "'+NewComp+'".');
          END
          ELSE LogAndStat('Compressor: '+Temp+' is not available on this system.');
     END;

     PROCEDURE ListAllLinkedAreas;
     VAR  Counter      : Longint;
          MCounter     : Longint;
          Crap         : String;
          TFile        : Text;
          MessageArea  : _MessageArea_Record;
          FMessageArea : File Of _MessageArea_Record;
     BEGIN
          ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
            READ(FMessageArea,MessageArea);
            IF (MessageArea.Area_Tag<>'') THEN
            BEGIN
              IF YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId) THEN
              BEGIN
                Crap := _PadRight(MessageArea.Area_Tag,41)+MessageArea.Area_Name;
                WRITELN(TFile,_Mid(Crap,1,78));
              END;
            END;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All mail echoes linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all your connected mail echoes:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(TempOutbound+'\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('Mail echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All mail echoes linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all your connected mail echoes:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('Mail echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(TempOutbound+'\AREAFIX.TMP');
     END;

     PROCEDURE ListAllUnlinkedAreas;
     VAR  Counter      : Longint;
          MCounter     : Longint;
          Crap         : String;
          TFile        : Text;
          MessageArea  : _MessageArea_Record;
          FMessageArea : File Of _MessageArea_Record;
     BEGIN
          ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
            READ(FMessageArea,MessageArea);
            IF ((MessageArea.Area_Tag<>'') AND (CanDo(MessageArea.Sub))) THEN
            BEGIN
              IF (DownLink.AccessLevel>=MessageArea.Read_Access) THEN
              BEGIN
                IF NOT(YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId)) THEN
                BEGIN
                  Crap := _PadRight(MessageArea.Area_Tag,41)+MessageArea.Area_Name;
                  WRITELN(TFile,_Mid(Crap,1,78));
                END;
              END;
            END;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All mail echoes not linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all mail echoes you are not linked:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(TempOutbound+'\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('Mail echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All mail echoes not linked on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all mail echoes you are not linked:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('Mail echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(TempOutbound+'\AREAFIX.TMP');
     END;

     PROCEDURE ListAllAreas;
     VAR  Counter      : Longint;
          MCounter     : Longint;
          Crap         : String;
          TFile        : Text;
          MessageArea  : _MessageArea_Record;
          FMessageArea : File Of _MessageArea_Record;
     BEGIN
          ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
          REWRITE(TFile);
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
            READ(FMessageArea,MessageArea);
            IF ((MessageArea.Area_Tag<>'') AND (CanDo(MessageArea.Sub))) THEN
            BEGIN
              IF (DownLink.AccessLevel>=MessageArea.Read_Access) THEN
              BEGIN
                IF YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId)
                   THEN Crap := '+ '+_PadRight(MessageArea.Area_Tag,41)+MessageArea.Area_Name
                   ELSE Crap := '  '+_PadRight(MessageArea.Area_Tag,41)+MessageArea.Area_Name;
                WRITELN(TFile,_Mid(Crap,1,78));
              END;
            END;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          CLOSE(TFile);
          Counter  := 0;
          MCounter := 1;
          StartMessage('All mail echoes available on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
          wFidoWriteString('Listing of all available mail echoes:');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('');
          IF (_FileSize(TempOutbound+'\AREAFIX.TMP')<>0) THEN
          BEGIN
            ASSIGN(TFile,TempOutbound+'\AREAFIX.TMP');
            RESET(TFile);
            REPEAT
              READLN(TFile,Crap);
              wFidoWriteString(Crap);
              INC(Counter);
              IF ((Counter=400) AND (NOT(EOF(TFile)))) THEN
              BEGIN
                wFidoWriteString('');
                wFidoWriteString('   + You are connected (linked) to that mail echo');
                wFidoWriteString('');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('Mail echoes listed: '+_String(Counter));
                wFidoWriteString(_Replicate('Ä',78));
                EndMessage;
                Counter := 0;
                INC(MCounter);
                StartMessage('All mail echoes available on '+AddressToString(Dest)+' ['+_String(MCounter)+']');
                wFidoWriteString('Listing of all available mail echoes:');
                wFidoWriteString(_Replicate('Ä',78));
                wFidoWriteString('');
              END;
            UNTIL EOF(TFile);
            CLOSE(TFile);
          END
          ELSE wFidoWriteString('No areas');
          wFidoWriteString('');
          wFidoWriteString('   + You are connected (linked) to that mail echo');
          wFidoWriteString('');
          wFidoWriteString(_Replicate('Ä',78));
          wFidoWriteString('Mail echoes listed: '+_String(Counter));
          wFidoWriteString(_Replicate('Ä',78));
          EndMessage;
          _EraseFile(TempOutbound+'\AREAFIX.TMP');
     END;

     PROCEDURE LinkAllAreas;
     VAR  EchoTag      : _SGEchoDat_Record;
          FFEchoTag    : File Of _SGEchoDat_Record;
          MessageArea  : _MessageArea_Record;
          FMessageArea : File Of _MessageArea_Record;
     BEGIN
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
            READ(FMessageArea,MessageArea);
            IF ((MessageArea.Area_Tag<>'') AND (CanDo(MessageArea.Sub))) THEN
            BEGIN
              IF (DownLink.AccessLevel>=MessageArea.Read_Access) THEN
              BEGIN
                IF NOT(YouAreConnected(DownLink.NetworkAddress,MessageArea.AreaId)) THEN
                BEGIN
                  EchoTag.AreaId := MessageArea.AreaId;
                  EchoTag.Aka    := DownLink.NetworkAddress;
                  CloseSGEchoDat;
                  ASSIGN(FFEchoTag,BaseDirectory+'\DATA\SGECHO.DAT');
                  {$I-}RESET(FFEchoTag);{$I+}
                  IF (IOResult<>0) THEN REWRITE(FFEchoTag);
                  SEEK(FFEchoTag,FileSize(FFEchoTag));
                  WRITE(FFEchoTag,EchoTag);
                  CLOSE(FFEchoTag);
                  OpenSGEchoDat;
                END;
              END;
            END;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
     END;

     PROCEDURE UnlinkAllAreas;
     VAR  EchoTag    : _SGEchoDat_Record;
          FFEchoTag  : File Of _SGEchoDat_Record;
          FFEchoTag2 : File Of _SGEchoDat_Record;
     BEGIN
          IF _FileExists(BaseDirectory+'\DATA\SGECHO.DAT') THEN
          BEGIN
            CloseSGEchoDat;
            _EraseFile(BaseDirectory+'\DATA\SGECHO.BAK');
            _RenameFile(BaseDirectory+'\DATA\SGECHO.DAT',BaseDirectory+'\DATA\SGECHO.BAK');
            ASSIGN(FFEchoTag2,BaseDirectory+'\DATA\SGECHO.BAK');
            ASSIGN(FFEchoTag,BaseDirectory+'\DATA\SGECHO.DAT');
            REWRITE(FFEchoTag);
            RESET(FFEchoTag2);
            REPEAT
              READ(FFEchoTag2,EchoTag);
              IF NOT(AkasMatch(EchoTag.Aka,DownLink.NetworkAddress)) THEN WRITE(FFEchoTag,EchoTag);
            UNTIL EOF(FFEchoTag2);
            CLOSE(FFEchoTag2);
            ERASE(FFEchoTag2);
            CLOSE(FFEchoTag);
            IF _FileSize(BaseDirectory+'\DATA\SGECHO.DAT')=0 THEN ERASE(FFEchoTag);
            OpenSGEchoDat;
          END;
     END;

BEGIN
     IF DoNotify THEN
     BEGIN
       WriteLogFile('Processing -NOTIFY');
       BufferedFile.Init(32768);
       FLinkGroups.OpenFile(BaseDirectory+'\DATA\LINKGRPS.DAT',SetFileMode);
       FLinksInfo.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);
       REPEAT
         FLinkGroups.BlkRead(DownLinkGroups,SizeOf(DownLinkGroups),BytesRead);
         FLinksInfo.BlkRead(DownLink,SizeOf(DownLink),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF DownLink.SendNotify THEN
           BEGIN
             GetNetAddress(DownLink.AkaToUse);
             Orig := DownLink.NetworkAddress;
             Dest := NetworkInfo.Net_Address;
             WriteLogFile('Sending basic setup information to '+AddressToString(DownLink.NetworkAddress));
             StartMessage('Current SGEcho setup.');
             wFidoWriteString('Please check your setup to make sure these settings are correct:');
             wFidoWriteString('');
             wFidoWriteString('  Sysop Name.........:  '+DownLink.SysopName);
             wFidoWriteString('  Network Address....:  '+AddressToString(DownLink.NetworkAddress));
             wFidoWriteString('  TIC File Password..:  '+DownLink.SGEchoPacket);
             wFidoWriteString('  Areafix Password...:  '+DownLink.SGEchoAreaFix);
             wFidoWriteString('  Compression Method.:  '+DownLink.Archiver);
             CASE DownLink.NetmailStatus OF
             1:   wFidoWriteString('  Netmail Status.....:  None');
             2:   wFidoWriteString('  Netmail Status.....:  Hold');
             3:   wFidoWriteString('  Netmail Status.....:  Crash');
             END;
             IF DownLink.AreaCreate
                THEN wFidoWriteString('  Auto Area Create...:  Yes')
                ELSE wFidoWriteString('  Auto Area Create...:  No');
             IF DownLink.Paused
                THEN wFidoWriteString('  System Paused......:  Yes')
                ELSE wFidoWriteString('  System Paused......:  No');
             EndMessage;
             WriteLogFile('%QUERY - Sending list of all linked areas to '+AddressToString(DownLink.NetworkAddress));
             ListAllLinkedAreas;
             WriteLogFile('%HELP - Sending SGECHO.HLP to '+AddressToString(DownLink.NetworkAddress));
             SendHelp;
           END;
         END;
       UNTIL BytesRead=0;
       FLinkGroups.CloseFile;
       FLinksInfo.CloseFile;
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
         IF ((Temp='SGECHO') OR (Temp='AREAFIX') OR (Temp='AREAMGR')) THEN
         BEGIN
           IF ((NOT rFidoIsReceived) AND (NOT rFidoIsLocal)) THEN
           BEGIN
             rFidoGetAkas(Orig,Dest);
             IF ((IsOurNode(Dest)) AND (LoadTheLink(Orig))) THEN
             BEGIN
               GetNetAddress(DownLink.AkaToUse);
               Dest := NetworkInfo.Net_Address;
               INC(RunningAFix);
               ASSIGN(StatusFile,TempOutbound+'\AREAFIX.$$$');
               REWRITE(StatusFile);
               WriteLogFile('Areafix message.: #'+_String(FidoMsgNum)+' from '+AddressToString(Orig));
               Temp := _RemoveSpaces(_UpperCase(rFidoGetMsgSubject));
               IF Temp=DownLink.SGEchoAreaFix THEN
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
                         IF DownLink.AllowPause THEN
                         BEGIN
                           LogAndStat('%PAUSE - '+AddressToString(Orig)+' packing paused.');
                           DownLink.Paused := True;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%PAUSE - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%RESUME' THEN
                       BEGIN
                         IF DownLink.AllowResume THEN
                         BEGIN
                           LogAndStat('%RESUME - '+AddressToString(Orig)+' packing resumed.');
                           DownLink.Paused := False;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%RESUME - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF _Mid(Temp,1,9)='%PASSWORD' THEN
                       BEGIN
                         Delete(Temp,1,9);
                         IF DownLink.AllowPassword THEN
                         BEGIN
                           LogAndStat('%PASSWORD - '+AddressToString(Orig)+' password changed to "'+Temp+'".');
                           DownLink.SGEchoPacket  := Temp;
                           DownLink.SGEchoAreaFix := Temp;
                           WriteThisNode;
                         END
                         ELSE LogAndStat('%PASSWORD - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%HELP' THEN
                       BEGIN
                         IF DownLink.AllowHelp THEN
                         BEGIN
                           LogAndStat('%HELP - Sending SGECHO.HLP to '+AddressToString(Orig));
                           SendHelp;
                         END
                         ELSE LogAndStat('%HELP - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF _Mid(Temp,1,10)='%COMPRESS ' THEN
                       BEGIN
                         Delete(Temp,1,10);
                         IF DownLink.AllowCompress THEN
                         BEGIN
                           LogAndStat('%COMPRESS - Processed to remote ('+Temp+')');
                           ChangeCompress(Temp);
                         END
                         ELSE LogAndStat('%COMPRESS - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%LIST' THEN
                       BEGIN
                         IF DownLink.AllowList THEN
                         BEGIN
                           LogAndStat('%LIST - Sending list of all available areas to '+AddressToString(Orig));
                           ListAllAreas;
                         END
                         ELSE LogAndStat('%LIST - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%QUERY' THEN
                       BEGIN
                         IF DownLink.AllowQuery THEN
                         BEGIN
                           LogAndStat('%QUERY - Sending list of all linked areas to '+AddressToString(Orig));
                           ListAllLinkedAreas;
                         END
                         ELSE LogAndStat('%QUERY - Not allowed by '+AddressToString(Orig));
                       END
                       ELSE IF Temp='%UNLINKED' THEN
                       BEGIN
                         IF DownLink.AllowUnlinked THEN
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
                           IF LoadSub(DownLinkGroups.CreateMsgGroup) THEN
                           BEGIN
                             IF MessageSubs.AutoRequests THEN
                             BEGIN
                               IF LoadTheLink(MessageSubs.Uplink) THEN
                               BEGIN
                                 GetNetAddress(DownLink.AkaToUse);
                                 LogAndStat('Area: '+Temp+' has been requested from upstream host.');
                                 wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
                                 wFidoSetMsgFrom(OurAppName);
                                 wFidoSetMsgTo(MessageSubs.AreaManager);
                                 wFidoSetMsgSubject(_UpperCase(MessageSubs.YourPassword));
                                 wFidoSetAkas(NetworkInfo.Net_Address,DownLink.NetworkAddress);
                                 CASE DownLink.NetMailStatus OF
                                 2:   wFidoSetHoldForPickup(True);
                                 3:   wFidoSetCrash(True);
                                 END;
                                 IF KeepAFix THEN wFidoSetKillSent(False);
                                 wFidoSetDirect(True);
                                 wFidoWriteHeader(True);
                                 wFidoWriteString('+'+Temp);
                                 wFidoEndMessage;
                               END;
                               LoadTheLink(Orig);
                               GetNetAddress(DownLink.AkaToUse);
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
                         IF DownLink.AllowRescan THEN
                         BEGIN
                           IF (Temp<>'') THEN
                           BEGIN
                             LogAndStat('%RESCAN - Rescanning '+Temp+' for '+AddressToString(Orig));
                             {Rescan(Temp); FUCK!}
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
                 WriteLogFile('! Areafix password from '+AddressToString(Orig)+' is incorrect.');
                 WriteLogFile('! Expected: "'+DownLink.SGEchoAreaFix+'"  Received: "'+Temp+'".');
               END;
               CLOSE(StatusFile);
               IF (_FileSize(TempOutbound+'\AREAFIX.$$$')<>0) THEN SendStatusMsg;
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