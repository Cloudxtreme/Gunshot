{$I DEFINES.INC}
UNIT BsFido;


INTERFACE


USES Shotgun;


{FIDO *.MSG MESSAGE WRITING}
PROCEDURE wFidoStartNewMessage  (NetMailPath,Application: String; MsgNumber: Word);
PROCEDURE wFidoWriteString      (InString: String);
PROCEDURE wFidoWriteStringWrap  (InString: String);
PROCEDURE wFidoWriteChar        (InChar: Char);
PROCEDURE wFidoSetMsgFrom       (InString: String);
PROCEDURE wFidoSetMsgTo         (InString: String);
PROCEDURE wFidoSetMsgSubject    (InString: String);
PROCEDURE wFidoSetAkas          (Orig,Dest: AddrType);
PROCEDURE wFidoSetDate          (InString: String);
PROCEDURE wFidoSetTime          (InString: String);
PROCEDURE wFidoSetLocal         (IsOn: Boolean);
PROCEDURE wFidoSetPrivate       (IsOn: Boolean);
PROCEDURE wFidoSetCrash         (IsOn: Boolean);
PROCEDURE wFidoSetFileAttached  (IsOn: Boolean);
PROCEDURE wFidoSetKillSent      (IsOn: Boolean);
PROCEDURE wFidoSetHoldForPickup (IsOn: Boolean);
PROCEDURE wFidoSetFileRequest   (IsOn: Boolean);
PROCEDURE wFidoSetTruncFile     (IsOn: Boolean);
PROCEDURE wFidoSetKillFile      (IsOn: Boolean);
PROCEDURE wFidoSetImmediate     (IsOn: Boolean);
PROCEDURE wFidoSetExclusive     (IsOn: Boolean);
PROCEDURE wFidoSetDirect        (IsOn: Boolean);
PROCEDURE wFidoSetReceived      (IsOn: Boolean);
PROCEDURE wFidoSetSent          (IsOn: Boolean);
PROCEDURE wFidoWriteHeader      (DoKludges: Boolean);
PROCEDURE wFidoEndMessage;
{FIDO *.MSG MESSAGE READING}
PROCEDURE rFidoStartUpArea      (NetMailPath: String);
PROCEDURE rFidoGetAkas          (VAR Orig,Dest: AddrType);
FUNCTION  rFidoNumberOfMsgs     : Word;
FUNCTION  rFidoHighestMsg       : Word;
FUNCTION  rFidoOpenMessage      (MsgNum: Word): Boolean;
FUNCTION  rFidoGetString        (VAR TheString: String): Boolean;
FUNCTION  rFidoGetMsgFrom       : String;
FUNCTION  rFidoGetMsgTo         : String;
FUNCTION  rFidoGetMsgSubject    : String;
FUNCTION  rFidoGetMsgNumber     : Word;
FUNCTION  rFidoIsLocal          : Boolean;
FUNCTION  rFidoIsPrivate        : Boolean;
FUNCTION  rFidoIsCrash          : Boolean;
FUNCTION  rFidoIsFileAttached   : Boolean;
FUNCTION  rFidoIsKillSent       : Boolean;
FUNCTION  rFidoIsHoldForPickup  : Boolean;
FUNCTION  rFidoIsFileRequest    : Boolean;
FUNCTION  rFidoIsReceived       : Boolean;
FUNCTION  rFidoIsSent           : Boolean;
FUNCTION  rFidoIsTruncFile      : Boolean;
FUNCTION  rFidoIsKillFile       : Boolean;
FUNCTION  rFidoIsImmediate      : Boolean;
FUNCTION  rFidoIsExclusive      : Boolean;
FUNCTION  rFidoIsDirect         : Boolean;
PROCEDURE rFidoCloseMessage;
PROCEDURE rFidoCloseArea;
{FIDO *.MSG MESSAGE EDITING}
FUNCTION  eFidoStartUpMessage   (NetMailPath: String; MsgNumber: Word): Boolean;
PROCEDURE eFidoSetMsgFrom       (InString: String);
PROCEDURE eFidoSetMsgTo         (InString: String);
PROCEDURE eFidoSetMsgSubject    (InString: String);
PROCEDURE eFidoSetReceived      (IsOn: Boolean);
PROCEDURE eFidoSetSent          (IsOn: Boolean);
PROCEDURE eFidoKillMessage;
PROCEDURE eFidoCloseMessage;


IMPLEMENTATION


USES Dos,MkFFile,FMode,BsAkas,BsString,BsFile;


