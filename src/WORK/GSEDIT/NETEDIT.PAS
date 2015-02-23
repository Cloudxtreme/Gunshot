{$I DEFINES.INC}
UNIT NetEdit;


INTERFACE


FUNCTION  is_quote            (in_string: string) : boolean;
FUNCTION  IsKludge            (In_String: String) : Boolean;
FUNCTION  ProcessedTime       (Hour,Minute: Word) : String;
FUNCTION  WriterMsgFrom       (Stuff: String)     : Boolean;
FUNCTION  WriterMsgTo         (Stuff: String)     : Boolean;
FUNCTION  WriterMsgSubject    (Stuff: String)     : Boolean;
PROCEDURE DrawMainScreen;
PROCEDURE DrawTheMessage;
PROCEDURE DrawTheMessageText;
PROCEDURE NetmailEditor;
PROCEDURE EditCurrentMessage;
PROCEDURE ReplyToMessage;
PROCEDURE DoNewMessage;


IMPLEMENTATION


USES FastW1,Globals,SaveScrn,NList,NetMail,Sema,BsAkas,BsFile,
     Crt,BsMulti,Time,Editor,MsgEdit,BsExec,BsTime,BsKeys,Misc,
     Version,Shotgun,DrawScrn,Keys,BsString,Dos,BsVideo,KeyCheck;


FUNCTION is_quote(in_string: string): boolean;
VAR  is_quote_loop        : word;
BEGIN
     is_quote_loop := Pos('>',In_String);
     IF Pos('<',In_String)<>0 THEN
     BEGIN
          IF Pos('<',In_String)<is_quote_loop THEN is_quote_loop := 0;
     END;
     IF ((Is_Quote_Loop<>0) AND (Is_Quote_Loop<9)) THEN is_quote := True
                                                   ELSE is_quote := False;
END;


