{$I DEFINES.INC}
UNIT Tossing;


INTERFACE


PROCEDURE TossInbound;


IMPLEMENTATION


USES Globals,Dos,DupeBase,BsFile,BsTime,BsString,Pkt,
     BsLog,Shotgun,BsExec,Crt,ApTimer,BsPkt;


FUNCTION TwoDigit(InVal: Word): String;
VAR  Temp : String;
BEGIN
     Temp := _String(InVal);
     IF LENGTH(Temp)=1 THEN Temp := '0'+Temp;
     TwoDigit := Temp;
END;


FUNCTION FancyFileDate(FName: String): String;
VAR  DT       : DateTime;
     Temp     : String;
BEGIN
     Temp := '';
     UnpackTime(_FileDate(FName),DT);
     WITH DT DO
     BEGIN
       CASE Month OF
       1:   Temp := Temp+'Jan ';
       2:   Temp := Temp+'Feb ';
       3:   Temp := Temp+'Mar ';
       4:   Temp := Temp+'Apr ';
       5:   Temp := Temp+'May ';
       6:   Temp := Temp+'Jun ';
       7:   Temp := Temp+'Jul ';
       8:   Temp := Temp+'Aug ';
       9:   Temp := Temp+'Sep ';
       10:  Temp := Temp+'Oct ';
       11:  Temp := Temp+'Nov ';
       12:  Temp := Temp+'Dec ';
       END;
       Temp := Temp+_String(Day)+', '+_String(Year)+' ';
       Temp := Temp+TwoDigit(Hour)+':'+TwoDigit(Min)+':'+TwoDigit(Sec);
     END;
     FancyFileDate := Temp;
END;


PROCEDURE DeArchive(FName: String);
VAR  Ext         : String[3];
     CommandLine : String;
     PPointer    : Word;
     Temp1       : String;
     Temp2       : String;
     FArcUtils   : File Of _Archiver_Utilities;
     ArcUtils    : _Archiver_Utilities;
BEGIN
     Ext := _GetArcType(FName);
     IF (Ext<>'') THEN
     BEGIN
       ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
       RESET(FArcUtils);
       REPEAT
         READ(FArcUtils,ArcUtils);
         IF Ext=ArcUtils.Extension THEN
         BEGIN
           CLOSE(FArcUtils);
           Temp1 := 'Unpacking '+FName+' ('+Ext+')';
           Temp2 := 'À['+FancyFileDate(FName)+']  File size: '+_String(_FileSize(FName))+' Bytes ';
           WRITELN(Temp1);
           WRITELN(Temp2);
           bsWriteLog(Temp1,False);
           bsWriteLog(Temp2,False);
           CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArcNoPath+' '+FName+' *.PKT >NUL';
           PPointer := DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwapMethod,TempOutbound);
           IF PPointer=0 THEN _EraseFile(FName);
           WRITELN;
           Exit;
         END;
       UNTIL EOF(FArcUtils);
       CLOSE(FArcUtils);
     END;
END;


PROCEDURE TossInbound;
VAR  Loop        : Word;
     i,j         : Word;
     TempFRecord : FFileRecord;
     DirInfo     : SearchRec;
     Temp        : String;
     Temp1       : String;
     Temp2       : String;
     FFile       : File;
     BytesRead   : Word;
     FExt        : String[3];
BEGIN
     NumPackets := 0;
     IF NumBundles=0 THEN Exit;
     {Open Our Dupe Records}
     OpenDupeFile;
     {Move/Dearc PKT,BAG & ARCMAIL Bundles}
     ChDir(TempUnpack);
     FOR Loop := 1 TO NumBundles DO
     BEGIN
       FExt := _GetFileExtension(FileNames[Loop].FName);
       IF FExt='PKT' THEN
       BEGIN
         Temp1 := 'Unpacking '+FileNames[Loop].FName+' (PKT)';
         Temp2 := 'À['+FancyFileDate(Mailer.Inbound+FileNames[Loop].FName)+
                  ']  File size: '+_String(_FileSize(Mailer.Inbound+FileNames[Loop].FName))+' Bytes ';
         WRITELN(Temp1);
         WRITELN(Temp2);
         bsWriteLog(Temp1,False);
         bsWriteLog(Temp2,False);
         _MoveFile(FileNames[Loop].FName,Mailer.Inbound,TempUnpack);
         WRITELN;
       END
       ELSE DeArchive(Mailer.Inbound+FileNames[Loop].FName);
     END;
     ChDir(BaseDirectory);
     {Get All The PKTs}
     FindFirst(TempUnpack+'\*.PKT',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
       INC(NumPackets);
       FileNames[NumPackets].FName := DirInfo.Name;
       FileNames[NumPackets].FDate := DirInfo.Time;
       FindNext(DirInfo);
     END;
     IF (NumPackets<>0) THEN
     BEGIN
       {Sort The Files To Date Order}
       FOR i := 1 TO NumPackets DO
       BEGIN
         FOR j := 1 TO NumPackets DO
         BEGIN
           IF (FileNames[i].FDate<FileNames[j].FDate) THEN
           BEGIN
             TempFRecord  := FileNames[i];
             FileNames[i] := FileNames[j];
             FileNames[j] := TempFRecord;
           END;
         END;
       END;
       ClrScr;
       NumMsgs := 0;
       NewTimerSecs(TossTimer,1440*60);
       {Do The Dirty}
       FOR Loop := 1 TO NumPackets DO
       BEGIN
         NumBytes := NumBytes+_FileSize(TempUnpack+'\'+FileNames[Loop].FName);
         TossThePkt(TempUnpack+'\'+FileNames[Loop].FName);
       END;
       Elapsed := ElapsedTimeInSecs(TossTimer);
       IF Elapsed=0 THEN Elapsed := 1;
       MsgsPerSecond := Round(NumMsgs/Elapsed);
     END;
     CloseDupeFile;
END;


END.
