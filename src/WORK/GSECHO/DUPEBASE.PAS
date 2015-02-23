{$I DEFINES.INC}
UNIT DupeBase;


INTERFACE


PROCEDURE OpenDupeFile;
PROCEDURE CloseDupeFile;
FUNCTION  IsADupe(TheMsgId: Longint; msgAreaId: Word): Boolean;


IMPLEMENTATION


USES Globals,BsFile;


PROCEDURE OpenDupeFile;
VAR  FFile     : File;
     BytesRead : Word;
BEGIN
     New(Dupes);
     FillChar(Dupes^,SizeOf(Dupes^),0);
     IF _FileExists(BaseDirectory+'\DATA\GSECHO.DUP') THEN
     BEGIN
          ASSIGN(FFile,BaseDirectory+'\DATA\GSECHO.DUP');
          RESET(FFile,1);
          BLOCKREAD(FFile,Dupes^,SizeOf(Dupes^),BytesRead);
          CLOSE(FFile);
     END;
END;


PROCEDURE CloseDupeFile;
VAR  FFile : File;
BEGIN
     ASSIGN(FFile,BaseDirectory+'\DATA\GSECHO.DUP');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,Dupes^,SizeOf(Dupes^));
     CLOSE(FFile);
     Dispose(Dupes);
END;


FUNCTION IsADupe(TheMsgId: Longint; msgAreaId: Word): Boolean;
VAR  Loop  : Word;
BEGIN
     IF ((TheMsgId=0) OR (NOT(CheckDupes))) THEN
     BEGIN
          IsADupe := False;
          Exit;
     END;
     FOR Loop := 1 TO Dupes^[0].MsgId DO
     BEGIN
       IF ((Dupes^[Loop].MsgId=TheMsgId) AND (Dupes^[Loop].AreaId=msgAreaId)) THEN
       BEGIN
         IsADupe := True;
         Exit;
       END;
     END;
     IF Dupes^[0].MsgId>=5000 THEN
     BEGIN
          Dupes^[0].MsgId := 5000;
          Move(Dupes^[2],Dupes^[1],29994);
          Dupes^[5000].MsgId  := TheMsgId;
          Dupes^[5000].AreaId := msgAreaId;
     END
     ELSE
     BEGIN
          INC(Dupes^[0].MsgId);
          Loop := Dupes^[0].MsgId;
          Dupes^[Loop].MsgId  := TheMsgId;
          Dupes^[Loop].AreaId := msgAreaId;
     END;
     IsADupe := False;
END;


END.