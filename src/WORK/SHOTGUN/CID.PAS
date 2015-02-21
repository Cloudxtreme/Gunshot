{$I DEFINES.INC}
UNIT CID;


INTERFACE


PROCEDURE CheckCIDInfo;


IMPLEMENTATION


USES Globals,Shotgun,BsLog,ANSIMisc,AllGone,Screens,UserFile,BsString;


FUNCTION NoCanDo(UName,UNumber: String): Boolean;
VAR  LockoutRecord  : _Lockout_Record;
     FLockoutRecord : File Of _Lockout_Record;
BEGIN
     ASSIGN(FLockoutRecord,DATA_Directory+'\LOCKOUT.DAT');
     {$I-}RESET(FLockoutRecord);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FLockoutRecord,LockoutRecord);
                IF (_UpperCase(UName)=_UpperCase(LockoutRecord.PhoneName)) THEN
                BEGIN
                     CLOSE(FLockoutRecord);
                     NoCanDo := True;
                     Exit;
                END;
                IF (_UpperCase(UNumber)=_UpperCase(LockoutRecord.PhoneNumber)) THEN
                BEGIN
                     CLOSE(FLockoutRecord);
                     NoCanDo := True;
                     Exit;
                END;
          UNTIL EOF(FLockoutRecord);
          CLOSE(FLockoutRecord);
     END;
     NoCanDo := False;
END;


PROCEDURE CheckCIDInfo;
VAR  OldTBank : Longint;
     OldBBank : Longint;
BEGIN
     FillChar(CIDSemaphore,SizeOf(CIDSemaphore),0);
     ASSIGN(FCIDSemaphore,INTR_Directory+'\CIDDATA.'+_String(NodeNumber));
     {$I-}RESET(FCIDSemaphore);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FCIDSemaphore,CIDSemaphore);
          CLOSE(FCIDSemaphore);
          bsWriteLog('CID Name   - "'+CIDSemaphore.Name+'"',False);
          bsWriteLog('CID Number - "'+CIDSemaphore.Number+'"',False);
     END;
     IF CallerIdRecord.UseCID THEN
     BEGIN
          IF NoCanDo(CIDSemaphore.Name,CIDSemaphore.Number) THEN
          BEGIN
               bsWriteLog('User is not allowed on the system - CID lockout',False);
               SendCrLf(1);
               DisplayGraphicsFile('BOOTUSER',true,false,True,True,False);
               SendCrLf(1);
               dispatcher(5);
          END;
          IF CIDSemaphore.Number='' THEN
          BEGIN
               IF CallerIdRecord.AccessLevelForcing THEN
               BEGIN
                    bsWriteLog('No phone # present - forcing access level '+_String(CallerIdRecord.AccessLevelNoNumber),False);
                    OldBBank := UserRecord.ByteBankBalance;
                    OldTBank := UserRecord.SecondsInBank;
                    UpdateAccess(CallerIdRecord.AccessLevelNoNumber);
                    UserRecord.SecondsInBank   := OldTBank;
                    UserRecord.ByteBankBalance := OldBBank;
               END;
          END;
     END;
END;


END.
