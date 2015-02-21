{$I DEFINES.INC}
UNIT BsPkt;


INTERFACE


USES Shotgun;


TYPE  Type2Header        = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      Year               : Word;
      Month              : Word;
      Day                : Word;
      Hour               : Word;
      Minute             : Word;
      Second             : Word;
      Baud               : Word;
      PacketType         : Byte;
      Scrap              : Byte;
      OrigNet            : Word;
      DestNet            : Word;
      ProductCode        : Byte;
      SerialNumber       : Byte;
      Password           : Array[1..8] Of Char;
      OrigZone           : Word;
      DestZone           : Word;
      Fill               : Array[1..20] Of Byte;
      END;
TYPE  Type22Header       = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      OrigPoint          : Word;
      DestPoint          : Word;
      Reserved           : Array[1..8] Of Byte;
      PktMinVer          : Word; {2}
      PktMajVer          : Word; {2}
      OrigNet            : Word;
      DestNet            : Word;
      ProductCode        : Byte;
      ProductVer         : Byte;
      Password           : Array[1..8] Of Char;
      OrigZone           : Word;
      DestZone           : Word;
      OrigDomain         : Array[1..8] Of Char;
      DestDomain         : Array[1..8] Of Char;
      Filler             : Array[1..4] Of Byte;
      END;
TYPE  Type2PHeader       = RECORD
      OrigNode           : Word;
      DestNode           : Word;
      Year               : Word;
      Month              : Word;
      Day                : Word;
      Hour               : Word;
      Min                : Word;
      Sec                : Word;
      Baud               : Word;
      PktVer             : Word;
      OrigNet            : Word;
      DestNet            : Word;
      PrdCodL            : Byte;
      PVMajor            : Byte;
      Password           : Array[1..8] Of Char;
      QOrigZone          : Word;
      QDestZone          : Word;
      Filler             : Word;
      CapValid           : Word;
      PrdCodH            : Byte;
      PVMinor            : Byte;
      CapWord            : Word;
      OrigZone           : Word;
      DestZone           : Word;
      OrigPoint          : Word;
      DestPoint          : Word;
      ProdData           : Longint;
      END;
