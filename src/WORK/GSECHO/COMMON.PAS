{$I DEFINES.INC}
UNIT Common;


INTERFACE


USES Shotgun;


FUNCTION  IsOurNode(InAddress: AddrType): Boolean;
FUNCTION  Bundle_Crc(FromAka,ToAka: AddrType): String;
FUNCTION  GetNetAddress(Num: Word): String;
FUNCTION  GetNetOrigin(Num: Word): String;
FUNCTION  System_Crc(ToAka: AddrType): String;
FUNCTION  LoadTheLink(Aka: AddrType): Boolean;
FUNCTION  LoadTheUpLink(Aka: AddrType): Boolean;
FUNCTION  LoadSub(Index: Word): Boolean;
FUNCTION  ZeroPadded(Number: Word): String;
FUNCTION  Address2D(InAddress: AddrType): String;
PROCEDURE WriteLogFile(InString: String);


IMPLEMENTATION


USES Globals,BsAkas,BsCrc,BsLog,FMode,BsString;


FUNCTION Bundle_Crc(FromAka,ToAka: AddrType): String;
VAR  Temp : String;
BEGIN
     Temp := AddressToString(FromAka)+'-'+AddressToString(ToAka);
     Bundle_Crc := StringCrc(Temp);
END;


FUNCTION IsOurNode(InAddress: AddrType): Boolean;
VAR  FNetWorkInfo : File Of _Network_Record;
     WNetworkInfo : _Network_Record;
BEGIN
     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FNetworkInfo,WNetworkInfo);
         IF AkasMatch(InAddress,WNetworkInfo.Net_Address) THEN
         BEGIN
           CLOSE(FNetworkInfo);
           IsOurNode := True;
           Exit;
         END;
       UNTIL EOF(FNetworkInfo);
       CLOSE(FNetworkInfo);
     END;
     IsOurNode := False;
END;


FUNCTION GetNetAddress(Num: Word): String;
VAR  FNetWorkInfo : File Of _Network_Record;
BEGIN
     ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
       IF FileSize(FNetworkInfo)>=Num THEN
       BEGIN
         SEEK(FNetworkInfo,Num-1);
         READ(FNetworkInfo,NetworkInfo);
         GetNetAddress := AddressToString(NetworkInfo.Net_Address);
       END
       ELSE GetNetAddress := '';
       CLOSE(FNetworkInfo);
     END
     ELSE GetNetAddress :=  '';
END;


FUNCTION System_Crc(ToAka: AddrType): String;
BEGIN
     System_Crc := StringCrc(AddressToString(ToAka));
END;


PROCEDURE WriteLogFile(InString: String);
BEGIN
     bsWriteLog(InString,False);
     WriteLn(InString);
END;


FUNCTION LoadTheLink(Aka: AddrType): Boolean;
VAR  BytesRead : Word;
BEGIN
     FLinkGroups.OpenFile(BaseDirectory+'\DATA\LINKGRPS.DAT',SetFileMode);
     FLinksInfo.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);
     REPEAT
       FLinkGroups.BlkRead(DownLinkGroups,SizeOf(DownLinkGroups),BytesRead);
       FLinksInfo.BlkRead(DownLink,SizeOf(DownLink),BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
         IF AkasMatch(DownLink.NetworkAddress,Aka) THEN
         BEGIN
           FLinkGroups.CloseFile;
           FLinksInfo.CloseFile;
           LoadTheLink := True;
           Exit;
         END;
       END;
     UNTIL BytesRead=0;
     FLinkGroups.CloseFile;
     FLinksInfo.CloseFile;
     LoadTheLink := False;
END;


FUNCTION LoadTheUpLink(Aka: AddrType): Boolean;
VAR  BytesRead : Word;
BEGIN
     FLinkGroups.OpenFile(BaseDirectory+'\DATA\LINKGRPS.DAT',SetFileMode);
     FLinksInfo.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);
     REPEAT
       FLinkGroups.BlkRead(UpLinkGroups,SizeOf(UpLinkGroups),BytesRead);
       FLinksInfo.BlkRead(UpLink,SizeOf(UpLink),BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
         IF AkasMatch(UpLink.NetworkAddress,Aka) THEN
         BEGIN
           FLinkGroups.CloseFile;
           FLinksInfo.CloseFile;
           LoadTheUpLink := True;
           Exit;
         END;
       END;
     UNTIL BytesRead=0;
     FLinkGroups.CloseFile;
     FLinksInfo.CloseFile;
     LoadTheUpLink := False;
END;


FUNCTION LoadSub(Index: Word): Boolean;
VAR  GotIt        : Boolean;
     FMessageSubs : File Of _MessageSub_Record;
BEGIN
     GotIt := False;
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     {$I-}RESET(FMessageSubs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FMessageSubs,MessageSubs);
         IF MessageSubs.Sub_Num=Index THEN GotIt := True;
       UNTIL ((EOF(FMessageSubs)) OR (GotIt));
       CLOSE(FMessageSubs);
     END;
     LoadSub := GotIt;
END;


FUNCTION ZeroPadded(Number: Word): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := _String(Number);
     FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
     ZeroPadded := Temp;
END;


FUNCTION GetNetOrigin(Num: Word): String;
VAR  FNetOrigins : File Of _Origin_Record;
     NetOrigins  : _Origin_Record;
BEGIN
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     {$I-}RESET(FNetOrigins);{$I+}
     IF IOResult=0 THEN
     BEGIN
       IF FileSize(FNetOrigins)>=Num THEN
       BEGIN
         SEEK(FNetOrigins,Num-1);
         READ(FNetOrigins,NetOrigins);
         GetNetOrigin := NetOrigins.Net_Origin;
       END
       ELSE GetNetOrigin := '';
       CLOSE(FNetOrigins);
     END
     ELSE GetNetOrigin := '';
END;


FUNCTION Address2D(InAddress: AddrType): String;
BEGIN
     Address2D := _String(InAddress.Net)+'/'+_String(InAddress.Node);
END;


END.