{$I DEFINES.INC}
UNIT KeyCheck;


INTERFACE


TYPE TheRecord = RECORD
     Sysop     : String[40];
     BBS       : String[40];
     BBSPhone  : String[30];
     Addr1     : String[30];
     Addr2     : String[30];
     City      : String[30];
     Prov      : String[30];
     Country   : String[30];
     Postal    : String[30];
     Phone     : String[30];
     Sn        : String[30];
     Lines     : String[3];
     Expiry    : String[6];
     Check1    : Longint;
     Check2    : Longint;
     Check3    : Longint;
     Check4    : Longint;
     Check5    : Longint;
     Check6    : Longint;
     Check7    : Longint;
     Check8    : Longint;
     Check9    : Longint;
     Check10   : Longint;
     Check11   : Longint;
     Check12   : Longint;
     Check13   : Longint;
     END;
VAR  OurAppName     : String;
     IsItRegistered : Boolean;
     Client         : TheRecord;


PROCEDURE CheckRegistered(TempDir,App: String);


IMPLEMENTATION


USES BsComp,ApMisc,Crt,Dos,BsFile,Version;


PROCEDURE ClearFile(TempDir: String);
TYPE Poo = RECORD
     Junk : Array[1..10] Of Byte;
     END;
VAR  PooPoo  : Poo;
     FPooPoo : File Of Poo;
BEGIN
     FillChar(PooPoo,SizeOf(PooPoo),0);
     ASSIGN(FPooPoo,TempDir+'MAINCHOP.$$$');
     REWRITE(FPooPoo);
     WRITE(FPooPoo,PooPoo);
     CLOSE(FPooPoo);
     ERASE(FPooPoo);
END;


PROCEDURE CheckRegistered(TempDir,App: String);
CONST Alphabet : Array[1..26] Of Char = ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                                         'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');
VAR  FClient   : File Of TheRecord;
     StillGood : Boolean;
     Loop      : Word;
     Crc       : Longint;
     TheAlpha  : String;
     Temp      : String;
BEGIN
     Move(Alphabet,TheAlpha[1],26);
     TheAlpha[0] := #26;
     IsItRegistered := False;
     IF (TempDir[LENGTH(TempDir)]<>'\') THEN TempDir := TempDir+'\';
     IF IOResult=0 THEN;
     StillGood  := True;
     Temp := TheAlpha[19]+TheAlpha[8]+TheAlpha[15]+TheAlpha[20]+TheAlpha[7]+
             TheAlpha[21]+TheAlpha[14]+'.'+TheAlpha[11]+TheAlpha[5]+TheAlpha[25];
     IF NOT(_FileExists(Temp)) THEN Exit;
     IF NOT(DecompressFile(Temp,TempDir+'MAINCHOP.$$$')) THEN
     BEGIN
          ClearFile(TempDir);
          Exit;
     END;
     ASSIGN(FClient,TempDir+'MAINCHOP.$$$');
     {$I-}
     RESET(FClient);
     READ(FClient,Client);
     CLOSE(FClient);
     {$I+}
     IF IOResult<>0 THEN
     BEGIN
          ClearFile(TempDir);
          Exit;
     END;
     ClearFile(TempDir);
     Crc := $FFFFFFFF; FOR Loop := 1 TO 40 DO Crc := UpdateCrc32(Ord(Client.Sysop[Loop]),crc);
                       IF Client.Check1<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 40 DO Crc := UpdateCrc32(Ord(Client.BBS[Loop]),crc);
                       IF Client.Check2<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.BBSPhone[Loop]),crc);
                       IF Client.Check3<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Addr1[Loop]),crc);
                       IF Client.Check4<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Addr2[Loop]),crc);
                       IF Client.Check5<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.City[Loop]),crc);
                       IF Client.Check6<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Prov[Loop]),crc);
                       IF Client.Check7<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Country[Loop]),crc);
                       IF Client.Check8<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Postal[Loop]),crc);
                       IF Client.Check9<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Phone[Loop]),crc);
                       IF Client.Check10<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 30 DO Crc := UpdateCrc32(Ord(Client.Sn[Loop]),crc);
                       IF Client.Check11<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 3  DO Crc := UpdateCrc32(Ord(Client.Lines[Loop]),crc);
                       IF Client.Check12<>Crc THEN StillGood := False;
     Crc := $FFFFFFFF; FOR Loop := 1 TO 6  DO Crc := UpdateCrc32(Ord(Client.Expiry[Loop]),crc);
                       IF Client.Check13<>Crc THEN StillGood := False;

     {Check For Cancelled Key Files}
     IF Client.Check11=1798348486 THEN StillGood := False; {Allan Prunty}
     IF Client.Check11=1474389876 THEN StillGood := False; {Donald Lee}
     IF Client.Check11=-245691764 THEN StillGood := False; {Larry Athey}
     IF Client.Check11=-570339138 THEN StillGood := False; {Margaret Collins}
     IF Client.Check11=1804869633 THEN StillGood := False; {Free Key}

     IF StillGood THEN
     BEGIN
       IsItRegistered := True;
       OurAppName := App+' '+GunshotVersion+'/Gold+';
     END;
END;


END.