CONST FidoMsgBufferSize  = 4096;
TYPE  _FidoMsgHeader     = RECORD
      MsgFrom            : Array[1..36] Of Char;
      MsgTo              : Array[1..36] Of Char;
      MsgSubject         : Array[1..72] Of Char;
      DateTime           : Array[1..20] Of Char;
      TimesRead          : Word;
      DestNode           : Word;
      OrigNode           : Word;
      Cost               : Word;
      OrigNet            : Word;
      DestNet            : Word;
      DestZone           : Word;
      OrigZone           : Word;
      DestPoint          : Word;
      OrigPoint          : Word;
      ReplyTo            : Word;
      Attribute1         : Byte;
      Attribute2         : Byte;
      NextReply          : Word;
      END;
TYPE  _WFidoMsg          = RECORD
      MsgNumber          : Word;
      FFile              : FFileObj;
      Application        : String;
      TruncFile          : Boolean;
      KillFile           : Boolean;
      Immediate          : Boolean;
      Exclusive          : Boolean;
      Direct             : Boolean;
      MsgDate            : String[10];
      MsgTime            : String[8];
      END;
TYPE  _RFidoMsg          = RECORD
      NumMsgs            : Word;
      Indexes            : Array[1..3000] Of Word;
      MsgPath            : String[80];
      MsgNumber          : Word;
      FFile              : FFileObj;
      TruncFile          : Boolean;
      KillFile           : Boolean;
      Immediate          : Boolean;
      Exclusive          : Boolean;
      Direct             : Boolean;
      END;
TYPE  _EFidoMsg          = RECORD
      MsgPath            : String[80];
      MsgNumber          : Word;
      FFile              : FFileObj;
      TruncFile          : Boolean;
      KillFile           : Boolean;
      Immediate          : Boolean;
      Exclusive          : Boolean;
      Direct             : Boolean;
      END;
VAR   WriteFidoMsgHeader : ^_FidoMsgHeader;
      ReadFidoMsgHeader  : ^_FidoMsgHeader;
      EditFidoMsgHeader  : ^_FidoMsgHeader;
      WriteFidoMsg       : ^_WFidoMsg;
      ReadFidoMsg        : ^_RFidoMsg;
      EditFidoMsg        : ^_EFidoMsg;


FUNCTION ReturnZeroPad(InWord: Word): String;
VAR  Scrap : String;
BEGIN
     Scrap := _String(InWord);
     IF LENGTH(Scrap)=1 THEN Scrap := '0'+Scrap;
     ReturnZeroPad := Scrap;
END;


FUNCTION GetFidoDate: String;
VAR  Temp      : String;
     Hour      : Word;
     Minute    : Word;
     Second    : Word;
     Sec100    : Word;
     Year      : Word;
     Month     : Word;
     Day       : Word;
     DayOfWeek : Word;
BEGIN
     GetTime(Hour,Minute,Second,Sec100);
     GetDate(Year,Month,Day,DayOfWeek);
     Temp := _String(Year);
     Delete(Temp,1,2);
     Year := _Numeric(Temp);
     Temp := ReturnZeroPad(Day)+' ';
     CASE Month OF
     1:   Temp := Temp+'Jan '+ReturnZeroPad(Year);
     2:   Temp := Temp+'Feb '+ReturnZeroPad(Year);
     3:   Temp := Temp+'Mar '+ReturnZeroPad(Year);
     4:   Temp := Temp+'Apr '+ReturnZeroPad(Year);
     5:   Temp := Temp+'May '+ReturnZeroPad(Year);
     6:   Temp := Temp+'Jun '+ReturnZeroPad(Year);
     7:   Temp := Temp+'Jul '+ReturnZeroPad(Year);
     8:   Temp := Temp+'Aug '+ReturnZeroPad(Year);
     9:   Temp := Temp+'Sep '+ReturnZeroPad(Year);
     10:  Temp := Temp+'Oct '+ReturnZeroPad(Year);
     11:  Temp := Temp+'Nov '+ReturnZeroPad(Year);
     12:  Temp := Temp+'Dec '+ReturnZeroPad(Year);
     END;
     Temp := Temp+'  '+ReturnZeroPad(Hour)+':'+ReturnZeroPad(Minute)+':'+ReturnZeroPad(Second);
     GetFidoDate := Temp;
END;


FUNCTION GetFidoSetDate: String;
VAR  Temp      : String;
     Month     : Word;
     Day       : Word;
     Year      : Word;
