{$I DEFINES.INC}
UNIT WriteMsg;


INTERFACE


PROCEDURE WriteMessage(sub,area: word; Reply: Boolean; ForcedTo: String);


IMPLEMENTATION


USES Globals,Dos,BsLog,MiscStr,MsgHeadr,ANSIMisc,GotKeys,MsgParam,Sigs,
     MFireUp,FullEdit,Time,Upload,JamStore,Screens,KeyInput,JamCC,
     BsTime,BsFile,BsString;


PROCEDURE WriteMessage(Sub,area: word; Reply: Boolean; ForcedTo: String);
VAR  MsgText      : MessageTextLines;
     temp         : string;
     MessageGood  : Boolean;
     DoingCC      : Boolean;
     DirInfo      : SearchRec;
     UploadedFile : string[12];
     CurrentFile  : Byte;
     FileNames    : Array[1..50] Of String[12];
     Loop         : Word;
     OldArea      : Word;
     OldSub       : Word;
BEGIN
     IF NOT(Reply) THEN ReplyDomain := '';
     bsWriteLog('Entering a message',False);
     OldArea := CurrentMessageArea;
     OldSub  := CurrentMessageSub;
     CurrentMessageArea := Area;
     CurrentMessageSub  := Sub;
     SendCrLf(1);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     reset(FMessageArea);
     Seek(FMessageArea,(area-1));
     read(FMessageArea,MessageAreas);
     close(FMessageArea);
     IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
        (UserRecord.Security>=MessageAreas.Write_Access)) THEN
     BEGIN
          FastBaseHdr.Priv := False;
          Use_Alias := False;
          CASE MessageAreas.msg_type OF
          1  : Use_Alias := false;
          2  : IF UserRecord.alias<>'' THEN Use_Alias := True;
          3  : BEGIN
                    IF UserRecord.alias<>'' THEN
                    BEGIN
                         IF Write_Alias=True THEN Use_Alias := True
                                             ELSE Use_Alias := False;
                    END
                    ELSE Use_Alias := False;
               END;
          END;
          CASE MessageAreas.area_type OF
          1,10,20,30 : FastBaseHdr.Priv := false;
          2,11,21,31 : FastBaseHdr.Priv := True;
          3,12,22,32 : BEGIN
                            IF Write_Private=True THEN FastBaseHdr.Priv := True
                                                  ELSE FastBaseHdr.Priv := False;
                       END;
          END;
          GetUseOfSignature;
          JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
          MessageGood := False;
          FastBaseHdr.MsgTo := ForcedTo;
          IF Use_Alias THEN FastBaseHdr.MsgFrom := UserRecord.Alias
                       ELSE FastBaseHdr.MsgFrom := UserRecord.Name;
          MessageGood := Full_Editor(Reply);
          FastBaseHdr.MessageDate := _UnpackedDate(_ProperDateNoTime);
          FastBaseHdr.MsgTime := Getting_Time;
          IF MessageGood=True THEN
          BEGIN
               {Get the file attaches}
               IF ((MessageAreas.Area_Type>=20) AND
                  (MessageAreas.Area_Type<=22) AND
                  (MessageAreas.file_attaches=1) AND
                  (UserRecord.Security>=MessageAreas.file_attaches_sec) AND
                  (Msg_File_Attach=True)) THEN
               BEGIN
                    SendCrLf(1);
                    _CreatePath(system_info.FileAttach);
                    private_upload(HOLD_Directory+'\');
                    {Gather in the files}
                    CurrentFile := 0;
                    FindFirst(HOLD_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
                    WHILE DosError = 0 DO
                    BEGIN
                         UploadedFile := _UpperCase(DirInfo.Name);
                         FindNext(DirInfo);
                         INC(CurrentFile);
                         FileNames[CurrentFile] := UploadedFile;
                    END;
                    IF CurrentFile=0 THEN Exit;
                    FOR Loop := 1 TO CurrentFile DO
                    BEGIN
                         Temp := _MoveFileSafe(FileNames[Loop],HOLD_Directory,system_info.FileAttach);
                         IF (Temp<>'') THEN
                         BEGIN
                              FastBaseHdr.MsgSubject := _UpperCase(system_info.FileAttach+Temp);
                              bsWriteLog('Attaching file to message: '+FastBaseHdr.MsgSubject,False);
                              IF Loop=1 THEN
                              BEGIN
                                   IF UseSignature THEN AddAnsiSig;
                                   JamBase_StoreMessage(False);
                                   _EraseFile(NODE_Directory+'\WRITE.$$$');
                              END
                              ELSE JamBase_StoreMessage(False);
                         END;
                    END;
               END
               ELSE
               BEGIN
                    IF UseSignature THEN AddAnsiSig;
                    JamBase_StoreMessage(True);
                    IF UserRecord.Security>=system_info.MessageCarbonCopy THEN
                    BEGIN
                         IF MessageAreas.Area_Type<30 THEN
                         BEGIN
                              DoingCC := False;
                              SendCrLf(1);
                              System_Prompt('',130,False,false);
                              IF Get_Yes_No=True THEN
                              BEGIN
                                   bsWriteLog('Carbon copying message',False);
                                   SendCrLf(2);
                                   System_Prompt('',131,True,false);
                                   REPEAT
                                         Get_Name(30,'',True,False);
                                         SendCrLf(1);
                                         IF Input_String<>'' THEN
                                         BEGIN
                                              DoingCC := True;
                                              CarbonCopy.UserName := Input_String;
                                              ASSIGN(FCarbonCopy,NODE_Directory+'\CC.DAT');
                                              {$I-}
                                              RESET(FCarbonCopy);
                                              {$I+}
                                              IF IOResult=0 THEN
                                              BEGIN
                                                   SEEK(FCarbonCopy,FileSize(FCarbonCopy));
                                                   WRITE(FCarbonCopy,CarbonCopy);
                                                   CLOSE(FCarbonCopy);
                                              END
                                              ELSE
                                              BEGIN
                                                   REWRITE(FCarbonCopy);
                                                   WRITE(FCarbonCopy,CarbonCopy);
                                                   CLOSE(FCarbonCopy);
                                              END;
                                         END;
                                   UNTIL Input_String='';
                                   IF DoingCC=True THEN JamBase_CarbonCopy;
                                   _EraseFile(NODE_Directory+'\CC.DAT');
                              END;
                         END;
                    END;
               END;
          END;
     END
     ELSE
     BEGIN
          SendCrLf(2);
          System_Prompt('',165,True,false);
          Get_Enter;
     END;
     Header2(OldSub,OldArea,True);
END;


END.