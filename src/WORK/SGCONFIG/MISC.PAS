{$I DEFINES.INC}
UNIT Misc;


INTERFACE


FUNCTION  GetNetAddress (Num: Word): String;
FUNCTION  GetNetDomain  (Num: Word): String;
FUNCTION  GetNetOrigin  (Num: Word): String;


IMPLEMENTATION


USES CnfgVars,Defaults,BsAkas,BsString;


FUNCTION GetNetAddress(Num: Word): String;
BEGIN
     CheckFile('NETWORK.DAT');
     IF Num=0 THEN
     BEGIN
          GetNetAddress := '';
          Exit;
     END;
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


FUNCTION GetNetDomain(Num: Word): String;
BEGIN
     CheckFile('NETWORK.DAT');
     IF Num=0 THEN
     BEGIN
          GetNetDomain := '';
          Exit;
     END;
     ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetworkInfo)>=Num THEN
          BEGIN
               SEEK(FNetworkInfo,Num-1);
               READ(FNetworkInfo,NetworkInfo);
               GetNetDomain := NetworkInfo.Net_Domain;
          END
          ELSE GetNetDomain := '';
          CLOSE(FNetworkInfo);
     END
     ELSE GetNetDomain := '';
END;


FUNCTION GetNetOrigin(Num: Word): String;
BEGIN
     CheckFile('ORIGINS.DAT');
     IF Num=0 THEN
     BEGIN
          GetNetOrigin := '';
          Exit;
     END;
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


END.