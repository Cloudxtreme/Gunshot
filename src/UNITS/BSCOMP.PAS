{$I DEFINES.INC}
UNIT BsComp;


INTERFACE


TYPE BuffType = ARRAY[1..35256] OF Char;
VAR  CBuffer  : ^Bufftype;


PROCEDURE pCompressFile(Source,Dest: String);
FUNCTION  pDecompressFile(Source,Dest: String): Boolean;
PROCEDURE CompressFile(Source,Dest: String);
FUNCTION  DecompressFile(Source,Dest: String): Boolean;


IMPLEMENTATION

{$L IMPLODE.OBJ}

USES Dos;

TYPE IntFunc  = FUNCTION(VAR Buff: BuffType; VAR bSize: Word): Word;
VAR  DictionarySize  : Word;
     FromFile        : File;
     ToFile          : File;
     Result          : Integer;
     CMP_BINARY      : Word;


{$F+}FUNCTION Implode(Read:IntFunc;Write:IntFunc;VAR Buf:BuffType;VAR Ctype:Word;VAR bSize:Word):Integer;EXTERNAL;{$F-}
{$F+}FUNCTION Explode(Read:IntFunc;Write:IntFunc;VAR Buf:BuffType):Integer;EXTERNAL;{$F-}

{$F+}
FUNCTION ReadData(VAR CBuffer : BuffType; VAR BufferSize : Word): Word;
VAR  BytesRead : Word;
BEGIN
     BlockRead(FromFile, CBuffer, BufferSize, BytesRead);
     ReadData := BytesRead;
END;
{$F-}


{$F+}
FUNCTION WriteData(VAR CBuffer : BuffType; VAR BytesRead : Word): Word;
VAR  byteswritten : Word;
BEGIN
     BlockWrite(ToFile, CBuffer, BytesRead, BytesWritten);
     WriteData := BytesWritten;
END;
{$F-}


PROCEDURE pCompressFile(Source,Dest: String);
BEGIN
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
     DictionarySize := 4096;
     CMP_BINARY     := 1;
     result         := implode(ReadData,WriteData,CBuffer^,CMP_BINARY,DictionarySize);
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult=0 THEN;
END;


FUNCTION pDecompressFile(Source,Dest: String): Boolean;
BEGIN
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
     result := explode(ReadData,WriteData,CBuffer^);
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult<>0 THEN pDecompressFile := False
                    ELSE pDecompressFile := True;
END;


PROCEDURE CompressFile(Source,Dest: String);
BEGIN
     NEW(CBuffer);
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
     DictionarySize := 4096;
     CMP_BINARY     := 1;
     result         := implode(ReadData,WriteData,CBuffer^,CMP_BINARY,DictionarySize);
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult=0 THEN;
     DISPOSE(CBuffer);
END;


FUNCTION DecompressFile(Source,Dest: String): Boolean;
BEGIN
     NEW(CBuffer);
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
     result := explode(ReadData,WriteData,CBuffer^);
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult<>0 THEN DecompressFile := False
                    ELSE DecompressFile := True;
     DISPOSE(CBuffer);
END;


END.