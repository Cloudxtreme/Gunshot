{$I DEFINES.INC}
UNIT ULMsg;


INTERFACE


PROCEDURE UploadOneMessage(area: word);


IMPLEMENTATION


USES Globals,MiscStr,Screens,KeyInput,Dos,Upload,BsLog,BsFile,
     GotKeys,MsgParam,MFireUp,ExtDos,Sigs,JamStore,BsString;


PROCEDURE UploadOneMessage(area: word);
VAR  MsgText       : ARRAY[1..1] Of MessageTextLines;
     temp          : string;
     MessageGood   : Boolean;
     DirInfo       : SearchRec;
     uploaded_file : string;
     MessageFile   : Text;
     Counter       : Word;
BEGIN
     bsWriteLog('Uploading a text message',False);
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     reset(FMessageArea);
     Seek(FMessageArea,(area-1));
     read(FMessageArea,MessageAreas);
     close(FMessageArea);
     IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
        (MessageAreas.Area_Type<20) AND
        (UserRecord.Security>=MessageAreas.Write_Access)) THEN
     BEGIN
          FastBaseHdr.Priv := False;
          Use_Alias := False;
          {MESSAGE TO}
          System_Prompt('',138);
          Get_Enter;
          IF Fields^[1].Text='' THEN Exit;
          FastBaseHdr.MsgTo := Fields^[1].Text;
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
          {MESSAGE SUBJECT}
          System_Prompt('',139);
          Get_Enter;
          IF Fields^[1].Text='' THEN Exit;
          FastBaseHdr.MsgSubject := Fields^[1].Text;
          CASE MessageAreas.msg_type OF
          1  : BEGIN
                    Use_Alias := false;
               END;
          2  : BEGIN
                    IF UserRecord.alias<>'' THEN Use_Alias := True;
               END;
          3  : BEGIN
                    IF UserRecord.alias<>'' THEN
                    BEGIN
                         IF Write_Alias=True THEN Use_Alias := True
                                             ELSE Use_Alias := False;
                    END
                    ELSE
                    BEGIN
                         Use_Alias := False;
                    END;
               END;
          END;
          CASE MessageAreas.area_type OF
          1,10,20  : BEGIN
                          FastBaseHdr.Priv := false;
                     END;
          2,11,21  : BEGIN
                          FastBaseHdr.Priv := True;
                     END;
          3,12,22  : BEGIN
                          IF Write_Private=True THEN FastBaseHdr.Priv := True
                                                ELSE FastBaseHdr.Priv := False;
                     END;
          END;
          JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
          Clear_Scan_Dir;
          private_upload(SCAN_Directory);
          Uploaded_File := '';
          {SCAN_DIR}
          FindFirst(SCAN_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
          IF DosError=0 THEN uploaded_file := _UpperCase(DirInfo.Name);
          IF Uploaded_File<>'' THEN
          BEGIN
               ASSIGN(MessageFile,SCAN_Directory+'\'+Uploaded_File);
               {$I-}RESET(MessageFile);{$I+}
               IF IOResult=0 THEN
               BEGIN
                    MessageGood := True;
                    Counter     := 0;
                    REPEAT
                          READLN(MessageFile,Temp);
                          INC(Counter);
                          IF LENGTH(Temp)>80 THEN MessageGood := False;
                    UNTIL EOF(MessageFile);
                    CLOSE(MessageFile);
                    IF _FileSize(SCAN_Directory+'\'+Uploaded_File)>32000 THEN MessageGood := False;
                    IF MessageGood THEN
                    BEGIN
                         ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
                         ASSIGN(MessageFile,SCAN_Directory+'\'+Uploaded_File);
                         REWRITE(FMsgText);
                         RESET(MessageFile);
                         REPEAT
                               READLN(MessageFile,Temp);
                               MsgText[1].Line := _Mid(Temp,1,MaxMsgWidth);
                               WRITE(FMsgText,MsgText[1]);
                         UNTIL EOF(MessageFile);
                         CLOSE(FMsgText);
                         CLOSE(MessageFile);
                         IF Use_Alias THEN FastBaseHdr.MsgFrom := UserRecord.Alias
                                      ELSE FastBaseHdr.MsgFrom := UserRecord.Name;
                         GetUseOfSignature;
                         IF UseSignature THEN AddAnsiSig;
                         JamBase_StoreMessage(True);
                    END
                    ELSE
                    BEGIN
                         DisplayGraphicFile('MSGBAD',False,True,True);
                         Get_Enter;
                    END;
               END;
          END;
          Clear_Scan_Dir;
          Chdir(Gunshot_Directory);
     END
     ELSE
     BEGIN
          System_Prompt('',165);
          Get_Enter;
     END;
END;


END.
