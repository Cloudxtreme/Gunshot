{$I DEFINES.INC}
UNIT BsBuff;


INTERFACE


{$IFDEF DPMI}
TYPE  File_Buffer = Array[1..60000] Of Char;
{$ELSE}
TYPE  File_Buffer = Array[1..48000] Of Char;
{$ENDIF}
TYPE  Buff_File   = RECORD
      FFile       : File;
      InBuff      : Word;
      BuffPoint   : Word;
      Buffer      : File_Buffer;
      EndOfFile   : Boolean;
      FFilePos    : Longint;
      END;
VAR   BsBuffFile  : ^Buff_File;


FUNCTION  bsOpenFile (FileName: String): Boolean;
FUNCTION  bsGetChar  (VAR C: Char): Boolean;
FUNCTION  bsGetBlock (VAR Blk; NumBytes: Word): Boolean;
PROCEDURE bsSeekFile (Location: Longint);
FUNCTION  bsFilePos  : Longint;
PROCEDURE bsCloseFile;


IMPLEMENTATION


USES BsFile;


PROCEDURE bsFillBuffer;
VAR  BytesRead : Word;
BEGIN
     WITH BsBuffFile^ DO
     BEGIN
       FFilePos := FFilePos+InBuff;
       BlockRead(FFile,Buffer,SizeOf(Buffer),BytesRead);
       IF (BytesRead<>SizeOf(Buffer)) THEN EndOfFile := True;
       IF EOF(FFile) THEN EndOfFile := True;
       InBuff := BytesRead;
       BuffPoint := 1;
     END;
END;


FUNCTION bsOpenFile(FileName: String): Boolean;
BEGIN
     IF NOT(_FileExists(FileName)) THEN
     BEGIN
       bsOpenFile := False;
       Exit;
     END;
     New(BsBuffFile);
     ASSIGN(BsBuffFile^.FFile,FileName);
     {$I-}RESET(BsBuffFile^.FFile,1);{$I+}
     IF (IOResult<>0) THEN
     BEGIN
       bsOpenFile := False;
       Exit;
     END;
     BsBuffFile^.EndOfFile := False;
     BsBuffFile^.BuffPoint := 0;
     BsBuffFile^.InBuff    := 0;
     BsBuffFile^.FFilePos  := 0;
     bsFillBuffer;
     bsOpenFile := True;
END;


FUNCTION bsGetChar(VAR C: Char): Boolean;
BEGIN
     WITH BsBuffFile^ DO
     BEGIN
       IF ((EndOfFile) AND (BuffPoint>InBuff)) THEN
       BEGIN
         bsGetChar := False;
         Exit;
       END;
       IF (BuffPoint>InBuff) THEN bsFillBuffer;
       C := Buffer[BuffPoint];
       INC(BuffPoint);
       bsGetChar := True;
     END;
END;


FUNCTION bsGetBlock(VAR Blk; NumBytes: Word): Boolean;
VAR  Loop     : Word;
     AllIsOk  : Boolean;
     Wb       : Array[1..1024] Of Char;
BEGIN
     IF NumBytes>1024 THEN
     BEGIN
       WRITELN('File buffer exceeded error!');
       HALT;
     END;
     WITH BsBuffFile^ DO
     BEGIN
       IF ((BuffPoint+NumBytes)<InBuff) THEN
       BEGIN
         Move(Buffer[BuffPoint],Blk,NumBytes);
         INC(BuffPoint,NumBytes);
         AllIsOk := True;
       END
       ELSE
       BEGIN
         FOR Loop := 1 TO NumBytes DO AllIsOk := bsGetChar(Wb[Loop]);
         Move(wb,Blk,NumBytes);
       END;
     END;
     bsGetBlock := AllIsOk;
END;


PROCEDURE bsCloseFile;
BEGIN
     {$I-}CLOSE(BsBuffFile^.FFile);{$I+}
     IF IOResult=0 THEN;
     Dispose(BsBuffFile);
END;


FUNCTION bsFilePos: Longint;
BEGIN
     bsFilePos := BsBuffFile^.FFilePos+BsBuffFile^.BuffPoint-1;
END;


PROCEDURE bsSeekFile(Location: Longint);
BEGIN
     WITH BsBuffFile^ DO
     BEGIN
       IF ((Location<FFilePos) OR (Location>FFilePos+InBuff-2)) THEN
       BEGIN
         FFilePos  := Location;
         Seek(FFile,FFilePos);
         InBuff    := 0;
         EndOfFile := False;
         bsFillBuffer;
       END
       ELSE BuffPoint := (Location-FFilePos)+1;
     END;
END;


END.
