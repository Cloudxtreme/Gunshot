{$I DEFINES.INC}
UNIT Special;


INTERFACE


FUNCTION process_special(work_string: string; PreProcess: Boolean): string;
FUNCTION remove_special(work_string: string): string;


IMPLEMENTATION


USES Globals,Time,MiscStr,CBVMisc,FilHeadr,MsgHeadr,TagArea,Version,
     BaseInfo,ApTimer,MkString,ANSIMisc,CDS,Archiver,Dates,Commands,
     BsString,BsTime,BsMulti;


FUNCTION remove_special(work_string: string): string;
VAR  work    : word;
     Loop    : Word;
     LookFor : String;
     SS      : String;
BEGIN
     IF work_string='' THEN
     BEGIN
          remove_special := '';
          EXIT;
     END;
     {Remove Clear Screen}
     Work := Pos(#27+'[2J',work_string);
     IF Work<>0 THEN Delete(Work_String,Work,4);
     Work := Pos(#12,work_string);
     IF Work<>0 THEN Delete(Work_String,Work,1);
     {Remove The Colour Codes}
     FOR Loop := 0 TO 15 DO
     BEGIN
          SS := _String(Loop);
          LookFor := '{'+SS+'}';
          REPEAT
                Work := Pos(LookFor,Work_String);
                IF (Work<>0) THEN Delete(Work_String,Work,Length(LookFor));
          UNTIL Work=0;
          IF NOT(IsRip) THEN
          BEGIN
               IF (Loop<10) THEN LookFor := '|0'+SS
                            ELSE LookFor := '|'+SS;
               REPEAT
                     Work := Pos(LookFor,Work_String);
                     IF (Work<>0) THEN Delete(Work_String,Work,3);
               UNTIL Work=0;
          END;
     END;
     remove_special := Work_String;
END;


FUNCTION GetTheNumeric(InString: String): Word;
VAR  Loop : Word;
BEGIN
     FOR Loop := 1 TO LENGTH(InString) DO
     BEGIN
          IF NOT(IsNumeric(InString[Loop])) THEN
          BEGIN
               GetTheNumeric := _Numeric(_Mid(InString,1,Loop-1));
               Exit;
          END;
     END;
     GetTheNumeric := 0;
END;


FUNCTION process_special(work_string: string; PreProcess: Boolean): string;
VAR  L7            : word;
     L8            : word;
     R             : string;
     work_word     : word;
     cunt          : word;
     check_colour  : string;
     end_of_colour : byte;
     override      : byte;
     SS            : Byte;
     ES            : Byte;
     Im            : Byte;
     SL            : Byte;
     MaxLook       : Byte;
     tttt          : String;
     String2       : String[3];
     Code          : Integer;
     P1            : Byte;
     P2            : Byte;
LABEL                over_again;
BEGIN
     L7 := Pos(Chr(27)+'[2J',work_string);
     IF L7<>0 THEN
     BEGIN
          had_a_clear := true;
          Delete(work_string,1,L7+3);
     END;
     L7 := Pos(Chr(12),work_string);
     IF L7<>0 THEN
     BEGIN
          had_a_clear := true;
          Delete(work_string,L7,1);
     END;
     Override := 1;
     over_again:
     FOR L7 := override TO LENGTH(work_string) DO
     BEGIN
          IF ((work_string[L7]='{') OR (work_string[L7]='|')) THEN
          BEGIN
               IF work_string[L7]='|' THEN
               BEGIN
                 IF IsRip THEN
                 BEGIN
                   OverRide := L7+1;
                   GOTO Over_Again;
                 END;
                 String2 := _Mid(work_string,L7+1,L7+2);
                 IF IsNumeric(String2) THEN
                 BEGIN
                   Delete(Work_String,L7,3);
                   IF NOT(PreProcess) THEN
                   BEGIN
                     VAL(String2,Work_Word,Code);
                     CASE Work_Word OF
                     0..15: BEGIN
                              R := get_fore(_String(work_word));
                              Insert(R,work_string,L7);
                            END;
                     END;
                   END;
                   OverRide := L7+1;
                   GOTO Over_Again;
                 END;
               END;
               P1 := _Pos2('|',work_string,L7+1);
               P2 := _Pos2('}',work_string,L7+1);
               IF P1=0 THEN
               BEGIN
                 IF (P2<>0) THEN L8 := P2
                            ELSE L8 := 0;
               END
               ELSE IF P2=0 THEN
               BEGIN
                 IF (P1<>0) THEN L8 := P1
                            ELSE L8 := 0;
               END
               ELSE
               BEGIN
                 IF P1<P2 THEN L8 := P1
                          ELSE L8 := P2;
               END;
               IF L8=0 THEN
               BEGIN
                    INC(Override);
                    GOTO Over_Again;
               END;

               SS := L7+1;
               ES := L8-1;
               Im := 0;
               R  := 'UNGABUNGABANG';

                    IF ((work_string[L7]='{') AND (work_string[L8]='}')) THEN Im := 1
               ELSE IF ((work_string[L7]='{') AND (work_string[L8]='|')) THEN Im := 2
               ELSE IF ((work_string[L7]='|') AND (work_string[L8]='}')) THEN Im := 3
               ELSE
               BEGIN
                    Override := L7+1;
                    Goto Over_Again;
               END;

                    IF _Pos2('CURRENTMESSAGEGROUP',work_string,SS)=SS THEN R := MessageSubs.Sub_Name
               ELSE IF _Pos2('CURRENTMESSAGEAREA',work_string,SS)=SS THEN R := MessageAreas.Area_Name
               ELSE IF _Pos2('USERSSTREETADDRESS',work_string,SS)=SS THEN R := UserRecord.street
               ELSE IF _Pos2('CURRENTFILEGROUP',work_string,SS)=SS THEN R := FileSubs.Sub_Name
               ELSE IF _Pos2('OPERATINGSYSTEM',work_string,SS)=SS THEN R := _GetOperatingSystem
               ELSE IF _Pos2('CURRENTFILEAREA',work_string,SS)=SS THEN R := FileAreas.Area_Name
               ELSE IF _Pos2('USERSPOSTALCODE',work_string,SS)=SS THEN R := UserRecord.postal
               ELSE IF _Pos2('SYSOPSALIASNAME',work_string,SS)=SS THEN R := system_info.alias
               ELSE IF _Pos2('USERSALIASNAME',work_string,SS)=SS THEN R := UserRecord.alias
               ELSE IF _Pos2('SYSOPSREALNAME',work_string,SS)=SS THEN R := system_info.sysop
               ELSE IF _Pos2('USERSVOICENUM',work_string,SS)=SS THEN R := UserRecord.voice
               ELSE IF _Pos2('USERSREALNAME',work_string,SS)=SS THEN R := UserRecord.name
               ELSE IF _Pos2('USERSPASSWORD',work_string,SS)=SS THEN R := UserRecord.password
               ELSE IF _Pos2('USERSPROVINCE',work_string,SS)=SS THEN R := UserRecord.prov
               ELSE IF _Pos2('FMONTHDAYYEAR',work_string,SS)=SS THEN R := _GetPrettyDate
               ELSE IF _Pos2('USERSCOUNTRY',work_string,SS)=SS THEN R := UserRecord.country
               ELSE IF _Pos2('USERSDATANUM',work_string,SS)=SS THEN R := UserRecord.data
               ELSE IF _Pos2('BBSLOCATION',work_string,SS)=SS THEN R := system_info.location
               ELSE IF _Pos2('USERSFNAME',work_string,SS)=SS THEN R := UsersFirstName
               ELSE IF _Pos2('USERSLNAME',work_string,SS)=SS THEN R := UsersLastName
               ELSE IF _Pos2('USERSCITY',work_string,SS)=SS THEN R := UserRecord.city
               ELSE IF _Pos2('UARCHIVER',work_string,SS)=SS THEN R := GetArcName(UserRecord.DefaultArchiver)
               ELSE IF _Pos2('UPROTOCOL',work_string,SS)=SS THEN
               BEGIN
                    CASE UserRecord.DefaultProtocol OF
                    1:   R := 'ZModem';
                    2:   R := 'XModem';
                    3:   R := 'XModem1K';
                    4:   R := 'YModem';
                    5:   R := 'YModemG';
                    ELSE R := 'None';
                    END;
               END
               ELSE IF _Pos2('CDROMNAME',work_string,SS)=SS THEN
               BEGIN
                    Work_Word := GetTheNumeric(_Mid(work_string,SS+9,LENGTH(Work_String)));
                    R := GetCDName(Work_Word);
               END
               ELSE IF _Pos2('MMDDYYYY',work_string,SS)=SS THEN R := _MMDDYYYY
               ELSE IF _Pos2('SUBTIME1',work_string,SS)=SS THEN R := _String(UserAccess.SubCalendarDays)
               ELSE IF _Pos2('SUBTIME2',work_string,SS)=SS THEN R := _String(UserAccess.SubCallDays)
               ELSE IF _Pos2('SUBTIME3',work_string,SS)=SS THEN R := _String(UserAccess.SubMinutes)
               ELSE IF _Pos2('USETIME1',work_string,SS)=SS THEN R := _String(UserRecord.SubCalendarDaysUsed)
               ELSE IF _Pos2('USETIME2',work_string,SS)=SS THEN R := _String(UserRecord.SubCallDaysUsed)
               ELSE IF _Pos2('USETIME3',work_string,SS)=SS THEN R := _String(UserRecord.SubMinutesUsed)
               ELSE IF _Pos2('SUBMODEL',work_string,SS)=SS THEN
               BEGIN
                    CASE UserRecord.SubModel OF
                    0:   R := 'None';
                    1:   R := 'Calendar Day Expiry';
                    2:   R := 'Call Day Expiry';
                    3:   R := 'Minutes Used Expiry';
                    ELSE R := 'Calendar Date Expiry';
                    END;
               END
               ELSE IF _Pos2('VERSION',work_string,SS)=SS THEN R := GunshotVersion
               ELSE IF _Pos2('BINBANK',work_string,SS)=SS THEN STR(UserRecord.ByteBankBalance,R)
               ELSE IF _Pos2('BREMAIN',work_string,SS)=SS THEN STR(UserRecord.DLBytesRemaining,R)
               ELSE IF _Pos2('BUPLOAD',work_string,SS)=SS THEN STR(UserRecord.uploads,R)
               ELSE IF _Pos2('BDNLOAD',work_string,SS)=SS THEN STR(UserRecord.dl_total,R)
               ELSE IF _Pos2('FUPLOAD',work_string,SS)=SS THEN STR(UserRecord.files_uploaded,R)
               ELSE IF _Pos2('FDNLOAD',work_string,SS)=SS THEN STR(UserRecord.files_downloaded,R)
               ELSE IF _Pos2('SYSBYTE',work_string,SS)=SS THEN STR(UserAccess.daily_bytes,R)
               ELSE IF _Pos2('BBSNAME',work_string,SS)=SS THEN R := system_info.bbs_name
               ELSE IF _Pos2('TBTRANS',work_string,SS)=SS THEN STR(Trunc(System_Info.TBank_Trans/60),R)
               ELSE IF _Pos2('BBTRANS',work_string,SS)=SS THEN STR(System_Info.BBank_Trans,R)
               ELSE IF _Pos2('USERACC',work_string,SS)=SS THEN STR(UserRecord.Security,R)
               ELSE IF _Pos2('REMAIN',work_string,SS)=SS THEN R := TimeRemainingString
               ELSE IF _Pos2('USEREX',work_string,SS)=SS THEN R := TranslateDate1(_UnpackedDate(UserRecord.Sub_Expiry))
               ELSE IF _Pos2('TCALLS',work_string,SS)=SS THEN STR(totals.total_calls,R)
               ELSE IF _Pos2('CALLST',work_string,SS)=SS THEN STR(totals.today_calls,R)
               ELSE IF _Pos2('BIRTHD',work_string,SS)=SS THEN R := TranslateDate1(_Mid(UserRecord.birth,1,2)+'-'+
                                                  _Mid(UserRecord.birth,3,4)+'-19'+
                                                  _Mid(UserRecord.birth,5,6))
               ELSE IF _Pos2('FRATIO',work_string,SS)=SS THEN
               BEGIN
                    IF UserAccess.NoFileRatio=1
                       THEN R := 'None'
                       ELSE R := '1:'+_String(UserAccess.Byte_Ratio);
               END
               ELSE IF _Pos2('UQUOTE',work_string,SS)=SS THEN
               BEGIN
                    CASE UserRecord.DefaultQuote OF
                    1:   R := 'New Only';
                    2:   R := 'All Text';
                    3:   R := 'No Quote';
                    ELSE R := 'None';
                    END;
               END
               ELSE IF _Pos2('STIME',work_string,SS)=SS THEN R := _GetPrettyTime
               ELSE IF _Pos2('MAREA',work_string,SS)=SS THEN R := _String(CurrentMessageArea)
               ELSE IF _Pos2('FAREA',work_string,SS)=SS THEN R := _String(CurrentFileArea)
               ELSE IF _Pos2('CBVS',work_string,SS)=SS THEN R := LongToFormattedTime(GetCBVStart)
               ELSE IF _Pos2('CBVE',work_string,SS)=SS THEN R := LongToFormattedTime(GetCBVEnd)
               ELSE IF _Pos2('PORT',work_string,SS)=SS THEN R := COMString
               ELSE IF _Pos2('BAUD',work_string,SS)=SS THEN R := BaudString
               ELSE IF _Pos2('NODE',work_string,SS)=SS THEN R := NodeString
               ELSE IF _Pos2('FSUB',work_string,SS)=SS THEN R := _String(CurrentFileSub)
               ELSE IF _Pos2('FTAG',work_string,SS)=SS THEN
               BEGIN
                    IF NOT(DidHeader) THEN
                    BEGIN
                         header(CurrentFileSub,CurrentFileArea,True);
                         DidHeader := True;
                    END;
                    IF IsFileTagged(FileAreas.AreaId) THEN R := '*'
                                                      ELSE R := ' ';
               END
               ELSE IF _Pos2('MSUB',work_string,SS)=SS THEN R := _String(CurrentMessageSub)
               ELSE IF _Pos2('MTAG',work_string,SS)=SS THEN
               BEGIN
                    IF NOT(DidHeader2) THEN
                    BEGIN
                         header2(CurrentMessageSub,CurrentMessageArea,True);
                         DidHeader2 := True;
                    END;
                    IF IsMsgTagged(MessageAreas.AreaId) THEN R := '*'
                                                        ELSE R := ' ';
               END
               ELSE IF _Pos2('MNEW',work_string,SS)=SS THEN
               BEGIN
                    IF NOT(DidHeader2) THEN
                    BEGIN
                         header2(CurrentMessageSub,CurrentMessageArea,True);
                         DidHeader2 := True;
                    END;
                    IF NOT(DidMsgInfo) THEN
                    BEGIN
                         JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
                         DidMsgInfo := True;
                    END;
                    IF UserLastReadMSG<HighMSGNumber THEN R := '*'
                                                     ELSE R := ' ';
               END
               ELSE IF _Pos2('MSGS',work_string,SS)=SS THEN
               BEGIN
                    IF NOT(DidHeader2) THEN
                    BEGIN
                         header2(CurrentMessageSub,CurrentMessageArea,True);
                         DidHeader2 := True;
                    END;
                    IF NOT(DidMsgInfo) THEN
                    BEGIN
                         JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
                         DidMsgInfo := True;
                    END;
                    R := _String(TotalMessages);
               END
               ELSE IF _Pos2('USEX',work_string,SS)=SS THEN
               BEGIN
                    IF UserRecord.sex=1 THEN R := GetCommandString('MISC',3)
                                        ELSE R := GetCommandString('MISC',4);
               END
               ELSE IF _Pos2('PAGE',work_string,SS)=SS THEN
               BEGIN
                    IF UserRecord.PageFlag=1 THEN R := GetCommandString('MISC',1)
                                             ELSE R := GetCommandString('MISC',2);
               END
               ELSE IF _Pos2('FDL',work_string,SS)=SS THEN R := _String(UserRecord.file_lines)
               ELSE IF _Pos2('COM',work_string,SS)=SS THEN R := ComString
               ELSE IF _Pos2('EVT',work_string,SS)=SS THEN
               BEGIN
                    IF EventMinutes=32000
                       THEN R := 'None'
                       ELSE R := _String(Round(RemainingTimeInSecs(EventTicker)/60));
               END
               ELSE IF _Pos2('CDO',work_string,SS)=SS THEN
               BEGIN
                    Work_Word := GetTheNumeric(_Mid(work_string,SS+3,LENGTH(Work_String)));
                    IF IsCDOnline(Work_Word) THEN R := 'Online'
                                             ELSE R := 'Offline';
               END
               ELSE IF _Pos2('ANS',work_string,SS)=SS THEN
               BEGIN
                    R := GetCommandString('MISC',1);
               END
               ELSE IF _Pos2('IUL',work_string,SS)=SS THEN
               BEGIN
                    IF UserRecord.UserList=1 THEN R := GetCommandString('MISC',1)
                                             ELSE R := GetCommandString('MISC',2);
               END
               ELSE IF _Pos2('FSE',work_string,SS)=SS THEN
               BEGIN
                    R := GetCommandString('MISC',1);
               END
               ELSE IF _Pos2('IBM',work_string,SS)=SS THEN
               BEGIN
                    IF UserRecord.IBM=1 THEN R := GetCommandString('MISC',1)
                                        ELSE R := GetCommandString('MISC',2);
               END
               ELSE IF _Pos2('CLR',work_string,SS)=SS THEN
               BEGIN
                    R := GetCommandString('MISC',1);
               END
               ELSE IF _Pos2('SEP',work_string,SS)=SS THEN
               BEGIN
                    IF UserRecord.seperator=1 THEN R := GetCommandString('MISC',1)
                                              ELSE R := GetCommandString('MISC',2);
               END
               ELSE IF _Pos2('MR',work_string,SS)=SS THEN STR(MinutesRemaining,R)
               ELSE IF _Pos2('TO',work_string,SS)=SS THEN STR(MinutesOn,R)
               ELSE IF _Pos2('TB',work_string,SS)=SS THEN STR(Trunc(UserRecord.SecondsInBank/60),R)
               ELSE
               BEGIN
                    SL := (ES-SS)+1;
                    Check_Colour := '';
                    CASE SL OF
                    1:   Check_Colour := work_string[SS];
                    2:   Check_Colour := work_string[SS]+work_string[SS+1];
                    END;
                    IF Check_Colour<>'' THEN
                    BEGIN
                         IF IsNumeric(Check_Colour) THEN
                         BEGIN
                              IF PreProcess THEN r := ''
                              ELSE
                              BEGIN
                                   VAL(Check_Colour,Work_Word,Code);
                                   CASE Work_Word OF
                                   0..15: R := get_fore(_String(work_word));
                                   END;
                              END;
                         END;
                    END;
               END;
               IF r='UNGABUNGABANG' THEN
               BEGIN
                    Override := L7+1;
                    Goto Over_Again;
               END
               ELSE
               BEGIN
                    SL := (L8-L7)+1;
                    CASE Im OF
                    1:   BEGIN {INSERT}
                              Delete(work_string,L7,L8-L7+1);
                              Insert(R,work_string,L7);
                              Override := L7;
                              Goto Over_Again;
                         END;
                    2:   BEGIN {PAD RIGHT}
                              R := _PadRight(R,SL);
                              Delete(work_string,L7,L8-L7+1);
                              Insert(R,work_string,L7);
                              Override := L7;
                              Goto Over_Again;
                         END;
                    3:   BEGIN {PAD LEFT}
                              R := _PadLeft(R,SL);
                              Delete(work_string,L7,L8-L7+1);
                              Insert(R,work_string,L7);
                              Override := L7;
                              Goto Over_Again;
                         END;
                    END;
               END;
          END;
     END;
     process_special := work_string;
END;


END.