BEGIN
     Month := _Numeric(_Mid(WriteFidoMsg^.MsgDate,1,2));
     Day   := _Numeric(_Mid(WriteFidoMsg^.MsgDate,4,5));
     Year  := _Numeric(_Mid(WriteFidoMsg^.MsgDate,9,10));
     Temp := ReturnZeroPad(Day)+' ';
     CASE Month OF
     1:   Temp := Temp+'Jin '+ReturnZeroPad(Year);
     2:   Temp := Temp+'Feb '+ReturnZeroPad(Year);
     3:   Temp := Temp+'Mar '+ReturnZeroPad(Year);
     4:   Temp := Temp+'Apr '+ReturnZeroPad(Year);
     5:   Temp := Temp+'May '+ReturnZeroPad(Year);
     6:   Temp := Temp+'Jun '+ReturnZeroPad(Year);
     7:   Temp := Temp+'Jul '+ReturnZeroPad(Year);
     8:   Temp := Temp+'Aug '+ReturnZeroPad(Year);
     9:   Temp := Temp+'Sep '+ReturnZeroPad(Year);
     10:  Temp := Temp+'Oct '+ReturnZeroPad(Year);
     11:  Temp := Temp+'Nov '+ReturnZeroPad(Year);
     12:  Temp := Temp+'Dec '+ReturnZeroPad(Year);
     END;
     Temp := Temp+'  '+WriteFidoMsg^.MsgTime;
     GetFidoSetDate := Temp;
END;


FUNCTION NextMsgNum(NetMailPath: String): Word;
VAR  DirInfo    : SearchRec;
     BigOne     : Word;
     SearchFile : Word;
BEGIN
     BigOne := 0;
     FindFirst(NetMailPath+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       SearchFile := _Numeric(_NoExtension(DirInfo.Name));
       IF (SearchFile>BigOne) THEN BigOne := SearchFile;
       FindNext(DirInfo);
     END;
     NextMsgNum := BigOne+1;
END;


FUNCTION GetDest: String;
VAR  Temp : String;
BEGIN
     WITH WriteFidoMsgHeader^ DO
     BEGIN
       Temp := _String(DestZone)+':'+_String(DestNet)+'/'+_String(DestNode);
     END;
     GetDest := Temp;
END;


FUNCTION GetOrig: String;
VAR  Temp : String;
BEGIN
     WITH WriteFidoMsgHeader^ DO
     BEGIN
       Temp := _String(OrigZone)+':'+_String(OrigNet)+'/'+_String(OrigNode);
     END;
     GetOrig := Temp;
END;


PROCEDURE wFidoStartNewMessage(NetMailPath,Application: String; MsgNumber: Word);
BEGIN
     NetMailPath := _Path(NetMailPath);
     _CreatePath(NetMailPath);
     New(WriteFidoMsgHeader);
     New(WriteFidoMsg);
     FillChar(WriteFidoMsgHeader^,SizeOf(WriteFidoMsgHeader^),0);
     FillChar(WriteFidoMsg^,SizeOf(WriteFidoMsg^),0);
     IF MsgNumber=0 THEN WriteFidoMsg^.MsgNumber := NextMsgNum(NetMailPath)
                    ELSE WriteFidoMsg^.MsgNumber := MsgNumber;
     WriteFidoMsg^.Application := Application;
     WriteFidoMsg^.FFile.Init(FidoMsgBufferSize);
     WriteFidoMsg^.FFile.OpenFile(NetMailPath+_String(WriteFidoMsg^.MsgNumber)+'.MSG',SetFileMode);
     wFidoSetLocal(True);
     wFidoSetPrivate(True);
     wFidoSetKillSent(True);
END;


PROCEDURE wFidoWriteString(InString: String);
BEGIN
     InString := InString+#$0D;
     WriteFidoMsg^.FFile.BlkWrite(InString[1],LENGTH(InString));
END;


PROCEDURE wFidoWriteStringWrap(InString: String);
BEGIN
     InString := InString+#$8D;
     WriteFidoMsg^.FFile.BlkWrite(InString[1],LENGTH(InString));
END;


PROCEDURE wFidoWriteChar(InChar: Char);
BEGIN
     WriteFidoMsg^.FFile.BlkWrite(InChar,1);
END;


PROCEDURE wFidoSetMsgFrom(InString: String);
BEGIN
     InString := _Mid(InString,1,36);
     Move(InString[1],WriteFidoMsgHeader^.MsgFrom,LENGTH(InString));
END;


PROCEDURE wFidoSetMsgTo(InString: String);
BEGIN
     InString := _Mid(InString,1,36);
     Move(InString[1],WriteFidoMsgHeader^.MsgTo,LENGTH(InString));
END;


PROCEDURE wFidoSetMsgSubject(InString: String);
BEGIN
     InString := _Mid(InString,1,72);
     Move(InString[1],WriteFidoMsgHeader^.MsgSubject,LENGTH(InString));
END;


PROCEDURE wFidoSetAkas(Orig,Dest: AddrType);
BEGIN
     WITH WriteFidoMsgHeader^ DO
     BEGIN
       OrigZone  := Orig.Zone;
       OrigNet   := Orig.Net;
       OrigNode  := Orig.Node;
       OrigPoint := Orig.Point;
       DestZone  := Dest.Zone;
       DestNet   := Dest.Net;
       DestNode  := Dest.Node;
       DestPoint := Dest.Point;
     END;
END;


PROCEDURE wFidoSetPrivate(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 1)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 1));
END;


