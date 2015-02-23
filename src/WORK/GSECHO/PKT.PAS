{$I DEFINES.INC}
UNIT Pkt;


INTERFACE


PROCEDURE TossThePkt(FName: String);
PROCEDURE SortSeenBys;


IMPLEMENTATION


USES BsPkt,Globals,BsFile,BsLog,Gunshot,BsAkas,Common,BsFido,_EchoTag,
     BsString,Crt,BsVideo,BsCrc,MkOpen,MkMsgAbs,DupeBase,KeyCheck;


PROCEDURE RenameToBad(FName: String);
VAR  Temp    : String;
     NewName : String;
BEGIN
     FName   := _NoPath(FName);
     NewName := _NoExtension(FName)+'.BAD';
     ChDir(TempUnpack);
     _RenameFile(FName,NewName);
     Temp := _MoveFileSafe(NewName,TempUnpack,Mailer.Inbound);
     bsWriteLog(' ! File renamed to: '+Mailer.Inbound+Temp,False);
     ChDir(BaseDirectory);
END;


PROCEDURE RenameToSec(FName: String);
VAR  Temp    : String;
     NewName : String;
BEGIN
     FName   := _NoPath(FName);
     NewName := _NoExtension(FName)+'.SEC';
     ChDir(TempUnpack);
     _RenameFile(FName,NewName);
     Temp := _MoveFileSafe(NewName,TempUnpack,Mailer.Inbound);
     bsWriteLog(' ! File renamed to: '+Mailer.Inbound+Temp,False);
     ChDir(BaseDirectory);
END;


FUNCTION LoadTheMessageArea(AreaTag: String): Boolean;
BEGIN
     IF TossMessageArea.Area_Tag=AreaTag THEN
     BEGIN
       LoadTheMessageArea := True;
       Exit;
     END;
     ASSIGN(FTossMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FTossMessageArea);
     REPEAT
       READ(FTossMessageArea,TossMessageArea);
       IF TossMessageArea.Area_Tag=AreaTag THEN
       BEGIN
         CLOSE(FTossMessageArea);
         LoadTheMessageArea := True;
         Exit;
       END;
     UNTIL EOF(FTossMessageArea);
     CLOSE(FTossMessageArea);
     LoadTheMessageArea := False;
END;


FUNCTION GetHighMessage: Word;
VAR  Highest : Word;
BEGIN
     Highest := 0;
     ASSIGN(FTossMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FTossMessageArea);
     REPEAT
       READ(FTossMessageArea,TossMessageArea);
       IF TossMessageArea.AreaID>Highest THEN Highest := TossMessageArea.AreaID;
     UNTIL EOF(FTossMessageArea);
     CLOSE(FTossMessageArea);
     GetHighMessage := Highest+1;
END;


FUNCTION AutoCreateIt(AreaTag: String): Boolean;
VAR  AreaIDCrc : String[8];
     NewId     : Word;
     AllDone   : Boolean;
     TFile     : Text;
     Temp      : String;
     Work      : Word;
     EchoTag   : _GSEchoDat_Record;
     FFEchoTag : File Of _GSEchoDat_Record;
