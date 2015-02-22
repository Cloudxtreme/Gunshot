{$I DEFINES.INC}
UNIT QWKUL;


INTERFACE


PROCEDURE ULTossREPPacket;


IMPLEMENTATION


USES Globals,BsLog,UserFile,MFireUp,ToggMsg,FMode,BsString,BsTime,
     JamStore,Time,Dos,Archiver,Execute,Shotgun,MkFFile,BsFile;


FUNCTION RTSpace(InString: String): String;
VAR  Loop : Byte;
     Loc  : Byte;
BEGIN
     Loc := 0;
     FOR Loop := LENGTH(InString) DOWNTO 1 DO
     BEGIN
          IF ((InString[Loop]<>#32) AND (Loc=0)) THEN Loc := Loop;
     END;
     RTSpace := _Mid(InString,1,Loc);
END;


PROCEDURE TossQWK;
VAR  MsgText        : MessageTextLines;
     GotIt          : Boolean;
     Loop           : Word;
     Temp           : String;
     Code           : Integer;
     Loop2          : Word;
     OldArea        : _MessageArea_Record;
     HasWriteAccess : Boolean;
     DoesBaseExist  : Boolean;
     DoesDestExist  : Boolean;
     CanDestRead    : Boolean;
     IsNetMail      : Boolean;
     BytesRead      : Word;

     PROCEDURE LogErrors;
     BEGIN
          IF NOT(HasWriteAccess) THEN bsWriteLog('QWK UL - User doesn''t have access to '+MessageAreas.Area_Name,False);
          IF NOT(DoesBaseExist) THEN  bsWriteLog('QWK ID - '+_String(QWKHeaders.MSGConf)+' doesn''t exist',False);
          IF NOT(DoesDestExist) THEN  bsWriteLog('QWK UL - Recipient '+FastBaseHdr.MsgTo+' doesn''t exist',False);
          IF NOT(CanDestRead) THEN    bsWriteLog('QWK UL - Recipient '+FastBaseHdr.MsgTo+' can''t access ULed MSG',False);
          IF IsNetmail THEN           bsWriteLog('QWK UL - Area is a netmail area. QWK not allowed',False);
     END;

BEGIN
     New(QWKTextBuffer);
     Messages_Dat.Init(16384);
     bsWriteLog('Tossing REP packet: '+REPPacket,False);
     IF _FileExists(SCAN_Directory+'\'+_NoExtension(REPPacket)+'.MSG') THEN
     BEGIN
          Messages_Dat.OpenFile(SCAN_Directory+'\'+_NoExtension(REPPacket)+'.MSG',SetFileMode);
          {READ THE PACKET HEADER}
          Messages_Dat.BlkRead(QWKTextBuffer^[1],128,BytesRead);
          REPEAT
            {READ MESSAGE HEADER}
            Messages_Dat.BlkRead(QWKHeaders,128,BytesRead);
            IF (BytesRead<>0) THEN
            BEGIN
                {FIX THE CONFERENCE NUMBER}
                Temp := '';
                FOR Loop := 1 TO 6 DO Temp := Temp+QWKHeaders.MSGNumber[Loop];
                QWKHeaders.MSGConf := _Numeric(_RemoveSpaces(Temp));
                {FIND THE AREA}
                ASSIGN(FMessageArea,DATA_Directory+'\MA000000.DAT');
                RESET(FMessageArea);
                GotIt := False;
                REPEAT
                      READ(FMessageArea,MessageAreas);
                      IF MessageAreas.AreaID=QWKHeaders.MSGConf THEN GotIt := True;
                UNTIL ((GotIt) OR (EOF(FMessageArea)));
                CLOSE(FMessageArea);
                {CREATE THE HEADER}
                FastBaseHdr.MessageDate := _UnpackedDate(_ProperDateNoTime);
                FastBaseHdr.MsgTime     := Getting_Time;
                FastBaseHdr.MsgTo       := '';
                FastBaseHdr.MsgFrom     := '';
                FastBaseHdr.MsgSubject  := '';
                Temp                    := '';
                FOR Loop := 1 TO 25 DO
                    FastBaseHdr.MsgTo := FastBaseHdr.MsgTo+QWKHeaders.MsgTo[Loop];
                FOR Loop := 1 TO 25 DO
                    FastBaseHdr.MsgFrom := FastBaseHdr.MsgFrom+QWKHeaders.MsgFrom[Loop];
                FOR Loop := 1 TO 25 DO
                    FastBaseHdr.MsgSubject := FastBaseHdr.MsgSubject+QWKHeaders.MsgSubj[Loop];
                FOR Loop := 1 TO 6 DO
                    Temp := Temp+QWKHeaders.MsgNumText[Loop];
                FastBaseHdr.MsgTo   := RTSpace(FastBaseHdr.MsgTo);
                FastBaseHdr.MsgFrom := RTSpace(FastBaseHdr.MsgFrom);
                FastBaseHdr.MsgSubject := RTSpace(FastBaseHdr.MsgSubject);
                VAL(_RemoveSpaces(Temp),FastBaseHdr.NumberText,Code);
                DEC(FastBaseHdr.NumberText);
                {CREATE THE WRITE.$$$ FILE}
                ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
                REWRITE(FMsgText);
                MsgText.Line := '';
                FOR Loop := 1 TO FastBaseHdr.NumberText DO
                BEGIN
                     Messages_Dat.BlkRead(QWKTextBuffer^[1],128,BytesRead);
                     FOR Loop2 := 1 TO 128 DO
                     BEGIN
                          IF QWKTextBuffer^[Loop2]<>#227 THEN
                          BEGIN
                               MsgText.Line := MsgText.Line+QWKTextBuffer^[Loop2];
                          END
                          ELSE
                          BEGIN
                               WRITE(FMsgText,MsgText);
                               MsgText.Line := '';
                          END;
                     END;
                END;
                CLOSE(FMsgText);
                IF _UpperCase(FastBaseHdr.MsgTo)='SHOTGUN' THEN
                BEGIN
                     IF GotIt THEN
                     BEGIN
                          IF _UpperCase(FastBaseHdr.MsgSubject)='ADD' THEN
                          BEGIN
                               ToggleMsgArea(MessageAreas.AreaID,True);
                               bsWriteLog('Adding area through QWK: '+MessageAreas.Area_Name,False);
                          END
                          ELSE IF _UpperCase(FastBaseHdr.MsgSubject)='DROP' THEN
                          BEGIN
                               ToggleMsgArea(MessageAreas.AreaID,False);
                               bsWriteLog('Dropping area through QWK: '+MessageAreas.Area_Name,False);
                          END;
                     END;
                END
                ELSE
                BEGIN
                     IF _UpperCase(FastBaseHdr.MsgTo)='SYSOP' THEN
                     BEGIN
                          IF MessageAreas.Sysop<>'' THEN FastBaseHdr.MsgTo := MessageAreas.Sysop
                          ELSE
                          BEGIN
                               IF System_Info.Alias<>'' THEN
                               BEGIN
                                    IF MessageAreas.Msg_Type>1
                                       THEN FastBaseHdr.MsgTo := System_Info.Alias
                                       ELSE FastBaseHdr.MsgTo := System_Info.Sysop;
                               END
                               ELSE FastBaseHdr.MsgTo := System_Info.Sysop;
                          END;
                     END;
                     Use_Alias := false;
                     IF ((QWKHeaders.MSGStatus='+') OR (QWKHeaders.MSGStatus='*')) THEN
                     BEGIN
                          CASE MessageAreas.area_type OF
                          1,10,20 : FastBaseHdr.Priv := False;
                          ELSE      FastBaseHdr.Priv := True;
                          END;
                     END
                     ELSE
                     BEGIN
                          CASE MessageAreas.area_type OF
                          1,10,20 : FastBaseHdr.Priv := False;
                          2,11,21 : FastBaseHdr.Priv := True;
                          ELSE      FastBaseHdr.Priv := False;
                          END;
                     END;
                     HasWriteAccess := False;
                     DoesBaseExist  := False;
                     DoesDestExist  := True;
                     CanDestRead    := True;
                     IsNetMail      := False;
                     IF UserRecord.Security>=MessageAreas.write_access THEN HasWriteAccess := True;
                     IF (MessageAreas.area_type>19) THEN IsNetMail := True;
                     IF GotIt THEN DoesBaseExist := True;
                     IF FastBaseHdr.Priv THEN
                        GetUserInfo(FastBaseHdr.MsgTo,DoesDestExist,CanDestRead,MessageAreas.Read_Access);
                     IF ((NOT(IsNetMail)) AND (HasWriteAccess) AND (DoesBaseExist)
                        AND (DoesDestExist) AND (CanDestRead)) THEN
                     BEGIN
                          JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                          JamBase_StoreMessage(True);
                     END
                     ELSE
                     BEGIN
                          LogErrors;
                          IF (system_info.BadQWK<>'') THEN
                          BEGIN
                               _CreatePath(system_info.BadQWK);
                               OldArea := MessageAreas;
                               MessageAreas.area_name         := 'Missing QWK Files';
                               MessageAreas.sub               := 1;
                               MessageAreas.dos_name          := system_info.BadQWK;
                               MessageAreas.sysop             := '';
                               MessageAreas.base_type         := 3;
                               MessageAreas.read_access       := 0;
                               MessageAreas.write_access      := 0;
                               MessageAreas.area_type         := 1;
                               MessageAreas.msg_type          := 1;
                               MessageAreas.file_attaches     := 0;
                               MessageAreas.file_attaches_sec := 0;
                               MessageAreas.origin            := 1;
                               MessageAreas.address           := 1;
                               MessageAreas.nodelist          := '';
                               MessageAreas.DoGraphics        := 1;
                               MessageAreas.CleanLanguage     := 0;
                               MessageAreas.AreaID            := 0;
                               JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
                               JamBase_StoreMessage(True);
                               MessageAreas := OldArea;
                          END;
                     END;
                END;
            END;
          UNTIL BytesRead=0;
          Messages_Dat.CloseFile;
     END;
     Dispose(QWKTextBuffer);
     Messages_Dat.Done;
END;


PROCEDURE ULTossREPPacket;
VAR  DirInfo     : SearchRec;
     REPType     : String;
     GotArc      : Boolean;
     Loop        : Byte;
     CommandLine : String;
     IsOk        : Word;
BEGIN
     ChDir(SCAN_Directory);
     FindFirst(SCAN_Directory+'\*.REP',Anyfile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN
     BEGIN
          REPPacket := _UpperCase(DirInfo.Name);
          REPType   := _GetArcType(SCAN_Directory+'\'+REPPacket);
          GotArc    := False;
          ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
          RESET(FArcUtils);
          REPEAT
                READ(FArcUtils,ArcUtils);
                IF REPType=ArcUtils.Extension THEN GotArc := True;
          UNTIL ((EOF(FArcUtils)) OR (GotArc));
          CLOSE(FArcUtils);
          IF GotArc THEN
          BEGIN
               CommandLine := '';
               CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArcNoPath+' '+REPPacket;
               IsOk := RUN_PROGRAM(CommandLine);
               IF IsOk=0 THEN TossQWK;
          END;
     END;
     ChDir(Shotgun_Directory);
END;


END.