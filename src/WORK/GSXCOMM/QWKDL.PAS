{$I DEFINES.INC}
UNIT QWKDL;


INTERFACE


PROCEDURE MakeQWKPacket(AreaType: String);


IMPLEMENTATION


USES Globals,Time,MiscStr,Screens,Toggle,ApTimer,KeyInput,ChangeMA,
     BsLog,TagArea,GotKeys,MFireUp,QWKMsgs,MsgHeadr,GetArc,Execute,
     Download,ExtDos,SBuffer,Version,BsString,BsFile,BsTime;


PROCEDURE RealToMsb(pReal : Real; Var b : bsingle);
VAR  r : Array[0 .. 5] Of Byte Absolute pReal;
BEGIN
     b[3] := r[0];
     move(r[3],b[0],3);
END;


FUNCTION MsbToReal(b : bsingle) : Real;
VAR  pReal : Real;
     r     : Array[0..5] Of Byte Absolute pReal;
BEGIN
     r[0] := b[3];
     r[1] := 0;
     r[2] := 0;
     move(b[0],r[3],3);
     MsbToReal := pReal;
END;


PROCEDURE StartControlDat;
BEGIN
     ASSIGN(Control_Dat,HOLD_Directory+'\CONTROL.TMP');
     REWRITE(Control_Dat);
     WRITELN(Control_Dat,system_info.QWKBBSId);
     WRITELN(Control_Dat,system_info.location);
     WRITELN(Control_Dat,system_info.QWKBBSPhone);
     WRITELN(Control_Dat,system_info.sysop);
     WRITELN(Control_Dat,'0,'+system_info.QWKPacketName);
     WRITELN(Control_Dat,_MMDDYYYY+','+LongToStringTime(GETTING_TIME)+':00');
     WRITELN(Control_Dat,_UpperCase(UserRecord.Name));
     WRITELN(Control_Dat,'');
     WRITELN(Control_Dat,'0');
     WRITELN(Control_Dat,'0');
END;


PROCEDURE EndControlDat;
BEGIN
     WRITELN(Control_Dat,'HELLO');
     WRITELN(Control_Dat,'NEWS');
     WRITELN(Control_Dat,'GOODBYE');
     WRITELN(Control_Dat,'0');
     CLOSE(Control_Dat);
END;


PROCEDURE WriteDoorId;
VAR  Door_Id : Text;
BEGIN
     ASSIGN(Door_Id,HOLD_Directory+'\DOOR.ID');
     REWRITE(Door_Id);
     WRITELN(Door_Id,'DOOR = Gunshot');
     WRITELN(Door_Id,'VERSION = '+GunshotVersion);
     WRITELN(Door_Id,'SYSTEM = Gunshot Professional');
     WRITELN(Door_Id,'CONTROLNAME = GUNSHOT');
     WRITELN(Door_Id,'CONTROLTYPE = ADD');
     WRITELN(Door_Id,'CONTROLTYPE = DROP');
     CLOSE(Door_Id);
END;


PROCEDURE StartMessagesDat;
VAR  Loop       : Word;
     Temp       : String;
BEGIN
     Temp := 'Produced by QMail...Copyright (c) 1987 by Sparkware.  All Rights Reserved';
     FillChar(QWKTextBuffer^[1],128,32);
     FOR Loop := 1 TO LENGTH(Temp) DO QWKTextBuffer^[Loop] := Temp[Loop];
     ASSIGN(Messages_Dat,HOLD_Directory+'\MESSAGES.DAT');
     REWRITE(Messages_Dat,1);
     BlockWrite(Messages_Dat,QWKTextBuffer^[1],128);
END;


PROCEDURE EndMessagesDat;
BEGIN
     CLOSE(Messages_Dat);
     IF _FileSize(HOLD_Directory+'\MESSAGES.DAT')=128 THEN Erase(Messages_Dat);
END;


PROCEDURE DoAreaUpdate;
BEGIN
     INC(QWKAreasFound);
     WRITELN(Control_Dat,MessageAreas.AreaId);
     WRITELN(Control_Dat,_Mid(MessageAreas.Area_Name,1,17));
END;


FUNCTION ZeroPad(InString: String): String;
VAR  Loop : Word;
     Work : Word;
BEGIN
     Work := _Numeric(InString);
     IF Work<1000 THEN
     BEGIN
          IF ((LENGTH(InString)<>3)) THEN InString := _Replicate('0',3-Length(InString))+InString;
     END;
     ZeroPad := InString;
END;


PROCEDURE CreateIndexes;
VAR  Count     : Real;
     Temp      : String;
     Loop      : Word;
     CName     : String;
     LName     : String;
     Code      : Integer;