BEGIN
     IF UpLink.AreaCreate THEN
     BEGIN
       IF LoadSub(UpLinkGroups.CreateMsgGroup) THEN
       BEGIN
         AreaIDCrc := StringCrc(AreaTag);
         NewId := GetHighMessage;
         {Set The Area Record}
         FillChar(TossMessageArea,SizeOf(TossMessageArea),0);
         Move(MessageSubs.Tags,TossMessageArea.Tags,10);
         TossMessageArea.Origin            := MessageSubs.Origin;
         TossMessageArea.Address           := MessageSubs.Address;
         TossMessageArea.Sub               := UpLinkGroups.CreateMsgGroup;
         TossMessageArea.AreaId            := NewId;
         TossMessageArea.MaxMsgs           := MessageSubs.MaxMsgs;
         TossMessageArea.Area_Tag          := AreaTag;
         TossMessageArea.Area_Name         := AreaTag;
         TossMessageArea.Base_Type         := MessageSubs.Base_Type;
         TossMessageArea.Read_Access       := MessageSubs.Read_Access;
         TossMessageArea.Write_Access      := MessageSubs.Write_Access;
         TossMessageArea.Area_Type         := MessageSubs.Area_Type;
         TossMessageArea.Msg_Type          := MessageSubs.Msg_Type;
         TossMessageArea.File_Attaches     := MessageSubs.File_Attaches;
         TossMessageArea.File_Attaches_Sec := MessageSubs.File_Attaches_Sec;
         TossMessageArea.DoGraphics        := MessageSubs.DoGraphics;
         TossMessageArea.CleanLanguage     := MessageSubs.CleanLanguage;
         TossMessageArea.PassThrough       := MessageSubs.PassThrough;
         _CreatePath(MessageSubs.Dos_Name);
         CASE TossMessageArea.Base_Type OF
         1:   TossMessageArea.Dos_Name := MessageSubs.Dos_Name+AreaIdCrc;
         2:   TossMessageArea.Dos_Name := MessageSubs.Dos_Name+AreaIdCrc;
         3:   BEGIN
                TossMessageArea.Dos_Name := MessageSubs.Dos_Name+AreaIdCrc+'\';
                _CreatePath(TossMessageArea.Dos_Name);
              END;
         END;
         {Try Grabbing A Real Description From BACKBONE.NA}
         IF ((MessageSubs.BackBoneNa<>'') AND (_FileExists(MessageSubs.BackBoneNa))) THEN
         BEGIN
           AllDone := False;
           ASSIGN(TFile,MessageSubs.BackBoneNa);
           RESET(TFile);
           REPEAT
             READLN(TFile,Temp);
             Temp := _RemoveLeftSpaces(Temp);
             Work := Pos(' ',Temp);
             IF (Work<>0) THEN
             BEGIN
               IF _UpperCase(_Mid(Temp,1,Work-1))=AreaTag THEN
               BEGIN
                 Delete(Temp,1,Work);
                 Temp := _RemoveLeftSpaces(Temp);
                 TossMessageArea.Area_Name := _Mid(Temp,1,40);
                 AllDone := True;
               END;
             END;
           UNTIL ((EOF(TFile)) OR (AllDone));
           CLOSE(TFile);
         END;
         {Write To Main MA000000.DAT File}
         ASSIGN(FTossMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
         RESET(FTossMessageArea);
         SEEK(FTossMessageArea,FileSize(FTossMessageArea));
         WRITE(FTossMessageArea,TossMessageArea);
         CLOSE(FTossMessageArea);
         {Write To Sub MAxxxxxx.DAT File}
         ASSIGN(FTossMessageArea,BaseDirectory+'\DATA\MA'+ZeroPadded(TossMessageArea.Sub)+'.DAT');
         {$I-}RESET(FTossMessageArea);{$I+}
         IF IOResult=0 THEN SEEK(FTossMessageArea,FileSize(FTossMessageArea))
                       ELSE REWRITE(FTossMessageArea);
         WRITE(FTossMessageArea,TossMessageArea);
         CLOSE(FTossMessageArea);
         {Announce/log the adding of the area}
         bsWriteLog(' $ Created new echo area: '+AreaTag+' from '+AddressToString(UpLink.NetworkAddress),False);
         Temp := 'Auto-Created Area:  '+_PadRight(AreaTag,30)+'Node: '+AddressToString(UpLink.NetworkAddress);
         ASSIGN(TFile,TempOutbound+'\AUTOADD.TXT');
         {$I-}APPEND(TFile);{$I+}
         IF IOResult<>0 THEN REWRITE(TFile);
         WRITELN(TFile,Temp);
         CLOSE(TFile);
         {Add the creating node to the area}
         EchoTag.AreaId := NewId;
         EchoTag.Aka    := UpLink.NetworkAddress;
         CloseGSEchoDat;
         ASSIGN(FFEchoTag,BaseDirectory+'\DATA\GSECHO.DAT');
         {$I-}RESET(FFEchoTag);{$I+}
         IF (IOResult<>0) THEN REWRITE(FFEchoTag);
         SEEK(FFEchoTag,FileSize(FFEchoTag));
         WRITE(FFEchoTag,EchoTag);
         CLOSE(FFEchoTag);
         OpenGSEchoDat;
         AutoCreateIt := True;
         Exit;
       END;
     END;
     AutoCreateIt := False;
END;


FUNCTION CanAccessArea(InAddress: AddrType): Boolean;
VAR  EchoTag   : _GSEchoDat_Record;
     BytesRead : Word;
BEGIN
     OpenGSEchoDat;
     IF IsEchoTagFileOpen THEN
     BEGIN
       REPEAT
         FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF (EchoTag.AreaID=TossMessageArea.AreaId) THEN
           BEGIN
             IF AkasMatch(EchoTag.Aka,InAddress) THEN
             BEGIN
               CanAccessArea := True;
               Exit;
             END;
           END;
         END;
       UNTIL BytesRead=0;
     END;
     CanAccessArea := False;
END;


PROCEDURE SortSeenBys;
VAR  i,j       : Word;
     Temp      : TwoDimensionAddr;
     StartSort : Word;
     EndSort   : Word;
     LastNet   : Word;
     Crapper   : Boolean;
LABEL            Again;

     PROCEDURE SortThisSection;
     VAR  i2,j2 : Word;
     BEGIN
          FOR i2 := StartSort TO EndSort DO
          BEGIN
            FOR j2 := StartSort TO EndSort DO
            BEGIN
              IF (SeenBys[i2].Node<SeenBys[j2].Node) THEN
              BEGIN
                Temp        := SeenBys[i2];
                SeenBys[i2] := SeenBys[j2];
                SeenBys[j2] := Temp;
              END;
            END;
          END;
     END;

BEGIN
     IF NumSeenBys<2 THEN Exit;
     {Sort The SeenBys - By Net}
     FOR i := 1 TO NumSeenBys DO
     BEGIN
       FOR j := 1 TO NumSeenBys DO
       BEGIN
         IF (SeenBys[i].Net<SeenBys[j].Net) THEN
         BEGIN
           Temp       := SeenBys[i];
           SeenBys[i] := SeenBys[j];
           SeenBys[j] := Temp;
         END;
       END;
     END;
     {Sort The SeenBys - By Node}
     StartSort := 1;
     Crapper   := False;
     Again:
     LastNet := SeenBys[StartSort].Net;
     REPEAT
       IF StartSort>NumSeenBys THEN Exit;
       EndSort := StartSort;
       REPEAT
         INC(EndSort);
       UNTIL ((EndSort>NumSeenBys) OR (SeenBys[EndSort].Net<>LastNet));
       DEC(EndSort);
       IF StartSort=EndSort THEN
       BEGIN
         INC(StartSort);
         GOTO Again;
       END
       ELSE
       BEGIN
         SortThisSection;
         StartSort := EndSort+1;
         GOTO Again;
       END;
     UNTIL Crapper;
END;


PROCEDURE TossThePkt(FName: String);
VAR  Temp         : String;
     Orig         : AddrType;
     Dest         : AddrType;
     MsgOrig      : AddrType;
     MsgDest      : AddrType;
     CanDoEcho    : Boolean;
     Status       : Boolean;
     GotString    : Boolean;
     WasWrapped   : Boolean;
     MsgTo        : String[100];
     MsgFrom      : String[100];
     MsgSubject   : String[100];
     MsgArea      : String[100];
     LastArea     : String[100];
     MsgDate      : String[10];
     MsgTime      : String[8];
     YPos         : Byte;
     LLen         : Word;
     Work         : Byte;
     MsgId        : Longint;
     IsIntl       : Boolean;
     IntlLine     : String[80];

     PROCEDURE StoreMsgLine;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO LENGTH(Temp) DO
          BEGIN
            INC(InBuffer);
            MsgTextBuffer^[InBuffer] := Temp[Loop];
          END;
          IF WasWrapped THEN
          BEGIN
            INC(InBuffer);
            MsgTextBuffer^[InBuffer] := ' ';
          END
          ELSE
          BEGIN
            INC(InBuffer);
            MsgTextBuffer^[InBuffer] := #13;
          END;
     END;

     PROCEDURE StorePath;
     VAR  TmpWork : String;
     BEGIN
          REPEAT
            Work := Pos(' ',Temp);
            IF (Work<>0) THEN
            BEGIN
              TmpWork := _Mid(Temp,1,Work-1);
              Delete(Temp,1,Work);
            END
            ELSE
            BEGIN
              TmpWork := Temp;
              Temp    := '';
            END;
            IF (TmpWork<>'') THEN
            BEGIN
              INC(NumPaths);
              Work := Pos('/',TmpWork);
              IF Work<>0 THEN
              BEGIN
                Paths[NumPaths].Net  := _Numeric(_Mid(TmpWork,1,Work-1));
                Paths[NumPaths].Node := _Numeric(_Mid(TmpWork,Work+1,Ord(TmpWork[0])));
              END
              ELSE
              BEGIN
                Paths[NumPaths].Net  := Paths[NumPaths-1].Net;
                Paths[NumPaths].Node := _Numeric(TmpWork);
              END;
            END;
          UNTIL TmpWork='';
     END;

     PROCEDURE StoreSeenBy;
     VAR  TmpWork : String;
     BEGIN
          REPEAT
            Work := Pos(' ',Temp);
            IF (Work<>0) THEN
            BEGIN
              TmpWork := _Mid(Temp,1,Work-1);
              Delete(Temp,1,Work);
            END
            ELSE
            BEGIN
              TmpWork := Temp;
              Temp    := '';
            END;
            IF (TmpWork<>'') THEN
            BEGIN
              INC(NumSeenBys);
              Work := Pos('/',TmpWork);
              IF Work<>0 THEN
              BEGIN
                SeenBys[NumSeenBys].Net  := _Numeric(_Mid(TmpWork,1,Work-1));
                SeenBys[NumSeenBys].Node := _Numeric(_Mid(TmpWork,Work+1,Ord(TmpWork[0])));
              END
              ELSE
              BEGIN
                SeenBys[NumSeenBys].Net  := SeenBys[NumSeenBys-1].Net;
                SeenBys[NumSeenBys].Node := _Numeric(TmpWork);
              END;
            END;
          UNTIL TmpWork='';
     END;

     PROCEDURE LoadMsgText;
     BEGIN
          Temp        := '';
          NumPaths    := 0;
          NumSeenBys  := 0;
          InBuffer    := 0;
          MsgId       := 0;
          IsIntl      := False;
          IntlLine[0] := #0;
          REPEAT
            GotString := rPktGetString(Temp,WasWrapped);
            IF GotString THEN
            BEGIN
              IF Pos(#1+'PATH: ',Temp)=1 THEN
              BEGIN
                Delete(Temp,1,7);
                StorePath;
              END
              ELSE IF Pos(#1+'MSGID: ',Temp)=1 THEN
              BEGIN
                StoreMsgLine;
                MsgId := StringCrcL(Temp);
              END
              ELSE IF Pos(#1+'INTL ',Temp)=1 THEN
              BEGIN
                StoreMsgLine;
                IntlLine := Temp;
                IsIntl   := True;
              END
              ELSE IF Pos('SEEN-BY: ',Temp)=1 THEN
              BEGIN
                Delete(Temp,1,9);
                StoreSeenBy;
              END
              ELSE StoreMsgLine;
            END;
          UNTIL NOT(GotString);
          WHILE MsgTextBuffer^[InBuffer]=#13 DO DEC(InBuffer);
          INC(InBuffer);
          MsgTextBuffer^[InBuffer] := #13;
     END;

     PROCEDURE WriteToNetmail;
     VAR  Loop : Word;
     BEGIN
          INC(NumNetmails);
          wFidoStartNewMessage(Mailer.NetMail,OurAppName,0);
          wFidoSetMsgFrom(MsgFrom);
          wFidoSetMsgTo(MsgTo);
          wFidoSetMsgSubject(MsgSubject);
          wFidoSetLocal(False);
          wFidoSetAkas(MsgOrig,MsgDest);
          wFidoSetDate(MsgDate);
          wFidoSetTime(MsgTime);
          wFidoWriteHeader(False);
          FOR Loop := 1 TO InBuffer DO wFidoWriteChar(MsgTextBuffer^[Loop]);
          wFidoEndMessage;
     END;

     PROCEDURE WriteSeenBysAndPaths(ToFido: Boolean);
     VAR  Loop    : Word;
          Temp2   : String;
          Temp3   : String;
          LastNet : Longint;
     BEGIN
          Temp2   := '';
          LastNet := 999999;
          FOR Loop := 1 TO NumSeenBys DO
          BEGIN
            IF (LastNet<>SeenBys[Loop].Net) THEN
            BEGIN
              Temp3 := ' '+_String(SeenBys[Loop].Net)+'/'+_String(SeenBys[Loop].Node);
              LastNet := SeenBys[Loop].Net;
            END
            ELSE Temp3 := ' '+_String(SeenBys[Loop].Node);
            IF Ord(Temp2[0])+Ord(Temp3[0])>60 THEN
            BEGIN
              IF ToFido THEN wFidoWriteString('SEEN-BY:'+Temp2)
                        ELSE TossMsg^.DoStringLn('SEEN-BY:'+Temp2);
              Temp2 := ' '+_String(SeenBys[Loop].Net)+'/'+_String(SeenBys[Loop].Node);
            END
            ELSE Temp2 := Temp2+Temp3;
          END;
          IF Temp2<>'' THEN
          BEGIN
            IF ToFido THEN wFidoWriteString('SEEN-BY:'+Temp2)
                      ELSE TossMsg^.DoStringLn('SEEN-BY:'+Temp2);
          END;
          Temp2   := '';
          LastNet := 999999;
          FOR Loop := 1 TO NumPaths DO
          BEGIN
            IF (LastNet<>Paths[Loop].Net) THEN
            BEGIN
              Temp3 := ' '+_String(Paths[Loop].Net)+'/'+_String(Paths[Loop].Node);
              LastNet := Paths[Loop].Net;
            END
            ELSE Temp3 := ' '+_String(Paths[Loop].Node);
            IF Ord(Temp2[0])+Ord(Temp3[0])>60 THEN
            BEGIN
              IF ToFido THEN wFidoWriteString(#1+'PATH:'+Temp2)
                        ELSE TossMsg^.DoStringLn(#1+'PATH:'+Temp2);
              Temp2 := ' '+_String(Paths[Loop].Net)+'/'+_String(Paths[Loop].Node);
            END
            ELSE Temp2 := Temp2+Temp3;
          END;
          IF Temp2<>'' THEN
          BEGIN
            IF ToFido THEN wFidoWriteString(#1+'PATH:'+Temp2)
                      ELSE TossMsg^.DoStringLn(#1+'PATH:'+Temp2);
          END;
     END;

     PROCEDURE WriteToBad(Reason: String);
     VAR  Loop    : Word;
     BEGIN
          INC(NumEchomails);
          bsWriteLog(' ! Message written to bad: '+Reason,False);
          wFidoStartNewMessage(BaseDirectory+'\BADECHO\',OurAppName,0);
          wFidoSetMsgFrom(MsgFrom);
          wFidoSetMsgTo(MsgTo);
          wFidoSetMsgSubject(MsgSubject);
          wFidoSetLocal(False);
          wFidoSetAkas(MsgOrig,MsgDest);
          wFidoSetDate(MsgDate);
          wFidoSetTime(MsgTime);
          wFidoWriteHeader(False);
          wFidoWriteString('  Area: '+MsgArea);
          wFidoWriteString('Origin: '+AddressToString(Orig));
          wFidoWriteString('Reason: '+Reason);
          wFidoWriteString('-------');
          FOR Loop := 1 TO InBuffer DO wFidoWriteChar(MsgTextBuffer^[Loop]);
          WriteSeenBysAndPaths(True);
          wFidoEndMessage;
     END;

     PROCEDURE ExportEchomail;
     VAR  EchoTag     : _GSEchoDat_Record;
          NeedsExport : Boolean;
          Temp        : String;
          PktHeader   : PakdMessageHeadr;
          FFile       : File;
          ScrapByte   : Byte;
          Loop        : Word;
          Temp2       : String;
          Temp3       : String;
          LastNet     : Longint;
          BytesRead   : Word;
     BEGIN
          NeedsExport := False;
          OpenGSEchoDat;
          IF IsEchoTagFileOpen THEN
          BEGIN
            {Add The Seen-Bys}
            REPEAT
              FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
              IF (BytesRead<>0) THEN
              BEGIN
                IF EchoTag.AreaId=TossMessageArea.AreaId THEN
                BEGIN
                  IF NOT(AkasMatch(EchoTag.Aka,UpLink.NetworkAddress)) THEN
                  BEGIN
                    IF (EchoTag.Aka.Point=0) THEN
                    BEGIN
                      INC(NumSeenBys);
                      SeenBys[NumSeenBys].Net  := EchoTag.Aka.Net;
                      SeenBys[NumSeenBys].Node := EchoTag.Aka.Node;
                    END;
                    NeedsExport := True;
                  END;
                END;
              END;
            UNTIL BytesRead=0;
            {Export If Needed}
            IF NeedsExport THEN
            BEGIN
              {Sort The SeenBy Lines}
              SortSeenBys;
              {Load Our Aka}
              GetNetAddress(TossMessageArea.Address);
              {Packet Origin}
              FillChar(PktHeader,SizeOf(PktHeader),0);
              PktHeader.Signature := 2;
              PktHeader.OrigNet   := NetworkInfo.Net_Address.Net;
              PktHeader.OrigNode  := NetworkInfo.Net_Address.Node;
              rPktGetDateTime(PktHeader.DateTime);
              {Set The Area Line}
              Temp := 'AREA:'+TossMessageArea.Area_Tag+#13;
              {Add Our Path}
              INC(NumPaths);
              Paths[NumPaths].Net  := NetworkInfo.Net_Address.Net;
              Paths[NumPaths].Node := NetworkInfo.Net_Address.Node;
              OpenGSEchoDat;
              REPEAT
                FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
                IF (BytesRead<>0) THEN
                BEGIN
                  IF EchoTag.AreaId=TossMessageArea.AreaId THEN
                  BEGIN
                    IF NOT(AkasMatch(EchoTag.Aka,UpLink.NetworkAddress)) THEN
                    BEGIN
                      IF LoadTheLink(EchoTag.Aka) THEN
                      BEGIN
                        INC(NumExported);
                        PktHeader.DestNet  := EchoTag.Aka.Net;
                        PktHeader.DestNode := EchoTag.Aka.Node;
                        ASSIGN(FFile,TempOutbound+'\'+System_Crc(DownLink.NetworkAddress)+'.OUT');
                        RESET(FFile,1);
                        SEEK(FFile,FileSize(FFile));
                        {Main Msg Header}
                        BlockWrite(FFile,PktHeader,SizeOf(PktHeader));
                        {Variable Length User Stuff}
                        ScrapByte := 0;
                        BlockWrite(FFile,MsgTo[1],Ord(MsgTo[0]));
                        BlockWrite(FFile,ScrapByte,1);
                        BlockWrite(FFile,MsgFrom[1],Ord(MsgFrom[0]));
                        BlockWrite(FFile,ScrapByte,1);
                        BlockWrite(FFile,MsgSubject[1],Ord(MsgSubject[0]));
                        BlockWrite(FFile,ScrapByte,1);
                        {Area Kludge Line}
                        BlockWrite(FFile,Temp[1],Ord(Temp[0]));
                        {Do Msg Body}
                        BlockWrite(FFile,MsgTextBuffer^,InBuffer);
                        {Do Seen-Bys}
                        Temp2   := '';
                        LastNet := 999999;
                        FOR Loop := 1 TO NumSeenBys DO
                        BEGIN
                          IF (LastNet<>SeenBys[Loop].Net) THEN
                          BEGIN
                            Temp3 := ' '+_String(SeenBys[Loop].Net)+'/'+_String(SeenBys[Loop].Node);
                            LastNet := SeenBys[Loop].Net;
                          END
                          ELSE Temp3 := ' '+_String(SeenBys[Loop].Node);
                          IF Ord(Temp2[0])+Ord(Temp3[0])>60 THEN
                          BEGIN
                            Temp2 := 'SEEN-BY:'+Temp2+#13;
                            BlockWrite(FFile,Temp2[1],Ord(Temp2[0]));
                            Temp2 := ' '+_String(SeenBys[Loop].Net)+'/'+_String(SeenBys[Loop].Node);
                          END
                          ELSE Temp2 := Temp2+Temp3;
                        END;
                        IF Temp2<>'' THEN
                        BEGIN
                          Temp2 := 'SEEN-BY:'+Temp2+#13;
                          BlockWrite(FFile,Temp2[1],Ord(Temp2[0]));
                        END;
                        {Do Path Lines}
                        Temp2   := '';
                        LastNet := 999999;
                        FOR Loop := 1 TO NumPaths DO
                        BEGIN
                          IF (LastNet<>Paths[Loop].Net) THEN
                          BEGIN
                            Temp3 := ' '+_String(Paths[Loop].Net)+'/'+_String(Paths[Loop].Node);
                            LastNet := Paths[Loop].Net;
                          END
                          ELSE Temp3 := ' '+_String(Paths[Loop].Node);
                          IF Ord(Temp2[0])+Ord(Temp3[0])>60 THEN
                          BEGIN
                            Temp2 := #1+'PATH:'+Temp2+#13;
                            BlockWrite(FFile,Temp2[1],Ord(Temp2[0]));
                            Temp2 := ' '+_String(Paths[Loop].Net)+'/'+_String(Paths[Loop].Node);
                          END
                          ELSE Temp2 := Temp2+Temp3;
                        END;
                        IF Temp2<>'' THEN
                        BEGIN
                          Temp2 := #1+'PATH:'+Temp2+#13;
                          BlockWrite(FFile,Temp2[1],Ord(Temp2[0]));
                        END;
                        {Write A Scrap Byte #0 Terminator}
                        BlockWrite(FFile,ScrapByte,1);
                        CLOSE(FFile);
                      END;
                    END;
                  END;
                END;
              UNTIL BytesRead=0;
            END;
          END;
     END;

     PROCEDURE WriteToEchomail;
     VAR  AreaType : Char;
          Loop     : Word;
          EchoTag  : _GSEchoDat_Record;
     BEGIN
          IF NOT(IsADupe(MsgId,TossMessageArea.AreaId)) THEN
          BEGIN
            INC(NumEchomails);
            IF NOT(TossMessageArea.PassThrough) THEN
            BEGIN
              CASE TossMessageArea.Base_Type OF
              1:  AreaType := 'J';
              2:  AreaType := 'S';
              3:  AreaType := 'F';
              END;
              IF TossMessageArea.MaxMsgs=0 THEN TossMessageArea.MaxMsgs := 1000;
              IF OpenOrCreateMsgArea(TossMsg,AreaType+TossMessageArea.Dos_Name,TossMessageArea.MaxMsgs) THEN
              BEGIN
                TossMsg^.StartNewMsg;
                TossMsg^.SetMailType (mmtEchoMail);
                TossMsg^.SetEcho     (True);
                TossMsg^.SetLocal    (False);
                TossMsg^.SetFrom     (MsgFrom);
                TossMsg^.SetTo       (MsgTo);
                TossMsg^.SetSubj     (MsgSubject);
                TossMsg^.SetDate     (MsgDate);
                TossMsg^.SetTime     (MsgTime);
                FOR Loop := 1 TO InBuffer DO TossMsg^.DoChar(MsgTextBuffer^[Loop]);
                IF NOT(StripControlLines) THEN WriteSeenBysAndPaths(False);
                TossMsg^.WriteMsg;
                CloseMsgArea(TossMsg);
              END;
            END;
            ExportEchomail;
          END
          ELSE
          BEGIN
            INC(NumDupes);
            WriteToBad('Duplicate message (via MSGID)');
          END;
     END;

BEGIN
     IF rPktStartUpPacket(FName) THEN
     BEGIN
       {Get AKAS and draw status/log}
       rPktGetAkas(Orig,Dest);
       Temp := 'Packet: '+_NoPath(FName)+' From '+AddressToString(Orig)+' to '+AddressToString(Dest)+
               ' ('+rPktGetProductName+' '+rPktGetProductVersion+' Type '+rPktGetPacketType+')';
       WRITELN(Temp);
       bsWriteLog(Temp,False);
       {Load the link and determine if it can toss echo mail}
       CanDoEcho := LoadTheUpLink(Orig);
       {Check The Password}
       IF CanDoEcho THEN
       BEGIN
         Temp := _UpperCase(rPktGetPktPassword);
         IF (Temp<>UpLink.GSEchoPacket) THEN
         BEGIN
           rPktCloseUpPacket;
           bsWriteLog(' ! Packet password error from: '+AddressToString(Orig),False);
           bsWriteLog(' ! Expected: "'+UpLink.GSEchoPacket+'" Received: "'+Temp+'"',False);
           RenameToSec(FName);
           Exit;
         END;
       END;
       {Toss It}
       YPos := WhereY+6;
       WRITE('À[Tossing to area: ');
       LastArea := '';
       REPEAT
         Status := rPktReadNextMessage;
         IF Status THEN
         BEGIN
           INC(NumMsgs);
           {Get The Goodies}
           MsgArea    := rPktGetMsgArea;
           MsgTo      := rPktGetMsgTo;
           MsgFrom    := rPktGetMsgFrom;
           MsgSubject := rPktGetMsgSubject;
           MsgDate    := rPktGetMsgDate;
           MsgTime    := rPktGetMsgTime;
           rPktGetMsgAkas(MsgOrig,MsgDest);
           {Draw The Status}
           IF (LastArea<>MsgArea) THEN
           BEGIN
             LastArea := MsgArea;
             FastWrite(_PadRight(LastArea,40),YPos,20,7);
           END;
           LoadMsgText;
           IF MsgArea='NETMAIL' THEN
           BEGIN
             WriteToNetmail;
           END
           ELSE IF CanDoEcho THEN
           BEGIN
             IF LoadTheMessageArea(MsgArea) THEN
             BEGIN
               IF CanAccessArea(Orig) THEN
               BEGIN
                 WriteToEchoMail;
               END
               ELSE
               BEGIN
                 WriteToBad('Remote can not access this area');
               END;
             END
             ELSE IF AutoCreateIt(MsgArea) THEN
             BEGIN
               WriteToEchoMail;
               GotoXy(1,WhereY);
               ClrEol;
               WRITELN('Ã[Creating area: '+MsgArea);
               WRITE('À[Tossing to area: ');
               YPos := WhereY+6;
               FastWrite(_PadRight(LastArea,40),YPos,20,7);
             END
             ELSE
             BEGIN
               WriteToBad('Area not found');
             END;
           END
           ELSE
           BEGIN
             WriteToBad('Uplink not defined on this system');
           END;
         END;
       UNTIL NOT(Status);
       rPktCloseUpPacket;
       WRITELN;
       WRITELN;
     END
     ELSE
     BEGIN
       bsWriteLog(' ! Unknown packet format: '+FName,False);
       RenameToBad(FName);
     END;
END;


END.