FUNCTION IsKludge(In_String: String): Boolean;
BEGIN
     IF (In_String[1]<>#1) THEN IsKludge := False
                           ELSE IsKludge := True;
END;


FUNCTION ProcessedTime(Hour,Minute: Word): String;
VAR  Temp : String;
     T    : String;
BEGIN
     T := _String(Minute);
     IF LENGTH(T)=1 THEN T := '0'+T;
     IF Hour>12 THEN Temp := _String(Hour-12)+':'+T+'pm'
                ELSE Temp := _String(Hour)+':'+T+'am';
     ProcessedTime := Temp;
END;


PROCEDURE DrawMainScreen;
{$IFNDEF MSDOS}
CONST MemAvail: LongInt = 640 * 1024; // Pretend we have 640k
{$ENDIF}    
VAR  Loop : Word;
BEGIN
     FOR Loop := 1 TO 25 DO FastWrite(_PadRight('',80),Loop,1,7);
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',7,1,1);
     FastWrite(_PadRight(' Netmail',80),1,1,31);
     FastWrite(_PadRight(' First:       Last:       Total:       Left:',80),25,1,27);
     FastWrite(' F1  Help',25,71,31);
     FastWrite('[',25,71,23);
     FastWrite(']',25,74,23);
     FastWrite('By:',3,1,3);
     FastWrite('To:',4,1,3);
     FastWrite('Re:',5,1,3);
     FastWrite('St:',6,1,3);
     FastWrite(_String(MemAvail),25,64,27);
     Save_Screen2;
END;


PROCEDURE DrawTheMessage;
CONST months : array [1..12] of String =
               ('January','February','March','April',
                'May','June','July','August','September',
               'October','November','December');
VAR  Loop    : Word;
     Temp    : String;
     TheAttr : Byte;
BEGIN
     Restore_Screen2;
     Date_Time;
     {Top And Bottom Status Lines}
     FastWrite(_PadLeft(SystemDate+'  '+_GetPrettyTime,70),1,10,31);
     FastWrite(_String(Indexes[1]),25,9,31);
     FastWrite(_String(Indexes[NumMsgs]),25,21,31);
     FastWrite(_String(NumMsgs),25,34,31);
     FastWrite(_String(NumMsgs-Current),25,46,31);
     {New Mail Flag}
     IF NewMsg THEN FastWrite('NEW',2,77,128+10);
     IF NewMsg THEN TheAttr := 15 ELSE TheAttr := 11;
     {Message Header Information}
     Temp := _String(FastBaseHdr.MsgNumber);
     FastWrite(Temp,2,2,TheAttr);
     FastWrite('[',2,1,3);
     FastWrite(']',2,2+Length(Temp),3);
     Temp := Months[FastBaseHdr.MsgDateTime.Month]+' '+
             _String(FastBaseHdr.MsgDateTime.Day)+','+
             _String(FastBaseHdr.MsgDateTime.Year)+' '+
             ProcessedTime(FastBaseHdr.MsgDateTime.Hour,
             FastBaseHdr.MsgDateTime.Min)+' ';
     FastWrite(Temp,2,8,TheAttr);
     FastWrite(FastBaseHdr.MsgFrom+' ('+AddressToString(FastBaseHdr.Orig)+')',3,8,TheAttr);
     FastWrite(FastBaseHdr.MsgTo+' ('+AddressToString(FastBaseHdr.Dest)+')',4,8,TheAttr);
     FastWrite(FastBaseHdr.MsgSubject,5,8,TheAttr);
     Temp :=  '';
     IF FastBaseHdr.Priv         THEN Temp := Temp+'Pvt ';
     IF FastBaseHdr.FileAttach   THEN Temp := Temp+'File ';
     IF FastBaseHdr.FileRequest  THEN Temp := Temp+'Freq ';
     IF FastBaseHdr.Crash        THEN Temp := Temp+'Crash ';
     IF FastBaseHdr.Hold         THEN Temp := Temp+'Hold ';
     IF FastBaseHdr.KillSent     THEN Temp := Temp+'Kill ';
     IF FastBaseHdr.Sent         THEN Temp := Temp+'Sent ';
     IF FastBaseHdr.Recv         THEN Temp := Temp+'Rcvd ';
     IF FastBaseHdr.Direct       THEN Temp := Temp+'Direct ';
     IF FastBaseHdr.Immediate    THEN Temp := Temp+'Immediate ';
     IF FastBaseHdr.InTransit    THEN Temp := Temp+'InTransit ';
     IF FastBaseHdr.Orphan       THEN Temp := Temp+'Orphan ';
     IF FastBaseHdr.TruncSent    THEN Temp := Temp+'Trunc/Sent ';
     IF FastBaseHdr.KillFileSent THEN Temp := Temp+'Kill/Sent ';
     IF FastBaseHdr.Exclusive    THEN Temp := Temp+'Exclusive ';
     FastWrite(Temp,6,8,TheAttr);
     IF NewMsg THEN CreateSemaphore(2);
END;


PROCEDURE DrawTheMessageText;
TYPE MessageTextLines = RECORD
     Line             : String[80];
     END;
VAR  MsgText     : MessageTextLines;
     FMsgText    : File Of MessageTextLines;
     Loop        : Word;
     Temp        : String;
     TheAttr     : Word;
     Y           : Word;
BEGIN
     ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
     RESET(FMsgText);
     SEEK(FMsgText,Top-1);
     Y := 8;
     FOR Loop := Top TO Top+16 DO
     BEGIN
          IF NOT(EOF(FMsgText)) THEN
          BEGIN
               READ(FMsgText,MsgText);
               MsgText.Line := _PadRight(MsgText.Line,80);
                    IF Is_Quote(MsgText.Line) THEN TheAttr := 2
               ELSE IF IsKludge(MsgText.Line) THEN TheAttr := 8
                                              ELSE TheAttr := 7;
               FastWrite(MsgText.Line,Y,1,TheAttr);
          END
          ELSE FastWrite(_PadRight('',80),Y,1,7);
          INC(Y);
     END;
     CLOSE(FMsgText);
END;


PROCEDURE DumpCurrentMessage;
CONST months : array [1..12] of String =
               ('January','February','March','April',
                'May','June','July','August','September',
               'October','November','December');
TYPE MessageTextLines = RECORD
     Line             : String[80];
     END;
VAR  MsgText          : MessageTextLines;
     FMsgText         : File Of MessageTextLines;
     TheFile          : String;
     TFile            : Text;
     Temp             : String;
     TheDate          : String;
     TheFlags         : String;
BEGIN
     DrawWindow(12,10,73,16,'EXPORT TO TEXT FILE',True);
     InvertedBox(14,11,71,15);
     TheFile := GetInput(16,13,54,31,'',True);
     IF TheFile<>'' THEN
     BEGIN
          TheDate := Months[FastBaseHdr.MsgDateTime.Month]+' '+
                     _String(FastBaseHdr.MsgDateTime.Day)+','+
                     _String(FastBaseHdr.MsgDateTime.Year)+' '+
                     ProcessedTime(FastBaseHdr.MsgDateTime.Hour,
                     FastBaseHdr.MsgDateTime.Min)+' ';
          TheFlags :=  '';
          IF FastBaseHdr.Priv         THEN TheFlags := TheFlags+'Pvt ';
          IF FastBaseHdr.FileAttach   THEN TheFlags := TheFlags+'File ';
          IF FastBaseHdr.FileRequest  THEN TheFlags := TheFlags+'Freq ';
          IF FastBaseHdr.Crash        THEN TheFlags := TheFlags+'Crash ';
          IF FastBaseHdr.Hold         THEN TheFlags := TheFlags+'Hold ';
          IF FastBaseHdr.KillSent     THEN TheFlags := TheFlags+'Kill ';
          IF FastBaseHdr.Sent         THEN TheFlags := TheFlags+'Sent ';
          IF FastBaseHdr.Recv         THEN TheFlags := TheFlags+'Rcvd ';
          IF FastBaseHdr.Direct       THEN TheFlags := TheFlags+'Direct ';
          IF FastBaseHdr.Immediate    THEN TheFlags := TheFlags+'Immediate ';
          IF FastBaseHdr.InTransit    THEN TheFlags := TheFlags+'InTransit ';
          IF FastBaseHdr.Orphan       THEN TheFlags := TheFlags+'Orphan ';
          IF FastBaseHdr.TruncSent    THEN TheFlags := TheFlags+'Trunc/Sent ';
          IF FastBaseHdr.KillFileSent THEN TheFlags := TheFlags+'Kill/Sent ';
          IF FastBaseHdr.Exclusive    THEN TheFlags := TheFlags+'Exclusive ';
          ASSIGN(TFile,TheFile);
          {$I-}REWRITE(TFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               WRITELN(TFile,'===============================================================================');
               WRITELN(TFile,' ['+_String(FastBaseHdr.MsgNumber)+']  '+TheDate);
               WRITELN(TFile,' By:  '+FastBaseHdr.MsgFrom+'  ('+AddressToString(FastBaseHdr.Orig)+')');
               WRITELN(TFile,' To:  '+FastBaseHdr.MsgTo+'  ('+AddressToString(FastBaseHdr.Dest)+')');
               WRITELN(TFile,' Re:  '+FastBaseHdr.MsgSubject);
               WRITELN(TFile,' St:  '+TheFlags);
               WRITELN(TFile,'===============================================================================');
               WRITELN(TFile,'');
               ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
               RESET(FMsgText);
               REPEAT
                     READ(FMsgText,MsgText);
                     WRITELN(TFile,MsgText.Line);
               UNTIL EOF(FMsgText);
               CLOSE(FMsgText);
               CLOSE(TFile);
          END;
     END;
END;


PROCEDURE GeneralHelp;
VAR  C : Char;
BEGIN
     Save_Screen;
     DrawWindow(18,8,61,23,'NETMAIL EDITOR COMMANDS',True);
     InvertedBox(20,9,59,22);
     FastWrite('INSERT ...... Enter A New Message   ',10,22,27);
     FastWrite('DELETE ...... Delete Current Message',11,22,27);
     FastWrite('RIGHT ARROW . Next Message          ',12,22,27);
     FastWrite('LEFT ARROW .. Previous Message      ',13,22,27);
     FastWrite('ALT-R ....... Reply To Message      ',15,22,27);
     FastWrite('ALT-D ....... Dump To Text File     ',16,22,27);
     FastWrite('ALT-E ....... Edit Current Message  ',17,22,27);
     FastWrite('ALT-X [ESC] . Quit Back To GSMail   ',18,22,27);
     FastWrite('F1 .......... Editor Help Screen    ',20,22,27);
     FastWrite('F2 .......... DOS Shell             ',21,22,27);
     C := ReadKey;
     IF Ord(C)=0 THEN C := ReadKey;
     Restore_Screen;
END;


PROCEDURE NetmailEditor;
VAR  AllDone : Boolean;
     C       : Char;
     TT      : Integer;
     Loop    : Word;
     OldX    : Word;
     OldY    : Word;
BEGIN
     New(Buffer);
     _HideCursor;
     RescanDateTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
     IndexAreas;
     DrawMainScreen;
     IF (NumMsgs<>0) THEN
     BEGIN
          GetTheMessage(Current);
          DrawTheMessage;
          DrawTheMessageText;
     END
     ELSE
     BEGIN
          FOR Loop := 2 TO 6 DO FastWrite(_PadRight('',80),Loop,1,7);
          FastWrite('No Messages In This Folder',4,3,11);
     END;
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF Ord(C)=0 THEN
                BEGIN
                     C := ReadKey;
                     CASE Ord(C) OF
                     59:  GeneralHelp;
                     45:  AllDone := True;
                     75:  IF ((NumMsgs<>0) AND (Current>1)) THEN
                          BEGIN
                               DEC(Current);
                               GetTheMessage(Current);
                               DrawTheMessage;
                               DrawTheMessageText;
                          END;
                     77:  IF ((NumMsgs<>0) AND (Current<NumMsgs)) THEN
                          BEGIN
                               INC(Current);
                               GetTheMessage(Current);
                               DrawTheMessage;
                               DrawTheMessageText;
                          END;
                     72:  IF ((NumMsgs<>0) AND (Top>1)) THEN
                          BEGIN
                               DEC(Top);
                               DrawTheMessageText;
                          END;
                     80:  IF ((NumMsgs<>0) AND (Top+17<=NumLines)) THEN
                          BEGIN
                               INC(Top);
                               DrawTheMessageText;
                          END;
                     73:  IF ((NumMsgs<>0) AND (NumLines>16)) THEN
                          BEGIN
                               TT := Top-17;
                               IF TT<1 THEN TT := 1;
                               IF (TT<>Top) THEN
                               BEGIN
                                    Top := TT;
                                    DrawTheMessageText;
                               END;
                          END;
                     81:  IF ((NumMsgs<>0) AND (NumLines>16)) THEN
                          BEGIN
                               TT := Top+17;
                               IF TT+16>NumLines THEN TT := NumLines-16;
                               IF (TT<>Top) THEN
                               BEGIN
                                    Top := TT;
                                    DrawTheMessageText;
                               END;
                          END;
                     132: IF ((NumMsgs<>0) AND (NumLines>16)) THEN
                          BEGIN
                               TT := 1;
                               IF (TT<>Top) THEN
                               BEGIN
                                    Top := TT;
                                    DrawTheMessageText;
                               END;
                          END;
                     118: IF ((NumMsgs<>0) AND (NumLines>16)) THEN
                          BEGIN
                               TT := NumLines-16;
                               IF (TT<>Top) THEN
                               BEGIN
                                    Top := TT;
                                    DrawTheMessageText;
                               END;
                          END;
                     83:  IF (NumMsgs<>0) THEN
                          BEGIN {Delete Msg}
                               Save_Screen3;
                               DrawWindow(20,9,55,14,'',True);
                               FastWrite('Delete the current message.',11,25,31);
                               FastWrite('    Are you sure? (Y/N)    ',12,25,31);
                               C := ReadKey;
                               Restore_Screen3;
                               IF Ord(C)=0 THEN C := ReadKey
                               ELSE IF UpCase(C)='Y' THEN
                               BEGIN
                                    IF FastBaseHdr.FileAttach THEN
                                    BEGIN
                                         Save_Screen3;
                                         DrawWindow(20,9,55,14,'',True);
                                         FastWrite('Delete the attached file?? ',11,25,31);
                                         FastWrite('           (Y/N)           ',12,25,31);
                                         C := ReadKey;
                                         Restore_Screen3;
                                         IF Ord(C)=0 THEN C := ReadKey
                                         ELSE IF UpCase(C)='Y' THEN _EraseFile(FastBaseHdr.MsgSubject);
                                    END;
                                    _EraseFile(MailerInfo.NetMail+_String(Indexes[Current])+'.MSG');
                                    IndexAreas;
                                    FOR Loop := 2 TO 6 DO FastWrite(_PadRight('',80),Loop,1,7);
                                    FOR Loop := 8 TO 24 DO FastWrite(_PadRight('',80),Loop,1,7);
                                    IF (NumMsgs<>0) THEN
                                    BEGIN
                                         GetTheMessage(Current);
                                         DrawTheMessage;
                                         DrawTheMessageText;
                                    END
                                    ELSE FastWrite('No Messages In This Folder',4,3,11);
                                    CreateSemaphore(2);
                               END;
                          END;
                     82:  BEGIN {New Message}
                               Loop := NumMsgs;
                               Save_Screen3;
                               DoNewMessage;
                               Restore_Screen3;
                               IndexAreas;
                               IF Loop=0 THEN
                               BEGIN
                                 Current := 1;
                                 FOR Loop := 2 TO 6 DO FastWrite(_PadRight('',80),Loop,1,7);
                                 FOR Loop := 8 TO 24 DO FastWrite(_PadRight('',80),Loop,1,7);
                                 IF (NumMsgs<>0) THEN
                                 BEGIN
                                      GetTheMessage(Current);
                                      DrawTheMessage;
                                      DrawTheMessageText;
                                 END
                                 ELSE FastWrite('No Messages In This Folder',4,3,11);
                               END;
                          END;
                     32:  BEGIN {Dump To Text File}
                               Save_Screen3;
                               DumpCurrentMessage;
                               Restore_Screen3;
                          END;
                     19:  BEGIN {Reply To Message}
                               Save_Screen3;
                               ReplyToMessage;
                               Restore_Screen3;
                               IndexAreas;
                               GetTheMessage(Current);
                          END;
                     18:  BEGIN {Edit Message}
                               EditCurrentMessage;
                               IndexAreas;
                               GetTheMessage(Current);
                               DrawTheMessage;
                               DrawTheMessageText;
                          END;
                     60:  BEGIN {F2 DOS Shell}
                               OldX := WhereX;
                               OldY := WhereY;
                               Save_Screen3;
                               ClrScr;
                               _ShowCursor;
                               PutEnviro('PROMPT=Enter EXIT to return to GSEdit!!$_$p$g');
                               DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),SwapMethod,MailerInfo.Outpkts);
                               ChDir(Shotgun_Directory);
                               _HideCursor;
                               Restore_Screen3;
                               GotoXY(OldX,OldY);
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(C) OF
                     27:  AllDone := True;
                     END;
                END;
           END
           ELSE IF GotARescan THEN
           BEGIN
                IndexAreas;
                FOR Loop := 2 TO 6 DO FastWrite(_PadRight('',80),Loop,1,7);
                FOR Loop := 8 TO 24 DO FastWrite(_PadRight('',80),Loop,1,7);
                IF (NumMsgs<>0) THEN
                BEGIN
                     GetTheMessage(Current);
                     DrawTheMessage;
                     DrawTheMessageText;
                END
                ELSE FastWrite('No Messages In This Folder',4,3,11);
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     _ShowCursor;
     _EraseFile(MailerInfo.OutPkts+'READ.$$$');
     Dispose(Buffer);
