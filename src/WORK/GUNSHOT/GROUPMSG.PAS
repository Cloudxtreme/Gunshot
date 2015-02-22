{$I DEFINES.INC}
UNIT GroupMsg;


INTERFACE


PROCEDURE WriteGroupMessage(Sub,area: word);


IMPLEMENTATION


USES Globals,BsLog,MiscStr,MsgParam,MFireUp,Sigs,JamStore,GotKeys,FullEdit,
     Time,ANSIMisc,Screens,KeyInput,MsgHeadr,Commands,BsString,BsTime;


PROCEDURE WriteGroupMessage(Sub,area: word);
VAR  MsgText      : MessageTextLines;
     temp         : String;
     MessageGood  : Boolean;
     OldArea      : Word;
     OldSub       : Word;
     DestCriteria : Array[1..20] Of String[40];
     NumCriteria  : Byte;
     Work         : Word;
     Loop         : Word;
     FFrom        : Longint;
     TTo          : Longint;
     NumWritten   : Word;
     Checked      : Boolean;
LABEL               SkipIt,IsThere;
BEGIN
     bsWriteLog('Writing a group message to: '+Input_String,False);
     Input_String := _UpperCase(Input_String);
     NumCriteria := 0;
     REPEAT
           Work := Pos(' ',Input_String);
           IF Work<>0 THEN
           BEGIN
                INC(NumCriteria);
                DestCriteria[NumCriteria] := _Mid(Input_String,1,Work-1);
                Delete(Input_String,1,Work);
           END;
     UNTIL Work=0;
     INC(NumCriteria);
     DestCriteria[NumCriteria] := Input_String;
     OldArea := CurrentMessageArea;
     OldSub  := CurrentMessageSub;
     CurrentMessageArea := Area;
     CurrentMessageSub  := Sub;
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     reset(FMessageArea);
     Seek(FMessageArea,(area-1));
     read(FMessageArea,MessageAreas);
     close(FMessageArea);
     IF (MessageAreas.Area_Type>29) THEN
     BEGIN
          {Can't do this for UUCP messages}
     END
     ELSE IF ((GotTheKeys(UserRecord.Tags,MessageAreas.Tags)) AND
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
          1,10,20 : FastBaseHdr.Priv := false;
          2,11,21 : FastBaseHdr.Priv := True;
          3,12,22 : BEGIN
                         IF Write_Private=True THEN FastBaseHdr.Priv := True
                                               ELSE FastBaseHdr.Priv := False;
                    END;
          END;
          GetUseOfSignature;
          JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
          MessageGood := False;
          FastBaseHdr.MsgTo := 'CONFERENCE MAIL';
          IF Use_Alias THEN FastBaseHdr.MsgFrom := UserRecord.Alias
                       ELSE FastBaseHdr.MsgFrom := UserRecord.Name;
          MessageGood := Full_Editor(False);
          FastBaseHdr.MessageDate := _UnpackedDate(_ProperDateNoTime);
          FastBaseHdr.MsgTime := Getting_Time;
          IF MessageGood=True THEN
          BEGIN
               NumWritten := 0;
               IF UseSignature THEN AddAnsiSig;
               New(UserRecord2);
               ASSIGN(FUserRecord,DATA_Directory+'\USERS.BBS');
               RESET(FUserRecord);
               READ(FUserRecord,UserRecord2^);
               REPEAT
                     READ(FUserRecord,UserRecord2^);
                     FOR Loop := 1 TO NumCriteria DO
                     BEGIN
                          Checked := False;
                          {Check For Subscribers}
                          IF Pos('SUBSCRIBERS',DestCriteria[Loop])<>0 THEN
                          BEGIN
                               IF UserRecord2^.Expiry_Adjust=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check For Sysops}
                          IF Pos('SYSOPS',DestCriteria[Loop])<>0 THEN
                          BEGIN
                               IF UserRecord2^.BBS_Phone='' THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check For Female}
                          IF DestCriteria[Loop]=_UpperCase(GetCommandString('MISC',4)) THEN
                          BEGIN
                               IF UserRecord2^.Sex=1 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check For Male}
                          IF DestCriteria[Loop]=_UpperCase(GetCommandString('MISC',3)) THEN
                          BEGIN
                               IF UserRecord2^.Sex=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check For Security}
                          IF Pos('SEC',DestCriteria[Loop])<>0 THEN
                          BEGIN
                               Temp := DestCriteria[Loop];
                               Delete(Temp,1,3);
                               Work := Pos('-',Temp);
                               IF Work<>0 THEN
                               BEGIN
                                    FFrom := _Numeric(_Mid(Temp,1,Work-1));
                                    Delete(Temp,1,Work);
                                    TTo := _Numeric(Temp);
                                    IF ((UserRecord2^.Security<FFrom) OR (UserRecord2^.Security>TTo)) THEN GOTO SkipIt;
                               END;
                               Checked := True;
                          END;
                          {Check Tag 1}
                          IF DestCriteria[Loop]='TAG1' THEN
                          BEGIN
                               IF UserRecord2^.Tags[1]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 2}
                          IF DestCriteria[Loop]='TAG2' THEN
                          BEGIN
                               IF UserRecord2^.Tags[2]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 3}
                          IF DestCriteria[Loop]='TAG3' THEN
                          BEGIN
                               IF UserRecord2^.Tags[3]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 4}
                          IF DestCriteria[Loop]='TAG4' THEN
                          BEGIN
                               IF UserRecord2^.Tags[4]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 5}
                          IF DestCriteria[Loop]='TAG5' THEN
                          BEGIN
                               IF UserRecord2^.Tags[5]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 6}
                          IF DestCriteria[Loop]='TAG6' THEN
                          BEGIN
                               IF UserRecord2^.Tags[6]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 7}
                          IF DestCriteria[Loop]='TAG7' THEN
                          BEGIN
                               IF UserRecord2^.Tags[7]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 8}
                          IF DestCriteria[Loop]='TAG8' THEN
                          BEGIN
                               IF UserRecord2^.Tags[8]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 9}
                          IF DestCriteria[Loop]='TAG9' THEN
                          BEGIN
                               IF UserRecord2^.Tags[9]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          {Check Tag 10}
                          IF DestCriteria[Loop]='TAG10' THEN
                          BEGIN
                               IF UserRecord2^.Tags[10]=0 THEN GOTO SkipIt;
                               Checked := True;
                          END;
                          IF NOT(Checked) THEN
                          BEGIN
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.Name))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.Alias))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.City))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.Prov))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.Country))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.BBS))<>0 THEN GOTO IsThere;
                               IF Pos(DestCriteria[Loop],_UpperCase(UserRecord2^.Note))<>0 THEN GOTO IsThere;
                               GOTO SkipIt;
                               IsThere:
                          END;
                     END;
                     CASE MessageAreas.msg_type OF
                     1    : FastBaseHdr.MsgTo := UserRecord2^.Name;
                     2,3  : IF UserRecord2^.Alias<>''
                               THEN FastBaseHdr.MsgTo := UserRecord2^.Alias
                               ELSE FastBaseHdr.MsgTo := UserRecord2^.Name;
                     END;
                     JamBase_StoreMessage(False);
                     INC(NumWritten);
                     SkipIt:
               UNTIL EOF(FUserRecord);
               CLOSE(FUserRecord);
               Dispose(UserRecord2);
               SendCrLf(1);
               System_Prompt(_String(NumWritten),166,True,false);
               Get_Enter;
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
