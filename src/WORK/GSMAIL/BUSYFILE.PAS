{$I DEFINES.INC}
UNIT BusyFile;


INTERFACE


USES Shotgun;


VAR LastBusyFiles : Array[1..100] Of String[12];
    NumBusy       : Byte;


PROCEDURE _KillBusy;
PROCEDURE _ClearOurBusyFiles;
PROCEDURE _NodeBusy   (InAddress: AddrType);
FUNCTION  _NodeIsBusy (InAddress: AddrType) : Boolean;


IMPLEMENTATION


USES BsFile,Globals,Transfer,BsMulti,Dos;


PROCEDURE _KillBusy;
VAR  Loop : Byte;
BEGIN
     FOR Loop := 1 TO NumBusy DO
     BEGIN
          IF (LastBusyFiles[Loop]<>'') THEN _EraseFile(MailerInfo.Semaphores+LastBusyFiles[Loop]);
     END;
     FillChar(LastBusyFiles,SizeOf(LastBusyFiles),0);
     NumBusy := 0;
END;


PROCEDURE _NodeBusy(InAddress: AddrType);
VAR  FFile : File;
     Work  : Word;
BEGIN
     INC(NumBusy);
     LastBusyFiles[NumBusy] := HexSystem(InAddress)+'.BSY';
     ASSIGN(FFile,MailerInfo.Semaphores+LastBusyFiles[NumBusy]);
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,SimNode,SizeOf(SimNode));
     CLOSE(FFile);
END;


FUNCTION _NodeIsBusy(InAddress: AddrType): Boolean;
BEGIN
     IF _FileExists(MailerInfo.Semaphores+HexSystem(InAddress)+'.BSY')
        THEN _NodeIsBusy := True
        ELSE _NodeIsBusy := False;
END;


PROCEDURE _ClearOurBusyFiles;
VAR  DirInfo   : SearchRec;
     FFile     : File;
     Work      : Word;
     BytesRead : Word;
BEGIN
     FindFirst(MailerInfo.Semaphores+'*.BSY',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          ASSIGN(FFile,MailerInfo.Semaphores+DirInfo.Name);
          {$I-}
          RESET(FFile,1);
          BLOCKREAD(FFile,Work,SizeOf(Work),BytesRead);
          CLOSE(FFile);
          {$I+}
          IF IOResult=0 THEN
          BEGIN
               IF ((BytesRead=2) AND (Work=SimNode)) THEN _EraseFile(MailerInfo.Semaphores+DirInfo.Name);
          END;
          FindNext(DirInfo);
     END;
END;


END.
