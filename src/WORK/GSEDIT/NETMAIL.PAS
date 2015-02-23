{$I DEFINES.INC}
UNIT NetMail;


INTERFACE


USES Globals,Shotgun;


PROCEDURE IndexAreas;
PROCEDURE GetTheMessage      (Num: Longint);
FUNCTION  GetFidoDate        : String;
FUNCTION  NextMsgNum         : Word;


IMPLEMENTATION


USES Dos,Misc,Version,BsAkas,BsString,BsFile;


PROCEDURE IndexAreas;
VAR  LastRead   : Word;
     FFile      : File;
     Loop       : Word;
     Loop2      : Word;
     Work       : Word;
     DirInfo    : SearchRec;
     I2,J2,N2   : Longint;
     Jump       : Longint;
     Done       : Boolean;
     BytesRead  : Word;
     Temp       : String;

     FUNCTION IsOk(InString: String): Boolean;
     BEGIN
          IsOk := True;
          {
          IF _Mid(InString,1,6)='GSECHO' THEN IsOk := False;
          IF _Mid(InString,1,6)='GSFILE' THEN IsOk := False;
          IF _Mid(InString,1,7)='ARCMAIL' THEN IsOk := False;
          IF _Mid(InString,1,7)='AREAFIX' THEN IsOk := False;
          IF _Mid(InString,1,7)='AREAMGR' THEN IsOk := False;
          IF _Mid(InString,1,4)='RAID' THEN IsOk := False;
          }
     END;

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
          ASSIGN(FFile,MailerInfo.NetMail+DirInfo.Name);
          RESET(FFile,1);
          BLOCKREAD(FFile,FidoHeader,SizeOf(FidoHeader),BytesRead);
          CLOSE(FFile);
          Temp := '';
          Loop := 1;
          WHILE ((FidoHeader.MsgFrom[Loop]<>#0) AND (Loop<36)) DO
          BEGIN
            Temp := Temp+UpCase(FidoHeader.MsgFrom[Loop]);
            INC(Loop);
          END;
          IF IsOk(Temp) THEN
          BEGIN
            Temp := '';
            Loop := 1;
            WHILE ((FidoHeader.MsgTo[Loop]<>#0) AND (Loop<36)) DO
            BEGIN
              Temp := Temp+UpCase(FidoHeader.MsgTo[Loop]);
              INC(Loop);
            END;
            IF IsOk(Temp) THEN
            BEGIN
              INC(NumMsgs);
              Indexes[NumMsgs] := _Numeric(_NoExtension(DirInfo.Name));
            END;
          END;
          FindNext(DirInfo);
     END;
     {CREATE THE SORTED INDEXES}
     IF (NumMsgs<>0) THEN
     BEGIN
          N2   := NumMsgs;
          Jump := N2;
          WHILE (Jump>1) DO
          BEGIN
               Jump := Jump DIV 2;
               REPEAT
                     Done := true;
                     FOR J2 := 1 to (N2-Jump) DO
                     BEGIN
                          I2 := J2+Jump;
                          IF Indexes[j2]>Indexes[i2] THEN
                          BEGIN
                               Work        := Indexes[j2];
                               Indexes[j2] := Indexes[i2];
                               Indexes[i2] := Work;
                               Done := false;
                          END;
                     END;
               UNTIL Done;
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
     FastBaseHdr.MsgDateTime.Year := _Numeric(_Mid(TTime,8,9))+1900;
     IF (FastBaseHdr.MsgDateTime.Year<1980) THEN INC(FastBaseHdr.MsgDateTime.Year,100);
     FastBaseHdr.MsgDateTime.Day  := _Numeric(_Mid(TTime,1,2));
     FastBaseHdr.MsgDateTime.Hour := _Numeric(_Mid(TTime,12,13));
     FastBaseHdr.MsgDateTime.Min  := _Numeric(_Mid(TTime,15,16));
     FastBaseHdr.MsgDateTime.Sec  := _Numeric(_Mid(TTime,18,19));
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
TYPE MessageTextLines = RECORD
     Line             : String[80];
     END;
VAR  MsgText          : MessageTextLines;
     FMsgText         : File Of MessageTextLines;
     FFile            : File;
     LastSpace        : Word;
     CurPointer       : Word;
     LineLength       : Word;
     AllDone          : Boolean;
     StartPoint       : Word;
     Loop             : Word;
     WorkBytes        : Array[1..2] Of Byte;
     LastRead         : Word;
     Temp             : String;
     BytesRead        : Word;

     PROCEDURE DumpRegularLine;
     BEGIN
          IF Pos('SEEN-BY: ',MsgText.Line)=1 THEN
          BEGIN
               IF SystemInfo.MessageDebug=1 THEN
               BEGIN
                    WRITE(FMsgText,MsgText);
                    INC(NumLines);
               END;
          END
          ELSE
          BEGIN
               WRITE(FMsgText,MsgText);
               INC(NumLines);
          END;
     END;

BEGIN
     ASSIGN(FFile,MailerInfo.NetMail+_String(Indexes[Num])+'.MSG');
     {$I-}RESET(FFile,1);{$I+}
     IF (IOResult<>0) THEN Exit;
     BLOCKREAD(FFile,FidoHeader,SizeOf(FidoHeader),BytesRead);
     BLOCKREAD(FFile,Buffer^[1],SizeOf(Buffer^),BytesRead);
     CLOSE(FFile);
     Buffer^[BytesRead+1] := #0;
     Buffer^[BytesRead+2] := #0;
     ReplyDomain  := '';
     IntlKludge   := '';
     MsgIDKludge  := '';
     FlagsKludge  := '';
     FmPtKludge   := '';
     ToPtKludge   := '';
     Current      := Num;
     CurPointer   := 0;
     NumLines     := 0;
     MsgText.Line := '';
     LineLength   := 0;
     LastSpace    := 0;
     AllDone      := False;
     StartPoint   := 1;
     Top          := 1;
     NewMsg       := False;
     ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
     REWRITE(FMsgText);
     REPEAT
           INC(CurPointer);
           CASE Buffer^[CurPointer] OF
           #0:  BEGIN {End Of Message}
                     IF MsgText.Line[0]=#0 THEN
                     BEGIN
                          WRITE(FMsgText,MsgText);
                          INC(NumLines);
                     END
                     ELSE IF MsgText.Line[1]<>#1 THEN
                     BEGIN
                          DumpRegularLine;
                     END
                     ELSE
                     BEGIN
                          IF _Mid(MsgText.Line,2,6)='FMPT ' THEN FmPtKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,6)='TOPT ' THEN ToPtKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,6)='INTL ' THEN IntlKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN MsgIdKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,7)='FLAGS ' THEN FlagsKludge := MsgText.Line;
                          IF SystemInfo.MessageDebug=1 THEN
                          BEGIN
                               WRITE(FMsgText,MsgText);
                               INC(NumLines);
                          END;
                     END;
                     AllDone := True;
                END;
           #10: ; {Line Feed - Ignore}
           #13: BEGIN {Carriage Return}
                     IF MsgText.Line[0]=#0 THEN
                     BEGIN
                          WRITE(FMsgText,MsgText);
                          INC(NumLines);
                     END
                     ELSE IF MsgText.Line[1]<>#1 THEN
                     BEGIN
                          DumpRegularLine;
                     END
                     ELSE
                     BEGIN
                          IF _Mid(MsgText.Line,2,6)='FMPT ' THEN FmPtKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,6)='TOPT ' THEN ToPtKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,6)='INTL ' THEN IntlKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN MsgIdKludge := MsgText.Line;
                          IF _Mid(MsgText.Line,2,7)='FLAGS ' THEN FlagsKludge := MsgText.Line;
                          IF SystemInfo.MessageDebug=1 THEN
                          BEGIN
                               WRITE(FMsgText,MsgText);
                               INC(NumLines);
                          END;
                     END;
                     MsgText.Line[0] := #0;
                     StartPoint := CurPointer+1;
                END;
           ELSE BEGIN
                     IF Buffer^[CurPointer]=#$8D THEN Buffer^[CurPointer] := #32;
                     IF LENGTH(MsgText.Line)=80 THEN
                     BEGIN
                          IF Buffer^[CurPointer]=#32 THEN
                          BEGIN
                               IF MsgText.Line[0]=#0 THEN
                               BEGIN
                                    WRITE(FMsgText,MsgText);
                                    INC(NumLines);
                               END
                               ELSE IF MsgText.Line[1]<>#1 THEN
                               BEGIN
                                    DumpRegularLine;
                               END
                               ELSE
                               BEGIN
                                    IF _Mid(MsgText.Line,2,6)='FMPT ' THEN FmPtKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,6)='TOPT ' THEN ToPtKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,6)='INTL ' THEN IntlKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN MsgIdKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,7)='FLAGS ' THEN FlagsKludge := MsgText.Line;
                                    IF SystemInfo.MessageDebug=1 THEN
                                    BEGIN
                                         WRITE(FMsgText,MsgText);
                                         INC(NumLines);
                                    END;
                               END;
                               MsgText.Line[0] := #0;
                               StartPoint := CurPointer+1;
                          END
                          ELSE
                          BEGIN
                               MsgText.Line[0] := #0;
                               FOR Loop := StartPoint TO LastSpace-1 DO
                               BEGIN
                                 IF (Buffer^[Loop]<>#10) THEN MsgText.Line := MsgText.Line+Buffer^[Loop];
                               END;
                               IF MsgText.Line[0]=#0 THEN
                               BEGIN
                                    WRITE(FMsgText,MsgText);
                                    INC(NumLines);
                               END
                               ELSE IF MsgText.Line[1]<>#1 THEN
                               BEGIN
                                    DumpRegularLine;
                               END
                               ELSE
                               BEGIN
                                    IF _Mid(MsgText.Line,2,6)='FMPT ' THEN FmPtKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,6)='TOPT ' THEN ToPtKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,6)='INTL ' THEN IntlKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,8)='MSGID: ' THEN MsgIdKludge := MsgText.Line;
                                    IF _Mid(MsgText.Line,2,7)='FLAGS ' THEN FlagsKludge := MsgText.Line;
                                    IF SystemInfo.MessageDebug=1 THEN
                                    BEGIN
                                         WRITE(FMsgText,MsgText);
                                         INC(NumLines);
                                    END;
                               END;
                               MsgText.Line[0] := #0;
                               StartPoint := LastSpace+1;
                               CurPointer := StartPoint-1;
                          END;
                     END
                     ELSE
                     BEGIN
                          MsgText.Line := MsgText.Line+Buffer^[CurPointer];
                          IF Buffer^[CurPointer]=#32 THEN LastSpace := CurPointer;
                          IF Buffer^[CurPointer]=',' THEN LastSpace := CurPointer;
                          IF Buffer^[CurPointer]='-' THEN LastSpace := CurPointer;
                     END;
                END;
           END;
     UNTIL AllDone;
     CLOSE(FMsgText);
     LastRead := Indexes[Num];
     ASSIGN(FFile,MailerInfo.NetMail+'LASTREAD');
     RESET(FFile,1);
     BLOCKWRITE(FFile,LastRead,SizeOf(LastRead));
     CLOSE(FFile);
     LoadInTheHeader;
     IF (MsgIdKludge[0]<>#0) THEN
     BEGIN
          ReplyDomain := MsgIdKludge;
          Delete(ReplyDomain,1,8);
     END;
     IF (IntlKludge[0]<>#0) THEN
     BEGIN
          Delete(IntlKludge,1,6);
          Loop := Pos(#32,IntlKludge);
          Temp := _Mid(IntlKludge,1,Loop-1);
          StringToAddress(Temp,FastBaseHdr.Dest);
          Temp := _Mid(IntlKludge,Loop+1,LENGTH(IntlKludge));
          StringToAddress(Temp,FastBaseHdr.Orig);
     END
     ELSE IF (MsgIdKludge[0]<>#0) THEN
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
     IF (FlagsKludge[0]<>#0) THEN
     BEGIN
          FlagsKludge := _UpperCase(FlagsKludge);
          Loop := Pos(#32,FlagsKludge);
          Delete(FlagsKludge,1,Loop);
          REPEAT
                Loop := Pos(#32,FlagsKludge);
                IF (Loop<>0) THEN
                BEGIN
                     Temp := _Mid(FlagsKludge,1,Loop-1);
                     Delete(FlagsKludge,1,Loop);
                END
                ELSE
                BEGIN
                     Temp := FlagsKludge;
                     FlagsKludge[0] := #0;
                END;
                     IF Temp='IMM' THEN FastBaseHdr.Immediate := True
                ELSE IF Temp='DIR' THEN FastBaseHdr.Direct := True
                ELSE IF Temp='TFS' THEN FastBaseHdr.TruncSent := True
                ELSE IF Temp='KFS' THEN FastBaseHdr.KillFileSent := True
                ELSE IF Temp='EXC' THEN FastBaseHdr.Exclusive := True;
          UNTIL FlagsKludge[0]=#0;
     END;
     IF (FmPtKludge[0]<>#0) THEN
     BEGIN
          Delete(FmPtKludge,1,5);
          FastBaseHdr.Orig.Point := _Numeric(FmPtKludge);
     END;
     IF (ToPtKludge[0]<>#0) THEN
     BEGIN
          Delete(ToPtKludge,1,5);
          FastBaseHdr.Dest.Point := _Numeric(ToPtKludge);
     END;
     IF ((_UpperCase(FastBaseHdr.MsgTo)=_UpperCase(SystemInfo.Sysop)) OR
        (_UpperCase(FastBaseHdr.MsgTo)=_UpperCase(SystemInfo.Alias))) THEN
     BEGIN
          IF NOT(FastBaseHdr.Recv) THEN
          BEGIN
               IF IsOurNode(FastBaseHdr.Dest) THEN
               BEGIN
                    NewMsg := True;
                    Move(FidoHeader.Attribute,WorkBytes[1],2);
                    WorkBytes[1] := (WorkBytes[1] OR 4);
                    Move(WorkBytes[1],FidoHeader.Attribute,2);
                    ASSIGN(FFile,MailerInfo.NetMail+_String(Indexes[Num])+'.MSG');
                    RESET(FFile,1);
                    BLOCKWRITE(FFile,FidoHeader,SizeOf(FidoHeader));
                    CLOSE(FFile);
               END;
          END;
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
     Temp := ReturnZeroPad(Day)+#32;
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


END.
