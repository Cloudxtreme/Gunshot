{$I DEFINES.INC}
UNIT QWKDL;


INTERFACE


PROCEDURE MakeQWKPacket(AreaType: String);


IMPLEMENTATION


USES Globals,Time,MiscStr,ANSIMisc,Screens,Toggle,ApTimer,KeyInput,
     ChangeMA,BsLog,TagArea,GotKeys,MFireUp,QWKMsgs,MsgHeadr,GetArc,
     Execute,Download,ExtDos,Version,MkFFile,FMode,BsString,BsFile,
     BsTime;


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
     WRITELN(Door_Id,'DOOR = Shotgun');
     WRITELN(Door_Id,'VERSION = '+ShotgunVersion);
     WRITELN(Door_Id,'SYSTEM = Shotgun Professional');
     WRITELN(Door_Id,'CONTROLNAME = SHOTGUN');
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
     Messages_Dat.Init(16384);
     Messages_Dat.OpenFile(HOLD_Directory+'\MESSAGES.DAT',SetFileMode);
     Messages_Dat.BlkWrite(QWKTextBuffer^[1],128);
END;


PROCEDURE EndMessagesDat;
BEGIN
     Messages_Dat.CloseFile;
     Messages_Dat.Done;
     IF _FileSize(HOLD_Directory+'\MESSAGES.DAT')=128
        THEN _EraseFile(HOLD_Directory+'\MESSAGES.DAT');
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
     BytesRead : Word;
