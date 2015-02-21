{$I DEFINES.INC}
UNIT BsCrc;


INTERFACE


FUNCTION FileCrc32(FName: String): String;
FUNCTION Byte2Hex(numb : Byte): String;
FUNCTION Word2Hex(numb: Word): String;
FUNCTION Long2Hex(L: LongInt): String;
FUNCTION StringCrc(InString: String): String;
FUNCTION StringCrcL(InString: String): Longint;


IMPLEMENTATION


USES ApMisc;


{$R-}


FUNCTION FileCrc32(FName: String): String;
{$IFDEF DPMI}
TYPE BigBuffer = Array[1..32768] Of Byte;
{$ELSE}
TYPE BigBuffer = Array[1..16384] Of Byte;
{$ENDIF}
VAR  FFile     : File;
     Work      : Longint;
     BBuffer   : ^BigBuffer;
     BytesRead : Word;
     Loop      : Word;
     Tries     : Byte;
LABEL            OneMoreTime;
BEGIN
     New(BBuffer);
     Work  := 0;
     Tries := 0;
     OneMoreTime:
     ASSIGN(FFile,FName);
     {$I-}RESET(FFile,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
       Work := $FFFFFFFF;
       REPEAT
         BlockRead(FFile,BBuffer^,SizeOf(BBuffer^),BytesRead);
         FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(BBuffer^[Loop],Work);
       UNTIL EOF(FFile);
       CLOSE(FFile);
       Work := NOT Work;
     END
     ELSE
     BEGIN
       INC(Tries);
       IF (Tries<3) THEN GOTO OneMoreTime;
     END;
     IF IOResult=0 THEN;
     FileCrc32 := Long2Hex(Work);
     Dispose(BBuffer);
END;


FUNCTION Byte2Hex(numb : Byte): String;
CONST HexChars : Array[0..15] of Char = '0123456789ABCDEF';
BEGIN
     Byte2Hex[0] := #2;
     Byte2Hex[1] := HexChars[numb shr  4];
     Byte2Hex[2] := HexChars[numb and 15];
END;


FUNCTION Word2Hex(numb: Word): String;
BEGIN
     Word2Hex := Byte2Hex(hi(numb))+Byte2Hex(lo(numb));
END;


FUNCTION Long2Hex(L: LongInt): String;
BEGIN
     Long2Hex := Word2Hex(L shr 16) + Word2Hex(L);
END;


FUNCTION StringCrc(InString: String): String;
VAR  Work : Longint;
     Loop : Word;
BEGIN
     Work := $FFFFFFFF;
     Work := UpdateCrc32(0,Work);
     FOR Loop := 1 TO LENGTH(InString) DO Work := UpdateCrc32(Ord(InString[Loop]),Work);
     StringCRC := Long2Hex(Work);
END;


FUNCTION StringCrcL(InString: String): Longint;
VAR  Work : Longint;
     Loop : Word;
BEGIN
     Work := $FFFFFFFF;
     Work := UpdateCrc32(0,Work);
     FOR Loop := 1 TO LENGTH(InString) DO Work := UpdateCrc32(Ord(InString[Loop]),Work);
     StringCrcL := Work;
END;


END.