END;


PROCEDURE DrawMailStatus;
VAR  Temp : String;
BEGIN
     Temp :=  '';
     IF FastBaseHdr.Priv         THEN Temp := Temp+'Pvt ';
     IF FastBaseHdr.FileAttach   THEN Temp := Temp+'File ';
     IF FastBaseHdr.FileRequest  THEN Temp := Temp+'Freq ';
     IF FastBaseHdr.Crash        THEN Temp := Temp+'Crash ';
     IF FastBaseHdr.Hold         THEN Temp := Temp+'Hold ';
     IF FastBaseHdr.KillSent     THEN Temp := Temp+'Kill ';
     IF FastBaseHdr.Sent         THEN Temp := Temp+'Sent ';
     IF FastBaseHdr.Recv         THEN Temp := Temp+'Rcvd ';
     IF FastBaseHdr.Direct       THEN Temp := Temp+'Direct ';
     IF FastBaseHdr.Immediate    THEN Temp := Temp+'Immediate ';
     IF FastBaseHdr.InTransit    THEN Temp := Temp+'InTransit ';
     IF FastBaseHdr.Orphan       THEN Temp := Temp+'Orphan ';
     IF FastBaseHdr.TruncSent    THEN Temp := Temp+'Trunc/Sent ';
     IF FastBaseHdr.KillFileSent THEN Temp := Temp+'Kill/Sent ';
     IF FastBaseHdr.Exclusive    THEN Temp := Temp+'Exclusive ';
     FastWrite(_PadRight(Temp,72),6,8,11);
