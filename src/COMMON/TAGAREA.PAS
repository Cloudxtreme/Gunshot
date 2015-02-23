{$I DEFINES.INC}
UNIT TagArea;


INTERFACE


FUNCTION IsMsgTagged  (SearchFile: Word) : Boolean;
FUNCTION IsFileTagged (SearchFile: Word) : Boolean;


IMPLEMENTATION


USES ErrorLog,Globals,Gunshot,BsFile,BsString;


PROCEDURE PadOutMsg;
VAR  FMsgArea3  : File Of _MessageArea_Record;
     MsgAreas3  : _MessageArea_Record;
     HighestOne : Word;
     FFile      : File;
     Scrap      : Array[1..1024] Of Byte;
     TheSize    : Longint;
     Needed     : Longint;
     Loop       : Longint;
BEGIN
     HighestOne := 0;
     ASSIGN(FMsgArea3,DATA_Directory+'\MA000000.DAT');
     RESET(FMsgArea3);
     REPEAT
       READ(FMsgArea3,MsgAreas3);
       IF MsgAreas3.AreaID>HighestOne THEN HighestOne := MsgAreas3.AreaID;
     UNTIL EOF(FMsgArea3);
     CLOSE(FMsgArea3);
     TheSize := _FileSize(Gunshot_Directory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
     IF (TheSize<HighestOne) THEN
     BEGIN
       FillChar(Scrap,SizeOf(Scrap),0);
       Needed := Trunc((HighestOne-TheSize+1)/1024)+1;
       ASSIGN(FFile,Gunshot_Directory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
       {$I-}RESET(FFile,1);{$I+}
       IF (IOResult<>0) THEN REWRITE(FFile,1);
       SEEK(FFile,FileSize(FFile));
       FOR Loop := 1 TO Needed DO BLOCKWRITE(FFile,Scrap,SizeOf(Scrap));
       CLOSE(FFile);
     END;
END;


PROCEDURE PadOutFile;
VAR  FFileArea3 : File Of _FileArea_Record;
     FileAreas3 : _FileArea_Record;
     HighestOne : Word;
     FFile      : File;
     Scrap      : Array[1..1024] Of Byte;
     TheSize    : Longint;
     Needed     : Longint;
     Loop       : Longint;
BEGIN
     HighestOne := 0;
     ASSIGN(FFileArea3,DATA_Directory+'\FA000000.DAT');
     RESET(FFileArea3);
     REPEAT
       READ(FFileArea3,FileAreas3);
       IF FileAreas3.AreaID>HighestOne THEN HighestOne := FileAreas3.AreaID;
     UNTIL EOF(FFileArea3);
     CLOSE(FFileArea3);
     TheSize := _FileSize(Gunshot_Directory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
     IF (TheSize<HighestOne) THEN
     BEGIN
       FillChar(Scrap,SizeOf(Scrap),0);
       Needed := Trunc((HighestOne-TheSize+1)/1024)+1;
       ASSIGN(FFile,Gunshot_Directory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
       {$I-}RESET(FFile,1);{$I+}
       IF (IOResult<>0) THEN REWRITE(FFile,1);
       SEEK(FFile,FileSize(FFile));
       FOR Loop := 1 TO Needed DO BLOCKWRITE(FFile,Scrap,SizeOf(Scrap));
       CLOSE(FFile);
     END;
END;


FUNCTION IsMsgTagged(SearchFile: Word): Boolean;
VAR  FFile  : File;
     Tagged : Boolean;
     Loop   : Word;
     FSize  : Longint;
BEGIN
     Tagged := False;
     IF SearchFile=0 THEN
     BEGIN
       DoErrorLog(32,'');
       IsMsgTagged := False;
       Exit;
     END;
     FSize := _FileSize(Gunshot_Directory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
     IF (FSize>=SearchFile) THEN
     BEGIN
       ASSIGN(FFile,Gunshot_Directory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
       RESET(FFile,1);
       SEEK(FFile,SearchFile-1);
       BLOCKREAD(FFile,Tagged,1);
       CLOSE(FFile);
       IsMsgTagged := Tagged;
     END
     ELSE
     BEGIN
       PadOutMsg;
       IsMsgTagged := False;
     END;
END;


FUNCTION IsFileTagged(SearchFile: Word): Boolean;
VAR  FFile  : File;
     Tagged : Boolean;
     Loop   : Word;
     FSize  : Longint;
BEGIN
     IF SearchFile=0 THEN
     BEGIN
       DoErrorLog(33,'');
       IsFileTagged := False;
       Exit;
     END;
     FSize := _FileSize(Gunshot_Directory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
     IF (FSize>=SearchFile) THEN
     BEGIN
       ASSIGN(FFile,Gunshot_Directory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
       RESET(FFile,1);
       SEEK(FFile,SearchFile-1);
       BLOCKREAD(FFile,Tagged,1);
       CLOSE(FFile);
       IsFileTagged := Tagged;
     END
     ELSE
     BEGIN
       PadOutFile;
       IsFileTagged := False;
     END;
END;


END.