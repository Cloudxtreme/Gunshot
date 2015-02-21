{$I DEFINES.INC}
UNIT NetMail;


INTERFACE


USES Globals,Shotgun;


PROCEDURE IndexAreas;
PROCEDURE AddThePacket;
PROCEDURE MakeTheMainPacketHeader(DestAddr: AddrType);
PROCEDURE PktToMSG           (InString: String);
PROCEDURE FailedFileRequest  (YourAka,TheirAka: AddrType; FName: String; Num: Word);
PROCEDURE CreateType2PPacket (FromAka,ToAka: AddrType; Password: String);
PROCEDURE GetTheMessage      (Num: Longint);
PROCEDURE TargetNode         (InAddress: AddrType; VAR GoingTo: AddrType);
FUNCTION  GetFidoDate        : String;
FUNCTION  NextMsgNum         : Word;


IMPLEMENTATION


USES Dos,Transfer,DrawScrn,BsLog,Misc,Version,BsAkas,BsFile,BsString;


FUNCTION GetSessionPassword(WorkAddr: AddrType): String;
BEGIN
     IF _FileExists('\SHOTGUN\DATA\PASSWORD.DAT') THEN
     BEGIN
          ASSIGN(FSessionPW,'\SHOTGUN\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF AkasMatch(WorkAddr,SessionPW.SystemAddress) THEN
                BEGIN
                     CLOSE(FSessionPW);
                     GetSessionPassword := _UpperCase(SessionPW.SystemPW);
                     Exit;
                END;
          UNTIL EOF(FSessionPW);
          CLOSE(FSessionPW);
     END;
     GetSessionPassword := '';
END;


PROCEDURE TargetNode(InAddress: AddrType; VAR GoingTo: AddrType);
VAR  RouteZone  : String[20];
     RouteNet   : String[20];
     RouteNode  : String[20];
     RoutePoint : String[20];
     DidIt      : Boolean;
     WorkAddr   : AddrType;
LABEL             SkipIt;
BEGIN
     GoingTo := InAddress;
     DidIt   := False;
     IF _FileExists(Shotgun_Directory+'\DATA\ROUTE.DAT') THEN
     BEGIN
          ASSIGN(FCallRouting,Shotgun_Directory+'\DATA\ROUTE.DAT');
          RESET(FCallRouting);
          REPEAT
                READ(FCallRouting,CallRouting);
                AddressStringBreakup(CallRouting.SourceAddr,RouteZone,RouteNet,RouteNode,RoutePoint);
                {Wildcard Zone}
                IF (RouteZone<>'*') THEN
                BEGIN
                     IF (_Numeric(RouteZone)<>InAddress.Zone) THEN GOTO SkipIt;
                END
                ELSE RouteZone := _String(InAddress.Zone);
                {Wildcard Net}
                IF (RouteNet<>'*') THEN
                BEGIN
                     IF (_Numeric(RouteNet)<>InAddress.Net) THEN GOTO SkipIt;
                END
                ELSE RouteNet := _String(InAddress.Net);
                {Wildcard Node}
                IF (RouteNode<>'*') THEN
                BEGIN
                     IF (_Numeric(RouteNode)<>InAddress.Node) THEN GOTO SkipIt;
                END
                ELSE RouteNode := _String(InAddress.Node);
                {Wildcard Point}
                IF (RoutePoint<>'*') THEN
                BEGIN
                     IF (_Numeric(RoutePoint)<>InAddress.Point) THEN GOTO SkipIt;
                END
                ELSE RoutePoint := _String(InAddress.Point);
                {Straight Compare}
                IF ((_Numeric(RouteZone)=InAddress.Zone) AND (_Numeric(RouteNet)=InAddress.Net) AND
                   (_Numeric(RouteNode)=InAddress.Node) AND (_Numeric(RoutePoint)=InAddress.Point)) THEN
                BEGIN
                     GoingTo := CallRouting.DestAddr;
                     DidIt   := True;
                END;
                SkipIt:
          UNTIL EOF(FCallRouting);
          CLOSE(FCallRouting);
     END;
     IF NOT(DidIt) THEN
     BEGIN
          WorkAddr := InAddress;
          WorkAddr.Point := 0;
          IF (InAddress.Point<>0) THEN
          BEGIN
               IF NOT(IsOurNode(WorkAddr)) THEN
               BEGIN
                    InAddress.Point := 0;
                    GoingTo := InAddress;
               END;
          END;
     END;
END;


PROCEDURE IndexAreas;
VAR  LastRead   : Word;
     FFile      : File;
     Loop       : Word;
     Loop2      : Word;
     Work       : Word;
     DirInfo    : SearchRec;
     SearchFile : String;
BEGIN
     {GET THE LAST READ POINTER}
     LastRead := 0;
     ASSIGN(FFile,MailerInfo.NetMail+'LASTREAD');
     {$I-}RESET(FFile,1);{$I+}
     IF (IOResult<>0) THEN
     BEGIN
          REWRITE(FFile);
          BLOCKWRITE(FFile,LastRead,SizeOf(LastRead));
          CLOSE(FFile);
     END
     ELSE
     BEGIN
          BLOCKREAD(FFile,LastRead,SizeOf(LastRead));
          CLOSE(FFile);
     END;
     {GET ALL THE MESSAGE NAMES}
     NumMsgs := 0;
     FindFirst(MailerInfo.NetMail+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          INC(NumMsgs);
          SearchFile := _NoExtension(_UpperCase(DirInfo.Name));
          Indexes[NumMsgs] := _Numeric(SearchFile);
          FindNext(DirInfo);
     END;
     {CREATE THE SORTED INDEXES}
     IF (NumMsgs<>0) THEN
     BEGIN
          FOR Loop := 1 TO NumMsgs DO
          BEGIN
               FOR Loop2 := 1 TO NumMsgs DO
               BEGIN
                    IF Indexes[Loop]<Indexes[Loop2] THEN
                    BEGIN
                         Work := Indexes[Loop];
                         Indexes[Loop]  := Indexes[Loop2];
                         Indexes[Loop2] := Work;
                    END;
               END;
          END;
          FOR Loop := 1 TO NumMsgs DO
          BEGIN
               IF (Indexes[Loop]>=LastRead) THEN
               BEGIN
                    Current := Loop;
                    LastRead := Indexes[Loop];
                    {REWRITE THE LAST READ}
                    ASSIGN(FFile,MailerInfo.NetMail+'LASTREAD');
                    RESET(FFile,1);
                    BLOCKWRITE(FFile,LastRead,SizeOf(LastRead));
                    CLOSE(FFile);
                    Exit;
               END;
          END;
          Current  := NumMsgs;
          LastRead := Indexes[Current];
          {REWRITE THE LAST READ}
          ASSIGN(FFile,MailerInfo.NetMail+'LASTREAD');
          RESET(FFile,1);
          BLOCKWRITE(FFile,LastRead,SizeOf(LastRead));
          CLOSE(FFile);
     END;
END;


FUNCTION FirstZero(InArray: Array Of Char): Byte;
VAR  Loop : Word;
BEGIN
     FOR Loop := 0 TO (SizeOf(InArray)-1) DO
     BEGIN
          IF InArray[Loop]=#0 THEN
          BEGIN
               FirstZero := Loop+1;
               Exit;
          END;
     END;
     FirstZero := SizeOf(InArray)+1;
END;


PROCEDURE LoadInTheHeader;
VAR  Work  : Word;
     TTime : String;
     Temp  : String;
BEGIN
     FillChar(FastBaseHdr,SizeOf(FastBaseHdr),0);
     FastBaseHdr.MsgNumber := Indexes[Current];
     {Message From}
     Work := FirstZero(FidoHeader.MsgFrom);
     Move(FidoHeader.MsgFrom,FastBaseHdr.MsgFrom[1],Work-1);
     FastBaseHdr.MsgFrom[0] := Chr(Work-1);
     {Message To}
     Work := FirstZero(FidoHeader.MsgTo);
     Move(FidoHeader.MsgTo,FastBaseHdr.MsgTo[1],Work-1);
     FastBaseHdr.MsgTo[0] := Chr(Work-1);
     {Message Subject}
     Work := FirstZero(FidoHeader.MsgSubject);
     Move(FidoHeader.MsgSubject,FastBaseHdr.MsgSubject[1],Work-1);
     FastBaseHdr.MsgSubject[0] := Chr(Work-1);
     {Message Destination Node}
     FastBaseHdr.Dest.Net  := FidoHeader.DestNet;
     FastBaseHdr.Dest.Node := FidoHeader.DestNode;
     FastBaseHdr.Orig.Net  := FidoHeader.OrigNet;
     FastBaseHdr.Orig.Node := FidoHeader.OrigNode;
     {Message Flags}
     FastBaseHdr.Priv        := ((Lo(FidoHeader.Attribute) AND 001)<>0);
     FastBaseHdr.Crash       := ((Lo(FidoHeader.Attribute) AND 002)<>0);
     FastBaseHdr.Recv        := ((Lo(FidoHeader.Attribute) AND 004)<>0);
     FastBaseHdr.Sent        := ((Lo(FidoHeader.Attribute) AND 008)<>0);
     FastBaseHdr.FileAttach  := ((Lo(FidoHeader.Attribute) AND 016)<>0);
     FastBaseHdr.InTransit   := ((Lo(FidoHeader.Attribute) AND 032)<>0);
     FastBaseHdr.Orphan      := ((Lo(FidoHeader.Attribute) AND 064)<>0);
     FastBaseHdr.KillSent    := ((Lo(FidoHeader.Attribute) AND 128)<>0);
     FastBaseHdr.Local       := ((Hi(FidoHeader.Attribute) AND 001)<>0);
     FastBaseHdr.Hold        := ((Hi(FidoHeader.Attribute) AND 002)<>0);
     FastBaseHdr.FileRequest := ((Hi(FidoHeader.Attribute) AND 008)<>0);
     {Message Time/Date}
     Move(FidoHeader.DateTime,TTime[1],19); TTime[0] := #19;
     IF _Numeric(_Mid(TTime,8,9))>79 THEN FastBaseHdr.MsgDateTime.Year := _Numeric(_Mid(TTime,8,9))+1900
                                     ELSE  FastBaseHdr.MsgDateTime.Year := _Numeric(_Mid(TTime,8,9))+2000;
     FastBaseHdr.MsgDateTime.Day   := _Numeric(_Mid(TTime,1,2));
     FastBaseHdr.MsgDateTime.Hour  := _Numeric(_Mid(TTime,12,13));
     FastBaseHdr.MsgDateTime.Min   := _Numeric(_Mid(TTime,15,16));
     FastBaseHdr.MsgDateTime.Sec   := _Numeric(_Mid(TTime,18,19));
     Temp := _UpperCase(_Mid(TTime,4,6));
          IF Temp='JAN' THEN FastBaseHdr.MsgDateTime.Month := 1
     ELSE IF Temp='FEB' THEN FastBaseHdr.MsgDateTime.Month := 2
     ELSE IF Temp='MAR' THEN FastBaseHdr.MsgDateTime.Month := 3
     ELSE IF Temp='APR' THEN FastBaseHdr.MsgDateTime.Month := 4
     ELSE IF Temp='MAY' THEN FastBaseHdr.MsgDateTime.Month := 5
     ELSE IF Temp='JUN' THEN FastBaseHdr.MsgDateTime.Month := 6
     ELSE IF Temp='JUL' THEN FastBaseHdr.MsgDateTime.Month := 7
     ELSE IF Temp='AUG' THEN FastBaseHdr.MsgDateTime.Month := 8
     ELSE IF Temp='SEP' THEN FastBaseHdr.MsgDateTime.Month := 9
     ELSE IF Temp='OCT' THEN FastBaseHdr.MsgDateTime.Month := 10
     ELSE IF Temp='NOV' THEN FastBaseHdr.MsgDateTime.Month := 11
     ELSE IF Temp='DEC' THEN FastBaseHdr.MsgDateTime.Month := 12;
END;


PROCEDURE GetTheMessage(Num: Longint);
VAR  MsgText          : String;
     FFile            : File;
     CurPointer       : Word;
     AllDone          : Boolean;
     Loop             : Word;
     Temp             : String;
     BytesRead        : Word;
BEGIN
     ASSIGN(FFile,MailerInfo.NetMail+_String(Indexes[Num])+'.MSG');
     {$I-}RESET(FFile,1);{$I+}
     IF (IOResult<>0) THEN Exit;
     BLOCKREAD(FFile,FidoHeader,SizeOf(FidoHeader),BytesRead);
     BLOCKREAD(FFile,Buffer^[1],SizeOf(Buffer^),BytesRead);
     CLOSE(FFile);
     Buffer^[BytesRead+1] := #0;
     Buffer^[BytesRead+2] := #0;
     IntlKludge  := '';
     MsgIDKludge := '';
     FlagsKludge := '';
     FmPtKludge  := '';
     ToPtKludge  := '';
     Current     := Num;
     CurPointer  := 0;
     MsgText     := '';
     AllDone     := False;
     REPEAT
           INC(CurPointer);
           CASE Buffer^[CurPointer] OF
           #0:  BEGIN {End Of Message}
                     IF ((MsgText[1]=#1) AND (MsgText<>'')) THEN
                     BEGIN
                          IF _Mid(MsgText,2,6)='FMPT ' THEN FmPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='TOPT ' THEN ToPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='INTL ' THEN IntlKludge := MsgText;
                          IF _Mid(MsgText,2,8)='MSGID: ' THEN MsgIdKludge := MsgText;
                          IF _Mid(MsgText,2,7)='FLAGS ' THEN FlagsKludge := MsgText;
                     END;
                     AllDone := True;
                END;
           #10: BEGIN {Line Feed}
                     IF Buffer^[CurPointer+1]=#13 THEN INC(CurPointer);
                     IF ((MsgText[1]=#1) AND (MsgText<>'')) THEN
                     BEGIN
                          IF _Mid(MsgText,2,6)='FMPT ' THEN FmPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='TOPT ' THEN ToPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='INTL ' THEN IntlKludge := MsgText;
                          IF _Mid(MsgText,2,8)='MSGID: ' THEN MsgIdKludge := MsgText;
                          IF _Mid(MsgText,2,7)='FLAGS ' THEN FlagsKludge := MsgText;
                     END;
                     MsgText := '';
                END;
           #13: BEGIN {Carriage Return}
                     IF Buffer^[CurPointer+1]=#10 THEN INC(CurPointer);
                     IF ((MsgText[1]=#1) AND (MsgText<>'')) THEN
                     BEGIN
                          IF _Mid(MsgText,2,6)='FMPT ' THEN FmPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='TOPT ' THEN ToPtKludge := MsgText;
                          IF _Mid(MsgText,2,6)='INTL ' THEN IntlKludge := MsgText;
                          IF _Mid(MsgText,2,8)='MSGID: ' THEN MsgIdKludge := MsgText;
                          IF _Mid(MsgText,2,7)='FLAGS ' THEN FlagsKludge := MsgText;
                     END;
                     MsgText := '';
                END;
           ELSE IF (LENGTH(MsgText)<>255) THEN MsgText := MsgText+Buffer^[CurPointer];
           END;
     UNTIL AllDone;
     LoadInTheHeader;
     IF (IntlKludge<>'') THEN
     BEGIN
          Delete(IntlKludge,1,6);
          Loop := Pos(' ',IntlKludge);
          Temp := _Mid(IntlKludge,1,Loop-1);
          StringToAddress(Temp,FastBaseHdr.Dest);
          Temp := _Mid(IntlKludge,Loop+1,LENGTH(IntlKludge));
          StringToAddress(Temp,FastBaseHdr.Orig);
     END
     ELSE IF (MsgIdKludge<>'') THEN
     BEGIN
          Delete(MsgIdKludge,1,8);
          Loop := Pos(':',MsgIdKludge);
          FastBaseHdr.Dest.Zone := _Numeric(_Mid(MsgIdKludge,1,Loop-1));
          FastBaseHdr.Orig.Zone := _Numeric(_Mid(MsgIdKludge,1,Loop-1));
     END
     ELSE
     BEGIN
          IF FastBaseHdr.Dest.Zone=0 THEN
          BEGIN
               ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
               RESET(FNetwork);
               REPEAT
                     READ(FNetwork,Network);
                     IF ((Network.Net_Address.Net=FastBaseHdr.Orig.Net) AND
                        (Network.Net_Address.Node=FastBaseHdr.Orig.Node)) THEN
                     BEGIN
                          FastBaseHdr.Dest.Zone := Network.Net_Address.Zone;
                          FastBaseHdr.Orig.Zone := Network.Net_Address.Zone;
                     END;
               UNTIL ((EOF(FNetwork)) OR (FastBaseHdr.Dest.Zone<>0));
               CLOSE(FNetwork);
               IF FastBaseHdr.Dest.Zone=0 THEN
               BEGIN
                    FastBaseHdr.Dest.Zone := 1;
                    FastBaseHdr.Orig.Zone := 1;
               END;
          END;
     END;
     IF (FlagsKludge<>'') THEN
     BEGIN
          FlagsKludge := _UpperCase(FlagsKludge);
          Loop := Pos(' ',FlagsKludge);
          Delete(FlagsKludge,1,Loop);
          REPEAT
                Loop := Pos(' ',FlagsKludge);
                IF (Loop<>0) THEN
                BEGIN
                     Temp := _Mid(FlagsKludge,1,Loop-1);
                     Delete(FlagsKludge,1,Loop);
                END
                ELSE
                BEGIN
                     Temp := FlagsKludge;
                     FlagsKludge := '';
                END;
                     IF Temp='IMM' THEN FastBaseHdr.Immediate := True
                ELSE IF Temp='DIR' THEN FastBaseHdr.Direct := True
                ELSE IF Temp='TFS' THEN FastBaseHdr.TruncSent := True
                ELSE IF Temp='KFS' THEN FastBaseHdr.KillFileSent := True
                ELSE IF Temp='EXC' THEN FastBaseHdr.Exclusive := True;
          UNTIL FlagsKludge='';
     END;
     IF (FmPtKludge<>'') THEN
     BEGIN
          Delete(FmPtKludge,1,5);
          FastBaseHdr.Orig.Point := _Numeric(FmPtKludge);
     END;
     IF (ToPtKludge<>'') THEN
     BEGIN
          Delete(ToPtKludge,1,5);
          FastBaseHdr.Dest.Point := _Numeric(ToPtKludge);
     END;
END;


PROCEDURE CreateFidoHeader;
BEGIN
     FillChar(FidoHeader,SizeOf(FidoHeader),0);
     Move(PKTMsgTo,FidoHeader.MsgTo,SizeOf(FidoHeader.MsgTo));
     Move(PKTMsgFrom,FidoHeader.MsgFrom,SizeOf(FidoHeader.MsgFrom));
     Move(PKTMsgSubject,FidoHeader.MsgSubject,SizeOf(FidoHeader.MsgSubject));
     Move(PackMsgHeader.DateTime,FidoHeader.DateTime,SizeOf(FidoHeader.DateTime));
     FidoHeader.OrigNode  := PackMsgHeader.OrigNode;
     FidoHeader.DestNode  := PackMsgHeader.DestNode;
     FidoHeader.OrigNet   := PackMsgHeader.OrigNet;
     FidoHeader.DestNet   := PackMsgHeader.DestNet;
     FidoHeader.Attribute := PackMsgHeader.Attribute;
     FidoHeader.Cost      := PackMsgHeader.Cost;
END;


PROCEDURE CreateType2PPacket(FromAka,ToAka: AddrType; Password: String);
VAR  Node         : Word;
     Net          : Word;
     Zone         : Word;
     Temp         : String;
     Loop         : Word;
     MajorVersion : Byte;
     MinorVersion : Byte;
     Hour         : Word;
     Minute       : Word;
     Second       : Word;
     Sec100       : Word;
     Year         : Word;
     Month        : Word;
     Day          : Word;
     DayOfWeek    : Word;
BEGIN
     Temp := ShotgunVersion;
     Delete(Temp,1,1);
     IF NOT(Temp[LENGTH(Temp)] IN ['0'..'9']) THEN DEC(Temp[0]);
     Loop := Pos('.',Temp);
     MajorVersion := _Numeric(_Mid(Temp,1,Loop-1));
     MinorVersion := _Numeric(_Mid(Temp,Loop+1,LENGTH(Temp)));
     GetTime(Hour,Minute,Second,Sec100);
     GetDate(Year,Month,Day,DayOfWeek);
     Dec(Year,1900);
     FillChar(Type2PPacket,SizeOf(Type2PPacket),0);
     Type2PPacket.QDestZone := ToAka.Zone;
     Type2PPacket.DestZone  := ToAka.Zone;
     Type2PPacket.DestNet   := ToAka.Net;
     Type2PPacket.DestNode  := ToAka.Node;
     Type2PPacket.DestPoint := ToAka.Point;
     Type2PPacket.QOrigZone := FromAka.Zone;
     Type2PPacket.OrigZone  := FromAka.Zone;
     Type2PPacket.OrigNet   := FromAka.Net;
     Type2PPacket.OrigNode  := FromAka.Node;
     Type2PPacket.OrigPoint := FromAka.Point;
     Type2PPacket.PrdCodL   := Lo(FTSCProductCode);
     Type2PPacket.PrdCodH   := Hi(FTSCProductCode);
     Type2PPacket.PVMajor   := MajorVersion;
     Type2PPacket.PVMinor   := MinorVersion;
     Type2PPacket.PktVer    := 2;
     Type2PPacket.CapWord   := 1;
     Type2PPacket.Year      := Year;
     Type2PPacket.Month     := Month;
     Type2PPacket.Day       := Day;
     Type2PPacket.Hour      := Hour;
     Type2PPacket.Min       := Minute;
     Type2PPacket.Sec       := Second;
     Type2PPacket.Baud      := MailerInfo.BaudRate;
     FOR Loop := 1 TO LENGTH(Password) DO Type2PPacket.Password[Loop] := Password[Loop];
END;


PROCEDURE MakeTheMainPacketHeader(DestAddr: AddrType);
VAR  Node      : Word;
     Net       : Word;
     Zone      : Word;
     Work      : Word;
     FFile     : File;
     BytesRead : Word;
     DestFile  : String;
BEGIN
     IsItNew   := False;
     PktName   := HexSystem(DestAddr)+'.PKT';
     IF FastBaseHdr.Exclusive
        THEN DestFile := MailerInfo.Outpkts+'EXC\'+PktName
        ELSE DestFile := MailerInfo.Outpkts+PktName;
     IF NOT(_FileExists(DestFile)) THEN
     BEGIN
          CreateType2PPacket(FastBaseHdr.Orig,DestAddr,GetSessionPassword(DestAddr));
          ASSIGN(FFile,DestFile);
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,Type2PPacket,SizeOf(Type2PPacket));
          BytesRead := 0;
          BLOCKWRITE(FFile,BytesRead,2);
          CLOSE(FFile);
          IsItNew := True;
     END;
END;


PROCEDURE AddThePacket;
VAR  FFile   : File;
     Loop    : Word;
     Temp1   : String;
     Temp2   : String;
     Temp3   : String;
     ToLen   : Word;
     FromLen : Word;
     SubjLen : Word;
     BuffLen : Word;
BEGIN
     Move(FidoHeader.MsgTo,PKTMsgTo,SizeOf(FidoHeader.MsgTo));
     Move(FidoHeader.MsgFrom,PKTMsgFrom,SizeOf(FidoHeader.MsgFrom));
     Move(FidoHeader.MsgSubject,PKTMsgSubject,SizeOf(FidoHeader.MsgSubject));
     {STRIP PATH NAMES FROM FILE ATTACHES}
     IF FastBaseHdr.FileAttach THEN
     BEGIN
          Temp1 := FidoHeader.MsgSubject;
          Temp3 := '';
          REPEAT
                Loop := Pos(' ',Temp1);
                IF (Loop<>0) THEN
                BEGIN
                     Temp2 := _Mid(Temp1,1,Loop-1);
                     Delete(Temp1,1,Loop);
                     IF Temp3='' THEN Temp3 := _NoPath(Temp2)
                                 ELSE Temp3 := Temp3+' '+_NoPath(Temp2);
                END
                ELSE
                BEGIN
                     Loop := Pos(',',Temp1);
                     IF (Loop<>0) THEN
                     BEGIN
                          Temp2 := _Mid(Temp1,1,Loop-1);
                          Delete(Temp1,1,Loop);
                          IF Temp3='' THEN Temp3 := _NoPath(Temp2)
                                      ELSE Temp3 := Temp3+' '+_NoPath(Temp2);
                     END
                     ELSE
                     BEGIN
                          IF Temp3='' THEN Temp3 := _NoPath(Temp1)
                                      ELSE Temp3 := Temp3+' '+_NoPath(Temp1);
                     END;
                END;
          UNTIL Loop=0;
          FillChar(PKTMsgSubject,SizeOf(PKTMsgSubject),0);
          Move(Temp3[1],PKTMsgSubject[1],Ord(Temp3[0]));
     END;
     FillChar(PackMsgHeader,SizeOf(PackMsgHeader),0);
     Move(FidoHeader.DateTime,PackMsgHeader.DateTime,SizeOf(FidoHeader.DateTime));
     PackMsgHeader.Signature := 2;
     PackMsgHeader.OrigNode  := FidoHeader.OrigNode;
     PackMsgHeader.DestNode  := FidoHeader.DestNode;
     PackMsgHeader.OrigNet   := FidoHeader.OrigNet;
     PackMsgHeader.DestNet   := FidoHeader.DestNet;
     PackMsgHeader.Attribute := FidoHeader.Attribute;
     PackMsgHeader.Cost      := FidoHeader.Cost;
     ToLen := 0;
     REPEAT INC(ToLen); UNTIL PKTMsgTo[ToLen]=#0;
     FromLen := 0;
     REPEAT INC(FromLen); UNTIL PKTMsgFrom[FromLen]=#0;
     SubjLen := 0;
     REPEAT INC(SubjLen); UNTIL PKTMsgSubject[SubjLen]=#0;
     BuffLen := 0;
     REPEAT INC(BuffLen); UNTIL Buffer^[BuffLen]=#0;
     Loop := 0;
     IF FastBaseHdr.Exclusive THEN
     BEGIN
          ASSIGN(FFile,MailerInfo.Outpkts+'EXC\'+PktName);
          RESET(FFile,1);
          SEEK(FFile,FileSize(FFile)-2);
          BLOCKWRITE(FFile,PackMsgHeader,SizeOf(PackMsgHeader));
          BLOCKWRITE(FFile,PKTMsgTo[1],ToLen);
          BLOCKWRITE(FFile,PKTMsgFrom[1],FromLen);
          BLOCKWRITE(FFile,PKTMsgSubject[1],SubjLen);
          BLOCKWRITE(FFile,Buffer^[1],BuffLen-1);
          BLOCKWRITE(FFile,ViaKludge[1],LENGTH(ViaKludge));
          BLOCKWRITE(FFile,Loop,1);
          BLOCKWRITE(FFile,Loop,2);
          CLOSE(FFile);
     END
     ELSE
     BEGIN
          ASSIGN(FFile,MailerInfo.Outpkts+PktName);
          RESET(FFile,1);
          SEEK(FFile,FileSize(FFile)-2);
          BLOCKWRITE(FFile,PackMsgHeader,SizeOf(PackMsgHeader));
          BLOCKWRITE(FFile,PKTMsgTo[1],ToLen);
          BLOCKWRITE(FFile,PKTMsgFrom[1],FromLen);
          BLOCKWRITE(FFile,PKTMsgSubject[1],SubjLen);
          BLOCKWRITE(FFile,Buffer^[1],BuffLen-1);
          BLOCKWRITE(FFile,ViaKludge[1],LENGTH(ViaKludge));
          BLOCKWRITE(FFile,Loop,1);
          BLOCKWRITE(FFile,Loop,2);
          CLOSE(FFile);
     END;
END;


FUNCTION NextMsgNum: Word;
VAR  DirInfo    : SearchRec;
     BigOne     : Word;
     SearchFile : Word;
BEGIN
     BigOne := 0;
     FindFirst(MailerInfo.NetMail+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          SearchFile := _Numeric(_NoExtension(DirInfo.Name));
          IF (SearchFile>BigOne) THEN BigOne := SearchFile;
          FindNext(DirInfo);
     END;
     NextMsgNum := BigOne;
END;


PROCEDURE PktToMSG(InString: String);
VAR  FFile       : File;
     AllDone     : Boolean;
     WantedBytes : Word;
     Running     : Word;
     InByte      : Char;
     Counter     : Word;
     FromSystem  : String;
     MessageTo   : String;
     BytesRead   : Word;
     StartPos    : Longint;
     Finished    : Boolean;
     OrigRead    : Word;

     PROCEDURE WriteTheMessage;
     VAR  FFile2 : File;
          Loop   : Word;
     BEGIN
          FOR Loop := 1 TO WantedBytes-2 DO IF (Buffer^[Loop]=#0) THEN Buffer^[Loop] := ' ';
          StatusWindow('Msg #'+_String(Running)+' from '+FromSystem+' to '+MessageTo);
          bsWriteLog('Msg #'+_String(Running)+' from '+FromSystem+' to '+MessageTo,False);
          ASSIGN(FFile2,MailerInfo.NetMail+_String(Running)+'.MSG');
          REWRITE(FFile2,1);
          BLOCKWRITE(FFile2,FidoHeader,SizeOf(FidoHeader));
          BLOCKWRITE(FFile2,Buffer^[1],WantedBytes);
          CLOSE(FFile2);
          INC(Running);
     END;

     FUNCTION IsItEmpty: Boolean;
     VAR  Loop      : Word;
          IsAllDone : Boolean;
     BEGIN
          Loop      := 1;
          IsAllDone := False;
          REPEAT
                CASE Buffer^[Loop] OF
                #0:  BEGIN
                          IsItEmpty := True;
                          Exit;
                     END;
                #1:  BEGIN
                          REPEAT
                                INC(Loop);
                          UNTIL Buffer^[Loop]=#13;
                          IF Buffer^[Loop+1]=#10 THEN INC(Loop);
                     END;
                #13: BEGIN
                          IF Buffer^[Loop+1]=#10 THEN INC(Loop);
                     END;
                #10: BEGIN
                          IF Buffer^[Loop+1]=#13 THEN INC(Loop);
                     END;
                ELSE BEGIN
                          IF ((Ord(Buffer^[Loop])>31) AND (Ord(Buffer^[Loop])<128)) THEN
                          BEGIN
                               IsItEmpty := False;
                               Exit;
                          END;
                     END;
                END;
                INC(Loop);
          UNTIL IsAllDone;
     END;

BEGIN
     New(Buffer);
     Running := NextMsgNum+1;
     AllDone := False;
     ASSIGN(FFile,InString);
     RESET(FFile,1);
     BlockRead(FFile,Type2PPacket,SizeOf(Type2PPacket),BytesRead);
     IF BytesRead=SizeOf(Type2PPacket) THEN
     BEGIN
          REPEAT
                {$I-}BlockRead(FFile,PackMsgHeader,SizeOf(PackMsgHeader));{$I+}
                IF ((IOResult=0) AND (PackMsgHeader.Signature=2)) THEN
                BEGIN
                     FillChar(PKTMsgTo,SizeOf(PKTMsgTo),0);
                     Counter := 0;
                     REPEAT
                           INC(Counter);
                           BlockRead(FFile,InByte,SizeOf(InByte),BytesRead);
                           PKTMsgTo[Counter] := InByte;
                     UNTIL InByte=#0;
                     Move(PKTMsgTo[1],MessageTo[1],Counter-1);
                     MessageTo[0] := Chr(Counter-1);

                     FillChar(PKTMsgFrom,SizeOf(PKTMsgFrom),0);
                     Counter := 0;
                     REPEAT
                           INC(Counter);
                           BlockRead(FFile,InByte,SizeOf(InByte),BytesRead);
                           PKTMsgFrom[Counter] := InByte;
                     UNTIL InByte=#0;

                     FillChar(PKTMsgSubject,SizeOf(PKTMsgSubject),0);
                     Counter := 0;
                     REPEAT
                           INC(Counter);
                           BlockRead(FFile,InByte,SizeOf(InByte),BytesRead);
                           PKTMsgSubject[Counter] := InByte;
                     UNTIL InByte=#0;

                     CreateFidoHeader;
                     FromSystem := _String(FidoHeader.OrigNet)+'/'+_String(FidoHeader.OrigNode);

                     StartPos  := FilePos(FFile);
                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),OrigRead);
                     BytesRead := 0;
                     Finished  := False;
                     REPEAT
                           INC(BytesRead);
                           IF ((Buffer^[BytesRead]=#2) AND (Buffer^[BytesRead+1]=#0)) THEN
                           BEGIN
                                DEC(BytesRead);
                                Finished := True;
                           END
                           ELSE IF Buffer^[BytesRead]=#0 THEN
                           BEGIN
                                IF ((Buffer^[BytesRead+1]<>#0) AND (Buffer^[BytesRead+1]<>#2)) THEN
                                BEGIN
                                     Buffer^[BytesRead] := #32;
                                END;
                           END;
                           IF (BytesRead=OrigRead) THEN Finished := True;
                     UNTIL Finished;
                     Seek(FFile,StartPos);
                     WantedBytes := BytesRead;
                     BlockRead(FFile,Buffer^,WantedBytes,BytesRead);
                     INC(WantedBytes);
                     Buffer^[WantedBytes] := #0;

                     IF IsItEmpty THEN
                     BEGIN
                          StatusWindow('Null message killed');
                          bsWriteLog('Null message killed',False);
                     END
                     ELSE WriteTheMessage;
                END
                ELSE AllDone := True; {End Of Packet}
          UNTIL AllDone;
     END;
     CLOSE(FFile);
     IF IOResult=0 THEN;
     _EraseFile(InString);
     Dispose(Buffer);
END;


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
     DEC(Year,1900);
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


PROCEDURE FailedFileRequest(YourAka,TheirAka: AddrType; FName: String; Num: Word);
VAR  Node      : Word;
     Net       : Word;
     Zone      : Word;
     Work      : Word;
     Loop      : Word;
     Temp1     : String;
     Temp2     : String;
     Temp3     : String;
     FFile     : File;
     TFile     : Text;
BEGIN
     IsItNew := False;
     PktName := HexSystem(TheirAka)+'.PKT';
     IF NOT(_FileExists(MailerInfo.Outpkts+PktName)) THEN
     BEGIN
          CreateType2PPacket(YourAka,TheirAka,GetSessionPassword(TheirAka));
          ASSIGN(FFile,MailerInfo.Outpkts+PktName);
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,Type2PPacket,SizeOf(Type2PPacket));
          Loop := 0;
          BLOCKWRITE(FFile,Loop,2);
          CLOSE(FFile);
          IsItNew := True;
     END;
     FillChar(PackMsgHeader,SizeOf(PackMsgHeader),0);
     Temp1 := GetFidoDate;
     Move(Temp1[1],PackMsgHeader.DateTime,19);
     PackMsgHeader.Signature := 2;
     PackMsgHeader.OrigNode  := Type2PPacket.OrigNode;
     PackMsgHeader.DestNode  := Type2PPacket.DestNode;
     PackMsgHeader.OrigNet   := Type2PPacket.OrigNet;
     PackMsgHeader.DestNet   := Type2PPacket.DestNet;
     PackMsgHeader.Attribute := 0;
     PackMsgHeader.Cost      := 0;
     ASSIGN(FFile,MailerInfo.Outpkts+PktName);
     RESET(FFile,1);
     SEEK(FFile,FileSize(FFile)-2);
     BLOCKWRITE(FFile,PackMsgHeader,SizeOf(PackMsgHeader));
     Temp1 := RemoteSystem.Sysop+#0;
     Temp2 := SystemInfo.Sysop+#0;
     Temp3 := 'Failed Request'+#0;
     BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
     BLOCKWRITE(FFile,Temp2[1],LENGTH(Temp2));
     BLOCKWRITE(FFile,Temp3[1],LENGTH(Temp3));
     IF (YourAka.Point<>0) THEN
     BEGIN
          Temp1 := #1+'FMPT '+_String(YourAka.Point)+#13;
          BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
     END;
     IF (TheirAka.Point<>0) THEN
     BEGIN
          Temp1 := #1+'TOPT '+_String(TheirAka.Point)+#13;
          BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
     END;
     Temp1 := #1+'INTL '+AddressToStringNoPoint(TheirAka)+' '+AddressToStringNoPoint(YourAka)+#13;
     BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
     CASE Num OF
     1:   BEGIN {No Freq's Allowed At All}
               Temp1 := 'No file requests are allowed on this system.'+#13#13;
               BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
          END;
     2:   BEGIN {No Freq's Allowed At This Time}
               Temp1 := 'No file requests are allowed at this time.'+#13#13;
               BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
          END;
     3:   BEGIN {File Not Found}
               Temp1 := 'No matches were found for: "'+FName+'"'+#13#13;
               BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
          END;
     4:   BEGIN {Too Slow For Freq}
               Temp1 := 'Baud rate of '+FName+' too slow to request files.'+#13#13;
               BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
          END;
     END;
     IF _FileExists(MailerInfo.NoMatch) THEN
     BEGIN
          ASSIGN(TFile,MailerInfo.NoMatch);
          RESET(TFile);
          REPEAT
                READLN(TFile,Temp1);
                Temp1 := Temp1+#13;
                BLOCKWRITE(FFile,Temp1[1],LENGTH(Temp1));
          UNTIL EOF(TFile);
          CLOSE(TFile);
     END;
     Loop := 0;
     BLOCKWRITE(FFile,Loop,2);
     CLOSE(FFile);
     IF IsItNew THEN
        AddToQueue('MAIL',TheirAka,MailerInfo.Outpkts+PktName,0,False,0,YetToGo,False,0,0,0,False,False,False);
END;


END.