TYPE  PakdMessageHeadr   = RECORD
      Signature          : Byte; {Always #2}
      Fill               : Byte;
      OrigNode           : Word;
      DestNode           : Word;
      OrigNet            : Word;
      DestNet            : Word;
      Attribute          : Word;
      Cost               : Word;
      DateTime           : Array[1..20] Of Char;
      END;


{FIDO *.PKT MESSAGE READING}
FUNCTION  rPktStartUpPacket     (PacketFile: String): Boolean;
PROCEDURE rPktGetAkas           (VAR Orig,Dest: AddrType);
FUNCTION  rPktGetPktPassword    : String;
FUNCTION  rPktGetProductVersion : String;
FUNCTION  rPktGetProductCode    : Word;
FUNCTION  rPktGetProductName    : String;
FUNCTION  rPktGetPacketType     : String;
FUNCTION  rPktGetMsgDate        : String;
FUNCTION  rPktGetMsgTime        : String;
FUNCTION  rPktReadNextMessage   : Boolean;
FUNCTION  rPktGetMsgTo          : String;
FUNCTION  rPktGetMsgFrom        : String;
FUNCTION  rPktGetMsgSubject     : String;
FUNCTION  rPktGetString         (VAR TheString: String; VAR IsWrapped: Boolean): Boolean;
FUNCTION  rPktGetMsgArea        : String;
PROCEDURE rPktGetMsgAkas        (VAR Orig,Dest: AddrType);
PROCEDURE rPktGetDateTime       (VAR PktDateTime: Array Of Char);
PROCEDURE rPktCloseUpPacket;


IMPLEMENTATION


USES Dos,BsAkas,FMode,BsString,BsCrc,BsBuff,BsFile;


TYPE  _RPktMsg           = RECORD
      PacketFile         : String[80];
      PacketType         : Byte;
      Type2              : Type2Header;
      Type22             : Type22Header;
      Type2P             : Type2PHeader;
      FromAddress        : AddrType;
      ToAddress          : AddrType;
      Password           : String[8];
      ProductVer         : String[30];
      ProductCode        : Word;
      END;
TYPE  _RPktMsgHeader     = RECORD
      MsgHeader          : PakdMessageHeadr;
      MsgArea            : String[40];
      MsgTo              : String[80];
      MsgFrom            : String[80];
      MsgSubject         : String[80];
      END;
VAR   ReadPktMsgHeader   : ^_RPktMsgHeader;
      ReadPktMsg         : ^_RPktMsg;


FUNCTION rPktGetPacketType: String;
BEGIN
     CASE ReadPktMsg^.PacketType OF
     1:   rPktGetPacketType := '2.0';
     2:   rPktGetPacketType := '2.2';
     3:   rPktGetPacketType := '2+';
     ELSE rPktGetPacketType := 'Unknown';
     END;
END;


FUNCTION rPktStartUpPacket(PacketFile: String): Boolean;
VAR  Loop : Word;
     C    : Char;
BEGIN
     PacketFile := _UpperCase(PacketFile);
     New(ReadPktMsg);
     New(ReadPktMsgHeader);
     FillChar(ReadPktMsg^,SizeOf(ReadPktMsg^),0);
     ReadPktMsg^.PacketFile := PacketFile;
     IF _FileExists(ReadPktMsg^.PacketFile) THEN
     BEGIN
       IF BsOpenFile(ReadPktMsg^.PacketFile) THEN
       BEGIN
         IF NOT(bsGetBlock(ReadPktMsg^.Type2P,SizeOf(ReadPktMsg^.Type2P))) THEN
         BEGIN
           rPktCloseUpPacket;
           rPktStartUpPacket := False;
           Exit;
         END;
         IF ((ReadPktMsg^.Type2P.Day=0) AND (ReadPktMsg^.Type2P.Hour=0) AND
            (ReadPktMsg^.Type2P.Min=0) AND (ReadPktMsg^.Type2P.Sec=0) AND
            (ReadPktMsg^.Type2P.Baud=2)) THEN
         BEGIN
           ReadPktMsg^.PacketType := 2; { fsc-0045 }
         END
         ELSE IF ReadPktMsg^.Type2P.CapWord=0 THEN
         BEGIN
           ReadPktMsg^.PacketType := 1; { fts-0001 }
         END
         ELSE IF ((ReadPktMsg^.Type2P.CapWord=1) AND (ReadPktMsg^.Type2P.Baud<>2)) THEN
         BEGIN
           ReadPktMsg^.PacketType := 3; { fsc-0039 }
         END
         ELSE
         BEGIN
           rPktCloseUpPacket;
           rPktStartUpPacket := False;
           Exit;
         END;
         CASE ReadPktMsg^.PacketType OF
         1:   BEGIN {Type 2}
                Move(ReadPktMsg^.Type2P,ReadPktMsg^.Type2,SizeOf(ReadPktMsg^.Type2));
                ReadPktMsg^.FromAddress.Zone := ReadPktMsg^.Type2.OrigZone;
                ReadPktMsg^.FromAddress.Net  := ReadPktMsg^.Type2.OrigNet;
                ReadPktMsg^.FromAddress.Node := ReadPktMsg^.Type2.OrigNode;
                ReadPktMsg^.ToAddress.Zone   := ReadPktMsg^.Type2.DestZone;
                ReadPktMsg^.ToAddress.Net    := ReadPktMsg^.Type2.DestNet;
                ReadPktMsg^.ToAddress.Node   := ReadPktMsg^.Type2.DestNode;
                ReadPktMsg^.ProductCode      := ReadPktMsg^.Type2.ProductCode;
                FOR Loop := 1 TO 8 DO
                BEGIN
                  C := ReadPktMsg^.Type2.Password[Loop];
                  IF ((C<>#32) AND (C<>#0)) THEN ReadPktMsg^.Password := ReadPktMsg^.Password+C;
                END;
              END;
         2:   BEGIN {Type 2.2}
                Move(ReadPktMsg^.Type2P,ReadPktMsg^.Type22,SizeOf(ReadPktMsg^.Type22));
                ReadPktMsg^.FromAddress.Zone  := ReadPktMsg^.Type22.OrigZone;
                ReadPktMsg^.FromAddress.Net   := ReadPktMsg^.Type22.OrigNet;
                ReadPktMsg^.FromAddress.Node  := ReadPktMsg^.Type22.OrigNode;
                ReadPktMsg^.FromAddress.Point := ReadPktMsg^.Type22.OrigPoint;
                ReadPktMsg^.ToAddress.Zone    := ReadPktMsg^.Type22.DestZone;
                ReadPktMsg^.ToAddress.Net     := ReadPktMsg^.Type22.DestNet;
                ReadPktMsg^.ToAddress.Node    := ReadPktMsg^.Type22.DestNode;
                ReadPktMsg^.ToAddress.Point   := ReadPktMsg^.Type22.DestPoint;
                ReadPktMsg^.ProductCode       := ReadPktMsg^.Type22.ProductCode;
                ReadPktMsg^.ProductVer        := _String(ReadPktMsg^.Type22.ProductVer);
                FOR Loop := 1 TO 8 DO
                BEGIN
                  C := ReadPktMsg^.Type22.Password[Loop];
                  IF ((C<>#32) AND (C<>#0)) THEN ReadPktMsg^.Password := ReadPktMsg^.Password+C;
                END;
              END;
         3:   BEGIN {Type 2+}
                ReadPktMsg^.FromAddress.Zone  := ReadPktMsg^.Type2P.OrigZone;
                ReadPktMsg^.FromAddress.Net   := ReadPktMsg^.Type2P.OrigNet;
                ReadPktMsg^.FromAddress.Node  := ReadPktMsg^.Type2P.OrigNode;
                ReadPktMsg^.FromAddress.Point := ReadPktMsg^.Type2P.OrigPoint;
                ReadPktMsg^.ToAddress.Zone    := ReadPktMsg^.Type2P.DestZone;
                ReadPktMsg^.ToAddress.Net     := ReadPktMsg^.Type2P.DestNet;
                ReadPktMsg^.ToAddress.Node    := ReadPktMsg^.Type2P.DestNode;
                ReadPktMsg^.ToAddress.Point   := ReadPktMsg^.Type2P.DestPoint;
                ReadPktMsg^.ProductVer        := _String(ReadPktMsg^.Type2P.PVMajor)+'.'+_String(ReadPktMsg^.Type2P.PVMinor);
                ReadPktMsg^.ProductCode       := (ReadPktMsg^.Type2P.PrdCodH*256)+ReadPktMsg^.Type2P.PrdCodL;
                FOR Loop := 1 TO 8 DO
                BEGIN
                  C := ReadPktMsg^.Type2P.Password[Loop];
                  IF ((C<>#32) AND (C<>#0)) THEN ReadPktMsg^.Password := ReadPktMsg^.Password+C;
                END;
              END;
         END;
       END
       ELSE
       BEGIN
         rPktCloseUpPacket;
         rPktStartUpPacket := False;
         Exit;
       END;
     END
     ELSE
     BEGIN
       Dispose(ReadPktMsg);
       Dispose(ReadPktMsgHeader);
       rPktStartUpPacket := False;
       Exit;
     END;
     rPktStartUpPacket := True;
END;


PROCEDURE rPktGetMsgAkas(VAR Orig,Dest: AddrType);
BEGIN
     FillChar(Orig,SizeOf(Orig),0);
     FillChar(Dest,SizeOf(Dest),0);
     WITH ReadPktMsgHeader^ DO
     BEGIN
       Orig.Net  := MsgHeader.OrigNet;
       Orig.Node := MsgHeader.OrigNode;
       Dest.Net  := MsgHeader.DestNet;
       Dest.Node := MsgHeader.DestNode;
     END;
END;


PROCEDURE rPktGetAkas(VAR Orig,Dest: AddrType);
BEGIN
     Orig := ReadPktMsg^.FromAddress;
     Dest := ReadPktMsg^.ToAddress;
END;


FUNCTION rPktGetPktPassword: String;
BEGIN
     rPktGetPktPassword := ReadPktMsg^.Password;
END;


FUNCTION rPktGetProductVersion: String;
BEGIN
     rPktGetProductVersion := ReadPktMsg^.ProductVer;
END;


FUNCTION rPktGetProductCode: Word;
BEGIN
     rPktGetProductCode := ReadPktMsg^.ProductCode;
END;


FUNCTION rPktGetProductName: String;
BEGIN
     CASE ReadPktMsg^.ProductCode OF
     $0000: rPktGetProductName := 'Fido';
     $0001: rPktGetProductName := 'Rover';
     $0002: rPktGetProductName := 'SEAdog';
     $0003: rPktGetProductName := 'WinDog';
     $0004: rPktGetProductName := 'Slick-150';
     $0005: rPktGetProductName := 'Opus';
     $0006: rPktGetProductName := 'Dutchie';
     $0007: rPktGetProductName := 'WPL Library';
     $0008: rPktGetProductName := 'Tabby';
     $0009: rPktGetProductName := 'SWMail';
     $000A: rPktGetProductName := 'Wolf-68k';
     $000B: rPktGetProductName := 'QMM';
     $000C: rPktGetProductName := 'FrontDoor';
     $000D: rPktGetProductName := 'GOmail';
     $000E: rPktGetProductName := 'FFGate';
     $000F: rPktGetProductName := 'FileMgr';
     $0010: rPktGetProductName := 'FIDZERCP';
     $0011: rPktGetProductName := 'MailMan';
     $0012: rPktGetProductName := 'OOPS';
     $0013: rPktGetProductName := 'GS-Point';
     $0014: rPktGetProductName := 'BGMail';
     $0015: rPktGetProductName := 'ComMotion/2';
     $0016: rPktGetProductName := 'OurBBS Fidomailer';
     $0017: rPktGetProductName := 'FidoPcb';
     $0018: rPktGetProductName := 'WimpLink';
     $0019: rPktGetProductName := 'BinkScan';
     $001A: rPktGetProductName := 'D''Bridge';
     $001B: rPktGetProductName := 'BinkleyTerm';
     $001C: rPktGetProductName := 'Yankee';
     $001D: rPktGetProductName := 'uuGate';
     $001E: rPktGetProductName := 'Daisy';
     $001F: rPktGetProductName := 'Polar Bear';
     $0020: rPktGetProductName := 'The-Box';
     $0021: rPktGetProductName := 'STARgate/2';
     $0022: rPktGetProductName := 'TMail';
     $0023: rPktGetProductName := 'TCOMMail';
     $0024: rPktGetProductName := 'GIGO';
     $0025: rPktGetProductName := 'RBBSMail';
     $0026: rPktGetProductName := 'Apple-Netmail';
     $0027: rPktGetProductName := 'Chameleon';
     $0028: rPktGetProductName := 'Majik Board';
     $0029: rPktGetProductName := 'QM';
     $002A: rPktGetProductName := 'Point And Click';
     $002B: rPktGetProductName := 'Aurora Three Bundler';
     $002C: rPktGetProductName := 'FourDog';
     $002D: rPktGetProductName := 'MSG-PACK';
     $002E: rPktGetProductName := 'AMAX';
     $002F: rPktGetProductName := 'Domain Communication System';
     $0030: rPktGetProductName := 'LesRobot';
     $0031: rPktGetProductName := 'Rose';
     $0032: rPktGetProductName := 'Paragon';
     $0033: rPktGetProductName := 'BinkleyTerm/oMMM/ST';
     $0034: rPktGetProductName := 'StarNet';
     $0035: rPktGetProductName := 'ZzyZx';
     $0036: rPktGetProductName := 'QEcho';
     $0037: rPktGetProductName := 'BOOM';
     $0038: rPktGetProductName := 'PBBS';
     $0039: rPktGetProductName := 'TrapDoor';
     $003A: rPktGetProductName := 'Welmat';
     $003B: rPktGetProductName := 'NetGate';
     $003C: rPktGetProductName := 'Odie';
     $003D: rPktGetProductName := 'Quick Gimme';
     $003E: rPktGetProductName := 'dbLink';
     $003F: rPktGetProductName := 'TosScan';
     $0040: rPktGetProductName := 'Beagle';
     $0041: rPktGetProductName := 'Igor';
     $0042: rPktGetProductName := 'TIMS';
     $0043: rPktGetProductName := 'Phoenix';
     $0044: rPktGetProductName := 'FrontDoor APX';
     $0045: rPktGetProductName := 'XRS';
     $0046: rPktGetProductName := 'Juliet Mail System';
     $0047: rPktGetProductName := 'Jabberwocky';
     $0048: rPktGetProductName := 'XST';
     $0049: rPktGetProductName := 'MailStorm';
     $004A: rPktGetProductName := 'BIX-Mail';
     $004B: rPktGetProductName := 'IMAIL';
     $004C: rPktGetProductName := 'FTNGate';
     $004D: rPktGetProductName := 'RealMail';
     $004E: rPktGetProductName := 'Lora-CBIS';
     $004F: rPktGetProductName := 'TDCS';
     $0050: rPktGetProductName := 'InterEcho';
     $0051: rPktGetProductName := 'RFD';
     $0052: rPktGetProductName := 'Yuppie!';
     $0053: rPktGetProductName := 'EMMA';
     $0054: rPktGetProductName := 'QBoxMail';
     $0055: rPktGetProductName := 'Number 4';
     $0056: rPktGetProductName := 'Number 5';
     $0057: rPktGetProductName := 'GSBBS';
     $0058: rPktGetProductName := 'Merlin';
     $0059: rPktGetProductName := 'TPCS';
     $005A: rPktGetProductName := 'Raid';
     $005B: rPktGetProductName := 'Outpost';
     $005C: rPktGetProductName := 'Nizze';
     $005D: rPktGetProductName := 'Armadillo';
     $005E: rPktGetProductName := 'rfmail';
     $005F: rPktGetProductName := 'Msgtoss';
     $0060: rPktGetProductName := 'InfoTex';
     $0061: rPktGetProductName := 'GEcho';
     $0062: rPktGetProductName := 'CDEhost';
     $0063: rPktGetProductName := 'Pktize';
     $0064: rPktGetProductName := 'PC-RAIN';
     $0065: rPktGetProductName := 'Truffle';
     $0066: rPktGetProductName := 'Foozle';
     $0067: rPktGetProductName := 'White Pointer';
     $0068: rPktGetProductName := 'GateWorks';
     $0069: rPktGetProductName := 'Portal of Power';
     $006A: rPktGetProductName := 'MacWoof';
     $006B: rPktGetProductName := 'Mosaic';
     $006C: rPktGetProductName := 'TPBEcho';
     $006D: rPktGetProductName := 'HandyMail';
     $006E: rPktGetProductName := 'EchoSmith';
     $006F: rPktGetProductName := 'FileHost';
     $0070: rPktGetProductName := 'SFTS';
     $0071: rPktGetProductName := 'Benjamin';
     $0072: rPktGetProductName := 'RiBBS';
     $0073: rPktGetProductName := 'MP';
     $0074: rPktGetProductName := 'Ping';
     $0075: rPktGetProductName := 'Door2Europe';
     $0076: rPktGetProductName := 'SWIFT';
     $0077: rPktGetProductName := 'WMAIL';
     $0078: rPktGetProductName := 'RATS';
     $0079: rPktGetProductName := 'Harry the Dirty Dog';
     $007A: rPktGetProductName := 'Squish';
     $007B: rPktGetProductName := 'SwifEcho';
     $007C: rPktGetProductName := 'GCChost';
     $007D: rPktGetProductName := 'RPX-Mail';
     $007E: rPktGetProductName := 'Tosser';
     $007F: rPktGetProductName := 'TCL';
     $0080: rPktGetProductName := 'MsgTrack';
     $0081: rPktGetProductName := 'FMail';
     $0082: rPktGetProductName := 'Scantoss';
     $0083: rPktGetProductName := 'Point Manager';
     $0084: rPktGetProductName := 'IMBINK';
     $0085: rPktGetProductName := 'Simplex';
     $0086: rPktGetProductName := 'UMTP';
     $0087: rPktGetProductName := 'Indaba';
     $0088: rPktGetProductName := 'Echomail Engine';
     $0089: rPktGetProductName := 'DragonMail';
     $008A: rPktGetProductName := 'Prox';
     $008B: rPktGetProductName := 'Tick';
     $008C: rPktGetProductName := 'RA-Echo';
     $008D: rPktGetProductName := 'TrapToss';
     $008E: rPktGetProductName := 'Babel';
     $008F: rPktGetProductName := 'UMS';
     $0090: rPktGetProductName := 'RWMail';
     $0091: rPktGetProductName := 'WildMail';
     $0092: rPktGetProductName := 'AlMAIL';
     $0093: rPktGetProductName := 'XCS';
     $0094: rPktGetProductName := 'Fone-Link';
     $0095: rPktGetProductName := 'Dogfight';
     $0096: rPktGetProductName := 'Ascan';
     $0097: rPktGetProductName := 'FastMail';
     $0098: rPktGetProductName := 'DoorMan';
     $0099: rPktGetProductName := 'PhaedoZap';
     $009A: rPktGetProductName := 'SCREAM';
     $009B: rPktGetProductName := 'MoonMail';
     $009C: rPktGetProductName := 'Backdoor';
     $009D: rPktGetProductName := 'MailLink';
     $009E: rPktGetProductName := 'Mail Manager';
     $009F: rPktGetProductName := 'Black Star';
     $00A0: rPktGetProductName := 'Bermuda';
     $00A1: rPktGetProductName := 'PT';
     $00A2: rPktGetProductName := 'UltiMail';
     $00A3: rPktGetProductName := 'GMD';
     $00A4: rPktGetProductName := 'FreeMail';
     $00A5: rPktGetProductName := 'Meliora';
     $00A6: rPktGetProductName := 'Foodo';
     $00A7: rPktGetProductName := 'MSBBS';
     $00A8: rPktGetProductName := 'Boston BBS';
     $00A9: rPktGetProductName := 'XenoMail';
     $00AA: rPktGetProductName := 'XenoLink';
     $00AB: rPktGetProductName := 'ObjectMatrix';
     $00AC: rPktGetProductName := 'Milquetoast';
     $00AD: rPktGetProductName := 'PipBase';
     $00AE: rPktGetProductName := 'EzyMail';
     $00AF: rPktGetProductName := 'FastEcho';
     $00B0: rPktGetProductName := 'IOS';
     $00B1: rPktGetProductName := 'Communique';
     $00B2: rPktGetProductName := 'PointMail';
     $00B3: rPktGetProductName := 'Harvey''s Robot';
     $00B4: rPktGetProductName := '2daPoint';
     $00B5: rPktGetProductName := 'CommLink';
     $00B6: rPktGetProductName := 'fronttoss';
     $00B7: rPktGetProductName := 'SysopPoint';
     $00B8: rPktGetProductName := 'PTMAIL';
     $00B9: rPktGetProductName := 'MHS';
     $00BA: rPktGetProductName := 'DLGMail';
     $00BB: rPktGetProductName := 'GatePrep';
     $00BC: rPktGetProductName := 'Spoint';
     $00BD: rPktGetProductName := 'TurboMail';
     $00BE: rPktGetProductName := 'FXMAIL';
     $00BF: rPktGetProductName := 'NextBBS';
     $00C0: rPktGetProductName := 'EchoToss';
     $00C1: rPktGetProductName := 'SilverBox';
     $00C2: rPktGetProductName := 'MBMail';
     $00C3: rPktGetProductName := 'SkyFreq';
     $00C4: rPktGetProductName := 'ProMailer';
     $00C5: rPktGetProductName := 'Mega Mail';
     $00C6: rPktGetProductName := 'YaBom';
     $00C7: rPktGetProductName := 'TachEcho';
     $00C8: rPktGetProductName := 'XAP';
     $00C9: rPktGetProductName := 'EZMAIL';
     $00CA: rPktGetProductName := 'Arc-Binkley';
     $00CB: rPktGetProductName := 'Roser';
     $00CC: rPktGetProductName := 'UU2';
     $00CD: rPktGetProductName := 'NMS';
     $00CE: rPktGetProductName := 'BBCSCAN';
     $00CF: rPktGetProductName := 'XBBS';
     $00D0: rPktGetProductName := 'LoTek Vzrul';
     $00D1: rPktGetProductName := 'Private Point Project';
     $00D2: rPktGetProductName := 'NoSnail';
     $00D3: rPktGetProductName := 'SmlNet';
     $00D4: rPktGetProductName := 'STIR';
     $00D5: rPktGetProductName := 'RiscBBS';
     $00D6: rPktGetProductName := 'Hercules';
     $00D7: rPktGetProductName := 'AMPRGATE';
     $00D8: rPktGetProductName := 'BinkEMSI';
     $00D9: rPktGetProductName := 'EditMsg';
     $00DA: rPktGetProductName := 'Roof';
     $00DB: rPktGetProductName := 'QwkPkt';
     $00DC: rPktGetProductName := 'MARISCAN';
     $00DD: rPktGetProductName := 'NewsFlash';
     $00DE: rPktGetProductName := 'Paradise';
     $00DF: rPktGetProductName := 'DogMatic-ACB';
     $00E0: rPktGetProductName := 'T-Mail';
     $00E1: rPktGetProductName := 'JetMail';
     $00E2: rPktGetProductName := 'MainDoor';
     $00E3: rPktGetProductName := 'Starnet Products';
     $00E4: rPktGetProductName := 'BMB';
     $00E5: rPktGetProductName := 'BNP';
     $00E6: rPktGetProductName := 'MailMaster';
     $00E7: rPktGetProductName := 'Mail Manager +Plus+';
     $00E8: rPktGetProductName := 'BloufGate';
     $00E9: rPktGetProductName := 'CrossPoint';
     $00EA: rPktGetProductName := 'DeltaEcho';
     $00EB: rPktGetProductName := 'ALLFIX';
     $00EC: rPktGetProductName := 'NetWay';
     $00ED: rPktGetProductName := 'MARSmail';
     $00EE: rPktGetProductName := 'ITRACK';
     $00EF: rPktGetProductName := 'GateUtil';
     $00F0: rPktGetProductName := 'Bert';
     $00F1: rPktGetProductName := 'Techno';
     $00F2: rPktGetProductName := 'AutoMail';
     $00F3: rPktGetProductName := 'April';
     $00F4: rPktGetProductName := 'Amanda';
     $00F5: rPktGetProductName := 'NmFwd';
     $00F6: rPktGetProductName := 'FileScan';
     $00F7: rPktGetProductName := 'FredMail';
     $00F8: rPktGetProductName := 'TP Kom';
     $00F9: rPktGetProductName := 'FidoZerb';
     $00FA: rPktGetProductName := '!!MessageBase';
     $00FB: rPktGetProductName := 'EMFido';
     $00FC: rPktGetProductName := 'GS-Toss';
     $00FD: rPktGetProductName := 'QWKDoor';
     $00FE: rPktGetProductName := 'Unknown';
     $00FF: rPktGetProductName := '16-bit product id';
     $0100: rPktGetProductName := 'Reservered';
     $0101: rPktGetProductName := 'The Brake!';
     $0102: rPktGetProductName := 'Zeus BBS';
     $0103: rPktGetProductName := 'XenoPhobe-Mailer';
     $0104: rPktGetProductName := 'None';
     $0105: rPktGetProductName := 'Terminate';
     $0106: rPktGetProductName := 'TeleMail';
     $0107: rPktGetProductName := 'CMBBS';
     $0108: rPktGetProductName := 'Shuttle';
     $0109: rPktGetProductName := 'Quater';
     $010A: rPktGetProductName := 'Windo';
     $010B: rPktGetProductName := 'Xenia';
     $010C: rPktGetProductName := 'GMS';
     $010D: rPktGetProductName := 'HNET';
     $010E: rPktGetProductName := 'SGEcho';
     ELSE
       BEGIN
         rPktGetProductName := 'Unknown $'+Word2Hex(ReadPktMsg^.ProductCode);
       END;
     END;
END;


FUNCTION rPktReadNextMessage: Boolean;
VAR  C : Char;
LABEL    Failed;
BEGIN
     FillChar(ReadPktMsgHeader^,SizeOf(ReadPktMsgHeader^),0);
     WITH ReadPktMsgHeader^ DO
     BEGIN
       IF bsGetBlock(MsgHeader,SizeOf(MsgHeader)) THEN
       BEGIN
         IF MsgHeader.Signature=2 THEN
         BEGIN
           {Msg To}
           REPEAT
             IF NOT(bsGetChar(C)) THEN GOTO Failed;
             IF (C<>#0) THEN MsgTo := MsgTo+C;
           UNTIL C=#0;
           {Msg From}
           REPEAT
             IF NOT(bsGetChar(C)) THEN GOTO Failed;
             IF (C<>#0) THEN MsgFrom := MsgFrom+C;
           UNTIL C=#0;
           {Msg Subject}
           REPEAT
             IF NOT(bsGetChar(C)) THEN GOTO Failed;
             IF (C<>#0) THEN MsgSubject := MsgSubject+C;
           UNTIL C=#0;
           rPktReadNextMessage := True;
         END
         ELSE GOTO Failed;
       END
       ELSE
       BEGIN
         Failed:
         rPktReadNextMessage := False;
       END;
     END;
END;


FUNCTION rPktGetMsgDate: String;
VAR  Temp  : String[20];
     Temp2 : String[10];
     Month : String[3];
BEGIN
     WITH ReadPktMsgHeader^ DO
     BEGIN
       Move(MsgHeader.DateTime,Temp[1],19);
       Temp[0] := #19;
       Temp2 := '01-';
       Month := _UpperCase(_Mid(Temp,4,6));
            IF Month='JAN' THEN Temp2 := '01-'
       ELSE IF Month='FEB' THEN Temp2 := '02-'
       ELSE IF Month='MAR' THEN Temp2 := '03-'
       ELSE IF Month='APR' THEN Temp2 := '04-'
       ELSE IF Month='MAY' THEN Temp2 := '05-'
       ELSE IF Month='JUN' THEN Temp2 := '06-'
       ELSE IF Month='JUL' THEN Temp2 := '07-'
       ELSE IF Month='AUG' THEN Temp2 := '08-'
       ELSE IF Month='SEP' THEN Temp2 := '09-'
       ELSE IF Month='OCT' THEN Temp2 := '10-'
       ELSE IF Month='NOV' THEN Temp2 := '11-'
       ELSE IF Month='DEC' THEN Temp2 := '12-';
       Temp2 := Temp2+_Mid(Temp,1,2)+'-';
       IF _Numeric(_Mid(Temp,8,9))>79
          THEN Temp2 := Temp2+'19'+_Mid(Temp,8,9)
          ELSE Temp2 := Temp2+'20'+_Mid(Temp,8,9);
     END;
     rPktGetMsgDate := Temp2;
END;


FUNCTION rPktGetMsgTime: String;
VAR  Temp  : String[20];
     Temp2 : String[8];
BEGIN
     WITH ReadPktMsgHeader^ DO
     BEGIN
       Move(MsgHeader.DateTime,Temp[1],19);
       Temp[0] := #19;
       Temp2 := _Mid(Temp,12,13)+':'+_Mid(Temp,15,16)+':'+_Mid(Temp,18,19);
     END;
     rPktGetMsgTime := Temp2;
END;


FUNCTION rPktGetMsgTo: String;
BEGIN
     rPktGetMsgTo := ReadPktMsgHeader^.MsgTo;
END;


FUNCTION rPktGetMsgFrom: String;
BEGIN
     rPktGetMsgFrom := ReadPktMsgHeader^.MsgFrom;
END;


FUNCTION rPktGetMsgSubject: String;
BEGIN
     rPktGetMsgSubject := ReadPktMsgHeader^.MsgSubject;
END;


FUNCTION rPktGetString(VAR TheString: String; VAR IsWrapped: Boolean): Boolean;
VAR  Temp      : String;
     LastSpace : Byte;
     AllDone   : Boolean;
     C         : Char;
     FPos      : Longint;
     LLen      : Byte;
     Status    : Boolean;
BEGIN
     Temp      := '';
     AllDone   := False;
     LastSpace := 0;
     FPos      := 0;
     IsWrapped := False;
     REPEAT
       IF NOT(bsGetChar(C)) THEN
       BEGIN
         TheString := '';
         rPktGetString := False;
         Exit;
       END
       ELSE
       BEGIN
         IF C=#$8D THEN C := #32;
         CASE C OF
         #$0A:  ;
         #$00:  BEGIN
                  IF Temp[0]=#0 THEN
                  BEGIN
                    TheString := '';
                    rPktGetString := False;
                    Exit;
                  END
                  ELSE AllDone := True;
                END;
         #$0D:  AllDone := True;
         ELSE   BEGIN {Normal Character}
                  Temp := Temp+C;
                  LLen := LENGTH(Temp);
                  IF LLen=80 THEN
                  BEGIN
                    IF (LastSpace<>0) THEN
                    BEGIN
                      Temp[0] := Chr(LastSpace);
                      bsSeekFile(FPos);
                      AllDone := True;
                    END
                    ELSE AllDone := True;
                    IsWrapped := True;
                  END
                  ELSE IF ((C=#32) OR (C=',')) THEN
                  BEGIN
                    LastSpace := LLen-1;
                    FPos := bsFilePos;
                  END;
                END;
         END;
       END;
     UNTIL AllDone;
     TheString := Temp;
     rPktGetString := True;
END;


PROCEDURE rPktGetDateTime(VAR PktDateTime: Array Of Char);
BEGIN
     WITH ReadPktMsgHeader^ DO
     BEGIN
       Move(MsgHeader.DateTime,PktDateTime,19);
       PktDateTime[19] := #0;
     END;
END;


FUNCTION rPktGetMsgArea: String;
VAR  FPos       : Longint;
     Temp       : String;
     WasWrapped : Boolean;
BEGIN
     Temp := '';
     FPos := bsFilePos;
     IF rPktGetString(Temp,WasWrapped) THEN
     BEGIN
       Temp := _UpperCase(Temp);
       IF (Pos('AREA:',Temp)<>1) THEN
       BEGIN
         Temp := 'NETMAIL';
         bsSeekFile(FPos);
       END
       ELSE
       BEGIN
         Delete(Temp,1,5);
         Temp := _RemoveLeftSpaces(Temp);
         Temp := _RemoveRightSpaces(Temp);
       END;
     END
     ELSE
     BEGIN
       Temp := 'NETMAIL';
       bsSeekFile(FPos);
     END;
     rPktGetMsgArea := _UpperCase(Temp);
END;


PROCEDURE rPktCloseUpPacket;
BEGIN
     bsCloseFile;
     Dispose(ReadPktMsg);
     Dispose(ReadPktMsgHeader);
END;


END.