END;


FUNCTION GetMsgSubject(X,Y,Len,Attr: Word; Stuff: String): String;
VAR  AllDone   : Boolean;
     OldX,OldY : Word;
     Loop      : Word;
     C         : Char;
LABEL            JumpIn;
BEGIN
     OldX := WhereX;
     OldY := WhereY;
     Save_Screen;

     DrawWindow(48,10,77,23,'NETMAIL STATUS',True);
     InvertedBox(50,11,75,22);
     FastWrite('ALT-C     Crash        ',12,52,31);
     FastWrite('ALT-D     Direct       ',13,52,31);
     FastWrite('ALT-E     Exclusive    ',14,52,31);
     FastWrite('ALT-F     File Attach  ',15,52,31);
     FastWrite('ALT-H     Hold         ',16,52,31);
     FastWrite('ALT-I     Immediate    ',17,52,31);
     FastWrite('ALT-K     Kill/Sent    ',18,52,31);
     FastWrite('ALT-P     Private      ',19,52,31);
     FastWrite('ALT-R     File Request ',20,52,31);
     FastWrite('ALT-T     Trunc/Sent   ',21,52,31);

     FastWrite(_PadRight(Stuff,Len),Y,X,31);
     GotoXY(X+Length(Stuff),Y);
     _ShowCursor;
     c := Chr(0);
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF (Ord(c)=0) THEN
                BEGIN
                     c := ReadKey;
                     CASE ORD(C) OF
                     18:  IF FastBaseHdr.Exclusive
                             THEN FastBaseHdr.Exclusive := False
                             ELSE FastBaseHdr.Exclusive := True;
                     19:  BEGIN
                               IF FastBaseHdr.FileRequest
                                  THEN FastBaseHdr.FileRequest := False
                                  ELSE FastBaseHdr.FileRequest := True;
                               FastBaseHdr.FileAttach := False;
                          END;
                     20:  IF FastBaseHdr.TruncSent
                             THEN FastBaseHdr.TruncSent := False
                             ELSE FastBaseHdr.TruncSent := True;
                     23:  BEGIN
                               IF FastBaseHdr.Immediate
                                  THEN FastBaseHdr.Immediate := False
                                  ELSE FastBaseHdr.Immediate := True;
                               FastBaseHdr.Hold := False;
                          END;
                     25:  IF FastBaseHdr.Priv
                             THEN FastBaseHdr.Priv := False
                             ELSE FastBaseHdr.Priv := True;
                     32:  IF FastBaseHdr.Direct
                             THEN FastBaseHdr.Direct := False
                             ELSE FastBaseHdr.Direct := True;
                     33:  BEGIN
                               IF FastBaseHdr.FileAttach
                                  THEN FastBaseHdr.FileAttach := False
                                  ELSE FastBaseHdr.FileAttach := True;
                               FastBaseHdr.FileRequest := False;
                          END;
                     35:  BEGIN
                               IF FastBaseHdr.Hold
                                  THEN FastBaseHdr.Hold := False
                                  ELSE FastBaseHdr.Hold := True;
                               FastBaseHdr.Crash := False;
                               FastBaseHdr.Immediate := False;
                          END;
                     37:  IF FastBaseHdr.KillSent
                             THEN FastBaseHdr.KillSent := False
                             ELSE FastBaseHdr.KillSent := True;
                     46:  BEGIN
                               IF FastBaseHdr.Crash
                                  THEN FastBaseHdr.Crash := False
                                  ELSE FastBaseHdr.Crash := True;
                               FastBaseHdr.Hold := False;
                          END;
                     ELSE BEGIN
                               C := IsTheKeyOk(C,True);
                               IF (C<>#0) THEN GOTO JumpIn;
                          END;
                     END;
                     DrawMailStatus;
                END
                ELSE
                BEGIN
                     CASE Ord(C) OF
                     8:   BEGIN
                               IF LENGTH(Stuff)>0 THEN
                               BEGIN
                                    Delete(Stuff,LENGTH(Stuff),1);
                                    FastWrite(_PadRight(Stuff,Len),Y,X,31);
                                    GotoXY(X+Length(Stuff),Y);
                               END;
                          END;
                     127: BEGIN
                               Stuff := '';
                               FastWrite(_PadRight(Stuff,Len),Y,X,31);
                               GotoXY(X+Length(Stuff),Y);
                          END;
                     13:  AllDone := True;
                     27:  BEGIN
                               Stuff := '';
                               AllDone := True;
                          END;
                     ELSE BEGIN
                               C := IsTheKeyOk(C,False);
                               IF (C<>#0) THEN
                               BEGIN
                                    JumpIn:
                                    IF LENGTH(Stuff)<Len THEN
                                    BEGIN
                                         Stuff := Stuff+c;
                                         FastWrite(_PadRight(Stuff,Len),Y,X,31);
                                         GotoXY(X+Length(Stuff),Y);
                                    END;
                               END;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     _HideCursor;
     Restore_Screen;
     FastWrite(_PadRight(Stuff,Len),Y,X,Attr);
     GotoXY(OldX,OldY);
     GetMsgSubject := Stuff;
END;


PROCEDURE StoreTheMessage(ForcedMsgNum: Word);
VAR  Temp      : String;
     TFile     : Text;
     NewMsgNum : Word;
     WByteLo   : Byte;
     WByteHi   : Byte;
     FFile     : File;
     OldX      : Word;
     OldY      : Word;
     C         : Char;
     SpellFile : String[80];
     SpellComm : String;
     FName     : String[80];
     FPath     : String[80];
     Work      : Word;

     PROCEDURE AddAString(InString: String);
     BEGIN
          Temp := InString+#13;
          BLOCKWRITE(FFile,Temp[1],LENGTH(Temp));
     END;

BEGIN
     Temp := ExternalApps.SpellChecker;
     Work := Pos(' ',Temp);
     SpellComm := '';
     IF (Work<>0) THEN
     BEGIN
          SpellFile := _Mid(Temp,1,Work-1);
          Delete(Temp,1,Work);
          SpellComm := _RemoveLeftSpaces(Temp);
     END
     ELSE SpellFile := Temp;
     FName := _NoPath(SpellFile);
     FPath := _GetFilePath(SpellFile);
     IF FPath='' THEN FPath := Shotgun_Directory+'\';
     Dec(FPath[0]);
     Work := Pos('%1',SpellComm);
     IF (Work<>0) THEN
     BEGIN
          Delete(SpellComm,Work,2);
          Insert(MailerInfo.OutPkts+'EDITOR.$$$',SpellComm,Work);
     END
     ELSE SpellComm := SpellComm+' '+MailerInfo.OutPkts+'EDITOR.$$$';
     IF _FileExists(SpellFile) THEN
     BEGIN
          OldX := WhereX;
          OldY := WhereY;
          Save_Screen;
          DrawWindow(20,9,55,14,'',True);
          FastWrite('Spell check this message?? ',11,25,31);
          FastWrite('           (Y/N)           ',12,25,31);
          C := ReadKey;
          IF Ord(C)=0 THEN C := ReadKey;
          IF UpCase(C)='Y' THEN
          BEGIN
               ClrScr;
               ChDir(FPath);
               DoExec(FName,SpellComm,SwapMethod,MailerInfo.Outpkts);
               ChDir(Shotgun_Directory);
          END;
          Restore_Screen;
          GotoXY(OldX,OldY);
     END;
     _CreatePath(MailerInfo.NetMail);
     FillChar(FidoHeader,SizeOf(FidoHeader),0);
     Temp := GetFidoDate;
     Move(Temp[1],FidoHeader.DateTime,19);
     FidoHeader.OrigNode := FastBaseHdr.Orig.Node;
     FidoHeader.DestNode := FastBaseHdr.Dest.Node;
     FidoHeader.OrigNet  := FastBaseHdr.Orig.Net;
     FidoHeader.DestNet  := FastBaseHdr.Dest.Net;
     FidoHeader.Cost     := 0;
     Move(FastBaseHdr.MsgFrom[1],FidoHeader.MsgFrom,LENGTH(FastBaseHdr.MsgFrom));
     Move(FastBaseHdr.MsgTo[1],FidoHeader.MsgTo,LENGTH(FastBaseHdr.MsgTo));
     Move(FastBaseHdr.MsgSubject[1],FidoHeader.MsgSubject,LENGTH(FastBaseHdr.MsgSubject));
     WByteLo := 0;
     WByteHi := 0;
     IF FastBaseHdr.Priv THEN WByteLo := (WByteLo OR 001);
     IF FastBaseHdr.Crash THEN WByteLo := (WByteLo OR 002);
     IF FastBaseHdr.Recv THEN WByteLo := (WByteLo OR 004);
     IF FastBaseHdr.Sent THEN WByteLo := (WByteLo OR 008);
     IF FastBaseHdr.FileAttach THEN WByteLo := (WByteLo OR 016);
     IF FastBaseHdr.InTransit THEN WByteLo := (WByteLo OR 032);
     IF FastBaseHdr.Orphan THEN WByteLo := (WByteLo OR 064);
     IF FastBaseHdr.KillSent THEN WByteLo := (WByteLo OR 128);
     IF FastBaseHdr.Local THEN WByteHi := (WByteHi OR 001);
     IF FastBaseHdr.Hold THEN WByteHi := (WByteHi OR 002);
     IF FastBaseHdr.FileRequest THEN WByteHi := (WByteHi OR 008);
     FidoHeader.Attribute := (WByteHi*256)+WByteLo;
     IF ForcedMsgNum=0 THEN NewMsgNum := NextMsgNum+1
                       ELSE NewMsgNum := ForcedMsgNum;
     ASSIGN(FFile,MailerInfo.NetMail+_String(NewMsgNum)+'.MSG');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,FidoHeader,SizeOf(FidoHeader));
     IF (FastBaseHdr.Orig.Point<>0) THEN AddAString(#1+'FMPT '+_String(FastBaseHdr.Orig.Point));
     IF (FastBaseHdr.Dest.Point<>0) THEN AddAString(#1+'TOPT '+_String(FastBaseHdr.Dest.Point));
     AddAString(#1+'INTL '+AddressToStringNoPoint(FastBaseHdr.Dest)+' '+AddressToStringNoPoint(FastBaseHdr.Orig));
     AddAString(GetMsgId(FastBaseHdr.Orig));
     IF (ReplyDomain<>'') THEN AddAString(#1+'REPLY: '+ReplyDomain);
     AddAString(#1+'PID: '+OurAppName);
     IF ((FastBaseHdr.FileAttach) OR (FastBaseHdr.FileRequest)) THEN FastBaseHdr.Direct := True;
     Temp := #1+'FLAGS';
     IF FastBaseHdr.Immediate    THEN Temp := Temp+' IMM';
     IF FastBaseHdr.TruncSent    THEN Temp := Temp+' TFS';
     IF FastBaseHdr.KillFileSent THEN Temp := Temp+' KFS';
     IF FastBaseHdr.Direct       THEN Temp := Temp+' DIR';
     IF FastBaseHdr.Exclusive    THEN Temp := Temp+' EXC';
     IF (Temp<>#1+'FLAGS') THEN AddAString(Temp);
     ASSIGN(TFile,MailerInfo.OutPkts+'EDITOR.$$$');
     RESET(TFile);
     REPEAT
           READLN(TFile,Temp);
           AddAString(Temp);
     UNTIL EOF(TFile);
     CLOSE(TFile);
     CLOSE(FFile);
END;


FUNCTION WriterMsgFrom(Stuff: String): Boolean;
VAR  Temp : String;
BEGIN
     FastWrite(_PadRight('',72),3,8,7);
     FastBaseHdr.MsgFrom := GetInput(8,3,36,11,Stuff,False);
     IF (FastBaseHdr.MsgFrom<>'') THEN
     BEGIN
       IF ChangeCurrentAKA THEN
       BEGIN
         ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
         RESET(FNetwork);
         SEEK(FNetwork,CurrentAka-1);
         READ(FNetwork,Network);
         CLOSE(FNetwork);
         FastBaseHdr.Orig := Network.Net_Address;
         Temp := GetBBSName(FastBaseHdr.Orig);
         IF (Temp<>'') THEN
         BEGIN
           FastWrite(FastBaseHdr.MsgFrom+', '+Temp+' ('+AddressToString(FastBaseHdr.Orig)+')',3,8,11);
           WriterMsgFrom := True;
         END
         ELSE WriterMsgFrom := False;
       END
       ELSE WriterMsgFrom := False;
     END
     ELSE WriterMsgFrom := False;
     _ShowCursor;
END;


FUNCTION WriterMsgTo(Stuff: String): Boolean;
VAR  Temp    : String;
     TmpAddr : AddrType;
LABEL          GotInfo;
BEGIN
     FastWrite(_PadRight('',72),4,8,7);
     FastBaseHdr.MsgTo := GetInput(8,4,36,11,Stuff,False);
     IF FastBaseHdr.MsgTo<>'' THEN
     BEGIN
          IF ((Pos(':',FastBaseHdr.MsgTo)<>0) AND (Pos('/',FastBaseHdr.MsgTo)<>0)) THEN
          BEGIN
            StringToAddress(FastBaseHdr.MsgTo,TmpAddr);
            IF GetNodeInfo(TmpAddr)<>'' THEN
            BEGIN
              StringToAddress(FastBaseHdr.MsgTo,FastBaseHdr.Dest);
              FastBaseHdr.MsgTo := NodeListSysop;
              Temp := GetBBSName(FastBaseHdr.Dest);
              IF (Temp<>'-Unlisted-') THEN
              BEGIN
                FastWrite(_PadRight('',72),4,8,7);
                FastWrite(FastBaseHdr.MsgTo+', '+Temp+' ('+AddressToString(FastBaseHdr.Dest)+')',4,8,11);
                WriterMsgTo := True;
              END
              ELSE WriterMsgTo := False;
            END
            ELSE WriterMsgTo := False;
          END
          ELSE
          BEGIN
               IF InTheBook(FastBaseHdr.MsgTo) THEN
               BEGIN
                 IF (GetNodeInfo(PhoneBook.NetAddress)<>'') THEN
                 BEGIN
                   FastBaseHdr.MsgTo := PhoneBook.Description;
                   FastBaseHdr.Dest  := PhoneBook.NetAddress;
                   Temp := GetBBSName(FastBaseHdr.Dest);
                   GOTO GotInfo;
                 END;
               END;
               IF SelectedAName(FastBaseHdr.MsgTo,FastBaseHdr.Dest) THEN
               BEGIN
                 Temp := GetBBSName(FastBaseHdr.Dest);
                 IF (Temp<>'-Unlisted-') THEN
                 BEGIN
                   FastBaseHdr.MsgTo := NodeListSysop;
                   GotInfo:
                   FastWrite(_PadRight('',72),4,8,7);
                   FastWrite(FastBaseHdr.MsgTo+', '+Temp+' ('+AddressToString(FastBaseHdr.Dest)+')',4,8,11);
                   WriterMsgTo := True;
                 END
                 ELSE WriterMsgTo := False;
               END
               ELSE
               BEGIN
                 FastWrite(_PadRight('',72),4,8,7);
                 FastWrite(FastBaseHdr.MsgTo+', ',4,8,11);
                 Temp := GetInput(8+LENGTH(FastBaseHdr.MsgTo)+2,4,20,11,'',False);
                 IF (Temp<>'') THEN
                 BEGIN
                   StringToAddress(Temp,FastBaseHdr.Dest);
                   Temp := GetBBSName(FastBaseHdr.Dest);
                   FastWrite(_PadRight('',72),4,8,7);
                   FastWrite(FastBaseHdr.MsgTo+', '+Temp+' ('+AddressToString(FastBaseHdr.Dest)+')',4,8,11);
                   WriterMsgTo := True;
                 END
                 ELSE WriterMsgTo := False;
               END;
          END;
     END
     ELSE WriterMsgTo := False;
     _ShowCursor;
END;


FUNCTION WriterMsgSubject(Stuff: String): Boolean;
BEGIN
     FastWrite(_PadRight('',72),5,8,7);
     DrawMailStatus;
     FastBaseHdr.MsgSubject := GetMsgSubject(8,5,72,11,Stuff);
     IF (FastBaseHdr.MsgSubject<>'') THEN
     BEGIN
          DrawMailStatus;
          WriterMsgSubject := True;
     END
     ELSE WriterMsgSubject := False;
     _ShowCursor;
END;


PROCEDURE DoNewMessage;
VAR  OldAKA  : Word;
     OrigHdr : Message_Header;
BEGIN
     Move(FastBaseHdr,OrigHdr,SizeOf(FastBaseHdr));
     GotoXY(1,8);
     OldAka := CurrentAka;
     FillChar(FastBaseHdr,SizeOf(FastBaseHdr),0);
     FastBaseHdr.Local      := True;
     FastBaseHdr.Echo       := True;
     FastBaseHdr.KillSent   := True;
     FastBaseHdr.Priv       := True;
     FastBaseHdr.MsgSubject := '';
     DrawMainScreen;
     IF WriterMsgFrom(SystemInfo.Sysop) THEN
     BEGIN
          IF WriterMsgTo('') THEN
          BEGIN
               IF WriterMsgSubject('') THEN
               BEGIN
                    New(EditorObject);
                    InitEditor(1,8,79,24);
                    FullEditor(False,False);
                    Dispose(EditorObject);
                    IF _FileExists(MailerInfo.OutPkts+'EDITOR.$$$') THEN
                    BEGIN
                         StoreTheMessage(0);
                         CreateSemaphore(2);
                    END;
               END;
          END;
     END;
     _HideCursor;
     CurrentAka := OldAka;
     _EraseFile(MailerInfo.OutPkts+'EDITOR.$$$');
     Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
END;


PROCEDURE ReplyToMessage;
VAR  OldAKA      : Word;
     OrigFrom    : String;
     OrigTo      : String;
     OrigSubject : String;
     OrigHdr     : Message_Header;
BEGIN
     OrigFrom    := FastBaseHdr.MsgFrom;
     OrigTo      := FastBaseHdr.MsgTo;
     OrigSubject := FastBaseHdr.MsgSubject;
     Move(FastBaseHdr,OrigHdr,SizeOf(FastBaseHdr));
     GotoXY(1,8);
     OldAka := CurrentAka;
     FillChar(FastBaseHdr,SizeOf(FastBaseHdr),0);
     FastBaseHdr.Local      := True;
     FastBaseHdr.Echo       := True;
     FastBaseHdr.KillSent   := True;
     FastBaseHdr.Priv       := True;
     DrawMainScreen;
     IF WriterMsgFrom(OrigTo) THEN
     BEGIN
          IF WriterMsgTo(OrigFrom) THEN
          BEGIN
               IF WriterMsgSubject(OrigSubject) THEN
               BEGIN
                    New(EditorObject);
                    InitEditor(1,8,79,24);
                    FullEditor(True,False);
                    Dispose(EditorObject);
                    IF _FileExists(MailerInfo.OutPkts+'EDITOR.$$$') THEN
                    BEGIN
                         StoreTheMessage(0);
                         CreateSemaphore(2);
                    END;
               END;
          END;
     END;
     _HideCursor;
     CurrentAka := OldAka;
     _EraseFile(MailerInfo.OutPkts+'EDITOR.$$$');
     Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
END;


PROCEDURE EditCurrentMessage;
VAR  OldAKA  : Word;
     OrigHdr : Message_Header;
BEGIN
     Move(FastBaseHdr,OrigHdr,SizeOf(FastBaseHdr));
     GotoXY(1,8);
     OldAka := CurrentAka;
     DrawMainScreen;
     IF WriterMsgFrom(FastBaseHdr.MsgFrom) THEN
     BEGIN
          IF WriterMsgTo(FastBaseHdr.MsgTo) THEN
          BEGIN
               IF WriterMsgSubject(FastBaseHdr.MsgSubject) THEN
               BEGIN
                    New(EditorObject);
                    InitEditor(1,8,79,24);
                    FullEditor(False,True);
                    Dispose(EditorObject);
                    IF _FileExists(MailerInfo.OutPkts+'EDITOR.$$$') THEN
                    BEGIN
                         StoreTheMessage(FastBaseHdr.MsgNumber);
                         CreateSemaphore(2);
                    END
                    ELSE Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
               END
               ELSE Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
          END
          ELSE Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
     END
     ELSE Move(OrigHdr,FastBaseHdr,SizeOf(OrigHdr));
     _HideCursor;
     CurrentAka := OldAka;
     _EraseFile(MailerInfo.OutPkts+'EDITOR.$$$');
END;


END.