BEGIN
     System_Prompt('',174,False,true);
     Fore(Colours.SpinCursor);
     StartToggle(0);
     Messages_Dat.Init(16384);
     Messages_Dat.OpenFile(HOLD_Directory+'\MESSAGES.DAT',SetFileMode);
     {READ THE PACKET HEADER}
     Messages_Dat.BlkRead(QWKTextBuffer^[1],128,BytesRead);
     Count := 1;
     LName := '';
     REPEAT
       {READ MESSAGE HEADER}
       Messages_Dat.BlkRead(QWKHeaders,128,BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
           CName := ZeroPad(_String(QWKHeaders.MSGConf));
           Count := Count+1;
           IF LName<>CName THEN
           BEGIN
                DoToggle;
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
           Messages_Dat.BlkRead(QWKTextBuffer^[1],128*FastBaseHdr.NumberText,BytesRead);
           Count := Count+FastBaseHdr.NumberText;
       END;
     UNTIL BytesRead=0;
     Messages_Dat.CloseFile;
     Messages_Dat.Done;
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
LABEL              QuitSearch,SkipIt;
BEGIN
     SendCrLf(2);
     DisplayGraphicsFile('SEARCHES',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,true);
     c := Get_Menu_Selection('CATSQ',#0);
     SendCrLf(1);
     IF c='Q' THEN Exit;
     QWKAreasFound := 0;
     before        := CurrentMessageArea;
     beforesub     := CurrentMessageSub;
     IF c='S' THEN
     BEGIN
          IF NOT(ChangeMessageArea) THEN Exit;
          Selected := CurrentMessageArea;
     END;
     bsWriteLog('Packing up QWK mail',False);
     PackedMsgs := 0;
     BigCounter := 0;
     New(QWKTextBuffer);
     WriteDoorId;
     StartControlDat;
     StartMessagesDat;
     ASSIGN(FQWKLastReads,NODE_Directory+'\QWKREAD.$$$');
     REWRITE(FQWKLastReads);
     SendCrLf(1);
     System_Prompt('',175,False,false);
     SendCrLf(2);
     DisplayGraphicsFile('QWKHDR',True,False,False,True,True);
     NewTimerSecs(QWKTimer,1440*60);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     {$I-}
     RESET(FMessageArea);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FMessageArea,MessageAreas);
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
                     WRITEANSI('  '+_PadRight(MessageAreas.Area_Name,42),False,False);
                     WRITEANSI(_PadRight(_String(TotalMessages),8),False,False);
                     Counter := 0;
                     WRITEANSI(_PadRight(_String(Counter),8),False,False);
                     end_at  := TotalMessages;
                     IF AreaType='ALLNEW' THEN
                     BEGIN
                          start_at := UserLastReadMSG+1;
                          IF ((start_at<end_at) AND (start_at<>0)) THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF CanSee=true THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                              IF nml=end_at THEN Temp := '0'
                                                            ELSE Str(nml,Temp);
                                              IF Temp[Length(Temp)]='0' THEN
                                                 WRITEANSI(#8#8#8#8#8#8#8#8+_PadRight(_String(nml),8),False,False);
                                         END;
                                    END;
                               END;
                               WRITEANSI(_String(Counter),True,False);
                               JamBase_CloseQWKBase;
                          END
                          ELSE WRITEANSI('0',True,False);
                     END
                     ELSE IF AreaType='ALL' THEN
                     BEGIN
                          start_at := 1;
                          IF TotalMessages<>0 THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF CanSee=true THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                              IF nml=end_at THEN Temp := '0'
                                                            ELSE Str(nml,Temp);
                                              IF Temp[Length(Temp)]='0' THEN
                                                 WRITEANSI(#8#8#8#8#8#8#8#8+_PadRight(_String(nml),8),False,False);
                                         END;
                                    END;
                               END;
                               WRITEANSI(_String(Counter),True,False);
                               JamBase_CloseQWKBase;
                          END
                          ELSE WRITEANSI('0',True,False);
                     END
                     ELSE IF ((AreaType='NEWPERSONAL') OR (AreaType='ALLPERSONAL')) THEN
                     BEGIN
                          IF AreaType='NEWPERSONAL'
                             THEN start_at := UserLastReadMSG+1
                             ELSE start_at := 1;
                          IF ((start_at<end_at) AND (start_at<>0)) THEN
                          BEGIN
                               JamBase_OpenQWKBase;
                               FOR nml := start_at TO end_at DO
                               BEGIN
                                    IF PackedMsgs<UserAccess.QWKMessages THEN
                                    BEGIN
                                         IF nml=start_at THEN JamBase_QWKMessageHeaderFirst(nml)
                                                         ELSE JamBase_QWKMessageHeaderNext(nml);
                                         IF ((IsYours=true) AND (FastBaseHdr.Recv=false)) THEN
                                         BEGIN
                                              JamBase_QWKMessage(nml);
                                              INC(PackedMsgs);
                                              INC(Counter);
                                              IF nml=end_at THEN Temp := '0'
                                                            ELSE Str(nml,Temp);
                                              IF Temp[Length(Temp)]='0' THEN
                                                 WRITEANSI(#8#8#8#8#8#8#8#8+_PadRight(_String(nml),8),False,False);
                                         END;
                                    END;
                               END;
                               WRITEANSI(_String(Counter),True,False);
                               JamBase_CloseQWKBase;
                          END
                          ELSE WRITEANSI('0',True,False);
                     END;
                     IF CommLookAhead=#27 THEN GOTO QuitSearch;
                END;
                SkipIt:
          UNTIL ((EOF(FMessageArea)) OR (PackedMsgs>=UserAccess.QWKMessages));
          QuitSearch:
          CLOSE(FMessageArea);
     END;
     CLOSE(FQWKLastReads);
     DisplayGraphicsFile('QWKFTR',True,False,False,True,True);
     System_Prompt(_String(PackedMsgs),161,True,false);
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
     SendCrLf(1);
     IF _FileExists(HOLD_Directory+'\MESSAGES.DAT') THEN
     BEGIN
          CreateIndexes;
          bsWriteLog('Packed '+_String(PackedMsgs)+' messages in '+_String(ElapsedTimeInSecs(QWKTimer))+' seconds',False);
          SendCrLf(1);
          IF (UserRecord.DefaultArchiver=0)
             THEN TargetArc := Select_Archiver
             ELSE TargetArc := UserRecord.DefaultArchiver;
          SendCrLf(1);
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
               SendCrLf(1);
               System_Prompt(system_info.QWKPacketName+Temp,42,False,false);
               ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
               RESET(FArcUtils);
               SEEK(FArcUtils,TargetArc-1);
               READ(FArcUtils,ArcUtils);
               CLOSE(FArcUtils);
               CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+system_info.QWKPacketName+Temp+' *.*';
               ChDir(HOLD_Directory);
               RUN_PROGRAM(CommandLine);
               ChDir(Shotgun_Directory);
               SendCrLf(1);
               dl_file(HOLD_Directory+'\'+system_info.QWKPacketName+Temp);
               IF NOT(AbortedProtocol) THEN
               BEGIN
                    INC(RunningMessageQWK);
                    SendCrLf(1);
                    System_Prompt('',168,False,true);
                    Fore(Colours.SpinCursor);
                    JamBase_UpdateQWKPointers;
                    IF system_info.Suspend_FList=1
                       THEN AdjustUsersTime(True,ElapsedTimeInSecs(QWKTimer));
                    SendCrLf(1);
               END;
          END;
     END;
     _EraseFile(NODE_Directory+'\QWKREAD.$$$');
     clear_hold_dir;
     Dispose(QWKTextBuffer);
END;


END.