PROCEDURE wFidoSetCrash(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 2)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 2));
END;


PROCEDURE wFidoSetReceived(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 4)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 4));
END;


PROCEDURE wFidoSetSent(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 8)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 8));
END;


PROCEDURE wFidoSetFileAttached(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 16)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 16));
END;


PROCEDURE wFidoSetKillSent(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 OR 128)
             ELSE WriteFidoMsgHeader^.Attribute1 := (WriteFidoMsgHeader^.Attribute1 AND (NOT 128));
END;


PROCEDURE wFidoSetLocal(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 OR 1)
             ELSE WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 AND (NOT 1));
END;


PROCEDURE wFidoSetHoldForPickup(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 OR 2)
             ELSE WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 AND (NOT 2));
END;


PROCEDURE wFidoSetFileRequest(IsOn: Boolean);
BEGIN
     IF IsOn THEN WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 OR 8)
             ELSE WriteFidoMsgHeader^.Attribute2 := (WriteFidoMsgHeader^.Attribute2 AND (NOT 8));
END;


PROCEDURE wFidoSetTruncFile(IsOn: Boolean);
BEGIN
     WriteFidoMsg^.TruncFile := IsOn;
END;


PROCEDURE wFidoSetKillFile(IsOn: Boolean);
BEGIN
     WriteFidoMsg^.KillFile := IsOn;
END;


PROCEDURE wFidoSetImmediate(IsOn: Boolean);
BEGIN
     WriteFidoMsg^.Immediate := IsOn;
END;


PROCEDURE wFidoSetExclusive(IsOn: Boolean);
BEGIN
     WriteFidoMsg^.Exclusive := IsOn;
END;


PROCEDURE wFidoSetDirect(IsOn: Boolean);
BEGIN
     WriteFidoMsg^.Direct := IsOn;
END;


PROCEDURE wFidoWriteHeader(DoKludges: Boolean);
VAR  Temp    : String;
     TmpAddr : AddrType;
