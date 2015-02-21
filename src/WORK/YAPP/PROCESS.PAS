{$I DEFINES.INC}
UNIT PROCESS;


INTERFACE


FUNCTION process_special(work_string: string; PreProcess: Boolean) : string;


IMPLEMENTATION


USES BsString,GfxProto;


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
     one           : Byte;
     two           : Byte;
     tttt          : String;
     String1       : String[2];
     String2       : String[3];
     String3       : String[4];
     String4       : String[5];
     String5       : String[6];
     String6       : String[7];
     String7       : String[8];
     String8       : String[9];
     String9       : String[10];
     String10      : String[11];
     String11      : String[12];
     String12      : String[13];
     String13      : String[14];
     String14      : String[15];
     String15      : String[16];
     String17      : String[18];
     String18      : String[19];
LABEL                over_again;

     FUNCTION GetTheNumeric(InString: String): Word;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO LENGTH(InString) DO
          BEGIN
               IF NOT(_IsNumeric(InString[Loop])) THEN
               BEGIN
                    GetTheNumeric := _Numeric(_Mid(InString,1,Loop-1));
                    Exit;
               END;
          END;
          GetTheNumeric := 0;
     END;



BEGIN
     Override := 1;
     over_again:
     FOR L7 := override TO LENGTH(work_string) DO
     BEGIN
          IF ((work_string[L7]='{') OR (work_string[L7]='|')) THEN
          BEGIN
               IF ((work_string[L7]='|') AND (PreProcess)) THEN
               BEGIN
                 String2 := _Mid(work_string,L7+1,L7+2);
                 IF _IsNumeric(String2) THEN
                 BEGIN
                   Delete(Work_String,L7,3);
                   OverRide := L7;
                   GOTO Over_Again;
                 END;
               END;
               L8  := 0;
               FOR One := L7+1 TO LENGTH(work_string) DO
               BEGIN
                    IF L8=0 THEN
                    BEGIN
                         IF ((work_string[one]='|') OR (work_string[one]='}')) THEN
                            L8 := One;
                    END;
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

               String1  := _Mid(work_string,SS,SS+1);
               String2  := _Mid(work_string,SS,SS+2);
               String3  := _Mid(work_string,SS,SS+3);
               String4  := _Mid(work_string,SS,SS+4);
               String5  := _Mid(work_string,SS,SS+5);
               String6  := _Mid(work_string,SS,SS+6);
               String7  := _Mid(work_string,SS,SS+7);
               String8  := _Mid(work_string,SS,SS+8);
               String9  := _Mid(work_string,SS,SS+9);
               String10 := _Mid(work_string,SS,SS+10);
               String11 := _Mid(work_string,SS,SS+11);
               String12 := _Mid(work_string,SS,SS+12);
               String13 := _Mid(work_string,SS,SS+13);
               String14 := _Mid(work_string,SS,SS+14);
               String15 := _Mid(work_string,SS,SS+15);
               String17 := _Mid(work_string,SS,SS+17);
               String18 := _Mid(work_string,SS,SS+18);

                    IF String18='CURRENTMESSAGEGROUP' THEN R := GetVariable(1,0)
               ELSE IF String17='CURRENTMESSAGEAREA' THEN R := GetVariable(2,0)
               ELSE IF String17='USERSSTREETADDRESS' THEN R := GetVariable(3,0)
               ELSE IF String15='CURRENTFILEGROUP' THEN R := GetVariable(4,0)
               ELSE IF String14='OPERATINGSYSTEM' THEN R := GetVariable(5,0)
               ELSE IF String14='CURRENTFILEAREA' THEN R := GetVariable(6,0)
               ELSE IF String14='USERSPOSTALCODE' THEN R := GetVariable(7,0)
               ELSE IF String14='SYSOPSALIASNAME' THEN R := GetVariable(8,0)
               ELSE IF String13='USERSALIASNAME' THEN R := GetVariable(9,0)
               ELSE IF String13='SYSOPSREALNAME' THEN R := GetVariable(10,0)
               ELSE IF String12='USERSVOICENUM' THEN R := GetVariable(11,0)
               ELSE IF String12='USERSREALNAME' THEN R := GetVariable(12,0)
               ELSE IF String12='USERSPASSWORD' THEN R := GetVariable(107,0)
               ELSE IF String12='USERSPROVINCE' THEN R := GetVariable(14,0)
               ELSE IF String12='FMONTHDAYYEAR' THEN R := GetVariable(15,0)
               ELSE IF String11='USERSCOUNTRY' THEN R := GetVariable(16,0)
               ELSE IF String11='USERSDATANUM' THEN R := GetVariable(17,0)
               ELSE IF String10='BBSLOCATION' THEN R := GetVariable(18,0)
               ELSE IF String9='USERSFNAME' THEN R := GetVariable(109,0)
               ELSE IF String9='USERSLNAME' THEN R := GetVariable(110,0)
               ELSE IF String8='USERSCITY' THEN R := GetVariable(19,0)
               ELSE IF String8='UARCHIVER' THEN R := GetVariable(124,0)
               ELSE IF String8='UPROTOCOL' THEN R := GetVariable(125,0)
               ELSE IF String8='CDROMNAME' THEN
               BEGIN
                    Work_Word := GetTheNumeric(_Mid(work_string,SS+9,LENGTH(Work_String)));
                    R := GetVariable(114,Work_Word);
               END
               ELSE IF String7='MMDDYYYY' THEN R := GetVariable(40,0)
               ELSE IF String7='SUBTIME1' THEN R := GetVariable(116,0)
               ELSE IF String7='SUBTIME2' THEN R := GetVariable(117,0)
               ELSE IF String7='SUBTIME3' THEN R := GetVariable(118,0)
               ELSE IF String7='USETIME1' THEN R := GetVariable(119,0)
               ELSE IF String7='USETIME2' THEN R := GetVariable(120,0)
               ELSE IF String7='USETIME3' THEN R := GetVariable(121,0)
               ELSE IF String7='SUBMODEL' THEN R := GetVariable(122,0)
               ELSE IF String6='VERSION' THEN R := GetVariable(108,0)
               ELSE IF String6='BINBANK' THEN R := GetVariable(41,0)
               ELSE IF String6='BREMAIN' THEN R := GetVariable(42,0)
               ELSE IF String6='BUPLOAD' THEN R := GetVariable(43,0)
               ELSE IF String6='BDNLOAD' THEN R := GetVariable(44,0)
               ELSE IF String6='FUPLOAD' THEN R := GetVariable(45,0)
               ELSE IF String6='FDNLOAD' THEN R := GetVariable(46,0)
               ELSE IF String6='SYSBYTE' THEN R := GetVariable(47,0)
               ELSE IF String6='BBSNAME' THEN R := GetVariable(48,0)
               ELSE IF String6='TBTRANS' THEN R := GetVariable(49,0)
               ELSE IF String6='BBTRANS' THEN R := GetVariable(50,0)
               ELSE IF String6='USERACC' THEN R := GetVariable(113,0)
               ELSE IF String5='REMAIN' THEN R := GetVariable(51,0)
               ELSE IF String5='USEREX' THEN R := GetVariable(52,0)
               ELSE IF String5='UQUOTE' THEN R := GetVariable(126,0)
               ELSE IF String5='BIRTHD' THEN R := GetVariable(53,0)
               ELSE IF String5='FRATIO' THEN R := GetVariable(54,0)
               ELSE IF String5='TCALLS' THEN R := GetVariable(111,0)
               ELSE IF String5='CALLST' THEN R := GetVariable(112,0)
               ELSE IF String4='STIME' THEN R := GetVariable(55,0)
               ELSE IF String4='MAREA' THEN R := GetVariable(56,0)
               ELSE IF String4='FAREA' THEN R := GetVariable(57,0)
               ELSE IF String3='CBVS' THEN R := GetVariable(58,0)
               ELSE IF String3='CBVE' THEN R := GetVariable(59,0)
               ELSE IF String3='PORT' THEN R := GetVariable(60,0)
               ELSE IF String3='BAUD' THEN R := GetVariable(61,0)
               ELSE IF String3='NODE' THEN R := GetVariable(62,0)
               ELSE IF String3='FSUB' THEN R := GetVariable(63,0)
               ELSE IF String3='FTAG' THEN R := GetVariable(64,0)
               ELSE IF String3='MSUB' THEN R := GetVariable(65,0)
               ELSE IF String3='MTAG' THEN R := GetVariable(66,0)
               ELSE IF String3='MNEW' THEN R := GetVariable(67,0)
               ELSE IF String3='MSGS' THEN R := GetVariable(68,0)
               ELSE IF String3='USEX' THEN R := GetVariable(69,0)
               ELSE IF String3='PAGE' THEN R := GetVariable(70,0)
               ELSE IF String2='FDL' THEN R := GetVariable(71,0)
               ELSE IF String2='COM' THEN R := GetVariable(72,0)
               ELSE IF String2='EVT' THEN R := GetVariable(73,0)
               ELSE IF String2='CDO' THEN
               BEGIN
                    Work_Word := GetTheNumeric(_Mid(work_string,SS+3,LENGTH(Work_String)));
                    R := GetVariable(115,Work_Word);
               END
               ELSE IF String2='ANS' THEN R := GetVariable(75,0)
               ELSE IF String2='FSE' THEN R := GetVariable(76,0)
               ELSE IF String2='IBM' THEN R := GetVariable(77,0)
               ELSE IF String2='CLR' THEN R := GetVariable(78,0)
               ELSE IF String2='SEP' THEN R := GetVariable(79,0)
               ELSE IF String2='IUL' THEN R := GetVariable(123,0)
               ELSE IF String1='MR' THEN R := GetVariable(80,0)
               ELSE IF String1='TO' THEN R := GetVariable(81,0)
               ELSE IF String1='TB' THEN R := GetVariable(82,0)
               ELSE IF PreProcess THEN
               BEGIN
                    SL := L8-L7-1;
                    CASE SL OF
                    1:   IF _IsNumeric(work_string[L7+1]) THEN R := '';
                    2:   IF _IsNumeric(String1) THEN R := '';
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
