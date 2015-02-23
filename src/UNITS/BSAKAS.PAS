{$I DEFINES.INC}
UNIT BsAkas;


INTERFACE


USES Gunshot;


VAR _LastMsgId : Longint;


PROCEDURE AddressStringBreakup   (InAddress: String; VAR Zone,Net,Node,Point: String);
PROCEDURE AddressStringBreakupW  (InAddress: String; VAR Zone,Net,Node,Point: Word);
PROCEDURE StringToAddress        (InString: String; VAR Aka: AddrType);
FUNCTION  AddressToString        (Aka: AddrType): String;
FUNCTION  AddressToStringNoPoint (Aka: AddrType): String;
FUNCTION  AkasMatch              (Aka1,Aka2: AddrType): Boolean;
FUNCTION  AkasMatchNoPoint       (Aka1,Aka2: AddrType): Boolean;
FUNCTION  GetMsgId               (InAddr: AddrType): String;


IMPLEMENTATION


USES BsString,Dos,BsCrc;


FUNCTION AkasMatch(Aka1,Aka2: AddrType): Boolean;
BEGIN
     {Check The Net}
     IF (Aka1.Net<>Aka2.Net) THEN
     BEGIN
       AkasMatch := False;
       Exit;
     END;
     {Check The Node}
     IF (Aka1.Node<>Aka2.Node) THEN
     BEGIN
       AkasMatch := False;
       Exit;
     END;
     {Check The Zone}
     IF (Aka1.Zone<>Aka2.Zone) THEN
     BEGIN
       AkasMatch := False;
       Exit;
     END;
     {Check The Point}
     IF (Aka1.Point<>Aka2.Point) THEN
     BEGIN
       AkasMatch := False;
       Exit;
     END;
     {They Match}
     AkasMatch := True;
END;


FUNCTION AkasMatchNoPoint(Aka1,Aka2: AddrType): Boolean;
BEGIN
     {Check The Net}
     IF (Aka1.Net<>Aka2.Net) THEN
     BEGIN
       AkasMatchNoPoint := False;
       Exit;
     END;
     {Check The Node}
     IF (Aka1.Node<>Aka2.Node) THEN
     BEGIN
       AkasMatchNoPoint := False;
       Exit;
     END;
     {Check The Zone}
     IF (Aka1.Zone<>Aka2.Zone) THEN
     BEGIN
       AkasMatchNoPoint := False;
       Exit;
     END;
     {They Match}
     AkasMatchNoPoint := True;
END;


PROCEDURE StringToAddress(InString: String; VAR Aka: AddrType);
VAR  Work : Word;
BEGIN
     FillChar(Aka,SizeOf(Aka),0);
     {Erase Domain}
     Work := Pos('@',InString);
     IF (Work<>0) THEN InString[0] := Chr(Work-1);
     {Zone}
     Work := Pos(':',InString);
     Aka.Zone := _Numeric(_Mid(InString,1,Work-1));
     Delete(InString,1,Work);
     {Net}
     Work := Pos('/',InString);
     Aka.Net := _Numeric(_Mid(InString,1,Work-1));
     Delete(InString,1,Work);
     {Node}
     Work := Pos('.',InString);
     IF Work=0 THEN
     BEGIN {Node Without Point}
       Aka.Node := _Numeric(InString);
     END
     ELSE
     BEGIN {Node With Point}
       Aka.Node := _Numeric(_Mid(InString,1,Work-1));
       Delete(InString,1,Work);
       {Point}
       Aka.Point := _Numeric(InString);
     END;
END;


FUNCTION AddressToString(Aka: AddrType): String;
VAR  Temp : String;
BEGIN
     Temp := _String(Aka.Zone)+':'+_String(Aka.Net)+'/'+_String(Aka.Node);
     IF (Aka.Point<>0) THEN Temp := Temp+'.'+_String(Aka.Point);
     AddressToString := Temp;
END;


FUNCTION AddressToStringNoPoint(Aka: AddrType): String;
BEGIN
     AddressToStringNoPoint := _String(Aka.Zone)+':'+_String(Aka.Net)+'/'+_String(Aka.Node);
END;


PROCEDURE AddressStringBreakup(InAddress: String; VAR Zone,Net,Node,Point: String);
VAR  Work : Word;
BEGIN
     {Erase Domain}
     Work := Pos('@',InAddress);
     IF (Work<>0) THEN InAddress[0] := Chr(Work-1);
     {Zone}
     Work := Pos(':',InAddress);
     Zone := _Mid(InAddress,1,Work-1);
     Delete(InAddress,1,Work);
     {Net}
     Work := Pos('/',InAddress);
     Net := _Mid(InAddress,1,Work-1);
     Delete(InAddress,1,Work);
     {Node}
     Work := Pos('.',InAddress);
     IF Work=0 THEN
     BEGIN {Node Without Point}
       Node := InAddress;
     END
     ELSE
     BEGIN {Node With Point}
       Node := _Mid(InAddress,1,Work-1);
       Delete(InAddress,1,Work);
       {Point}
       Point := InAddress;
     END;
END;


PROCEDURE AddressStringBreakupW(InAddress: String; VAR Zone,Net,Node,Point: Word);
VAR  Work : Word;
BEGIN
     {Erase Domain}
     Work := Pos('@',InAddress);
     IF (Work<>0) THEN InAddress[0] := Chr(Work-1);
     {Zone}
     Work := Pos(':',InAddress);
     Zone := _Numeric(_Mid(InAddress,1,Work-1));
     Delete(InAddress,1,Work);
     {Net}
     Work := Pos('/',InAddress);
     Net := _Numeric(_Mid(InAddress,1,Work-1));
     Delete(InAddress,1,Work);
     {Node}
     Work := Pos('.',InAddress);
     IF Work=0 THEN
     BEGIN {Node Without Point}
       Node := _Numeric(InAddress);
     END
     ELSE
     BEGIN {Node With Point}
       Node := _Numeric(_Mid(InAddress,1,Work-1));
       Delete(InAddress,1,Work);
       {Point}
       Point := _Numeric(InAddress);
     END;
END;


FUNCTION GetMsgId(InAddr: AddrType): String;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
     Temp         : String;
BEGIN
     IF _LastMsgId=0 THEN
     BEGIN
       GetDate(yy,mm,dd,dow);
       GetTime(h,m,s,s100);
       FillChar(DT,SizeOf(DT),0);
       DT.Year  := yy;
       DT.Month := mm;
       DT.Day   := dd;
       DT.Hour  := h;
       DT.Min   := m;
       DT.Sec   := s;
       PackTime(DT,WorkDate);
       WorkDate := WorkDate*1000;
       WorkDate := WorkDate+s100;
       _LastMsgId := WorkDate;
     END
     ELSE INC(_LastMsgId);
     Temp := _String(InAddr.Zone)+':'+_String(InAddr.Net)+'/'+_String(InAddr.Node);
     IF InAddr.Point<>0 THEN Temp := Temp+'.'+_String(InAddr.Point);
     Temp := #1+'MSGID: '+Temp+' '+Long2Hex(_LastMsgId);
     GetMsgId := Temp;
END;


END.