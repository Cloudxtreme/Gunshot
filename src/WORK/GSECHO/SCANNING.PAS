{$I DEFINES.INC}
UNIT Scanning;


INTERFACE


PROCEDURE DoScan;


IMPLEMENTATION


USES BsFile,Crt,BsVideo,Globals,BsString,MkOpen,
     BsLog,BsPkt,KeyCheck,Common,Gunshot,Pkt,_EchoTag;


PROCEDURE DoScan;
TYPE ETossRec    = RECORD
     Dos_Name    : String[50];
     END;
VAR  CurrentArea : Longint;
     LastPercent : Longint;
     TotalAreas  : Longint;
     Temp        : String;
     AreaType    : Char;
     MsgTo       : String[100];
     MsgFrom     : String[100];
     MsgSubject  : String[100];
     PktHeader   : PakdMessageHeadr;
     LLen        : Word;
     C           : Char;
     NoEchoToss  : Boolean;
     FEToss      : File Of ETossRec;
     EToss       : ETossRec;
     TFile       : Text;
     Work        : Word;
     DoThisOne   : Boolean;
     EchoTag     : _GSEchoDat_Record;
LABEL              SkipBy;

     PROCEDURE DoPercent;
     VAR  Percent : Longint;
     BEGIN
          Percent := Round((CurrentArea*100)/TotalAreas);
          IF Percent<>LastPercent THEN
          BEGIN
            LastPercent := Percent;
            Temp := _PadRight(_String(Percent),3);
            FastWrite(Temp,7,77,7);
          END;
     END;

     PROCEDURE BuildSeenBys;
     VAR  BytesRead : Word;
     BEGIN
          NumSeenBys := 1;
          FillChar(SeenBys,SizeOf(SeenBys),0);
          SeenBys[1].Net  := NetworkInfo.Net_Address.Net;
          SeenBys[1].Node := NetworkInfo.Net_Address.Node;
          OpenGSEchoDat;
          IF IsEchoTagFileOpen THEN
          BEGIN
            REPEAT
              FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
              IF (BytesRead<>0) THEN
              BEGIN
                IF EchoTag.AreaId=ScanMessageArea.AreaId THEN
                BEGIN
                  IF (EchoTag.Aka.Point=0) THEN
                  BEGIN
                    INC(NumSeenBys);
                    SeenBys[NumSeenBys].Net  := EchoTag.Aka.Net;
                    SeenBys[NumSeenBys].Node := EchoTag.Aka.Node;
                  END;
                END;
              END;
            UNTIL BytesRead=0;
          END;
     END;

     PROCEDURE DumpForExport;
     VAR  FFile     : File;
          BytesRead : Word;
     BEGIN
          PktHeader.OrigNet  := NetworkInfo.Net_Address.Net;
          PktHeader.OrigNode := NetworkInfo.Net_Address.Node;
          OpenGSEchoDat;
          IF IsEchoTagFileOpen THEN
          BEGIN
            REPEAT
              FEchoTag.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
              IF (BytesRead<>0) THEN
              BEGIN
                IF EchoTag.AreaId=ScanMessageArea.AreaId THEN
                BEGIN
                  IF LoadTheLink(EchoTag.Aka) THEN
                  BEGIN
                    INC(NumExported);
                    PktHeader.DestNet  := EchoTag.Aka.Net;
                    PktHeader.DestNode := EchoTag.Aka.Node;
                    ASSIGN(FFile,TempOutbound+'\'+System_Crc(EchoTag.Aka)+'.OUT');
                    RESET(FFile,1);
                    SEEK(FFile,FileSize(FFile));
                    BlockWrite(FFile,PktHeader,SizeOf(PktHeader));
                    BlockWrite(FFile,MsgTo[1],Ord(MsgTo[0]));
                    BlockWrite(FFile,MsgFrom[1],Ord(MsgFrom[0]));
                    BlockWrite(FFile,MsgSubject[1],Ord(MsgSubject[0]));
                    BlockWrite(FFile,MsgTextBuffer^[1],InBuffer);
                    CLOSE(FFile);
                  END;
                END;
              END;
            UNTIL BytesRead=0;
          END;
     END;

     FUNCTION ProcessDate(InDate: String): String;
     VAR  Day,Year : String[3];
          Month    : Word;
          MonthS   : String[3];
     BEGIN
          Month := _Numeric(_Mid(InDate,1,2));
          Day   := _Mid(InDate,4,5);
          Year  := _Mid(InDate,9,10);
          CASE Month OF
          1:   MonthS := 'Jan';
          2:   MonthS := 'Feb';
          3:   MonthS := 'Mar';
          4:   MonthS := 'Apr';
          5:   MonthS := 'May';
          6:   MonthS := 'Jun';
          7:   MonthS := 'Jul';
          8:   MonthS := 'Aug';
          9:   MonthS := 'Sep';
          10:  MonthS := 'Oct';
          11:  MonthS := 'Nov';
          12:  MonthS := 'Dec';
          END;
          ProcessDate := Day+' '+MonthS+' '+Year;
     END;

     PROCEDURE AddString(InString: String);
     BEGIN
          InString := InString+#13;
          LLen := Ord(InString[0]);
          Move(InString[1],MsgTextBuffer^[InBuffer+1],LLen);
          INC(InBuffer,LLen);
     END;

     PROCEDURE AddCharacter(InChar: Char);
     BEGIN
          INC(InBuffer);
          MsgTextBuffer^[InBuffer] := InChar;
     END;

     PROCEDURE FoldInSeenBys;
     VAR  Temp2   : String;
          Temp3   : String;
          LastNet : Word;
          Loop    : Word;
     BEGIN
          Temp2   := '';
          LastNet := 0;
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
              AddString('SEEN-BY:'+Temp2);
              Temp2 := ' '+_String(SeenBys[Loop].Net)+'/'+_String(SeenBys[Loop].Node);
            END
            ELSE Temp2 := Temp2+Temp3;
          END;
          IF (Temp2<>'') THEN AddString('SEEN-BY:'+Temp2);
     END;

BEGIN
     Window(1,6,80,25); ClrScr;
     Window(1,10,80,25); ClrScr;
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�',9,1,8);
     IF NOT(_FileExists(BaseDirectory+'\DATA\MA000000.DAT')) THEN Exit;
     IF NOT(_FileExists(BaseDirectory+'\DATA\GSECHO.DAT')) THEN Exit;
     FastWrite('%',7,76,7);
     FastWrite('Scanning:',7,2,7);
     FastWrite('Area Tag:',8,2,7);
     CurrentArea := 0;
     LastPercent := 999999;
     NoEchoToss  := True;
     IF UseEchoToss THEN
     BEGIN
       IF _FileExists(Mailer.Semaphores+'ECHOMAIL.BBS') THEN
       BEGIN
         ASSIGN(FEToss,BaseDirectory+'\ETOSSTMP.$$$');
         ASSIGN(TFile,Mailer.Semaphores+'ECHOMAIL.BBS');
         REWRITE(FEToss);
         RESET(TFile);
         REPEAT
           READLN(TFile,Temp);
           Work := Pos(' ',Temp);
           IF (Work<>0) THEN Temp[0] := Chr(Work-1);
           EToss.Dos_Name := Temp;
           WRITE(FEToss,EToss);
         UNTIL EOF(TFile);
         CLOSE(FEToss);
         CLOSE(TFile);
         ERASE(TFile);
         NoEchoToss := False;
         ASSIGN(FEToss,BaseDirectory+'\ETOSSTMP.$$$');
         RESET(FEToss);
       END;
     END;
     OpenGSEchoDat;
     ASSIGN(FScanMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FScanMessageArea);
     TotalAreas := FileSize(FScanMessageArea);
     REPEAT
       READ(FScanMessageArea,ScanMessageArea);
       INC(CurrentArea);
       DoPercent;
       IF ((ScanMessageArea.Area_Type>=10) AND (ScanMessageArea.Area_Type<=12) AND (ScanMessageArea.Area_Tag<>'')) THEN
       BEGIN
         FastWrite(_PadRight(ScanMessageArea.Area_Name,40),7,13,7);
         FastWrite(_PadRight(ScanMessageArea.Area_Tag,40),8,13,7);
         IF UseEchoToss THEN
         BEGIN
           IF NoEchoToss THEN GOTO SkipBy;
           DoThisOne := False;
           RESET(FEToss);
           REPEAT
             READ(FEToss,EToss);
             IF EToss.Dos_Name=ScanMessageArea.Dos_Name THEN DoThisOne := True;
           UNTIL ((EOF(FEToss)) OR (DoThisOne));
           IF NOT(DoThisOne) THEN GOTO SkipBy;
         END;
         CASE ScanMessageArea.Base_Type OF
         1:  AreaType := 'J';
         2:  AreaType := 'S';
         3:  AreaType := 'F';
         END;
         IF ScanMessageArea.MaxMsgs=0 THEN ScanMessageArea.MaxMsgs := 1000;
         IF OpenOrCreateMsgArea(ScanMsg,AreaType+ScanMessageArea.Dos_Name,ScanMessageArea.MaxMsgs) THEN
         BEGIN
           ScanMsg^.SeekFirst(1);
           IF NOT(ScanMsg^.SeekFound) THEN ScanMsg^.SeekNext;
           WHILE ScanMsg^.SeekFound DO
           BEGIN
             ScanMsg^.MsgStartUp;
             IF ((ScanMsg^.IsLocal) AND (NOT(ScanMsg^.IsSent))) THEN
             BEGIN
               GetNetAddress(ScanMessageArea.Address);
               INC(NumEchomails);
               Temp := 'Exporting msg #'+_String(ScanMsg^.GetMsgNum)+' from '+ScanMessageArea.Area_Tag;
               WRITELN(Temp);
               bsWriteLog(Temp,False);
               {Header Info}
               MsgTo      := ScanMsg^.GetTo+#0;
               MsgFrom    := ScanMsg^.GetFrom+#0;
               MsgSubject := ScanMsg^.GetSubj+#0;
               {Packed Message Header}
               FillChar(PktHeader,SizeOf(PktHeader),0);
               PktHeader.Signature := 2;
               Temp := ProcessDate(ScanMsg^.GetDate);
               Temp := Temp+'  '+ScanMsg^.GetTime+':00';
               Move(Temp[1],PktHeader.DateTime[1],19);
               InBuffer := 0;
               {Area Tag}
               AddString('AREA:'+ScanMessageArea.Area_Tag);
               {Our TID Line}
               AddString(#1+'TID: '+OurAppName);
               {Message Body}
               ScanMsg^.MsgTxtStartUp;
               WHILE NOT(ScanMsg^.EOM) DO
               BEGIN
                 C := ScanMsg^.GetChar;
                 IF ((C<>#0) AND (C<>#10)) THEN AddCharacter(C);
               END;
               {Add An Extra Cr If We Need One}
               IF (MsgTextBuffer^[InBuffer]<>#13) THEN AddCharacter(#13);
               {SEEN-BY: Everyone its going to, including me}
               BuildSeenBys;
               SortSeenBys;
               FoldInSeenBys;
               {^APATH  Just my AKA}
               AddString(#1+'PATH: '+Address2D(NetworkInfo.Net_Address));
               {Add A Terminating Null}
               AddCharacter(#0);
               {Export It}
               DumpForExport;
               ScanMsg^.SetSent(True);
               ScanMsg^.ReWriteHdr;
             END;
             ScanMsg^.SeekNext;
           END;
           CloseMsgArea(ScanMsg);
         END;
       END;
       SkipBy:
     UNTIL EOF(FScanMessageArea);
     CLOSE(FScanMessageArea);
     IF NOT(NoEchoToss) THEN
     BEGIN
       CLOSE(FEToss);
       _EraseFile(BaseDirectory+'\ETOSSTMP.$$$');
     END;
     Window(1,6,80,25); ClrScr;
     Window(1,7,80,25); ClrScr;
END;


END.
