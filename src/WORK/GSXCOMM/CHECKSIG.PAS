{$I DEFINES.INC}
UNIT CheckSig;


INTERFACE


FUNCTION ValidateSignature: Byte;


IMPLEMENTATION


USES Dos,Globals,ExtDos,BsLog,BsString,BsFile;


FUNCTION ValidateSignature: Byte; {0-ABORTED, 1-OK, 2-INVALID}
VAR  DirInfo       : SearchRec;
     UploadedFile  : String;
     AnsiFile      : Text;
     Temp          : String;
     Counter       : Word;
BEGIN
     UploadedFile := '';
     FindFirst(SCAN_Directory+'\*.SIG',Anyfile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN UploadedFile := _UpperCase(DirInfo.Name);
     Counter := 0;
     IF UploadedFile<>'' THEN
     BEGIN
          bsWriteLog('Validating signature file',True);
          ASSIGN(ANSIFile,SCAN_Directory+'\'+UploadedFile);
          RESET(ANSIFile);
          REPEAT
                IF NOT(EOF(ANSIFile)) THEN
                BEGIN
                     READLN(ANSIFile,Temp);
                     INC(Counter);
                     IF LENGTH(Temp)>80 THEN UploadedFile := '';
                END;
          UNTIL EOF(ANSIFile);
          CLOSE(ANSIFile);
          IF ((Counter=0) OR (Counter>5)) THEN UploadedFile := '';
          IF UploadedFile<>'' THEN
          BEGIN
               ASSIGN(ANSIFile,SCAN_Directory+'\'+UploadedFile);
               {$I-}
               RENAME(ANSIFile,SCAN_Directory+'\'+_String(UserRecord.User_Number)+'.SIG');
               {$I+}
               IF IOResult=0 THEN;
               _MoveFile(_String(UserRecord.User_Number)+'.SIG',SCAN_Directory,SIG_Directory);
               Clear_Scan_Dir;
               bsWriteLog('Signature is a valid signature',True);
               ValidateSignature := 1;
          END
          ELSE
          BEGIN
               Clear_Scan_Dir;
               bsWriteLog('Signature is an invalid signature',True);
               ValidateSignature := 2;
          END;
     END
     ELSE
     BEGIN
          Clear_Scan_Dir;
          bsWriteLog('Signature is an invalid signature',True);
          ValidateSignature := 0;
     END;
END;


END.