BEGIN
     System_Prompt('',174);
     ASSIGN(Messages_Dat,HOLD_Directory+'\MESSAGES.DAT');
     RESET(Messages_Dat,1);
     {READ THE PACKET HEADER}
     StartToggle(Trunc(FileSize(Messages_Dat)/128)-1);
     BlockRead(Messages_Dat,QWKTextBuffer^[1],128);
     Count := 1;
     LName := '';
     REPEAT
           DoToggle;
           {READ MESSAGE HEADER}
           BlockRead(Messages_Dat,QWKHeaders,128);
           CName := ZeroPad(_String(QWKHeaders.MSGConf));
           Count := Count+1;
           IF LName<>CName THEN
           BEGIN
                IF LName<>'' THEN CLOSE(FQWKIndex);
                LName := CName;
                QWKIndex.Scrap := 0;
                RealToMsb(Count,QWKIndex.Mks);
                ASSIGN(FQWkIndex,HOLD_Directory+'\'+CName+'.NDX');
                REWRITE(FQWKIndex);
                WRITE(FQWKIndex,QWKIndex);
           END
           ELSE
           BEGIN
                QWKIndex.Scrap := 0;
                RealToMsb(Count,QWKIndex.Mks);
                WRITE(FQWKIndex,QWKIndex);
           END;
           Temp := '';
           FOR Loop := 1 TO 6 DO Temp := Temp+QWKHeaders.MsgNumText[Loop];
           VAL(_RemoveSpaces(Temp),FastBaseHdr.NumberText,Code);
           DEC(FastBaseHdr.NumberText);
           BlockRead(Messages_Dat,QWKTextBuffer^[1],128*FastBaseHdr.NumberText);
           FOR Loop := 1 TO FastBaseHdr.NumberText DO DoToggle;
           Count := Count+FastBaseHdr.NumberText;
     UNTIL EOF(Messages_Dat);
     CLOSE(Messages_Dat);
     CLOSE(FQWKIndex);
     EndToggle;
END;


PROCEDURE MakeQWKPacket(AreaType: String);
VAR  NewControl  : Text;
     Loop        : Word;
     Temp        : String;
     Temp2       : String;
     CommandLine : String;
     C           : Char;
     before      : Word;
     BeforeSub   : Word;
     Start_At    : Word;
     End_At      : Word;
     nml         : Word;
     TargetArc   : Word;
     PackedMsgs  : Word;
     Counter     : Word;
     QWKTimer    : EventTimer;
     Selected    : Word;
     BigCounter  : Word;
     SaveToggle  : Toggle_Info;
LABEL              QuitSearch,SkipIt;
BEGIN
     DisplayGraphicFile('SEARCHES',False,True,True);
     c := Get_Menu_Selection('CATSQ',#0);
     IF c='Q' THEN Exit;
     QWKAreasFound := 0;
     before        := CurrentMessageArea;
     beforesub     := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     bsWriteLog('Packing up QWK mail',True);
     PackedMsgs := 0;
     BigCounter := 0;
     New(QWKTextBuffer);
     WriteDoorId;
     StartControlDat;
     StartMessagesDat;
     System_Prompt('',175);
     ASSIGN(FQWKLastReads,NODE_Directory+'\QWKREAD.$$$');
     REWRITE(FQWKLastReads);
     NewTimerSecs(QWKTimer,1440*60);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     {$I-}
     RESET(FMessageArea);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          StartToggle(FileSize(FMessageArea));
          REPEAT
                READ(FMessageArea,MessageAreas);
                DoToggle;
                INC(BigCounter);
                CASE c OF
                'C': IF BigCounter<>Before THEN GOTO SkipIt;
                'T': IF NOT(IsMsgTagged(MessageAreas.AreaID)) THEN GOTO SkipIt;
                'S': IF BigCounter<>Selected THEN GOTO SkipIt;
                END;
                {CHECK FOR HAVING THE READ KEYS & IF THE AREA HAS AN ID}
                IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
                   (UserRecord.Security>=MessageAreas.Read_Access) AND
                   (MessageAreas.Area_Type<29) AND
                   (MessageAreas.AreaId<>0)) THEN
                BEGIN
                     DoAreaUpdate;
                     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                     Counter := 0;
                     end_at  := TotalMessages;
                     IF AreaType='ALLNEW' THEN
                     BEGIN
                          start_at := UserLastReadMSG+1;
                          IF ((start_at<end_at) AND (start_at<>0)) THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               SaveToggle := ToggleInfo;
                               EndToggle;
                               ClearBuffer;
                               AddToBuffer('@MESSAGEAREANAME',MessageAreas.Area_Name);
                               DisplayGraphicFile('QWKHDR',True,True,True);
                               StartToggle(End_At-Start_At+1);
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    DoToggle;
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF CanSee=true THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                         END;
                                    END;
                               END;
                               JamBase_CloseQWKBase;
                               EndToggle;
                               System_Prompt('',175);
                               ToggleInfo.Total   := SaveToggle.Total;
                               ToggleInfo.Current := SaveToggle.Current;
                               ToggleInfo.Percent := SaveToggle.Percent;
                               ToggleInfo.Active  := SaveToggle.Active;
                               RedrawToggle;
                          END;
                     END
                     ELSE IF AreaType='ALL' THEN
                     BEGIN
                          start_at := 1;
                          IF TotalMessages<>0 THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               SaveToggle := ToggleInfo;
                               EndToggle;
                               ClearBuffer;
                               AddToBuffer('@MESSAGEAREANAME',MessageAreas.Area_Name);
                               DisplayGraphicFile('QWKHDR',True,True,True);
                               StartToggle(End_At-Start_At+1);
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    DoToggle;
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF CanSee=true THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                         END;
                                    END;
                               END;
                               JamBase_CloseQWKBase;
                               EndToggle;
                               System_Prompt('',175);
                               ToggleInfo.Total   := SaveToggle.Total;
                               ToggleInfo.Current := SaveToggle.Current;
                               ToggleInfo.Percent := SaveToggle.Percent;
                               ToggleInfo.Active  := SaveToggle.Active;
                               RedrawToggle;
                          END;
                     END
                     ELSE IF ((AreaType='NEWPERSONAL') OR (AreaType='ALLPERSONAL')) THEN
                     BEGIN
                          IF AreaType='NEWPERSONAL'
                             THEN start_at := UserLastReadMSG+1
                             ELSE start_at := 1;
                          IF ((start_at<end_at) AND (start_at<>0)) THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               SaveToggle := ToggleInfo;
                               EndToggle;
                               ClearBuffer;
                               AddToBuffer('@MESSAGEAREANAME',MessageAreas.Area_Name);
                               DisplayGraphicFile('QWKHDR',True,True,True);
                               StartToggle(End_At-Start_At+1);
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    DoToggle;
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF ((IsYours=true) AND (FastBaseHdr.Recv=false)) THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                         END;
                                    END;
                               END;
                               JamBase_CloseQWKBase;
                               EndToggle;
                               System_Prompt('',175);
                               ToggleInfo.Total   := SaveToggle.Total;
                               ToggleInfo.Current := SaveToggle.Current;
                               ToggleInfo.Percent := SaveToggle.Percent;
                               ToggleInfo.Active  := SaveToggle.Active;
                               RedrawToggle;
                          END;
                     END;
                     IF CommLookAhead=#27 THEN GOTO QuitSearch;
                END;
                SkipIt:
          UNTIL ((EOF(FMessageArea)) OR (PackedMsgs>=UserAccess.QWKMessages));
          QuitSearch:
          CLOSE(FMessageArea);
          EndToggle;
     END;
     CLOSE(FQWKLastReads);
     EndControlDat;
     EndMessagesDat;
     IF _FileExists(HOLD_Directory+'\MESSAGES.DAT') THEN
     BEGIN
          ASSIGN(Control_Dat,HOLD_Directory+'\CONTROL.TMP');
          ASSIGN(NewControl,HOLD_Directory+'\CONTROL.DAT');
          REWRITE(NewControl);
          RESET(Control_Dat);
          FOR Loop := 1 TO 10 DO
          BEGIN
               READLN(Control_Dat,Temp);
               WRITELN(NewControl,Temp);
          END;
          WRITELN(NewControl,_String(QWKAreasFound-1));
          REPEAT
                READLN(Control_Dat,Temp);
                WRITELN(NewControl,Temp);
          UNTIL EOF(Control_Dat);
          CLOSE(NewControl);
          CLOSE(Control_Dat);
          ERASE(Control_Dat);
     END;
     Header2(BeforeSub,Before,True);
     IF _FileExists(HOLD_Directory+'\MESSAGES.DAT') THEN
     BEGIN
          CreateIndexes;
          bsWriteLog('Packed '+_String(PackedMsgs)+' messages in '+_String(ElapsedTimeInSecs(QWKTimer))+' seconds',True);
          IF (UserRecord.DefaultArchiver=0)
             THEN TargetArc := Select_Archiver
             ELSE TargetArc := UserRecord.DefaultArchiver;
          IF TargetArc<>0 THEN
          BEGIN
               IF (RunningMessageQWK<>0) THEN
               BEGIN
                    Temp2 := _String(RunningMessageQWK);
                    CASE Length(Temp2) OF
                    1:   Temp := '.QW'+Temp2;
                    2:   Temp := '.Q'+Temp2;
                    3:   Temp := '.'+Temp2;
                    ELSE Temp := '.QWK';
                    END;
               END
               ELSE Temp := '.QWK';
               System_Prompt(system_info.QWKPacketName+Temp,42);
               ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
               RESET(FArcUtils);
               SEEK(FArcUtils,TargetArc-1);
               READ(FArcUtils,ArcUtils);
               CLOSE(FArcUtils);
               CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+system_info.QWKPacketName+Temp+' *.*';
               ChDir(HOLD_Directory);
               RUN_PROGRAM(CommandLine);
               ChDir(Gunshot_Directory);
               dl_file(HOLD_Directory+'\'+system_info.QWKPacketName+Temp,False);
               IF NOT(AbortedProtocol) THEN
               BEGIN
                    INC(RunningMessageQWK);
                    System_Prompt('',168);
                    JamBase_UpdateQWKPointers;
                    IF system_info.Suspend_FList=1
                       THEN AdjustUsersTime(True,ElapsedTimeInSecs(QWKTimer));
               END;
          END;
     END;
     _EraseFile(NODE_Directory+'\QWKREAD.$$$');
     clear_hold_dir;
     Dispose(QWKTextBuffer);
END;


END.
