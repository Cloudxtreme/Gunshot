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

{$IFDEF MSDOS}
{$L IMPLODE.OBJ}
{$ENDIF}

USES {$IFNDEF MSDOS}Implode,{$ENDIF}Dos;

TYPE IntFunc  = FUNCTION(VAR Buff: BuffType; VAR bSize: Word): Word;
VAR  DictionarySize  : Word;
     FromFile        : File;
     ToFile          : File;
     Result          : Integer;
     CMP_BINARY      : Word;


{$IFDEF MSDOS}
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
{$ENDIF}


PROCEDURE pCompressFile(Source,Dest: String);
{$IFNDEF MSDOS}
VAR
   InBuffer: PByte;
   InBufferSize: LongInt;
   OutBuffer: PByte;
   OutBufferSize: LongInt;
{$ENDIF} 
BEGIN
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
{$IFDEF MSDOS}
     DictionarySize := 4096;
     CMP_BINARY     := 1;
     result         := implode(ReadData,WriteData,CBuffer^,CMP_BINARY,DictionarySize);
{$ENDIF}
{$IFNDEF MSDOS}
     InBufferSize := FileSize(FromFile);
     OutBufferSize := InBufferSize;
     GetMem(InBuffer, InBufferSize);
     GetMem(OutBuffer, InBufferSize);
     BlockRead(FromFile, InBuffer^, InBufferSize);
     pklib_implode(1, 6, InBuffer, InBufferSize, OutBuffer, OutBufferSize);
     BlockWrite(ToFile, OutBuffer^, OutBufferSize);
     FreeMem(InBuffer, InBufferSize);
     FreeMem(OutBuffer, InBufferSize);
{$ENDIF}
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult=0 THEN;
END;


FUNCTION pDecompressFile(Source,Dest: String): Boolean;
VAR
   Success: Boolean;
{$IFNDEF MSDOS}
   InBuffer: PByte;
   InBufferSize: LongInt;
   OutBuffer: PByte;
   OutBufferSize: LongInt;
{$ENDIF}
BEGIN
     {$I-}
     Assign(FromFile,Source);
     Reset(FromFile,1);
     Assign(ToFile,Dest);
     Rewrite(ToFile,1);
{$IFDEF MSDOS}
     result := explode(ReadData,WriteData,CBuffer^);
	 Success := True; { Actual success will be based on IOResult below }
{$ENDIF}
{$IFNDEF MSDOS}
     // __TODO__ Is 10x the input file size always going to be enough?
	 // __TODO__ If the file was compressed 91%, then it won't be.  100x seems overkill though
	 // __TODO__ Reworking the IMPLODE.PAS to work like IMPLODE.OBJ may be a good idea
     InBufferSize := FileSize(FromFile);
     OutBufferSize := InBufferSize * 10;
     GetMem(InBuffer, InBufferSize);
     GetMem(OutBuffer, InBufferSize * 10);
     BlockRead(FromFile, InBuffer^, InBufferSize);
     Success := pklib_explode(InBuffer, InBufferSize, OutBuffer, OutBufferSize);
     BlockWrite(ToFile, OutBuffer^, OutBufferSize);
     FreeMem(InBuffer, InBufferSize);
     FreeMem(OutBuffer, InBufferSize * 10);
{$ENDIF}
     Close(FromFile);
     Close(ToFile);
     {$I+}
     IF IOResult<>0 THEN pDecompressFile := False
                    ELSE pDecompressFile := Success;
END;


PROCEDURE CompressFile(Source,Dest: String);
BEGIN
     NEW(CBuffer);
{$IFDEF MSDOS}
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
{$ENDIF}
{$IFNDEF MSDOS}
     pCompressFile(Source,Dest);
{$ENDIF}
     DISPOSE(CBuffer);
END;


FUNCTION DecompressFile(Source,Dest: String): Boolean;
BEGIN
     NEW(CBuffer);
{$IFDEF MSDOS}
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
{$ENDIF}
{$IFNDEF MSDOS}
  DecompressFile := pDecompressFile(Source,Dest);
{$ENDIF}
     DISPOSE(CBuffer);
END;


END.