BEGIN
     IF (WriteFidoMsg^.MsgDate<>'')
        THEN Temp := GetFidoSetDate+#0
        ELSE Temp := GetFidoDate+#0;
     Move(Temp[1],WriteFidoMsgHeader^.DateTime,20);
     WriteFidoMsg^.FFile.BlkWrite(WriteFidoMsgHeader^,SizeOf(WriteFidoMsgHeader^));
     IF DoKludges THEN
     BEGIN
       IF (WriteFidoMsgHeader^.OrigPoint<>0) THEN wFidoWriteString(#1+'FMPT '+_String(WriteFidoMsgHeader^.OrigPoint));
       IF (WriteFidoMsgHeader^.DestPoint<>0) THEN wFidoWriteString(#1+'TOPT '+_String(WriteFidoMsgHeader^.DestPoint));
       wFidoWriteString(#1+'INTL '+GetDest+' '+GetOrig);
       TmpAddr.Zone  := WriteFidoMsgHeader^.OrigZone;
       TmpAddr.Net   := WriteFidoMsgHeader^.OrigNet;
       TmpAddr.Node  := WriteFidoMsgHeader^.OrigNode;
       TmpAddr.Point := WriteFidoMsgHeader^.OrigPoint;
       wFidoWriteString(GetMsgId(TmpAddr));
       wFidoWriteString(#1+'PID: '+WriteFidoMsg^.Application);
       Temp := '';
       IF WriteFidoMsg^.TruncFile THEN Temp := Temp+'TFS ';
       IF WriteFidoMsg^.KillFile THEN Temp := Temp+'KFS ';
       IF WriteFidoMsg^.Immediate THEN Temp := Temp+'IMM ';
       IF WriteFidoMsg^.Exclusive THEN Temp := Temp+'EXC ';
       IF WriteFidoMsg^.Direct THEN Temp := Temp+'DIR ';
       IF (Temp<>'') THEN
       BEGIN
         DEC(Temp[0]);
         wFidoWriteString(#1+'FLAGS '+Temp);
       END;
     END;
END;


PROCEDURE wFidoSetDate(InString: String);
BEGIN
     WriteFidoMsg^.MsgDate := InString;
END;


PROCEDURE wFidoSetTime(InString: String);
BEGIN
     WriteFidoMsg^.MsgTime := InString;
END;


PROCEDURE wFidoEndMessage;
BEGIN
     WriteFidoMsg^.FFile.CloseFile;
     WriteFidoMsg^.FFile.Done;
     Dispose(WriteFidoMsgHeader);
     Dispose(WriteFidoMsg);
END;


FUNCTION CharArrayToString(InArray: Array Of Char): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := '';
     FOR Loop := 0 TO (SizeOf(InArray)-1) DO
     BEGIN
       IF (InArray[Loop]<>#0) THEN Temp := Temp+InArray[Loop];
     END;
     CharArrayToString := Temp;
END;


PROCEDURE ReIndex;
VAR  DirInfo  : SearchRec;
     J2       : Longint;
     I2       : Longint;
     N2       : Longint;
     Jump     : Longint;
     TempIndx : Word;
     Done     : Boolean;
BEGIN
     FindFirst(ReadFidoMsg^.MsgPath+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       IF ReadFidoMsg^.NumMsgs<3000 THEN
       BEGIN
         INC(ReadFidoMsg^.NumMsgs);
         ReadFidoMsg^.Indexes[ReadFidoMsg^.NumMsgs] := _Numeric(_NoExtension(DirInfo.Name));
       END;
       FindNext(DirInfo);
     END;
     IF (ReadFidoMsg^.NumMsgs<>0) THEN
     BEGIN
       N2   := ReadFidoMsg^.NumMsgs;
       Jump := N2;
       WHILE (Jump>1) DO
       BEGIN
         Jump := Jump DIV 2;
         REPEAT
           Done := true;
           FOR J2 := 1 to (N2-Jump) DO
           BEGIN
             I2 := J2+Jump;
             IF ReadFidoMsg^.Indexes[j2]>ReadFidoMsg^.Indexes[i2] THEN
             BEGIN
               TempIndx                 := ReadFidoMsg^.Indexes[j2];
               ReadFidoMsg^.Indexes[j2] := ReadFidoMsg^.Indexes[i2];
               ReadFidoMsg^.Indexes[i2] := TempIndx;
               Done := false;
             END;
           END;
         UNTIL Done;
       END;
     END;
END;


PROCEDURE rFidoStartUpArea(NetMailPath: String);
BEGIN
     NetMailPath := _Path(NetMailPath);
     _CreatePath(NetMailPath);
     New(ReadFidoMsg);
     FillChar(ReadFidoMsg^,SizeOf(ReadFidoMsg^),0);
     ReadFidoMsg^.MsgPath := NetMailPath;
     ReIndex;
END;


PROCEDURE rFidoCloseArea;
BEGIN
     Dispose(ReadFidoMsg);
END;


FUNCTION rFidoNumberOfMsgs: Word;
BEGIN
     rFidoNumberOfMsgs := ReadFidoMsg^.NumMsgs;
END;


FUNCTION rFidoHighestMsg: Word;
BEGIN
     IF ReadFidoMsg^.NumMsgs=0
        THEN rFidoHighestMsg := 0
        ELSE rFidoHighestMsg := ReadFidoMsg^.Indexes[ReadFidoMsg^.NumMsgs];
END;


PROCEDURE rFidoCloseMessage;
BEGIN
     ReadFidoMsg^.FFile.CloseFile;
     ReadFidoMsg^.FFile.Done;
     Dispose(ReadFidoMsgHeader);
END;


FUNCTION rFidoGetMsgFrom: String;
BEGIN
     rFidoGetMsgFrom := CharArrayToString(ReadFidoMsgHeader^.MsgFrom);
END;


FUNCTION rFidoGetMsgTo: String;
BEGIN
     rFidoGetMsgTo := CharArrayToString(ReadFidoMsgHeader^.MsgTo);
END;


FUNCTION rFidoGetMsgSubject: String;
BEGIN
     rFidoGetMsgSubject := CharArrayToString(ReadFidoMsgHeader^.MsgSubject);
END;


FUNCTION rFidoIsPrivate: Boolean;
BEGIN
     rFidoIsPrivate := ((ReadFidoMsgHeader^.Attribute1 AND 1)<>0);
END;


FUNCTION rFidoIsCrash: Boolean;
BEGIN
     rFidoIsCrash := ((ReadFidoMsgHeader^.Attribute1 AND 2)<>0);
END;


FUNCTION rFidoIsReceived: Boolean;
BEGIN
     rFidoIsReceived := ((ReadFidoMsgHeader^.Attribute1 AND 4)<>0);
END;


FUNCTION rFidoIsSent: Boolean;
BEGIN
     rFidoIsSent := ((ReadFidoMsgHeader^.Attribute1 AND 8)<>0);
END;


FUNCTION rFidoIsFileAttached: Boolean;
BEGIN
     rFidoIsFileAttached := ((ReadFidoMsgHeader^.Attribute1 AND 16)<>0);
END;


FUNCTION rFidoIsKillSent: Boolean;
BEGIN
     rFidoIsKillSent := ((ReadFidoMsgHeader^.Attribute1 AND 128)<>0);
END;


FUNCTION rFidoIsLocal: Boolean;
BEGIN
     rFidoIsLocal := ((ReadFidoMsgHeader^.Attribute2 AND 1)<>0);
END;


FUNCTION rFidoIsHoldForPickup: Boolean;
BEGIN
     rFidoIsHoldForPickup := ((ReadFidoMsgHeader^.Attribute2 AND 2)<>0);
END;


FUNCTION rFidoIsFileRequest: Boolean;
BEGIN
     rFidoIsFileRequest := ((ReadFidoMsgHeader^.Attribute2 AND 8)<>0);
END;


FUNCTION rFidoIsTruncFile: Boolean;
BEGIN
     rFidoIsTruncFile := ReadFidoMsg^.TruncFile;
END;


FUNCTION rFidoIsKillFile: Boolean;
BEGIN
     rFidoIsKillFile := ReadFidoMsg^.KillFile;
END;


FUNCTION rFidoIsImmediate: Boolean;
BEGIN
     rFidoIsImmediate := ReadFidoMsg^.Immediate;
END;


FUNCTION rFidoIsExclusive: Boolean;
BEGIN
     rFidoIsExclusive := ReadFidoMsg^.Exclusive;
END;


FUNCTION rFidoIsDirect: Boolean;
BEGIN
     rFidoIsDirect := ReadFidoMsg^.Direct;
END;


PROCEDURE rFidoGetAkas(VAR Orig,Dest: AddrType);
BEGIN
     WITH ReadFidoMsgHeader^ DO
     BEGIN
       Orig.Zone  := OrigZone;
       Orig.Net   := OrigNet;
       Orig.Node  := OrigNode;
       Orig.Point := OrigPoint;
       Dest.Zone  := DestZone;
       Dest.Net   := DestNet;
       Dest.Node  := DestNode;
       Dest.Point := DestPoint;
     END;
END;


FUNCTION rFidoOpenMessage(MsgNum: Word): Boolean;
VAR  Temp      : String;
     Temp2     : String;
     BytesRead : Word;
     Stat      : Boolean;
     NeedAkas  : Boolean;
     Work      : Word;
BEGIN
     Temp := ReadFidoMsg^.MsgPath+_String(ReadFidoMsg^.Indexes[MsgNum])+'.MSG';
     New(ReadFidoMsgHeader);
     IF NOT(_FileExists(Temp)) THEN
     BEGIN
       Dispose(ReadFidoMsgHeader);
       rFidoOpenMessage := False;
       Exit;
     END;
     ReadFidoMsg^.FFile.Init(FidoMsgBufferSize);
     IF ReadFidoMsg^.FFile.OpenFile(Temp,SetFileMode) THEN
     BEGIN
       ReadFidoMsg^.MsgNumber := ReadFidoMsg^.Indexes[MsgNum];
       ReadFidoMsg^.FFile.BlkRead(ReadFidoMsgHeader^,SizeOf(ReadFidoMsgHeader^),BytesRead);
       ReadFidoMsgHeader^.OrigZone  := 0;
       ReadFidoMsgHeader^.DestZone  := 0;
       ReadFidoMsgHeader^.OrigPoint := 0;
       ReadFidoMsgHeader^.DestPoint := 0;
       NeedAkas := True;
       REPEAT
         Stat := rFidoGetString(Temp);
         IF Pos(#1'FMPT ',Temp)=1 THEN
         BEGIN
           Delete(Temp,1,6);
           ReadFidoMsgHeader^.OrigPoint := _Numeric(Temp);
         END
         ELSE IF Pos(#1'TOPT ',Temp)=1 THEN
         BEGIN
           Delete(Temp,1,6);
           ReadFidoMsgHeader^.DestPoint := _Numeric(Temp);
         END
         ELSE IF Pos(#1'INTL ',Temp)=1 THEN
         BEGIN
           IF NeedAkas THEN
           BEGIN
             Delete(Temp,1,6);
             Work := Pos(#32,Temp);
             Temp2 := _Mid(Temp,1,Work-1);
             AddressStringBreakupW(Temp2,ReadFidoMsgHeader^.DestZone,ReadFidoMsgHeader^.DestNet,
                                   ReadFidoMsgHeader^.DestNode,ReadFidoMsgHeader^.DestPoint);
             Temp2 := _Mid(Temp,Work+1,LENGTH(Temp));
             AddressStringBreakupW(Temp2,ReadFidoMsgHeader^.OrigZone,ReadFidoMsgHeader^.OrigNet,
                                   ReadFidoMsgHeader^.OrigNode,ReadFidoMsgHeader^.OrigPoint);
             NeedAkas := False;
           END;
         END
         ELSE IF Pos(#1'MSGID: ',Temp)=1 THEN
         BEGIN
           IF NeedAkas THEN
           BEGIN
             Delete(Temp,1,8);
             Work := Pos(':',Temp);
             ReadFidoMsgHeader^.OrigZone := _Numeric(_Mid(Temp,1,Work-1));
             ReadFidoMsgHeader^.DestZone := _Numeric(_Mid(Temp,1,Work-1));
           END;
         END
         ELSE IF Pos(#1'FLAGS ',Temp)=1 THEN
         BEGIN
           Delete(Temp,1,7);
           IF (Pos('TFS',Temp)<>0) THEN ReadFidoMsg^.TruncFile := True;
           IF (Pos('KFS',Temp)<>0) THEN ReadFidoMsg^.KillFile  := True;
           IF (Pos('IMM',Temp)<>0) THEN ReadFidoMsg^.Immediate := True;
           IF (Pos('EXC',Temp)<>0) THEN ReadFidoMsg^.Exclusive := True;
           IF (Pos('DIR',Temp)<>0) THEN ReadFidoMsg^.Direct    := True;
         END
         ELSE IF (Pos('#1',Temp)<>1) THEN
         BEGIN
           Stat := False;
         END;
       UNTIL NOT(Stat);
       ReadFidoMsg^.FFile.SeekFile(SizeOf(ReadFidoMsgHeader^));
     END
     ELSE
     BEGIN
       ReadFidoMsg^.FFile.Done;
       Dispose(ReadFidoMsgHeader);
       rFidoOpenMessage := False;
       Exit;
     END;
     rFidoOpenMessage := True;
END;


FUNCTION rFidoGetString(VAR TheString: String): Boolean;
VAR  Temp      : String;
     LastSpace : Byte;
     AllDone   : Boolean;
     C         : Char;
     BytesRead : Word;
     FPos      : Longint;
BEGIN
     Temp      := '';
     AllDone   := False;
     LastSpace := 1;
     FPos      := ReadFidoMsg^.FFile.FilePos;
     REPEAT
       ReadFidoMsg^.FFile.BlkRead(C,1,BytesRead);
       IF BytesRead=0 THEN
       BEGIN
         TheString := '';
         rFidoGetString := False;
         Exit;
       END
       ELSE
       BEGIN
         IF C=#$8D THEN C := #32;
         CASE C OF
         #$0A:  ;
         #$00:  BEGIN
                  IF Temp='' THEN
                  BEGIN
                    TheString := '';
                    rFidoGetString := False;
                    Exit;
                  END;
                END;
         #$0D:  AllDone := True;
         ELSE   BEGIN {Normal Character}
                  Temp := Temp+C;
                  IF (C=#32) THEN
                  BEGIN
                    LastSpace := LENGTH(Temp)-1;
                    FPos      := ReadFidoMsg^.FFile.FilePos;
                  END;
                  IF LENGTH(Temp)=80 THEN
                  BEGIN
                    Temp[0] := Chr(LastSpace);
                    ReadFidoMsg^.FFile.SeekFile(FPos);
                    AllDone := True;
                  END;
                END;
         END;
       END;
     UNTIL AllDone;
     TheString := Temp;
     rFidoGetString := True;
END;


FUNCTION rFidoGetMsgNumber: Word;
BEGIN
     rFidoGetMsgNumber := ReadFidoMsg^.MsgNumber;
END;


FUNCTION eFidoStartUpMessage(NetMailPath: String; MsgNumber: Word): Boolean;
VAR  BytesRead : Word;
BEGIN
     NetMailPath := _Path(NetMailPath);
     _CreatePath(NetMailPath);
     IF NOT(_FileExists(NetMailPath+_String(MsgNumber)+'.MSG')) THEN
     BEGIN
       eFidoStartupMessage := False;
       Exit;
     END;
     New(EditFidoMsg);
     New(EditFidoMsgHeader);
     FillChar(EditFidoMsg^,SizeOf(EditFidoMsg^),0);
     FillChar(EditFidoMsgHeader^,SizeOf(EditFidoMsgHeader^),0);
     EditFidoMsg^.FFile.Init(FidoMsgBufferSize);
     EditFidoMsg^.MsgPath   := NetMailPath;
     EditFidoMsg^.MsgNumber := MsgNumber;
     IF NOT(EditFidoMsg^.FFile.OpenFile(NetMailPath+_String(MsgNumber)+'.MSG',SetFileMode)) THEN
     BEGIN
       EditFidoMsg^.FFile.Done;
       Dispose(EditFidoMsgHeader);
       Dispose(EditFidoMsg);
       eFidoStartupMessage := False;
       Exit;
     END;
     EditFidoMsg^.FFile.BlkRead(EditFidoMsgHeader^,SizeOf(EditFidoMsgHeader^),BytesRead);
     eFidoStartupMessage := True;
END;


PROCEDURE eFidoSetReceived(IsOn: Boolean);
BEGIN
     IF IsOn THEN EditFidoMsgHeader^.Attribute1 := (EditFidoMsgHeader^.Attribute1 OR 4)
             ELSE EditFidoMsgHeader^.Attribute1 := (EditFidoMsgHeader^.Attribute1 AND (NOT 4));
END;


PROCEDURE eFidoSetSent(IsOn: Boolean);
BEGIN
     IF IsOn THEN EditFidoMsgHeader^.Attribute1 := (EditFidoMsgHeader^.Attribute1 OR 8)
             ELSE EditFidoMsgHeader^.Attribute1 := (EditFidoMsgHeader^.Attribute1 AND (NOT 8));
END;


PROCEDURE eFidoSetMsgFrom(InString: String);
BEGIN
     FillChar(EditFidoMsgHeader^.MsgFrom,SizeOf(EditFidoMsgHeader^.MsgFrom),0);
     InString := _Mid(InString,1,36);
     Move(InString[1],EditFidoMsgHeader^.MsgFrom,LENGTH(InString));
END;


PROCEDURE eFidoSetMsgTo(InString: String);
BEGIN
     FillChar(EditFidoMsgHeader^.MsgTo,SizeOf(EditFidoMsgHeader^.MsgTo),0);
     InString := _Mid(InString,1,36);
     Move(InString[1],EditFidoMsgHeader^.MsgTo,LENGTH(InString));
END;


PROCEDURE eFidoSetMsgSubject(InString: String);
BEGIN
     FillChar(EditFidoMsgHeader^.MsgSubject,SizeOf(EditFidoMsgHeader^.MsgSubject),0);
     InString := _Mid(InString,1,72);
     Move(InString[1],EditFidoMsgHeader^.MsgSubject,LENGTH(InString));
END;


PROCEDURE eFidoCloseMessage;
BEGIN
     EditFidoMsg^.FFile.SeekFile(0);
     EditFidoMsg^.FFile.BlkWrite(EditFidoMsgHeader^,SizeOf(EditFidoMsgHeader^));
     EditFidoMsg^.FFile.Done;
     Dispose(EditFidoMsgHeader);
     Dispose(EditFidoMsg);
END;


PROCEDURE eFidoKillMessage;
BEGIN
     EditFidoMsg^.FFile.Done;
     _EraseFile(EditFidoMsg^.MsgPath+_String(EditFidoMsg^.MsgNumber)+'.MSG');
     Dispose(EditFidoMsgHeader);
     Dispose(EditFidoMsg);
END;


END.


LAST READS??
